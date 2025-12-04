#!/bin/bash

MVN=
COPILOT=
GIT_TYPE=GitHub
GIT_PULL_REQUEST_ID=
GIT_PROJECT=XTEST
GIT_OWNER="bmcglau-parasoft"
GIT_REPO="parabank-ai"
GIT_BASEURL="https://api.github.com"
GIT_USER="bmcglau-parasoft"
GOALS=

SA_CONFIG="builtin://Demo Configuration"
SA_SETTINGS="scripts/jtestcli.properties"
TIA_SETTINGS="scripts/jtestcli.properties"
TESTGEN_SETTINGS="scripts/testgen.properties"

function print_usage() {
	echo "Must be run from root folder of Parabank-AI repo"
	echo ""
	echo "  Usage:  run-copilot-fix.sh --pull-request <id> --git-auth <token> <goal[ goal2, ...]> [<options>]"
	echo ""
	echo "Options:  --pull-request <id>               The ID of the pull-request on Github or Bitbucket"
	echo "          --git-base-url <url>              Overrides base URL for pull-request API calls"
	echo "          --git-type <GitHub|BitBucket>     Default: GitHub"
	echo "          --git-owner <github_owner>        Only used for GitHub"
	echo "          --git-project <bitbucket_project> Only used for BitBucket"
	echo "          --git-repo <repository_name>      Name of the repository"
	echo "          --git-auth <token>                Overrides token for making pull-request API calls"
	echo "                                            Must provide permissions to make editing calls to pull-requests"
	echo "          --git-user <username>             Username for interacting with pull-request API"
	echo "                                            Must match the auth token"
	echo "          --sa-config <configuration>       Jtest configuration to use when performing static analysis"
	echo "                                            Default: 'builtin://Demo Configuration'"
	echo "          --sa-settings <settings>          Path to the .properties file for Jtest static analysis settings"
	echo "          --tia-settings <settings>         Path to the .properties file for Jtest impacted test execution settings"
	echo "          --testgen-settings <settings>     Path to the .properties file for Jtest bulk creation"
	echo "          --maven-path <path>               Path to maven home - bin/mvn should be relative to this directory"
	echo "          --copilot-path <path>             Path to copilot executable"
	echo ""
	echo "Goals:    run-test                          Runs impacted tests on the current branch"
	echo "          static                            Perform Static Analysis on modified files in the current branch"
	echo "          static-fix                        Asks CoPilot to fix violations - auto-includes 'static' goal"
	echo "          testgen                           Performs bulk creation for all .java files modified in the pull-request and commits them"
}
function missingArg () {
	echo "ERROR:  missing argument for:  $1"
	print_usage
	exit 1
}

while (( "$#" ))
do
	case "$1" in
		--help )			print_usage; exit 0 ;;
		--pull-request )	GIT_PULL_REQUEST_ID="${2// }";	shift 2 || missingArg --pull-request ;;
		--git-type )		GIT_TYPE="${2// }";				shift 2 || missingArg --git-type
			if [[ "$GIT_TYPE" == "BitBucket" ]]; then
				GIT_BASEURL="https://trove.parasoft.com/rest/api/latest/projects"
				GIT_USER="jenkins-git"
			fi
			;;
		--git-project )		 GIT_PROJECT="${2// }";		 shift 2 || missingArg --git-project  ;;
		--git-owner )		 GIT_OWNER="${2// }";		 shift 2 || missingArg --git-owner	  ;;
		--git-repo )		 GIT_REPO="${2// }";		 shift 2 || missingArg --git-repo	  ;;
		--git-base-url )	 GIT_BASEURL="${2// }";		 shift 2 || missingArg --git-base-url ;;
		--git-auth )		 GIT_AUTH="${2// }";		 shift 2 || missingArg --git-auth	  ;;
		--git-user )		 GIT_USER="${2// }";		 shift 2 || missingArg --git-user	  ;;
		--sa-config )		 SA_CONFIG="${2// }";		 shift 2 || missingArg --sa-config	  ;;
		--sa-settings )		 SA_SETTINGS="${2// }";		 shift 2 || missingArg --sa-settings  ;;
		--testgen-settings ) TESTGEN_SETTINGS="${2// }"; shift 2 || missingArg --testgen-settings  ;;
		--maven-path )       MVN_PATH="${2// }/bin/mvn"; shift 2 || missingArg --maven-path
			if [[ -f "$MVN_PATH" ]]; then
				MVN="$MVN_PATH"
			else
				echo "mvn not found at $MVN_PATH"
				exit 1
			fi
			;;
		--copilot-path )     COPILOT_PATH="${2// }";     shift 2 || missingArg --copilot-path
			if [[ -f "$COPILOT_PATH" ]]; then
				COPILOT="$COPILOT_PATH"
			else
				echo "copilot not found at $COPILOT_PATH"
				exit 1
			fi
			;;
		static | static-fix | run-test | testgen )    GOALS+="${1// },"; shift 1 ;;
		* )
			echo "ERROR:  parameter not understood:  $1"
			print_usage
			exit 1
			;;
	esac
done

if [[ -z "$GOALS" ]]; then
	GOALS="static-fix,run-test,testgen"
	echo "No goals specified - all goals will be run"
fi

if [[ -z "$GIT_PULL_REQUEST_ID" ]]; then
	echo "ERROR: Missing --pull-request arg"
	print_usage
	exit 1
fi

if [[ -z "$GIT_AUTH" ]]; then
	echo "ERROR: Missing --git-auth arg"
	print_usage
	exit 1
fi

if [[ -z "$MVN" || ! -f "$MVN" ]]; then
	MVN=$(which mvn)
	if [[ ! -f "$MVN" ]]; then
		echo "ERROR: Maven not found: $MVN"
		exit 1
	fi
fi
echo "Maven found at $MVN"
"$MVN" --version

if [[ -z "$COPILOT" || ! -f "$COPILOT" ]]; then
	COPILOT=$(which copilot)
	if [[ ! -f "$COPILOT" ]]; then
		echo "ERROR: Copilot CLI not found: $COPILOT"
		exit 1
	fi
fi
echo "Copilot CLI found at $COPILOT"
"$COPILOT" --version

STATUS=ok
SUMMARY="# Analysis Summary"$'\n'

case "$GIT_TYPE" in
	BitBucket )		source ./scripts/bitbucket.sh	;;
	GitHub )		source ./scripts/github.sh		;;
	* )
		echo "ERROR: --git-type $GIT_TYPE not supported."
		print_usage
		exit 1
		;;
esac

start_review

# Setup an error trap to ensure cancel_review is called
error_handler() {
	local exit_code=$?
	local line_number=$LINENO
	echo "Error: Command failed with exit code $exit_code on line $line_number."
	cancel_review
	exit 1 # Exit the script with an error status
}
# Set the trap to call the error_handler function on any error
trap 'error_handler' ERR
# Enable immediate exit on error
set -e

# So that we can finish early if needed
function finish () {
	echo ""
	echo "========================================================"
	echo "=====[ Adding summary comment and updating status ]====="
	echo "========================================================"
	finish_review "$SUMMARY" "$STATUS"
	echo "$SUMMARY" >> "scripts/summary.md"

	echo ""
	echo "=====[ Done ]====="
}

GROUPID=$(xmllint --xpath "*[local-name()='project']/*[local-name()='groupId']/text()" pom.xml)
ARTIFACTID=$(xmllint --xpath "*[local-name()='project']/*[local-name()='artifactId']/text()" pom.xml)
PROJECT_NAME="$GROUPID:$ARTIFACTID"
#PROJECT_NAME=$(jq -e -r '.name' target/jtest/jtest.data.json)
echo "Found project name $PROJECT_NAME"

if [[ "$GOALS" == *"run-test"* ]]; then
	# Run impacted tests with Jtest
	# TODO: Make this a TIA run
	echo "============================="
	echo "=====[ Run Junit tests ]====="
	echo "============================="
	"$MVN" test surefire-report:report-only -P run-tia -Dmaven.test.failure.ignore=true -Dtia.settings="$TIA_SETTINGS"
	SUMMARY+="## Junit test execution"$'\n'
	if [[ -f "target/reports/surefire.html" ]]; then
		rm -rf scripts/test_failures.md
		rm -rf scripts/test_results.md
		"$COPILOT" -p "Examine the Surefire report at @target/reports/surefire.html. Create a simple markdown report containing only information from the 'Summary' and 'Failure Details' sections of the report. If there were any failures, write your report to scripts/test_failures.md; otherwise, write your report to scripts/test_results.md." --model claude-sonnet-4.5 --allow-all-tools --allow-all-paths --log-dir .copilot/logs/
		if [[ -f "scripts/test_failures.md" ]]; then
			echo "There are test failures. The pull-request will be marked as 'Needs Work'."
			COMMENT=$(cat scripts/test_failures.md)
			SUMMARY+="$COMMENT"$'\n'
			STATUS=needsWork
			finish
			exit 0
		else
			if [[ -f "scripts/test_results.md" ]]; then
				COMMENT=$(cat scripts/test_results.md)
				SUMMARY+="$COMMENT"$'\n'
			else
				echo "ERROR: No test summary found!"
				SUMMARY+="** No summary from Copilot CLI! **"$'\n'
			fi
		fi
	else
		echo "ERROR: No single surefire report was found at target/reports/surefire.html."
		echo "       Make sure you have maven-surefire-report-plugin added to your pom.xml"
		SUMMARY+="** No surefire report was found for executed tests! **$'\n'"
	fi
fi

if [[ "$GOALS" == *"static"* || "$GOALS" == *"static-fix"* ]]; then
	# Perform SA on modified files and generate report.xml
	echo "=========================================================="
	echo "=====[ Performing static analysis on modified files ]====="
	echo "=========================================================="
	SUMMARY+="## Static Analysis"$'\n'
	"$MVN" jtest:jtest -Dmaven.test.skip=true -Djtest.config="$SA_CONFIG" -Djtest.settings="$SA_SETTINGS"
	if [[ ! -f 'target/jtest/jtest.data.json' ]]; then
		echo "ERROR: SA failed"
		finish
		exit 1
	fi
	SUMMARY+="1. Jtest performed analysis on modified files using the \"$SA_CONFIG\" configuration"$'\n'

	# Configure environment variables and ask CoPilot CLI to fix violations using Jtest MCP server to get the violations, docs etc. For successful fixes, add a commit for each one.
	NUM_VIOLATIONS=$(cat target/jtest/report.xml | sed -n "s/.*Goals tsks=\"\([0-9]\+\)\".*/\1/p")
	if [[ -z "$NUM_VIOLATIONS" ]]; then
		NUM_VIOLATIONS=0
	fi
	echo "Jtest found $NUM_VIOLATIONS violations"
	SUMMARY+="2. Jtest found $NUM_VIOLATIONS violations"$'\n'
else
	NUM_VIOLATIONS=0
fi

if [[ "$NUM_VIOLATIONS" -ne 0 && "$GOALS" == *"static-fix"* ]]; then
    echo "==============================================================="
	echo "=====[ Ask Copilot CLI to fix violations and commit them ]====="
	echo "==============================================================="
	export BASELINE_REPORT=target/jtest/report.xml
	#export JTEST_HOME="C:/Program Files/Parasoft/jtest-2025.2.0"      # Should be set by the job, or on the workstation ENV
	export JTEST_SETTINGS="$SA_SETTINGS"
	export MVN_EXE="$MVN"
	
	rm -rf scripts/copilot_summary.md
	"$COPILOT" -p "Using @scripts/copilot-instructions.md, fix violations" --model claude-sonnet-4.5 --allow-all-tools --allow-all-paths --log-dir .copilot/logs/
	
	if [[ -f scripts/copilot_summary.md ]]; then
		SUMMARY+="3. Summary from Copilot CLI:"$'\n'
		SUMMARY+=$(cat scripts/copilot_summary.md)
		SUMMARY+=$'\n'
	else 
		SUMMARY+="3. ** No summary from Copilot CLI! **"$'\n'
	fi

	# If there's any local commits to add to the pull-request, push them now
	NEEDS_PUSH=$(git status | grep -c -e 'is ahead of ')
	if [[ -n "$NEEDS_PUSH" ]]; then
		echo "Pushing changes to update pull-request"
		echo "git push"
		SUMMARY+="4. Fixes added to pull-request"$'\n'
		STATUS=review
	else
		echo "No violation fixes to submit"
		SUMMARY+="4. No fixes to push"$'\n'
	fi
else
	if [[ "$GOALS" == *"static-fix"* ]]; then
		echo "No violations for Copilot to fix"
		SUMMARY+="3. No violations for Copilot to fix"$'\n'
		SUMMARY+="4. No fixes to push"$'\n'
	fi
fi

if [[ "$GOALS" == *"testgen"* ]]; then
	# Perform Jtest CLI bulk test creation for modified source files. Commit changes and push to add to pull-request.
	echo "========================================================="
	echo "=====[ Create Junit tests for modified or new code ]====="
	echo "========================================================="
	get_modified_resources
	"$MVN" jtest:jtest -Djtest.config="builtin://Create Unit Tests" -Djtest.settings="$TESTGEN_SETTINGS" -Djtest.resources="$RESOURCES"
	SUMMARY+="## Test creation for modified code"$'\n'

	MODIFIED=$(git diff --name-only HEAD -- "*.java")
	if [[ ! -z "$MODIFIED" ]]; then
		echo "Modified java code detected - adding to pull-request"
		git add "*.java"
		git commit -m "Parasoft Jtest: Adding Junit tests for modified code $PULL_REQUEST_ID"
		echo "git push"
		SUMMARY+="Tests were committed to this pull-request"$'\n'
		if [[ "$STATUS" == "ok" ]]; then
			STATUS=review
		fi
	else
		SUMMARY+="No tests were added"$'\n'
	fi
fi

finish