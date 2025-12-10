#!/bin/bash

function start_review() {
	# Get pull-request info and list of files modified
	echo "Loading pull-request data from $GIT_BASEURL/repos/$GIT_OWNER/$GIT_REPO/pulls/$GIT_PULL_REQUEST_ID"
	curl -X GET --url "$GIT_BASEURL/repos/$GIT_OWNER/$GIT_REPO/pulls/$GIT_PULL_REQUEST_ID" -L \
		-H "Accept: application/vnd.github+json" \
		-H "User-Agent: $GIT_USER" \
		-H "Authorization: Bearer $GIT_AUTH" \
		-H "X-GitHub-Api-Version: 2022-11-28" \
		-o artifacts/pull-request.json
	if [[ ! -f artifacts/pull-request.json ]]; then
		echo "ERROR: Invalid pull-request $GIT_PULL_REQUEST_ID"
		exit 1
	fi
	echo "Loading modified files from pull-request"
	curl -X GET --url "$GIT_BASEURL/repos/$GIT_OWNER/$GIT_REPO/pulls/$GIT_PULL_REQUEST_ID/files" -L \
		-H "Accept: application/vnd.github+json" \
		-H "User-Agent: $GIT_USER" \
		-H "Authorization: Bearer $GIT_AUTH" \
		-H "X-GitHub-Api-Version: 2022-11-28" \
		-o artifacts/changes.json

	# Get the commit ID
	COMMIT_ID=$(jq -r '.head.sha' artifacts/pull-request.json)
	if [[ -z COMMIT_ID ]]; then
		echo "ERROR: Unable to get commit ID for pull-request $GIT_PULL_REQUEST_ID"
		exit 1
	fi
	case "$REVIEW_MODE" in
		review )
			echo "Starting pull-request review"
			curl -X POST --url "$GIT_BASEURL/repos/$GIT_OWNER/$GIT_REPO/pulls/$GIT_PULL_REQUEST_ID/reviews" -L \
				-H "Accept: application/vnd.github+json" \
				-H "User-Agent: $GIT_USER" \
				-H "Authorization: Bearer $GIT_AUTH" \
				-H "X-GitHub-Api-Version: 2022-11-28" \
				-d "{\"commit_id\":\"$COMMIT_ID\"}" \
				-o artifacts/start-review.json
			if [[ ! -f artifacts/start-review.json ]]; then
				echo "ERROR: Unable to create pending review for $GIT_PULL_REQUEST_ID"
				exit 1
			fi
			REVIEW_ID=$(jq -r '.id // empty' artifacts/start-review.json)
			if [[ -z "$REVIEW_ID" ]]; then
				ERR=$(jq -r '.message' artifacts/start-review.json)
				echo "Unable to start review of pull-request $GIT_PULL_REQUEST_ID: $ERR"
				exit 1
			fi
			echo "Pull-request review $REVIEW_ID started"
			echo ""
			;;
		check )
			echo "Creating a pull-request check run"
			STARTED_AT=$(date -Is)
			curl -X POST --url "$GIT_BASEURL/repos/$GIT_OWNER/$GIT_REPO/check-runs" -L \
				-H "Accept: application/vnd.github+json" \
				-H "User-Agent: $GIT_USER" \
				-H "Authorization: Bearer $GIT_AUTH" \
				-H "X-GitHub-Api-Version: 2022-11-28" \
				-d "{\"name\":\"$GIT_USER\",\"head_sha\":\"$COMMIT_ID\",\"status\":\"in_progress\",\"external_id\":\"$GIT_PULL_REQUEST_ID\",\"started_at\":\"$STARTED_AT\",\"output\":{\"title\":\"$GIT_USER Analysis\",\"summary\":\"\",\"text\":\"\"}}" \
				-o artifacts/start-checks.json
			if [[ ! -f artifacts/start-checks.json ]]; then
				echo "ERROR: Unable to start check run for pull-request $GIT_PULL_REQUEST_ID"
				exit 1
			fi
			CHECK_ID=$(jq -r '.id // empty' artifacts/start-checks.json)
			if [[ -z "$CHECK_ID" ]]; then
				ERR=$(jq -r '.message' artifacts/start-checks.json)
				echo "Unable to start start check run for pull-request $GIT_PULL_REQUEST_ID: $ERR"
				exit 1
			fi
			echo "Pull-request check run $CHECK_ID started"
			echo ""
			;;
		status )
			echo "Creating a pending commit status"
			curl -X POST --url "$GIT_BASEURL/repos/$GIT_OWNER/$GIT_REPO/statuses/$COMMIT_ID" -L \
				-H "Accept: application/vnd.github+json" \
				-H "User-Agent: $GIT_USER" \
				-H "Authorization: Bearer $GIT_AUTH" \
				-H "X-GitHub-Api-Version: 2022-11-28" \
				-d "{\"state\":\"pending\",\"target_url\"=\"$BUILD_URL\",\"description\":\"$GIT_USER is performing analysis\",\"context\":\"continuous-integration/jenkins\"}" \
				-o artifacts/start-status.json
			if [[ ! -f artifacts/start-status.json ]]; then
				echo "ERROR: Unable to create pending status for pull-request $GIT_PULL_REQUEST_ID"
				exit 1
			fi
			STATUS_ID=$(jq -r '.id // empty' artifacts/start-status.json)
			if [[ -z "$STATUS_ID" ]]; then
				ERR=$(jq -r '.message' artifacts/start-status.json)
				echo "Unable to create pending status for pull-request $GIT_PULL_REQUEST_ID: $ERR"
				exit 1
			fi
			echo "Commit status $STATUS_ID is pending"
			echo ""
			;;
	esac
}

function get_modified_resources() {
	RESOURCES=$(jq -r "map(select(.filename | endswith(\".java\")) | .filename) | map(\"$PROJECT_NAME/\" + .) | join(\",\")" artifacts/changes.json)
	echo "Modified files: $RESOURCES"
}

function cancel_review() {
	case "$REVIEW_MODE" in
		review )
			echo "Cancelling pull-request review"
			curl -X DELETE --url "$GIT_BASEURL/repos/$GIT_OWNER/$GIT_REPO/pulls/$GIT_PULL_REQUEST_ID/reviews/$REVIEW_ID" -L \
				-H "Accept: application/vnd.github+json" \
				-H "User-Agent: $GIT_USER" \
				-H "Authorization: Bearer $GIT_AUTH" \
				-H "X-GitHub-Api-Version: 2022-11-28" \
				-o artifacts/cancelled.json
			echo "Pull-request review $REVIEW_ID is cancelled"
			echo ""
			;;
		check )
			echo "Cancelling pull-request check run"
			MESSAGE_ESC=$(echo "$SUMMARY" | jq -Rsa .)
			NOW=$(date -Is)
			curl -X PATCH --url "$GIT_BASEURL/repos/$GIT_OWNER/$GIT_REPO/check-runs/$CHECK_ID" -L \
				-H "Accept: application/vnd.github+json" \
				-H "User-Agent: $GIT_USER" \
				-H "Authorization: Bearer $GIT_AUTH" \
				-H "X-GitHub-Api-Version: 2022-11-28" \
				-d "{\"name\":\"$GIT_USER\",\"status\":\"completed\",\"external_id\":\"$GIT_PULL_REQUEST_ID\",\"started_at\":\"$STARTED_AT\",\"completed_at\":\"$NOW\",\"details_url\":\"$BUILD_URL\",\"conclusion\":\"cancelled\",\"output\":{\"title\":\"$GIT_USER analysis cancelled\",\"text\":\"$MESSAGE_ESC\"}}" \
				-o artifacts/cancelled.json
			echo "Pull-request check run for $CHECK_ID is cancelled"
			echo ""
			;;
		status )
			COMMIT_ID=$(git rev-parse HEAD)
			echo "Setting commit status to failure"
			curl -X POST --url "$GIT_BASEURL/repos/$GIT_OWNER/$GIT_REPO/statuses/$COMMIT_ID" -L \
				-H "Accept: application/vnd.github+json" \
				-H "User-Agent: $GIT_USER" \
				-H "Authorization: Bearer $GIT_AUTH" \
				-H "X-GitHub-Api-Version: 2022-11-28" \
				-d "{\"state\":\"failure\",\"target_url\"=\"$BUILD_URL\",\"description\":\"Analysis aborted\",\"context\":\"$GIT_USER\"}" \
				-o artifacts/cancelled.json
			echo "Commit status $STATUS_ID marked as failure"
			echo ""
			;;
	esac
}

function finish_review() {
	case "$2" in
		review | ok )
			STATUS=COMMENT
			CONCLUSION=success
			STATE=success
			;;
		needsWork )
			STATUS=REQUEST_CHANGES
			CONCLUSION=action_required
			STATE=failure
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
	case "$REVIEW_MODE" in
		review )
			curl -X POST --url "$GIT_BASEURL/repos/$GIT_OWNER/$GIT_REPO/pulls/$GIT_PULL_REQUEST_ID/reviews/$REVIEW_ID/events" -L \
				-H "Accept: application/vnd.github+json" \
				-H "User-Agent: $GIT_USER" \
				-H "Authorization: Bearer $GIT_AUTH" \
				-H "X-GitHub-Api-Version: 2022-11-28" \
				-d "{\"body\": $MESSAGE_ESC, \"event\": \"$STATUS\"}" \
				-o artifacts/finish_review.json
			echo "Pull-request review $REVIEW_ID finished with status $STATUS"
			echo ""
			;;
		check )
			NOW=$(date -Is)
			curl -X PATCH --url "$GIT_BASEURL/repos/$GIT_OWNER/$GIT_REPO/check-runs/$CHECK_ID" -L \
				-H "Accept: application/vnd.github+json" \
				-H "User-Agent: $GIT_USER" \
				-H "Authorization: Bearer $GIT_AUTH" \
				-H "X-GitHub-Api-Version: 2022-11-28" \
				-d "{\"name\":\"$GIT_USER\",\"status\":\"completed\",\"external_id\":\"$GIT_PULL_REQUEST_ID\",\"started_at\":\"$STARTED_AT\",\"completed_at\":\"$NOW\",\"details_url\":\"$BUILD_URL\",\"conclusion\":\"$CONCLUSION\",\"output\":{\"title\":\"$GIT_USER analysis complete\",\"text\":\"$MESSAGE_ESC\"}}" \
				-o artifacts/finish_check.json
			echo "Pull-request check run for $CHECK_ID is cancelled"
			echo ""
			;;
		status )
			COMMIT_ID=$(git rev-parse HEAD)
			curl -X POST --url "$GIT_BASEURL/repos/$GIT_OWNER/$GIT_REPO/statuses/$COMMIT_ID" -L \
				-H "Accept: application/vnd.github+json" \
				-H "User-Agent: $GIT_USER" \
				-H "Authorization: Bearer $GIT_AUTH" \
				-H "X-GitHub-Api-Version: 2022-11-28" \
				-d "{\"state\":\"$STATE\",\"target_url\"=\"$BUILD_URL\",\"description\":\"Analysis complete\",\"context\":\"$GIT_USER\"}" \
				-o artifacts/finish_status.json
			echo "Commit status $STATUS_ID marked as $STATE"
			curl -X POST --url "$GIT_BASEURL/repos/$GIT_OWNER/$GIT_REPO/issues/$GIT_PULL_REQUEST_ID/comments" -L \
				-H "Accept: application/vnd.github+json" \
				-H "User-Agent: $GIT_USER" \
				-H "Authorization: Bearer $GIT_AUTH" \
				-H "X-GitHub-Api-Version: 2022-11-28" \
				-d "{\"body\": $MESSAGE_ESC}" \
				-o artifacts/finish_comment.json
			echo "Summary comment added to pull-request $GIT_PULL_REQUEST_ID"
			echo ""
			;;
	esac
}
