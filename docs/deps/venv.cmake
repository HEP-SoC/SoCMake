# Python virtual environment creation script
if(DEPS_USE_VENV)
    # Create the python virtual environment if not already done
    if(NOT DEFINED ENV{VIRTUAL_ENV})
        # Set an environment variable as activating a virtual env would do
        set(ENV{VIRTUAL_ENV} "${PYTHON_VENV_BASE_DIR}/.venv")
    endif()
    # The previous coommand tricks find_package() to look for a python interpreter under the
    # VIRUTAL_ENV path. Note that if the venv is deleted, the Python3_EXECUTABLE is still cached so it
    # generates an error (in this case delete the CMakeCache.txt)
    find_package(Python3 COMPONENTS Interpreter)
    # Check if the virtual env path is inside the found python3 executable
    string(FIND "${Python3_EXECUTABLE}" $ENV{VIRTUAL_ENV}/bin/python IN_VENV)
    if(NOT IN_VENV EQUAL 0)
        # If no venv exist, create one
        execute_process (COMMAND "${Python3_EXECUTABLE}" -m venv "${PYTHON_VENV_BASE_DIR}/.venv")
        # The virtual environment is used before any other standard paths to look-up for the interpreter
        set(Python3_FIND_VIRTUALENV FIRST)
        # Remove the python executable to search for the venv one
        unset(Python3_EXECUTABLE)
        # Use fin_package fails if no python3.6 is available so the
        # executable is set manually for now
        # find_package(Python3 COMPONENTS Interpreter)
        set(Python3_EXECUTABLE $ENV{VIRTUAL_ENV}/bin/python)
        # For the update of the deps for a newly created venv
        set(__UPDATE_PYTHON_DEPS TRUE)
    endif()

    # Cache the string for simpler access (this causes the problem above, so maybe it is not the best)
    set(Python3_EXECUTABLE ${Python3_EXECUTABLE} CACHE STRING "Python3_EXECUTABLE")
    # Cache the virtual env path to use package more easily
    set(Python3_VIRTUAL_ENV $ENV{VIRTUAL_ENV} CACHE STRING "Python3_VIRTUAL_ENV")

    # If requested by the user or the script, update the deps
    if((NOT DEFINED UPDATE_PYTHON_DEPS) OR UPDATE_PYTHON_DEPS OR __UPDATE_PYTHON_DEPS OR UPDATE_DEPS OR (NOT DEFINED FIRST_RUN_DONE))
        execute_process(COMMAND ${Python3_EXECUTABLE} -m pip install --upgrade pip)
        # Existing package are ignored by default (first apparence is installed in case of different requirements)
        execute_process(COMMAND ${Python3_EXECUTABLE} -m pip install --exists-action i -r ${CMAKE_CURRENT_LIST_DIR}/requirements.txt)
        # Disable and unset the triggering variables otherwise it will always be executed
        set(UPDATE_PYTHON_DEPS OFF CACHE STRING "Force update python dependencies")
        # Is this really needed?
        unset(__UPDATE_PYTHON_DEPS)
    endif()
else()
    # Use the global python installation
    find_package (Python3 COMPONENTS Interpreter)
endif()
