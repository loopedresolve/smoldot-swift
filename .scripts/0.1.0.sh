#! /bin/zsh -e

source ".scripts/functions.sh"

set -e

PACKAGE_VERSION=0.1.0

env::setup
env::build_configuration $1

rust::setup

pre_build::create_build_directory
pre_build::setup_smoldot_c_ffi

rust::build

build::lipo
build::xcframework

post_build::compress
post_build::success

post_build::copy_to_package
