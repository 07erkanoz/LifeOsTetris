#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlMethodChannel* window_channel;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Desktops (GNOME, KDE, Wayland in general) take a window's icon from the
// .desktop file named after the application id, not from the window. A
// package installs that file; when the game runs straight from the unpacked
// tar.gz there is none, so write a per-user entry pointing at this copy.
static void ensure_desktop_entry(const gchar* exe, const gchar* icon) {
  const gchar* name = APPLICATION_ID ".desktop";
  for (const gchar* const* dir = g_get_system_data_dirs(); *dir != nullptr; dir++) {
    g_autofree gchar* system = g_build_filename(*dir, "applications", name, nullptr);
    if (g_file_test(system, G_FILE_TEST_EXISTS)) return;
  }
  g_autofree gchar* folder = g_build_filename(g_get_user_data_dir(), "applications", nullptr);
  if (g_mkdir_with_parents(folder, 0755) != 0) return;
  g_autofree gchar* path = g_build_filename(folder, name, nullptr);
  g_autofree gchar* contents = g_strdup_printf(
      "[Desktop Entry]\n"
      "Type=Application\n"
      "Name=LifeOS Küpler\n"
      "Comment=Bol efektli blok bulmaca oyunu\n"
      "Comment[en]=A block puzzle game packed with effects\n"
      "Exec=\"%s\"\n"
      "Icon=%s\n"
      "Terminal=false\n"
      "Categories=Game;BlocksGame;\n"
      "StartupWMClass=%s\n",
      exe, icon, APPLICATION_ID);
  g_autofree gchar* current = nullptr;
  if (g_file_get_contents(path, &current, nullptr, nullptr) &&
      g_strcmp0(current, contents) == 0) {
    return;
  }
  g_file_set_contents(path, contents, -1, nullptr);
}

// Sets the window (and X11 taskbar) icon from data/app_icon.png next to the
// executable, and makes sure the desktop knows the icon too.
static void set_window_icon(GtkWindow* window) {
  g_autofree gchar* exe = g_file_read_link("/proc/self/exe", nullptr);
  if (exe == nullptr) return;
  g_autofree gchar* dir = g_path_get_dirname(exe);
  g_autofree gchar* path = g_build_filename(dir, "data", "app_icon.png", nullptr);
  gtk_window_set_icon_from_file(window, path, nullptr);
  gtk_window_set_default_icon_from_file(path, nullptr);
  ensure_desktop_entry(exe, path);
}

// "lifeos_kupler/window": full screen on request from the game's settings
// (lib/platform/window_mode.dart), like the Windows runner.
static void window_method_cb(FlMethodChannel* channel, FlMethodCall* call,
                             gpointer user_data) {
  GtkWindow* window = GTK_WINDOW(user_data);
  g_autoptr(FlMethodResponse) response = nullptr;
  if (g_strcmp0(fl_method_call_get_name(call), "setFullScreen") == 0) {
    FlValue* args = fl_method_call_get_args(call);
    const gboolean on = args != nullptr &&
                        fl_value_get_type(args) == FL_VALUE_TYPE_BOOL &&
                        fl_value_get_bool(args);
    if (on) {
      gtk_window_fullscreen(window);
    } else {
      gtk_window_unfullscreen(window);
      gtk_window_maximize(window);
    }
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_bool(TRUE)));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  fl_method_call_respond(call, response, nullptr);
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "LifeOS Küpler");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "LifeOS Küpler");
  }

  gtk_window_set_default_size(window, 1280, 720);
  set_window_icon(window);
  // Games open filling the screen.
  gtk_window_maximize(window);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  g_autoptr(FlPluginRegistrar) registrar =
      fl_plugin_registry_get_registrar_for_plugin(FL_PLUGIN_REGISTRY(view),
                                                  "LifeosWindow");
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->window_channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar), "lifeos_kupler/window",
      FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->window_channel,
                                            window_method_cb, window, nullptr);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  g_clear_object(&self->window_channel);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
