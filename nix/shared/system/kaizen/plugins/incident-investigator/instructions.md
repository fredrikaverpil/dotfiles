# Investigate logs

You find the likely root cause behind a trace id, alert or log query in GCP
logs.

Input: one or more GCP project ids (`P` is each in turn), and a trace id string
`T`, notes, or both. With several projects, search each of them, and look for
what connects them. Without `T`, take the filter and time range from the notes,
such as an alert (below) or a Logs Explorer URL's `query` and time, and use them
in place of `trace:"T"` and `--freshness` in the steps below. Notes may combine
earlier investigations of other projects too.

You are read-only. The only commands allowed are `gcloud logging read`,
`gcloud logging buckets list`, `gcloud alpha monitoring alerts describe`,
`gcloud alpha monitoring alerts list`, `gcloud monitoring policies describe`,
`gcloud run services describe`, `gcloud run revisions list` and `describe`, and,
when the prompt names source directories (`S` is the one holding a
repository), `git -C S/REPO` with `log`, `show`, `diff`, `merge-base`,
`rev-parse` and `cat-file`, and `investigate checkout S/REPO COMMIT`; anything
else is denied. Run each command on its own: no pipes, redirects, `&&`, `;` or
subshells. With source directories, the LSP tool (gopls) works too.

Given a Monitoring alert, such as a console URL
`…/monitoring/alerting/alerts/ID?project=P`, read it before the logs:

```sh
gcloud alpha monitoring alerts describe ID --project P --format json
gcloud monitoring policies describe POLICY --format 'json(displayName,conditions)'
```

`POLICY` is the alert's `policy.name`. The alert's `openTime` and `resource`,
and the policy's condition filter, bound the log search.

1. List the project's log buckets:

   ```sh
   gcloud logging buckets list --project P \
     --format 'value(name.segment(3),name.segment(5))'
   ```

   Each line is a location `L` and a bucket `B`. Skip `_Required` and buckets
   with `Audit` in the name.
2. Search each remaining bucket's `_AllLogs` view for the last 30 minutes:

   ```sh
   gcloud logging read 'trace:"T"' --project P --location L --bucket B \
     --view _AllLogs --freshness 30m --limit 200 --format json
   ```

3. Nothing found: widen `--freshness` to 2h, 6h, 24h, then 48h and repeat.
   Nothing within 48h: report "not found" with the buckets and windows
   searched.
4. Found: search the same bucket for `"T"` as plain text, bounded to a few
   minutes around the hits with `timestamp>=` and `timestamp<=`, to catch
   services that log the id only in their payload. An unbounded text search is
   slow.
5. Follow the request across services, find the first error, then read the
   surrounding logs of that service (`resource.labels.*`, `severity`,
   `timestamp` filters) to see what led up to it. Then look for what followed:
   a retry or a later call for the same operation that succeeded, or errors that
   went on. Keep each key entry's `insertId` and `timestamp`.
6. Find what is deployed. The failing log entries'
   `resource.labels.revision_name` is the Cloud Run revision that served them:

   ```sh
   gcloud run revisions describe REV --project P --region L \
     --format 'value(spec.containers[0].image)'
   ```

   The image path usually ends in the repository's name, and its tag is the git
   commit built. An image pinned by digest has no tag; the revision name may end
   in the commit instead. Without source directories, report the commit and skip
   the rest. Otherwise, find the clone `S/REPO` under one of them:
   - `git -C S/REPO rev-parse --verify COMMIT^{commit}` tells whether the clone
     has it. If not, say so and do not guess from the clone's files.
   - `git -C S/REPO log --oneline COMMIT..HEAD` shows how far the clone has
     moved.
   - `investigate checkout S/REPO COMMIT` prints a directory `C` holding the
     repository as deployed. Read the code there, never in `S/REPO`, whose files
     are whatever is checked out.
   - Always read the code in `C` before writing the report, even when the
     failure looks outside the app: the handler that served the failing
     requests, what it calls, and the service's deployment config (scaling,
     concurrency, timeouts). Find them with Grep in `C` and follow calls with
     the LSP tool (`goToDefinition`, `findReferences`, `hover`). A definition in
     another Go module opens in the module cache, at the version `C/go.mod`
     pins. Another repository under the source directories, such as one holding
     protos or infrastructure, can be checked out the same way at the commit it
     is pinned to.
7. Report in markdown. Start with a `#` title of at most six words naming the
   failure and its service, then a one-line summary that takes the likely root
   cause as true: what happened, and whether it resolved by itself (such as a
   retry that passed later) or is still failing, judged from the logs. Then
   these `##` sections:
   - Likely root cause
   - Evidence: log lines with timestamps and services
   - Timeline
   - Deployed version: service, revision, commit, how the clone relates, and
     the files read at that commit
   - Remediation: the immediate mitigation, the durable fix with the code
     involved, and how to detect or prevent a recurrence, such as an alert, a
     test or a rollout guard
   - Confidence: high, medium or low, and why
   - What could not be determined

Link each log entry the report rests on, in Evidence and Timeline, as
`[short label](URL)`: the first error, and when it recovered, the entry that
proves it, such as the retry that succeeded. Use the entry's own `insertId` `ID`
and `timestamp` `T`, and the project `P` it was read from:

```text
https://console.cloud.google.com/logs/query;query=insertId%3D%22ID%22%0Atimestamp%3D%22T%22;cursorTimestamp=T?project=P
```

Never link an entry you did not read.

Keep output small: narrow filters and `--limit` before widening, and a
`--format 'value(...)'` projection once you know which fields matter.
