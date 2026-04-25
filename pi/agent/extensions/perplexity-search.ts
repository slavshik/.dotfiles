import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { homedir } from "node:os";

function getApiKey(): string | undefined {
  // Try environment variable first
  if (process.env.PERPLEXITY_KEY) return process.env.PERPLEXITY_KEY;
  if (process.env.PERPLEXITY_API_KEY) return process.env.PERPLEXITY_API_KEY;

  // Try reading from openclaw secrets file
  try {
    const envFile = resolve(homedir(), ".openclaw/secrets/perplexity.env");
    const content = readFileSync(envFile, "utf-8");
    const match = content.match(/PERPLEXITY_KEY="?([^"\n]+)"?/);
    if (match) return match[1];
  } catch {
    // File not found or unreadable
  }

  return undefined;
}

interface SearchRequest {
  query: string;
  count?: number;
}

const SearchParams = Type.Object({
  query: Type.String({ description: "Search query" }),
  count: Type.Optional(Type.Number({ description: "Number of results (default: 5, max: 10)", default: 5 })),
});

export default function (pi: ExtensionAPI) {
  const apiKey = getApiKey();

  if (!apiKey) {
    pi.on("session_start", async (_event, ctx) => {
      ctx.ui.notify(
        "perplexity-search: PERPLEXITY_KEY not set. Set in env or ~/.openclaw/secrets/perplexity.env",
        "warning",
      );
    });
  }

  pi.registerTool({
    name: "web_search",
    label: "Web Search",
    description:
      "Search the web using Perplexity AI. Returns summarized results from recent web sources. Use for fact-checking, current events, documentation lookups, or any information not in your training data.",
    promptSnippet: "Search the web via Perplexity",
    promptGuidelines: [
      "Use web_search for current information, recent events, API documentation, library version checks, or fact verification.",
      "Prefer web_search over reading docs manually when you need the latest version-specific API or configuration details.",
    ],
    parameters: SearchParams,

    async execute(_toolCallId, params, signal, onUpdate) {
      if (!apiKey) {
        return {
          content: [
            {
              type: "text" as const,
              text: "Perplexity API key not configured. Set PERPLEXITY_KEY environment variable.",
            },
          ],
          details: { error: true },
        };
      }

      const count = Math.min(params.count ?? 5, 10);
      onUpdate?.({ content: [{ type: "text", text: "Searching..." }] });

      try {
        const response = await fetch("https://api.perplexity.ai/chat/completions", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${apiKey}`,
          },
          body: JSON.stringify({
            model: "sonar",
            messages: [
              {
                role: "system",
                content:
                  "You are a web search assistant. Answer the user's query concisely using web results. " +
                  "Cite sources inline as [title](url). " +
                  "Return up to 3 relevant results per query in this format:\n\n" +
                  "## Query Results\n\n" +
                  "1. **[Title](URL)** — Date/Time\n" +
                  "   Brief description or key finding.\n\n" +
                  "Limit your response to factual, sourced information.",
              },
              {
                role: "user",
                content: params.query,
              },
            ],
            max_tokens: 2048,
            temperature: 0.1,
            search_domain_filter: null,
            return_images: false,
            return_related_questions: false,
            search_recency_filter: "month",
            top_p: 1,
            presence_penalty: 0,
            frequency_penalty: 1,
            web_search_options: { search_context_size: "medium" },
          }),
          signal,
        });

        if (!response.ok) {
          const errorText = await response.text();
          return {
            content: [
              { type: "text" as const, text: `Search failed (${response.status}): ${errorText.slice(0, 500)}` },
            ],
            details: { error: true, status: response.status },
          };
        }

        const data = (await response.json()) as {
          choices?: Array<{ message?: { content?: string } }>;
          citations?: string[];
        };
        const content = data.choices?.[0]?.message?.content ?? "No results found.";

        let text = content;
        const citations = data.citations ?? [];
        if (citations.length > 0) {
          text += "\n\n---\n**Sources:**\n";
          for (let i = 0; i < citations.length; i++) {
            text += `${i + 1}. ${citations[i]}\n`;
          }
        }

        return {
          content: [{ type: "text" as const, text }],
          details: { query: params.query, count, sourced: true },
        };
      } catch (err: unknown) {
        const message = err instanceof Error ? err.message : String(err);
        return {
          content: [{ type: "text" as const, text: `Search error: ${message}` }],
          details: { error: true },
        };
      }
    },
  });
}
