cmake_minimum_required(VERSION 3.8)
project(__PKG_NAME__)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)

add_executable(__NODE_NAME__ src/__NODE_NAME__.cpp)
target_include_directories(__NODE_NAME__ PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>)
target_compile_features(__NODE_NAME__ PUBLIC c_std_99 cxx_std_17)
ament_target_dependencies(__NODE_NAME__ rclcpp std_msgs)

install(TARGETS __NODE_NAME__
  DESTINATION lib/${PROJECT_NAME})

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  # Comment the line when a copyright and license is not present in all source files
  set(ament_cmake_copyright_FOUND TRUE)
  # Comment the line when this package is in a git repo and when
  # a copyright and license is added to all source files
  set(ament_cmake_cpplint_FOUND TRUE)
  ament_lint_auto_find_test_dependencies()
endif()

ament_package()
