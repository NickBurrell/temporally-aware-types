include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(temporally_aware_types_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(temporally_aware_types_setup_options)
  option(temporally_aware_types_ENABLE_HARDENING "Enable hardening" ON)
  option(temporally_aware_types_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    temporally_aware_types_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    temporally_aware_types_ENABLE_HARDENING
    OFF)

  temporally_aware_types_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR temporally_aware_types_PACKAGING_MAINTAINER_MODE)
    option(temporally_aware_types_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(temporally_aware_types_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(temporally_aware_types_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(temporally_aware_types_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(temporally_aware_types_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(temporally_aware_types_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(temporally_aware_types_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(temporally_aware_types_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(temporally_aware_types_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(temporally_aware_types_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(temporally_aware_types_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(temporally_aware_types_ENABLE_PCH "Enable precompiled headers" OFF)
    option(temporally_aware_types_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(temporally_aware_types_ENABLE_IPO "Enable IPO/LTO" ON)
    option(temporally_aware_types_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(temporally_aware_types_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(temporally_aware_types_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(temporally_aware_types_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(temporally_aware_types_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(temporally_aware_types_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(temporally_aware_types_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(temporally_aware_types_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(temporally_aware_types_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(temporally_aware_types_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(temporally_aware_types_ENABLE_PCH "Enable precompiled headers" OFF)
    option(temporally_aware_types_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      temporally_aware_types_ENABLE_IPO
      temporally_aware_types_WARNINGS_AS_ERRORS
      temporally_aware_types_ENABLE_USER_LINKER
      temporally_aware_types_ENABLE_SANITIZER_ADDRESS
      temporally_aware_types_ENABLE_SANITIZER_LEAK
      temporally_aware_types_ENABLE_SANITIZER_UNDEFINED
      temporally_aware_types_ENABLE_SANITIZER_THREAD
      temporally_aware_types_ENABLE_SANITIZER_MEMORY
      temporally_aware_types_ENABLE_UNITY_BUILD
      temporally_aware_types_ENABLE_CLANG_TIDY
      temporally_aware_types_ENABLE_CPPCHECK
      temporally_aware_types_ENABLE_COVERAGE
      temporally_aware_types_ENABLE_PCH
      temporally_aware_types_ENABLE_CACHE)
  endif()

  temporally_aware_types_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (temporally_aware_types_ENABLE_SANITIZER_ADDRESS OR temporally_aware_types_ENABLE_SANITIZER_THREAD OR temporally_aware_types_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(temporally_aware_types_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(temporally_aware_types_global_options)
  if(temporally_aware_types_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    temporally_aware_types_enable_ipo()
  endif()

  temporally_aware_types_supports_sanitizers()

  if(temporally_aware_types_ENABLE_HARDENING AND temporally_aware_types_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR temporally_aware_types_ENABLE_SANITIZER_UNDEFINED
       OR temporally_aware_types_ENABLE_SANITIZER_ADDRESS
       OR temporally_aware_types_ENABLE_SANITIZER_THREAD
       OR temporally_aware_types_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${temporally_aware_types_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${temporally_aware_types_ENABLE_SANITIZER_UNDEFINED}")
    temporally_aware_types_enable_hardening(temporally_aware_types_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(temporally_aware_types_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(temporally_aware_types_warnings INTERFACE)
  add_library(temporally_aware_types_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  temporally_aware_types_set_project_warnings(
    temporally_aware_types_warnings
    ${temporally_aware_types_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(temporally_aware_types_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    configure_linker(temporally_aware_types_options)
  endif()

  include(cmake/Sanitizers.cmake)
  temporally_aware_types_enable_sanitizers(
    temporally_aware_types_options
    ${temporally_aware_types_ENABLE_SANITIZER_ADDRESS}
    ${temporally_aware_types_ENABLE_SANITIZER_LEAK}
    ${temporally_aware_types_ENABLE_SANITIZER_UNDEFINED}
    ${temporally_aware_types_ENABLE_SANITIZER_THREAD}
    ${temporally_aware_types_ENABLE_SANITIZER_MEMORY})

  set_target_properties(temporally_aware_types_options PROPERTIES UNITY_BUILD ${temporally_aware_types_ENABLE_UNITY_BUILD})

  if(temporally_aware_types_ENABLE_PCH)
    target_precompile_headers(
      temporally_aware_types_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(temporally_aware_types_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    temporally_aware_types_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(temporally_aware_types_ENABLE_CLANG_TIDY)
    temporally_aware_types_enable_clang_tidy(temporally_aware_types_options ${temporally_aware_types_WARNINGS_AS_ERRORS})
  endif()

  if(temporally_aware_types_ENABLE_CPPCHECK)
    temporally_aware_types_enable_cppcheck(${temporally_aware_types_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(temporally_aware_types_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    temporally_aware_types_enable_coverage(temporally_aware_types_options)
  endif()

  if(temporally_aware_types_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(temporally_aware_types_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(temporally_aware_types_ENABLE_HARDENING AND NOT temporally_aware_types_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR temporally_aware_types_ENABLE_SANITIZER_UNDEFINED
       OR temporally_aware_types_ENABLE_SANITIZER_ADDRESS
       OR temporally_aware_types_ENABLE_SANITIZER_THREAD
       OR temporally_aware_types_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    temporally_aware_types_enable_hardening(temporally_aware_types_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
