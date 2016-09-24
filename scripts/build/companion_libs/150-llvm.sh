# This file adds the functions to build the LLVM library
# Copyright 2012 Yann Diorcet
# Licensed under the GPL v2. See COPYING in the root of this package

do_llvm_get() { :; }
do_llvm_extract() { :; }
do_llvm_for_build() { :; }
do_llvm_for_host() { :; }

# Overide functions depending on configuration
if [ "${CT_LLVM}" = "y" ]; then

# Override variable depending on configuration
LLVM_GET_FN="CT_GetFile"
LLVM_SUFFIX=""
LLVM_BRANCH=""
LLVM_URL=http://llvm.org/releases
CT_LLVM_FULLNAME=
CT_COMPILER_RT_FULLNAME=
# Comment this out to fetch from the internet.
CT_LOCAL_LLVM_GIT_PATH=file:///f/upstreams/llvm

if [ "${CT_LLVM_V_3_1}" = "y" ]; then
    LLVM_SUFFIX=".src"
elif [ "${CT_LLVM_V_3_2}" = "y" ]; then
    LLVM_SUFFIX=".src"
elif [ "${CT_LLVM_V_3_3}" = "y" ]; then
    LLVM_SUFFIX=".src"
elif [ "${CT_LLVM_V_3_4}" = "y" ]; then
    LLVM_SUFFIX=".src"
elif [ "${CT_LLVM_V_3_4_2}" = "y" ]; then
    LLVM_SUFFIX=".src"
elif [ "${CT_LLVM_V_3_5_2}" = "y" ]; then
    LLVM_SUFFIX=".src"
elif [ "${CT_LLVM_V_3_6_2}" = "y" ]; then
    LLVM_SUFFIX=".src"
elif [ "${CT_LLVM_V_3_8_1}" = "y" ]; then
    LLVM_SUFFIX=".src"
elif [ "${CT_LLVM_V_3_9_0}" = "y" ]; then
    LLVM_GET_FN="CT_GitGet"
    if [ -z "${CT_LOCAL_LLVM_GIT_PATH}" ]; then
        LLVM_URL=http://llvm.org/git
        LLVM_SUFFIX=".git"
    else
        LLVM_URL=${CT_LOCAL_LLVM_GIT_PATH}
        LLVM_SUFFIX=""
    fi
    LLVM_BRANCH="release_39"
elif [ "${CT_LLVM_V_DEVEL}" = "y" ]; then
    LLVM_GET_FN="CT_GitGet"
    if [ -z "${CT_LOCAL_LLVM_GIT_PATH}" ]; then
        LLVM_URL=http://llvm.org/git
        LLVM_SUFFIX=".git"
    else
        LLVM_URL=${CT_LOCAL_LLVM_GIT_PATH}
        LLVM_SUFFIX=""
    fi
    LLVM_BRANCH="master"
fi

# Fetch source code from a clang or llvm project
# Usage: do_clang_llvm_get param=value [...]
#   Parameter     : Definition                          : Type      : Default
#   getfn         : the function to do fetching         : string    : "CT_GetFile"
#   name          : the (proper) project name           : string    : (none)
#   archive_name  : the old archive name (cfe vs clang) : string    : ${name}
#   out_fname_var : final fname eval'ed into this       : var       : (none)
#   version       : version                             : string    : (none)
#   git_ref       : git reference                       : string    : (none)
#   base_url      : base URL                            : string    : (none)
#   url_suffix    : url suffix (e.g. .src)              : string    : (none)
do_clang_llvm_get() {
    local getfn=CT_GetFile
    local name
    local archive_name
    local out_fname_var
    local version
    local git_ref
    local base_url
    local url_suffix

    for arg in "$@"; do
        eval "${arg// /\\ }"
    done
    if [[ -z ${archive_name} ]]; then
        archive_name=${name}
    fi
    local _fullname

    CT_DoStep INFO "Fetching ${name}-${version} source from ${base_url}, out_fname_var is ${out_fname_var}"
    if [[ ${getfn} == CT_GetFile ]]; then
        _fullname=${archive_name}-${version}${url_suffix}
        CT_GetFile "${_fullname}" "${base_url}/${version}"
    else
        local -a _version_downloaded
        CT_GetGit ${name} "ref=${git_ref}" "${base_url}/${name}${url_suffix}" _version_downloaded
        _fullname="${name}-${_version_downloaded}"
    fi
    if [ -n "${out_fname_var}" ]; then
        eval ${out_fname_var}=\${_fullname}
    fi
    CT_EndStep
}

# Download llvm + possibly compiler_rt
do_llvm_get() {
    local -a opts
    opts+=( "getfn=${LLVM_GET_FN}" )
    opts+=( "name=llvm" )
    opts+=( "out_fname_var=CT_LLVM_FULLNAME" )
    opts+=( "version=${CT_LLVM_VERSION}" )
    opts+=( "git_ref=${LLVM_BRANCH}" )
    opts+=( "base_url=${LLVM_URL}" )
    opts+=( "url_suffix=${LLVM_SUFFIX}" )
    do_clang_llvm_get "${opts[@]}"
    CT_DoLog INFO "CT_LLVM_FULLNAME ${CT_LLVM_FULLNAME}"

    if [ "${CT_LLVM_COMPILER_RT}" = "y" ]; then
        opts+=( "name=compiler-rt" )
        opts+=( "out_fname_var=CT_COMPILER_RT_FULLNAME" )
        do_clang_llvm_get "${opts[@]}"
        CT_DoLog INFO "CT_COMPILER_RT_FULLNAME ${CT_COMPILER_RT_FULLNAME}"
    fi
}

# Extract llvm + possibly compiler_rt
do_llvm_extract() {
    CT_DoLog INFO "do_llvm_extract CT_LLVM_FULLNAME ${CT_LLVM_FULLNAME}"
    CT_Extract "${CT_LLVM_FULLNAME}"

    CT_Pushd "${CT_SRC_DIR}/${CT_LLVM_FULLNAME}"
    CT_Patch nochdir "llvm" "${CT_LLVM_VERSION}"
    CT_Popd

    if [ "${CT_LLVM_COMPILER_RT}" = "y" ]; then
        CT_DoLog INFO "do_llvm_extract CT_COMPILER_RT_FULLNAME ${CT_COMPILER_RT_FULLNAME}"
        CT_Extract "${CT_COMPILER_RT_FULLNAME}"

        CT_Pushd "${CT_SRC_DIR}/${CT_COMPILER_RT_FULLNAME}"
        CT_Patch nochdir "llvm-compiler-rt" "${CT_LLVM_VERSION}"
        CT_Popd
    fi
}

# Build LLVM for running on build
# - always build statically
# - we do not have build-specific CFLAGS
# - install in build-tools prefix
do_llvm_for_build() {
    local -a llvm_opts

    case "${CT_TOOLCHAIN_TYPE}" in
        native|cross)   return 0;;
    esac

    CT_DoStep INFO "Installing LLVM for build"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-LLVM-build-${CT_BUILD}"

    llvm_opts+=( "host=${CT_BUILD}" )
    llvm_opts+=( "prefix=${CT_BUILDTOOLS_PREFIX_DIR}" )
    llvm_opts+=( "cflags=${CT_CFLAGS_FOR_BUILD}" )
    llvm_opts+=( "ldflags=${CT_LDFLAGS_FOR_BUILD}" )     
    do_llvm_backend "${llvm_opts[@]}"

    CT_Popd
    CT_EndStep
}

# Build LLVM for running on host
do_llvm_for_host() {
    local -a llvm_opts

    CT_DoStep INFO "Installing LLVM for host"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-LLVM-host-${CT_HOST}"

    llvm_opts+=( "host=${CT_HOST}" )
    llvm_opts+=( "prefix=${CT_PREFIX_DIR}" )
    llvm_opts+=( "cflags=${CT_CFLAGS_FOR_HOST}" )
    llvm_opts+=( "ldflags=${CT_LDFLAGS_FOR_HOST}" )     
    do_llvm_backend "${llvm_opts[@]}"

    CT_Popd
    CT_EndStep
}

# Build LLVM
#     Parameter     : description               : type      : default
#     host          : machine to run on         : tuple     : (none)
#     prefix        : prefix to install into    : dir       : (none)
#     cflags        : host cflags to use        : string    : (empty)
do_llvm_backend() {
    local host
    local prefix
    local cflags
    local ldflags
    local arg
    local copydlls

    for arg in "$@"; do
        eval "${arg// /\\ }"
    done
    
    cp -r "${CT_SRC_DIR}/${CT_LLVM_FULLNAME}/"* "."
    if [ "${CT_LLVM_COMPILER_RT}" = "y" ]; then
	mkdir "projects/compiler-rt"
        cp -r "${CT_SRC_DIR}/${CT_COMPILER_RT_FULLNAME}/"* "projects/compiler-rt/"
    fi

    if [ "${CT_DEBUGGABLE_TOOLCHAIN}" = "y" ]; then
        OPTIM_CONFIG_FLAG="--enable-optimized=no"
        OPTIM_MAKE_FLAG="ENABLE_OPTIMIZED=0"
    else
        OPTIM_CONFIG_FLAG="--enable-optimized=yes"
        OPTIM_MAKE_FLAG="ENABLE_OPTIMIZED=1"
    fi

    CT_DoLog EXTRA "Configuring LLVM"

    CT_DoExecLog CFG                  \
    CFLAGS="${cflags}"                \
    CXXFLAGS="${cflags}"              \
    CPPFLAGS="${cflags}"              \
    LDFLAGS="${ldflags}"              \
    ./configure                       \
        --build=${CT_BUILD}           \
        --host=${host}                \
        --prefix="${prefix}"          \
        --target=${CT_TARGET}         \
        ${OPTIM_CONFIG_FLAG}          \

    CT_DoLog EXTRA "Building LLVM"
    CT_DoExecLog ALL                  \
    make ${JOBSFLAGS}                 \
    CFLAGS="${cflags}"                \
    CXXFLAGS="${cflags}"              \
    CPPFLAGS="${cflags}"              \
    LDFLAGS="${ldflags}"              \
    ${OPTIM_MAKE_FLAG}                \

    CT_DoLog EXTRA "Installing LLVM"
    CT_DoExecLog ALL make install     \
    ${OPTIM_MAKE_FLAG}                \

    # LLVM installs dlls into ${prefix}/lib instead of ${prefix}/bin
    # so copy them to ${prefix}/bin so that executables load them in
    # without requiring that ${prefix}/lib be added to PATH env. var
    copydlls="no"
    if [ ! "${host/mingw/}" = "${host}" -o ! "${host/cygwin/}" = "${host}" ]; then
        copydlls="yes"
    fi

    if [[ "$copydlls" = "yes" ]] ; then
        local dlls=$(find "${prefix}"/lib -name "*.dll")
        for dll in $dlls ; do
            cp -f "${dll}" "${prefix}"/bin/
        done
    fi
}

fi # CT_LLVM
