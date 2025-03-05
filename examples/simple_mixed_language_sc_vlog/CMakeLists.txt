include("../../SoCMakeConfig.cmake")

set(FETCHCONTENT_BASE_DIR ${CMAKE_CURRENT_LIST_DIR}/deps/_deps)
set(CMAKE_EXPORT_COMPILE_COMMANDS TRUE)
set(SOCMAKE_ADDITIONAL_LANGUAGES SYSTEMC)

option_enum(SIMULATOR "Which Simulator to use" "mgc;osci" "mgc")
option_enum(TEST_LANG "Language for test module" "verilog;systemc" "verilog")
option_enum(DUT_LANG "Language for DUT modules" "verilog;systemc" "verilog")
option_boolean(MGC_GUI "Use GUI for modelsim" OFF)

cmake_minimum_required(VERSION 3.25)
project(simple_mixed_language_sc_vlog NONE)

add_subdirectory(tests)


# ################################################
# ################ MODELSIM ######################
# ################################################

if(SIMULATOR STREQUAL "mgc")
    if(MGC_GUI)
        set(modelsim_gui_args GUI_VISUALIZER RUN_ARGS -vopt -voptargs=+acc=pn)
    endif()
    modelsim(test_counters QUIET
        ${modelsim_gui_args}
        )
endif()

# ################################################
# ######### Open-Source simulation ###############
# ################################################

if(SIMULATOR STREQUAL "osci")
    if(TEST_LANG STREQUAL "verilog" AND DUT_LANG STREQUAL "systemc")
        message(FATAL_ERROR "Incorrect project configuration, Open-Source simulation cannot support Verilog-SystemC hierachy")
    endif()

    # If Hierarchy is Verilog-Verilog use only Verilator to simulate whole design 
    # Generate main.cpp with MAIN argument
    if(TEST_LANG STREQUAL "verilog")
        verilator(test_counters MAIN
                    VERILATOR_ARGS --timing)
    endif()

    # In case hierarchy is SystemC-SystemC or SystemC-Verilog
    if(TEST_LANG STREQUAL "systemc")
        enable_language(CXX)
        set(CMAKE_CXX_STANDARD 11)
        systemc_build(VERSION 2.3.4 EXACT_VERSION)

        add_executable(systemc_example
            tests/sc_main.cpp
            )

        target_link_libraries(systemc_example PUBLIC
            SystemC::systemc
            test_counters
        )

        # In case DUT is verilog, use Verilator to convert from Verilog to SystemC
        if(DUT_LANG STREQUAL "verilog")
            verilator(counters SYSTEMC
                VERILATOR_ARGS --pins-sc-uint
            )

            # Link into the verilated static library
            target_link_libraries(systemc_example PUBLIC
                counters__vlt
            )
        endif()
    endif()

endif()

help()
