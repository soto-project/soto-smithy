// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "soto-smithy",
    products: [
        .library(name: "SotoSmithy", targets: ["SotoSmithy"]),
        .library(name: "SotoSmithyAWS", targets: ["SotoSmithyAWS"])
    ],
    targets: [
        .target(name: "SotoSmithy", dependencies: []),
        .target(name: "SotoSmithyAWS", dependencies: ["SotoSmithy"]),
        .testTarget(name: "SotoSmithyTests", dependencies: ["SotoSmithy", "SotoSmithyAWS"]),
    ]
)
