CONFIGURATION?=Release

all: build

clean:
	rm -Rf build

build:
	xcodebuild -configuration $(CONFIGURATION) -sdk iphoneos
	xcodebuild -configuration $(CONFIGURATION) -sdk iphonesimulator