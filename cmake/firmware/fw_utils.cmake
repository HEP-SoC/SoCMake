#[[[
# This function disassembles the given executable target to generate an assembly file.
#
# The function retrieves the binary directory of the target, sets the output assembly file name,
# and adds a custom command to disassemble the executable and store the result in the specified file.
#
# :param EXE: The executable target.
# :type EXE: string
#]]
function(disassemble EXE)
    # Retrieve the binary directory of the target
    get_target_property(BINARY_DIR ${EXE} BINARY_DIR)

    # Set the paths for the executable and output assembly file
    set(EXECUTABLE ${BINARY_DIR}/${EXE})
    set(OUT_ASM_FILE "${BINARY_DIR}/${EXE}_disasm.S")

    # Add a custom command to disassemble the executable and generate the assembly file
    add_custom_command(TARGET ${EXE}
        POST_BUILD
        BYPRODUCTS ${OUT_ASM_FILE}
        COMMAND ${CMAKE_OBJDUMP} -DgrwCS ${EXECUTABLE} > ${OUT_ASM_FILE}
        COMMENT "Dumping assembly from ${EXE}"
    )

    # Set a property on the target to store the path of the generated assembly file
    set_property(TARGET ${EXE}
        PROPERTY DISASM_FILE
        ${OUT_ASM_FILE}
    )
endfunction()

#[[[
# This function generates hex files for the given executable target.
#
# The function retrieves the binary directory of the target, parses the width arguments,
# and includes a utility script to find Python. It then retrieves binary file properties
# from the target, sets the appropriate sections for the bootloader, and generates hex files
# for each specified width.
#
# :param EXE: The executable target.
# :type EXE: string
#]]
function(gen_hex_files EXE)
    # Retrieve the binary directory of the target
    get_target_property(BINARY_DIR ${EXE} BINARY_DIR)

    # Parse the width arguments
    cmake_parse_arguments(ARG "" "" "WIDTHS" ${ARGN})

    # Include the utility script to find Python
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils/find_python.cmake")
    find_python3()

    # Set the path for the executable
    set(EXECUTABLE ${BINARY_DIR}/${EXE})

    # Retrieve binary file properties from the target
    get_property(BIN_FILE TARGET ${EXE} PROPERTY BIN_FILE)
    get_property(BIN_TEXT_FILE TARGET ${EXE} PROPERTY BIN_TEXT_FILE)
    get_property(BIN_DATA_FILE TARGET ${EXE} PROPERTY BIN_DATA_FILE)

    # Set default width to 32 if not specified
    if(NOT ARG_WIDTHS)
        set(ARG_WIDTHS 32)
    endif()

    # Determine the sections based on whether the target is a bootloader
    get_target_property(BOOTLOADER ${EXE} BOOTLOADER)
    if(BOOTLOADER)
        set(TEXT_SECTION --only-section=.bootloader)
    else()
        set(TEXT_SECTION
            --only-section=.vectors
            --only-section=.init
            --only-section=.fini
            --only-section=.text
        )
    endif()

    # Set the sections to be excluded for the data section
    set(DATA_SECTION
        --remove-section=.bootloader
        --remove-section=.vectors
        --remove-section=.init
        --remove-section=.fini
        --remove-section=.text
    )

    # Define allowed widths and iterate over specified widths to generate hex files
    set(ALLOWED_WIDTHS 8 16 32 64)
    foreach(width ${ARG_WIDTHS})
        list(FIND ALLOWED_WIDTHS ${width} WIDTH_FIND)
        if(WIDTH_FIND GREATER -1)
            set(WIDTH_ARG --width ${width})
            set(HEX_FILE "${BINARY_DIR}/${EXE}_${width}bit.hex")
            set(HEX_TEXT_FILE "${BINARY_DIR}/${EXE}_text_${width}bit.hex")
            set(HEX_DATA_FILE "${BINARY_DIR}/${EXE}_data_${width}bit.hex")

            # Add custom commands to generate hex files for the specified width
            add_custom_command(TARGET ${EXE}
                POST_BUILD
                BYPRODUCTS ${HEX_FILE} ${HEX_TEXT_FILE} ${HEX_DATA_FILE}
                COMMAND ${CMAKE_OBJCOPY} -O verilog ${EXECUTABLE} ${HEX_FILE}
                COMMAND ${CMAKE_OBJCOPY} -O verilog --verilog-data-width=4 --gap-fill 0x0000 ${TEXT_SECTION} ${EXECUTABLE} ${HEX_TEXT_FILE}
                # TODO: find an automatic way to 'correct' the VMA for loading during simulation
                COMMAND ${CMAKE_OBJCOPY} -O verilog --verilog-data-width=4 --gap-fill 0x0000 --adjust-vma=-0x10000000 ${DATA_SECTION} ${EXECUTABLE} ${HEX_DATA_FILE}
                COMMENT "Generating ${width} bit hex file for ${EXE}"
            )

            # Set properties on the target to store the paths of the generated hex files
            set_property(TARGET ${EXE} PROPERTY HEX_${width}bit_FILE ${HEX_FILE})
            set_property(TARGET ${EXE} PROPERTY HEX_TEXT_${width}bit_FILE ${HEX_TEXT_FILE})
            set_property(TARGET ${EXE} PROPERTY HEX_DATA_${width}bit_FILE ${HEX_DATA_FILE})
        else()
            message(FATAL_ERROR "\nWidth ${width} not allowed in gen_hex_files(), allowed values ${ALLOWED_WIDTHS}\n")
        endif()
    endforeach()
endfunction()

#[[[
# This function sets linker scripts for the given executable target.
#
# The function parses the linker script arguments and sets them as link options for the target.
# It also sets a property on the target to store the list of linker scripts.
#
# :param EXE: The executable target.
# :type EXE: string
#]]
function(set_linker_scripts EXE)
    # Parse the linker script arguments
    cmake_parse_arguments(ARG "" "" "LDS" ${ARGN})

    # Ensure linker scripts are provided
    if(NOT ARG_LDS)
        message(FATAL_ERROR "Must provide one or more linker_scripts: LDS [fn,...]")
    endif()

    # Iterate over linker scripts and set them as link options for the target
    foreach(lds ${ARG_LDS})
        target_link_options(${PROJECT_NAME} PUBLIC
            -T${lds}
        )
    endforeach()

    # Set a property on the target to store the list of linker scripts
    set_property(TARGET ${EXE} PROPERTY LINK_DEPENDS ${ARG_LDS})
endfunction()
