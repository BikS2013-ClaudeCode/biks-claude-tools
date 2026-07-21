# Tool Creation

> Personal working rule, loaded in every project via `~/.claude/rules`.
> The repo-portable side of the tool conventions (the `docs/tools/<name>.md` layout,
> the "Tools" section in the project CLAUDE.md, and the reuse-before-new-script rule)
> stays in the replicated `<structure-and-conventions>` documentation map.

- Tools created in the context of a project are always written in TypeScript.
- **Tool creation is MANDATORY via `/tool-conventions scaffold <tool-name>` when that installed/configured command is available; otherwise dispatch the `tool-doc-config-architect` subagent directly (`~/.claude/agents/tool-doc-config-architect.md`; in Pi-based sessions: `~/.pi/agents/tool-doc-config-architect.md`).** Do NOT scaffold a tool's documentation file or its `~/.tool-agents/<tool-name>/` configuration folder by hand under any circumstances. The subagent owns the full specification — the documentation file format (the `<toolName>` XML block under `docs/tools/<tool-name>.md`), the configuration folder structure and modes (`~/.tool-agents/<tool-name>/` at `0700`, `.env` at `0600`), the four-tier env-var resolution chain (shell env → `~/.tool-agents/<name>/.env` → local `.env` → CLI flags, lowest to highest priority), the vendor-canonical LLM provider env-var names (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GOOGLE_API_KEY`, `AZURE_OPENAI_*`, `AZURE_AI_INFERENCE_*`, `OLLAMA_HOST`, `LITELLM_*`), and the required set of eight standard LLM providers every LLM-enabled tool must support out of the box. Read the subagent prompt to inspect the full specification.
- For existing tools, run `/tool-conventions audit <tool-name>` (or dispatch the `tool-doc-config-architect` subagent in audit mode) to verify conformance against the same specification.
