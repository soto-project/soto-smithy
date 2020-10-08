// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "soto-smithy",
    products: [
        .library(name: "SotoSmithy", targets: ["SotoSmithy"])
    ],
    targets: [
        .target(name: "SotoSmithy", dependencies: []),
        .testTarget(name: "SotoSmithyTests", dependencies: ["SotoSmithy"]),
    ]
)
