// modules: gtk+-3.0

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

        this.dialog = builder.get_object ("dialog") as Gtk.Dialog;

        this.author = builder.get_object ("author") as Gtk.Entry;
        this.created = builder.get_object ("label_created") as Gtk.Label;
        this.modified = builder.get_object ("label_modified") as Gtk.Label;
        this.filepath = builder.get_object ("label_path") as Gtk.Label;

        var frame_map = builder.get_object ("frame_map") as Gtk.Frame;
        frame_map.add (this.box);
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
        this.load_from_preferences (pref);
        time_t (out this.created);
        time_t (out this.modified);
    }

    public void load_from_preferences (Preferences pref) {
        this.author = pref.author;

        this.rise_method = pref.rise_method;
        this.rise_ideas = pref.rise_ideas;
        this.rise_branches = pref.rise_branches;
    }

    private void load_from_ui () {
        this.author = pw.author.get_text ();

        this.rise_method = pw.get_rise_method ();
        this.rise_ideas = pw.get_rise_ideas ();
        this.rise_branches = pw.get_rise_branches ();
    }

    private void save_to_ui () {
        this.pw.author.set_text (this.author);

        var c_created = ClaverTime (this.created);
        this.pw.created.set_text (c_created.to_string());

        var c_modified = ClaverTime (this.modified);
        this.pw.modified.set_text (c_modified.to_string());

        this.pw.filepath.set_text (this.filepath);

        this.pw.set_rise_method (this.rise_method);
        this.pw.set_rise_ideas (this.rise_ideas);
        this.pw.set_rise_branches (this.rise_branches);
    }

    public bool dialog (Gtk.Window parent) {
        if (this.pw != null) {
            stderr.printf("Preferences are open yet.\n");
            return false;
        }

        var pref_widgets = new PropertiesWidgets ();
        this.pw = pref_widgets;

        try {
            this.pw.loadui ();
            this.pw.dialog.set_transient_for (parent);
        } catch (Error e) {
            stderr.printf ("Could not load app UI: %s\n", e.message);
            return false;
        }

        this.save_to_ui();

        var retval = (this.pw.dialog.run() == 1);
        if (retval)
            this.load_from_ui ();

        this.pw.dialog.destroy();
        this.pw = null;

        return retval;
    }
}
