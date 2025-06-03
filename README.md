# isOlderThanSixMonths

A POSIX-compatible shell script to check if a file is older than 6 months.

## 📋 Description

`isOlderThanSixMonths` checks a file's modification date and determines if the file is older than 6 months. The calculation follows the same logic as Excel's `DATEDIF` function with the `"m"` parameter for months.

## 🚀 Installation

### Automatic Installation
```bash
# Download and install
curl -O https://raw.githubusercontent.com/yourusername/isOlderThanSixMonths/main/isOlderThanSixMonths
chmod +x isOlderThanSixMonths
sudo mv isOlderThanSixMonths /usr/local/bin/
```

### Manual Installation
1. Download the script
2. Make it executable: `chmod +x isOlderThanSixMonths`
3. Move to a directory in your `$PATH` (e.g., `/usr/local/bin/`)

### Installing the Man Page
```bash
# Copy the man page to the system
sudo cp isOlderThanSixMonths.1 /usr/local/man/man1/

# Update the man database
sudo mandb                                    # Linux
# or
sudo makewhatis /usr/local/man               # macOS/BSD
```

## 📖 Usage

### Syntax
```bash
isOlderThanSixMonths <file_path>
```

### Examples
```bash
# Check a file in the current directory
isOlderThanSixMonths ./document.txt

# Check a file with absolute path
isOlderThanSixMonths /var/log/system.log

# Check a file in the home directory
isOlderThanSixMonths ~/backup.tar.gz

# Show help
isOlderThanSixMonths --help
```

### Usage in Scripts
```bash
#!/bin/bash

if isOlderThanSixMonths "/path/to/file.txt"; then
    echo "File is older than 6 months - can be deleted"
    # rm "/path/to/file.txt"
else
    echo "File is still current"
fi
```

### Usage with find
```bash
# Find all files older than 6 months
find /backup -type f -exec sh -c 'isOlderThanSixMonths "$1"' _ {} \; -print

# Delete all old backup files
find /backup -name "*.bak" -type f -exec sh -c '
    if isOlderThanSixMonths "$1"; then
        echo "Deleting old file: $1"
        rm "$1"
    fi
' _ {} \;
```

## 🔄 Return Values

The script uses exit codes to communicate the result:

| Exit Code | Meaning |
|-----------|---------|
| `0` | ✅ File is **older** than 6 months |
| `1` | ⏰ File is **younger** than 6 months |
| `255` (-1) | ❌ File not found |
| `254` (-2) | ⚠️ Other error (wrong parameters, etc.) |

### Checking Return Values
```bash
isOlderThanSixMonths /path/to/file.txt
case $? in
    0)   echo "File is older than 6 months" ;;
    1)   echo "File is younger than 6 months" ;;
    255) echo "File not found" ;;
    254) echo "Error during execution" ;;
esac
```

## 🔧 How it Works

The script:
1. Determines the file's modification date using `stat`
2. Calculates the number of months between the modification date and today
3. Uses the same logic as Excel's `DATEDIF` function
4. Correctly handles different month lengths

### Calculation Logic
```
Months = (Today_Year - File_Year) × 12 + (Today_Month - File_Month)

If Today_Day < File_Day:
    Months = Months - 1
```

## 🖥️ Compatibility

**Supported Systems:**
- ✅ Linux (all distributions)
- ✅ macOS
- ✅ FreeBSD, OpenBSD, NetBSD
- ✅ AIX, Solaris
- ✅ Cygwin on Windows

**Supported Shells:**
- ✅ sh (POSIX)
- ✅ bash
- ✅ zsh
- ✅ ksh
- ✅ dash
- ✅ ash

## ⚠️ Important Notes

- The script uses the file's **modification date** (`mtime`)
- Symbolic links are not followed automatically
- System time changes may cause temporarily inaccurate results
- The script is POSIX-compatible and requires no special tools

## 📚 Documentation

### Man Page Generation
The included man page can be generated and installed as follows:

#### Installing the Man Page
```bash
# Copy the man page source
sudo cp isOlderThanSixMonths.1 /usr/local/man/man1/

# Update man database (Linux)
sudo mandb

# Update man database (macOS/BSD)
sudo makewhatis /usr/local/man

# Verify installation
man isOlderThanSixMonths
```

#### Alternative Installation Locations
```bash
# System-wide (requires root)
sudo cp isOlderThanSixMonths.1 /usr/share/man/man1/

# User-specific
mkdir -p ~/.local/man/man1
cp isOlderThanSixMonths.1 ~/.local/man/man1/
export MANPATH="$HOME/.local/man:$MANPATH"
```

#### Viewing the Man Page
```bash
# View the installed man page
man isOlderThanSixMonths

# View the raw man page source
man -l isOlderThanSixMonths.1

# Generate formatted text output
man -t isOlderThanSixMonths | ps2pdf - isOlderThanSixMonths.pdf
```

## 🐛 Troubleshooting

### Common Problems

**Problem:** `stat: command not found`
```bash
# Solution: Use full path
/usr/bin/stat or /bin/stat
```

**Problem:** Different `stat` syntax
```bash
# The script automatically detects:
# Linux: stat -c "%Y"
# macOS/BSD: stat -f "%m"
```

**Problem:** Different `date` syntax
```bash
# The script automatically detects:
# Linux: date -d "@timestamp"
# macOS/BSD: date -r timestamp
```

## 📝 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

- 🐛 **Bug Reports:** Create an [Issue](https://github.com/yourusername/isOlderThanSixMonths/issues)
- 💡 **Feature Requests:** Create an [Issue](https://github.com/yourusername/isOlderThanSixMonths/issues)
- 📧 **Contact:** [airdrop_zufluesse2a@icloud.com](mailto:airdrop_zufluesse2a@icloud.com)

## 📊 Changelog

### Version 1.0.0
- ✨ Initial release
- ✅ POSIX compatibility
- ✅ Linux/macOS/BSD support
- ✅ Complete error handling
- ✅ Full documentation with man page

---

**⭐ Like this project? Give us a star!**
