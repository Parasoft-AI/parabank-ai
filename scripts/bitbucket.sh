#!/bin/bash

function start_review() {
	echo "Loading pull-request data from $GIT_BASEURL/$GIT_PROJECT/repos/$GIT_REPO/pull-requests/$GIT_PULL_REQUEST_ID"
	curl --request GET --url "$GIT_BASEURL/$GIT_PROJECT/repos/$GIT_REPO/pull-requests/$GIT_PULL_REQUEST_ID" \
		--header 'Accept: application/json' \
		-H "Authorization: Basic $GIT_AUTH" \
		-o pull-request.json
	if [[ ! -f pull-request.json ]]; then
		echo "ERROR: Invalid pull-request $GIT_PULL_REQUEST_ID"
		exit 1
	fi
	curl --request GET --url "$GIT_BASEURL/$GIT_PROJECT/repos/$GIT_REPO/pull-requests/$GIT_PULL_REQUEST_ID/changes" \
		--header 'Accept: application/json' \
		-H "Authorization: Basic $GIT_AUTH" \
		-o changes.json
}

function get_modified_resources() {
	RESOURCES=$(jq -r '.values | map("$PROJECT_NAME/" + (.path.toString)) | join(",")' changes.json)
	echo "Modified files: $RESOURCES"
}

function cancel_review() {
	# Nothing to do
}

function finish_review() {
	if [[ "$2" == "ok" ]]; then
		curl --request POST --url "$GIT_BASEURL/$GIT_PROJECT/repos/$GIT_REPO/pull-requests/$GIT_PULL_REQUEST_ID/comments" \
			--header 'Accept: application/json' \
			--header 'Content-Type: application/json' \
			-H "Authorization: Basic $GIT_AUTH" \
			--data "{ \"text\": \"$1\" }"
		echo "Added comment to pull-request $GIT_PULL_REQUEST_ID"
	else
		case "$2" in
			review )
				STATUS=UNAPPROVED
				;;
			needsWork )
				STATUS=NEEDS_WORK
				;;
			* )
				echo "Unknown pull-request status $2"
				exit 1
				;;
		esac
		curl --request PUT --url "$GIT_BASEURL/$GIT_PROJECT/repos/$GIT_REPO/pull-requests/$GIT_PULL_REQUEST_ID/participants/$GIT_USER" \
			--header 'Accept: application/json' \
			--header 'Content-Type: application/json' \
			-H "Authorization: Basic $GIT_AUTH" \
			--data "{ \"user\": { \"name\": \"$GIT_USER\", \"emailAddress\": \"$GIT_USER@parasoft.com\", \"displayName\": \"$GIT_USER\", \"active\": true, \"slug\": \"$GIT_USER\", \"type\": \"NORMAL\", \"links\": {} }, \"role\": \"REVIEWER\", \"approved\": false, \"status\": \"$STATUS\" }"
		echo "Status of pull-request $GIT_PULL_REQUEST_ID is now $STATUS"
	fi
}
