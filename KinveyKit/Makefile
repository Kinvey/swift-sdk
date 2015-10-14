CONFIGURATION=Release
TARGET=Kinvey
PRODUCT_NAME=$(TARGET)Kit
MODULE=$(PRODUCT_NAME).framework
FRAMEWORK=NonModule/$(PRODUCT_NAME).framework
STATIC_LIB=libKinvey.a
OUTPUT_FOLDER=build

all: build
	
build:
	xcodebuild -configuration $(CONFIGURATION) -target $(TARGET) -sdk iphoneos
	xcodebuild -configuration $(CONFIGURATION) -target $(TARGET) -sdk iphonesimulator
	cd $(OUTPUT_FOLDER); \
	mkdir $(CONFIGURATION)-universal; \
	cp -R $(CONFIGURATION)-iphoneos/include $(CONFIGURATION)-universal; \
	lipo -create $(CONFIGURATION)-iphoneos/$(STATIC_LIB) $(CONFIGURATION)-iphonesimulator/$(STATIC_LIB) -output $(CONFIGURATION)-universal/$(STATIC_LIB); \
	cd $(CONFIGURATION)-universal; \
	mkdir -p $(FRAMEWORK)/Versions/A/Headers; \
	ln -sfh A "$(FRAMEWORK)/Versions/Current"; \
	ln -sfh Versions/Current/Headers "$(FRAMEWORK)/Headers"; \
	ln -sfh "Versions/Current/$(PRODUCT_NAME)" "$(FRAMEWORK)/$(PRODUCT_NAME)"; \
	cp include/$(PRODUCT_NAME)/*.h "$(FRAMEWORK)/Versions/A/Headers"; \
	cp $(STATIC_LIB) "$(FRAMEWORK)/Versions/A/$(PRODUCT_NAME)"
	
	xcodebuild -configuration $(CONFIGURATION) -target $(PRODUCT_NAME) -sdk iphoneos
	xcodebuild -configuration $(CONFIGURATION) -target $(PRODUCT_NAME) -sdk iphonesimulator
	cd $(OUTPUT_FOLDER); \
	cp -R $(CONFIGURATION)-iphonesimulator/$(MODULE) $(CONFIGURATION)-universal; \
	lipo -create $(CONFIGURATION)-iphoneos/$(MODULE)/$(PRODUCT_NAME) $(CONFIGURATION)-iphonesimulator/$(MODULE)/$(PRODUCT_NAME) -output $(CONFIGURATION)-universal/$(MODULE)/$(PRODUCT_NAME)
	
clean:
	rm -Rf $(OUTPUT_FOLDER)
