ROOT_FOLDER=Kinvey
CONFIGURATION?=Release

all: clean build

clean:
	rm -Rf build

build:
	xcodebuild -workspace KinveyKit.xcworkspace -scheme Kinvey -configuration $(CONFIGURATION) -sdk iphoneos ONLY_ACTIVE_ARCH=NO
	xcodebuild -workspace KinveyKit.xcworkspace -scheme Kinvey -configuration $(CONFIGURATION) -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO
	cd $(ROOT_FOLDER)/build; \
	mkdir -p $(CONFIGURATION)-universal; \
	cp -R $(CONFIGURATION)-iphoneos/Kinvey.framework $(CONFIGURATION)-universal; \
	cp -R $(CONFIGURATION)-iphonesimulator/Kinvey.framework/Modules/Kinvey.swiftmodule/* $(CONFIGURATION)-universal/Kinvey.framework/Modules/Kinvey.swiftmodule; \
	lipo -create $(CONFIGURATION)-iphoneos/Kinvey.framework/Kinvey $(CONFIGURATION)-iphonesimulator/Kinvey.framework/Kinvey -output $(CONFIGURATION)-universal/Kinvey.framework/Kinvey; \
	lipo -info $(CONFIGURATION)-universal/Kinvey.framework/Kinvey
