# vim: ft=cmake :

function(_rosgo_setup_global_variable)
@[if DEVELSPACE]@
    set(libdir "${CATKIN_DEVEL_PREFIX}/lib")
@[else]@
    set(libdir "${CMAKE_INSTALL_PREFIX}/lib")
@[end if]@
    set(root "${libdir}/go")
    file(MAKE_DIRECTORY ${root})
    execute_process(COMMAND go env GOARCH OUTPUT_VARIABLE goarch OUTPUT_STRIP_TRAILING_WHITESPACE)
    execute_process(COMMAND go env GOOS OUTPUT_VARIABLE goos OUTPUT_STRIP_TRAILING_WHITESPACE)
    set_property(GLOBAL PROPERTY _ROSGO_ROOT "${root}")
    set_property(GLOBAL PROPERTY _ROSGO_BIN "${libdir}")
    set_property(GLOBAL PROPERTY _ROSGO_SRC "${root}/src")
    set_property(GLOBAL PROPERTY _ROSGO_PKG "${root}/pkg/${goos}_${goarch}")
    get_property(gopath GLOBAL PROPERTY _ROSGO_PATH)
    if("${gopath}" STREQUAL "")
        set_property(GLOBAL PROPERTY _ROSGO_PATH "${root}")
    endif()
    set_property(GLOBAL APPEND PROPERTY _ROSGO_PATH "${PROJECT_SOURCE_DIR}")
endfunction()

# This will be evaluated per each project that depend `rosgo_build_tools`.
_rosgo_setup_global_variable()


function(_rosgo_get_gopath var)
    get_property(paths GLOBAL PROPERTY _ROSGO_PATH)
    list(APPEND paths ${PROJECT_SOURCE_DIR})
    list(REMOVE_DUPLICATES paths)
    set(gopath "")
    foreach(p ${paths})
        if("${gopath}" STREQUAL "")
            set(gopath "${p}")
        else()
            set(gopath "${p}:${gopath}")
        endif()
    endforeach()
    set("${var}" ${gopath} PARENT_SCOPE)
endfunction()


function(rosgo_add_executable) 
    set(options)
    set(one_value_args)
    set(multi_value_args DEPENDS)
    cmake_parse_arguments(rosgo_add_executable "${options}" "${one_value_args}"
                          "${multi_value_args}" "${ARGN}")
    list(GET rosgo_add_executable_UNPARSED_ARGUMENTS 0 package)
    if("${rosgo_add_executable_TARGET}" STREQUAL "")
        string(REPLACE "/" "_" target "${PROJECT_NAME}_${package}")
        if(NOT ${target} STREQUAL ${PROJECT_NAME}_NOTFOUND)
            set(rosgo_add_executable_TARGET ${target})
        endif()
    endif()
    #message(STATUS "target=${rosgo_add_executable_TARGET}")
    #message(STATUS "exe target=${target}")
    #message(STATUS "exe package=${package}")

    _rosgo_get_gopath(gopath)
    get_property(gobin GLOBAL PROPERTY _ROSGO_BIN)
    #message(STATUS "exe GOPATH=${gopath}")
    get_filename_component(exe_name ${package} NAME)
    set(exe ${gobin}/${PROJECT_NAME}/${exe_name})
    add_custom_target(
        ${rosgo_add_executable_TARGET} ALL
        COMMAND env GOPATH=${gopath} go build -o ${exe} ${package}
        DEPENDS ${rosgo_add_executable_DEPENDS}
    )

    #install(PROGRAMS ${exe} DESTINATION ${CATKIN_GLOBAL_LIB_DESTINATION}/go/bin)
endfunction()


function(rosgo_add_library)
    set(options)
    set(one_value_args TARGET)
    set(multi_value_args DEPENDS)
    cmake_parse_arguments(rosgo_add_library "${options}" "${one_value_args}"
                          "${multi_value_args}" "${ARGN}")
    list(GET rosgo_add_library_UNPARSED_ARGUMENTS 0 package)
    if("${rosgo_add_library_TARGET}" STREQUAL "")
        string(REPLACE "/" "_" target "${PROJECT_NAME}_${package}")
        if(NOT ${target} STREQUAL ${PROJECT_NAME}_NOTFOUND)
            set(rosgo_add_library_TARGET ${target})
        endif()
    endif()
    message(STATUS "target=${rosgo_add_library_TARGET}")
    #message(STATUS "lib target=${target}")
    #message(STATUS "lib package=${package}")
    _rosgo_get_gopath(gopath)
    get_property(gopkg GLOBAL PROPERTY _ROSGO_PKG)
    #message(STATUS "lib GOPATH=${gopath}")
    add_custom_target(
        ${rosgo_add_library_TARGET} ALL
        COMMAND env GOPATH=${gopath} go build -o ${gopkg}/${package} ${package}
        DEPENDS ${rosgo_add_library_DEPENDS}
    )

    #install(
    #    DIRECTORY ${CMAKE_SOURCE_DIR}/src/${package} DESTINATION ${CATKIN_GLOBAL_LIB_DESTINATION}/go/src
    #    PATTERN "*.go"
    #    PATTERN "*_test.go" EXCLUDE 
    #)
endfunction()


function(rosgo_add_test)
    set(options)
    set(one_value_args)
    set(multi_value_args DEPENDS)
    cmake_parse_arguments(rosgo_add_test "${options}" "${one_value_args}"
                          "${multi_value_args}" "${ARGN}")
    list(GET rosgo_add_test_UNPARSED_ARGUMENTS 0 package)
    string(REPLACE "/" "_" target "${package}")

    _rosgo_get_gopath(gopath)
    add_custom_target(
        run_tests_${PROJECT_NAME}_gotest_${target}
        COMMAND env GOPATH=${gopath} go test ${package}
        DEPENDS ${rosgo_add_test_DEPENDS}
    )

    if(NOT TARGET run_tests_${PROJECT_NAME}_gotest)
        add_custom_target(run_tests_${PROJECT_NAME}_gotest)
        add_dependencies(run_tests run_tests_${PROJECT_NAME}_gotest)
    endif()
    add_dependencies(run_tests_${PROJECT_NAME}_gotest
                     run_tests_${PROJECT_NAME}_gotest_${target})
endfunction()


function(rosgo_gopath)
    get_property(_gopath GLOBAL PROPERTY _ROSGO_PATH)
    #message(STATUS "get GOPATH=${_gopath}")
    foreach(p ${ARGV})
        get_filename_component(abspath ${p} ABSOLUTE)
        message(STATUS "append gopath+=${abspath}")
        set_property(GLOBAL APPEND PROPERTY _ROSGO_PATH "${abspath}")
    endforeach()
    #get_property(x GLOBAL PROPERTY _ROSGO_PATH)
    #message(STATUS "append GOPATH=${x}")
endfunction()


