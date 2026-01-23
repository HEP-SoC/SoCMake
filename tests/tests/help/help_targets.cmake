include("${CMAKE_CURRENT_LIST_DIR}/../../../SoCMakeConfig.cmake")

set(CDIR ${CMAKE_CURRENT_LIST_DIR})

set(TEST_NAME ip_link1)

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
    help_custom_targets("build" TARGET_LIST 
        build_bootloader 
        build_firmware 
        build_fpga_bitstream 
        build_documentation)

    help_custom_targets("simulation" TARGET_LIST 
        sim_core_unit_tests 
        sim_peripheral_tests 
        sim_integration)

    help_custom_targets("flash" TARGET_LIST 
        flash_bootloader 
        flash_firmware 
        flash_fpga)

    help_custom_targets("uart_tests" PATTERN "run_test_uart[0-9]_*")
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

    # Helper function to check if target is in help file
    function(ct_assert_target_in_help_file HELP_FILE TARGET_NAME)
        if(NOT EXISTS "${HELP_FILE}")
            message(FATAL_ERROR "Help file does not exist: ${HELP_FILE}")
        endif()
        
        file(READ "${HELP_FILE}" content)
        string(FIND "${content}" "${TARGET_NAME}" pos)
        if(pos EQUAL -1)
            message(FATAL_ERROR "Target '${TARGET_NAME}' not found in ${HELP_FILE}")
        else()
            message(STATUS "✓ Target '${TARGET_NAME}' found in ${HELP_FILE}")
        endif()
    endfunction()

    # Test help_build.txt
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_build.txt" "build_bootloader")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_build.txt" "build_firmware")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_build.txt" "build_fpga_bitstream")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_build.txt" "build_documentation")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_build.txt" "help_build")

    # Test help_simulation.txt
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_simulation.txt" "sim_core_unit_tests")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_simulation.txt" "sim_peripheral_tests")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_simulation.txt" "sim_integration")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_simulation.txt" "help_simulation")

    # Test help_flash.txt
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_flash.txt" "flash_bootloader")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_flash.txt" "flash_firmware")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_flash.txt" "flash_fpga")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_flash.txt" "help_flash")

    # Test help_uart_tests.txt
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_uart_tests.txt" "run_test_uart0_loopback")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_uart_tests.txt" "run_test_uart0_baud_rates")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_uart_tests.txt" "run_test_uart0_interrupts")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_uart_tests.txt" "run_test_uart1_loopback")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_uart_tests.txt" "run_test_uart1_dma")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_uart_tests.txt" "help_uart_tests")

    # Test help_spi_tests.txt
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_spi_tests.txt" "run_test_spi0_master_mode")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_spi_tests.txt" "run_test_spi0_slave_mode")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_spi_tests.txt" "run_test_spi1_flash_access")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_spi_tests.txt" "run_test_spi1_dual_quad_mode")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_spi_tests.txt" "help_spi_tests")

    # Test help_i2c_tests.txt
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_i2c_tests.txt" "run_test_i2c0_master")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_i2c_tests.txt" "run_test_i2c0_multi_master")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_i2c_tests.txt" "run_test_i2c1_sensor_read")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_i2c_tests.txt" "help_i2c_tests")

    # Test help_memory_tests.txt
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_memory_tests.txt" "run_test_ddr_calibration")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_memory_tests.txt" "run_test_ddr_bandwidth")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_memory_tests.txt" "run_test_cache_coherency")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_memory_tests.txt" "help_memory_tests")

    # Test help_power_tests.txt
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_power_tests.txt" "run_test_pm_sleep_modes")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_power_tests.txt" "run_test_pm_clock_gating")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_power_tests.txt" "run_test_pm_voltage_scaling")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_power_tests.txt" "help_power_tests")

    # Test help_uart0_specific.txt
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_uart0_specific.txt" "run_test_uart0_loopback")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_uart0_specific.txt" "run_test_uart0_baud_rates")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_uart0_specific.txt" "run_test_uart0_interrupts")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_uart0_specific.txt" "help_uart0_specific")
    
    # UART1 targets should NOT be in uart0_specific
    file(READ "${CMAKE_BINARY_DIR}/help_uart0_specific.txt" uart0_content)
    string(FIND "${uart0_content}" "run_test_uart1_loopback" pos)
    if(NOT pos EQUAL -1)
        message(FATAL_ERROR "Target 'run_test_uart1_loopback' should NOT be in help_uart0_specific.txt")
    else()
        message(STATUS "✓ Target 'run_test_uart1_loopback' correctly excluded from help_uart0_specific.txt")
    endif()

    # Test help_all_peripheral_tests.txt
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_all_peripheral_tests.txt" "run_test_uart0_loopback")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_all_peripheral_tests.txt" "run_test_uart1_dma")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_all_peripheral_tests.txt" "run_test_spi0_master_mode")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_all_peripheral_tests.txt" "run_test_spi1_dual_quad_mode")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_all_peripheral_tests.txt" "run_test_i2c0_master")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_all_peripheral_tests.txt" "run_test_i2c1_sensor_read")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_all_peripheral_tests.txt" "help_all_peripheral_tests")
    
    # DDR/cache targets should NOT be in all_peripheral_tests
    file(READ "${CMAKE_BINARY_DIR}/help_all_peripheral_tests.txt" peripheral_content)
    string(FIND "${peripheral_content}" "run_test_ddr_calibration" pos)
    if(NOT pos EQUAL -1)
        message(FATAL_ERROR "Target 'run_test_ddr_calibration' should NOT be in help_all_peripheral_tests.txt")
    else()
        message(STATUS "✓ Target 'run_test_ddr_calibration' correctly excluded from help_all_peripheral_tests.txt")
    endif()

    # Test help_ips.txt
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_ips.txt" "riscv_core_cv32e40p")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_ips.txt" "axi_interconnect")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_ips.txt" "uart_16550")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_ips.txt" "spi_master_apb")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_ips.txt" "i2c_master_wb")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_ips.txt" "ddr3_controller")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_ips.txt" "plic_interrupt_controller")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_ips.txt" "timer_subsystem")

    # Test help_options.txt
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_options.txt" "ENABLE_FPU")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_options.txt" "ENABLE_COMPRESSED")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_options.txt" "ENABLE_DEBUG_MODULE")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_options.txt" "ENABLE_TRACE_PORT")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_options.txt" "USE_EXTERNAL_DDR")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_options.txt" "ENABLE_CRYPTO_ENGINE")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_options.txt" "ENABLE_DMA")
    ct_assert_target_in_help_file("${CMAKE_BINARY_DIR}/help_options.txt" "LOW_POWER_MODE")

    # Test that descriptions are present
    file(READ "${CMAKE_BINARY_DIR}/help_build.txt" build_content)
    string(FIND "${build_content}" "Build first-stage bootloader" pos)
    if(pos EQUAL -1)
        message(FATAL_ERROR "Description 'Build first-stage bootloader' not found in help_build.txt")
    else()
        message(STATUS "✓ Description found in help_build.txt")
    endif()

    message(STATUS "All help menu tests passed! ✓")

endfunction()
