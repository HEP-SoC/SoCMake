cmake_minimum_required(VERSION 3.30)
project(Example C)

add_library(iface INTERFACE)
set_target_properties(iface PROPERTIES
  TRANSITIVE_LINK_PROPERTIES             "MY_PIERCE_INTERFACE_INC_DIRS"
  INTERFACE_MY_PIERCE_INTERFACE_INC_DIRS "$<TARGET_PROPERTY:iface,INTERFACE_INCLUDE_DIRECTORIES>"
)
target_include_directories(iface INTERFACE iface_inc)

add_library(static1 STATIC static1.c)
target_include_directories(static1 INTERFACE static1_inc)
target_link_libraries(static1 PRIVATE iface)
set_target_properties(static1 PROPERTIES
  INTERFACE_MY_PIERCE_INTERFACE_INC_DIRS "$<TARGET_PROPERTY:static1,INTERFACE_INCLUDE_DIRECTORIES>"
)

add_library(static2 STATIC static2.c)
target_include_directories(static2 INTERFACE static2_inc)
target_link_libraries(static2 PRIVATE iface)
set_target_properties(static2 PROPERTIES
  INTERFACE_MY_PIERCE_INTERFACE_INC_DIRS "$<TARGET_PROPERTY:static2,INTERFACE_INCLUDE_DIRECTORIES>"
)

add_library(static3 STATIC static3.c)
target_include_directories(static3 INTERFACE static3_inc)
target_link_libraries(static3 PRIVATE iface)
target_link_libraries(static3 PRIVATE static2)
set_target_properties(static3 PROPERTIES
  INTERFACE_MY_PIERCE_INTERFACE_INC_DIRS "$<TARGET_PROPERTY:static3,INTERFACE_INCLUDE_DIRECTORIES>"
)

add_library(static4 STATIC static4.c)
target_include_directories(static4 INTERFACE static4_inc)
set_target_properties(static4 PROPERTIES
  INTERFACE_MY_PIERCE_INTERFACE_INC_DIRS "$<TARGET_PROPERTY:static4,INTERFACE_INCLUDE_DIRECTORIES>"
)

add_executable(main main.c)
target_include_directories(main PRIVATE main_inc)
target_link_libraries(main PRIVATE static1 static3 static4)

add_custom_command(TARGET main PRE_BUILD VERBATIM
  COMMAND ${CMAKE_COMMAND} -E echo "m: $<TARGET_PROPERTY:main,MY_PIERCE_INTERFACE_INC_DIRS>")
