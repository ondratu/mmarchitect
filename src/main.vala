//extern const string GETTEXT_PACKAGE;

public static int main (string[] args) {
    string filename = (args.length > 1) ? args[1] : "";

    Intl.bindtextdomain(PROGRAM, SYSTEM_LANG_DIR);
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
