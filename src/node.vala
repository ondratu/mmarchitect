enum Direction {
    LEFT,
    RIGHT,
    AUTO
}

public struct CoreNode {
    public string title;
    public uint direction;
    public bool is_expand;

    public CoreNode () {
        is_expand = true;
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

    public Gdk.Rectangle area;
    public Gdk.Rectangle full_left;
    public Gdk.Rectangle full_right;
    public AppSettings app_set;
    public Pango.FontDescription font_desc;
    public bool is_expand;
    public bool is_focus {get; private set;}
    public bool visible;

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
            if (parent.direction != Direction.AUTO) // parent is not root
                this.direction = parent.direction;
            else if (direction != Direction.AUTO)   // parent is root, and direction is set
                this.direction = direction;
            else                                    // parent is root, and direction is not set
                this.direction =  parent.children.length() % 2;
        } else {                                    // I'm root
            this.direction = Direction.AUTO;
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
            child.realize(this.window, app_set);
        children.append (child);
        return child;
    }

    public void paste (Node node) {
        node.parent = this;
        
        if (node.direction == Direction.AUTO && direction == Direction.AUTO)
            node.corect_direction (children.length() % 2);
        else if (direction != Direction.AUTO)
            node.corect_direction (direction);
        
        node.realize(this.window, app_set);
        children.append (node);
    }

    public Node insert(int pos){
        var child = new Node ("", this);
        assert (child != null);
        if (this.window != null)
            child.realize(this.window, app_set);
        children.insert(child, pos);
        return child;
    }

    public static void remove (Node node) {
        if (node.parent == null)
            return;
        var parent = node.parent;
        parent.children.remove(node);
    }

    public Node? get_next() {
        int pos = get_position();
        if (parent.children.length()-1 > pos)
            return parent.children.nth_data(pos + 1);
        return null;
    }

    public Node? get_prev() {
        int pos = get_position();
        if (pos > 0)
            return parent.children.nth_data(pos - 1);
        return null;
    }

    public void realize (Gdk.Drawable window, AppSettings app_set) {
        this.window = window;
        this.app_set = app_set;
        get_size_request (out area.width, out area.height);
        foreach (var child in children) {
            child.realize (window, app_set);
        }
    }

    public int get_position (){
        return parent.children.index(this);
    }

    public void set_focus(bool is_focus){
        this.is_focus = is_focus;
    }

    public void change_expand () {
        if (parent != null)                 // parent can't be close
            is_expand = ! is_expand;
    }
    public void expand () {
        is_expand = true;
    }
    public void rollup () {
        is_expand = false;
    }

    public void expand_all () {
        is_expand = true;
        foreach (var it in children)
            it.expand_all ();
    }

    public void rollup_all () {
        is_expand = false;
        foreach (var it in children)
            it.rollup_all ();
    }

    public void get_size_request (out int width, out int height) {
        var cr = Gdk.cairo_create (this.window);
        var la = Pango.cairo_create_layout (cr);

        font_desc = app_set.font_desc.copy();

        var font_size = font_desc.get_size() * (1 + (weight / FONT_RISE)) * (app_set.dpi / 100);
        font_desc.set_size((int) GLib.Math.lrint (font_size));

        la.set_font_description(font_desc);
        la.set_text((title.length > 0) ? title : NONE_TITLE, -1);

        int t_width, t_height;
        la.get_size (out t_width, out t_height);
        width = (t_width / Pango.SCALE) + TEXT_PADDING * 2;
        height = (t_height / Pango.SCALE) + TEXT_PADDING * 2;
    }

    public void set_size_request () {
        get_size_request (out area.width, out area.height);
    }

    private void corect_direction (uint direction) {
        if (direction == Direction.AUTO)
            this.direction =  parent.children.length() % 2;
        else
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

    public int set_position (int left, int top) {
        area.x = left;
        area.y = top;

        full_left.width = area.width;
        full_right.width = area.width;
        full_left.height = area.height + NODE_PADDING_HEIGHT;
        full_right.height = area.height + NODE_PADDING_HEIGHT;
        
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
                        rightjmp += node.set_position (area.x + area.width + NODE_PADDING_WEIGHT,
                                        area.y + rightjmp);
                    else
                        rightjmp += node.set_position (area.x + area.width + NODE_PADDING_WEIGHT,
                                        area.y + i * (area.height + NODE_PADDING_HEIGHT));

                    int full_width = node.area.x - area.x + node.full_right.width;
                    full_right.width = (full_right.width < full_width) ? full_width : full_right.width;
                    full_right.height += node.full_right.height;

                } else {
                    if (i > 0)
                        leftjmp += node.set_position (area.x - node.area.width - NODE_PADDING_WEIGHT,
                                        area.y + leftjmp);
                    else
                        leftjmp += node.set_position (area.x - node.area.width - NODE_PADDING_WEIGHT,
                                        area.y + i * (area.height + NODE_PADDING_HEIGHT));

                    int full_width = ((node.area.x + node.area.width) - (area.x + area.width)).abs()  + node.full_left.width;
                    full_left.width = (full_left.width < full_width) ? full_width : full_left.width;
                    full_left.height += node.full_left.height;
                }
            }
            
            if (full_right.height > area.height)
                full_right.height -= area.height + NODE_PADDING_HEIGHT;
            if (full_left.height > area.height)
                full_left.height -= area.height + NODE_PADDING_HEIGHT;
            
            if (parent == null){
                full_left.width -= area.width;
                full_left.height -= NODE_PADDING_HEIGHT;
                full_right.height -= NODE_PADDING_HEIGHT;
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
            area.y = area.y + jmp / 2 - (area.height + NODE_PADDING_HEIGHT)/ 2;
            return jmp;
        }

        return area.height + NODE_PADDING_HEIGHT;
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
        draw_rectangle (cr, area, (area.height / 2) + 2);
        if (is_focus){
            cr.set_source_rgb (0.6, 0.6, 0.6);
            cr.fill_preserve();
        }
        cr.set_source_rgb (0.2, 0.2, 0.2);
        cr.stroke ();

        // text
        cr.set_source_rgb (0, 0, 0);
        cr.move_to (area.x + TEXT_PADDING, area.y + TEXT_PADDING);

        if (title.length > 0){
            var la = Pango.cairo_create_layout (cr);
            la.set_font_description(font_desc);
            la.set_text(title, -1);
            Pango.cairo_show_layout (cr, la);
        }

        // draw line to parent
        if (parent != null) {
            if (direction == Direction.RIGHT) {
                cr.move_to (area.x, area.y + area.height / 2);
                cr.line_to (parent.area.x + parent.area.width,
                            parent.area.y + parent.area.height / 2);
            } else {
                cr.move_to (area.x + area.width, area.y + area.height / 2);
                cr.line_to (parent.area.x,
                            parent.area.y + parent.area.height / 2);
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
        cr.set_source_rgb (0.2, 0.2, 0.2);
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
        this._title = title;
        get_size_request (out area.width, out area.height);
        //set_position (area.x, area.y);
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
