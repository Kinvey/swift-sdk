CONFIGURATION=Release
TARGET=Kinvey
PRODUCT_NAME=$(TARGET)Kit
MODULE=$(PRODUCT_NAME).framework
FRAMEWORK=NonModule/$(PRODUCT_NAME).framework
STATIC_LIB=libKinvey.a
OUTPUT_FOLDER=build
PWD=$(dir $(shell pwd))$(notdir $(shell pwd))
VERSION=$(shell /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${PWD}/KinveyKit/Info.plist")
DEPLOY_FOLDER=$(OUTPUT_FOLDER)/$(PRODUCT_NAME)-$(VERSION)

all: build doc
	
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
	
doc:
	cd ../Tools; \
	./build-doc ../KinveyKit

pkg: all
	rm -Rf mkdir -p $(DEPLOY_FOLDER)
	mkdir -p $(DEPLOY_FOLDER)
	cp -R doc/built-docs/com.kinvey.$(PRODUCT_NAME).docset $(DEPLOY_FOLDER)
	cp -R $(OUTPUT_FOLDER)/$(CONFIGURATION)-universal/$(FRAMEWORK) $(DEPLOY_FOLDER)
	cp LICENSES $(DEPLOY_FOLDER)
	mkdir -p $(DEPLOY_FOLDER)/Module/$(MODULE)
	cp -R $(OUTPUT_FOLDER)/$(CONFIGURATION)-universal/$(MODULE) $(DEPLOY_FOLDER)/Module
	cd $(DEPLOY_FOLDER); \
	zip -r -X ../$(PRODUCT_NAME)-$(VERSION).zip *
	
deploy: pkg
	cd ../Tools/upload-to-amazon-aws-s3; \
	npm install; \
	npm start
	
deploy-reference:
	rm -Rf devcenter
	git clone git@github.com:Kinvey/devcenter.git
	cd devcenter; \
	git remote add staging git@heroku.com:v3yk1n-devcenter.git; \
	git remote add production git@heroku.com:kinvey-devcenter-prod.git
	rm -R devcenter/content/reference/ios/api
	cp -R doc/output/html devcenter/content/reference/ios
	mv devcenter/content/reference/ios/html devcenter/content/reference/ios/api
	cd devcenter; \
	git add content/reference/ios/*/*; \
	git commit -m "iOS Release Version $(VERSION)"; \
	git push origin master; \
	git push staging master; \
	git push production master

clean:
	rm -Rf $(OUTPUT_FOLDER)
	rm -Rf doc
