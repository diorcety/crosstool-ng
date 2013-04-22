# This file adds the functions to build the LLVM library
# Copyright 2012 Yann Diorcet
# Licensed under the GPL v2. See COPYING in the root of this package

do_llvm-compiler-rt_get() { :; }
do_llvm-compiler-rt_extract() { :; }
do_llvm-compiler-rt_for_build() { :; }
do_llvm-compiler-rt_for_host() { :; }

# Overide functions depending on configuration
if [ "${CT_LLVM_COMPILER_RT}" = "y" ]; then

# Download LLVM Compiler-rt
do_llvm-compiler-rt_get() {
    CT_GetFile "compiler-rt-${CT_LLVM_COMPILER_RT_VERSION}.src" \
               http://llvm.org/releases/${CT_LLVM_VERSION}
}

# Extract LLVM
do_llvm-compiler-rt_extract() {
    CT_Extract "compiler-rt-${CT_LLVM_COMPILER_RT_VERSION}.src"
    
    CT_Pushd "${CT_SRC_DIR}/compiler-rt-${CT_LLVM_COMPILER_RT_VERSION}.src"
    CT_Patch nochdir "compiler-rt" "${CT_LLVM_COMPILER_RT_VERSION}"
    CT_Popd
    
    CT_DoExecLog ALL \
    cp -aT "${CT_SRC_DIR}/compiler-rt-${CT_LLVM_COMPILER_RT_VERSION}.src" "${CT_SRC_DIR}/llvm-${CT_LLVM_VERSION}.src/projects/compiler-rt"
}

# Build LLVM Compiler-rt for running on build
# - always build statically
# - we do not have build-specific CFLAGS
# - install in build-tools prefix
do_llvm-compiler-rt_for_build() {
    local -a llvm_compiler_rt_opts

    case "${CT_TOOLCHAIN_TYPE}" in
        native|cross)   return 0;;
    esac

    CT_DoStep INFO "Installing LLVM for build"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-LLVM-COMPILER-RT-build-${CT_BUILD}"

    llvm_compiler_rt_opts+=( "host=${CT_BUILD}" )
    llvm_compiler_rt_opts+=( "prefix=${CT_BUILDTOOLS_PREFIX_DIR}" )
    do_llvm-compiler-rt_backend "${llvm_compiler_rt_opts[@]}"

    CT_Popd
    CT_EndStep
}

# Build LLVM for running on host
do_llvm-compiler-rt_for_host() {
    local -a llvm_compiler_rt_opts

    CT_DoStep INFO "Installing LLVM for host"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-LLVM-COMPILER-RT-host-${CT_HOST}"

    llvm_compiler_rt_opts+=( "host=${CT_HOST}" )
    llvm_compiler_rt_opts+=( "prefix=${CT_PREFIX_DIR}" )
    llvm_compiler_rt_opts+=( "cflags=${CT_CFLAGS_FOR_HOST}" )
    do_llvm-compiler-rt_backend "${llvm_compiler_rt_opts[@]}"

    CT_Popd
    CT_EndStep
}

# Build LLVM
#     Parameter     : description               : type      : default
#     host          : machine to run on         : tuple     : (none)
#     prefix        : prefix to install into    : dir       : (none)
#     cflags        : host cflags to use        : string    : (empty)
do_llvm-compiler-rt_backend() {
    local host
    local prefix
    local cflags
    local arg

    for arg in "$@"; do
        eval "${arg// /\\ }"
    done

    CT_DoLog EXTRA "Configuring LLVM Compiler-rt"

    #CT_DoExecLog CFG                                      \
    #CFLAGS="${cflags}"                                    \
    #"${CT_SRC_DIR}/compiler-rt-${CT_LLVM_COMPILER_RT_VERSION}.src/configure" \
    #    --build=${CT_BUILD}                               \
    #    --host=${host}                                    \
    #    --prefix="${prefix}"                              \

    CT_DoLog EXTRA "Building LLVM Compiler-rt"
    #CT_DoExecLog ALL make ${JOBSFLAGS}

    CT_DoLog EXTRA "Installing LLVM Compiler-rt"
    #CT_DoExecLog ALL make install
}

fi # CT_LLVM
