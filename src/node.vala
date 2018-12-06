/*
 * DESCRIPTION      Node Class
 * PROJECT          Mind Map Architect
 * AUTHOR           Ondrej Tuma <mcbig@zeropage.cz>
 *
 * Copyright (C) Ondrej Tuma 2011
 * Code is present with BSD licence.
 */

// modules: Gtk

public enum Direction {
    LEFT,
    RIGHT,
    AUTO
}

public static string [] node_flags () {
    return { "done", "leave", "idea", "tip", "bomb", "question", "warning",
             "phone", "mail", "bug", "plan", "web", "yes", "no", "maybe",
             "mmarchitect",
             "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"};
}

public enum PointsFce {
    OWN,
    SUM,
    AVG,
    MIN,
    MAX;

    public static string to_string(int i) {
        switch (i) {
            case PointsFce.MAX:
                return "MAX";
            case PointsFce.MIN:
                return "MIN";
            case PointsFce.AVG:
                return "AVG";
            case PointsFce.SUM:
                return "SUM";
            case PointsFce.OWN:
            default:
                return "OWN";
        }
    }

    public static int parse(string s) {
        if (s == "MAX")
            return PointsFce.MAX;
        if (s == "MIN")
            return PointsFce.MIN;
        if (s == "AVG")
            return PointsFce.AVG;
        if (s == "SUM")
            return PointsFce.SUM;
        else    // OWN is default
            return PointsFce.OWN;
    }

    public static string [] labels () {
        return { "OWN", "SUM", "AVG", "MIN", "MAX"};
    }
    public static int [] values () {
        return { PointsFce.OWN, PointsFce.SUM, PointsFce.AVG, PointsFce.MIN,
                 PointsFce.MAX };
    }
}

public static string rgb_to_hex(Gdk.RGBA rgb) {
    uint8 red = (uint8) GLib.Math.rint(rgb.red * uint8.MAX);
    uint8 green = (uint8) GLib.Math.rint(rgb.green * uint8.MAX);
    uint8 blue = (uint8) GLib.Math.rint(rgb.blue * uint8.MAX);
    return "#" + red.to_string("%02x")
               + green.to_string("%02x")
               + blue.to_string("%02x");
}

public struct CoreNode {
    public string title;
    public uint direction;
    public bool is_expand;
    public double points;
    public int function;
    public bool default_color;
    public Gdk.RGBA rgb;

    public CoreNode () {
        is_expand = true;
        points = 0;
        function = PointsFce.OWN;
        default_color = true;
        rgb = Gdk.RGBA();
    }
}

public class Node : GLib.Object {

    public Gdk.Window window;
    public Node? parent;
    public MindMap ? map;
    public List<Node> children = new List<Node> ();
    private string _title;
    public string title {get {return _title;} }
    public string text = "";
    public uint direction;
    public double weight;
    public double points;
    public int function = PointsFce.OWN;
    public double fpoints {get; private set;}
    public string str_points {get; private set;}
    public Gdk.RGBA rgb;
    public Gdk.Rectangle area = Gdk.Rectangle();
    private int points_width;
    private int points_height;
    public Gdk.Rectangle full_left = Gdk.Rectangle();
    public Gdk.Rectangle full_right = Gdk.Rectangle();
    public Pango.FontDescription font_desc;
    public bool is_expand = true;
    public bool is_focus {get; private set; default = false; }
    public bool visible = true;
    public bool default_color;
    public Gee.HashSet<string> flags = new Gee.HashSet<string> ();

    private Node (string title, Node? parent = null,
            uint direction = Direction.AUTO)
    {
        this._title = title;
        this.parent = parent;

        // Direction set ...
        if (parent != null){                        // i have parent
            this.map = parent.map;
            this.rgb = parent.rgb;
            this.default_color = parent.default_color;

            if (parent.direction != Direction.AUTO) {   // parent is not root
                this.direction = parent.direction;
            } else if (direction != Direction.AUTO) { // parent is root, and direction is set
                this.direction = direction;
            } else {                                    // parent is root, and direction is not set
                this.direction =  parent.children.length() % 2;
                parent.zip();
            }
        } else {                                     // I'm root
            this.direction = Direction.AUTO;
            this.default_color = true;
            this.rgb = Gdk.RGBA();
        }
    }

    public Node.root (string title, MindMap map) {
        this (title);
        this.map = map;
        this.count_weight ();
        this.fce_on_points (false);
    }

    public Node copy () {
        var node = new Node (this.title, this.parent, this.direction);
        node.map = this.map;    // if it is copy of parrent
        node.text = this.text;
        node.points = this.points;
        node.function = this.function;
        foreach (var it in children) {
            var chld = it.copy ();
            chld.parent = node;
            node.children.append (chld);
        }

        foreach (var flag in this.flags) {
            node.flags.add (flag);
        }

        node.area = this.area;
        node.full_right = this.full_right;
        node.full_left = this.full_left;
        node.is_expand = this.is_expand;
        node.is_focus = false;      // is_focus must be fall in copy
        node.visible = this.visible;

        return node;
    }

    public Node add (string title = "", uint direction = Direction.AUTO,
            bool is_expand = true)
    {
        var child = new Node (title, this, direction);
        assert (child != null);
        child.is_expand = is_expand;
        if (this.window != null)
            child.realize(this.window);
        children.append (child);
        child.count_weight ();
        this.fce_on_points (false);
        return child;
    }

    public void paste (Node node) {
        node.parent = this;

        if (node.direction == Direction.AUTO && this.direction == Direction.AUTO)
            node.corect_direction (this.children.length() % 2);
        else if (this.direction != Direction.AUTO)
            node.corect_direction (this.direction);

        node.realize(this.window);
        this.children.append (node);
        node.count_weight (true);   // node could be from anoter map
        this.count_weight ();
        this.fce_on_points (true);
    }

    public Node insert(int pos){
        var child = new Node ("", this);
        assert (child != null);
        if (this.window != null) {
            child.realize(this.window);
        }
        this.children.insert(child, pos);
        child.count_weight ();
        this.fce_on_points (true);
        return child;
    }

    public static void remove (Node node) {
        if (node.parent == null) {
            return;
        }
        var parent = node.parent;
        parent.children.remove(node);
        parent.count_weight ();
        parent.fce_on_points (false);
    }

    private void fce_on_points (bool down) {
        if (down) {             // to children
            foreach (var it in children) {
                it.fce_on_points (down);
            }
        }

        if (function == PointsFce.OWN) {
            this.fpoints = this.points;
        } else {
            // start on second children, for right MIN fce
            uint len = this.children.length();
            this.fpoints = (len > 0) ? this.children.nth_data(0).fpoints : 0;
            for (int i = 1; i < len; i++) {
                var chfp = this.children.nth_data(i).fpoints;
                switch (this.function) {
                    case PointsFce.SUM:
                    case PointsFce.AVG:
                        this.fpoints += chfp;
                        break;
                    case PointsFce.MAX:
                        this.fpoints = (chfp > this.fpoints) ? chfp : this.fpoints;
                        break;
                    case PointsFce.MIN:
                        this.fpoints = (chfp < this.fpoints) ? chfp : this.fpoints;
                        break;
                }
            }

            if (function == PointsFce.AVG) {
                this.fpoints = this.fpoints / len;
            }
        }

        // call count_children_points on parent
        if (parent != null && !down)    // to parent
            parent.fce_on_points (down);

        if (window != null)
            set_size_request();
    }

    private void count_weight_by_branches (bool down) {
        this.weight = 1;
        if (!down) {        // to parent way
            foreach (var it in this.children) {
                this.weight += it.weight;
            }

            if (this.parent != null)
                this.parent.count_weight_by_branches (down);
        } else {            // to children
            foreach (var it in this.children) {
                it.count_weight_by_branches (down);
                this.weight += it.weight;
            }
        }

        if (this.window != null)
            set_size_request();
    }

    private void count_weight_by_points (bool down) {
        if (down) {             // to children
            foreach (var it in this.children)
                it.count_weight_by_points (down);
        }

        if (this.function == PointsFce.OWN) {
            this.weight = this.points;
        } else if (this.children.length() == 0) {
            this.weight = 0;
        } else {
            foreach (var it in children) {
                switch (this.function) {
                    case PointsFce.SUM:
                    case PointsFce.AVG:
                        this.weight += it.weight;
                        break;
                    case PointsFce.MAX:
                        this.weight = (it.weight > this.weight) ? it.weight : this.weight;
                        break;
                    case PointsFce.MIN:
                        this.weight = (it.weight < this.weight) ? it.weight : this.weight;
                        break;
                }
            }

            if (this.function == PointsFce.AVG) {
                this.weight = this.weight / this.children.length ();
            }
        }

        // call count_children_points on parent
        if (this.parent != null && !down)    // to parent
            this.parent.count_weight_by_points (down);

        if (this.window != null)
            set_size_request();
    }

    private void count_weight_disabled (bool down) {
        this.weight = 0;
        if (!down){
            if (this.parent != null)
                this.parent.count_weight_disabled (down);
        } else {
            foreach (var it in this.children) {
                it.count_weight_disabled (down);
            }
        }

        if (this.window != null)
            this.set_size_request();
    }

    public void count_weight (bool down = false) {
        assert (this.map != null);
        switch (this.map.prop.rise_method) {
            case RisingMethod.BRANCHES:
                this.count_weight_by_branches (down);
                break;
            case RisingMethod.POINTS:
                this.count_weight_by_points (down);
                break;
            case RisingMethod.DISABLE:
            default:
                this.count_weight_disabled (down);
                break;
        }
    }

    // sort child with zip right on direction
    public void zip () {
        bool direction = false;
        uint len = this.children.length();
        for (int i = 0; i < len;){
            var a = this.children.nth_data(i);
            // direction is right cik cak
            if (a.direction == (uint) direction){
                direction = !direction;
                i++;
                continue;
            }

            // find node with right cik cak direction
            int l;
            for (l = i+1; l < len; l++){
                var b = this.children.nth_data(l);
                if (b.direction == (uint) direction) {
                    this.children.remove(b);
                    this.children.insert(b,i);
                    direction = !direction;
                    i++;
                    break;
                }
            }

            // if threre is no other children, stop
            if (l == len)
                return;
        }
    }

    public void move_up () {
        if (this.parent == null)
            return;

        int pos = this.get_position();
        if (pos == 0)
            return;

        if (this.parent.parent != null) { // not child of root
            this.parent.children.remove(this);
            this.parent.children.insert(this, pos - 1);
        } else {
            for (int i = pos - 1; i >= 0; i--){
                var node = this.parent.children.nth_data(i);
                if (node.direction == this.direction) {
                    this.parent.children.remove(this);
                    this.parent.children.insert(this, i);
                    this.parent.zip();
                    return;
                }
            }
        }
    }

    public void move_down () {
        if (this.parent == null)
            return;

        int pos = this.get_position();
        uint len = this.parent.children.length();

        if (pos == len - 1)
            return;

        if (this.parent.parent != null) { // not child of root
            this.parent.children.remove(this);
            this.parent.children.insert(this, pos + 1);
        } else {
            for (int i = pos + 1; i < len; i++){
                var node = this.parent.children.nth_data(i);
                if (node.direction == this.direction) {
                    this.parent.children.remove(this);
                    this.parent.children.insert(this, i);
                    this.parent.zip();
                    return;
                }
            }
        }
    }

    public void move_left () {
        if (parent == null) return;

        // not right child of root
        if (!(this.parent.parent == null && this.direction == Direction.RIGHT)) {
            Node new_parent;
            if (this.direction == Direction.LEFT){
                int pos = this.get_position();
                if (pos > 0)
                    new_parent = this.get_prev(Direction.LEFT);
                else if (pos +1 < this.parent.children.length())
                    new_parent = this.get_next(Direction.LEFT);
                else
                    return;

                this.parent.children.remove(this);
                new_parent.paste(this);
            } else {            // Direction.RIGHT
                new_parent = this.parent.parent;
                this.parent.children.remove(this);
                new_parent.children.insert(this, this.parent.get_position() +1);
                this.parent = new_parent;
                this.parent.zip();
            }
        } else {
            int pos = this.get_position();
            if (pos > 0){
                this.parent.children.remove(this);
                this.parent.children.insert(this, pos -1);
            }
            this.corect_direction(Direction.LEFT);
            this.parent.zip();
        }
    }

    public void move_right () {
        if (parent == null) return;

        // not left child of root
        if (!(this.parent.parent == null && this.direction == Direction.LEFT)) {
            Node new_parent;
            if (this.direction == Direction.RIGHT){
                int pos = this.get_position();
                if (pos > 0)
                    new_parent = get_prev(Direction.RIGHT);
                else if (pos +1 < parent.children.length())
                    new_parent = get_next(Direction.RIGHT);
                else
                    return;

                parent.children.remove(this);
                new_parent.paste(this);
            } else {            // Direction.RIGHT
                new_parent = parent.parent;
                parent.children.remove(this);
                new_parent.children.insert(this, parent.get_position() +1);
                this.parent = new_parent;
                this.parent.zip();
            }
        } else {
            corect_direction(Direction.RIGHT);
            parent.zip();
        }
    }

    public Node? get_next(uint direction = Direction.AUTO) {
        uint len = parent.children.length();
        for (int i = get_position()+1; i < len; i++) {
            var node = parent.children.nth_data(i);
            if (direction == Direction.AUTO || node.direction == direction)
                return node;
        }
        return null;
    }

    public Node? get_prev(uint direction = Direction.AUTO) {
        for (int i = get_position()-1; i >= 0; i--) {
            var node = parent.children.nth_data(i);
            if (direction == Direction.AUTO || node.direction == direction)
                return node;
        }
        return null;
    }

    public void realize (Gdk.Window window) {
        assert (window != null);

        this.window = window;
        if (this.default_color)
            this.rgb = map.pref.default_color;

        get_size_request (out area.width, out area.height);
        foreach (var child in children) {
            child.realize (window);
        }
    }

    public int get_position (){
        return parent.children.index(this);
    }

    public void set_focus(bool is_focus){
        this.is_focus = is_focus;
    }

    public bool change_expand () {
        if (parent == null)                 // parent can't be close
            return false;
        if (children.length() == 0)         // no children means expand = True
            return false;

        is_expand = ! is_expand;
        return true;
    }
    public void expand () {
        is_expand = true;
    }
    public void collapse () {
        is_expand = false;
    }

    public void expand_all () {
        is_expand = true;
        foreach (var it in children)
            it.expand_all ();
    }

    public void collapse_all () {
        is_expand = false;
        foreach (var it in children)
            it.collapse_all ();
    }

    public void get_size_request (out int width, out int height) {
        var cr = new Cairo.Context (new Cairo.ImageSurface (Cairo.Format.A1, 0, 0));
        var la = Pango.cairo_create_layout (cr);

        font_desc = map.pref.node_font.copy();

        var font_size = font_desc.get_size()
                        * (1 + (weight / map.pref.font_rise)) * (map.pref.dpi / 100.0);
        font_desc.set_size((int) font_size);

        la.set_font_description(font_desc);
        la.set_text((title.length > 0) ? title : NONE_TITLE, -1);

        int t_width, t_height;
        la.get_size (out t_width, out t_height);
        width = (int) GLib.Math.lrint ( (title.length > 0) ?
                (t_width / Pango.SCALE) + map.pref.font_padding * 8 :
                NONE_TITLE.length * (int) (font_size / Pango.SCALE)
                                            + map.pref.font_padding * 2 + ICO_SIZE);
        height = (int) GLib.Math.lrint ((t_height / Pango.SCALE) + map.pref.font_padding * 2);

        if (text.length > 0)            // if there is text, icon is visible
            width += ICO_SIZE + 1;

        width += (ICO_SIZE + 1) * this.flags.size;

        // if there are points or function, thay are visible
        if (fpoints != 0 || function != PointsFce.OWN) {
            str_points = "%1g".printf(fpoints);

            var tmp_font = font_desc.copy();
            tmp_font.set_size((int) GLib.Math.lrint (font_desc.get_size() * 0.7));

            la.set_font_description(tmp_font);
            la.set_text(str_points, -1);
            la.get_size (out t_width, out t_height);

            points_width = (int) GLib.Math.lrint (
                                (t_width / Pango.SCALE) + map.pref.font_padding * 6);
            points_height = (int) GLib.Math.lrint (height * 0.7);

            width += points_width;
        } else {
            points_width = 0;
            points_height = 0;
        }
    }

    public void set_size_request (bool recursive = false) {
        get_size_request (out area.width, out area.height);
        if (!recursive)
            return;
        foreach (var node in children){
            node.set_size_request(true);
        }
    }

    private void corect_direction (uint direction) {
        if (direction == Direction.AUTO) {
            this.direction =  parent.children.length() % 2;
            parent.zip();
        } else
            this.direction = direction;
        foreach (var it in children)
            it.corect_direction (direction);
    }

    private void corect_y (int fix) {
        area.y += fix;
        foreach (var node in children){
            node.corect_y(fix);
        }
    }

    public void set_rgb (Gdk.RGBA rgb) {
        foreach (var node in children){
            if (node.rgb.equal(this.rgb))
                node.set_rgb(rgb);
        }
        this.rgb = rgb;
        this.default_color = false;
    }

    public int set_position (int left, int top) {
        area.x = left;
        area.y = top;

        full_left.width = area.width;
        full_right.width = area.width;
        full_left.height = area.height + map.pref.height_padding;
        full_right.height = area.height + map.pref.height_padding;

        int leftjmp = 0;
        int rightjmp = 0;

        uint len = children.length();
        if (is_expand && len > 0) {
            for (int i = 0; i < len; i++) {
                var node = children.nth_data (i);
                assert (node.direction != Direction.AUTO);

                // this is right orientation from top
                if (node.direction == Direction.RIGHT) {
                    if (i > 0)
                        rightjmp += node.set_position (area.x + area.width + map.pref.width_padding,
                                        area.y + rightjmp);
                    else
                        rightjmp += node.set_position (area.x + area.width + map.pref.width_padding,
                                        area.y + i * (area.height + map.pref.height_padding));

                    int full_width = node.area.x - area.x + node.full_right.width;
                    full_right.width = (full_right.width < full_width) ? full_width : full_right.width;
                    full_right.height += node.full_right.height;

                } else {
                    if (i > 0)
                        leftjmp += node.set_position (area.x - node.area.width - map.pref.width_padding,
                                        area.y + leftjmp);
                    else
                        leftjmp += node.set_position (area.x - node.area.width - map.pref.width_padding,
                                        area.y + i * (area.height + map.pref.height_padding));

                    int full_width = ((node.area.x + node.area.width) - (area.x + area.width)).abs()  + node.full_left.width;
                    full_left.width = (full_left.width < full_width) ? full_width : full_left.width;
                    full_left.height += node.full_left.height;
                }
            }

            if (full_right.height > area.height)
                full_right.height -= area.height + map.pref.height_padding;
            if (full_left.height > area.height)
                full_left.height -= area.height + map.pref.height_padding;

            if (parent == null){
                full_left.width -= area.width;
                full_left.height -= map.pref.height_padding;
                full_right.height -= map.pref.height_padding;
                // TODO: posun mensiho bloku o pulku rozdilu niz
                // y axis correction
                int dist = (full_left.height - full_right.height).abs() / 2;
                uint dir;
                if (full_left.height > full_right.height)
                    dir = Direction.RIGHT;
                else
                    dir = Direction.LEFT;

                foreach (var node in children)
                    if (node.direction == dir) node.corect_y (dist);
            }

            int jmp = (rightjmp > leftjmp) ? rightjmp : leftjmp;
            area.y = area.y + jmp / 2 - (area.height + map.pref.height_padding)/ 2;
            return jmp;
        }

        return area.height + map.pref.height_padding;
    }

    public int get_higher_full () {
        return (full_left.height > full_right.height) ? full_left.height : full_right.height;
    }

    public void draw_rectangle (Cairo.Context cr, Gdk.Rectangle area,
            double r = 10)
    {
        // code copy from http://cairographics.org/cookbook/roundedrectangles/
        // this is Method C
        cr.move_to(area.x + r, area.y);
        cr.line_to(area.x + area.width - r, area.y);
        cr.curve_to(area.x + area.width, area.y,
                    area.x + area.width, area.y,
                    area.x + area.width, area.y + r);
        cr.line_to(area.x + area.width, area.y + area.height - r);
        cr.curve_to(area.x + area.width, area.y + area.height,
                    area.x + area.width, area.y + area.height,
                    area.x + area.width - r, area.y + area.height);
        cr.line_to(area.x + r, area.y + area.height);
        cr.curve_to(area.x, area.y + area.height,
                    area.x, area.y + area.height,
                    area.x, area.y + area.height - r);
        cr.line_to(area.x, area.y + r);
        cr.curve_to(area.x, area.y, area.x, area.y,
                    area.x + r, area.y);
        cr.close_path();
    }

    public void draw (Cairo.Context cr) {
        cr.set_line_width (0.7);

        // roundable rectangle
        if (fpoints != 0 || function != PointsFce.OWN) {
            var t_area = Gdk.Rectangle() {
                width = area.width - points_width,
                height = area.height,
                x = area.x,
                y = area.y
            };
            draw_rectangle (cr, t_area, (area.height / 2) + 2);

            t_area = Gdk.Rectangle() {
                width = points_width,
                height = points_height,
                x = area.x + area.width - points_width,
                y = area.y + (int) GLib.Math.lrint ( (area.height - points_height) / 2)
            };
            draw_rectangle (cr, t_area, (t_area.height / 2) + 2);
        } else
            draw_rectangle (cr, area, (area.height / 2) + 2);

        if (is_focus){
            Gdk.cairo_set_source_rgba (cr, map.pref.back_selected);
        } else
            Gdk.cairo_set_source_rgba (cr, map.pref.back_normal);

        cr.fill_preserve();

        if (default_color)
            Gdk.cairo_set_source_rgba (cr, map.pref.default_color);
        else
            Gdk.cairo_set_source_rgba (cr, rgb);

        cr.stroke ();

        var flags_padding = (ICO_SIZE + 1) * this.flags.size;

        // text
        if (title.length > 0){
            if (is_focus)
                Gdk.cairo_set_source_rgba (cr, map.pref.text_selected);
            else
                Gdk.cairo_set_source_rgba (cr, map.pref.text_normal);
            cr.move_to (area.x + flags_padding + map.pref.font_padding * 4,
                        area.y + map.pref.font_padding);

            var la = Pango.cairo_create_layout (cr);
            la.set_font_description(font_desc);
            la.set_text(title, -1);
            Pango.cairo_show_layout (cr, la);
        }

        if (fpoints != 0 || function != PointsFce.OWN) {
            cr.move_to (area.x + area.width - points_width + 2,
                        area.y + map.pref.font_padding + (int) GLib.Math.lrint (
                                            (area.height - points_height) / 2) );

            var la = Pango.cairo_create_layout (cr);
            var tmp_font = font_desc.copy();
            tmp_font.set_size((int) GLib.Math.lrint (font_desc.get_size() * 0.7));

            la.set_font_description(tmp_font);
            la.set_text(str_points, -1);
            Pango.cairo_show_layout (cr, la);
        }

        if (text.length > 0) {
            try {
                Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default ();
                var ico = icon_theme.load_surface ("text-editor-symbolic",
                                                   ICO_SIZE, 1, null, 0);
                cr.set_source_surface (ico,
                        area.x + area.width - ICO_SIZE - 2 - points_width,
                        area.y + (area.height - ICO_SIZE) /2 );
            } catch (Error e){}
            cr.paint ();
        }

        // flag icons
        int f = 0;
        foreach (var flag in this.flags) {
            int ico_padding = (ICO_SIZE + 1) * f;
            set_source_svg (cr, DATA_DIR + "/icons/" + flag + ".svg",
                    area.x + ico_padding,
                    area.y + (area.height - ICO_SIZE) /2,
                    ICO_SIZE, ICO_SIZE);
            cr.paint ();
            f++;
        }

        // draw line to parent
        if (parent != null) {
            cr.set_line_width (0.7 * (1 + (weight / map.pref.line_rise)));

            if (default_color)
                Gdk.cairo_set_source_rgba (cr, map.pref.default_color);
            else
                Gdk.cairo_set_source_rgba (cr, rgb);

            // TODO: draw technique could be set
            if (direction == Direction.RIGHT) {
                double nx = area.x;
                double ny = area.y + area.height / 2;
                double px = parent.area.x + parent.area.width;
                double py = parent.area.y + parent.area.height / 2;
                /*
                cr.move_to (area.x, area.y + area.height / 2);
                cr.line_to (parent.area.x + parent.area.width,
                            parent.area.y + parent.area.height / 2);
                */
                cr.move_to (px, py);
                cr.curve_to (px + map.pref.width_padding / 1.5, py,
                             nx - map.pref.width_padding / 1.5, ny,
                             nx, ny);
            } else {
                double nx = area.x + area.width;
                double ny = area.y + area.height / 2;
                double px = parent.area.x;
                double py = parent.area.y + parent.area.height / 2;
                /*
                cr.move_to (area.x + area.width, area.y + area.height / 2);
                cr.line_to (parent.area.x,
                            parent.area.y + parent.area.height / 2);
                */
                cr.move_to (nx, ny);
                cr.curve_to (nx + map.pref.width_padding / 1.5, ny,
                             px - map.pref.width_padding / 1.5, py,
                             px, py);
            }
            cr.stroke ();
        }
    }

    public void draw_expander (Cairo.Context cr) {
        if (parent == null)             // root can't be closed
            return;

        var earea = Gdk.Rectangle() {
            width = 6,
            height = 6,
            y = area.y + area.height / 2 - 3
        };

        if (direction == Direction.RIGHT) {
            earea.x = area.x + area.width - 3;
        } else if (direction == Direction.LEFT) {
            earea.x = area.x - 3;
        }

        draw_rectangle (cr, earea, 2);
        cr.set_source_rgb (1, 1, 1);
        cr.fill_preserve();
        cr.set_source_rgb (0.5, 0.5, 0.5);
        cr.stroke();
    }

    public void draw_tree (Cairo.Context cr) {
        draw (cr);

        if (children.length() > 0) {
            if (is_expand) {
                foreach (var node in children)
                    node.draw_tree (cr);
            } else {
                draw_expander (cr);
            }
        }
    }

    public void set_title (string title) {
        this._title = title.strip();
        get_size_request (out area.width, out area.height);
    }

    public void set_text (string text) {
        this.text = text.strip();
        get_size_request (out area.width, out area.height);
    }

    public void set_points (double points, int function) {
        this.points = points;
        this.function = function;
        fce_on_points (false);
        if (map.prop.rise_method == RisingMethod.POINTS)
            count_weight_by_points (false);
        get_size_request (out area.width, out area.height);
    }

    public unowned Node? event_on (double x, double y) {
        if (x >= area.x && x <= (area.x + area.width) &&
                y >= area.y && y <= (area.y + area.height))
        {
            return this;
        } else {
            unowned Node? unode;
            foreach (var node in children) {
                unode = node.event_on (x, y);
                if (unode != null)
                    return unode;
            }
            return null;
        }
    }
}
