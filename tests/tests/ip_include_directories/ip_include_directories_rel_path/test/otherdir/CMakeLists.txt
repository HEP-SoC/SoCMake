list(APPEND SV_INCDIRS
    otherdir/.
    otherdir/incdir
    )
ip_include_directories(ip SYSTEMVERILOG
    .
    incdir
    )

set(SV_INCDIRS ${SV_INCDIRS} PARENT_SCOPE)
