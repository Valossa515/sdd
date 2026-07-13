#!/usr/bin/env bash
# validate-spec-test.sh — Regression tests for scripts/validate-spec.sh
#
# 1. The valid reference specs (specs/examples/) must PASS.
# 2. The invalid fixtures (tests/invalid-specs/) must FAIL, and every
#    expected defect must be individually reported — a validator that goes
#    blind to a rule breaks this test, not just one that crashes.
#
# Usage: bash tests/validate-spec-test.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALIDATOR="$ROOT/scripts/validate-spec.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

FAILURES=0
CHECKS=0

assert_contains() {
  local label="$1" haystack="$2" needle="$3"
  CHECKS=$((CHECKS + 1))
  if echo "$haystack" | grep -qF "$needle"; then
    echo -e "  ${GREEN}✔${RESET} $label"
  else
    echo -e "  ${RED}✘${RESET} $label — expected output to contain: $needle"
    FAILURES=$((FAILURES + 1))
  fi
}

echo ""
echo "1) Valid reference specs must pass"
echo "───────────────────────────────────────"
if bash "$VALIDATOR" "$ROOT/specs/examples" > /dev/null 2>&1; then
  echo -e "  ${GREEN}✔${RESET} specs/examples validates cleanly (exit 0)"
else
  echo -e "  ${RED}✘${RESET} specs/examples should validate cleanly but failed"
  FAILURES=$((FAILURES + 1))
fi
CHECKS=$((CHECKS + 1))

echo ""
echo "2) Invalid fixtures must fail, defect by defect"
echo "───────────────────────────────────────"
set +e
OUTPUT=$(bash "$VALIDATOR" "$ROOT/tests/invalid-specs" 2>&1)
STATUS=$?
set -e

CHECKS=$((CHECKS + 1))
if [ "$STATUS" -eq 1 ]; then
  echo -e "  ${GREEN}✔${RESET} invalid fixtures exit with status 1"
else
  echo -e "  ${RED}✘${RESET} expected exit 1 for invalid fixtures, got $STATUS"
  FAILURES=$((FAILURES + 1))
fi

# feature spec defects
assert_contains "feature: invalid id rejected"          "$OUTPUT" "missing or invalid 'feature.id'"
assert_contains "feature: missing summary rejected"     "$OUTPUT" "missing 'requirement.summary'"
assert_contains "feature: row-count mismatch rejected"  "$OUTPUT" "inputs declares [3] but has 2 row(s)"
assert_contains "feature: bad HTTP status rejected"     "$OUTPUT" "invalid HTTP status 'quatro'"
assert_contains "feature: duplicate BR id rejected"     "$OUTPUT" "duplicate business rule id 'BR-001'"

# acceptance defects
assert_contains "acceptance: dangling feature-ref"      "$OUTPUT" "feature-ref 'FT-999' does not match"
assert_contains "acceptance: duplicate AC id rejected"  "$OUTPUT" "duplicate criterion id 'AC-001'"
assert_contains "acceptance: invalid priority rejected" "$OUTPUT" "invalid priority 'urgent'"
assert_contains "acceptance: malformed BR ref rejected" "$OUTPUT" "invalid business-rule-ref 'BRX'"

# contract defects
assert_contains "contract: invalid action rejected"     "$OUTPUT" "invalid action 'delete'"
assert_contains "contract: duplicate path rejected"     "$OUTPUT" "appears in more than one layer"
assert_contains "contract: excluded without reason"     "$OUTPUT" "'Foo' has no reason"

# the valid fixture in the same directory must still pass
assert_contains "good fixture still accepted"           "$OUTPUT" "good.spec.toon"

echo ""
echo "───────────────────────────────────────"
echo "Checks: $CHECKS, failures: $FAILURES"
if [ "$FAILURES" -gt 0 ]; then
  echo -e "${RED}Validator regression detected.${RESET}"
  exit 1
fi
echo -e "${GREEN}All validator tests passed!${RESET}"
