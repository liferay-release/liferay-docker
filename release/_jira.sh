#!/bin/bash

source ../_liferay_common.sh

function add_jira_issue {
	local data=$(
		cat <<- END
		{
			"fields": {
				"assignee": {
					"id": "${1}"
				},
				"components": [
					{
						"name": "${2}"
					}
				],
				"issuetype": {
					"name": "${3}"
				},
				"project": {
					"key": "${4}"
				},
				"summary": "${5}",
				"${6}": "${7}"
			}
		}
		END
	)

	_invoke_jira_api "https://liferay.atlassian.net/rest/api/3/issue/" "${data}"
}

function add_jira_issue_comment {
	_invoke_jira_api "https://liferay.atlassian.net/rest/api/3/issue/${1}/comment" "${2}"
}

function _invoke_jira_api {
	local http_response=$(curl \
		"${1}" \
		--data "${2}" \
		--fail \
		--header "Accept: application/json" \
		--header "Content-Type: application/json" \
		--max-time 10 \
		--request "POST" \
		--retry 3 \
		--silent \
		--user "${LIFERAY_RELEASE_JIRA_USER}:${LIFERAY_RELEASE_JIRA_TOKEN}")

	if [ "$(echo "${http_response}" | jq --exit-status '.id?')" != "null" ]
	then
		echo "${http_response}" | jq --raw-output '.key'

		return "${LIFERAY_COMMON_EXIT_CODE_OK}"
	fi

	echo "${LIFERAY_COMMON_EXIT_CODE_BAD}"
}