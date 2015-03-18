CONFIGURATION=Release
TARGET=Kinvey
PRODUCT_NAME=$(TARGET)Kit
FRAMEWORK=$(PRODUCT_NAME).framework
STATIC_LIB=libKinvey.a

all: clean build
	
build:
	xcodebuild -configuration $(CONFIGURATION) -target $(TARGET) -sdk iphoneos
	xcodebuild -configuration $(CONFIGURATION) -target $(TARGET) -sdk iphonesimulator
	cd build; \
	mkdir Release-universal; \
	cp -R Release-iphoneos/include Release-universal; \
	lipo -create Release-iphoneos/$(STATIC_LIB) Release-iphonesimulator/$(STATIC_LIB) -output Release-universal/$(STATIC_LIB); \
	cd Release-universal; \
	mkdir -p $(FRAMEWORK)/Versions/A/Headers; \
	ln -sfh A "$(FRAMEWORK)/Versions/Current"; \
	ln -sfh Versions/Current/Headers "$(FRAMEWORK)/Headers"; \
	ln -sfh "Versions/Current/$(PRODUCT_NAME)" "$(FRAMEWORK)/$(PRODUCT_NAME)"; \
	cp include/$(PRODUCT_NAME)/*.h "$(FRAMEWORK)/Versions/A/Headers"; \
	cp $(STATIC_LIB) "$(FRAMEWORK)/Versions/A/$(PRODUCT_NAME)"; \
	
clean:
	rm -Rf build
