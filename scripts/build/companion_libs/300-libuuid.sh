# Build script for libuuid

do_libuuid_get() { :; }
do_libuuid_extract() { :; }
do_libuuid_for_build() { :; }
do_libuuid_for_host() { :; }

if [ "${CT_LIBUUID}" = "y" ]; then

do_libuuid_get() {
    if [ "${CT_LIBUUID_UTILLINUX}" = "y" ]; then
        CT_GetFile "util-linux-${CT_LIBUUID_UTILLINUX_VERSION}" \
                   http://www.kernel.org/pub/linux/utils/util-linux/v2.20
    elif [ "${CT_LIBUUID_E2FSPROGSLIBS}" = "y" ]; then
        CT_GetFile "e2fsprogs-libs-${CT_LIBUUID_E2FSPROGSLIBS_VERSION}" \
                   http://downloads.sourceforge.net/project/e2fsprogs/e2fsprogs/${CT_LIBUUID_E2FSPROGSLIBS_VERSION}
    fi
}

do_libuuid_extract() {
    if [ "${CT_LIBUUID_UTILLINUX}" = "y" ]; then    
        CT_Extract "util-linux-${CT_LIBUUID_UTILLINUX_VERSION}"
        CT_Patch "util-linux" "${CT_LIBUUID_UTILLINUX_VERSION}"
    elif [ "${CT_LIBUUID_E2FSPROGSLIBS}" = "y" ]; then
        CT_Extract "e2fsprogs-libs-${CT_LIBUUID_E2FSPROGSLIBS_VERSION}"
        CT_Patch "e2fsprogs-libs" "${CT_LIBUUID_E2FSPROGSLIBS_VERSION}"
    fi
}

# Build libuuid for running on build
do_libuuid_for_build() {
     local -a libuuid_opts

    case "${CT_TOOLCHAIN_TYPE}" in
        native|cross)   return 0;;
    esac

    CT_DoStep INFO "Installing libuuid for build"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-libuuid-build-${CT_BUILD}"

    libuuid_opts+=( "host=${CT_BUILD}" )
    libuuid_opts+=( "prefix=${CT_BUILDTOOLS_PREFIX_DIR}" )
    libuuid_opts+=( "cflags=${CT_CFLAGS_FOR_BUILD}" ) 
    libuuid_opts+=( "ldflags=${CT_LDFLAGS_FOR_BUILD}" )

    if [ "${CT_LIBUUID_UTILLINUX}" = "y" ]; then
        do_libuuid_utillinux_backend "${libuuid_opts[@]}"
    elif [ "${CT_LIBUUID_E2FSPROGSLIBS}" = "y" ]; then
        do_libuuid_e2fsprogslibs_backend "${libuuid_opts[@]}"
    fi

    CT_Popd
    CT_EndStep
}

# Build libuuid for running on host
do_libuuid_for_host() {
    local -a libuuid_opts

    CT_DoStep INFO "Installing libuuid for host"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-libuuid-host-${CT_HOST}"

    libuuid_opts+=( "host=${CT_HOST}" )
    libuuid_opts+=( "prefix=${CT_HOST_COMPLIBS_DIR}" )
    libuuid_opts+=( "cflags=${CT_CFLAGS_FOR_HOST}" )
    libuuid_opts+=( "ldflags=${CT_LDFLAGS_FOR_HOST}" )     
    libuuid_opts+=( "static_build=${CT_STATIC_TOOLCHAIN}" )

    if [ "${CT_LIBUUID_UTILLINUX}" = "y" ]; then
        do_libuuid_utillinux_backend "${libuuid_opts[@]}"
    elif [ "${CT_LIBUUID_E2FSPROGSLIBS}" = "y" ]; then
        do_libuuid_e2fsprogslibs_backend "${libuuid_opts[@]}"
    fi

    CT_Popd
    CT_EndStep
}

# Build libuuid with utillinux
#     Parameter     : description               : type      : default
#     host          : machine to run on         : tuple     : (none)
#     prefix        : prefix to install into    : dir       : (none)
#     cflags        : host cflags to use        : string    : (empty)
#     ldflags       : host ldflags to use       : string    : (empty)
do_libuuid_utillinux_backend() {
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
        extra_config+=("--disable-shared")
    fi

    CT_DoLog EXTRA "Configuring libuuid(utillinux)"

    CT_DoExecLog CFG                                                      \
    CFLAGS="${cflags}"                                                    \
    LDFLAGS="${ldflags}"                                                  \
    "${CT_SRC_DIR}/util-linux-${CT_LIBUUID_UTILLINUX_VERSION}/configure"  \
        --prefix="${prefix}"                                              \
        --host="${host}"                                                  \
        --build=${CT_BUILD}                                               \
        --without-ncurses                                                 \
        --disable-makeinstall-chown                                       \
        "${extra_config[@]}"                                              \

    CT_Pushd libuuid
    CT_DoLog EXTRA "Building libuuid(utillinux)"
    CT_DoExecLog ALL make ${JOBSFLAGS}

    CT_DoLog EXTRA "Installing libuuid(utillinux)"
    CT_DoExecLog ALL make install
    CT_Popd
}

# Build libuuid with e2fsprogslibs
#     Parameter     : description               : type      : default
#     host          : machine to run on         : tuple     : (none)
#     prefix        : prefix to install into    : dir       : (none)
#     cflags        : host cflags to use        : string    : (empty)
#     ldflags       : host ldflags to use       : string    : (empty)
do_libuuid_e2fsprogslibs_backend() {
    local host
    local prefix
    local cflags
    local ldflags
    local arg
    local -a extra_config

    for arg in "$@"; do
        eval "${arg// /\\ }"
    done

    if [ "${static_build}" = "y" ]; then
        extra_config+=("--disable-elf-shlibs")
    fi

    CT_DoLog EXTRA "Configuring libuuid(e2fsprogslibs)"

    CT_DoExecLog CFG                                                             \
    CFLAGS="${cflags}"                                                           \
    LDFLAGS="${ldflags}"                                                         \
    "${CT_SRC_DIR}/e2fsprogs-libs-${CT_LIBUUID_E2FSPROGSLIBS_VERSION}/configure" \
        --prefix="${prefix}"                                                     \
        --host="${host}"                                                         \
        --build=${CT_BUILD}                                                      \
        --disable-uuidd                                                          \
        "${extra_config[@]}"                                                     \

    CT_Pushd lib/uuid
    CT_DoLog EXTRA "Building libuuid(e2fsprogslibs)"
    CT_DoExecLog ALL make ${JOBSFLAGS}

    CT_DoLog EXTRA "Installing libuuid(e2fsprogslibs)"
    CT_DoExecLog ALL make install
    CT_Popd
}


fi
