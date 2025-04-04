include_guard(GLOBAL)

if(NOT TARGET graphviz)
    add_custom_target(graphviz
        COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_LIST_DIR}/graphviz/CMakeGraphVizOptions.cmake ${CMAKE_BINARY_DIR}
        COMMAND ${CMAKE_COMMAND} "--graphviz=graphviz/foo.dot" .
        COMMAND python3 ${CMAKE_CURRENT_LIST_DIR}/graphviz/graphviz_shorten_path.py -f "${CMAKE_BINARY_DIR}/graphviz/foo.dot" -o "${CMAKE_BINARY_DIR}/graphviz/out.dot" -l
        COMMAND dot -Tpng "${CMAKE_BINARY_DIR}/graphviz/out.dot" -o graph.png
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    )
    set_target_properties(graphviz PROPERTIES DESCRIPTION "Generate a build graph with graphviz")
endif()


