
function(stupid_printer NUM_TO_ADD)
    add_ip(vendor::lib_${NUM_TO_ADD}::printer_${NUM_TO_ADD}::0.0.1
        DESCRIPTION "A stupid module that prints ${NUM_TO_ADD}")

    configure_file(
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/printer.v.in
        ${CMAKE_BINARY_DIR}/printer_${NUM_TO_ADD}.v
        @ONLY
        )
    ip_sources(${IP} VERILOG
        ${CMAKE_BINARY_DIR}/printer_${NUM_TO_ADD}.v
        )
endfunction()
