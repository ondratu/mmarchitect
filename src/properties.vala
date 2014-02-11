// modules: Gtk

public class PropertiesWidgets : MapWidgets {
    public Gtk.Dialog dialog;

    // file side
    public Gtk.Entry author;


    public PropertiesWidgets () {}

    public override void loadui () throws Error {
        base.loadui();

        var builder = new Gtk.Builder ();
        builder.add_from_file (DATA + "/ui/properties.ui");
        builder.connect_signals (this);

        dialog = builder.get_object ("dialog") as Gtk.Dialog;

        author = builder.get_object ("author") as Gtk.Entry;

        var alignment_map = builder.get_object ("alignment_map") as Gtk.Alignment;
        alignment_map.add (box);
    }
}

public class Properties : GLib.Object {

    public unowned PropertiesWidgets pw;

    public string author;

    public uint rise_method;
    public uint points;
    public uint function;
    public bool rise_ideas;
    public bool rise_branches;

    public FilePreferences (Preferences pref) {
        load_from_preferences (pref);
    }

    public void load_from_preferences (Preferences pref) {
        author = pref.author;

        rise_method = pref.rise_method;
        points = pref.points;
        function = pref.function;
        rise_ideas = pref.rise_ideas;
        rise_branches = pref.rise_branches;
    }

    private void load_from_ui () {
        author = pw.author.get_text ();

        rise_method = pw.get_rise_method ();
        points = pw.get_idea_points ();
        function = pw.get_points_function ();
        rise_ideas = pw.get_rise_ideas ();
        rise_branches = pw.get_rise_branches ();
    }

    private void save_to_ui () {
        pw.author.set_text (author);

        pw.set_rise_method (rise_method);
        pw.set_idea_points (points);
        pw.set_points_function (function);
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
