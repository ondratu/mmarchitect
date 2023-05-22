// modules: gtk+-3.0
// sources: mapwidgets.vala preferences.vala

[GtkTemplate (ui = "/cz/zeropage/mmarchitect/properties.ui")]
public class PropertiesWidgets : Gtk.Dialog {
    public Gtk.Dialog dialog;

    // file side
    [GtkChild]
    public unowned Gtk.Entry author;
    [GtkChild]
    public unowned Gtk.Label created;
    [GtkChild]
    public unowned Gtk.Label modified;
    [GtkChild]
    public unowned Gtk.Label filepath;

    public MapWidgets box;

    [GtkChild]
    private unowned Gtk.Frame frame_map;

    public PropertiesWidgets () {
        box = new MapWidgets();
        frame_map.add (box);
    }
}

public class Properties : GLib.Object {

    public unowned PropertiesWidgets pw;

    public string author;
    public time_t created;
    public time_t modified;
    public string filepath;

    public uint rise_method;
    public bool rise_ideas;
    public bool rise_branches;

    public Properties (Preferences pref) {
        load_from_preferences (pref);
        time_t (out created);
        time_t (out modified);
    }

    public void load_from_preferences (Preferences pref) {
        author = pref.author;

        rise_method = pref.rise_method;
        rise_ideas = pref.rise_ideas;
        rise_branches = pref.rise_branches;
    }

    private void load_from_ui () {
        author = pw.author.get_text ();

        rise_method = pw.box.get_rise_method ();
        rise_ideas = pw.box.get_rise_ideas ();
        rise_branches = pw.box.get_rise_branches ();
    }

    private void save_to_ui () {
        pw.author.set_text (author);

        var c_created = ClaverTime (created);
        pw.created.set_text (c_created.to_string ());

        var c_modified = ClaverTime (modified);
        pw.modified.set_text (c_modified.to_string ());

        pw.filepath.set_text (filepath);

        pw.box.set_rise_method (rise_method);
        pw.box.set_rise_ideas (rise_ideas);
        pw.box.set_rise_branches (rise_branches);
    }

    public bool dialog (Gtk.Window parent) {
        if (pw != null) {
            stderr.printf ("Preferences are open yet.\n");
            return false;
        }

        var pref_widgets = new PropertiesWidgets ();
        pw = pref_widgets;

        pw.set_transient_for (parent);
        save_to_ui ();

        var retval = (pw.run () == 1);
        if (retval) {
            load_from_ui ();
        }

        pw.destroy ();
        pw = null;

        return retval;
    }
}
