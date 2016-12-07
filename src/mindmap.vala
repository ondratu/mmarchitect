/*
 * DESCRIPTION      Map canvas for drawing nodes tree.
 * PROJECT          Mind Map Architect
 * AUTHOR           Ondrej Tuma <mcbig@zeropage.cz>
 *
 * Copyright (C) Ondrej Tuma 2011
 * Code is present with BSD licence.
 */

// modules: gtk+-3.0

public class MindMap : Gtk.Fixed {
    public Preferences pref;
    public Properties prop;
    public EditForm? editform;
    public Node root;
    public unowned Node? focused;
    public unowned Node? last;
    public signal void change();
    public signal void focus_changed(double x, double y,
                                     double width, double height);
    public signal void editform_open();
    public signal void editform_close();
    public signal void node_context_menu (Gdk.Event event);
    public signal void map_context_menu(Gdk.Event event);

    private bool mod_ctrl;
    private bool mod_alt;
    private bool mod_shift;
    private bool event_context;

    public Gdk.RGBA background { private get; construct set; }

    public MindMap(Preferences pref, Properties prop) {
        Object (background: pref.canvas_color);
        this.pref = pref;
        this.prop = prop;

        this.set_has_window (true);
        this.set_can_focus (true);
        this.set_has_tooltip (true);

        this.draw.connect (this.on_draw);
        this.key_press_event.connect (this.on_key_press_event);
        this.key_release_event.connect (this.on_key_release_event);
        this.show_all();
    }

    // realize method is good place to load file if is present....
    public override void realize () {
        base.realize();

        if (this.root == null)
            this.create_new_root();
        this.root.realize(this.get_window());
        this.refresh_tree();
    }

    // nodes have their own tooltips (text)
    public override bool query_tooltip (int x, int y, bool keyboard_tooltip,
            Gtk.Tooltip tooltip)
    {
        double tx, ty;
        this.get_translation (out tx, out ty);
        var node = this.root.event_on(x - tx, y - ty);
        if (node != null && node.text.length > 0) {
            tooltip.set_text (node.text);
            return true;
        }
        // no tooltip to show
        return false;
    }

    public Node create_new_root (
            CoreNode core = CoreNode(){title = _("Main Idea")})
    {
        this.root = new Node.root(core.title, this);
        assert(root != null);
        if (!core.default_color) {
            this.root.rgb = core.rgb;
            this.root.default_color = false;
        }
        this.root.set_points (core.points, core.function);
        this.focused = root;
        this.focused.set_focus(true);
        return this.root;
    }

    public void set_focus(Node? node){
        if (this.editform != null)      // some node in edit mode
            return;
        if (node == focused)            // node to focused is focused yet
            return;

        double x, y;
        this.get_translation (out x, out y);
        int xx = (int) GLib.Math.lrint (x);
        int yy = (int) GLib.Math.lrint (y);

        if (this.focused != null) {
            this.focused.set_focus (false);
            this.queue_draw_area (this.focused.area.x + xx - 1,
                                  this.focused.area.y + yy - 1,
                                  this.focused.area.width + 2,
                                  this.focused.area.height + 2);
            this.focused = null;
        }

        if (node == null)
            return;

        this.focused = node;
        this.focused.set_focus(true);
        this.queue_draw_area (this.focused.area.x + xx - 1,
                              this.focused.area.y + yy - 1,
                              this.focused.area.width + 2,
                              this.focused.area.height + 2 );

        if (this.last != this.focused) {
            // move to focused node (area), only if is not only regrap focus
            this.focus_changed (this.focused.area.x + xx,
                                this.focused.area.y + yy,
                                this.focused.area.width,
                                this.focused.area.height);
        }
        this.grab_focus();
    }

    public void get_translation (out double x, out double y,
            Gtk.Allocation ? allocation = null)
    {
        if (allocation == null) {
            allocation = Gtk.Allocation();
            this.get_allocation (out allocation);
        }

        int dist = (this.root.full_right.width - this.root.full_left.width).abs() / 2;

        if (this.root.full_right.width > this.root.full_left.width){
            x = GLib.Math.lrint (allocation.width / 2 - dist ) + 0.5;
        } else {
            x = GLib.Math.lrint (allocation.width / 2 + dist ) + 0.5;
        }

        y = GLib.Math.lrint (allocation.height / 2 - this.root.get_higher_full() / 2) + 0.5;
    }

    public void refresh_tree() {
        this.root.set_position (0, 0);
        this.set_size_request (
                this.root.full_left.width + this.root.full_right.width + PAGE_PADDING * 2,
                this.root.get_higher_full() + PAGE_PADDING * 2);
        this.queue_draw();
    }

    public void apply_style() {
        if (this.get_window() != null) { // only if map was be drow yet
            this.root.set_size_request(true);
            this.background = pref.canvas_color;
            this.refresh_tree();
        }
    }

    public bool on_draw (Cairo.Context cr) {
        var allocation = Gtk.Allocation();
        this.get_allocation (out allocation);

        cr.set_source_rgb (this.background.red,
                           this.background.green,
                           this.background.blue);
        cr.rectangle(0, 0, allocation.width, allocation.height);
        cr.fill_preserve();
        cr.clip ();

        double x, y;
        this.get_translation (out x, out y, allocation);
        cr.translate (x, y);
        this.root.draw_tree(cr);
        return false;
    }

    /* For mouse button press event (select or open or close node) */
    public override bool button_press_event (Gdk.EventButton event) {
        // stdout.printf ("Fixed: button_press_event %s -> (%f x %f > %s)\n",
        //        event.type.to_string(),event.x, event.y, event.button.to_string());

        // allocation translation

        if (event.button == 1) {
            double x, y;
            this.get_translation (out x, out y);
            var node = this.root.event_on (event.x - x, event.y - y);
            if (node != null && node == this.focused) {
                if (node.change_expand()) {
                    this.change();
                    this.refresh_tree();
                }
            } else {
                this.set_focus(node);
            }
        } else if (event.button == 3) {     // left button
            double x, y;
            this.get_translation (out x, out y);
            var node = this.root.event_on (event.x - x, event.y - y);
            this.event_context = true;
            if (node != null) {             // context menu of node
                this.set_focus(node);
                this.node_context_menu (event);
            } else {
                this.map_context_menu (event);
            }
            return true;
        }

        if (this.editform == null) {
            this.grab_focus ();
        }
        return false;
    }

    public override bool focus_in_event (Gdk.EventFocus event) {
        if (this.focused == null) {
            if (last != null) {
                this.set_focus (this.last);
            } else {
                this.set_focus (this.root);
            }
        }
        return base.focus_out_event (event);
    }

    public override bool focus_out_event (Gdk.EventFocus event) {
        if (!this.event_context) {
            this.last = this.focused;
            this.set_focus (null);
        } else {
            this.event_context = false;
        }
        return base.focus_out_event (event);
    }

    /* For key press event (move over nodes or insert, edit and delete nodes) */
    public bool on_key_press_event (Gdk.EventKey event) {
        /*
                KP_Enter    - 65421,
                Return      - 65293,
                Escape      - 65307,
                Delete      - 65535,
                F2          - 65471,
                Up          - 65362,
                Down        - 65364,
                Left        - 65361,
                Right       - 65363,
                Insert      - 65379,
                Tab         - 65289,
                KP_Add (+)      - 43, 65451,
                KP_Subtract (-) - 45, 65453,
        */

        // unset modificators
        if (event.keyval == 65507 || event.keyval == 65508)
            mod_ctrl = true;
        if (event.keyval == 65513 || event.keyval == 65527)
            mod_alt = true;
        if (event.keyval == 65505 || event.keyval == 65506)
            mod_shift = true;

        if (this.focused != null && this.editform == null) {
            if (event.keyval == 65421 || event.keyval == 65293){// enter
                // new node
                if (this.focused == this.root){
                    this.set_focus (this.root.add ());
                    this.change ();
                    this.refresh_tree ();
                    this.node_edit (true);
                    return true;
                } else {
                    this.set_focus (this.focused.parent.insert (this.focused.get_position ()+1));
                    this.change ();
                    this.refresh_tree ();
                    this.node_edit (true);
                    return true;
                }
            } else if (event.keyval == 65535) {                 // delete
                this.node_delete();
                return true;
            } else if (event.keyval == 65379) {                 // insert
                this.node_insert();
                return true;
            } else if (event.keyval == 65471) {                 // F2
                this.node_edit();
                return true;
            } else if (event.keyval == 65451 || event.keyval == 43) {   // KP_Add (+)
                this.node_expand();
                return true;
            } else if (event.keyval == 65453 || event.keyval == 45) {   // KP_Subtract (-)
                this.node_collapse();
                return true;
            } else if (mod_ctrl && event.keyval == 65362) {     // Ctrl + Up
                this.node_move_up();
                return true;
            } else if (mod_ctrl && event.keyval == 65364) {     // Ctrl + Down
                this.node_move_down();
                return true;
            } else if (mod_ctrl && event.keyval == 65361) {     // Ctrl + Left
                this.node_move_left();
                return true;
            } else if (mod_ctrl && event.keyval == 65363) {     // Ctrl + Right
                this.node_move_right();
                return true;
            } else if (event.keyval == 65362) {                 // Up
                if (this.focused == this.root)
                    return true;

                if (this.focused.parent == this.root) {
                    for (int i = this.focused.get_position() -1;
                            i >= 0; i--)
                    {
                        var node = this.root.children.nth_data(i);
                        if (node.direction == this.focused.direction){
                            this.set_focus(node);
                            break;
                        }
                    }
                    return true;
                } else {
                    int pos = this.focused.get_position();
                    if (pos > 0)
                        this.set_focus(this.focused.parent.children.nth_data(pos -1));
                    return true;
                }
            } else if (event.keyval == 65364) {                 // Down
                if (this.focused == this.root)
                    return true;
                if (this.focused.parent == this.root) {
                    for (int i = this.focused.get_position() +1;
                            i < this.root.children.length(); i++)
                    {
                        var node = this.root.children.nth_data(i);
                        if (node.direction == this.focused.direction){
                            this.set_focus(node);
                            break;
                        }
                    }
                    return true;
                } else {
                    int pos = this.focused.get_position();
                    if (pos < this.focused.parent.children.length()-1)
                        this.set_focus(this.focused.parent.children.nth_data(pos +1));
                    return true;
                }
            } else if (event.keyval == 65361) {                 // Left
                if (this.focused.direction == Direction.LEFT) {
                    if (this.focused.children.length() > 0 && this.focused.is_expand){
                        this.set_focus(this.focused.children.nth_data(0));
                    }
                } else if (this.focused.direction == Direction.RIGHT ){
                    this.set_focus(this.focused.parent);
                } else if (this.focused == this.root) {
                    foreach (var node in this.root.children){
                        if (node.direction == Direction.LEFT) {
                            this.set_focus(node);
                            return true;
                        }
                    }
                }
                return true;
            } else if (event.keyval == 65363) {                 // Right
                if (this.focused.direction == Direction.RIGHT) {
                    if (this.focused.children.length() > 0 && this.focused.is_expand){
                        this.set_focus(this.focused.children.nth_data(0));
                    }
                } else if (this.focused.direction == Direction.LEFT ){
                    this.set_focus(this.focused.parent);
                } else if (this.focused == this.root) {
                    foreach (var node in root.children){
                        if (node.direction == Direction.RIGHT) {
                            this.set_focus(node);
                            return true;
                        }
                    }
                }
                return true;
            }
        } else if (event.keyval == 65362 || event.keyval == 65364 ||
                   event.keyval == 65361 || event.keyval == 65363 )
        {
            this.set_focus (this.root);
            return true;
        }

        return false;
    }

    public bool on_key_release_event (Gdk.EventKey event) {
        /*
            Modificators:
                Control_L   - 65507,
                Control_R   - 65508,
                Alt_L       - 65513,
                ISO_Level3_Shift - 65027 (Alt r),
                Shift_L     - 65505,
                Shift_R     - 65506,
                Menu        - 65383 (context menu),
                Super_L     - 65515 (Win key),
        */

        // unset modificators
        if (event.keyval == 65507 || event.keyval == 65508)
            mod_ctrl = false;
        if (event.keyval == 65513 || event.keyval == 65527)
            mod_alt = false;
        if (event.keyval == 65505 || event.keyval == 65506)
            mod_shift = false;

        /*
        stdout.printf ("release keyval : %u, hardware_keycode: %u, unicode: %u, string: %s\n",
                event.keyval, event.hardware_keycode,
                Gdk.keyval_to_unicode(event.keyval),
                Gdk.keyval_name(event.keyval));
        */
        return false;
    }

    public void node_insert () {
        if (this.focused != null) {
            this.focused.expand ();
            var node = focused.insert (0);
            this.refresh_tree ();
            this.set_focus (node);
            this.change ();
            this.node_edit (true);
        }
    }

    public void node_paste(Node ? node) {
        if (this.focused != null && node != null) {
            this.focused.expand();
            this.focused.paste(node.copy());
            this.refresh_tree();
            this.set_focus(node);
            this.change();
        }
    }

    public void node_move_up() {
        if (this.focused != null) {
            this.focused.move_up();
            this.refresh_tree();
            this.change();
        }
    }

    public void node_move_down() {
        if (this.focused != null) {
            this.focused.move_down();
            this.refresh_tree();
            this.change();
        }
    }

    public void node_move_left() {
        if (this.focused != null) {
            this.focused.move_left();
            this.refresh_tree();
            this.change();
        }
    }

    public void node_move_right() {
        if (this.focused != null) {
            this.focused.move_right();
            this.refresh_tree();
            this.change();
        }
    }

    public void node_delete(){
        if (this.focused != this.root && this.focused != null) {
            Node? node = this.focused.get_next();
            if (node == null)
                node = this.focused.get_prev();
            if (node == null)
                node = this.focused.parent;
            Node.remove(this.focused);
            this.refresh_tree();
            this.focused = null;
            this.set_focus(node);
            this.change();
        }
    }

    public void node_edit (bool newone = false) {
        if (this.focused != null && this.editform == null) {
            double x, y;
            this.get_translation (out x, out y);
            int xx = (int) GLib.Math.lrint(x);
            int yy = (int) GLib.Math.lrint(y);

            this.editform_open();        // emit signal that editform will be open
            this.set_can_focus (false);
            this.editform = new EditForm(this.focused, newone, this.pref);
            this.editform.close.connect (this.on_close_editform);
            this.editform.save.connect (() => {this.change();});
            this.editform.size_allocate.connect (this.on_change_editform);
            put(this.editform,
                this.focused.area.x + xx, this.focused.area.y + yy);
            this.editform.entry.grab_focus();
        }
    }

    private void on_change_editform (Gtk.Allocation aloc) {
        var allocation = Gtk.Allocation();
        this.get_allocation (out allocation);

        double x, y;
        get_translation (out x, out y);

        int new_x = focused.area.x + (int) GLib.Math.lrint(x) - 1;
        int new_y = focused.area.y + (int) GLib.Math.lrint(y) - 1;

        if (this.focused.direction == Direction.LEFT &&
            this.focused.area.width < NONE_TITLE.length * this.pref.node_font_size)
        {
            int ico_size = (this.focused.text.length > 0
                            || this.focused.title.length == 0) ? 0 : ICO_SIZE;
            int tmp_x = new_x + this.focused.area.width
                    - NONE_TITLE.length * this.pref.node_font_size
                    - ico_size - this.pref.font_padding * 2;
            if (tmp_x > 0)
                new_x =  tmp_x;
        }

        // move editform to left if it is needed allways
        if ((new_x + aloc.width) > allocation.width)
            new_x = allocation.width - this.pref.font_padding - aloc.width;

        // move editform up needed when is expand
        if (this.editform.is_expand && (new_y + aloc.height) > allocation.height) {
            new_y = allocation.height - this.pref.font_padding - aloc.height;
        }

        this.move (this.editform, new_x, new_y);
        this.focus_changed (new_x, new_y, aloc.width,  aloc.height);
    }

    private void on_close_editform () {
        if (this.editform.newone && this.focused.title.length == 0)
            this.node_delete();

        this.remove (this.editform);
        this.editform = null; // delete editform
        this.editform_close();       // emit signal that editform is close
        this.set_can_focus (true);
        this.grab_focus();
        this.refresh_tree();
    }

    public Node? node_copy () {
        if (this.focused != null)
            return this.focused.copy();
        else
            return null;
    }

    public Node? node_cut () {
        if (this.focused != this.root && this.focused != null) {
            var node = this.focused;
            this.node_delete();
            return node;
        } else
            return null;
    }

    public void node_expand () {
        if (this.focused != this.root && this.focused != null) {
            if (!this.focused.is_expand) {
                this.focused.change_expand();
                this.change();
                this.refresh_tree();
            }
        }
    }

    public void node_expand_all () {
        foreach (var it in this.root.children)
            it.expand_all ();
        this.change ();
        this.refresh_tree ();

        // scroll to selected node
        double x, y;
        this.get_translation (out x, out y);
        int xx = (int) GLib.Math.lrint(x);
        int yy = (int) GLib.Math.lrint(y);
        this.focus_changed (this.focused.area.x + xx,
                            this.focused.area.y + yy,
                            this.focused.area.width,
                            this.focused.area.height);
    }

    public void node_collapse () {
        if (this.focused != this.root && this.focused != null) {
            if (this.focused.is_expand) {
                this.focused.change_expand();
                this.change();
                this.refresh_tree();
            }
        }
    }

    public void node_collapse_all () {
        foreach (var it in this.root.children)
            it.collapse_all ();
        this.set_focus (this.root);
        this.change ();
        this.refresh_tree ();
    }
}
