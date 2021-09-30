CONFIGURATION?=Release
VERSION=$(shell /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${PWD}/Kinvey/Kinvey/Info.plist")
CURRENT_BRANCH=$(shell git branch | awk '{split($$0, array, " "); if (array[1] == "*") print array[2]}')
DEVCENTER_GIT=git@github.com:Kinvey/devcenter.git
DEVCENTER_GIT_TEST=https://git.heroku.com/v3yk1n-devcenter.git
DEVCENTER_GIT_PROD=https://git.heroku.com/kinvey-devcenter-prod.git
DESTINATION_OS?=15.0
DESTINATION_NAME?=iPhone 13 mini

XCODEBUILD_ARCHIVE_COMMAND=xcodebuild archive -scheme Kinvey -configuration Release SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES ONLY_ACTIVE_ARCH=NO
XCFrameworks=Kinvey.xcframework \
	KeychainAccess.xcframework \
	ObjectMapper.xcframework \
	PromiseKit.xcframework \
	PubNub.xcframework \
	Realm.xcframework \
	RealmSwift.xcframework \
	SwiftyBeaver.xcframework \

ECHO?=no
GREEN=\033[0;32m
RED=\033[0;31m
YELLOW=\033[1;33m
NC=\033[0m

all: build-prod xcframework archive docs

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

show-destinations:
	xcodebuild -workspace Kinvey.xcworkspace -scheme Kinvey -showdestinations

checkout-dependencies:
	carthage checkout
	@sed -i '' 's/EXCLUDED_ARCHS/\/\/EXCLUDED_ARCHS/' Carthage/Checkouts/realm-cocoa/Configuration/Base.xcconfig

update-deps:
	carthage update --cache-builds --no-use-binaries --use-xcframeworks

# `--cache-builds` improves build times tremendously. However we need to be careful when doing
# a production build. `--no-use-binaries` builds every dependency from source instead of
# downloading it from the GitHub release. This ensures  correct binaries because it's possible
# that some of the downloaded ones do not contain all platforms that we support
# (e.g. PubNub v4.13.1 is missing tvOS and watchOS)
build-warning:
	@echo "$(YELLOW)warning: $(NC)Building Carthage dependencies with '--cache-builds'. When producing artifacts for a release do it in a clean workspace ('$(GREEN)git clean -fdx$(NC)' or '$(GREEN)make clean$(NC)')"

build-deps: build-warning checkout-dependencies
	carthage build --cache-builds --no-use-binaries --use-xcframeworks

build-ios: build-warning checkout-dependencies
	carthage build --cache-builds --no-use-binaries --use-xcframeworks --platform iOS

build-macos: build-warning checkout-dependencies
	carthage build --cache-builds --no-use-binaries --use-xcframeworks --platform macOS

build-tvos: build-warning checkout-dependencies
	carthage build --cache-builds --no-use-binaries --use-xcframeworks --platform tvOS

build-watchos: build-warning checkout-dependencies
	carthage build --cache-builds --no-use-binaries --use-xcframeworks --platform watchOS

build-prod:
	@rm -rf .dist/macOS && $(XCODEBUILD_ARCHIVE_COMMAND) -destination 'generic/platform=macOS' -archivePath .dist/macOS/Kinvey.xcarchive -sdk macosx | xcpretty -c
	@rm -rf .dist/iOS && $(XCODEBUILD_ARCHIVE_COMMAND) -destination 'generic/platform=iOS' -archivePath .dist/iOS/Kinvey.xcarchive -sdk iphoneos | xcpretty -c
	@rm -rf .dist/iOSSimulator && $(XCODEBUILD_ARCHIVE_COMMAND) -destination 'generic/platform=iOS Simulator' -archivePath .dist/iOSSimulator/Kinvey.xcarchive -sdk iphonesimulator | xcpretty -c
	@rm -rf .dist/tvOS && $(XCODEBUILD_ARCHIVE_COMMAND) -destination 'generic/platform=tvOS' -archivePath .dist/tvOS/Kinvey.xcarchive -sdk appletvos | xcpretty -c
	@rm -rf .dist/tvOSSimulator && $(XCODEBUILD_ARCHIVE_COMMAND) -destination 'generic/platform=tvOS Simulator' -archivePath .dist/tvOSSimulator/Kinvey.xcarchive -sdk appletvsimulator | xcpretty -c
	@rm -rf .dist/watchOS && $(XCODEBUILD_ARCHIVE_COMMAND) -destination 'generic/platform=watchOS' -archivePath .dist/watchOS/Kinvey.xcarchive -sdk watchos | xcpretty -c
	@rm -rf .dist/watchOSSimulator && $(XCODEBUILD_ARCHIVE_COMMAND) -destination 'generic/platform=watchOS Simulator' -archivePath .dist/watchOSSimulator/Kinvey.xcarchive -sdk watchsimulator | xcpretty -c

xcframework:
	@rm -rf Carthage/Build/Kinvey.xcframework
	xcodebuild -create-xcframework \
		-framework .dist/macOS/Kinvey.xcarchive/Products/Library/Frameworks/Kinvey.framework \
		-framework .dist/iOS/Kinvey.xcarchive/Products/Library/Frameworks/Kinvey.framework \
		-framework .dist/iOSSimulator/Kinvey.xcarchive/Products/Library/Frameworks/Kinvey.framework \
		-framework .dist/tvOS/Kinvey.xcarchive/Products/Library/Frameworks/Kinvey.framework \
		-framework .dist/tvOSSimulator/Kinvey.xcarchive/Products/Library/Frameworks/Kinvey.framework \
		-framework .dist/watchOS/Kinvey.xcarchive/Products/Library/Frameworks/Kinvey.framework \
		-framework .dist/watchOSSimulator/Kinvey.xcarchive/Products/Library/Frameworks/Kinvey.framework \
		-output Carthage/Build/Kinvey.xcframework

	@# fix swiftinterface files generated with resolved typealiases breaking the build
	@find Carthage/Build/Kinvey.xcframework -iname \*.swiftinterface -exec sed -i '' 's/Realm\.RealmSwiftObject/RealmSwift\.Object/' {} \;

archive:
	@rm -rf Carthage/Build/Kinvey-$(VERSION).zip
	@cd Carthage/Build && mkdir -p .tmp && mv $(XCFrameworks) .tmp
	@cd Carthage/Build/.tmp && zip --symlinks -r Kinvey-$(VERSION).zip $(XCFrameworks)
	@cd Carthage/Build/.tmp && mv $(XCFrameworks) Kinvey-$(VERSION).zip ../ && cd .. && rm -rf .tmp

	@rm -rf Carthage/Build/Carthage.xcframework.zip
	@cd Carthage/Build && mkdir -p Carthage && mv Kinvey.xcframework Carthage
	@cd Carthage/Build && zip --symlinks -r Carthage.xcframework.zip Carthage
	@cd Carthage/Build/Carthage && mv Kinvey.xcframework ../ && cd .. && rm -rf Carthage

test: test-ios test-macos

test-ios:
	xcodebuild -workspace Kinvey.xcworkspace \
		-scheme Kinvey \
		-destination 'OS=$(DESTINATION_OS),name=$(DESTINATION_NAME)' \
		'-skip-testing:KinveyTests/PushTestCase/testRegisterForPush' \
		'-skip-testing:PushMissingConfiguration/PushMissingConfigurationTestCase/testMissingConfigurationError' \
		test -enableCodeCoverage YES

test-macos:
	xcodebuild -workspace Kinvey.xcworkspace \
		-scheme Kinvey-macOS \
		-destination 'platform=macOS,arch=x86_64' \
		test -enableCodeCoverage YES

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
	aws s3 cp Carthage/Build/Kinvey-$(VERSION).zip s3://kinvey-downloads/iOS/

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
	@cat Kinvey.podspec | grep "s.version\s*=\s*\"[0-9]*.[0-9]*.[0-9]*.*\"" | awk {'print $$3'} | sed 's/"//g' | xargs echo 'Kinvey.podspec'
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
	sed -i -e "s/s.version[ ]*=[ ]*\"[0-9]*.[0-9]*.[0-9]*.*\"/s.version      = \"$$version\"/g" Kinvey.podspec; \
	rm Kinvey.podspec-e

	@echo
	@echo

	@echo 'New Version:'
	@echo '----------------------'
	@$(MAKE) show-version
