include config.env

.PHONY: test build app run install uninstall purge previews icon dist clean

test:
	swift test

build:
	swift build -c debug

app:
	@echo "not implemented yet (#14)"; exit 78

run: app
	open dist/$(APP_NAME).app

install uninstall purge dist:
	@echo "not implemented yet (#14)"; exit 78

previews:
	@echo "not implemented yet (#8)"; exit 78

ICON_DIR = .build/icon

icon:
	swift scripts/make-icon.swift $(ICON_DIR)/AppIcon.iconset
	iconutil -c icns -o $(ICON_DIR)/AppIcon.icns $(ICON_DIR)/AppIcon.iconset
	mkdir -p docs/images
	cp $(ICON_DIR)/AppIcon.iconset/icon_512x512@2x.png docs/images/icon-1024.png

clean:
	rm -rf .build dist
