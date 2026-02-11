include("${CMAKE_CURRENT_LIST_DIR}/../../../SoCMakeConfig.cmake")

set(CDIR ${CMAKE_CURRENT_LIST_DIR})

set(TEST_NAME help_targets)

ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
# Build targets for different components
    add_custom_target(build_bootloader)
    set_target_properties(build_bootloader PROPERTIES 
        DESCRIPTION "Build first-stage bootloader (ROM code)")

    add_custom_target(build_firmware)
    set_target_properties(build_firmware PROPERTIES 
        DESCRIPTION "Build application firmware for main processor")

    add_custom_target(build_fpga_bitstream)
    set_target_properties(build_fpga_bitstream PROPERTIES 
        DESCRIPTION "Synthesize and generate FPGA bitstream")

    add_custom_target(build_documentation)
    set_target_properties(build_documentation PROPERTIES 
        DESCRIPTION "Generate technical documentation and register maps")

# Simulation targets
    add_custom_target(sim_core_unit_tests)
    set_target_properties(sim_core_unit_tests PROPERTIES 
        DESCRIPTION "Run CPU core unit tests in Verilator")

    add_custom_target(sim_peripheral_tests)
    set_target_properties(sim_peripheral_tests PROPERTIES 
        DESCRIPTION "Run peripheral subsystem tests")

    add_custom_target(sim_integration)
    set_target_properties(sim_integration PROPERTIES 
        DESCRIPTION "Run full SoC integration simulation")

# Flash/Programming targets
    add_custom_target(flash_bootloader)
    set_target_properties(flash_bootloader PROPERTIES 
        DESCRIPTION "Program bootloader to on-chip ROM/Flash")

    add_custom_target(flash_firmware)
    set_target_properties(flash_firmware PROPERTIES 
        DESCRIPTION "Program application firmware to external Flash")

    add_custom_target(flash_fpga)
    set_target_properties(flash_fpga PROPERTIES 
        DESCRIPTION "Program FPGA configuration memory")

# Test execution targets for UART peripheral
    add_custom_target(run_test_uart0_loopback)
    add_custom_target(run_test_uart0_baud_rates)
    add_custom_target(run_test_uart0_interrupts)
    add_custom_target(run_test_uart1_loopback)
    add_custom_target(run_test_uart1_dma)

# Test execution targets for SPI peripheral
    add_custom_target(run_test_spi0_master_mode)
    add_custom_target(run_test_spi0_slave_mode)
    add_custom_target(run_test_spi1_flash_access)
    add_custom_target(run_test_spi1_dual_quad_mode)

# Test execution targets for I2C peripheral
    add_custom_target(run_test_i2c0_master)
    add_custom_target(run_test_i2c0_multi_master)
    add_custom_target(run_test_i2c1_sensor_read)

# Memory subsystem tests
    add_custom_target(run_test_ddr_calibration)
    add_custom_target(run_test_ddr_bandwidth)
    add_custom_target(run_test_cache_coherency)

# Power management tests
    add_custom_target(run_test_pm_sleep_modes)
    add_custom_target(run_test_pm_clock_gating)
    add_custom_target(run_test_pm_voltage_scaling)

# Organize help menus
    help_custom_targets("build" LIST 
        build_bootloader 
        build_firmware 
        build_fpga_bitstream 
        build_documentation
        DESCRIPTION "Build targets"
        )

    help_custom_targets("simulation" LIST 
        sim_core_unit_tests 
        sim_peripheral_tests 
        sim_integration
        DESCRIPTION "Simulation targets"
        )

    help_custom_targets("flash" LIST 
        flash_bootloader 
        flash_firmware 
        flash_fpga)

    help_custom_targets("uart_tests" PATTERN "run_test_uart[0-9]_*" DESCRIPTION "UART tests")
    help_custom_targets("spi_tests" PATTERN "run_test_spi[0-9]_*")
    help_custom_targets("i2c_tests" PATTERN "run_test_i2c[0-9]_*")
    help_custom_targets("memory_tests" PATTERN "run_test_ddr_*|run_test_cache_*")
    help_custom_targets("power_tests" PATTERN "run_test_pm_*")

    help_custom_targets("uart0_specific" PATTERN ".*_uart0_.*")
    help_custom_targets("all_peripheral_tests" PATTERN "run_test_(uart|spi|i2c)[0-9]_.*")

# IP blocks
    add_ip(riscv_core_cv32e40p)
    add_ip(axi_interconnect)
    add_ip(uart_16550)
    add_ip(spi_master_apb)
    add_ip(i2c_master_wb)
    add_ip(ddr3_controller)
    add_ip(plic_interrupt_controller)
    add_ip(timer_subsystem)

# Configuration options
    option_boolean(ENABLE_FPU "Enable hardware floating-point unit" ON)
    option_boolean(ENABLE_COMPRESSED "Enable RISC-V compressed instructions (RVC)" ON)
    option_boolean(ENABLE_DEBUG_MODULE "Include on-chip debug module (JTAG)" ON)
    option_boolean(ENABLE_TRACE_PORT "Enable instruction trace port for profiling" OFF)
    option_boolean(USE_EXTERNAL_DDR "Use external DDR3 memory (vs on-chip SRAM only)" ON)
    option_boolean(ENABLE_CRYPTO_ENGINE "Include hardware cryptography accelerator" OFF)
    option_boolean(ENABLE_DMA "Include direct memory access controller" ON)
    option_boolean(LOW_POWER_MODE "Optimize for low power consumption" OFF)

    help()

# Assert that help targets exist
    ct_assert_target_exists(help_all)
    ct_assert_target_exists(help_options)
    ct_assert_target_exists(help_targets)
    ct_assert_target_exists(help_ips)
    ct_assert_target_exists(help_build)
    ct_assert_target_exists(help_simulation)
    ct_assert_target_exists(help_flash)
    ct_assert_target_exists(help_uart_tests)
    ct_assert_target_exists(help_spi_tests)
    ct_assert_target_exists(help_i2c_tests)
    ct_assert_target_exists(help_memory_tests)
    ct_assert_target_exists(help_power_tests)
    ct_assert_target_exists(help_uart0_specific)
    ct_assert_target_exists(help_all_peripheral_tests)

    # Helper function to read JSON and find item by name
    function(ct_json_find_item JSON_FILE ARRAY_NAME ITEM_NAME OUT_INDEX)
        if(NOT EXISTS "${JSON_FILE}")
            message(FATAL_ERROR "JSON file does not exist: ${JSON_FILE}")
        endif()
        
        file(READ "${JSON_FILE}" json_content)
        
        # Get array length
        string(JSON array_length ERROR_VARIABLE err LENGTH "${json_content}" "${ARRAY_NAME}")
        if(err)
            message(FATAL_ERROR "Failed to read array '${ARRAY_NAME}' from ${JSON_FILE}: ${err}")
        endif()
        
        # Search for item
        set(found_index -1)
        if(array_length GREATER 0)
            math(EXPR max_index "${array_length} - 1")
            foreach(i RANGE 0 ${max_index})
                string(JSON item_name ERROR_VARIABLE err GET "${json_content}" "${ARRAY_NAME}" ${i} "name")
                if(NOT err AND item_name STREQUAL ITEM_NAME)
                    set(found_index ${i})
                    break()
                endif()
            endforeach()
        endif()
        
        set(${OUT_INDEX} ${found_index} PARENT_SCOPE)
    endfunction()

    # Helper function to check if item exists in JSON array
    function(ct_assert_item_in_json JSON_FILE ARRAY_NAME ITEM_NAME)
        ct_json_find_item("${JSON_FILE}" "${ARRAY_NAME}" "${ITEM_NAME}" index)
        
        if(index EQUAL -1)
            message(FATAL_ERROR "Item '${ITEM_NAME}' not found in ${ARRAY_NAME} of ${JSON_FILE}")
        else()
            message(STATUS "✓ Item '${ITEM_NAME}' found in ${JSON_FILE}")
        endif()
    endfunction()

    # Helper function to check if item is NOT in JSON array
    function(ct_assert_item_not_in_json JSON_FILE ARRAY_NAME ITEM_NAME)
        ct_json_find_item("${JSON_FILE}" "${ARRAY_NAME}" "${ITEM_NAME}" index)
        
        if(NOT index EQUAL -1)
            message(FATAL_ERROR "Item '${ITEM_NAME}' should NOT be in ${ARRAY_NAME} of ${JSON_FILE}")
        else()
            message(STATUS "✓ Item '${ITEM_NAME}' correctly excluded from ${JSON_FILE}")
        endif()
    endfunction()

    # Helper function to check if item has specific group
    function(ct_assert_item_has_group JSON_FILE ARRAY_NAME ITEM_NAME GROUP_NAME)
        ct_json_find_item("${JSON_FILE}" "${ARRAY_NAME}" "${ITEM_NAME}" index)
        
        if(index EQUAL -1)
            message(FATAL_ERROR "Item '${ITEM_NAME}' not found in ${JSON_FILE}")
        endif()
        
        file(READ "${JSON_FILE}" json_content)
        string(JSON groups_array ERROR_VARIABLE err GET "${json_content}" "${ARRAY_NAME}" ${index} "groups")
        if(err)
            message(FATAL_ERROR "Failed to read groups for '${ITEM_NAME}': ${err}")
        endif()
        
        # Check if GROUP_NAME is in groups array
        string(JSON groups_length LENGTH "${groups_array}")
        set(found FALSE)
        if(groups_length GREATER 0)
            math(EXPR max_index "${groups_length} - 1")
            foreach(i RANGE 0 ${max_index})
                string(JSON group_value GET "${groups_array}" ${i})
                if(group_value STREQUAL GROUP_NAME)
                    set(found TRUE)
                    break()
                endif()
            endforeach()
        endif()
        
        if(NOT found)
            message(FATAL_ERROR "Item '${ITEM_NAME}' does not have group '${GROUP_NAME}'")
        else()
            message(STATUS "✓ Item '${ITEM_NAME}' has group '${GROUP_NAME}'")
        endif()
    endfunction()

    # Helper function to verify description exists
    function(ct_assert_item_has_description JSON_FILE ARRAY_NAME ITEM_NAME EXPECTED_DESC)
        ct_json_find_item("${JSON_FILE}" "${ARRAY_NAME}" "${ITEM_NAME}" index)
        
        if(index EQUAL -1)
            message(FATAL_ERROR "Item '${ITEM_NAME}' not found in ${JSON_FILE}")
        endif()
        
        file(READ "${JSON_FILE}" json_content)
        string(JSON description ERROR_VARIABLE err GET "${json_content}" "${ARRAY_NAME}" ${index} "description")
        if(err)
            message(FATAL_ERROR "Failed to read description for '${ITEM_NAME}': ${err}")
        endif()
        
        string(FIND "${description}" "${EXPECTED_DESC}" pos)
        if(pos EQUAL -1)
            message(FATAL_ERROR "Description '${EXPECTED_DESC}' not found in item '${ITEM_NAME}'. Got: ${description}")
        else()
            message(STATUS "✓ Item '${ITEM_NAME}' has correct description")
        endif()
    endfunction()

    set(TARGETS_JSON "${CMAKE_BINARY_DIR}/help/help_targets.json")
    set(IPS_JSON "${CMAKE_BINARY_DIR}/help/help_ips.json")
    set(OPTIONS_JSON "${CMAKE_BINARY_DIR}/help/help_options.json")

    # Test that JSON files exist
    if(NOT EXISTS "${TARGETS_JSON}")
        message(FATAL_ERROR "Targets JSON file does not exist: ${TARGETS_JSON}")
    endif()
    if(NOT EXISTS "${IPS_JSON}")
        message(FATAL_ERROR "IPs JSON file does not exist: ${IPS_JSON}")
    endif()
    if(NOT EXISTS "${OPTIONS_JSON}")
        message(FATAL_ERROR "Options JSON file does not exist: ${OPTIONS_JSON}")
    endif()

    # Test help targets JSON - build group
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "build_bootloader")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "build_firmware")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "build_fpga_bitstream")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "build_documentation")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "help_build")
    
    ct_assert_item_has_group("${TARGETS_JSON}" "targets" "build_bootloader" "build")
    ct_assert_item_has_group("${TARGETS_JSON}" "targets" "build_firmware" "build")
    ct_assert_item_has_group("${TARGETS_JSON}" "targets" "help_build" "help")

    # Test help targets JSON - simulation group
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "sim_core_unit_tests")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "sim_peripheral_tests")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "sim_integration")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "help_simulation")
    
    ct_assert_item_has_group("${TARGETS_JSON}" "targets" "sim_core_unit_tests" "simulation")

    # Test help targets JSON - flash group
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "flash_bootloader")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "flash_firmware")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "flash_fpga")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "help_flash")
    
    ct_assert_item_has_group("${TARGETS_JSON}" "targets" "flash_bootloader" "flash")

    # Test help targets JSON - uart_tests group
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_uart0_loopback")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_uart0_baud_rates")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_uart0_interrupts")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_uart1_loopback")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_uart1_dma")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "help_uart_tests")
    
    ct_assert_item_has_group("${TARGETS_JSON}" "targets" "run_test_uart0_loopback" "uart_tests")

    # Test help targets JSON - spi_tests group
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_spi0_master_mode")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_spi0_slave_mode")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_spi1_flash_access")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_spi1_dual_quad_mode")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "help_spi_tests")
    
    ct_assert_item_has_group("${TARGETS_JSON}" "targets" "run_test_spi0_master_mode" "spi_tests")

    # Test help targets JSON - i2c_tests group
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_i2c0_master")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_i2c0_multi_master")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_i2c1_sensor_read")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "help_i2c_tests")
    
    ct_assert_item_has_group("${TARGETS_JSON}" "targets" "run_test_i2c0_master" "i2c_tests")

    # Test help targets JSON - memory_tests group
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_ddr_calibration")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_ddr_bandwidth")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_cache_coherency")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "help_memory_tests")
    
    ct_assert_item_has_group("${TARGETS_JSON}" "targets" "run_test_ddr_calibration" "memory_tests")

    # Test help targets JSON - power_tests group
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_pm_sleep_modes")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_pm_clock_gating")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_pm_voltage_scaling")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "help_power_tests")
    
    ct_assert_item_has_group("${TARGETS_JSON}" "targets" "run_test_pm_sleep_modes" "power_tests")

    # Test help targets JSON - uart0_specific group
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_uart0_loopback")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_uart0_baud_rates")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_uart0_interrupts")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "help_uart0_specific")
    
    ct_assert_item_has_group("${TARGETS_JSON}" "targets" "run_test_uart0_loopback" "uart0_specific")
    
    # UART1 targets should still exist but also be in uart_tests group
    ct_assert_item_has_group("${TARGETS_JSON}" "targets" "run_test_uart1_loopback" "uart_tests")

    # Test help targets JSON - all_peripheral_tests group
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_uart0_loopback")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_uart1_dma")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_spi0_master_mode")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_spi1_dual_quad_mode")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_i2c0_master")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "run_test_i2c1_sensor_read")
    ct_assert_item_in_json("${TARGETS_JSON}" "targets" "help_all_peripheral_tests")
    
    ct_assert_item_has_group("${TARGETS_JSON}" "targets" "run_test_uart0_loopback" "all_peripheral_tests")
    ct_assert_item_has_group("${TARGETS_JSON}" "targets" "run_test_spi0_master_mode" "all_peripheral_tests")
    ct_assert_item_has_group("${TARGETS_JSON}" "targets" "run_test_i2c0_master" "all_peripheral_tests")
    
    # DDR/cache targets should NOT be in all_peripheral_tests group (they're in memory_tests)
    ct_json_find_item("${TARGETS_JSON}" "targets" "run_test_ddr_calibration" ddr_index)
    if(NOT ddr_index EQUAL -1)
        file(READ "${TARGETS_JSON}" json_content)
        string(JSON groups_array GET "${json_content}" "targets" ${ddr_index} "groups")
        string(JSON groups_length LENGTH "${groups_array}")
        set(found_peripheral_group FALSE)
        if(groups_length GREATER 0)
            math(EXPR max_index "${groups_length} - 1")
            foreach(i RANGE 0 ${max_index})
                string(JSON group_value GET "${groups_array}" ${i})
                if(group_value STREQUAL "all_peripheral_tests")
                    set(found_peripheral_group TRUE)
                    break()
                endif()
            endforeach()
        endif()
        
        if(found_peripheral_group)
            message(FATAL_ERROR "Target 'run_test_ddr_calibration' should NOT have group 'all_peripheral_tests'")
        else()
            message(STATUS "✓ Target 'run_test_ddr_calibration' correctly excluded from 'all_peripheral_tests' group")
        endif()
    endif()

    # Test help IPs JSON
    ct_assert_item_in_json("${IPS_JSON}" "ips" "riscv_core_cv32e40p")
    ct_assert_item_in_json("${IPS_JSON}" "ips" "axi_interconnect")
    ct_assert_item_in_json("${IPS_JSON}" "ips" "uart_16550")
    ct_assert_item_in_json("${IPS_JSON}" "ips" "spi_master_apb")
    ct_assert_item_in_json("${IPS_JSON}" "ips" "i2c_master_wb")
    ct_assert_item_in_json("${IPS_JSON}" "ips" "ddr3_controller")
    ct_assert_item_in_json("${IPS_JSON}" "ips" "plic_interrupt_controller")
    ct_assert_item_in_json("${IPS_JSON}" "ips" "timer_subsystem")

    # Test help options JSON
    ct_assert_item_in_json("${OPTIONS_JSON}" "options" "ENABLE_FPU")
    ct_assert_item_in_json("${OPTIONS_JSON}" "options" "ENABLE_COMPRESSED")
    ct_assert_item_in_json("${OPTIONS_JSON}" "options" "ENABLE_DEBUG_MODULE")
    ct_assert_item_in_json("${OPTIONS_JSON}" "options" "ENABLE_TRACE_PORT")
    ct_assert_item_in_json("${OPTIONS_JSON}" "options" "USE_EXTERNAL_DDR")
    ct_assert_item_in_json("${OPTIONS_JSON}" "options" "ENABLE_CRYPTO_ENGINE")
    ct_assert_item_in_json("${OPTIONS_JSON}" "options" "ENABLE_DMA")
    ct_assert_item_in_json("${OPTIONS_JSON}" "options" "LOW_POWER_MODE")

    # Test that descriptions are present
    ct_assert_item_has_description("${TARGETS_JSON}" "targets" "build_bootloader" "Build first-stage bootloader")
    ct_assert_item_has_description("${TARGETS_JSON}" "targets" "sim_core_unit_tests" "Run CPU core unit tests")
    ct_assert_item_has_description("${OPTIONS_JSON}" "options" "ENABLE_FPU" "Enable hardware floating-point unit")
    
    # Test option values and types
    ct_json_find_item("${OPTIONS_JSON}" "options" "ENABLE_FPU" fpu_index)
    if(NOT fpu_index EQUAL -1)
        file(READ "${OPTIONS_JSON}" json_content)
        string(JSON opt_type GET "${json_content}" "options" ${fpu_index} "type")
        string(JSON opt_current GET "${json_content}" "options" ${fpu_index} "current")
        string(JSON opt_default GET "${json_content}" "options" ${fpu_index} "default")
        
        if(NOT opt_type STREQUAL "Boolean")
            message(FATAL_ERROR "ENABLE_FPU should have type 'Boolean', got '${opt_type}'")
        endif()
        if(NOT opt_current STREQUAL "ON")
            message(FATAL_ERROR "ENABLE_FPU current value should be 'ON', got '${opt_current}'")
        endif()
        if(NOT opt_default STREQUAL "ON")
            message(FATAL_ERROR "ENABLE_FPU default value should be 'ON', got '${opt_default}'")
        endif()
        message(STATUS "✓ ENABLE_FPU option has correct type and values")
    endif()

    message(STATUS "All help menu JSON tests passed! ✓")

endfunction()
