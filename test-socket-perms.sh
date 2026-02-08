#!/bin/bash
# Test socket permissions feature

set -e

echo "Testing socket permissions functionality..."

# Clean up test directory
TEST_DIR="/tmp/keept-test-perms-$$"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

# Cleanup function
cleanup() {
    # Kill any remaining keept processes
    for pid in $(pgrep -f "keept.*$TEST_DIR" 2>/dev/null); do
        kill "$pid" 2>/dev/null || true
    done
    # Wait a moment for cleanup
    sleep 1
    rm -rf "$TEST_DIR"
}

trap cleanup EXIT

echo "1. Test default permissions (no -p flag)"
./keept -n -t -b -w -m "$TEST_DIR/default-socket" bash -c "sleep 5" &
sleep 1
PERMS=$(stat -c "%a" "$TEST_DIR/default-socket" 2>/dev/null || echo "missing")
if [ "$PERMS" = "775" ] || [ "$PERMS" = "755" ]; then
    echo "  ✓ Default permissions test passed (permissions: $PERMS)"
else
    echo "  ✗ Default permissions test failed (expected 775 or 755, got: $PERMS)"
    exit 1
fi

echo "2. Test 777 permissions"
./keept -n -t -b -w -m -p 777 "$TEST_DIR/world-socket" bash -c "sleep 5" &
sleep 1
PERMS=$(stat -c "%a" "$TEST_DIR/world-socket" 2>/dev/null || echo "missing")
if [ "$PERMS" = "777" ]; then
    echo "  ✓ 777 permissions test passed"
else
    echo "  ✗ 777 permissions test failed (expected 777, got: $PERMS)"
    exit 1
fi

echo "3. Test 770 permissions"
./keept -n -t -b -w -m -p 770 "$TEST_DIR/group-socket" bash -c "sleep 5" &
sleep 1
PERMS=$(stat -c "%a" "$TEST_DIR/group-socket" 2>/dev/null || echo "missing")
if [ "$PERMS" = "770" ]; then
    echo "  ✓ 770 permissions test passed"
else
    echo "  ✗ 770 permissions test failed (expected 770, got: $PERMS)"
    exit 1
fi

echo "4. Test 755 permissions"
./keept -n -t -b -w -m -p 755 "$TEST_DIR/readonly-socket" bash -c "sleep 5" &
sleep 1
PERMS=$(stat -c "%a" "$TEST_DIR/readonly-socket" 2>/dev/null || echo "missing")
if [ "$PERMS" = "755" ]; then
    echo "  ✓ 755 permissions test passed"
else
    echo "  ✗ 755 permissions test failed (expected 755, got: $PERMS)"
    exit 1
fi

echo "5. Test invalid permissions (should fail)"
if ./keept -n -t -b -w -m -p 1000 "$TEST_DIR/invalid-socket" bash 2>&1 | grep -q "value too large"; then
    echo "  ✓ Invalid permissions correctly rejected"
else
    echo "  ✗ Invalid permissions test failed"
    exit 1
fi

echo "6. Test non-numeric permissions (should fail)"
if ./keept -n -t -b -w -m -p abc "$TEST_DIR/invalid-socket" bash 2>&1 | grep -q "trailing characters"; then
    echo "  ✓ Non-numeric permissions correctly rejected"
else
    echo "  ✗ Non-numeric permissions test failed"
    exit 1
fi

echo "7. Test that sessions can be listed in shared directory"
SESSION_COUNT=$(./keept -L "$TEST_DIR" 2>&1 | grep -c "$TEST_DIR" || echo "0")
if [ "$SESSION_COUNT" -ge "4" ]; then
    echo "  ✓ Session listing works with custom permissions"
else
    echo "  ✗ Session listing test failed (found $SESSION_COUNT sessions, expected at least 4)"
    exit 1
fi

echo ""
echo "All tests passed!"
