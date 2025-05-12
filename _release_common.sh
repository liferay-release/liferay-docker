#!/bin/bash

function get_latest_quarterly_product_version {
	local product_version_1=$(echo "${1}" | sed -e "s/-lts//")
	local product_version_2=$(echo "${2}" | sed -e "s/-lts//")

	IFS='.' read -r product_version_1_year product_version_1_quarter product_version_1_suffix <<< "${product_version_1}"
	IFS='.' read -r product_version_2_year product_version_2_quarter product_version_2_suffix <<< "${product_version_2}"

	product_version_1_quarter=$(echo "${product_version_1_quarter}" | sed -e "s/q//")
	product_version_2_quarter=$(echo "${product_version_2_quarter}" | sed -e "s/q//")

	if [ "${product_version_1_year}" -gt "${product_version_2_year}" ]
	then
		echo "${1}"

		return
	elif [ "${product_version_1_year}" -lt "${product_version_2_year}" ]
	then
		echo "${2}"

		return
	fi

	if [ "${product_version_1_quarter}" -gt "${product_version_2_quarter}" ]
	then
		echo "${1}"

		return
	elif [ "${product_version_1_quarter}" -lt "${product_version_2_quarter}" ]
	then
		echo "${2}"

		return
	fi

	if [ "${product_version_1_suffix}" -gt "${product_version_2_suffix}" ]
	then
		echo "${1}"

		return
	elif [ "${product_version_1_suffix}" -lt "${product_version_2_suffix}" ]
	then
		echo "${2}"

		return
	fi

	echo "${1}"
}