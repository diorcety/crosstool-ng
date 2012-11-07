# Build script for libtool

CT_OPENSSL_VERSION=1.0.1c

do_companion_tools_openssl_get() {
    CT_GetFile "openssl-${CT_OPENSSL_VERSION}" \
               http://www.openssl.org/source/ 
}

do_companion_tools_openssl_extract() {
    CT_Extract "openssl-${CT_OPENSSL_VERSION}"
    CT_Patch "openssl" "${CT_OPENSSL_VERSION}"
}

do_companion_tools_openssl_build() {
	local -a extra_config
	
    CT_DoStep EXTRA "Installing openssl"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-openssl"
    
    if [ "${CT_STATIC_TOOLCHAIN}" = "y" ]; then
        extra_config+=("-no-shared")
        extra_config+=("-no-zlib-dynamic")
    fi
    
    if echo "${CT_BUILD}" | "${grep}" -E 'mingw' >/dev/null 2>&1; then
        extra_config+=("mingw")
    elif echo "${CT_BUILD}" | "${grep}" -E 'linux' >/dev/null 2>&1; then
        if echo "${CT_BUILD}" | "${grep}" -E '^x86_64' >/dev/null 2>&1; then
            CT_DoExecLog ALL echo "${CT_CFLAGS_FOR_BUILD}"
            if echo "${CT_CFLAGS_FOR_BUILD}" | "${grep}" -E '\-m32' >/dev/null 2>&1; then
                extra_config+=("linux-generic32")
			else
                extra_config+=("linux-generic64")
            fi
        else
            extra_config+=("linux-generic32")
        fi
    fi
    
    CT_DoExecLog ALL cp -aT "${CT_SRC_DIR}/openssl-${CT_OPENSSL_VERSION}" "."
    
    CT_DoExecLog CFG                           \
    CFLAGS="${CT_CFLAGS_FOR_BUILD}"            \
    LDFLAGS="${CT_LDFLAGS_FOR_BUILD}"          \
    "./Configure"                              \
        --prefix="${CT_BUILDTOOLS_PREFIX_DIR}" \
        -no-test                               \
        "${extra_config[@]}"                   \
    
    CT_DoExecLog ALL make CC="${CT_CC} ${CT_CFLAGS_FOR_BUILD}"
    CT_DoExecLog ALL make install CC="${CT_CC} ${CT_CFLAGS_FOR_BUILD}"
    CT_Popd
    CT_EndStep
}
