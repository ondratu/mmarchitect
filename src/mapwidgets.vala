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

[GtkTemplate (ui = "/cz/zeropage/mmarchitect/map.ui")]
public class MapWidgets: Gtk.Box {
    [GtkChild]
    public unowned Gtk.RadioButton rise_method_disable;
    [GtkChild]
    public unowned Gtk.RadioButton rise_method_branches;
    [GtkChild]
    public unowned Gtk.RadioButton rise_method_points;
    [GtkChild]
    public unowned Gtk.CheckButton rise_ideas;
    [GtkChild]
    public unowned Gtk.CheckButton rise_branches;

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
