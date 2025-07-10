#!/bin/bash

function get_product_group_version {
	echo "$(_get_product_version "${1}")" | cut -d '.' -f 1,2
}

function get_release_patch_version {
	local product_version="$(_get_product_version "${1}")"

	if is_lts_release "${product_version}"
	then
		echo "${product_version}" | cut -d '.' -f 3 | sed -e "s/-lts//"
	else
		echo "${product_version}" | cut -d '.' -f 3
	fi
}

function get_release_quarter {
	echo "$(_get_product_version "${1}")" | cut -d '.' -f 2 | tr -d 'q'
}

function get_release_version {
	local product_version="$(_get_product_version "${1}")"

	if is_ga_release "${product_version}"
	then
		if is_7_3_ga_release "${product_version}"
		then
			echo "${product_version}" | cut -d '.' -f 1,2,3 | cut -d '-' -f 1
		else
			echo "${product_version}" | cut -d '.' -f 1,2,3
		fi
	elif is_u_release "${product_version}"
	then
		echo "${product_version}" | cut -d '-' -f 1
	fi
}

function get_release_version_trivial {
	local product_version="$(_get_product_version "${1}")"

	if is_ga_release "${product_version}"
	then
		echo "${product_version}" | cut -d '-' -f 2 | sed 's/ga//'
	elif is_u_release "${product_version}"
	then
		echo "${product_version}" | cut -d '-' -f 2 | tr -d u
	fi
}

function get_release_year {
	echo "$(_get_product_version "${1}")" | cut -d '.' -f 1
}

function has_ssh_connection {
	ssh "root@${1}" "exit" &> /dev/null

	if [ "${?}" -eq 0 ]
	then
		return "${LIFERAY_COMMON_EXIT_CODE_OK}"
	fi

	return "${LIFERAY_COMMON_EXIT_CODE_BAD}"
}

function is_7_3_ga_release {
	if [[ "$(_get_product_version "${1}")" == 7.3.*-ga* ]]
	then
		return 0
	fi

	return 1
}

function is_7_3_release {
	if [[ "$(_get_product_version "${1}")" == 7.3* ]]
	then
		return 0
	fi

	return 1
}

function is_7_3_u_release {
	if [[ "$(_get_product_version "${1}")" == 7.3.*-u* ]]
	then
		return 0
	fi

	return 1
}

function is_7_4_ga_release {
	if [[ "$(_get_product_version "${1}")" == 7.4.*-ga* ]]
	then
		return 0
	fi

	return 1
}

function is_7_4_release {
	if [[ "$(_get_product_version "${1}")" == 7.4* ]]
	then
		return 0
	fi

	return 1
}

function is_7_4_u_release {
	if [[ "$(_get_product_version "${1}")" == 7.4.*-u* ]]
	then
		return 0
	fi

	return 1
}

function is_dxp_release {
	if [ "${LIFERAY_RELEASE_PRODUCT_NAME}" == "dxp" ]
	then
		return 0
	fi

	return 1
}

function is_early_product_version_than {
	_compare_product_versions "${1}" "early"
}

function is_ga_release {
	if [[ "$(_get_product_version "${1}")" == *-ga* ]]
	then
		return 0
	fi

	return 1
}

function is_later_product_version_than {
	_compare_product_versions "${1}" "later"
}

function is_lts_release {
	if [[ "$(_get_product_version "${1}")" == *lts* ]]
	then
		return 0
	fi

	return 1
}

function is_nightly_release {
	if [[ "$(_get_product_version "${1}")" == *nightly ]]
	then
		return 0
	fi

	return 1
}

function is_portal_release {
	if [ "${LIFERAY_RELEASE_PRODUCT_NAME}" == "portal" ]
	then
		return 0
	fi

	return 1
}

function is_quarterly_release {
	if [[ "$(_get_product_version "${1}")" == *q* ]]
	then
		return 0
	fi

	return 1
}

function is_u_release {
	if [[ "$(_get_product_version "${1}")" == *-u* ]]
	then
		return 0
	fi

	return 1
}

function set_actual_product_version {
	ACTUAL_PRODUCT_VERSION="${1}"
}

function _compare_product_versions {
	local product_version_1

	if [ -n "${ACTUAL_PRODUCT_VERSION}" ]
	then
		product_version_1="${ACTUAL_PRODUCT_VERSION}"
	else
		product_version_1=$(_get_product_version)
	fi

	local product_version_2="${1}"

	local operator_1
	local operator_2

	if [ "${2}" == "early" ]
	then
		operator_1="-lt"
		operator_2="-gt"
	elif [ "${2}" == "later" ]
	then
		operator_1="-gt"
		operator_2="-lt"
	fi

	if is_quarterly_release "${product_version_1}" &&
	   is_quarterly_release "${product_version_2}"
	then
		if [ "$(get_release_year ${product_version_1})" "${operator_1}" "$(get_release_year ${product_version_2})" ]
		then
			return 0
		elif [ "$(get_release_year ${product_version_1})" "${operator_2}" "$(get_release_year ${product_version_2})" ]
		then
			return 1
		fi

		if [ "$(get_release_quarter ${product_version_1})" "${operator_1}" "$(get_release_quarter ${product_version_2})" ]
		then
			return 0
		elif [ "$(get_release_quarter ${product_version_1})" "${operator_2}" "$(get_release_quarter ${product_version_2})" ]
		then
			return 1
		fi

		if [ "$(get_release_patch_version ${product_version_1})" "${operator_1}" "$(get_release_patch_version ${product_version_2})" ]
		then
			return 0
		elif [ "$(get_release_patch_version ${product_version_1})" "${operator_2}" "$(get_release_patch_version ${product_version_2})" ]
		then
			return 1
		fi
	fi

	return 1
}

function _get_product_version {
	if [ -n "${_PRODUCT_VERSION}" ] && [ -z "${1}" ]
	then
		echo "${_PRODUCT_VERSION}"
	else
		echo "${1}"
	fi
}