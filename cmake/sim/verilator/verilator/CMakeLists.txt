cmake_minimum_required(VERSION 3.25)
project(${TARGET})

find_package(verilator HINTS ${VERILATOR_ROOT})
if (NOT verilator_FOUND)
  message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
endif()

foreach(ARG ${ARGUMENTS_LIST})
    string(REPLACE "VERILATE_" "" ARG_MOD ${ARG})
    list(APPEND FORWARDED_ARGS ${ARG_MOD} ${VERILATE_${ARG}})
endforeach()

add_library(${TARGET})
verilate(${TARGET}
    ${FORWARDED_ARGS}
    )

if(VERILATE_SYSTEMC)
    verilator_link_systemc(${TARGET})
endif()

if("--main" IN_LIST VERILATE_VERILATOR_ARGS)
    set(GENERATED_MAIN "${VERILATE_DIRECTORY}/${VERILATE_PREFIX}__main.cpp")
    add_executable(${EXECUTABLE_NAME}
        ${GENERATED_MAIN}
        )
    target_include_directories(${EXECUTABLE_NAME} PRIVATE
        ${VERILATOR_ROOT}/include
        )
    target_link_libraries(${EXECUTABLE_NAME} PRIVATE
        ${TARGET}
        )
endif()
