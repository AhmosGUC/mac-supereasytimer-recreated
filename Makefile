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

icon:
	@echo "not implemented yet (#13)"; exit 78

clean:
	rm -rf .build dist
