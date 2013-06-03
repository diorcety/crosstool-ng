# This file adds the function to build the clang C compiler
# Copyright 2012 Yann Diorcet
# Licensed under the GPL v2. See COPYING in the root of this package

CC_LLVMGCC_FULLNAME="${CT_CC_LLVMGCC_PREFIX}-${CT_CC_LLVMGCC_VERSION}${CT_CC_LLVMGCC_SUFFIX}"

# Download clang

if [ "${CC_CLANG_V_3_1}" = "y" ]; then
	CLANG_SUFFIX=".src"
else
	CLANG_SUFFIX=""
fi

do_clang_get() {
    CT_GetFile "clang-${CT_CC_CLANG_VERSION}${CLANG_SUFFIX}" \
               http://llvm.org/releases/${CT_CC_CLANG_VERSION}
}

# Extract clang
do_clang_extract() {
    CT_Extract "clang-${CT_CC_CLANG_VERSION}${CLANG_SUFFIX}"
    
    CT_Pushd "${CT_SRC_DIR}/clang-${CT_CC_CLANG_VERSION}${CLANG_SUFFIX}"
    CT_Patch nochdir "clang" "${CT_CC_CLANG_VERSION}"
    CT_Popd

    # Is this strictly needed even when not using Apple's tarballs?
    if [ ! "${CT_CC_LLVMGCC_PREFIX}" = "llvmgcc42" ]; then
        CT_DoExecLog ALL \
        cp -aT "${CT_SRC_DIR}/clang-${CT_CC_CLANG_VERSION}${CLANG_SUFFIX}" "${CT_SRC_DIR}/${CC_LLVMGCC_FULLNAME}/tools/clang"
    fi
}

#------------------------------------------------------------------------------
# Core clang pass 1
do_clang_core_pass_1() {
    :
}

# Core clang pass 2
do_clang_core_pass_2() {
    :
}

#------------------------------------------------------------------------------
# Build core clang
do_clang_core_backend() {
    :
}

#------------------------------------------------------------------------------
# Build complete clang to run on build
do_clang_for_build() {
    :
}

#------------------------------------------------------------------------------
# Build final clang to run on host
do_clang_for_host() {
    :
}

#------------------------------------------------------------------------------
# Build the final clang
do_clang_backend() {
    :
}
