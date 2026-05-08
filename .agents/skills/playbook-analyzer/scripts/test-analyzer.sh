#!/bin/bash
# Test script for playbook-analyzer skill
# This demonstrates the analysis process with sample RKE2 readiness output

SAMPLE_FILE="${1:-$HOME/github/agent-configs/.agents/skills/playbook-analyzer/scripts/sample-output.txt}"

if [ ! -f "$SAMPLE_FILE" ]; then
    echo "Error: Sample file not found: $SAMPLE_FILE"
    exit 1
fi

echo "=== Playbook Analyzer Test ==="
echo ""
echo "Input: $SAMPLE_FILE"
echo "---"
cat "$SAMPLE_FILE"
