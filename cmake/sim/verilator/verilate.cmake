function(verilate TARGET LIB)
    set(OPTIONS "COVERAGE;TRACE;TRACE_FST;SYSTEMC;TRACE_STRUCTS;EXCLUDE_FROM_ALL")
    set(ONE_PARAM_ARGS "PREFIX;TOP_MODULE;THREADS;TRACE_THREADS;DIRECTORY")
    set(MULTI_PARAM_ARGS "VERILATOR_ARGS;OPT_SLOW;OPT_FAST;OPT_GLOBAL")

    cmake_parse_arguments(VERILATE "${OPTIONS}"
        "${ONE_PARAM_ARGS}"
        "${MULTI_PARAM_ARGS}"
        ${ARGN})

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../rtllib.cmake")

    get_target_property(BINARY_DIR ${LIB} BINARY_DIR)

    get_rtl_target_property(INTERFACE_INCLUDE_DIRECTORIES ${LIB} INTERFACE_INCLUDE_DIRECTORIES)
    get_rtl_target_property(INCLUDE_DIRECTORIES ${LIB} INCLUDE_DIRECTORIES)
    if(INTERFACE_INCLUDE_DIRECTORIES)
        set(INCLUDE_DIRS_ARG INCLUDE_DIRS ${INTERFACE_INCLUDE_DIRECTORIES} ${INCLUDE_DIRECTORIES})
    endif()

    if(VERILATE_TOP_MODULE)
        set(TOP_MODULE_ARG TOP_MODULE ${VERILATE_TOP_MODULE})
    endif()

    if(VERILATE_EXCLUDE_FROM_ALL)
        set(VERILATE_EXCLUDE_FROM_ALL "EXCLUDE_FROM_ALL")
    else()
        set(VERILATE_EXCLUDE_FROM_ALL "")
    endif()

    get_rtl_target_property(LIB_VERILATOR_ARGS ${LIB} VERILATOR_ARGS)
    if(NOT TARGET ${TARGET})
        set(VERILATOR_ARGS VERILATOR_ARGS --main --timing ${VERILATE_VERILATOR_ARGS} ${LIB_VERILATOR_ARGS})
    else()
        set(VERILATOR_ARGS VERILATOR_ARGS ${VERILATE_VERILATOR_ARGS} ${LIB_VERILATOR_ARGS})
    endif()

    get_rtl_target_sources(V_FILES ${LIB} SOURCES)
    list(REMOVE_DUPLICATES V_FILES)

    _verilate(${TARGET} ${VERILATE_EXCLUDE_FROM_ALL}
        SOURCES ${V_FILES}
        ${VERILATOR_ARGS}

        ${ARGN}
        ${INCLUDE_DIRS_ARG}
        
        )

    add_dependencies(${TARGET}_vlt ${LIB})

endfunction()

function(_verilate TARGET)
    set(OPTIONS "COVERAGE;TRACE;TRACE_FST;SYSTEMC;TRACE_STRUCTS;EXCLUDE_FROM_ALL")
    set(ONE_PARAM_ARGS "PREFIX;TOP_MODULE;THREADS;TRACE_THREADS;DIRECTORY")
    set(MULTI_PARAM_ARGS "SOURCES;VERILATOR_ARGS;INCLUDE_DIRS;OPT_SLOW;OPT_FAST;OPT_GLOBAL")
    cmake_parse_arguments(VERILATE "${OPTIONS}"
        "${ONE_PARAM_ARGS}"
        "${MULTI_PARAM_ARGS}"
        ${ARGN})


    if (NOT VERILATE_SOURCES)
        message(FATAL_ERROR "Need at least one source")
    endif()

    if(NOT VERILATE_TOP_MODULE)
        list(GET VERILATE_SOURCES 0 FIRST_SOURCE)
        get_filename_component(TOP_MODULE ${FIRST_SOURCE} NAME_WE)
    else()
        set(TOP_MODULE ${VERILATE_TOP_MODULE})
    endif()

    if(VERILATE_EXCLUDE_FROM_ALL)
        set(VERILATE_EXCLUDE_FROM_ALL "EXCLUDE_FROM_ALL")
    else()
        set(VERILATE_EXCLUDE_FROM_ALL "")
    endif()

    set(MAIN_FN "V${TOP_MODULE}__main.cpp")
    if(VERILATE_PREFIX)
        set(TOP_MODULE ${VERILATE_PREFIX})
        set(MAIN_FN "${TOP_MODULE}__main.cpp")
    else()
        if(VERILATE_TOP_MODULE)
            set(VERILATE_PREFIX "V${VERILATE_TOP_MODULE}")
        endif()
    endif()

    if(NOT VERILATE_DIRECTORY)
        set(VERILATE_DIRECTORY "${PROJECT_BINARY_DIR}/${TARGET}_vlt/verilate")
    endif()

    list(FIND VERILATE_VERILATOR_ARGS --main GENERATE_MAIN)

    if(GENERATE_MAIN GREATER -1)
        set(MAIN "${VERILATE_DIRECTORY}/${MAIN_FN}")
        set_source_files_properties(${MAIN} PROPERTIES GENERATED TRUE)

        if(NOT TARGET ${TARGET})
            file(WRITE "${PROJECT_BINARY_DIR}/__null.cpp" "")
            add_executable(${TARGET} ${VERILATE_EXCLUDE_FROM_ALL}
                "${PROJECT_BINARY_DIR}/__null.cpp"
                )
        endif()

        target_sources(${TARGET} PUBLIC
            ${MAIN}
            )
    endif()

    foreach(param ${MULTI_PARAM_ARGS})
        string(REPLACE ";" "|" VERILATE_${param} "${VERILATE_${param}}")
    endforeach()

    foreach(param ${OPTIONS} ${ONE_PARAM_ARGS} ${MULTI_PARAM_ARGS})
        if(VERILATE_${param})
            list(APPEND EXT_PRJ_ARGS "-DVERILATE_${param}=${VERILATE_${param}}")
            list(APPEND ARGUMENTS_LIST ${param})
        endif()
    endforeach()
    string(REPLACE ";" "|" ARGUMENTS_LIST "${ARGUMENTS_LIST}")

    if(CMAKE_CXX_STANDARD)
        set(ARG_CMAKE_CXX_STANDARD "-DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}")
    endif()


    if(VERISC_HOME)
        set(VERILATOR_HOME "${VERISC_HOME}/open/verilator-${VERILATOR_VERSION}")
    else()
        find_package(verilator REQUIRED)
        set(VERILATOR_HOME "${verilator_DIR}/../../")
    endif()

      include(ExternalProject)
      ExternalProject_Add(${TARGET}_vlt
          DOWNLOAD_COMMAND ""
          SOURCE_DIR "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/verilator"
          PREFIX ${PROJECT_BINARY_DIR}/${TARGET}_vlt
          BINARY_DIR ${PROJECT_BINARY_DIR}/${TARGET}_vlt
          LIST_SEPARATOR |
          BUILD_ALWAYS 1

          CMAKE_ARGS
              ${ARG_CMAKE_CXX_STANDARD}
              -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
              -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
              -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}

              -DTARGET=${TARGET}
              -DARGUMENTS_LIST=${ARGUMENTS_LIST}
              ${EXT_PRJ_ARGS}
              -DVERILATOR_ROOT=${VERILATOR_HOME}

          INSTALL_COMMAND ""
          DEPENDS ${RTL_LIB}
          EXCLUDE_FROM_ALL 1
          ) 

    set(VLT_STATIC_LIB "${PROJECT_BINARY_DIR}/${TARGET}_vlt/lib${TARGET}.a")
    set(INC_DIR ${VERILATE_DIRECTORY})
    
    add_library(tmp_${TOP_MODULE} STATIC IMPORTED)
    add_dependencies(${TARGET} tmp_${TOP_MODULE} ${TARGET}_vlt)
    set_target_properties(tmp_${TOP_MODULE} PROPERTIES IMPORTED_LOCATION ${VLT_STATIC_LIB})
    
    target_include_directories(${TARGET} PUBLIC ${INC_DIR})
    target_include_directories(${TARGET} PUBLIC 
        "${VERILATOR_HOME}/include"
        "${VERILATOR_HOME}/include/vltstd")

    set(THREADS_PREFER_PTHREAD_FLAG ON)
    find_package(Threads REQUIRED)

    target_link_libraries(${TARGET} tmp_${TOP_MODULE} -pthread)
endfunction()
