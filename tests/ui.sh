#!/bin/sh
# inspector's UI tests: drives the example app (examples/main.tsl) without
# a window, with scripts of clicks and typing, and checks what the panels
# show afterwards. Run from anywhere: sh tests/ui.sh
#
# Author: Alexius Academia
# Date: 2026-10-25

cd "$(dirname "$0")/.." || exit 1
TESSEL="${TESSEL:-tessel}"
failed=0
passed=0

# check NAME SCRIPT EXPECTED... : every EXPECTED line must be in the output.
check() {
    name="$1"
    script="$2"
    shift 2
    out=$(TESSEL_SCRIPT="$script" "$TESSEL" run examples 2>&1)
    for want in "$@"; do
        if printf '%s\n' "$out" | grep -qF -- "$want"; then
            :
        else
            echo "FAIL  $name: no \"$want\""
            failed=$((failed + 1))
            return
        fi
    done
    echo "ok    $name"
    passed=$((passed + 1))
}

# refute NAME SCRIPT UNEXPECTED : the line must not be in the output (and
# the script must have run to its `tree`).
refute() {
    out=$(TESSEL_SCRIPT="$2" "$TESSEL" run examples 2>&1)
    if ! printf '%s\n' "$out" | grep -qF -- 'Text "Bound rows"' || printf '%s\n' "$out" | grep -q '^script:'; then
        echo "FAIL  $1: the script didn't run"
        failed=$((failed + 1))
    elif printf '%s\n' "$out" | grep -qF -- "$3"; then
        echo "FAIL  $1: \"$3\" is there"
        failed=$((failed + 1))
    else
        echo "ok    $1"
        passed=$((passed + 1))
    fi
}

nl='
'
check "starts with the values" "tree" \
    'TextField "" = "6000"' 'Text "0.1125 m²"' 'Text "Grade 60"' 'ColorPicker = #3478f6' 'Text "2 of 3"'
check "a unit is converted" "click field 3${nl}key cmd+a${nl}type 20 ft${nl}key enter${nl}tree" \
    'TextField "" = "6096"' 'Text "span = 6096.0 mm"'
check "a sum is worked out" "click field 3${nl}key cmd+a${nl}type 6 m + 250${nl}key enter${nl}tree" \
    'TextField "" = "6250"'
check "max holds" "click field 4${nl}key cmd+a${nl}type 5000${nl}key enter${nl}tree" \
    'TextField "" = "2000"' 'Text "depth = 2000.0 mm"'
check "min holds" "click field 4${nl}key cmd+a${nl}type 10${nl}key enter${nl}tree" \
    'TextField "" = "100"'
check "a mistake is shown" "click field 5${nl}key cmd+a${nl}type 2*${nl}key enter${nl}tree" \
    'Text "a number is missing at the end"' 'TextField "" = "2*"'
refute "a mistake changes nothing" "click field 5${nl}key cmd+a${nl}type 2*${nl}key enter${nl}tree" \
    'Text "width ='
check "typing without Enter is marked" "click field 6${nl}key cmd+a${nl}type 7${nl}tree" \
    'TextField "" = "7"' 'Icon undo'
check "the mark goes back" "click field 6${nl}key cmd+a${nl}type 7${nl}key escape${nl}click \"undo\"${nl}tree" \
    'TextField "" = "4"'
check "the area follows" "click field 4${nl}key cmd+a${nl}type 500${nl}key enter${nl}tree" \
    'Text "0.125 m²"'
check "plus steps" "click \"plus\"${nl}tree" 'TextField "" = "475"' 'Text "depth = 475.0 mm"'
check "minus steps" "click \"minus\"${nl}tree" 'TextField "" = "425"'
check "dragging the label" "drag 50 266 4 0${nl}tree" 'TextField "" = "350"'
check "an integer row rounds" "click field 6${nl}key cmd+a${nl}type 5.6${nl}key enter${nl}tree" \
    'TextField "" = "6"' 'Text "bars = 6"'
check "a choice opens and picks" "click \"Grade 60\"${nl}tree${nl}click \"Grade 75\"${nl}tree" \
    'Popover' 'Text "Grade 40"' 'Text "grade = Grade 75"'
check "a switch flips" "click \"On\"${nl}tree" 'Text "braced = false"'
check "a text row" "click field 2${nl}key cmd+a${nl}type B-14${nl}key enter${nl}tree" 'TextField "" = "B-14"'
check "a color" "click colorpicker 1${nl}click \"#000000\"${nl}tree" 'Text "color changed"' 'Text "#000000"'
check "search shows matching rows" "click field 1${nl}type dep${nl}tree" 'Text "Depth"'
refute "search hides the others" "click field 1${nl}type dep${nl}tree" 'Text "Span"'
check "search clears" "click field 1${nl}type dep${nl}click \"close\"${nl}tree" 'Text "Span"'
refute "a section closes" "click \"Beam\"${nl}tree" 'Text "Span"'
check "Inspector: mixed values" "tree" 'TextField "Mixed" = ""' 'Text "Mixed"'
check "Inspector: a choice for both" "click \"Mixed\"${nl}click \"Doors\"${nl}tree" \
    'Text "Doors"' 'Text "layer changed"'
check "Inspector: a number for both" "click field 8${nl}type 3 ft${nl}key enter${nl}tree" \
    'TextField "" = "0.914"' 'Text "x changed"'
check "Inspector: a button" "click \"Delete\"${nl}tree" 'Text "delete pressed"'
check "Inspector: one selected" "click \"Column\"${nl}tree" 'Text "1 of 3"' 'Text "Area"' 'TextField "" = "Table"'
check "Inspector: nothing selected" "click \"Column\"${nl}click \"Table\"${nl}tree" 'Text "Nothing selected"'
check "Inspector: search" "click field 7${nl}type rad${nl}tree" 'Text "Radius"' 'Text "Geometry"'
refute "Inspector: search hides groups" "click field 7${nl}type rad${nl}tree" 'Text "General"'
check "Inspector: search by group" "click field 7${nl}type geometry${nl}tree" 'Text "Center X"' 'Text "Radius"'
check "Inspector: no match" "click field 7${nl}type zzz${nl}tree" 'No property matches'
refute "Inspector: a group closes" "click \"Geometry\"${nl}tree" 'Text "Radius"'
check "dark appearance" "appearance dark${nl}tree" 'Text "Bound rows"'

echo
echo "$passed passed, $failed failed"
[ "$failed" -eq 0 ]
