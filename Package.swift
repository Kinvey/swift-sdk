// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Kinvey",
    platforms: [
        .macOS(.v10_12),
        .iOS(.v12),
        .tvOS(.v12),
        .watchOS(.v3)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Kinvey",
            targets: ["Kinvey"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(
            url: "https://github.com/realm/realm-cocoa.git",
            .exact("10.15.1")
        ),
        .package(
            url: "https://github.com/mxcl/PromiseKit.git",
            .exact("6.15.3")
        ),
        .package(
            url: "https://github.com/kishikawakatsumi/KeychainAccess.git",
            .exact("4.2.2")
        ),
        .package(
            url: "https://github.com/SwiftyBeaver/SwiftyBeaver.git",
            .exact("1.9.5")
        ),
        .package(
            url: "https://github.com/tristanhimmelman/ObjectMapper.git",
            .exact("4.2.0")
        ),
        .package(
            url: "https://github.com/Kinvey/objective-c.git",
            .exact("4.16.2-with-spm-v0.0.1")
        ),
        .package(
            url: "https://github.com/tjboneman/NSPredicate-MongoDB-Adaptor.git",
            .branch("master")
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Kinvey",
            dependencies: [
                "Realm",
                "RealmSwift",
                "PromiseKit",
                "KeychainAccess",
                "SwiftyBeaver",
                "ObjectMapper",
                "PubNub",
                "MongoDBPredicateAdaptor",
            ]
        ),
    ]
)
