package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"regexp"
	"strings"
)

// --- Auth & HTTP helpers ---

func getToken() string {
	patVar := os.Getenv("_JIRA_PAT_VAR")
	if patVar == "" {
		fatal("_JIRA_PAT_VAR not set. Run: jira-use <profile>")
	}
	token := os.Getenv(patVar)
	if token == "" {
		fatal("Token env var %s is empty", patVar)
	}
	return token
}

func authHeader() string {
	token := getToken()
	authType := os.Getenv("_JIRA_AUTH_TYPE")
	if authType == "basic" {
		return "Basic " + token
	}
	return "Bearer " + token
}

func apiBase() string {
	api := os.Getenv("JIRA_API")
	if api == "" {
		fatal("JIRA_API not set. Run: jira-use <profile>")
	}
	return api
}

func jiraHost() string {
	h := os.Getenv("JIRA_HOST")
	if h == "" {
		fatal("JIRA_HOST not set. Run: jira-use <profile>")
	}
	return h
}

var controlChars = regexp.MustCompile(`[\x00-\x08\x0b\x0c\x0e-\x1f]`)

func jiraGet(path string) ([]byte, error) {
	req, err := http.NewRequest("GET", apiBase()+path, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", authHeader())
	req.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("HTTP %d: %s", resp.StatusCode, resp.Status)
	}
	// Strip control characters that break JSON parsing
	cleaned := controlChars.ReplaceAll(body, nil)
	return cleaned, nil
}

func jiraPost(path string, payload []byte) ([]byte, error) {
	req, err := http.NewRequest("POST", apiBase()+path, strings.NewReader(string(payload)))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", authHeader())
	req.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("HTTP %d: %s", resp.StatusCode, resp.Status)
	}
	return controlChars.ReplaceAll(body, nil), nil
}

func jiraPut(path string, payload []byte) error {
	req, err := http.NewRequest("PUT", apiBase()+path, strings.NewReader(string(payload)))
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", authHeader())
	req.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 400 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("HTTP %d: %s\n%s", resp.StatusCode, resp.Status, string(body))
	}
	return nil
}

// --- JSON helpers ---

func jsonStr(v interface{}, keys ...string) string {
	m, ok := v.(map[string]interface{})
	if !ok || m == nil {
		return ""
	}
	for i, k := range keys {
		val, exists := m[k]
		if !exists || val == nil {
			return ""
		}
		if i == len(keys)-1 {
			s, ok := val.(string)
			if ok {
				return s
			}
			// handle numbers (e.g. story points)
			return fmt.Sprintf("%v", val)
		}
		m, ok = val.(map[string]interface{})
		if !ok {
			return ""
		}
	}
	return ""
}

func jsonArr(v interface{}, key string) []interface{} {
	m, ok := v.(map[string]interface{})
	if !ok || m == nil {
		return nil
	}
	arr, ok := m[key].([]interface{})
	if !ok {
		return nil
	}
	return arr
}

// --- Jira markup stripping ---

var (
	reCode      = regexp.MustCompile(`(?s)\{code(?::[^}]*)?\}.*?\{code\}`)
	reNoformat  = regexp.MustCompile(`(?s)\{noformat\}.*?\{noformat\}`)
	reColor     = regexp.MustCompile(`(?s)\{color[^}]*\}(.*?)\{color\}`)
	reHeading   = regexp.MustCompile(`h[1-6]\.\s*`)
	reLinkFull  = regexp.MustCompile(`\[([^|]+)\|([^\]]+)\]`)
	reLinkPlain = regexp.MustCompile(`\[([^\]]+)\]`)
	reBold      = regexp.MustCompile(`\*([^*]+)\*`)
	reItalic    = regexp.MustCompile(`_([^_]+)_`)
	reMacro     = regexp.MustCompile(`\{[^}]+\}`)
)

func stripMarkup(text string) string {
	if text == "" {
		return "(none)"
	}
	text = reCode.ReplaceAllString(text, "[code block]")
	text = reNoformat.ReplaceAllString(text, "[formatted block]")
	text = reColor.ReplaceAllString(text, "$1")
	text = reHeading.ReplaceAllString(text, "")
	text = reLinkFull.ReplaceAllString(text, "$1 ($2)")
	text = reLinkPlain.ReplaceAllString(text, "$1")
	text = reBold.ReplaceAllString(text, "$1")
	text = reItalic.ReplaceAllString(text, "$1")
	text = reMacro.ReplaceAllString(text, "")
	return strings.TrimSpace(text)
}

// --- ANSI colors ---

const (
	cyan  = "\033[36m"
	reset = "\033[0m"
)

// --- Issue fields ---

const viewFields = "summary,status,priority,issuetype,assignee"
const detailFields = "summary,status,assignee,priority,issuetype,description,labels,components,comment,attachment,fixVersions,customfield_10016,customfield_10014"
const listFields = "summary,status,priority,issuetype"
const searchFields = "summary,status,assignee,issuetype"

// --- Commands ---

func cmdView(args []string) {
	if len(args) == 0 {
		fatal("Usage: jira-cli view <ISSUE-KEY>")
	}
	key := strings.ToUpper(args[0])
	data, err := fetchIssue(key, viewFields)
	if err != nil {
		fatal("%v", err)
	}
	f := data["fields"].(map[string]interface{})

	fmt.Printf("%s  [%s] %s\n\n", key, jsonStr(f, "issuetype", "name"), jsonStr(f, "summary"))
	fmt.Printf("Status:   %s\n", jsonStr(f, "status", "name"))
	fmt.Printf("Priority: %s\n", jsonStr(f, "priority", "name"))
	assignee := "Unassigned"
	if a := jsonStr(f, "assignee", "displayName"); a != "" {
		assignee = a
	}
	fmt.Printf("Assignee: %s\n", assignee)
}

func cmdDetail(args []string) {
	if len(args) == 0 {
		fatal("Usage: jira-cli detail <ISSUE-KEY>")
	}
	key := strings.ToUpper(args[0])
	data, err := fetchIssue(key, detailFields)
	if err != nil {
		fatal("%v", err)
	}
	f := data["fields"].(map[string]interface{})

	fmt.Printf("%s  [%s] %s\n", key, jsonStr(f, "issuetype", "name"), jsonStr(f, "summary"))
	fmt.Println(strings.Repeat("\u2500", 45))
	fmt.Printf("Status:    %s\n", jsonStr(f, "status", "name"))
	fmt.Printf("Priority:  %s\n", jsonStr(f, "priority", "name"))
	assignee := "Unassigned"
	if a := jsonStr(f, "assignee", "displayName"); a != "" {
		assignee = a
	}
	fmt.Printf("Assignee:  %s\n", assignee)

	if labels := jsonArr(f, "labels"); len(labels) > 0 {
		strs := make([]string, len(labels))
		for i, l := range labels {
			strs[i] = fmt.Sprint(l)
		}
		fmt.Printf("Labels:    %s\n", strings.Join(strs, ", "))
	}

	if sp, ok := f["customfield_10016"]; ok && sp != nil {
		fmt.Printf("Story pts: %v\n", sp)
	}

	if fv := jsonArr(f, "fixVersions"); len(fv) > 0 {
		names := make([]string, 0, len(fv))
		for _, v := range fv {
			if n := jsonStr(v, "name"); n != "" {
				names = append(names, n)
			}
		}
		fmt.Printf("Fix ver:   %s\n", strings.Join(names, ", "))
	}

	desc := stripMarkup(jsonStr(f, "description"))
	fmt.Printf("\nDescription:\n  %s\n", desc)

	// Comments
	commentObj, _ := f["comment"].(map[string]interface{})
	if commentObj != nil {
		comments := jsonArr(commentObj, "comments")
		if len(comments) > 0 {
			fmt.Println("\nComments (last 3):")
			start := 0
			if len(comments) > 3 {
				start = len(comments) - 3
			}
			for _, c := range comments[start:] {
				cm := c.(map[string]interface{})
				date := jsonStr(cm, "updated")
				if len(date) > 10 {
					date = date[:10]
				}
				author := jsonStr(cm, "author", "displayName")
				body := stripMarkup(jsonStr(cm, "body"))
				// First line only, max 200 chars
				if idx := strings.IndexByte(body, '\n'); idx >= 0 {
					body = body[:idx]
				}
				if len(body) > 200 {
					body = body[:200]
				}
				fmt.Printf("  [%s %s] %s\n", date, author, body)
			}
		}
	}

	// Attachments
	if atts := jsonArr(f, "attachment"); len(atts) > 0 {
		fmt.Println("\nAttachments:")
		for _, a := range atts {
			fmt.Printf("  %s (%s)\n", jsonStr(a, "filename"), jsonStr(a, "mimeType"))
		}
	}
}

func cmdMy(args []string) {
	max := "15"
	if len(args) > 0 {
		max = args[0]
	}

	jql := "assignee=currentUser() AND resolution=Unresolved ORDER BY updated DESC"
	issues, err := searchIssues(jql, max, listFields)
	if err != nil {
		fatal("%v", err)
	}

	// Write cache file for shell completions
	if cache := os.Getenv("_JIRA_CACHE"); cache != "" {
		writeCache(cache, issues)
	}

	printIssueList(issues)
}

func cmdSearch(args []string) {
	if len(args) == 0 {
		fatal("Usage: jira-cli search <text>")
	}
	text := strings.Join(args, " ")
	jql := fmt.Sprintf(`text ~ "%s" ORDER BY updated DESC`, text)
	issues, err := searchIssues(jql, "15", searchFields)
	if err != nil {
		fatal("%v", err)
	}
	for _, iss := range issues {
		m := iss.(map[string]interface{})
		key := jsonStr(m, "key")
		f := m["fields"].(map[string]interface{})
		pad := strings.Repeat(" ", max(0, 14-len(key)))
		fmt.Printf("%s%s[%s] %s\n", key, pad, jsonStr(f, "status", "name"), jsonStr(f, "summary"))
	}
}

func cmdByStatus(args []string) {
	if len(args) == 0 {
		fatal("Usage: jira-cli by-status <status> [max]")
	}
	status := args[0]
	mx := "15"
	if len(args) > 1 {
		mx = args[1]
	}
	jql := fmt.Sprintf(`assignee=currentUser() AND status="%s" ORDER BY updated DESC`, status)
	issues, err := searchIssues(jql, mx, listFields)
	if err != nil {
		fatal("%v", err)
	}
	if len(issues) == 0 {
		fmt.Printf("No issues with status %q\n", status)
		return
	}
	printIssueList(issues)
}

func cmdComment(args []string) {
	if len(args) < 2 {
		fatal("Usage: jira-cli comment <ISSUE-KEY> <message...>")
	}
	key := strings.ToUpper(args[0])
	body := strings.Join(args[1:], " ")
	payload, _ := json.Marshal(map[string]string{"body": body})
	resp, err := jiraPost(fmt.Sprintf("/issue/%s/comment", key), payload)
	if err != nil {
		fatal("%v", err)
	}
	var result map[string]interface{}
	json.Unmarshal(resp, &result)
	fmt.Printf("Comment added (id: %v)\n", result["id"])
}

func cmdAssign(args []string) {
	if len(args) == 0 {
		fatal("Usage: jira-cli assign <ISSUE-KEY> [username]")
	}
	key := strings.ToUpper(args[0])
	var user string
	if len(args) > 1 {
		user = args[1]
	} else {
		// Fetch current user
		body, err := jiraGet("/myself")
		if err != nil {
			fatal("Failed to fetch current user: %v", err)
		}
		var me map[string]interface{}
		json.Unmarshal(body, &me)
		user = jsonStr(me, "name")
	}
	payload, _ := json.Marshal(map[string]string{"name": user})
	err := jiraPut(fmt.Sprintf("/issue/%s/assignee", key), payload)
	if err != nil {
		fatal("%v", err)
	}
	fmt.Printf("Assigned %s to %s\n", key, user)
}

func cmdTransitions(args []string) {
	if len(args) == 0 {
		fatal("Usage: jira-cli transitions <ISSUE-KEY>")
	}
	key := strings.ToUpper(args[0])
	body, err := jiraGet(fmt.Sprintf("/issue/%s/transitions", key))
	if err != nil {
		fatal("%v", err)
	}
	var result map[string]interface{}
	json.Unmarshal(body, &result)
	transitions := jsonArr(result, "transitions")
	for _, t := range transitions {
		fmt.Printf("%s\t%s\n", jsonStr(t, "id"), jsonStr(t, "name"))
	}
}

func cmdTransition(args []string) {
	if len(args) < 2 {
		fatal("Usage: jira-cli transition <ISSUE-KEY> <id-or-name>")
	}
	key := strings.ToUpper(args[0])
	target := args[1]

	// If target looks like a number, use it directly as transition ID
	isID := true
	for _, c := range target {
		if c < '0' || c > '9' {
			isID = false
			break
		}
	}

	var tid, tname string
	if isID {
		tid = target
		tname = target
	} else {
		// Fetch transitions and fuzzy match by name
		body, err := jiraGet(fmt.Sprintf("/issue/%s/transitions", key))
		if err != nil {
			fatal("%v", err)
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
			fmt.Fprintf(os.Stderr, "No transition matching %q for %s. Available:\n", target, key)
			for _, t := range transitions {
				fmt.Fprintf(os.Stderr, "  %s\n", jsonStr(t, "name"))
			}
			os.Exit(1)
		}
	}

	payload, _ := json.Marshal(map[string]interface{}{
		"transition": map[string]string{"id": tid},
	})
	_, err := jiraPost(fmt.Sprintf("/issue/%s/transitions", key), payload)
	if err != nil {
		fatal("%v", err)
	}
	fmt.Printf("%s \u2192 %s\n", key, tname)
}

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
	fmt.Printf("Transitioning %d issue(s) from %q \u2192 %q:\n", len(issues), from, to)
	for _, iss := range issues {
		key := jsonStr(iss, "key")
		cmdTransition([]string{key, to})
	}
}

func cmdMR(args []string) {
	if len(args) == 0 {
		fatal("Usage: jira-cli mr <ISSUE-KEY> [--web]")
	}
	key := strings.ToUpper(args[0])
	openWeb := len(args) > 1 && args[1] == "--web"

	cmd := exec.Command("glab", "mr", "list", "--author=@me", "--search="+key)
	out, err := cmd.CombinedOutput()
	if err != nil {
		// Show glab's own error output
		msg := strings.TrimSpace(string(out))
		if msg != "" {
			fatal("glab: %s", msg)
		}
		fatal("glab mr list failed: %v", err)
	}

	// Filter lines matching the key
	var matches []string
	for _, line := range strings.Split(string(out), "\n") {
		if strings.Contains(strings.ToUpper(line), key) {
			matches = append(matches, line)
		}
	}
	if len(matches) == 0 {
		fatal("No MR found for %s", key)
	}
	for _, m := range matches {
		fmt.Println(m)
	}

	if openWeb {
		// Extract MR ID (e.g. "!123") from output
		re := regexp.MustCompile(`!(\d+)`)
		m := re.FindStringSubmatch(matches[0])
		if m != nil {
			exec.Command("glab", "mr", "view", m[1], "--web").Run()
		}
	}
}

func cmdJQL(args []string) {
	if len(args) == 0 {
		fatal("Usage: jira-cli jql <JQL> [maxResults]")
	}
	jql := args[0]
	mx := "20"
	if len(args) > 1 {
		mx = args[1]
	}
	issues, err := searchIssues(jql, mx, searchFields)
	if err != nil {
		fatal("%v", err)
	}
	if len(issues) == 0 {
		fmt.Println("No issues found")
		return
	}
	for _, iss := range issues {
		m := iss.(map[string]interface{})
		key := jsonStr(m, "key")
		f := m["fields"].(map[string]interface{})
		pad := strings.Repeat(" ", max(0, 14-len(key)))
		status := jsonStr(f, "status", "name")
		assignee := jsonStr(f, "assignee", "displayName")
		if assignee == "" {
			assignee = "Unassigned"
		}
		fmt.Printf("%s%s%s%s[%s] %s  (%s)\n", cyan, key, reset, pad, status, jsonStr(f, "summary"), assignee)
	}
}

func cmdOpen(args []string) {
	if len(args) == 0 {
		fatal("Usage: jira-cli open <ISSUE-KEY>")
	}
	key := strings.ToUpper(args[0])
	fmt.Printf("%s/browse/%s\n", jiraHost(), key)
}

// --- Shared helpers ---

func fetchIssue(key, fields string) (map[string]interface{}, error) {
	body, err := jiraGet(fmt.Sprintf("/issue/%s?fields=%s", key, fields))
	if err != nil {
		return nil, err
	}
	var data map[string]interface{}
	if err := json.Unmarshal(body, &data); err != nil {
		return nil, fmt.Errorf("JSON parse error: %w", err)
	}
	if msgs := jsonArr(data, "errorMessages"); len(msgs) > 0 {
		return nil, fmt.Errorf("%v", msgs[0])
	}
	return data, nil
}

func searchIssues(jql, maxResults, fields string) ([]interface{}, error) {
	params := url.Values{}
	params.Set("jql", jql)
	params.Set("maxResults", maxResults)
	params.Set("fields", fields)
	body, err := jiraGet("/search?" + params.Encode())
	if err != nil {
		return nil, err
	}
	var data map[string]interface{}
	if err := json.Unmarshal(body, &data); err != nil {
		return nil, fmt.Errorf("JSON parse error: %w", err)
	}
	return jsonArr(data, "issues"), nil
}

func printIssueList(issues []interface{}) {
	for _, iss := range issues {
		m := iss.(map[string]interface{})
		key := jsonStr(m, "key")
		f := m["fields"].(map[string]interface{})
		pad := strings.Repeat(" ", max(0, 14-len(key)))
		fmt.Printf("%s%s%s%s[%s] %s\n", cyan, key, reset, pad, jsonStr(f, "status", "name"), jsonStr(f, "summary"))
	}
}

func writeCache(path string, issues []interface{}) {
	f, err := os.Create(path)
	if err != nil {
		return
	}
	defer f.Close()
	for _, iss := range issues {
		m := iss.(map[string]interface{})
		key := jsonStr(m, "key")
		summary := jsonStr(m["fields"], "summary")
		fmt.Fprintf(f, "%s\t%s\n", key, summary)
	}
}

func fatal(format string, args ...interface{}) {
	fmt.Fprintf(os.Stderr, "Error: "+format+"\n", args...)
	os.Exit(1)
}

// --- Main ---

func usage() {
	fmt.Fprintln(os.Stderr, `Usage: jira-cli <command> [args]

Commands:
  view     <KEY>                    Quick issue summary
  detail   <KEY>                    Full issue detail
  my       [max]                    My unresolved issues
  search   <text>                   Free-text search
  by-status <status> [max]          List my issues by status
  comment  <KEY> <message>          Add a comment
  assign   <KEY> [user]             Assign issue (default: self)
  transitions <KEY>                 List available transitions
  transition  <KEY> <id-or-name>    Transition issue
  batch-transition <from> <to>      Batch transition issues
  jql      <JQL> [max]               Run a raw JQL query
  mr       <KEY> [--web]            Find GitLab MR by ticket key
  open     <KEY>                    Print browse URL`)
	os.Exit(1)
}

func main() {
	if len(os.Args) < 2 {
		usage()
	}
	switch os.Args[1] {
	case "view":
		cmdView(os.Args[2:])
	case "detail":
		cmdDetail(os.Args[2:])
	case "my":
		cmdMy(os.Args[2:])
	case "search":
		cmdSearch(os.Args[2:])
	case "by-status":
		cmdByStatus(os.Args[2:])
	case "comment":
		cmdComment(os.Args[2:])
	case "assign":
		cmdAssign(os.Args[2:])
	case "transitions":
		cmdTransitions(os.Args[2:])
	case "transition":
		cmdTransition(os.Args[2:])
	case "batch-transition":
		cmdBatchTransition(os.Args[2:])
	case "jql":
		cmdJQL(os.Args[2:])
	case "mr":
		cmdMR(os.Args[2:])
	case "open":
		cmdOpen(os.Args[2:])
	default:
		fmt.Fprintf(os.Stderr, "Unknown command: %s\n", os.Args[1])
		usage()
	}
}
