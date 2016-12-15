// modules: gtk+-3.0 libxml-2.0 gee-0.8

enum Start {
    EMPTY,
    LAST,
    WELCOME;

    public static string to_string(uint i){
        switch (i) {
            case Start.LAST:
                return "LAST";
            case Start.EMPTY:
                return "EMPTY";
            case Start.WELCOME:
            default:
                return "WELCOME";
        }
    }

    public static uint parse(string s){
        if (s == "LAST")
            return Start.LAST;
        if (s == "EMPTY")
            return Start.EMPTY;
        else // WELCOME and default
            return Start.WELCOME;
    }
}

public class RecentFile {
    public string path;
    public time_t time;

    public RecentFile (string path) {
        this.path = path;
        time_t(out this.time);     // fill with now time
    }

    public RecentFile.with_time (string path, time_t time) {
        this.path = path;
        this.time = time;
    }

    public RecentFile copy() {
        return new RecentFile.with_time (path, time);
    }

    public static int comp(ref RecentFile a, ref RecentFile b) {
        if (a.path == b.path)
            return 0;
        if (a.time > b.time)
            return 1;
        else
            return -1;
    }
}

public class PreferenceWidgets : MapWidgets {
    public Gtk.Dialog dialog;

    // general tab
    public Gtk.Entry author;
    public Gtk.FileChooserButton default_directory;
    public Gtk.RadioButton start_empty;
    public Gtk.RadioButton start_last;
    public Gtk.RadioButton start_welcome;

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

    public override void loadui () throws Error {
        base.loadui();

        var builder = new Gtk.Builder ();
        builder.add_from_file (DATA + "/ui/preferences.ui");
        builder.connect_signals (this);

        this.dialog = builder.get_object ("dialog") as Gtk.Dialog;

        // general tab
        this.author = builder.get_object ("author") as Gtk.Entry;
        this.default_directory = builder.get_object("default_directory")
                    as Gtk.FileChooserButton;
        this.start_empty = builder.get_object("start_empty") as Gtk.RadioButton;
        this.start_last = builder.get_object("start_last") as Gtk.RadioButton;
        this.start_welcome = builder.get_object("start_welcome") as Gtk.RadioButton;

        // style tab
        this.node_system_font = builder.get_object("node_system_font")
                    as Gtk.CheckButton;
        this.node_font = builder.get_object("node_font") as Gtk.FontButton;
        this.font_rise = builder.get_object("font_rise") as Gtk.SpinButton;
        this.font_rise.set_increments (10, 50);
        this.font_rise.set_range (20, 400);

        this.line_rise = builder.get_object("line_rise") as Gtk.SpinButton;
        this.line_rise.set_increments (5, 10);
        this.line_rise.set_range (1, 100);

        this.font_padding = builder.get_object("font_padding") as Gtk.SpinButton;
        this.font_padding.set_increments (1, 5);
        this.font_padding.set_range (1, 200);

        this.height_padding = builder.get_object("height_padding") as Gtk.SpinButton;
        this.height_padding.set_increments (1, 5);
        this.height_padding.set_range (1, 200);

        this.width_padding = builder.get_object("width_padding") as Gtk.SpinButton;
        this.width_padding.set_increments (1, 5);
        this.width_padding.set_range (1, 200);

        this.text_system_font = builder.get_object("text_system_font")
                    as Gtk.CheckButton;
        this.text_font = builder.get_object("text_font") as Gtk.FontButton;
        this.text_height = builder.get_object("text_height") as Gtk.SpinButton;
        this.text_height.set_increments (5, 10);
        this.text_height.set_range (100, 1000);

        // color tab
        this.system_colors = builder.get_object("system_colors") as Gtk.CheckButton;
        this.default_color = builder.get_object("default_color") as Gtk.ColorButton;
        this.canvas_color = builder.get_object("canvas_color") as Gtk.ColorButton;
        this.text_normal = builder.get_object("text_normal") as Gtk.ColorButton;
        this.text_selected = builder.get_object("text_selected") as Gtk.ColorButton;
        this.back_normal = builder.get_object("back_normal") as Gtk.ColorButton;
        this.back_selected = builder.get_object("back_selected") as Gtk.ColorButton;

        // map tab
        // add map vbox to application preference dialog
        var notebook = builder.get_object("notebook") as Gtk.Notebook;
        var label_map = builder.get_object("label_map") as Gtk.Label;
        notebook.append_page (this.box, label_map);
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT preference_widgets_toggled_node_font")]
    public void toggled_node_font (Gtk.Widget sender) {
        this.node_font.set_sensitive(!node_system_font.get_active());
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT preference_widgets_toggled_text_font")]
    public void toggled_text_font (Gtk.Widget sender) {
        this.text_font.set_sensitive(!text_system_font.get_active());
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT preference_widgets_toggled_system_colors")]
    public void toggled_system_colors (Gtk.Widget sender) {
        this.default_color.set_sensitive(!system_colors.get_active());
        this.canvas_color.set_sensitive(!system_colors.get_active());
        this.text_normal.set_sensitive(!system_colors.get_active());
        this.text_selected.set_sensitive(!system_colors.get_active());
        this.back_normal.set_sensitive(!system_colors.get_active());
        this.back_selected.set_sensitive(!system_colors.get_active());
    }
}

public class Preferences : GLib.Object {

    public Gtk.Settings gtk_sett;
    public int dpi;

    public unowned PreferenceWidgets pw;

    public string author;
    public string default_directory;
    public uint start_with { get; private set; }

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
    public Gdk.RGBA default_color;
    public Gdk.RGBA canvas_color;
    public Gdk.RGBA text_normal;
    public Gdk.RGBA text_selected;
    public Gdk.RGBA back_normal;
    public Gdk.RGBA back_selected;

    public uint rise_method;
    public bool rise_ideas;
    public bool rise_branches;

    private Gee.HashMap<string, string> print_settings;
    private GLib.List<RecentFile> recent_files;
    private GLib.List<string> last_files;

    public Preferences () {
        this.print_settings = new Gee.HashMap<string, string> ();
        this.recent_files = new GLib.List<RecentFile> ();
        this.last_files = new GLib.List<string> ();

        this.gtk_sett = Gtk.Settings.get_default ();
        this.dpi = get_dpi (gtk_sett);

        this.load_default ();
        this.load_style_from_gtk ();
        this.load_from_config ();
    }

    public GLib.List<RecentFile> get_recent_files(){
        // BUG: copy fails ! :(
        // return recent_files.copy ();

        var rv = new GLib.List<RecentFile>();
        foreach (var it in this.recent_files)
            rv.append (it.copy());
        return rv;
    }

    public GLib.List<string> get_last_files() {
        var rv = new GLib.List<string> ();
        foreach (var it in this.last_files)
            rv.append(it);
        return rv;
    }

    private void load_style_from_gtk() {
        if (! this.system_colors)
            return;

        var widget = new Gtk.TextView();
        var stylecx = widget.get_style_context ();

        this.default_color = (Gdk.RGBA) stylecx.get_property (
                "border-color", Gtk.StateFlags.NORMAL);
        this.canvas_color = (Gdk.RGBA) stylecx.get_property (
                "background-color", Gtk.StateFlags.NORMAL);
        this.text_normal = stylecx.get_color(Gtk.StateFlags.NORMAL);
        this.text_selected = stylecx.get_color(Gtk.StateFlags.SELECTED);
        this.back_normal = (Gdk.RGBA) stylecx.get_property (
                "background-color", Gtk.StateFlags.NORMAL);
        this.back_selected = (Gdk.RGBA) stylecx.get_property (
                "background-color", Gtk.StateFlags.SELECTED);
    }

    private void load_default() {
        author = GLib.Environment.get_real_name();
        default_directory = GLib.Environment.get_home_dir();
        start_with = Start.WELCOME;

        node_system_font = true;
        node_font = Pango.FontDescription.from_string(gtk_sett.gtk_font_name);
        node_font_size = (int) GLib.Math.lrint (
                            (node_font.get_size() / Pango.SCALE) * (dpi / 100.0));
        font_rise = FONT_RISE;
        line_rise = LINE_RISE;
        font_padding = FONT_PADDING;
        height_padding = NODE_PADDING_HEIGHT;
        width_padding = NODE_PADDING_WEIGHT;
        text_system_font = true;
        text_font = Pango.FontDescription.from_string(gtk_sett.gtk_font_name);
        text_font_size = (int) GLib.Math.lrint (
                            (text_font.get_size() / Pango.SCALE) * (dpi / 100.0));
        text_height = TEXT_HEIGHT;

        system_colors = true;
        default_color = { uint32.MAX/2, uint16.MAX/2, uint16.MAX/2, uint16.MAX/2 };   // gray
        canvas_color = { uint32.MAX, uint16.MAX, uint16.MAX, uint16.MAX };          // white
        text_normal   = { uint32.MIN, uint16.MIN, uint16.MIN, uint16.MIN };         // black
        text_selected = canvas_color;
        back_normal   = canvas_color;
        back_selected = default_color;

        rise_method = RisingMethod.BRANCHES;
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
                start_with = Start.parse (it->get_content().strip());
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
                    default_color.parse(it->get_content());
                } else if (it->name == "canvas_color"){
                    canvas_color.parse(it->get_content());
                } else if (it->name == "text_normal"){
                    text_normal.parse(it->get_content());
                } else if (it->name == "text_selected"){
                    text_selected.parse(it->get_content());
                } else if (it->name == "back_normal"){
                    back_normal.parse(it->get_content());
                } else if (it->name == "back_selected"){
                    back_selected.parse(it->get_content());
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
                rise_method = RisingMethod.parse(it->get_content().strip());
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
            if (it->name == "recent"){
                read_recent_node(it);
            }
            if (it->name == "last"){
                read_last_node(it);
            }
        }
    }

    private void load_from_ui() {
        // general tab
        author = pw.author.get_text ();
        default_directory = pw.default_directory.get_current_folder ();
        if (pw.start_empty.get_active ()){
            start_with = Start.EMPTY;
        } else if (pw.start_last.get_active ()){
            start_with = Start.LAST;
        } else {
            start_with = Start.WELCOME;
        }

        // style tab
        node_system_font = pw.node_system_font.get_active();
        if (!node_system_font)
            node_font = Pango.FontDescription.from_string (pw.node_font.font_name);
        else
            node_font = Pango.FontDescription.from_string (gtk_sett.gtk_font_name);
        node_font_size = (int) GLib.Math.lrint (
                        (node_font.get_size() / Pango.SCALE) * (dpi / 100.0));
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
        text_font_size = (int) GLib.Math.lrint (
                        (text_font.get_size() / Pango.SCALE) * (dpi / 100.0));
        text_height = (int) pw.text_height.get_value ();

        // colors map
        system_colors = pw.system_colors.get_active();
        if (!system_colors) {
            default_color = pw.default_color.get_rgba();
            canvas_color = pw.canvas_color.get_rgba();
            text_normal = pw.text_normal.get_rgba();
            text_selected = pw.text_selected.get_rgba();
            back_normal = pw.back_normal.get_rgba();
            back_selected = pw.back_selected.get_rgba();
        } else {
            load_style_from_gtk ();
        }

        // map tab
        rise_method = pw.get_rise_method ();
        rise_ideas = pw.get_rise_ideas ();
        rise_branches = pw.get_rise_branches ();
    }

    private void save_to_ui() {
        // general tab
        pw.author.set_text (author);
        pw.default_directory.set_current_folder (default_directory);
        if (start_with == Start.EMPTY)
            pw.start_empty.set_active (true);
        else if (start_with == Start.LAST)
            pw.start_last.set_active (true);
        else
            pw.start_welcome.set_active (true);

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
        pw.default_color.set_rgba (default_color);
        pw.canvas_color.set_rgba (canvas_color);
        pw.text_normal.set_rgba (text_normal);
        pw.text_selected.set_rgba (text_selected);
        pw.back_normal.set_rgba (back_normal);
        pw.back_selected.set_rgba (back_selected);

        // map tab
        pw.set_rise_method (rise_method);
        pw.set_rise_ideas (rise_ideas);
        pw.set_rise_branches (rise_branches);
    }


    private void write_general_node (Xml.TextWriter w) {
        w.start_element ("general");

        w.write_element ("author", author);
        w.write_element ("default_directory", default_directory);
        w.write_element ("start_with", Start.to_string (start_with));

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

        w.write_element ("rise_method", RisingMethod.to_string (rise_method));
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
        write_recent_node (w);
        write_last_node (w);
        write_print_node (w);

        w.end_element();
        w.end_document();
        w.flush();
    }

    public bool dialog (Gtk.Window window) {
        if (this.pw != null) {
            stderr.printf("Preferences are open yet.\n");
            return false;
        }

        var pref_widgets = new PreferenceWidgets ();
        this.pw = pref_widgets;

        try {
            pw.loadui ();
            pw.dialog.set_transient_for (window);
        } catch (Error e) {
            stderr.printf ("Could not load app UI: %s\n", e.message);
            return false;
        }

        this.save_to_ui();

        var retval = (this.pw.dialog.run() == 1);

        if (retval) {
            this.load_from_ui ();
            try {
                this.save_to_config ();
            } catch (Error e) {
                stderr.printf ("%s\n", e.message);
            }
        }

        this.pw.dialog.destroy();
        this.pw = null;

        return retval;
    }

    private void read_from_print_settings (string key, string val) {
        this.print_settings.set (key, val);
    }

    public void load_print_settings (Gtk.PrintSettings settings) {
        this.print_settings.foreach((entry) => {
            settings.set(entry.key, entry.value);
            return true;
        });
    }

    private void write_print_node (Xml.TextWriter w) {
        w.start_element ("print");

        this.print_settings.foreach((it) => {
            w.write_element (it.key, it.value);
            return true;
        });

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

    public void append_recent (string path) {
        uint len = recent_files.length ();
        for (uint i = 0; i < len; i++) {
            var it = recent_files.nth_data (i);
            if (it.path == path) {
                recent_files.remove (it);
                break;
            }
        }

        var file = new RecentFile (path);
        recent_files.insert (file, 0);

        try {
            save_to_config ();
        } catch (Error e) {
            stderr.printf("%s\n", e.message);
        }
    }

    private void write_recent_node (Xml.TextWriter w) {
        w.start_element ("recent");

        uint i = 0;
        foreach (var it in recent_files){
            uint64 utime = it.time;    // time_t have not to_string method
            w.start_element ("file");
            w.write_attribute ("path", it.path);
            w.write_attribute ("time", utime.to_string());
            w.end_element ();
            ++i;
            if (i == RECENT_FILES)  break;         // only 5 recent files
        }

        w.end_element ();
    }

    private void read_recent_node (Xml.Node* node) {
        for (Xml.Node* it = node->children; it != null; it = it->next) {
            if (it->type != Xml.ElementType.ELEMENT_NODE) {
                continue;
            }

            if (it->name != "file")     // don't know item
                continue;

            string ? path = null;
            time_t ? time = null;

            for (Xml.Attr* at = it->properties; at != null; at = at->next){
                if (at->name == "path")
                    path = at->children->content;
                else if (at->name == "time")
                    time = (time_t) uint64.parse(at->children->content);
            }

            if (path != null && time != null)
                recent_files.append (new RecentFile.with_time(path, time));
            else
                stderr.printf ("Missing file attribute %s\n", path);
        }
    }

    public void append_last (string path) {
        unowned GLib.List<string>? item = last_files.find_custom (path, strcmp);
        if (item == null)
            last_files.append (path);

        try {
            save_to_config ();
        } catch (Error e) {
            stderr.printf("%s\n", e.message);
        }
    }

    public void remove_last (string path) {
        unowned GLib.List<string>? item = last_files.find_custom (path, strcmp);
        assert (item != null);
        last_files.remove_link (item);

        try {
            save_to_config ();
        } catch (Error e) {
            stderr.printf("%s\n", e.message);
        }
    }

    public void reorder_last (string path, uint pos) {
        unowned GLib.List<string>? item = last_files.find_custom (path, strcmp);
        assert (item != null);
        last_files.remove_link (item);
        last_files.insert (path, (int) pos);

        try {
            save_to_config ();
        } catch (Error e) {
            stderr.printf("%s\n", e.message);
        }
    }

    private void write_last_node (Xml.TextWriter w) {
        w.start_element ("last");

        foreach (var it in last_files){
            w.write_element ("file", it);
        }

        w.end_element ();
    }

    private void read_last_node (Xml.Node* node) {
        unowned GLib.List<string>? item;
        for (Xml.Node* it = node->children; it != null; it = it->next) {
            if (it->type != Xml.ElementType.ELEMENT_NODE) {
                continue;
            }
            if (it->name == "file") {
                item = last_files.find_custom (it->get_content(), strcmp);
                if (item == null)
                    last_files.append (it->get_content());
            }
        }
    }
}
