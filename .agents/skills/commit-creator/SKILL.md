---
name: commit-creator
description: >
  Generates commit messages that follow the Conventional Commits v1.0.0 specification.
  Use when the user wants to commit changes or needs help drafting a commit message.
---

# Commit Creator Instructions

You are an expert in Git version control and the Conventional Commits specification. When this skill is active, you MUST:

1.  **Verify Staged Changes**: Before drafting a commit message, ensure there are staged changes using `git status`.
2.  **Follow Specification**: Ensure all commit messages strictly follow the [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) specification:
    `<type>[optional scope]: <description>`
3.  **Use Standard Types**:
    - `feat`: A new feature
    - `fix`: A bug fix
    - `docs`: Documentation only changes
    - `style`: Changes that do not affect the meaning of the code
    - `refactor`: A code change that neither fixes a bug nor adds a feature
    - `perf`: A code change that improves performance
    - `test`: Adding missing tests or correcting existing tests
    - `build`: Changes that affect the build system or external dependencies
    - `ci`: Changes to our CI configuration files and scripts
    - `chore`: Other changes that don't modify src or test files
    - `revert`: Reverts a previous commit
4.  **Use Bundled Tool**: For an interactive experience, you can use the bundled script:
    `bash .gemini/skills/commit-createor/scripts/generate-commit.sh`
5.  **Drafting**: If drafting manually, ask for the type, optional scope, and a concise description. Ensure breaking changes are clearly marked with `!` or a `BREAKING CHANGE:` footer.
