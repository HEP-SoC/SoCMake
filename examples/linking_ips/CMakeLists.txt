cmake_minimum_required(VERSION 3.28)
project(example 
    LANGUAGES NONE
    VERSION 0.0.1)

include("deps/deps.cmake")
# highlight-next-line
set(SOCMAKE_NOWARN_VLNV TRUE) # Do not warn incomplete VLNV format

## Define IP TOP
# highlight-next-line
add_ip(top)
ip_sources(top VERILOG
    ${PROJECT_SOURCE_DIR}/top.v
    )

# Define IP prim10
# highlight-next-line
add_ip(prim10)
ip_sources(prim10 VERILOG
    ${PROJECT_SOURCE_DIR}/prim10.v
    )

## Define IP prim11
# highlight-next-line
add_ip(prim11)
ip_sources(prim11 VERILOG
    ${PROJECT_SOURCE_DIR}/prim11.v
    )

## Define IP prim00
# highlight-next-line
add_ip(prim00)
ip_sources(prim00 VERILOG
    ${PROJECT_SOURCE_DIR}/prim00.v
    )

## Define IP prim01
add_ip(prim01)
ip_sources(prim01 VERILOG
    ${PROJECT_SOURCE_DIR}/prim01.v
    )

# highlight-start
ip_link(top prim10 prim11)
ip_link(prim10 prim00)
ip_link(prim11 prim00 prim01)
# highlight-end

# Get Verilog sources
get_ip_sources(V_SOURCES top VERILOG)
# Just print sources
string(REPLACE ";" "\n    " V_SOURCES "${V_SOURCES}")
message("V_SOURCES: \n    ${V_SOURCES}")
