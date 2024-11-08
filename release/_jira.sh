#!/bin/bash

source ../_liferay_common.sh

function add_comment_jira_ticket {
	local data=$(
		cat <<- END
		{
			"body": {
				"content": [
					{
						"content": [
							{
								"text": "${1}",
								"type": "text"
							}
						],
						"type": "paragraph"
					}
				],
				"type": "doc",
				"version": 1
			}
		}
		END
	)

	_invoke_jira_api "https://liferay.atlassian.net/rest/api/3/issue/${2}/comment" "${data}"
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