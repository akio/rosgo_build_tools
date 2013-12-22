# vim: ft=cmake :
@[if DEVELSPACE]@
set(ROSGO_ROOT "${CATKIN_DEVEL_PREFIX}/go")
@[else]@
set(ROSGO_ROOT "${CMAKE_INSTALL_PREFIX}/go")
@[end if]@


file(MAKE_DIRECTORY ${ROSGO_ROOT})

if($ENV{GOPATH})
    set(ENV{GOPATH} ${ROSGO_ROOT}:$ENV{GOPATH})
else()
    set(ENV{GOPATH} ${ROSGO_ROOT})
endif()

set(ROSGO_SRC ${ROSGO_ROOT}/src)
set(ROSGO_BIN ${ROSGO_ROOT}/bin)
execute_process(COMMAND go env GOARCH OUTPUT_VARIABLE ROSGO_ARCH OUTPUT_STRIP_TRAILING_WHITESPACE)
execute_process(COMMAND go env GOOS OUTPUT_VARIABLE ROSGO_OS OUTPUT_STRIP_TRAILING_WHITESPACE)
set(ROSGO_PKG ${ROSGO_ROOT}/pkg/${ROSGO_OS}_${ROSGO_ARCH})

file(MAKE_DIRECTORY ${ROSGO_SRC})
file(MAKE_DIRECTORY ${ROSGO_BIN})
file(MAKE_DIRECTORY ${ROSGO_PKG})


macro(rosgo_add_executable _package) 
    #set(output ${ROSGO_BIN}/${_package}) 
    set(src_link ${CATKIN_DEVEL_PREFIX}/go/src/${_package})
    add_custom_target(
        ${_package} ALL
        COMMAND ${CMAKE_COMMAND} -E create_symlink ${PROJECT_SOURCE_DIR}/src/${_package} ${src_link}
        COMMAND env GOPATH=$ENV{GOPATH} go install ${_package}
    )
endmacro()


macro(rosgo_add_library _package)
    #set(output ${ROSGO_PKG}/${_package}.a) 
    set(src_link ${CATKIN_DEVEL_PREFIX}/go/src/${_package})
    add_custom_target(
        ${_package} ALL
        COMMAND ${CMAKE_COMMAND} -E create_symlink ${PROJECT_SOURCE_DIR}/src/${_package} ${src_link}
        COMMAND env GOPATH=$ENV{GOPATH} go install ${_package}
    )
endmacro()




# At DEVELSPACE, this macro export PROJECT_SOURCE_DIR to GOPATH
macro(catkin_rosgo_setup)
    #    set(ENV{GOPATH} "${PROJECT_SOURCE_DIR}:$ENV{GOPATH}")
endmacro()
