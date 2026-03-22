# ==============================================================================
# Variables
# ==============================================================================
APP_NAME    := stress-pilot
BINARY_NAME := stress_pilot
VERSION     := 1.0.2
ARCH        := amd64
MAINTAINER  := Long Ly <longhienly112@gmail.com>
DESCRIPTION := A Stress testing application
DEPENDS     := libgtk-3-0 (>= 3.18), libblkid1 (>= 2.27), liblzma5 (>= 5.1)
SECTION     := utils
PRIORITY    := optional

# JDK Linux
JDK_URL     := https://aka.ms/download-jdk/microsoft-jdk-25-linux-x64.tar.gz
JDK_ARCHIVE := /tmp/openjdk-25.tar.gz
JDK_EXTRACT := /tmp/jdk-25

# JDK Windows
JDK_WIN_URL     := https://aka.ms/download-jdk/microsoft-jdk-25-windows-x64.zip
JDK_WIN_ARCHIVE := build/jdk25.zip
JDK_WIN_EXTRACT := build/jdk-win

# Paths
DIST_ROOT         := dist
PACKAGE_DIR       := $(DIST_ROOT)/$(APP_NAME)_$(VERSION)_$(ARCH)
FLUTTER_BUILD_DIR := build/linux/x64/release/bundle
RELEASE_DIR       := build/windows/x64/runner/Release
ISS_FILE          := inno-script.iss
INNO_COMPILER     := $(subst \,/,$(LOCALAPPDATA))/Programs/Inno Setup 6/ISCC.exe
DEB_FILE          := $(DIST_ROOT)/$(APP_NAME)_$(VERSION)_$(ARCH).deb

ICON_SRC  := $(FLUTTER_BUILD_DIR)/data/flutter_assets/assets/images/logo.png
ICON_DEST := $(PACKAGE_DIR)/usr/share/pixmaps/$(APP_NAME).png

.PHONY: all build-windows build-linux \
        clean fetch-jdk fetch-jdk-win flutter-build-linux structure files copy permissions deb \
        install lint clean-cache nuke help

# ==============================================================================
# Default: show help
# ==============================================================================
all: help

# ==============================================================================
# Windows build pipeline
# ==============================================================================
build-windows: fetch-jdk-win
	flutter build windows --release
	@echo "Bundling JDK to $(RELEASE_DIR)/jdk..."
	@powershell -Command "if (Test-Path '$(RELEASE_DIR)/jdk') { Remove-Item -Recurse -Force '$(RELEASE_DIR)/jdk' }; New-Item -ItemType Directory -Path '$(RELEASE_DIR)/jdk' -Force"
	@powershell -Command "Copy-Item -Path '$(JDK_WIN_EXTRACT)/*' -Destination '$(RELEASE_DIR)/jdk/' -Recurse -Force"
	"$(INNO_COMPILER)" "$(ISS_FILE)"
	@echo Build complete (Windows)

fetch-jdk-win:
	@echo "Fetching Windows JDK 25..."
	@powershell -Command "if (!(Test-Path 'build')) { New-Item -ItemType Directory -Path 'build' }"
	@powershell -Command "if (!(Test-Path '$(JDK_WIN_ARCHIVE)')) { echo 'Downloading JDK 25 for Windows...'; curl.exe -L --fail -o '$(JDK_WIN_ARCHIVE)' '$(JDK_WIN_URL)' } else { echo '(cached) $(JDK_WIN_ARCHIVE) already exists, skipping.' }"
	@powershell -Command "if (Test-Path '$(JDK_WIN_EXTRACT)') { Remove-Item -Recurse -Force '$(JDK_WIN_EXTRACT)' }"
	@powershell -Command "New-Item -ItemType Directory -Path '$(JDK_WIN_EXTRACT)' -Force"
	@powershell -Command "Expand-Archive -Path '$(JDK_WIN_ARCHIVE)' -DestinationPath '$(JDK_WIN_EXTRACT)' -Force"
	@echo "Flattening Windows JDK..."
	@powershell -Command "$$sub = Get-ChildItem -Path '$(JDK_WIN_EXTRACT)' -Directory | Select-Object -First 1; if ($$sub) { Get-ChildItem $$sub.FullName | Move-Item -Destination '$(JDK_WIN_EXTRACT)' -Force; Remove-Item $$sub.FullName -Recurse -Force }"
	@echo "JDK ready at $(JDK_WIN_EXTRACT)"

# ==============================================================================
# Linux build pipeline
# ==============================================================================
build-linux: fetch-jdk flutter-build-linux structure files copy permissions deb
	@echo "Build complete (Linux)"
	@echo "Output: $(DEB_FILE)"

# ==============================================================================
# Linux steps
# ==============================================================================
fetch-jdk:
	@echo "Fetching JDK 25..."
	@if [ ! -f "$(JDK_ARCHIVE)" ]; then \
		echo "Downloading JDK 25..."; \
		curl -L --fail -o $(JDK_ARCHIVE) $(JDK_URL); \
	else \
		echo "(cached) $(JDK_ARCHIVE) already exists, skipping."; \
	fi
	@rm -rf $(JDK_EXTRACT)
	@mkdir -p $(JDK_EXTRACT)
	@tar -xzf $(JDK_ARCHIVE) -C $(JDK_EXTRACT) --strip-components=1
	@echo "JDK ready at $(JDK_EXTRACT)"

flutter-build-linux:
	flutter build linux --release

structure:
	mkdir -p $(PACKAGE_DIR)/DEBIAN
	mkdir -p $(PACKAGE_DIR)/opt/$(BINARY_NAME)
	mkdir -p $(PACKAGE_DIR)/usr/share/applications
	mkdir -p $(PACKAGE_DIR)/usr/share/pixmaps

files:
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

	@echo "[Desktop Entry]"                          > $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop
	@echo "Version=1.0"                             >> $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop
	@echo "Type=Application"                        >> $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop
	@echo "Name=Stress Pilot"                       >> $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop
	@echo "Comment=$(DESCRIPTION)"                  >> $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop
	@echo "Exec=/opt/$(BINARY_NAME)/$(BINARY_NAME)" >> $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop
	@echo "Icon=$(APP_NAME)"                        >> $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop
	@echo "Terminal=false"                          >> $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop
	@echo "Categories=Utility;"                     >> $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop
	@echo "StartupNotify=true"                      >> $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop

	@echo "#!/bin/bash"                                                                      > $(PACKAGE_DIR)/DEBIAN/postinst
	@echo "set -e"                                                                          >> $(PACKAGE_DIR)/DEBIAN/postinst
	@echo "find /opt/$(BINARY_NAME)/jdk/bin -type f -exec chmod 755 {} \;"                 >> $(PACKAGE_DIR)/DEBIAN/postinst
	@echo "find /opt/$(BINARY_NAME)/jdk/lib -name '*.so*' -exec chmod 644 {} \; || true"  >> $(PACKAGE_DIR)/DEBIAN/postinst
	@echo "update-desktop-database /usr/share/applications || true"                        >> $(PACKAGE_DIR)/DEBIAN/postinst
	@echo "gtk-update-icon-cache /usr/share/pixmaps || true"                               >> $(PACKAGE_DIR)/DEBIAN/postinst

	@echo "#!/bin/bash"                                                                      > $(PACKAGE_DIR)/DEBIAN/prerm
	@echo "set -e"                                                                          >> $(PACKAGE_DIR)/DEBIAN/prerm
	@echo "update-desktop-database /usr/share/applications || true"                        >> $(PACKAGE_DIR)/DEBIAN/prerm

copy:
	cp -r $(FLUTTER_BUILD_DIR)/* $(PACKAGE_DIR)/opt/$(BINARY_NAME)/
	mkdir -p $(PACKAGE_DIR)/opt/$(BINARY_NAME)/jdk
	cp -r $(JDK_EXTRACT)/* $(PACKAGE_DIR)/opt/$(BINARY_NAME)/jdk/
	@if [ -f "$(ICON_SRC)" ]; then \
		cp $(ICON_SRC) $(ICON_DEST); \
	else \
		echo "WARNING: icon not found at $(ICON_SRC), skipping."; \
	fi

permissions:
	chmod 644 $(PACKAGE_DIR)/DEBIAN/control
	chmod 755 $(PACKAGE_DIR)/DEBIAN/postinst
	chmod 755 $(PACKAGE_DIR)/DEBIAN/prerm
	chmod +x  $(PACKAGE_DIR)/opt/$(BINARY_NAME)/$(BINARY_NAME)
	find $(PACKAGE_DIR)/opt/$(BINARY_NAME)/lib -name "*.so*" -exec chmod 644 {} \; 2>/dev/null || true
	find $(PACKAGE_DIR)/opt/$(BINARY_NAME)/jdk/bin -type f -exec chmod 755 {} \;
	find $(PACKAGE_DIR)/opt/$(BINARY_NAME)/jdk/lib -name "*.so*" -exec chmod 644 {} \; 2>/dev/null || true

deb:
	fakeroot dpkg-deb --build $(PACKAGE_DIR)
	@echo "Package ready: $(DEB_FILE)"

# ==============================================================================
# Optional targets
# ==============================================================================
clean:
	flutter clean
	rm -rf $(DIST_ROOT)

clean-cache:
	@rm -f $(JDK_ARCHIVE)
	@rm -rf $(JDK_EXTRACT)

nuke: clean clean-cache

lint:
	@if command -v lintian &> /dev/null; then \
		lintian $(DEB_FILE) || true; \
	else \
		echo "lintian not installed. Run: sudo apt install lintian"; \
	fi

install:
	sudo dpkg -i $(DEB_FILE)

# ==============================================================================
# Help
# ==============================================================================
help:
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "  make build-windows    Flutter build + copy JDK + compile installer"
	@echo "  make build-linux      Flutter build + fetch JDK + .deb package"
	@echo ""
	@echo "Optional:"
	@echo "  make clean            Remove dist/ and flutter build cache"
	@echo "  make clean-cache      Remove cached JDK (Linux)"
	@echo "  make nuke             Full clean including cache"
	@echo "  make lint             Run lintian on the .deb (Linux)"
	@echo "  make install          Install .deb locally for testing (Linux)"
	@echo ""