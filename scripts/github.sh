#!/bin/bash

function start_review() {
	# Get pull-request info and list of files modified
	echo "Loading pull-request data from $GIT_BASEURL/repos/$GIT_OWNER/$GIT_REPO/pulls/$GIT_PULL_REQUEST_ID"
	curl -X GET --url "$GIT_BASEURL/repos/$GIT_OWNER/$GIT_REPO/pulls/$GIT_PULL_REQUEST_ID" -L \
		-H "Accept: application/vnd.github+json" \
		-H "User-Agent: $GIT_USER" \
		-H "Authorization: Bearer $GIT_AUTH" \
		-H "X-GitHub-Api-Version: 2022-11-28" \
		-o scripts/pull-request.json
	if [[ ! -f scripts/pull-request.json ]]; then
		echo "ERROR: Invalid pull-request $GIT_PULL_REQUEST_ID"
		exit 1
	fi
	curl -X GET --url "$GIT_BASEURL/repos/$GIT_OWNER/$GIT_REPO/pulls/$GIT_PULL_REQUEST_ID/files" -L \
		-H "Accept: application/vnd.github+json" \
		-H "User-Agent: $GIT_USER" \
		-H "Authorization: Bearer $GIT_AUTH" \
		-H "X-GitHub-Api-Version: 2022-11-28" \
		-o scripts/changes.json

	# Get the commit ID
	COMMIT_ID=$(jq -r '.head.sha' scripts/pull-request.json)
	if [[ -z COMMIT_ID ]]; then
		echo "ERROR: Unable to get commit ID for pull-request $GIT_PULL_REQUEST_ID"
		exit 1
	fi
	# Start the review
	curl -X POST --url "$GIT_BASEURL/repos/$GIT_OWNER/$GIT_REPO/pulls/$GIT_PULL_REQUEST_ID/reviews" -L \
		-H "Accept: application/vnd.github+json" \
		-H "User-Agent: $GIT_USER" \
		-H "Authorization: Bearer $GIT_AUTH" \
		-H "X-GitHub-Api-Version: 2022-11-28" \
		-d "{\"commit_id\":\"$COMMIT_ID\"}" \
		-o scripts/start-review.json
	if [[ ! -f scripts/start-review.json ]]; then
		echo "ERROR: Unable to create pending review for $GIT_PULL_REQUEST_ID"
		exit 1
	fi
	REVIEW_ID=$(jq -r '.id // empty' scripts/start-review.json)
	if [[ -z "$REVIEW_ID" ]]; then
		ERR=$(jq -r '.message' scripts/start-review.json)
		echo "Unable to start review of pull-request $GIT_PULL_REQUEST_ID: $ERR"
		exit 1
	fi
	echo "Pull-request review $REVIEW_ID started"
}

function get_modified_resources() {
	RESOURCES=$(jq -r "map(select(.filename | endswith(\".java\")) | .filename) | map(\"$PROJECT_NAME/\" + .) | join(\",\")" scripts/changes.json)
	echo "Modified files: $RESOURCES"
}

function cancel_review() {
	curl -X DELETE --url "$GIT_BASEURL/repos/$GIT_OWNER/$GIT_REPO/pulls/$GIT_PULL_REQUEST_ID/reviews/$REVIEW_ID" -L \
		-H "Accept: application/vnd.github+json" \
		-H "User-Agent: $GIT_USER" \
		-H "Authorization: Bearer $GIT_AUTH" \
		-H "X-GitHub-Api-Version: 2022-11-28"
		-o scripts/cancelled.json
	echo "Pull-request review $REVIEW_ID cancelled"
}

function finish_review() {
	case "$2" in
		review | ok )
			STATUS=COMMENT
			;;
		needsWork )
			STATUS=REQUEST_CHANGES
			;;
		* )
			echo "Unknown pull-request status $2"
			exit 1
			;;
	esac
	# Finish the review
	MESSAGE="$1"
	echo "Finishing pull-request review with comment:"
	echo "$MESSAGE"
	MESSAGE_ESC=$(echo "$MESSAGE" | jq -Rsa .)
	BODY="{\"body\": $MESSAGE_ESC, \"event\": \"$STATUS\"}"
	curl -X POST --url "$GIT_BASEURL/repos/$GIT_OWNER/$GIT_REPO/pulls/$GIT_PULL_REQUEST_ID/reviews/$REVIEW_ID/events" -L \
		-H "Accept: application/vnd.github+json" \
		-H "User-Agent: $GIT_USER" \
		-H "Authorization: Bearer $GIT_AUTH" \
		-H "X-GitHub-Api-Version: 2022-11-28" \
		-d "$BODY" \
		-o scripts/final_comment.json
	echo ""
	echo "Pull-request review $REVIEW_ID finished with status $STATUS"
}
