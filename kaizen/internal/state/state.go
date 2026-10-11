// Package state reads the state of kaizen's shell from systemd and from the
// shell itself.
package state

import (
	"bytes"
	"context"
	"encoding/json/v2"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

// Unit is the shell's systemd user unit.
const Unit = "kaizen-shell.service"

// queryTimeout bounds one IPC query.
const queryTimeout = 2 * time.Second

// notReady is qs's answer while the shell loads its config, and for good once
// loading failed.
const notReady = "Not ready to accept queries yet."

// ErrNotReady reports that the shell is loading its config, or failed to.
var ErrNotReady = errors.New("not ready to accept queries")

// Runner runs a program and returns its stdout.
type Runner interface {
	Run(ctx context.Context, name string, args ...string) ([]byte, error)
}

// Exec runs programs on the host.
type Exec struct{}

// Run runs name with args. qs refuses config selection beside --pid, so the
// environment that selects one is dropped.
func (Exec) Run(ctx context.Context, name string, args ...string) ([]byte, error) {
	cmd := exec.CommandContext(ctx, name, args...)
	for _, kv := range os.Environ() {
		switch key, _, _ := strings.Cut(kv, "="); key {
		case "QS_CONFIG_NAME", "QS_CONFIG_PATH", "QS_MANIFEST":
			continue
		}
		cmd.Env = append(cmd.Env, kv)
	}
	return cmd.Output()
}

// Status is the shell's state. A fact that could not be learned is nil.
type Status struct {
	Unit   string `json:"unit"`
	Active string `json:"active"`
	Sub    string `json:"sub"`
	// PID is 0 while the unit runs no process.
	PID int `json:"pid"`
	// Dev reports a `kaizen dev` drop-in on the unit.
	Dev bool `json:"dev"`
	// Ready reports that the shell answered `shell status`.
	Ready bool `json:"ready"`
	// Error is why a running shell did not answer.
	Error     *string  `json:"error"`
	Tree      *string  `json:"tree"`
	BarHeight *int     `json:"barHeight"`
	Lock      *Lock    `json:"lock"`
	Curtain   *Curtain `json:"curtain"`
	Idle      *Idle    `json:"idle"`
}

// Lock is the lock service's status.
type Lock struct {
	Locked         bool `json:"locked"`
	Requested      bool `json:"requested"`
	Secure         bool `json:"secure"`
	PasswordPam    bool `json:"passwordPam"`
	Authenticating bool `json:"authenticating"`
}

// Curtain is the curtain service's status.
type Curtain struct {
	Active         bool `json:"active"`
	Awake          bool `json:"awake"`
	PasswordPam    bool `json:"passwordPam"`
	Authenticating bool `json:"authenticating"`
}

// Idle is the idle service's status.
type Idle struct {
	Enabled          bool `json:"enabled"`
	Idle             bool `json:"idle"`
	LockAfterSeconds int  `json:"lockAfterSeconds"`
}

// shellStatus is the answer to `shell status`.
type shellStatus struct {
	Tree      *string  `json:"tree"`
	BarHeight *int     `json:"barHeight"`
	Lock      *Lock    `json:"lock"`
	Curtain   *Curtain `json:"curtain"`
	Idle      *Idle    `json:"idle"`
}

// Read returns the shell's state. It fails only when systemd cannot be read; a
// shell that does not answer is a Status that says why.
func Read(ctx context.Context, r Runner) (Status, error) {
	status, err := readUnit(ctx, r)
	if err != nil {
		return Status{}, err
	}
	if status.PID == 0 {
		return status, nil
	}
	shell, err := query(ctx, r, status.PID)
	if err != nil {
		status.Error = new(err.Error())
		return status, nil
	}
	status.answered(shell)
	return status, nil
}

// answered records the shell's answer to `shell status`.
func (s *Status) answered(shell shellStatus) {
	s.Ready = true
	s.Tree = shell.Tree
	s.BarHeight = shell.BarHeight
	s.Lock = shell.Lock
	s.Curtain = shell.Curtain
	s.Idle = shell.Idle
}

// readUnit returns the unit's facts from systemd.
func readUnit(ctx context.Context, r Runner) (Status, error) {
	out, err := r.Run(ctx, "systemctl", "--user", "show", Unit, "-p", "MainPID,ActiveState,SubState,DropInPaths")
	if err != nil {
		return Status{}, fmt.Errorf("systemctl show %s: %w", Unit, err)
	}
	status := Status{Unit: Unit}
	for line := range strings.Lines(string(out)) {
		key, value, _ := strings.Cut(strings.TrimSuffix(line, "\n"), "=")
		switch key {
		case "MainPID":
			if status.PID, err = strconv.Atoi(value); err != nil {
				return Status{}, fmt.Errorf("systemctl show %s: MainPID: %w", Unit, err)
			}
		case "ActiveState":
			status.Active = value
		case "SubState":
			status.Sub = value
		case "DropInPaths":
			for path := range strings.FieldsSeq(value) {
				if filepath.Base(path) == "dev.conf" {
					status.Dev = true
				}
			}
		}
	}
	return status, nil
}

// call calls function fn of target on the shell at pid and returns the first
// line of its answer. qs answers with an error message in place of the
// function's answer, mostly with exit 0: the caller tells the two apart.
func call(ctx context.Context, r Runner, pid int, target, fn string) ([]byte, string, error) {
	ctx, cancel := context.WithTimeout(ctx, queryTimeout)
	defer cancel()
	out, err := r.Run(ctx, "qs", "ipc", "--pid", strconv.Itoa(pid), "call", target, fn)
	answer, _, _ := strings.Cut(string(bytes.TrimSpace(out)), "\n")
	if answer == notReady {
		return nil, "", ErrNotReady
	}
	if err != nil && answer == "" {
		return nil, "", fmt.Errorf("qs ipc: %v", err)
	}
	return out, answer, nil
}

// query asks the shell at pid for its status.
func query(ctx context.Context, r Runner, pid int) (shellStatus, error) {
	out, answer, err := call(ctx, r, pid, "shell", "status")
	if err != nil {
		return shellStatus{}, err
	}
	if !strings.HasPrefix(answer, "{") {
		return shellStatus{}, errors.New(answer)
	}
	var shell shellStatus
	if err := json.Unmarshal(out, &shell); err != nil {
		return shellStatus{}, fmt.Errorf("shell status: %v", err)
	}
	return shell, nil
}
