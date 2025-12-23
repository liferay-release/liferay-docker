#!/bin/bash

test_bom_copy_tld

tear_down

lc_time_run generate_pom_release_api
lc_time_run generate_pom_release_bom
lc_time_run generate_pom_release_bom_compile_only
lc_time_run generate_pom_release_distro

if [ -n "${nexus_repository_name}" ]
then
	_download_bom_file
fi

for portal_jar in portal-kernel support-tomcat
do
	_manage_bom_jar "${_BUNDLES_DIR}/tomcat/lib/ext/${portal_jar}.jar"
done

curl \
	"${api_url}/login" \
	--data "${data}" \
	--header "Content-Type: application/json" \
	--request POST \
	--silent

local http_code=$( \
	curl -o /dev/null -s -w "%{http_code}" "$url"
)

if is_abc
then
	echo "abc"
fi

file_name=$(basename "$1")

docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" | \
	grep --extended-regexp ":.*(-slim).*" | \
	awk '{print $2}' | \
	xargs --no-run-if-empty docker rmi --force &> /dev/null

############################################################
# PRIVATE FUNCTIONS
############################################################

function _download_bom_file {
	:
}
