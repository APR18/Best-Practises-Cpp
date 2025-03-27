include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(Best_Practises_C__supports_sanitizers)
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

macro(Best_Practises_C__setup_options)
  option(Best_Practises_C__ENABLE_HARDENING "Enable hardening" ON)
  option(Best_Practises_C__ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    Best_Practises_C__ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    Best_Practises_C__ENABLE_HARDENING
    OFF)

  Best_Practises_C__supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR Best_Practises_C__PACKAGING_MAINTAINER_MODE)
    option(Best_Practises_C__ENABLE_IPO "Enable IPO/LTO" OFF)
    option(Best_Practises_C__WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(Best_Practises_C__ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(Best_Practises_C__ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(Best_Practises_C__ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(Best_Practises_C__ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(Best_Practises_C__ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(Best_Practises_C__ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(Best_Practises_C__ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(Best_Practises_C__ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(Best_Practises_C__ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(Best_Practises_C__ENABLE_PCH "Enable precompiled headers" OFF)
    option(Best_Practises_C__ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(Best_Practises_C__ENABLE_IPO "Enable IPO/LTO" ON)
    option(Best_Practises_C__WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(Best_Practises_C__ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(Best_Practises_C__ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(Best_Practises_C__ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(Best_Practises_C__ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(Best_Practises_C__ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(Best_Practises_C__ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(Best_Practises_C__ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(Best_Practises_C__ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(Best_Practises_C__ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(Best_Practises_C__ENABLE_PCH "Enable precompiled headers" OFF)
    option(Best_Practises_C__ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      Best_Practises_C__ENABLE_IPO
      Best_Practises_C__WARNINGS_AS_ERRORS
      Best_Practises_C__ENABLE_USER_LINKER
      Best_Practises_C__ENABLE_SANITIZER_ADDRESS
      Best_Practises_C__ENABLE_SANITIZER_LEAK
      Best_Practises_C__ENABLE_SANITIZER_UNDEFINED
      Best_Practises_C__ENABLE_SANITIZER_THREAD
      Best_Practises_C__ENABLE_SANITIZER_MEMORY
      Best_Practises_C__ENABLE_UNITY_BUILD
      Best_Practises_C__ENABLE_CLANG_TIDY
      Best_Practises_C__ENABLE_CPPCHECK
      Best_Practises_C__ENABLE_COVERAGE
      Best_Practises_C__ENABLE_PCH
      Best_Practises_C__ENABLE_CACHE)
  endif()

  Best_Practises_C__check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (Best_Practises_C__ENABLE_SANITIZER_ADDRESS OR Best_Practises_C__ENABLE_SANITIZER_THREAD OR Best_Practises_C__ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(Best_Practises_C__BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(Best_Practises_C__global_options)
  if(Best_Practises_C__ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    Best_Practises_C__enable_ipo()
  endif()

  Best_Practises_C__supports_sanitizers()

  if(Best_Practises_C__ENABLE_HARDENING AND Best_Practises_C__ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR Best_Practises_C__ENABLE_SANITIZER_UNDEFINED
       OR Best_Practises_C__ENABLE_SANITIZER_ADDRESS
       OR Best_Practises_C__ENABLE_SANITIZER_THREAD
       OR Best_Practises_C__ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${Best_Practises_C__ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${Best_Practises_C__ENABLE_SANITIZER_UNDEFINED}")
    Best_Practises_C__enable_hardening(Best_Practises_C__options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(Best_Practises_C__local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(Best_Practises_C__warnings INTERFACE)
  add_library(Best_Practises_C__options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  Best_Practises_C__set_project_warnings(
    Best_Practises_C__warnings
    ${Best_Practises_C__WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(Best_Practises_C__ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    Best_Practises_C__configure_linker(Best_Practises_C__options)
  endif()

  include(cmake/Sanitizers.cmake)
  Best_Practises_C__enable_sanitizers(
    Best_Practises_C__options
    ${Best_Practises_C__ENABLE_SANITIZER_ADDRESS}
    ${Best_Practises_C__ENABLE_SANITIZER_LEAK}
    ${Best_Practises_C__ENABLE_SANITIZER_UNDEFINED}
    ${Best_Practises_C__ENABLE_SANITIZER_THREAD}
    ${Best_Practises_C__ENABLE_SANITIZER_MEMORY})

  set_target_properties(Best_Practises_C__options PROPERTIES UNITY_BUILD ${Best_Practises_C__ENABLE_UNITY_BUILD})

  if(Best_Practises_C__ENABLE_PCH)
    target_precompile_headers(
      Best_Practises_C__options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(Best_Practises_C__ENABLE_CACHE)
    include(cmake/Cache.cmake)
    Best_Practises_C__enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(Best_Practises_C__ENABLE_CLANG_TIDY)
    Best_Practises_C__enable_clang_tidy(Best_Practises_C__options ${Best_Practises_C__WARNINGS_AS_ERRORS})
  endif()

  if(Best_Practises_C__ENABLE_CPPCHECK)
    Best_Practises_C__enable_cppcheck(${Best_Practises_C__WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(Best_Practises_C__ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    Best_Practises_C__enable_coverage(Best_Practises_C__options)
  endif()

  if(Best_Practises_C__WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(Best_Practises_C__options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(Best_Practises_C__ENABLE_HARDENING AND NOT Best_Practises_C__ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR Best_Practises_C__ENABLE_SANITIZER_UNDEFINED
       OR Best_Practises_C__ENABLE_SANITIZER_ADDRESS
       OR Best_Practises_C__ENABLE_SANITIZER_THREAD
       OR Best_Practises_C__ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    Best_Practises_C__enable_hardening(Best_Practises_C__options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
