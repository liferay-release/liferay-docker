# Bash code style

This document is the source of truth for the style of every Bash file in the
`liferay-docker` repository. It defines how files are structured, named,
formatted, and documented so that all scripts read consistently regardless of
author.

It applies to every `*.sh` file in the repository, including executables,
internal (`_`-prefixed) helpers, and test files. When the rules here and the
existing code disagree, this document wins and the code should be updated to
match. To apply these rules, run the [`format-bash-code`](skills/format-bash-code/SKILL.md)
Claude skill: invoke `/format-bash-code` with no arguments to format the `*.sh`
files you have modified locally, or pass file or folder paths to format those
targets instead.

## Table of contents

- [Main structures](#main-structures)
	- [Files](#files)
	- [Functions](#functions)
	- [Test file](#test-file)
	- [Variables](#variables)
- [Sorting](#sorting)
	- [`source`](#source)
	- [`function`](#function)
- [Command flags](#command-flags)
- [Comments](#comments)
- [Control flow](#control-flow)
- [Indentation and spacing](#indentation-and-spacing)
- [Pipelines](#pipelines)
- [Return codes](#return-codes)
- [Shared helpers](#shared-helpers)
	- [Logging](#logging)

## Main structures

### Files

Files intended to be used only by other files (i.e. for internal use) should be
named starting with `_`, like `_file.sh`. Files meant to be executed by end
users do not need the leading `_` and should be named like `file.sh`.

Additionally, every file must follow the same top-to-bottom layout:

- Shebang `#!/bin/bash` for Linux environments or `#!/usr/bin/env bash` for
multi-platform environments, followed by a blank line.
- `source` statements for dependencies, followed by a blank line.
- Function definitions.
- A single `main` invocation as the last line. `main "${@}"` should be used if
parameters will be sent to the file.
- Files meant to be both executed and sourced guard their `main` body so it
only runs when the file is executed directly.
- Do not add a blank line as the last line.

```bash
#!/bin/bash

source _file_a.sh
source file_b.sh

function function_1 {
	...
}

function function_2 {
	...
}

function main {
	if [[ "${BASH_SOURCE[0]}" != "${0}" ]]
	then
		return
	fi

	function_1
	function_2
}

main
```

### Functions

- Declare functions with the keyword `function` followed by the name only,
without `()`.
- Wrap the function body in `{}`.
- Name functions in `snake_case`.
- Use verb-prefixed names that describe the action:
	- `get_*` for functions that echo a value.
	- `is_*` for boolean predicates.
	- `set_*`, `add_*`, `update_*`, `clean_*`, `build_*`, etc.
- Name local functions with a leading `_`, like `_function_local`.
- Name global functions, which are invoked by other files, without the leading
`_`, like `function_global`.

```bash
function function_global {
	...
}

function _function_local {
	...
}
```

### Test file

Test files follow the same structure as the Files and Functions sections, with
a few additions:

- Add `source _test_common.sh` to import the test utils `assert_equals`,
`common_set_up` and `common_tear_down`.
- Add a `source` for the file being tested.
- Declare functions `set_up` and `tear_down` to create and destroy the test
dependencies, respectively.
- Prefix test files and test functions with `test_`: for a file named
`file_a.sh`, create `test_file_a.sh` and name its test functions
`test_file_a_function_1`, `test_file_a_function_2`, etc.

```bash
#!/bin/bash

source _test_common.sh
source file_a.sh

function main {
	test_file_a_function_1
	test_file_a_function_2
}

function set_up {
	common_set_up

	...
}

function tear_down {
	common_tear_down

	...
}

function test_file_a_function_1 {
	_test_file_a_function_1 "0" "true"
	_test_file_a_function_1 "1" "false"
}

function test_file_a_function_2 {
	...
}

function _test_file_a_function_1 {
	assert_equals "$(function_1 "${1}")" "${2}"
}

main
```

### Variables

- Name environment and global variables in upper snake case (e.g.
`ENVIRONMENT_VARIABLE`).
- Declare local variables with `local` and name them in lower snake case (e.g.
`local_variable`); if a local variable is shared across local functions, name it
in upper snake case with a leading underscore (e.g. `_LOCAL_SHARED_VARIABLE`).
- Declare each local variable close to its first use rather than batching all
declarations at the top of the function. For local variables that share the same
first-use location, declare them together and apply [Sorting](#sorting).
- Do not put spaces around `=` in assignments.
- Always wrap variable references in braces and quote them: `"${variable}"`. This
applies to positional and special parameters too: `"${1}"`, `"${@}"`, `"${#}"`,
`"${?}"`.

```bash
function function_1 {
	echo "User ${_USER_ID} running function_1"

	local local_variable_1="${1}"

	echo "${local_variable_1}"
}

function function_2 {
	echo "User ${_USER_ID} running function_2"

	local local_variable_2="${1}"

	echo "${local_variable_2}"
}

function main {
	_USER_ID=$((RANDOM % 10))

	function_1
	function_2
}

main
```

- When a variable reference is adjacent to literal text, quote the entire
parameter, not just the variable.

```bash
echo "${variable} text"
```

- Avoid Bash-specific parameter expansions like `${1##*/}`; prefer legible
alternatives like `basename`.

```bash
file_name=$(basename "${1}")
```

- Use `$(( ... ))` for arithmetic.

```bash
local fixed_issues_array_part_length=$((fixed_issues_array_length / 4))
```

- Use `$( ... )` for command substitution, never backticks (`` ` ` ``).
- Do not quote a command substitution when assigning it to a variable.

```bash
local architecture=$(dpkg --print-architecture)
```

## Sorting

Sort alphabetically, case-sensitive. You can do this by selecting the lines to
sort and using the instructions below:

- Sublime
	- Click on `Edit` > `Sort Lines (Case Sensitive)`
	- Shortcut: `Ctrl + F9`
- VSCode:
	- Shortcut: `F1` and choose `Sort Lines Ascending`

For specific rules of each structure, see next sections.

### `source`

List parent-directory sources (`../`) before current-directory sources (`./`).

```bash
source ../_file_a.sh
source ../file_b.sh
source ./_file_c.sh
source ./file_d.sh
```

### `function`

Declare functions with global scope before functions with local scope.

```bash
function function_global_a {
	...
}

function function_global_c {
	...
}

function _function_local_b {
	...
}

function _function_local_d {
	...
}
```

## Command flags

Always prefer the long form of command-line flags for readability.

```bash
mkdir --parents release-data
git commit --message "${2}"
rm --force --recursive "${directory}"
cp --archive "${source}" "${destination}"
grep --invert-match LRCI
grep --extended-regexp --quiet "^[0-9a-f]{40}$"
sed --expression "s/^\([A-Z][A-Z0-9]*-[0-9]*\).*/\\1/"
head --lines=1
```

Short forms are only acceptable where no long form exists (e.g.
`git clean -dfx`).

## Comments

Comments are rare; prefer self-explanatory names. When a comment is needed, use
a `#`-delimited block with blank comment lines above and below the text.

```bash
#
# Your comment here
#
```

## Control flow

- Put `then` and `do` on their own line, never inline with `; then` / `; do`.

```bash
if [ -z "${LIFERAY_RELEASE_GIT_REF}" ]
then
	...
elif [ -n "${LIFERAY_RELEASE_GIT_SHA}" ]
then
	...
fi

for counter in {0..3}
do
	...
done
```

- Prefer single-bracket `[ ... ]` tests. Reserve `[[ ... ]]` for cases that need
  its features: pattern matching, regular-expression matching (`=~`),
  `${BASH_SOURCE[0]}` comparisons, and numeric comparisons (`-eq`, `-ne`, `-lt`,
  `-le`, `-gt`, `-ge`). Numeric comparisons stay in `[[ ... ]]` because its
  arithmetic context tolerates empty or non-integer operands, whereas `[ ... ]`
  fails with "integer expression expected".
- Use `==` for string equality and the numeric operators above for numeric
  comparison.
- For multi-line conditions, break after the logical operator (`||` / `&&`) and
  align continuation lines so the test lines up under the first one (one tab
  plus three spaces, matching the width of `if `).

```bash
if [ "$(get_release_output)" == "hotfix" ] ||
   [ "$(get_release_output)" == "nightly" ] ||
   [ "${BUILD_CAUSE}" != "TIMERTRIGGER" ]
then
	return "${LIFERAY_COMMON_EXIT_CODE_SKIPPED}"
fi
```

- Do not wrap a single boolean function or variable in parentheses. Parentheses
  are only needed for combined conditions.

```bash
if is_abc
then
	...
fi

if (is_abc && is_xyz)
then
	...
fi
```

## Indentation and spacing

- Indent with **tabs**, never spaces.
- Separate logical statements within a function with a single blank line.
- Do not put a blank line immediately after the opening `{` of a function or
immediately before the closing `}`.

```bash
function function_name {
	mkdir --parents my_folder

	cd my_folder
}
```

## Pipelines

- Break long pipelines across lines, ending each line with `| \` and indenting
the continuation by one tab.

```bash
git log "tags/${ga_version}..HEAD" --pretty="%s %H" | \
	sed --expression "/c394bcbc1c36af47e66678c470d623568d3f1e88/c\LPD-27038/" | \
	grep --extended-regexp "^[A-Z][A-Z0-9]*-[0-9]+" | \
	sort | \
	uniq | \
	paste --delimiters=',' --serial > "${_BUILD_DIR}/release/release-notes.txt"
```

- Break multi-flag commands (e.g. `curl`) one argument per line, sorted
alphabetically, with the continuation indented:

```bash
curl \
	"${file_url}" \
	--fail \
	--head \
	--max-time 300 \
	--retry 3 \
	--silent \
	--user "${LIFERAY_RELEASE_NEXUS_REPOSITORY_USER}:${LIFERAY_RELEASE_NEXUS_REPOSITORY_PASSWORD}"
```

- Break long pipelines inside `$( ... )` as well, adding a space after `$(` for
readability:

```bash
local http_response=$( \
	curl \
		"https://api.github.com/repos/liferay/${repository_name}/contents/${file_path}?ref=${ref}" \
		--header "Accept: application/vnd.github.v3.raw" \
		--header "Authorization: token ${LIFERAY_RELEASE_GITHUB_PAT}" \
		--include \
		--max-time 10 \
		--output "${file_name}" \
		--request GET \
		--retry 3 \
		--write-out "%{http_code}")
```

## Return codes

Use the named `LIFERAY_COMMON_EXIT_CODE_*` constants instead of bare numbers,
and quote them on `return`.

```bash
return "${LIFERAY_COMMON_EXIT_CODE_SKIPPED}"
return "${LIFERAY_COMMON_EXIT_CODE_BAD}"
return "${LIFERAY_COMMON_EXIT_CODE_OK}"
```

But, in boolean functions only, prefer `0` and `1` in the `return` statement.

## Shared helpers

If `_liferay_common.sh` is available in the repository, `source` it and use the
`lc_*` helper functions instead of reimplementing common behavior:

- `lc_cd`: change directory.
- `lc_background_run` / `lc_wait`: run functions concurrently and join them.
- `lc_download`: download files.
- `lc_get_property`: read properties.
- `lc_log`: leveled logging.
- `lc_time_run`: run a function and report its elapsed time.

### Logging

Use the `lc_log` helper with a level rather than raw `echo` for diagnostics.
Reserve plain `echo` for user-facing output (help text, reproduction commands).

```bash
lc_log INFO "${LIFERAY_RELEASE_GIT_REF} was already built in ${_BUILD_DIR}."
lc_log ERROR "No tag found."
lc_log DEBUG "File is available at ${file_url}."
```