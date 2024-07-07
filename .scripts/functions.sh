#! /bin/zsh

log::error() {
    echo "\033[0;31m$@\033[0m" 1>&2
}

log::success() {
    echo "\033[0;32m$@\033[0m"
}

log::message() {
    echo "\033[0;36m▸ $@\033[0m"
}

log::info() {
    echo "\033[1;37m$@\033[0m"
}

env::setup() {
    log::message "Setting up env"
    if [ -z $PACKAGE_VERSION ]; then
        log::error 'Must specify $PACKAGE_VERSION'
        exit -1
    fi
    log::info "PACKAGE_VERSION=$PACKAGE_VERSION"
    export SMOLDOTSWIFT_VERSION=${SMOLDOTSWIFT_VERSION:-$PACKAGE_VERSION}
    log::info "SMOLDOTSWIFT_VERSION=$SMOLDOTSWIFT_VERSION"
    export ROOT_DIRECTORY=${ROOT_DIRECTORY:-`pwd`}
    log::info "ROOT_DIRECTORY=$ROOT_DIRECTORY"
    export BUILD_DIRECTORY=${BUILD_DIRECTORY:-"$ROOT_DIRECTORY/.build/smoldot-framework"}
    log::info "BUILD_DIRECTORY=$BUILD_DIRECTORY"
    export RUST_TOOLCHAIN=${RUST_TOOLCHAIN:-'nightly-2024-06-30'}
    log::info "RUST_TOOLCHAIN=$RUST_TOOLCHAIN"
    
    export CHECKOUTS_DIRECTORY=${CHECKOUTS_DIRECTORY:-"$ROOT_DIRECTORY/.build/checkouts"}
    log::info "CHECKOUTS_DIRECTORY=$CHECKOUTS_DIRECTORY"
    export FFI_DIRECTORY=${FFI_DIRECTORY:-"$CHECKOUTS_DIRECTORY/smoldot-c-ffi"}
    log::info "FFI_DIRECTORY=$FFI_DIRECTORY"

}

env::build_configuration() {
    if [ -z $1 ]; then
        BUILD_CONFIG="release"
    elif [ $1 = "debug" ]; then
        BUILD_CONFIG="debug"
    else
        BUILD_CONFIG="release"
    fi

    log::message "Building for $BUILD_CONFIG"
    export BUILD_CONFIG
}

pre_build::create_build_directory() {
    if [ ! -d "$BUILD_DIRECTORY" ]; then
        log::message "Creating build directory"
        mkdir -p $BUILD_DIRECTORY
    fi
}

pre_build::setup_smoldot_c_ffi() {
    log::message "Checkout smoldot-c-ffi version $SMOLDOT_VERSION"
    if [ ! -d $FFI_DIRECTORY ]; then
        git clone https://github.com/finsig/smoldot-c-ffi $FFI_DIRECTORY
    fi
    
    cd $FFI_DIRECTORY
    git fetch --all
    #git checkout -f tags/$SMOLDOT_VERSION
}


rust::toolchain() {
    log::message "Install $RUST_TOOLCHAIN toolchain"
    rustup toolchain install $RUST_TOOLCHAIN
}

rust::targets() {
    log::message "Install targets"
    rustup target add --toolchain $RUST_TOOLCHAIN aarch64-apple-ios
    rustup target add --toolchain $RUST_TOOLCHAIN aarch64-apple-ios-sim
    rustup target add --toolchain $RUST_TOOLCHAIN x86_64-apple-ios
    rustup target add --toolchain $RUST_TOOLCHAIN aarch64-apple-darwin
    rustup target add --toolchain $RUST_TOOLCHAIN x86_64-apple-darwin
}

rust::components() {
    log::message "Install rustup components"
    #rustup component add rust-src --toolchain $RUST_TOOLCHAIN-x86_64-apple-darwin
    rustup component add rust-src --toolchain $RUST_TOOLCHAIN-aarch64-apple-darwin
}

rust::update() {
	rustup update
}

rust::setup() {
    rust::toolchain
    rust::targets
    rust::components
    rust::update
}

rust::build_target() {
    log::message "Build $1"
    if [ -z $1 ]; then
        log::error 'Must specify target as input to rust::build_target'
        exit -1
    fi
    cargo +$RUST_TOOLCHAIN build $([[ $1 = "aarch64-apple-ios-sim" ]] && [[ $RUST_TOOLCHAIN == "nightly"* ]] && echo "-Z build-std") --lib --package smoldot-c-ffi --target $1 $([[ $BUILD_CONFIG = "release" ]] && echo --release)
}

rust::build_ios() {
    rust::build_target aarch64-apple-ios
}

rust::build_ios_sim() {
    rust::build_target aarch64-apple-ios-sim
    rust::build_target x86_64-apple-ios
}

rust::build_macos() {
    rust::build_target aarch64-apple-darwin
    rust::build_target x86_64-apple-darwin
}

rust::build() {
    rust::build_ios
    rust::build_ios_sim
    rust::build_macos
}

build::lipo_ios_sim() {
    log::message "Lipo iOS Simulator"
    mkdir -p $FFI_DIRECTORY/target/apple-ios-simulator/$BUILD_CONFIG
    lipo -create  \
        $FFI_DIRECTORY/target/x86_64-apple-ios/$BUILD_CONFIG/libsmoldot_c_ffi.a \
        $FFI_DIRECTORY/target/aarch64-apple-ios-sim/$BUILD_CONFIG/libsmoldot_c_ffi.a \
        -output $FFI_DIRECTORY/target/apple-ios-simulator/$BUILD_CONFIG/libsmoldot_c_ffi.a
}

build::lipo_macos() {
    log::message "Lipo macOS"
    mkdir -p $FFI_DIRECTORY/target/apple-darwin/$BUILD_CONFIG
    lipo -create  \
        $FFI_DIRECTORY/target/x86_64-apple-darwin/$BUILD_CONFIG/libsmoldot_c_ffi.a \
        $FFI_DIRECTORY/target/aarch64-apple-darwin/$BUILD_CONFIG/libsmoldot_c_ffi.a \
        -output $FFI_DIRECTORY/target/apple-darwin/$BUILD_CONFIG/libsmoldot_c_ffi.a
}

build::lipo() {
	build::lipo_ios_sim
    build::lipo_macos
}

build::xcframework() {
    if [ -d "$BUILD_DIRECTORY/build/$PACKAGE_VERSION/$BUILD_CONFIG" ]; then
        log::message "Delete old build artifacts"
        rm -rf $BUILD_DIRECTORY/build/$PACKAGE_VERSION/$BUILD_CONFIG
    fi

    log::message "Create smoldot.xcframework"
    xcodebuild -create-xcframework \
	    -library $FFI_DIRECTORY/target/apple-ios-simulator/$BUILD_CONFIG/libsmoldot_c_ffi.a \
        -headers $FFI_DIRECTORY/src/c \
	    -library $FFI_DIRECTORY/target/aarch64-apple-ios/$BUILD_CONFIG/libsmoldot_c_ffi.a \
        -headers $FFI_DIRECTORY/src/c \
        -library $FFI_DIRECTORY/target/apple-darwin/$BUILD_CONFIG/libsmoldot_c_ffi.a \
        -headers $FFI_DIRECTORY/src/c \
        -output $BUILD_DIRECTORY/build/$PACKAGE_VERSION/$BUILD_CONFIG/smoldot.xcframework
}

post_build::compress() {
    if [ $BUILD_CONFIG = "release" ]; then
        log::message "Compress smoldot.xcframework"
        ditto -c -k --sequesterRsrc --keepParent $BUILD_DIRECTORY/build/$PACKAGE_VERSION/$BUILD_CONFIG/smoldot.xcframework $BUILD_DIRECTORY/build/$PACKAGE_VERSION/$BUILD_CONFIG/smoldot.xcframework.zip

        log::message "Compute smoldot.xcframework checksum"
        swift package compute-checksum $BUILD_DIRECTORY/build/$PACKAGE_VERSION/$BUILD_CONFIG/smoldot.xcframework.zip > $BUILD_DIRECTORY/build/$PACKAGE_VERSION/$BUILD_CONFIG/smoldot.xcframework.zip.checksum
    fi
}

post_build::copy_framework_to_package() {
    log::message "Copy framework artifact to package"
    mkdir -p $ROOT_DIRECTORY/Libs/smoldot.xcframework
    cp -r $BUILD_DIRECTORY/build/$PACKAGE_VERSION/$BUILD_CONFIG/smoldot.xcframework/. $ROOT_DIRECTORY/Libs/smoldot.xcframework
}

post_build::success() {
    log::success "▸ BUILD SUCCESSFUL!"
    log::success ''
    if [ $BUILD_CONFIG = "release" ]; then
        log::success "Built artifacts can be found at $BUILD_DIRECTORY/build/$PACKAGE_VERSION/$BUILD_CONFIG"
    fi
}

package::use_local_binary_target() {
    # assertion: only one binary target
    log::message "Modify Package.swift"
    log::info "Comment out remote binary target"
    if ! grep -q '\/\*.binaryTarget.*checksum.*\*\/' $ROOT_DIRECTORY/Package.swift; then # is using remote
        sed -i '' 's/.binaryTarget.*checksum.*/\/\*&\*\//' $ROOT_DIRECTORY/Package.swift # comment out remote
    fi
    
    log::info "Uncommment local binary target"
    sed -i '' 's/\/\*\(.binaryTarget.*path:.*),\)\*\//\1/' $ROOT_DIRECTORY/Package.swift # uncomment local
}

package::use_remote_binary_target() {
    # assertion: only one binary target
    log::message "Modify Package.swift"
    log::info "Comment out local binary target"
    if ! grep -q '\/\*.binaryTarget.*path.*\*\/' $ROOT_DIRECTORY/Package.swift; then    # is using local
        sed -i '' 's/.binaryTarget.*path.*),/\/\*&\*\//' $ROOT_DIRECTORY/Package.swift  # comment out local
    fi
    
    log::info "Uncommment remote binary target"
    sed -i '' 's/\/\*\(.binaryTarget.*checksum:.*),\)\*\//\1/' $ROOT_DIRECTORY/Package.swift # uncomment remote
}

package::remove_local_artifact() {
    log::message "Remove local framework artifact from package"
    if [ -d $ROOT_DIRECTORY/Libs ]; then
        rm -r $ROOT_DIRECTORY/Libs
    fi
}
