extern const string GETTEXT_PACKAGE;

public static int main (string[] args) {
    string filename = (args.length > 1) ? args[1] : "";
    string ? lc_time = null;

#if ! WINDOWS
    lc_time = GLib.Environment.get_variable("LC_TIME");
    if (lc_time == null)
        lc_time = GLib.Environment.get_variable("LC_ALL");
    if (lc_time == null)
        lc_time = GLib.Environment.get_variable("LANG");
#else
    lc_time = GLib.Win32.getlocale();
#endif
    if (lc_time != null)
        GLib.Intl.setlocale (LocaleCategory.TIME, lc_time);

    Intl.bindtextdomain(PROGRAM, LOCALE_DIR);
    Intl.bind_textdomain_codeset(PROGRAM, "UTF-8");
    Intl.textdomain(PROGRAM);

    Gtk.init (ref args);
    var app = new App ();

    try {
        app.loadui (filename);
    } catch (Error e) {
        stderr.printf (_("Could not load app UI: %s\n"), e.message);
        return 1;
    }

    Gtk.main ();
    return 0;
}
