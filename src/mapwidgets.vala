// modules: gtk+-3.0
// sources: consts.vala

enum RisingMethod {
    DISABLE,                // not rising
    BRANCHES,               // rising by branches
    POINTS;                 // rising by points

    public static string to_string (uint i){
        switch (i) {
            case RisingMethod.DISABLE:
                return "DISABLE";
            case RisingMethod.POINTS:
                return "POINTS";
            case RisingMethod.BRANCHES:
            default:
                return "BRANCHES";
        }
    }

    public static uint parse (string s) {
        if (s == "DISABLE") {
            return RisingMethod.DISABLE;
        }
        if (s == "POINTS") {
            return RisingMethod.POINTS;
        }
        return RisingMethod.BRANCHES;
    }
}

public class MapWidgets: GLib.Object {
    public Gtk.RadioButton rise_method_disable;
    public Gtk.RadioButton rise_method_branches;
    public Gtk.RadioButton rise_method_points;
    public Gtk.CheckButton rise_ideas;
    public Gtk.CheckButton rise_branches;

    public Gtk.Box box;

    public virtual void loadui () throws Error {
        var builder = new Gtk.Builder ();
        builder.add_from_file (DATA_DIR + "/ui/map.ui");
        builder.connect_signals (this);

        rise_method_disable = (Gtk.RadioButton)
                builder.get_object ("rise_method_disable");
        rise_method_branches = (Gtk.RadioButton)
                builder.get_object ("rise_method_branches");
        rise_method_points = (Gtk.RadioButton)
                builder.get_object ("rise_method_points");
        rise_ideas = (Gtk.CheckButton)
                builder.get_object ("rise_ideas");
        rise_branches = (Gtk.CheckButton)
                builder.get_object ("rise_branches");

        box = (Gtk.Box) builder.get_object ("box_map");
    }

    public void set_rise_method (uint method) {
        if (method == RisingMethod.BRANCHES) {
            rise_method_branches.set_active (true);
        } else if (method == RisingMethod.POINTS) {
            rise_method_points.set_active (true);
        } else {        // RisingMethod.DISABLE
            rise_method_disable.set_active (true);
        }
    }

    public uint get_rise_method () {
        if (rise_method_branches.get_active ()) {
            return RisingMethod.BRANCHES;
        }
        if (rise_method_points.get_active ()) {
            return RisingMethod.POINTS;
        }
        return RisingMethod.DISABLE;
    }

    public void set_rise_ideas (bool state) {
        rise_ideas.set_active (state);
    }

    public bool get_rise_ideas () {
        return rise_ideas.get_active ();
    }

    public void set_rise_branches (bool state) {
        rise_branches.set_active (state);
    }

    public bool get_rise_branches () {
        return rise_branches.get_active ();
    }
}
