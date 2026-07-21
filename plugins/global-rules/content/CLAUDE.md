<!-- Instruction layout:
     1. Repo-portable documentation map: master copy in ~/.claude/structure-and-conventions.md;
        the SessionStart hook ~/.claude/scripts/sync-claude-md.sh syncs it as the
        <structure-and-conventions> block into each project's CLAUDE.md so the map travels
        with the repo. It is intentionally NOT duplicated here.
     2. Personal working rules (pre-implementation pipeline, dependency vetting, tool
        creation, interaction preferences, config no-fallback, database naming, Google
        auth, GitHub-sourced skills registry): one file each under ~/.claude/rules/
        (symlink to claude-workdocs/.claude/rules/). They load in every project on this
        machine and are never written into project repos. -->

## Python Instructions 
- When you install or run Python packages, you must ALWAYS consider that ALL Python code must work under a virtual environment controlled by the UV tool. So, you must always prefix any Python code you run with the source .venv/bin/activate command, while you must always use the 'UV add' command to install any Python packages.

- Never use SQLAlchemy to access databasesin Python projects. If an ORM library is needed prefer the pydapper.

- Use always the FastAPI library, when you have to implement REST APIs in PYTHON projects.

- Be aware that the Postgres database is running in a docker. So, when you want to run PostgreSQL commands, you must run them in Docker.

- If while developing the project, happens the user to ask you to create or change a skill, you must create a folder named according to the following pattern [skill-name]-docs and create all the necessary documentation, plans, designs, etc inside this folder. This folder must keep only material related to the skill development; nothing else.
