#! /bin/zsh -e

source ".scripts/functions.sh"

set -e

PACKAGE_VERSION=999.0.0

env::setup
env::build_configuration $1

rust::setup

pre_build::create_build_directory
pre_build::setup_smoldot_c_ffi

rust::build

build::lipo
build::xcframework

#package::use_remote_binary_target
package::use_local_binary_target

#post_build::compress
post_build::copy_framework_to_package
post_build::success
