# This file adds functions to build cctools
# Copyright 2012 Yann Diorcet, Ray Donnelly.
# Licensed under the GPL v2. See COPYING in the root of this package

CT_ODCCTOOLS_VERSION=9.2

do_binutils_get() {
    CT_GetFile "cctools-${CT_BINUTILS_VERSION}" \
               http://opensource.apple.com/tarballs/cctools/
    if [ "${CT_BINUTILS_VERSIOIN}" = "806" ]; then
        CT_GetGit  "odcctools-${CT_ODCCTOOLS_VERSION}" \
                   https://github.com/Tatsh/xchain/
    else
    fi
}

do_binutils_extract() {
    CT_Extract "cctools-${CT_BINUTILS_VERSION}"
    CT_Patch "cctools" "${CT_BINUTILS_VERSION}"

    chmod +x "${CT_SRC_DIR}/cctools-${CT_BINUTILS_VERSION}/configure"

    rm -rf "${CT_SRC_DIR}/odcctools-${CT_ODCCTOOLS_VERSION}/"
    rm -rf "${CT_SRC_DIR}/.odcctools-${CT_ODCCTOOLS_VERSION}"*
    CT_Extract "odcctools-${CT_ODCCTOOLS_VERSION}"
    CT_Patch "odcctools" "${CT_ODCCTOOLS_VERSION}"

    chmod +x "${CT_SRC_DIR}/odcctools-${CT_ODCCTOOLS_VERSION}/odcctools-9.2-ld/configure"
}

# Build cctools for build -> target
do_binutils_for_build() {
    local -a cctools_opts
    local -a odcctools_opts

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

    CT_mkdir_pushd "${CT_BUILD_DIR}/build-odcctools-build"

    odcctools_opts+=( "host=${CT_BUILD}" )
    odcctools_opts+=( "cflags=${CT_CFLAGS_FOR_BUILD}" )
    odcctools_opts+=( "ldflags=${CT_LDFLAGS_FOR_BUILD}" )
    odcctools_opts+=( "prefix=${CT_BUILDTOOLS_PREFIX_DIR}" )

    do_odcctools_backend "${odcctools_opts[@]}"

    CT_Popd

    CT_EndStep
}

# Build cctools for host -> target
do_binutils_for_host() {
    local -a cctools_opts
    local -a odcctools_opts

    CT_DoStep INFO "Installing cctools for host"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-cctools-host-${CT_HOST}"

    cctools_opts+=( "host=${CT_HOST}" )
    cctools_opts+=( "cflags=${CT_CFLAGS_FOR_HOST}" )
    cctools_opts+=( "ldflags=${CT_LDFLAGS_FOR_HOST}" )
    cctools_opts+=( "prefix=${CT_PREFIX_DIR}" )

    do_cctools_backend "${cctools_opts[@]}"

    mkdir -p "${CT_BUILDTOOLS_PREFIX_DIR}/${CT_TARGET}/bin"

    CT_Popd

    CT_mkdir_pushd "${CT_BUILD_DIR}/build-odcctools-host-${CT_HOST}"

    odcctools_opts+=( "host=${CT_HOST}" )
    odcctools_opts+=( "cflags=${CT_CFLAGS_FOR_HOST}" )
    odcctools_opts+=( "ldflags=${CT_LDFLAGS_FOR_HOST}" )
    odcctools_opts+=( "prefix=${CT_PREFIX_DIR}" )

    do_odcctools_backend "${odcctools_opts[@]}"

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
    CFLAGS="${cflags} -isystem ${CT_BUILDTOOLS_PREFIX_DIR}/include/" 	\
    CXXFLAGS="${cflags} -isystem ${CT_BUILDTOOLS_PREFIX_DIR}/include/" 	\
    LDFLAGS="${ldflags} -L${CT_BUILDTOOLS_PREFIX_DIR}/lib/"             \
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

# Build odcctools for X -> target
#     Parameter     : description               : type      : default
#     host          : machine to run on         : tuple     : (none)
#     prefix        : prefix to install into    : dir       : (none)
#     cflags        : host cflags to use        : string    : (empty)
#     ldflags       : host ldflags to use       : string    : (empty)
do_odcctools_backend() {
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

    CT_DoLog EXTRA "Configuring odcctools"
    CT_DoExecLog CFG \
    CFLAGS="${cflags} -isystem ${CT_BUILDTOOLS_PREFIX_DIR}/include/" 		 \
    CXXFLAGS="${cflags} -isystem ${CT_BUILDTOOLS_PREFIX_DIR}/include/" 		 \
    LDFLAGS="${ldflags} -L${CT_BUILDTOOLS_PREFIX_DIR}/lib/" 			 \
    "${CT_SRC_DIR}/odcctools-${CT_ODCCTOOLS_VERSION}/odcctools-9.2-ld/configure" \
        --build=${CT_BUILD}                                     \
        --host=${host}                                          \
        --target=${CT_TARGET}                                   \
        --prefix=${prefix}                                      \
        --disable-werror                                        \
        "${extra_config[@]}"                                    \
        ${CT_ARCH_WITH_FLOAT}                                   \
        ${BINUTILS_SYSROOT_ARG}                                 \
        --enable-ld64

    CT_DoLog EXTRA "Building odcctools"
    CT_Pushd libstuff
    CT_DoExecLog ALL make
    CT_Popd
    CT_Pushd ld64
    CT_DoExecLog ALL make

    CT_DoLog EXTRA "Installing odcctools"
    CT_DoExecLog ALL make install

    echo "int main(int argc, char*argv[]){return 0;}" > dsymutil.c
    CT_DoExecLog CFG \
    CFLAGS="${cflags} -isystem ${CT_BUILDTOOLS_PREFIX_DIR}/include/"             \
    CXXFLAGS="${cflags} -isystem ${CT_BUILDTOOLS_PREFIX_DIR}/include/"           \
    LDFLAGS="${ldflags} -L${CT_BUILDTOOLS_PREFIX_DIR}/lib/"                      \
    gcc dsymutil.c                                                               \
    -o $prefix/bin/${CT_TARGET}-dsymutil

    mv "${prefix}/bin/${CT_TARGET}-ld" "${prefix}/bin/${CT_TARGET}-ld_classic"
    ln -sv "${prefix}/bin/${CT_TARGET}-ld64" "${prefix}/bin/${CT_TARGET}-ld"

    CT_Popd
}
