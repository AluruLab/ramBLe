# Include the required headers
include(CheckCXXSourceCompiles)

# Define the source code snippet for SSE detection
set(SSE41_CXX_CODE
    "#include <immintrin.h>
int main() {
#if __SSE4_1__
return 0;
#else
#error \"SSE 4.1 is not supported\"
#endif
}")

set(SSE42_CXX_CODE
    "#include <immintrin.h>
int main() {
#if __SSE4_2__
return 0;
#else
#error \"SSE 4.1 is not supported\"
#endif
}")


# Check for SSE41 support
check_cxx_source_compiles("${SSE41_CXX_CODE}" SSE41_SUPPORTED)
# Check for AVX-512F support
check_cxx_source_compiles("${SSE42_CXX_CODE}" SSE42_SUPPORTED)

#
if(SSE41_SUPPORTED)
    message("SSE 4.1 is supported")
    add_definitions(-msse4.1)
else()
    message("SSE 4.1 is not supported")
endif()

if(SSE42_SUPPORTED)
    message("SSE 4.2 is supported")
    add_definitions(-msse4.1)
else()
    message("SSE 4.2 is not supported")
endif()

