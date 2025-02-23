include("../../SoCMakeConfig.cmake")

set(FETCHCONTENT_BASE_DIR ${CMAKE_CURRENT_LIST_DIR}/deps/_deps)
set(CMAKE_EXPORT_COMPILE_COMMANDS TRUE)
set(SOCMAKE_ADDITIONAL_LANGUAGES SYSTEMC)

option_enum(SCENARIO "Which SystemC and Verilog scenario to run" "OSCI_SC;VERILATOR_SC_VLOG;MGC_SC_VLOG;MGC_VLOG_SC;MGC_VLOG;MGC_SC" MGC_SC_VLOG)

cmake_minimum_required(VERSION 3.25)
project(simple_mixed_language_sc_vlog NONE)


################################################
############ PURE VERILOG ######################
################################################

if(SCENARIO STREQUAL "MGC_VLOG")
    add_ip(counters)

    ip_sources(counters VERILOG
        ./counter1.v
        ./counter2.v
        ./counters.v
        )

    add_ip(test_counters)

    ip_sources(test_counters VERILOG
        ./test_counters.v
        )

    ip_link(test_counters counters)

    modelsim(${IP})
endif()

################################################
############ PURE SYSTEMC OSCI #################
################################################

if(SCENARIO STREQUAL "OSCI_SC")

    enable_language(CXX)
    set(CMAKE_CXX_STANDARD 11)

    systemc_build(VERSION 2.3.4 EXACT_VERSION)

    add_executable(systemc_example
        sc_main.cpp
        )

    target_link_libraries(systemc_example PUBLIC
        SystemC::systemc)

endif()

################################################
############ PURE SYSTEMC MODELSIM #############
################################################

if(SCENARIO STREQUAL "MGC_SC")
    add_ip(counters)

    ip_sources(counters SYSTEMC
        HEADERS
        ./counter1.h
        ./counter2.h
        ./counters.h
        )

    add_ip(test_counters)

    ip_sources(test_counters SYSTEMC
        ./test_counters.cpp
        HEADERS
        ./test_counters.h
        )

    ip_link(test_counters counters)

    modelsim(${IP})
endif()


################################################
############ SYSTEMC ON TOP MODELSIM ###########
################################################

if(SCENARIO STREQUAL "MGC_SC_VLOG")
    add_ip(counters)

    ip_sources(counters VERILOG
        ./counter1.v
        ./counter2.v
        ./counters.v
        )

    modelsim_scgenmod(counters)

    add_ip(test_counters)

    ip_sources(test_counters SYSTEMC
        ./test_counters.cpp
        HEADERS
        ./test_counters.h
        )

    ip_link(test_counters counters)

    modelsim(${IP})
endif()


################################################
############ VERILOG ON TOP MODELSIM ###########
################################################

if(SCENARIO STREQUAL "MGC_VLOG_SC")
    add_ip(counters)

    ip_sources(counters SYSTEMC
        ./counters.cpp
        HEADERS
        ./counter1.h
        ./counter2.h
        ./counters.h
        )

    add_ip(test_counters)

    ip_sources(test_counters VERILOG
        ./test_counters.v
        )

    ip_link(test_counters counters)

    modelsim(${IP})
endif()

################################################
############ OSCI SC ON TOP VERILATOR ##########
################################################

if(SCENARIO STREQUAL "VERILATOR_SC_VLOG")

    add_ip(counters)

    ip_sources(counters VERILOG
        ./counter1.v
        ./counter2.v
        ./counters.v
        )

    enable_language(CXX)
    set(CMAKE_CXX_STANDARD 11)
    systemc_build(VERSION 2.3.4 EXACT_VERSION)

    verilator(counters SYSTEMC
        VERILATOR_ARGS --pins-sc-uint
    )

    add_executable(systemc_example
        sc_main.cpp
        )

    target_link_libraries(systemc_example PUBLIC
        SystemC::systemc
        counters__vlt
    )

endif()

help()
