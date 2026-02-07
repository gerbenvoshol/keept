#!/bin/bash
set -e

echo "Testing session listing functionality..."

# Clean up any existing test sessions
rm -rf /tmp/keept-test-sessions 2>/dev/null || true
mkdir -p /tmp/keept-test-sessions
cd /tmp/keept-test-sessions

KEEPT=/home/runner/work/keept/keept/keept

echo "1. Test empty directory"
output=$($KEEPT L . 2>&1)
if echo "$output" | grep -q "No active"; then
    echo "  ✓ Empty directory test passed"
else
    echo "  ✗ Empty directory test failed"
    echo "Output was: $output"
    exit 1
fi

echo "2. Test with one active session"
$KEEPT nt session1 sleep 60
sleep 1
output=$($KEEPT L . 2>&1)
if echo "$output" | grep -q "session1"; then
    echo "  ✓ Single session test passed"
else
    echo "  ✗ Single session test failed"
    echo "Output was: $output"
    exit 1
fi

echo "3. Test with multiple active sessions"
$KEEPT nt session2 sleep 60
$KEEPT nt session3 sleep 60
sleep 1
output=$($KEEPT L . 2>&1)
# Count lines starting with whitespace followed by a path (./session)
count=$(echo "$output" | grep "^\s*\./" | wc -l)
if [ "$count" -eq 3 ]; then
    echo "  ✓ Multiple sessions test passed (found $count sessions)"
else
    echo "  ✗ Multiple sessions test failed (expected 3, found $count)"
    echo "Output was: $output"
    exit 1
fi

echo "4. Test with absolute path"
output=$($KEEPT L /tmp/keept-test-sessions 2>&1)
if echo "$output" | grep -q "/tmp/keept-test-sessions/session"; then
    echo "  ✓ Absolute path test passed"
else
    echo "  ✗ Absolute path test failed"
    echo "Output was: $output"
    exit 1
fi

echo "5. Test that regular files are ignored"
touch not-a-socket
output=$($KEEPT L . 2>&1)
if ! echo "$output" | grep -q "not-a-socket"; then
    echo "  ✓ Regular file filtering test passed"
else
    echo "  ✗ Regular file filtering test failed"
    echo "Output was: $output"
    exit 1
fi

echo "6. Test with no directory argument"
output=$($KEEPT L 2>&1)
if echo "$output" | grep -q "session"; then
    echo "  ✓ Default directory test passed (uses current dir)"
else
    echo "  ✗ Default directory test failed"
    echo "Output was: $output"
    exit 1
fi

echo ""
echo "All tests passed!"

exit 0
