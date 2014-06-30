// modules: Gtk

public class PropertiesWidgets : MapWidgets {
    public Gtk.Dialog dialog;

    // file side
    public Gtk.Entry author;
    public Gtk.Label created;
    public Gtk.Label modified;
    public Gtk.Label filepath;

    public PropertiesWidgets () {}

    public override void loadui () throws Error {
        base.loadui();

        var builder = new Gtk.Builder ();
        builder.add_from_file (DATA + "/ui/properties.ui");
        builder.connect_signals (this);

        dialog = builder.get_object ("dialog") as Gtk.Dialog;

        author = builder.get_object ("author") as Gtk.Entry;
        created = builder.get_object ("label_created") as Gtk.Label;
        modified = builder.get_object ("label_modified") as Gtk.Label;
        filepath = builder.get_object ("label_path") as Gtk.Label;

        var alignment_map = builder.get_object ("alignment_map") as Gtk.Alignment;
        alignment_map.add (box);
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
        time_t (out this.created);
        time_t (out this.modified);
    }

    public void load_from_preferences (Preferences pref) {
        author = pref.author;

        rise_method = pref.rise_method;
        rise_ideas = pref.rise_ideas;
        rise_branches = pref.rise_branches;
    }

    private void load_from_ui () {
        author = pw.author.get_text ();

        rise_method = pw.get_rise_method ();
        rise_ideas = pw.get_rise_ideas ();
        rise_branches = pw.get_rise_branches ();
    }

    private void save_to_ui () {
        pw.author.set_text (author);

        var c_created = ClaverTime (created);
        pw.created.set_text (c_created.to_string());

        var c_modified = ClaverTime (modified);
        pw.modified.set_text (c_modified.to_string());

        pw.filepath.set_text (filepath);

        pw.set_rise_method (rise_method);
        pw.set_rise_ideas (rise_ideas);
        pw.set_rise_branches (rise_branches);
    }

    public bool dialog () {
        if (pw != null) {
            stderr.printf("Preferences are open yet.\n");
            return false;
        }

        var pref_widgets = new PropertiesWidgets ();
        pw = pref_widgets;

        try {
            pw.loadui ();
        } catch (Error e) {
            stderr.printf ("Could not load app UI: %s\n", e.message);
            return false;
        }

        save_to_ui();

        var retval = (pw.dialog.run() == 1);
        if (retval)
            load_from_ui ();

        pw.dialog.destroy();
        pw = null;

        return retval;
    }
}
