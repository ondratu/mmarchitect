
// modules: gtk+-3.0
// sources: consts.vala

[GtkTemplate (ui = "/cz/zeropage/mmarchitect/about_dialog.ui")]
public class AboutDialog : Gtk.AboutDialog {

    public AboutDialog () {
        set_version (VERSION);
    }

}
