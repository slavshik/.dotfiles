package main

import (
	"encoding/json"
	"fmt"
	"html"
	"io"
	"net/http"
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
	t := os.Getenv("EVO_WIKI_PAT")
	if t == "" {
		fatal("EVO_WIKI_PAT not set")
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
	pageID := extractPageID(args[0])
	host := wikiHost()

	url := fmt.Sprintf("%s/rest/api/content/%s?expand=body.storage,space,version,ancestors", host, pageID)
	body, err := wikiGet(url)
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

var rePageID = regexp.MustCompile(`/pages/(\d+)`)

func extractPageID(input string) string {
	// Raw numeric ID
	matched, _ := regexp.MatchString(`^\d+$`, input)
	if matched {
		return input
	}
	// Extract from URL
	m := rePageID.FindStringSubmatch(input)
	if m != nil {
		return m[1]
	}
	fatal("Could not extract page ID from: %s", input)
	return ""
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
