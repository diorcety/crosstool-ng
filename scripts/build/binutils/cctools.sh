# This file adds functions to build cctools
# Copyright 2012 Yann Diorcet, Ray Donnelly.
# Licensed under the GPL v2. See COPYING in the root of this package

CT_LD64_VERSION=127.2
CT_GCCLLVM_VERSION=2336.1
CT_DYLD_VERSION=210.2.3

do_binutils_get() {
    CT_GetFile "cctools-${CT_BINUTILS_VERSION}" \
               http://opensource.apple.com/tarballs/cctools/
    CT_GetFile "ld64-${CT_LD64_VERSION}" \
               http://opensource.apple.com/tarballs/ld64/
    CT_GetFile "llvmgcc42-${CT_GCCLLVM_VERSION}" \
               http://opensource.apple.com/tarballs/llvmgcc42/
    CT_GetFile "dyld-${CT_DYLD_VERSION}" \
               http://opensource.apple.com/tarballs/dyld/
}

do_binutils_extract() {
    CT_Extract "cctools-${CT_BINUTILS_VERSION}"
    CT_Extract "ld64-${CT_LD64_VERSION}"
    CT_Extract "llvmgcc42-${CT_GCCLLVM_VERSION}"
    CT_Extract "dyld-${CT_DYLD_VERSION}"
    mkdir "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/ld64/"
    mkdir "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/dyld/"
    mkdir "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/libprunetrie/"
    mv -f "${CT_SRC_DIR}/ld64-${CT_LD64_VERSION}"/*                                 "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/ld64/"
    mv -f "${CT_SRC_DIR}/llvmgcc42-${CT_GCCLLVM_VERSION}"/llvmCore/include/llvm-c/* "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/include/"
    mv -f "${CT_SRC_DIR}/dyld-${CT_DYLD_VERSION}"/*                                 "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/dyld/"
    cp "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/ld64/src/other/PruneTrie.cpp"  "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/libprunetrie/"
    cp "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/ld64/src/other/prune_trie.h"   "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/include/mach-o/"
    cp "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/ld64/doc/man/man1/ld"*         "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/man/"

    CT_Patch "cctools" "${CT_BINUTILS_VERSION}"

    CT_Pushd "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/"
    autoreconf -vi
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

    do_cctools_backend "${cctools_opts[@]}"

    mkdir -p "${CT_BUILDTOOLS_PREFIX_DIR}/${CT_TARGET}/bin"

    CT_Popd

    # Make those new tools available to the core C compilers to come.
    # Note: some components want the ${TARGET}-{ar,as,ld,strip} commands as
    # well. Create that.
    # Don't do it for canadian or cross-native, because the binutils
    # are not executable on the build machine.
    case "${CT_TOOLCHAIN_TYPE}" in
        cross|native)
            binutils_tools=( ar as ld ld64 ld_classic strip dsymutil )
            mkdir -p "${CT_BUILDTOOLS_PREFIX_DIR}/${CT_TARGET}/bin"
            mkdir -p "${CT_BUILDTOOLS_PREFIX_DIR}/bin"
            for t in "${binutils_tools[@]}"; do
                CT_DoExecLog ALL ln -sv                                         \
                                    "${CT_PREFIX_DIR}/bin/${CT_TARGET}-${t}"    \
                                    "${CT_BUILDTOOLS_PREFIX_DIR}/${CT_TARGET}/bin/${t}"
                CT_DoExecLog ALL ln -sv                                         \
                                    "${CT_PREFIX_DIR}/bin/${CT_TARGET}-${t}"    \
                                    "${CT_BUILDTOOLS_PREFIX_DIR}/bin/${CT_TARGET}-${t}"
                CT_DoExecLog ALL ln -sv                                         \
                                    "${CT_PREFIX_DIR}/bin/${CT_TARGET}-${t}"    \
                                    "${CT_PREFIX_DIR}/${CT_TARGET}/bin/${t}" 
            done
            ;;
        *)  ;;
    esac

    CT_EndStep
}

do_binutils_for_target() {
    :
}

# Build cctools for X -> target
#     Parameter     : description               : type      : default
#     host          : machine to run on         : tuple     : (none)
#     prefix        : prefix to install into    : dir       : (none)
#     cflags        : host cflags to use        : string    : (empty)
#     ldflags       : host ldflags to use       : string    : (empty)
do_cctools_backend() {
    local host
    local prefix
    local cflags
    local ldflags
    local -a extra_config

    for arg in "$@"; do
        eval "${arg// /\\ }"
    done

    if [ "${CT_MULTILIB}" = "y" ]; then
        extra_config+=("--enable-multilib")
    else
        extra_config+=("--disable-multilib")
    fi

    CT_DoLog EXTRA "Configuring cctools"
    CT_DoExecLog CFG \
    CFLAGS="${cflags} -isystem ${prefix}/include/ -isystem ${CT_BUILDTOOLS_PREFIX_DIR}/include/" 	\
    CXXFLAGS="${cflags} -isystem ${prefix}/include/ -isystem ${CT_BUILDTOOLS_PREFIX_DIR}/include/" 	\
    LDFLAGS="${ldflags} -L${CT_BUILDTOOLS_PREFIX_DIR}/lib/ -L${prefix}/lib/"                            \
    "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/configure"            \
        --build=${CT_BUILD}                                             \
        --host=${host}                                                  \
        --target=${CT_TARGET}                                           \
        --prefix=${prefix}                                              \
        --disable-werror                                                \
        "${extra_config[@]}"                                            \
        ${CT_ARCH_WITH_FLOAT}                                           \
        ${BINUTILS_SYSROOT_ARG}                                         \

    CT_DoLog EXTRA "Building cctools"
    CT_DoExecLog ALL make

    CT_DoLog EXTRA "Installing cctools"
    CT_DoExecLog ALL make install

    mkdir -p "${prefix}/${CT_TARGET}/bin"
}
