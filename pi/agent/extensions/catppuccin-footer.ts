import type { AssistantMessage } from "@mariozechner/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

const CATPPUCCIN = {
  base: "#1e1e2e",
  mauve: "#cba6f7",
  lavender: "#b4befe",
  green: "#a6e3a1",
  teal: "#94e2d5",
};

function fg(hex: string, text: string): string {
  const [r, g, b] = [hex.slice(1, 3), hex.slice(3, 5), hex.slice(5, 7)].map((v) => Number.parseInt(v, 16));
  return `\x1b[38;2;${r};${g};${b}m${text}`;
}

function bg(hex: string, text: string): string {
  const [r, g, b] = [hex.slice(1, 3), hex.slice(3, 5), hex.slice(5, 7)].map((v) => Number.parseInt(v, 16));
  return `\x1b[48;2;${r};${g};${b}m${text}`;
}

function bold(text: string): string {
  return `\x1b[1m${text}\x1b[22m`;
}

function reset(text: string): string {
  return `${text}\x1b[0m`;
}

function modelChip(modelId: string): string {
  return reset(
    fg(CATPPUCCIN.mauve, "") +
      bg(CATPPUCCIN.mauve, fg(CATPPUCCIN.base, bold(" AI "))) +
      bg(CATPPUCCIN.lavender, fg(CATPPUCCIN.mauve, "")) +
      bg(CATPPUCCIN.lavender, fg(CATPPUCCIN.base, bold(` ${modelId} `))) +
      fg(CATPPUCCIN.lavender, ""),
  );
}

function branchChip(branch: string): string {
  return reset(
    fg(CATPPUCCIN.green, "") +
      bg(CATPPUCCIN.green, fg(CATPPUCCIN.base, bold("  "))) +
      bg(CATPPUCCIN.teal, fg(CATPPUCCIN.green, "")) +
      bg(CATPPUCCIN.teal, fg(CATPPUCCIN.base, bold(` ${branch} `))) +
      fg(CATPPUCCIN.teal, ""),
  );
}

function formatNumber(n: number): string {
  if (n < 1000) return `${n}`;
  if (n < 10_000) return `${(n / 1000).toFixed(1)}k`;
  return `${Math.round(n / 1000)}k`;
}

function getTotalCost(ctx: ExtensionContext): number {
  let cost = 0;
  for (const entry of ctx.sessionManager.getBranch()) {
    if (entry.type === "message" && entry.message.role === "assistant") {
      const message = entry.message as AssistantMessage;
      cost += message.usage.cost.total;
    }
  }
  return cost;
}

function installFooter(ctx: ExtensionContext): void {
  ctx.ui.setFooter((tui, theme, footerData) => {
    const unsub = footerData.onBranchChange(() => tui.requestRender());

    return {
      dispose: unsub,
      invalidate() {},
      render(width: number): string[] {
        const usage = ctx.getContextUsage();
        const contextWindow = ctx.model?.contextWindow;
        const totalCost = getTotalCost(ctx);
        const percent = usage && contextWindow ? Math.min(999, Math.round((usage.tokens / contextWindow) * 100)) : undefined;

        const usageLabel = theme.fg("dim", "ctx ");
        const usageValue = usage
          ? contextWindow
            ? `${formatNumber(usage.tokens)}/${formatNumber(contextWindow)} ${percent}%`
            : formatNumber(usage.tokens)
          : "n/a";
        const usageText = usageLabel + theme.fg("warning", usageValue);

        const costText = totalCost > 0
          ? theme.fg("dim", "  ") + theme.fg("success", "$") + theme.fg("warning", totalCost.toFixed(3))
          : "";

        const left = usageText + costText;

        const statuses = [...footerData.getExtensionStatuses().values()].filter(Boolean);
        const rightParts: string[] = [];
        if (statuses.length > 0) rightParts.push(statuses.join(theme.fg("dim", " · ")));
        rightParts.push(modelChip(ctx.model?.id || "no-model"));
        const branch = footerData.getGitBranch();
        if (branch) rightParts.push(branchChip(branch));
        const right = rightParts.join(theme.fg("dim", " · "));

        const pad = " ".repeat(Math.max(1, width - visibleWidth(left) - visibleWidth(right)));
        return [truncateToWidth(left + pad + right, width)];
      },
    };
  });
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    installFooter(ctx);
  });

  pi.on("model_select", async (_event, ctx) => {
    installFooter(ctx);
  });
}
