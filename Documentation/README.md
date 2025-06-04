# isOlderThan - File Age Verification Tool

A cross-platform command-line utility that checks if a file is older than a specified time period. Written in C99 for maximum compatibility across Unix, Linux, macOS, and Windows platforms.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Usage](#usage)
- [Documentation Setup](#documentation-setup)
- [Building from Source](#building-from-source)
- [Platform-Specific Notes](#platform-specific-notes)
- [Examples](#examples)
- [Contributing](#contributing)
- [License](#license)

## Overview

`isOlderThan` provides precise file age verification with support for multiple time units and accurate calendar arithmetic. Perfect for cleanup scripts, backup validation, and automated maintenance tasks.

**Key Capabilities:**
- ✅ Cross-platform compatibility (Unix/Linux/Mac/Windows)
- ✅ Accurate calendar arithmetic (leap years, variable month lengths)
- ✅ Flexible time specifications (days, weeks, months, years)
- ✅ Two reference time modes (exact vs. end-of-previous-day)
- ✅ Comprehensive error handling and exit codes
- ✅ Professional documentation (man pages, Windows help)

## Features

### Time Parameters
- **Days**: `isOlderThan file.txt -days 30`
- **Weeks**: `isOlderThan file.txt -weeks 4` 
- **Months**: `isOlderThan file.txt -months 6`
- **Years**: `isOlderThan file.txt -years 2`
- **Combined**: `isOlderThan file.txt -years 1 -months 6`
- **Default**: 6 months if no time specified

### Reference Time Modes
- **Default**: End of previous day (ideal for daily scripts)
- **Exact**: Current execution time (`-exact` flag)

### Parameter Rules
- `-days` and `-weeks` exclude all other time parameters
- `-months` can combine with `-years` (max 11 months when combined)
- All numeric values must be positive

## Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/isOlderThan.git
cd isOlderThan

# Build the program
make

# Check if a file is older than 6 months (default)
./isOlderThan /path/to/file

# Check if a file is older than 30 days
./isOlderThan /path/to/file -days 30

# Install system-wide (Unix/Linux/Mac)
sudo make install
```

## Installation

### Unix/Linux/macOS

```bash
# Method 1: Using Make (recommended)
make
sudo make install

# Method 2: Manual compilation
gcc -std=c99 -Wall -Wextra -O2 -o isOlderThan isOlderThan.c
sudo cp isOlderThan /usr/local/bin/
sudo cp isOlderThan.1 /usr/local/share/man/man1/
sudo mandb
```

### Windows

```cmd
# Using MinGW/MSYS2
make
make install-windows

# Using Visual Studio Developer Command Prompt
cl /std:c99 isOlderThan.c

# Manual installation
copy isOlderThan.exe "C:\Program Files\isOlderThan\"
copy isOlderThan.txt "C:\Program Files\isOlderThan\help.txt"
```

## Usage

### Basic Syntax
```
isOlderThan <filepath> [options]
```

### Exit Codes
- `0`: File is older than specified period ✅
- `1`: File is NOT older or invalid arguments ❌
- `2`: File not found 🚫
- `3`: File access error 🔒
- `4`: Invalid parameter combination ⚠️
- `5`: Invalid parameter value ❌

### Shell Script Integration

```bash
#!/bin/bash
# Cleanup script example

if isOlderThan "/tmp/cache.dat" -days 7; then
    rm "/tmp/cache.dat"
    echo "Removed old cache file"
fi

# Check multiple files
for file in /var/log/*.log; do
    if isOlderThan "$file" -months 3; then
        gzip "$file"
        echo "Compressed old log: $file"
    fi
done
```

## Documentation Setup

### Manual Pages (Unix/Linux/macOS)

The repository includes a complete manual page (`isOlderThan.1`) that follows standard Unix conventions.

#### Installation
```bash
# Automatic installation (with make install)
sudo make install

# Manual installation
sudo cp isOlderThan.1 /usr/local/share/man/man1/
sudo mandb  # Update man database
```

#### Verification
```bash
# View the manual page
man isOlderThan

# Search for the manual
man -k isOlderThan
apropos isOlderThan
```

#### Manual Page Locations by Platform
- **Linux**: `/usr/local/share/man/man1/` or `/usr/share/man/man1/`
- **macOS**: `/usr/local/share/man/man1/` or `/usr/share/man/man1/`
- **FreeBSD**: `/usr/local/man/man1/`

#### Creating Manual Page Packages

**For Debian/Ubuntu (.deb):**
```bash
# Create package structure
mkdir -p isolderthan-1.0/usr/local/bin
mkdir -p isolderthan-1.0/usr/local/share/man/man1
mkdir -p isolderthan-1.0/DEBIAN

# Copy files
cp isOlderThan isolderthan-1.0/usr/local/bin/
cp isOlderThan.1 isolderthan-1.0/usr/local/share/man/man1/

# Create control file
cat > isolderthan-1.0/DEBIAN/control << EOF
Package: isolderthan
Version: 1.0
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Your Name <your.email@example.com>
Description: File age verification tool
 Checks if files are older than specified time periods
EOF

# Build package
dpkg-deb --build isolderthan-1.0
```

**For Red Hat/CentOS (.rpm):**
```bash
# Create RPM spec file
cat > isolderthan.spec << EOF
Name: isolderthan
Version: 1.0
Release: 1
Summary: File age verification tool
License: MIT
Source: isolderthan-1.0.tar.gz

%description
Cross-platform tool for checking file ages

%install
mkdir -p %{buildroot}/usr/local/bin
mkdir -p %{buildroot}/usr/local/share/man/man1
cp isOlderThan %{buildroot}/usr/local/bin/
cp isOlderThan.1 %{buildroot}/usr/local/share/man/man1/

%files
/usr/local/bin/isOlderThan
/usr/local/share/man/man1/isOlderThan.1

%post
mandb > /dev/null 2>&1 || true
EOF

# Build RPM
rpmbuild -ba isolderthan.spec
```

### Windows Help File

The repository includes a comprehensive Windows help file (`isOlderThan.txt`) with detailed usage information.

#### Installation
```cmd
# Automatic (with make install-windows)
make install-windows

# Manual installation
mkdir "C:\Program Files\isOlderThan"
copy isOlderThan.exe "C:\Program Files\isOlderThan\"
copy isOlderThan.txt "C:\Program Files\isOlderThan\help.txt"

# Add to PATH
setx PATH "%PATH%;C:\Program Files\isOlderThan"
```

#### Creating Windows Documentation Package

**Using NSIS (Nullsoft Scriptable Install System):**
```nsis
; isOlderThan.nsi
Name "isOlderThan"
OutFile "isOlderThan-installer.exe"
InstallDir "$PROGRAMFILES\isOlderThan"

Section "MainSection" SEC01
    SetOutPath "$INSTDIR"
    File "isOlderThan.exe"
    File "isOlderThan.txt"
    
    ; Add to PATH
    ${EnvVarUpdate} $0 "PATH" "A" "HKLM" "$INSTDIR"
    
    ; Create Start Menu shortcuts
    CreateDirectory "$SMPROGRAMS\isOlderThan"
    CreateShortCut "$SMPROGRAMS\isOlderThan\Help.lnk" "$INSTDIR\isOlderThan.txt"
SectionEnd
```

**Using Windows MSI:**
```xml
<!-- isOlderThan.wxs -->
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="*" Name="isOlderThan" Language="1033" Version="1.0.0" 
           Manufacturer="YourCompany" UpgradeCode="PUT-GUID-HERE">
    <Package InstallerVersion="200" Compressed="yes" />
    
    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFilesFolder">
        <Directory Id="INSTALLFOLDER" Name="isOlderThan">
          <Component Id="MainExecutable" Guid="PUT-GUID-HERE">
            <File Id="isOlderThan.exe" Source="isOlderThan.exe" />
            <File Id="help.txt" Source="isOlderThan.txt" />
            <Environment Id="PATH" Name="PATH" Value="[INSTALLFOLDER]" 
                        Permanent="no" Part="last" Action="set" System="yes" />
          </Component>
        </Directory>
      </Directory>
    </Directory>
    
    <Feature Id="Complete" Title="isOlderThan" Level="1">
      <ComponentRef Id="MainExecutable" />
    </Feature>
  </Product>
</Wix>
```

### Documentation Validation

#### Manual Page Validation
```bash
# Check manual page syntax
man --warnings -E UTF-8 -l isOlderThan.1 > /dev/null

# Test rendering
groff -mandoc -Tascii isOlderThan.1 | less

# Check for broken references
lexgrog isOlderThan.1
```

#### Help File Validation
```cmd
# Windows: Check encoding and readability
type isOlderThan.txt | more

# Verify line endings (should be CRLF)
file isOlderThan.txt
```

## Building from Source

### Prerequisites

**Unix/Linux/macOS:**
- GCC or Clang with C99 support
- Make utility
- Standard POSIX development environment

**Windows:**
- MinGW-w64 or Visual Studio
- Make (via MSYS2 or equivalent)

### Build Options

```bash
# Standard build
make

# Debug build with symbols
make debug

# Clean build artifacts
make clean

# Create distribution package
make dist

# Run tests
make test
```

### Compiler Flags Explained

```bash
# Production flags
-std=c99        # Use C99 standard
-Wall -Wextra   # Enable comprehensive warnings
-Wpedantic      # Strict ISO C compliance
-O2             # Optimize for speed

# Debug flags (make debug)
-g              # Include debug symbols
-DDEBUG         # Enable debug macros
```

## Platform-Specific Notes

### Unix/Linux
- Uses POSIX `stat()` for file times
- Respects system timezone settings
- Manual pages integrate with `man` system

### macOS
- Compatible with both Intel and Apple Silicon
- Uses Darwin-specific time extensions when available
- Integrates with macOS Help system

### Windows
- Compiled with MinGW for maximum compatibility
- Handles Windows path separators automatically
- Supports long file paths and Unicode filenames
- Compatible with PowerShell and Command Prompt

## Examples

### Daily Cleanup Script
```bash
#!/bin/bash
# cleanup.sh - Remove files older than specified periods

LOG_DIR="/var/log/myapp"
TEMP_DIR="/tmp/myapp"

# Remove log files older than 30 days
find "$LOG_DIR" -name "*.log" -type f | while read file; do
    if isOlderThan "$file" -days 30; then
        rm "$file"
        echo "Removed old log: $file"
    fi
done

# Remove temp files older than 1 week
find "$TEMP_DIR" -type f | while read file; do
    if isOlderThan "$file" -weeks 1; then
        rm "$file"
        echo "Removed temp file: $file"
    fi
done
```

### Backup Validation
```bash
#!/bin/bash
# backup-check.sh - Verify backup freshness

BACKUP_FILE="/backups/daily-backup.tar.gz"

if isOlderThan "$BACKUP_FILE" -days 1; then
    echo "WARNING: Backup is older than 1 day!"
    echo "Last backup: $(stat -c %y "$BACKUP_FILE")"
    exit 1
else
    echo "Backup is current"
    exit 0
fi
```

### Windows PowerShell Integration
```powershell
# cleanup.ps1 - Windows cleanup script

$LogPath = "C:\Logs\MyApp"
$TempPath = "C:\Temp\MyApp"

# Clean old log files
Get-ChildItem -Path $LogPath -Filter "*.log" | ForEach-Object {
    if (& .\isOlderThan.exe $_.FullName -days 30) {
        Remove-Item $_.FullName
        Write-Host "Removed old log: $($_.Name)"
    }
}

# Clean temp files
Get-ChildItem -Path $TempPath | ForEach-Object {
    if (& .\isOlderThan.exe $_.FullName -weeks 1) {
        Remove-Item $_.FullName
        Write-Host "Removed temp file: $($_.Name)"
    }
}
```

## Testing

### Automated Tests
```bash
# Run included test suite
make test

# Manual testing examples
touch test_file.txt
sleep 2

# These should return exit code 1 (not older)
./isOlderThan test_file.txt -days 1
./isOlderThan test_file.txt -exact -days 1

# This should return exit code 0 (is older)
./isOlderThan test_file.txt -exact -seconds 1  # If implemented

rm test_file.txt
```

### Edge Case Testing
```bash
# Test leap year handling
touch leap_test.txt
# Set file date to Feb 29, 2020 (leap year)
touch -d "2020-02-29" leap_test.txt
./isOlderThan leap_test.txt -years 4  # Should handle Feb 29 -> Feb 28

# Test month boundary conditions
touch month_test.txt
touch -d "2024-01-31" month_test.txt
./isOlderThan month_test.txt -months 1  # Jan 31 -> Feb 28/29
```

## Troubleshooting

### Common Issues

**"Command not found"**
- Ensure the executable is in your PATH
- Check installation location
- Verify file permissions (`chmod +x isOlderThan`)

**"Permission denied"**
- Run with appropriate privileges
- Check file ownership and permissions
- On Windows, try "Run as Administrator"

**"Invalid parameter combination"**
- Review parameter rules in documentation
- Don't mix exclusive parameters (-days with -weeks)
- Ensure months ≤ 11 when combined with years

### Debug Information
```bash
# Enable debug output (if compiled with DEBUG)
DEBUG=1 ./isOlderThan file.txt -days 30

# Check file permissions
ls -la file.txt
stat file.txt

# Test with known files
./isOlderThan /etc/passwd -days 1  # Should be readable on Unix
```

## Contributing

### Development Setup
```bash
git clone https://github.com/yourusername/isOlderThan.git
cd isOlderThan
make debug
```

### Code Style
- Follow C99 standard
- Use descriptive variable names
- Include comprehensive comments
- Maintain cross-platform compatibility

### Submitting Changes
1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Update documentation as needed
5. Submit a pull request

### Testing Requirements
- All platforms must compile without warnings
- New features need corresponding tests
- Documentation must be updated for changes
- Manual pages and help files must stay synchronized

## License

This project is provided as-is for educational and practical use. See LICENSE file for details.

## Support

- **Issues**: Use GitHub Issues for bug reports and feature requests
- **Documentation**: Check manual pages (`man isOlderThan`) or help file
- **Source Code**: Available on GitHub with full documentation

---

**Built with ❤️ for system administrators, developers, and automation enthusiasts.**
