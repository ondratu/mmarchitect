public class EditForm : Gtk.VBox {
    public Node node;
    public Gtk.Entry entry;
    public signal void close();
    public bool newone;

    public EditForm (Node node, bool newone, AppSettings app_set){
        this.node = node;
        this.newone = newone;
        entry = new Gtk.Entry();
        entry.set_text (node.title);
        entry.key_press_event.connect (on_key_press_event);
        entry.set_width_chars ((node.title.length > 0) ? node.title.length : NONE_TITLE.length);
        
        var font_desc = node.font_desc.copy();
        font_desc.set_size ((int) GLib.Math.lrint (
                font_desc.get_size() / (app_set.dpi / 102.0)));

        entry.modify_font(font_desc);
        entry.set_size_request (node.area.width + TEXT_PADDING * 2, -1);

        pack_start(entry);
        show_all();
    }

    public virtual signal void save (){
        newone = false;
        node.set_title(entry.get_text());
    }

    public bool on_key_press_event (Gdk.EventKey e){
        if (e.keyval == 65307){
            close();
            return true;
        } else if (e.keyval == 65421 || e.keyval == 65293) {
            save();
            close();
            return true;
        }

        //stdout.printf ("EditForm key press %s (%u)\n",
        //        Gdk.keyval_name(e.keyval), e.keyval);
        return false;
    }
}

public class MindMap : Gtk.Fixed {
    public AppSettings app_settings;
    public EditForm? editform;
    public Node root;
    public unowned Node? focused;
    public signal void change();
    public signal void focus_changed(double x, double y,
                                     double width, double height);
    
    public MindMap(AppSettings app_set) {
        app_settings = app_set;

        add_events (Gdk.EventMask.BUTTON_PRESS_MASK
                  | Gdk.EventMask.BUTTON_RELEASE_MASK
                  | Gdk.EventMask.KEY_PRESS_MASK
                  | Gdk.EventMask.KEY_RELEASE_MASK
                  | Gdk.EventMask.FOCUS_CHANGE_MASK);

        set_has_window (true);
        set_can_focus (true);
        
        key_press_event.connect(on_key_press_event);
        show_all();
    }
        
    
    // realize method is good place to load file if is present....
    public override void realize () {
        base.realize();
        if (root == null)
            create_new_root();
        root.realize(this.window, app_settings);
        refresh_tree();
    }

    public Node create_new_root (CoreNode core = CoreNode(){title = _("Main Idea")}) {
        root = new Node(core.title);
        assert(root != null);
        focused = root;
        focused.set_focus(true);
        return root;
    }

    public void set_focus(Node? node){
        if (editform != null)       // some node in edit mode
            return;
        if (node == focused)        // node to focused is focused yet
            return;

        grab_focus();

        double x, y;
        get_translation (out x, out y);
        int xx = (int) GLib.Math.lrint(x);
        int yy = (int) GLib.Math.lrint(y);

        if (focused != null) {
            focused.set_focus (false);
            queue_draw_area(focused.area.x + xx - 1, focused.area.y + yy - 1,
                            focused.area.width + 2, focused.area.height + 2 );
            focused = null;
        }

        if (node == null)
            return;

        focused = node;
        focused.set_focus(true);
        queue_draw_area(focused.area.x + xx - 1, focused.area.y + yy - 1,
                            focused.area.width + 2, focused.area.height + 2 );

        // musim poslat takovey rozmer, aby bylo vse videt
        focus_changed (focused.area.x + xx, focused.area.y + yy,
                       focused.area.width,  focused.area.height);
    }

    public void get_translation (out double x, out double y) {
        int dist = (root.full_right.width - root.full_left.width).abs()  / 2;

        if (root.full_right.width > root.full_left.width){
            x = GLib.Math.lrint (allocation.width / 2 - dist ) + 0.5;
        } else {
            x = GLib.Math.lrint (allocation.width / 2 + dist ) + 0.5;
        }

        y = GLib.Math.lrint (allocation.height / 2 - root.get_higher_full() / 2) + 0.5;
    }

    public void refresh_tree() {
        root.set_position (0, 0);
        set_size_request (root.full_left.width + root.full_right.width + PAGE_PADDING * 2,
                              root.get_higher_full() + PAGE_PADDING * 2);
        queue_draw();
    }
    
    public override bool expose_event (Gdk.EventExpose event) {
        var cr = Gdk.cairo_create (this.window as Gdk.Drawable);
        cr.rectangle (event.area.x, event.area.y,
                      event.area.width, event.area.height);
        cr.clip ();
        
        double x, y;
        get_translation (out x, out y);

        cr.translate (x, y);
        
        // draw
        root.draw_tree(cr);

        //stdout.printf ("expose_event (%d,%d) -> (%d,%d)\n",
        //                    event.area.x, event.area.y,
        //                    event.area.width, event.area.height);
        return base.expose_event (event);
    }

    public override bool button_press_event (Gdk.EventButton event) {
        //stdout.printf ("Fixed: button_press_event %s -> (%f x %f > %s)\n",
        //        event.type.to_string(),event.x, event.y, event.button.to_string());

        // allocation translation

        if (event.button == 1) {
            double x, y;
            get_translation (out x, out y);
            var node = root.event_on(event.x - x, event.y - y);
            if (node != null && node == focused) {
                node.change_expand();
                change();
                refresh_tree();
                grab_focus();
            } else
                set_focus(node);
        }
        grab_focus ();
        return false;
    }

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
        */

        if (focused != null) {
            if (event.keyval == 65421 || event.keyval == 65293){// enter
                // new node
                if (focused == root){
                    set_focus (root.add ());
                    change ();
                    refresh_tree ();
                    node_edit (true);
                    return true;
                } else {
                    set_focus (focused.parent.insert (focused.get_position ()+1));
                    change ();
                    refresh_tree ();
                    node_edit (true);
                    return true;
                }
            } else if (event.keyval == 65535) {                 // delete
                node_delete();
                return true;
            } else if (event.keyval == 65379) {                 // insert
                node_insert();
                return true;
            } else if (event.keyval == 65471) {                 // F2
                node_edit();
                return true;
            } else if (event.keyval == 65362) {                 // Up
                if (focused == root)
                    return true;

                if (focused.parent == root) {
                    for (int i = focused.get_position() -1;
                            i >= 0; i--)
                    {
                        var node = root.children.nth_data(i);
                        if (node.direction == focused.direction){
                            set_focus(node);
                            break;
                        }
                    }
                    return true;
                } else {
                    int pos = focused.get_position();
                    if (pos > 0)
                        set_focus(focused.parent.children.nth_data(pos -1));
                    return true;
                }
            } else if (event.keyval == 65364) {                 // Down
                if (focused == root) return true;
                if (focused.parent == root) {
                    for (int i = focused.get_position() +1;
                            i < root.children.length(); i++)
                    {
                        var node = root.children.nth_data(i);
                        if (node.direction == focused.direction){
                            set_focus(node);
                            break;
                        }
                    }
                    return true;
                } else {
                    int pos = focused.get_position();
                    if (pos < focused.parent.children.length()-1)
                        set_focus(focused.parent.children.nth_data(pos +1));
                    return true;
                }
            } else if (event.keyval == 65361) {                 // Left
                if (focused.direction == Direction.LEFT && focused.children.length() > 0){
                    set_focus(focused.children.nth_data(0));
                } else if (focused.direction == Direction.RIGHT ){
                    set_focus(focused.parent);
                } else if (focused == root) {
                    foreach (var node in root.children){
                        if (node.direction == Direction.LEFT) {
                            set_focus(node);
                            return true;
                        }
                    }
                }
                return true;
            } else if (event.keyval == 65363) {                 // Right
                if (focused.direction == Direction.RIGHT && focused.children.length() > 0){
                    set_focus(focused.children.nth_data(0));
                } else if (focused.direction == Direction.LEFT ){
                    set_focus(focused.parent);
                } else if (focused == root) {
                    foreach (var node in root.children){
                        if (node.direction == Direction.RIGHT) {
                            set_focus(node);
                            return true;
                        }
                    }
                }
                return true;
            }
        } else if (event.keyval == 65362 || event.keyval == 65364 ||
                   event.keyval == 65361 || event.keyval == 65363 ) 
        {
            set_focus (root);
            return true;
        }

        //stdout.printf ("keyval : %u, hardware_keycode: %u, unicode: %u, string: %s\n",
        //        event.keyval, event.hardware_keycode,
        //        Gdk.keyval_to_unicode(event.keyval),
        //        Gdk.keyval_name(event.keyval));
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

    public void node_paste(Node ? node) {
        if (focused != null && node != null) {
            focused.expand();
            focused.paste(node.copy());
            refresh_tree();
            set_focus(node);
            change();
        }
    }

    public void node_delete(){
        if (focused != root && focused != null) {
            Node? node = focused.get_next();
            if (node == null)
                node = focused.get_prev();
            if (node == null)
                node = focused.parent;
            Node.remove(focused);
            refresh_tree();
            focused = null;
            set_focus(node);
            change();
        }
    }

    public void node_edit (bool newone = false) {
        if (focused != null && editform == null) {
            double x, y;
            get_translation (out x, out y);
            int xx = (int) GLib.Math.lrint(x);
            int yy = (int) GLib.Math.lrint(y);

            editform = new EditForm(focused, newone, app_settings);
            editform.close.connect (on_close_editform);
            editform.save.connect (() => {change();});
            put(editform, focused.area.x + xx, focused.area.y + yy);
            editform.entry.grab_focus();
        }
    }

    private void on_close_editform () {
        if (editform.newone && focused.title.length == 0)
            node_delete();

        remove (editform);
        editform = null; // delete editform
        grab_focus();
        refresh_tree();
    }

    public Node? node_copy () {
        if (focused != null)
            return focused.copy();
        else
            return null;
    }

    public Node? node_cut () {
        if (focused != root && focused != null) {
            var node = focused;
            node_delete();
            return node;
        } else
            return null;
    }

    public void node_expand () {
        if (focused != root && focused != null) {
            if (!focused.is_expand) {
                focused.change_expand();
                change();
                refresh_tree();
            }
        }
    }

    public void node_expand_all () {
        foreach (var it in root.children)
            it.expand_all ();
        change ();
        refresh_tree ();

        // scroll to selected node
        double x, y;
        get_translation (out x, out y);
        int xx = (int) GLib.Math.lrint(x);
        int yy = (int) GLib.Math.lrint(y);
        focus_changed (focused.area.x + xx, focused.area.y + yy,
                       focused.area.width,  focused.area.height);
    }

    public void node_rollup () {
        if (focused != root && focused != null) {
            if (focused.is_expand) {
                focused.change_expand();
                change();
                refresh_tree();
            }
        }
    }

    public void node_rollup_all () {
        foreach (var it in root.children)
            it.rollup_all ();
        set_focus (root);
        change ();
        refresh_tree ();
    }
}
