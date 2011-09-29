public class AppSettings : GLib.Object {

    public Gtk.Settings gtk_sett;
    public Pango.FontDescription font_desc;
    public int dpi;
    public int entry_icon_size;

    public AppSettings () {
        gtk_sett = Gtk.Settings.get_default ();
        font_desc = Pango.FontDescription.from_string(gtk_sett.gtk_font_name);
        font_desc.set_size (FONT_SIZE * Pango.SCALE);
        dpi = gtk_sett.gtk_xft_dpi/1024;
        entry_icon_size = 16; // TODO get size from gtk_setting

        stdout.printf ("icon_size: %s\n", gtk_sett.gtk_icon_sizes);
    }

    

}
