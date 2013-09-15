# Build script for openssl

do_openssl_get() { :; }
do_openssl_extract() { :; }
do_openssl_for_build() { :; }
do_openssl_for_host() { :; }

if [ "${CT_OPENSSL}" = "y" ]; then

do_openssl_get() {
    CT_GetFile "openssl-${CT_OPENSSL_VERSION}" \
               http://www.openssl.org/source/ 
}

do_openssl_extract() {
    CT_Extract "openssl-${CT_OPENSSL_VERSION}"
    CT_Patch "openssl" "${CT_OPENSSL_VERSION}"
}

# Build openssl for running on build
do_openssl_for_build() {
    local -a openssl_opts

    case "${CT_TOOLCHAIN_TYPE}" in
        native|cross)   return 0;;
    esac

    CT_DoStep INFO "Installing openssl for build"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-openssl-build-${CT_BUILD}"

    openssl_opts+=( "host=${CT_BUILD}" )
    openssl_opts+=( "prefix=${CT_BUILDTOOLS_PREFIX_DIR}" )
    libuuid_opts+=( "cflags=${CT_CFLAGS_FOR_BUILD}" )
    libuuid_opts+=( "ldflags=${CT_LDFLAGS_FOR_BUILD}" )
    do_openssl_backend "${gmp_opts[@]}"

    CT_Popd
    CT_EndStep
}

# Build openssl for running on host
do_openssl_for_host() {
    local -a openssl_opts

    # OpenSSL doesn't build, and isn't needed on Darwin.
    case "${CT_HOST}" in
        *darwin*)   return 0;;
    esac

    CT_DoStep INFO "Installing openssl for host"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-openssl-host-${CT_HOST}"

    openssl_opts+=( "host=${CT_HOST}" )
    openssl_opts+=( "prefix=${CT_HOST_COMPLIBS_DIR}" )
    openssl_opts+=( "cflags=${CT_CFLAGS_FOR_HOST}" )
    openssl_opts+=( "ldflags=${CT_LDFLAGS_FOR_HOST}" )
    openssl_opts+=( "static_build=${CT_STATIC_TOOLCHAIN}" )
    do_openssl_backend "${openssl_opts[@]}"

    CT_Popd
    CT_EndStep
}

# Build openssl
#     Parameter     : description               : type      : default
#     host          : machine to run on         : tuple     : (none)
#     prefix        : prefix to install into    : dir       : (none)
#     static_build  : build statcially          : bool      : no
#     cflags        : host cflags to use        : string    : (empty)
#     ldflags       : host ldflags to use       : string    : (empty)
do_openssl_backend() {
    local host
    local prefix
    local static_build
    local cflags
    local ldflags
    local arg
    local -a extra_config

    for arg in "$@"; do
        eval "${arg// /\\ }"
    done

    if [ "${static_build}" = "y" ]; then
        extra_config+=("-no-shared")
        extra_config+=("-no-zlib-dynamic")
    fi
    
    if echo "${host}" | "${grep}" -E 'mingw' >/dev/null 2>&1; then
        extra_config+=("mingw")
    elif echo "${host}" | "${grep}" -E 'linux' >/dev/null 2>&1; then
        if echo "${host}" | "${grep}" -E '^x86_64' >/dev/null 2>&1; then
            if echo "${clfags}" | "${grep}" -E '\-m32' >/dev/null 2>&1; then
                extra_config+=("linux-generic32")
			else
                extra_config+=("linux-generic64")
            fi
        else
            extra_config+=("linux-generic32")
        fi
    fi
 
    CT_DoLog EXTRA "Configuring openssl"

    CT_DoExecLog ALL cp -aT "${CT_SRC_DIR}/openssl-${CT_OPENSSL_VERSION}" "."
    
    CT_DoExecLog CFG                           \
    CFLAGS="${clfags}"                         \
    LDFLAGS="${ldflags}"                       \
    "./Configure"                              \
        --prefix="${prefix}"                   \
        -no-test                               \
        "${extra_config[@]}"                   \
 
    CT_DoLog EXTRA "Building openssl"
    CT_DoExecLog ALL make CC="${CT_HOST}-gcc ${cflags}"

    CT_DoLog EXTRA "Installing openssl"
    CT_DoExecLog ALL make install CC="${CT_HOST}-gcc ${cflags}"
}

fi
