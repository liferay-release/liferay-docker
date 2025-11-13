#!/bin/bash

function main {
	local output=$(curl --cookie "/tmp/hc" --show-error --silent --verbose "http://localhost:8080/c/portal/layout" 2>&1) || exit 1

	if echo "${output}" | grep -q "WARNING: failed to open cookie file"
	then
		curl --cookie-jar "/tmp/hc" --show-error --silent "http://localhost:8080/c/portal/layout" || exit 1
	fi
}

main