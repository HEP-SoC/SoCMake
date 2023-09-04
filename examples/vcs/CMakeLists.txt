include("deps/deps.cmake")

if(SIM_VCS)
    if(NOT VCS_HOME AND NOT ENV{VCS_HOME})
        set(VCS_HOME /eda/synopsys/2022-23/RHELx86/VCS_2022.06-SP2)
    endif()
    vcs_init()
else()
    set(VERILATOR_HOME /cerneda/various/RHELx86/verilator-4.228/)
    set(SYSTEMC_HOME /scratch/rpejasin/socmake/SoCMake-Ibex/deps/_deps/verisc/open/systemc-2.3.3/)
endif()

cmake_minimum_required(VERSION 3.25)
project(example CXX C)

if(NOT SIM_VCS)
    find_package(SystemCLanguage REQUIRED
        HINTS ${SYSTEMC_HOME}/*/*/*
        )
    set(CMAKE_CXX_STANDARD ${SystemC_CXX_STANDARD})
endif()

add_subdirectory(../verilator/adder "adder")

add_executable(test sc_main.cpp)

if(SIM_VCS)
    vcs_vlogan(cern::ip::adder::0.0.1
        OUTDIR ${PROJECT_BINARY_DIR})

    target_link_libraries(test
        cern::ip::adder::0.0.1::vcs
        vcs::libs
        )
else()
    verilate(cern::ip::adder::0.0.1
        SYSTEMC
        PREFIX adder
        VERILATOR_ARGS --pins-bv 1
        )

    target_link_libraries(test
        cern::ip::adder::0.0.1::vlt
        SystemC::systemc
        )
endif()

target_compile_definitions(test PUBLIC
    VERBOSE=1
    )

