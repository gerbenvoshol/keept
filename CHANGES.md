# Changes Summary: Regular Argument Parsing and Man Page

## Overview
This PR implements two main improvements to keept:
1. Standard getopt-based argument parsing (replacing custom FLAGS format)
2. Comprehensive manual page in groff format

## Changes Made

### 1. Argument Parsing Refactoring

**Old Syntax (removed):**
```bash
keept bw socket-name command      # bundled flags without dashes
```

**New Syntax:**
```bash
keept -b -w socket-name command   # standard POSIX options with dashes
```

**Implementation:**
- Replaced custom FLAGS parsing with standard `getopt()` 
- All single-letter options now use dash prefix
- Options can be combined: `-b -w` or `-bw`
- Added support for `--help` in addition to `-h`
- Maintains same functionality, just with standard syntax

**Modified Files:**
- `keept.c`: Complete rewrite of argument parsing in `main()`
  - Removed legacy FLAGS parsing loop
  - Implemented getopt-based parsing
  - Updated usage() function for new syntax

### 2. Manual Page Creation

**New File:** `keept.1` - Complete manual page in groff/troff format

**Sections Included:**
- NAME - Brief description
- SYNOPSIS - Usage syntax
- DESCRIPTION - Detailed description
- OPTIONS - All command-line options
- ARGUMENTS - Positional arguments
- ESCAPE CHARACTER - Ctrl-Z behavior
- ENVIRONMENT - Environment variables
- EXAMPLES - Usage examples
- SEE ALSO - Related commands
- BUGS - Known issues
- AUTHOR - Contact information
- LICENSE - License information

**Modified Files:**
- `keept.1`: New manual page file (removed from .gitignore)
- `.gitignore`: Removed keept.1 since it's now source-controlled
- `Makefile`: Updated to not require keept.1 generation

### 3. Documentation Updates

**Modified Files:**
- `README`: Complete rewrite to reflect new syntax
  - Updated SYNOPSIS section
  - Changed all examples to use new dash-prefix options
  - Reorganized OPTIONS section for clarity
  - Added information about flag combining
  
- `test-list-sessions.sh`: Updated all test commands
  - Changed `keept L .` to `keept -L .`
  - Changed `keept nt` to `keept -n -t`
  - All tests pass with new syntax

## Testing

All functionality has been tested:
- ✅ Help output (`--help` and `-h`)
- ✅ Session creation with various flag combinations
- ✅ Session listing (`-L` flag)
- ✅ All redraw modes (`-q`, `-b`, `-l`, `-w`)
- ✅ All action flags (`-a`, `-n`, `-m`, etc.)
- ✅ Options with arguments (`-s`, `-g`, `-o`)
- ✅ Man page rendering (`man ./keept.1`)
- ✅ Existing test suite passes

## Migration Notes

**For Users:**
- Old syntax will **not** work - must use new dash-prefix syntax
- Flag bundling changed: `bw` → `-b -w` or `-bw`
- Help is now `--help` or `-h` instead of `help`

**Benefits:**
- Standard POSIX-compliant argument parsing
- Better integration with shell completion
- More familiar syntax for Unix users
- Proper man page documentation

## Files Modified
- keept.c (argument parsing implementation)
- keept.1 (new manual page)
- README (documentation update)
- Makefile (build process update)
- .gitignore (remove keept.1)
- test-list-sessions.sh (test updates)

## Backward Compatibility
None - this is a breaking change. Old FLAGS syntax no longer works.
