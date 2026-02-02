# Shell Script Conventions in Liferay

This document defines the conventions for writing and formatting **Shell scripts** used in **Liferay** projects.

The goal is to keep code **simple, consistent, and readable**.

## Blank Lines and Functions

- Blank lines separate functions
- Lines inside the same block indicate that order does **not** matter
- Functions should be sorted when possible

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

## Comments

- Avoid comments whenever possible
- If required, add blank lines **before and after**

Example:

    #
    # Workaround
    #

    workaround code

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

## Flags

Always use **long flag forms**:

**Correct:**

    --delimiter

**Incorrect:**

    -d

## Function Structure

- Private functions must be at the **end of the file**
- Private functions start with `_`
- Files with only one function must **NOT** define `main`

Example:

    function promote_boms {
      ...
    }

    function _download_bom_file {
      ...
    }

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

## Line Sorting (Case Sensitive)

Regardless of the editor, the sorting must follow Lexicographical ASCII order. This ensures consistent behavior across CLI tools and IDEs:

1. Precedence: 0-9 > A-Z (Uppercase) > a-z (Lowercase).
2. Validation: A word starting with Z must always come before a word starting with a.

**Manual sorting:**

1. Highlight the target text block.
2. Invoke the Case Sensitive sorting function.
3. Verify that all words starting with A-Z are grouped above words starting with a-z.

## Optional keybinding

Add to `keybindings.json`:

    {
      "key": "ctrl+f9",
      "command": "editor.action.sortLinesAscending",
      "when": "editorTextFocus"
    }

## Parameter Substitution

Prefer portable approaches.

**Avoid:**

    ${1##*/}

**Prefer:**

    file_name=$(basename "$1")

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
- All variables are quoted and braces

## Subshell Wrapping ($())

Line breaks inside `$()` are allowed **only when the command is long**.

**Correct**
    local http_code=$( \
      curl -o /dev/null -s -w "%{http_code}" "$url"
    )

**Precedence Exception (Quotes):**
Do NOT wrap command substitutions in double quotes when used in simple assignments or `local` declarations, unless word splitting is explicitly intended or required for portability.

- **Correct:** `local date=$(date +%Y-%m-%d)`
- **Incorrect:** `local date="$(date +%Y-%m-%d)"`

## Tabulation Formatting

### Core Rule: Hard Tabs for Structural Indentation
All **code indentation** (structural spacing at the beginning of the line) must be performed using **Hard Tabs** (`\t`) instead of spaces.

1.  **Nesting Consistency:** Indentation must strictly reflect the logical nesting level of the code. Each new block (`if`, `while`, `for`, or function body) must increase the indentation by exactly **one tab** relative to its parent block.
2.  **No Arbitrary Offsets:** Do **NOT** add extra tabs or spaces for visual alignment or "padding". All lines within the same scope must start at the exact same indentation column.
3.  **Content Preservation (Strings):** Do **NOT** modify or tabulate spacing inside string literals (content between double quotes). Spacing inside quotes is considered functional content, not structural indentation.

- **Correct:** `write "    CustomLog ..."` (Spaces inside the string are preserved).

- **Incorrect:** `write "\tCustomLog ..."` (Internal spaces converted to tabs).

### Known Exception: Heredoc Indentation
An exception is granted for **Bash Heredocs** specifically when using the `<<-` operator.

* **Mechanism:** The shell strips leading **tabs** from each line in the heredoc block.
* **Internal Spacing:** You may use spaces for internal formatting (like JSON or XML structures) within the heredoc to ensure payload validity, as long as the leading structural indentation uses tabs.

**Example of Correct Indentation:**

```bash
function _check_logic {
	if [ "${_TEST_RESULT}" == "true" ]
	then
		while IFS= read -r line
		do
			# Exactly one tab more than 'do'
			echo "Actual: ${line}" >> "${error_file}"
		done < "${temp_file}"
	fi
}
```

## Variables

Always **double quote variables** and use **braces** for direct variable references:

- **Correct:** `"${file_name}"`
- **Correct:** `lc_log INFO "${scan_output}"`

### Exceptions and Special Cases:

1.  **Direct Assignments:** Quotes are omitted in direct assignments or `local` declarations from command substitutions `$(...)`.
    - **Correct:** `local date=$(date +%Y-%m-%d)`
    - **Incorrect:** `local date="$(date +%Y-%m-%d)"`

2.  **Function Arguments:** Do NOT wrap a command substitution `$(...)` in double quotes when it is being passed as an argument to a function.
    - **Correct:** `is_quarterly_release $(echo "${1}" | cut --delimiter=':' --fields=2)`
    - **Incorrect:** `is_quarterly_release "$(echo "${1}" | cut --delimiter=':' --fields=2)"`
