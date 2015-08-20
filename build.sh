PROJECT="KinveyKit"
SCHEME="Kinvey"
REPO_ROOT=$1
xcodebuild -project $REPO_ROOT/$PROJECT/$PROJECT.xcodeproj -scheme $SCHEME clean build test | xcpretty -tc -r junit -r html
