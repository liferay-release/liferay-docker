#!/bin/bash

source ./_liferay_common.sh

function main {
	local current_job=$(basename "${PWD}")

	lc_log INFO "Cleaning workspace for job ${current_job}."

	if [ "${current_job}" == "build-release" ] ||
	   [ "${current_job}" == "build-release-nightly" ] ||
	   [ "${current_job}" == "release-gold" ]
	then
		docker system prune --all --force &> /dev/null

		find . /opt/dev/projects/github/liferay-docker \
			-maxdepth 1 \
			-regextype posix-extended \
			-regex ".*/(logs-[0-9]{12}|temp-.*)$" \
			-type d \
			-exec rm --force --recursive {} \; &> /dev/null

		rm --force --recursive release/release-data
		rm --force --recursive downloads
	elif [ "${current_job}" == "source-code-sharing" ]
	then
		rm --force --recursive narwhal/source_code_sharing/cache
		rm --force --recursive narwhal/source_code_sharing/liferay-portal-ee
	fi
}

main