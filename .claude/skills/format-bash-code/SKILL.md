---
name: format-bash-code
description: >-
  Format Bash (*.sh) files to match .claude/CODE_STYLE.md, the repository's
  source of truth for shell style. Use when the user asks to format, fix, or
  apply the code style to shell scripts. Runs in two modes — with no arguments
  it formats only the locally modified *.sh files; with file or folder paths as
  arguments it formats those targets instead.
---

# Format Bash code

Reformat Bash scripts so they comply with [.claude/CODE_STYLE.md](../../CODE_STYLE.md),
the authoritative style guide for every `*.sh` file in this repository.

## Step 1 — Load the style guide

Read `.claude/CODE_STYLE.md` in full before touching any file. It is the single
source of truth; every rule you apply must come from it. Do not invent rules or
rely on generic Bash conventions that the document does not state. If the
document and a file disagree, the document wins.

## Step 2 — Resolve the target files

There are two modes. Pick the mode from whether arguments were provided.

### Default mode (no arguments)

Format only the `*.sh` files that have been modified locally. Collect them with:

```bash
{
	git diff --name-only --diff-filter=ACMR
	git diff --name-only --cached --diff-filter=ACMR
	git ls-files --others --exclude-standard
} | sort --unique | grep '\.sh$'
```

This covers unstaged changes, staged changes, and new untracked scripts. If the
list is empty, report that there are no locally modified `*.sh` files and stop.

### Argument mode (paths provided)

When the skill is invoked with arguments, treat each argument as a file or a
folder:

- A path ending in `.sh` is formatted directly.
- A folder is expanded to every `*.sh` file under it:

  ```bash
  find "${path}" -type f -name '*.sh'
  ```

- Ignore arguments that resolve to no `*.sh` files, but report each one that was
  skipped so the user knows.

The arguments passed to this skill are: $ARGUMENTS

## Step 3 — Format each file

For every target file, read it and apply the rules from `.claude/CODE_STYLE.md`
using `Edit`. Make only style changes — never alter the script's behavior,
logic, or output. The checks to enforce include (this is a reminder, not a
replacement for reading the document):

- **File layout**: shebang, blank line, sorted `source` block, blank line,
  function definitions, single trailing `main` invocation; `_`-prefix for
  internal files.
- **Functions**: `function name` form (no `()`), `snake_case`, verb prefixes,
  `_`-prefix for local functions, globals declared before locals.
- **Variables**: `UPPER_SNAKE_CASE` for globals/env, `lower_snake_case` for
  locals (`_UPPER` when shared across local functions), `local` declarations,
  no spaces around `=`, always braced and quoted (`"${var}"`), the whole
  parameter quoted when adjacent to literal text (`"${var} text"`), locals
  declared close to first use rather than batched at the top, no Bash-specific
  parameter expansions (`${1##*/}`) — prefer legible alternatives like
  `basename`, `$((...))` arithmetic with no inner spaces, `$(...)` over
  backticks, command substitution left unquoted when assigned to a variable.
- **Sorting**: `source` lines, function order, and same-location local variable
  declarations sorted case-sensitively (`../` before `./`).
- **Command flags**: long form preferred; multi-flag commands broken one
  argument per line, sorted alphabetically.
- **Control flow**: `then` (including after `elif`) and `do` on their own line,
  single-bracket `[ ... ]` tests by default but `[[ ... ]]` for pattern/regex
  matching and numeric comparisons (`-eq`, `-ge`, etc.), `==` for strings,
  aligned multi-line conditions, no parentheses around a single boolean
  function or variable (parentheses only for combined conditions).
- **Indentation/spacing**: tabs only, single blank line between logical
  statements, no blank line just inside `{` / `}`.
- **Pipelines**: long pipelines and `curl`-style commands broken across lines
  with `| \` continuations indented one tab; a space after `$(` when a pipeline
  is broken inside a command substitution.
- **Return codes**: named `LIFERAY_COMMON_EXIT_CODE_*` constants, quoted.
- **Comments / logging / shared helpers**: `#`-delimited comment blocks, `lc_log`
  for diagnostics, `lc_*` helpers over reimplementation.

Skip `.claude/CODE_STYLE.md` itself and any non-`*.sh` file.

## Step 4 — Report

Summarize what happened: list each formatted file with a short note of the
changes made, and list any paths that were skipped and why. If a file was
already compliant, say so rather than editing it.
