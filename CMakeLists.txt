cmake_minimum_required(VERSION 2.6.0)
project(palace)
find_package(Alure2 REQUIRED CONFIG)

get_target_property(include_dirs Alure2::alure2 INTERFACE_INCLUDE_DIRECTORIES)
message("alure2_include_dirs=${include_dirs}")

get_target_property(link_libraries Alure2::alure2 INTERFACE_LINK_LIBRARIES)
get_target_property(libalure2 Alure2::alure2 IMPORTED_LOCATION_NOCONFIG)
message("alure2_extra_objects=${link_libraries};${libalure2}")
