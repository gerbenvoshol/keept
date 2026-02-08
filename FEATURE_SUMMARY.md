# Session Listing Feature

## Overview
This PR adds the ability to list active keept sessions using the new 'L' flag.

## Usage

### Basic usage - list sessions in current directory:
```bash
keept L .
```

### List sessions in a specific directory:
```bash
keept L /path/to/sessions
```

### List sessions with default directory (current directory):
```bash
keept L
```

## Examples

### Create some sessions:
```bash
keept nt session1 bash
keept nt session2 zsh
keept nt session3 python
```

### List all active sessions:
```bash
$ keept L .
Active keept sessions:
  ./session1
  ./session2
  ./session3
```

### Empty directory:
```bash
$ keept L /tmp/empty
No active keept sessions found in '/tmp/empty'
```

## Implementation Details

- Scans the specified directory for socket files
- Tests connectivity to each socket to verify it's an active session
- Only displays live sessions (dead sockets are filtered out)
- Non-socket files are automatically ignored
- Uses PATH_MAX for buffer sizes (portable)
- Handles edge cases like missing arguments gracefully

## Testing

A comprehensive test suite is included in `test-list-sessions.sh` that validates:
1. Empty directory handling
2. Single session detection
3. Multiple session detection
4. Absolute path support
5. Regular file filtering
6. Default directory behavior

All tests pass successfully.
