package main

import (
	"bufio"
	"bytes"
	"cmp"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"html"
	"io"
	"io/fs"
	"log/slog"
	"maps"
	"math/rand/v2"
	"net"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"slices"
	"strings"
	"sync"
	"syscall"
	"time"
	"uuid"

	"investigate/internal/claude"
)

// Investigation is the shape the window reads from index.json.
type Investigation struct {
	ID string `json:"id"`
	// Status is draft, running, done, failed or cancelled.
	Status    string `json:"status"`
	SessionID string `json:"sessionId"`
	// ClaudeConfigDir is the Claude Code profile the session is stored under.
	ClaudeConfigDir string   `json:"claudeConfigDir"`
	Projects        []string `json:"projects"`
	// Project is the single project older state files hold; load moves it to Projects.
	Project string `json:"project,omitempty"`
	// Tag is one of the configured tags, "" for none.
	Tag string `json:"tag"`
	// EnvHint is the tag older state files hold; load moves it to Tag.
	EnvHint string `json:"envHint,omitempty"`
	TraceID string `json:"traceId"`
	// Title is the report's heading, "" until a turn returns one.
	Title string `json:"title"`
	Notes string `json:"notes"`
	Alert *Alert `json:"alert"`
	// Model and Effort are what the last run started with; follow-ups continue with them. "" for a draft.
	Model  string `json:"model"`
	Effort string `json:"effort"`
	// Times are Unix milliseconds, 0 if unset.
	CreatedAt  int64            `json:"createdAt"`
	StartedAt  int64            `json:"startedAt"`
	FinishedAt int64            `json:"finishedAt"`
	CostUSD    float64          `json:"costUsd"`
	Error      string           `json:"error"`
	Messages   []claude.Message `json:"messages"`
	// Entities are the user and organization ids the tool output named.
	Entities []claude.Entity `json:"entities"`
}

// settings are the model and effort that the next run starts with, and the configured tags, for the window.
type settings struct {
	Model  string `json:"model"`
	Effort string `json:"effort"`
	Tags   []Tag  `json:"tags"`
}

// Tag is a label an investigation can carry; Color is a palette role.
type Tag struct {
	Name  string `json:"name"`
	Color string `json:"color"`
}

// Alert is the notification a draft was made from.
type Alert struct {
	App     string `json:"app"`
	Summary string `json:"summary"`
	Body    string `json:"body"`
}

// turn is a claude process; pid is 0 until it starts.
type turn struct {
	pid       int
	cancelled bool
}

// config is what the daemon runs with.
type config struct {
	pluginDir       string
	claudeConfigDir string
	// sourceDirs hold the repositories the services are built from; none gives runs no access to source.
	sourceDirs []string
	// instructionFiles are appended to the system prompt, read on each turn.
	instructionFiles []string
	// toolPath (go, gopls) goes first on the runs' PATH; goModCache is the module cache their gopls reads.
	toolPath, goModCache string
	tags                 []Tag
	// entityPatterns find the ids listed as entities.
	entityPatterns []claude.EntityPattern
}

type daemon struct {
	config
	logger *slog.Logger
	state  string

	// mu guards the fields below and the files under state.
	mu       sync.Mutex
	items    map[string]*Investigation
	turns    map[string]*turn
	projects []string
	settings settings
}

// serve answers requests on socket until ctx is done.
func serve(ctx context.Context, logger *slog.Logger, socket, state string, cfg config) error {
	d := &daemon{
		config: cfg,
		logger: logger,
		state:  state,
		items:  map[string]*Investigation{},
		turns:  map[string]*turn{},
	}
	if err := d.load(); err != nil {
		return err
	}
	// A crash leaves the socket behind, which blocks Listen.
	if err := os.Remove(socket); err != nil && !errors.Is(err, fs.ErrNotExist) {
		return fmt.Errorf("remove stale socket: %v", err)
	}
	listener, err := net.Listen("unix", socket)
	if err != nil {
		return fmt.Errorf("listen: %v", err)
	}
	context.AfterFunc(ctx, func() { _ = listener.Close() })
	logger.Info("serving", "socket", socket, "state", state)
	if err := d.showTray(ctx); err != nil {
		return err
	}
	for {
		conn, err := listener.Accept()
		if err != nil {
			if ctx.Err() != nil {
				return nil
			}
			return fmt.Errorf("accept: %v", err)
		}
		go d.handle(conn)
	}
}

// handle answers one request per connection.
func (d *daemon) handle(conn net.Conn) {
	defer func() { _ = conn.Close() }()
	id, err := d.do(conn)
	resp := response{ID: id}
	if err != nil {
		resp.Error = err.Error()
	}
	if err := json.NewEncoder(conn).Encode(resp); err != nil {
		d.logger.Warn("answer request", "error", err)
	}
}

func (d *daemon) do(r io.Reader) (string, error) {
	var req request
	if err := json.NewDecoder(r).Decode(&req); err != nil {
		return "", fmt.Errorf("read request: %v", err)
	}
	d.mu.Lock()
	defer d.mu.Unlock()
	switch req.Verb {
	case "draft":
		return d.draft(req)
	case "combine":
		return d.combine(req.IDs)
	case "settings":
		return "", d.setSettings(req)
	}
	inv, ok := d.items[req.ID]
	if !ok {
		return "", fmt.Errorf("no investigation %q", req.ID)
	}
	switch req.Verb {
	case "edit":
		return inv.ID, d.edit(inv, req)
	case "start":
		return inv.ID, d.start(inv)
	case "followup":
		return inv.ID, d.followup(inv, req.Text)
	case "branch":
		return d.branch(inv, req.Index, req.Text)
	case "cancel":
		return inv.ID, d.cancel(inv)
	case "delete":
		return inv.ID, d.remove(inv)
	}
	return "", fmt.Errorf("unknown verb %q", req.Verb)
}

func (d *daemon) draft(req request) (string, error) {
	if err := d.checkTag(req.Tag); err != nil {
		return "", err
	}
	inv := &Investigation{
		ID:        d.newID(),
		Status:    "draft",
		Tag:       req.Tag,
		Alert:     req.Alert,
		CreatedAt: now(),
		Projects:  []string{},
		Messages:  []claude.Message{},
		Entities:  []claude.Entity{},
	}
	if req.Alert != nil {
		if link, project := gcpAlertLink(req.Alert.Body); link != "" {
			inv.Notes = link
			if project != "" {
				inv.Projects = []string{project}
			}
		}
	}
	d.items[inv.ID] = inv
	return inv.ID, d.save(inv)
}

// gcpAlertLink is the first GCP alert or incident URL in text and its project, "" if none.
func gcpAlertLink(text string) (link, project string) {
	linkRE := regexp.MustCompile(
		`https://console\.cloud\.google\.com/monitoring/alerting/(?:incidents|alerts)/[^\s<>|)\]"']+`,
	)
	link = html.UnescapeString(linkRE.FindString(text))
	if u, err := url.Parse(link); err == nil {
		project = u.Query().Get("project")
	}
	return link, project
}

func (d *daemon) newID() string {
	for {
		id := fmt.Sprintf("%06x", rand.N(1<<24))
		if _, ok := d.items[id]; !ok {
			return id
		}
	}
}

// edit stores a draft's fields as typed; start trims them.
func (d *daemon) edit(inv *Investigation, req request) error {
	if inv.Status != "draft" {
		return fmt.Errorf("%s is %s; only a draft can be edited", inv.ID, inv.Status)
	}
	if err := d.checkTag(req.Tag); err != nil {
		return err
	}
	inv.Tag, inv.Projects, inv.TraceID, inv.Notes = req.Tag, cleanProjects(req.Projects), req.TraceID, req.Notes
	return d.save(inv)
}

// checkTag rejects a tag that is not configured; "" is none.
func (d *daemon) checkTag(tag string) error {
	if tag == "" || slices.ContainsFunc(d.tags, func(t Tag) bool { return t.Name == tag }) {
		return nil
	}
	names := make([]string, 0, len(d.tags))
	for _, t := range d.tags {
		names = append(names, t.Name)
	}
	return fmt.Errorf("tag %q: want one of %s", tag, strings.Join(names, ", "))
}

// start runs a draft, or re-runs a finished investigation in a new session.
func (d *daemon) start(inv *Investigation) error {
	if _, ok := d.turns[inv.ID]; ok {
		return fmt.Errorf("%s is already running", inv.ID)
	}
	inv.Projects, inv.TraceID = cleanProjects(inv.Projects), strings.TrimSpace(inv.TraceID)
	notes := strings.TrimSpace(inv.Notes)
	if len(inv.Projects) == 0 || (inv.TraceID == "" && notes == "") {
		return fmt.Errorf("%s needs a project, and a trace id or notes", inv.ID)
	}
	names := "`" + strings.Join(inv.Projects, "`, `") + "`"
	prompt := fmt.Sprintf("Investigate %s.", names)
	if inv.TraceID != "" {
		prompt = fmt.Sprintf("Investigate trace `%s` in %s.", inv.TraceID, names)
	}
	if notes != "" {
		prompt += "\n\n" + notes
	}
	// A combined draft arrives with its sources' entities; a re-run starts over.
	if inv.SessionID != "" {
		inv.Entities = []claude.Entity{}
	}
	inv.SessionID = uuid.New().String()
	inv.Model, inv.Effort = d.settings.Model, d.settings.Effort
	inv.StartedAt, inv.CostUSD, inv.Title = now(), 0, ""
	inv.Messages = []claude.Message{{Kind: "user", Text: prompt}}
	for _, project := range slices.Backward(inv.Projects) {
		if err := d.rememberProject(project); err != nil {
			return err
		}
	}
	return d.begin(inv, prompt+d.sourcesNote(), false)
}

// followup continues a finished investigation's session.
func (d *daemon) followup(inv *Investigation, text string) error {
	text = strings.TrimSpace(text)
	_, running := d.turns[inv.ID]
	switch {
	case running:
		return fmt.Errorf("%s is already running", inv.ID)
	case inv.SessionID == "":
		return fmt.Errorf("%s has not run yet", inv.ID)
	case text == "":
		return errors.New("empty follow-up")
	}
	inv.Messages = append(inv.Messages, claude.Message{Kind: "user", Text: text})
	return d.begin(inv, text, true)
}

// combine drafts an investigation from finished ones: their alerts, notes and reports become its notes, and their
// entities its entities. It names no trace id, so the run starts from the notes.
func (d *daemon) combine(ids []string) (string, error) {
	if len(ids) < 2 {
		return "", errors.New("combine needs at least two investigations")
	}
	inv := &Investigation{
		ID:        d.newID(),
		Status:    "draft",
		CreatedAt: now(),
		Messages:  []claude.Message{},
		Entities:  []claude.Entity{},
	}
	notes, projects := []string{}, []string{}
	for _, id := range ids {
		src, ok := d.items[id]
		if !ok {
			return "", fmt.Errorf("no investigation %q", id)
		}
		if src.Status == "running" {
			return "", fmt.Errorf("%s is running; wait for it or cancel it first", id)
		}
		inv.Tag = cmp.Or(inv.Tag, src.Tag)
		for _, project := range src.Projects {
			if !slices.Contains(projects, project) {
				projects = append(projects, project)
			}
		}
		notes = append(notes, summarize(src))
		for _, e := range src.Entities {
			inv.Entities = mergeEntity(inv.Entities, e)
		}
	}
	slices.SortStableFunc(inv.Entities, func(a, b claude.Entity) int { return cmp.Compare(b.Count, a.Count) })
	inv.Projects = projects
	inv.Notes = "Combine these earlier investigations of projects " + strings.Join(projects, ", ") +
		" and investigate further: find what connects them, and what the earlier ones missed.\n\n" +
		strings.Join(notes, "\n\n")
	d.items[inv.ID] = inv
	return inv.ID, d.save(inv)
}

// branch replays src from its index'th message, a user message, as text in a new investigation, and keeps src as it
// was. The new session is told what was said before; the earlier tool calls are not replayed.
// ponytail: the history is replayed as text; truncate a copy of the session file to keep the tool results.
func (d *daemon) branch(src *Investigation, index int, text string) (string, error) {
	text = strings.TrimSpace(text)
	switch {
	case src.Status == "running" || src.Status == "draft":
		return "", fmt.Errorf("%s is %s; only a finished investigation can be branched", src.ID, src.Status)
	case index < 0 || index >= len(src.Messages) || src.Messages[index].Kind != "user":
		return "", fmt.Errorf("%s has no user message %d", src.ID, index)
	case text == "":
		return "", errors.New("empty message")
	}
	inv := &Investigation{
		ID:        d.newID(),
		Status:    "draft",
		Tag:       src.Tag,
		Projects:  slices.Clone(src.Projects),
		TraceID:   src.TraceID,
		Notes:     src.Notes,
		Alert:     src.Alert,
		CreatedAt: now(),
		Model:     src.Model,
		Effort:    src.Effort,
		SessionID: uuid.New().String(),
		StartedAt: now(),
		Messages:  append(slices.Clone(src.Messages[:index]), claude.Message{Kind: "user", Text: text}),
		Entities:  []claude.Entity{},
	}
	if index > 0 {
		inv.Title, inv.Entities = src.Title, slices.Clone(src.Entities)
	}
	prompt := text
	if index > 0 {
		var b strings.Builder
		b.WriteString("This investigation is already under way. Do not redo it: answer the last message, and search the " +
			"logs again only if it needs it.\n\nSo far:\n")
		for _, m := range src.Messages[:index] {
			switch m.Kind {
			case "user":
				fmt.Fprintf(&b, "\nUser: %s\n", m.Text)
			case "assistant":
				fmt.Fprintf(&b, "\nYou: %s\n", m.Text)
			}
		}
		fmt.Fprintf(&b, "\nLast message from the user: %s", text)
		prompt = b.String()
	}
	d.items[inv.ID] = inv
	if err := d.begin(inv, prompt+d.sourcesNote(), false); err != nil {
		return "", err
	}
	return inv.ID, nil
}

// setSettings changes the model and effort that runs start with; "" keeps the current one.
func (d *daemon) setSettings(req request) error {
	if req.Model != "" && !slices.Contains(claude.Models, req.Model) {
		return fmt.Errorf("model %q: want one of %s", req.Model, strings.Join(claude.Models, ", "))
	}
	if req.Effort != "" && !slices.Contains(claude.Efforts, req.Effort) {
		return fmt.Errorf("effort %q: want one of %s", req.Effort, strings.Join(claude.Efforts, ", "))
	}
	d.settings.Model = cmp.Or(req.Model, d.settings.Model)
	d.settings.Effort = cmp.Or(req.Effort, d.settings.Effort)
	return writeJSON(filepath.Join(d.state, "settings.json"), d.settings)
}

// sourcesNote tells a new session where the source repositories are, "" without any.
func (d *daemon) sourcesNote() string {
	if len(d.sourceDirs) == 0 {
		return ""
	}
	return "\n\nSource repositories are cloned under `" + strings.Join(d.sourceDirs, "`, `") + "`."
}

// summarize is an investigation's alert, trace id and report as notes for another investigation.
func summarize(inv *Investigation) string {
	var b strings.Builder
	fmt.Fprintf(&b, "### Investigation %s: %s\n\nProjects: %s\n", inv.ID, inv.Title, strings.Join(inv.Projects, ", "))
	if inv.TraceID != "" {
		fmt.Fprintf(&b, "Trace id: %s\n", inv.TraceID)
	}
	if inv.Alert != nil {
		fmt.Fprintf(&b, "Alert: %s %s\n", inv.Alert.Summary, inv.Alert.Body)
	}
	if notes := strings.TrimSpace(inv.Notes); notes != "" {
		fmt.Fprintf(&b, "\nNotes:\n%s\n", notes)
	}
	if i := lastAssistant(inv.Messages); i >= 0 {
		fmt.Fprintf(&b, "\nReport:\n%s\n", inv.Messages[i].Text)
	}
	return b.String()
}

func lastAssistant(msgs []claude.Message) int {
	for i := len(msgs) - 1; i >= 0; i-- {
		if msgs[i].Kind == "assistant" {
			return i
		}
	}
	return -1
}

func mergeEntity(entities []claude.Entity, e claude.Entity) []claude.Entity {
	for i := range entities {
		if entities[i].Kind == e.Kind && entities[i].ID == e.ID {
			entities[i].Count += e.Count
			return entities
		}
	}
	return append(entities, e)
}

func (d *daemon) begin(inv *Investigation, prompt string, resume bool) error {
	inv.Status, inv.Error, inv.FinishedAt = "running", "", 0
	inv.ClaudeConfigDir = d.claudeConfigDir
	d.turns[inv.ID] = &turn{}
	d.updateTray()
	go d.runTurn(inv.ID, inv.SessionID, inv.Model, inv.Effort, prompt, resume)
	return d.save(inv)
}

func (d *daemon) cancel(inv *Investigation) error {
	t, ok := d.turns[inv.ID]
	if !ok {
		return fmt.Errorf("%s is not running", inv.ID)
	}
	t.cancelled = true
	if t.pid == 0 {
		return nil
	}
	if err := syscall.Kill(-t.pid, syscall.SIGTERM); err != nil && !errors.Is(err, syscall.ESRCH) {
		return fmt.Errorf("stop %s: %v", inv.ID, err)
	}
	return nil
}

func (d *daemon) remove(inv *Investigation) error {
	if _, ok := d.turns[inv.ID]; ok {
		return fmt.Errorf("%s is running; cancel it first", inv.ID)
	}
	if err := os.RemoveAll(d.dir(inv.ID)); err != nil {
		return fmt.Errorf("delete %s: %v", inv.ID, err)
	}
	delete(d.items, inv.ID)
	return d.writeIndex()
}

// runTurn runs one claude turn and records how it ended.
func (d *daemon) runTurn(id, sessionID, model, effort, prompt string, resume bool) {
	err := d.execTurn(id, sessionID, model, effort, prompt, resume)
	d.mu.Lock()
	defer d.mu.Unlock()
	t := d.turns[id]
	delete(d.turns, id)
	d.updateTray()
	inv := d.items[id]
	inv.FinishedAt = now()
	switch {
	case t.cancelled:
		inv.Status = "cancelled"
	case err != nil:
		inv.Status, inv.Error = "failed", err.Error()
	default:
		inv.Status = "done"
	}
	if err := d.save(inv); err != nil {
		d.logger.Error("save investigation", "id", id, "error", err)
	}
	if inv.Status != "cancelled" {
		go d.notify(id, inv.Status, strings.Join(inv.Projects, ", "))
	}
}

func (d *daemon) execTurn(id, sessionID, model, effort, prompt string, resume bool) error {
	instructions, err := d.instructions()
	if err != nil {
		return err
	}
	// Fails before spending on Claude when gcloud needs a login. The token is discarded.
	if _, err := exec.Command("gcloud", "auth", "print-access-token").Output(); err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			return fmt.Errorf("gcloud auth: %s", strings.TrimSpace(string(exitErr.Stderr)))
		}
		return fmt.Errorf("gcloud auth: %v", err)
	}
	dir := d.dir(id)
	transcript, err := os.OpenFile(filepath.Join(dir, "transcript.jsonl"), os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o600)
	if err != nil {
		return fmt.Errorf("open transcript: %v", err)
	}
	defer func() { _ = transcript.Close() }()
	cmd := claude.Command(dir, d.pluginDir, d.sourceDirs, d.goModCache, model, effort, sessionID, instructions, prompt,
		resume)
	// CLAUDE_CONFIG_DIR comes from the daemon's environment.
	cmd.Env = append(os.Environ(),
		// For `investigate checkout`.
		"INVESTIGATE_RUN_DIR="+dir, "INVESTIGATE_SOURCE_DIRS="+strings.Join(d.sourceDirs, string(os.PathListSeparator)),
		// git never writes to the clones' .git; go and gopls never download modules or toolchains.
		"GIT_OPTIONAL_LOCKS=0", "GOPROXY=off", "GOTOOLCHAIN=local")
	if d.toolPath != "" {
		cmd.Env = append(cmd.Env, "PATH="+d.toolPath+string(os.PathListSeparator)+os.Getenv("PATH"))
	}
	if d.goModCache != "" {
		cmd.Env = append(cmd.Env, "GOMODCACHE="+d.goModCache)
	}
	// claude and the commands it runs share a process group, which cancel stops.
	cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return fmt.Errorf("claude stdout: %v", err)
	}
	if err := d.startTurn(id, cmd); err != nil {
		return err
	}
	scanner := bufio.NewScanner(stdout)
	// An event carries whole tool results.
	scanner.Buffer(nil, 64<<20)
	var result *claude.Result
	for scanner.Scan() {
		if _, err := fmt.Fprintf(transcript, "%s\n", scanner.Bytes()); err != nil {
			d.logger.Warn("write transcript", "id", id, "error", err)
		}
		if r := d.fold(id, scanner.Bytes()); r != nil {
			result = r
		}
	}
	if err := scanner.Err(); err != nil {
		// Unread output would block claude on a full pipe.
		_ = syscall.Kill(-cmd.Process.Pid, syscall.SIGKILL)
		_ = cmd.Wait()
		return fmt.Errorf("read claude output: %v", err)
	}
	waitErr := cmd.Wait()
	switch {
	case result != nil && result.IsError:
		return fmt.Errorf("claude: %s", result.Text)
	case waitErr != nil:
		return fmt.Errorf("claude: %s", cmp.Or(strings.TrimSpace(stderr.String()), waitErr.Error()))
	case result == nil:
		return errors.New("claude ended without a result")
	}
	return nil
}

// instructions joins the instruction files, read on each turn so that edits apply to the next one.
func (d *daemon) instructions() (string, error) {
	texts := make([]string, 0, len(d.instructionFiles))
	for _, path := range d.instructionFiles {
		data, err := os.ReadFile(path)
		if err != nil {
			return "", fmt.Errorf("instructions: %v", err)
		}
		texts = append(texts, strings.TrimSpace(string(data)))
	}
	return strings.Join(texts, "\n\n"), nil
}

// startTurn starts cmd unless its turn was cancelled first.
func (d *daemon) startTurn(id string, cmd *exec.Cmd) error {
	d.mu.Lock()
	defer d.mu.Unlock()
	t := d.turns[id]
	if t.cancelled {
		return errors.New("cancelled")
	}
	if err := cmd.Start(); err != nil {
		return fmt.Errorf("start claude: %v", err)
	}
	t.pid = cmd.Process.Pid
	return nil
}

// fold adds one stream-json line to the investigation; it returns the turn's result once the line is one.
func (d *daemon) fold(id string, line []byte) *claude.Result {
	d.mu.Lock()
	defer d.mu.Unlock()
	inv := d.items[id]
	msgs, changed, result, err := claude.Fold(inv.Messages, line)
	if err != nil {
		d.logger.Warn("fold claude event", "id", id, "error", err)
		return nil
	}
	inv.Messages = msgs
	var found bool
	inv.Entities, found = claude.FoldEntities(inv.Entities, line, d.entityPatterns)
	changed = changed || found
	if result != nil {
		inv.CostUSD += result.CostUSD
		if inv.Title == "" && !result.IsError {
			inv.Title = claude.Title(result.Text)
		}
	}
	// Most events add nothing to show; runTurn saves the result.
	if !changed {
		return result
	}
	if err := d.save(inv); err != nil {
		d.logger.Error("save investigation", "id", id, "error", err)
	}
	return result
}

// notify announces a finished turn; its Open button shows the investigation in the window.
func (d *daemon) notify(id, status, projects string) {
	out, err := exec.Command(
		"notify-send", "--app-name", "Incident investigator", "--action", "open=Open", "--wait",
		"Investigation "+status, projects,
	).Output()
	if err != nil {
		d.logger.Warn("notify", "id", id, "error", err)
		return
	}
	if strings.TrimSpace(string(out)) != "open" {
		return
	}
	if err := show(id); err != nil {
		d.logger.Warn("show investigation", "id", id, "error", err)
	}
}

// load reads the state dir. A turn that was running when the daemon stopped has failed.
func (d *daemon) load() error {
	if err := readJSON(
		filepath.Join(d.state, "projects.json"),
		&d.projects,
	); err != nil &&
		!errors.Is(err, fs.ErrNotExist) {
		return err
	}
	d.settings = settings{Model: claude.DefaultModel, Effort: claude.DefaultEffort}
	if err := readJSON(
		filepath.Join(d.state, "settings.json"),
		&d.settings,
	); err != nil &&
		!errors.Is(err, fs.ErrNotExist) {
		return err
	}
	d.settings.Tags = d.tags
	if err := writeJSON(filepath.Join(d.state, "settings.json"), d.settings); err != nil {
		return err
	}
	paths, err := filepath.Glob(filepath.Join(d.state, "*", "investigation.json"))
	if err != nil {
		return err
	}
	for _, path := range paths {
		var inv Investigation
		if err := readJSON(path, &inv); err != nil {
			d.logger.Warn("skip investigation", "path", path, "error", err)
			continue
		}
		if inv.Project != "" {
			inv.Projects, inv.Project = append(inv.Projects, inv.Project), ""
		}
		if inv.Projects == nil {
			inv.Projects = []string{}
		}
		if inv.EnvHint != "" {
			inv.Tag, inv.EnvHint = cmp.Or(inv.Tag, inv.EnvHint), ""
		}
		// Runs before models were recorded used the defaults.
		if inv.SessionID != "" {
			inv.Model, inv.Effort = cmp.Or(inv.Model, claude.DefaultModel), cmp.Or(inv.Effort, claude.DefaultEffort)
		}
		d.items[inv.ID] = &inv
		if inv.Status != "running" {
			continue
		}
		inv.Status, inv.Error, inv.FinishedAt = "failed", "interrupted: the daemon stopped", now()
		if err := writeJSON(path, &inv); err != nil {
			return err
		}
	}
	return d.writeIndex()
}

// cleanProjects trims projects and drops empty and repeated ones.
func cleanProjects(projects []string) []string {
	clean := []string{}
	for _, project := range projects {
		if project = strings.TrimSpace(project); project != "" && !slices.Contains(clean, project) {
			clean = append(clean, project)
		}
	}
	return clean
}

// rememberProject moves project to the front of projects.json, which the window offers.
func (d *daemon) rememberProject(project string) error {
	d.projects = slices.DeleteFunc(d.projects, func(p string) bool { return p == project })
	d.projects = slices.Insert(d.projects, 0, project)
	return writeJSON(filepath.Join(d.state, "projects.json"), d.projects)
}

func (d *daemon) save(inv *Investigation) error {
	if err := writeJSON(filepath.Join(d.dir(inv.ID), "investigation.json"), inv); err != nil {
		return fmt.Errorf("save %s: %v", inv.ID, err)
	}
	return d.writeIndex()
}

// writeIndex writes every investigation, newest first, for the window.
func (d *daemon) writeIndex() error {
	items := slices.AppendSeq(make([]*Investigation, 0, len(d.items)), maps.Values(d.items))
	slices.SortFunc(items, func(a, b *Investigation) int { return cmp.Compare(b.CreatedAt, a.CreatedAt) })
	return writeJSON(filepath.Join(d.state, "index.json"), items)
}

func (d *daemon) dir(id string) string {
	return filepath.Join(d.state, id)
}

func readJSON(path string, v any) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	if err := json.Unmarshal(data, v); err != nil {
		return fmt.Errorf("parse %s: %v", path, err)
	}
	return nil
}

// writeJSON replaces path atomically, so a reader never sees a partial file.
func writeJSON(path string, v any) error {
	data, err := json.Marshal(v)
	if err != nil {
		return err
	}
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return err
	}
	f, err := os.CreateTemp(dir, ".*.tmp")
	if err != nil {
		return err
	}
	// A no-op once renamed.
	defer func() { _ = os.Remove(f.Name()) }()
	if _, err := f.Write(data); err != nil {
		_ = f.Close()
		return err
	}
	if err := f.Close(); err != nil {
		return err
	}
	return os.Rename(f.Name(), path)
}

func now() int64 {
	return time.Now().UnixMilli()
}
