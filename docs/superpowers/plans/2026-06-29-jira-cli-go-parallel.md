# jira-cli Go Parallel Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `fetch`, `reporter`, `assign-to-reporter` commands to the jira-cli Go binary, extract a `transitionIssue` helper, and parallelize all batch operations using goroutines — then slim down the shell wrappers to thin delegates.

**Architecture:** Single file `~/.dotfiles/cli/cmd/jira/main.go`. A new `runParallel(keys, fn)` helper fans out goroutines and streams results via a buffered channel as each completes. All multi-key operations (`batch-transition`, `assign-to-reporter`) use it. Shell functions in `jira.zsh` that previously did curl become one-liners calling the binary.

**Tech Stack:** Go 1.22, stdlib only (`net/http`, `encoding/json`, `sync` not needed — channel-based). No new dependencies.

## Global Constraints

- No new go.mod dependencies — stdlib only
- Binary output format: `KEY → status` for transitions, `Assigned KEY to user` for assigns — match existing style
- Parallel results print as-they-arrive (no sorting), errors go to stderr
- Build command: `cd ~/.dotfiles/cli && go build -o jira-cli ./cmd/jira/ && cp jira-cli ~/.local/bin/`
- `jira.zsh` lives at `~/.dotfiles/zsh/scripts/jira.zsh`
- SKILL.md lives at `~/.claude/skills/jira/SKILL.md`

---

### Task 1: `runParallel` helper + extract `transitionIssue` + parallelize `batch-transition`

**Files:**
- Modify: `~/.dotfiles/cli/cmd/jira/main.go`

**What changes:**
1. Add `parallelResult` struct and `runParallel` after the `fatal` function (line 668)
2. Extract `transitionIssue(key, target string) (string, error)` from the body of `cmdTransition` (lines 449–503)
3. Rewrite `cmdTransition` to call `transitionIssue`
4. Rewrite `cmdBatchTransition` to use `runParallel`
5. Add `reporter` to `detailFields` constant (line 205)
6. Show reporter in `cmdDetail` output (after the assignee block, ~line 251)

- [ ] **Step 1: Add `parallelResult` struct and `runParallel` after `fatal` (before `// --- Main ---`)**

Insert after line 668 (`}`  — end of `fatal`):

```go
// --- Parallel execution ---

type parallelResult struct {
	key string
	msg string
	err error
}

// runParallel spawns one goroutine per key, prints results to stdout as they complete.
// Errors go to stderr. fn receives the key and returns a display string or an error.
func runParallel(keys []string, fn func(key string) (string, error)) {
	ch := make(chan parallelResult, len(keys))
	for _, k := range keys {
		k := k
		go func() {
			msg, err := fn(k)
			ch <- parallelResult{key: k, msg: msg, err: err}
		}()
	}
	for range keys {
		r := <-ch
		if r.err != nil {
			fmt.Fprintf(os.Stderr, "%s: %v\n", r.key, r.err)
		} else {
			fmt.Println(r.msg)
		}
	}
}
```

- [ ] **Step 2: Extract `transitionIssue` — replace the body of `cmdTransition` (lines 449–503)**

Replace the entire `cmdTransition` function with:

```go
// transitionIssue transitions key to target (name or numeric ID).
// Returns "KEY → StatusName" on success, error with available transitions on name mismatch.
func transitionIssue(key, target string) (string, error) {
	key = strings.ToUpper(key)

	isID := true
	for _, c := range target {
		if c < '0' || c > '9' {
			isID = false
			break
		}
	}

	var tid, tname string
	if isID {
		tid, tname = target, target
	} else {
		body, err := jiraGet(fmt.Sprintf("/issue/%s/transitions", key))
		if err != nil {
			return "", err
		}
		var result map[string]interface{}
		json.Unmarshal(body, &result)
		transitions := jsonArr(result, "transitions")
		targetLower := strings.ToLower(target)
		for _, t := range transitions {
			name := jsonStr(t, "name")
			if strings.Contains(strings.ToLower(name), targetLower) {
				tid = jsonStr(t, "id")
				tname = name
				break
			}
		}
		if tid == "" {
			var names []string
			for _, t := range transitions {
				names = append(names, jsonStr(t, "name"))
			}
			return "", fmt.Errorf("no transition matching %q for %s\n  available: %s",
				target, key, strings.Join(names, ", "))
		}
	}

	payload, _ := json.Marshal(map[string]interface{}{
		"transition": map[string]string{"id": tid},
	})
	_, err := jiraPost(fmt.Sprintf("/issue/%s/transitions", key), payload)
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%s → %s", key, tname), nil
}

func cmdTransition(args []string) {
	if len(args) < 2 {
		fatal("Usage: jira-cli transition <ISSUE-KEY> <id-or-name>")
	}
	msg, err := transitionIssue(args[0], args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error:", err)
		os.Exit(1)
	}
	fmt.Println(msg)
}
```

- [ ] **Step 3: Rewrite `cmdBatchTransition` to use `runParallel`**

Replace the entire `cmdBatchTransition` function (lines 506–525) with:

```go
func cmdBatchTransition(args []string) {
	if len(args) < 2 {
		fatal("Usage: jira-cli batch-transition <from-status> <to-status>")
	}
	from, to := args[0], args[1]
	jql := fmt.Sprintf(`assignee=currentUser() AND status="%s" ORDER BY updated DESC`, from)
	issues, err := searchIssues(jql, "50", "key,summary")
	if err != nil {
		fatal("%v", err)
	}
	if len(issues) == 0 {
		fmt.Printf("No issues with status %q\n", from)
		return
	}
	keys := make([]string, len(issues))
	for i, iss := range issues {
		keys[i] = jsonStr(iss, "key")
	}
	fmt.Printf("Transitioning %d issue(s) from %q → %q:\n", len(keys), from, to)
	runParallel(keys, func(key string) (string, error) {
		return transitionIssue(key, to)
	})
}
```

- [ ] **Step 4: Add `reporter` to `detailFields`**

Change line 205:
```go
const detailFields = "summary,status,assignee,reporter,priority,issuetype,description,labels,components,comment,attachment,fixVersions,customfield_10016,customfield_10014"
```

- [ ] **Step 5: Show reporter in `cmdDetail` — insert after the assignee block (~line 251)**

After:
```go
	fmt.Printf("Assignee:  %s\n", assignee)
```

Add:
```go
	if r := jsonStr(f, "reporter", "displayName"); r != "" {
		fmt.Printf("Reporter:  %s\n", r)
	}
```

- [ ] **Step 6: Build and verify it compiles**

```bash
cd ~/.dotfiles/cli && go build -o jira-cli ./cmd/jira/ && echo "OK"
```

Expected: `OK` with no errors.

- [ ] **Step 7: Smoke test**

```bash
cd ~/.dotfiles/cli && zsh -i -c './jira-cli detail ESS-1193' 2>/dev/null | grep -E "Assignee|Reporter"
```

Expected: both `Assignee:` and `Reporter:` lines appear.

- [ ] **Step 8: Commit**

```bash
cd ~/.dotfiles/cli
git add cli/cmd/jira/main.go 2>/dev/null || git add cmd/jira/main.go
git commit -m "feat(jira-cli): add runParallel engine, extract transitionIssue, parallelize batch-transition, show reporter in detail"
```

---

### Task 2: `fetch` command — raw JSON output

**Files:**
- Modify: `~/.dotfiles/cli/cmd/jira/main.go`

**What changes:** Add `cmdFetch` that returns pretty-printed JSON for any issue with optional field filter. Eliminates all reasons to ever use raw curl for Jira API.

- [ ] **Step 1: Add `cmdFetch` before `// --- Shared helpers ---` (line 608)**

```go
func cmdFetch(args []string) {
	if len(args) == 0 {
		fatal("Usage: jira-cli fetch <ISSUE-KEY> [fields]")
	}
	key := strings.ToUpper(args[0])
	fields := "*all"
	if len(args) > 1 {
		fields = args[1]
	}
	path := fmt.Sprintf("/issue/%s?fields=%s", key, url.QueryEscape(fields))
	body, err := jiraGet(path)
	if err != nil {
		fatal("%v", err)
	}
	var v interface{}
	json.Unmarshal(body, &v)
	out, _ := json.MarshalIndent(v, "", "  ")
	fmt.Println(string(out))
}
```

Note: `url` is already imported.

- [ ] **Step 2: Add `"fetch"` to `usage()` string (line 673 area)**

In the usage heredoc, after the `open` line add:
```
  fetch    <KEY> [fields]            Raw JSON (default: *all fields)
```

- [ ] **Step 3: Add `"fetch"` case to `main()` switch**

After `case "open":` add:
```go
	case "fetch":
		cmdFetch(os.Args[2:])
```

- [ ] **Step 4: Build**

```bash
cd ~/.dotfiles/cli && go build -o jira-cli ./cmd/jira/ && echo "OK"
```

- [ ] **Step 5: Smoke test**

```bash
cd ~/.dotfiles/cli && ./jira-cli fetch ESS-1193 reporter 2>/dev/null | jq '.fields.reporter.name'
```

Expected: `"nahliuk.d"` (quoted string).

- [ ] **Step 6: Commit**

```bash
cd ~/.dotfiles/cli
git add cmd/jira/main.go
git commit -m "feat(jira-cli): add fetch command for raw JSON — eliminates curl fallback"
```

---

### Task 3: `reporter` command

**Files:**
- Modify: `~/.dotfiles/cli/cmd/jira/main.go`

**What changes:** Add `cmdReporter` — prints reporter username for a single key. Used by shell wrapper `jira-reporter`.

- [ ] **Step 1: Add `cmdReporter` after `cmdFetch`**

```go
func cmdReporter(args []string) {
	if len(args) == 0 {
		fatal("Usage: jira-cli reporter <ISSUE-KEY>")
	}
	key := strings.ToUpper(args[0])
	data, err := fetchIssue(key, "reporter")
	if err != nil {
		fatal("%v", err)
	}
	f := data["fields"].(map[string]interface{})
	name := jsonStr(f, "reporter", "name")
	if name == "" {
		fatal("No reporter found for %s", key)
	}
	fmt.Println(name)
}
```

- [ ] **Step 2: Add `"reporter"` to `usage()` and `main()` switch**

In usage heredoc add:
```
  reporter <KEY>                     Print reporter username
```

In `main()` switch add:
```go
	case "reporter":
		cmdReporter(os.Args[2:])
```

- [ ] **Step 3: Build**

```bash
cd ~/.dotfiles/cli && go build -o jira-cli ./cmd/jira/ && echo "OK"
```

- [ ] **Step 4: Smoke test**

```bash
cd ~/.dotfiles/cli && ./jira-cli reporter ESS-1193
```

Expected: `nahliuk.d`

- [ ] **Step 5: Commit**

```bash
cd ~/.dotfiles/cli
git add cmd/jira/main.go
git commit -m "feat(jira-cli): add reporter command"
```

---

### Task 4: `assign-to-reporter` command (parallel for multiple keys)

**Files:**
- Modify: `~/.dotfiles/cli/cmd/jira/main.go`

**What changes:** `assignOneToReporter` fetches reporter + assigns in one function (2 API calls). `cmdAssignToReporter` handles 1 key directly, N keys via `runParallel` — so 6 tickets take the time of 1 instead of 6 sequential pairs.

- [ ] **Step 1: Add `assignOneToReporter` and `cmdAssignToReporter` after `cmdReporter`**

```go
func assignOneToReporter(key string) (string, error) {
	key = strings.ToUpper(key)
	data, err := fetchIssue(key, "reporter")
	if err != nil {
		return "", fmt.Errorf("fetch: %w", err)
	}
	f := data["fields"].(map[string]interface{})
	reporter := jsonStr(f, "reporter", "name")
	if reporter == "" {
		return "", fmt.Errorf("no reporter found")
	}
	payload, _ := json.Marshal(map[string]string{"name": reporter})
	if err := jiraPut(fmt.Sprintf("/issue/%s/assignee", key), payload); err != nil {
		return "", fmt.Errorf("assign: %w", err)
	}
	return fmt.Sprintf("Assigned %s to %s", key, reporter), nil
}

func cmdAssignToReporter(args []string) {
	if len(args) == 0 {
		fatal("Usage: jira-cli assign-to-reporter <KEY> [KEY...]")
	}
	keys := make([]string, len(args))
	for i, k := range args {
		keys[i] = strings.ToUpper(k)
	}
	if len(keys) == 1 {
		msg, err := assignOneToReporter(keys[0])
		if err != nil {
			fatal("%v", err)
		}
		fmt.Println(msg)
		return
	}
	runParallel(keys, assignOneToReporter)
}
```

- [ ] **Step 2: Add to `usage()` and `main()` switch**

In usage heredoc add:
```
  assign-to-reporter <KEY> [KEY...]  Reassign to reporter (parallel for N keys)
```

In `main()` switch add:
```go
	case "assign-to-reporter":
		cmdAssignToReporter(os.Args[2:])
```

- [ ] **Step 3: Build**

```bash
cd ~/.dotfiles/cli && go build -o jira-cli ./cmd/jira/ && echo "OK"
```

- [ ] **Step 4: Smoke test single key**

```bash
cd ~/.dotfiles/cli && ./jira-cli assign-to-reporter ESS-1193
```

Expected: `Assigned ESS-1193 to nahliuk.d`

- [ ] **Step 5: Commit**

```bash
cd ~/.dotfiles/cli
git add cmd/jira/main.go
git commit -m "feat(jira-cli): add assign-to-reporter command with parallel multi-key support"
```

---

### Task 5: Install binary + update `jira.zsh` shell wrappers

**Files:**
- Modify: `~/.dotfiles/zsh/scripts/jira.zsh`

**What changes:** Install the new binary. Replace the 3 shell functions added last session (`_jira_fetch_full`, `jira-reporter`, `jira-assign-to-reporter`) with thin delegates to the Go binary. Remove curl entirely.

- [ ] **Step 1: Install binary**

```bash
cd ~/.dotfiles/cli && make install && echo "Installed: $(~/.local/bin/jira-cli 2>&1 | head -1)"
```

Expected: prints `Usage: jira-cli <command> [args]` line.

- [ ] **Step 2: Replace `_jira_fetch_full` in `jira.zsh`**

Find and replace the current multi-line `_jira_fetch_full` function (the curl-based one added last session):

Old:
```zsh
# _jira_fetch_full <KEY> — raw JSON for a ticket (for field access: reporter, labels, sprint, etc.)
_jira_fetch_full() {
    _jira_require_profile || return 1
    local key="${1:u}"
    [[ -z "$key" ]] && { echo "Usage: _jira_fetch_full <ISSUE-KEY>"; return 1; }
    local pat="${(P)_JIRA_PAT_VAR}"
    if [[ "$_JIRA_AUTH_TYPE" == "bearer" ]]; then
        curl -sk -H "Authorization: Bearer $pat" "$JIRA_API/issue/$key"
    else
        curl -sk -u "$pat" "$JIRA_API/issue/$key"
    fi
}
```

New:
```zsh
# _jira_fetch_full <KEY> [fields] — raw JSON for a ticket (delegates to Go binary)
_jira_fetch_full() {
    _jira_cli fetch "$@"
}
```

- [ ] **Step 3: Replace `jira-reporter` in `jira.zsh`**

Old:
```zsh
# jira-reporter <KEY> — print reporter username
jira-reporter() {
    _jira_require_profile || return 1
    local key="${1:u}"
    [[ -z "$key" ]] && { echo "Usage: jira-reporter <ISSUE-KEY>"; return 1; }
    _jira_fetch_full "$key" | jq -r '.fields.reporter.name // empty'
}
```

New:
```zsh
# jira-reporter <KEY> — print reporter username
jira-reporter() {
    _jira_cli reporter "$@"
}
```

- [ ] **Step 4: Replace `jira-assign-to-reporter` in `jira.zsh`**

Old:
```zsh
# jira-assign-to-reporter <KEY> — reassign issue back to its reporter
jira-assign-to-reporter() {
    _jira_require_profile || return 1
    local key="${1:u}"
    [[ -z "$key" ]] && { echo "Usage: jira-assign-to-reporter <ISSUE-KEY>"; return 1; }
    local reporter
    reporter=$(jira-reporter "$key") || return 1
    [[ -z "$reporter" ]] && { echo "Could not determine reporter for $key"; return 1; }
    jira-assign "$key" "$reporter"
}
```

New:
```zsh
# jira-assign-to-reporter <KEY> [KEY...] — reassign to reporter (parallel for N keys)
jira-assign-to-reporter() {
    _jira_cli assign-to-reporter "$@"
}
```

- [ ] **Step 5: Smoke test shell wrappers**

```bash
zsh -i -c 'jira-reporter ESS-1193' 2>/dev/null
```

Expected: `nahliuk.d`

```bash
zsh -i -c '_jira_fetch_full ESS-1193 reporter' 2>/dev/null | jq -r '.fields.reporter.name'
```

Expected: `nahliuk.d`

- [ ] **Step 6: Commit**

```bash
cd ~/.dotfiles
git add zsh/scripts/jira.zsh
git commit -m "refactor(jira.zsh): replace curl-based helpers with thin Go binary delegates"
```

---

### Task 6: Update SKILL.md

**Files:**
- Modify: `~/.claude/skills/jira/SKILL.md`

**What changes:** Update the command map to document `fetch`, `reporter`, `assign-to-reporter`. Update the raw JSON section to show `fetch` usage with `jq`. Remove lingering notes about curl.

- [ ] **Step 1: Update command map in SKILL.md**

In the "Intent → command map" section, after `- Raw JSON (for field access): ...` update to:

```markdown
- Raw JSON (for field access): `_jira_fetch_full KEY [fields]` — wraps `jira-cli fetch`; pipe to `jq` for specific fields
- Get reporter username: `jira-reporter KEY`
- Assign to reporter (1 or N keys): `jira-assign-to-reporter KEY [KEY...]` — parallel for N keys
```

- [ ] **Step 2: Update the raw JSON example block**

Replace the existing "Raw JSON + error handling" code block with:

```bash
# Get reporter of a ticket
reporter=$(zsh -i -c 'jira-reporter ESS-1234' 2>/dev/null)

# Get any field via raw JSON
res=$(zsh -i -c '_jira_fetch_full ESS-1234 reporter,assignee' 2>/dev/null)
echo "$res" | jq -r '.fields.reporter.name'

# Reassign multiple tickets to their reporters in parallel
zsh -i -c 'jira-assign-to-reporter ESS-1 ESS-2 ESS-3 ESS-4' 2>/dev/null
```

- [ ] **Step 3: Verify SKILL.md has no remaining curl references**

```bash
grep -n "curl" ~/.claude/skills/jira/SKILL.md
```

Expected: no output.

- [ ] **Step 4: Commit**

```bash
cd ~/.claude
git add skills/jira/SKILL.md 2>/dev/null || true
# (skills may not be in a git repo — skip if not)
echo "SKILL.md updated"
```

---

## Self-Review

**Spec coverage:**
- ✅ `runParallel` engine — Task 1
- ✅ `transitionIssue` extraction — Task 1
- ✅ `batch-transition` parallelized — Task 1
- ✅ `reporter` in `detailFields` — Task 1
- ✅ `fetch` command — Task 2
- ✅ `reporter` command — Task 3
- ✅ `assign-to-reporter` command — Task 4
- ✅ Binary install + shell wrappers thinned — Task 5
- ✅ SKILL.md updated — Task 6

**Placeholder scan:** None found.

**Type consistency:** `runParallel` signature `func(key string) (string, error)` used consistently in Task 1 (`transitionIssue` wrapper), Task 4 (`assignOneToReporter`).
