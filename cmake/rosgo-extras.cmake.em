# vim: ft=cmake :
@[if DEVELSPACE]@
set(ROSGO_ROOT "${CATKIN_DEVEL_PREFIX}/lib/go")
@[else]@
set(ROSGO_ROOT "${CMAKE_INSTALL_PREFIX}/lib/go")
@[end if]@
file(MAKE_DIRECTORY ${ROSGO_ROOT})

set(ROSGO_BIN ${ROSGO_ROOT}/bin)
set(ROSGO_SRC ${ROSGO_ROOT}/src)
execute_process(COMMAND go env GOARCH OUTPUT_VARIABLE ROSGO_ARCH OUTPUT_STRIP_TRAILING_WHITESPACE)
execute_process(COMMAND go env GOOS OUTPUT_VARIABLE ROSGO_OS OUTPUT_STRIP_TRAILING_WHITESPACE)
set(ROSGO_PKG ${ROSGO_ROOT}/pkg/${ROSGO_OS}_${ROSGO_ARCH})

set(ROSGO_PATH "${ROSGO_ROOT}" PARENT_SCOPE)


function(rosgo_add_executable) 
@[if DEVELSPACE]@
    set(ROSGO_ROOT "${CATKIN_DEVEL_PREFIX}/lib/go")
@[else]@
    set(ROSGO_ROOT "${CMAKE_INSTALL_PREFIX}/lib/go")
@[end if]@
    file(MAKE_DIRECTORY ${ROSGO_ROOT})
    
    set(ROSGO_BIN ${ROSGO_ROOT}/bin)
    set(ROSGO_SRC ${ROSGO_ROOT}/src)
    execute_process(COMMAND go env GOARCH OUTPUT_VARIABLE ROSGO_ARCH OUTPUT_STRIP_TRAILING_WHITESPACE)
    execute_process(COMMAND go env GOOS OUTPUT_VARIABLE ROSGO_OS OUTPUT_STRIP_TRAILING_WHITESPACE)
    set(ROSGO_PKG ${ROSGO_ROOT}/pkg/${ROSGO_OS}_${ROSGO_ARCH})

    set(options)
    set(one_value_args)
    set(multi_value_args DEPENDS)
    cmake_parse_arguments(rosgo_add_executable "${options}" "${one_value_args}"
                          "${multi_value_args}" "${ARGN}")
    list(GET rosgo_add_executable_UNPARSED_ARGUMENTS 0 target)
    list(GET rosgo_add_executable_UNPARSED_ARGUMENTS 1 package)
    message(STATUS "exe target=${target}")
    message(STATUS "exe package=${package}")

    message(STATUS "exe GOPATH=${ROSGO_PATH}")
    get_filename_component(exe_name ${package} NAME)
    set(exe ${ROSGO_BIN}/${exe_name})
    add_custom_target(
        ${target} ALL
        COMMAND env GOPATH=${ROSGO_PATH} go build -o ${exe} ${package}
        DEPENDS ${rosgo_add_executable_DEPENDS}
    )
    #install(PROGRAMS ${exe} DESTINATION ${CATKIN_GLOBAL_LIB_DESTINATION}/go/bin)
endfunction()


function(rosgo_add_library)
@[if DEVELSPACE]@
    set(ROSGO_ROOT "${CATKIN_DEVEL_PREFIX}/lib/go")
@[else]@
    set(ROSGO_ROOT "${CMAKE_INSTALL_PREFIX}/lib/go")
@[end if]@
    file(MAKE_DIRECTORY ${ROSGO_ROOT})
    
    set(ROSGO_BIN ${ROSGO_ROOT}/bin)
    set(ROSGO_SRC ${ROSGO_ROOT}/src)
    execute_process(COMMAND go env GOARCH OUTPUT_VARIABLE ROSGO_ARCH OUTPUT_STRIP_TRAILING_WHITESPACE)
    execute_process(COMMAND go env GOOS OUTPUT_VARIABLE ROSGO_OS OUTPUT_STRIP_TRAILING_WHITESPACE)
    set(ROSGO_PKG ${ROSGO_ROOT}/pkg/${ROSGO_OS}_${ROSGO_ARCH})

    set(options)
    set(one_value_args)
    set(multi_value_args DEPENDS)
    cmake_parse_arguments(rosgo_add_library "${options}" "${one_value_args}"
                          "${multi_value_args}" "${ARGN}")
    list(GET rosgo_add_library_UNPARSED_ARGUMENTS 0 target)
    list(GET rosgo_add_library_UNPARSED_ARGUMENTS 1 package)
    message(STATUS "lib target=${target}")
    message(STATUS "lib package=${package}")
    message(STATUS "lib GOPATH=${ROSGO_PATH}")
    add_custom_target(
        ${target} ALL
        COMMAND env GOPATH=${ROSGO_PATH} go build -o ${ROSGO_PKG}/${package} ${package}
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

    add_custom_target(
        run_${PROJECT_NAME}_${target}_tests
        COMMAND env GOPATH=${ROSGO_PATH} go test ${package}
        DEPENDS ${rosgo_add_test_DEPENDS}
    )
    add_dependencies(run_tests run_${PROJECT_NAME}_${package}_tests)
endfunction()


# At DEVELSPACE, this macro export PROJECT_SOURCE_DIR to GOPATH
# Each package that cotains go library must invoke this macro
macro(rosgo_setup)
    set(ROSGO_PATH "${PROJECT_SOURCE_DIR}:${ROSGO_PATH}")
    set(ROSGO_PATH "${ROSGO_PATH}" PARENT_SCOPE)
    message(STATUS "set GOPATH=${ROSGO_PATH}")
endmacro()
