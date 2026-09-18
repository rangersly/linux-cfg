import type { PluginInput, PluginOptions, Plugin, Hooks } from "@opencode-ai/plugin"

type Redirect = { tool: string; reason: string }

const REDIRECTS: Record<string, Redirect> = {
  grep: { tool: "grep", reason: "content search" },
  rg: { tool: "grep", reason: "content search" },
  ag: { tool: "grep", reason: "content search" },
  ack: { tool: "grep", reason: "content search" },
  cat: { tool: "read", reason: "file reading" },
  bat: { tool: "read", reason: "file reading" },
  less: { tool: "read", reason: "file reading" },
  more: { tool: "read", reason: "file reading" },
  head: { tool: "read", reason: "file reading" },
  tail: { tool: "read", reason: "file reading" },
  sed: { tool: "edit", reason: "file editing" },
  find: { tool: "glob", reason: "file discovery" },
  fd: { tool: "glob", reason: "file discovery" },
  tree: { tool: "glob", reason: "file discovery" },
  ls: { tool: "glob", reason: "listing files" },
  exa: { tool: "glob", reason: "listing files" },
  eza: { tool: "glob", reason: "listing files" },
  dir: { tool: "glob", reason: "listing files" },
  cd: { tool: "bash", reason: "changing directory" },
}

const SCANNERS = new Set(["grep", "rg", "ag", "ack", "find", "fd", "tree"])

const WRAPPERS = new Set([
  "sudo",
  "command",
  "builtin",
  "exec",
  "nohup",
  "time",
  "env",
  "nice",
  "timeout",
  "xargs",
])

const OPT_WITH_ARG = /^(?:-u|-g|-p|-C|-h|-r|-t|-U|-D|-n|-s|-I|-P|-d|-a|-E|-S|--user|--group|--prompt|--nice|--signal|--max-args|--replace|--delimiter|--arg-file|--eof|--max-chars|--unset)$/
const ASSIGN_RE = /^[A-Za-z_][A-Za-z0-9_]*=/

function splitSegments(input: string): { text: string; piped: boolean }[] {
  const segs: { text: string; piped: boolean }[] = []
  let cur = ""
  let quote: string | null = null
  let piped = false
  const push = () => {
    segs.push({ text: cur, piped })
    cur = ""
  }
  for (let i = 0; i < input.length; i++) {
    const ch = input[i]
    if (quote) {
      cur += ch
      if (ch === "\\" && quote === '"' && i + 1 < input.length) {
        cur += input[++i]
      } else if (ch === quote) {
        quote = null
      }
      continue
    }
    if (ch === "'" || ch === '"') {
      quote = ch
      cur += ch
      continue
    }
    if (ch === "\\" && i + 1 < input.length) {
      cur += ch + input[++i]
      continue
    }
    if (ch === "\n" || ch === ";") {
      push()
      piped = false
      continue
    }
    if (ch === "|" || ch === "&") {
      const isPipe = ch === "|" && input[i + 1] !== "|"
      push()
      piped = isPipe
      if (input[i + 1] === ch) i++
      continue
    }
    cur += ch
  }
  push()
  return segs
}

function effectiveCommand(segment: string): string[] {
  const tokens = segment.trim().replace(/^\(+/, "").split(/\s+/).filter(Boolean)
  let i = 0
  while (i < tokens.length) {
    const token = tokens[i]
    if (ASSIGN_RE.test(token)) {
      i++
      continue
    }
    if (token.startsWith("(")) {
      tokens[i] = token.replace(/^\(+/, "")
      if (!tokens[i]) i++
      continue
    }
    if (WRAPPERS.has(token)) {
      i++
      while (i < tokens.length) {
        const opt = tokens[i]
        if (opt.startsWith("-")) {
          i++
          if (OPT_WITH_ARG.test(opt) && i < tokens.length) i++
          continue
        }
        if (/^\d+(?:\.\d+)?[smhd]?$/.test(opt)) {
          i++
          continue
        }
        break
      }
      continue
    }
    break
  }
  return tokens.slice(i)
}

function substitutions(command: string): string[] {
  const found: string[] = []
  const re = /\$\(([^()]*)\)|`([^`]*)`/g
  let match: RegExpExecArray | null
  while ((match = re.exec(command))) found.push(match[1] ?? match[2] ?? "")
  return found
}

function guard(command: string): string | null {
  if (/#\s*confirm\s*$/i.test(command)) return null

  for (const segment of splitSegments(command)) {
    const tokens = effectiveCommand(segment.text)
    const name = tokens[0]
    if (!name) continue

    if (name === "git" && tokens[1] === "grep") {
      return message("git grep", "grep", "content search")
    }

    if ((name === "bash" || name === "sh" || name === "zsh") && tokens.includes("-c")) {
      const inner = tokens
        .slice(tokens.indexOf("-c") + 1)
        .join(" ")
        .replace(/^['"]|['"]$/g, "")
      const nested = guard(inner)
      if (nested) return nested
    }

    const redirect = REDIRECTS[name]
    if (redirect && (!segment.piped || SCANNERS.has(name))) {
      return message(name, redirect.tool, redirect.reason)
    }
  }

  for (const sub of substitutions(command)) {
    const nested = guard(sub)
    if (nested) return nested
  }
  return null
}

function message(name: string, tool: string, reason: string): string {
  if (tool === "bash") {
    return (
      `Command '${name}' was blocked. Use the \`bash\` tool's \`workdir\` parameter instead of \`${name}\` (${reason}).\n\n` +
      `Tip: If you really want to run it via bash, append a "# confirm" comment and retry.`
    )
  }
  return (
    `Command '${name}' was blocked. Use the \`${tool}\` tool instead of running shell commands (${reason}).\n\n` +
    `Tip: If you really want to run it via bash, append a "# confirm" comment and retry.`
  )
}

export default {
  id: "bash-guard",
  async server(_input: PluginInput, _options?: PluginOptions): Promise<Hooks> {
    return {
      "tool.execute.before": async (input, output) => {
        if (input.tool !== "bash") return
        const command: string | undefined = output.args.command
        if (!command) return
        const msg = guard(command)
        if (msg) throw new Error(msg)
      },
    }
  },
} satisfies { id: string; server: Plugin }
