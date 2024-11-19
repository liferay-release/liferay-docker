#!/bin/bash

source _liferay_common.sh
source _test_common.sh

function main {
	test_patching_tool_version "2.0"
	test_patching_tool_version "3.0"
	test_patching_tool_version "4.0"
}

function test_patching_tool_version {
	local latest_patching_tool_version=$(./patching_tool_version.sh "${1}")

	assert_equals \
		"${latest_patching_tool_version}" \
		$(lc_curl https://releases.liferay.com/tools/patching-tool/LATEST-${1}.txt)
}

main