set(socmake_root "${CMAKE_CURRENT_LIST_DIR}/../../../")

function(eda_test SOURCE_DIR TEST_NAME)
    cmake_parse_arguments(ARG "MODELSIM" "TARGET_NAME" "DEFINES" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    if(ARG_TARGET_NAME)
        set(TARGET_NAME ${ARG_TARGET_NAME})
    else()
        set(TARGET_NAME ${TEST_NAME})
    endif()

# Modelsim does not return the status code to the shell, so there is no way of knowing if the simulation was successfull or not without parsing the log
    unset(RESULT_PARSE_CMD)
    if(ARG_MODELSIM)
        set(RESULT_PARSE_CMD  " | tee /dev/stderr | grep -q \"# Errors: 0,\"")
    endif()

    set(source_dir "${PROJECT_SOURCE_DIR}/${SOURCE_DIR}")
    set(build_dir "${PROJECT_BINARY_DIR}/${TEST_NAME}")
    add_test(NAME ${TEST_NAME}
        COMMAND bash -c "\
        ${CMAKE_COMMAND} -S ${source_dir} -B ${build_dir} -DCMAKE_MODULE_PATH=${socmake_root} ${ARG_DEFINES} && \
        ${CMAKE_COMMAND} --build  ${build_dir} -t run_${TARGET_NAME} ${RESULT_PARSE_CMD}"
        COMMAND_EXPAND_LISTS
    )
endfunction()
