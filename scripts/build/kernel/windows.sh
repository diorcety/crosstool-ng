# This file declares functions to install the kernel headers for mingw64
# Copyright 2012 Yann Diorcet
# Licensed under the GPL v2. See COPYING in the root of this package

CT_DoKernelTupleValues() {
    # Even we compile for x86_64 target architecture, the target OS have to
    # bet mingw32 (require by gcc and mingw-w64)
    CT_TARGET_KERNEL="mingw32"
    CT_TARGET_SYS=

    # May not be the best place - or name - for this!
    # There seems to be some amount of voodoo around
    # the naming of this so it may require tweaking.
    if [ "${CT_MULTILIB}" = "y" ]; then
        CT_TARGET_MINGW_SYSROOT_TOP="mingw"
    elif [ "${CT_ARCH_64}" = "y" ]; then
        CT_TARGET_MINGW_SYSROOT_TOP="mingw64"
    else
        CT_TARGET_MINGW_SYSROOT_TOP="mingw32"
    fi
    # .. and finally, hack it back to "mingw" because
    # as gcc/config/i386/mingw32.h is hardcoded:
    # #define NATIVE_SYSTEM_HEADER_DIR "/mingw/include"
    # I must speak with Alexey about this.
    CT_TARGET_MINGW_SYSROOT_TOP="mingw"
}

do_kernel_get() {
    :
}

do_kernel_extract() {
    :
}

do_kernel_headers() {
   :
}
