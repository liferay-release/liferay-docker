#!/bin/bash

PID="$(cat "${LIFERAY_PID}")"

DUMP_ONE="$LIFERAY_HOME/dump_one.tdump"
DUMP_TWO="$LIFERAY_HOME/dump_two.tdump"
DUMP_THREE="$LIFERAY_HOME/dump_three.tdump"

jcmd "$PID" Thread.print > "$DUMP_ONE"
sleep 5
jcmd "$PID" Thread.print > "$DUMP_TWO"
sleep 5
jcmd "$PID" Thread.print > "$DUMP_THREE"

filter_threads() {
    local infile=$1
    awk '
    BEGIN { capture=0; stack="" }
    /^"/ {
        if ($0 ~ /catalina-exec-/ || $0 ~ /http-nio-8081-exec/) {
            capture=1
            sub(/#.*/, "", $0)
            stack = $0 "\n"
        } else {
            capture=0
        }
    }
    capture && !/^"/ { stack = stack $0 "\n" }
    capture && /^$/ { print stack; capture=0; stack="" }
    END { if (capture) print stack }
    ' "$infile"
}

parse_threads() {
    awk -v tmpdir="$LIFERAY_HOME" '
    BEGIN { RS=""; FS="\n" }
    {
        thread = $1
        if (thread ~ /catalina-exec-|http-nio-8081-exec/) {
            state=""
            stack=""
            stack_lines=0
            for (i=1; i<=NF; i++) {
                stack = stack $i "\n"
                if ($i ~ /java\.lang\.Thread\.State:/) {
                    if (match($i, /java\.lang\.Thread\.State:\s*([A-Z_]+)/, m)) {
                        state = m[1]
                    }
                }
                if ($i ~ /^\s*at /) stack_lines++
            }
            if (stack_lines <= 30) next

            tmpfile = sprintf("%s/.tmpstack_%d", tmpdir, NR)
            print stack > tmpfile
            close(tmpfile)

            cmd = "sha256sum \"" tmpfile "\""
            cmd | getline hashline
            close(cmd)
            split(hashline, parts, " ")
            hash = parts[1]
            system("rm -f \"" tmpfile "\"")

            if (match(thread, /"(catalina-exec-[^"]+|http-nio-8081-exec[^"]+)"/, m)) {
                tname = m[1]
                print tname, state, hash
            }
        }
    }'
}

FILTERED_ONE="$LIFERAY_HOME/filtered_one.txt"
FILTERED_TWO="$LIFERAY_HOME/filtered_two.txt"
FILTERED_THREE="$LIFERAY_HOME/filtered_three.txt"

filter_threads "$DUMP_ONE" | parse_threads > "$FILTERED_ONE"
filter_threads "$DUMP_TWO" | parse_threads > "$FILTERED_TWO"
filter_threads "$DUMP_THREE" | parse_threads > "$FILTERED_THREE"

for f in "$FILTERED_ONE" "$FILTERED_TWO" "$FILTERED_THREE"
do
    if [[ ! -s "$f" ]]
    then
        echo "Lifecycle monitor: Empty filtered threads ($f)"
        exit 0
    fi
done

compare() {
    local BASE=$1
    local OTHER=$2

    local total=0
    local match=0

    while read -r name state hash
    do
        ((total++))
        found=$(awk -v n="$name" -v s="$state" -v h="$hash" \
            '$1==n && $2==s && $3==h {print}' "$OTHER")
        [[ -n "$found" ]] && ((match++))
    done < "$BASE"

    if (( total == 0 ))
    then
        echo 0
    else
        echo $(( match * 100 / total ))
    fi
}

MATCH_BASE_TO_DUMP_TWO=$(compare "$FILTERED_ONE" "$FILTERED_TWO")
MATCH_BASE_TO_DUMP_THREE=$(compare "$FILTERED_ONE" "$FILTERED_THREE")

echo "Lifecycle monitor: Match dump_one & dump_two: ${MATCH_BASE_TO_DUMP_TWO}%"
echo "Lifecycle monitor: Match dump_one & dump_three: ${MATCH_BASE_TO_DUMP_THREE}%"

if (( MATCH_BASE_TO_DUMP_TWO == 100 && MATCH_BASE_TO_DUMP_THREE == 100 ))
then
    echo "Lifecycle monitor: All dumps match perfectly"
    exit 2
elif (( MATCH_BASE_TO_DUMP_TWO >= 90 && MATCH_BASE_TO_DUMP_THREE >= 90 ))
then
    echo "Lifecycle monitor: Baseline matches >=90% with both dumps"
    exit 2
elif (( MATCH_BASE_TO_DUMP_TWO >= 90 || MATCH_BASE_TO_DUMP_THREE >= 90 ))
then
    echo "Lifecycle monitor: Only one comparison met >=90% threshold"
    exit 1
else
    echo "Lifecycle monitor: Both comparisons below threshold"
    exit 0
fi