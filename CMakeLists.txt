cmake_minimum_required(VERSION 3.8)

if(WIN32)
string(REGEX REPLACE "/W[0-4]" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
string(REGEX REPLACE "/W[0-4]" "" CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")
message(STATUS "CMAKE_CXX_FLAGS: ${CMAKE_CXX_FLAGS}")
message(STATUS "CMAKE_CXX_FLAGS: ${CMAKE_C_FLAGS}")
endif()

# Find includes in corresponding build directories
set(CMAKE_INCLUDE_CURRENT_DIR ON)

################################################################################
# Mosquitto Mqtt library
################################################################################
set(WITH_SRV OFF CACHE STRING "Disable server")
set(WITH_TLS OFF CACHE STRING "Disable TLS")
set(WITH_THREADING OFF CACHE STRING "Disable threading")
set(WITH_LIB_ONLY ON STRING "Build only lib")
add_subdirectory(mosquitto)
if(WIN32)
    target_compile_options(libmosquitto PRIVATE "/W0")
    target_compile_options(mosquittopp PRIVATE "/W0")
elseif(UNIX)
    target_compile_options(libmosquitto PRIVATE "-w")
    target_compile_options(mosquittopp PRIVATE "-w")
endif()

################################################################################
# SQLite
################################################################################
project(sqlite)
add_library(${PROJECT_NAME} STATIC sqlite/sqlite3.c)
target_include_directories(${PROJECT_NAME} PUBLIC sqlite)
if(WIN32)
    target_compile_options(${PROJECT_NAME} PRIVATE "/W0")
elseif(UNIX)
    target_link_libraries(${PROJECT_NAME} PUBLIC pthread dl)
    target_compile_options(${PROJECT_NAME} PRIVATE "-w")
endif()

################################################################################
# TagLib
################################################################################
add_subdirectory(taglib)
target_compile_definitions(tag PUBLIC TAGLIB_STATIC)
# make sure include directories are set for dependent targets
target_include_directories(tag PUBLIC
    taglib/taglib/toolkit
    taglib/taglib/asf
    taglib/taglib/mpeg
    taglib/taglib/ogg
    taglib/taglib/ogg/flac
    taglib/taglib/flac
    taglib/taglib/mpc
    taglib/taglib/mp4
    taglib/taglib/ogg/vorbis
    taglib/taglib/ogg/speex
    taglib/taglib/ogg/opus
    taglib/taglib/mpeg/id3v2
    taglib/taglib/mpeg/id3v2/frames
    taglib/taglib/mpeg/id3v1
    taglib/taglib/ape
    taglib/taglib/wavpack
    taglib/taglib/trueaudio
    taglib/taglib/riff
    taglib/taglib/riff/aiff
    taglib/taglib/riff/wav
    taglib/taglib/mod
    taglib/taglib/s3m
    taglib/taglib/it
    taglib/taglib/xm
    taglib/3rdparty
    taglib
    ${CMAKE_BINARY_DIR}/taglib
)

################################################################################
# Qt
################################################################################
# Instruct CMake to run moc automatically when needed.
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Find the Qt libraries
if(WIN32)
    set (CMAKE_PREFIX_PATH "C:/Qt/5.10.1/msvc2017_64")
else()
    set (CMAKE_PREFIX_PATH "~/raspberry_pi/qt5pi")
endif()

find_package(Qt5 COMPONENTS
    Core
    Quick
    QuickControls2
    Charts
    Widgets
    REQUIRED
)

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
# McCtrl Project
################################################################################
project(mcctrl)
add_executable(${PROJECT_NAME} main.cpp)
if(WIN32)
    target_compile_options(${PROJECT_NAME} PRIVATE "/W4")
else()
    target_compile_options(${PROJECT_NAME} PRIVATE "-Wall" "-pedantic" "-g")
endif()

target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_14)
target_compile_definitions(${PROJECT_NAME} PRIVATE
    -D QT_DEPRECATED_WARNINGS
    -D QT_QML_DEBUG
    -D QT_DISABLE_DEPRECATED_BEFORE=0x060000
)

target_sources(${PROJECT_NAME} PRIVATE
    qmlmqttclient.cpp
    sensordb.cpp
    audioformatter.cpp
    qml.qrc
)

target_include_directories(${PROJECT_NAME} PRIVATE
    mosquitto/lib
    mosquitto/lib/cpp
    sqlite_orm/include
)

# Use paho mqtt cpp and Qt5
target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt5::Quick
    Qt5::QuickControls2
    Qt5::Charts
    Qt5::Widgets
    mosquittopp
    sqlite
    tag
)

# use rpath for cross compilation
if (NOT WIN32)
    add_library(${PROJECT_NAME}_rpath INTERFACE)
    target_link_libraries(${PROJECT_NAME}_rpath INTERFACE
        "-Wl,-rpath,\$ORIGIN/../../../lib"
        "-Wl,-rpath-link,~/raspberry_pi/sysroot/opt/vc/lib"
        "-Wl,-rpath-link,~/raspberry_pi/sysroot/lib/arm-linux-gnueabihf"
        "-Wl,-rpath-link,~/raspberry_pi/sysroot/usr/lib/arm-linux-gnueabihf"
    )
    target_link_libraries(${PROJECT_NAME} PRIVATE
        ${PROJECT_NAME}_rpath
    )
endif()

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
    add_custom_command(TARGET ${PROJECT_NAME}
        POST_BUILD
        COMMAND set PATH=%PATH%$<SEMICOLON>${qt5_install_prefix}/bin
        COMMAND Qt5::windeployqt --qmldir ${CMAKE_CURRENT_LIST_DIR} "$<TARGET_FILE_DIR:mcctrl>/$<TARGET_FILE_NAME:mcctrl>"
    )
endif()
