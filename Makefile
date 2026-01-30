# Variables
APP_NAME := stress-pilot
BINARY_NAME := stress_pilot
VERSION := 1.0.0
ARCH := amd64
MAINTAINER := Long Ly <longhienly112@gmail.com>
DESCRIPTION := A Stress testing application
DEPENDS := libgtk-3-0, libblkid1, liblzma5

# Paths
DIST_ROOT := dist
PACKAGE_DIR := $(DIST_ROOT)/$(APP_NAME)_$(VERSION)_$(ARCH)
FLUTTER_BUILD_DIR := build/linux/x64/release/bundle

.PHONY: all clean build structure files copy permissions deb install

# Default target: Runs the full sequence
all: clean build structure files copy permissions deb

# 1. Clean previous builds
clean:
	flutter clean
	rm -rf $(DIST_ROOT)

# 2. Build the Flutter app
build:
	flutter build linux --release

# 3. Create the directory structure
structure:
	mkdir -p $(PACKAGE_DIR)/DEBIAN
	mkdir -p $(PACKAGE_DIR)/opt/$(BINARY_NAME)
	mkdir -p $(PACKAGE_DIR)/usr/share/applications

# 4. Generate 'control' and '.desktop' files dynamically
files:
	# --- Generating Control File ---
	@echo "Package: $(APP_NAME)" > $(PACKAGE_DIR)/DEBIAN/control
	@echo "Version: $(VERSION)" >> $(PACKAGE_DIR)/DEBIAN/control
	@echo "Architecture: $(ARCH)" >> $(PACKAGE_DIR)/DEBIAN/control
	@echo "Maintainer: $(MAINTAINER)" >> $(PACKAGE_DIR)/DEBIAN/control
	@echo "Description: $(DESCRIPTION)" >> $(PACKAGE_DIR)/DEBIAN/control
	@echo "Depends: $(DEPENDS)" >> $(PACKAGE_DIR)/DEBIAN/control

	# --- Generating Desktop Entry ---
	@echo "[Desktop Entry]" > $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop
	@echo "Version=1.0" >> $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop
	@echo "Type=Application" >> $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop
	@echo "Name=Stress Pilot" >> $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop
	@echo "Comment=$(DESCRIPTION)" >> $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop
	@echo "Exec=/opt/$(BINARY_NAME)/$(BINARY_NAME)" >> $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop
	@echo "Icon=/opt/$(BINARY_NAME)/data/flutter_assets/assets/images/logo.png" >> $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop
	@echo "Terminal=false" >> $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop
	@echo "Categories=Utility;" >> $(PACKAGE_DIR)/usr/share/applications/$(APP_NAME).desktop

# 5. Copy the build files to the package directory
copy:
	cp -r $(FLUTTER_BUILD_DIR)/* $(PACKAGE_DIR)/opt/$(BINARY_NAME)/

# 6. Set executable permissions
permissions:
	chmod 755 $(PACKAGE_DIR)/DEBIAN/control
	chmod +x $(PACKAGE_DIR)/opt/$(BINARY_NAME)/$(BINARY_NAME)

# 7. Build the .deb package
deb:
	dpkg-deb --build $(PACKAGE_DIR)
	@echo "✅ Build complete: $(DIST_ROOT)/$(APP_NAME)_$(VERSION)_$(ARCH).deb"

# Optional: Install the package locally for testing
install:
	sudo dpkg -i $(DIST_ROOT)/$(APP_NAME)_$(VERSION)_$(ARCH).deb