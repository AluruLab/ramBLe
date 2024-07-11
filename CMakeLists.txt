cmake_minimum_required(VERSION 3.14)

# project settings
project(ramble C CXX)

set (ramble_VERSION_MAJOR 1)
set (ramble_VERSION_MINOR 0)
set (ramble_VERSION_PATCH 0)
set (ramble_VERSION_TWEAK 0)
set(CMAKE_VERBOSE_MAKEFILE ON)

INCLUDE(CMakeDependentOption)

# Requires at least C++14
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Initialize CXXFLAGS.
set(BASE_OPT_FLAGS "-ffast-math -funroll-loops")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wuninitialized -Wextra -fPIC")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -O0")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} ${BASE_OPT_FLAGS}")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO} ${BASE_OPT_FLAGS}")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wuninitialized -Wextra -fPIC")
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -O0")
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} ${BASE_OPT_FLAGS}")
set(CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO} ${BASE_OPT_FLAGS}")

# Specify build type
IF(NOT CMAKE_BUILD_TYPE)
  SET(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING
      "Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel."
      FORCE)
ENDIF(NOT CMAKE_BUILD_TYPE)

# External directories
set(EXT_PROJECTS_DIR ${PROJECT_SOURCE_DIR}/ext)
set(CMAKE_MODULE_DIR ${PROJECT_SOURCE_DIR}/ext/cmake-utils)

include("${CMAKE_MODULE_DIR}/ExtraWarnings.cmake")
include("${CMAKE_MODULE_DIR}/CompilerProfiling.cmake")
# include("${CMAKE_MODULE_DIR}/OpenMP.cmake")
include("${CMAKE_MODULE_DIR}/MPI.cmake")
include("${CMAKE_MODULE_DIR}/SIMD.cmake")
include("${CMAKE_MODULE_DIR}/Boost.cmake")
# include("${CMAKE_MODULE_DIR}/HDF5.cmake")
# include("${CMAKE_MODULE_DIR}/CodeAnalysis.cmake")
include("${CMAKE_MODULE_DIR}/Sanitizer.cmake")

# Check if the user want to build applications
OPTION(BUILD_APPLICATIONS "whether applications should be built" ON)
OPTION(BUILD_TESTS "whether tests should be built" OFF)

# library usage.
OPTION(USE_ZLIB "whether mcpnet should use ZLIB" OFF)

###### Executable and Libraries
# Save libs and executables in the same place
set(LIBRARY_OUTPUT_PATH ${CMAKE_BINARY_DIR}/lib CACHE PATH "Output directory for libraries" )
set(EXECUTABLE_OUTPUT_PATH ${CMAKE_BINARY_DIR}/bin CACHE PATH "Output directory for applications" )


# add the binary tree to the search path for include files
include_directories("${PROJECT_SOURCE_DIR}/include")
include_directories("${EXT_PROJECTS_DIR}")
include_directories("${EXT_PROJECTS_DIR}/mxx/include")
include_directories("${EXT_PROJECTS_DIR}/mxx/ext/")

if (BUILD_APPLICATIONS)
    set(RAMBLE_APP ramble)
    set(app_compile_defs "-DVERBOSE")
    set(app_compile_flags "")
    set(app_link_flags "")
    set(app_link_libs "m" Boost::system Boost::program_options Boost::filesystem)

    if (CMAKE_CXX_COMPILER_ID STREQUAL "Intel")
        set(app_compile_defs "${app_compile_defs};-DHAVE_INTEL_ICC")
        if (PRINT_VEC_REPORT)
            set(app_compile_flags "${app_compile_flags};-qopt-report=5;-qopt-report-phase=vec;-qopt-report-file=stdout")
        endif(PRINT_VEC_REPORT)
    
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        if (PRINT_VEC_REPORT)
            set(app_compile_flags "${app_compile_flags};-ftree-vectorizer-verbose=4")
        endif(PRINT_VEC_REPORT)
    endif()

    add_executable(${RAMBLE_APP} src/ramble.cpp src/ProgramOptions.cpp)
    foreach (cdef IN LISTS app_compile_defs)
        target_compile_definitions(${RAMBLE_APP} PRIVATE ${cdef})
    endforeach(cdef)
    foreach (cflgs IN LISTS app_compile_flags)
        target_compile_options(${RAMBLE_APP} PRIVATE ${cflgs})
    endforeach(cflgs)
    target_link_libraries(${RAMBLE_APP} ${app_link_flags} ${app_link_libs} ${EXTRA_LIBS})

    if (USE_MPI)
        target_compile_definitions(${RAMBLE_APP} PRIVATE -DUSE_MPI)
        # MPI_LIBRARIES already in EXTRA_LIBS
    endif(USE_MPI)
endif()

if (BUILD_TESTS)
   include("${CMAKE_MODULE_DIR}/GTest.cmake")
endif()



