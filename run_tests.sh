#!/bin/bash

function main {
	local changed_files=$(git diff --name-only upstream/master)
	local test_results=""

	if [ -z "${changed_files}" ]
	then
		test_results=$(\
			find . -maxdepth 1 \( -name "test_*.sh" ! -name "test_bundle_image.sh" \) -type f -exec ./{} \; && \
			\
			cd release && \
			\
			find . -name "test_*.sh" -type f -exec ./{} \;)
	else
		if (echo "${changed_files}" | grep --extended-regexp "^[^/]+\.sh$" --quiet)
		then
			test_results=$(find . -maxdepth 1 -name "test_*.sh" ! -name "test_bundle_image.sh" -type f -exec ./{} \;)
		fi

		if (echo "${changed_files}" | grep --extended-regexp "^release/.*\.sh$|^release/test-dependencies/.*" --quiet)
		then
			test_results+=$'\n'"$(cd release && find . -name "test_*.sh" -type f -exec ./{} \;)"
		fi
	fi

	echo "${test_results}"

	if [[ "${test_results}" == *"FAILED"* ]]
	then
		exit 1
	fi
}

main