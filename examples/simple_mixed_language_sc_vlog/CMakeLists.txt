include("../../SoCMakeConfig.cmake")


set(FETCHCONTENT_BASE_DIR ${CMAKE_CURRENT_LIST_DIR}/deps/_deps)
set(CMAKE_EXPORT_COMPILE_COMMANDS TRUE)
set(SOCMAKE_ADDITIONAL_LANGUAGES SYSTEMC)

option_enum(SIMULATOR "Which Simulator to use" "questa;osci;xcelium;vcs" "vcs")
option_enum(TEST_LANG "Language for test module" "verilog;systemc" "verilog")
option_enum(DUT_LANG "Language for DUT modules" "verilog;systemc" "verilog")
option_boolean(QUESTA_GUI "Use GUI for questasim" OFF)

if(SIMULATOR STREQUAL "xcelium")
    xcelium_configure_cxx(LIBRARIES SystemC)
elseif(SIMULATOR STREQUAL "questa")
    questasim_configure_cxx(LIBRARIES SystemC)
elseif(SIMULATOR STREQUAL "vcs")
    vcs_configure_cxx(LIBRARIES SystemC)
endif()

# If Using Verilator and Testbench is Verilog, we need coroutines for --timing from C++17
if(SIMULATOR STREQUAL "osci" AND TEST_LANG STREQUAL "verilog")
    set(CMAKE_CXX_STANDARD 17)
else()
    set(CMAKE_CXX_STANDARD 11)
endif()

cmake_minimum_required(VERSION 3.25)
project(simple_mixed_language_sc_vlog CXX)

add_subdirectory(tests)

# ################################################
# ################ XCELIUM #######################
# ################################################

if(SIMULATOR STREQUAL "xcelium")
    xcelium(test_counters
        ELABORATE_ARGS -timescale 1ps/1ps)
endif()

# ################################################
# ################ VCS ###########################
# ################################################

if(SIMULATOR STREQUAL "vcs")
    vcs(test_counters TOP_MODULE test_counters
        ELABORATE_ARGS  -timescale=1ps/1ps
        # 32BIT
        )

endif()

# ################################################
# ################ QUESTASIM #####################
# ################################################

if(SIMULATOR STREQUAL "questa")
    if(QUESTA_GUI)
        set(questasim_gui_args GUI)
        set(questasim_gui_run_args -vopt -voptargs=+acc=pn)
    endif()
    questasim(test_counters QUIET
        ${questasim_gui_args}
        RUN_ARGS -t 1ps ${questasim_gui_run_args}
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
        systemc_build(VERSION 2.3.4 EXACT_VERSION)

        add_executable(systemc_example
            tests/sc_main.cpp
            )

        target_link_libraries(systemc_example PUBLIC
            test_counters
        )
        target_link_libraries(test_counters PUBLIC SystemC::systemc)
        target_compile_definitions(test_counters PUBLIC OSCI)


        # In case DUT is verilog, use Verilator to convert from Verilog to SystemC
        if(DUT_LANG STREQUAL "verilog")
            verilator(counters SYSTEMC
                VERILATOR_ARGS --pins-sc-uint --timescale-override 1ps/1ps
                PREFIX counters

            )

            # Link into the verilated static library
            target_link_libraries(test_counters PUBLIC
                counters__vlt
            )
        elseif(DUT_LANG STREQUAL "systemc")
            target_link_libraries(counters PUBLIC SystemC::systemc)
            target_compile_definitions(counters PUBLIC OSCI)
        endif()
    endif()

endif()

help()
