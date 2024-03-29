/*
 * DESCRIPTION      Map canvas for drawing nodes tree.
 * PROJECT          Mind Map Architect
 * AUTHOR           Ondrej Tuma <mcbig@zeropage.cz>
 *
 * Copyright (C) Ondrej Tuma 2011
 * Code is present with BSD licence.
 */

public class MindMap : Gtk.Fixed {
    public Preferences pref;
    public Properties prop;
    public EditForm? editform;
    public Node root;
    public unowned Node? focused;
    public unowned Node? last;
    public signal void change ();
    public signal void focus_changed (double x, double y,
                                      double width, double height);
    public signal void editform_open ();
    public signal void editform_close ();
    public signal void node_context_menu (Gdk.Event event);
    public signal void map_context_menu (Gdk.Event event);

    private bool mod_ctrl;
    private bool mod_alt;
    private bool mod_shift;
    private bool event_context;
    private unowned Gtk.Window window;

    public Gdk.RGBA background { private get; construct set; }

    public MindMap (Preferences pref, Properties prop, Gtk.Window window) {
        Object (background: pref.canvas_color);
        this.pref = pref;
        this.prop = prop;
        this.window = window;

        set_has_window (true);
        set_can_focus (true);
        set_has_tooltip (true);

        draw.connect (on_draw);
        key_press_event.connect (on_key_press_event);
        key_release_event.connect (on_key_release_event);
        show_all ();
    }

    // realize method is good place to load file if is present....
    public override void realize () {
        base.realize ();

        if (root == null){
            create_new_root ();
        }
        root.realize (get_window ());
        refresh_tree ();
    }

    // nodes have their own tooltips (text)
    public override bool query_tooltip (int x, int y, bool keyboard_tooltip,
            Gtk.Tooltip tooltip)
    {
        double tx, ty;
        get_translation (out tx, out ty);
        var node = root.event_on (x - tx, y - ty);
        if (node != null && node.text.length > 0) {
            tooltip.set_text (node.text);
            return true;
        }
        // no tooltip to show
        return false;
    }

    public Node create_new_root (
            CoreNode core = CoreNode (){title = _("Main Idea")})
    {
        root = new Node.root (core.title, this);
        assert (root != null);
        if (!core.default_color) {
            root.rgb = core.rgb;
            root.default_color = false;
        }
        root.set_points (core.points, core.function);
        focused = root;
        focused.set_focus (true);
        return root;
    }

    public void set_focus (Node? node) {
        if (editform != null) {         // some node in edit mode
            return;
        }
        if (node == focused) {          // node to focused is focused yet
            return;
        }

        double x, y;
        get_translation (out x, out y);
        int xx = (int) Math.lrint (x);
        int yy = (int) Math.lrint (y);

        if (focused != null) {
            focused.set_focus (false);
            queue_draw_area (focused.area.x + xx - 1,
                             focused.area.y + yy - 1,
                             focused.area.width + 2,
                             focused.area.height + 2);
            focused = null;
        }

        if (node == null) {
            return;
        }

        focused = node;
        focused.set_focus (true);
        queue_draw_area (focused.area.x + xx - 1,
                         focused.area.y + yy - 1,
                         focused.area.width + 2,
                         focused.area.height + 2 );

        if (last != focused) {
            // move to focused node (area), only if is not only regrap focus
            focus_changed (focused.area.x + xx,
                           focused.area.y + yy,
                           focused.area.width,
                           focused.area.height);
        }
        grab_focus ();
    }

    public void get_translation (out double x, out double y,
            Gtk.Allocation ? allocation = null)
    {
        if (allocation == null) {
            allocation = Gtk.Allocation ();
            get_allocation (out allocation);
        }

        int dist = (root.full_right.width - root.full_left.width).abs () / 2;

        if (root.full_right.width > root.full_left.width) {
            x = Math.lrint (allocation.width / 2 - dist ) + 0.5;
        } else {
            x = Math.lrint (allocation.width / 2 + dist ) + 0.5;
        }

        y = Math.lrint (allocation.height / 2 - root.get_higher_full () / 2) + 0.5;
    }

    public void refresh_tree () {
        root.set_position (0, 0);
        set_size_request (
                root.full_left.width + root.full_right.width + PAGE_PADDING * 2,
                root.get_higher_full () + PAGE_PADDING * 2);
        queue_draw ();
    }

    public void apply_style () {
        if (get_window () != null) { // only if map was be drow yet
            root.set_size_request (true);
            background = pref.canvas_color;
            refresh_tree ();
        }
    }

    public bool on_draw (Cairo.Context cr) {
        var allocation = Gtk.Allocation ();
        get_allocation (out allocation);

        cr.set_source_rgb (background.red,
                           background.green,
                           background.blue);
        cr.rectangle (0, 0, allocation.width, allocation.height);
        cr.fill_preserve ();
        cr.clip ();

        double x, y;
        get_translation (out x, out y, allocation);
        cr.translate (x, y);
        root.draw_tree (cr);
        return false;
    }

    /* For mouse button press event (select or open or close node) */
    public override bool button_press_event (Gdk.EventButton event) {
        // stdout.printf ("Fixed: button_press_event %s -> (%f x %f > %s)\n",
        //        event.type.to_string(),event.x, event.y, event.button.to_string());

        // allocation translation

        if (event.button == 1) {
            double x, y;
            get_translation (out x, out y);
            var node = root.event_on (event.x - x, event.y - y);
            if (node != null && node == focused) {
                if (node.change_expand ()) {
                    change ();
                    refresh_tree ();
                }
            } else {
                set_focus (node);
            }
        } else if (event.button == 3) {     // left button
            double x, y;
            get_translation (out x, out y);
            var node = root.event_on (event.x - x, event.y - y);
            event_context = true;
            if (node != null) {             // context menu of node
                set_focus (node);
                node_context_menu (event);
            } else {
                map_context_menu (event);
            }
            return true;
        }

        if (editform == null) {
            grab_focus ();
        }
        return false;
    }

    public override bool focus_in_event (Gdk.EventFocus event) {
        if (focused == null) {
            if (last != null) {
                set_focus (last);
            } else {
                set_focus (root);
            }
        }
        return base.focus_out_event (event);
    }

    public override bool focus_out_event (Gdk.EventFocus event) {
        if (!event_context) {
            last = focused;
            set_focus (null);
        } else {
            event_context = false;
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
        if (event.keyval == 65507 || event.keyval == 65508) {
            mod_ctrl = true;
        }
        if (event.keyval == 65513 || event.keyval == 65527) {
            mod_alt = true;
        }
        if (event.keyval == 65505 || event.keyval == 65506) {
            mod_shift = true;
        }

        if (focused != null && editform == null) {
            if (event.keyval == 65421 || event.keyval == 65293) {// enter
                // new node
                if (focused == root){
                    set_focus (root.add ());
                    change ();
                    refresh_tree ();
                    node_edit (true);
                    return true;
                } else {
                    set_focus (focused.parent.insert (focused.get_position () + 1));
                    change ();
                    refresh_tree ();
                    node_edit (true);
                    return true;
                }
            } else if (event.keyval == 65535) {                 // delete
                node_delete ();
                return true;
            } else if (event.keyval == 65379) {                 // insert
                node_insert ();
                return true;
            } else if (event.keyval == 65471) {                 // F2
                node_edit ();
                return true;
            } else if (event.keyval == 65451 || event.keyval == 43) {   // KP_Add (+)
                node_expand ();
                return true;
            } else if (event.keyval == 65453 || event.keyval == 45) {   // KP_Subtract (-)
                node_collapse ();
                return true;
            } else if (mod_ctrl && event.keyval == 65362) {     // Ctrl + Up
                node_move_up ();
                return true;
            } else if (mod_ctrl && event.keyval == 65364) {     // Ctrl + Down
                node_move_down ();
                return true;
            } else if (mod_ctrl && event.keyval == 65361) {     // Ctrl + Left
                node_move_left ();
                return true;
            } else if (mod_ctrl && event.keyval == 65363) {     // Ctrl + Right
                node_move_right ();
                return true;
            } else if (event.keyval == 65362) {                 // Up
                if (focused == root)
                    return true;

                if (focused.parent == root) {
                    for (int i = focused.get_position () - 1; i >= 0; i--)
                    {
                        var node = root.children.nth_data (i);
                        if (node.direction == focused.direction) {
                            set_focus (node);
                            break;
                        }
                    }
                    return true;
                } else {
                    int pos = focused.get_position ();
                    if (pos > 0) {
                        set_focus (focused.parent.children.nth_data (pos - 1));
                    }
                    return true;
                }
            } else if (event.keyval == 65364) {                 // Down
                if (focused == root) {
                    return true;
                }
                if (focused.parent == root) {
                    for (int i = focused.get_position () + 1;
                            i < root.children.length (); i++)
                    {
                        var node = root.children.nth_data (i);
                        if (node.direction == focused.direction) {
                            set_focus (node);
                            break;
                        }
                    }
                    return true;
                } else {
                    int pos = focused.get_position ();
                    if (pos < focused.parent.children.length () - 1) {
                        set_focus (focused.parent.children.nth_data (pos + 1));
                    }
                    return true;
                }
            } else if (event.keyval == 65361) {                 // Left
                if (focused.direction == Direction.LEFT) {
                    if (focused.children.length () > 0 && focused.is_expand) {
                        set_focus (focused.children.nth_data (0));
                    }
                } else if (focused.direction == Direction.RIGHT) {
                    set_focus (focused.parent);
                } else if (focused == root) {
                    foreach (var node in root.children){
                        if (node.direction == Direction.LEFT) {
                            set_focus (node);
                            return true;
                        }
                    }
                }
                return true;
            } else if (event.keyval == 65363) {                 // Right
                if (focused.direction == Direction.RIGHT) {
                    if (focused.children.length () > 0 && focused.is_expand) {
                        set_focus (focused.children.nth_data (0));
                    }
                } else if (focused.direction == Direction.LEFT) {
                    set_focus (focused.parent);
                } else if (focused == root) {
                    foreach (var node in root.children) {
                        if (node.direction == Direction.RIGHT) {
                            set_focus (node);
                            return true;
                        }
                    }
                }
                return true;
            }
        } else if (event.keyval == 65362 || event.keyval == 65364 ||
                   event.keyval == 65361 || event.keyval == 65363)
        {
            set_focus (root);
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
        if (event.keyval == 65507 || event.keyval == 65508) {
            mod_ctrl = false;
        }
        if (event.keyval == 65513 || event.keyval == 65527) {
            mod_alt = false;
        }
        if (event.keyval == 65505 || event.keyval == 65506) {
            mod_shift = false;
        }

        /*
        stdout.printf ("release keyval : %u, hardware_keycode: %u, unicode: %u, string: %s\n",
                event.keyval, event.hardware_keycode,
                Gdk.keyval_to_unicode(event.keyval),
                Gdk.keyval_name(event.keyval));
        */
        return false;
    }

    public void node_insert () {
        if (focused != null) {
            focused.expand ();
            var node = focused.insert (0);
            refresh_tree ();
            set_focus (node);
            change ();
            node_edit (true);
        }
    }

    public void node_paste (Node ? node) {
        if (focused != null && node != null) {
            focused.expand ();
            focused.paste (node.copy ());
            refresh_tree ();
            set_focus (node);
            change ();
        }
    }

    public void node_move_up () {
        if (focused != null) {
            var tmp = Node.move_up (focused);
            focused = null;
            set_focus (tmp);
            refresh_tree ();
            change ();
        }
    }

    public void node_move_down () {
        if (focused != null) {
            var tmp = Node.move_down (focused);
            focused = null;
            set_focus (tmp);
            refresh_tree ();
            change ();
        }
    }

    public void node_move_left () {
        if (focused != null) {
            var tmp = Node.move_left (focused);
            focused = null;
            set_focus (tmp);
            refresh_tree ();
            change ();
        }
    }

    public void node_move_right () {
        if (focused != null) {
            var tmp = Node.move_right (focused);
            focused = null;
            set_focus (tmp);
            refresh_tree ();
            change ();
        }
    }

    public void node_delete (){
        if (focused != root && focused != null) {
            Node? node = focused.get_next ();
            if (node == null){
                node = focused.get_prev ();
            }
            if (node == null) {
                node = focused.parent;
            }
            Node.remove (focused);
            refresh_tree ();
            focused = null;
            set_focus (node);
            change ();
        }
    }

    public void node_edit (bool newone = false) {
        if (focused != null && editform == null) {
            double x, y;
            get_translation (out x, out y);
            int xx = (int) Math.lrint (x);
            int yy = (int) Math.lrint (y);

            editform_open ();        // emit signal that editform will be open
            set_can_focus (false);
            editform = new EditForm (focused, newone, pref, window);
            editform.close.connect (on_close_editform);
            editform.save.connect (() => {change ();});
            editform.size_allocate.connect (on_change_editform);
            put (editform, focused.area.x + xx, focused.area.y + yy);
            editform.entry.grab_focus ();
        }
    }

    private void on_change_editform (Gtk.Allocation aloc) {
        var allocation = Gtk.Allocation ();
        get_allocation (out allocation);

        double x, y;
        get_translation (out x, out y);

        int new_x = focused.area.x + (int) Math.lrint (x) - 1;
        int new_y = focused.area.y + (int) Math.lrint (y) - 1;

        if (focused.direction == Direction.LEFT &&
            focused.area.width < NONE_TITLE.length * pref.node_font_size)
        {
            int ico_size = (focused.text.length > 0
                            || focused.title.length == 0) ? 0 : ICO_SIZE;
            int tmp_x = new_x + focused.area.width
                    - NONE_TITLE.length * pref.node_font_size
                    - ico_size - pref.font_padding * 2;
            if (tmp_x > 0) {
                new_x = tmp_x;
            }
        }

        // move editform to left if it is needed allways
        if ((new_x + aloc.width) > allocation.width) {
            new_x = allocation.width - pref.font_padding - aloc.width;
        }

        // move editform up needed when is expand
        if (editform.is_expand && (new_y + aloc.height) > allocation.height) {
            new_y = allocation.height - pref.font_padding - aloc.height;
        }

        move (editform, new_x, new_y);
        focus_changed (new_x, new_y, aloc.width, aloc.height);
    }

    private void on_close_editform () {
        if (editform.newone && focused.title.length == 0) {
            node_delete ();
        }

        remove (editform);
        editform = null; // delete editform
        editform_close ();       // emit signal that editform is close
        set_can_focus (true);
        grab_focus ();
        refresh_tree ();
    }

    public Node? node_copy () {
        if (focused != null) {
            return focused.copy ();
        } else {
            return null;
        }
    }

    public Node? node_cut () {
        if (focused != root && focused != null) {
            var node = focused;
            node_delete ();
            return node;
        }
        return null;
    }

    public void node_expand () {
        if (focused != root && focused != null) {
            if (!focused.is_expand) {
                focused.change_expand ();
                change ();
                refresh_tree ();
            }
        }
    }

    public void node_expand_all () {
        foreach (var it in root.children) {
            it.expand_all ();
        }
        change ();
        refresh_tree ();

        // scroll to selected node
        double x, y;
        get_translation (out x, out y);
        int xx = (int) Math.lrint (x);
        int yy = (int) Math.lrint (y);
        focus_changed (focused.area.x + xx,
                       focused.area.y + yy,
                       focused.area.width,
                       focused.area.height);
    }

    public void node_collapse () {
        if (focused != root && focused != null) {
            if (focused.is_expand) {
                focused.change_expand ();
                change ();
                refresh_tree ();
            }
        }
    }

    public void node_collapse_all () {
        foreach (var it in root.children) {
            it.collapse_all ();
        }
        set_focus (root);
        change ();
        refresh_tree ();
    }
}
