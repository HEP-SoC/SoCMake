include_guard(GLOBAL)

function(fc4sc_merge_coverage DIRECTORY)
    cmake_parse_arguments(ARG "" "OUTFILE;FC4SC_HOME;VERISC_HOME" "DEPENDS" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/find_python.cmake")

    if(NOT ARG_OUTFILE)
        set(OUTFILE ${CMAKE_CURRENT_BINARY_DIR}/coverage_merged_db.xml)
    else()
        set(OUTFILE ${ARG_OUTFILE})
    endif()

    if(ARG_VERISC_HOME AND ARG_FC4SC_HOME)
        message(FATAL_ERROR "Specify only one of VERISC_HOME, FC4SC_HOME")
    endif()
    
    if(ARG_VERISC_HOME)
        set(SEARCH_HINT "${ARG_VERISC_HOME}/*/*")
    elseif(VERISC_HOME)
        set(SEARCH_HINT "${VERISC_HOME}/*/*")
    endif()
    if(ARG_FC4SC_HOME)
        set(SEARCH_HINT "${ARG_FC4SC_HOME}/")
    elseif(FC4SC_HOME)
        set(SEARCH_HINT "${FC4SC_HOME}/")
    endif()
    find_file(FC4SC_MERGE_COVERAGE merge.py
        HINTS ${SEARCH_HINT}
        PATH_SUFFIXES tools/coverage_merge)

    find_file(FC4SC_GUI index.html 
        HINTS ${SEARCH_HINT}
        PATH_SUFFIXES tools/gui)

    find_python3()

    set(_GEN_XML_FILE "${DIRECTORY}/coverage_merged_db.xml")
    add_custom_target(${CMAKE_CURRENT_FUNCTION}
        COMMAND ${Python3_EXECUTABLE} ${FC4SC_MERGE_COVERAGE}
        COMMAND ${CMAKE_COMMAND} -E rename ${_GEN_XML_FILE} ${OUTFILE}
        WORKING_DIRECTORY ${DIRECTORY}
        BYPRODUCTS ${OUTFILE}
        DEPENDS ${ARG_DEPENDS}
        COMMENT "Merging coverage with fc4sc from ${DIRECTORY} to ${OUTFILE}"
        )

    add_custom_target(fc4sc_gui
        COMMAND xdg-open ${FC4SC_GUI}
        DEPENDS ${OUTFILE}
        COMMENT "Opening FC4SC gui in a browser"
        )

endfunction()

