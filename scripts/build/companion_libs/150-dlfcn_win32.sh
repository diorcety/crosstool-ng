# This file adds the functions to build the dlfcn-win32 library
# Copyright 2015 Ray Donnelly
# Licensed under the GPL v2. See COPYING in the root of this package

do_dlfcn_win32_get() { :; }
do_dlfcn_win32_extract() { :; }
do_dlfcn_win32_for_build() { :; }
do_dlfcn_win32_for_host() { :; }

if [ "${CT_DLFCN_WIN32}" = "y" ]; then

CT_DLFCN_WIN32_VERSION_DOWNLOADED=

do_dlfcn_win32_get() {
    CT_DoStep INFO "Fetching dlfcn-win32 source for ${CT_DLFCN_WIN32_VERSION}"
    if [ "${CT_DLFCN_WIN32_VERSION}" = "devel" ]; then
        CT_GetGit "dlfcn-win32" "ref=HEAD" "https://github.com/dlfcn-win32/dlfcn-win32" CT_DLFCN_WIN32_VERSION_DOWNLOADED
        CT_DoLog EXTRA "Fetched as ${CT_DLFCN_WIN32_VERSION_DOWNLOADED}"
    else
        CT_GetFile "dlfcn-win32-${CT_DLFCN_WIN32_VERSION}" \
            https://github.com/dlfcn-win32/dlfcn-win32/archive/v${CT_DLFCN_WIN32_VERSION}
        CT_DLFCN_WIN32_VERSION_DOWNLOADED=${CT_DLFCN_WIN32_VERSION}
    fi
    CT_EndStep
}

do_dlfcn_win32_extract() {
    CT_Extract "dlfcn-win32-${CT_DLFCN_WIN32_VERSION_DOWNLOADED}"
    CT_Pushd "${CT_SRC_DIR}/dlfcn-win32-${CT_DLFCN_WIN32_VERSION_DOWNLOADED}/"
    CT_Patch nochdir dlfcn-win32 "${CT_DLFCN_WIN32_VERSION_DOWNLOADED}"
    CT_Popd
}

# Build dlfcn-win32 for running on build
# - always build statically
# - we do not have build-specific CFLAGS
# - install in build-tools prefix
do_dlfcn_win32_for_build() {
    local -a dlfcn_win32_opts
    local dlfcn_win32_cflags

    if [ "${CT_BUILD}" = "${CT_BUILD/mingw/}" ]; then
      return
    fi

    CT_DoStep INFO "Building dlfcn-win32 for build"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-dlfcn-win32-build-${CT_BUILD}"
    dlfcn_win32_cflags="${CT_CFLAGS_FOR_BUILD}"

    dlfcn_win32_opts+=( "cc=${CT_BUILD}-gcc" )
    dlfcn_win32_opts+=( "crossprefix=${CT_BUILD}-" )
    dlfcn_win32_opts+=( "prefix=${CT_BUILDTOOLS_PREFIX_DIR}" )
    dlfcn_win32_opts+=( "cflags=${dlfcn_win32_cflags}" )
    do_dlfcn_win32_backend "${dlfcn_win32_opts[@]}"

    CT_Popd
    CT_EndStep
}
# Build dlfcn-win32 for running on host
do_dlfcn_win32_for_host() {
    local -a dlfcn_win32_opts
    local dlfcn_win32_cflags

    if [ "${CT_HOST}" = "${CT_HOST/mingw/}" ]; then
      return
    fi

    CT_DoStep INFO "Installing dlfcn-win32 for host"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-dlfcn-win32-host-${CT_HOST}"

    dlfcn_win32_cflags="${CT_CFLAGS_FOR_HOST}"

    dlfcn_win32_opts+=( "cc=${CT_HOST}-gcc" )
    dlfcn_win32_opts+=( "crossprefix=${CT_HOST}-" )
    dlfcn_win32_opts+=( "prefix=${CT_HOST_COMPLIBS_DIR}" )
    dlfcn_win32_opts+=( "cflags=${dlfcn_win32_cflags}" )
    do_dlfcn_win32_backend "${dlfcn_win32_opts[@]}"

    CT_Popd
    CT_EndStep
}


# Build dlfcn-win32
#     Parameter     : description               : type      : default
#     prefix        : prefix to install into    : dir       : (none)
#     cc            : c compiler to use         : string    : (empty)
#     cross-prefix  : cross tools prefix to use : string    : (empty)
#     cflags        : cflags to use             : string    : (empty)
#     ldflags       : ldflags to use            : string    : (empty)
do_dlfcn_win32_backend() {
    local prefix
    local cc
    local crossprefix
    local cflags
    local ldflags
    local arg

    for arg in "$@"; do
        eval "${arg// /\\ }"
    done

    CT_DoLog EXTRA "Configuring dlfcn-win32"

    cp -rf "${CT_SRC_DIR}"/dlfcn-win32-${CT_DLFCN_WIN32_VERSION_DOWNLOADED}/* .
    CT_DoExecLog CFG                                                           \
    CFLAGS="${cflags}"                                                         \
    LDFLAGS="${ldflags}"                                                       \
    ./configure \
        --prefix="${prefix}"                                                   \
        --cc="${cc}"                                                           \
        --cross-prefix="${crossprefix}"                                        \
        --disable-shared                                                       \
        --enable-static

    CT_DoLog EXTRA "Building dlfcn-win32"
    CT_DoExecLog ALL make ${JOBSFLAGS}

    if [ "${CT_COMPLIBS_CHECK}" = "y" ]; then
        CT_DoLog EXTRA "Checking dlfcn-win32"
        CT_DoExecLog ALL make ${JOBSFLAGS} -s check
    fi

    CT_DoLog EXTRA "Installing dlfcn-win32"
    CT_DoExecLog ALL make install
}

fi # CT_DLFCN_WIN32
