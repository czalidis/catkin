
execute_process(COMMAND date +%F-%0k-%0M-%0S%z
  OUTPUT_VARIABLE DEBIAN_SNAPSHOT_SUFFIX
  OUTPUT_STRIP_TRAILING_WHITESPACE)

if (NOT TARGET debs)
  add_custom_target(debs)
endif()

function(catkin_package PKGNAME)
  
  file(GLOB EMFILES ${CMAKE_CURRENT_SOURCE_DIR}/debian/*.em)
  foreach(file ${EMFILES})
    get_filename_component(basename ${file} NAME_WE)
    assert(catkin_DIR)
    assert_file_exists(${catkin_DIR}/catkin-context.py "while in package ${PKGNAME}")
    log(2 "Expanding ${file} to ${basename}")
        
    safe_execute_process(COMMAND ${EMPY_EXECUTABLE} --raw-errors -F
      ${catkin_DIR}/catkin-context.py -o ${CMAKE_CURRENT_SOURCE_DIR}/debian/${basename} ${file}
      )
    assert_file_exists(${CMAKE_CURRENT_SOURCE_DIR}/debian/${basename} 
      "in package ${PKGNAME}: Should have been generated by empy")
  endforeach()
      
  file(GLOB debfiles RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} debian/*)
  foreach(f ${debfiles})
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/${f}
      ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${f}.stamp
      @ONLY
      )
  endforeach()

  # see http://www.mail-archive.com/cmake@cmake.org/msg03461.html
  add_custom_target(${PKGNAME}-install
    COMMAND ${CMAKE_COMMAND} -DCOMPONENT=${PACKAGE_NAME} -P cmake_install.cmake
    WORKING_DIRECTORY ${${PACKAGE_NAME}_BINARY_DIR}
    COMMENT "making binary deb for package ${PKGNAME}"
    )

  log(1 "${PROJECT_NAME}: Enabling deb target since directory 'debian' exists")
  safe_execute_process(COMMAND /bin/mkdir -p ${CMAKE_BINARY_DIR}/debs)
  add_custom_target(${PROJECT_NAME}-dsc
    COMMAND dpkg-source -b ${CMAKE_CURRENT_SOURCE_DIR}
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/debs
    )
  add_dependencies(debs ${PROJECT_NAME}-deb)

endfunction()
