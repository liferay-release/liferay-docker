# Shell Script Conventions in Liferay

This document defines the conventions for writing and formatting **Shell scripts** used in **Liferay** projects.

The goal is to keep code **simple, consistent, and readable**.

---

## Line Sorting (Case Sensitive)

### VS Code

**Manual sorting:**

1. Select the lines  
2. Press `Ctrl + Shift + P` (or `F1`)  
3. Type **Sort Lines Ascending**  
4. Choose **Sort Lines (Case Sensitive)**

### Optional keybinding

Add to `keybindings.json`:

    {
      "key": "ctrl+f9",
      "command": "editor.action.sortLinesAscending",
      "when": "editorTextFocus"
    }

---

## Blank Lines and Logical Blocks

- Blank lines separate logical blocks  
- Lines inside the same block indicate that order does **not** matter  
- Blocks should be sorted when possible  

### Private functions

- must be at the **end of the file**
- must start with `_`

**Incorrect**

    test_bom_copy_tld
    tear_down
    lc_time_run generate_pom_release_api

**Correct**

    lc_time_run generate_pom_release_api
    lc_time_run generate_pom_release_bom
    lc_time_run generate_pom_release_bom_compile_only
    lc_time_run generate_pom_release_bom_third_party
    lc_time_run generate_pom_release_distro

---

## Function Structure

- Private functions start with `_`
- Files with only one function must **NOT** define `main`

Example:

    function promote_boms {
      ...
    }

    function _download_bom_file {
      ...
    }

---

## Flags

Always use **long flag forms**:

**Correct:**

    --delimiter

**Incorrect:**

    -d

---

## Control Structures

### if / then / elif / fi

    if [ -n "${nexus_repository_name}" ]
    then
      _download_bom_file
    fi

### for / do / done

    for portal_jar in portal-kernel support-tomcat
    do
      _manage_bom_jar "${_BUNDLES_DIR}/tomcat/lib/ext/${portal_jar}.jar"
    done

---

## Pipes and Redirections

Pipes and redirections such as:

- `|`
- `&> /dev/null`
- `2> /dev/null`
- `1> /dev/null`

**Must stay on the same line as the command**, unless the line exceeds 80 columns.

**Correct (within 80 columns)**

    elif (unzip -l "${file_path}" | grep "\.zip$" &> /dev/null)

**Incorrect (unnecessary wrapping)**

    elif (unzip -l "${file_path}" | \
        grep "\.zip$" &> /dev/null)

The same applies for `.lpkg`, `.zip`, or similar cases.

---

## Internal Filters (jq, pipelines, etc.)

For pipelines such as:

- jq
- grep
- awk
- sed
- pipelines inside parentheses

Do NOT wrap these lines if they remain within 80 columns.

Exception: `jq` filters can be wrapped for better readability, even if the line is less than 80 columns.

**Correct**

    | max_by([(.value.version | test("Q")), (.value.version | split(", ") | max)]) | .key?

**Incorrect (only formatting reasons)**

    | max_by([
      (.value.version | test("Q")),
      (.value.version \
        | split(", ") \
        | max)
    ]) | .key?

---

## Subshell Wrapping ($())

Line breaks inside `$()` are allowed **only when the command is long**.

**Correct**

    local http_code=$( \
      curl -o /dev/null -s -w "%{http_code}" "$url"
    )

**Incorrect**

    local http_code=$(\
    curl -o /dev/null -s -w "%{http_code}" "$url"
    )

---

## Output Redirection

Redirections should stay on the same line as the command.

Only wrap if exceeding 80 columns.

**Correct**

    docker rmi --force "liferay/jdk21:latest" &> /dev/null

---

## Variables

Always **quote variables**:

    "${file_name}"
    lc_log INFO "${scan_output}"

---

## Boolean Functions

Avoid unnecessary parentheses:

**Correct**

    if is_abc
    then
      ...
    fi

Use parentheses only in compound expressions:

**Correct**

    if (is_abc && is_xyz)
    then
      ...
    fi

---

## Comments

- Avoid comments whenever possible
- If required, add blank lines **before and after**

Example:

    #
    # Workaround
    #

    workaround code

---

## Parameter Substitution

Prefer portable approaches.

**Avoid:**

    ${1##*/}

**Prefer:**

    file_name=$(basename "$1")

---

## Full Correct Example

    #!/bin/bash

    docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" | \
      grep --extended-regexp ":.*(-slim).*" | \
      awk '{print $2}' | \
      xargs --no-run-if-empty docker rmi --force &> /dev/null

    docker rmi --force "liferay/jdk21:latest" &> /dev/null

    for file in $(find . -name "logs-20*" -type d)
    do
      rm --force --recursive "${file}"
    done

---

## Review Checklist

Before submitting code, verify:

- No line exceeds **80 characters**
- No unnecessary wrapping
- Pipes remain on the same line when possible
- Redirections remain on the same line when possible
- `elif (...)` remains on a single line (if ≤ 80 cols)
- jq filters are NOT broken unnecessarily
- Private functions start with `_`
- Boolean functions do NOT use parentheses unless needed
- All variables are quoted

---

## References

- https://github.com/davisaints/liferay-docker/commit/08d287b84c8f52d243029c930b4c37dea7b4e635
- https://github.com/liferay/liferay-docker/commit/dd24143f1901f3cb3bd86ac143c0bc752c8f28cd
- https://github.com/brianchandotcom/liferay-docker/pull/1043
