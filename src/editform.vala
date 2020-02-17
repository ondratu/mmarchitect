/*
 * DESCRIPTION      Edit form for nodes.
 * PROJECT          Mind Map Architect
 * AUTHOR           Ondrej Tuma <mcbig@zeropage.cz>
 *
 * Copyright (C) Ondrej Tuma 2011
 * Code is present with BSD licence.
 */

// modules: gtk+-3.0
// sources: preferences.vala

public class PointsEntry : Gtk.ComboBoxText {
    public double points;
    public int function;
    public uint digits;
    public Gtk.Entry ? entry { get; private set; }

    public PointsEntry () {
        Object (has_entry: true);
        points = 0;
        function = PointsFce.OWN;
        digits = 1;

        //changed.connect(on_changed);
        entry = (Gtk.Entry) get_child ();
        entry.set_width_chars (4);
        fill_model ();
        set_wrap_width (5);
    }

    private void fill_model () {
        var model = new Gtk.ListStore (2, typeof (int), typeof (string));
        set_model (model);
        set_entry_text_column (1);

        Gtk.TreeIter it;
        int [] values = PointsFce.values ();
        string [] labels = PointsFce.labels ();
        for (uint i = 0; i < values.length; i++) {
            model.append (out it);
            model.set_value (it, 0, values[i]);
            model.set_value (it, 1, labels[i]);
        }
    }

    private void update_points () {
        var format = "%%%ug".printf (this.digits);
        var model = (Gtk.ListStore) this.model;
        Gtk.TreeIter iter;
        model.get_iter_first (out iter);    // own points are first
        model.set_value (iter, 1, format.printf (points));
    }

    public void set_digits (uint digits) {
        this.digits = digits;
        update_points ();
    }

    public uint get_digits () {
        return digits;
    }

    public void set_points (double points) {
        this.points = points;
        update_points ();
    }

    public double get_points () {
        return points;
    }

    public void set_function (int function) {
        int [] values = PointsFce.values ();
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

    public override void changed () {
        if (get_active () > 0){
            function = get_active ();
        } else {
            var text = this.get_active_text ().replace (",", ".");
            if (Regex.match_simple ("^[0-9]*(\\.)?[0-9]*$", text)) {
                points = double.parse (text);
                function = PointsFce.OWN;
            } else {
                set_points (double.parse (text));
                set_active (0);
                function = PointsFce.OWN;
            }
        }
    }
}

private class Swatch: Gtk.DrawingArea {
    private Gdk.RGBA rgba;

    public void set_rgba (Gdk.RGBA rgba){
        this.rgba = rgba;
        queue_draw ();
    }

    public Gdk.RGBA get_rgba () {
        return rgba;
    }

    public override bool draw (Cairo.Context cr) {
        var allocation = Gtk.Allocation ();
        get_allocation (out allocation);

        cr.set_source_rgb (rgba.red, rgba.green, rgba.blue);
        cr.rectangle (0, 0, allocation.width, allocation.height);
        cr.fill_preserve ();

        return false;
    }
}

public class ColorButton : Gtk.Button {
    private Node node;
    private Swatch color_widget;
    private bool default_color;
    private bool rgba_lock;

    private unowned Gtk.ColorChooserDialog chooser;
    private unowned Gtk.Window window;

    public ColorButton (Node node, Gtk.Window window) {
        this.node = node;
        default_color = node.default_color;
        color_widget = new Swatch ();
        rgba_lock = true;
        this.window = window;

        color_widget.set_rgba (node.rgb);
        color_widget.set_size_request (20, 20);
        set_image (this.color_widget);
    }

    public Gdk.RGBA get_rgba () {
        return color_widget.get_rgba ();
    }

    public override void clicked () {
        try {
            var rgba = color_widget.get_rgba ();

            var builder = new Gtk.Builder ();
            builder.add_from_file (DATA_DIR + "/ui/color_dialog.ui");
            builder.connect_signals (this);

            chooser = (Gtk.ColorChooserDialog)
                    builder.get_object ("color_dialog");
            chooser.set_transient_for (window);
            chooser.set_rgba (rgba);

            // couse this settings call dialog_color_changed event
            var radio_default = (Gtk.RadioButton)
                    builder.get_object ("radio_default");
            var radio_parent = (Gtk.RadioButton)
                    builder.get_object ("radio_parent");
            var radio_own = (Gtk.RadioButton)
                    builder.get_object ("radio_own");

            if (default_color || rgba.equal (node.map.pref.default_color)) {
                radio_default.set_active (true);
            } else if (node.parent == null || !rgba.equal (node.parent.rgb)) {
                radio_own.set_active (true);
            } else {
                radio_parent.set_active (true);
            }

            rgba_lock = false;     // unlock rgba notify
            chooser.notify.connect ((property) => {
                if (!rgba_lock && property.name == "rgba") {
                    radio_own.set_active (true);
                }
            });

            if (chooser.run () == Gtk.ResponseType.OK) {
                if (radio_default.get_active ()) {
                    color_widget.set_rgba (node.map.pref.default_color);
                    default_color = true;
                } else if (radio_own.get_active ()) {
                    color_widget.set_rgba (chooser.get_rgba ());
                    default_color = false;
                } else {
                    this.default_color = true;
                    if (node.parent != null) {
                        color_widget.set_rgba (node.parent.rgb);
                    } else {
                        color_widget.set_rgba (node.map.pref.default_color);
                    }
                }
            }

            chooser.destroy ();
        } catch (Error e) {
            stderr.printf ("Could not load app UI: %s\n", e.message);
        }
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT color_button_default_toggled")]
    public void default_toggled (Gtk.Widget sender) {
        if ((sender as Gtk.ToggleButton).get_active ()){
            rgba_lock = true;
            chooser.set_rgba (this.node.map.pref.default_color);
            rgba_lock = false;
        }
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT color_button_parent_toggled")]
    public void parent_toggled (Gtk.Widget sender) {
        if (((Gtk.ToggleButton) sender).get_active ()){
            rgba_lock = true;
            if (node.parent != null) {
                this.chooser.set_rgba (this.node.parent.rgb);
            } else {
                chooser.set_rgba (node.map.pref.default_color);
            }
            rgba_lock = false;
        }
    }
}

public class ToggleFlagButton : Gtk.ToggleToolButton {
    public ToggleFlagButton (string flag) {
        name = flag;
        set_label ( _(flag));
        set_tooltip_text (_(flag));
        var icon_path = DATA_DIR + "/icons/" + flag + ".svg";

        try {
            var pb = new Gdk.Pixbuf.from_file (icon_path);
            int width, height;
            Gtk.icon_size_lookup (
                Gtk.IconSize.SMALL_TOOLBAR, out width, out height);
            set_icon_widget (
                    new Gtk.Image.from_pixbuf (
                        pb.scale_simple (
                                width, height, Gdk.InterpType.BILINEAR)));
        } catch (Gdk.PixbufError.UNKNOWN_TYPE e) {
             set_icon_widget (
                    new SVGImage (icon_path, Gtk.IconSize.SMALL_TOOLBAR));
        } catch (Error e) {
            stderr.printf ("Icon file %s not found!\n", icon_path);
            set_icon_widget (new Gtk.Image.from_icon_name (
                    "image-missing",
                    Gtk.IconSize.SMALL_TOOLBAR));
        }

    }
}

public class EditForm : Gtk.Box {
    private Node node;
    public Gtk.Entry entry = new Gtk.Entry ();
    private Gtk.ScrolledWindow text_scroll = new Gtk.ScrolledWindow (null, null);
    private Gtk.TextView text_view = new Gtk.TextView ();
    private PointsEntry points = new PointsEntry ();
    private Gtk.Button btn_save = new Gtk.Button.from_icon_name ("document-save");
    private Gtk.Button btn_close = new Gtk.Button.from_icon_name ("window-close");
    private ColorButton btn_color;
    private Gtk.Toolbar icons_box = new Gtk.Toolbar ();
    private Gtk.CssProvider provider = new Gtk.CssProvider ();

    public signal void close ();
    public signal void expand_change (bool is_expand, int width, int height);
    public bool newone;
    public bool is_expand = false;

    public EditForm (Node node, bool newone, Preferences pref, Gtk.Window window) {
        Object (orientation: Gtk.Orientation.VERTICAL, spacing: 0);
        // TODO: move application style to css file
        string editform_css = ".editform { border: 1px solid gray; border-radius: 4px; }";
        // TODO: move style provider to application
        var form_provider = new StaticProvider (editform_css);
        try {
            form_provider.load_from_data (editform_css);
        } catch (Error e) {
            stderr.printf ("Problem with style %s\n -> %s\n", editform_css, e.message);
        }

        get_style_context ().add_class ("editform");
        this.node = node;
        this.newone = newone;

        entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY,
                                            "text-editor-symbolic");

        entry.set_icon_sensitive (Gtk.EntryIconPosition.SECONDARY, true);
        entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Extends edit"));
        entry.set_text (node.title);
        entry.key_press_event.connect (on_key_press_event);
        entry.icon_release.connect (on_change_expand);

        prepare_style (node.font_desc, pref.text_font);
        entry.get_style_context ().add_class ("editform_entry");

        int width = (node.area.width > NONE_TITLE.length * pref.node_font_size) ?
                node.area.width : NONE_TITLE.length * pref.node_font_size;
        int ico_size = (node.text.length > 0 || node.title.length == 0) ? 0 : ICO_SIZE;
        entry.set_size_request (width + pref.font_padding * 2 + ico_size, -1);

        points.set_digits (1);
        points.set_points (node.points);
        points.set_function (node.function);
        points.get_style_context ().add_class ("editform_entry");
        points.entry.set_size_request (POINTS_LENGTH * pref.node_font_size
                                       + pref.font_padding * 2, -1);
        points.entry.key_press_event.connect (on_key_press_event);

        btn_color = new ColorButton (node, window);

        btn_save.clicked.connect (() => {save (); close ();});
        btn_close.clicked.connect (() => {close ();});

        icons_box.set_style (Gtk.ToolbarStyle.ICONS);
        var flags = node_flags ();
        for (uint i = 0; i < flags.length; i++) {
            var tfb = new ToggleFlagButton (flags[i]);
            if (flags[i] in node.flags) {
                tfb.set_active (true);
            }
            icons_box.add (tfb);
        }

        text_view.set_wrap_mode (Gtk.WrapMode.WORD);
        text_view.get_style_context ().add_class ("editform_view");
        text_view.buffer.text = node.text;

        text_scroll.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        text_scroll.get_hscrollbar ().set_size_request (-1, 7);
        text_scroll.get_vscrollbar ().set_size_request (7, -1);
        text_scroll.add (text_view);
        text_scroll.set_size_request (-1, pref.text_height);

        var topbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        topbox.pack_start (entry);
        topbox.pack_start (points, false, false);
        topbox.pack_start (btn_color);
        topbox.pack_start (btn_save);
        topbox.pack_start (btn_close);

        var ebox = new Gtk.EventBox ();
        ebox.add (icons_box);   // becouse direct pack_start crash map background

        pack_start (topbox);
        pack_start (ebox);
        pack_start (text_scroll);

        topbox.show ();
        entry.show_all ();
        if (node.points != 0) {
            points.show_all ();
        }
        show ();
    }

    public void prepare_style (Pango.FontDescription entry_font,
                               Pango.FontDescription view_font)
    {
        Gtk.StyleContext.add_provider_for_screen (
            Gdk.Screen.get_default (),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        try {
            provider.load_from_data (font_to_css (entry_font, "editform_entry")
                                     + font_to_css (view_font, "editform_view"));
        } catch (Error e) {
            stderr.printf ("Problem with style: %s\n", e.message);
        }
    }


    public virtual signal void save () {
        newone = false;
        var buffer = text_view.get_buffer ();
        Gtk.TextIter start, end;
        buffer.get_start_iter (out start);
        buffer.get_end_iter (out end);
        node.set_text (buffer.get_text (start, end, true));
        node.set_rgb (btn_color.get_rgba ());

        if (points.get_function () == PointsFce.OWN) {
            node.set_points (points.get_points (), PointsFce.OWN);
        } else {
            node.set_points (node.points, points.get_function ());
        }

        // save icons
        this.icons_box.forall ((w) => {
            if (!(w is ToggleFlagButton)) return;

            var ttb = w as ToggleFlagButton;
            if (ttb.get_active ())
                node.flags.add (ttb.name);
            else if (ttb.name in node.flags)
                node.flags.remove (ttb.name);
        });

        // set title at the end, couse set_title call get_size_request on node
        node.set_title (entry.get_text ());
    }

    public bool on_key_press_event (Gdk.EventKey e) {
        if (e.keyval == 65307) {                                 // Escape
            close ();
            return true;
        } else if (e.keyval == 65421 || e.keyval == 65293) {    // KP_Enter || Return
            save ();
            close ();
            return true;
        } else if (e.keyval == 65471) {                         // F2
            do_change_expand ();
            return true;
        }
        return false;                                           // no catch
    }

    public void on_change_expand (Gtk.EntryIconPosition p0, Gdk.Event p1) {
        if (p0 != Gtk.EntryIconPosition.SECONDARY)
            return;
        do_change_expand ();
    }

    public void do_change_expand () {
        if (is_expand) {
            collapse ();
        } else {
            do_expand ();
        }
    }

    public void collapse () {
        is_expand = false;
        if (node.points == 0) {
            points.hide ();
        }
        text_scroll.hide ();
        btn_color.hide ();
        btn_save.hide ();
        btn_close.hide ();
        icons_box.hide ();
    }

    public void do_expand () {
        is_expand = true;
        show_all ();
    }

    // change flag setting of node when toogle tool button is toggled
    public void flag_toogled (Gtk.ToggleToolButton ttb) {
        if (ttb.get_active ())
            node.flags.add (ttb.name);
        else if (ttb.name in node.flags)
            node.flags.remove (ttb.name);
    }
}
