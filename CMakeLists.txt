cmake_minimum_required(VERSION 3.24)
project(NovaOS VERSION 0.2.0 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
include(CTest)
option(NOVA_BUILD_DESKTOP "Build the native Qt/KDE Control Center" ON)

add_library(nova_metrics STATIC src/core/SystemMetrics.cpp)
target_include_directories(nova_metrics PUBLIC src/core)
target_compile_options(nova_metrics PRIVATE -Wall -Wextra -Wpedantic)
if(BUILD_TESTING)
    add_executable(nova_metrics_test tests/metrics_test.cpp)
    target_link_libraries(nova_metrics_test PRIVATE nova_metrics)
    add_test(NAME metrics-parser COMMAND nova_metrics_test)
endif()

if(NOVA_BUILD_DESKTOP)
    find_package(Qt6 6.6 REQUIRED COMPONENTS Core Gui Quick QuickControls2 DBus Svg Test)
    find_package(KF6Config REQUIRED)
    find_package(KF6Kirigami REQUIRED)
    find_package(KF6IconThemes REQUIRED)
    set(CMAKE_AUTOMOC ON)
    add_library(nova_backend STATIC
        src/MetricsProvider.cpp src/MetricsProvider.hpp
        src/Preferences.cpp src/Preferences.hpp
        src/SystemInfo.cpp src/SystemInfo.hpp
        src/DesktopActions.cpp src/DesktopActions.hpp
        src/UpdateManager.cpp src/UpdateManager.hpp
        src/ProfileManager.cpp src/ProfileManager.hpp
        src/DriverCenter.cpp src/DriverCenter.hpp)
    target_include_directories(nova_backend PUBLIC src)
    target_link_libraries(nova_backend PUBLIC nova_metrics Qt6::Core Qt6::DBus KF6::ConfigCore)
    target_compile_options(nova_backend PRIVATE -Wall -Wextra -Wpedantic)
    qt_add_executable(nova-control-center src/main.cpp)
    target_link_libraries(nova-control-center PRIVATE nova_backend Qt6::Gui Qt6::Quick Qt6::QuickControls2 Qt6::Svg KF6::IconThemes)
    set(NOVA_UI_FILES
        ui/qmldir ui/Theme.qml ui/Main.qml ui/NovaCard.qml ui/NovaButton.qml
        ui/NavItem.qml ui/MetricBar.qml ui/NovaIcon.qml assets/nova-mark.svg assets/cosmic.svg)
    qt_add_resources(nova-control-center nova_ui PREFIX "/" FILES ${NOVA_UI_FILES})
    install(TARGETS nova-control-center RUNTIME DESTINATION bin)
    install(FILES system/usr/share/applications/org.novaos.ControlCenter.desktop DESTINATION share/applications)
    install(FILES assets/nova-mark.svg DESTINATION share/icons/hicolor/scalable/apps RENAME nova-control-center.svg)

    add_library(nova_compat STATIC
        src/compat/CompatInspector.cpp src/compat/CompatInspector.hpp)
    target_include_directories(nova_compat PUBLIC src/compat)
    target_link_libraries(nova_compat PUBLIC Qt6::Core)
    target_compile_options(nova_compat PRIVATE -Wall -Wextra -Wpedantic)
    qt_add_executable(nova-compatibility
        src/compat/main.cpp src/compat/CompatController.cpp src/compat/CompatController.hpp)
    target_link_libraries(nova-compatibility PRIVATE nova_compat Qt6::Gui Qt6::Quick Qt6::QuickControls2)
    qt_add_resources(nova-compatibility nova_compat_ui PREFIX "/"
        FILES ui/Compatibility.qml assets/nova-mark.svg)
    install(TARGETS nova-compatibility RUNTIME DESTINATION bin)
    if(BUILD_TESTING)
        qt_add_executable(nova_compat_test tests/compatibility_test.cpp)
        target_link_libraries(nova_compat_test PRIVATE nova_compat Qt6::Test)
        add_test(NAME compatibility-parser COMMAND nova_compat_test)
        qt_add_executable(nova_backend_test tests/backend_test.cpp)
        target_link_libraries(nova_backend_test PRIVATE nova_backend Qt6::Test)
        add_test(NAME preference-persistence-and-monitor-lifecycle COMMAND nova_backend_test)
        qt_add_executable(nova_ui_test tests/ui_test.cpp)
        target_link_libraries(nova_ui_test PRIVATE nova_backend Qt6::Test Qt6::Quick Qt6::QuickControls2 Qt6::Svg KF6::IconThemes)
        qt_add_resources(nova_ui_test nova_test_ui PREFIX "/" FILES ${NOVA_UI_FILES})
        add_test(NAME keyboard-and-page-lifecycle COMMAND nova_ui_test)
        set_tests_properties(keyboard-and-page-lifecycle PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen;QT_QUICK_BACKEND=software;QT_FORCE_STDERR_LOGGING=1")
    endif()
endif()

