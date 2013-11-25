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

# Please keep these around for reference until everything is working well.
#
# My old toolchain4 linux build:
# Configured with: /tmp/tc4/src-apple-osx/gcc-5666.3/configure
#                    --prefix=/tmp/tc4/final-install/apple-osx --disable-checking
#                    --enable-languages=c,c++,objc,obj-c++
#                    --with-as=/tmp/tc4/final-install/apple-osx/bin/i686-apple-darwin11-as
#                    --with-ld=/tmp/tc4/final-install/apple-osx/bin/i686-apple-darwin11-ld
#                    --with-ranlib=/tmp/tc4/final-install/apple-osx/bin/i686-apple-darwin11-ranlib
#                    --target=i686-apple-darwin11
#                    --with-sysroot=/tmp/tc4/final-install/apple-osx
#                    --enable-static
#                    --enable-shared
#                    --enable-nls
#                    --enable-multilib
#                    --disable-werror
#                    --enable-libgomp
#                    --with-gxx-include-dir=/tmp/tc4/final-install/apple-osx/include/c++/4.2.1
#                    --with-gmp=/tmp/tc4/host-install-gmp-mpfr
#                    --with-mpfr=/tmp/tc4/host-install-gmp-mpfr
#                    --libexecdir=/tmp/tc4/final-install/apple-osx/libexec
# Thread model: posix
#
# Native official:
# Configured with: /Volumes/Media/Builds/gcc-5666.3/build/obj/src/configure
#                    --disable-checking
#                    --prefix=/
#                    --mandir=/share/man
#                    --enable-languages=c,objc,c++,obj-c++,fortran
#                    --program-transform-name=/^[cg][^.-]*$/s/$/-4.2/
#                    --with-slibdir=/usr/lib
#                    --build=i686-apple-darwin11
#                    --program-prefix=i686-apple-darwin11-
#                    --host=x86_64-apple-darwin11
#                    --target=i686-apple-darwin11
#                    --with-gxx-include-dir=/include/c++/4.2.1
# Thread model: posix

do_kernel_extract_minimal() {
    CT_DoStep INFO "Extract kernel headers and libraries (minimal)"

    local _SRC="${CT_DARWIN_SDK_PATH}"
    local _TARGET="${CT_TARGET}"

    [ -d "${_SRC}" ] || CT_Abort "Can't found the SDK at ${_SRC}"
    [ -d "${CT_SYSROOT_DIR}" ] || mkdir -p "${CT_SYSROOT_DIR}"

    CT_Pushd "${CT_SYSROOT_DIR}"

    # SYSHEADERS is just those headers necessary for building libgcc and the crt files.
    declare -a SYSHEADERS
    declare -a HELLOWORDCPPHEADERS
    if [ -z "$CT_ARCH_arm" ] ; then
        _SDKARCH=i686
        if [ ! -z "$CT_DARWIN_MAC_OSX_V_10_6" ] ; then
            SYSHEADERS=(libc.h stdio.h errno.h string.h strings.h alloca.h stdlib.h unistd.h time.h dlfcn.h limits.h _types.h _structs.h Availability.h AvailabilityMacros.h AvailabilityInternal.h vproc.h fcntl.h pthread.h pthread_impl.h sched.h sys/select.h sys/unistd.h sys/wait.h sys/errno.h sys/types.h sys/syslimits.h sys/_types.h sys/_endian.h sys/cdefs.h sys/appleapiopts.h sys/_structs.h sys/signal.h sys/resource.h sys/stat.h sys/_select.h sys/fcntl.h machine/types.h machine/endian.h machine/signal.h machine/limits.h machine/_structs.h machine/_limits.h machine/_types.h i386/types.h i386/_types.h i386/endian.h i386/limits.h i386/_limits.h i386/_structs.h i386/signal.h libkern/_OSByteOrder.h libkern/i386/_OSByteOrder.h mach/i386/_structs.h mach/mach_error.h)
        else
            SYSHEADERS=(libc.h stdio.h errno.h string.h strings.h alloca.h stdlib.h unistd.h time.h dlfcn.h limits.h _types.h _structs.h Availability.h AvailabilityMacros.h AvailabilityInternal.h vproc.h fcntl.h pthread.h pthread_impl.h sched.h sys/select.h sys/unistd.h sys/wait.h sys/errno.h sys/types.h sys/syslimits.h sys/_types.h sys/_endian.h sys/cdefs.h sys/appleapiopts.h sys/_structs.h sys/_symbol_aliasing.h sys/_posix_availability.h sys/signal.h sys/resource.h sys/stat.h sys/_select.h sys/fcntl.h machine/types.h machine/endian.h machine/signal.h machine/limits.h machine/_structs.h machine/_limits.h machine/_types.h i386/types.h i386/_types.h i386/endian.h i386/limits.h i386/_limits.h i386/_structs.h i386/signal.h libkern/_OSByteOrder.h libkern/i386/_OSByteOrder.h mach/i386/_structs.h mach/mach_error.h)
        fi
        # HELLOWORDCPPHEADERS are the subsequent headers necessary for "include <iostream>" to compile.
        HELLOWORDCPPHEADERS=(locale.h _locale.h ctype.h wchar.h wctype.h _wctype.h stdint.h runetype.h)
    else
        SYSHEADERS=(secure/_common.h secure/_stdio.h secure/_string.h stdint.h stdio.h errno.h string.h strings.h alloca.h stdlib.h unistd.h time.h dlfcn.h limits.h _types.h _structs.h Availability.h AvailabilityMacros.h AvailabilityInternal.h vproc.h fcntl.h pthread.h pthread_impl.h sched.h sys/select.h sys/unistd.h sys/wait.h sys/errno.h sys/types.h sys/syslimits.h sys/_types.h sys/_endian.h sys/cdefs.h sys/appleapiopts.h sys/_structs.h sys/_symbol_aliasing.h sys/_posix_availability.h sys/signal.h sys/resource.h sys/stat.h sys/_select.h sys/fcntl.h machine/types.h machine/endian.h machine/signal.h machine/limits.h machine/_structs.h                   machine/_types.h  arm/types.h  arm/_types.h  arm/endian.h  arm/limits.h  arm/_limits.h  arm/_structs.h  arm/signal.h libkern/_OSByteOrder.h libkern/arm/OSByteOrder.h   mach/arm/_structs.h arm/arch.h mach/mach_error.h)
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

    for SYSHDR in ${SYSHEADERS[@]} ${HELLOWORDCPPHEADERS[@]}; do
        for DST_INCLUDE in ${DST_INCLUDE_FOLDERS[@]}; do
            [ ! -d $DST_INCLUDE/$(dirname $SYSHDR) ] && mkdir -p $DST_INCLUDE/$(dirname $SYSHDR)
            CT_DoExecLog ALL \
            cp -R -p -u $_SRC/usr/include/$SYSHDR $DST_INCLUDE/$(dirname $SYSHDR)
        done
    done

    # Since libstdc++ doesn't get built, we need to get the headers from an existing SDK.
    # May as well do that here, even though it's not needed for the build.
    CT_Pushd "${_SRC}/usr/include/c++"
    CXX_INCLUDES=$(find . -mindepth 2 -maxdepth 2)
    CT_Popd

    # This puts the stdc++ lib headers inside the sysroot and requires configuring gcc and llvmgcc
    # --with-gxx-include-dir=/usr/include/c++/4.2.1 - in lieu of configuring like this, would have
    # to set GXX_INCLUDE_DIR=${CT_PREFIX_DIR}/${CT_TARGET}
    GXX_INCLUDE_DIR=usr

    for CXX_INCLUDE in $CXX_INCLUDES; do
        DSTDIR=${GXX_INCLUDE_DIR}/include/c++/${CXX_INCLUDE}
        CT_DoExecLog ALL \
        mkdir -p $(dirname "${DSTDIR}")
        CT_DoExecLog ALL \
        cp -Rf -u "${_SRC}/usr/include/c++/${CXX_INCLUDE}" "${DSTDIR}"
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
    cp -fR -u $_SRC/usr/lib/system    usr/lib/
    find usr/lib/ -type d -exec chmod u+w {} \;
    cp -f -u $_SRC/usr/lib/libc.dylib usr/lib/
    cp -f -u $_SRC/usr/lib/dylib1.o   usr/lib/
    # Not sure what the difference is between
    # crt1.o (not made by the build process?!?)
    # and crt3.o (made by the build process) is.
    # TODO :: Figure out the score on OS X.
    cp -f -u $_SRC/usr/lib/crt1.o     usr/lib/

    mkdir -p $_TARGET/lib
    cp -fR -u $_SRC/usr/lib/system    $_TARGET/lib/
    find $_TARGET/lib/ -type d -exec chmod u+w {} \;
    cp -f -u $_SRC/usr/lib/libc.dylib $_TARGET/lib/system/
    cp -f -u $_SRC/usr/lib/dylib1.o   $_TARGET/lib/system/

    CT_Popd

    CT_EndStep
}

do_kernel_extract_copy_sdk() {
    CT_DoStep INFO "Extract kernel headers and libraries (copy SDK)"
    
    local _SRC="${CT_DARWIN_SDK_PATH}"
    local _TARGET="${CT_TARGET}"

    [ -d "${_SRC}" ] || CT_Abort "Can't found the SDK at ${_SRC}"
    [ -d "${CT_SYSROOT_DIR}" ] || mkdir -p "${CT_SYSROOT_DIR}"

    CT_Pushd "${CT_SYSROOT_DIR}"
    [ -d usr ] && rm -rf usr
    mkdir usr
    
    for _SRCDIR in $_SRC/usr/include $_SRC/usr/lib $_SRC/usr/X11 $_SRC/usr/X11R6; do
        if [ -d $_SRCDIR ]; then
            cp -fR $_SRCDIR usr/
        fi
    done

    # Copy System files
    [ -d System ] && rm -rf System
    cp -a $_SRC/System System

    CT_Popd

    CT_EndStep
}

do_kernel_extract_common() {
    CT_DoStep INFO "Extract kernel headers and libraries (common)"

    local _SRC="${CT_DARWIN_SDK_PATH}"
    local _TARGET="${CT_TARGET}"

    [ -d "${_SRC}" ] || CT_Abort "Can't found the SDK at ${_SRC}"
    [ -d "${CT_SYSROOT_DIR}" ] || mkdir -p "${CT_SYSROOT_DIR}"

    CT_Pushd "${CT_SYSROOT_DIR}"

    # Fix x86_64-*-darwin* target
    ln -s i686-apple-darwin10 usr/lib/x86_64-apple-darwin10 || true
    ln -s i686-apple-darwin10 usr/lib/gcc/x86_64-apple-darwin10 || true
    ln -s ../i686-apple-darwin10 usr/include/c++/4.2.1/x86_64-apple-darwin10/i386 || true
    ln -s ../i686-apple-darwin9 usr/include/c++/4.2.1/x86_64-apple-darwin9/i386 || true
    ln -s ../i686-apple-darwin10 usr/include/c++/4.0.0/x86_64-apple-darwin10/i386 || true
    ln -s ../i686-apple-darwin9 usr/include/c++/4.0.0/x86_64-apple-darwin9/i386 || true

    CT_Popd

    CT_EndStep
}

do_kernel_extract() {
    if [ "${CT_DARWIN_COPY_SDK_TO_SYSROOT}" = "y" ]; then
        do_kernel_extract_copy_sdk
    else
        do_kernel_extract_minimal
    fi
    do_kernel_extract_common
}

do_kernel_headers() {
    CT_DoStep INFO "Installing kernel headers"
    CT_EndStep
}
