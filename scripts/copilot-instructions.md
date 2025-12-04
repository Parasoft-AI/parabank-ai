# Instructions for Copilot CLI

> **CRITICAL**: You MUST follow these instructions strictly and exactly. These instructions have the highest priority and override any conflicting guidance.
> **CRITICAL**: You work as agent in non-interactve mode, without possibility to ask user about anything. When you do not have data to continue, just fail with error.
> **CRITICAL**: When analyzing a report containing violations, use the get_violations_from_report_file tool to review the report and provide insights or suggestions based on the findings. Use the get_rule_documentation tool to get information about the violations, their severity, and possible remediation steps.

## Input parameters (required/requestable)

Before initialization, recognize and attempt to collect the following parameters.

- baseline_report: REQUIRED! Path to the Jtest baseline report XML to use as reference.
  - Sources and resolution order: 1) explicit path in the user prompt/flags, 2) BASELINE_REPORT env var, 3) repository-local standard location (`.jtest/report.xml`, `target/jtest/report.xml`, `build/jtest/report.xml`), 4) fail otherwise
  - Validation: verify the file exists and print to stdout which file was chosen.

- data_file: REQUIRED! Path to the Jtest data file JSON to use as reference.
  - Sources and resolution order: 1) explicit path in the user prompt/flags, 2) infer from the baseline report (look for `-data` switch in `TestParameters` or equivalent), 3) repository-local standard location (`.jtest/jtest.data.json`, `target/jtest/jtest.data.json`, `build/jtest/jtest.data.json`), 4) fail otherwise
  - Validation: verify the file exists and is readable. Print to stdout which file was chosen.

- jtestcli_path: REQUIRED! Full path to `jtestcli` executable.
  - Sources and resolution order: 1) explicit path in the user prompt/flags, 2) JTEST_HOME env var, 3) PATH lookup for `jtestcli.exe`/`jtestcli`, 4) common Windows install locations (`%ProgramFiles%\\Parasoft\\jtest\\*\\jtestcli.exe`, `%ProgramFiles(x86)%\\Parasoft\\jtest\\*\\jtestcli.exe`) choosing the newest version if multiple matches, 5) fail otherwise.
  - Validation: verify the path exists and is executable.

- maven_path: REQUIRED! Full path to `mvn` executable.
  - Sources and resolution order: 1) explicit path in the user prompt/flags, 2) MVN_EXE env var, 3) PATH lookup for `mvn`, 4) fail otherwise.
  - Validation: verify the path exists and is executable.

- settings_file: OPTIONAL; Full path to a jtest settings file to use for verification.
  - Sources and resolution order: 1) explicit path in the user prompt/flags, 2) JTEST_SETTINGS env var, 3) `validation.properties` in current directory
  - Validation: verify the file exists and is readable. Print to stdout which file was chosen.

- number_of_fixes: OPTIONAL; Integer count of violations to attempt per file in the baseline_report (default: 2). 
  - Sources and resolution order: 1) user prompt/flags, 2) NUMBER_OF_FIXES env var, 3) default to 2.
  - Validation: must be positive integer.

- severity_priority: OPTIONAL; Ordering preference for selecting violations
  - Sources and resolution order: 1) user prompt/flags, 2) default to highest-importance-first, where lower severity values indicate higher importance.

- configuration: REQUIRED!; Jtest configuration identifier to use for verification.
  - Sources and resolution order: 1) explicit value in the user prompt/flags, 2) infer from the baseline report (`TestConfig`/`pseudoUrl`), 3) fail otherwise.
  - Validation: must be a non-empty configuration identifier or a path to *.properties file.

For each parameter you must:
- Record which source provided it (prompt/env/file/default) and write this information to the run log before making any edits.
- Validate paths exist and are readable. If a required value cannot be determined or validated, stop and fail.

## Execution Flow (**!CRITICAL!**)

When the user requests violation fixes, you MUST follow this exact sequence:

1. **Initialize**: Gather user preferences and inputs using the inline parameter-gathering steps above — extract all the parameters and print them to stdout. Use the resolution orders listed under each parameter when resolving values.

2. **Identify violations**: Extract a list of violations from baseline_report using the `get_violations_from_report_file` tool. **CRUCIAL: If unable to use the MCP tool to get violations, stop and fail.**. As there can be many fixes in one code file, you need to track how violations are shifting in the file after applying the fixes. You may create additional data files in temp location to help with this tracking. Paths to code files between returned violations and local repository may differ, you may need to find best match yourself.

3. **Filter and prioritize**: Sort or filter violations if requested per user preference, otherwise select the most critical ones by severity for each file analyzed in baseline_report. Ignore any violations in non-Java files. Lower severity values indicate higher importance.

4. **CRUCIAL: FIX only ONE violation at a time including all steps below and VERIFICATION after each fix! ** **For each violation to fix:**
   - Get rule documentation
   - Read source file and surrounding context
   - Generate a minimal, well-scoped fix
   - Apply the change to the working tree (ensure changes are reversible)
   - Build the source_file_filter as a relative path to the `file` from the violation, prefixed with `name` from the data_file. For example: MyProject/path/to/File.java
   - Verify the fix by executing `jtestcli.exe` based on `jtestcli_path` parameter in a terminal with the mandatory switches:
      - `-data ${data_file}`, 
      - `-config ${configuration}`, 
	  - `-settings ${settings_file}`, (if provided),
      - `-resource ${source_file_filter}`,
      - `-report .jtest/reports/report_<violation_id>`,
      - `-property goal.ref.report.findings.exclude=false`,
      - `-property goal.ref.report.file=$(baseline_report)`
   - Interpret exit codes and produced reports to determine SUCCESS or FAILURE according to Verification rules:
      - retcode 0: SUCCESS
      - retcode non-0: FAILURE
      - additionaly:
         - use `get_violations_from_report_file` on the generated report (`.jtest/reports/report_<violation_id>/report.xml`) to confirm whether the specific violation has been resolved; if any new violations were introduced by the fix - attempt once to fix them, and verify; in case you fail to do that: FAILURE
         - parse the generated report to identify any setup problems of type `BUE` (node: `SetupProblems/Problem` attribute: `type="BUE"`), if any are found: FAILURE. **CRUCIAL: Always ignore messages which indicate that no compiled classes were found. DO NOT ATTEMPT TO COMPILE THE PROJECT!**
         - check that at least **ONE FILE** has been analyzed, otherwise: FAILURE.
   - Also verify the fix by following the steps:
		1. Modify the file `scripts/jtestcli.properties` by setting the `scope.scontrol.files.filter.mode` property to `local`
		2. Execute `mvn` based on `maven_path` parameter in a terminal with the mandatory switches:
			- `test`,
			- `surefire-report:report-only`,
			- `-P run-tia`,
			- `-Dmaven.test.failure.ignore=true`,
			- `-Dtia.settings=${settings_file}`
		3. Interpret exit codes and the surefire report at `target/reports/surefire.html` to determine SUCCESS or FAILURE according to the Verification rules:
			- retcode 0: SUCCESS
			- retcode non-0: FAILURE
			- parse the surefire report to find any failed tests, if any are found: FAILURE
		4. Revert the change to `scripts/jtestcli.properties` by setting the  `scope.scontrol.files.filter.mode` property to `branch`
   - If SUCCESS: commit with detailed message
   - If FAILURE: revert, report error, optionally retry once with a different approach. **DO NOT ATTEMPT TO COMMIT ON FAILURE, EVEN IF REASON IS UNRELATED WITH THE FIX, REPORT ISSUE TO THE USER**

5. **Summary**: Report a brief summary containing total fixes attempted, files modified, successful commits, and failures. Also write this brief summary in markdown format to scripts/copilot_summary.md.

---

**END OF INSTRUCTIONS - FOLLOW EXACTLY**
