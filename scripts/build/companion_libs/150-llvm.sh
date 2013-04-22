# This file adds the functions to build the LLVM library
# Copyright 2012 Yann Diorcet
# Licensed under the GPL v2. See COPYING in the root of this package

do_llvm_get() { :; }
do_llvm_extract() { :; }
do_llvm_for_build() { :; }
do_llvm_for_host() { :; }

# Overide functions depending on configuration
if [ "${CT_LLVM}" = "y" ]; then

if [ "${CC_LLVM_V_3_1}" = "y" ]; then
	LLVM_SUFFIX=".src"
else
	LLVM_SUFFIX=""
fi
	
# Download LLVM
do_llvm_get() {
    CT_GetFile "llvm-${CT_LLVM_VERSION}${LLVM_SUFFIX}" \
               http://llvm.org/releases/${CT_LLVM_VERSION}
}

# Extract LLVM
do_llvm_extract() {
    CT_Extract "llvm-${CT_LLVM_VERSION}${LLVM_SUFFIX}"
    
    CT_Pushd "${CT_SRC_DIR}/llvm-${CT_LLVM_VERSION}${LLVM_SUFFIX}"
    CT_Patch nochdir "llvm" "${CT_LLVM_VERSION}"
    CT_Popd
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
    local arg

    for arg in "$@"; do
        eval "${arg// /\\ }"
    done

    CT_DoLog EXTRA "Configuring LLVM"

    CT_DoExecLog CFG                                      \
    CFLAGS="${cflags}"                                    \
    "${CT_SRC_DIR}/llvm-${CT_LLVM_VERSION}${LLVM_SUFFIX}/configure" \
        --build=${CT_BUILD}                               \
        --host=${host}                                    \
        --prefix="${prefix}"                              \
        --target=${CT_TARGET}                             \

    CT_DoLog EXTRA "Building LLVM"
    CT_DoExecLog ALL make ${JOBSFLAGS}

    CT_DoLog EXTRA "Installing LLVM"
    CT_DoExecLog ALL make install
}

fi # CT_LLVM
