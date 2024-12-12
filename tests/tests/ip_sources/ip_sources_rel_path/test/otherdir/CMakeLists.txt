

ip_sources(ip SYSTEMVERILOG
    otherdir_file1.sv
    otherdir_file2.sv
    )
list(APPEND SV_SOURCES 
    otherdir/otherdir_file1.sv
    otherdir/otherdir_file2.sv
    )
set(SV_SOURCES ${SV_SOURCES} PARENT_SCOPE)

ip_sources(ip VHDL
    otherdir_file1.vhdl
    otherdir_file2.vhdl
    )
list(APPEND VHDL_SOURCES 
    otherdir/otherdir_file1.vhdl
    otherdir/otherdir_file2.vhdl
    )
set(VHDL_SOURCES ${VHDL_SOURCES} PARENT_SCOPE)
