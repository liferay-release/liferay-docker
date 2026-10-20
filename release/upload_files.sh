#!/bin/bash

source ../_liferay_common.sh

function check_usage {
	if [ -z "${LIFERAY_RELEASE_UPLOAD_DESTINATION_DIR_NAME}" ] ||
	   [ -z "${LIFERAY_RELEASE_UPLOAD_SOURCE_DIR}" ]
	then
		print_help
	fi

	if ! _is_valid_destination_dir_name "${LIFERAY_RELEASE_UPLOAD_DESTINATION_DIR_NAME}"
	then
		lc_log ERROR "\${LIFERAY_RELEASE_UPLOAD_DESTINATION_DIR_NAME} must only contain letters, numbers, \".\", \"_\", and \"-\", and must start with a letter or number."

		exit "${LIFERAY_COMMON_EXIT_CODE_BAD}"
	fi

	if ! _is_valid_source_dir "${LIFERAY_RELEASE_UPLOAD_SOURCE_DIR}"
	then
		lc_log ERROR "\${LIFERAY_RELEASE_UPLOAD_SOURCE_DIR} must be a relative path whose directory names only contain letters, numbers, \".\", \"_\", and \"-\", and start with a letter or number."

		exit "${LIFERAY_COMMON_EXIT_CODE_BAD}"
	fi

	lc_check_utils rsync ssh || exit "${LIFERAY_COMMON_EXIT_CODE_BAD}"

	_DESTINATION_DIR="/www/releases.liferay.com/tools/ide/${LIFERAY_RELEASE_UPLOAD_DESTINATION_DIR_NAME}"
	_DESTINATION_HOST="root@lrdcom-vm-1"
	_SOURCE_DIR="/opt/java/jenkins/userContent/liferay-ide/${LIFERAY_RELEASE_UPLOAD_SOURCE_DIR}"

	if [ ! -d "${_SOURCE_DIR}" ]
	then
		lc_log ERROR "${_SOURCE_DIR} does not exist."

		exit "${LIFERAY_COMMON_EXIT_CODE_BAD}"
	fi
}

function main {
	if [[ "${BASH_SOURCE[0]}" != "${0}" ]]
	then
		return
	fi

	check_usage

	lc_time_run _prepare_destination_dir

	lc_time_run _upload_files
}

function print_help {
	echo "Usage: LIFERAY_RELEASE_UPLOAD_DESTINATION_DIR_NAME=<destination_dir_name> LIFERAY_RELEASE_UPLOAD_SOURCE_DIR=<source_dir> ${0}"
	echo ""
	echo "The script reads the following environment variables:"
	echo ""
	echo "    LIFERAY_RELEASE_UPLOAD_DESTINATION_DIR_NAME: Name of the directory under /www/releases.liferay.com/tools/ide on lrdcom-vm-1 to upload to. It is deleted and recreated before uploading."
	echo "    LIFERAY_RELEASE_UPLOAD_SOURCE_DIR: Directory relative to /opt/java/jenkins/userContent/liferay-ide to upload from"
	echo ""
	echo "Example: LIFERAY_RELEASE_UPLOAD_DESTINATION_DIR_NAME=4.0.1 LIFERAY_RELEASE_UPLOAD_SOURCE_DIR=4.x/202608072258 ${0}"

	exit "${LIFERAY_COMMON_EXIT_CODE_HELP}"
}

function _is_valid_destination_dir_name {
	if [[ "${1}" =~ ^[0-9A-Za-z][0-9A-Za-z._-]*$ ]]
	then
		return 0
	fi

	return 1
}

function _is_valid_source_dir {
	if [[ "${1}" =~ ^[0-9A-Za-z][0-9A-Za-z._-]*(/[0-9A-Za-z][0-9A-Za-z._-]*)*/?$ ]]
	then
		return 0
	fi

	return 1
}

function _prepare_destination_dir {
	ssh "${_DESTINATION_HOST}" rm --force --recursive "${_DESTINATION_DIR}"

	if ! ssh "${_DESTINATION_HOST}" mkdir --parents "${_DESTINATION_DIR}"
	then
		lc_log ERROR "Unable to create ${_DESTINATION_DIR} on ${_DESTINATION_HOST}."

		return "${LIFERAY_COMMON_EXIT_CODE_BAD}"
	fi
}

function _upload_files {
	if ! rsync \
			--archive \
			--chmod=go=rx \
			--timeout=900 \
			"${_SOURCE_DIR}/" \
			"${_DESTINATION_HOST}:${_DESTINATION_DIR}"
	then
		lc_log ERROR "Unable to upload ${_SOURCE_DIR} to ${_DESTINATION_HOST}:${_DESTINATION_DIR}."

		return "${LIFERAY_COMMON_EXIT_CODE_BAD}"
	fi
}

main