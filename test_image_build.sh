#!/bin/bash

source ./_test_common.sh

function main {
	set_up

	test_image_successfully_built "${LATEST_RELEASE}"
	test_image_successfully_built 7.3.10-u36
	test_latest_is_not_slim "${LATEST_RELEASE}"

	tear_down
}

function run_container {
	CONTAINER_ID=$(docker run --detach --name "liferay-container-${1}" "liferay/dxp:${1}")

	for counter in {1..200}
	do
		local health_status=$(docker inspect --format="{{json .State.Health.Status}}" "${CONTAINER_ID}")
		local ignore_license=$(docker logs ${CONTAINER_ID} 2> /dev/null | grep --count "Starting Liferay Portal")
		local license_status=$(docker logs ${CONTAINER_ID} 2> /dev/null | grep --count "License registered for DXP Development")

		if [ "${health_status}" == "\"healthy\"" ] && ([ ${ignore_license} -gt 0 ] || [ ${license_status} -gt 0 ])
		then
			echo "${health_status}"

			return
		fi

		sleep 3
	done

	echo "Failed"
}

function set_up {
	export LATEST_RELEASE=$(yq eval ".quarterly | keys | .[-1]" "${PWD}/bundles.yml")

	LIFERAY_DOCKER_IMAGE_FILTER="${LATEST_RELEASE}" LIFERAY_DOCKER_SLIM="true" ./build_all_images.sh &> /dev/null
	LIFERAY_DOCKER_IMAGE_FILTER="7.3.10-u36" ./build_all_images.sh &> /dev/null
}

function tear_down {
	docker stop "liferay-container-${LATEST_RELEASE}" > /dev/null
	docker stop "liferay-container-7.3.10-u36" > /dev/null

	docker rm "liferay-container-${LATEST_RELEASE}" > /dev/null
	docker rm "liferay-container-7.3.10-u36" > /dev/null

	docker rmi -f $(docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | grep '^liferay/' | awk '{print $2}') &> /dev/null

	unset LATEST_RELEASE
}

function test_image_successfully_built {
	echo -e "Running test_image_successfully_built for version ${1}.\n"

	assert_equals \
		$(run_container "${1}") \
		"\"healthy\""
}

function test_latest_is_not_slim {
	echo -e "Running test_latest_is_not_slim for version ${1}.\n"

	assert_equals \
		$(docker images --filter "reference=liferay/dxp:${1}" --format "{{.ID}}") \
		$(docker images --filter "reference=liferay/dxp:latest" --format "{{.ID}}")
}

main