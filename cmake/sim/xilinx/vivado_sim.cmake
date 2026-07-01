#[[[ @module xilinx
#]]

include_guard(GLOBAL)
include("${CMAKE_CURRENT_LIST_DIR}/../../utils/socmake_message.cmake")

#[[[
# Create a target for invoking Vivado (compilation, elaboration, and simulation) on IP_LIB.
#
# It will create a target **run_<IP_LIB>_vivado** that will compile, elaborate, and simulate the IP_LIB design.
#
# :param IP_LIB: The target IP library, it needs to have SOURCES property set with a list of System Verilog or VHDL files.
# :type IP_LIB: string
#
# **Keyword Arguments**
#
# :keyword NO_RUN_TARGET: Do not create a run target.
# :type NO_RUN_TARGET: bool
# :keyword GUI: Run simulation in GUI mode.
# :type GUI: bool
# :keyword RUN_TARGET_NAME: Replace the default name of the run target.
# :type RUN_TARGET_NAME: string
# :keyword TOP_MODULE: Top module name to be used for elaboration and simulation.
# :type TOP_MODULE: string
# :keyword XVLOG_ARGS: Extra arguments to be passed to the SystemVerilog / Verilog compilation step.
# :type XVLOG_ARGS: string
# :keyword XVHDL_ARGS: Extra arguments to be passed to the VHDL compilation step.
# :type XVHDL_ARGS: string
# :keyword XELAB_ARGS: Extra arguments to be passed to the elaboration step.
# :type XELAB_ARGS: string
# :keyword XSIM_ARGS: Extra arguments to be passed to the simulation step.
# :type XSIM_ARGS: string
# :keyword RUN_ARGS: Extra arguments to be passed to the simulation step.
# :type RUN_ARGS: string
# :keyword OUTDIR: Output directory for the simulation build files. If omitted, ``${BINARY_DIR}/${IP_LIB}_vivado_sim`` is used.
# :type OUTDIR: string
# :keyword FILE_SETS: Specify list of File sets to retrieve the sources from
# :type FILE_SETS: list[string]
#]]
function(vivado_sim IP_LIB)
    cmake_parse_arguments(
        ARG
        "NO_RUN_TARGET;GUI"
        "RUN_TARGET_NAME;TOP_MODULE;OUTDIR"
        "XVLOG_ARGS;XVHDL_ARGS;XELAB_ARGS;XSIM_ARGS;RUN_ARGS;FILE_SETS"
        ${ARGN}
    )
    if(ARG_UNPARSED_ARGUMENTS)
        socmake_message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../sim_utils.cmake")

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    get_target_property(LIBRARY ${IP_LIB} LIBRARY)
    if(NOT LIBRARY)
        set(LIBRARY work)
    endif()

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_vivado_sim)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    if(NOT ARG_TOP_MODULE)
        get_target_property(ARG_TOP_MODULE ${IP_LIB} IP_NAME)
    endif()

    if(ARG_XVLOG_ARGS)
        set(ARG_XVLOG_ARGS XVLOG_ARGS ${ARG_XVLOG_ARGS})
    endif()
    if(ARG_XVHDL_ARGS)
        set(ARG_XVHDL_ARGS XVHDL_ARGS ${ARG_XVHDL_ARGS})
    endif()

    if(ARG_FILE_SETS)
        set(ARG_FILE_SETS FILE_SETS ${ARG_FILE_SETS})
    endif()

    get_ip_links(IPS_LIST ${IP_LIB})

    unset(__lib_args)
    unset(__ld_library_paths)
    foreach(ip ${IPS_LIST})
        get_target_property(ip_type ${ip} TYPE)
        if(
            ip_type STREQUAL "SHARED_LIBRARY"
            OR ip_type STREQUAL "STATIC_LIBRARY"
        )
            get_target_property(DPI_LIB_BINDIR ${ip} BINARY_DIR)
            list(
                APPEND __lib_args
                --sv_root
                ${DPI_LIB_BINDIR}
                --sv_lib
                lib$<TARGET_FILE_BASE_NAME:${ip}>
            )
            set(__ld_library_paths "${__ld_library_paths}${DPI_LIB_BINDIR}:")
        endif()
    endforeach()

    __vivado_sim_compile_lib(${IP_LIB}
        OUTDIR ${OUTDIR}
        ${ARG_XVLOG_ARGS}
        ${ARG_XVHDL_ARGS}
        ${ARG_FILE_SETS}
    )
    set(lib_comp_tgt ${IP_LIB}_vivado_sim_complib)

    if(NOT TARGET ${IP_LIB}_vivado_sim)
        get_ip_sources(SOURCES ${IP_LIB} SYSTEMVERILOG VERILOG VHDL ${ARG_FILE_SETS})
        ## Xelab command for elaborating simulation
        set(__xelab_cmd
            COMMAND
            xelab
            ${LIB_SEARCH_DIRS}
            ${ARG_XELAB_ARGS}
            ${__lib_args}
            ${LIBRARY}.${ARG_TOP_MODULE}
            # -work ${OUTDIR}/${LIBRARY}
        )

        ### Clean files:
        #       * xelab.log, xelab.pb
        set(__clean_files
            ${OUTDIR}/xelab.log
            ${OUTDIR}/xelab.pb
            ${OUTDIR}/xsim.dir/${LIBRARY}.${IP_NAME}
        )

        set(DESCRIPTION
            "Compile testbench ${IP_LIB} with ${CMAKE_CURRENT_FUNCTION} xelab"
        )
        set(STAMP_FILE
            "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp"
        )
        add_custom_command(
            # OUTPUT ${SIM_EXEC_PATH} ${STAMP_FILE}
            OUTPUT ${STAMP_FILE}
            COMMAND ${__xelab_cmd}
            COMMAND touch ${STAMP_FILE}
            COMMENT ${DESCRIPTION}
            BYPRODUCTS ${__clean_files}
            WORKING_DIRECTORY ${OUTDIR}
            DEPENDS ${lib_comp_tgt} ${SOURCES}
            COMMAND_EXPAND_LISTS
        )

        add_custom_target(${IP_LIB}_vivado_sim DEPENDS ${STAMP_FILE} ${IP_LIB})
        set_property(
            TARGET ${IP_LIB}_vivado_sim
            PROPERTY DESCRIPTION ${DESCRIPTION}
        )
    endif()

    ### Clean files:
    #       * xelab.log, xelab.pb
    set(__clean_files
        ${OUTDIR}/xsim.log
        ${OUTDIR}/xsim.jou
        ${OUTDIR}/xsim.dir/${LIBRARY}.${IP_NAME}
    )

    ## XSIM command for running simulation
    set(__xsim_cmd
        xsim
        ${ARG_RUN_ARGS}
        ${LIBRARY}.${ARG_TOP_MODULE}
        $<IF:$<BOOL:${ARG_GUI}>,--gui,--R>
    )
    if(NOT ARG_NO_RUN_TARGET)
        if(NOT ARG_RUN_TARGET_NAME)
            set(ARG_RUN_TARGET_NAME run_${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
        endif()
        set(DESCRIPTION
            "Run simulation on ${IP_LIB} with ${CMAKE_CURRENT_FUNCTION}"
        )
        add_custom_target(
            ${ARG_RUN_TARGET_NAME}
            COMMAND
                ${CMAKE_COMMAND} -E env
                "LD_LIBRARY_PATH=$$LD_LIBRARY_PATH:${__ld_library_paths}"
                ${__xsim_cmd}
            WORKING_DIRECTORY ${OUTDIR}
            BYPRODUCTS ${__clean_files}
            COMMENT ${DESCRIPTION}
            DEPENDS ${IP_LIB}_vivado_sim
        )
        set_property(
            TARGET ${ARG_RUN_TARGET_NAME}
            PROPERTY DESCRIPTION ${DESCRIPTION}
        )
    endif()
    set(SOCMAKE_SIM_RUN_CMD ${__xsim_cmd} PARENT_SCOPE)
endfunction()

# This function is called by ``vivado_sim``, it shouldn't be used directly in a cmake file.
#
# It will create an intermediary target to compile VHDL and SystemVerilog/Verilog files, using xvhdl and xvlog.
#
# :param IP_LIB: The target IP library, it needs to have SOURCES property set with a list of System Verilog or VHDL files.
# :type IP_LIB: string
#
# **Keyword Arguments**
#
# :keyword OUTDIR: Output directory.
# :type OUTDIR: string
# :keyword XVLOG_ARGS: Extra arguments to be passed to the SystemVerilog / Verilog compilation step.
# :type XVLOG_ARGS: string
# :keyword XVHDL_ARGS: Extra arguments to be passed to the VHDL compilation step.
# :type XVHDL_ARGS: string
# :keyword FILE_SETS: Specify list of File sets to retrieve the sources from
# :type FILE_SETS: list[string]
function(__vivado_sim_compile_lib IP_LIB)
    cmake_parse_arguments(
        ARG
        ""
        "OUTDIR"
        "XVLOG_ARGS;XVHDL_ARGS;FILE_SETS"
        ${ARGN}
    )
    # Check for any unrecognized arguments
    if(ARG_UNPARSED_ARGUMENTS)
        socmake_message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    # get_target_property(LIBRARY ${IP_LIB} LIBRARY)
    # if(NOT LIBRARY)
    set(LIBRARY work)
    # endif()

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_vivado_sim)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    if(ARG_FILE_SETS)
        set(ARG_FILE_SETS FILE_SETS ${ARG_FILE_SETS})
    endif()

    get_ip_links(__ips ${IP_LIB})
    unset(all_stamp_files)
    unset(lib_search_dirs)
    foreach(lib ${__ips})
        get_target_property(__comp_lib_name ${lib} LIBRARY)
        if(NOT __comp_lib_name)
            set(__comp_lib_name work)
        endif()
        if(ARG_LIBRARY)
            set(__comp_lib_name ${ARG_LIBRARY})
        endif()
        set(lib_outdir ${OUTDIR}/${__comp_lib_name})

        # SystemVerilog and Verilog files and arguments
        get_ip_sources(SV_SOURCES ${lib} SYSTEMVERILOG VERILOG NO_DEPS ${ARG_FILE_SETS})
        unset(__xvlog_cmd)
        unset(SV_ARG_INCDIRS)
        unset(SV_CMP_DEFS_ARG)
        if(SV_SOURCES)
            get_ip_include_directories(SV_INC_DIRS ${lib}  SYSTEMVERILOG VERILOG ${ARG_FILE_SETS})
            get_ip_compile_definitions(SV_COMP_DEFS ${lib} SYSTEMVERILOG VERILOG ${ARG_FILE_SETS})

            foreach(dir ${SV_INC_DIRS})
                list(APPEND SV_ARG_INCDIRS -i ${dir})
            endforeach()

            foreach(def ${SV_COMP_DEFS})
                list(APPEND SV_CMP_DEFS_ARG -d ${def})
            endforeach()

            set(DESCRIPTION
                "Compile Verilog and SV files of ${lib} with vivado xvlog in library ${LIBRARY}"
            )
            set(__xvlog_cmd
                COMMAND
                xvlog
                --sv
                -work
                ${__comp_lib_name}=${lib_outdir}
                ${lib_search_dirs}
                ${ARG_XVLOG_ARGS}
                ${SV_ARG_INCDIRS}
                ${SV_CMP_DEFS_ARG}
                ${SV_SOURCES}
            )
        endif()

        # VHDL files and arguments
        get_ip_sources(VHDL_SOURCES ${lib} VHDL NO_DEPS ${ARG_FILE_SETS})
        unset(__xvhdl_cmd)
        if(VHDL_SOURCES)
            set(__xvhdl_cmd
                COMMAND
                xvhdl
                -work
                ${__comp_lib_name}=${lib_outdir}
                ${lib_search_dirs}
                ${ARG_XVHDL_ARGS}
                ${VHDL_SOURCES}
            )
        endif()

        if(__xvlog_cmd OR __xvhdl_cmd)
            list(APPEND lib_search_dirs -L ${__comp_lib_name}=${lib_outdir})
        endif()

        ### Clean files:
        set(__clean_files
            ${OUTDIR}/xvlog.log
            ${OUTDIR}/xvlog.pb
            ${OUTDIR}/xvhdl.log
            ${OUTDIR}/xvhdl.pb
            ${lib_outdir}/xsim.dir/${LIBRARY}
            ${lib_outdir}/${__comp_lib_name}.rlx
        )
        foreach(source ${VHDL_SOURCES})
            get_filename_component(source_basename ${source} NAME_WLE)
            list(APPEND __clean_files ${lib_outdir}/${source_basename}.vdb)
        endforeach()

        set(DESCRIPTION
            "Compile VHDL, SV, and Verilog files for ${lib} with vivado in library ${LIBRARY}"
        )
        set(STAMP_FILE "${OUTDIR}/${lib}_${CMAKE_CURRENT_FUNCTION}.stamp")
        add_custom_command(
            OUTPUT ${STAMP_FILE} ${__xvlog_cmd} ${__xvhdl_cmd}
            COMMAND touch ${STAMP_FILE}
            WORKING_DIRECTORY ${OUTDIR}
            BYPRODUCTS ${__clean_files}
            DEPENDS ${all_stamp_files} ${SV_SOURCES} ${VHDL_SOURCES}
            COMMENT ${DESCRIPTION}
        )

        list(APPEND all_stamp_files ${STAMP_FILE})
    endforeach()

    if(NOT TARGET ${IP_LIB}_vivado_sim_complib)
        add_custom_target(
            ${IP_LIB}_vivado_sim_complib
            DEPENDS ${all_stamp_files} ${IP_LIB}
        )
        set_property(
            TARGET ${IP_LIB}_vivado_sim_complib
            PROPERTY DESCRIPTION ${DESCRIPTION}
        )
    endif()

    set(LIB_SEARCH_DIRS ${lib_search_dirs} PARENT_SCOPE)
endfunction()

#[[[
# This macro is used to configure the C and CXX compiler to the one used by the tool.
# In this specific case, it won't change anything for the compiler use but will add some useful information to IP_LIB.
#
# The only supported library by this function is DPI-C, it can be used as done in the following example :
#
# .. code-block:: cmake
#
#    vivado_sim_configure_cxx(LIBRARIES DPI-C)
#
# **Keyword Arguments**
#
# :keyword LIBRARIES: Libraries that needs to be added.
# :type LIBRARIES: list[string]
#]]
macro(vivado_sim_configure_cxx)
    cmake_parse_arguments(ARG "" "" "LIBRARIES" ${ARGN})

    # __find_vivado_sim_home(vivado_sim_home)
    # set(CMAKE_CXX_COMPILER "${vivado_sim_home}/tools.lnx86/cdsgcc/gcc/bin/g++")
    # set(CMAKE_C_COMPILER "${vivado_sim_home}/tools.lnx86/cdsgcc/gcc/bin/gcc")

    if(ARG_LIBRARIES)
        vivado_sim_add_cxx_libs(${ARGV})
    endif()
endmacro()

#[[[
# This function is called by the ``vivado_sim_configure_cxx`` macro, you shouldn't use it directly.
#
# It will add the needed information to IP_LIB and add some flags for the compilation and linking.
#
# **Keyword Arguments**
#
# :keyword 32BIT: Use 32 bitness.
# :type 32BIT: bool
# :keyword LIBRARIES: libraries that needs to be added, possible choice are DPI-C only for now.
# :type LIBRARIES: list[string]
#]]
function(vivado_sim_add_cxx_libs)
    cmake_parse_arguments(ARG "32BIT" "" "LIBRARIES" ${ARGN})
    # Check for any unrecognized arguments
    if(ARG_UNPARSED_ARGUMENTS)
        socmake_message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    set(allowed_libraries DPI-C)
    foreach(lib ${ARG_LIBRARIES})
        if(NOT ${lib} IN_LIST allowed_libraries)
            socmake_message(FATAL_ERROR "Vivado does not support library: ${lib}")
        endif()
    endforeach()

    # __find_vivado_sim_home(vivado_sim_home)

    if(DPI-C IN_LIST ARG_LIBRARIES)
        add_library(vivado_sim_dpi-c INTERFACE)
        add_library(SoCMake::DPI-C ALIAS vivado_sim_dpi-c)

        if(ARG_32BIT)
            target_compile_options(vivado_sim_dpi-c INTERFACE -m32)
            target_link_options(vivado_sim_dpi-c INTERFACE -m32)
        endif()
        # target_include_directories(vivado_sim_dpi-c INTERFACE ${vivado_sim_home}/include)
        # target_compile_definitions(vivado_sim_dpi-c INTERFACE INCA)
    endif()
endfunction()
