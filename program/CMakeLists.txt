cmake_minimum_required (VERSION 2.8)

project(copy-file-stats)

set(cfs_sources
    AuxiliaryFunctions.cpp
    FileUtilities.cpp
    ModeUtility.cpp
    SaveRestore.cpp
    main.cpp)

message ( "Info: CMAKE_CXX_COMPILER is set to ${CMAKE_CXX_COMPILER}." )

if (CMAKE_COMPILER_IS_GNUCC)
    add_definitions (-Wall -Wextra -Wpedantic -pedantic-errors -Wshadow -O3 -fexceptions)

    set( CMAKE_EXE_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} -s" )
endif (CMAKE_COMPILER_IS_GNUCC)

add_executable(copy-file-stats ${cfs_sources})
