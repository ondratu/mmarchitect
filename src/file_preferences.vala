// modules: Gtk

public class FilePreferenceWidgets : PreferenceMap {
    public Gtk.Dialog dialog;

    // file side
    public Gtk.Entry author;


    public FilePreferenceWidgets () {}

    public override void loadui () throws Error {
        base.loadui();

        var builder = new Gtk.Builder ();
        builder.add_from_file (DATA + "/ui/file_preferences.ui");
        builder.connect_signals (this);



        dialog = builder.get_object ("dialog") as Gtk.Dialog;
        var main_box = builder.get_object("main_box") as Gtk.HBox;
        main_box.pack_start(box);
    }
}

public class FilePreferences : GLib.Object {
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

}
