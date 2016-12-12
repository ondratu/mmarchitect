// modules: gtk+-3.0 

public int get_dpi () {
#if ! WINDOWS
	var gtk_sett = Gtk.Settings.get_default ();
    return gtk_sett.gtk_xft_dpi/1024;
#else
        return 96;              // there is no gtk_xft_dpi property on windows
#endif
 
}

public string font_to_css(Pango.FontDescription font, string class_name) {
    string ? family = font.get_family();
    string family_string =(family != null) ? @"font-family: $family;" : "";

    string style = "";
    switch (font.get_style()){
        case Pango.Style.OBLIQUE:
            style = "font-style: oblique;";
            break;
        case Pango.Style.ITALIC:
            style = "font-style: italic;";
            break;
    }

    string weight = "";
    switch (font.get_weight()){
        case Pango.Weight.BOLD:
            weight = "font-weight: bold;";
            break;
        // other is not supported
    }

    long size = GLib.Math.lrint (font.get_size() / (get_dpi () / 100.0));
    return @".$class_name { $family_string $style $weight font-size: $(size/1000)pt; }";
}

public class StaticProvider : Gtk.CssProvider {
    public StaticProvider (string css_string) {
        Object ();
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            this,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }
}
