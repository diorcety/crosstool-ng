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
CT_LLVM_SUFFIX=""
LLVM_GET_FN="CT_GetFile"
LLVM_URL=http://llvm.org/releases/${CT_LLVM_VERSION}
LLVM_CRT_URL=http://llvm.org/releases/${CT_LLVM_VERSION}

LLVM_BRANCH=""
LLVM_CRT_BRANCH=""
if [ "${CT_LLVM_V_3_1}" = "y" ]; then
    CT_LLVM_SUFFIX=".src"
elif [ "${CT_LLVM_V_3_2}" = "y" ]; then
    CT_LLVM_SUFFIX=".src"
elif [ "${CT_LLVM_V_3_3}" = "y" ]; then
    CT_LLVM_SUFFIX=".src"
elif [ "${CT_LLVM_V_3_4}" = "y" ]; then
    CT_LLVM_SUFFIX=".src"
elif [ "${CT_LLVM_V_3_4_2}" = "y" ]; then
    CT_LLVM_SUFFIX=".src"
elif [ "${CT_LLVM_V_3_5}" = "y" ]; then
    CT_LLVM_SUFFIX=".git"
    LLVM_GET_FN="CT_GetGit"
    LLVM_URL=http://llvm.org/git/llvm.git
    LLVM_BRANCH="master" # will be changed to release_35 when it's branched
    LLVM_CRT_URL=http://llvm.org/git/compiler-rt.git
    LLVM_CRT_BRANCH=${LLVM_BRANCH}
elif [ "${CT_LLVM_V_HEAD}" = "y" ]; then
    CT_LLVM_SUFFIX=".git"
    LLVM_GET_FN="CT_GetGit"
    LLVM_URL=http://llvm.org/git/llvm.git
    LLVM_BRANCH="master" # just to make git clone quicker
    LLVM_CRT_URL=http://llvm.org/git/compiler-rt.git
    LLVM_CRT_BRANCH=${LLVM_BRANCH} # just to make git clone quicker
fi

CT_LLVM_FULLNAME="llvm-${CT_LLVM_VERSION}${CT_LLVM_SUFFIX}"

# Download LLVM
do_llvm_get() {
    if [ -z "${LLVM_BRANCH}" ]; then
        $LLVM_GET_FN "${CT_LLVM_FULLNAME}" "${LLVM_URL}"
    else
        $LLVM_GET_FN "${CT_LLVM_FULLNAME}" "branch" "${LLVM_BRANCH}" "${LLVM_URL}"
    fi

    if [ "${CT_LLVM_COMPILER_RT}" = "y" ]; then
        $LLVM_GET_FN "compiler-rt-${CT_LLVM_VERSION}${CT_LLVM_SUFFIX}" \
               "${LLVM_CRT_BRANCH}" "${LLVM_CRT_URL}"
    fi
}

# Extract LLVM
do_llvm_extract() {
    CT_Extract "${CT_LLVM_FULLNAME}"
    
    CT_Pushd "${CT_SRC_DIR}/${CT_LLVM_FULLNAME}"
    CT_Patch nochdir "llvm" "${CT_LLVM_VERSION}"
    CT_Popd
    
    if [ "${CT_LLVM_COMPILER_RT}" = "y" ]; then
        CT_Extract "compiler-rt-${CT_LLVM_VERSION}${CT_LLVM_SUFFIX}"
        
        CT_Pushd "${CT_SRC_DIR}/compiler-rt-${CT_LLVM_VERSION}${CT_LLVM_SUFFIX}"
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
	cp -r "${CT_SRC_DIR}/compiler-rt-${CT_LLVM_VERSION}${CT_LLVM_SUFFIX}/"* "projects/compiler-rt/"
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
