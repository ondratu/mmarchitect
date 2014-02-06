/*
 * DESCRIPTION      Node Class
 * PROJECT          Mind Map Architect
 * AUTHOR           Ondrej Tuma <mcbig@zeropage.cz>
 *
 * Copyright (C) Ondrej Tuma 2011
 * Code is present with BSD licence.
 */

// modules: Gtk

enum Direction {
    LEFT,
    RIGHT,
    AUTO
}

public struct CoreNode {
    public string title;
    public uint direction;
    public bool is_expand;
    public double points;
    public bool default_color;
    public Gdk.Color color;

    public CoreNode () {
        is_expand = true;
        points = 0;
        default_color = true;
        color = Gdk.Color();
    }
}

public class Node : GLib.Object {

    public Gdk.Drawable window;
    public Node? parent;
    public List<Node> children;
    private string _title;
    public string title {get {return _title;}}
    public string text;
    public uint direction;
    public uint weight;
    public double points;
    public string str_points {get; private set;}
    public Gdk.Color color;

    public Gdk.Rectangle area;
    private int points_width;
    private int points_height;
    public Gdk.Rectangle full_left;
    public Gdk.Rectangle full_right;
    public Preferences pref;
    public Pango.FontDescription font_desc;
    public bool is_expand;
    public bool is_focus {get; private set;}
    public bool visible;
    public bool default_color;

    public Node (string title, Node? parent = null,
            uint direction = Direction.AUTO)
    {
        this.text = "";
        this._title = title;
        this.parent = parent;
        this.weight = 1;

        var it = parent;
        while (it != null) {                        // count parent's weight
            it.weight += 1;
            if (it.window != null)
                it.set_size_request();
            it = it.parent;
        }

        // Direction set ...
        if (parent != null){                        // i have parent
            this.color = parent.color;
            this.default_color = parent.default_color;

            if (parent.direction != Direction.AUTO) // parent is not root
                this.direction = parent.direction;
            else if (direction != Direction.AUTO)   // parent is root, and direction is set
                this.direction = direction;
            else {                                   // parent is root, and direction is not set
                this.direction =  parent.children.length() % 2;
                parent.zip();
            }
        } else {                                    // I'm root
            this.direction = Direction.AUTO;
            this.default_color = true;
            this.color = Gdk.Color();
        }

        this.children = new List<Node> ();

        this.area = Gdk.Rectangle();
        this.full_right = Gdk.Rectangle();
        this.full_left = Gdk.Rectangle();

        this.is_expand = true;
        this.is_focus = false;
        this.visible = true;
    }

    public Node copy () {
        var node = new Node (title, parent, direction);
        node.text = text;
        node.points = points;
        foreach (var it in children) {
            var chld = it.copy();
            chld.parent = node;
            node.children.append (chld);
        }

        node.area = area;
        node.full_right = full_right;
        node.full_left = full_left;
        node.is_expand = is_expand;
        node.is_focus = false;      // is_focus must be fall in copy
        node.visible = visible;

        return node;
    }

    public Node add (string title = "", uint direction = Direction.AUTO,
            bool is_expand = true)
    {
        var child = new Node (title, this, direction);
        assert (child != null);
        child.is_expand = is_expand;
        if (this.window != null)
            child.realize(this.window, pref);
        children.append (child);
        return child;
    }

    public void paste (Node node) {
        node.parent = this;

        if (node.direction == Direction.AUTO && direction == Direction.AUTO)
            node.corect_direction (children.length() % 2);
        else if (direction != Direction.AUTO)
            node.corect_direction (direction);

        node.realize(this.window, pref);
        children.append (node);
    }

    public Node insert(int pos){
        var child = new Node ("", this);
        assert (child != null);
        if (this.window != null)
            child.realize(this.window, pref);
        children.insert(child, pos);
        return child;
    }

    public static void remove (Node node) {
        if (node.parent == null)
            return;
        var parent = node.parent;
        parent.children.remove(node);
    }

    // sort child with zip right on direction
    public void zip () {
        bool direction = false;
        uint len = children.length();
        for (int i = 0; i < len;){
            var a = children.nth_data(i);
            // direction is right cik cak
            if (a.direction == (uint) direction){
                direction = !direction;
                i++;
                continue;
            }

            // find node with right cik cak direction
            int l;
            for (l = i+1; l < len; l++){
                var b = children.nth_data(l);
                if (b.direction == (uint) direction) {
                    children.remove(b);
                    children.insert(b,i);
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
        if (parent == null)
            return;

        int pos = get_position();
        if (pos == 0)
            return;

        if (parent.parent != null) { // not child of root
            parent.children.remove(this);
            parent.children.insert(this, pos - 1);
        } else {
            for (int i = pos - 1; i >= 0; i--){
                var node = parent.children.nth_data(i);
                if (node.direction == this.direction) {
                    parent.children.remove(this);
                    parent.children.insert(this, i);
                    parent.zip();
                    return;
                }
            }
        }
    }

    public void move_down () {
        if (parent == null)
            return;

        int pos = get_position();
        uint len = parent.children.length();

        if (pos == len - 1)
            return;

        if (parent.parent != null) { // not child of root
            parent.children.remove(this);
            parent.children.insert(this, pos + 1);
        } else {
            for (int i = pos + 1; i < len; i++){
                var node = parent.children.nth_data(i);
                if (node.direction == this.direction) {
                    parent.children.remove(this);
                    parent.children.insert(this, i);
                    parent.zip();
                    return;
                }
            }
        }
    }

    public void move_left () {
        if (parent == null) return;

        // not right child of root
        if (!(parent.parent == null && this.direction == Direction.RIGHT)) {
            Node new_parent;
            if (this.direction == Direction.LEFT){
                int pos = get_position();
                if (pos > 0)
                    new_parent = get_prev(Direction.LEFT);
                else if (pos +1 < parent.children.length())
                    new_parent = get_next(Direction.LEFT);
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
            int pos = get_position();
            if (pos > 0){
                parent.children.remove(this);
                parent.children.insert(this, pos -1);
            }
            corect_direction(Direction.LEFT);
            parent.zip();
        }
    }

    public void move_right () {
        if (parent == null) return;

        // not left child of root
        if (!(parent.parent == null && this.direction == Direction.LEFT)) {
            Node new_parent;
            if (this.direction == Direction.RIGHT){
                int pos = get_position();
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

    public void realize (Gdk.Drawable window, Preferences pref) {
        assert (window != null);
        assert (pref != null);

        this.window = window;
        this.pref = pref;
        if (this.default_color)
            this.color = pref.default_color;

        get_size_request (out area.width, out area.height);
        foreach (var child in children) {
            child.realize (window, pref);
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
        var cr = Gdk.cairo_create (this.window);
        var la = Pango.cairo_create_layout (cr);

        font_desc = pref.node_font.copy();

        var font_size = font_desc.get_size()
                        * (1 + (weight / pref.font_rise)) * (pref.dpi / 100.0);
        font_desc.set_size((int) font_size);

        la.set_font_description(font_desc);
        la.set_text((title.length > 0) ? title : NONE_TITLE, -1);

        int t_width, t_height;
        la.get_size (out t_width, out t_height);
        width = (int) GLib.Math.lrint ( (title.length > 0) ?
                (t_width / Pango.SCALE) + pref.font_padding * 8 :
                NONE_TITLE.length * (int) (font_size / Pango.SCALE)
                                            + pref.font_padding * 2 + ICO_SIZE);
        height = (int) GLib.Math.lrint ((t_height / Pango.SCALE) + pref.font_padding * 2);

        if (text.length > 0)            // if there is text, icon is visible
            width += ICO_SIZE + 1;

        // points area
        if (points != 0) {              // if there are points, thay are visible
            str_points = "%1g".printf(points);
            var tmp_font = pref.node_font.copy();
            font_size = font_desc.get_size()
                        * (1 + (weight / pref.font_rise)) * (pref.dpi / 100.0);
            tmp_font.set_size((int) font_size - 2);

            la.set_font_description(tmp_font);
            la.set_text(str_points, -1);
            la.get_size (out t_width, out t_height);

            points_width = (int) GLib.Math.lrint (
                                ((t_width / Pango.SCALE) + pref.font_padding * 6) * 0.8);
            points_height = (int) GLib.Math.lrint (height * 0.8);

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

    public void set_color (Gdk.Color color) {
        foreach (var node in children){
            if (node.color.equal(this.color))
                node.set_color(color);
        }
        this.color = color;
        this.default_color = false;
    }

    public int set_position (int left, int top) {
        assert (pref != null);

        area.x = left;
        area.y = top;

        full_left.width = area.width;
        full_right.width = area.width;
        full_left.height = area.height + pref.height_padding;
        full_right.height = area.height + pref.height_padding;

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
                        rightjmp += node.set_position (area.x + area.width + pref.width_padding,
                                        area.y + rightjmp);
                    else
                        rightjmp += node.set_position (area.x + area.width + pref.width_padding,
                                        area.y + i * (area.height + pref.height_padding));

                    int full_width = node.area.x - area.x + node.full_right.width;
                    full_right.width = (full_right.width < full_width) ? full_width : full_right.width;
                    full_right.height += node.full_right.height;

                } else {
                    if (i > 0)
                        leftjmp += node.set_position (area.x - node.area.width - pref.width_padding,
                                        area.y + leftjmp);
                    else
                        leftjmp += node.set_position (area.x - node.area.width - pref.width_padding,
                                        area.y + i * (area.height + pref.height_padding));

                    int full_width = ((node.area.x + node.area.width) - (area.x + area.width)).abs()  + node.full_left.width;
                    full_left.width = (full_left.width < full_width) ? full_width : full_left.width;
                    full_left.height += node.full_left.height;
                }
            }

            if (full_right.height > area.height)
                full_right.height -= area.height + pref.height_padding;
            if (full_left.height > area.height)
                full_left.height -= area.height + pref.height_padding;

            if (parent == null){
                full_left.width -= area.width;
                full_left.height -= pref.height_padding;
                full_right.height -= pref.height_padding;
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
            area.y = area.y + jmp / 2 - (area.height + pref.height_padding)/ 2;
            return jmp;
        }

        return area.height + pref.height_padding;
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
        if (points != 0) {
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
            Gdk.cairo_set_source_color (cr, pref.back_selected);
        } else
            Gdk.cairo_set_source_color (cr, pref.back_normal);

        cr.fill_preserve();

        if (default_color)
            Gdk.cairo_set_source_color (cr, pref.default_color);
        else
            Gdk.cairo_set_source_color (cr, color);

        cr.stroke ();

        // text
        if (title.length > 0){
            if (is_focus)
                Gdk.cairo_set_source_color (cr, pref.text_selected);
            else
                Gdk.cairo_set_source_color (cr, pref.text_normal);
            cr.move_to (area.x + pref.font_padding * 4, area.y + pref.font_padding);

            var la = Pango.cairo_create_layout (cr);
            la.set_font_description(font_desc);
            la.set_text(title, -1);
            Pango.cairo_show_layout (cr, la);
        }

        if (points != 0) {
            cr.move_to (area.x + area.width - points_width + 2,
                        area.y + pref.font_padding + (int) GLib.Math.lrint (
                                            (area.height - points_height) / 2) );

            var la = Pango.cairo_create_layout (cr);
            var tmp_font = font_desc.copy();
            tmp_font.set_size((int) GLib.Math.lrint (font_desc.get_size() * 0.7));

            la.set_font_description(tmp_font);
            la.set_text(str_points, -1);
            Pango.cairo_show_layout (cr, la);
        }

        if (text.length > 0) {
            var ico = new Cairo.ImageSurface.from_png (DATA + "/icons/sticky_notes_pin.png");
            cr.set_source_surface (ico, area.x + area.width - ICO_SIZE - 2 - points_width,
                                        area.y + (area.height - ICO_SIZE) /2 );
            cr.paint ();
        }

        // draw line to parent
        if (parent != null) {
            cr.set_line_width (0.7 * (1 + (weight / pref.line_rise)));

            if (default_color)
                Gdk.cairo_set_source_color (cr, pref.default_color);
            else
                Gdk.cairo_set_source_color (cr, color);

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
                cr.curve_to (px + pref.width_padding / 1.5, py,
                             nx - pref.width_padding / 1.5, ny,
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
                cr.curve_to (nx + pref.width_padding / 1.5, ny,
                             px - pref.width_padding / 1.5, py,
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

    public void set_points (double points) {
        this.points = points;
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
