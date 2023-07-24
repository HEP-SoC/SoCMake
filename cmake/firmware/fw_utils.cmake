function(print_link_map EXE)
    get_target_property(BINARY_DIR ${EXE} BINARY_DIR)
     
    add_custom_command(TARGET ${EXE}
        POST_BUILD
        COMMAND cat ${BINARY_DIR}/map_file.map # TODO find where it is
        COMMAND ${CMAKE_SIZE} "${BINARY_DIR}/${EXE}"
        COMMENT "Printing the Map file from the linker for ${EXE}"
        )

endfunction()

function(disassemble EXE)
    get_target_property(BINARY_DIR ${EXE} BINARY_DIR)
    set(EXECUTABLE ${BINARY_DIR}/${EXE})
    set(OUT_ASM_FILE "${BINARY_DIR}/${EXE}_asm.S")

    add_custom_command(TARGET ${EXE}
        POST_BUILD
        BYPRODUCTS ${OUT_ASM_FILE}
        COMMAND ${CMAKE_OBJDUMP} -DgrwCS ${EXECUTABLE} > ${OUT_ASM_FILE}
        COMMENT "Dumping assembly from ${EXE}"
        )

    set_property(TARGET ${EXE}
        PROPERTY DISASM_FILE
        ${OUT_ASM_FILE}
        )
endfunction()

function(gen_bin EXE)
    get_target_property(BINARY_DIR ${EXE} BINARY_DIR)
    set(EXECUTABLE ${BINARY_DIR}/${EXE})
    set(BIN_FILE "${BINARY_DIR}/${EXE}.bin")
    set(BIN_TEXT_FILE "${BINARY_DIR}/${EXE}_text.bin")
    set(BIN_DATA_FILE "${BINARY_DIR}/${EXE}_data.bin")

    get_target_property(BOOTLOADER ${EXE} BOOTLOADER)
    if(BOOTLOADER)
        set(TEXT_SECTION .bootloader)
    else()
        set(TEXT_SECTION .text)
    endif()
    add_custom_command(TARGET ${EXE}
        POST_BUILD
        BYPRODUCTS ${BIN_FILE} ${BIN_TEXT_FILE} ${BIN_DATA_FILE}
        COMMAND ${CMAKE_OBJCOPY} -O binary ${EXECUTABLE} ${BIN_FILE}
        COMMAND ${CMAKE_OBJCOPY} -O binary --only-section=${TEXT_SECTION} ${EXECUTABLE} ${BIN_TEXT_FILE}
        COMMAND ${CMAKE_OBJCOPY} -O binary --remove-section=${TEXT_SECTION} ${EXECUTABLE} ${BIN_DATA_FILE}
        COMMENT "Generating bin file from ${EXE}"
        )

    set_property(TARGET ${EXE} PROPERTY BIN_FILE ${BIN_FILE})
    set_property(TARGET ${EXE} PROPERTY BIN_TEXT_FILE ${BIN_TEXT_FILE})
    set_property(TARGET ${EXE} PROPERTY BIN_DATA_FILE ${BIN_DATA_FILE})
endfunction()

function(gen_hex_files EXE)
    get_target_property(BINARY_DIR ${EXE} BINARY_DIR)

    cmake_parse_arguments(ARG "" "" "WIDTHS" ${ARGN})

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils/find_python.cmake")
    find_python3()

    set(EXECUTABLE ${BINARY_DIR}/${EXE})
    set(MAKEHEX_TOOL       "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/makehex.py")
    gen_bin(${EXE})
    get_property(BIN_FILE TARGET ${EXE} PROPERTY BIN_FILE)
    get_property(BIN_TEXT_FILE TARGET ${EXE} PROPERTY BIN_TEXT_FILE)
    get_property(BIN_DATA_FILE TARGET ${EXE} PROPERTY BIN_DATA_FILE)

    if(NOT ARG_WIDTHS)
        set(ARG_WIDTHS 32)
    endif()

    set(ALLOWED_WIDTHS 8 16 32 64)
    foreach(width ${ARG_WIDTHS})
        list(FIND ALLOWED_WIDTHS ${width} WIDTH_FIND)
        if(WIDTH_FIND GREATER -1)
            set(WIDTH_ARG --width ${width})
            set(HEX_FILE "${BINARY_DIR}/${EXE}_${width}bit.hex")
            set(HEX_TEXT_FILE "${BINARY_DIR}/${EXE}_text_${width}bit.hex")
            set(HEX_DATA_FILE "${BINARY_DIR}/${EXE}_data_${width}bit.hex")
            add_custom_command(TARGET ${EXE}
                POST_BUILD
                BYPRODUCTS ${HEX_FILE} ${HEX_TEXT_FILE} ${HEX_DATA_FILE}
                COMMAND ${Python3_EXECUTABLE} ${MAKEHEX_TOOL} --width ${width} ${BIN_FILE} ${HEX_FILE}
                COMMAND ${Python3_EXECUTABLE} ${MAKEHEX_TOOL} --width ${width} ${BIN_TEXT_FILE} ${HEX_TEXT_FILE}
                COMMAND ${Python3_EXECUTABLE} ${MAKEHEX_TOOL} --width ${width} ${BIN_DATA_FILE} ${HEX_DATA_FILE}
                COMMENT "Generating ${width} bit hex file file for ${EXE}"
                )

            set_property(TARGET ${EXE} PROPERTY HEX_${width}bit_FILE ${HEX_FILE})
            set_property(TARGET ${EXE} PROPERTY HEX_TEXT_${width}bit_FILE ${HEX_TEXT_FILE})
            set_property(TARGET ${EXE} PROPERTY HEX_DATA_${width}bit_FILE ${HEX_DATA_FILE})
        else()
            message(FATAL_ERROR "\nWidth ${width} not allowed in gen_hex_files(), allowed values ${ALLOWED_WIDTHS}\n")
        endif()
    endforeach()

endfunction()

function(set_linker_scripts EXE)
    cmake_parse_arguments(ARG "" "" "LDS" ${ARGN})

    if(NOT ARG_LDS)
        message(FATAL_ERROR "Must provide one or more linker_scripts: LDS [fn,...]")
    endif()

    set(LINKER_SCRIPT_ARG "-Wl")
    foreach(lds ${ARG_LDS})
        string(APPEND LINKER_SCRIPT_ARG ",-T${lds}")
    endforeach()

    target_link_options(${EXE} BEFORE PRIVATE ${LINKER_SCRIPT_ARG})
    set_property(TARGET ${EXE} PROPERTY LINK_DEPENDS ${ARG_LDS})
endfunction()

# function(static_stack_analysis EXE)
#     set(SSA_TOOL "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/ssa.py")
#     get_target_property(BINARY_DIR ${EXE} BINARY_DIR)
#     set(CFLOW_CALLSTACK "${BINARY_DIR}/${EXE}_cflow_callstack.txt")
#
#     get_target_property(CPP_SOURCES ${EXE} SOURCES)
#     list(FILTER CPP_SOURCES EXCLUDE REGEX "\\.[S|s]$") # Exclude asm files
#
#     add_custom_command(TARGET ${EXE}
#         POST_BUILD
#         BYPRODUCTS ${CFLOW_CALLSTACK}
#         COMMAND cflow ${CPP_SOURCES} > ${CFLOW_CALLSTACK} || (exit 0)
#         COMMAND ${Python3_EXECUTABLE} ${SSA_TOOL} -f ${CFLOW_CALLSTACK} -d ${BINARY_DIR}/CMakeFiles/${EXE}.dir/ || (exit 0)
#         COMMENT "Running static stack analysis on ${EXE}, error on this command can be ignored"
#         )
#
# endfunction()
#
