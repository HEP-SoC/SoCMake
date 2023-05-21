cmake_minimum_required(VERSION 3.25)
project(gpio NONE)

include("deps/deps.cmake")

add_library(gpio INTERFACE       # Define RTL library and add RTL files
    rtl/gpio_core.sv
    rtl/gpio.sv
    )

set_property(TARGET gpio PROPERTY RDL_FILES # Add SystemRDL files
    rdl/gpio_defs.rdl
    gpio.rdl
    )

add_library(pad_prim INTERFACE
    rtl/pads/pad_prim.v
    )

add_library(prim_cell INTERFACE
    rtl/cells/prim_cell.v
    )

add_library(prim INTERFACE
    rtl/prim/prim.v
    )

add_library(lowest_prim INTERFACE
    rtl/prim/lowest_prim.v
    )

target_link_libraries(prim INTERFACE lowest_prim)
target_link_libraries(prim_cell INTERFACE lowest_prim)
target_link_libraries(pad_prim INTERFACE prim_cell prim lowest_prim)
target_link_libraries(gpio INTERFACE pad_prim lowest_prim)

get_target_property(JUST_GPIO_SOURCES gpio SOURCES)
get_rtl_target_sources(SOURCES gpio)

message("JUST_GPIO_SOURCES: ${JUST_GPIO_SOURCES}")
message("SOURCES: ${SOURCES}")
