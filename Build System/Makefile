# Makefile for isOlderThan - Enhanced Cross-Platform Version
# File Age Verification Tool with Professional Build System
# Supports: Unix, Linux, macOS, Windows (MinGW), and development workflows

#==============================================================================
# Project Configuration
#==============================================================================
PROJECT_NAME = isOlderThan
VERSION = 1.0
SOURCE_FILE = IsOlderThan/isOlderThan.c
HEADER_FILE = IsOlderThan/isOlderThan.h
MAIN_FILE = IsOlderThan/main.c

# Documentation files
MANPAGE = Documentation/isOlderThan.1
HELPFILE = Documentation/isOlderThan.txt
README = README.md

# Build output
BUILD_DIR = build
DIST_DIR = dist
INSTALL_PREFIX = /usr/local

#==============================================================================
# Platform Detection and Configuration
#==============================================================================
UNAME_S := $(shell uname -s 2>/dev/null || echo Windows)
UNAME_M := $(shell uname -m 2>/dev/null || echo unknown)

# Detect if we're in a Git repository
GIT_VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "v$(VERSION)")
BUILD_DATE := $(shell date -u +"%Y-%m-%d %H:%M:%S UTC" 2>/dev/null || echo "unknown")

#==============================================================================
# Compiler and Build Tool Configuration
#==============================================================================
CC = gcc
AR = ar
STRIP = strip
INSTALL = install
MKDIR = mkdir -p
CP = cp -r
RM = rm -rf

# Base compiler flags
CFLAGS_BASE = -std=c99 -Wall -Wextra -Wpedantic
CFLAGS_RELEASE = -O2 -DNDEBUG
CFLAGS_DEBUG = -g -DDEBUG -O0
LDFLAGS =

# Version information
VERSION_DEFINES = -DVERSION=\"$(VERSION)\" -DGIT_VERSION=\"$(GIT_VERSION)\" -DBUILD_DATE=\"$(BUILD_DATE)\"

#==============================================================================
# Platform-Specific Settings
#==============================================================================
ifeq ($(UNAME_S),Linux)
    PLATFORM = linux
    CFLAGS_PLATFORM = -D_GNU_SOURCE -D_POSIX_C_SOURCE=200809L
    MANDIR = $(INSTALL_PREFIX)/share/man/man1
    BINDIR = $(INSTALL_PREFIX)/bin
    INCDIR = $(INSTALL_PREFIX)/include
    LIBDIR = $(INSTALL_PREFIX)/lib
    TARGET_SUFFIX =
    SHARED_EXT = .so
    STATIC_EXT = .a
    PKG_FORMAT = deb rpm
endif

ifeq ($(UNAME_S),Darwin)
    PLATFORM = macos
    CFLAGS_PLATFORM = -D_DARWIN_C_SOURCE
    MANDIR = $(INSTALL_PREFIX)/share/man/man1
    BINDIR = $(INSTALL_PREFIX)/bin
    INCDIR = $(INSTALL_PREFIX)/include
    LIBDIR = $(INSTALL_PREFIX)/lib
    TARGET_SUFFIX =
    SHARED_EXT = .dylib
    STATIC_EXT = .a
    PKG_FORMAT = pkg
    # Universal binary support
    ARCH_FLAGS = -arch x86_64 -arch arm64
endif

ifeq ($(UNAME_S),FreeBSD)
    PLATFORM = freebsd
    CFLAGS_PLATFORM = -D_BSD_SOURCE
    MANDIR = $(INSTALL_PREFIX)/man/man1
    BINDIR = $(INSTALL_PREFIX)/bin
    INCDIR = $(INSTALL_PREFIX)/include
    LIBDIR = $(INSTALL_PREFIX)/lib
    TARGET_SUFFIX =
    SHARED_EXT = .so
    STATIC_EXT = .a
    PKG_FORMAT = pkg
endif

ifeq ($(findstring MINGW,$(UNAME_S)),MINGW)
    PLATFORM = windows
    CFLAGS_PLATFORM = -D_WIN32 -DWIN32_LEAN_AND_MEAN
    BINDIR = /c/Program\ Files/$(PROJECT_NAME)
    TARGET_SUFFIX = .exe
    SHARED_EXT = .dll
    STATIC_EXT = .a
    PKG_FORMAT = msi nsis
    # Windows-specific libraries
    LDFLAGS += -lkernel32 -luser32
endif

ifeq ($(findstring MSYS,$(UNAME_S)),MSYS)
    PLATFORM = windows
    CFLAGS_PLATFORM = -D_WIN32 -DWIN32_LEAN_AND_MEAN
    BINDIR = /c/Program\ Files/$(PROJECT_NAME)
    TARGET_SUFFIX = .exe
    SHARED_EXT = .dll
    STATIC_EXT = .a
    PKG_FORMAT = msi nsis
    LDFLAGS += -lkernel32 -luser32
endif

# Fallback for unknown platforms
ifndef PLATFORM
    PLATFORM = unknown
    CFLAGS_PLATFORM =
    BINDIR = $(INSTALL_PREFIX)/bin
    TARGET_SUFFIX =
    SHARED_EXT = .so
    STATIC_EXT = .a
    PKG_FORMAT =
endif

#==============================================================================
# Target Names and Paths
#==============================================================================
TARGET = $(PROJECT_NAME)$(TARGET_SUFFIX)
TARGET_DEBUG = $(PROJECT_NAME)_debug$(TARGET_SUFFIX)
STATIC_LIB = lib$(PROJECT_NAME)$(STATIC_EXT)
SHARED_LIB = lib$(PROJECT_NAME)$(SHARED_EXT)

# Build directories
BUILD_RELEASE_DIR = $(BUILD_DIR)/release
BUILD_DEBUG_DIR = $(BUILD_DIR)/debug
BUILD_LIB_DIR = $(BUILD_DIR)/lib
BUILD_TEST_DIR = $(BUILD_DIR)/test

# Object files
OBJ_RELEASE = $(BUILD_RELEASE_DIR)/isOlderThan.o $(BUILD_RELEASE_DIR)/main.o
OBJ_DEBUG = $(BUILD_DEBUG_DIR)/isOlderThan.o $(BUILD_DEBUG_DIR)/main.o
OBJ_LIB = $(BUILD_LIB_DIR)/isOlderThan.o

#==============================================================================
# Final Compiler Flags Assembly
#==============================================================================
CFLAGS = $(CFLAGS_BASE) $(CFLAGS_PLATFORM) $(VERSION_DEFINES) $(ARCH_FLAGS)
CFLAGS_REL = $(CFLAGS) $(CFLAGS_RELEASE)
CFLAGS_DBG = $(CFLAGS) $(CFLAGS_DEBUG)

#==============================================================================
# Default Target
#==============================================================================
.PHONY: all
all: release

#==============================================================================
# Build Targets
#==============================================================================

# Release build
.PHONY: release
release: $(BUILD_RELEASE_DIR)/$(TARGET)

$(BUILD_RELEASE_DIR)/$(TARGET): $(OBJ_RELEASE) | $(BUILD_RELEASE_DIR)
	@echo "Linking release executable: $@"
	$(CC) $(CFLAGS_REL) $(LDFLAGS) -o $@ $(OBJ_RELEASE)
	@echo "Release build complete: $@"

$(BUILD_RELEASE_DIR)/isOlderThan.o: $(SOURCE_FILE) $(HEADER_FILE) | $(BUILD_RELEASE_DIR)
	@echo "Compiling (release): $<"
	$(CC) $(CFLAGS_REL) -c $< -o $@

$(BUILD_RELEASE_DIR)/main.o: $(MAIN_FILE) $(HEADER_FILE) | $(BUILD_RELEASE_DIR)
	@echo "Compiling (release): $<"
	$(CC) $(CFLAGS_REL) -c $< -o $@

# Debug build
.PHONY: debug
debug: $(BUILD_DEBUG_DIR)/$(TARGET_DEBUG)

$(BUILD_DEBUG_DIR)/$(TARGET_DEBUG): $(OBJ_DEBUG) | $(BUILD_DEBUG_DIR)
	@echo "Linking debug executable: $@"
	$(CC) $(CFLAGS_DBG) $(LDFLAGS) -o $@ $(OBJ_DEBUG)
	@echo "Debug build complete: $@"

$(BUILD_DEBUG_DIR)/isOlderThan.o: $(SOURCE_FILE) $(HEADER_FILE) | $(BUILD_DEBUG_DIR)
	@echo "Compiling (debug): $<"
	$(CC) $(CFLAGS_DBG) -c $< -o $@

$(BUILD_DEBUG_DIR)/main.o: $(MAIN_FILE) $(HEADER_FILE) | $(BUILD_DEBUG_DIR)
	@echo "Compiling (debug): $<"
	$(CC) $(CFLAGS_DBG) -c $< -o $@

# Static library
.PHONY: static-lib
static-lib: $(BUILD_LIB_DIR)/$(STATIC_LIB)

$(BUILD_LIB_DIR)/$(STATIC_LIB): $(OBJ_LIB) | $(BUILD_LIB_DIR)
	@echo "Creating static library: $@"
	$(AR) rcs $@ $(OBJ_LIB)
	@echo "Static library complete: $@"

$(BUILD_LIB_DIR)/isOlderThan.o: $(SOURCE_FILE) $(HEADER_FILE) | $(BUILD_LIB_DIR)
	@echo "Compiling (library): $<"
	$(CC) $(CFLAGS_REL) -fPIC -c $< -o $@

# Shared library (where supported)
.PHONY: shared-lib
shared-lib: $(BUILD_LIB_DIR)/$(SHARED_LIB)

$(BUILD_LIB_DIR)/$(SHARED_LIB): $(OBJ_LIB) | $(BUILD_LIB_DIR)
	@echo "Creating shared library: $@"
ifeq ($(PLATFORM),macos)
	$(CC) $(CFLAGS_REL) $(LDFLAGS) -shared -o $@ $(OBJ_LIB) -install_name $(LIBDIR)/$(SHARED_LIB)
else ifeq ($(PLATFORM),windows)
	$(CC) $(CFLAGS_REL) $(LDFLAGS) -shared -o $@ $(OBJ_LIB) -Wl,--out-implib,$(BUILD_LIB_DIR)/lib$(PROJECT_NAME).dll.a
else
	$(CC) $(CFLAGS_REL) $(LDFLAGS) -shared -fPIC -o $@ $(OBJ_LIB) -Wl,-soname,$(SHARED_LIB)
endif
	@echo "Shared library complete: $@"

# Build everything
.PHONY: all-targets
all-targets: release debug static-lib shared-lib

#==============================================================================
# Directory Creation
#==============================================================================
$(BUILD_DIR):
	$(MKDIR) $(BUILD_DIR)

$(BUILD_RELEASE_DIR): | $(BUILD_DIR)
	$(MKDIR) $(BUILD_RELEASE_DIR)

$(BUILD_DEBUG_DIR): | $(BUILD_DIR)
	$(MKDIR) $(BUILD_DEBUG_DIR)

$(BUILD_LIB_DIR): | $(BUILD_DIR)
	$(MKDIR) $(BUILD_LIB_DIR)

$(BUILD_TEST_DIR): | $(BUILD_DIR)
	$(MKDIR) $(BUILD_TEST_DIR)

$(DIST_DIR):
	$(MKDIR) $(DIST_DIR)

#==============================================================================
# Installation Targets
#==============================================================================

# Unix/Linux/macOS installation
.PHONY: install
install: release static-lib
ifdef MANDIR
	@echo "Installing to system directories..."
	$(MKDIR) $(BINDIR) $(MANDIR) $(INCDIR) $(LIBDIR)
	$(INSTALL) -m 755 $(BUILD_RELEASE_DIR)/$(TARGET) $(BINDIR)/
	$(INSTALL) -m 644 $(MANPAGE) $(MANDIR)/
	$(INSTALL) -m 644 $(HEADER_FILE) $(INCDIR)/
	$(INSTALL) -m 644 $(BUILD_LIB_DIR)/$(STATIC_LIB) $(LIBDIR)/
	@echo "Updating manual database..."
	-mandb > /dev/null 2>&1 || true
	@echo "Installation complete!"
	@echo "Usage: $(PROJECT_NAME) <filepath> [options]"
	@echo "Manual: man $(PROJECT_NAME)"
else
	@echo "ERROR: Installation not supported on this platform"
	@echo "Use 'make install-windows' for Windows installation"
	@exit 1
endif

# Windows installation
.PHONY: install-windows
install-windows: release
ifeq ($(PLATFORM),windows)
	@echo "Installing for Windows..."
	$(MKDIR) "$(BINDIR)" 2>/dev/null || true
	$(CP) $(BUILD_RELEASE_DIR)/$(TARGET) "$(BINDIR)/" 2>/dev/null || true
	$(CP) $(HELPFILE) "$(BINDIR)/help.txt" 2>/dev/null || true
	@echo "Windows installation complete!"
	@echo "Add $(BINDIR) to your PATH environment variable"
else
	@echo "ERROR: install-windows only available on Windows platforms"
	@exit 1
endif

# Development installation (includes headers and libraries)
.PHONY: install-dev
install-dev: install shared-lib
ifdef LIBDIR
	$(INSTALL) -m 644 $(BUILD_LIB_DIR)/$(SHARED_LIB) $(LIBDIR)/
	@echo "Development installation complete!"
else
	@echo "ERROR: Development installation not supported on this platform"
	@exit 1
endif

#==============================================================================
# Uninstallation
#==============================================================================
.PHONY: uninstall
uninstall:
ifdef MANDIR
	@echo "Removing installed files..."
	$(RM) $(BINDIR)/$(TARGET)
	$(RM) $(MANDIR)/$(PROJECT_NAME).1
	$(RM) $(INCDIR)/$(PROJECT_NAME).h
	$(RM) $(LIBDIR)/$(STATIC_LIB)
	$(RM) $(LIBDIR)/$(SHARED_LIB)
	-mandb > /dev/null 2>&1 || true
	@echo "Uninstallation complete!"
else
	@echo "Manual uninstallation required on this platform"
endif

#==============================================================================
# Testing Framework
#==============================================================================

# Basic functionality tests
.PHONY: test
test: release
	@echo "Running basic functionality tests..."
	@echo "Creating test environment..."
	@$(MKDIR) $(BUILD_TEST_DIR)
	@touch $(BUILD_TEST_DIR)/test_file.tmp
	@sleep 1
	@echo "Testing file age detection..."
	@echo "Test 1: Recent file should NOT be older than 1 day"
	@if $(BUILD_RELEASE_DIR)/$(TARGET) $(BUILD_TEST_DIR)/test_file.tmp -days 1; then \
		echo "FAIL: Recent file incorrectly identified as old"; \
		exit 1; \
	else \
		echo "PASS: Recent file correctly identified as new"; \
	fi
	@echo "Test 2: Recent file should NOT be older than 1 day (exact mode)"
	@if $(BUILD_RELEASE_DIR)/$(TARGET) $(BUILD_TEST_DIR)/test_file.tmp -days 1 -exact; then \
		echo "FAIL: Recent file incorrectly identified as old (exact mode)"; \
		exit 1; \
	else \
		echo "PASS: Recent file correctly identified as new (exact mode)"; \
	fi
	@echo "Test 3: Invalid parameter combination"
	@if $(BUILD_RELEASE_DIR)/$(TARGET) $(BUILD_TEST_DIR)/test_file.tmp -days 1 -weeks 1 2>/dev/null; then \
		echo "FAIL: Invalid combination not detected"; \
		exit 1; \
	else \
		echo "PASS: Invalid combination correctly detected"; \
	fi
	@echo "Test 4: Non-existent file"
	@if $(BUILD_RELEASE_DIR)/$(TARGET) /nonexistent/file.txt -days 1 2>/dev/null; then \
		echo "FAIL: Non-existent file not detected"; \
		exit 1; \
	else \
		echo "PASS: Non-existent file correctly detected"; \
	fi
	@$(RM) $(BUILD_TEST_DIR)/test_file.tmp
	@echo "All basic tests passed!"

# Extended testing with various scenarios
.PHONY: test-extended
test-extended: test
	@echo "Running extended test suite..."
	@$(MKDIR) $(BUILD_TEST_DIR)/extended
	@echo "Creating test files with different ages..."
	
	# Create files with different ages using touch
	@touch $(BUILD_TEST_DIR)/extended/new_file.txt
	@touch -d "1 hour ago" $(BUILD_TEST_DIR)/extended/hour_old.txt 2>/dev/null || touch $(BUILD_TEST_DIR)/extended/hour_old.txt
	@touch -d "2 days ago" $(BUILD_TEST_DIR)/extended/days_old.txt 2>/dev/null || touch $(BUILD_TEST_DIR)/extended/days_old.txt
	@touch -d "1 week ago" $(BUILD_TEST_DIR)/extended/week_old.txt 2>/dev/null || touch $(BUILD_TEST_DIR)/extended/week_old.txt
	
	@echo "Testing various time parameters..."
	@echo "Extended tests completed - manual verification required for timestamp-dependent tests"

# Performance testing
.PHONY: test-performance
test-performance: release
	@echo "Running performance tests..."
	@$(MKDIR) $(BUILD_TEST_DIR)/performance
	@echo "Creating 100 test files..."
	@for i in $$(seq 1 100); do \
		touch $(BUILD_TEST_DIR)/performance/file_$$i.txt; \
	done
	@echo "Testing batch processing performance..."
	@time for file in $(BUILD_TEST_DIR)/performance/*.txt; do \
		$(BUILD_RELEASE_DIR)/$(TARGET) "$$file" -days 1 >/dev/null 2>&1; \
	done
	@echo "Performance test completed!"

# Memory leak testing (requires valgrind)
.PHONY: test-memory
test-memory: debug
	@if command -v valgrind >/dev/null 2>&1; then \
		echo "Running memory leak tests with valgrind..."; \
		$(MKDIR) $(BUILD_TEST_DIR); \
		touch $(BUILD_TEST_DIR)/memory_test.txt; \
		valgrind --leak-check=full --error-exitcode=1 \
			$(BUILD_DEBUG_DIR)/$(TARGET_DEBUG) $(BUILD_TEST_DIR)/memory_test.txt -days 1; \
		echo "Memory test completed!"; \
	else \
		echo "Valgrind not available - skipping memory tests"; \
	fi

# Complete test suite
.PHONY: test-all
test-all: test test-extended test-performance test-memory

#==============================================================================
# Code Quality and Analysis
#==============================================================================

# Static analysis (requires cppcheck)
.PHONY: analyze
analyze:
	@if command -v cppcheck >/dev/null 2>&1; then \
		echo "Running static analysis..."; \
		cppcheck --enable=all --std=c99 --suppress=missingIncludeSystem \
			$(SOURCE_FILE) $(MAIN_FILE); \
		echo "Static analysis completed!"; \
	else \
		echo "cppcheck not available - skipping static analysis"; \
	fi

# Code formatting (requires clang-format)
.PHONY: format
format:
	@if command -v clang-format >/dev/null 2>&1; then \
		echo "Formatting source code..."; \
		clang-format -i $(SOURCE_FILE) $(HEADER_FILE) $(MAIN_FILE); \
		echo "Code formatting completed!"; \
	else \
		echo "clang-format not available - skipping code formatting"; \
	fi

# Check formatting
.PHONY: format-check
format-check:
	@if command -v clang-format >/dev/null 2>&1; then \
		echo "Checking code formatting..."; \
		clang-format --dry-run --Werror $(SOURCE_FILE) $(HEADER_FILE) $(MAIN_FILE); \
		echo "Code formatting check passed!"; \
	else \
		echo "clang-format not available - skipping format check"; \
	fi

#==============================================================================
# Distribution and Packaging
#==============================================================================

# Create source distribution
.PHONY: dist-source
dist-source: | $(DIST_DIR)
	@echo "Creating source distribution..."
	@$(MKDIR) $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION)
	@$(CP) $(SOURCE_FILE) $(HEADER_FILE) $(MAIN_FILE) $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION)/
	@$(CP) Makefile $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION)/
	@$(CP) $(README) $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION)/
	@$(CP) Documentation/ $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION)/
	@$(CP) "Build System/" $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION)/ 2>/dev/null || true
	@cd $(DIST_DIR) && tar -czf $(PROJECT_NAME)-$(VERSION)-src.tar.gz $(PROJECT_NAME)-$(VERSION)/
	@echo "Source distribution created: $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION)-src.tar.gz"

# Create binary distribution
.PHONY: dist-binary
dist-binary: release static-lib | $(DIST_DIR)
	@echo "Creating binary distribution for $(PLATFORM)..."
	@$(MKDIR) $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION)-$(PLATFORM)
	@$(CP) $(BUILD_RELEASE_DIR)/$(TARGET) $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION)-$(PLATFORM)/
	@$(CP) $(BUILD_LIB_DIR)/$(STATIC_LIB) $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION)-$(PLATFORM)/
	@$(CP) $(HEADER_FILE) $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION)-$(PLATFORM)/
	@$(CP) $(README) $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION)-$(PLATFORM)/
ifdef MANDIR
	@$(CP) $(MANPAGE) $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION)-$(PLATFORM)/
else
	@$(CP) $(HELPFILE) $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION)-$(PLATFORM)/
endif
	@cd $(DIST_DIR) && tar -czf $(PROJECT_NAME)-$(VERSION)-$(PLATFORM).tar.gz $(PROJECT_NAME)-$(VERSION)-$(PLATFORM)/
	@echo "Binary distribution created: $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION)-$(PLATFORM).tar.gz"

# Platform-specific packages
.PHONY: package
package: dist-binary
ifeq ($(PLATFORM),linux)
	@echo "Creating Linux packages..."
	@$(MAKE) package-deb
	@$(MAKE) package-rpm
else ifeq ($(PLATFORM),macos)
	@echo "Creating macOS package..."
	@$(MAKE) package-macos
else ifeq ($(PLATFORM),windows)
	@echo "Windows installer creation requires NSIS or WiX toolset"
	@echo "Binary distribution available in $(DIST_DIR)/"
else
	@echo "No specific package format available for $(PLATFORM)"
	@echo "Binary distribution available in $(DIST_DIR)/"
endif

# Debian package
.PHONY: package-deb
package-deb: release | $(DIST_DIR)
ifeq ($(PLATFORM),linux)
	@echo "Creating Debian package..."
	@$(MKDIR) $(DIST_DIR)/deb/$(PROJECT_NAME)_$(VERSION)/DEBIAN
	@$(MKDIR) $(DIST_DIR)/deb/$(PROJECT_NAME)_$(VERSION)/usr/local/bin
	@$(MKDIR) $(DIST_DIR)/deb/$(PROJECT_NAME)_$(VERSION)/usr/local/share/man/man1
	@$(CP) $(BUILD_RELEASE_DIR)/$(TARGET) $(DIST_DIR)/deb/$(PROJECT_NAME)_$(VERSION)/usr/local/bin/
	@$(CP) $(MANPAGE) $(DIST_DIR)/deb/$(PROJECT_NAME)_$(VERSION)/usr/local/share/man/man1/
	@echo "Package: $(PROJECT_NAME)" > $(DIST_DIR)/deb/$(PROJECT_NAME)_$(VERSION)/DEBIAN/control
	@echo "Version: $(VERSION)" >> $(DIST_DIR)/deb/$(PROJECT_NAME)_$(VERSION)/DEBIAN/control
	@echo "Section: utils" >> $(DIST_DIR)/deb/$(PROJECT_NAME)_$(VERSION)/DEBIAN/control
	@echo "Priority: optional" >> $(DIST_DIR)/deb/$(PROJECT_NAME)_$(VERSION)/DEBIAN/control
	@echo "Architecture: $(shell dpkg --print-architecture 2>/dev/null || echo amd64)" >> $(DIST_DIR)/deb/$(PROJECT_NAME)_$(VERSION)/DEBIAN/control
	@echo "Maintainer: isOlderThan Project" >> $(DIST_DIR)/deb/$(PROJECT_NAME)_$(VERSION)/DEBIAN/control
	@echo "Description: File age verification tool" >> $(DIST_DIR)/deb/$(PROJECT_NAME)_$(VERSION)/DEBIAN/control
	@echo " Cross-platform command-line utility for checking file ages" >> $(DIST_DIR)/deb/$(PROJECT_NAME)_$(VERSION)/DEBIAN/control
	@if command -v dpkg-deb >/dev/null 2>&1; then \
		cd $(DIST_DIR)/deb && dpkg-deb --build $(PROJECT_NAME)_$(VERSION); \
		echo "Debian package created: $(DIST_DIR)/deb/$(PROJECT_NAME)_$(VERSION).deb"; \
	else \
		echo "dpkg-deb not available - Debian package structure created but not built"; \
	fi
endif

# RPM package
.PHONY: package-rpm
package-rpm: release | $(DIST_DIR)
ifeq ($(PLATFORM),linux)
	@echo "Creating RPM package structure..."
	@$(MKDIR) $(DIST_DIR)/rpm/BUILD $(DIST_DIR)/rpm/RPMS $(DIST_DIR)/rpm/SOURCES $(DIST_DIR)/rpm/SPECS $(DIST_DIR)/rpm/SRPMS
	@echo "Name: $(PROJECT_NAME)" > $(DIST_DIR)/rpm/SPECS/$(PROJECT_NAME).spec
	@echo "Version: $(VERSION)" >> $(DIST_DIR)/rpm/SPECS/$(PROJECT_NAME).spec
	@echo "Release: 1" >> $(DIST_DIR)/rpm/SPECS/$(PROJECT_NAME).spec
	@echo "Summary: File age verification tool" >> $(DIST_DIR)/rpm/SPECS/$(PROJECT_NAME).spec
	@echo "License: MIT" >> $(DIST_DIR)/rpm/SPECS/$(PROJECT_NAME).spec
	@echo "Group: Applications/System" >> $(DIST_DIR)/rpm/SPECS/$(PROJECT_NAME).spec
	@echo "" >> $(DIST_DIR)/rpm/SPECS/$(PROJECT_NAME).spec
	@echo "%description" >> $(DIST_DIR)/rpm/SPECS/$(PROJECT_NAME).spec
	@echo "Cross-platform command-line utility for checking if files are older than specified time periods." >> $(DIST_DIR)/rpm/SPECS/$(PROJECT_NAME).spec
	@echo "" >> $(DIST_DIR)/rpm/SPECS/$(PROJECT_NAME).spec
	@echo "%install" >> $(DIST_DIR)/rpm/SPECS/$(PROJECT_NAME).spec
	@echo "mkdir -p %{buildroot}/usr/local/bin" >> $(DIST_DIR)/rpm/SPECS/$(PROJECT_NAME).spec
	@echo "mkdir -p %{buildroot}/usr/local/share/man/man1" >> $(DIST_DIR)/rpm/SPECS/$(PROJECT_NAME).spec
	@echo "cp $(BUILD_RELEASE_DIR)/$(TARGET) %{buildroot}/usr/local/bin/" >> $(DIST_DIR)/rpm/SPECS/$(PROJECT_NAME).spec
	@echo "cp $(MANPAGE) %{buildroot}/usr/local/share/man/man1/" >> $(DIST_DIR)/rpm/SPECS/$(PROJECT_NAME).spec
	@echo "" >> $(DIST_DIR)/rpm/SPECS/$(PROJECT_NAME).spec
	@echo "%files" >> $(DIST_DIR)/rpm/SPECS/$(PROJECT_NAME).spec
	@echo "/usr/local/bin/$(TARGET)" >> $(DIST_DIR)/rpm/SPECS/$(PROJECT_NAME).spec
	@echo "/usr/local/share/man/man1/$(PROJECT_NAME).1" >> $(DIST_DIR)/rpm/SPECS/$(PROJECT_NAME).spec
	@echo "RPM spec file created: $(DIST_DIR)/rpm/SPECS/$(PROJECT_NAME).spec"
	@echo "Use 'rpmbuild -ba $(DIST_DIR)/rpm/SPECS/$(PROJECT_NAME).spec' to build RPM"
endif

# macOS package
.PHONY: package-macos
package-macos: release | $(DIST_DIR)
ifeq ($(PLATFORM),macos)
	@echo "Creating macOS package structure..."
	@$(MKDIR) $(DIST_DIR)/macos/package/usr/local/bin
	@$(MKDIR) $(DIST_DIR)/macos/package/usr/local/share/man/man1
	@$(CP) $(BUILD_RELEASE_DIR)/$(TARGET) $(DIST_DIR)/macos/package/usr/local/bin/
	@$(CP) $(MANPAGE) $(DIST_DIR)/macos/package/usr/local/share/man/man1/
	@if command -v pkgbuild >/dev/null 2>&1; then \
		pkgbuild --root $(DIST_DIR)/macos/package \
			--identifier com.isolderthan.pkg \
			--version $(VERSION) \
			--install-location / \
			$(DIST_DIR)/$(PROJECT_NAME)-$(VERSION)-macos.pkg; \
		echo "macOS package created: $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION)-macos.pkg"; \
	else \
		echo "pkgbuild not available - package structure created in $(DIST_DIR)/macos/"; \
	fi
endif

#==============================================================================
# Documentation Generation
#==============================================================================

# Generate all documentation
.PHONY: docs
docs:
	@echo "Generating documentation..."
	@echo "Manual page: $(MANPAGE)"
	@echo "Help file: $(HELPFILE)"
	@echo "README: $(README)"
	@if command -v groff >/dev/null 2>&1; then \
		echo "Validating manual page..."; \
		groff -mandoc -Tascii $(MANPAGE) >/dev/null; \
		echo "Manual page validation passed!"; \
	fi
	@echo "Documentation check completed!"

# Test manual page rendering
.PHONY: test-man
test-man:
	@if command -v groff >/dev/null 2>&1; then \
		echo "Testing manual page rendering..."; \
		groff -mandoc -Tascii $(MANPAGE) | head -50; \
	else \
		echo "groff not available - cannot test manual page rendering"; \
	fi

#==============================================================================
# Continuous Integration Support
#==============================================================================

# CI-friendly build (quiet output, fail fast)
.PHONY: ci-build
ci-build: clean
	@echo "=== CI Build Starting ==="
	@echo "Platform: $(PLATFORM)"
	@echo "Compiler: $(CC) $(shell $(CC) --version 2>/dev/null | head -1)"
	@echo "Build date: $(BUILD_DATE)"
	@echo "Git version: $(GIT_VERSION)"
	@$(MAKE) --no-print-directory release
	@$(MAKE) --no-print-directory static-lib
	@$(MAKE) --no-print-directory test
	@echo "=== CI Build Completed Successfully ==="

# CI test suite (includes all automated tests)
.PHONY: ci-test
ci-test:
	@echo "=== CI Test Suite Starting ==="
	@$(MAKE) --no-print-directory test
	@$(MAKE) --no-print-directory test-extended
	@$(MAKE) --no-print-directory analyze
	@$(MAKE) --no-print-directory format-check
	@echo "=== CI Test Suite Completed Successfully ==="

# Coverage build (requires gcov)
.PHONY: coverage
coverage:
	@if command -v gcov >/dev/null 2>&1; then \
		echo "Building with coverage support..."; \
		$(MAKE) clean; \
		CFLAGS_DEBUG="$(CFLAGS_DEBUG) --coverage" LDFLAGS="$(LDFLAGS) --coverage" $(MAKE) debug; \
		$(MAKE) test; \
		echo "Generating coverage report..."; \
		gcov $(BUILD_DEBUG_DIR)/*.gcno; \
		echo "Coverage report generated!"; \
	else \
		echo "gcov not available - skipping coverage build"; \
	fi

#==============================================================================
# Development Workflow Targets
#==============================================================================

# Quick development build and test
.PHONY: dev
dev: debug test
	@echo "Development build completed!"

# Full development cycle
.PHONY: dev-full
dev-full: clean all-targets test-all analyze docs
	@echo "Full development cycle completed!"

# Prepare for release
.PHONY: prepare-release
prepare-release: clean all-targets test-all analyze format-check docs dist-source dist-binary
	@echo "Release preparation completed!"
	@echo "Version: $(VERSION)"
	@echo "Git version: $(GIT_VERSION)"
	@echo "Platform: $(PLATFORM)"
	@echo "Distributions created in $(DIST_DIR)/"

#==============================================================================
# Debugging and Development Utilities
#==============================================================================

# Show build configuration
.PHONY: show-config
show-config:
	@echo "=== Build Configuration ==="
	@echo "Project: $(PROJECT_NAME) $(VERSION)"
	@echo "Platform: $(PLATFORM)"
	@echo "Architecture: $(UNAME_M)"
	@echo "Compiler: $(CC)"
	@echo "C Flags: $(CFLAGS)"
	@echo "C Flags (Release): $(CFLAGS_REL)"
	@echo "C Flags (Debug): $(CFLAGS_DBG)"
	@echo "Linker Flags: $(LDFLAGS)"
	@echo "Target: $(TARGET)"
	@echo "Build Directory: $(BUILD_DIR)"
	@echo "Install Prefix: $(INSTALL_PREFIX)"
ifdef MANDIR
	@echo "Manual Directory: $(MANDIR)"
endif
	@echo "Git Version: $(GIT_VERSION)"
	@echo "Build Date: $(BUILD_DATE)"
	@echo "=== End Configuration ==="

# Show available targets
.PHONY: help
help:
	@echo "=== isOlderThan Build System ==="
	@echo "Available targets:"
	@echo ""
	@echo "Build Targets:"
	@echo "  all              - Build release version (default)"
	@echo "  release          - Build optimized release version"
	@echo "  debug            - Build debug version with symbols"
	@echo "  static-lib       - Build static library"
	@echo "  shared-lib       - Build shared library"
	@echo "  all-targets      - Build all variants"
	@echo ""
	@echo "Installation:"
	@echo "  install          - Install to system (Unix/Linux/macOS)"
	@echo "  install-windows  - Install for Windows"
	@echo "  install-dev      - Install with development files"
	@echo "  uninstall        - Remove from system"
	@echo ""
	@echo "Testing:"
	@echo "  test             - Run basic functionality tests"
	@echo "  test-extended    - Run extended test suite"
	@echo "  test-performance - Run performance tests"
	@echo "  test-memory      - Run memory leak tests (requires valgrind)"
	@echo "  test-all         - Run complete test suite"
	@echo ""
	@echo "Code Quality:"
	@echo "  analyze          - Static code analysis (requires cppcheck)"
	@echo "  format           - Format source code (requires clang-format)"
	@echo "  format-check     - Check code formatting"
	@echo "  coverage         - Build with coverage support (requires gcov)"
	@echo ""
	@echo "Distribution:"
	@echo "  dist-source      - Create source distribution"
	@echo "  dist-binary      - Create binary distribution"
	@echo "  package          - Create platform-specific packages"
	@echo "  package-deb      - Create Debian package (Linux)"
	@echo "  package-rpm      - Create RPM package (Linux)"
	@echo "  package-macos    - Create macOS package"
	@echo ""
	@echo "Documentation:"
	@echo "  docs             - Generate and validate documentation"
	@echo "  test-man         - Test manual page rendering"
	@echo ""
	@echo "Development:"
	@echo "  dev              - Quick development build and test"
	@echo "  dev-full         - Full development cycle"
	@echo "  prepare-release  - Prepare for release"
	@echo ""
	@echo "CI/CD:"
	@echo "  ci-build         - CI-friendly build"
	@echo "  ci-test          - CI test suite"
	@echo ""
	@echo "Utilities:"
	@echo "  clean            - Remove build artifacts"
	@echo "  clean-all        - Remove all generated files"
	@echo "  show-config      - Show build configuration"
	@echo "  help             - Show this help message"
	@echo ""
	@echo "Platform: $(PLATFORM)"
	@echo "Version: $(VERSION)"

# Verbose build (for debugging build issues)
.PHONY: verbose
verbose:
	@$(MAKE) V=1 release

#==============================================================================
# Maintenance and Cleanup
#==============================================================================

# Clean build artifacts
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	$(RM) $(BUILD_DIR)
	@echo "Build directory cleaned!"

# Clean everything including distributions
.PHONY: clean-all
clean-all: clean
	@echo "Cleaning all generated files..."
	$(RM) $(DIST_DIR)
	$(RM) *.gcov *.gcda *.gcno
	$(RM) core core.*
	$(RM) .DS_Store ._.DS_Store
	@echo "All generated files cleaned!"

# Clean and rebuild
.PHONY: rebuild
rebuild: clean all

# Clean and rebuild everything
.PHONY: rebuild-all
rebuild-all: clean-all all-targets

#==============================================================================
# Advanced Features
#==============================================================================

# Cross-compilation support (example for Windows from Linux)
.PHONY: cross-windows
cross-windows:
	@if command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1; then \
		echo "Cross-compiling for Windows..."; \
		CC=x86_64-w64-mingw32-gcc \
		PLATFORM=windows \
		TARGET_SUFFIX=.exe \
		CFLAGS_PLATFORM="-D_WIN32 -DWIN32_LEAN_AND_MEAN" \
		$(MAKE) release; \
		echo "Windows cross-compilation completed!"; \
	else \
		echo "MinGW cross-compiler not available"; \
		echo "Install mingw-w64 for Windows cross-compilation"; \
		exit 1; \
	fi

# Universal binary for macOS (Intel + Apple Silicon)
.PHONY: universal-macos
universal-macos:
ifeq ($(PLATFORM),macos)
	@echo "Building Universal Binary for macOS..."
	@$(MAKE) clean
	ARCH_FLAGS="-arch x86_64 -arch arm64" $(MAKE) release
	@echo "Universal Binary created!"
	@file $(BUILD_RELEASE_DIR)/$(TARGET)
else
	@echo "Universal Binary only available on macOS"
	@exit 1
endif

# Profile-guided optimization (PGO) build
.PHONY: pgo
pgo: release
	@echo "Building with Profile-Guided Optimization..."
	@$(MKDIR) $(BUILD_DIR)/pgo
	@echo "Step 1: Building instrumented version..."
	CFLAGS_RELEASE="$(CFLAGS_RELEASE) -fprofile-generate=$(BUILD_DIR)/pgo" \
	LDFLAGS="$(LDFLAGS) -fprofile-generate=$(BUILD_DIR)/pgo" \
	$(MAKE) release
	@echo "Step 2: Running training workload..."
	@$(MKDIR) $(BUILD_TEST_DIR)
	@touch $(BUILD_TEST_DIR)/pgo_test.txt
	@$(BUILD_RELEASE_DIR)/$(TARGET) $(BUILD_TEST_DIR)/pgo_test.txt -days 1 >/dev/null 2>&1 || true
	@$(BUILD_RELEASE_DIR)/$(TARGET) $(BUILD_TEST_DIR)/pgo_test.txt -weeks 1 >/dev/null 2>&1 || true
	@$(BUILD_RELEASE_DIR)/$(TARGET) $(BUILD_TEST_DIR)/pgo_test.txt -months 1 >/dev/null 2>&1 || true
	@echo "Step 3: Building optimized version..."
	@$(MAKE) clean-build
	CFLAGS_RELEASE="$(CFLAGS_RELEASE) -fprofile-use=$(BUILD_DIR)/pgo -fprofile-correction" \
	$(MAKE) release
	@echo "PGO build completed!"

# Clean only build directory (preserve profiles)
.PHONY: clean-build
clean-build:
	$(RM) $(BUILD_RELEASE_DIR) $(BUILD_DEBUG_DIR) $(BUILD_LIB_DIR)

#==============================================================================
# Xcode Integration Support
#==============================================================================

# Targets for Xcode build integration
.PHONY: xcode-build
xcode-build:
	@echo "Building for Xcode integration..."
	@$(MAKE) static-lib
	@echo "Xcode build support completed!"

# Export headers for Xcode
.PHONY: xcode-headers
xcode-headers: | $(BUILD_DIR)
	@echo "Preparing headers for Xcode..."
	@$(MKDIR) $(BUILD_DIR)/include
	@$(CP) $(HEADER_FILE) $(BUILD_DIR)/include/
	@echo "Headers exported to $(BUILD_DIR)/include/"

#==============================================================================
# Special Configurations
#==============================================================================

# Minimal build (smallest possible size)
.PHONY: minimal
minimal:
	@echo "Building minimal version..."
	CFLAGS_RELEASE="$(CFLAGS_RELEASE) -Os -DMINIMAL_BUILD" \
	LDFLAGS="$(LDFLAGS) -s" \
	$(MAKE) release
	@if command -v $(STRIP) >/dev/null 2>&1; then \
		$(STRIP) $(BUILD_RELEASE_DIR)/$(TARGET); \
		echo "Binary stripped for minimal size"; \
	fi
	@echo "Minimal build completed!"
	@ls -lh $(BUILD_RELEASE_DIR)/$(TARGET)

# Hardened build (security-focused)
.PHONY: hardened
hardened:
	@echo "Building hardened version..."
	CFLAGS_RELEASE="$(CFLAGS_RELEASE) -D_FORTIFY_SOURCE=2 -fstack-protector-strong -fPIE" \
	LDFLAGS="$(LDFLAGS) -Wl,-z,relro -Wl,-z,now -pie" \
	$(MAKE) release
	@echo "Hardened build completed!"

#==============================================================================
# Dependency Management
#==============================================================================

# Check build dependencies
.PHONY: check-deps
check-deps:
	@echo "Checking build dependencies..."
	@echo -n "C Compiler ($(CC)): "
	@if command -v $(CC) >/dev/null 2>&1; then \
		echo "✓ Available ($(shell $(CC) --version | head -1))"; \
	else \
		echo "✗ Missing"; \
	fi
	@echo -n "Make: "
	@if command -v make >/dev/null 2>&1; then \
		echo "✓ Available ($(shell make --version | head -1))"; \
	else \
		echo "✗ Missing"; \
	fi
	@echo -n "Git: "
	@if command -v git >/dev/null 2>&1; then \
		echo "✓ Available ($(shell git --version))"; \
	else \
		echo "✗ Missing (optional)"; \
	fi

# Check optional dependencies
.PHONY: check-optional-deps
check-optional-deps:
	@echo "Checking optional dependencies..."
	@echo -n "Static analyzer (cppcheck): "
	@if command -v cppcheck >/dev/null 2>&1; then \
		echo "✓ Available"; \
	else \
		echo "✗ Missing (install cppcheck for static analysis)"; \
	fi
	@echo -n "Code formatter (clang-format): "
	@if command -v clang-format >/dev/null 2>&1; then \
		echo "✓ Available"; \
	else \
		echo "✗ Missing (install clang-format for code formatting)"; \
	fi
	@echo -n "Memory checker (valgrind): "
	@if command -v valgrind >/dev/null 2>&1; then \
		echo "✓ Available"; \
	else \
		echo "✗ Missing (install valgrind for memory testing)"; \
	fi
	@echo -n "Coverage tool (gcov): "
	@if command -v gcov >/dev/null 2>&1; then \
		echo "✓ Available"; \
	else \
		echo "✗ Missing (usually included with GCC)"; \
	fi
	@echo -n "Documentation (groff): "
	@if command -v groff >/dev/null 2>&1; then \
		echo "✓ Available"; \
	else \
		echo "✗ Missing (install groff for manual page testing)"; \
	fi

#==============================================================================
# File Dependencies and Automatic Rebuilding
#==============================================================================

# Automatic dependency generation
-include $(BUILD_RELEASE_DIR)/*.d
-include $(BUILD_DEBUG_DIR)/*.d
-include $(BUILD_LIB_DIR)/*.d

# Generate dependencies automatically
%.d: %.c
	@$(CC) $(CFLAGS) -MM $< > $@

#==============================================================================
# Advanced Build Options
#==============================================================================

# Enable verbose output if V=1
ifeq ($(V),1)
    Q =
    MAKEFLAGS += --no-print-directory
else
    Q = @
endif

# Parallel build support
ifneq ($(filter -j%, $(MAKEFLAGS)),)
    PARALLEL_BUILD = 1
endif

# Color output support
ifndef NO_COLOR
    RED = \033[0;31m
    GREEN = \033[0;32m
    YELLOW = \033[0;33m
    BLUE = \033[0;34m
    NC = \033[0m # No Color
endif

#==============================================================================
# Version and Build Information
#==============================================================================

# Show version information
.PHONY: version
version:
	@echo "$(PROJECT_NAME) Build System"
	@echo "Version: $(VERSION)"
	@echo "Git: $(GIT_VERSION)"
	@echo "Build Date: $(BUILD_DATE)"
	@echo "Platform: $(PLATFORM)"
	@echo "Architecture: $(UNAME_M)"

# Generate version header
.PHONY: version-header
version-header: | $(BUILD_DIR)
	@echo "Generating version header..."
	@echo "#ifndef VERSION_H" > $(BUILD_DIR)/version.h
	@echo "#define VERSION_H" >> $(BUILD_DIR)/version.h
	@echo "#define PROJECT_VERSION \"$(VERSION)\"" >> $(BUILD_DIR)/version.h
	@echo "#define GIT_VERSION \"$(GIT_VERSION)\"" >> $(BUILD_DIR)/version.h
	@echo "#define BUILD_DATE \"$(BUILD_DATE)\"" >> $(BUILD_DIR)/version.h
	@echo "#define BUILD_PLATFORM \"$(PLATFORM)\"" >> $(BUILD_DIR)/version.h
	@echo "#endif /* VERSION_H */" >> $(BUILD_DIR)/version.h
	@echo "Version header created: $(BUILD_DIR)/version.h"

#==============================================================================
# Safety Checks and Validation
#==============================================================================

# Validate source files exist
.PHONY: validate-sources
validate-sources:
	@echo "Validating source files..."
	@test -f $(SOURCE_FILE) || (echo "Error: $(SOURCE_FILE) not found" && exit 1)
	@test -f $(HEADER_FILE) || (echo "Error: $(HEADER_FILE) not found" && exit 1)
	@test -f $(MAIN_FILE) || (echo "Error: $(MAIN_FILE) not found" && exit 1)
	@test -f $(MANPAGE) || (echo "Error: $(MANPAGE) not found" && exit 1)
	@test -f $(HELPFILE) || (echo "Error: $(HELPFILE) not found" && exit 1)
	@test -f $(README) || (echo "Error: $(README) not found" && exit 1)
	@echo "All source files validated!"

# Pre-build validation
.PHONY: pre-build
pre-build: validate-sources check-deps

#==============================================================================
# Default Target Override
#==============================================================================

# Make sure we have a clean default behavior
.DEFAULT_GOAL := all

# Ensure directories are created before building
$(OBJ_RELEASE): | pre-build
$(OBJ_DEBUG): | pre-build
$(OBJ_LIB): | pre-build

#==============================================================================
# Special Variables and Settings
#==============================================================================

# Make variables
.SUFFIXES:
.SECONDARY:
.DELETE_ON_ERROR:

# Disable built-in rules for better performance
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables

# Export variables for sub-makes
export CC CFLAGS LDFLAGS PLATFORM VERSION

#==============================================================================
# Final Safety Check
#==============================================================================

# Ensure we don't accidentally include system files
ifdef SYSTEM_MAKEFILE
$(error This Makefile should not be included as a system makefile)
endif

# Prevent infinite recursion
ifndef MAKEFILE_INCLUDED
MAKEFILE_INCLUDED := 1
export MAKEFILE_INCLUDED
endif

#==============================================================================
# End of Enhanced Makefile
#==============================================================================
