# ==============================================================================
# Variables
# ==============================================================================
APP_NAME    := stress-pilot
BINARY_NAME := stress_pilot
VERSION     := 1.0.0
ARCH        := amd64
MAINTAINER  := Long Ly <longhienly112@gmail.com>
DESCRIPTION := A Stress testing application
DEPENDS     := libgtk-3-0 (>= 3.18), libblkid1 (>= 2.27), liblzma5 (>= 5.1), \
               libglib2.0-0, libnss3, libatk1.0-0, libdrm2, libxcomposite1, \
               libxdamage1, libxrandr2, libgbm1
SECTION     := utils
PRIORITY    := optional

# JDK
JDK_URL     := https://aka.ms/download-jdk/microsoft-jdk-25-linux-x64.tar.gz
JDK_ARCHIVE := /tmp/openjdk-25.tar.gz
JDK_EXTRACT := /tmp/jdk-25

# CEF cache
CEF_CACHE_DIR  := $(HOME)/.cache/stress-pilot-build
CEF_CACHE_FILE := $(CEF_CACHE_DIR)/cef_prebuilt.zip
CEF_PLUGIN_DIR := linux/flutter/ephemeral/.plugin_symlinks/webview_cef/linux

# Paths
DIST_ROOT         := dist
PACKAGE_DIR       := $(DIST_ROOT)/$(APP_NAME)_$(VERSION)_$(ARCH)
FLUTTER_BUILD_DIR := build/linux/x64/release/bundle
DEB_FILE          := $(DIST_ROOT)/$(APP_NAME)_$(VERSION)_$(ARCH).deb

ICON_SRC  := $(FLUTTER_BUILD_DIR)/data/flutter_assets/assets/images/logo.png
ICON_DEST := $(PACKAGE_DIR)/usr/share/pixmaps/$(APP_NAME).png

.PHONY: all clean fetch-jdk cache-cef restore-cef build structure files copy permissions deb install lint help

# ==============================================================================
# Default target
# ==============================================================================
all: clean fetch-jdk build structure files copy permissions deb
	@echo ""
	@echo "╔══════════════════════════════════════════════╗"
	@echo "║  Build complete!                             ║"
	@echo "║  Output: $(DEB_FILE)"
	@echo "╚══════════════════════════════════════════════╝"

# ==============================================================================
# 1. Clean previous builds
# ==============================================================================
clean:
	@echo "→ Cleaning previous builds..."
	flutter clean
	rm -rf $(DIST_ROOT)

# ==============================================================================
# 2. Fetch and extract JDK 25
# ==============================================================================
fetch-jdk:
	@echo "→ Fetching JDK 25..."
	@if [ ! -f "$(JDK_ARCHIVE)" ]; then \
		echo "  Downloading JDK 25 GA (Microsoft OpenJDK build)..."; \
		curl -L --fail -o $(JDK_ARCHIVE) $(JDK_URL); \
	else \
		echo "  (cached) $(JDK_ARCHIVE) already exists, skipping download."; \
	fi
	@echo "→ Extracting JDK..."
	@rm -rf $(JDK_EXTRACT)
	@mkdir -p $(JDK_EXTRACT)
	@tar -xzf $(JDK_ARCHIVE) -C $(JDK_EXTRACT) --strip-components=1
	@echo "✅ JDK ready at $(JDK_EXTRACT)"

# ==============================================================================
# 3. Cache CEF binary (run once after first successful build)
# ==============================================================================
cache-cef:
	@echo "→ Caching CEF binary..."
	@mkdir -p $(CEF_CACHE_DIR)
	@if [ -f "$(CEF_PLUGIN_DIR)/prebuilt.zip" ]; then \
		cp $(CEF_PLUGIN_DIR)/prebuilt.zip $(CEF_CACHE_FILE); \
		echo "✅ CEF cached to $(CEF_CACHE_FILE)"; \
	elif [ -f "$(CEF_CACHE_FILE)" ]; then \
		echo "  (already cached) $(CEF_CACHE_FILE)"; \
	else \
		echo "⚠️  CEF prebuilt.zip not found yet. Run a full build first."; \
	fi

# ==============================================================================
# 4. Restore CEF from cache before build
# ==============================================================================
restore-cef:
	@echo "→ Restoring CEF from cache..."
	@if [ -f "$(CEF_CACHE_FILE)" ]; then \
		mkdir -p $(CEF_PLUGIN_DIR); \
		cp $(CEF_CACHE_FILE) $(CEF_PLUGIN_DIR)/prebuilt.zip; \
		echo "✅ CEF restored from cache"; \
	else \
		echo "  No CEF cache found, will download during build."; \
	fi

# ==============================================================================
# 5. Build the Flutter app
# ==============================================================================
build: restore-cef
	@echo "→ Building Flutter app (release)..."
	flutter build linux --release
	@$(MAKE) cache-cef

# ==============================================================================
# 6. Create the directory structure
# ==============================================================================
structure:
	@echo "→ Creating package directory structure..."
	mkdir -p $(PACKAGE_DIR)/DEBIAN
	mkdir -p $(PACKAGE_DIR)/opt/$(BINARY_NAME)
	mkdir -p $(PACKAGE_DIR)/usr/share/applications
	mkdir -p $(PACKAGE_DIR)/usr/share/pixmaps

# ==============================================================================
# 7. Generate control, desktop, postinst, and prerm files
# ==============================================================================
files:
	@echo "→ Generating DEBIAN/control..."
	@INSTALLED_SIZE=$$(du -sk $(FLUTTER_BUILD_DIR) | cut -f1); \
	echo "Package: $(APP_NAME)"              > $(PACKAGE_DIR)/DEBIAN/control; \
	echo "Version: $(VERSION)"             >> $(PACKAGE_DIR)/DEBIAN/control; \
	echo "Architecture: $(ARCH)"           >> $(PACKAGE_DIR)/DEBIAN/control; \
	echo "Maintainer: $(MAINTAINER)"       >> $(PACKAGE_DIR)/DEBIAN/control; \
	echo "Installed-Size: $$INSTALLED_SIZE" >> $(PACKAGE_DIR)/DEBIAN/control; \
	echo "Depends: $(DEPENDS)"             >> $(PACKAGE_DIR)/DEBIAN/control; \
	echo "Section: $(SECTION)"             >> $(PACKAGE_DIR)/DEBIAN/control; \
	echo "Priority: $(PRIORITY)"           >> $(PACKAGE_DIR)/DEBIAN/control; \
	echo "Description: $(DESCRIPTION)"     >> $(PACKAGE_DIR)/DEBIAN/control

	@echo "→ Generating .desktop entry..."
	@echo "[Desktop Entry]"                                           > $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop
	@echo "Version=1.0"                                              >> $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop
	@echo "Type=Application"                                         >> $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop
	@echo "Name=Stress Pilot"                                        >> $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop
	@echo "Comment=$(DESCRIPTION)"                                   >> $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop
	@echo "Exec=/opt/$(BINARY_NAME)/$(BINARY_NAME)"                  >> $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop
	@echo "Icon=$(APP_NAME)"                                         >> $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop
	@echo "Terminal=false"                                           >> $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop
	@echo "Categories=Utility;"                                      >> $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop
	@echo "StartupNotify=true"                                       >> $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop

	@echo "→ Generating DEBIAN/postinst..."
	@echo "#!/bin/bash"                                                                      > $(PACKAGE_DIR)/DEBIAN/postinst
	@echo "set -e"                                                                          >> $(PACKAGE_DIR)/DEBIAN/postinst
	@echo ""                                                                                >> $(PACKAGE_DIR)/DEBIAN/postinst
	@echo "# Make bundled JDK executable"                                                   >> $(PACKAGE_DIR)/DEBIAN/postinst
	@echo "find /opt/$(BINARY_NAME)/jdk/bin -type f -exec chmod 755 {} \;"                 >> $(PACKAGE_DIR)/DEBIAN/postinst
	@echo "find /opt/$(BINARY_NAME)/jdk/lib -name '*.so*' -exec chmod 644 {} \; || true"  >> $(PACKAGE_DIR)/DEBIAN/postinst
	@echo ""                                                                                >> $(PACKAGE_DIR)/DEBIAN/postinst
	@echo "update-desktop-database /usr/share/applications || true"                        >> $(PACKAGE_DIR)/DEBIAN/postinst
	@echo "gtk-update-icon-cache /usr/share/pixmaps || true"                               >> $(PACKAGE_DIR)/DEBIAN/postinst

	@echo "→ Generating DEBIAN/prerm..."
	@echo "#!/bin/bash"                                                                      > $(PACKAGE_DIR)/DEBIAN/prerm
	@echo "set -e"                                                                          >> $(PACKAGE_DIR)/DEBIAN/prerm
	@echo "update-desktop-database /usr/share/applications || true"                        >> $(PACKAGE_DIR)/DEBIAN/prerm

# ==============================================================================
# 8. Copy build files, JDK, and icon
# ==============================================================================
copy:
	@echo "→ Copying Flutter build files..."
	cp -r $(FLUTTER_BUILD_DIR)/* $(PACKAGE_DIR)/opt/$(BINARY_NAME)/

	@echo "→ Bundling JDK 25..."
	mkdir -p $(PACKAGE_DIR)/opt/$(BINARY_NAME)/jdk
	cp -r $(JDK_EXTRACT)/* $(PACKAGE_DIR)/opt/$(BINARY_NAME)/jdk/

	@echo "→ Copying icon..."
	@if [ -f "$(ICON_SRC)" ]; then \
		cp $(ICON_SRC) $(ICON_DEST); \
	else \
		echo "⚠️  Warning: icon not found at $(ICON_SRC), skipping."; \
	fi

# ==============================================================================
# 9. Set permissions
# ==============================================================================
permissions:
	@echo "→ Setting permissions..."
	chmod 644 $(PACKAGE_DIR)/DEBIAN/control
	chmod 755 $(PACKAGE_DIR)/DEBIAN/postinst
	chmod 755 $(PACKAGE_DIR)/DEBIAN/prerm
	chmod +x  $(PACKAGE_DIR)/opt/$(BINARY_NAME)/$(BINARY_NAME)
	find $(PACKAGE_DIR)/opt/$(BINARY_NAME)/lib -name "*.so*" -exec chmod 644 {} \; 2>/dev/null || true
	find $(PACKAGE_DIR)/opt/$(BINARY_NAME)/jdk/bin -type f -exec chmod 755 {} \;
	find $(PACKAGE_DIR)/opt/$(BINARY_NAME)/jdk/lib -name "*.so*" -exec chmod 644 {} \; 2>/dev/null || true

# ==============================================================================
# 10. Build the .deb package
# ==============================================================================
deb:
	@echo "→ Building .deb package..."
	fakeroot dpkg-deb --build $(PACKAGE_DIR)
	@echo "✅ Package ready: $(DEB_FILE)"

# ==============================================================================
# Optional: Lint the package
# ==============================================================================
lint:
	@echo "→ Running lintian..."
	@if command -v lintian &> /dev/null; then \
		lintian $(DEB_FILE) || true; \
	else \
		echo "⚠️  lintian not installed. Run: sudo apt install lintian"; \
	fi

# ==============================================================================
# Optional: Install locally for testing
# ==============================================================================
install:
	sudo dpkg -i $(DEB_FILE)

# ==============================================================================
# Help
# ==============================================================================
help:
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "  all          Full build pipeline (default)"
	@echo "  clean        Remove dist/ and flutter build cache"
	@echo "  fetch-jdk    Download and extract JDK 25 to /tmp"
	@echo "  restore-cef  Restore CEF binary from ~/.cache"
	@echo "  cache-cef    Save CEF binary to ~/.cache (auto-runs after build)"
	@echo "  build        Run flutter build linux --release"
	@echo "  structure    Create package directory layout"
	@echo "  files        Generate control, desktop, postinst files"
	@echo "  copy         Copy build output + JDK into package"
	@echo "  permissions  Set correct file permissions"
	@echo "  deb          Package into .deb file"
	@echo "  lint         Run lintian on the .deb (optional)"
	@echo "  install      Install .deb locally for testing"
	@echo ""