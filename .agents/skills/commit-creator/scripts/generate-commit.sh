#!/bin/bash

# Conventional Commits Generator
# Adheres to v1.0.0 specification

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we are in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo -e "${RED}Error: Not a git repository.${NC}"
    exit 1
fi

# Check for staged changes
STAGED_FILES=$(git diff --cached --name-only)
if [ -z "$STAGED_FILES" ]; then
    echo -e "${YELLOW}Warning: No staged changes found.${NC}"
    echo "Please stage your changes before running this script (e.g., git add .)"
    exit 0
fi

echo -e "${BLUE}--- Conventional Commit Generator ---${NC}"

# 1. Select Type
echo "Select the type of change:"
options=("feat: A new feature" "fix: A bug fix" "docs: Documentation only changes" "style: Changes that do not affect the meaning of the code" "refactor: A code change that neither fixes a bug nor adds a feature" "perf: A code change that improves performance" "test: Adding missing tests or correcting existing tests" "build: Changes that affect the build system or external dependencies" "ci: Changes to our CI configuration files and scripts" "chore: Other changes that don't modify src or test files" "revert: Reverts a previous commit")

# Use a custom menu if select is not behaving well in some terminals, 
# but select is standard for bash.
PS3="Enter number (1-11): "
select opt in "${options[@]}"; do
    case $opt in
        "feat: A new feature") type="feat"; break;;
        "fix: A bug fix") type="fix"; break;;
        "docs: Documentation only changes") type="docs"; break;;
        "style: Changes that do not affect the meaning of the code") type="style"; break;;
        "refactor: A code change that neither fixes a bug nor adds a feature") type="refactor"; break;;
        "perf: A code change that improves performance") type="perf"; break;;
        "test: Adding missing tests or correcting existing tests") type="test"; break;;
        "build: Changes that affect the build system or external dependencies") type="build"; break;;
        "ci: Changes to our CI configuration files and scripts") type="ci"; break;;
        "chore: Other changes that don't modify src or test files") type="chore"; break;;
        "revert: Reverts a previous commit") type="revert"; break;;
        *) echo "Invalid option $REPLY";;
    esac
done

# 2. Input Scope (Optional)
echo -n "Enter the scope of this change (optional, e.g., component name): "
read scope
if [ -n "$scope" ]; then
    scope="($scope)"
fi

# 3. Breaking Change?
echo -n "Is this a breaking change? (y/N): "
read is_breaking
breaking_mark=""
breaking_footer=""
if [[ "$is_breaking" =~ ^[Yy]$ ]]; then
    breaking_mark="!"
    echo -n "Enter breaking change description: "
    read breaking_desc
    breaking_footer="BREAKING CHANGE: $breaking_desc"
fi

# 4. Input Description
while true; do
    echo -n "Enter a short, imperative description (mandatory): "
    read description
    if [ -n "$description" ]; then
        if [ ${#description} -gt 72 ]; then
            echo -e "${YELLOW}Warning: Description is long (${#description} chars). Recommended is < 72.${NC}"
        fi
        break
    fi
    echo -e "${RED}Description is required.${NC}"
done

# 5. Input Body (Optional)
echo "Enter a longer description (body) (optional, press Enter to skip):"
echo -n "> "
read body

# 6. Input Footer (Optional)
echo "Enter footer information (e.g., issue links 'Refs #123') (optional, press Enter to skip):"
echo -n "> "
read footer

# Assemble the message
COMMIT_MSG="${type}${scope}${breaking_mark}: ${description}"

if [ -n "$body" ]; then
    COMMIT_MSG="${COMMIT_MSG}\n\n${body}"
fi

if [ -n "$breaking_footer" ]; then
    COMMIT_MSG="${COMMIT_MSG}\n\n${breaking_footer}"
fi

if [ -n "$footer" ]; then
    if [ -z "$breaking_footer" ]; then
        COMMIT_MSG="${COMMIT_MSG}\n\n${footer}"
    else
        COMMIT_MSG="${COMMIT_MSG}\n${footer}"
    fi
fi

echo -e "\n${BLUE}Proposed Commit Message:${NC}"
echo -e "${GREEN}------------------------${NC}"
echo -e "$COMMIT_MSG"
echo -e "${GREEN}------------------------${NC}"

# Final confirmation
echo -n "Do you want to commit with this message? (y/N): "
read confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "$COMMIT_MSG" | git commit -F -
    echo -e "${GREEN}Successfully committed!${NC}"
else
    echo -e "${YELLOW}Commit aborted. Here is your message to copy:${NC}"
    echo -e "$COMMIT_MSG"
fi

# TODO: Add support for Conventional Comments v2.0.0