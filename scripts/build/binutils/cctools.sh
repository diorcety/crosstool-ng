# This file adds functions to build cctools
# Copyright 2012 Yann Diorcet, Ray Donnelly.
# Licensed under the GPL v2. See COPYING in the root of this package

CT_LD64_VERSION=127.2
CT_DYLD_VERSION=210.2.3

do_binutils_get() {
    CT_GetFile "cctools-${CT_BINUTILS_VERSION}" \
               http://opensource.apple.com/tarballs/cctools/
    CT_GetFile "ld64-${CT_LD64_VERSION}" \
               http://opensource.apple.com/tarballs/ld64/
    CT_GetFile "dyld-${CT_DYLD_VERSION}" \
               http://opensource.apple.com/tarballs/dyld/
}

do_binutils_extract() {
    CT_Extract "cctools-${CT_BINUTILS_VERSION}"
    CT_Extract "ld64-${CT_LD64_VERSION}"
    CT_Extract "dyld-${CT_DYLD_VERSION}"
    
    # Mixing
    mkdir -p "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/ld64/"
    mkdir -p  "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/dyld/"
    mkdir -p "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/libprunetrie/"
    mv -f "${CT_SRC_DIR}/ld64-${CT_LD64_VERSION}"/*                                 "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/ld64/"
    cp -rf "${CT_SRC_DIR}/${CT_LLVM_FULLNAME}/include/llvm-c"                       "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/include/"
    mv -f "${CT_SRC_DIR}/dyld-${CT_DYLD_VERSION}"/*                                 "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/dyld/"
    cp "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/ld64/src/other/PruneTrie.cpp"  "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/libprunetrie/"
    cp "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/ld64/src/other/prune_trie.h"   "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/include/mach-o/"
    cp "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/ld64/doc/man/man1/ld"*         "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/man/"

    CT_Patch "cctools" "${CT_BINUTILS_VERSION}"

    CT_Pushd "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/"
    autoreconf -vi > /dev/null
    CT_Popd
}

# Build cctools for build -> target
do_binutils_for_build() {
    local -a cctools_opts

    case "${CT_TOOLCHAIN_TYPE}" in
        native|cross)   return 0;;
    esac

    CT_DoStep INFO "Installing cctools for build"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-cctools-build"

    cctools_opts+=( "host=${CT_BUILD}" )
    cctools_opts+=( "cflags=${CT_CFLAGS_FOR_BUILD}" )
    cctools_opts+=( "ldflags=${CT_LDFLAGS_FOR_BUILD}" )
    cctools_opts+=( "prefix=${CT_BUILDTOOLS_PREFIX_DIR}" )
    if [ "${CT_STATIC_TOOLCHAIN}" = "y" ]; then
        cctools_opts+=( "build_staticlinked=yes" )
    fi

    do_cctools_backend "${cctools_opts[@]}"

    CT_Popd

    CT_EndStep
}

# Build cctools for host -> target
do_binutils_for_host() {
    local -a cctools_opts

    CT_DoStep INFO "Installing cctools for host"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-cctools-host-${CT_HOST}"

    cctools_opts+=( "host=${CT_HOST}" )
    cctools_opts+=( "cflags=${CT_CFLAGS_FOR_HOST}" )
    cctools_opts+=( "ldflags=${CT_LDFLAGS_FOR_HOST}" )
    cctools_opts+=( "prefix=${CT_PREFIX_DIR}" )
    if [ "${CT_STATIC_TOOLCHAIN}" = "y" ]; then
        cctools_opts+=( "build_staticlinked=yes" )
    fi

    do_cctools_backend "${cctools_opts[@]}"

    # This is likely un-needed as it probably existed only for the old
    # symlink stuff that's now removed.
    mkdir -p "${CT_BUILDTOOLS_PREFIX_DIR}/${CT_TARGET}/bin"

    CT_Popd

    CT_EndStep
}

do_binutils_for_target() {
    :
}

# Build cctools for X -> target
#     Parameter          : description                    : type      : default
#     host               : machine to run on              : tuple     : (none)
#     prefix             : prefix to install into         : dir       : (none)
#     cflags             : host cflags to use             : string    : (empty)
#     ldflags            : host ldflags to use            : string    : (empty)
#     build_staticlinked : build statically linked or not : bool      : no
do_cctools_backend() {
    local host
    local prefix
    local cflags
    local ldflags
    local build_staticlinked=no
    local -a extra_config

    for arg in "$@"; do
        eval "${arg// /\\ }"
    done

    if [ "${build_staticlinked}" = "yes" ]; then
        extra_config+=("--enable-static")
        extra_config+=("--disable-shared")
    else
        extra_config+=("--disable-static")
        extra_config+=("--enable-shared")
    fi

    CT_DoLog EXTRA "Configuring cctools"
    CT_DoExecLog CFG \
    CFLAGS="${cflags} -I${CT_BUILDTOOLS_PREFIX_DIR}/include/"           \
    CXXFLAGS="${cflags} -I${CT_BUILDTOOLS_PREFIX_DIR}/include/"         \
    LDFLAGS="${ldflags} -L${CT_BUILDTOOLS_PREFIX_DIR}/lib/"             \
    "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/configure"            \
        --build=${CT_BUILD}                                             \
        --host=${host}                                                  \
        --target=${CT_TARGET}                                           \
        --prefix=${prefix}                                              \
        --with-llvm=${prefix}                                           \
        "${extra_config[@]}"                                            \
        ${CT_ARCH_WITH_FLOAT}                                           \
        ${BINUTILS_SYSROOT_ARG}                                         \

    CT_DoLog EXTRA "Building cctools"
    CT_DoExecLog ALL make

    CT_DoLog EXTRA "Installing cctools"
    CT_DoExecLog ALL make install

    mkdir -p "${prefix}/${CT_TARGET}/bin"
}
