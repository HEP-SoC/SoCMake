# Test workaround for quirk at https://cmake.org/cmake/help/v3.30/prop_tgt/INTERFACE_LINK_LIBRARIES.html
# In case INTERFACE library ("top" in this case) is defined in a subdirectory
# and target_link_libraries() was called on that lib ("top") from a different source directory
# CMake wraps INTERFACE_LINK_LIBRARIES with ::@(directory-id);...;::@
# Graph traversal functions should ignore this wrapper

include("${CMAKE_CURRENT_LIST_DIR}/../../../../CMakeLists.txt")
set(THIS_DIR ${CMAKE_CURRENT_LIST_DIR})

set(TEST_NAME ip_link_different_subdir)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(subip)

    add_subdirectory(${THIS_DIR}/ips "ips")
    ip_link(top subip)

    # This would normally fail, as flatten_graph would fail
    get_ip_sources(SOURCES top SYSTEMRDL)
endfunction()
