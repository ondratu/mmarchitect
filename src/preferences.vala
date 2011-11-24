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
    public Gtk.RadioButton rise_method_min;
    public Gtk.RadioButton rise_method_max;
    public Gtk.RadioButton rise_method_avg;
    public Gtk.RadioButton points_ignore;
    public Gtk.RadioButton points_sum;
    public Gtk.RadioButton points_replace;
    public Gtk.CheckButton rise_ideas;
    public Gtk.CheckButton rise_branches;

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
        font_padding.set_increments (1, 5);
        font_padding.set_range (1, 200);

        height_padding = builder.get_object("height_padding") as Gtk.SpinButton;
        height_padding.set_increments (1, 5);
        height_padding.set_range (1, 200);

        width_padding = builder.get_object("width_padding") as Gtk.SpinButton;
        width_padding.set_increments (1, 5);
        width_padding.set_range (1, 200);

        text_system_font =builder.get_object("text_system_font")
                    as Gtk.CheckButton;
        text_font = builder.get_object("text_font") as Gtk.FontButton;
        text_height = builder.get_object("text_height") as Gtk.SpinButton;
        text_height.set_increments (5, 10);
        text_height.set_range (100, 1000);

        // map tab
        rise_method_disable = builder.get_object("rise_method_disable")
                    as Gtk.RadioButton;
        rise_method_branches = builder.get_object("rise_method_branches")
                    as Gtk.RadioButton;
        rise_method_min = builder.get_object("rise_method_min")
                    as Gtk.RadioButton;
        rise_method_max = builder.get_object("rise_method_max")
                    as Gtk.RadioButton;
        rise_method_avg = builder.get_object("rise_method_avg")
                    as Gtk.RadioButton;
        points_ignore = builder.get_object("points_ignore") as Gtk.RadioButton;
        points_sum = builder.get_object("points_sum") as Gtk.RadioButton;
        points_replace = builder.get_object("points_replace") as Gtk.RadioButton;
        rise_ideas = builder.get_object("rise_ideas") as Gtk.CheckButton;
        rise_branches = builder.get_object("rise_branches") as Gtk.CheckButton;
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
    public int dpi;
    public Gdk.Color default_color;

    public unowned PreferenceWidgets pw;

    public string author_name;
    public string author_surname;
    public string default_directory;
    public uint start_with;

    public bool node_system_font;
    public Pango.FontDescription node_font;
    public int node_font_size;
    public double font_rise;
    public double line_rise;
    public int font_padding;
    public int height_padding;
    public int width_padding;
    public bool text_system_font;
    public Pango.FontDescription text_font;
    public int text_font_size;
    public int text_height;

    public uint rise_method;
    public uint points;
    public bool rise_ideas;
    public bool rise_branches;

    public Preferences () {

        gtk_sett = Gtk.Settings.get_default ();
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
        node_font_size = (node_font.get_size() / Pango.SCALE) * (dpi / 100);
        font_rise = FONT_RISE;
        line_rise = LINE_RISE;
        font_padding = FONT_PADDING;
        height_padding = NODE_PADDING_HEIGHT;
        width_padding = NODE_PADDING_WEIGHT;
        text_system_font = true;
        text_font = Pango.FontDescription.from_string(gtk_sett.gtk_font_name);
        text_font_size = (text_font.get_size() / Pango.SCALE) * (dpi / 100);
        text_height = TEXT_HEIGHT;

        rise_method = RisingMethod.BRANCHES;
        points = IdeaPoints.IGNORE;
        rise_ideas = true;
        rise_branches = true;
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
        if (!node_system_font)
            node_font = Pango.FontDescription.from_string (pw.node_font.font_name);
        else
            node_font = Pango.FontDescription.from_string (gtk_sett.gtk_font_name);
        node_font_size = (node_font.get_size() / Pango.SCALE) * (dpi / 100);
        font_rise = pw.font_rise.get_value ();
        line_rise = pw.line_rise.get_value ();
        font_padding = (int) pw.font_padding.get_value ();
        height_padding = (int) pw.height_padding.get_value ();
        width_padding = (int) pw.width_padding.get_value ();
        text_system_font = pw.text_system_font.get_active();
        if (!text_system_font)
            text_font = Pango.FontDescription.from_string (pw.text_font.font_name);
        else
            text_font = Pango.FontDescription.from_string (gtk_sett.gtk_font_name);
        text_font_size = (text_font.get_size() / Pango.SCALE) * (dpi / 100);
        text_height = (int) pw.text_height.get_value ();

        // map tab
        if (pw.rise_method_branches.get_active ()){
            rise_method = RisingMethod.BRANCHES;
        } else if (pw.rise_method_min.get_active ()){
            rise_method = RisingMethod.MIN;
        } else if (pw.rise_method_max.get_active ()){
            rise_method = RisingMethod.MAX;
        } else if (pw.rise_method_avg.get_active ()){
            rise_method = RisingMethod.AVG;
        } else {
            rise_method = RisingMethod.DISABLE;
        }
        
        if (pw.points_sum.get_active ()){
            points = IdeaPoints.SUM;
        } else if (pw.points_replace.get_active ()){
            points = IdeaPoints.REPLACE;
        } else {
            points = IdeaPoints.IGNORE;
        }

        rise_ideas = pw.rise_ideas.get_active ();
        rise_branches = pw.rise_branches.get_active ();
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

        // map tab
        switch (rise_method) {
            case RisingMethod.BRANCHES:
                pw.rise_method_branches.set_active (true);
                break;
            case RisingMethod.MIN:
                pw.rise_method_min.set_active (true);
                break;
            case RisingMethod.MAX:
                pw.rise_method_max.set_active (true);
                break;
            case RisingMethod.AVG:
                pw.rise_method_avg.set_active (true);
                break;
            case RisingMethod.DISABLE:
            default:
                pw.rise_method_disable.set_active (true);
                break;
        }
        if (points == IdeaPoints.SUM)
            pw.points_sum.set_active (true);
        else if (points == IdeaPoints.REPLACE)
            pw.points_replace.set_active (true);
        else
            pw.points_ignore.set_active (true);

        pw.rise_ideas.set_active (rise_ideas);
        pw.rise_branches.set_active (rise_branches);
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
