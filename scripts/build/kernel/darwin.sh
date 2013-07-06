# This file declares functions to install the kernel headers for Darwin.
# Copyright 2012 Yann Diorcet
# Licensed under the GPL v2. See COPYING in the root of this package

CT_DoKernelTupleValues() {
    CT_TARGET_KERNEL="darwin${CT_DARWIN_VERSION}"
    CT_TARGET_SYS=
}

do_kernel_extract() {
    :
}
do_kernel_get() {
    CT_DoStep INFO "Get kernel headers"
    CT_EndStep
}

# I'm not sure about the usr/ folder prefix. toolchain4 didn't have one finally, but does during the build process.
do_kernel_extract() {
    CT_DoStep INFO "Extract kernel headers and libraries"

    local _SRC="${CT_DARWIN_SDK_PATH}"
    local _TARGET="${CT_TARGET}"

    [ -d "${CT_SYSROOT_DIR}" ] || mkdir -p "${CT_SYSROOT_DIR}"
    CT_Pushd "${CT_SYSROOT_DIR}"

    declare -a SYSHEADERS
    if [ -z "$CT_ARCH_arm" ] ; then
        _SDKARCH=i686
        if [ ! -z "$CT_DARWIN_MAC_OSX_V_10_6" ] ; then
            SYSHEADERS=(libc.h stdio.h errno.h string.h strings.h alloca.h stdlib.h unistd.h time.h dlfcn.h limits.h _types.h _structs.h Availability.h AvailabilityMacros.h AvailabilityInternal.h vproc.h fcntl.h pthread.h pthread_impl.h sched.h sys/select.h sys/unistd.h sys/wait.h sys/errno.h sys/types.h sys/syslimits.h sys/_types.h sys/_endian.h sys/cdefs.h sys/appleapiopts.h sys/_structs.h sys/signal.h sys/resource.h sys/stat.h sys/_select.h sys/fcntl.h machine/types.h machine/endian.h machine/signal.h machine/limits.h machine/_structs.h machine/_limits.h machine/_types.h i386/types.h i386/_types.h i386/endian.h i386/limits.h i386/_limits.h i386/_structs.h i386/signal.h libkern/_OSByteOrder.h libkern/i386/_OSByteOrder.h mach/i386/_structs.h)
        else
            SYSHEADERS=(libc.h stdio.h errno.h string.h strings.h alloca.h stdlib.h unistd.h time.h dlfcn.h limits.h _types.h _structs.h Availability.h AvailabilityMacros.h AvailabilityInternal.h vproc.h fcntl.h pthread.h pthread_impl.h sched.h sys/select.h sys/unistd.h sys/wait.h sys/errno.h sys/types.h sys/syslimits.h sys/_types.h sys/_endian.h sys/cdefs.h sys/appleapiopts.h sys/_structs.h sys/_symbol_aliasing.h sys/_posix_availability.h sys/signal.h sys/resource.h sys/stat.h sys/_select.h sys/fcntl.h machine/types.h machine/endian.h machine/signal.h machine/limits.h machine/_structs.h machine/_limits.h machine/_types.h i386/types.h i386/_types.h i386/endian.h i386/limits.h i386/_limits.h i386/_structs.h i386/signal.h libkern/_OSByteOrder.h libkern/i386/_OSByteOrder.h mach/i386/_structs.h)
        fi
    else
        SYSHEADERS=(secure/_common.h secure/_stdio.h secure/_string.h stdint.h stdio.h errno.h string.h strings.h alloca.h stdlib.h unistd.h time.h dlfcn.h limits.h _types.h _structs.h Availability.h AvailabilityMacros.h AvailabilityInternal.h vproc.h fcntl.h pthread.h pthread_impl.h sched.h sys/select.h sys/unistd.h sys/wait.h sys/errno.h sys/types.h sys/syslimits.h sys/_types.h sys/_endian.h sys/cdefs.h sys/appleapiopts.h sys/_structs.h sys/_symbol_aliasing.h sys/_posix_availability.h sys/signal.h sys/resource.h sys/stat.h sys/_select.h sys/fcntl.h machine/types.h machine/endian.h machine/signal.h machine/limits.h machine/_structs.h                   machine/_types.h  arm/types.h  arm/_types.h  arm/endian.h  arm/limits.h  arm/_limits.h  arm/_structs.h  arm/signal.h libkern/_OSByteOrder.h libkern/arm/OSByteOrder.h   mach/arm/_structs.h arm/arch.h)
        _SDKARCH=arm
    fi

    [ -d usr ] && rm -rf usr
    mkdir usr
    [ -d $_TARGET ] && rm -rf $_TARGET
    mkdir $_TARGET

    # Ideally wouldn't be installing to both usr/include and $_TARGET/sys-include but instead 
    # to only $_TARGET/include
    declare -a DST_INCLUDE_FOLDERS
    DST_INCLUDE_FOLDERS=(usr/include $_TARGET/sys-include)

    for SYSHDR in ${SYSHEADERS[@]}; do
        for DST_INCLUDE in ${DST_INCLUDE_FOLDERS[@]}; do
            [ ! -d $DST_INCLUDE/$(dirname $SYSHDR) ] && mkdir -p $DST_INCLUDE/$(dirname $SYSHDR)
            cp -R -p $_SRC/usr/include/$SYSHDR $DST_INCLUDE/$(dirname $SYSHDR)
        done
    done

    # Since libstdc++ doesn't get built, we need to get the headers from an existing SDK.
    # May as well do that here, even though it's not needed for the build.
    CT_Pushd "${_SRC}/usr/include/c++"
    CXX_INCLUDES=$(find . -mindepth 2 -maxdepth 2) # -regex '.*/\([0-9]\.\)*[0-9]')
    CT_Popd

    for CXX_INCLUDE in $CXX_INCLUDES; do
        DSTDIR=usr/include/c++/$(echo "${CXX_INCLUDE}" | sed -r -e "s/darwin[0-9]*/darwin${CT_DARWIN_VERSION}/g")
        CT_DoExecLog ALL \
        mkdir -p $(dirname "${DSTDIR}")
        CT_DoExecLog ALL \
        cp -rf "${_SRC}/usr/include/c++/${CXX_INCLUDE}" "${DSTDIR}"
    done

    # libs needed:
    # In order to build libgcc_s.1.dylib, the 25 of the 26 dylibs in ${MACOSX}.sdk/usr/lib/system
    # must be available (the unneeded one is libkxld.dylib)
    # .. I Could copy them into $PREFIX/usr/$TARGET/lib instead of $PREFIX/usr/$TARGET/lib/system
    # but gcc-5666.3-lib-system.patch should take care of the problem without needing to get a
    # LD_FLAGS_FOR_TARGET hack to work.

    # Some redundancy here. Probably only the 2nd block is needed but it won't really hurt to do
    # both.
    mkdir usr/lib
    cp -fR $_SRC/usr/lib/system    usr/lib/
    cp -f $_SRC/usr/lib/libc.dylib usr/lib/
    cp -f $_SRC/usr/lib/dylib1.o   usr/lib/
    # Not sure what the difference is between
    # crt1.o (not made by the build process?!?)
    # and crt3.o (made by the build process) is.
    # TODO :: Figure out the score on OS X.
    cp -f $_SRC/usr/lib/crt1.o     usr/lib/

    mkdir -p $_TARGET/lib
    cp -fR $_SRC/usr/lib/system    $_TARGET/lib/
    cp -f $_SRC/usr/lib/libc.dylib $_TARGET/lib/system/
    cp -f $_SRC/usr/lib/dylib1.o   $_TARGET/lib/system/

    CT_Popd

    CT_EndStep
}

do_kernel_headers() {
    CT_DoStep INFO "Installing kernel headers"

    CT_Pushd "${CT_PREFIX_DIR}/${CT_TARGET}"
    
    CT_DoExecLog ALL \
    ln -sf "${CT_SYSROOT_REL_DIR}/include" "include"
    
    CT_Popd

    CT_EndStep
}
