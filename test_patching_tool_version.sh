#!/bin/bash

source _liferay_common.sh
source _test_common.sh

function main {
	test_patching_tool_version
}

function test_patching_tool_version {
	_test_patching_tool_version "1.0"
	_test_patching_tool_version "2.0"
	_test_patching_tool_version "3.0"
	_test_patching_tool_version "4.0"
}

function _test_patching_tool_version {
	local latest_patching_tool_version=$(./patching_tool_version.sh "${1}")

	if [ "${1}" == "1.0" ]
	then
		assert_equals "${latest_patching_tool_version}" "1.0.24"
	else
		assert_equals \
			"${latest_patching_tool_version}" \
			$(lc_curl https://releases.liferay.com/tools/patching-tool/LATEST-${1}.txt)
	fi
}

main