#include "flutter_window.h"

#include <flutter/standard_method_codec.h>

#include <optional>
#include <variant>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  window_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "lifeos_kupler/window",
      &flutter::StandardMethodCodec::GetInstance());
  window_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "setFullScreen") {
          const auto* on = std::get_if<bool>(call.arguments());
          if (on == nullptr) {
            result->Error("bad_arguments", "Expected a bool");
            return;
          }
          SetFullScreen(*on);
          result->Success(flutter::EncodableValue(full_screen_));
        } else if (call.method_name() == "isFullScreen") {
          result->Success(flutter::EncodableValue(full_screen_));
        } else {
          result->NotImplemented();
        }
      });

  // Games open filling the screen: maximized, or full screen if the game
  // already asked for it before the first frame.
  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    ::ShowWindow(GetHandle(), full_screen_ ? SW_SHOWNORMAL : SW_SHOWMAXIMIZED);
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::SetFullScreen(bool full_screen) {
  HWND hwnd = GetHandle();
  if (hwnd == nullptr || full_screen == full_screen_) {
    return;
  }
  if (full_screen) {
    // A window that is not shown yet opens maximized, so return to that.
    restore_maximized_ = !::IsWindowVisible(hwnd) || ::IsZoomed(hwnd);
    if (::IsZoomed(hwnd)) {
      ::ShowWindow(hwnd, SW_RESTORE);
    }
    saved_style_ = ::GetWindowLong(hwnd, GWL_STYLE);
    ::GetWindowRect(hwnd, &saved_rect_);
    MONITORINFO monitor = {sizeof(monitor)};
    ::GetMonitorInfo(::MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST), &monitor);
    const RECT& area = monitor.rcMonitor;
    ::SetWindowLong(hwnd, GWL_STYLE, saved_style_ & ~(WS_CAPTION | WS_THICKFRAME));
    ::SetWindowPos(hwnd, HWND_TOP, area.left, area.top, area.right - area.left,
                   area.bottom - area.top, SWP_NOOWNERZORDER | SWP_FRAMECHANGED);
  } else {
    ::SetWindowLong(hwnd, GWL_STYLE, saved_style_);
    const RECT& area = saved_rect_;
    ::SetWindowPos(hwnd, nullptr, area.left, area.top, area.right - area.left,
                   area.bottom - area.top,
                   SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_FRAMECHANGED);
    if (restore_maximized_) {
      ::ShowWindow(hwnd, SW_MAXIMIZE);
    }
  }
  full_screen_ = full_screen;
}

void FlutterWindow::OnDestroy() {
  window_channel_ = nullptr;
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
