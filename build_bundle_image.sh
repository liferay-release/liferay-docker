#!/bin/bash

source ./_common.sh
source ./_liferay_common.sh

function build_docker_image {
	if [ "${LIFERAY_DOCKER_SLIM}" == "true" ]
	then
		DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME}-slim
	fi

	if [[ ${LIFERAY_DOCKER_RELEASE_FILE_URL%} == */snapshot-* ]]
	then
		DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME}-snapshot
	fi

	if [[ ${LIFERAY_DOCKER_RELEASE_FILE_URL} == https://release-* ]] || [[ ${LIFERAY_DOCKER_RELEASE_FILE_URL} == *release.liferay.com* ]]
	then
		DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME}-snapshot
	fi

	local release_version=${LIFERAY_DOCKER_RELEASE_FILE_URL%/*}

	release_version=${release_version##*/}

	if [[ ${LIFERAY_DOCKER_RELEASE_FILE_URL} == https://release-* ]] || [[ ${LIFERAY_DOCKER_RELEASE_FILE_URL} == *release.liferay.com* ]]
	then
		release_version=${LIFERAY_DOCKER_RELEASE_FILE_URL#*tomcat-}
		release_version=${release_version%.*}
	fi

	if [[ ${LIFERAY_DOCKER_RELEASE_FILE_URL} == *files.liferay.com/* ]] && [[ ${LIFERAY_DOCKER_RELEASE_FILE_URL%} != */snapshot-* ]]
	then
		local file_name_release_version=${LIFERAY_DOCKER_RELEASE_FILE_URL#*tomcat-}

		file_name_release_version=${file_name_release_version%.*}
		file_name_release_version=${file_name_release_version%-*}

		if [[ ${file_name_release_version} == *-slim ]]
		then
			file_name_release_version=${file_name_release_version%-slim}
		fi

		local service_pack_name=${file_name_release_version##*-}
	fi

	if [[ ${service_pack_name} == ga* ]] || [[ ${service_pack_name} == sp* ]]
	then
		release_version=${release_version}-${service_pack_name}
	fi

	LABEL_VERSION=${release_version}

	if [[ ${LIFERAY_DOCKER_RELEASE_FILE_URL%} == */snapshot-* ]]
	then
		local release_branch=${LIFERAY_DOCKER_RELEASE_FILE_URL%/*}

		release_branch=${release_branch%/*}
		release_branch=${release_branch%-private*}
		release_branch=${release_branch##*-}

		local release_hash=$(cat "${TEMP_DIR}/liferay/.githash")

		release_hash=${release_hash:0:7}

		if [[ ${release_branch} == master ]]
		then
			LABEL_VERSION="Master Snapshot on ${LABEL_VERSION} at ${release_hash}"
		else
			LABEL_VERSION="${release_branch} Snapshot on ${LABEL_VERSION} at ${release_hash}"
		fi
	fi

	if [ -n "${LIFERAY_DOCKER_RELEASE_VERSION}" ]
	then
		release_version=${LIFERAY_DOCKER_RELEASE_VERSION}
	fi

	DOCKER_IMAGE_TAGS=()

	local default_ifs=${IFS}

	IFS=","

	for release_version_single in ${release_version}
	do
		if [[ ${LIFERAY_DOCKER_RELEASE_FILE_URL%} == */snapshot-* ]]
		then
			DOCKER_IMAGE_TAGS+=("${LIFERAY_DOCKER_REPOSITORY}/${DOCKER_IMAGE_NAME}:${release_branch}-${release_version_single}-${release_hash}")
			DOCKER_IMAGE_TAGS+=("${LIFERAY_DOCKER_REPOSITORY}/${DOCKER_IMAGE_NAME}:${release_branch}-$(date "${CURRENT_DATE}" "+%Y%m%d")")
			DOCKER_IMAGE_TAGS+=("${LIFERAY_DOCKER_REPOSITORY}/${DOCKER_IMAGE_NAME}:${release_branch}")
		else
			DOCKER_IMAGE_TAGS+=("${LIFERAY_DOCKER_REPOSITORY}/${DOCKER_IMAGE_NAME}:${release_version_single}-d$(./release_notes.sh get-version)-${TIMESTAMP}")
			DOCKER_IMAGE_TAGS+=("${LIFERAY_DOCKER_REPOSITORY}/${DOCKER_IMAGE_NAME}:${release_version_single}")
		fi
	done

	if [[ "${LIFERAY_DOCKER_LATEST}" = "true" ]]
	then
		DOCKER_IMAGE_TAGS+=("${LIFERAY_DOCKER_REPOSITORY}/${DOCKER_IMAGE_NAME}:latest")
	fi

	if [ -e "${TEMP_DIR}/liferay/.githash" ]
	then
		LIFERAY_VCS_REF=$(cat "${TEMP_DIR}/liferay/.githash")
	fi

	IFS=${default_ifs}

	remove_temp_dockerfile_target_platform

	docker build \
		--build-arg LABEL_BUILD_DATE=$(date "${CURRENT_DATE}" "+%Y-%m-%dT%H:%M:%SZ") \
		--build-arg LABEL_LIFERAY_PATCHING_TOOL_VERSION="${LIFERAY_DOCKER_TEST_PATCHING_TOOL_VERSION}" \
		--build-arg LABEL_LIFERAY_TOMCAT_VERSION=$(get_tomcat_version "${TEMP_DIR}/liferay") \
		--build-arg LABEL_LIFERAY_VCS_REF="${LIFERAY_VCS_REF}" \
		--build-arg LABEL_NAME="${DOCKER_LABEL_NAME}" \
		--build-arg LABEL_RELEASE_VERSION="${LIFERAY_DOCKER_RELEASE_VERSION}" \
		--build-arg LABEL_VCS_REF=$(git rev-parse HEAD) \
		--build-arg LABEL_VCS_URL="https://github.com/liferay/liferay-docker" \
		--build-arg LABEL_VERSION="${LABEL_VERSION}" \
		$(get_docker_image_tags_args "${DOCKER_IMAGE_TAGS[@]}") \
		"${TEMP_DIR}" || exit 1
}

function check_release {
	if [[ ${RELEASE_FILE_NAME} == *-dxp-* ]] || [[ ${RELEASE_FILE_NAME} == *-private* ]]
	then
		DOCKER_IMAGE_NAME="dxp"
		DOCKER_LABEL_NAME="Liferay DXP"
	elif [[ ${RELEASE_FILE_NAME} == *-portal-* ]]
	then
		DOCKER_IMAGE_NAME="portal"
		DOCKER_LABEL_NAME="Liferay Portal"
	else
		echo "${RELEASE_FILE_NAME} is an unsupported release file name."

		exit 1
	fi
}

function check_usage {
	if [ ! -n "${LIFERAY_DOCKER_OPENSEARCH_PASSWORD}" ]
	then
		print_help
	fi

	if [ ! -n "${LIFERAY_DOCKER_RELEASE_FILE_URL}" ]
	then
		print_help
	fi

	if [[ -n "${LIFERAY_DOCKER_ELASTICSEARCH_NETWORK_ADDRESSES}" ]] &&
	   ! ( echo "${LIFERAY_DOCKER_ELASTICSEARCH_NETWORK_ADDRESSES}" | grep --quiet --perl-regexp "\[?(\"?(http|https):\/\/[.\w-]+:[\d]+\"?)+(,\s*\"(http|https):\/\/[.\w-]+:[\d]+\")*\]?" )
	then
		print_help
	fi

	if [[ -n "${LIFERAY_DOCKER_OPENSEARCH_NETWORK_ADDRESSES}" ]] &&
	   ! ( echo "${LIFERAY_DOCKER_OPENSEARCH_NETWORK_ADDRESSES}" | grep --quiet --perl-regexp "\[?(\"?(http|https):\/\/[.\w-]+:[\d]+\"?)+(,\s*\"(http|https):\/\/[.\w-]+:[\d]+\")*\]?" )
	then
		print_help
	fi

	check_utils 7z curl docker java unzip
}

function download_trial_dxp_license {
	if [[ ${DOCKER_IMAGE_NAME} == "dxp" ]]
	then
		rm -fr "${TEMP_DIR}/liferay/data/license"

		if (! ./download_trial_dxp_license.sh "${TEMP_DIR}/liferay" $(date "${CURRENT_DATE}" "+%s000"))
		then
			exit 4
		fi
	fi
}

function get_latest_tomcat_version {
	local tomcat_version=$(get_tomcat_version "${TEMP_DIR}/liferay")

	if [[ "${tomcat_version}" == "9.0"* ]]
	then
		echo "9.0.102"
	else
		echo "Unable to get latest Tomcat version for ${1}."

		exit 1
	fi
}

function install_fix_pack {
	if [ -n "${LIFERAY_DOCKER_FIX_PACK_URL}" ]
	then
		local fix_pack_url=${LIFERAY_DOCKER_FIX_PACK_URL}

		FIX_PACK_FILE_NAME=${fix_pack_url##*/}

		download downloads/fix-packs/"${FIX_PACK_FILE_NAME}" "${fix_pack_url}"

		cp "downloads/fix-packs/${FIX_PACK_FILE_NAME}" "${TEMP_DIR}/liferay/patching-tool/patches"

		"${TEMP_DIR}/liferay/patching-tool/patching-tool.sh" install

		rm -fr "${TEMP_DIR}/liferay/data/hypersonic/"*
		rm -fr "${TEMP_DIR}/liferay/osgi/state/"*
	fi
}

function main {
	if [[ " ${@} " =~ " --test " ]]
	then
		return
	fi

	check_usage "${@}"

	make_temp_directory templates/bundle

	set_parent_image

	prepare_temp_directory "${@}"

	check_release "${@}"

	update_patching_tool

	install_fix_pack "${@}"

	prepare_tomcat

	if [ "${LIFERAY_DOCKER_SLIM}" == "true" ]
	then
		prepare_slim_image

		if [ $? -ne 0 ]
		then
			return "${LIFERAY_COMMON_EXIT_CODE_BAD}"
		fi
	fi

	download_trial_dxp_license

	build_docker_image

	test_docker_image

	log_in_to_docker_hub

	push_docker_image "${1}"

	clean_up_temp_directory
}

function prepare_slim_image {
	local release_product_name=$(echo "${LIFERAY_DOCKER_RELEASE_FILE_URL}" | cut -d '/' -f 2)
	local release_version=$(echo "${LIFERAY_DOCKER_RELEASE_FILE_URL}" | cut -d '/' -f 3)

	LIFERAY_COMMON_DOWNLOAD_SKIP_CACHE="true" lc_download "https://releases-gcp.liferay.com/opensearch/${release_product_name}/${release_version}/com.liferay.portal.search.opensearch2.api.jar" "${TEMP_DIR}/liferay/deploy/com.liferay.portal.search.opensearch2.api.jar"

	if [ $? -ne 0 ]
	then
		lc_log ERROR "Unable to download com.liferay.portal.search.opensearch2.api.jar."

		return "${LIFERAY_COMMON_EXIT_CODE_BAD}"
	fi

	LIFERAY_COMMON_DOWNLOAD_SKIP_CACHE="true" lc_download "https://releases-gcp.liferay.com/opensearch/${release_product_name}/${release_version}/com.liferay.portal.search.opensearch2.impl.jar" "${TEMP_DIR}/liferay/deploy/com.liferay.portal.search.opensearch2.impl.jar"

	if [ $? -ne 0 ]
	then
		lc_log ERROR "Unable to download com.liferay.portal.search.opensearch2.impl.jar."

		return "${LIFERAY_COMMON_EXIT_CODE_BAD}"
	fi

	rm -fr "${TEMP_DIR}/liferay/elasticsearch-sidecar"

	(
		echo "active=B\"true\""
		echo "connectionId=\"REMOTE\""
		echo "password=\"${LIFERAY_DOCKER_OPENSEARCH_PASSWORD}\""
		echo "networkHostAddresses=\"${LIFERAY_DOCKER_OPENSEARCH_NETWORK_ADDRESSES}\""
	) > "${TEMP_DIR}/liferay/osgi/configs/com.liferay.portal.search.opensearch2.configuration.OpenSearchConnectionConfiguration-REMOTE.config"

	(
		echo "blacklistBundleSymbolicNames=[\\"
		echo "	\"com.liferay.portal.search.elasticsearch.cross.cluster.replication.impl\",\\"
		echo "	\"com.liferay.portal.search.elasticsearch.monitoring.web\",\\"
		echo "	\"com.liferay.portal.search.elasticsearch7.api\",\\"
		echo "	\"com.liferay.portal.search.elasticsearch7.impl\",\\"
		echo "	\"com.liferay.portal.search.learning.to.rank.api\",\\"
		echo "	\"com.liferay.portal.search.learning.to.rank.impl\"\\"
		echo "]"
	) > "${TEMP_DIR}/liferay/osgi/configs/com.liferay.portal.bundle.blacklist.internal.configuration.BundleBlacklistConfiguration.config"
	
	(
		echo "networkHostAddresses=\"${LIFERAY_DOCKER_ELASTICSEARCH_NETWORK_ADDRESSES}\""
		echo "productionModeEnabled=B\"true\""
	) > "${TEMP_DIR}/liferay/osgi/configs/com.liferay.portal.search.elasticsearch7.configuration.ElasticsearchConfiguration.config"

	echo "remoteClusterConnectionId=\"REMOTE\"" > "${TEMP_DIR}/liferay/osgi/configs/com.liferay.portal.search.opensearch2.configuration.OpenSearchConfiguration.config"
}

function prepare_temp_directory {
	RELEASE_FILE_NAME=${LIFERAY_DOCKER_RELEASE_FILE_URL##*/}

	local download_dir=${LIFERAY_DOCKER_RELEASE_FILE_URL%/*}

	download_dir=${download_dir#*com/}
	download_dir=${download_dir#*com/}
	download_dir=${download_dir#*liferay-release-tool/}
	download_dir=${download_dir#*private/ee/}
	download_dir=downloads/${download_dir}

	download "${download_dir}/${RELEASE_FILE_NAME}" "${LIFERAY_DOCKER_RELEASE_FILE_URL}"

	if [[ ${RELEASE_FILE_NAME} == *.7z ]]
	then
		7z x -O"${TEMP_DIR}" "${download_dir}/${RELEASE_FILE_NAME}" || exit 3
	else
		unzip -d "${TEMP_DIR}" -q "${download_dir}/${RELEASE_FILE_NAME}"  || exit 3
	fi

	mv "${TEMP_DIR}/liferay-"* "${TEMP_DIR}/liferay"

	local tomcat_version=$(get_latest_tomcat_version)

	local tomcat_download_dir="downloads/tomcat/apache-tomcat-${tomcat_version}"
	local tomcat_url="https://dlcdn.apache.org/tomcat/tomcat-${tomcat_version%%.*}/v${tomcat_version}/bin/apache-tomcat-${tomcat_version}.zip"

	download "${tomcat_download_dir}/apache-tomcat.zip" "${tomcat_url}"

	mv "${TEMP_DIR}/liferay/tomcat" "${TEMP_DIR}/liferay/tomcat-temp"

	unzip -d "${TEMP_DIR}/liferay" -q "${tomcat_download_dir}/apache-tomcat.zip" || exit 3

	mv "${TEMP_DIR}/liferay/apache-tomcat-"* "${TEMP_DIR}/liferay/tomcat"

	rm -fr "${TEMP_DIR}/liferay/tomcat/conf"
	rm -fr "${TEMP_DIR}/liferay/tomcat/temp/safeToDelete.tmp"
	rm -fr "${TEMP_DIR}/liferay/tomcat/webapps"

	cp -r "${TEMP_DIR}/liferay/tomcat-temp/LICENSE" "${TEMP_DIR}/liferay/tomcat/LICENSE"
	cp -r "${TEMP_DIR}/liferay/tomcat-temp/NOTICE" "${TEMP_DIR}/liferay/tomcat/NOTICE"
	cp -r "${TEMP_DIR}/liferay/tomcat-temp/RELEASE-NOTES" "${TEMP_DIR}/liferay/tomcat/RELEASE-NOTES"
	cp -r "${TEMP_DIR}/liferay/tomcat-temp/bin/catalina-tasks.xml" "${TEMP_DIR}/liferay/tomcat/bin/catalina-tasks.xml"
	cp -r "${TEMP_DIR}/liferay/tomcat-temp/bin/setenv.bat" "${TEMP_DIR}/liferay/tomcat/bin/setenv.bat"
	cp -r "${TEMP_DIR}/liferay/tomcat-temp/bin/setenv.sh" "${TEMP_DIR}/liferay/tomcat/bin/setenv.sh"
	cp -r "${TEMP_DIR}/liferay/tomcat-temp/conf" "${TEMP_DIR}/liferay/tomcat/"
	cp -r "${TEMP_DIR}/liferay/tomcat-temp/webapps" "${TEMP_DIR}/liferay/tomcat/"
	cp -r "${TEMP_DIR}/liferay/tomcat-temp/work/Catalina" "${TEMP_DIR}/liferay/tomcat/work/Catalina"

	rm -fr "${TEMP_DIR}/liferay/tomcat-temp"

	chmod +x "${TEMP_DIR}/liferay/tomcat/bin/"*
}

function push_docker_image {
	if [ "${1}" == "push" ]
	then
		check_docker_buildx

		sed -i '1s/FROM /FROM --platform=${TARGETPLATFORM} /g' "${TEMP_DIR}"/Dockerfile

		docker buildx build \
			--build-arg LABEL_BUILD_DATE=$(date "${CURRENT_DATE}" "+%Y-%m-%dT%H:%M:%SZ") \
			--build-arg LABEL_LIFERAY_PATCHING_TOOL_VERSION="${LIFERAY_DOCKER_TEST_PATCHING_TOOL_VERSION}" \
			--build-arg LABEL_LIFERAY_TOMCAT_VERSION=$(get_tomcat_version "${TEMP_DIR}/liferay") \
			--build-arg LABEL_LIFERAY_VCS_REF="${LIFERAY_VCS_REF}" \
			--build-arg LABEL_NAME="${DOCKER_LABEL_NAME}" \
			--build-arg LABEL_RELEASE_VERSION="${LIFERAY_DOCKER_RELEASE_VERSION}" \
			--build-arg LABEL_VCS_REF=$(git rev-parse HEAD) \
			--build-arg LABEL_VCS_URL="https://github.com/liferay/liferay-docker" \
			--build-arg LABEL_VERSION="${LABEL_VERSION}" \
			--builder "liferay-buildkit" \
			--platform "${LIFERAY_DOCKER_IMAGE_PLATFORMS}" \
			--push \
			$(get_docker_image_tags_args "${DOCKER_IMAGE_TAGS[@]}") \
			"${TEMP_DIR}" || exit 1
	fi
}

function print_help {
	echo "Usage: ${0} --push"
	echo ""
	echo "The script reads the following environment variables:"
	echo ""
	echo "    LIFERAY_DOCKER_DEVELOPER_MODE (optional): If set to \"true\", all local images will be deleted before building a new one"
	echo "    LIFERAY_DOCKER_ELASTICSEARCH_NETWORK_ADDRESSES (optional): Elasticsearch remote server network addresses"
	echo "    LIFERAY_DOCKER_FIX_PACK_URL (optional): URL to a fix pack"
	echo "    LIFERAY_DOCKER_HUB_TOKEN (optional): Docker Hub token to log in automatically"
	echo "    LIFERAY_DOCKER_HUB_USERNAME (optional): Docker Hub username to log in automatically"
	echo "    LIFERAY_DOCKER_IMAGE_PLATFORMS (optional): Comma separated Docker image platforms to build when the \"push\" parameter is set"
	echo "    LIFERAY_DOCKER_LICENSE_API_HEADER (required for DXP): API header used to generate the trial license"
	echo "    LIFERAY_DOCKER_LICENSE_API_URL (required for DXP): API URL to generate the trial license"
	echo "    LIFERAY_DOCKER_OPENSEARCH_NETWORK_ADDRESSES (optional): OpenSearch remote server network addresses"
	echo "    LIFERAY_DOCKER_OPENSEARCH_PASSWORD (optional): OpenSearch remote server password"
	echo "    LIFERAY_DOCKER_RELEASE_FILE_URL (required): URL to a Liferay bundle"
	echo "    LIFERAY_DOCKER_REPOSITORY (optional): Docker repository"
	echo "    LIFERAY_DOCKER_SLIM (optional): If set to \"true\", the image will be the slim variant"
	echo ""
	echo "Example: LIFERAY_DOCKER_RELEASE_FILE_URL=files.liferay.com/private/ee/portal/7.2.10/liferay-dxp-tomcat-7.2.10-ga1-20190531140450482.7z ${0} push"
	echo ""
	echo "Example: LIFERAY_DOCKER_ELASTICSEARCH_NETWORK_ADDRESSES=["http://es-node1:9200","http://es-node2:9201"] LIFERAY_DOCKER_OPENSEARCH_NETWORK_ADDRESSES=http://es-node1:9203 LIFERAY_DOCKER_OPENSEARCH_PASSWORD=OpenSearchPassword LIFERAY_DOCKER_RELEASE_FILE_URL=files.liferay.com/private/ee/portal/7.2.10/liferay-dxp-tomcat-7.2.10-ga1-20190531140450482.7z LIFERAY_DOCKER_SLIM=true ${0} push"
	echo ""

	exit 1
}

function set_parent_image {
	if (echo "${LIFERAY_DOCKER_RELEASE_VERSION}" | grep -q "q")
	then
		if [[ "$(echo "${LIFERAY_DOCKER_RELEASE_VERSION}" | cut -d '.' -f 1)" -gt 2024 ]]
		then
			return
		fi

		if [[ "$(echo "${LIFERAY_DOCKER_RELEASE_VERSION}" | cut -d '.' -f 1)" -eq 2024 ]] &&
		   [[ "$(echo "${LIFERAY_DOCKER_RELEASE_VERSION}" | cut -d '.' -f 2 | tr -d q)" -ge 3 ]]
		then
			return
		fi

		sed -i 's/liferay\/jdk21:latest AS liferay-jdk21/liferay\/jdk11:latest AS liferay-jdk11/g' "${TEMP_DIR}"/Dockerfile
		sed -i 's/FROM liferay-jdk21/FROM liferay-jdk11/g' "${TEMP_DIR}"/Dockerfile
	elif [ "$(echo "${LIFERAY_DOCKER_RELEASE_VERSION}" | cut -d '.' -f 1,2)" == 7.4 ]
	then
		if [ "${LIFERAY_DOCKER_RELEASE_VERSION}" == "7.4.13.nightly" ]
		then
			return
		fi

		if [ "$(echo "${LIFERAY_DOCKER_RELEASE_VERSION}" | cut -d '.' -f 1,2,3 | cut -d '-' -f 1)" == 7.4.13 ] &&
		   [[ "$(echo "${LIFERAY_DOCKER_RELEASE_VERSION}" | cut -d '-' -f 2 | tr -d u)" -ge 125 ]]
		then
			return
		fi

		if [ "$(echo "${LIFERAY_DOCKER_RELEASE_VERSION}" | cut -d '.' -f 1,2,3)" == 7.4.3 ] &&
		   [[ "$(echo "${LIFERAY_DOCKER_RELEASE_VERSION}" | cut -d '-' -f 2 | sed 's/ga//g')" -ge 125 ]]
		then
			return
		fi

		sed -i 's/liferay\/jdk21:latest AS liferay-jdk21/liferay\/jdk11:latest AS liferay-jdk11/g' "${TEMP_DIR}"/Dockerfile
		sed -i 's/FROM liferay-jdk21/FROM liferay-jdk11/g' "${TEMP_DIR}"/Dockerfile
	elif [[ "$(echo "${LIFERAY_DOCKER_RELEASE_VERSION}" | cut -d '.' -f 1,2 | tr -d .)" -le 73 ]]
	then
		sed -i 's/liferay\/jdk21:latest AS liferay-jdk21/liferay\/jdk11-jdk8:latest AS liferay-jdk11-jdk8/g' "${TEMP_DIR}"/Dockerfile
		sed -i 's/FROM liferay-jdk21/FROM liferay-jdk11-jdk8/g' "${TEMP_DIR}"/Dockerfile
	fi
}

function update_patching_tool {
	if [ -e "${TEMP_DIR}/liferay/tomcat" ]
	then
		sed -i "s@tomcat-[0-9]*.[0-9]*.[0-9]*/@tomcat/@g" "${TEMP_DIR}/liferay/patching-tool/default.properties"
	fi

	if [ -e "${TEMP_DIR}/liferay/patching-tool" ]
	then
		local patching_tool_minor_version=$("${TEMP_DIR}"/liferay/patching-tool/patching-tool.sh version | grep "Patching-tool version")

		if [ ! -n "${patching_tool_minor_version}" ]
		then
			patching_tool_minor_version="2.0.0"
		else
			patching_tool_minor_version=${patching_tool_minor_version##*Patching-tool version: }
		fi

		patching_tool_minor_version=${patching_tool_minor_version%.*}

		if (! echo ${patching_tool_minor_version} | grep -e '[0-9]*[.][0-9]*' >/dev/null)
		then
			echo "Patching Tool update is skipped as it's not a 1.0+ version or the bundle did not include a properly configured Patching Tool."

			return
		fi

		mv "${TEMP_DIR}/liferay/patching-tool/patches" "${TEMP_DIR}/liferay/patching-tool-upgrade-patches"

		rm -fr "${TEMP_DIR}/liferay/patching-tool"

		local latest_patching_tool_version

		#
		# Set the latest patching tool version in a separate line to get the
		# proper exit code.
		#

		latest_patching_tool_version=$(./patching_tool_version.sh ${patching_tool_minor_version})

		local exit_code=$?

		if [ ${exit_code} -gt 0 ]
		then
			echo "./patching_tool_version.sh returned with an error: ${latest_patching_tool_version}"

			exit ${exit_code}
		fi

		echo ""
		echo "Updating Patching Tool to version ${latest_patching_tool_version}."
		echo ""

		download "downloads/patching-tool/patching-tool-${latest_patching_tool_version}.zip" "releases-cdn.liferay.com/tools/patching-tool/patching-tool-${latest_patching_tool_version}.zip"

		unzip -d "${TEMP_DIR}/liferay" -q "downloads/patching-tool/patching-tool-${latest_patching_tool_version}.zip"

		"${TEMP_DIR}/liferay/patching-tool/patching-tool.sh" auto-discovery

		rm -fr "${TEMP_DIR}/liferay/patching-tool/patches"

		mv "${TEMP_DIR}/liferay/patching-tool-upgrade-patches" "${TEMP_DIR}/liferay/patching-tool/patches"

		if [ ! -n "${LIFERAY_DOCKER_TEST_PATCHING_TOOL_VERSION}" ]
		then
			export LIFERAY_DOCKER_TEST_PATCHING_TOOL_VERSION="${latest_patching_tool_version}"
		fi
	fi
}

main "${@}"