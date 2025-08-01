#!/bin/bash

function create_symlink {
	local target_dir

	if [ -e "/usr/lib/jvm/${2}-${1}" ]
	then
		target_dir=/usr/lib/jvm/"${2}"-"${1}"
	elif [ -e "/usr/lib/jvm/${2}-crac-${1}" ]
	then
		target_dir="/usr/lib/jvm/${2}-crac-${1}"
	fi

	if [ -n "${target_dir}" ] && [ ! -e "/usr/lib/jvm/${2//-/}" ]
	then
		ln --force --symbolic ${target_dir} "/usr/lib/jvm/${2//-/}"
	fi
}

function main {
	if [ -n "${JAVA_VERSION}" ]
	then
		if [ ! -e "/usr/lib/jvm/${JAVA_VERSION}" ]
		then
			local architecture=$(dpkg --print-architecture)
			local zulu_version=$(echo "${JAVA_VERSION}" | tr --complement --delete '0-9')

			create_symlink "${architecture}" "zulu-${zulu_version}"
			update-java-alternatives -s zulu-"${zulu_version}"-"${architecture}"
		fi

		local zulu_jdks=$(ls /usr/lib/jvm/ | grep "zulu-.*-.*" | awk -F- '{print $1$2}' | paste -s -d "," | sed "s/,/, /g")

		if [ -e "/usr/lib/jvm/${JAVA_VERSION}" ]
		then
			JAVA_HOME=/usr/lib/jvm/${JAVA_VERSION}
			PATH=/usr/lib/jvm/${JAVA_VERSION}/bin/:${PATH}

			echo "[LIFERAY] Using ${JAVA_VERSION} JDK. You can use another JDK by setting the \"JAVA_VERSION\" environment variable."
			echo "[LIFERAY] Available JDKs: ${zulu_jdks}."
		else
			echo "[LIFERAY] \"${JAVA_VERSION}\" JDK is not available in this Docker image."
			echo "[LIFERAY] Available JDKs: ${zulu_jdks}."

			exit 1
		fi
	fi
}

main