# Multi-User Session Access Feature

## Overview

This feature allows multiple users to join a keept session by setting appropriate socket permissions. By default, Unix domain sockets created by keept inherit the process's umask, which typically restricts access to the creating user. The new `-p` option allows you to specify custom permissions.

## Usage

### Basic Syntax

```bash
keept -p MODE [other options] socket-path command
```

Where `MODE` is an octal permission value (e.g., 777, 770, 755).

### Common Permission Modes

- **777** - World-readable, writable, and executable (any user can connect)
- **770** - Group-readable, writable, and executable (group members can connect)
- **755** - Owner and group can connect; others cannot (read-only for others)
- **750** - Owner and group can connect; others have no access

## Examples

### Create a Session Accessible to All Users

```bash
# Create a session in a shared directory with world-writable permissions
keept -b -w -m -p 777 /tmp/shared-session bash

# Another user on the same system can attach
keept -a /tmp/shared-session
```

### Create a Session Accessible to Group Members

```bash
# Create a session with group-writable permissions
keept -b -w -m -p 770 /var/keept-sessions/team-session zsh

# Team members in the same group can attach
keept -a /var/keept-sessions/team-session
```

### List All Accessible Sessions

```bash
# List all active keept sessions in a directory
keept -L /tmp

# List sessions in the current directory
keept -L .
```

## Security Considerations

1. **Use Shared Directories Carefully**: When creating world-writable sockets, place them in directories with appropriate permissions (e.g., `/tmp` or a dedicated shared directory).

2. **Group-Based Access**: For team collaboration, use permission mode 770 and ensure all users are in the same group.

3. **Avoid World-Writable in Production**: Mode 777 should be used cautiously. Consider using group-based permissions (770) for better security.

4. **Socket Location**: The socket file's directory must also be accessible to users who need to connect. Ensure directory permissions are appropriate.

## Best Practices

1. **Create a Dedicated Directory**: 
   ```bash
   mkdir -p /var/keept-shared
   chmod 1777 /var/keept-shared  # Sticky bit prevents users from deleting others' sockets
   ```

2. **Use Consistent Naming**:
   ```bash
   keept -p 777 /var/keept-shared/project-build bash
   keept -p 777 /var/keept-shared/project-deploy bash
   ```

3. **Document Shared Sessions**: Keep a list of active shared sessions for your team.

4. **Clean Up**: Remove old sockets when no longer needed (use `-u` flag for automatic cleanup).

## Limitations

- **Abstract Socket Namespace**: The `-p` option has no effect when using abstract socket namespace (`-@` flag on Linux), as abstract sockets don't have filesystem permissions.

- **Directory Permissions**: Users must have execute permission on all parent directories in the socket path.

- **Default Permissions**: Without `-p`, sockets are created with permissions determined by the process's umask. For example, with a typical umask of 022, sockets will have permissions of 755 (rwxr-xr-x).

## Troubleshooting

### "Permission denied" when connecting

**Problem**: Another user cannot connect to your session.

**Solution**: 
1. Check socket permissions: `ls -l /path/to/socket`
2. Ensure you used `-p 777` (or appropriate mode) when creating the session
3. Verify directory permissions allow access: `ls -ld /path/to`

### Socket not visible to other users

**Problem**: Other users cannot see the socket file.

**Solution**: Ensure the directory containing the socket has execute permissions for those users.

### "Socket exists but not live"

**Problem**: The socket file exists but keept cannot connect to it.

**Solution**: The original keept daemon may have crashed. Remove the stale socket file and create a new session.

## Testing

A comprehensive test suite is included in `test-socket-perms.sh`:

```bash
# Run the test suite
./test-socket-perms.sh
```

The test suite validates:
- Default permissions (no `-p` flag)
- Custom permissions (777, 770, 755)
- Invalid permission values
- Session listing with custom permissions

All tests should pass before considering the feature production-ready.
