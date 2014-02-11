// modules: Gtk

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

enum IdeaPoints {
    IGNORE,             // node points are ignore when chlidren have points
    MIX,                // node points are sumary with all children points
    REPLACE;            // node points are replace when children have poins

    public static string to_string(uint i){
        switch (i) {
            case IdeaPoints.MIX:
                return "MIX";
            case IdeaPoints.REPLACE:
                return "REPLACE";
            case IdeaPoints.IGNORE:
            default:
                return "IGNORE";
        }
    }

    public static uint parse(string s){
        if (s == "MIX")
            return IdeaPoints.MIX;
        if (s == "REPLACE")
            return IdeaPoints.REPLACE;
        else // IGNORE and default
            return IdeaPoints.IGNORE;
    }
}

public enum PointsFunction {
    SUM,
    AVG,
    MAX,
    MIN;

    public static string to_string(uint i) {
        switch (i) {
            case PointsFunction.MIN:
                return "MIN";
            case PointsFunction.MAX:
                return "MAX";
            case PointsFunction.AVG:
                return "AVG";
            case PointsFunction.SUM:
            default:
                return "SUM";
        }
    }

    public static uint parse(string s) {
        if (s == "MIN")
            return PointsFunction.MIN;
        if (s == "MAX")
            return PointsFunction.MAX;
        if (s == "AVG")
            return PointsFunction.AVG;
        else    // SUM is default
            return PointsFunction.SUM;
    }
}

public class MapWidgets: GLib.Object {
    public Gtk.RadioButton rise_method_disable;
    public Gtk.RadioButton rise_method_branches;
    public Gtk.RadioButton rise_method_points;
    public Gtk.RadioButton points_ignore;
    public Gtk.RadioButton points_mix;
    public Gtk.RadioButton points_replace;
    public Gtk.RadioButton function_sum;
    public Gtk.RadioButton function_avg;
    public Gtk.RadioButton function_max;
    public Gtk.RadioButton function_min;
    public Gtk.CheckButton rise_ideas;
    public Gtk.CheckButton rise_branches;

    public Gtk.Box box;

    public virtual void loadui () throws Error {
        var builder = new Gtk.Builder ();
        builder.add_from_file (DATA + "/ui/map.ui");
        builder.connect_signals (this);

        rise_method_disable = builder.get_object("rise_method_disable")
                    as Gtk.RadioButton;
        rise_method_branches = builder.get_object("rise_method_branches")
                    as Gtk.RadioButton;
        rise_method_points = builder.get_object("rise_method_points")
                    as Gtk.RadioButton;
        points_ignore = builder.get_object("points_ignore") as Gtk.RadioButton;
        points_mix = builder.get_object("points_mix") as Gtk.RadioButton;
        points_replace = builder.get_object("points_replace") as Gtk.RadioButton;
        function_sum = builder.get_object("function_sum") as Gtk.RadioButton;
        function_avg = builder.get_object("function_avg") as Gtk.RadioButton;
        function_min = builder.get_object("function_max") as Gtk.RadioButton;
        function_max = builder.get_object("function_min") as Gtk.RadioButton;
        rise_ideas = builder.get_object("rise_ideas") as Gtk.CheckButton;
        rise_branches = builder.get_object("rise_branches") as Gtk.CheckButton;

        box = builder.get_object("vbox_map") as Gtk.Box;
    }

    public void set_rise_method (uint method) {
        if (method == RisingMethod.BRANCHES)
            rise_method_branches.set_active (true);
        else if (method == RisingMethod.POINTS)
            rise_method_points.set_active (true);
        else        // RisingMethod.DISABLE
            rise_method_disable.set_active (true);
    }

    public uint get_rise_method () {
        if (rise_method_branches.get_active ())
            return RisingMethod.BRANCHES;
        if (rise_method_points.get_active ())
            return RisingMethod.POINTS;
        return RisingMethod.DISABLE;
    }

    public void set_idea_points (uint points) {
        if (points == IdeaPoints.MIX)
            points_mix.set_active (true);
        else if (points == IdeaPoints.REPLACE)
            points_replace.set_active (true);
        else        // IdeaPoints.IGNORE
            points_ignore.set_active (true);
    }

    public uint get_idea_points () {
        if (points_mix.get_active ())
            return IdeaPoints.MIX;
        if (points_replace.get_active ())
            return IdeaPoints.REPLACE;
        return IdeaPoints.IGNORE;
    }

    public void set_points_function (uint function) {
        if (function == PointsFunction.SUM)
            function_sum.set_active (true);
        else if (function == PointsFunction.AVG)
            function_avg.set_active (true);
        else if (function == PointsFunction.MAX)
            function_max.set_active (true);
        else        // PointsFunction.MIN
            function_min.set_active (true);
    }

    public uint get_points_function () {
        if (function_sum.get_active ())
            return PointsFunction.SUM;
        if (function_avg.get_active ())
            return PointsFunction.AVG;
        if (function_max.get_active ())
            return PointsFunction.MAX;
        return PointsFunction.MIN;
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
