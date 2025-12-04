# Introduction

This is a clone of the Parabank Github project [here](https://github.com/parasoft/parabank), with a few important changes:

- The scripts directory has been added with files and scripts used to perform automated quality-gate analysis
- All branches except for master have been deleted

## Prerequisites

In order to perform the quality-gate analysis, you will need the following:

- Cygwin with standard tools, including:
    - curl
	- jq
- Maven 3.9+, JDK 17, and Git
- GitHub Copilot CLI and its prerequisites from [here](https://github.com/github/copilot-cli).
    - Node.js v22 or higher
    - npm v10 or higher
    - (On Windows) PowerShell v6 or higher
    - An active Copilot subscription. [See Copilot plans](https://github.com/features/copilot/plans?ref_cta=Copilot+plans+signup&ref_loc=install-copilot-cli&ref_page=docs).
- Jtest 2025.2+ with an active Parasoft license
- A Github account with access to the [Parasoft-AI](https://github.com/parasoft-AI) organization. This provides the "Copilot subscription" above and access to the model used by scripts.

## Installation

1. Install cygwin and include curl and jq.
2. Install [Maven 3.9+](https://maven.apache.org/download.cgi), Java 17, and git and include them on the path. Check that they are available in Cygwin.
3. Install node.js from [here](https://nodejs.org/en/download)
4. Launch cygwin and install Copilot CLI: `npm install -g @github/copilot`
5. Install Jtest 2025.2 and set the JTEST_HOME environment variable. Add the Jtest and TIA plugins to ~/.m2/.settings.xml according to the [instructions](https://docs.parasoft.com/display/JTEST20252/Configuring+the+Jtest+Plugin+for+Maven)
6. Configure copilot:
    1. In cygwin, run `copilot` and accept the current directory.
	2. Login with `/login`. Use github.com and follow instructions to finish login.
	3. Set the model: `/model claude-sonnet-4.5`
	4. Add the Jtest MCP server with `/mcp add`
	5. Configure the server with name='Jtest', type='Local', command='\<path_to_jtest\>/integration/mcp/jtestmcp.bat'.
	    - It is strongly recommended to avoid paths with spaces for the command.
	    - Environment variables are not needed and tools can be 'all' (default).
	6. Add the directory where this Parabank project will be checked out using git: `add-dir \<path\>`.
	7. Save and quit Copilot CLI

## Running analysis

This is intended to be done after a pull-request is created, to perform analysis on the files changed in the pull-request. Here's an example workflow:

1. Clone this project into a local directory.
2. Make a code change, commit it, and submit a pull-request
3. Build the jtestcli.properties file with the following settings:<br/>
    parasoft.eula.accepted=true<br/>
	license and/or DTP settings<br/>
	scope.scontrol=true<br/>
	scope.scontrol.files.filter.mode=branch<br/>
	scontrol.rep1.type=git<br/>
	scontrol.rep1.git.url=https://github.com/\<git_user\>/\<git_repo\>.git<br/>
	scontrol.rep1.git.workspace=\<path_to_git_repo\><br/>
	scontrol.git.exec=\<path_to_git_exe\><br/>
	scontrol.rep1.git.branch=\<pull_request_branch\>
4. Add the following properties to scripts/testgen.properties:<br/>
	parasoft.eula.accepted=true<br/>
	license and/or DTP settings<br/>
	LLM settings (optional)
5. Run scripts/run-copilot-fix.sh --pull-request \<id\> --git-auth \<auth_token\> \<goals\><br/>
	The pull-request ID is the number from github<br/>
	The auth_token should be a fine-grained Personal Access Token with permissions for pull-requests for the GitHub repository. See [Managing your Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens).<br/>
	The goals should be one or more of static, static-fix, run-test, and/or testgen. Each is a separate argument and represent the different parts of analysis. If not specified, all goals are run.

## Expected results

The run-copilot-fix.sh script should perform static analysis using the Jtest Maven plugin on all java files modified in the pull-request branch.
Copilot CLI should then be used to fix 2 violations per file and commit the fixes. These commits are pushed to the pull-request.
Impacted Junit tests are run using the Jtest Maven plugin, and the results are summarized by Copilot CLI.
Bulk creation is performed using the Jtest Maven plugin, and modified .java files are committed and pushed to the pull-request.
A report is generated with the outcome of all the above steps, including summaries from Copilot about its fixes for violations and the Junit execution results. The report is added as a comment to the pull-request. If Junit tests failed, the pull-request is marked as "Needs work".
Files should be generated in the scripts/ folder for debugging:

- .json files are the Github API responses for curl requests made during script execution
- copilot_summary.md is Copilot's summary of violation fixes performed and is added to the pull-request summary comment
- test_results.md or test_failures.md are Copilot's summary of Junit execution results which is added to the pull-request summary comment
- summary.md is the full comment added to the pull-request