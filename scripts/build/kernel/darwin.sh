# This file declares functions to install the kernel headers for Darwin.
# Copyright 2012 Yann Diorcet
# Licensed under the GPL v2. See COPYING in the root of this package

CT_DoKernelTupleValues() {
    CT_TARGET_KERNEL="darwin${CT_DARWIN_VERSION}"
    CT_TARGET_SYS=
}

do_kernel_extract() {
    :
}
do_kernel_get() {
    CT_DoStep INFO "Get kernel headers"
    CT_EndStep
}

do_kernel_extract() {
    CT_DoStep INFO "Extract kernel headers"

    SDK_NAME="${CT_DARWIN_SDK}"  

    CT_Pushd "${CT_SYSROOT_DIR}"

    CT_DoExecLog ALL \
    mkdir -p "SDKs/${SDK_NAME}"

    CT_DoExecLog ALL \
    cp -aT "${CT_DARWIN_SDK_PATH}" "SDKs/${SDK_NAME}"

    CT_DoExecLog ALL \
    rm -rf "SDKs/${SDK_NAME}/Library/Frameworks"

    CT_DoExecLog ALL \
    ln -sf "../System/Library/Frameworks" "SDKs/${SDK_NAME}/Library"

    CT_DoExecLog ALL \
    ln -sf "SDKs/${SDK_NAME}/Developer" "Developer"

    CT_DoExecLog ALL \
    ln -sf "SDKs/${SDK_NAME}/Library" "Library"

    CT_DoExecLog ALL \
    ln -sf "SDKs/${SDK_NAME}/System" "System"

    CT_DoExecLog ALL \
    rm -rf "usr" "lib"

    CT_DoExecLog ALL \
    ln -sf "SDKs/${SDK_NAME}/usr" "usr"

    CT_DoExecLog ALL \
    ln -sf "i686-apple-darwin${CT_DARWIN_VERSION}" "usr/lib/${CT_TARGET_ARCH}-apple-darwin${CT_DARWIN_VERSION}"

    mkdir -p "usr/lib/gcc/" 

    CT_DoExecLog ALL \
    ln -sf "i686-apple-darwin${CT_DARWIN_VERSION}" "usr/lib/gcc/${CT_TARGET_ARCH}-apple-darwin${CT_DARWIN_VERSION}"

    CT_DoExecLog ALL \
    ln -sf "usr/lib" "lib"

    CT_DoExecLog ALL \
    ln -sf "usr/include" "include"

    CT_Popd

    CT_EndStep
}

do_kernel_headers() {
    CT_DoStep INFO "Installing kernel headers"

    CT_Pushd "${CT_PREFIX_DIR}/${CT_TARGET}"
    
    CT_DoExecLog ALL \
    ln -sf "${CT_SYSROOT_REL_DIR}/include" "include"
    
    CT_Popd

    CT_EndStep
}
