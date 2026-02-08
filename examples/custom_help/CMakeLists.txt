include("../../SoCMakeConfig.cmake")
cmake_minimum_required(VERSION 3.25)
project(risc_v_soc NONE)

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

set_target_properties(run_test_pm_voltage_scaling PROPERTIES SOCMAKE_GROUPS voltage)

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


help_custom_targets("uart_tests" PATTERN "run_test_uart[0-9]_*" DESCRIPTION "Uart tests")
help_custom_targets("spi_tests" PATTERN "run_test_spi[0-9]_*" DESCRIPTION "SPI test cases")
help_custom_targets("i2c_tests" PATTERN "run_test_i2c[0-9]_*")
help_custom_targets("memory_tests" PATTERN "run_test_ddr_*|run_test_cache_*")
help_custom_targets("power_tests" PATTERN "run_test_pm_*")

help_custom_targets("uart0_specific" PATTERN ".*_uart0_.*")
help_custom_targets("all_peripheral_tests" PATTERN "run_test_(uart|spi|i2c)[0-9]_.*")

# IP blocks
add_ip(riscv_core_cv32e40p DESCRIPTION "This is a riscv core")
add_ip(axi_interconnect)
add_ip(uart_16550)
add_ip(spi_master_apb)
add_ip(i2c_master_wb)
add_ip(ddr3_controller)
add_ip(plic_interrupt_controller)
add_ip(timer_subsystem)

help_custom_ips("master" PATTERN "master")

set_target_properties(riscv_core_cv32e40p PROPERTIES SOCMAKE_GROUPS core)

# Configuration options
option_boolean(ENABLE_FPU "Enable hardware floating-point unit" ON)
option_boolean(ENABLE_COMPRESSED "Enable RISC-V compressed instructions (RVC)" ON ADVANCED)
option_boolean(ENABLE_DEBUG_MODULE "Include on-chip debug module (JTAG)" ON)
option_boolean(ENABLE_TRACE_PORT "Enable instruction trace port for profiling" OFF)
option_boolean(USE_EXTERNAL_DDR "Use external DDR3 memory (vs on-chip SRAM only)" ON)
option_boolean(ENABLE_CRYPTO_ENGINE_ASDAaaDaaADASaaaaaass "Include hardware cryptography accelerator" OFF)
option_boolean(ENABLE_DMA "Include direct memory access controller" ON)
option_boolean(LOW_POWER_MODE "Optimize for low power consumption" OFF)

option_directory(SOME_DIR "Directory to some random location on the file system" "/tools/work/go/ipxact/ipxact_schema_files/1685-2009-VE-1.0/AMS/wire.xsd" )
option_enum(SIMULATORS "Which simulator" "verilator;modelsim;questasim;xcelium"  "verilator")


help()
