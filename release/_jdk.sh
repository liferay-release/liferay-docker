#!/bin/bash

source ../_liferay_common.sh
source ../_release_common.sh

function set_jdk_version_and_parameters {
	local jdk_version="zulu8"

	if [ "$(is_quarterly_release "${_PRODUCT_VERSION}")" == "true" ]
	then
		if [[ "$(echo "${_PRODUCT_VERSION}" | cut -d '.' -f 1)" -ge 2025 ]]
		then
			jdk_version="openjdk17"
		fi
	fi

	if [[ "$(echo "${_PRODUCT_VERSION}" | grep "ga")" ]] &&
	   [[ "$(echo "${_PRODUCT_VERSION}" | cut -d '-' -f 2 | sed "s/ga//g")" -ge 132 ]]
	then
		jdk_version="openjdk17"
	fi

	if [[ "$(echo "${_PRODUCT_VERSION}" | cut -d '-' -f 1)" == "7.4.13" ]] &&
	   [[ "$(echo "${_PRODUCT_VERSION}" | cut -d '-' -f 2 | tr -d u)" -ge 132 ]]
	then
		jdk_version="openjdk17"
	fi

	if [ ! -d "/opt/java/${jdk_version}" ]
	then
		lc_log INFO "JDK ${jdk_version} is not installed."

		jdk_version=$(echo "${jdk_version}" | sed -r "s/(openjdk|zulu)/jdk/g")

		if [ ! -d "/opt/java/${jdk_version}" ]
		then
			lc_log INFO "JDK ${jdk_version} is not installed."

			return "${LIFERAY_COMMON_EXIT_CODE_BAD}"
		fi
	fi

	lc_log INFO "Using JDK ${jdk_version} for release ${_PRODUCT_VERSION}."

	export JAVA_HOME="/opt/java/${jdk_version}"

	if [[ "${jdk_version}" == *"8"* ]] && [[ ! "${JAVA_OPTS}" =~ "-XX:MaxPermSize" ]]
	then
		JAVA_OPTS="${JAVA_OPTS} -XX:MaxPermSize=256m"
	fi

	if [[ "${jdk_version}" == *"17"* ]]
	then
		JAVA_OPTS=$(echo "${JAVA_OPTS}" | sed "s/-XX:MaxPermSize=[^ ]*//g")
	fi

	export JAVA_OPTS

	export PATH="${JAVA_HOME}/bin:${PATH}"
}