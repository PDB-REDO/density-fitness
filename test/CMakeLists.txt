# Makefile for tests

find_or_fetch_package(Catch2 VERSION 3 GIT_REPOSITORY https://github.com/catchorg/Catch2.git GIT_TAG v3.4.0)

add_executable(unit-test-density-fitness
	${PROJECT_SOURCE_DIR}/test/unit-test-density-fitness.cpp
	${PROJECT_SOURCE_DIR}/src/density-fitness.cpp)

target_include_directories(unit-test-density-fitness PRIVATE ${PROJECT_SOURCE_DIR}/src ${PROJECT_BINARY_DIR})

target_link_libraries(unit-test-density-fitness pdb-redo::pdb-redo mcfp::mcfp nlohmann_json::nlohmann_json Catch2::Catch2WithMain)

add_test(NAME unit-test-density-fitness COMMAND $<TARGET_FILE:unit-test-density-fitness> --data-dir ${PROJECT_SOURCE_DIR}/test)

if(USE_RSRC)
	mrc_target_resources(unit-test-density-fitness ${CIFPP_SHARE_DIR}/mmcif_pdbx.dic ${CIFPP_SHARE_DIR}/mmcif_ddl.dic)
endif()
