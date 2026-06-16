#[[[ @module fc4sc
#]]

include_guard(GLOBAL)
include("${CMAKE_CURRENT_LIST_DIR}/../../utils/socmake_message.cmake")

#[[[
# This function use fc4sc to merge already existing coverages files in the ``DIRECTORY`` directory (function's argument).
#
# :param DIRECTORY: Directory containing coverage informations 
# :type DIRECTORY: path string
#
# **Keyword Arguments**
#
# :keyword OUTFILE: specify a path to an outfile and it name, by default it's set to ${CMAKE_CURRENT_BINARY_DIR}/coverage_merged_db.xml
# :type OUTFILE: string
# :keyword FC4SC_HOME: Path to the home directory of fc4sc
# :type FC4SC_HOME: path string
# :keyword DEPENDS: can be used if any dependencies need to be given for the coverage merging
# :type DEPENDS: string
#]]
function(fc4sc_merge_coverage DIRECTORY)
    cmake_parse_arguments(ARG "" "OUTFILE;FC4SC_HOME" "DEPENDS" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        socmake_message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/find_python.cmake")

    if(NOT ARG_OUTFILE)
        set(OUTFILE ${CMAKE_CURRENT_BINARY_DIR}/coverage_merged_db.xml)
    else()
        set(OUTFILE ${ARG_OUTFILE})
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

