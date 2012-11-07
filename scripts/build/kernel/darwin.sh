# This file declares functions to install the kernel headers for mingw
# Copyright 2012 Yann Diorcet
# Licensed under the GPL v2. See COPYING in the root of this package

CT_DoKernelTupleValues() {
    CT_TARGET_KERNEL="darwin10"
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

    DIST="${CT_SYSROOT_DIR}/"
    SDK_NAME="${CT_DARWIN_SDK}"  
 
    CT_DoExecLog ALL \
    mkdir -p "${DIST}/SDKs/${SDK_NAME}"
 
    CT_DoExecLog ALL \
    cp -aT "${CT_DARWIN_SDK_PATH}" "${DIST}/SDKs/${SDK_NAME}"
    
    CT_DoExecLog ALL \
    rm -rf "${DIST}/SDKs/${SDK_NAME}/Library/Frameworks"
    
    CT_DoExecLog ALL \
    ln -sf "${DIST}/SDKs/${SDK_NAME}/System/Library/Frameworks" "${DIST}/SDKs/${SDK_NAME}/Library"
    
    CT_DoExecLog ALL \
    ln -sf "${DIST}/SDKs/${SDK_NAME}/Developer" "${DIST}/Developer"
    
    CT_DoExecLog ALL \
    ln -sf "${DIST}/SDKs/${SDK_NAME}/Library" "${DIST}/Library"
    
    CT_DoExecLog ALL \
    ln -sf "${DIST}/SDKs/${SDK_NAME}/System" "${DIST}/System"

    CT_DoExecLog ALL \
    rm -rf "${DIST}/usr" "${DIST}/lib"

    CT_DoExecLog ALL \
    ln -sf "${DIST}/SDKs/${SDK_NAME}/usr" "${DIST}/usr"
  
    CT_DoExecLog ALL \
    ln -sf "${DIST}/usr/lib/i686-apple-darwin10" "${DIST}/usr/lib/x86_64-apple-darwin10"
  
    mkdir -p "${DIST}/usr/lib/gcc/" 
   
    CT_DoExecLog ALL \
    ln -sf "${DIST}/usr/lib/gcc/i686-apple-darwin10" "${DIST}/usr/lib/gcc/x86_64-apple-darwin10"
    
    CT_DoExecLog ALL \
    ln -sf "${DIST}/usr/lib" "${DIST}/lib"

    CT_DoExecLog ALL \
    ln -sf "${DIST}/usr/include" "${DIST}/include"
 
    CT_EndStep
}

do_kernel_headers() {
    CT_DoStep INFO "Installing kernel headers"

    CT_DoExecLog ALL \
    ln -sf "${DIST}/include" "${CT_PREFIX_DIR}/${CT_TARGET}/include"

    CT_EndStep
}
