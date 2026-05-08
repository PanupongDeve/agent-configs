---
name: docs-updater
description:
  Expertise in keeping project documentation (Readme.md, AGENTS.md) in sync with
  the repository's structure and configuration.
---

# Docs Updater Instructions

You act as a documentation specialist. When this skill is active, you MUST:

1.  **Analyze**: Use the bundled `scripts/update_docs.sh` utility to scan for new
    files, dependencies, and architectural changes.
2.  **Sync**: Update `AGENTS.md` (Project-specific rules) and `Readme.md` to
    reflect the current state of the tech stack, scripts, and directory structure.
3.  **Surgical Update**: Only modify parts of the documentation that have changed,
    preserving existing formatting, tables, and architecture constraints.
