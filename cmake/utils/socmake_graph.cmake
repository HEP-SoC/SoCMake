#[[[ @module socmake_graph
#]]

include_guard(GLOBAL)
include("${CMAKE_CURRENT_LIST_DIR}/socmake_message.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/get_interface_link_libraries.cmake")

#[[[
# Flatten the dependency graph of NODE into a topologically-sorted flat list.
#
# With no ``EXCLUDED_IPS``, the result is cached in the ``FLAT_GRAPH`` target property (read it back
# with ``get_property``). When ``EXCLUDED_IPS`` is passed, the excluded IPs and any of their
# dependencies that are not also reachable through a non-excluded IP are left out of the traversal;
# since that result is specific to this call's exclusion set, it is returned via ``OUTVAR`` instead
# of being cached.
#
# :param NODE: The root IP target whose dependency graph should be flattened.
# :type NODE: string
#
# **Keyword Arguments**
#
# :keyword OUTVAR: Variable that receives the flattened list. Required when ``EXCLUDED_IPS`` is used.
# :type OUTVAR: string
# :keyword EXCLUDED_IPS: Exclude the listed IPs (and dependencies only reachable through them) from the graph.
# :type EXCLUDED_IPS: list[string]
#]]
function(flatten_graph NODE)
    set(options)
    set(oneValueArgs OUTVAR)
    set(multiValueArgs EXCLUDED_IPS)

    cmake_parse_arguments(
        ARG
        "${options}"
        "${oneValueArgs}"
        "${multiValueArgs}"
        ${ARGN}
    )
    alias_dereference(NODE ${NODE})

    set(excluded_reallibs)
    foreach(excl_ip ${ARG_EXCLUDED_IPS})
        alias_dereference(excl_reallib ${excl_ip})
        list(APPEND excluded_reallibs ${excl_reallib})
    endforeach()

    # __GLOBAL_STACK will hold the flattened graph as the DFS is traversing the tree
    set_property(GLOBAL PROPERTY __GLOBAL_STACK "")
    # __ALREADY_VISITED flag marks that the node was already visited by the DFS search algorithm
    # Since DFS visit every node once for a DAG, if a node is visited twice a cycle was detected
    set_property(TARGET ${NODE} PROPERTY __ALREADY_VISITED FALSE)
    # Once all the children of the node have been visited, mark this node as TRUE to avoid reentering it
    set_property(TARGET ${NODE} PROPERTY __NODE_PROCESSED FALSE)

    # Recursive DFS topological sort
    __dfs_topo(${NODE} unused "${excluded_reallibs}")

    get_property(STACK GLOBAL PROPERTY __GLOBAL_STACK)

    foreach(lib ${STACK}) # Clear the temporary properties
        alias_dereference(lib ${lib})
        set_property(TARGET ${lib} PROPERTY __ALREADY_VISITED FALSE)
        set_property(TARGET ${lib} PROPERTY __NODE_PROCESSED FALSE)
    endforeach()

    if(excluded_reallibs)
        set(${ARG_OUTVAR} ${STACK} PARENT_SCOPE)
    else()
        set_property(TARGET ${NODE} PROPERTY FLAT_GRAPH ${STACK})
    endif()
endfunction()

# This function is a recursive DFS topological sort
#
# Will return 0 if the node doesn't have the TARGET keyword set, was excluded, or has already been
# processed, otherwise, it will return 1 after processing it.
#
# :param NODE: node to be processed
# :type NODE: node
# :param RET: value returned by this function
# :type RET: integer
# :param EXCLUDED: list of real (dereferenced) target names to exclude from the graph
# :type EXCLUDED: list[string]
function(__dfs_topo NODE RET EXCLUDED)
    alias_dereference(NODE ${NODE})

    # Skip non-targets (like -pthread, etc.)
    if(NOT TARGET ${NODE})
        set(${RET} 0 PARENT_SCOPE)
        return()
    endif()

    # Skip excluded IPs entirely: don't visit their dependencies and don't add them to the
    # graph. A dependency also reachable through a non-excluded IP is still visited normally
    # via that other path.
    if(NODE IN_LIST EXCLUDED)
        set(${RET} 0 PARENT_SCOPE)
        return()
    endif()

    # Already processed, just exit
    get_target_property(processed ${NODE} __NODE_PROCESSED)
    if(processed)
        set(${RET} 0 PARENT_SCOPE)
        return()
    endif()

    # Already visited, means there was a cycle detected, flag FATAL_ERROR
    get_target_property(temp ${NODE} __ALREADY_VISITED)
    if(temp)
        socmake_message(FATAL_ERROR "Cycle detected in dependency graph at node: ${NODE}")
    endif()

    # Node is visited, we should not visit the same node again
    set_property(TARGET ${NODE} PROPERTY __ALREADY_VISITED TRUE)

    get_interface_link_libraries(LINK_LIBS ${NODE})

    # Visit each child recursively
    foreach(child ${LINK_LIBS})
        alias_dereference(child ${child})
        __dfs_topo(${child} _child_ret "${EXCLUDED}")
    endforeach()

    # Mark node as processed
    set_property(TARGET ${NODE} PROPERTY __ALREADY_VISITED FALSE)
    set_property(TARGET ${NODE} PROPERTY __NODE_PROCESSED TRUE)

    # Append node to global stack if not already added
    get_property(STACK GLOBAL PROPERTY __GLOBAL_STACK)
    list(FIND STACK ${NODE} ALREADY_ADDED)
    if(ALREADY_ADDED EQUAL -1)
        list(APPEND STACK ${NODE})
        set_property(GLOBAL PROPERTY __GLOBAL_STACK ${STACK})
    endif()

    set(${RET} 1 PARENT_SCOPE)
endfunction()

#[[[
# Function to compare 2 list, will return 1 if they are equal, otherwise, will return -1.
#
# :param L1: 1st list
# :type L1: list
# :param L2: 2nd list
# :type L2: list
# :param RET: returned value for the comparison
# :type RET: integer
#]]
function(compare_lists L1 L2 RET)
    set(l1 ${L1})
    set(l2 ${L2})
    list(LENGTH l1 L1_LEN)
    list(LENGTH l2 L2_LEN)

    if(NOT (L1_LEN EQUAL L2_LEN))
        set(${RET} -1 PARENT_SCOPE)
        return()
    endif()

    list(SORT l1)
    list(SORT l2)

    if(NOT "${l1}" STREQUAL "${l2}")
        set(${RET} -1 PARENT_SCOPE)
        return()
    endif()

    set(${RET} 1 PARENT_SCOPE)
endfunction()
