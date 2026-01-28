#!/bin/bash

if [ -f "${1}" ]
then
	echo "Act as a specialized Bash code formatter. Apply the stylistic rules defined in .gemini/shell-style-guide.md to the file ${1}. Return only the formatted code."
else
	echo "Act as a specialized Bash code formatter. Apply the stylistic rules defined in .gemini/shell-style-guide.md to the root folder of this repository. Return only the formatted code."
fi
