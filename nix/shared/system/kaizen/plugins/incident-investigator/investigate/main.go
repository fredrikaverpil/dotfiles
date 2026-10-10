// Command investigate runs Claude Code investigations of alerts. `investigate serve` is the daemon that
// owns the runs and their state; the other verbs are its clients.
package main

import (
	"bytes"
	"cmp"
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"log/slog"
	"net"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"regexp"
	"slices"
	"strconv"
	"strings"
	"syscall"

	"github.com/tailscale/hujson"

	"investigate/internal/claude"
)

const usage = `usage: investigate <verb> [args]

  serve [-config FILE] [-dir DIR] [-tool-path PATH] [-go-mod-cache DIR]
                                 run the daemon in STATE_DIRECTORY; the config (JSONC, default
                                 ~/.config/kaizen/plugins/incident-investigator.jsonc) holds the Claude Code profile,
                                 source dirs, instruction files, tags and entity patterns, the plugin's dir (default
                                 ~/.config/quickshell/kaizen/plugins/incident-investigator) its instructions.md and the
                                 claude-plugin/ serving gopls, and the tool path (go, gopls) and module cache
                                 (default: go env GOMODCACHE) serve the LSP
  draft [-tag T]                 create a draft from NOTIFICATION_* and INVESTIGATE_TAG, show it in the window;
                                 a failure shows a notification
  edit ID [-projects P,Q] [-tag T] [-trace-id T] [-notes N]
                                 set a draft's fields; omitted ones are cleared
  tag ID [T]                     set the tag of an investigation in any status; none clears it
  start ID...                    run investigations, or re-run finished ones
  followup ID TEXT               ask a follow-up in an investigation's session
  combine ID ID...               draft an investigation from finished ones, show it in the window
  branch ID INDEX TEXT           replay an investigation from its INDEXth message, edited to TEXT, as a new one
  settings [-model M] [-effort E]
                                 set the model and effort that runs start with; omitted ones are kept
  cancel ID...                   stop running investigations
  delete ID...                   remove investigations and their files
  checkout DIR/REPO COMMIT       unpack a source repository at COMMIT into the run's directory; run by Claude`

var errUsage = errors.New(usage)

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "investigate:", err)
		os.Exit(1)
	}
}

func run(args []string) error {
	if len(args) == 0 {
		return errUsage
	}
	runtimeDir, ok := os.LookupEnv("XDG_RUNTIME_DIR")
	if !ok {
		return errors.New("XDG_RUNTIME_DIR is not set")
	}
	socket := filepath.Join(runtimeDir, "kaizen-incident-investigator.sock")
	verb, args := args[0], args[1:]
	switch verb {
	case "serve":
		// `kaizen log` lists the unit's warnings and errors by journal priority.
		logger := slog.New(newJournalHandler(os.Stderr, nil))
		if err := runServe(logger, socket, args); err != nil {
			logger.Error("serve", "error", err)
			return err
		}
		return nil
	case "draft":
		flags := flag.NewFlagSet("draft", flag.ContinueOnError)
		tag := flags.String("tag", "", "tag; overrides INVESTIGATE_TAG")
		if err := flags.Parse(args); err != nil {
			return err
		}
		req := request{Verb: verb, Tag: cmp.Or(*tag, os.Getenv("INVESTIGATE_TAG"))}
		if app, ok := os.LookupEnv("NOTIFICATION_APP"); ok {
			req.Alert = &Alert{App: app, Summary: os.Getenv("NOTIFICATION_SUMMARY"), Body: os.Getenv("NOTIFICATION_BODY")}
		}
		id, err := call(socket, req)
		if err != nil {
			// A notification's button runs draft detached, so nothing else shows the error.
			_ = exec.Command(
				"notify-send", "--app-name", "Incident investigator", "--urgency", "critical",
				"Investigation not drafted", err.Error(),
			).Run()
			return err
		}
		fmt.Println(id)
		// The draft exists even when the window cannot show it.
		if err := show(id); err != nil {
			fmt.Fprintln(os.Stderr, "investigate:", err)
		}
		return nil
	case "checkout":
		if len(args) != 2 {
			return errUsage
		}
		sourceDirs := filepath.SplitList(os.Getenv("INVESTIGATE_SOURCE_DIRS"))
		dir, err := checkout(sourceDirs, os.Getenv("INVESTIGATE_RUN_DIR"), args[0], args[1])
		if err != nil {
			return err
		}
		fmt.Println(dir)
		return nil
	case "edit":
		if len(args) == 0 {
			return errUsage
		}
		flags := flag.NewFlagSet("edit", flag.ContinueOnError)
		projects := flags.String("projects", "", "comma-separated GCP project ids")
		tag := flags.String("tag", "", "tag")
		traceID := flags.String("trace-id", "", "trace id")
		notes := flags.String("notes", "", "notes for Claude")
		if err := flags.Parse(args[1:]); err != nil {
			return err
		}
		_, err := call(
			socket,
			request{
				Verb:     verb,
				ID:       args[0],
				Tag:      *tag,
				Projects: strings.Split(*projects, ","),
				TraceID:  *traceID,
				Notes:    *notes,
			},
		)
		return err
	case "tag":
		if len(args) < 1 || len(args) > 2 {
			return errUsage
		}
		req := request{Verb: verb, ID: args[0]}
		if len(args) == 2 {
			req.Tag = args[1]
		}
		_, err := call(socket, req)
		return err
	case "combine", "branch":
		req := request{Verb: verb}
		switch {
		case verb == "combine" && len(args) >= 2:
			req.IDs = args
		case verb == "branch" && len(args) == 3:
			index, err := strconv.Atoi(args[1])
			if err != nil {
				return fmt.Errorf("branch: index: %v", err)
			}
			req.ID, req.Index, req.Text = args[0], index, args[2]
		default:
			return errUsage
		}
		id, err := call(socket, req)
		if err != nil {
			return err
		}
		fmt.Println(id)
		if err := show(id); err != nil {
			fmt.Fprintln(os.Stderr, "investigate:", err)
		}
		return nil
	case "settings":
		flags := flag.NewFlagSet("settings", flag.ContinueOnError)
		model := flags.String("model", "", "model")
		effort := flags.String("effort", "", "effort")
		if err := flags.Parse(args); err != nil {
			return err
		}
		_, err := call(socket, request{Verb: verb, Model: *model, Effort: *effort})
		return err
	case "followup":
		if len(args) != 2 {
			return errUsage
		}
		_, err := call(socket, request{Verb: verb, ID: args[0], Text: args[1]})
		return err
	case "start", "cancel", "delete":
		if len(args) == 0 {
			return errUsage
		}
		for _, id := range args {
			if _, err := call(socket, request{Verb: verb, ID: id}); err != nil {
				return err
			}
		}
		return nil
	}
	return errUsage
}

// runServe reads serve's flags and config, then runs the daemon until it is stopped.
func runServe(logger *slog.Logger, socket string, args []string) error {
	configDir, err := os.UserConfigDir()
	if err != nil {
		return err
	}
	flags := flag.NewFlagSet("serve", flag.ContinueOnError)
	configFile := flags.String(
		"config",
		filepath.Join(configDir, "kaizen", "plugins", "incident-investigator.jsonc"),
		"JSONC file with the profile, source dirs, instruction files, tags and entity patterns",
	)
	dir := flags.String(
		"dir",
		filepath.Join(configDir, "quickshell", "kaizen", "plugins", "incident-investigator"),
		"the plugin's directory, with instructions.md and claude-plugin/",
	)
	toolPath := flags.String("tool-path", "", "directories with go and gopls, first on the runs' PATH")
	goModCache := flags.String("go-mod-cache", "", "Go module cache the runs may read")
	if err := flags.Parse(args); err != nil {
		return err
	}
	// Set by the unit: systemd creates the state directory.
	state := os.Getenv("STATE_DIRECTORY")
	if state == "" {
		return errors.New("serve: STATE_DIRECTORY must be set")
	}
	cfg, err := readConfig(*configFile)
	if err != nil {
		return err
	}
	cfg.pluginDir = filepath.Join(*dir, "claude-plugin")
	cfg.instructionFiles = append([]string{filepath.Join(*dir, "instructions.md")}, cfg.instructionFiles...)
	cfg.toolPath, cfg.goModCache = *toolPath, *goModCache
	if cfg.goModCache == "" && len(cfg.sourceDirs) > 0 {
		// Without it, only definitions in other modules fail.
		if out, err := exec.Command("go", "env", "GOMODCACHE").Output(); err == nil {
			cfg.goModCache = strings.TrimSpace(string(out))
		}
	}
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	return serve(ctx, logger, socket, state, cfg)
}

// readConfig reads the -config file: the profile, the source dirs, the instruction files after the plugin's own,
// the tags, and the entity patterns besides the built-in ones. A path is absolute or starts with ~/.
func readConfig(path string) (config, error) {
	var file struct {
		ClaudeConfigDir  string   `json:"claudeConfigDir"`
		SourceDirs       []string `json:"sourceDirs"`
		InstructionFiles []string `json:"instructionFiles"`
		Tags             []Tag    `json:"tags"`
		EntityPatterns   []struct {
			Kind  string `json:"kind"`
			Regex string `json:"regex"`
		} `json:"entityPatterns"`
	}
	// Never null in settings.json.
	file.Tags = []Tag{}
	if err := readJSONC(path, &file); err != nil {
		return config{}, err
	}
	if file.ClaudeConfigDir == "" {
		return config{}, fmt.Errorf("%s: claudeConfigDir is required", path)
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return config{}, err
	}
	expand := func(p string) (string, error) {
		if rest, ok := strings.CutPrefix(p, "~/"); ok {
			return filepath.Join(home, rest), nil
		}
		if !filepath.IsAbs(p) {
			return "", fmt.Errorf("%s: path %q: want an absolute path or ~/", path, p)
		}
		return p, nil
	}
	cfg := config{tags: file.Tags, entityPatterns: slices.Clone(claude.EntityPatterns)}
	if cfg.claudeConfigDir, err = expand(file.ClaudeConfigDir); err != nil {
		return config{}, err
	}
	for _, list := range []struct{ from, to *[]string }{
		{&file.SourceDirs, &cfg.sourceDirs},
		{&file.InstructionFiles, &cfg.instructionFiles},
	} {
		for _, p := range *list.from {
			expanded, err := expand(p)
			if err != nil {
				return config{}, err
			}
			*list.to = append(*list.to, expanded)
		}
	}
	for _, p := range file.EntityPatterns {
		re, err := regexp.Compile(p.Regex)
		if err != nil {
			return config{}, fmt.Errorf("entity pattern: %v", err)
		}
		if re.NumSubexp() == 0 {
			return config{}, fmt.Errorf("entity pattern %q: want a group around the id", p.Regex)
		}
		cfg.entityPatterns = append(cfg.entityPatterns, claude.EntityPattern{Kind: p.Kind, Regexp: re})
	}
	return cfg, nil
}

// readJSONC reads JSON that may hold comments and trailing commas. An unknown field is an error.
func readJSONC(path string, v any) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	if data, err = hujson.Standardize(data); err != nil {
		return fmt.Errorf("parse %s: %v", path, err)
	}
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(v); err != nil {
		return fmt.Errorf("parse %s: %v", path, err)
	}
	return nil
}

// request is one verb sent to the daemon; it answers with a response.
type request struct {
	Verb     string   `json:"verb"`
	ID       string   `json:"id,omitempty"`
	Tag      string   `json:"tag,omitempty"`
	Alert    *Alert   `json:"alert,omitempty"`
	Projects []string `json:"projects,omitempty"`
	TraceID  string   `json:"traceId,omitempty"`
	Notes    string   `json:"notes,omitempty"`
	Text     string   `json:"text,omitempty"`
	IDs      []string `json:"ids,omitempty"`
	Index    int      `json:"index,omitempty"`
	Model    string   `json:"model,omitempty"`
	Effort   string   `json:"effort,omitempty"`
}

type response struct {
	ID    string `json:"id,omitempty"`
	Error string `json:"error,omitempty"`
}

// call sends req to the daemon and returns the investigation id it answers with.
func call(socket string, req request) (string, error) {
	conn, err := net.Dial("unix", socket)
	if err != nil {
		return "", fmt.Errorf("connect to the daemon: %v", err)
	}
	defer func() { _ = conn.Close() }()
	if err := json.NewEncoder(conn).Encode(req); err != nil {
		return "", fmt.Errorf("send %s: %v", req.Verb, err)
	}
	var resp response
	if err := json.NewDecoder(conn).Decode(&resp); err != nil {
		return "", fmt.Errorf("read %s response: %v", req.Verb, err)
	}
	if resp.Error != "" {
		return "", errors.New(resp.Error)
	}
	return resp.ID, nil
}

// show selects an investigation in the window and opens it.
func show(id string) error {
	// `kaizen ipc call <target> show` is parsed as the CLI's own `show`.
	return callWindow("reveal", id)
}

// callWindow runs a function of the window's IPC handler. The daemon's unit has no WAYLAND_DISPLAY, so instances
// are not filtered by display.
func callWindow(function string, args ...string) error {
	cmd := append([]string{"ipc", "--any-display", "call", "incident-investigator", function}, args...)
	if out, err := exec.Command("kaizen", cmd...).CombinedOutput(); err != nil {
		return fmt.Errorf("kaizen ipc call %s: %v: %s", function, err, out)
	}
	return nil
}
