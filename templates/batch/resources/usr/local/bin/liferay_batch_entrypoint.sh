#!/bin/bash

function main {
	if [ ! -n "${LIFERAY_BATCH_OAUTH_APP_ERC}" ]
	then
		echo "Set the environment variable LIFERAY_BATCH_OAUTH_APP_ERC."

		exit 1
	fi

	if [ ! -n "${LIFERAY_BATCH_CURL_OPTIONS}" ]
	then
		LIFERAY_BATCH_CURL_OPTIONS=" "
	fi

	if [ ! -n "${LIFERAY_ROUTES_CLIENT_EXTENSION}" ]
	then
		LIFERAY_ROUTES_CLIENT_EXTENSION="/etc/liferay/lxc/ext-init-metadata"
	fi

	if [ ! -n "${LIFERAY_ROUTES_DXP}" ]
	then
		LIFERAY_ROUTES_DXP="/etc/liferay/lxc/dxp-metadata"
	fi

	echo "OAuth Application ERC: ${LIFERAY_BATCH_OAUTH_APP_ERC}"
	echo ""

	local lxc_dxp_main_domain=$(cat ${LIFERAY_ROUTES_DXP}/com.liferay.lxc.dxp.main.domain)

	if [ ! -n "${lxc_dxp_main_domain}" ]
	then
		lxc_dxp_main_domain=$(cat ${LIFERAY_ROUTES_DXP}/com.liferay.lxc.dxp.mainDomain)
	fi

	local lxc_dxp_server_protocol=$(cat ${LIFERAY_ROUTES_DXP}/com.liferay.lxc.dxp.server.protocol)
	local oauth2_client_id=$(cat ${LIFERAY_ROUTES_CLIENT_EXTENSION}/${LIFERAY_BATCH_OAUTH_APP_ERC}.oauth2.headless.server.client.id)
	local oauth2_client_secret=$(cat ${LIFERAY_ROUTES_CLIENT_EXTENSION}/${LIFERAY_BATCH_OAUTH_APP_ERC}.oauth2.headless.server.client.secret)
	local oauth2_token_uri=$(cat ${LIFERAY_ROUTES_CLIENT_EXTENSION}/${LIFERAY_BATCH_OAUTH_APP_ERC}.oauth2.token.uri)

	echo "LXC DXP Main Domain: ${lxc_dxp_main_domain}"
	echo "LXC DXP Server Protocol: ${lxc_dxp_server_protocol}"
	echo ""
	echo "OAuth Client ID: ${oauth2_client_id}"
	echo "OAuth Client Secret: ${oauth2_client_secret}"
	echo "OAuth Token URI: ${oauth2_token_uri}"
	echo ""

	local oauth2_token_response=$(\
		curl \
			--data "client_id=${oauth2_client_id}&client_secret=${oauth2_client_secret}&grant_type=client_credentials" \
			--header "Content-type: application/x-www-form-urlencoded" \
			--request POST \
			--silent \
			${LIFERAY_BATCH_CURL_OPTIONS} \
			"${lxc_dxp_server_protocol}://${lxc_dxp_main_domain}${oauth2_token_uri}" \
		| jq --raw-output ".")

	echo "OAuth Token Response: ${oauth2_token_response}"
	echo ""

	local oauth2_access_token=$(jq --raw-output ".access_token" <<< ${oauth2_token_response})

	if [ "${oauth2_access_token}" == "" ]
	then
		echo "Unable to get OAuth 2 access token."

		exit 1
	fi

	if [ -e "/opt/liferay/site-initializer/site-initializer.json" ]
	then
		echo "Processing: /opt/liferay/site-initializer/site-initializer.json"
		echo ""

		local href="/o/headless-site/v1.0/sites/by-external-reference-code/"

		echo "HREF: ${href}"

		local site=$(jq --raw-output '.' /opt/liferay/site-initializer/site-initializer.json)

		echo "Site: ${site}"

		local external_reference_code=$(jq --raw-output ".externalReferenceCode" <<< "${site}")

		local put_response=$(\
			curl \
				--form "file=@/opt/liferay/site-initializer/site-initializer.zip;type=application/zip" \
				--form "site=${site}" \
				--header "Accept: application/json" \
				--header "Authorization: Bearer ${oauth2_access_token}" \
				--header "Content-Type: multipart/form-data" \
				--request PUT \
				--silent \
				${LIFERAY_BATCH_CURL_OPTIONS} \
				"${lxc_dxp_server_protocol}://${lxc_dxp_main_domain}${href}${external_reference_code}" \
			| jq --raw-output ".")

		echo "PUT Response: ${put_response}"
		echo ""

		if [ ! -n "${put_response}" ]
		then
			echo "Received invalid PUT response."

			exit 1
		fi
	fi

	find /opt/liferay/batch -type f -name "*.batch-engine-data.json" -print0 2> /dev/null | LC_ALL=C sort -z |
	while IFS= read -r -d "" file_name
	do
		echo "Processing: ${file_name}"
		echo ""

		local href=$(jq --raw-output ".actions.createBatch.href" ${file_name})

		if [[ "$href" == "null" ]]
		then
			local class_name=$(jq --raw-output ".configuration.className" ${file_name})

			if [[ "$class_name" == "null" ]]
			then
				echo "Batch data file is missing configuration class name."

				exit 1
			fi

			href="/o/headless-batch-engine/v1.0/import-task/${class_name}"
		fi

		href="${href#*://*/}"

		if [[ ! $href =~ ^/.* ]]
		then
			href="/${href}"
		fi

		echo "HREF: ${href}"

		jq --raw-output ".items" ${file_name} > /tmp/liferay_batch_entrypoint.items.json

		echo "Items: $(</tmp/liferay_batch_entrypoint.items.json)"

		local parameters=$(jq --raw-output '.configuration.parameters | [map_values(. | @uri) | to_entries[] | .key + "=" + .value] | join("&")' ${file_name} 2>/dev/null)

		if [ "${parameters}" != "" ]
		then
			parameters="?${parameters}"
		fi

		echo "Parameters: ${parameters}"

		local post_response=$(\
			curl \
				--data @/tmp/liferay_batch_entrypoint.items.json \
				--header "Accept: application/json" \
				--header "Authorization: Bearer ${oauth2_access_token}" \
				--header "Content-Type: application/json" \
				--request POST \
				--silent \
				${LIFERAY_BATCH_CURL_OPTIONS} \
				"${lxc_dxp_server_protocol}://${lxc_dxp_main_domain}${href}${parameters}" \
			| jq --raw-output ".")

		echo "POST Response: ${post_response}"
		echo ""

		if [ ! -n "${post_response}" ]
		then
			echo "Received invalid POST response."

			rm /tmp/liferay_batch_entrypoint.items.json

			exit 1
		fi

		local external_reference_code=$(jq --raw-output ".externalReferenceCode" <<< "${post_response}")

		local status=$(jq --raw-output ".executeStatus//.status" <<< "${post_response}")

		until [ "${status}" == "COMPLETED" ] || [ "${status}" == "FAILED" ] || [ "${status}" == "NOT_FOUND" ]
		do
			local status_response=$(\
				curl \
					--header "Authorization: Bearer ${oauth2_access_token}" \
					--header "accept: application/json" \
					--request GET \
					--silent \
					${LIFERAY_BATCH_CURL_OPTIONS} \
					"${lxc_dxp_server_protocol}://${lxc_dxp_main_domain}/o/headless-batch-engine/v1.0/import-task/by-external-reference-code/${external_reference_code}" \
				| jq --raw-output ".")

			status=$(jq --raw-output '.executeStatus//.status' <<< "${status_response}")

			echo "Execute Status: ${status}"
		done

		rm /tmp/liferay_batch_entrypoint.items.json

		if [ "${status}" == "FAILED" ]
		then
			exit 1
		fi
	done
}

main