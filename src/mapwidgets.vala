// modules: gtk+-3.0

enum RisingMethod {
    DISABLE,                // not rising
    BRANCHES,               // rising by branches
    POINTS;                 // rising by points

    public static string to_string(uint i){
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

    public static uint parse(string s){
        if (s == "DISABLE")
            return RisingMethod.DISABLE;
        if (s == "POINTS")
            return RisingMethod.POINTS;
        else // BRANCHES and default
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
        builder.add_from_file (DATA + "/ui/map.ui");
        builder.connect_signals (this);

        this.rise_method_disable = builder.get_object("rise_method_disable")
                    as Gtk.RadioButton;
        this.rise_method_branches = builder.get_object("rise_method_branches")
                    as Gtk.RadioButton;
        this.rise_method_points = builder.get_object("rise_method_points")
                    as Gtk.RadioButton;
        this.rise_ideas = builder.get_object("rise_ideas") as Gtk.CheckButton;
        this.rise_branches = builder.get_object("rise_branches") as Gtk.CheckButton;

        this.box = builder.get_object("box_map") as Gtk.Box;
    }

    public void set_rise_method (uint method) {
        if (method == RisingMethod.BRANCHES)
            this.rise_method_branches.set_active (true);
        else if (method == RisingMethod.POINTS)
            this.rise_method_points.set_active (true);
        else        // RisingMethod.DISABLE
            this.rise_method_disable.set_active (true);
    }

    public uint get_rise_method () {
        if (this.rise_method_branches.get_active ())
            return RisingMethod.BRANCHES;
        if (this.rise_method_points.get_active ())
            return RisingMethod.POINTS;
        return RisingMethod.DISABLE;
    }

    public void set_rise_ideas (bool state) {
        this.rise_ideas.set_active (state);
    }

    public bool get_rise_ideas () {
        return this.rise_ideas.get_active ();
    }

    public void set_rise_branches (bool state) {
        this.rise_branches.set_active (state);
    }

    public bool get_rise_branches () {
        return this.rise_branches.get_active ();
    }
}
