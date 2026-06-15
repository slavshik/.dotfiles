package main

import (
	"encoding/json"
	"fmt"
	"html"
	"io"
	"net/http"
	"net/url"
	"os"
	"regexp"
	"strings"
)

// --- HTTP helpers ---

var controlChars = regexp.MustCompile(`[\x00-\x08\x0b\x0c\x0e-\x1f]`)

func wikiHost() string {
	h := os.Getenv("WIKI_HOST")
	if h == "" {
		h = "https://wiki.evolution.com"
	}
	return h
}

func wikiToken() string {
	t := os.Getenv("WIKI_PAT")
	if t == "" {
		fatal("WIKI_PAT not set")
	}
	return t
}

func wikiGet(url string) ([]byte, error) {
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+wikiToken())
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

// --- HTML to text conversion ---

var (
	reHeading    = regexp.MustCompile(`(?s)<h([1-6])[^>]*>(.*?)</h[1-6]>`)
	reLi         = regexp.MustCompile(`<li[^>]*>`)
	reLiClose    = regexp.MustCompile(`</li>`)
	reList       = regexp.MustCompile(`</?[ou]l[^>]*>`)
	reTr         = regexp.MustCompile(`<tr[^>]*>`)
	reTd         = regexp.MustCompile(`<t[hd][^>]*>`)
	reTdClose    = regexp.MustCompile(`</t[hd]>`)
	reTrClose    = regexp.MustCompile(`</tr>`)
	reTable      = regexp.MustCompile(`</?table[^>]*>`)
	reThead      = regexp.MustCompile(`</?thead[^>]*>`)
	reTbody      = regexp.MustCompile(`</?tbody[^>]*>`)
	reBr         = regexp.MustCompile(`<br\s*/?>`)
	rePara       = regexp.MustCompile(`</?p[^>]*>`)
	reDiv        = regexp.MustCompile(`</?div[^>]*>`)
	reCodeBlock  = regexp.MustCompile(`(?s)<ac:structured-macro[^>]*ac:name="code"[^>]*>.*?<ac:plain-text-body>\s*<!\[CDATA\[(.*?)\]\]>\s*</ac:plain-text-body>\s*</ac:structured-macro>`)
	rePanel      = regexp.MustCompile(`(?s)<ac:structured-macro[^>]*ac:name="(info|note|warning|tip)"[^>]*>(.*?)</ac:structured-macro>`)
	reLink       = regexp.MustCompile(`(?s)<a[^>]*href="([^"]*)"[^>]*>(.*?)</a>`)
	reConfLink   = regexp.MustCompile(`(?s)<ac:link[^>]*>.*?<ri:page[^>]*ri:content-title="([^"]*)"[^>]*/>.*?</ac:link>`)
	reConfLink2  = regexp.MustCompile(`(?s)<ac:link[^>]*>.*?<ac:plain-text-link-body>\s*<!\[CDATA\[(.*?)\]\]>.*?</ac:link>`)
	reImage      = regexp.MustCompile(`(?s)<ac:image[^>]*>.*?<ri:attachment[^>]*ri:filename="([^"]*)"[^>]*/>.*?</ac:image>`)
	reStrong     = regexp.MustCompile(`(?s)<strong[^>]*>(.*?)</strong>`)
	reEm         = regexp.MustCompile(`(?s)<em[^>]*>(.*?)</em>`)
	reUnderline  = regexp.MustCompile(`(?s)<u>(.*?)</u>`)
	reAllTags    = regexp.MustCompile(`<[^>]+>`)
	reBlankLines = regexp.MustCompile(`\n{3,}`)
	reTrailSpace = regexp.MustCompile(`[ \t]+\n`)
)

func htmlToText(body string) string {
	text := body

	// Headings
	text = reHeading.ReplaceAllStringFunc(text, func(s string) string {
		m := reHeading.FindStringSubmatch(s)
		level := int(m[1][0] - '0')
		return "\n" + strings.Repeat("#", level) + " " + m[2] + "\n"
	})

	// Lists
	text = reLi.ReplaceAllString(text, "\n  - ")
	text = reLiClose.ReplaceAllString(text, "")
	text = reList.ReplaceAllString(text, "\n")

	// Tables
	text = reTr.ReplaceAllString(text, "\n| ")
	text = reTd.ReplaceAllString(text, "")
	text = reTdClose.ReplaceAllString(text, " | ")
	text = reTrClose.ReplaceAllString(text, "")
	text = reTable.ReplaceAllString(text, "\n")
	text = reThead.ReplaceAllString(text, "")
	text = reTbody.ReplaceAllString(text, "")

	// Line breaks and paragraphs
	text = reBr.ReplaceAllString(text, "\n")
	text = rePara.ReplaceAllString(text, "\n")
	text = reDiv.ReplaceAllString(text, "\n")

	// Code blocks
	text = reCodeBlock.ReplaceAllString(text, "\n```\n$1\n```\n")

	// Panels
	text = rePanel.ReplaceAllStringFunc(text, func(s string) string {
		m := rePanel.FindStringSubmatch(s)
		return "\n[" + strings.ToUpper(m[1]) + "] " + m[2] + "\n"
	})

	// Links
	text = reLink.ReplaceAllString(text, "$2 ($1)")
	text = reConfLink.ReplaceAllString(text, "[$1]")
	text = reConfLink2.ReplaceAllString(text, "$1")

	// Images
	text = reImage.ReplaceAllString(text, "[image: $1]")

	// Bold, italic
	text = reStrong.ReplaceAllString(text, "**$1**")
	text = reEm.ReplaceAllString(text, "*$1*")
	text = reUnderline.ReplaceAllString(text, "$1")

	// Strip remaining tags
	text = reAllTags.ReplaceAllString(text, "")

	// Unescape HTML entities
	text = html.UnescapeString(text)

	// Clean up whitespace
	text = reBlankLines.ReplaceAllString(text, "\n\n")
	text = reTrailSpace.ReplaceAllString(text, "\n")

	return strings.TrimSpace(text)
}

// --- Commands ---

func cmdView(args []string) {
	if len(args) == 0 {
		fatal("Usage: wiki-cli view <page-id-or-url>")
	}
	host, pageID := resolvePage(args[0])

	apiURL := fmt.Sprintf("%s/rest/api/content/%s?expand=body.storage,space,version,ancestors", host, pageID)
	body, err := wikiGet(apiURL)
	if err != nil {
		fatal("%v", err)
	}
	var data map[string]interface{}
	if err := json.Unmarshal(body, &data); err != nil {
		fatal("JSON parse error: %v", err)
	}

	title := jsonStr(data, "title")
	spaceKey := jsonStr(data, "space", "key")
	spaceName := jsonStr(data, "space", "name")
	version := jsonStr(data, "version", "number")
	modBy := jsonStr(data, "version", "by", "displayName")
	modWhen := jsonStr(data, "version", "when")
	if len(modWhen) > 10 {
		modWhen = modWhen[:10]
	}
	id := jsonStr(data, "id")

	// Breadcrumb from ancestors
	ancestors := jsonArr(data, "ancestors")
	var breadcrumb string
	if len(ancestors) > 0 {
		parts := make([]string, 0, len(ancestors)+1)
		for _, a := range ancestors {
			parts = append(parts, jsonStr(a, "title"))
		}
		parts = append(parts, title)
		breadcrumb = strings.Join(parts, " > ")
	}

	pageURL := fmt.Sprintf("%s/spaces/%s/pages/%s", host, spaceKey, id)

	fmt.Println(title)
	maxLen := len(title) + 10
	if maxLen > 60 {
		maxLen = 60
	}
	fmt.Println(strings.Repeat("\u2500", maxLen))
	fmt.Printf("Space:     %s (%s)\n", spaceName, spaceKey)
	if breadcrumb != "" {
		fmt.Printf("Path:      %s\n", breadcrumb)
	}
	fmt.Printf("Version:   %s (by %s, %s)\n", version, modBy, modWhen)
	fmt.Printf("URL:       %s\n", pageURL)

	bodyHTML := jsonStr(data, "body", "storage", "value")
	if bodyHTML != "" {
		fmt.Printf("\n%s\n", htmlToText(bodyHTML))
	} else {
		fmt.Println("\n(no content)")
	}
}

func cmdSearch(args []string) {
	if len(args) == 0 {
		fatal("Usage: wiki-cli search <query>")
	}
	query := strings.Join(args, " ")
	host := wikiHost()
	url := fmt.Sprintf("%s/rest/api/content/search?cql=text~\"%s\"&limit=10", host, query)

	body, err := wikiGet(url)
	if err != nil {
		fatal("%v", err)
	}
	var data map[string]interface{}
	if err := json.Unmarshal(body, &data); err != nil {
		fatal("JSON parse error: %v", err)
	}

	results := jsonArr(data, "results")
	if len(results) == 0 {
		fmt.Println("No results found.")
		return
	}
	for _, r := range results {
		m := r.(map[string]interface{})
		id := jsonStr(m, "id")
		title := jsonStr(m, "title")
		typ := jsonStr(m, "type")
		space := jsonStr(m, "space", "name")
		if space == "" {
			space = "?"
		}
		links, _ := m["_links"].(map[string]interface{})
		webui := ""
		if links != nil {
			webui = fmt.Sprintf("%v", links["webui"])
		}
		fmt.Printf("%s  %s\n    %s in %s\n    %s%s\n\n", id, title, typ, space, host, webui)
	}
}

// --- Helpers ---

// pageRef is what we can statically extract from a page id or URL, before any
// network call. host is the scheme://host taken from the URL (empty if the
// input had none); pageID is set when directly available; space+title are set
// for legacy /display/ URLs that must be resolved to an id via the API.
type pageRef struct {
	host   string
	pageID string
	space  string
	title  string
}

func parsePageRef(input string) (pageRef, error) {
	input = strings.TrimSpace(input)

	// Bare numeric id
	if reNumericID.MatchString(input) {
		return pageRef{pageID: input}, nil
	}

	u, err := url.Parse(input)
	if err != nil {
		return pageRef{}, fmt.Errorf("invalid URL: %v", err)
	}

	var ref pageRef
	if u.Host != "" {
		scheme := u.Scheme
		if scheme == "" {
			scheme = "https"
		}
		ref.host = scheme + "://" + u.Host
	}

	// Modern /spaces/<KEY>/pages/<id>/... and legacy /pages/<id>
	if m := rePageID.FindStringSubmatch(u.Path); m != nil {
		ref.pageID = m[1]
		return ref, nil
	}

	// Legacy /pages/viewpage.action?pageId=<id>
	if id := u.Query().Get("pageId"); id != "" {
		ref.pageID = id
		return ref, nil
	}

	// Legacy /display/<SPACE>/<Title> — title has spaces encoded as '+',
	// resolved to an id via the API later.
	if m := reDisplay.FindStringSubmatch(u.Path); m != nil {
		ref.space = m[1]
		ref.title = strings.ReplaceAll(m[2], "+", " ")
		return ref, nil
	}

	return pageRef{}, fmt.Errorf("could not extract page reference from: %s", input)
}

var (
	rePageID    = regexp.MustCompile(`/pages/(\d+)`)
	reDisplay   = regexp.MustCompile(`^/display/([^/]+)/(.+)$`)
	reNumericID = regexp.MustCompile(`^\d+$`)
)

// resolvePage turns a page id or URL into the host and numeric page id to fetch.
// For legacy /display/<SPACE>/<Title> URLs it resolves the title to an id via the API.
func resolvePage(input string) (host, pageID string) {
	ref, err := parsePageRef(input)
	if err != nil {
		fatal("%v", err)
	}
	host = ref.host
	if host == "" {
		host = wikiHost()
	}
	if ref.pageID != "" {
		return host, ref.pageID
	}
	return host, resolveByTitle(host, ref.space, ref.title)
}

// resolveByTitle looks up a page id by space key + exact title.
func resolveByTitle(host, space, title string) string {
	q := url.Values{}
	q.Set("spaceKey", space)
	q.Set("title", title)
	q.Set("limit", "1")
	body, err := wikiGet(host + "/rest/api/content?" + q.Encode())
	if err != nil {
		fatal("%v", err)
	}
	var data map[string]interface{}
	if err := json.Unmarshal(body, &data); err != nil {
		fatal("JSON parse error: %v", err)
	}
	results := jsonArr(data, "results")
	if len(results) == 0 {
		fatal("No page titled %q found in space %s", title, space)
	}
	return jsonStr(results[0], "id")
}

func fatal(format string, args ...interface{}) {
	fmt.Fprintf(os.Stderr, "Error: "+format+"\n", args...)
	os.Exit(1)
}

// --- Main ---

func usage() {
	fmt.Fprintln(os.Stderr, `Usage: wiki-cli <command> [args]

Commands:
  view   <page-id-or-url>    Fetch and display a Confluence page
  search <query>              Search Confluence`)
	os.Exit(1)
}

func main() {
	if len(os.Args) < 2 {
		usage()
	}
	switch os.Args[1] {
	case "view":
		cmdView(os.Args[2:])
	case "search":
		cmdSearch(os.Args[2:])
	default:
		fmt.Fprintf(os.Stderr, "Unknown command: %s\n", os.Args[1])
		usage()
	}
}
