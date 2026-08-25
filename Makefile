.DEFAULT_GOAL := help
SUBMAKE := $(MAKE) --no-print-directory

FVM_FLUTTER_SDK := $(wildcard $(CURDIR)/.fvm/flutter_sdk)
FLUTTER := $(if $(FVM_FLUTTER_SDK),$(FVM_FLUTTER_SDK)/bin/flutter,flutter)
DART := $(if $(FVM_FLUTTER_SDK),$(FVM_FLUTTER_SDK)/bin/dart,dart)

PROJECT_NAME := ios_window_control_layout
EXAMPLE_DIR := example
IOS_WORKSPACE := $(EXAMPLE_DIR)/ios/Runner.xcworkspace
IOS_SCHEME := Runner
MARKDOWNLINT_VERSION := 0.22.1
NPM_CACHE := $(CURDIR)/.dart_tool/npm-cache

# Test mode flags:
#   make test
#   make test CI=1
#   make test CI=1 MACHINE_OUT=<file>
CI ?= 0
MACHINE_OUT ?=

# Optional simulator override for iOS XCTest and integration tests.
DEVICE ?=

DART_DIRS := lib test tool $(EXAMPLE_DIR)/lib $(EXAMPLE_DIR)/test \
             $(EXAMPLE_DIR)/integration_test

.PHONY: help bootstrap format format-check fix analyze mdlint sync-version test \
        test-ios test-integration publish-check check aio aio-full

help:
	@echo "$(PROJECT_NAME) — automation entrypoints"
	@echo
	@echo "  bootstrap        Resolve root and example dependencies"
	@echo "  format           Format maintained Dart sources"
	@echo "  format-check     Verify Dart formatting without modifying files"
	@echo "  fix              Apply Dart fixes, then format"
	@echo "  analyze          Run Flutter static analysis"
	@echo "  mdlint           Lint maintained Markdown files"
	@echo "  sync-version     Sync pubspec version to the iOS podspec"
	@echo "  test             Run Flutter unit and widget tests"
	@echo "  publish-check    Validate the pub.dev package without publishing"
	@echo "  check            Run formatting, lint, analysis, and tests"
	@echo "  aio              Apply fixes, then run Dart checks and tests"
	@echo "  aio-full         Run aio plus all native unit tests"
	@echo
	@echo "Device tests:"
	@echo "  test-ios         Run iOS XCTest (optional DEVICE=<simulator id>)"
	@echo "  test-integration Run Flutter integration tests (optional DEVICE=<id>)"

bootstrap:
	@$(FLUTTER) pub get
	@cd $(EXAMPLE_DIR) && $(FLUTTER) pub get

format:
	@$(DART) format $(DART_DIRS)

format-check:
	@$(DART) format --output=none --set-exit-if-changed $(DART_DIRS)

fix:
	@$(DART) fix --apply
	@$(SUBMAKE) format

analyze:
	@$(FLUTTER) analyze

mdlint:
	@npm_config_cache=$(NPM_CACHE) \
		npx --yes markdownlint-cli2@$(MARKDOWNLINT_VERSION)

sync-version:
	@VERSION=$$($(DART) run tool/sync_version.dart) && \
		echo "Synced podspec version to $$VERSION"

test:
ifneq ($(MACHINE_OUT),)
	@$(FLUTTER) test --machine > $(MACHINE_OUT)
else ifeq ($(CI),1)
	@$(FLUTTER) test --reporter github
else
	@$(FLUTTER) test
endif

test-ios:
	@cd $(EXAMPLE_DIR) && $(FLUTTER) build ios --config-only --simulator
	@DEVICE_ID="$(DEVICE)"; \
	if [ -z "$$DEVICE_ID" ]; then \
		DEVICE_ID=$$(xcrun simctl list devices available iPhone \
			| awk '/^-- iOS (2[6-9]|[3-9][0-9])/{eligible=1; next} eligible' \
			| grep -m 1 -o '[A-F0-9]\{8\}-[A-F0-9]\{4\}-[A-F0-9]\{4\}-[A-F0-9]\{4\}-[A-F0-9]\{12\}'); \
	fi; \
	if [ -z "$$DEVICE_ID" ]; then \
		echo "ERROR: no iOS 26+ simulator is available"; \
		exit 1; \
	fi; \
	xcodebuild test \
		-workspace $(IOS_WORKSPACE) \
		-scheme $(IOS_SCHEME) \
		-destination "platform=iOS Simulator,id=$$DEVICE_ID" \
		-derivedDataPath /tmp/$(PROJECT_NAME)-derived-data \
		CODE_SIGNING_ALLOWED=NO

test-integration:
	@cd $(EXAMPLE_DIR) && $(FLUTTER) test integration_test \
		$(if $(DEVICE),-d $(DEVICE),) \
		$(if $(MACHINE_OUT),--machine,$(if $(filter 1,$(CI)),--reporter github,)) \
		$(if $(MACHINE_OUT),> $(abspath $(MACHINE_OUT)),)

publish-check:
	@$(FLUTTER) pub publish --dry-run

check: format-check mdlint analyze test

aio:
	@$(SUBMAKE) fix
	@$(SUBMAKE) check

aio-full:
	@$(SUBMAKE) aio
	@$(SUBMAKE) test-ios DEVICE=$(DEVICE) CI=$(CI)
