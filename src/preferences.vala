enum Start {
    EMPTY,
    LAST,
    MAP
}

enum RisingMethod {
    DISABLE,
    BRANCHES,
    MIN,
    MAX,
    AVG
}

enum IdeaPoints {
    IGNORE,             // node points are ignore when chlidren have points
    SUM,                // node points are sumary with all children points
    REPLACE             // node points are replace when children have poins
}

public class PreferenceWidgets : GLib.Object {
    public Gtk.Dialog dialog;

    // general tab
    public Gtk.Entry author_name;
    public Gtk.Entry author_surname;
    public Gtk.FileChooserButton default_directory;
    public Gtk.RadioButton start_empty;
    public Gtk.RadioButton start_last;
    public Gtk.RadioButton start_map;

    // style tab
    public Gtk.CheckButton node_system_font;
    public Gtk.FontButton node_font;
    public Gtk.SpinButton font_rise;
    public Gtk.SpinButton line_rise;
    public Gtk.SpinButton font_padding;
    public Gtk.SpinButton height_padding;
    public Gtk.SpinButton width_padding;
    public Gtk.CheckButton text_system_font;
    public Gtk.FontButton text_font;
    public Gtk.SpinButton text_height;

    // map tab
    public Gtk.RadioButton rise_method_disable;
    public Gtk.RadioButton rise_method_branches;
    public Gtk.RadioButton rise_methos_min;
    public Gtk.RadioButton rise_methos_max;
    public Gtk.RadioButton rise_methos_avg;
    public Gtk.RadioButton points_ignore;
    public Gtk.RadioButton points_sum;
    public Gtk.RadioButton points_replace;

    public PreferenceWidgets () {}
    
    public void loadui () throws Error {
        var builder = new Gtk.Builder ();
        builder.add_from_file (DATA + "/ui/preferences.ui");
        builder.connect_signals (this);

        dialog = builder.get_object ("dialog") as Gtk.Dialog;

        // general tab
        author_name = builder.get_object ("author_name") as Gtk.Entry;
        author_surname = builder.get_object ("author_surname") as Gtk.Entry;
        default_directory = builder.get_object("default_directory") 
                    as Gtk.FileChooserButton;
        start_empty = builder.get_object("start_empty") as Gtk.RadioButton;
        start_last = builder.get_object("start_last") as Gtk.RadioButton;
        start_map = builder.get_object("start_map") as Gtk.RadioButton;

        // style tab
        node_system_font = builder.get_object("node_system_font")
                    as Gtk.CheckButton;
        node_font = builder.get_object("node_font") as Gtk.FontButton;
        font_rise = builder.get_object("font_rise") as Gtk.SpinButton;
        font_rise.set_increments (10, 50);
        font_rise.set_range (20, 400);

        line_rise = builder.get_object("line_rise") as Gtk.SpinButton;
        line_rise.set_increments (5, 10);
        line_rise.set_range (1, 100);

        font_padding = builder.get_object("font_padding") as Gtk.SpinButton;
        font_padding.set_increments (5, 10);
        font_padding.set_range (0, 200);

        height_padding = builder.get_object("height_padding") as Gtk.SpinButton;
        height_padding.set_increments (5, 10);
        height_padding.set_range (0, 200);

        width_padding = builder.get_object("width_padding") as Gtk.SpinButton;
        width_padding.set_increments (5, 10);
        width_padding.set_range (0, 200);

        text_system_font =builder.get_object("text_system_font")
                    as Gtk.CheckButton;
        text_font = builder.get_object("text_font") as Gtk.FontButton;
        text_height = builder.get_object("text_height") as Gtk.SpinButton;
        text_height.set_increments (5, 10);
        text_height.set_range (100, 1000);

        // map tab
        rise_method_disable = builder.get_object("rise_method_disable") as Gtk.RadioButton;
    }

    [CCode (instance_pos = -1)]
    [CCode (cname = "G_MODULE_EXPORT preference_widgets_toggled_node_font")]
    public void toggled_node_font (Gtk.Widget sender) {
        node_font.set_sensitive(!node_system_font.get_active());
    }

    [CCode (instance_pos = -1)]
    [CCode (cname = "G_MODULE_EXPORT preference_widgets_toggled_text_font")]
    public void toggled_text_font (Gtk.Widget sender) {
        text_font.set_sensitive(!text_system_font.get_active());
    }
}

public class Preferences : GLib.Object {

    public Gtk.Settings gtk_sett;
    public Pango.FontDescription font_desc;
    public int dpi;
    public Gdk.Color default_color;

    public unowned PreferenceWidgets pw;

    public string author_name;
    public string author_surname;
    public string default_directory;
    public uint start_with;

    public bool node_system_font;
    public Pango.FontDescription node_font;
    public double font_rise;
    public double line_rise;
    public double font_padding;
    public double height_padding;
    public double width_padding;
    public bool text_system_font;
    public Pango.FontDescription text_font;
    public double text_height;

    public Preferences () {

        gtk_sett = Gtk.Settings.get_default ();
        font_desc = Pango.FontDescription.from_string(gtk_sett.gtk_font_name);
        dpi = gtk_sett.gtk_xft_dpi/1024;
        default_color = { uint32.MIN, uint16.MAX/2, uint16.MAX/2, uint16.MAX/2 };

        load_default ();
        //load_from_config ();
    }

    private void load_default() {
        author_name = "";           // TODO: get from system
        author_surname = "";
        default_directory = GLib.Environment.get_home_dir();
        start_with = Start.EMPTY;

        node_system_font = true;
        node_font = Pango.FontDescription.from_string(gtk_sett.gtk_font_name);
        font_rise = FONT_RISE;
        line_rise = LINE_RISE;
        font_padding = FONT_PADDING;
        height_padding = NODE_PADDING_HEIGHT;
        width_padding = NODE_PADDING_WEIGHT;
        text_system_font = true;
        text_font = Pango.FontDescription.from_string(gtk_sett.gtk_font_name);
        text_height = TEXT_HEIGHT;
    }

    private void load_from_ui() {
        // general tab
        author_name = pw.author_name.get_text ();
        author_surname = pw.author_surname.get_text ();
        default_directory = pw.default_directory.get_current_folder ();
        if (pw.start_map.get_active ()){
            start_with = Start.MAP;
        } else if (pw.start_last.get_active ()){
            start_with = Start.LAST;
        } else {
            start_with = Start.EMPTY;
        }
            
        // style tab
        node_system_font = pw.node_system_font.get_active();
        node_font = Pango.FontDescription.from_string (pw.node_font.font_name);
        font_rise = pw.font_rise.get_value ();
        line_rise = pw.line_rise.get_value ();
        font_padding = pw.font_padding.get_value ();
        height_padding = pw.height_padding.get_value ();
        width_padding = pw.width_padding.get_value ();
        text_system_font = pw.text_system_font.get_active();
        text_font = Pango.FontDescription.from_string (pw.text_font.font_name);
        text_height = pw.text_height.get_value ();

        // map tab
        
    }

    private void save_to_ui() {
        // general tab
        pw.author_name.set_text (author_name);
        pw.author_surname.set_text (author_surname);
        pw.default_directory.set_current_folder (default_directory);
        if (start_with == Start.MAP)
            pw.start_map.set_active (true);
        else if (start_with == Start.LAST)
            pw.start_last.set_active (true);
        else
            pw.start_empty.set_active (true);

        // style tab
        pw.node_system_font.set_active (node_system_font);
        pw.node_font.set_font_name (node_font.to_string ());
        pw.font_rise.set_value (font_rise);
        pw.line_rise.set_value (line_rise);
        pw.font_padding.set_value (font_padding);
        pw.height_padding.set_value (height_padding);
        pw.width_padding.set_value (width_padding);
        pw.text_system_font.set_active (text_system_font);
        pw.text_font.set_font_name (text_font.to_string ());
        pw.text_height.set_value (text_height);
    }

    public bool dialog () {
        var pref_widgets = new PreferenceWidgets ();
        pw = pref_widgets;

        try {
            pw.loadui ();
        } catch (Error e) {
            stderr.printf ("Could not load app UI: %s\n", e.message);
            return false;
        }
        
        save_to_ui();

        var retval = (pw.dialog.run() == 1);

        if (retval) {
            load_from_ui ();
            // save_to_config ();
            // redraw_all_tabs ();
        }

        pw.dialog.destroy();
        pw = null;

        return retval;
    }

}
