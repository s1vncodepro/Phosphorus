cmake_minimum_required(VERSION 3.21)
project(AssignmentReminder VERSION 1.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2)

# Core logic lives in a static library so the tests can link against it.
add_library(ar_core STATIC
    src/assignmentstore.cpp src/assignmentstore.h
    src/assignmentfilter.cpp src/assignmentfilter.h
)
target_include_directories(ar_core PUBLIC src)
target_link_libraries(ar_core PUBLIC Qt6::Core)

qt_add_executable(assignmentreminder WIN32 MACOSX_BUNDLE
    src/main.cpp
    src/appsettings.h
)

set(AR_QML
    Main Theme Icon Glow PButton PTextField Sidebar StatCard AssignmentCard EditorDialog DatePicker)
set(AR_QML_FILES)
foreach(name IN LISTS AR_QML)
    # Alias each file to the module root so it sits next to the generated qmldir;
    # otherwise the Theme singleton is not resolved as a singleton.
    set_source_files_properties(qml/${name}.qml PROPERTIES QT_RESOURCE_ALIAS ${name}.qml)
    list(APPEND AR_QML_FILES qml/${name}.qml)
endforeach()
set_source_files_properties(qml/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(assignmentreminder
    URI AssignmentReminder
    VERSION 1.0
    RESOURCE_PREFIX /
    QML_FILES ${AR_QML_FILES}
)

target_link_libraries(assignmentreminder PRIVATE
    ar_core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::QuickControls2)

option(AR_BUILD_TESTS "Build the unit tests" ON)
if(AR_BUILD_TESTS)
    find_package(Qt6 QUIET COMPONENTS Test)
    if(Qt6Test_FOUND)
        enable_testing()
        qt_add_executable(tst_store tests/tst_store.cpp)
        target_link_libraries(tst_store PRIVATE ar_core Qt6::Test)
        add_test(NAME tst_store COMMAND tst_store)
    endif()
endif()
