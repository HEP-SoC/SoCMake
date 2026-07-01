cmake_minimum_required(VERSION 3.27)

# This adds the top CMakeLists.txt file to retrieve information
# like the version of SoCMake.
add_subdirectory("../" socmake)

project(SoCMake-Documentation VERSION ${SOCMAKE_VERSION})

# Create the API documentation target
find_python3()
set(DOC_INPUT_DIR "${PROJECT_SOURCE_DIR}/../cmake/")
set(DOC_RST_DIR "${PROJECT_BINARY_DIR}/api_source")
# Markdown output goes into the Docusaurus docs tree so pages are native routes.
set(DOC_MD_DIR "${PROJECT_SOURCE_DIR}/docs/api")
# List of file or directory to be excluded from the recursive search.
# By forcing recursive search in our cminx config file, we are able to search into the full cmake/
# to find all the .cmake, but we don't want to have some .cmake file that doesn't have functions
# or repository without .cmake file having an .rst generated.
# Using the config file with the include_undocumented_XXXX parameter does not solve this problem.
# So if a new file is not available in the api doc, it might be excluded with this list.
set(EXCLUDE_FROM_RST
    -e
    "*Config.cmake"
    -e
    "*firmware"
    -e
    "*flows"
    -e
    "*FindYosys.cmake"
    -e
    "*graphviz*"
    -e
    "*sim_utils.cmake"
)
# cminx converts SoCMake cmake docstrings into RST files.
set(CMINX_CMD
    $ENV{VIRTUAL_ENV}/bin/cminx
    -o
    ${DOC_RST_DIR}
    -s
    ${PROJECT_SOURCE_DIR}/api/api_config.yaml
    ${EXCLUDE_FROM_RST}
    -r
    ${DOC_INPUT_DIR}
)
# rst_to_md.py converts the cminx RST output to Docusaurus-compatible Markdown
# so the API reference is rendered as native Docusaurus pages.
set(RST_TO_MD_CMD
    $ENV{VIRTUAL_ENV}/bin/python3
    ${PROJECT_SOURCE_DIR}/rst_to_md.py
    ${DOC_RST_DIR}
    ${DOC_MD_DIR}
)

set(INDEX_RST_FILE "${DOC_RST_DIR}/index.rst")
# Use the Markdown index as the build output sentinel
set(INDEX_MD_FILE "${DOC_MD_DIR}/hwip.md")

add_custom_command(
    OUTPUT ${INDEX_RST_FILE} ${INDEX_MD_FILE}
    COMMAND touch ${INDEX_RST_FILE}
    COMMAND ${CMINX_CMD}
    COMMAND ${RST_TO_MD_CMD}
    COMMENT "Generating the SoCMake API documentation (RST to Markdown)."
)
# This will trigger the above command through the dependency
add_custom_target(api_doc DEPENDS ${INDEX_RST_FILE})

# Generated files based on cmake configuration/template file (.in files)
# Only @MY_VAR@ format is replaced to avoid replacing structure like ${MY_VAR} which are used in other
# languages or file format (e.g., in Makefiles).
configure_file(
    ${PROJECT_SOURCE_DIR}/api/conf.py.in
    ${PROJECT_BINARY_DIR}/api_source/conf.py
    @ONLY
)
configure_file(
    ${PROJECT_SOURCE_DIR}/api/Makefile.in
    ${PROJECT_BINARY_DIR}/api_source/Makefile
    @ONLY
)

# Now build the docusaurus documentation using npm
find_program(NPM_EXECUTABLE npm)

set(DOCUSAURUS_OUT_DIR ${PROJECT_BINARY_DIR}/docusaurus)
file(MAKE_DIRECTORY ${DOCUSAURUS_OUT_DIR})
set(DOCUSAURUS_STAMP_FILE ${DOCUSAURUS_OUT_DIR}/stamp.stamp)
add_custom_command(
    OUTPUT ${DOCUSAURUS_STAMP_FILE}
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    COMMAND touch ${DOCUSAURUS_STAMP_FILE}
    COMMAND ${NPM_EXECUTABLE} install
    COMMAND
        ${NPM_EXECUTABLE} run build ${PROJECT_SOURCE_DIR} -- --out-dir
        ${DOCUSAURUS_OUT_DIR}
    DEPENDS api_doc
    COMMENT "Installing and Building Docusaurus"
)
add_custom_target(
    docusaurus_doc
    DEPENDS ${DOCUSAURUS_STAMP_FILE}
    COMMENT "Installing and Building Docusaurus"
)

add_custom_target(
    docusaurus_start
    DEPENDS docusaurus_doc
    COMMAND
        ${NPM_EXECUTABLE} run serve ${PROJECT_SOURCE_DIR} -- --dir
        ${DOCUSAURUS_OUT_DIR}
)
