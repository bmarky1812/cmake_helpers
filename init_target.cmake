# This file is part of Desktop App Toolkit,
# a set of libraries for developing nice desktop applications.
#
# For license and copyright information please follow this link:
# https://github.com/desktop-app/legal/blob/master/LEGAL

set(MAXIMUM_CXX_STANDARD cxx_std_20)

function(init_target_folder target_name folder_name)
    if (NOT "${folder_name}" STREQUAL "")
        set_target_properties(${target_name} PROPERTIES FOLDER ${folder_name})
    endif()
endfunction()

function(init_target target_name) # init_target(my_target [cxx_std_..] folder_name)
    set(standard ${MAXIMUM_CXX_STANDARD})
    foreach (entry ${ARGN})
        if (${entry} STREQUAL cxx_std_14 OR ${entry} STREQUAL cxx_std_11 OR ${entry} STREQUAL cxx_std_17)
            set(standard ${entry})
        else()
            init_target_folder(${target_name} ${entry})
        endif()
    endforeach()
    target_compile_features(${target_name} PRIVATE ${standard})

    # Taken from Qt 6.
    # For MSVC we need to explicitly pass -Zc:__cplusplus to get correct __cplusplus
    # define values. According to common/msvc-version.conf the flag is supported starting
    # with 1913.
    # https://developercommunity.visualstudio.com/content/problem/139261/msvc-incorrectly-defines-cplusplus.html
    # No support for the flag in upstream CMake as of 3.17.
    # https://gitlab.kitware.com/cmake/cmake/issues/18837
    if (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" AND MSVC_VERSION GREATER_EQUAL 1913)
        target_compile_options(${target_name} PRIVATE "-Zc:__cplusplus")
    endif()

    if (WIN32 AND DESKTOP_APP_SPECIAL_TARGET)
        set_property(TARGET ${target_name} APPEND_STRING PROPERTY STATIC_LIBRARY_OPTIONS "$<IF:$<CONFIG:Debug>,,/LTCG>")
    endif()

    target_link_libraries(${target_name} PRIVATE desktop-app::common_options)
    set_target_properties(${target_name} PROPERTIES
        XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_WEAK YES
        XCODE_ATTRIBUTE_GCC_INLINES_ARE_PRIVATE_EXTERN YES
        XCODE_ATTRIBUTE_GCC_SYMBOLS_PRIVATE_EXTERN YES
        MSVC_RUNTIME_LIBRARY MultiThreaded$<$<CONFIG:Debug>:Debug>
    )
    if (DESKTOP_APP_SPECIAL_TARGET)
        set_target_properties(${target_name} PROPERTIES
            XCODE_ATTRIBUTE_GCC_OPTIMIZATION_LEVEL $<IF:$<CONFIG:Debug>,0,fast>
            XCODE_ATTRIBUTE_LLVM_LTO $<IF:$<CONFIG:Debug>,NO,YES>
        )
    endif()
endfunction()

# This code is not supposed to run on build machine, only on target machine.
function(init_non_host_target target_name)
    init_target(${ARGV})
    if (APPLE)
        set_target_properties(${target_name} PROPERTIES
            OSX_ARCHITECTURES "${DESKTOP_APP_MAC_ARCH}"
        )
    endif()
endfunction()
