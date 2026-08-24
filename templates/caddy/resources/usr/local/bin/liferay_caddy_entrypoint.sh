#!/bin/bash

function log_configuration {
	local checksum
	local file_name
	local file_type

	checksum=$(sha256sum /etc/caddy/Caddyfile | sed --expression "s/ .*//")

	_log_json "Liferay Caddy configuration /etc/caddy/Caddyfile has checksum ${checksum}."

	for file_name in /etc/caddy.d/*
	do
		if [ ! -e "${file_name}" ]
		then
			continue
		fi

		checksum=$(sha256sum "${file_name}" | sed --expression "s/ .*//")

		file_type="unmanaged"

		if [ "${file_name}" == "/etc/caddy.d/liferay_caddy_file" ]
		then
			file_type="generated"
		fi

		_log_json "Liferay Caddy configuration import ${file_name} is ${file_type} and has checksum ${checksum}."
	done
}

function main {
	if [ ! -n "${LIFERAY_ROUTES_DXP}" ]
	then
		LIFERAY_ROUTES_DXP="/etc/liferay/lxc/dxp-metadata"
	fi

	local protocol=$(cat "${LIFERAY_ROUTES_DXP}/com.liferay.lxc.dxp.server.protocol" 2> /dev/null)

	for i in $(cat "${LIFERAY_ROUTES_DXP}/com.liferay.lxc.dxp.domains" 2> /dev/null)
	do
		local url="${protocol}://${i}"

		_log_json "Liferay Caddy is allowing cross-origin requests from ${url}."

		cat >> /etc/caddy.d/liferay_caddy_file << EOF
@origin${url} header Origin ${url}
header @origin${url} Access-Control-Allow-Origin "${url}"
EOF
	done

	if [ -n "${LIFERAY_CADDY_404_URL}" ]
	then
		_log_json "Liferay Caddy is redirecting HTTP 404 responses to ${LIFERAY_CADDY_404_URL}."

		cat >> /etc/caddy.d/liferay_caddy_file << EOF
handle_errors {

	@404 expression {http.error.status_code} == 404
	handle @404 {
		redir * ${LIFERAY_CADDY_404_URL} 301
	}

}
EOF
	fi

	log_configuration

	caddy run --adapter caddyfile --config /etc/caddy/Caddyfile
}

function _log_json {
	local escaped_message

	escaped_message=$(echo "${1}" | sed --expression 's/"/\\"/g')

	local script_name

	script_name=$(basename "${0}")

	local severity="${2:-INFO}"

	local timestamp

	timestamp=$(date --utc +"%Y-%m-%dT%H:%M:%SZ")

	printf "{\"message\": \"%s\", \"script\": \"%s\", \"severity\": \"%s\", \"timestamp\": \"%s\"}\n" "${escaped_message}" "${script_name}" "${severity}" "${timestamp}"
}

main