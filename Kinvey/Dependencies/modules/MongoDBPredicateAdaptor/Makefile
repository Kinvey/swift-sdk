CONFIGURATION?=Release
FRAMEWORK_NAME=MongoDBPredicateAdaptorKit

all: build

clean:
	rm -Rf build

build:
	xcodebuild -configuration $(CONFIGURATION) ONLY_ACTIVE_ARCH=NO -sdk iphoneos
	xcodebuild -configuration $(CONFIGURATION) ONLY_ACTIVE_ARCH=NO -sdk iphonesimulator
	cp -R build/$(CONFIGURATION)-iphonesimulator build/$(CONFIGURATION)-ios
	lipo -create build/$(CONFIGURATION)-iphoneos/$(FRAMEWORK_NAME).framework/$(FRAMEWORK_NAME) \
				 build/$(CONFIGURATION)-iphonesimulator/$(FRAMEWORK_NAME).framework/$(FRAMEWORK_NAME) \
		 -output build/$(CONFIGURATION)-ios/$(FRAMEWORK_NAME).framework/$(FRAMEWORK_NAME)
	lipo -info build/$(CONFIGURATION)-ios/$(FRAMEWORK_NAME).framework/$(FRAMEWORK_NAME)
    