#!/bin/bash

source ./_release_common.sh
source ./_test_common.sh

function main {
	test_release_common_get_product_group_version
	test_release_common_get_release_patch_version
	test_release_common_get_release_quarter
	test_release_common_get_release_version
	test_release_common_get_release_version_trivial
	test_release_common_get_release_year
	test_release_common_is_7_3_ga_release
	test_release_common_is_7_3_release
	test_release_common_is_7_3_u_release
	test_release_common_is_7_4_ga_release
	test_release_common_is_7_4_release
	test_release_common_is_7_4_u_release
	test_release_common_is_dxp_release
	test_release_common_is_early_product_version_than
	test_release_common_is_ga_release
	test_release_common_is_later_product_version_than
	test_release_common_is_lts_release
	test_release_common_is_nightly_release
	test_release_common_is_portal_release
	test_release_common_is_quarterly_release
	test_release_common_is_u_release

	unset _PRODUCT_VERSION
	unset ACTUAL_PRODUCT_VERSION
}

function test_release_common_get_product_group_version {
	_test_release_common_get_product_group_version "2025.q1.0-lts" "2025.q1"
	_test_release_common_get_product_group_version "7.4.13.nightly" "7.4"
}

function test_release_common_get_release_patch_version {
	_test_release_common_get_release_patch_version "2023.q4.3" "3"
	_test_release_common_get_release_patch_version "2024.q3.7" "7"
	_test_release_common_get_release_patch_version "2025.q1.13-lts" "13"
	_test_release_common_get_release_patch_version "2025.q2.0" "0"
}

function test_release_common_get_release_quarter {
	_test_release_common_get_release_quarter "2023.q4.3" "4"
	_test_release_common_get_release_quarter "2024.q3.7" "3"
	_test_release_common_get_release_quarter "2025.q1.1-lts" "1"
	_test_release_common_get_release_quarter "2025.q2.0" "2"
}

function test_release_common_get_release_version {
	_test_release_common_get_release_version "7.3.10-ga1" "7.3.10"
	_test_release_common_get_release_version "7.3.10-u36" "7.3.10"
	_test_release_common_get_release_version "7.3.7-ga8" "7.3.7"
	_test_release_common_get_release_version "7.4.13-u134" "7.4.13"
	_test_release_common_get_release_version "7.4.3.132-ga132" "7.4.3"
}

function test_release_common_get_release_version_trivial {
	_test_release_common_get_release_version_trivial "7.3.10-u36" "36"
	_test_release_common_get_release_version_trivial "7.3.7-ga8" "8"
	_test_release_common_get_release_version_trivial "7.4.13-u134" "134"
	_test_release_common_get_release_version_trivial "7.4.3.132-ga132" "132"
}

function test_release_common_get_release_year {
	_PRODUCT_VERSION="2025.q1.0-lts"

	assert_equals "$(get_release_year)" "2025"
}

function test_release_common_is_7_3_ga_release {
	_test_release_common_is_7_3_ga_release "7.3.10-ga1" "0"
	_test_release_common_is_7_3_ga_release "7.3.7-ga8" "0"
	_test_release_common_is_7_3_ga_release "7.4.13-u132" "1"
	_test_release_common_is_7_3_ga_release "7.4.3.132-ga132" "1"
}

function test_release_common_is_7_3_release {
	_test_release_common_is_7_3_release "7.3.10-u36" "0"
	_test_release_common_is_7_3_release "7.3.7-ga8" "0"
	_test_release_common_is_7_3_release "7.4.13-u132" "1"
	_test_release_common_is_7_3_release "7.4.3.132-ga132" "1"
}

function test_release_common_is_7_3_u_release {
	_test_release_common_is_7_3_u_release "7.3.10-u36" "0"
	_test_release_common_is_7_3_u_release "7.3.7-ga8" "1"
	_test_release_common_is_7_3_u_release "7.4.13-u132" "1"
	_test_release_common_is_7_3_u_release "7.4.3.132-ga132" "1"
}

function test_release_common_is_7_4_ga_release {
	_test_release_common_is_7_4_ga_release "7.3.10-u36" "1"
	_test_release_common_is_7_4_ga_release "7.3.7-ga8" "1"
	_test_release_common_is_7_4_ga_release "7.4.13-u132" "1"
	_test_release_common_is_7_4_ga_release "7.4.3.132-ga132" "0"
}

function test_release_common_is_7_4_release {
	_test_release_common_is_7_4_release "7.3.10-u36" "1"
	_test_release_common_is_7_4_release "7.3.7-ga8" "1"
	_test_release_common_is_7_4_release "7.4.13-u132" "0"
	_test_release_common_is_7_4_release "7.4.3.132-ga132" "0"
}

function test_release_common_is_7_4_u_release {
	_test_release_common_is_7_4_u_release "7.3.10-u3" "1"
	_test_release_common_is_7_4_u_release "7.3.10-u36" "1"
	_test_release_common_is_7_4_u_release "7.4.0-ga1" "1"
	_test_release_common_is_7_4_u_release "7.4.13-u134" "0"
}

function test_release_common_is_dxp_release {
	_test_release_common_is_dxp_release "dxp" "0"
	_test_release_common_is_dxp_release "portal" "1"
}

function test_release_common_is_early_product_version_than {
	_test_release_common_is_early_product_version_than "2023.q3.3" "2025.q2.0" "0"
	_test_release_common_is_early_product_version_than "2024.q4.7" "2025.q1.0" "0"
	_test_release_common_is_early_product_version_than "2025.q1.0" "2025.q1.1" "0"
	_test_release_common_is_early_product_version_than "2025.q1.1-lts" "2025.q1.0-lts" "1"
	_test_release_common_is_early_product_version_than "7.3.6-ga7" "7.3.7-ga8" "0"
	_test_release_common_is_early_product_version_than "7.3.10-u35" "7.3.10-u36" "0"
	_test_release_common_is_early_product_version_than "7.4.13-u134" "7.4.13-u135" "0"
	_test_release_common_is_early_product_version_than "7.4.3.120-ga120" "7.4.3.132-ga132" "0"
	_test_release_common_is_early_product_version_than "7.3.7-ga8" "7.3.6-ga7" "1"
	_test_release_common_is_early_product_version_than "7.3.10-u36" "7.3.10-u35" "1"
	_test_release_common_is_early_product_version_than "7.4.13-u135" "7.4.13-u134" "1"
	_test_release_common_is_early_product_version_than "7.4.3.132-ga132" "7.4.3.120-ga120" "1"
}

function test_release_common_is_ga_release {
	_test_release_common_is_ga_release "2025.q1.0-lts" "1"
	_test_release_common_is_ga_release "7.3.10-ga2" "0"
	_test_release_common_is_ga_release "7.4.0-ga1" "0"
	_test_release_common_is_ga_release "7.4.13-u134" "1"
	_test_release_common_is_ga_release "7.4.3.132-ga132" "0"
}

function test_release_common_is_later_product_version_than {
	_test_release_common_is_later_product_version_than "2025.q2.0" "2023.q3.3" "0"
	_test_release_common_is_later_product_version_than "2025.q1.0" "2024.q4.7" "0"
	_test_release_common_is_later_product_version_than "2025.q1.1" "2025.q1.0" "0"
	_test_release_common_is_later_product_version_than "2025.q1.0-lts" "2025.q1.1-lts" "1"
	_test_release_common_is_later_product_version_than "7.3.6-ga7" "7.3.7-ga8" "1"
	_test_release_common_is_later_product_version_than "7.3.10-u35" "7.3.10-u36" "1"
	_test_release_common_is_later_product_version_than "7.4.13-u134" "7.4.13-u135" "1"
	_test_release_common_is_later_product_version_than "7.4.3.120-ga120" "7.4.3.132-ga132" "1"
	_test_release_common_is_later_product_version_than "7.3.7-ga8" "7.3.6-ga7" "0"
	_test_release_common_is_later_product_version_than "7.3.10-u36" "7.3.10-u35" "0"
	_test_release_common_is_later_product_version_than "7.4.13-u135" "7.4.13-u134" "0"
	_test_release_common_is_later_product_version_than "7.4.3.132-ga132" "7.4.3.120-ga120" "0"
}

function test_release_common_is_lts_release {
	_test_release_common_is_lts_release "2023.q4.3" "1"
	_test_release_common_is_lts_release "2024.q3.7" "1"
	_test_release_common_is_lts_release "2025.q1.1-lts" "0"
	_test_release_common_is_lts_release "2025.q2.0" "1"
}

function test_release_common_is_nightly_release {
	_test_release_common_is_nightly_release "2025.q1.0-lts" "1"
	_test_release_common_is_nightly_release "7.4.13-u134" "1"
	_test_release_common_is_nightly_release "7.4.13.nightly" "0"
	_test_release_common_is_nightly_release "7.4.3.132-ga132" "1"
}

function test_release_common_is_portal_release {
	_test_release_common_is_portal_release "dxp" "1"
	_test_release_common_is_portal_release "portal" "0"
}

function test_release_common_is_quarterly_release {
	_test_release_common_is_quarterly_release "2025.q1.0-lts" "0"
	_test_release_common_is_quarterly_release "7.4.13-u134" "1"
	_test_release_common_is_quarterly_release "7.4.3.112-ga112" "1"
}

function test_release_common_is_u_release {
	_test_release_common_is_u_release "2025.q1.0-lts" "1"
	_test_release_common_is_u_release "7.3.10-u2" "0"
	_test_release_common_is_u_release "7.4.0-ga1" "1"
	_test_release_common_is_u_release "7.4.13-u1" "0"
}

function _test_release_common_get_product_group_version {
	_PRODUCT_VERSION="${1}"

	echo -e "Running _test_release_common_get_product_group_version for ${_PRODUCT_VERSION}.\n"

	assert_equals "$(get_product_group_version)" "${2}"
}

function _test_release_common_get_release_patch_version {
	_PRODUCT_VERSION="${1}"

	echo -e "Running _test_release_common_get_release_patch_version for ${_PRODUCT_VERSION}.\n"

	assert_equals "$(get_release_patch_version)" "${2}"
}

function _test_release_common_get_release_quarter {
	_PRODUCT_VERSION="${1}"

	echo -e "Running _test_release_common_get_release_quarter for ${1}.\n"
	
	assert_equals "$(get_release_quarter)" "${2}"
}

function _test_release_common_get_release_version {
	_PRODUCT_VERSION="${1}"

	echo -e "Running _test_release_common_get_release_version for ${_PRODUCT_VERSION}.\n"

	assert_equals "$(get_release_version)" "${2}"
}

function _test_release_common_get_release_version_trivial {
	_PRODUCT_VERSION="${1}"

	echo -e "Running _test_release_common_get_release_version_trivial for ${_PRODUCT_VERSION}.\n"

	assert_equals "$(get_release_version_trivial)" "${2}"
}

function _test_release_common_is_7_3_ga_release {
	echo -e "Running _test_release_common_is_7_3_ga_release for ${1}.\n"

	is_7_3_ga_release "${1}"

	assert_equals "${?}" "${2}"
}

function _test_release_common_is_7_3_release {
	echo -e "Running _test_release_common_is_7_3_release for ${1}.\n"

	is_7_3_release "${1}"

	assert_equals "${?}" "${2}"
}

function _test_release_common_is_7_3_u_release {
	echo -e "Running _test_release_common_is_7_3_u_release for ${1}.\n"

	is_7_3_u_release "${1}"

	assert_equals "${?}" "${2}"
}

function _test_release_common_is_7_4_ga_release {
	echo -e "Running _test_release_common_is_7_4_ga_release for ${1}.\n"

	is_7_4_ga_release "${1}"

	assert_equals "${?}" "${2}"
}

function _test_release_common_is_7_4_release {
	echo -e "Running _test_release_common_is_7_4_release for ${1}.\n"

	is_7_4_release "${1}"

	assert_equals "${?}" "${2}"
}

function _test_release_common_is_7_4_u_release {
	echo -e "Running _test_release_common_is_7_4_u_release for ${1}.\n"

	is_7_4_u_release "${1}"

	assert_equals "${?}" "${2}"
}

function _test_release_common_is_dxp_release {
	LIFERAY_RELEASE_PRODUCT_NAME="${1}"

	echo -e "Running _test_release_common_is_dxp_release for ${LIFERAY_RELEASE_PRODUCT_NAME}.\n"

	is_dxp_release

	assert_equals "${?}" "${2}"
}

function _test_release_common_is_early_product_version_than {
	_PRODUCT_VERSION="${1}"

	echo -e "Running _test_release_common_is_early_product_version_than for ${_PRODUCT_VERSION}.\n"

	is_early_product_version_than "${2}"

	assert_equals "${?}" "${3}"
}

function _test_release_common_is_ga_release {
	echo -e "Running _test_release_common_is_ga_release for ${1}.\n"

	is_ga_release "${1}"

	assert_equals "${?}" "${2}"
}

function _test_release_common_is_later_product_version_than {
	_PRODUCT_VERSION="${1}"

	echo -e "Running _test_release_common_is_later_product_version_than for ${_PRODUCT_VERSION}.\n"

	is_later_product_version_than "${2}"

	assert_equals "${?}" "${3}"
}

function _test_release_common_is_lts_release {
	echo -e "Running _test_release_common_is_lts_release for ${1}.\n"

	is_lts_release "${1}"

	assert_equals "${?}" "${2}"
}

function _test_release_common_is_nightly_release {
	echo -e "Running _test_release_common_is_nightly_release for ${1}.\n"

	is_nightly_release "${1}"

	assert_equals "${?}" "${2}"
}

function _test_release_common_is_portal_release {
	LIFERAY_RELEASE_PRODUCT_NAME="${1}"

	echo -e "Running _test_release_common_is_portal_release for ${LIFERAY_RELEASE_PRODUCT_NAME}.\n"

	is_portal_release

	assert_equals "${?}" "${2}"
}

function _test_release_common_is_quarterly_release {
	echo -e "Running _test_release_common_is_quarterly_release for ${1}.\n"

	is_quarterly_release "${1}"

	assert_equals "${?}" "${2}"
}

function _test_release_common_is_u_release {
	echo -e "Running _test_release_common_is_u_release for ${1}.\n"

	is_u_release "${1}"

	assert_equals "${?}" "${2}"
}

main