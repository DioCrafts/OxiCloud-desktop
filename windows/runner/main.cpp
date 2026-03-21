#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  // CRITICAL FIX: Set the working directory to the directory containing the
  // executable. When launched from a Start Menu shortcut, desktop shortcut,
  // or installer, Windows may set the CWD to an unrelated directory (e.g.
  // C:\Windows\System32). flutter_rust_bridge's default library loader uses
  // ioDirectory: '.' which resolves to CWD, so the Rust DLL would not be
  // found. This ensures DLLs next to the .exe are always discoverable.
  {
    wchar_t exe_path[MAX_PATH];
    if (GetModuleFileNameW(nullptr, exe_path, MAX_PATH)) {
      // Strip the filename, keep only the directory
      wchar_t *last_slash = wcsrchr(exe_path, L'\\');
      if (last_slash) {
        *last_slash = L'\0';
        SetCurrentDirectoryW(exe_path);
      }
    }
  }

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"OxiCloud", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
