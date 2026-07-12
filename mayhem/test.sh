#!/usr/bin/env bash
#
# RESSA/mayhem/test.sh — RUN rusty-ecma/RESSA's own test suite (`cargo test`) and emit a CTRF
# summary. exit 0 iff no test failed.
#
# PATCH-grade oracle: RESSA ships a real assertion suite —
#   - src unit tests (parser internals, comment handling, regex, lexical names, spanned parser);
#   - tests/snippets.rs: known-answer AST equality tests (parses JS snippets and asserts the exact
#     resulting AST structure);
#   - tests/comment_handler.rs: asserts the exact comments captured while parsing;
#   - tests/everything_js.rs: parses the everything.js corpus and asserts the full AST against
#     committed insta snapshots (golden output);
#   - tests/major_libs.rs: parses real-world libraries (jquery/angular/react/react-dom/vue/
#     moment/dexie, normal + minified, from node_modules baked into the image by the Dockerfile).
# These assert concrete values / golden snapshots, so a no-op / "exit(0)" patch CANNOT pass.
# This script only RUNS the suite; build.sh pre-compiled it with `cargo test --no-run`.
#
# Skipped upstream tests: tests/spider_monkey.rs (feature `moz_central`) — requires a multi-GB
# mozilla-central jit-test corpus downloaded from hg.mozilla.org at test time; upstream disables
# it by default (non-default cargo feature) and it cannot be run air-gapped.
set -uo pipefail
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH

: "${MAYHEM_JOBS:=$(nproc)}"
cd "$SRC"

# emit_ctrf <tool> <passed> <failed> [skipped] [pending] [other]
emit_ctrf() {
  local tool="$1" passed="$2" failed="$3" skipped="${4:-0}" pending="${5:-0}" other="${6:-0}"
  local tests=$(( passed + failed + skipped + pending + other ))
  cat > "${CTRF_REPORT:-$SRC/ctrf-report.json}" <<JSON
{
  "results": {
    "tool": { "name": "$tool" },
    "summary": {
      "tests": $tests,
      "passed": $passed,
      "failed": $failed,
      "pending": $pending,
      "skipped": $skipped,
      "other": $other
    }
  }
}
JSON
  printf 'CTRF {"results":{"tool":{"name":"%s"},"summary":{"tests":%d,"passed":%d,"failed":%d,"pending":%d,"skipped":%d,"other":%d}}}\n' \
    "$tool" "$tests" "$passed" "$failed" "$pending" "$skipped" "$other"
  [ "$failed" -eq 0 ]
}

if ! command -v cargo >/dev/null 2>&1; then
  echo "cargo not available — cannot run the test suite" >&2
  emit_ctrf "cargo-test" 0 1 0; exit 2
fi

if [ ! -d node_modules ]; then
  echo "node_modules missing — the Dockerfile's npm install step did not run; major_libs/everything_js need it" >&2
  emit_ctrf "cargo-test" 0 1 0; exit 2
fi

echo "=== running cargo test (RESSA unit + integration suite) ==="
# Use the image's DEFAULT toolchain (the Dockerfile pins it to the same nightly the fuzz build
# uses) — no `+toolchain` override. --no-fail-fast so we count every test; RUSTFLAGS cleared so it
# inherits nothing from the sanitizer build. RUST_MIN_STACK per upstream's .env (deep recursion in
# the parser needs a larger stack). CI=1/INSTA_UPDATE=no force insta to FAIL on snapshot mismatch
# instead of rewriting the golden files.
out="$(RUSTFLAGS="" RUST_MIN_STACK=9999999 CI=1 INSTA_UPDATE=no cargo test --no-fail-fast --jobs "$MAYHEM_JOBS" 2>&1)"; rc=$?
echo "$out"

# libtest prints one line per test binary:
#   test result: ok. 12 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; ...
# Sum across all binaries.
PASSED=0; FAILED=0; IGNORED=0
while read -r p f i; do
  PASSED=$(( PASSED + p )); FAILED=$(( FAILED + f )); IGNORED=$(( IGNORED + i ))
done < <(printf '%s\n' "$out" \
  | sed -n 's/^test result:.* \([0-9][0-9]*\) passed; \([0-9][0-9]*\) failed; \([0-9][0-9]*\) ignored.*/\1 \2 \3/p')

# If we parsed no result lines, fall back to the cargo exit code (e.g. compile error).
if [ "$(( PASSED + FAILED + IGNORED ))" -eq 0 ]; then
  echo "could not parse any 'test result:' lines; using cargo exit code $rc" >&2
  [ "$rc" -eq 0 ] && { emit_ctrf "cargo-test" 1 0 0; exit 0; }
  emit_ctrf "cargo-test" 0 1 0; exit 1
fi

emit_ctrf "cargo-test" "$PASSED" "$FAILED" "$IGNORED"
