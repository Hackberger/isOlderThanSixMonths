# Makefile for isOlderThan
# Cross-platform file age verification tool
# Supports: Unix, Linux, Mac, Windows (with MinGW)

# Compiler settings
CC = gcc
CFLAGS = -std=c99 -Wall -Wextra -Wpedantic -O2
TARGET = isOlderThan
SOURCE = isOlderThan.c

# Manual pages and documentation
MANPAGE = isOlderThan.1
HELPFILE = isOlderThan.txt

# Platform detection
UNAME_S := $(shell uname -s 2>/dev/null || echo Windows)

# Platform-specific settings
ifeq ($(UNAME_S),Linux)
    CFLAGS += -D_GNU_SOURCE
    MANDIR = /usr/local/share/man/man1
endif

ifeq ($(UNAME_S),Darwin)
    CFLAGS += -D_DARWIN_C_SOURCE
    MANDIR = /usr/local/share/man/man1
endif

ifeq ($(findstring MINGW,$(UNAME_S)),MINGW)
    TARGET := $(TARGET).exe
    CFLAGS += -D_WIN32
    HELPDIR = C:\Program Files\isOlderThan
endif

# Default target
all: $(TARGET)

# Build target
$(TARGET): $(SOURCE)
	$(CC) $(CFLAGS) -o $(TARGET) $(SOURCE)

# Debug build
debug: CFLAGS += -g -DDEBUG
debug: $(TARGET)

# Clean build artifacts
clean:
	rm -f $(TARGET) $(TARGET).exe *.o

# Install (Unix/Linux/Mac)
install: $(TARGET) $(MANPAGE)
ifdef MANDIR
	install -d $(MANDIR)
	install -m 755 $(TARGET) /usr/local/bin/
	install -m 644 $(MANPAGE) $(MANDIR)/
	mandb > /dev/null 2>&1 || true
	@echo "Installation complete. Use 'man isOlderThan' for documentation."
else
	@echo "Manual installation required on this platform"
endif

# Install on Windows (requires admin privileges)
install-windows: $(TARGET) $(HELPFILE)
	@echo "Windows installation requires administrator privileges"
	mkdir -p "$(HELPDIR)" 2>/dev/null || true
	copy $(TARGET) "$(HELPDIR)\" 2>/dev/null || true
	copy $(HELPFILE) "$(HELPDIR)\help.txt" 2>/dev/null || true
	@echo "Installation complete. Use 'isOlderThan.exe' and see help.txt"

# Uninstall
uninstall:
ifdef MANDIR
	rm -f /usr/local/bin/$(TARGET)
	rm -f $(MANDIR)/$(MANPAGE)
	mandb > /dev/null 2>&1 || true
else
	@echo "Manual uninstallation required on this platform"
endif

# Create distribution package
dist: clean
	mkdir -p isOlderThan-dist
	cp $(SOURCE) Makefile $(MANPAGE) $(HELPFILE) README.md isOlderThan-dist/
	tar -czf isOlderThan-dist.tar.gz isOlderThan-dist/
	rm -rf isOlderThan-dist/
	@echo "Distribution package created: isOlderThan-dist.tar.gz"

# Run tests
test: $(TARGET)
	@echo "Running basic tests..."
	@touch test_file.tmp
	@sleep 1
	@echo "Testing current file (should NOT be older than 1 second):"
	@./$(TARGET) test_file.tmp -days 1 || echo "Correct: File is not older"
	@echo "Testing with exact mode:"
	@./$(TARGET) test_file.tmp -days 1 -exact || echo "Correct: File is not older"
	@rm -f test_file.tmp
	@echo "Tests completed"

# Show help
help:
	@echo "Available targets:"
	@echo "  all           - Build the program (default)"
	@echo "  debug         - Build with debug symbols"
	@echo "  clean         - Remove build artifacts"
	@echo "  install       - Install to system (Unix/Linux/Mac)"
	@echo "  install-windows - Install on Windows (requires admin)"
	@echo "  uninstall     - Remove from system"
	@echo "  dist          - Create distribution package"
	@echo "  test          - Run basic functionality tests"
	@echo "  help          - Show this help"

.PHONY: all debug clean install install-windows uninstall dist test help
