###### CODE ANALYSIS FLAGS.  TODO: sanitizer flags for icc?  profiling flags for icc?
# enable_code_analysis - mutually exclusive options
#	enable_profiling - mutually exclusive options
#		enable_vtune_profiling
#   enable_google_profiling
#	enable_coverage
#	enable_sanitizer

set(CODE_ANALYSIS_TYPE "disabled" CACHE STRING "Enable different testing mechanisms. options are disabled, coverage, sanitizer, profiling")
set_property(CACHE CODE_ANALYSIS_TYPE PROPERTY STRINGS disabled profiling coverage sanitizer)

set(SANITIZER_STYLE "address" CACHE STRING "Any Compiler supported Sanitizer style: address, thread, and clang's memory, leak, undefined")
set_property(CACHE SANITIZER_STYLE PROPERTY STRINGS address thread memory leak undefined)
#if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
#  set_property(CACHE SANITIZER_STYLE PROPERTY STRINGS address thread memory leak undefined)
#else (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
#  set_property(CACHE SANITIZER_STYLE PROPERTY STRINGS address thread leak)
#endif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
mark_as_advanced(FORCE SANITIZER_STYLE)


OPTION(ENABLE_VTUNE_PROFILING "Turn on vtune specific profiling flags" OFF)
#OPTION(ENABLE_GOOGLE_PROFILING "Turn on google perftools specific profiling flags" OFF)
mark_as_advanced(FORCE ENABLE_VTUNE_PROFILING)
#mark_as_advanced(FORCE ENABLE_GOOGLE_PROFILING)

function(update_analysis_options varname cacheaccess varval) 

	message(STATUS "changing ${varname} with value ${varval}")

    if (${cacheaccess} STREQUAL READ_ACCESS AND
        ${varname} STREQUAL CODE_ANALYSIS_TYPE)
                    
        if (${varval} STREQUAL "disabled")
          mark_as_advanced(FORCE SANITIZER_STYLE)
          mark_as_advanced(FORCE ENABLE_VTUNE_PROFILING)
          #mark_as_advanced(FORCE ENABLE_GOOGLE_PROFILING)
        elseif (${varval} STREQUAL "profiling")
          mark_as_advanced(FORCE SANITIZER_STYLE)
          mark_as_advanced(CLEAR ENABLE_VTUNE_PROFILING)
          #mark_as_advanced(CLEAR ENABLE_GOOGLE_PROFILING)
        elseif (${varval} STREQUAL "coverage")
          mark_as_advanced(FORCE SANITIZER_STYLE)
          mark_as_advanced(FORCE ENABLE_VTUNE_PROFILING)
          #mark_as_advanced(FORCE ENABLE_GOOGLE_PROFILING)
#	        if (SUPPORTS_COVERAGE)
#		        set(ENABLE_COVERAGE ON CACHE INTERNAL "enabling coverage")
#          else(SUPPORTS_COVERAGE)
#            set(ENABLE_COVERAGE OFF CACHE INTERNAL "enabling coverage")
#	        endif(SUPPORTS_COVERAGE)
        elseif (${varval} STREQUAL "sanitizer")
          mark_as_advanced(CLEAR SANITIZER_STYLE)
          mark_as_advanced(FORCE ENABLE_VTUNE_PROFILING)
          #mark_as_advanced(FORCE ENABLE_GOOGLE_PROFILING)
        else()
          mark_as_advanced(FORCE SANITIZER_STYLE)
          mark_as_advanced(FORCE ENABLE_VTUNE_PROFILING)
          #mark_as_advanced(FORCE ENABLE_GOOGLE_PROFILING)
          message(SEND_ERROR "Unknown code analysis type: ${varval}")
        endif()
                    
    endif(${cacheaccess} STREQUAL READ_ACCESS AND
        ${varname} STREQUAL CODE_ANALYSIS_TYPE)
                
endfunction(update_analysis_options varname cacheaccess varval)
variable_watch(CODE_ANALYSIS_TYPE update_analysis_options)

# NOT SURE WHY, BUT REMOVING THESE CAUSES THE VARIABLES NOT TO BE SET CORRECTLY.
message(STATUS "Code Analysis type = ${CODE_ANALYSIS_TYPE}")

###### SUPPORTING FUNCTIONS.

# code analysis configuration
              
#### COMPILER based Profiling?
string(COMPARE EQUAL "${CODE_ANALYSIS_TYPE}" profiling ENABLE_PROFILING)
if(ENABLE_PROFILING)
  SET(CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -pg -g")
  SET(CMAKE_EXE_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} -pg -g")
else(ENABLE_PROFILING)
  # Remove unreferenced functions: function level linking
  if(NOT APPLE)
    add_definitions(-ffunction-sections)
  endif()
endif(ENABLE_PROFILING)

# vtunes profiling.
if(ENABLE_PROFILING)
  message(STATUS "VTUNE_ANALYSIS set to ${ENABLE_VTUNE_PROFILING}")
  if (ENABLE_VTUNE_PROFILING)
    ADD_LIBRARY(ittnotify STATIC IMPORTED)
    SET_TARGET_PROPERTIES(ittnotify PROPERTIES
        IMPORTED_LOCATION ${VTUNE_LIB})
  endif(ENABLE_VTUNE_PROFILING)

  # vtunes profiling.
  #message(STATUS "GPERFTOOLS_ANALYSIS set to ${ENABLE_GOOGLE_PROFILING}")
  #if (ENABLE_GOOGLE_PROFILING)
  #  ADD_LIBRARY(profiler SHARED IMPORTED)
  #	SET_TARGET_PROPERTIES(profiler PROPERTIES
  #	    IMPORTED_LOCATION /usr/lib/x86_64-linux-gnu)
  #endif(ENABLE_GOOGLE_PROFILING)
endif(ENABLE_PROFILING)


# coverage analysis
string(COMPARE EQUAL "${CODE_ANALYSIS_TYPE}" coverage ENABLE_COVERAGE)
if (ENABLE_COVERAGE)
  # set flags for coverage test
  message(STATUS "Code coverage reporting enabled")
#      add_definitions(-fprofile-arcs -ftest-coverage -g)
  add_definitions(--coverage -g)
#      set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fprofile-arcs -ftest-coverage -g")
#      set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -fprofile-arcs -ftest-coverage -g")
#      set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -fprofile-arcs -ftest-coverage -g")
#      set(CMAKE_STATIC_LINKER_FLAGS "${CMAKE_STATIC_LINKER_FLAGS} -fprofile-arcs -ftest-coverage -g")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --coverage -g")
  set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} --coverage -g")
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} --coverage -g")
  set(CMAKE_STATIC_LINKER_FLAGS "${CMAKE_STATIC_LINKER_FLAGS} --coverage -g")
endif(ENABLE_COVERAGE)

