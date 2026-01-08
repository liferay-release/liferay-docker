#!/bin/bash

# ==============================================================================
# Bash Formatter Wrapper (Gemini CLI Edition)
# 
# Description:
#   Leverages the Gemini CLI to format shell scripts based on corporate
#   style guides defined in the .gemini/ directory.
#
# Usage:
#   ./format_shell.sh <target_file.sh>
# ==============================================================================

set -e # Exit on error

# Constants
readonly RULES_FILE=".gemini/bash-rules.md"
readonly TARGET_FILE="$1"

# Validation: Check if argument is provided
if [[ -z "$TARGET_FILE" ]]; then
	echo "Usage: $0 <path_to_file.sh>"
	exit 1
fi

# Validation: Check if target file exists
if [[ ! -f "$TARGET_FILE" ]]; then
	echo "Error: File not found: $TARGET_FILE"
	exit 1
fi

# Validation: Check if rules file exists
if [[ ! -f "$RULES_FILE" ]]; then
	echo "Error: Rules documentation missing at $RULES_FILE"
	exit 1
fi

echo "--- Gemini Code Formatter ---"
echo "Instructions for Gemini CLI:"
echo ""
echo "Act as a specialized Bash code formatter. Apply the stylistic rules defined in '$RULES_FILE' to the file '$TARGET_FILE'. Return only the formatted code."
echo ""
echo "------------------------------"
echo "Copy the prompt above into your Gemini CLI to proceed."