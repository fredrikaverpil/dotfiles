package doctor

import (
	"bytes"
	"context"
	"encoding/binary"
	"encoding/json/v2"
	"errors"
	"fmt"
	"maps"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
	"testing"
	"time"

	"gotest.tools/v3/assert"

	"github.com/fredrikaverpil/dotfiles/kaizen/cli/internal/compositor"
	"github.com/fredrikaverpil/dotfiles/kaizen/cli/internal/state"
)

// recorded is a program's recorded stdout and error.
type recorded struct {
	Stdout string
	Err    error
}

// seqRunner answers each command line with its recorded outputs in turn,
// repeating the last, and records the lines it ran.
type seqRunner struct {
	outputs map[string][]recorded
	calls   []string
}

func (s *seqRunner) Run(_ context.Context, name string, args ...string) ([]byte, error) {
	line := strings.Join(append([]string{name}, args...), " ")
	s.calls = append(s.calls, line)
	outs := s.outputs[line]
	if len(outs) == 0 {
		return nil, fmt.Errorf("unexpected command: %s", line)
	}
	if len(outs) > 1 {
		s.outputs[line] = outs[1:]
	}
	return []byte(outs[0].Stdout), outs[0].Err
}

const (
	showLine    = "systemctl --user show kaizen-* -p Id -p InvocationID -p NRestarts -p ActiveState -p Result -p MainPID -p DropInPaths"
	niriLine    = "env NO_COLOR=1 niri validate"
	umbrielLine = "umbriel config validate"
	portalLine  = "busctl --user --timeout=5 call org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop " +
		"org.freedesktop.portal.Settings ReadOne ss org.freedesktop.appearance color-scheme"
	runsLine  = "journalctl --user --lines all --output json --no-pager"
	bootLine  = "journalctl --user --unit kaizen-* --boot --lines all --output json --no-pager"
	userBus   = "busctl --user list --no-legend"
	systemBus = "busctl --system list --no-legend"
	envLine   = "systemctl --user show-environment"
	fontLine  = "fc-list : family"
	// coreRequires is the core's requires under the test's $HOME.
	coreRequires = "home/.config/quickshell/kaizen/requires"
	// niriConfig is niri's config under the test's $HOME.
	niriConfig = "home/.config/niri/config.kdl"
	// umbrielConfig is umbriel's config under the test's $HOME.
	umbrielConfig = "home/.config/umbriel/config.toml"
)

// base is the time the journal's entries count from.
var base = time.Date(2026, 10, 11, 11, 0, 0, 0, time.UTC)

// logLine is a journal entry as journalctl's JSON, logged sec seconds after
// base.
func logLine(sec int, fields map[string]string) string {
	fields["__REALTIME_TIMESTAMP"] = fmt.Sprint(base.Add(time.Duration(sec) * time.Second).UnixMicro())
	out, err := json.Marshal(fields)
	if err != nil {
		panic(err)
	}
	return string(out) + "\n"
}

// restartsLine reads the n latest restarts of unit id.
func restartsLine(id string, n int) string {
	return fmt.Sprintf(
		"journalctl --user --boot USER_UNIT=%s MESSAGE_ID=%s --lines %d --output json --no-pager",
		id, restartScheduled, n,
	)
}

// unitBlock is a unit as `systemctl show` prints it.
func unitBlock(id, invocation, state, result, pid, restarts, dropIns string) string {
	return fmt.Sprintf(
		"Id=%s\nActiveState=%s\nDropInPaths=%s\nInvocationID=%s\nMainPID=%s\nResult=%s\nNRestarts=%s\n",
		id, state, dropIns, invocation, pid, result, restarts,
	)
}

// scheduled is systemd's entry about the shell's run that it restarts.
func scheduled(run string) map[string]string {
	return map[string]string{
		"MESSAGE": "kaizen-shell.service: Scheduled restart job.", "SYSLOG_IDENTIFIER": "systemd",
		"USER_UNIT": "kaizen-shell.service", "USER_INVOCATION_ID": run, "MESSAGE_ID": restartScheduled,
	}
}

// exited is systemd's entry about how the shell's run exited.
func exited(run, how string) map[string]string {
	return map[string]string{
		"MESSAGE": "kaizen-shell.service: Main process exited, " + how, "PRIORITY": "5", "SYSLOG_IDENTIFIER": "systemd",
		"USER_UNIT": "kaizen-shell.service", "USER_INVOCATION_ID": run, "MESSAGE_ID": processExited,
	}
}

// failed is systemd's entry about the shell's failed run.
func failed(run string) map[string]string {
	return map[string]string{
		"MESSAGE": "kaizen-shell.service: Failed with result 'exit-code'.", "PRIORITY": "4", "SYSLOG_IDENTIFIER": "systemd",
		"USER_UNIT": "kaizen-shell.service", "USER_INVOCATION_ID": run, "MESSAGE_ID": failureResult,
	}
}

// shellLine is a line the shell's run logged.
func shellLine(run, message string) map[string]string {
	return map[string]string{
		"MESSAGE": message, "PRIORITY": "6", "_PID": "10",
		"_SYSTEMD_USER_UNIT": "kaizen-shell.service", "_SYSTEMD_INVOCATION_ID": run,
	}
}

// xattr is a file's security.capability attribute, or the error reading it.
type xattr struct {
	value []byte
	err   error
}

// vfsCap is a security.capability attribute of size bytes: magic_etc, then the
// permitted set's low word.
func vfsCap(magic, permitted uint32, size int) []byte {
	data := make([]byte, size)
	binary.LittleEndian.PutUint32(data, magic)
	binary.LittleEndian.PutUint32(data[4:], permitted)
	return data
}

// The vfs_cap_data revisions, and their effective flag.
const (
	capRevision2 = 0x02000000
	capRevision3 = 0x03000000
	capEffective = 1
)

// cap_setpcap and cap_sys_admin, as NixOS's wrapper holds them.
const setpcapSysAdmin = 1<<8 | 1<<21

// result is what Command.Run did, and the lines it ran.
type result struct {
	Code   int
	Stdout string
	Stderr string
	Calls  []string
}

func TestRun(t *testing.T) {
	now := time.Date(2026, 10, 11, 12, 0, 0, 0, time.UTC)
	shellRunning := unitBlock("kaizen-shell.service", "aaa", "active", "success", "4242", "0", "")
	binding := map[string]string{
		"MESSAGE": "  WARN scene: Binding loop", "PRIORITY": "6", "_PID": "10",
		"_SYSTEMD_USER_UNIT": "kaizen-shell.service",
	}
	for _, tt := range []struct {
		name string
		args []string
		// env, files, links and outputs say $DIR for the test's directory.
		env map[string]string
		// files are written under $DIR, over a niri config including
		// kaizen.kdl; those in execs are executable.
		files map[string]string
		execs []string
		// unreadable are files under $DIR without permissions.
		unreadable []string
		// links are symbolic links under $DIR to their targets.
		links map[string]string
		// caps are files' capabilities under $DIR; a file without is ENODATA.
		caps    map[string]xattr
		outputs map[string][]recorded
		want    result
	}{
		{
			name: "help",
			args: []string{"-h"},
			want: result{Stdout: "usage: kaizen doctor [--json] [JOURNALCTL_ARGS...]    " + Command{}.Summary() + "\n"},
		},
		{
			name:  "healthy",
			args:  []string{"--json"},
			env:   map[string]string{"PATH": "$DIR/bin"},
			files: map[string]string{coreRequires: ""},
			execs: []string{"bin/kaizen", "bin/gsr-kms-server"},
			caps:  map[string]xattr{"bin/gsr-kms-server": {value: vfsCap(capRevision2|capEffective, setpcapSysAdmin, 20)}},
			outputs: map[string][]recorded{
				showLine:   {{Stdout: shellRunning + "\n" + unitBlock("kaizen-dcal.service", "bbb", "active", "success", "77", "0", "")}},
				niriLine:   {{}},
				portalLine: {{}},
				runsLine + " _SYSTEMD_INVOCATION_ID=aaa + USER_INVOCATION_ID=aaa + _SYSTEMD_INVOCATION_ID=bbb + USER_INVOCATION_ID=bbb": {
					{},
				},
			},
			want: result{
				Stdout: `{"findings":[],"text":"No errors or warnings"}` + "\n",
				Calls: []string{
					showLine,
					niriLine, portalLine,
					runsLine + " _SYSTEMD_INVOCATION_ID=aaa + USER_INVOCATION_ID=aaa + _SYSTEMD_INVOCATION_ID=bbb + USER_INVOCATION_ID=bbb",
				},
			},
		},
		{
			name:  "units and logs",
			files: map[string]string{coreRequires: ""},
			outputs: map[string][]recorded{
				showLine: {{Stdout: strings.Join([]string{
					unitBlock("kaizen-shell.service", "aaa", "active", "success", "0", "0", ""),
					unitBlock("kaizen-dcal.service", "", "failed", "exit-code", "0", "1", ""),
					unitBlock("kaizen-incident-investigator.service", "ccc", "active", "success", "77", "2", ""),
				}, "\n")}},
				restartsLine("kaizen-dcal.service", 1):                  {{}},
				restartsLine("kaizen-incident-investigator.service", 2): {{Err: errors.New("exit status 1")}},
				niriLine:   {{}},
				portalLine: {{}},
				runsLine + " _SYSTEMD_INVOCATION_ID=aaa + USER_INVOCATION_ID=aaa + _SYSTEMD_INVOCATION_ID=ccc + USER_INVOCATION_ID=ccc": {
					{Stdout: logLine(5, binding) + logLine(65, binding) +
						logLine(85, map[string]string{
							"MESSAGE": "kaizen-dcal.service: Failed with result 'exit-code'.", "PRIORITY": "4",
							"SYSLOG_IDENTIFIER": "systemd", "USER_UNIT": "kaizen-dcal.service",
						}) +
						logLine(90, map[string]string{
							"MESSAGE": "Failed to start kaizen-incident-investigator.service.", "PRIORITY": "3",
							"SYSLOG_IDENTIFIER": "systemd", "USER_UNIT": "kaizen-incident-investigator.service",
						}) +
						logLine(100, map[string]string{
							"MESSAGE":            "time=2026-10-11T11:00:00Z level=WARN msg=slow",
							"_SYSTEMD_USER_UNIT": "kaizen-incident-investigator.service",
						}) +
						logLine(110, map[string]string{
							"MESSAGE":            "2026/10/11 11:00:00 systray error: boom",
							"_SYSTEMD_USER_UNIT": "kaizen-incident-investigator.service",
						}) +
						logLine(115, map[string]string{
							"MESSAGE": "  INFO: Configuration Loaded", "_SYSTEMD_USER_UNIT": "kaizen-shell.service",
						}) +
						logLine(120, map[string]string{"MESSAGE": "orphan", "PRIORITY": "4"})},
				},
			},
			want: result{
				Stdout: "4 errors, 5 warnings\n\n" +
					"ERROR kaizen-dcal  check\n  failed (exit-code)\n" +
					"ERROR doctor  check\n  cannot read why kaizen-incident-investigator was restarted: journalctl: exit status 1\n" +
					"ERROR kaizen-incident-investigator  11:01:50\n  2026/10/11 11:00:00 systray error: boom\n" +
					"ERROR kaizen-incident-investigator  11:01:30\n  Failed to start kaizen-incident-investigator.service.\n" +
					"WARN  kaizen-dcal  check\n  failed and was restarted 1 time\n" +
					"WARN  kaizen-incident-investigator  check\n  failed and was restarted 2 times\n" +
					"WARN  ?  11:02:00\n  orphan\n" +
					"WARN  kaizen-incident-investigator  11:01:40\n  level=WARN msg=slow\n" +
					"WARN  kaizen-shell  ×2  11:00:05–11:01:05\n  WARN scene: Binding loop\n",
				Calls: []string{
					showLine,
					restartsLine("kaizen-dcal.service", 1),
					restartsLine("kaizen-incident-investigator.service", 2),
					niriLine, portalLine,
					runsLine + " _SYSTEMD_INVOCATION_ID=aaa + USER_INVOCATION_ID=aaa + _SYSTEMD_INVOCATION_ID=ccc + USER_INVOCATION_ID=ccc",
				},
			},
		},
		{
			name:  "restarts",
			files: map[string]string{coreRequires: ""},
			outputs: map[string][]recorded{
				showLine: {{Stdout: unitBlock("kaizen-shell.service", "aaa", "active", "success", "0", "4", "")}},
				restartsLine("kaizen-shell.service", 4): {{Stdout: logLine(10, scheduled("r1")) + logLine(20, scheduled("r2")) +
					logLine(30, scheduled("r3")) + logLine(40, scheduled("r4"))}},
				runsLine + " _SYSTEMD_INVOCATION_ID=r1 + USER_INVOCATION_ID=r1 + _SYSTEMD_INVOCATION_ID=r2 + USER_INVOCATION_ID=r2" +
					" + _SYSTEMD_INVOCATION_ID=r3 + USER_INVOCATION_ID=r3 + _SYSTEMD_INVOCATION_ID=r4 + USER_INVOCATION_ID=r4": {
					{Stdout: logLine(7, shellLine("r1", "  WARN scene: Binding loop")) +
						logLine(8, shellLine("r1", "  ERROR boom")) +
						logLine(9, exited("r1", "code=exited, status=1/FAILURE")) +
						logLine(9, failed("r1")) +
						logLine(18, shellLine("r2", "  ERROR boom")) +
						logLine(19, exited("r2", "code=exited, status=1/FAILURE")) +
						logLine(19, failed("r2")) +
						logLine(27, shellLine("r3", "  ERROR first\nat line 3")) +
						logLine(29, exited("r3", "code=dumped, status=11/SEGV")) +
						logLine(29, failed("r3"))},
				},
				niriLine:   {{}},
				portalLine: {{}},
				runsLine + " _SYSTEMD_INVOCATION_ID=aaa + USER_INVOCATION_ID=aaa": {{}},
			},
			want: result{
				Stdout: "1 warning\n\nWARN  kaizen-shell  check\n  failed and was restarted 4 times\n" +
					"  ×2  11:00:09–11:00:19  code=exited, status=1/FAILURE\n    ERROR boom\n" +
					"  11:00:29  code=dumped, status=11/SEGV\n    ERROR first\n    at line 3\n" +
					"  11:00:40\n",
				Calls: []string{
					showLine,
					restartsLine("kaizen-shell.service", 4),
					runsLine + " _SYSTEMD_INVOCATION_ID=r1 + USER_INVOCATION_ID=r1 + _SYSTEMD_INVOCATION_ID=r2 + USER_INVOCATION_ID=r2" +
						" + _SYSTEMD_INVOCATION_ID=r3 + USER_INVOCATION_ID=r3 + _SYSTEMD_INVOCATION_ID=r4 + USER_INVOCATION_ID=r4",
					niriLine, portalLine,
					runsLine + " _SYSTEMD_INVOCATION_ID=aaa + USER_INVOCATION_ID=aaa",
				},
			},
		},
		{
			name: "checks",
			env: map[string]string{
				"PATH":          "$DIR/home/.local/bin:$DIR/bin",
				"XDG_DATA_HOME": "$DIR/data",
				"XDG_DATA_DIRS": "$DIR/share",
			},
			files: map[string]string{
				"bin/notexec":             "",
				"share/kaizen/emoji.json": "{}",
				"run/kaizen-shell.service.d/dev.conf": "[Service]\nExecStart=\n" +
					"ExecStart=/usr/bin/env quickshell -p \"$DIR/tree\"\n",
				"tree/requires": "# comment\n\ncmd present\ncmd notexec\ncmd absent warn\n" +
					"bus session org.a\nbus session org.b warn\nbus system org.c\nbus system org.d\nbus other x\n" +
					"bus session\nbus session org.a warn extra\ncmd\ncmd present extra\ndata\n" +
					"file $DIR/tree/requires\nfile $DIR/nope\n" +
					"data kaizen/emoji.json\ndata kaizen/nope.json warn\n" +
					"env A=1\nenv B=2 warn\nenv C=3\nenv A\nenv =1\n" +
					"font Mono Sans\nfont mono  ALIAS\nfont Gone Mono warn\nfont Gone Serif\nfont\n" +
					"qtplugin imageformats/libqwebp.so\nqtplugin platforms/libqwayland.so\n" +
					"qtplugin imageformats/libqgif.so warn\nqtplugin imageformats/libqsvg.so\nqtplugin\n",
				"proc/4242/environ": "A=1\x00QT_PLUGIN_PATH=$DIR/qt/a::$DIR/qt/b\x00",
				"proc/4242/maps": "7299-72aa r--p 00000000 00:00 0\n" +
					"7299-72aa r--p 00000000 fe:00 1    $DIR/qtbase/lib/libQt6Core.so.6.11.2\n",
				"qt/b/imageformats/libqwebp.so":                    "",
				"qtbase/lib/qt-6/plugins/platforms/libqwayland.so": "",
				"tree/plugin-api":                                  "1\n",
				"tree/plugins/ok/Plugin.qml":                       "",
				"tree/plugins/ok/plugin.json":                      `{"id": "ok", "api": 1}`,
				"tree/plugins/ok/requires":                         "bus session org.a\ncmd present\nenv A=1\nqtplugin imageformats/libqwebp.so\n",
				"tree/plugins/warned/Plugin.qml":                   "",
				"tree/plugins/warned/plugin.json":                  `{"id": "warned", "api": 1}`,
				"tree/plugins/warned/requires":                     "cmd absent warn\n",
				"tree/plugins/both/Plugin.qml":                     "",
				"home/.config/kaizen/plugins/both/Plugin.qml":      "",
				"home/.config/kaizen/plugins/noqml/plugin.json":    `{"id": "noqml", "api": 1}`,
				"home/.config/kaizen/plugins/noqml/requires":       "cmd absent\n",
				"home/.config/kaizen/plugins/ok.jsonc":             "{}",
				"home/.config/kaizen/plugins/warned.jsonc":         "{}",
				"home/.config/kaizen/plugins/both.jsonc":           "{}",
				"home/.config/kaizen/plugins/noqml.jsonc":          "{}",
				"home/.config/kaizen/plugins/absent.jsonc":         "{}",
				"home/.config/kaizen/plugins/.hidden.jsonc":        "{}",
			},
			execs: []string{"home/.local/bin/kaizen", "bin/kaizen", "bin/present"},
			links: map[string]string{"proc/4242/exe": "/usr/bin/quickshell (deleted)"},
			outputs: map[string][]recorded{
				showLine: {{Stdout: unitBlock(
					"kaizen-shell.service", "", "active", "success", "4242", "0",
					"$DIR/run/kaizen-shell.service.d/dev.conf /etc/systemd/user/kaizen-shell.service.d/env.conf",
				)}},
				"$DIR/home/.local/bin/kaizen --version": {{Stdout: "abc123\n"}},
				niriLine: {{Err: &exec.ExitError{
					Stderr: []byte("2026-10-11T11:00:00.000Z  INFO niri: loading\nError: bad config\n\n  at line 3\n"),
				}}},
				portalLine: {{Err: errors.New("exit status 1")}},
				userBus:    {{Stdout: "org.a 1 x\n:1.5 2 y\n"}},
				systemBus:  {{Err: errors.New("exit status 1")}},
				envLine:    {{Stdout: "A=1\nB=1\nPATH=/bin\n"}},
				fontLine:   {{Stdout: "Mono Sans,Mono Alias\nOther\n"}},
			},
			want: result{
				Stdout: "7 errors, 5 warnings\n\n" +
					"ERROR niri  check\n  niri validate:\n  Error: bad config\n\n    at line 3\n" +
					"ERROR doctor  check\n  cannot list the system bus: busctl: exit status 1\n" +
					"ERROR requires  check\n" +
					"  missing cmd notexec\n  missing cmd absent\n  missing bus session org.b\n" +
					"  unknown line: bus other x\n  unknown line: bus session\n" +
					"  unknown line: bus session org.a warn extra\n  unknown line: cmd\n" +
					"  unknown line: cmd present extra\n  unknown line: data\n  missing file $DIR/nope\n" +
					"  missing data kaizen/nope.json\n  missing env B=2\n  missing env C=3\n" +
					"  unknown line: env A\n  unknown line: env =1\n" +
					"  missing font Gone Mono\n  missing font Gone Serif\n  unknown line: font\n" +
					"  missing qtplugin imageformats/libqgif.so\n  missing qtplugin imageformats/libqsvg.so\n" +
					"  unknown line: qtplugin\n" +
					"ERROR plugins  check\n  absent: no absent/ in $DIR/tree/plugins or $DIR/home/.config/kaizen/plugins\n" +
					"ERROR plugins  check\n  both: both/ in both $DIR/tree/plugins and $DIR/home/.config/kaizen/plugins\n" +
					"ERROR plugins  check\n  noqml: no Plugin.qml in $DIR/home/.config/kaizen/plugins/noqml\n" +
					"ERROR noqml  check\n  missing cmd absent\n" +
					"WARN  kaizen-shell  check\n" +
					"  runs a Quickshell that is no longer installed\n  hint: kaizen reload --restart\n" +
					"WARN  kaizen  check\n  2 kaizen on PATH; the first, ~/.local/bin/kaizen, is abc123\n" +
					"  hint: delete ~/.local/bin/kaizen or rebuild\n" +
					"WARN  xdg-desktop-portal  check\n  cannot read the colour scheme: busctl: exit status 1\n" +
					"WARN  kaizen-shell  check\n  runs $DIR/tree\n  hint: kaizen dev off\n" +
					"WARN  warned  check\n  missing cmd absent\n",
				Calls: []string{showLine, "$DIR/home/.local/bin/kaizen --version", niriLine, portalLine, userBus, systemBus, envLine, fontLine},
			},
		},
		{
			name: "plugin manifests",
			files: map[string]string{
				coreRequires: "",
				"home/.config/quickshell/kaizen/plugin-api":      "1\n",
				"home/.config/kaizen/plugins/broken.jsonc":       "{}",
				"home/.config/kaizen/plugins/broken/Plugin.qml":  "",
				"home/.config/kaizen/plugins/broken/plugin.json": "{",
				"home/.config/kaizen/plugins/good.jsonc":         "{}",
				"home/.config/kaizen/plugins/good/Plugin.qml":    "",
				"home/.config/kaizen/plugins/good/plugin.json": `{"id": "good", "name": "Good", "version": "0.1.0", "api": 1, ` +
					`"units": ["kaizen-good.service", "kaizen-idle.service", "kaizen-gone.service"]}`,
				"home/.config/kaizen/plugins/newer.jsonc":      "{}",
				"home/.config/kaizen/plugins/newer/Plugin.qml": "",
				"home/.config/kaizen/plugins/newer/plugin.json": `{"id": "newer", "name": "Newer", "version": "2.0.0", "api": 2, ` +
					`"units": ["kaizen-good.service"]}`,
				"home/.config/kaizen/plugins/nomanifest.jsonc":      "{}",
				"home/.config/kaizen/plugins/nomanifest/Plugin.qml": "",
				"home/.config/kaizen/plugins/renamed.jsonc":         "{}",
				"home/.config/kaizen/plugins/renamed/Plugin.qml":    "",
				"home/.config/kaizen/plugins/renamed/plugin.json":   `{"id": "other", "api": 1, "units": ["kaizen-gone.service"]}`,
			},
			outputs: map[string][]recorded{
				showLine: {{Stdout: strings.Join([]string{
					unitBlock("kaizen-shell.service", "", "active", "success", "0", "0", ""),
					unitBlock("kaizen-good.service", "", "active", "success", "0", "0", ""),
					unitBlock("kaizen-idle.service", "", "inactive", "success", "0", "0", ""),
				}, "\n")}},
				niriLine:   {{}},
				portalLine: {{}},
			},
			want: result{
				Stdout: "5 errors, 1 warning\n\n" +
					"ERROR plugins  check\n  broken: $DIR/home/.config/kaizen/plugins/broken/plugin.json: " +
					"jsontext: unexpected EOF after offset 1\n" +
					"ERROR plugins  check\n  good: kaizen-gone.service is not loaded\n  hint: kaizen link\n" +
					"ERROR plugins  check\n  newer: Newer 2.0.0 needs plugin API 2, the shell's is 1\n" +
					"ERROR plugins  check\n  nomanifest: no plugin.json in $DIR/home/.config/kaizen/plugins/nomanifest\n" +
					"ERROR plugins  check\n  renamed: $DIR/home/.config/kaizen/plugins/renamed/plugin.json names id \"other\"\n" +
					"WARN  kaizen-idle  check\n  not running, though plugin good is enabled\n" +
					"  hint: systemctl --user start kaizen-idle.service\n",
				Calls: []string{showLine, niriLine, portalLine},
			},
		},
		{
			name: "no plugin API",
			files: map[string]string{
				coreRequires:                                   "",
				"home/.config/kaizen/plugins/good.jsonc":       "{}",
				"home/.config/kaizen/plugins/good/Plugin.qml":  "",
				"home/.config/kaizen/plugins/good/plugin.json": `{"id": "good", "api": 2}`,
			},
			outputs: map[string][]recorded{
				showLine:   {{Stdout: unitBlock("kaizen-shell.service", "", "active", "success", "0", "0", "")}},
				niriLine:   {{}},
				portalLine: {{}},
			},
			want: result{
				Stdout: "1 error\n\nERROR plugins  check\n  cannot read the shell's plugin API: " +
					"open $DIR/home/.config/quickshell/kaizen/plugin-api: no such file or directory\n",
				Calls: []string{showLine, niriLine, portalLine},
			},
		},
		{
			name: "no core requires",
			outputs: map[string][]recorded{
				showLine:   {{Stdout: unitBlock("kaizen-shell.service", "", "active", "success", "0", "0", "")}},
				niriLine:   {{}},
				portalLine: {{}},
			},
			want: result{
				Stdout: "1 error\n\nERROR requires  check\n  no requires in $DIR/home/.config/quickshell/kaizen\n",
				Calls:  []string{showLine, niriLine, portalLine},
			},
		},
		{
			name:  "qtplugin without a shell",
			files: map[string]string{coreRequires: "qtplugin imageformats/libqwebp.so\nqtplugin platforms/libqwayland.so\n"},
			outputs: map[string][]recorded{
				showLine:   {{Stdout: unitBlock("kaizen-shell.service", "", "inactive", "success", "0", "0", "")}},
				niriLine:   {{}},
				portalLine: {{}},
			},
			want: result{
				Stdout: "1 error\n\nERROR doctor  check\n  cannot list the shell's Qt plugin dirs: kaizen-shell is not running\n",
				Calls:  []string{showLine, niriLine, portalLine},
			},
		},
		{
			name:  "quickshell replaced in the Nix store",
			env:   map[string]string{"PATH": "$DIR/bin"},
			files: map[string]string{coreRequires: ""},
			execs: []string{"bin/nix-store", "store/qs-new/bin/quickshell"},
			links: map[string]string{
				"bin/quickshell": "$DIR/store/qs-new/bin/quickshell",
				"proc/4242/exe":  "/nix/store/qs-old/bin/quickshell",
			},
			outputs: map[string][]recorded{
				showLine: {{Stdout: unitBlock("kaizen-shell.service", "", "active", "success", "4242", "0", "")}},
				"nix-store -qR $DIR/store/qs-new/bin/quickshell": {{Stdout: "/nix/store/glibc\n/nix/store/qs-new\n"}},
				niriLine:   {{}},
				portalLine: {{}},
			},
			want: result{
				Stdout: "1 warning\n\nWARN  kaizen-shell  check\n" +
					"  runs a Quickshell that is no longer installed\n  hint: kaizen reload --restart\n",
				Calls: []string{showLine, "nix-store -qR $DIR/store/qs-new/bin/quickshell", niriLine, portalLine},
			},
		},
		{
			name:  "quickshell current in the Nix store",
			env:   map[string]string{"PATH": "$DIR/bin"},
			files: map[string]string{coreRequires: ""},
			execs: []string{"bin/nix-store", "store/qs-new/bin/quickshell"},
			links: map[string]string{
				"bin/quickshell": "$DIR/store/qs-new/bin/quickshell",
				"proc/4242/exe":  "/nix/store/qs-new/bin/quickshell",
			},
			outputs: map[string][]recorded{
				showLine: {{Stdout: unitBlock("kaizen-shell.service", "", "active", "success", "4242", "0", "")}},
				"nix-store -qR $DIR/store/qs-new/bin/quickshell": {{Stdout: "/nix/store/glibc\n/nix/store/qs-new\n"}},
				niriLine:   {{}},
				portalLine: {{}},
			},
			want: result{
				Stdout: "No errors or warnings\n",
				Calls:  []string{showLine, "nix-store -qR $DIR/store/qs-new/bin/quickshell", niriLine, portalLine},
			},
		},
		{
			name:  "quickshell outside the Nix store",
			env:   map[string]string{"PATH": "$DIR/bin"},
			files: map[string]string{coreRequires: ""},
			execs: []string{"bin/nix-store", "bin/quickshell"},
			links: map[string]string{"proc/4242/exe": "/usr/bin/quickshell (deleted)"},
			outputs: map[string][]recorded{
				showLine:   {{Stdout: unitBlock("kaizen-shell.service", "", "active", "success", "4242", "0", "")}},
				niriLine:   {{}},
				portalLine: {{}},
			},
			want: result{
				Stdout: "1 warning\n\nWARN  kaizen-shell  check\n" +
					"  runs a Quickshell that is no longer installed\n  hint: kaizen reload --restart\n",
				Calls: []string{showLine, niriLine, portalLine},
			},
		},
		{
			name:  "gsr-kms-server without cap_sys_admin",
			env:   map[string]string{"PATH": "$DIR/bin"},
			files: map[string]string{coreRequires: ""},
			execs: []string{"bin/gsr-kms-server"},
			outputs: map[string][]recorded{
				showLine:   {{Stdout: unitBlock("kaizen-shell.service", "", "active", "success", "0", "0", "")}},
				niriLine:   {{}},
				portalLine: {{}},
			},
			want: result{
				Stdout: "1 warning\n\nWARN  gpu-screen-recorder  check\n" +
					"  $DIR/bin/gsr-kms-server lacks cap_sys_admin+ep\n" +
					"  hint: sudo setcap cap_sys_admin+ep $DIR/bin/gsr-kms-server\n",
				Calls: []string{showLine, niriLine, portalLine},
			},
		},
		{
			name:  "check as JSON",
			args:  []string{"--json"},
			files: map[string]string{coreRequires: ""},
			links: map[string]string{"proc/4242/exe": "/usr/bin/quickshell (deleted)"},
			outputs: map[string][]recorded{
				showLine:   {{Stdout: unitBlock("kaizen-shell.service", "", "active", "success", "4242", "0", "")}},
				niriLine:   {{}},
				portalLine: {{}},
			},
			want: result{
				Stdout: fmt.Sprintf(
					`{"findings":[{"source":"check","id":"stale-shell","level":"WARN","unit":"kaizen-shell",`+
						`"message":"runs a Quickshell that is no longer installed","hint":"kaizen reload --restart",`+
						`"count":1,"first":%[1]d,"last":%[1]d}],`+
						`"text":"1 warning\n\nWARN  kaizen-shell  check\n`+
						`  runs a Quickshell that is no longer installed\n  hint: kaizen reload --restart"}`+"\n",
					now.UnixMilli(),
				),
				Calls: []string{showLine, niriLine, portalLine},
			},
		},
		{
			name: "checks that cannot run",
			env:  map[string]string{"PATH": "$DIR/bin"},
			files: map[string]string{
				coreRequires:                            "cmd absent\n",
				"run/kaizen-shell.service.d/dev.conf/x": "",
				"home/.config/kaizen/plugins":           "",
			},
			unreadable: []string{coreRequires},
			execs:      []string{"bin/nix-store", "store/qs-new/bin/quickshell", "bin/gsr-kms-server"},
			caps:       map[string]xattr{"bin/gsr-kms-server": {err: syscall.EACCES}},
			links: map[string]string{
				"bin/quickshell": "$DIR/store/qs-new/bin/quickshell",
				"proc/4242/exe":  "/nix/store/qs-old/bin/quickshell",
			},
			outputs: map[string][]recorded{
				showLine: {{Stdout: unitBlock(
					"kaizen-shell.service", "", "active", "success", "4242", "0",
					"$DIR/run/kaizen-shell.service.d/dev.conf",
				)}},
				"nix-store -qR $DIR/store/qs-new/bin/quickshell": {{Err: errors.New("exit status 1")}},
				niriLine:   {{Err: errors.New("exit status 1")}},
				portalLine: {{}},
			},
			want: result{
				Stdout: "6 errors\n\n" +
					"ERROR doctor  check\n  cannot check the shell's Quickshell: nix-store: exit status 1\n" +
					"ERROR niri  check\n  niri validate:\n  exit status 1\n" +
					"ERROR doctor  check\n  cannot read $DIR/bin/gsr-kms-server's capabilities: permission denied\n" +
					"ERROR doctor  check\n" +
					"  cannot read kaizen dev's drop-in: read $DIR/run/kaizen-shell.service.d/dev.conf: is a directory\n" +
					"ERROR doctor  check\n" +
					"  cannot check a requires file: open $DIR/home/.config/quickshell/kaizen/requires: permission denied\n" +
					"ERROR doctor  check\n" +
					"  cannot list the enabled plugins: open $DIR/home/.config/kaizen/plugins: not a directory\n",
				Calls: []string{showLine, "nix-store -qR $DIR/store/qs-new/bin/quickshell", niriLine, portalLine},
			},
		},
		{
			name: "niri config reaches kaizen.kdl through includes",
			env:  map[string]string{"NIRI_CONFIG": "$DIR/niri/main.kdl"},
			files: map[string]string{
				coreRequires:            "",
				"niri/main.kdl":         "// include \"kaizen.kdl\"\ninclude optional=true \"sub/host.kdl\"\n",
				"niri/sub/host.kdl":     "include \"~/shell/kaizen.kdl\"\n",
				"home/shell/kaizen.kdl": "",
			},
			outputs: map[string][]recorded{
				showLine:   {{Stdout: unitBlock("kaizen-shell.service", "", "active", "success", "0", "0", "")}},
				niriLine:   {{}},
				portalLine: {{}},
			},
			want: result{
				Stdout: "No errors or warnings\n",
				Calls:  []string{showLine, niriLine, portalLine},
			},
		},
		{
			name: "niri config without kaizen.kdl",
			files: map[string]string{
				coreRequires: "",
				niriConfig: "// include \"kaizen.kdl\"\ninclude optional=true \"gone/kaizen.kdl\"\n" +
					"include \"apps.kdl\"\n",
				"home/.config/niri/apps.kdl": "include \"apps.kdl\"\n",
			},
			outputs: map[string][]recorded{
				showLine:   {{Stdout: unitBlock("kaizen-shell.service", "", "active", "success", "0", "0", "")}},
				niriLine:   {{}},
				portalLine: {{}},
			},
			want: result{
				Stdout: "1 error\n\nERROR niri  check\n" +
					"  $DIR/home/.config/niri/config.kdl does not include kaizen.kdl\n" +
					"  hint: add include \"kaizen.kdl\" to $DIR/home/.config/niri/config.kdl\n",
				Calls: []string{showLine, niriLine, portalLine},
			},
		},
		{
			name:  "invalid niri config without kaizen.kdl",
			files: map[string]string{coreRequires: "", niriConfig: "bad\n"},
			outputs: map[string][]recorded{
				showLine:   {{Stdout: unitBlock("kaizen-shell.service", "", "active", "success", "0", "0", "")}},
				niriLine:   {{Err: errors.New("exit status 1")}},
				portalLine: {{}},
			},
			want: result{
				Stdout: "1 error\n\nERROR niri  check\n  niri validate:\n  exit status 1\n",
				Calls:  []string{showLine, niriLine, portalLine},
			},
		},
		{
			name:  "no compositor named",
			env:   map[string]string{"KAIZEN_COMPOSITOR": ""},
			files: map[string]string{coreRequires: ""},
			outputs: map[string][]recorded{
				showLine:   {{Stdout: unitBlock("kaizen-shell.service", "", "active", "success", "0", "0", "")}},
				portalLine: {{}},
			},
			want: result{
				Stdout: "1 error\n\nERROR compositor  check\n" +
					"  KAIZEN_COMPOSITOR names no compositor: it is unset\n" +
					"  hint: start the session with kaizen run; over SSH, copy it from systemctl --user show-environment\n",
				Calls: []string{showLine, portalLine},
			},
		},
		{
			name: "umbriel config, niri config without kaizen.kdl",
			env:  map[string]string{"KAIZEN_COMPOSITOR": "umbriel"},
			files: map[string]string{
				coreRequires:                       "",
				niriConfig:                         "include \"apps.kdl\"\n",
				umbrielConfig:                      "[include]\nfiles = [\"kaizen.toml\"]\n",
				"home/.config/umbriel/kaizen.toml": "",
			},
			outputs: map[string][]recorded{
				showLine:    {{Stdout: unitBlock("kaizen-shell.service", "", "active", "success", "0", "0", "")}},
				umbrielLine: {{}},
				portalLine:  {{}},
			},
			want: result{
				Stdout: "No errors or warnings\n",
				Calls:  []string{showLine, umbrielLine, portalLine},
			},
		},
		{
			name: "umbriel config reaches kaizen.toml through includes",
			env: map[string]string{
				"KAIZEN_COMPOSITOR": "umbriel",
				"XDG_CONFIG_HOME":   "$DIR/cfg",
				"SHELL_DIR":         "$DIR/home/shell",
			},
			files: map[string]string{
				"cfg/quickshell/kaizen/requires": "",
				"cfg/umbriel/config.toml": "[include]\nfiles = [\n  \"apps.toml\", # \"kaizen.toml\"\n]\n\n" +
					"[include . optional]\nfiles = [\"sub/host.toml\"]\n",
				"cfg/umbriel/apps.toml":     "",
				"cfg/umbriel/sub/host.toml": "[include]\nfiles = ['${SHELL_DIR}/kaizen.toml']\n",
				"home/shell/kaizen.toml":    "",
			},
			outputs: map[string][]recorded{
				showLine:    {{Stdout: unitBlock("kaizen-shell.service", "", "active", "success", "0", "0", "")}},
				umbrielLine: {{}},
				portalLine:  {{}},
			},
			want: result{
				Stdout: "No errors or warnings\n",
				Calls:  []string{showLine, umbrielLine, portalLine},
			},
		},
		{
			name: "umbriel config without kaizen.toml",
			env:  map[string]string{"KAIZEN_COMPOSITOR": "umbriel"},
			files: map[string]string{
				coreRequires: "",
				umbrielConfig: "# [include]\n# files = [\"kaizen.toml\"]\n[general]\nfiles = [\"kaizen.toml\"]\n" +
					"[include]\nfiles = [\"apps.toml\", \"gone/kaizen.toml\"]\n",
				"home/.config/umbriel/apps.toml":   "[include]\nfiles = [\"apps.toml\"]\n",
				"home/.config/umbriel/kaizen.toml": "",
			},
			outputs: map[string][]recorded{
				showLine:    {{Stdout: unitBlock("kaizen-shell.service", "", "active", "success", "0", "0", "")}},
				umbrielLine: {{}},
				portalLine:  {{}},
			},
			want: result{
				Stdout: "1 error\n\nERROR umbriel  check\n" +
					"  $DIR/home/.config/umbriel/config.toml does not include kaizen.toml\n" +
					"  hint: add \"kaizen.toml\" to [include] files in $DIR/home/.config/umbriel/config.toml\n",
				Calls: []string{showLine, umbrielLine, portalLine},
			},
		},
		{
			name:  "invalid umbriel config",
			env:   map[string]string{"KAIZEN_COMPOSITOR": "umbriel"},
			files: map[string]string{coreRequires: ""},
			outputs: map[string][]recorded{
				showLine: {{Stdout: unitBlock("kaizen-shell.service", "", "active", "success", "0", "0", "")}},
				umbrielLine: {{Err: &exec.ExitError{
					Stderr: []byte("error: config.toml:3: unknown key 'gaps'\nconfiguration invalid\n"),
				}}},
				portalLine: {{}},
			},
			want: result{
				Stdout: "1 error\n\nERROR umbriel  check\n  umbriel config validate:\n" +
					"  error: config.toml:3: unknown key 'gaps'\n  configuration invalid\n",
				Calls: []string{showLine, umbrielLine, portalLine},
			},
		},
		{
			name: "dev drop-in without a tree",
			files: map[string]string{
				coreRequires:                          "",
				"run/kaizen-shell.service.d/dev.conf": "[Service]\nExecStart=\n",
			},
			outputs: map[string][]recorded{
				showLine: {{Stdout: unitBlock(
					"kaizen-shell.service", "", "active", "success", "0", "0",
					"$DIR/run/kaizen-shell.service.d/dev.conf",
				)}},
				niriLine:   {{}},
				portalLine: {{}},
			},
			want: result{
				Stdout: "1 warning\n\nWARN  kaizen-shell  check\n" +
					"  runs a tree $DIR/run/kaizen-shell.service.d/dev.conf does not name\n  hint: kaizen dev off\n",
				Calls: []string{showLine, niriLine, portalLine},
			},
		},
		{
			name: "journalctl arguments",
			args: []string{"-b", "--json", "-1"},
			outputs: map[string][]recorded{
				bootLine + " -b -1": {{Stdout: logLine(5, binding) + logLine(65, binding)}},
			},
			want: result{
				Stdout: fmt.Sprintf(
					`{"findings":[{"source":"log","id":"log","level":"WARN","unit":"kaizen-shell",`+
						`"message":"WARN scene: Binding loop","count":2,"first":%d,"last":%d}],`+
						`"text":"1 warning\n\nWARN  kaizen-shell  ×2  11:00:05–11:01:05\n  WARN scene: Binding loop"}`+"\n",
					base.Add(5*time.Second).UnixMilli(),
					base.Add(65*time.Second).UnixMilli(),
				),
				Calls: []string{bootLine + " -b -1"},
			},
		},
		{
			name:    "systemctl fails",
			outputs: map[string][]recorded{showLine: {{Err: errors.New("exit status 1")}}},
			want: result{
				Code:   1,
				Stderr: "kaizen doctor: systemctl: exit status 1\n",
				Calls:  []string{showLine},
			},
		},
		{
			name: "journal unreadable",
			args: []string{"--since", "-1h"},
			outputs: map[string][]recorded{
				bootLine + " --since -1h": {{Stdout: `{"MESSAGE":"x","PRIORITY":"high"}` + "\n"}},
			},
			want: result{
				Code:   1,
				Stderr: "kaizen doctor: journalctl: PRIORITY: strconv.Atoi: parsing \"high\": invalid syntax\n",
				Calls:  []string{bootLine + " --since -1h"},
			},
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			if len(tt.unreadable) > 0 && os.Geteuid() == 0 {
				t.Skip("root reads any file")
			}
			dir := t.TempDir()
			expand := func(s string) string { return strings.ReplaceAll(s, "$DIR", dir) }
			files := map[string]string{niriConfig: "include \"kaizen.kdl\"\n", "home/.config/niri/kaizen.kdl": ""}
			maps.Copy(files, tt.files)
			for path, content := range files {
				write(t, filepath.Join(dir, path), expand(content), 0o644)
			}
			for _, path := range tt.unreadable {
				assert.NilError(t, os.Chmod(filepath.Join(dir, path), 0))
			}
			for _, path := range tt.execs {
				write(t, filepath.Join(dir, path), "#!/bin/sh\n", 0o755)
			}
			for path, target := range tt.links {
				assert.NilError(t, os.MkdirAll(filepath.Dir(filepath.Join(dir, path)), 0o755))
				assert.NilError(t, os.Symlink(expand(target), filepath.Join(dir, path)))
			}
			env := map[string]string{"HOME": "$DIR/home", "PATH": "$DIR/empty", "KAIZEN_COMPOSITOR": "niri"}
			maps.Copy(env, tt.env)
			outputs := map[string][]recorded{}
			for line, outs := range tt.outputs {
				for _, out := range outs {
					outputs[expand(line)] = append(outputs[expand(line)], recorded{Stdout: expand(out.Stdout), Err: out.Err})
				}
			}
			caps := map[string]xattr{}
			for path, x := range tt.caps {
				caps[filepath.Join(dir, path)] = x
			}
			runner := &seqRunner{outputs: outputs}
			c := Command{
				Runner:     runner,
				Compositor: compositor.FromEnv(func(key string) string { return expand(env[key]) }, runner),
				Home:       expand(env["HOME"]),
				Getenv:     func(key string) string { return expand(env[key]) },
				now:        func() time.Time { return now },
				location:   time.UTC,
				proc:       filepath.Join(dir, "proc"),
				getxattr: func(path, attr string) ([]byte, error) {
					x, ok := caps[path]
					if !ok || attr != "security.capability" {
						return nil, syscall.ENODATA
					}
					return x.value, x.err
				},
			}
			var stdout, stderr bytes.Buffer

			code := c.Run(t.Context(), tt.args, &stdout, &stderr)

			unexpand := func(s string) string { return strings.ReplaceAll(s, dir, "$DIR") }
			got := result{Code: code, Stdout: unexpand(stdout.String()), Stderr: unexpand(stderr.String())}
			for _, call := range runner.calls {
				got.Calls = append(got.Calls, unexpand(call))
			}
			assert.DeepEqual(t, got, tt.want)
		})
	}
}

// write writes content to path with mode, creating its directory.
func write(t *testing.T, path, content string, mode os.FileMode) {
	t.Helper()
	assert.NilError(t, os.MkdirAll(filepath.Dir(path), 0o755))
	assert.NilError(t, os.WriteFile(path, []byte(content), mode))
}

func TestSysAdmin(t *testing.T) {
	for _, tt := range []struct {
		name string
		data []byte
		want bool
	}{
		{name: "permitted and effective", data: vfsCap(capRevision2|capEffective, setpcapSysAdmin, 20), want: true},
		{name: "revision 3", data: vfsCap(capRevision3|capEffective, 1<<21, 24), want: true},
		{name: "permitted only", data: vfsCap(capRevision2, setpcapSysAdmin, 20)},
		{name: "other capabilities", data: vfsCap(capRevision2|capEffective, 1<<8, 20)},
		{name: "truncated", data: vfsCap(capRevision2|capEffective, setpcapSysAdmin, 20)[:6]},
		{name: "none"},
	} {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, sysAdmin(tt.data), tt.want)
		})
	}
}

func TestJoinDBusErrors(t *testing.T) {
	const (
		updating    = "  WARN quickshell.dbus.properties: Error updating property org.mpris.MediaPlayer2.x:Position"
		dbusError   = `  WARN quickshell.dbus.properties: QDBusError("org.freedesktop.DBus.Error.`
		failed      = dbusError + `Failed", "boom")`
		unknown     = dbusError + `ServiceUnknown", "The name is not activatable")`
		noObject    = dbusError + `UnknownMethod", "Object does not exist at path “/x”")`
		noMethod    = dbusError + `UnknownMethod", "No such method 'Get'")`
		bindingLoop = "  WARN scene: Binding loop"
	)
	for _, tt := range []struct {
		name    string
		entries []state.Entry
		want    []state.Entry
	}{
		{
			name:    "error joined to its call",
			entries: []state.Entry{{Message: updating, PID: "10"}, {Message: failed, PID: "10"}},
			want:    []state.Entry{{Message: updating + "\n" + strings.TrimSpace(failed), PID: "10"}},
		},
		{
			name:    "unknown method joined to its call",
			entries: []state.Entry{{Message: updating, PID: "10"}, {Message: noMethod, PID: "10"}},
			want:    []state.Entry{{Message: updating + "\n" + strings.TrimSpace(noMethod), PID: "10"}},
		},
		{
			name: "peer gone",
			entries: []state.Entry{
				{Message: bindingLoop, PID: "10"},
				{Message: updating, PID: "10"}, {Message: noObject, PID: "10"},
				{Message: updating, PID: "10"}, {Message: unknown, PID: "10"},
			},
			want: []state.Entry{{Message: bindingLoop, PID: "10"}},
		},
		{
			name:    "peer gone without its call",
			entries: []state.Entry{{Message: unknown, PID: "10"}},
			want:    []state.Entry{},
		},
		{
			name:    "error after another process's line",
			entries: []state.Entry{{Message: updating, PID: "10"}, {Message: failed, PID: "11"}},
			want:    []state.Entry{{Message: updating, PID: "10"}, {Message: failed, PID: "11"}},
		},
		{
			name:    "error first",
			entries: []state.Entry{{Message: failed, PID: "10"}},
			want:    []state.Entry{{Message: failed, PID: "10"}},
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			assert.DeepEqual(t, joinDBusErrors(tt.entries), tt.want)
		})
	}
}

func TestSeverity(t *testing.T) {
	for _, tt := range []struct {
		name  string
		entry state.Entry
		want  string
	}{
		{name: "quickshell warning", entry: state.Entry{Message: "  WARN scene: Binding loop", Priority: 6}, want: "WARN"},
		{name: "quickshell error", entry: state.Entry{Message: " ERROR: Failed to load", Priority: 6}, want: "ERROR"},
		{name: "quickshell fatal", entry: state.Entry{Message: " FATAL: crashed", Priority: 6}, want: "ERROR"},
		{name: "quickshell info", entry: state.Entry{Message: "  INFO: Configuration Loaded", Priority: 6}},
		{name: "debug at error priority", entry: state.Entry{Message: " DEBUG x", Priority: 3}, want: "ERROR"},
		{name: "info at warning priority", entry: state.Entry{Message: "  INFO x", Priority: 4}, want: "WARN"},
		{name: "word", entry: state.Entry{Message: "error: boom", Priority: 6}, want: "ERROR"},
		{name: "word after a word", entry: state.Entry{Message: "systray Warning: icon", Priority: 6}, want: "WARN"},
		{name: "go log timestamp", entry: state.Entry{Message: "2026/10/11 10:00:00 dcal crit: x", Priority: 6}, want: "ERROR"},
		{name: "panic", entry: state.Entry{Message: "panic: nil map", Priority: 6}, want: "ERROR"},
		{name: "word too late", entry: state.Entry{Message: "a b error: x", Priority: 6}},
		{name: "word inside a word", entry: state.Entry{Message: "errors: none", Priority: 6}},
		{name: "slog warning", entry: state.Entry{Message: "time=2026-10-11T10:00:00Z level=WARN msg=x", Priority: 6}, want: "WARN"},
		{name: "slog error", entry: state.Entry{Message: "level=error msg=x", Priority: 6}, want: "ERROR"},
		{name: "slog info", entry: state.Entry{Message: "time=x level=INFO msg=x", Priority: 6}},
		{name: "systemd error", entry: state.Entry{Message: "Failed to start x.", Priority: 3}, want: "ERROR"},
		{name: "systemd warning", entry: state.Entry{Message: "x: Failed with result 'exit-code'.", Priority: 4}, want: "WARN"},
		{name: "notice", entry: state.Entry{Message: "Started x.", Priority: 5}},
	} {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, severity(tt.entry), tt.want)
		})
	}
}
