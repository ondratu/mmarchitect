
public static int main (string[] args) {
    string filename = (args.length > 1) ? args[1] : "";
    Gtk.init (ref args);
    var app = new App ();

    try {
        app.loadui (filename);
    } catch (Error e) {
        stderr.printf ("Could not load app UI: %s\n", e.message);
        return 1;
    }

    Gtk.main ();
    return 0;
}
