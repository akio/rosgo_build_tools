# vim: ft=cmake :

function(_rosgo_setup_global_variable)
    set(libdir "${CATKIN_DEVEL_PREFIX}/lib")
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


# Clear old symlinks and create new ones that point original sources.
function(_rosgo_mirror_go_files package var)
    get_filename_component(orig_dir "${PROJECT_SOURCE_DIR}/src/${package}" ABSOLUTE)
    get_filename_component(link_dir "${CATKIN_DEVEL_PREFIX}/lib/go/src/${package}" ABSOLUTE)

    file(MAKE_DIRECTORY "${link_dir}")

    file(GLOB orig_paths "${orig_dir}/*.go")
    set(filenames "")
    foreach(p ${orig_paths})
        get_filename_component(f ${p} NAME)
        list(APPEND filenames "${f}")
    endforeach()

    file(GLOB last_items "${link_dirs}/*.go")
    foreach(item ${last_items})
        if(IS_SYMLINK "${item}")
            file(REMOVE "${item}")
        endif()
    endforeach()

    set(links "")
    foreach(filename ${filenames})
        set(orig "${orig_dir}/${filename}")
        set(link "${link_dir}/${filename}")
        add_custom_command(
            OUTPUT "${link}"
            COMMAND ${CMAKE_COMMAND} -E create_symlink "${orig}" "${link}"
            )
        list(APPEND links "${link}")
    endforeach()
    set(${var} ${links} PARENT_SCOPE)
endfunction()


function(rosgo_add_executable)
    set(options)
    set(one_value_args TARGET)
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

    _rosgo_mirror_go_files(${package} src_links)

    string(REPLACE "/" ";" exe_path "${package}")
    list(GET exe_path -1 exe_name)
    set(exe "${CATKIN_DEVEL_PREFIX}/lib/${PROJECT_NAME}/${exe_name}")

    add_custom_target(
            ${rosgo_add_executable_TARGET} ALL
            COMMAND env GOPATH=$ENV{GOPATH} go build -o ${exe} ${package}
            DEPENDS ${DEPENDS} ${src_links})
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

    _rosgo_mirror_go_files(${package} src_links)
    get_property(gopkg GLOBAL PROPERTY _ROSGO_PKG)

    add_custom_target(
            ${rosgo_add_library_TARGET} ALL
            COMMAND env GOPATH=$ENV{GOPATH} go build -o ${gopkg}/${package}.a ${package}
            DEPENDS ${DEPENDS} ${src_links})
endfunction()


function(rosgo_add_test)
    set(options)
    set(one_value_args)
    set(multi_value_args DEPENDS)
    cmake_parse_arguments(rosgo_add_test "${options}" "${one_value_args}"
                          "${multi_value_args}" "${ARGN}")
    list(GET rosgo_add_test_UNPARSED_ARGUMENTS 0 package)
    string(REPLACE "/" "_" target "${package}")

    _rosgo_mirror_go_files(${package} src_links)

    add_custom_target(
        run_tests_${PROJECT_NAME}_gotest_${target}
        COMMAND env GOPATH=$ENV{GOPATH} go test ${package}
        DEPENDS ${rosgo_add_test_DEPENDS} ${src_links})

    # Register this test to workspace-wide run_tests target
    if(NOT TARGET run_tests_${PROJECT_NAME}_gotest)
        add_custom_target(run_tests_${PROJECT_NAME}_gotest)
        add_dependencies(run_tests run_tests_${PROJECT_NAME}_gotest)
    endif()
    add_dependencies(run_tests_${PROJECT_NAME}_gotest
                     run_tests_${PROJECT_NAME}_gotest_${target})
endfunction()


