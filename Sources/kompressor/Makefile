NAME = kompressor
SWIFT_BUILD_FLAGS = -c release --arch arm64 --arch x86_64
BUILD_DIR = .build/apple/Products/Release
BINARY = $(BUILD_DIR)/$(NAME)

# Standard-Ziel
all: build

# Erstellt die Release-Binärdatei für macOS (Universal Binary)
build:
	@echo "--> Creating $(NAME) for Release..."
	@swift build $(SWIFT_BUILD_FLAGS)
	@echo "--> Created: $(BINARY)"

# Führt Tests aus
test:
	@echo "--> Executing Tests..."
	@swift test

# Installiert die Binärdatei und Shell-Vervollständigungen
# Verwendung: make install PREFIX=/pfad/zur/installation
PREFIX ?= /usr/local
install: build
	@echo "--> Installing $(NAME) to $(PREFIX)/bin..."
	@mkdir -p "$(PREFIX)/bin"
	@cp "$(BINARY)" "$(PREFIX)/bin/$(NAME)"
	@echo "--> Generating and installing Shell-Completions..."
	@mkdir -p "$(PREFIX)/share/bash/completion"
	@mkdir -p "$(PREFIX)/share/zsh/site-functions"
	@mkdir -p "$(PREFIX)/share/fish/vendor_completions.d"
	@"$(BINARY)" --generate-completion-script bash > "$(PREFIX)/share/bash/completion/$(NAME).bash"
	@"$(BINARY)" --generate-completion-script zsh > "$(PREFIX)/share/zsh/site-functions/_$(NAME)"
	@"$(BINARY)" --generate-completion-script fish > "$(PREFIX)/share/fish/vendor_completions.d/$(NAME).fish"
	@echo "--> Installation completed."

# Deinstalliert die Binärdatei und Vervollständigungen
uninstall:
	@echo "--> Removing $(NAME) from $(PREFIX)/bin..."
	@rm -f "$(PREFIX)/bin/$(NAME)"
	@echo "--> Uninstalling Shell-Completions..."
	@rm -f "$(PREFIX)/share/bash/completion/$(NAME).bash"
	@rm -f "$(PREFIX)/share/zsh/site-functions/_$(NAME)"
	@rm -f "$(PREFIX)/share/fish/vendor_completions.d/$(NAME).fish"
	@echo "--> Deinstallation completed."

# Bereinigt Build-Artefakte
clean:
	@echo "--> cleaing up build artifacts..."
	@swift package clean

.PHONY: all build test install uninstall clean
