add_ip(top)

ip_sources(top SYSTEMRDL
    ${CMAKE_CURRENT_LIST_DIR}/src.rdl)


add_subdirectory(ip2)
add_subdirectory(ip3)
add_subdirectory(ip4)

ip_link(ip2 ip4)

ip_link(top ip3)
ip_link(ip3 ip2)
