CONFIGURATION?=Release
VERSION=$(shell /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${PWD}/Kinvey/Kinvey/Info.plist")
CURRENT_BRANCH=$(shell git branch | awk '{split($$0, array, " "); if (array[1] == "*") print array[2]}')
DEVCENTER_GIT=git@github.com:Kinvey/devcenter.git
DEVCENTER_GIT_TEST=https://git.heroku.com/v3yk1n-devcenter.git
DEVCENTER_GIT_PROD=https://git.heroku.com/kinvey-devcenter-prod.git
CARTFILE_RESOLVED_MD5=$(shell md5 Cartfile.resolved | awk '{ print $$4 }')

all: build archive pack docs

deploy: deploy-git deploy-aws-s3 deploy-github deploy-cocoapods deploy-docs deploy-devcenter

release: all deploy

clean:
	rm -Rf docs
	rm -Rf build
	rm -Rf Carthage
	
checkout-dependencies:
	carthage checkout

build-debug:
	xcodebuild -workspace Kinvey.xcworkspace -scheme Kinvey -configuration Debug BUILD_DIR=build ONLY_ACTIVE_ARCH=NO -sdk iphoneos
	xcodebuild -workspace Kinvey.xcworkspace -scheme Kinvey -configuration Debug BUILD_DIR=build ONLY_ACTIVE_ARCH=NO -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone SE'

build-dependencies-ios: checkout-dependencies
	carthage build --platform iOS

cartfile-md5:
	@echo $(CARTFILE_RESOLVED_MD5)
	
travisci-cache:
	test -s Carthage/$(CARTFILE_RESOLVED_MD5).tar.lzma || \
	{ \
		cd Carthage; \
		rm *.tar.lzma; \
		wget http://download.kinvey.com/iOS/travisci-cache/$(CARTFILE_RESOLVED_MD5).tar.lzma; \
		tar -xvf $(CARTFILE_RESOLVED_MD5).tar.lzma; \
	}

travisci-cache-upload:
	cd Carthage; \
	tar --lzma -cvf $(CARTFILE_RESOLVED_MD5).tar.lzma Build; \
	aws s3 cp $(CARTFILE_RESOLVED_MD5).tar.lzma s3://kinvey-downloads/iOS/travisci-cache/$(CARTFILE_RESOLVED_MD5).tar.lzma

build: checkout-dependencies
	carthage build --no-skip-current

build-ios: checkout-dependencies
	carthage build --no-skip-current --platform iOS

build-macos: checkout-dependencies
	carthage build --no-skip-current --platform macOS

build-tvos: checkout-dependencies
	carthage build --no-skip-current --platform tvOS

build-watchos: checkout-dependencies
	carthage build --no-skip-current --platform watchOS

archive: archive-ios

archive-ios:
	carthage archive Kinvey

test: test-ios test-macos

	
test-ios:
	xcodebuild -workspace Kinvey.xcworkspace -scheme Kinvey -destination "OS=11.4,name=iPhone X" test -enableCodeCoverage YES

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
	pod trunk push Kinvey.podspec --verbose --allow-warnings

test-cocoapods:
	pod spec lint Kinvey.podspec --verbose --no-clean --allow-warnings

deploy-aws-s3:
	aws s3 cp build/Kinvey-$(VERSION).zip s3://kinvey-downloads/iOS/

deploy-github:
	swift scripts/github-release/main.swift release .

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
	swift scripts/devcenter-release/main.swift $(VERSION) build/devcenter
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
