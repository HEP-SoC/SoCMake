include_guard(GLOBAL)

add_library(socgen INTERFACE)
set_property(TARGET socgen PROPERTY RDL_FILES 
    ${CMAKE_CURRENT_LIST_DIR}/socgen_props.rdl
    )
