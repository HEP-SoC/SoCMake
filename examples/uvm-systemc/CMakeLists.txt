include("../../SoCMakeConfig.cmake")

# xcelium_configure_cxx(LIBRARIES SystemC TLM2)
# vcs_configure_cxx(LIBRARIES SystemC)
modelsim_configure_cxx(LIBRARIES SystemC)

cmake_minimum_required(VERSION 3.25)
project(uvm-systemc_example CXX)


# set(FETCHCONTENT_BASE_DIR ${CMAKE_CURRENT_LIST_DIR}/deps/_deps)

# systemc_build(VERSION 3.0.0 EXACT_VERSION)
# uvm_systemc_xcelium_build(VERSION 1.0-beta6)
# uvm_systemc_vcs_build(VERSION 1.0-beta6)
uvm_systemc_questa_build(VERSION 1.0-beta6)

add_library(systemc_example  SHARED
    hello_world.cpp
    )
target_include_directories(systemc_example PUBLIC
    .
    )

target_link_libraries(systemc_example PUBLIC
    UVM-SystemC-Questa::shared
    SoCMake::SystemC
    # SoCMake::TLM2
    )

# xcelium(systemc_example TOP_MODULE sc_main)
# vcs(systemc_example TOP_MODULE sc_main)
modelsim(systemc_example TOP_MODULE sc_main)
