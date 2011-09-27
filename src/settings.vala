public class AppSettings : GLib.Object {

    public Gtk.Settings gtk_sett;
    public Pango.FontDescription font_desc;
    public int dpi;

    public AppSettings () {
        gtk_sett = Gtk.Settings.get_default ();
        font_desc = Pango.FontDescription.from_string(gtk_sett.gtk_font_name);
        font_desc.set_size (FONT_SIZE * Pango.SCALE);
        dpi = gtk_sett.gtk_xft_dpi/1024;
    }

    

}
