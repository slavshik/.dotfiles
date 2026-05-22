/**
 * Anthropic provider routed through an HTTP(S) forward proxy.
 *
 * Registers an "anthropic-proxied" provider whose Anthropic SDK client uses
 * undici's ProxyAgent (driven by HTTPS_PROXY / HTTP_PROXY env vars) so chat
 * traffic goes through the same forward proxy used for `ai claude`.
 *
 * OAuth login/refresh is delegated to pi-ai's built-in flow (modern
 * platform.claude.com endpoints + localhost callback server), which fetches
 * direct rather than via the proxy.
 *
 * Usage:
 *   ai pi
 *   /login                                       # then pick "Anthropic via proxy"
 *   /model anthropic-proxied/claude-opus-4-6
 */

import { existsSync, realpathSync } from "node:fs";
import { createRequire } from "node:module";
import {
	type Api,
	type AssistantMessage,
	type AssistantMessageEventStream,
	calculateCost,
	type Context,
	createAssistantMessageEventStream,
	type ImageContent,
	type Message,
	type Model,
	type OAuthCredentials,
	type SimpleStreamOptions,
	type StopReason,
	type TextContent,
	type ThinkingContent,
	type Tool,
	type ToolCall,
	type ToolResultMessage,
} from "@mariozechner/pi-ai";
import {
	loginAnthropic as builtinLoginAnthropic,
	refreshAnthropicToken as builtinRefreshAnthropicToken,
} from "@mariozechner/pi-ai/oauth";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

// @anthropic-ai/sdk and undici aren't in pi's extension allowlist (loader.ts
// only exposes @mariozechner/* + typebox), but they live in pi's own
// node_modules. Anchor a CommonJS require on the pi binary so Node walks up
// to that directory and resolves them.
function makePeerRequire(): NodeRequire {
	const candidates = [
		`${process.env.HOME}/.bun/bin/pi`,
		`${process.env.HOME}/.npm/bin/pi`,
		`${process.env.HOME}/.local/bin/pi`,
		"/usr/local/bin/pi",
		"/opt/homebrew/bin/pi",
	];
	for (const p of candidates) {
		if (!existsSync(p)) continue;
		try {
			const req = createRequire(realpathSync(p));
			req.resolve("@anthropic-ai/sdk");
			req.resolve("undici");
			return req;
		} catch {
			// try next candidate
		}
	}
	throw new Error(
		"anthropic-proxy: couldn't locate the pi install that has @anthropic-ai/sdk and undici. " +
			"Edit the candidates list in this file if pi lives elsewhere.",
	);
}

const peerRequire = makePeerRequire();
const anthropicSdkModule = peerRequire("@anthropic-ai/sdk") as { default: any; Anthropic?: any };
const AnthropicCtor: any = anthropicSdkModule.default ?? anthropicSdkModule.Anthropic;
const { fetch: undiciFetch, ProxyAgent } = peerRequire("undici") as {
	fetch: typeof fetch;
	ProxyAgent: new (url: string) => unknown;
};

type ContentBlockParam = any;
type MessageCreateParamsStreaming = any;

// ============================================================================
// Proxy-aware fetch
// ============================================================================

function readProxyUrl(): string | undefined {
	return (
		process.env.HTTPS_PROXY ??
		process.env.https_proxy ??
		process.env.HTTP_PROXY ??
		process.env.http_proxy ??
		undefined
	);
}

const proxyUrl = readProxyUrl();
const dispatcher = proxyUrl ? new ProxyAgent(proxyUrl) : undefined;

const proxiedFetch = (dispatcher
	? ((input: unknown, init?: unknown) =>
			undiciFetch(input as Parameters<typeof undiciFetch>[0], {
				...(init as Parameters<typeof undiciFetch>[1]),
				dispatcher,
			}))
	: (globalThis.fetch as unknown)) as typeof fetch;

// ============================================================================
// OAuth — delegated to pi-ai's built-in implementation
// ============================================================================
//
// Earlier this file inlined the upstream custom-provider-anthropic example's
// OAuth flow, which posts to https://console.anthropic.com/v1/oauth/token —
// Anthropic has since migrated to https://platform.claude.com. Pi-ai's built-in
// loginAnthropic uses the modern URL and the localhost callback flow, so we
// reuse it. OAuth fetches go via the system fetch (no proxy); that's fine
// because platform.claude.com is reachable directly. Only the chat stream
// itself traverses the proxy.

const refreshAnthropicToken = (credentials: OAuthCredentials): Promise<OAuthCredentials> =>
	builtinRefreshAnthropicToken(credentials.refresh);

// ============================================================================
// Streaming impl (forked from upstream custom-provider-anthropic)
// ============================================================================

const claudeCodeTools = [
	"Read",
	"Write",
	"Edit",
	"Bash",
	"Grep",
	"Glob",
	"AskUserQuestion",
	"TodoWrite",
	"WebFetch",
	"WebSearch",
];
const ccToolLookup = new Map(claudeCodeTools.map((t) => [t.toLowerCase(), t]));
const toClaudeCodeName = (name: string) => ccToolLookup.get(name.toLowerCase()) ?? name;
const fromClaudeCodeName = (name: string, tools?: Tool[]) => {
	const lowerName = name.toLowerCase();
	const matched = tools?.find((t) => t.name.toLowerCase() === lowerName);
	return matched?.name ?? name;
};

function isOAuthToken(apiKey: string): boolean {
	return apiKey.includes("sk-ant-oat");
}

function sanitizeSurrogates(text: string): string {
	return text.replace(/[\uD800-\uDFFF]/g, "�");
}

function convertContentBlocks(
	content: (TextContent | ImageContent)[],
): string | Array<{ type: "text"; text: string } | { type: "image"; source: any }> {
	const hasImages = content.some((c) => c.type === "image");
	if (!hasImages) {
		return sanitizeSurrogates(content.map((c) => (c as TextContent).text).join("\n"));
	}

	const blocks = content.map((block) => {
		if (block.type === "text") {
			return { type: "text" as const, text: sanitizeSurrogates(block.text) };
		}
		return {
			type: "image" as const,
			source: {
				type: "base64" as const,
				media_type: block.mimeType,
				data: block.data,
			},
		};
	});

	if (!blocks.some((b) => b.type === "text")) {
		blocks.unshift({ type: "text" as const, text: "(see attached image)" });
	}

	return blocks;
}

function convertMessages(messages: Message[], isOAuth: boolean, _tools?: Tool[]): any[] {
	const params: any[] = [];

	for (let i = 0; i < messages.length; i++) {
		const msg = messages[i];

		if (msg.role === "user") {
			if (typeof msg.content === "string") {
				if (msg.content.trim()) {
					params.push({ role: "user", content: sanitizeSurrogates(msg.content) });
				}
			} else {
				const blocks: ContentBlockParam[] = msg.content.map((item) =>
					item.type === "text"
						? { type: "text" as const, text: sanitizeSurrogates(item.text) }
						: {
								type: "image" as const,
								source: {
									type: "base64" as const,
									media_type: item.mimeType as any,
									data: item.data,
								},
							},
				);
				if (blocks.length > 0) {
					params.push({ role: "user", content: blocks });
				}
			}
		} else if (msg.role === "assistant") {
			const blocks: ContentBlockParam[] = [];
			for (const block of msg.content) {
				if (block.type === "text" && block.text.trim()) {
					blocks.push({ type: "text", text: sanitizeSurrogates(block.text) });
				} else if (block.type === "thinking" && block.thinking.trim()) {
					if ((block as ThinkingContent).thinkingSignature) {
						blocks.push({
							type: "thinking" as any,
							thinking: sanitizeSurrogates(block.thinking),
							signature: (block as ThinkingContent).thinkingSignature!,
						});
					} else {
						blocks.push({ type: "text", text: sanitizeSurrogates(block.thinking) });
					}
				} else if (block.type === "toolCall") {
					blocks.push({
						type: "tool_use",
						id: block.id,
						name: isOAuth ? toClaudeCodeName(block.name) : block.name,
						input: block.arguments,
					});
				}
			}
			if (blocks.length > 0) {
				params.push({ role: "assistant", content: blocks });
			}
		} else if (msg.role === "toolResult") {
			const toolResults: any[] = [];
			toolResults.push({
				type: "tool_result",
				tool_use_id: msg.toolCallId,
				content: convertContentBlocks(msg.content),
				is_error: msg.isError,
			});

			let j = i + 1;
			while (j < messages.length && messages[j].role === "toolResult") {
				const nextMsg = messages[j] as ToolResultMessage;
				toolResults.push({
					type: "tool_result",
					tool_use_id: nextMsg.toolCallId,
					content: convertContentBlocks(nextMsg.content),
					is_error: nextMsg.isError,
				});
				j++;
			}
			i = j - 1;
			params.push({ role: "user", content: toolResults });
		}
	}

	if (params.length > 0) {
		const last = params[params.length - 1];
		if (last.role === "user" && Array.isArray(last.content)) {
			const lastBlock = last.content[last.content.length - 1];
			if (lastBlock) {
				lastBlock.cache_control = { type: "ephemeral" };
			}
		}
	}

	return params;
}

function convertTools(tools: Tool[], isOAuth: boolean): any[] {
	return tools.map((tool) => ({
		name: isOAuth ? toClaudeCodeName(tool.name) : tool.name,
		description: tool.description,
		input_schema: {
			type: "object",
			properties: (tool.parameters as any).properties || {},
			required: (tool.parameters as any).required || [],
		},
	}));
}

function mapStopReason(reason: string): StopReason {
	switch (reason) {
		case "end_turn":
		case "pause_turn":
		case "stop_sequence":
			return "stop";
		case "max_tokens":
			return "length";
		case "tool_use":
			return "toolUse";
		default:
			return "error";
	}
}

function streamProxiedAnthropic(
	model: Model<Api>,
	context: Context,
	options?: SimpleStreamOptions,
): AssistantMessageEventStream {
	const stream = createAssistantMessageEventStream();

	(async () => {
		const output: AssistantMessage = {
			role: "assistant",
			content: [],
			api: model.api,
			provider: model.provider,
			model: model.id,
			usage: {
				input: 0,
				output: 0,
				cacheRead: 0,
				cacheWrite: 0,
				totalTokens: 0,
				cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
			},
			stopReason: "stop",
			timestamp: Date.now(),
		};

		try {
			const apiKey = options?.apiKey ?? "";
			const isOAuth = isOAuthToken(apiKey);

			const betaFeatures = [
				"fine-grained-tool-streaming-2025-05-14",
				"interleaved-thinking-2025-05-14",
			];
			const clientOptions: any = {
				baseURL: model.baseUrl,
				dangerouslyAllowBrowser: true,
				fetch: proxiedFetch,
			};

			if (isOAuth) {
				clientOptions.apiKey = null;
				clientOptions.authToken = apiKey;
				clientOptions.defaultHeaders = {
					accept: "application/json",
					"anthropic-dangerous-direct-browser-access": "true",
					"anthropic-beta": `claude-code-20250219,oauth-2025-04-20,${betaFeatures.join(",")}`,
					"user-agent": "claude-cli/2.1.2 (external, cli)",
					"x-app": "cli",
				};
			} else {
				clientOptions.apiKey = apiKey;
				clientOptions.defaultHeaders = {
					accept: "application/json",
					"anthropic-dangerous-direct-browser-access": "true",
					"anthropic-beta": betaFeatures.join(","),
				};
			}

			const client = new AnthropicCtor(clientOptions);

			const params: MessageCreateParamsStreaming = {
				model: model.id,
				messages: convertMessages(context.messages, isOAuth, context.tools),
				max_tokens: options?.maxTokens || Math.floor(model.maxTokens / 3),
				stream: true,
			};

			if (isOAuth) {
				params.system = [
					{
						type: "text",
						text: "You are Claude Code, Anthropic's official CLI for Claude.",
						cache_control: { type: "ephemeral" },
					},
				];
				if (context.systemPrompt) {
					params.system.push({
						type: "text",
						text: sanitizeSurrogates(context.systemPrompt),
						cache_control: { type: "ephemeral" },
					});
				}
			} else if (context.systemPrompt) {
				params.system = [
					{
						type: "text",
						text: sanitizeSurrogates(context.systemPrompt),
						cache_control: { type: "ephemeral" },
					},
				];
			}

			if (context.tools) {
				params.tools = convertTools(context.tools, isOAuth);
			}

			if (options?.reasoning && model.reasoning) {
				const defaultBudgets: Record<string, number> = {
					minimal: 1024,
					low: 4096,
					medium: 10240,
					high: 20480,
				};
				const customBudget =
					options.thinkingBudgets?.[options.reasoning as keyof typeof options.thinkingBudgets];
				params.thinking = {
					type: "enabled",
					budget_tokens: customBudget ?? defaultBudgets[options.reasoning] ?? 10240,
				};
			}

			const anthropicStream = client.messages.stream(
				{ ...params },
				{ signal: options?.signal },
			);
			stream.push({ type: "start", partial: output });

			type Block = (ThinkingContent | TextContent | (ToolCall & { partialJson: string })) & {
				index: number;
			};
			const blocks = output.content as Block[];

			for await (const event of anthropicStream) {
				if (event.type === "message_start") {
					output.usage.input = event.message.usage.input_tokens || 0;
					output.usage.output = event.message.usage.output_tokens || 0;
					output.usage.cacheRead = (event.message.usage as any).cache_read_input_tokens || 0;
					output.usage.cacheWrite =
						(event.message.usage as any).cache_creation_input_tokens || 0;
					output.usage.totalTokens =
						output.usage.input +
						output.usage.output +
						output.usage.cacheRead +
						output.usage.cacheWrite;
					calculateCost(model, output.usage);
				} else if (event.type === "content_block_start") {
					if (event.content_block.type === "text") {
						output.content.push({ type: "text", text: "", index: event.index } as any);
						stream.push({
							type: "text_start",
							contentIndex: output.content.length - 1,
							partial: output,
						});
					} else if (event.content_block.type === "thinking") {
						output.content.push({
							type: "thinking",
							thinking: "",
							thinkingSignature: "",
							index: event.index,
						} as any);
						stream.push({
							type: "thinking_start",
							contentIndex: output.content.length - 1,
							partial: output,
						});
					} else if (event.content_block.type === "tool_use") {
						output.content.push({
							type: "toolCall",
							id: event.content_block.id,
							name: isOAuth
								? fromClaudeCodeName(event.content_block.name, context.tools)
								: event.content_block.name,
							arguments: {},
							partialJson: "",
							index: event.index,
						} as any);
						stream.push({
							type: "toolcall_start",
							contentIndex: output.content.length - 1,
							partial: output,
						});
					}
				} else if (event.type === "content_block_delta") {
					const index = blocks.findIndex((b) => b.index === event.index);
					const block = blocks[index];
					if (!block) continue;

					if (event.delta.type === "text_delta" && block.type === "text") {
						block.text += event.delta.text;
						stream.push({
							type: "text_delta",
							contentIndex: index,
							delta: event.delta.text,
							partial: output,
						});
					} else if (event.delta.type === "thinking_delta" && block.type === "thinking") {
						block.thinking += event.delta.thinking;
						stream.push({
							type: "thinking_delta",
							contentIndex: index,
							delta: event.delta.thinking,
							partial: output,
						});
					} else if (event.delta.type === "input_json_delta" && block.type === "toolCall") {
						(block as any).partialJson += event.delta.partial_json;
						try {
							block.arguments = JSON.parse((block as any).partialJson);
						} catch {}
						stream.push({
							type: "toolcall_delta",
							contentIndex: index,
							delta: event.delta.partial_json,
							partial: output,
						});
					} else if (event.delta.type === "signature_delta" && block.type === "thinking") {
						block.thinkingSignature =
							(block.thinkingSignature || "") + (event.delta as any).signature;
					}
				} else if (event.type === "content_block_stop") {
					const index = blocks.findIndex((b) => b.index === event.index);
					const block = blocks[index];
					if (!block) continue;

					delete (block as any).index;
					if (block.type === "text") {
						stream.push({
							type: "text_end",
							contentIndex: index,
							content: block.text,
							partial: output,
						});
					} else if (block.type === "thinking") {
						stream.push({
							type: "thinking_end",
							contentIndex: index,
							content: block.thinking,
							partial: output,
						});
					} else if (block.type === "toolCall") {
						try {
							block.arguments = JSON.parse((block as any).partialJson);
						} catch {}
						delete (block as any).partialJson;
						stream.push({
							type: "toolcall_end",
							contentIndex: index,
							toolCall: block,
							partial: output,
						});
					}
				} else if (event.type === "message_delta") {
					if ((event.delta as any).stop_reason) {
						output.stopReason = mapStopReason((event.delta as any).stop_reason);
					}
					output.usage.input = (event.usage as any).input_tokens || 0;
					output.usage.output = (event.usage as any).output_tokens || 0;
					output.usage.cacheRead = (event.usage as any).cache_read_input_tokens || 0;
					output.usage.cacheWrite = (event.usage as any).cache_creation_input_tokens || 0;
					output.usage.totalTokens =
						output.usage.input +
						output.usage.output +
						output.usage.cacheRead +
						output.usage.cacheWrite;
					calculateCost(model, output.usage);
				}
			}

			if (options?.signal?.aborted) {
				throw new Error("Request was aborted");
			}

			stream.push({
				type: "done",
				reason: output.stopReason as "stop" | "length" | "toolUse",
				message: output,
			});
			stream.end();
		} catch (error) {
			for (const block of output.content) delete (block as any).index;
			output.stopReason = options?.signal?.aborted ? "aborted" : "error";
			output.errorMessage = error instanceof Error ? error.message : JSON.stringify(error);
			stream.push({ type: "error", reason: output.stopReason, error: output });
			stream.end();
		}
	})();

	return stream;
}

// ============================================================================
// Registration
// ============================================================================

export default function (pi: ExtensionAPI) {
	pi.registerProvider("anthropic-proxied", {
		baseUrl: "https://api.anthropic.com",
		apiKey: "ANTHROPIC_PROXIED_API_KEY",
		api: "anthropic-messages-proxied",
		models: [
			{
				id: "claude-opus-4-6",
				name: "Claude Opus 4.6 (proxied)",
				reasoning: true,
				input: ["text", "image"],
				cost: { input: 5, output: 25, cacheRead: 0.5, cacheWrite: 6.25 },
				contextWindow: 1_000_000,
				maxTokens: 128_000,
			},
			{
				id: "claude-opus-4-5",
				name: "Claude Opus 4.5 (proxied)",
				reasoning: true,
				input: ["text", "image"],
				cost: { input: 5, output: 25, cacheRead: 0.5, cacheWrite: 6.25 },
				contextWindow: 200_000,
				maxTokens: 64_000,
			},
			{
				id: "claude-sonnet-4-6",
				name: "Claude Sonnet 4.6 (proxied)",
				reasoning: true,
				input: ["text", "image"],
				cost: { input: 3, output: 15, cacheRead: 0.3, cacheWrite: 3.75 },
				contextWindow: 1_000_000,
				maxTokens: 64_000,
			},
			{
				id: "claude-sonnet-4-5",
				name: "Claude Sonnet 4.5 (proxied)",
				reasoning: true,
				input: ["text", "image"],
				cost: { input: 3, output: 15, cacheRead: 0.3, cacheWrite: 3.75 },
				contextWindow: 200_000,
				maxTokens: 64_000,
			},
			{
				id: "claude-haiku-4-5",
				name: "Claude Haiku 4.5 (proxied)",
				reasoning: true,
				input: ["text", "image"],
				cost: { input: 1, output: 5, cacheRead: 0.1, cacheWrite: 1.25 },
				contextWindow: 200_000,
				maxTokens: 64_000,
			},
		],
		oauth: {
			name: "Anthropic via proxy (Claude Pro/Max)",
			login: builtinLoginAnthropic,
			refreshToken: refreshAnthropicToken,
			getApiKey: (cred) => cred.access,
		},
		streamSimple: streamProxiedAnthropic,
	});

	pi.on?.("session_start", (_event, ctx) => {
		const msg = proxyUrl
			? `anthropic-proxied: routing via ${proxyUrl}`
			: "anthropic-proxied: HTTPS_PROXY/HTTP_PROXY not set — using direct fetch";
		ctx.ui?.notify?.(msg, proxyUrl ? "info" : "warning");
	});
}
