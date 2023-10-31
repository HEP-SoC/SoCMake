find_path(Yosys_INCLUDE_DIR "kernel/yosys.h" PATH_SUFFIXES include)

# # Allow Yosys_LIBRARY to be set manually
if(NOT Yosys_LIBRARY)
    find_library(Yosys_LIBRARY yosys PATH_SUFFIXES lib)
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Yosys
    REQUIRED_VARS
    Yosys_LIBRARY
        Yosys_INCLUDE_DIR)

if(Yosys_FOUND)
    set(Yosys_INCLUDE_DIRS ${Yosys_INCLUDE_DIR})

    if(NOT Yosys_LIBRARIES)
        set(Yosys_LIBRARIES ${Yosys_LIBRARY})
    endif()

    if(NOT TARGET Yosys::Yosys)
        add_library(Yosys::Yosys UNKNOWN IMPORTED)
        set_target_properties(Yosys::Yosys PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${Yosys_INCLUDE_DIRS}"
            INTERFACE_COMPILE_DEFINITIONS "_YOSYS_"
            IMPORTED_LOCATION "${Yosys_LIBRARY}"
        )
    endif()
endif()

