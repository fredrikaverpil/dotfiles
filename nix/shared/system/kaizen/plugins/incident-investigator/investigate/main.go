// Command investigate runs Claude Code investigations of alerts. `investigate serve` is the daemon that
// owns the runs and their state; the other verbs are its clients.
package main

import (
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

	"investigate/internal/claude"
)

const usage = `usage: investigate <verb> [args]

  serve -plugin-dir DIR -config FILE [-instructions FILE]... [-source-dir DIR]... [-tool-path PATH]
        [-go-mod-cache DIR]
                                 run the daemon with the Claude Code profile CLAUDE_CONFIG_DIR, in STATE_DIRECTORY;
                                 the plugin dir serves gopls, the config holds the tags and entity patterns,
                                 the instructions are appended to the system prompt,
                                 the source dirs hold the repositories runs may read,
                                 the tool path (go, gopls) and module cache serve their LSP
  draft [-tag T]                 create a draft from NOTIFICATION_* and INVESTIGATE_TAG, show it in the window
  edit ID [-projects P,Q] [-tag T] [-trace-id T] [-notes N]
                                 set a draft's fields; omitted ones are cleared
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
		var cfg config
		appendTo := func(list *[]string) func(string) error {
			return func(v string) error { *list = append(*list, v); return nil }
		}
		flags := flag.NewFlagSet("serve", flag.ContinueOnError)
		flags.StringVar(&cfg.pluginDir, "plugin-dir", "", "Claude plugin serving gopls")
		configFile := flags.String("config", "", "JSON file with the tags and entity patterns")
		flags.Func("instructions", "file appended to the system prompt; repeatable", appendTo(&cfg.instructionFiles))
		flags.Func("source-dir", "directory of repositories the runs may read; repeatable", appendTo(&cfg.sourceDirs))
		flags.StringVar(&cfg.toolPath, "tool-path", "", "directories with go and gopls, first on the runs' PATH")
		flags.StringVar(&cfg.goModCache, "go-mod-cache", "", "Go module cache the runs may read")
		if err := flags.Parse(args); err != nil {
			return err
		}
		if cfg.pluginDir == "" || *configFile == "" {
			return errUsage
		}
		// Set by the unit: the profile is chosen per host, and systemd creates the state directory.
		cfg.claudeConfigDir = os.Getenv("CLAUDE_CONFIG_DIR")
		state := os.Getenv("STATE_DIRECTORY")
		if cfg.claudeConfigDir == "" || state == "" {
			return errors.New("serve: CLAUDE_CONFIG_DIR and STATE_DIRECTORY must be set")
		}
		var err error
		if cfg.tags, cfg.entityPatterns, err = readConfig(*configFile); err != nil {
			return err
		}
		ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
		defer stop()
		logger := slog.New(slog.NewTextHandler(os.Stderr, nil))
		return serve(ctx, logger, socket, state, cfg)
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

// readConfig reads the -config file: the tags, and the entity patterns besides the built-in ones.
func readConfig(path string) ([]Tag, []claude.EntityPattern, error) {
	var file struct {
		Tags           []Tag `json:"tags"`
		EntityPatterns []struct {
			Kind  string `json:"kind"`
			Regex string `json:"regex"`
		} `json:"entityPatterns"`
	}
	// Never null in settings.json.
	file.Tags = []Tag{}
	if err := readJSON(path, &file); err != nil {
		return nil, nil, err
	}
	patterns := slices.Clone(claude.EntityPatterns)
	for _, p := range file.EntityPatterns {
		re, err := regexp.Compile(p.Regex)
		if err != nil {
			return nil, nil, fmt.Errorf("entity pattern: %v", err)
		}
		if re.NumSubexp() == 0 {
			return nil, nil, fmt.Errorf("entity pattern %q: want a group around the id", p.Regex)
		}
		patterns = append(patterns, claude.EntityPattern{Kind: p.Kind, Regexp: re})
	}
	return file.Tags, patterns, nil
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
	// `qs ipc call <target> show` is parsed as the CLI's own `show`.
	return callWindow("reveal", id)
}

// callWindow runs a function of the window's IPC handler. The daemon's unit has no WAYLAND_DISPLAY, so instances
// are not filtered by display.
func callWindow(function string, args ...string) error {
	cmd := append([]string{"ipc", "--any-display", "call", "incident-investigator", function}, args...)
	if out, err := exec.Command("qs", cmd...).CombinedOutput(); err != nil {
		return fmt.Errorf("qs ipc call %s: %v: %s", function, err, out)
	}
	return nil
}
