include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/../../../hwip.cmake")

add_ip(base
    VENDOR cern
    LIBRARY ldsgen
    VERSION 0.0.1
    )
ip_sources(${IP} SYSTEMRDL
    ${CMAKE_CURRENT_LIST_DIR}/lds_props.rdl
    )

