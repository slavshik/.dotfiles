import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const OLLAMA_URLS = [
  "http://localhost:11434/v1",
  "http://192.168.0.6:11434/v1",
  "https://wkwkwk.ngrok.app/v1",
  "http://wkwkwk.ngrok.app/v1",
];

async function findOllama(): Promise<string | undefined> {
  for (const url of OLLAMA_URLS) {
    try {
      const res = await fetch(`${url}/models`, { signal: AbortSignal.timeout(2000) });
      if (res.ok) return url;
    } catch {
      // try next
    }
  }
}

export default async function (pi: ExtensionAPI) {
  const baseUrl = await findOllama();

  if (!baseUrl) {
    pi.on("session_start", (_event, ctx) => {
      ctx.ui.notify("ollama: unreachable at localhost, 192.168.0.6, or ngrok", "warning");
    });
    return;
  }

  pi.registerProvider("ollama", {
    baseUrl,
    apiKey: "ollama",
    api: "openai-completions",
    models: [
      {
        id: "qwen2.5-coder:1.5b",
        name: "Qwen Coder 1.5B (ollama)",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 32768,
        maxTokens: 8192,
      },
      {
        id: "qwen2.5-coder:14b",
        name: "Qwen Coder 14B (ollama)",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 32768,
        maxTokens: 8192,
      },
      {
        id: "gemma4:latest",
        name: "Gemma 4 (ollama)",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 32768,
        maxTokens: 8192,
      },
      {
        id: "gpt-oss:20b",
        name: "GPT-OSS 20B (ollama)",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 32768,
        maxTokens: 8192,
      },
    ],
  });

  pi.on("session_start", (_event, ctx) => {
    ctx.ui.notify(`ollama connected via ${new URL(baseUrl).hostname}`, "info");
  });
}
