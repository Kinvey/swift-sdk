CONFIGURATION?=Release
VERSION=$(shell /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${PWD}/Kinvey/Kinvey/Info.plist")
CURRENT_BRANCH=$(shell git branch | awk '{split($$0, array, " "); if (array[1] == "*") print array[2]}')
DEVCENTER_GIT=git@github.com:Kinvey/devcenter.git
DEVCENTER_GIT_TEST=https://git.heroku.com/v3yk1n-devcenter.git
DEVCENTER_GIT_PROD=https://git.heroku.com/kinvey-devcenter-prod.git
CARTFILE_RESOLVED_MD5=$(shell { cat Cartfile.resolved; swift --version | sed -e "s/Apple //" | head -1 | awk '{ print "Swift " $$3 }'; } | tr "\n" "\n" | md5)
DESTINATION_OS?=13.5
DESTINATION_NAME?=iPhone 11 Pro
ECHO?=no
GREEN=\033[0;32m
RED=\033[0;31m
YELLOW=\033[1;33m
NC=\033[0m

all: build archive pack docs

deploy: deploy-git deploy-aws-s3 deploy-github deploy-cocoapods deploy-docs deploy-devcenter

release: all deploy

clean:
	rm -Rf docs
	rm -Rf build
	rm -Rf Carthage

open:
	@open Kinvey.xcworkspace 

echo:
	@echo $(ECHO)

checkout-dependencies:
	carthage checkout

build-debug:
	xcodebuild -workspace Kinvey.xcworkspace -scheme Kinvey -configuration Debug BUILD_DIR=build ONLY_ACTIVE_ARCH=NO -sdk iphoneos
	xcodebuild -workspace Kinvey.xcworkspace -scheme Kinvey -configuration Debug BUILD_DIR=build ONLY_ACTIVE_ARCH=NO -sdk iphonesimulator -destination 'platform=iOS Simulator'

show-destinations:
	xcodebuild -workspace Kinvey.xcworkspace -scheme Kinvey -showdestinations

build-dependencies-ios: checkout-dependencies
	carthage build --platform iOS

cartfile-md5:
	@echo $(CARTFILE_RESOLVED_MD5)

cache:
	test -s Carthage/$(CARTFILE_RESOLVED_MD5).tar.lzma || \
	{ \
		cd Carthage; \
		rm *.tar.lzma; \
		curl -L http://download.kinvey.com/iOS/travisci-cache/$(CARTFILE_RESOLVED_MD5).tar.lzma -o $(CARTFILE_RESOLVED_MD5).tar.lzma; \
		tar -xvf $(CARTFILE_RESOLVED_MD5).tar.lzma; \
	}

cache-upload:
	cd Carthage; \
	tar --exclude=Build/**/Kinvey.framework* --lzma -cvf $(CARTFILE_RESOLVED_MD5).tar.lzma Build; \
	aws s3 cp $(CARTFILE_RESOLVED_MD5).tar.lzma s3://kinvey-downloads/iOS/travisci-cache/$(CARTFILE_RESOLVED_MD5).tar.lzma

update-deps:
	carthage update --cache-builds --no-use-binaries --use-xcframeworks

# `--cache-builds` improves build times tremendously. However we need to be careful when doing
# a production build. `--no-use-binaries` builds every dependency from source instead of
# downloading it from the GitHub release. This ensures  correct binaries because it's possible
# that some of the downloaded ones do not contain all platforms that we support
# (e.g. PubNub v4.13.1 is missing tvOS and watchOS)
build-warning:
	@echo "$(YELLOW)warning: $(NC)Building Carthage dependencies with '--cache-builds'. When producing artifacts for a release do it in a clean workspace ('$(GREEN)git clean -fdx$(NC)' or '$(GREEN)make clean$(NC)')"

build: build-warning checkout-dependencies
	carthage build --no-skip-current --cache-builds --no-use-binaries --use-xcframeworks

build-ios: build-warning checkout-dependencies
	carthage build --no-skip-current --cache-builds --no-use-binaries --use-xcframeworks --platform iOS

build-macos: build-warning checkout-dependencies
	carthage build --no-skip-current --cache-builds --no-use-binaries --use-xcframeworks --platform macOS

build-tvos: build-warning checkout-dependencies
	carthage build --no-skip-current --cache-builds --no-use-binaries --use-xcframeworks --platform tvOS

build-watchos: build-warning checkout-dependencies
	carthage build --no-skip-current --cache-builds --no-use-binaries --use-xcframeworks --platform watchOS

archive: archive-ios

archive-ios:
	carthage archive Kinvey

test: test-ios test-macos


test-ios:
	xcodebuild -workspace Kinvey.xcworkspace -scheme Kinvey -destination 'OS=$(DESTINATION_OS),name=$(DESTINATION_NAME)' test -enableCodeCoverage YES

test-macos:
	xcodebuild -workspace Kinvey.xcworkspace -scheme Kinvey-macOS test -enableCodeCoverage YES

pack:
	mkdir -p build/Kinvey-$(VERSION)
	cd Carthage/Build; \
	find . -name "*.framework" ! -name "KIF.framework" ! -name "Nimble.framework" ! -name "Swifter.framework" | awk '{split($$0, array, "/"); system("mkdir -p ../../build/Kinvey-$(VERSION)/" array[2] " && cp -R " array[2] "/" array[3] " ../../build/Kinvey-$(VERSION)/" array[2])}'
	cd build; \
	zip -r Kinvey-$(VERSION).zip Kinvey-$(VERSION)

docs:
	jazzy --author Kinvey \
				--author_url http://www.kinvey.com \
				--module-version $(VERSION) \
				--readme README-API-Reference-Docs.md \
				--min-acl public \
				--theme apple \
				--xcodebuild-arguments -workspace,Kinvey.xcworkspace,-scheme,Kinvey \
				--module Kinvey \
				--output docs

deploy-cocoapods:
	pod trunk push Kinvey.podspec --allow-warnings

test-cocoapods:
	pod spec lint Kinvey.podspec --verbose --no-clean --allow-warnings

deploy-aws-s3:
	aws s3 cp build/Kinvey-$(VERSION).zip s3://kinvey-downloads/iOS/

deploy-github:
	cd scripts/github-release; \
	swift run github-release release ../..

deploy-git:
	@if [ "$(CURRENT_BRANCH)" = "develop" ]; then \
		git-flow release start "$(VERSION)"; \
		GIT_MERGE_AUTOEDIT=no git-flow release finish -n "$(VERSION)"; \
		git push; \
	else \
		echo "Change to 'develop' branch and run again"; \
		exit 1; \
	fi

deploy-docs:
	rm -Rf build/devcenter
	cd build; \
	git clone $(DEVCENTER_GIT)
	cd build/devcenter; \
	git remote add v3yk1n-devcenter $(DEVCENTER_GIT_TEST); \
	git remote add kinvey-devcenter-prod $(DEVCENTER_GIT_PROD)
	rm -Rf build/devcenter/content/reference/ios-v3.0/*
	cp -R docs/** build/devcenter/content/reference/ios-v3.0
	cd build/devcenter; \
	git add content/reference/ios-v3.0; \
	git commit -m "Swift SDK Release $(VERSION) - Reference Docs"; \
	git push origin master; \
	git push v3yk1n-devcenter master; \
	git push kinvey-devcenter-prod master

deploy-devcenter:
	rm -Rf build/devcenter
	cd build; \
	git clone $(DEVCENTER_GIT)
	cd build/devcenter; \
	git remote add v3yk1n-devcenter $(DEVCENTER_GIT_TEST); \
	git remote add kinvey-devcenter-prod $(DEVCENTER_GIT_PROD); \
	git checkout -b feature/Swift_SDK_Release_$(VERSION)
	cd scripts/devcenter-release; \
	swift run devcenter-release $(VERSION) ../../build/devcenter
	cd build/devcenter; \
	git add content; \
	git commit -m "Swift SDK Release $(VERSION) - Release Notes"; \
	git push origin feature/Swift_SDK_Release_$(VERSION)

show-version:
	@/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${PWD}/Kinvey/Kinvey/Info.plist" | xargs echo 'Info.plist    '
	@cat Kinvey.podspec | grep "s.version\s*=\s*\"[0-9]*.[0-9]*.[0-9]*\"" | awk {'print $$3'} | sed 's/"//g' | xargs echo 'Kinvey.podspec'
	@agvtool what-version | awk '0 == NR % 2' | awk {'print $1'} | xargs echo 'Project Version  '

set-version:
	@echo 'Current Version:'
	@echo '----------------------'
	@$(MAKE) show-version

	@echo

	@echo 'New Version:'
	@read version; \
	\
	/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $$version" "${PWD}/Kinvey/Kinvey/Info.plist"; \
	sed -i -e "s/s.version[ ]*=[ ]*\"[0-9]*.[0-9]*.[0-9]*\"/s.version      = \"$$version\"/g" Kinvey.podspec; \
	rm Kinvey.podspec-e

	@echo
	@echo

	@echo 'New Version:'
	@echo '----------------------'
	@$(MAKE) show-version
