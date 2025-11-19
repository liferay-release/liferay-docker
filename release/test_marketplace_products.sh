#!/bin/bash

source ../_liferay_common.sh
source ../_test_common.sh
source ./_marketplace_products.sh

function main {
	set_up

	if [ "${#}" -eq 1 ]
	then
		"${1}"
	else
		test_marketplace_products_get_latest_product_virtual_settings_file_entry_json_index
		test_marketplace_products_test_marketplace_products_compatibility
	fi

	tear_down
}

function set_up {
	export _RELEASE_ROOT_DIR="${PWD}"

	export _BUILD_DIR="${_RELEASE_ROOT_DIR}/release-data/build"
	export _BUNDLES_DIR="${_RELEASE_ROOT_DIR}/test-dependencies/liferay-dxp"
	export _PRODUCT_VERSION="2025.q3.0"

	lc_cd "${_RELEASE_ROOT_DIR}/test-dependencies"

	lc_download \
		https://releases-cdn.liferay.com/dxp/2025.q3.0/liferay-dxp-tomcat-2025.q3.0-1756231955.zip \
		liferay-dxp-tomcat-2025.q3.0-1756231955.zip 1> /dev/null

	unzip -oq liferay-dxp-tomcat-2025.q3.0-1756231955.zip
}

function tear_down {
	pgrep --full --list-name "${_BUNDLES_DIR}" | awk '{print $1}' | xargs --no-run-if-empty kill -9

	rm --force --recursive "${_BUILD_DIR}"
	rm --force --recursive "${_BUNDLES_DIR}"
	rm --force "${_RELEASE_ROOT_DIR}/test-dependencies/liferay-dxp-tomcat-2025.q3.0-1756231955.zip"

	unset _BUILD_DIR
	unset _BUNDLES_DIR
	unset _PRODUCT_VERSION
	unset _RELEASE_ROOT_DIR
}

function test_marketplace_products_get_latest_product_virtual_settings_file_entry_json_index {
	_test_marketplace_products_get_latest_product_virtual_settings_file_entry_json_index "2025.Q1" "2"
	_test_marketplace_products_get_latest_product_virtual_settings_file_entry_json_index "7.4" "2"
}

function test_marketplace_products_test_marketplace_products_compatibility {
	test_marketplace_products_compatibility &> /dev/null

	assert_equals "${?}" "${LIFERAY_COMMON_EXIT_CODE_OK}"
}

function _test_marketplace_products_get_latest_product_virtual_settings_file_entry_json_index {
	local product_virtual_settings_file_entries=$(cat "${_RELEASE_ROOT_DIR}/test-dependencies/expected/test_marketplace_products_${1}.json")

	assert_equals \
		"$(_get_latest_product_virtual_settings_file_entry_json_index "${product_virtual_settings_file_entries}")" \
		"${2}"
}

main "${@}"