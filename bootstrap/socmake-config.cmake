set(_socmake_version "${SoCMake_FIND_VERSION}")
set(_socmake_git_ref "develop")
set(_socmake_git_url "https://github.com/HEP-SoC/SoCMake.git")

if(_socmake_version)
    # If version is passed in find_package() call, use it as tag v<VERSION> (prepended v)
    set(_socmake_git_ref "v${_socmake_version}")
elseif(DEFINED SoCMake_GIT_TAG)
    # Allow custom variable for tag/branch/commit
    set(_socmake_git_ref "${SoCMake_GIT_TAG}")
endif()

# Git url can be changed with SOCMAKE_GIT_URL variable
if(SOCMAKE_GIT_URL)
    set(_socmake_git_url "${SOCMAKE_GIT_URL}")
endif()

# Don't populate -subbuild to save time during configuration
# This is introduced in 3.30, but this way we dont need to have 3.30 as minimum version to use the new behavior
set(CMAKE_POLICY_DEFAULT_CMP0168 NEW)

include(FetchContent)
FetchContent_Declare(SoCMake
    GIT_REPOSITORY ${_socmake_git_url}
    GIT_TAG ${_socmake_git_ref}
)
FetchContent_MakeAvailable(SoCMake)

set(SoCMake_FOUND TRUE)
set(SoCMake_VERSION ${SoCMake_FIND_VERSION})
# Override the variable that find_package() sets to point to the fetched repo instead of the one in .local/lib/cmake
set(SoCMake_DIR "${SoCMake_SOURCE_DIR}" CACHE STRING "SoCMake package dir" FORCE)
