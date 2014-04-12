# Compute AVR-specific values

CT_DoArchTupleValues() {
    CT_TARGET_ARCH="${CT_ARCH}"
}

#------------------------------------------------------------------------------
# Get multilib architecture-specific target
# Usage: CT_DoArchMultilibTarget "multilib flags" "target tuple"
CT_DoArchMultilibTarget ()
{
    local multi_flags="${1}"
    local target="${2}"

    :;

    echo "${target}"
}
