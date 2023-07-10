set(VERISC_INSTALL_LIST_DIR ${CMAKE_CURRENT_LIST_DIR} CACHE INTERNAL "")

macro(verisc_build)

    set(DEPS "SYSTEMC;UVM-SYSTEMC;VERILATOR;FC4SC;ICSC_COMPILER;GCC")
    foreach(dep ${DEPS})
        list(APPEND OPTIONS NO${dep})
        list(APPEND ONE_PARAM ${dep}_VERSION)
    endforeach()
    list(APPEND ONE_PARAM "CMAKE_CXX_STANDARD;INSTALL_DIR;VERSION")
    set(MULT_PARAM "")
    cmake_parse_arguments(ARG 
        "${OPTIONS}"
        "${ONE_PARAM}"
        "${MULT_PARAM}"
        ${ARGN}
        )
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_MACRO} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    foreach(dep ${DEPS})
        if(ARG_NO${dep})
            set(ARG_${dep}_VERSION FALSE)
        endif()
    endforeach()

    foreach(dep ${DEPS})
        if(DEFINED ARG_${dep}_VERSION)
            list(APPEND VERISC_CFG -D${dep}_VERSION=${ARG_${dep}_VERSION})
        endif()
    endforeach()

    if(NOT ARG_VERSION)
        set(VERSION 0.0.2)
    else()
        set(VERSION ${ARG_VERSION})
    endif()

    if((NOT ARG_INSTALL_DIR))
        if(FETCHCONTENT_BASE_DIR)
            set(INSTALL_DIR ${FETCHCONTENT_BASE_DIR}/verisc)
        endif()
    else()
        set(INSTALL_DIR ${ARG_INSTALL_DIR})
    endif()

    find_package(veriSC CONFIG
        PATHS $ENV{VERISC_HOME} ${VERISC_HOME} ${INSTALL_DIR}
        NO_DEFAULT_PATH
        )

    set(VERISC_HOME "${veriSC_DIR}/../../../")

    if((NOT veriSC_FOUND) OR (NOT veriSC_VERSION VERSION_EQUAL ${VERSION}) OR FORCE_UPDATE)

        set(BOOTSTRAP_DIR "${INSTALL_DIR}/../verisc-build/")
        cmake_host_system_information(RESULT nproc QUERY NUMBER_OF_PHYSICAL_CORES)

        message("UPDATING VERISC TO VERSION ${VERSION}")

        execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${BOOTSTRAP_DIR})
        execute_process(COMMAND ${CMAKE_COMMAND}
            -B ${BOOTSTRAP_DIR}
            -S ${VERISC_INSTALL_LIST_DIR}
                ${VERISC_CFG}
                -DVERISC_VERSION=${VERSION}
                -DVERISC_INSTALL_DIR=${INSTALL_DIR}
                -DVERISC_BUILD_DIR=${BOOTSTRAP_DIR}
                )
        execute_process(COMMAND make -j${nproc} -C ${BOOTSTRAP_DIR} verisc)

        find_package(veriSC ${VERSION} CONFIG REQUIRED
            PATHS ${INSTALL_DIR}
            NO_DEFAULT_PATH
            )
    endif()
endmacro()
