

[GtkTemplate (ui = "/cz/zeropage/mmarchitect/about_dialog.ui")]
public class AboutDialog : Gtk.AboutDialog {

    public AboutDialog () {
        set_version (VERSION);
    }
}

[GtkTemplate (ui = "/cz/zeropage/mmarchitect/close_file_dialog.ui")]
public class CloseFileDialog : Gtk.Dialog {
    [GtkChild]
    private unowned Gtk.Label warning_label;

    public CloseFileDialog (string filename) {
        warning_label.label = warning_label.label.replace("%s", filename);
    }

}
