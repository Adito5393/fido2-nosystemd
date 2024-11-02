#!/bin/bash

# Prerequisite check(s) for module.
check() {
    require_binaries fido2-token fido2-assert || return 1
    # Return 255 to only include the module, if another module requires it.
    return 255
}

# Module dependency requirements.
depends() {
    echo crypt udev-rules
    # Return 0 to include the dependent module(s) in the initramfs.
    return 0
}

# Install the required file(s) and directories for the module in the initramfs.
install() {
    # Architecture-specific library paths.
    _arch=${DRACUT_ARCH:-$(uname -m)}

    # Install required libraries.
    inst_libdir_file \
        {"tls/$_arch/",tls/,"$_arch/",}"libfido2.so.*" \
        {"tls/$_arch/",tls/,"$_arch/",}"libcbor.so.*" \
        {"tls/$_arch/",tls/,"$_arch/",}"libhidapi-hidraw.so.*" \
        {"tls/$_arch/",tls/,"$_arch/",}"libz.so.*" \
        {"tls/$_arch/",tls/,"$_arch/",}"cryptsetup/libcryptsetup-token-systemd-fido2.so"

    # Install required binaries.
    inst_multiple -o \
        fido2-token \
        fido2-assert
}
