
public static int main (string[] args) {
    Gtk.init (ref args);
    var app = new App ();
    
    try {
        app.loadui ();
    } catch (Error e) {
        stderr.printf ("Could not load app UI: %s\n", e.message);
        return 1;
    }

    Gtk.main ();
    return 0;
}
