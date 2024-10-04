include_guard(GLOBAL)
set(__VCS__CMAKE__CURRENT_LIST_DIR ${CMAKE_CURRENT_LIST_DIR} CACHE INTERNAL "")

macro(vcs_init)
    set(CMAKE_TOOLCHAIN_FILE ${__VCS__CMAKE__CURRENT_LIST_DIR}/vcs_toolchain.cmake)
endmacro()

function(vcs_vlogan IP_LIB)
    cmake_parse_arguments(ARG "" "TOP_MODULE;OUTDIR" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    get_ip_sources(SOURCES ${IP_LIB} SYSTEMVERILOG VERILOG VHDL)

    get_ip_include_directories(INC_DIRS ${IP_LIB} SYSTEMVERILOG VERILOG VHDL)

    foreach(dir ${INC_DIRS})
        list(APPEND ARG_INCDIRS -incdir ${dir})
    endforeach()

    get_ip_compile_definitions(COMP_DEFS ${IP_LIB} SYSTEMVERILOG VERILOG VHDL)
    foreach(def ${COMP_DEFS})
        list(APPEND CMP_DEFS_ARG -D${def})
    endforeach()

    if(ARG_TOP_MODULE)
        set(ARG_TOP_MODULE ${ARG_TOP_MODULE})
    else()
        get_target_property(ARG_TOP_MODULE ${IP_LIB} IP_NAME)
    endif()

    if(ARG_OUTDIR)
        set(OUTDIR ${ARG_OUTDIR})
    else()
        set(OUTDIR ${BINARY_DIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR}/csrc/sysc/include)

    find_program(VLOGAN_EXECUTABLE vlogan REQUIRED
        HINTS ${VCS_HOME} $ENV{VCS_HOME}
        )

    set(STAMP_FILE "${OUTDIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${STAMP_FILE}
        WORKING_DIRECTORY ${OUTDIR}
        COMMAND ${VLOGAN_EXECUTABLE} 
            -full64 -nc -sverilog
            -sc_model ${ARG_TOP_MODULE}
            ${SOURCES}
            ${COMP_DEFS}

        COMMAND touch ${STAMP_FILE}
        DEPENDS ${SOURCES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
        )

    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${STAMP_FILE}
        )

    set(__VCS_LIB ${IP_LIB}__vcs)
    add_library(${__VCS_LIB} OBJECT IMPORTED)
    add_dependencies(${__VCS_LIB} ${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
    target_include_directories(${__VCS_LIB} INTERFACE 
        ${OUTDIR}/csrc/sysc/include)
    #target_link_libraries(${__VCS_LIB} INTERFACE -lpthread)

    string(REPLACE "__" "::" ALIAS_NAME "${__VCS_LIB}")
    add_library(${ALIAS_NAME} ALIAS ${__VCS_LIB})

    # add_dependencies(${IP_LIB}_${CMAKE_CURRENT_FUNCTION} ${IP_LIB})
endfunction()

# syscan -full64 -sysc=scv20 sc_main.cpp

#function(vcs EXEC)
#    cmake_parse_arguments(ARG "" "OUTDIR" "DEPENDS" ${ARGN})
#    if(ARG_UNPARSED_ARGUMENTS)
#        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
#    endif()
#
#    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")
#
#    get_target_property(BINARY_DIR ${EXEC} BINARY_DIR)
#
#    safe_get_target_property(INTERFACE_SOURCES ${EXEC} INTERFACE_SOURCES "")
#    safe_get_target_property(SOURCES ${EXEC} SOURCES "")
#    list(APPEND SOURCES ${INTERFACE_SOURCES})
#    message("SOURCES: ${SOURCES}")
#
#    if(NOT ARG_OUTDIR)
#        set(OUTDIR "${BINARY_DIR}/${EXEC}_vcs")
#    else()
#        set(OUTDIR ${ARG_OUTDIR})
#    endif()
#    file(MAKE_DIRECTORY ${OUTDIR})
#
#    ######################################
#    ##### Get libraries from EXEC ########
#    ######################################
#
#    safe_get_target_property(INTERFACE_LINK_LIBRARIES ${EXEC} INTERFACE_LINK_LIBRARIES "")
#    safe_get_target_property(LINK_LIBRARIES ${EXEC} LINK_LIBRARIES "")
#    list(APPEND LINK_LIBRARIES ${INTERFACE_LINK_LIBRARIES})
#    list(REMOVE_DUPLICATES LINK_LIBRARIES)
#    message("====== LINK_LIBRARIES: ${LINK_LIBRARIES}")
#
#    unset(VCS_LDFLAG_RPATH)
#    unset(VCS_LDFLAGS_LIBS)
#    string(APPEND VCS_LDFLAG_RPATH "-LDFLAGS -Wl,-rpath,")
#    foreach(lib ${LINK_LIBRARIES})
#        if(TARGET ${lib})
#            get_target_property(IMPORTED_LOCATION ${lib} IMPORTED_LOCATION)
#            if(IMPORTED_LOCATION)
#                 set(lib ${IMPORTED_LOCATION})
#                cmake_path(GET lib PARENT_PATH lib_dir)
#                string(APPEND VCS_LDFLAG_RPATH ${lib_dir}:)
#                list(APPEND VCS_LDFLAGS_LIBS -LDFLAGS ${lib})
#            else()
#                get_target_property(BINARY_DIR ${lib} BINARY_DIR)
#                set(lib_dir ${BINARY_DIR})
#                string(APPEND VCS_LDFLAG_RPATH ${lib_dir}:)
#                message("------ ADDING LIB: ${lib}")
#                list(APPEND VCS_LIBS_ARG -LDFLAGS -L${lib_dir} -l${lib})
#            endif()
#        endif()
#    endforeach()
#
#    #   string (REPLACE ";" " " VCS_LDFLAG_RPATH "${VCS_LDFLAG_RPATH}")
#    message("LIBS: ${VCS_LDFLAG_RPATH}")
#
#    ######################################
#    ##### Get Include Directories ########
#    ######################################
#
#    safe_get_target_property(INTERFACE_INCLUDE_DIRECTORIES ${EXEC} INTERFACE_INCLUDE_DIRECTORIES "")
#    safe_get_target_property(INCLUDE_DIRECTORIES ${EXEC} INCLUDE_DIRECTORIES "")
#    message("INCLUDE: ${INCLUDE_DIRECTORIES}, INTF_INC: ${INTERFACE_INCLUDE_DIRECTORIES}")
#    foreach(incdir ${INCLUDE_DIRECTORIES} ${INTERFACE_INCLUDE_DIRECTORIES})
#        list(APPEND _VCS_CFLAGS -CFLAGS -I${incdir})
#    endforeach()
#
#    foreach(lib ${LINK_LIBRARIES})
#        if(TARGET ${lib})
#            safe_get_target_property(intf_inc_dirs ${lib} INTERFACE_INCLUDE_DIRECTORIES "")
#            safe_get_target_property(inc_dirs ${lib} INCLUDE_DIRECTORIES "")
#            message("LIB: ${lib} DIR: ${intf_inc_dirs} inc_dirs: ${inc_dirs}")
#            foreach(incdir ${inc_dirs} ${intf_inc_dirs})
#                list(APPEND _VCS_CFLAGS -CFLAGS -I${incdir})
#            endforeach()
#        endif()
#    endforeach()
#
#
#    set(CMAKE_FIND_DEBUG_MODE TRUE)
#    find_program(_SYSCAN_EXECUTABLE syscan REQUIRED
#        HINTS ${VCS_HOME} $ENV{VCS_HOME}
#        )
#    set(CMAKE_FIND_DEBUG_MODE FALSE)
#
#        set(STAMP_FILE "${OUTDIR}/${EXEC}_syscan.stamp")
#        add_custom_command(
#            OUTPUT ${STAMP_FILE}
#            WORKING_DIRECTORY ${OUTDIR}
#            COMMAND ${_SYSCAN_EXECUTABLE} 
#                -full64 -sysc=scv20
#                ${_VCS_CFLAGS}
#                ${SOURCES}
#    
#            COMMAND touch ${STAMP_FILE}
#            DEPENDS ${SOURCES} ${ARG_DEPENDS}
#            COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${EXEC}"
#            )
#    
#        add_custom_target(
#            ${EXEC}_syscan
#            DEPENDS ${STAMP_FILE}
#            )
#
## vcs -V -full64 -nc -j16 -sverilog -sysc=scv20 sc_main -timescale=1ns/1ps
#
#    find_program(_VCS_EXECUTABLE vcs REQUIRED
#        HINTS ${VCS_HOME} $ENV{VCS_HOME}
#        )
#
#    message("DEPENDS: ${ARG_DEPENDS}")
#    set(STAMP_FILE "${OUTDIR}/${EXEC}_vcs.stamp")
#    add_custom_command(
#        OUTPUT ${STAMP_FILE} ${PROJECT_BINARY_DIR}/${EXEC}
#        WORKING_DIRECTORY ${OUTDIR}
#        COMMAND ${_VCS_EXECUTABLE} 
#            -full64 -nc -sysc=scv20
#            sc_main
#            -timescale=1ns/1ps
#            ${VCS_LDFLAG_RPATH}
#            ${VCS_LDFLAGS_LIBS}
#            ${VCS_LIBS_ARG}
#            -o ${PROJECT_BINARY_DIR}/${EXEC}
#
#        COMMAND touch ${STAMP_FILE}
#        DEPENDS  ${SOURCES} ${EXEC}_syscan ${ARG_DEPENDS} ${LINK_LIBRARIES}
#        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${EXEC}"
#        )
#
#    add_custom_target(
#        ${EXEC}_vcs
#        DEPENDS ${STAMP_FILE}
#        )
#
#    # add_dependencies(${IP_LIB}_${CMAKE_CURRENT_FUNCTION} ${IP_LIB})
#endfunction()
