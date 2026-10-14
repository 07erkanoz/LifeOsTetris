#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/encodable_value.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <memory>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // "lifeos_kupler/window": lets the game switch to borderless full screen.
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> window_channel_;

  // Covers the whole monitor (no title bar or taskbar), or restores the
  // window it was before.
  void SetFullScreen(bool full_screen);

  bool full_screen_ = false;
  bool restore_maximized_ = true;
  LONG saved_style_ = 0;
  RECT saved_rect_{};
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
