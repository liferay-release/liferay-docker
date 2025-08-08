#!/bin/bash

function main {
	local changed_files=$(git diff --name-only upstream/master)
	local tests_results=""

	if [ -z "${changed_files}" ]
	then
		tests_results=$(\
			find . -maxdepth 1 \( -name "test_*.sh" ! -name "test_bundle_image.sh" \) -type f -exec ./{} \; && \
			\
			cd release && \
			\
			find . -name "test_*.sh" -type f -exec ./{} \;)
	else
		if (echo "${changed_files}" | grep --extended-regexp "^[^/]+\.sh$" --quiet)
		then
			tests_results=$(find . -maxdepth 1 -name "test_*.sh" ! -name "test_bundle_image.sh" -type f -exec ./{} \;)
		fi

		if (echo "${changed_files}" | grep --extended-regexp "^release/.*\.sh$|^release/test-dependencies/.*" --quiet)
		then
			tests_results+=$'\n'"$(cd release && find . -name "test_*.sh" -type f -exec ./{} \;)"
		fi
	fi

	echo "${tests_results}"

	if [[ "${tests_results}" == *"FAILED"* ]]
	then
		exit 1
	fi
}

main