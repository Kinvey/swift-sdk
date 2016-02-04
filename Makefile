CONFIGURATION?=Release

all: build

clean:
	rm -Rf build

build:
	xcodebuild -workspace Kinvey.xcworkspace -scheme Kinvey -configuration $(CONFIGURATION) BUILD_DIR=$(PWD)/build -sdk iphoneos
	xcodebuild -workspace Kinvey.xcworkspace -scheme Kinvey -configuration $(CONFIGURATION) BUILD_DIR=$(PWD)/build -sdk iphonesimulator
	cd $(PWD)/build; \
	mkdir -p $(CONFIGURATION)-universal; \
	cp -R $(CONFIGURATION)-iphoneos/Kinvey.framework $(CONFIGURATION)-universal; \
	cp -R $(CONFIGURATION)-iphonesimulator/Kinvey.framework/Modules/Kinvey.swiftmodule/* $(CONFIGURATION)-universal/Kinvey.framework/Modules/Kinvey.swiftmodule; \
	lipo -create $(CONFIGURATION)-iphoneos/Kinvey.framework/Kinvey $(CONFIGURATION)-iphonesimulator/Kinvey.framework/Kinvey -output $(CONFIGURATION)-universal/Kinvey.framework/Kinvey; \
	lipo -info $(CONFIGURATION)-universal/Kinvey.framework/Kinvey
