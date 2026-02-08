#!/bin/bash
# Test socket permissions feature

set -e

echo "Testing socket permissions functionality..."

# Set a known umask for predictable test results
OLD_UMASK=$(umask)
umask 002  # This should result in 775 permissions

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
    # Restore original umask
    umask "$OLD_UMASK"
}

trap cleanup EXIT

# Helper function to wait for socket creation
wait_for_socket() {
    local socket_path="$1"
    local timeout=5
    local elapsed=0
    
    while [ ! -S "$socket_path" ] && [ $elapsed -lt $timeout ]; do
        sleep 0.2
        elapsed=$((elapsed + 1))
    done
    
    if [ ! -S "$socket_path" ]; then
        echo "  ✗ Socket $socket_path was not created within ${timeout}s"
        exit 1
    fi
}

echo "1. Test default permissions (no -p flag, with umask 002)"
./keept -n -t -b -w -m "$TEST_DIR/default-socket" bash -c "sleep 5" &
wait_for_socket "$TEST_DIR/default-socket"
PERMS=$(stat -c "%a" "$TEST_DIR/default-socket" 2>/dev/null || echo "missing")
EXPECTED_PERMS="775"  # With umask 002, expect 775
if [ "$PERMS" = "$EXPECTED_PERMS" ]; then
    echo "  ✓ Default permissions test passed (permissions: $PERMS)"
else
    echo "  ✗ Default permissions test failed (expected $EXPECTED_PERMS, got: $PERMS)"
    exit 1
fi

echo "2. Test 777 permissions"
./keept -n -t -b -w -m -p 777 "$TEST_DIR/world-socket" bash -c "sleep 5" &
wait_for_socket "$TEST_DIR/world-socket"
PERMS=$(stat -c "%a" "$TEST_DIR/world-socket" 2>/dev/null || echo "missing")
if [ "$PERMS" = "777" ]; then
    echo "  ✓ 777 permissions test passed"
else
    echo "  ✗ 777 permissions test failed (expected 777, got: $PERMS)"
    exit 1
fi

echo "3. Test 770 permissions"
./keept -n -t -b -w -m -p 770 "$TEST_DIR/group-socket" bash -c "sleep 5" &
wait_for_socket "$TEST_DIR/group-socket"
PERMS=$(stat -c "%a" "$TEST_DIR/group-socket" 2>/dev/null || echo "missing")
if [ "$PERMS" = "770" ]; then
    echo "  ✓ 770 permissions test passed"
else
    echo "  ✗ 770 permissions test failed (expected 770, got: $PERMS)"
    exit 1
fi

echo "4. Test 755 permissions"
./keept -n -t -b -w -m -p 755 "$TEST_DIR/readonly-socket" bash -c "sleep 5" &
wait_for_socket "$TEST_DIR/readonly-socket"
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
# We created 4 sockets in tests 1-4 (default, 777, 770, 755)
SESSION_COUNT=$(./keept -L "$TEST_DIR" 2>&1 | grep -c "$TEST_DIR" || echo "0")
EXPECTED_SESSIONS=4
if [ "$SESSION_COUNT" -ge "$EXPECTED_SESSIONS" ]; then
    echo "  ✓ Session listing works with custom permissions"
else
    echo "  ✗ Session listing test failed (found $SESSION_COUNT sessions, expected at least $EXPECTED_SESSIONS)"
    exit 1
fi

echo ""
echo "All tests passed!"
