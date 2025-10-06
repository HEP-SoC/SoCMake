include_guard(GLOBAL)

# ========================================================== #
# ======== Internal graph flattening functions ============= #
# ========================================================== #

function(flatten_graph NODE)
    alias_dereference(NODE ${NODE})

    # __GLOBAL_STACK will hold the flattened graph as the DFS is traversing the tree
    set_property(GLOBAL PROPERTY __GLOBAL_STACK "")
    # __ALREADY_VISITED flag marks that the node was already visited by the DFS search algorithm
    # Since DFS visit every node once for a DAG, if a node is visited twice a cycle was detected
    set_property(TARGET ${NODE} PROPERTY __ALREADY_VISITED FALSE)
    # Once all the children of the node have been visited, mark this node as TRUE to avoid reentering it
    set_property(TARGET ${NODE} PROPERTY __NODE_PROCESSED FALSE)

    # Recursive DFS topological sort
    __dfs_topo(${NODE} unused)

    get_property(STACK GLOBAL PROPERTY __GLOBAL_STACK)

    foreach(lib ${STACK}) # Clear the temporary properties
        alias_dereference(lib ${lib})
        set_property(TARGET ${lib} PROPERTY __ALREADY_VISITED FALSE)
        set_property(TARGET ${lib} PROPERTY __NODE_PROCESSED FALSE)
    endforeach()

    set_property(TARGET ${NODE} PROPERTY FLAT_GRAPH ${STACK})
endfunction()

# ------------------------------------------------------------------ #
# Recursive DFS topological sort
# ------------------------------------------------------------------ #
function(__dfs_topo NODE RET)
    alias_dereference(NODE ${NODE})

    # Skip non-targets (like -pthread, etc.)
    if(NOT TARGET ${NODE})
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
        message(FATAL_ERROR "Cycle detected in dependency graph at node: ${NODE}")
    endif()

    # Node is visited, we should not visit the same node again
    set_property(TARGET ${NODE} PROPERTY __ALREADY_VISITED TRUE)

    get_target_property(LINK_LIBS ${NODE} INTERFACE_LINK_LIBRARIES)
    if(LINK_LIBS)
        # Workaround a mechanism described in (https://cmake.org/cmake/help/v3.30/prop_tgt/INTERFACE_LINK_LIBRARIES.html)
        list(FILTER LINK_LIBS EXCLUDE REGEX "::@")
        list(REMOVE_DUPLICATES LINK_LIBS)
    endif()

    # Visit each child recursively
    foreach(child ${LINK_LIBS})
        alias_dereference(child ${child})
        __dfs_topo(${child} _child_ret)
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

# ------------------------------------------------------------------ #
# Utility: compare lists (unchanged)
# ------------------------------------------------------------------ #
function(compare_lists L1 L2 RET)
    set(_l1 ${L1})
    set(_l2 ${L2})
    list(LENGTH _l1 L1_LEN)
    list(LENGTH _l2 L2_LEN)

    if(NOT (L1_LEN EQUAL L2_LEN))
        set(${RET} -1 PARENT_SCOPE)
        return()
    endif()

    list(SORT _l1)
    list(SORT _l2)

    if(NOT "${_l1}" STREQUAL "${_l2}")
        set(${RET} -1 PARENT_SCOPE)
        return()
    endif()

    set(${RET} 1 PARENT_SCOPE)
endfunction()

