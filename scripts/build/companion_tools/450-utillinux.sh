# Build script for libtool

CT_UTILLINUX_VERSION=2.20.1

do_companion_tools_utillinux_get() {
    CT_GetFile "util-linux-${CT_UTILLINUX_VERSION}" \
               http://www.kernel.org/pub/linux/utils/util-linux/v2.20/
}

do_companion_tools_utillinux_extract() {
    CT_Extract "util-linux-${CT_UTILLINUX_VERSION}"
    CT_Patch "util-linux" "${CT_UTILLINUX_VERSION}"
}

do_companion_tools_utillinux_build() {
    CT_DoStep EXTRA "Installing util-linux"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-util-linux"
    
    CT_DoExecLog CFG \
    CFLAGS="${CT_CFLAGS_FOR_BUILD}" \
    LDFLAGS="${CT_LDFLAGS_FOR_BUILD}" \
    "${CT_SRC_DIR}/util-linux-${CT_UTILLINUX_VERSION}/configure" \
        "${CC_CORE_SYSROOT_ARG}" \
        --prefix="${CT_BUILDTOOLS_PREFIX_DIR}" \
        --target=${CT_TARGET} \
        --without-ncurses \
        --disable-makeinstall-chown
        
    CT_DoExecLog ALL make
    CT_DoExecLog ALL make install
    CT_Popd
    CT_EndStep
}
