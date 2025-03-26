cmake_minimum_required(VERSION 3.25)
project(leon2 NONE)

include(FetchContent)
FetchContent_Declare(
  leon2
  URL https://www.accellera.org/images/activities/committees/ip-xact/Leon2_1685-2022.zip
)
FetchContent_MakeAvailable(leon2)

include("../../../../SoCMakeConfig.cmake")

socmake_add_languages(SYSTEMC UNKNOWN)
set(SOCMAKE_ALLOW_UNDEFINED_TARGETS TRUE)

if(NOT EXISTS "${leon2_SOURCE_DIR}/spiritconsortium.org/Leon2TLM/timers/1.4/spiritconsortium.org_Leon2TLM_timers_1.4.cmake")
    file(GLOB_RECURSE ipxact_files LIST_DIRECTORIES FALSE  "${leon2_SOURCE_DIR}/*/*.xml")
    foreach(file ${ipxact_files})
        add_ip_from_ipxact(${file})
    endforeach()
else()
    
    file(GLOB_RECURSE cmake_files LIST_DIRECTORIES FALSE  "${leon2_SOURCE_DIR}/*/*.cmake")
    foreach(file ${cmake_files})
        include(${file})
    endforeach()
endif()

set(SOCMAKE_ALLOW_UNDEFINED_TARGETS FALSE)

# flatten_graph(spiritconsortium.org__Leon2RTL__design_Leon2Platform__1.0)
ghdl(spiritconsortium.org::Leon2RTL::design_Leon2Platform::1.0)
help()
