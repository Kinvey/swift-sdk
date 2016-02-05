CONFIGURATION?=Release

all: build

clean:
	rm -Rf build

build:
	xcodebuild -workspace Kinvey.xcworkspace -scheme Kinvey -configuration $(CONFIGURATION) BUILD_DIR=build -sdk iphoneos
