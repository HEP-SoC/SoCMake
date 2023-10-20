cmake_minimum_required(VERSION 3.25)
project(install)

include(FetchContent)

FetchContent_Declare(
    SoCMake
    GIT_REPOSITORY ssh://git@gitlab.cern.ch:7999/socrates/SoCMake.git
    GIT_TAG master
)

FetchContent_MakeAvailable(SoCMake)
