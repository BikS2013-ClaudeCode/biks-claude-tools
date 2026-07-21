# Configuration Settings — No Fallbacks

> Personal working rule, loaded in every project via `~/.claude/rules`.

- NEVER create fallback solutions for configuration settings. Whenever a configuration setting is not provided, raise the appropriate exception — never substitute the missing value with a default or fallback.
- If the user explicitly asks for an exception to this rule, write the exception in the project's memory file before implementing it.
