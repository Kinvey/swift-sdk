PROJECT="KinveyKit"
SCHEME="Kinvey"
REPO_ROOT=$1
ps aux | grep _sim | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null
osascript kill-simulators
xcodebuild -project $REPO_ROOT/$PROJECT/$PROJECT.xcodeproj -scheme $SCHEME clean build test | xcpretty -tc -r junit -r html
