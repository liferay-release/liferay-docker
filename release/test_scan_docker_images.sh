#!/bin/bash

source ../_test_common.sh
source ./scan_docker_images.sh

function main {
	set_up

	if [ "${#}" -eq 1 ]
	then
		if [ "${1}" == "test_scan_docker_images_with_invalid_image" ]
		then
			"${1}"

			tear_down
		else
			tear_down

			"${1}"
		fi
	else
		test_scan_docker_images_with_invalid_image

		tear_down

		test_scan_docker_images_without_parameters
	fi
}

function set_up {
	export LIFERAY_IMAGE_NAMES="liferay/dxp:test-image"
	export LIFERAY_PRISMA_CLOUD_ACCESS_KEY="key"
	export LIFERAY_PRISMA_CLOUD_SECRET="secret"
}

function tear_down {
	unset LIFERAY_IMAGE_NAMES
	unset LIFERAY_PRISMA_CLOUD_ACCESS_KEY
	unset LIFERAY_PRISMA_CLOUD_SECRET
}

function test_scan_docker_images_with_invalid_image {
	assert_equals \
		"$(check_usage_scan_docker_images ${LIFERAY_IMAGE_NAMES} | cut --delimiter=' ' --fields=2-)" \
		"[ERROR] Unable to find liferay/dxp:test-image locally."
}

function test_scan_docker_images_without_parameters {
	assert_equals \
		"$(check_usage_scan_docker_images)" \
		"$(cat test-dependencies/expected/test_scan_docker_images_without_parameters_output.txt)"
}

main "${@}"