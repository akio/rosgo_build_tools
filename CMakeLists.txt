cmake_minimum_required(VERSION 2.8.3)
project(rosgo_build_tools)

find_package(catkin REQUIRED)

catkin_package(CFG_EXTRAS rosgo-extras.cmake)

catkin_add_env_hooks(99.rosgo SHELLS sh
                     DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/env-hooks)
