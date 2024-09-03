# Options for the virtual env creation
option(UPDATE_PYTHON_DEPS "Force update dependencies" OFF)
option(DEPS_USE_VENV "Create a Python virtual environment and install dependencies locally" ON)
option(UPDATE_DEPS "Update all of the dependencies, CPM packages and Python" OFF)
# This script creates the virtual env if it is not existing
include("${CMAKE_CURRENT_LIST_DIR}/venv.cmake")
