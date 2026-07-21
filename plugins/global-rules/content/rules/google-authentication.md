# Google Authentication

> Personal working rule, loaded in every project via `~/.claude/rules`.
> Formerly lived only in `~/aiwork/CLAUDE.md`.

- Google authentication material for Google-related skills/tools is stored under `~/.google-skills`.
- When a user asks to use Google APIs, Google Slides, Google Drive, or other Google services and authentication is required, first check for the existing auth/config under `~/.google-skills` and use it through the approved local tooling or API flow.
- Treat all files under `~/.google-skills` as sensitive credential material: never print, paste, copy into project files, expose in responses, or log token contents. Record only non-secret paths/status and report missing, expired, or unusable credentials as configuration errors.
