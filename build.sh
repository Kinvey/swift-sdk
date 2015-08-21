PROJECT="KinveyKit"
SCHEME="Kinvey"
REPO_ROOT=$1
ps aux | grep _sim | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null
osascript kill-simulators
xcodebuild -project $REPO_ROOT/$PROJECT/$PROJECT.xcodeproj -scheme $SCHEME -sdk iphonesimulator -configuration Debug clean build test | xcpretty -tc -r junit -r html
xcodebuild -project $REPO_ROOT/$PROJECT/$PROJECT.xcodeproj -scheme $SCHEME -sdk iphonesimulator -configuration Release clean build
