#!/bin/bash

source ./_liferay_common.sh

function main {
	export DISPLAY_SUCCESSFUL_TEST_RESULT="false"

	local test_results=""

	local changed_files=$(git diff --name-only upstream/master)

	lc_log DEBUG "Changed files: ${changed_files}"

	if [ -z "${changed_files}" ]
	then
		lc_log DEBUG "All tests will be run since no changed files were detected."

		test_results=$(_run_docker_tests && _run_release_tests)
	else
		if (echo "${changed_files}" | grep --extended-regexp "^[^/]+\.sh$" --quiet)
		then
			lc_log DEBUG "Running docker tests"

			test_results=$(_run_docker_tests)
		fi

		if (echo "${changed_files}" | grep --extended-regexp "^release/.*\.sh$|^release/test-dependencies/.*" --quiet)
		then
			if [ -n "${test_results}" ]
			then
				test_results+=$'\n'
			fi

			lc_log DEBUG "Running release tests"

			test_results+=$(_run_release_tests)
		fi
	fi

	echo "${test_results}"

	if [[ "${test_results}" == *"FAILED"* ]]
	then
		exit 1
	fi

	unset DISPLAY_SUCCESSFUL_TEST_RESULT
}

function _run_docker_tests {
	find . -maxdepth 1 -name "test_*.sh" ! -name "test_bundle_image.sh" -type f -exec {} \;
}

function _run_release_tests {
	cd release

	find . -name "test_*.sh" -type f -exec {} \;
}

main