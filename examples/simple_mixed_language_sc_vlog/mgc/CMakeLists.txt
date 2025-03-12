include("../../../SoCMakeConfig.cmake")
socmake_add_languages(SYSTEMC)

set(CMAKE_CXX_COMPILER /home/risto/mgc/questa/questasim/gcc-7.4.0-linux/bin/g++)

cmake_minimum_required(VERSION 3.25)
project(simple_mixed_language_sc_vlog CXX)

######
###### SystemC-SystemC
######

# add_library(counters STATIC
#     ../counters/sc/counters.cpp
#     ../tests/sc/test_counters.cpp
#     )
#
#
# target_include_directories(counters PUBLIC
#     ../counter1/sc/
#     ../counter2/sc/
#     ../counters/sc/
#     # ../tests/sc/
#     /home/risto/mgc/questa/questasim/include/systemc
#     /home/risto/mgc/questa/questasim/include
#     /home/risto/mgc/questa/questasim/include/ac_types
#     )
#
# target_compile_options(counters PUBLIC
#     -fPIC
#     -m32
#     )
#
# target_link_options(counters PUBLIC
#     -fPIC
#     -m32
#     )
#
# target_compile_definitions(counters PUBLIC
#     MTI_SYSTEMC
#     )
#
# # target_link_libraries(counters PUBLIC
# #     /home/risto/mgc/questa/questasim/linux/libsystemc_gcc74.a
# #     /home/risto/mgc/questa/questasim/linux/libmtipli.so
# #     m
# # )
#
# add_custom_target(elaborate
#     COMMAND sccom 
#         "$<PATH:ABSOLUTE_PATH,NORMALIZE,$<LIST:GET, $<TARGET_PROPERTY:counters,SOURCES>,-1>,$<TARGET_PROPERTY:counters,SOURCE_DIR>>" # Get Absolute path to the last source file
#         "$<LIST:TRANSFORM,$<TARGET_PROPERTY:counters,INCLUDE_DIRECTORIES>,PREPEND,-I>" 
#         "$<LIST:TRANSFORM,$<TARGET_PROPERTY:counters,COMPILE_DEFINITIONS>,PREPEND,-D>" 
#
#     COMMAND sccom -link $<TARGET_FILE:counters>
#     COMMAND_EXPAND_LISTS
#     DEPENDS counters
# )
#
# add_custom_target(run
#     COMMAND vsim -c -do "run 100ns\; exit" "$<PATH:GET_STEM,$<LIST:GET, $<TARGET_PROPERTY:counters,SOURCES>,-1>>"
#     VERBATIM
#     DEPENDS elaborate
# )


####
#### SystemC Verilog
####

#  add_ip(counter1)
#
# ip_sources(counter1 VERILOG
#     ../counter1/vlog/counter1.v)
#
# add_ip(counter2)
#
# ip_sources(counter2 VERILOG
#     ../counter2/vlog/counter2.v)
#
# add_ip(counters)
#
# ip_sources(counters VERILOG
#     ../counters/vlog/counters.v)
#
# ip_link(counters counter1 counter2)
#
# target_include_directories(counters INTERFACE
#     ${CMAKE_BINARY_DIR}
# )
#
# add_library(test_counters STATIC
#     ../tests/sc/test_counters.cpp
#     ../tests/sc/test_counters.cpp
#     )
#
#
# target_include_directories(test_counters PUBLIC
#     ../tests/sc/
#
#     /home/risto/mgc/questa/questasim/include/systemc
#     /home/risto/mgc/questa/questasim/include
#     /home/risto/mgc/questa/questasim/include/ac_types
#     )
#
# target_compile_options(test_counters PUBLIC
#     -fPIC
#     -m32
#     )
#
# target_link_options(test_counters PUBLIC
#     -fPIC
#     -m32
#     )
#
# target_compile_definitions(test_counters PUBLIC
#     MTI_SYSTEMC
#     )
#
# target_link_libraries(test_counters PRIVATE
#     counters)
#
# get_ip_sources(sv_files ${IP} VERILOG)
# add_custom_target(scgenmod
#     COMMAND vlog ${sv_files}
#     COMMAND scgenmod -bool -sc_uint ${IP} > ${CMAKE_BINARY_DIR}/${IP}.h
# )
# add_dependencies(test_counters scgenmod)
#
# add_custom_target(elaborate
#     COMMAND sccom 
#         "$<PATH:ABSOLUTE_PATH,NORMALIZE,$<LIST:GET, $<TARGET_PROPERTY:test_counters,SOURCES>,-1>,$<TARGET_PROPERTY:test_counters,SOURCE_DIR>>" # Get Absolute path to the last source file
#         "$<LIST:TRANSFORM,$<TARGET_PROPERTY:test_counters,INCLUDE_DIRECTORIES>,PREPEND,-I>" 
#         "$<LIST:TRANSFORM,$<TARGET_PROPERTY:test_counters,COMPILE_DEFINITIONS>,PREPEND,-D>" 
#
#     COMMAND sccom -link $<TARGET_FILE:test_counters>
#     COMMAND_EXPAND_LISTS
#     DEPENDS test_counters
# )
#
# add_custom_target(run
#     COMMAND vsim -c -do "run 100ns\; exit" test_counters -t 1ps
#     VERBATIM
#     DEPENDS elaborate
# )

####
#### Verilog SystemC
####


add_library(counters STATIC
    ../counters/sc/counters.cpp
    ../counters/sc/counters.cpp
    )


target_include_directories(counters PUBLIC
    ../counter1/sc/
    ../counter2/sc/
    ../counters/sc/

    /home/risto/mgc/questa/questasim/include/systemc
    /home/risto/mgc/questa/questasim/include
    /home/risto/mgc/questa/questasim/include/ac_types
    )

target_compile_options(counters PUBLIC
    -fPIC
    -m32
    )

target_link_options(counters PUBLIC
    -fPIC
    -m32
    )

target_compile_definitions(counters PUBLIC
    MTI_SYSTEMC
    )

add_ip(test_counters)

ip_sources(test_counters VERILOG
    ../tests/vlog/test_counters.v
)

add_custom_target(elaborate
    COMMAND sccom 
        "$<PATH:ABSOLUTE_PATH,NORMALIZE,$<LIST:GET, $<TARGET_PROPERTY:counters,SOURCES>,-1>,$<TARGET_PROPERTY:counters,SOURCE_DIR>>" # Get Absolute path to the last source file
        "$<LIST:TRANSFORM,$<TARGET_PROPERTY:counters,INCLUDE_DIRECTORIES>,PREPEND,-I>" 
        "$<LIST:TRANSFORM,$<TARGET_PROPERTY:counters,COMPILE_DEFINITIONS>,PREPEND,-D>" 
    COMMAND vlog ${CMAKE_CURRENT_SOURCE_DIR}/../tests/vlog/test_counters.v
    COMMAND sccom -link $<TARGET_FILE:counters>
    COMMAND_EXPAND_LISTS
)

add_custom_target(run
    COMMAND vsim -c -do "run 100ns\; exit" test_counters -t 1ps
    VERBATIM
    DEPENDS elaborate counters
)
