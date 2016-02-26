CONFIGURATION?=Release

all: build

build: build-ios

clean:
	rm -Rf docs
	rm -Rf build

build-debug:
	xcodebuild -workspace Kinvey.xcworkspace -scheme Kinvey -configuration Debug BUILD_DIR=build -sdk iphoneos
	xcodebuild -workspace Kinvey.xcworkspace -scheme Kinvey -configuration Debug BUILD_DIR=build -sdk iphonesimulator
	
build-ios:
	cd Kinvey; \
	carthage build --no-skip-current --platform ios

docs:
	jazzy --author Kinvey \
				--author_url http://www.kinvey.com \
				--module-version 3.0 \
				--readme README-API-Reference-Docs.md \
				--podspec Kinvey.podspec \
				--min-acl public \
				--theme apple \
				--xcodebuild-arguments -workspace,Kinvey.xcworkspace,-scheme,Kinvey \
				--module Kinvey \
				--output docs
