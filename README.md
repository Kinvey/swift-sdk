# Kinvey Kit - iOS Library

## Release process:

1. Change to develop branch
* Update KinveyKit-History-template.md with the new release date
* Update README.md with the new release number and date
* Update TAG-ME in KinveyVersion.h
* Commit changes to develop branch
* Double-check with an app that the lib works
* Create Release Branch following the git-flow pattern witch the version number as suffix, for example: release/1.29.0
* Merge the develop branch to master following the git-flow pattern
* Update documentation in devcenter
* Upload the binaries to S3 Updating The Downloads
* Update the downloads.js and the changelog file in the devcenter
* Push the devcenter
* Update the Cocoapods spec. For KK1, just copy over last one, update the build number everywhere and push to pods trunk.