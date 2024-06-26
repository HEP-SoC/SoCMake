include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/../../../hwip.cmake")

add_ip(base
    VENDOR cern
    LIBRARY socgen
    VERSION 0.0.5
)

ip_sources(${IP} SYSTEMRDL_SOCGEN
    ${CMAKE_CURRENT_LIST_DIR}/socgen_props.rdl
    )

ip_sources(${IP} SYSTEMRDL
    ${CMAKE_CURRENT_LIST_DIR}/socgen_props.rdl
    )
