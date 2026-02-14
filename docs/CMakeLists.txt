
cmake_minimum_required(VERSION 3.27)

# This adds the top CMakeLists.txt file to retrieve information
# like the version of SoCMake.
add_subdirectory("../" socmake)

project(SoCMake-Documentation
        VERSION ${SOCMAKE_VERSION}
)

# This is needed to create the python venv for CMinx
include("deps/deps.cmake")

# Create the API documentation target
find_python3()
set(DOC_INPUT_DIR "${PROJECT_SOURCE_DIR}/../cmake/")
set(DOC_OUTPUT_DIR "${PROJECT_BINARY_DIR}/api_source")
set(HTML_SPHINX_OUTPUT_DIR "${PROJECT_BINARY_DIR}/api_html")
# Cminx is used to convert SoCMake function comments into rST format later transformed to a
# static html documentation using sphinx
set(VENV_CMD $ENV{VIRTUAL_ENV}/bin/cminx -o ${DOC_OUTPUT_DIR} -r ${DOC_INPUT_DIR})
# This command trigger the rST to html conversion and copy into the docusaurus static folder for
# integration with the latter
set(DOC_API_MAKE_CMD make -C ${PROJECT_BINARY_DIR}/api_source/ html)
# This files tries to create an automatic triggering for the documentation update
set(INDEX_RST_FILE "${DOC_OUTPUT_DIR}/index.rst")
set(INDEX_HTML_FILE "${HTML_SPHINX_OUTPUT_DIR}/html/index.html")

add_custom_command(
        OUTPUT ${INDEX_RST_FILE} ${INDEX_HTML_FILE}
        COMMAND touch ${INDEX_RST_FILE}
        COMMAND ${VENV_CMD}
        COMMAND ${DOC_API_MAKE_CMD}
        COMMENT "Generating the SoCMake API rST documentation."
)
# This will trigger the above command through the dependency
add_custom_target(
        api_doc
        DEPENDS ${INDEX_RST_FILE}
)

# Generated files based on cmake configuration/template file (.in files)
# Only @MY_VAR@ format is replaced to avoid replacing structure like ${MY_VAR} which are used in other
# languages or file format (e.g., in Makefiles).
configure_file(${PROJECT_SOURCE_DIR}/api/conf.py.in ${PROJECT_BINARY_DIR}/api_source/conf.py @ONLY)
configure_file(${PROJECT_SOURCE_DIR}/api/Makefile.in ${PROJECT_BINARY_DIR}/api_source/Makefile @ONLY)

# Now build the docusaurus documentation using npm
find_program(NPM_EXECUTABLE npm)

set(DOCUSAURUS_OUT_DIR  ${PROJECT_BINARY_DIR}/docusaurus)
file(MAKE_DIRECTORY ${DOCUSAURUS_OUT_DIR})
set(DOCUSAURUS_STAMP_FILE ${DOCUSAURUS_OUT_DIR}/stamp.stamp)
add_custom_command(
        OUTPUT ${DOCUSAURUS_STAMP_FILE}
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
        COMMAND touch ${DOCUSAURUS_STAMP_FILE}
        COMMAND ${NPM_EXECUTABLE} install docusaurus
        COMMAND ${NPM_EXECUTABLE} run build ${PROJECT_SOURCE_DIR} -- --out-dir ${DOCUSAURUS_OUT_DIR}
        # API static html is copied and added as a simple link (didn't find a nicer solution yet)
        COMMAND cp -r ${HTML_SPHINX_OUTPUT_DIR}/html ${DOCUSAURUS_OUT_DIR}/api_html
        DEPENDS api_doc
        COMMENT "Installing and Building Docusaurus"
)
add_custom_target(docusaurus_doc
        DEPENDS ${DOCUSAURUS_STAMP_FILE}
        COMMENT "Installing and Building Docusaurus"
)

add_custom_target(docusaurus_start
        DEPENDS docusaurus_doc
        COMMAND ${NPM_EXECUTABLE} run serve ${PROJECT_SOURCE_DIR} -- --dir ${DOCUSAURUS_OUT_DIR}
)
