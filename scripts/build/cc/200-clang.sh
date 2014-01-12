# This file adds the function to build the clang C compiler
# Copyright 2012 Yann Diorcet
# Licensed under the GPL v2. See COPYING in the root of this package

# Override variable depending on configuration
CLANG_GET_FN="CT_GetFile"
CLANG_SUFFIX=""
CLANG_NAME="clang"
CLANG_BRANCH=""
CLANG_URL=http://llvm.org/releases/${CT_CC_CLANG_VERSION}
if [ "${CT_CC_CLANG_V_3_1}" = "y" ]; then
	CLANG_SUFFIX=".src"
	CLANG_NAME="clang"
elif [ "${CT_CC_CLANG_V_3_2}" = "y" ]; then
	CLANG_SUFFIX=".src"
	CLANG_NAME="clang"
elif [ "${CT_CC_CLANG_V_3_3}" = "y" ]; then
	CLANG_SUFFIX=".src"
	CLANG_NAME="cfe"
elif [ "${CT_CC_CLANG_V_3_4}" = "y" ]; then
    CLANG_SUFFIX=".src"
    CLANG_NAME="cfe"
elif [ "${CT_CC_CLANG_V_3_5}" = "y" ]; then
    CLANG_SUFFIX=".git"
    CLANG_NAME="cfe"
    CLANG_GET_FN="CT_GetGit"
    CLANG_URL=http://llvm.org/git/clang.git
    CLANG_BRANCH="master" #will be release_35 when it is branched
elif [ "${CT_CC_CLANG_V_HEAD}" = "y" ]; then
	CLANG_SUFFIX=".git"
	CLANG_NAME="cfe"
	CLANG_GET_FN="CT_GetGit"
	CLANG_URL=http://llvm.org/git/clang.git
    CLANG_BRANCH="master" # just to make git clone quicker
fi

CT_CLANG_FULLNAME="${CLANG_NAME}-${CT_CC_CLANG_VERSION}${CLANG_SUFFIX}"

# Download clang
do_clang_get() {
    if [ -z "${CLANG_BRANCH}" ]; then
        $CLANG_GET_FN "${CT_CLANG_FULLNAME}" "${CLANG_URL}"
    else
        $CLANG_GET_FN "${CT_CLANG_FULLNAME}" "branch" "${CLANG_BRANCH}" "${CLANG_URL}"
    fi
}

# Extract clang
do_clang_extract() {
    CT_Extract "${CT_CLANG_FULLNAME}"
    
    CT_Pushd "${CT_SRC_DIR}/${CT_CLANG_FULLNAME}"
    CT_Patch nochdir "clang" "${CT_CC_CLANG_VERSION}"
    CT_Popd
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
    local -a final_opts

    # In case we're canadian or cross-native, it seems that a
    # real, complete compiler is needed?!? WTF? Sigh...
    # Otherwise, there is nothing to do.
    case "${CT_TOOLCHAIN_TYPE}" in
        native|cross)   return 0;;
    esac

    CT_DoStep INFO "Installing final clang compiler for build"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-cc-clang-final-build"
    
    final_opts+=( "host=${CT_BUILD}" )
    final_opts+=( "prefix=${CT_BUILDTOOLS_PREFIX_DIR}" )
    final_opts+=( "cflags=${CT_CFLAGS_FOR_BUILD}" )
    final_opts+=( "ldflags=${CT_LDFLAGS_FOR_BUILD}" )     

    do_clang_backend "${final_opts[@]}"

    CT_Popd
    CT_EndStep
}

#------------------------------------------------------------------------------
# Build final clang to run on host
do_clang_for_host() {
    local -a final_opts

    CT_DoStep INFO "Installing final clang compiler"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-cc-clang-final"
    
    final_opts+=( "host=${CT_HOST}" )
    final_opts+=( "prefix=${CT_PREFIX_DIR}" )
    final_opts+=( "cflags=${CT_CFLAGS_FOR_HOST}" )
    final_opts+=( "ldflags=${CT_LDFLAGS_FOR_HOST}" )     

    do_clang_backend "${final_opts[@]}"

    CT_Popd
    CT_EndStep
}

#------------------------------------------------------------------------------
# Build the final clang
do_clang_backend() {
    local host
    local prefix
    local cflags
    local ldflags
    local arg
    local -a final_CFLAGS

    for arg in "$@"; do
        eval "${arg// /\\ }"
    done

    cp -r "${CT_SRC_DIR}/${CT_LLVM_FULLNAME}/"* "."
    mkdir "tools/clang"
    cp -r "${CT_SRC_DIR}/${CT_CLANG_FULLNAME}/"* "tools/clang/"
    if [ "${CT_LLVM_COMPILER_RT}" = "y" ]; then
	mkdir "projects/compiler-rt"
	cp -r "${CT_SRC_DIR}/compiler-rt-${CT_LLVM_VERSION}${CLANG_SUFFIX}/"* "projects/compiler-rt/"
    fi

    final_CFLAGS+=("${cflags}")
    if [ "${CT_CC_GCC_APPLE}" = "y" ]; then
        final_CFLAGS+=("-DCLANG_GCC_VERSION=4.2.1")
    else
        final_CFLAGS+=("-DCLANG_GCC_VERSION=${CT_CC_GCC_VERSION}")
    fi

    if [ "${CT_DEBUGGABLE_TOOLCHAIN}" = "y" ]; then
        OPTIM_CONFIG_FLAG="--enable-optimized=no"
        OPTIM_MAKE_FLAG="ENABLE_OPTIMIZED=0"
    else
        OPTIM_CONFIG_FLAG="--enable-optimized=yes"
        OPTIM_MAKE_FLAG="ENABLE_OPTIMIZED=1"
    fi

    CT_DoLog EXTRA "Configuring clang"

    CT_DoExecLog CFG                  \
    CFLAGS="${final_CFLAGS[*]}"       \
    CXXFLAGS="${final_CFLAGS[*]}"     \
    LDFLAGS="${ldflags}"              \
    ./configure                       \
        --build=${CT_BUILD}           \
        --host=${host}                \
        --prefix="${prefix}"          \
        --target=${CT_TARGET}         \
        ${OPTIM_CONFIG_FLAG}          \
        

    CT_DoLog EXTRA "Building clang"
    CT_DoExecLog ALL                  \
    make ${JOBSFLAGS}                 \
        CFLAGS="${final_CFLAGS[*]}"   \
        CXXFLAGS="${final_CFLAGS[*]}" \
        LDFLAGS="${ldflags}"          \
        ONLY_TOOLS="clang"            \
        ${OPTIM_MAKE_FLAG}            \

    CT_Pushd "tools/clang/"

    CT_DoLog EXTRA "Installing clang"
    CT_DoExecLog ALL make install     \
        CFLAGS="${final_CFLAGS[*]}"   \
        CXXFLAGS="${final_CFLAGS[*]}" \
        LDFLAGS="${ldflags}"          \
        ONLY_TOOLS="clang"            \
        ${OPTIM_MAKE_FLAG}            \
        
    CT_Popd

    # clang > 3.1 creates ${CT_TARGET}- prefixed executables already.
    # So do the same for clang > 2.9. Earlier versions don't have the
    # code to detect the prefixes so they need wrapper shell scripts.
    if [ "${CT_CC_CLANG_V_3_1}" = "y" -o "${CT_CC_CLANG_V_3_0}" = "y" ]; then
        for cc in clang clang++; do
            CT_Pushd "${prefix}/bin"
            ln -s ${cc} ${CT_TARGET}-${cc}
            CT_Popd
        done
    elif [ "${CT_CC_CLANG_V_2_9}" = "y" -o "${CT_CC_CLANG_V_2_8}" = "y" -o "${CT_CC_CLANG_V_2_7}" = "y" ]; then
        for cc in clang clang++; do
            gcc=${cc/clang/gcc}
            gcc=${gcc/gcc++/g++}
            cat > ${prefix}/bin/${CT_TARGET}-${cc} << EOF
#!/bin/sh
\`dirname \$0\`/${cc} \
-ccc-gcc-name ${CT_TARGET}-${gcc} \
-ccc-host-triple ${CT_TARGET} \
\$*
EOF
            chmod +x ${prefix}/bin/${CT_TARGET}-${cc}
        done
    fi
}
