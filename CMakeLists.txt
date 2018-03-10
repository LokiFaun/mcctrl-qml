cmake_minimum_required(VERSION 3.8)

# Find includes in corresponding build directories
set(CMAKE_INCLUDE_CURRENT_DIR ON)

################################################################################
# Mosquitto Mqtt library
################################################################################
set(WITH_SRV OFF)
set(WITH_TLS OFF)
set(WITH_THREADING OFF)
add_subdirectory(mosquitto)
set_target_properties(libmosquitto PROPERTIES COMPILE_FLAGS "-W0")

################################################################################
# Qt
################################################################################
# Instruct CMake to run moc automatically when needed.
set(CMAKE_AUTOMOC ON)

# Find the Qt libraries
if (WIN32)
set (CMAKE_PREFIX_PATH "C:/Qt/5.10.1/msvc2017_64")
endif()
find_package(Qt5 COMPONENTS Core Quick QuickControls2 REQUIRED)
#find_package(Qt5QuickCompiler)

if(Qt5_FOUND AND WIN32 AND TARGET Qt5::qmake AND NOT TARGET Qt5::windeployqt)
    get_target_property(_qt5_qmake_location Qt5::qmake IMPORTED_LOCATION)

    execute_process(
        COMMAND "${_qt5_qmake_location}" -query QT_INSTALL_PREFIX
        RESULT_VARIABLE return_code
        OUTPUT_VARIABLE qt5_install_prefix
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    set(imported_location "${qt5_install_prefix}/bin/windeployqt.exe")

    if(EXISTS ${imported_location})
        add_executable(Qt5::windeployqt IMPORTED)

        set_target_properties(Qt5::windeployqt PROPERTIES
            IMPORTED_LOCATION ${imported_location}
        )
    endif()
endif()

################################################################################
# McCtrol Project
################################################################################
project(mcctrl)
add_executable(${PROJECT_NAME} main.cpp)

target_compile_definitions(${PROJECT_NAME} PRIVATE
    -D QT_DEPRECATED_WARNINGS
    -D QT_QML_DEBUG
    -D QT_DISABLE_DEPRECATED_BEFORE=0x060000)

qt5_add_resources(RESOURCES qml.qrc)

target_sources(${PROJECT_NAME} PRIVATE qmlmqttclient.cpp main.qml ${RESOURCES})

target_include_directories(${PROJECT_NAME} PRIVATE mosquitto/lib)
target_include_directories(${PROJECT_NAME} PRIVATE mosquitto/lib/cpp)

qt5_use_modules(${PROJECT_NAME} Quick QuickControls2)

# Use paho mqtt cpp
target_link_libraries(${PROJECT_NAME} mosquittopp)

# set libmosquitto and mosquittopp output directory to mcctrl output director
set_target_properties(libmosquitto PROPERTIES
                      RUNTIME_OUTPUT_DIRECTORY_DEBUG $<TARGET_FILE_DIR:mcctrl>
                      RUNTIME_OUTPUT_DIRECTORY_RELEASE $<TARGET_FILE_DIR:mcctrl>
)
set_target_properties(mosquittopp PROPERTIES
                      RUNTIME_OUTPUT_DIRECTORY_DEBUG $<TARGET_FILE_DIR:mcctrl>
                      RUNTIME_OUTPUT_DIRECTORY_RELEASE $<TARGET_FILE_DIR:mcctrl>
)

if(TARGET Qt5::windeployqt)
    # execute windeployqt in a tmp directory after build
    add_custom_command(TARGET mcctrl
        POST_BUILD
        COMMAND set PATH=%PATH%$<SEMICOLON>${qt5_install_prefix}/bin
        COMMAND Qt5::windeployqt --qmldir ${CMAKE_CURRENT_LIST_DIR} "$<TARGET_FILE_DIR:mcctrl>/$<TARGET_FILE_NAME:mcctrl>"
    )
endif()
