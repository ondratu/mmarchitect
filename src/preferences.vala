enum Start {
    EMPTY,
    LAST,
    MAP
}

public string StartToString(uint start){
    switch (start) {
        case Start.LAST:
            return "LAST";
        case Start.MAP:
            return "MAP";
        case Start.EMPTY:
        default:
            return "EMPTY";
    } 
}

public uint StartFromString(string start){
    if (start == "LAST")
        return Start.LAST;
    if (start == "MAP")
        return Start.MAP;
    else // EMPTY and default
        return Start.EMPTY;
}

enum RisingMethod {
    DISABLE,
    BRANCHES,
    MIN,
    MAX,
    AVG
}

public string RisingMethodToString(uint rising){
    switch (rising) {
        case RisingMethod.DISABLE:
            return "DISABLE";
        case RisingMethod.MIN:
            return "MIN";
        case RisingMethod.MAX:
            return "MAX";
        case RisingMethod.AVG:
            return "AVG";
        case RisingMethod.BRANCHES:
        default:
            return "BRANCHES";
    } 
}

public uint RisingMethodFromString(string rising){
    if (rising == "DISABLE")
        return RisingMethod.DISABLE;
    if (rising == "MIN")
        return RisingMethod.MIN;
    if (rising == "MAX")
        return RisingMethod.MAX;
    if (rising == "AVG")
        return RisingMethod.AVG;
    else // BRANCHES and default
        return RisingMethod.BRANCHES;
}

enum IdeaPoints {
    IGNORE,             // node points are ignore when chlidren have points
    SUM,                // node points are sumary with all children points
    REPLACE             // node points are replace when children have poins
}

public string IdeaPointsToString(uint points){
    switch (points) {
        case IdeaPoints.SUM:
            return "SUM";
        case IdeaPoints.REPLACE:
            return "REPLACE";
        case IdeaPoints.IGNORE:
        default:
            return "IGNORE";
    } 
}

public uint IdeaPointsFromString(string points){
    if (points == "SUM")
        return IdeaPoints.SUM;
    if (points == "REPLACE")
        return IdeaPoints.REPLACE;
    else // IGNORE and default
        return IdeaPoints.IGNORE;
}

public class KeyValue {
    public string key;
    public string val;

    public KeyValue(string key, string val) {
        this.key = key;
        this.val = val;
    }
}

public class PreferenceWidgets : GLib.Object {
    public Gtk.Dialog dialog;

    // general tab
    public Gtk.Entry author;
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

    // color tab
    public Gtk.CheckButton system_colors;
    public Gtk.ColorButton default_color;
    public Gtk.ColorButton canvas_color;
    public Gtk.ColorButton text_normal;
    public Gtk.ColorButton text_selected;
    public Gtk.ColorButton back_normal;
    public Gtk.ColorButton back_selected;

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
        author = builder.get_object ("author") as Gtk.Entry;
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

        text_system_font = builder.get_object("text_system_font")
                    as Gtk.CheckButton;
        text_font = builder.get_object("text_font") as Gtk.FontButton;
        text_height = builder.get_object("text_height") as Gtk.SpinButton;
        text_height.set_increments (5, 10);
        text_height.set_range (100, 1000);

        // color tab
        system_colors = builder.get_object("system_colors") as Gtk.CheckButton;
        default_color = builder.get_object("default_color") as Gtk.ColorButton;
        canvas_color = builder.get_object("canvas_color") as Gtk.ColorButton;
        text_normal = builder.get_object("text_normal") as Gtk.ColorButton;
        text_selected = builder.get_object("text_selected") as Gtk.ColorButton;
        back_normal = builder.get_object("back_normal") as Gtk.ColorButton;
        back_selected = builder.get_object("back_selected") as Gtk.ColorButton;

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

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT preference_widgets_toggled_node_font")]
    public void toggled_node_font (Gtk.Widget sender) {
        node_font.set_sensitive(!node_system_font.get_active());
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT preference_widgets_toggled_text_font")]
    public void toggled_text_font (Gtk.Widget sender) {
        text_font.set_sensitive(!text_system_font.get_active());
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT preference_widgets_toggled_system_colors")]
    public void toggled_system_colors (Gtk.Widget sender) {
        default_color.set_sensitive(!system_colors.get_active());
        canvas_color.set_sensitive(!system_colors.get_active());
        text_normal.set_sensitive(!system_colors.get_active());
        text_selected.set_sensitive(!system_colors.get_active());
        back_normal.set_sensitive(!system_colors.get_active());
        back_selected.set_sensitive(!system_colors.get_active());
    }
}

public class Preferences : GLib.Object {

    public Gtk.Settings gtk_sett;
    public int dpi;

    public unowned PreferenceWidgets pw;

    public string author;
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

    public bool system_colors;
    public Gdk.Color default_color;
    public Gdk.Color canvas_color;
    public Gdk.Color text_normal; 
    public Gdk.Color text_selected;
    public Gdk.Color back_normal; 
    public Gdk.Color back_selected;

    public uint rise_method;
    public uint points;
    public bool rise_ideas;
    public bool rise_branches;

    private Gee.HashMap<string, string> print_settings;

    public Preferences () {
        this.print_settings = new Gee.HashMap<string, string> ();

        gtk_sett = Gtk.Settings.get_default ();
#if ! WINDOWS
        dpi = gtk_sett.gtk_xft_dpi/1024;
#else
        dpi = 96;               // there is no gtk_xft_dpi property on windows
#endif

        load_default ();
        load_from_config ();
    }

    public void set_style(Gtk.Style style) {
        if (! system_colors)
            return;

        default_color   = style.fg[Gtk.StateType.NORMAL];
        canvas_color    = style.bg[Gtk.StateType.NORMAL];
        text_normal     = style.text[Gtk.StateType.NORMAL];
        text_selected   = style.text[Gtk.StateType.SELECTED];
        back_normal     = style.bg[Gtk.StateType.NORMAL];
        back_selected   = style.bg[Gtk.StateType.SELECTED];        
    }

    private void load_default() {
        author = GLib.Environment.get_real_name();
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

        system_colors = true;
        default_color = { uint32.MIN, uint16.MAX/2, uint16.MAX/2, uint16.MAX/2 };   // gray
        canvas_color = { uint32.MIN, uint16.MAX, uint16.MAX, uint16.MAX };          // white
        text_normal   = { uint32.MIN, uint16.MIN, uint16.MIN, uint16.MIN };         // black
        text_selected = canvas_color;
        back_normal   = canvas_color;
        back_selected = default_color;

        rise_method = RisingMethod.BRANCHES;
        points = IdeaPoints.IGNORE;
        rise_ideas = true;
        rise_branches = true;
    }

    private void read_general_node(Xml.Node* node) {
        for (Xml.Node* it = node->children; it != null; it = it->next) {
            if (it->type != Xml.ElementType.ELEMENT_NODE) {
                continue;
            }
        
            if (it->name == "author"){
                author = it->get_content().strip();
            } else if (it->name == "default_directory"){
                default_directory = it->get_content().strip();
            } else if (it->name == "start_with"){
                start_with = StartFromString (it->get_content().strip());
            }
        }        
    }

    private void read_style_node(Xml.Node* node) {
        for (Xml.Node* it = node->children; it != null; it = it->next) {
            if (it->type != Xml.ElementType.ELEMENT_NODE) {
                continue;
            }
        
            if (it->name == "node_system_font"){
                node_system_font = bool.parse(it->get_content().strip());
            } else if (it->name == "node_font"){
                if (!node_system_font)
                    node_font = Pango.FontDescription.from_string(
                            it->get_content().strip());
            } else if (it->name == "font_rise"){
                font_rise = int.parse(it->get_content().strip());
            } else if (it->name == "line_rise"){
                line_rise = int.parse(it->get_content().strip());
            } else if (it->name == "font_padding"){
                font_padding = int.parse(it->get_content().strip());
            } else if (it->name == "height_padding"){
                height_padding = int.parse(it->get_content().strip());
            } else if (it->name == "width_padding"){
                width_padding = int.parse(it->get_content().strip());
            } else if (it->name == "text_system_font"){
                text_system_font = bool.parse(it->get_content().strip());
            } else if (it->name == "text_font"){
                if (!text_system_font)
                    text_font = Pango.FontDescription.from_string(
                            it->get_content().strip());
            } else if (it->name == "text_height"){
                text_height = int.parse(it->get_content().strip());
            }
        }
    }

    private void read_colors_node(Xml.Node* node) {
        for (Xml.Node* it = node->children; it != null; it = it->next) {
            if (it->type != Xml.ElementType.ELEMENT_NODE) {
                continue;
            }
        
            // XXX: tady pokud neni system colors false prvni tak to neklapne
            if (it->name == "system_colors"){
                system_colors = bool.parse(it->get_content().strip());
            } else if (!system_colors) {
                if (it->name == "default_color"){
                    Gdk.Color.parse(it->get_content(), out default_color);
                } else if (it->name == "canvas_color"){
                    Gdk.Color.parse(it->get_content(), out canvas_color);
                } else if (it->name == "text_normal"){
                    Gdk.Color.parse(it->get_content(), out text_normal);
                } else if (it->name == "text_selected"){
                    Gdk.Color.parse(it->get_content(), out text_selected);
                } else if (it->name == "back_normal"){
                    Gdk.Color.parse(it->get_content(), out back_normal);
                } else if (it->name == "back_selected"){
                    Gdk.Color.parse(it->get_content(), out back_selected);
                }
            }
        }        
    }

    private void read_map_node(Xml.Node* node) {
        for (Xml.Node* it = node->children; it != null; it = it->next) {
            if (it->type != Xml.ElementType.ELEMENT_NODE) {
                continue;
            }
        
            if (it->name == "rise_method"){
                rise_method = RisingMethodFromString(it->get_content().strip());
            } else if (it->name == "points"){
                points = IdeaPointsFromString(it->get_content().strip());
            } else if (it->name == "rise_ideas"){
                rise_ideas = bool.parse(it->get_content().strip());
            } else if (it->name == "rise_branches"){
                rise_branches = bool.parse(it->get_content().strip());
            }
        }
    }

    private void load_from_config () {
        var path = GLib.Environment.get_user_config_dir() + "/"+PROGRAM+".conf";
        if (!GLib.File.new_for_path (path).query_exists())
            return;

        var r = new Xml.TextReader.filename (path);
        r.read();
        
        Xml.Node* x = r.expand ();
        if (x == null)
            return;
        
        // read the file
        for (Xml.Node* it = x->children; it != null; it = it->next) {
            if (it->type != Xml.ElementType.ELEMENT_NODE) {
                continue;
            }
            
            if (it->name == "general"){
                read_general_node(it);
            }
            if (it->name == "style"){
                read_style_node(it);
            }
            if (it->name == "colors"){
                read_colors_node(it);
            }
            if (it->name == "map"){
                read_map_node(it);
            }
            if (it->name == "print"){
                read_print_node(it);
            }
        }
    }

    private void load_from_ui(Gtk.Style style) {
        // general tab
        author = pw.author.get_text ();
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

        // colors map
        system_colors = pw.system_colors.get_active();
        if (!system_colors) {
            pw.default_color.get_color(out default_color);
            pw.canvas_color.get_color(out canvas_color);
            pw.text_normal.get_color(out text_normal);
            pw.text_selected.get_color(out text_selected);
            pw.back_normal.get_color(out back_normal);
            pw.back_selected.get_color(out back_selected);
        } else {
            set_style (style);
        }

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
        pw.author.set_text (author);
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

        // colors map
        pw.system_colors.set_active (system_colors);
        pw.default_color.set_color (default_color);
        pw.canvas_color.set_color (canvas_color);
        pw.text_normal.set_color (text_normal);
        pw.text_selected.set_color (text_selected);
        pw.back_normal.set_color (back_normal);
        pw.back_selected.set_color (back_selected);

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


    private void write_general_node (Xml.TextWriter w) {
        w.start_element ("general");
       
        w.write_element ("author", author);
        w.write_element ("default_directory", default_directory);
        w.write_element ("start_with", StartToString (start_with));

        w.end_element ();
    }

    private void write_style_node (Xml.TextWriter w) {
        w.start_element ("style");
        
        w.write_element ("node_system_font", node_system_font.to_string ());
        if (!node_system_font)
            w.write_element ("node_font", node_font.to_string ());
        w.write_element ("font_rise", font_rise.to_string ());
        w.write_element ("line_rise", line_rise.to_string ());
        w.write_element ("font_padding", font_padding.to_string ());
        w.write_element ("width_padding", width_padding.to_string ());
        w.write_element ("text_system_font", text_system_font.to_string ());
        if (!text_system_font)
            w.write_element ("text_font", text_font.to_string ());
        w.write_element ("text_font_size", text_font_size.to_string ());
        w.write_element ("text_height", text_height.to_string ());

        w.end_element ();
    }

    private void write_colors_node (Xml.TextWriter w) {
        w.start_element ("colors");
       
        w.write_element ("system_colors", system_colors.to_string ());
        if (!system_colors) {
            w.write_element ("default_color", default_color.to_string());
            w.write_element ("canvas_color", canvas_color.to_string());
            w.write_element ("text_normal", text_normal.to_string());
            w.write_element ("text_selected", text_selected.to_string());
            w.write_element ("back_normal", back_normal.to_string());
            w.write_element ("back_selected", back_selected.to_string());
        }

        w.end_element ();
    }

    private void write_map_node (Xml.TextWriter w) {
        w.start_element ("map");

        w.write_element ("rise_method", RisingMethodToString (rise_method));
        w.write_element ("points", IdeaPointsToString (points));
        w.write_element ("rise_ideas", rise_ideas.to_string ());
        w.write_element ("rise_branches", rise_branches.to_string ());

        w.end_element ();
    }

    private void save_to_config() throws Error {
        string config_dir_str = GLib.Environment.get_user_config_dir();
        var config_dir = GLib.File.new_for_path(config_dir_str);
        if (!config_dir.query_exists())
            GLib.DirUtils.create_with_parents(config_dir_str, 0755);
        if (config_dir.query_file_type (0) != FileType.DIRECTORY)
            throw new GLib.FileError.NOTDIR (config_dir_str + " is not directory!");

        var w = new Xml.TextWriter.filename (config_dir_str + "/"+PROGRAM+".conf");
        w.set_indent (true);
        w.set_indent_string ("\t");

        w.start_document ();
        w.start_element ("appconfig");

        write_general_node (w);
        write_style_node (w);
        write_colors_node (w);
        write_map_node (w);
        write_print_node (w);

        w.end_element();
        w.end_document();
        w.flush();
    }

    public bool dialog () {
        // TODO: set modal !!
        if (pw != null) {
            stderr.printf("Preferences are open yet.\n");
            return false;
        }

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
            load_from_ui (pw.dialog.style);
            try {
                save_to_config ();
            } catch (Error e) {
                stderr.printf ("%s\n", e.message);
            }
        }

        pw.dialog.destroy();
        pw = null;

        return retval;
    }

    private void read_from_print_settings (string key, string val) {
        print_settings.set(key, val); 
    }

    public void load_print_settings (Gtk.PrintSettings settings) {
        foreach (var it in print_settings.entries){
            settings.set(it.key, it.value);
        }
    }

    private void write_print_node (Xml.TextWriter w) {
        w.start_element ("print");

        foreach (var it in print_settings.entries){
            w.write_element (it.key, it.value);
        }

        w.end_element ();
    }

    private void read_print_node (Xml.Node* node) {
        for (Xml.Node* it = node->children; it != null; it = it->next) {
            if (it->type != Xml.ElementType.ELEMENT_NODE) {
                continue;
            }

            print_settings.set(it->name, it->get_content()); 
        }
    }

    public void save_print_settings(Gtk.PrintSettings settings)  throws Error {
        settings.foreach (read_from_print_settings);
        save_to_config ();
    }

}
