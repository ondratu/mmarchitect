// modules: Gtk

extern const string GETTEXT_PACKAGE;
extern const string LOCALEDIR;
extern const string DATADIR;

string ? DATA_DIR = null;

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

    DATA_DIR = GLib.Environment.get_variable("DATADIR");
    if (DATA_DIR == null){
        DATA_DIR = DATADIR;
    }

    string ? locale_dir = null;
    locale_dir = GLib.Environment.get_variable("LOCALEDIR");
    if (locale_dir == null){
        locale_dir = LOCALEDIR;
    }

    Intl.bindtextdomain(GETTEXT_PACKAGE, locale_dir);
    Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain(GETTEXT_PACKAGE);

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
