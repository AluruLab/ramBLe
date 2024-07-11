
string(COMPARE EQUAL "${CODE_ANALYSIS_TYPE}" sanitizer ENABLE_SANITIZER)

if (ENABLE_SANITIZER)
  # set flags for coverage test
  message(STATUS "Sanitizer enabled")
  # probably should be specific based on sanitizer style.  no-omit-frame-pointer is for address.
  set(SANITIZER_COMPILE_FLAGS "-fsanitize=${SANITIZER_STYLE};-fPIE;-fno-omit-frame-pointer;-g")
  #add_definitions(-fsanitize=${SANITIZER_STYLE} -fPIE -fno-omit-frame-pointer -g)
  # and static-libtsan is for thread.

  set(SANITIZER_LINK_FLAGS "-fsanitize=${SANITIZER_STYLE};-fno-omit-frame-pointer;-pie")

  if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    if ("${SANITIZER_STYLE}" MATCHES "thread")
      set(SANITIZER_EXTRA_FLAGS "-static-libtsan")
      set(SANITIZER_LINK_FLAGS "${SANITIZER_LINK_FLAGS};-static-libtsan")
    else()
        set(SANITIZER_EXTRA_FLAGS "")
    endif()
  else()
    set(SANITIZER_EXTRA_FLAGS "")	
  endif()
  

  # set(CMAKE_EXE_LINKER_FLAGS    "${CMAKE_EXE_LINKER_FLAGS}    -fsanitize=${SANITIZER_STYLE} -fno-omit-frame-pointer -pie ${SANITIZER_EXTRA_FLAGS}")
  # set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -fsanitize=${SANITIZER_STYLE} -fno-omit-frame-pointer -pie ${SANITIZER_EXTRA_FLAGS}")
  # set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -fsanitize=${SANITIZER_STYLE} -fno-omit-frame-pointer -pie ${SANITIZER_EXTRA_FLAGS}")
  # set(CMAKE_STATIC_LINKER_FLAGS "${CMAKE_STATIC_LINKER_FLAGS} -fsanitize=${SANITIZER_STYLE} -fno-omit-frame-pointer -pie ${SANITIZER_EXTRA_FLAGS}")

  # NOTE: if using thread sanitizer, please use g++ 4.9 and later, compiled with --disable-linux-futex (for libgomp)
  #  else lots of false positives from OMP will be reported by tsan
else()
  set(SANITIZER_COMPILE_FLAGS "")
  set(SANITIZER_LINK_FLAGS "")
endif()
