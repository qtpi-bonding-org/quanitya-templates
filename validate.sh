#!/usr/bin/env bash
# Validates all template.json files in the templates/ directory.
# Requires: jq (https://jqlang.github.io/jq/)
#
# Usage: ./validate.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASS=0
FAIL=0
ERRORS=""

VALID_TYPES="integer float text boolean datetime enumerated dimension reference location group multiEnum"
VALID_UI="slider textField textArea stepper chips dropdown radio toggleSwitch checkbox datePicker timePicker datetimePicker searchField locationPicker timer"

validate_field() {
  local slug="$1" path="$2" field="$3"

  # Required keys
  for key in id label type isDeleted isList; do
    if ! echo "$field" | jq -e "has(\"$key\")" > /dev/null 2>&1; then
      ERRORS+="  [$slug] $path: missing required key \"$key\"\n"
      return 1
    fi
  done

  # Valid type
  local type
  type=$(echo "$field" | jq -r '.type')
  if ! echo "$VALID_TYPES" | grep -qw "$type"; then
    ERRORS+="  [$slug] $path: invalid type \"$type\"\n"
    return 1
  fi

  # Valid uiElement (if present)
  local ui
  ui=$(echo "$field" | jq -r '.uiElement // empty')
  if [[ -n "$ui" ]] && ! echo "$VALID_UI" | grep -qw "$ui"; then
    ERRORS+="  [$slug] $path: invalid uiElement \"$ui\"\n"
    return 1
  fi

  # Enumerated/multiEnum must have options
  if [[ "$type" == "enumerated" || "$type" == "multiEnum" ]]; then
    local optcount
    optcount=$(echo "$field" | jq '.options | length // 0')
    if [[ "$optcount" -lt 1 ]]; then
      ERRORS+="  [$slug] $path: $type requires non-empty options\n"
      return 1
    fi
  fi

  # Group must have subFields
  if [[ "$type" == "group" ]]; then
    local sfcount
    sfcount=$(echo "$field" | jq '.subFields | length // 0')
    if [[ "$sfcount" -lt 1 ]]; then
      ERRORS+="  [$slug] $path: group requires non-empty subFields\n"
      return 1
    fi
  fi

  # Dimension must have unit
  if [[ "$type" == "dimension" ]]; then
    local unit
    unit=$(echo "$field" | jq -r '.unit // empty')
    if [[ -z "$unit" ]]; then
      ERRORS+="  [$slug] $path: dimension requires unit\n"
      return 1
    fi
  fi

  return 0
}

for dir in templates/*/; do
  slug=$(basename "$dir")
  file="$dir/template.json"

  if [[ ! -f "$file" ]]; then
    echo -e "${RED}FAIL${NC}  $slug (missing template.json)"
    FAIL=$((FAIL + 1))
    continue
  fi

  # Valid JSON
  if ! jq empty "$file" 2>/dev/null; then
    echo -e "${RED}FAIL${NC}  $slug (invalid JSON)"
    FAIL=$((FAIL + 1))
    continue
  fi

  OK=true

  # Required top-level keys
  for key in version author template category; do
    if ! jq -e "has(\"$key\")" "$file" > /dev/null 2>&1; then
      ERRORS+="  [$slug] missing required key \"$key\"\n"
      OK=false
    fi
  done

  # Author must have name
  if ! jq -e '.author.name' "$file" > /dev/null 2>&1; then
    ERRORS+="  [$slug] author must have name\n"
    OK=false
  fi

  # Template must have id, name, fields
  for key in id name fields; do
    if ! jq -e ".template.${key}" "$file" > /dev/null 2>&1; then
      ERRORS+="  [$slug] template missing \"$key\"\n"
      OK=false
    fi
  done

  # Validate each field
  fieldcount=$(jq '.template.fields | length' "$file")
  for i in $(seq 0 $((fieldcount - 1))); do
    field=$(jq ".template.fields[$i]" "$file")
    if ! validate_field "$slug" "fields[$i]" "$field"; then
      OK=false
    fi

    # Validate group sub-fields
    ftype=$(echo "$field" | jq -r '.type')
    if [[ "$ftype" == "group" ]]; then
      sfcount=$(echo "$field" | jq '.subFields | length // 0')
      for j in $(seq 0 $((sfcount - 1))); do
        sf=$(echo "$field" | jq ".subFields[$j]")
        if ! validate_field "$slug" "fields[$i].subFields[$j]" "$sf"; then
          OK=false
        fi
      done
    fi
  done

  if $OK; then
    echo -e "${GREEN}PASS${NC}  $slug"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  $slug"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
if [[ -n "$ERRORS" ]]; then
  echo "Errors:"
  echo -e "$ERRORS"
fi
echo "Results: $PASS passed, $FAIL failed"

exit $FAIL
