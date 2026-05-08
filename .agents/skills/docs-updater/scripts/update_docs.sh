#!/bin/bash

# Documentation Helper Script
# This script gathers information about the project to help update AGENTS.md and Readme.md

echo "--- Project Analysis ---"

echo "1. Tech Stack (package.json)"
if [ -f "package.json" ]; then
    grep -E '"version"|"dependencies"|"devDependencies"|"type"' package.json
else
    echo "No package.json found."
fi

echo -e "\n2. Directory Structure"
if command -v tree >/dev/null 2>&1; then
    tree -L 2 -I 'node_modules|.git'
else
    echo "Tree command not found. Listing directories with find:"
    find . -maxdepth 2 -not -path '*/.*' -not -path './node_modules*'
fi

echo -e "\n3. Skills (.agents/skills)"
if [ -d ".agents/skills" ]; then
    ls -d .agents/skills/*/ 2>/dev/null | xargs -n 1 basename
else
    echo "No .agents/skills directory found."
fi

echo -e "\n4. Root Scripts"
ls -F 2>/dev/null | grep '\.sh$'

echo "--- Analysis Complete ---"
