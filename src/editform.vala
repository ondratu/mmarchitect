/*
 * DESCRIPTION      Edit form for nodes.
 * PROJECT          Mind Map Architect
 * AUTHOR           Ondrej Tuma <mcbig@zeropage.cz>
 *
 * Copyright (C) Ondrej Tuma 2011
 * Code is present with BSD licence.
 */

// modules: Gtk

public class BgLabel : Gtk.Widget {
    private string label;
    private Pango.Layout layout;

    public BgLabel (string label) {
        this.label = label;
        this.layout = create_pango_layout (label);
    }

    public override void size_request (out Gtk.Requisition requisition) {
        requisition = Gtk.Requisition ();
        int width, height;

        this.layout.get_size (out width, out height);
        requisition.width = width / Pango.SCALE;
        requisition.height = height / Pango.SCALE;
    }

    public override void realize () {
        var attrs = Gdk.WindowAttr () {
            window_type = Gdk.WindowType.CHILD,
            wclass = Gdk.WindowClass.INPUT_OUTPUT,
            event_mask = get_events () | Gdk.EventMask.EXPOSURE_MASK
        };
        this.window = new Gdk.Window (get_parent_window (), attrs, 0);
        this.window.move_resize (this.allocation.x, this.allocation.y,
                                 this.allocation.width, this.allocation.height);

        this.window.set_user_data (this);

        this.style = this.style.attach (this.window);
        this.style.set_background (this.window, Gtk.StateType.NORMAL);

        set_flags (Gtk.WidgetFlags.REALIZED);
    }

    public override bool expose_event (Gdk.EventExpose event) {
        var cr = Gdk.cairo_create (this.window);

        Gdk.cairo_set_source_color (cr, this.style.fg[this.state]);

        // And draw the text in the middle of the allocated space
        int fontw, fonth;
        this.layout.get_pixel_size (out fontw, out fonth);
        cr.move_to ((this.allocation.width - fontw) / 2,
                    (this.allocation.height - fonth) / 2);
        Pango.cairo_update_layout (cr, this.layout);
        Pango.cairo_show_layout (cr, this.layout);

        return true;
    }
}

public class PointsEntry : Gtk.ComboBoxEntry {
    public double points;
    public int  function;
    public uint digits;

    public PointsEntry () {
        points = 0;
        function = PointsFce.OWN;
        digits = 1;

        changed.connect(on_changed);
        var entry = get_child() as Gtk.Entry;
        entry.insert_text.connect(on_insert_text);

        fill_model ();
        set_wrap_width (5);
    }

    private void fill_model () {
        var model = new Gtk.ListStore(2, typeof(int), typeof(string));
        set_model(model);
        set_text_column (1);

        Gtk.TreeIter it;
        int   [] values = PointsFce.values();
        string [] labels = PointsFce.labels();
        for (uint i = 0; i < values.length; i++) {
            model.append(out it);
            model.set_value(it, 0, values[i]);
            model.set_value(it, 1, labels[i]);
        }
    }

    private void update_points() {
        var format = "%%%ug".printf(digits);
        var model = this.model as Gtk.ListStore;
        Gtk.TreeIter iter;
        model.get_iter_first (out iter);    // own points are first
        model.set_value(iter, 1, format.printf(points));
    }

    public void set_digits(uint digits) {
        this.digits = digits;
        update_points ();
    }

    public uint get_digits() {
        return digits;
    }

    public void set_points(double points) {
        this.points = points;
        update_points();
    }

    public double get_points() {
        return points;
    }

    public void set_function(int function) {
        int [] values = PointsFce.values();
        assert (function in values);

        this.function = function;
        int pos = 0;
        for (int i = 0; i < values.length; i++ ) {
            if (function == values[i]) {
                pos = i;
                break;
            }
        }
        set_active (pos);
    }

    public int get_function () {
        return function;
    }

    public void on_changed () {
        var model = this.model as Gtk.ListStore;
        Gtk.TreeIter iter;
        if (get_active_iter (out iter)){
            Value function_value;
            model.get_value(iter, 0, out function_value);
            function = function_value.get_int();
        } else {    // no iter -> just new string -> points
            if (Regex.match_simple ("^[0-9]*(\\.|,)?[0-9]*$", get_active_text())) {
                modify_text(Gtk.StateType.NORMAL, null);
                set_points(double.parse(get_active_text().replace(",", ".")));
                function = PointsFce.OWN;
                set_active(0);
            } else {
                // set error if it is not correct number (more then one separator)
                modify_text(Gtk.StateType.NORMAL, Gdk.Color(){red = uint16.MAX});
            }
        }
    }

    public void on_insert_text (string text, int length, ref int position) {
        var labels = PointsFce.labels();
        if (text in labels)     // text is one of label, so it is ok
            return;
        // stop insert text which is not number
        if (! Regex.match_simple ("^[0-9]*(\\.|,)?[0-9]*$", text))
            GLib.Signal.stop_emission_by_name (get_child(), "insert-text");
    }
}

public class ColorButton : Gtk.Button {
    private Node node;
    private Gtk.DrawingArea color_widget;
    private Gdk.Color color;
    private bool default_color;

    private Gtk.ColorSelection ? color_selection;
    private Gtk.DrawingArea ? drawing_color;
    private Gtk.RadioButton ? radio_default;
    private Gtk.RadioButton ? radio_parent;
    private Gtk.RadioButton ? radio_own;

    public ColorButton (Node node) {
        this.node = node;
        color = node.color;
        default_color = node.default_color;

        color_widget = new Gtk.DrawingArea ();
        color_widget.modify_bg(Gtk.StateType.NORMAL, color);
        color_widget.modify_bg(Gtk.StateType.PRELIGHT, color);
        color_widget.set_size_request(20, 20);
        set_image (color_widget);

        clicked.connect(() => {dialog();});
    }

    public void get_color (out Gdk.Color color) {
        color = this.color;
    }

    public void dialog () {
        try {
            var builder = new Gtk.Builder ();
            builder.add_from_file (DATA + "/ui/color_dialog.ui");
            builder.connect_signals (this);

            var dialog = builder.get_object ("color_dialog")
                        as Gtk.ColorSelectionDialog;
            //dialog.set_modal(true);

            var button_internal = builder.get_object ("colorsel-ok_button1")
                        as Gtk.Widget;
            button_internal.hide_all();

            var button_ok = new Gtk.Button.from_stock(Gtk.Stock.OK);
            button_ok.show_all();
            dialog.add_action_widget (button_ok, Gtk.ResponseType.OK);

            color_selection = dialog.get_color_selection() as Gtk.ColorSelection;

            drawing_color = builder.get_object ("drawing_color")
                        as Gtk.DrawingArea;
            drawing_color.modify_bg(Gtk.StateType.NORMAL, color);

            // couse this settings call dialog_color_changed event
            radio_default = builder.get_object ("radio_default")
                        as Gtk.RadioButton;
            radio_parent = builder.get_object ("radio_parent")
                        as Gtk.RadioButton;
            radio_own = builder.get_object ("radio_own")
                        as Gtk.RadioButton;

            color_selection.set_current_color(color);
            if (default_color || color.equal(node.map.pref.default_color))
                radio_default.set_active(true);
            else if (node.parent == null || !color.equal(node.parent.color))
                radio_own.set_active(true);
            else
                radio_parent.set_active(true);

            if (dialog.run() == Gtk.ResponseType.OK) {
                if (radio_default.get_active()) {
                    color = node.map.pref.default_color;
                    default_color = true;
                } else if (radio_own.get_active()) {
                    color = color_selection.current_color;
                    default_color = false;
                } else {
                    default_color = true;
                    if (node.parent != null)
                        color = node.parent.color;
                    else
                        color = node.map.pref.default_color;
                }
                color_widget.modify_bg(Gtk.StateType.NORMAL, color);
                color_widget.modify_bg(Gtk.StateType.PRELIGHT, color);
            }

            dialog.destroy();

            drawing_color = null;
            radio_default = null;
            radio_parent = null;
            radio_own = null;
            color_selection = null;
        } catch (Error e) {
            stderr.printf ("Could not load app UI: %s\n", e.message);
        }
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT color_button_dialog_color_changed")]
    public void dialog_color_changed (Gtk.Widget sender) {
        //if (radio_own.get_active())
        //    drawing_color.modify_bg(Gtk.StateType.NORMAL, color_selection.current_color);
        radio_own.set_active(true);
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT color_button_dialog_default_toggled")]
    public void dialog_default_toggled (Gtk.Widget sender) {
        drawing_color.modify_bg(Gtk.StateType.NORMAL, node.map.pref.default_color);
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT color_button_dialog_parent_toggled")]
    public void dialog_parent_toggled (Gtk.Widget sender) {
        if (node.parent != null)
            drawing_color.modify_bg(Gtk.StateType.NORMAL, node.parent.color);
        else
            drawing_color.modify_bg(Gtk.StateType.NORMAL, node.map.pref.default_color);
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT color_button_dialog_own_toggled")]
    public void dialog_radio_toggled (Gtk.Widget sender) {
        drawing_color.modify_bg(Gtk.StateType.NORMAL, color_selection.current_color);
    }
}

public class WidgetRound {
    public WidgetRound ? next;
    public Gtk.Widget widget;
    public WidgetRound (Gtk.Widget w) {
        widget = w;
        next = null;
    }

    public unowned WidgetRound append (Gtk.Widget w) {
        next = new WidgetRound (w);
        return next;
    }

}

public class ToggleFlagButton : Gtk.ToggleToolButton {
    public ToggleFlagButton (string flag) {
        name = flag;
        set_label(_(flag));
        set_tooltip_text(_(flag));
        var icon_path = DATA + "/icons/" + flag + ".svg";

        try {
            var pb = new Gdk.Pixbuf.from_file (icon_path);
            int width, height;
            Gtk.icon_size_lookup (Gtk.IconSize.SMALL_TOOLBAR, out width, out height);
            set_icon_widget(new Gtk.Image.from_pixbuf(
                        pb.scale_simple(width, height, Gdk.InterpType.BILINEAR)));
        } catch (Error e) {
            stderr.printf("Icon file %s not found!\n", icon_path);
            set_icon_widget(new Gtk.Image.from_stock ( Gtk.Stock.MISSING_IMAGE,
                                    Gtk.IconSize.SMALL_TOOLBAR));
        }

    }
}

public class EditForm : Gtk.VBox {
    public Node node;
    public Gtk.Entry entry;
    public Gtk.ScrolledWindow text_scroll;
    public Gtk.TextView text_view;
    public PointsEntry points;
    //public Gtk.ColorButton btn_color;
    public ColorButton btn_color;
    public Gtk.Button btn_save;
    public Gtk.Button btn_close;
    public Gtk.Toolbar icons_box;

    public signal void close();
    public signal void expand_change(bool is_expand, int width, int height);
    public bool newone;
    public bool is_expand;
    public WidgetRound ? actives;
    public List<Gtk.Widget> focusable_widgets;

    public EditForm (Node node, bool newone, Preferences pref){
        this.node = node;
        this.newone = newone;

        entry = new Gtk.Entry();
        actives = new WidgetRound (entry);
        var last = actives;
        focusable_widgets = new List<Gtk.Widget> ();
        set_focus_chain (focusable_widgets);

        try {
            var ico = new Gdk.Pixbuf.from_file (DATA + "/icons/comment_edit.png");
            entry.set_icon_from_pixbuf (Gtk.EntryIconPosition.SECONDARY, ico);
        } catch (Error e) {
            stderr.printf ("%s\n", e.message);
            entry.set_icon_from_stock (Gtk.EntryIconPosition.SECONDARY, Gtk.Stock.EDIT);
        }

        entry.set_icon_sensitive (Gtk.EntryIconPosition.SECONDARY, true);
        entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Extends edit"));
        entry.set_text (node.title);
        entry.key_press_event.connect (on_key_press_event);
        entry.icon_release.connect (on_change_expand);

        var font_desc = node.font_desc.copy();
        font_desc.set_size ((int) GLib.Math.lrint (
                font_desc.get_size() / (pref.dpi / 100.0)));

        entry.modify_font(font_desc);
        int width = (node.area.width > NONE_TITLE.length * pref.node_font_size) ?
                node.area.width : NONE_TITLE.length * pref.node_font_size;
        int ico_size = (node.text.length > 0 || node.title.length == 0) ? 0 : ICO_SIZE;
        entry.set_size_request (width + pref.font_padding * 2 + ico_size, -1);
        focusable_widgets.append (entry);

        points = new PointsEntry ();
        points.set_digits(1);
        points.set_points(node.points);
        points.set_function(node.function);
        points.modify_font(font_desc);
        points.key_press_event.connect (on_key_press_event);
        points.get_child().set_size_request(POINTS_LENGTH * pref.node_font_size
                                + pref.font_padding * 2, -1);

        btn_color = new ColorButton (node);
        btn_color.set_can_focus (true);
        last = last.append (btn_color);
        focusable_widgets.append (btn_color);

        btn_save = new Gtk.Button.from_stock (Gtk.Stock.SAVE);
        btn_save.clicked.connect(() => {save(); close();});
        last = last.append (btn_save);
        focusable_widgets.append (btn_save);

        btn_close = new Gtk.Button.from_stock (Gtk.Stock.CLOSE);
        btn_close.clicked.connect(() => {close();});
        last = last.append (btn_close);
        focusable_widgets.append (btn_close);

        icons_box = new Gtk.Toolbar();
        var flags = node_flags();
        for (uint i = 0; i < flags.length; i++) {
            var tfb = new ToggleFlagButton(flags[i]);
            if (flags[i] in this.node.flags)
                tfb.set_active(true);
            tfb.toggled.connect (() => { flag_toogled(tfb); });
            icons_box.add (tfb);
        }
        icons_box.show_all();
        last = last.append (icons_box);
        focusable_widgets.append (icons_box);

        text_view = new Gtk.TextView ();
        text_view.modify_font (pref.text_font);
        text_view.get_buffer().set_text(node.text);
        last = last.append (text_view);
        focusable_widgets.append (text_view);

        text_scroll = new Gtk.ScrolledWindow (null, null);
        text_scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        text_scroll.get_hscrollbar ().set_size_request (-1,7);
        text_scroll.get_vscrollbar ().set_size_request (7,-1);
        text_scroll.add_with_viewport (text_view);
        text_scroll.set_size_request (-1, pref.text_height);

        var box = new Gtk.HBox(false, 0);
        box.pack_start(entry);
        box.pack_start(points);
        box.pack_start (btn_color);
        box.pack_start(btn_save);
        box.pack_start(btn_close);

        pack_start(box);
        pack_start(icons_box);
        pack_start(text_scroll);

        collapse ();
        box.show ();
        entry.show_all ();
        if (node.points != 0)
            points.show_all ();
        show ();
    }

    public virtual signal void save (){
        newone = false;
        node.set_title (entry.get_text ());
        var buffer = text_view.get_buffer ();
        Gtk.TextIter start, end;
        buffer.get_start_iter (out start);
        buffer.get_end_iter (out end);
        node.set_text (buffer.get_text (start, end, true));
        Gdk.Color color;
        btn_color.get_color (out color);
        node.set_color (color);

        if (points.get_function() == PointsFce.OWN)
            node.set_points (points.get_points (), PointsFce.OWN);
        else
            node.set_points (node.points, points.get_function());
    }

    public bool on_key_press_event (Gdk.EventKey e){
        if (e.keyval == 65307){
            close();
            return true;
        } else if (e.keyval == 65421 || e.keyval == 65293) {
            save();
            close();
            return true;
        } else if (e.keyval == 65471) {
            do_change_expand ();
            return true;
        } else if (e.keyval == 65289 && is_expand) {
            return false;
            /*var it = actives;
            while (it != null) {
                if (it.widget.has_focus) {
                    if (it.next != null)
                        it.next.widget.grab_focus ();
                    else
                        actives.widget.grab_focus ();

                    stdout.printf ("next Widget %s has focus\n" ,it.next.widget.name);
                    break;
                }
                stdout.printf ("Widget %s has not focus\n" ,it.widget.name);
                it = it.next;

            }
            actives.widget.grab_focus ();
            return true;
            */
        }

        //stdout.printf ("EditForm key press %s (%u)\n",
        //        Gdk.keyval_name(e.keyval), e.keyval);
        return false;
    }

    public void on_change_expand (Gtk.EntryIconPosition p0, Gdk.Event p1) {
        if (p0 != Gtk.EntryIconPosition.SECONDARY)
            return;

        do_change_expand ();
    }

    public void do_change_expand (){
        if (is_expand)
            collapse ();
        else
            expand ();

        //int width, height;
        //get_size_request (out width, out height);
        //expand_change(is_expand, allocation.width, allocation.height);
    }

    public override void set_focus_child (Gtk.Widget ? widget) {
        base.set_focus_child(widget);
        /*if (widget != null)
            stdout.printf ("focused child %s\n" ,widget.name);
        else
            stdout.printf ("no child focused\n");*/
    }

    public void collapse () {
        is_expand = false;
        if (node.points == 0)
            points.hide ();
        text_scroll.hide ();
        btn_color.hide ();
        btn_save.hide ();
        btn_close.hide ();
        icons_box.hide ();
    }

    public void expand () {
        is_expand = true;
        show_all();
    }

    // change flag setting of node when toogle tool button is toggled
    public void flag_toogled (Gtk.ToggleToolButton ttb) {
        if (ttb.get_active())
            this.node.flags.add(ttb.name);
        else if (ttb.name in this.node.flags)
            this.node.flags.remove(ttb.name);
    }
}
