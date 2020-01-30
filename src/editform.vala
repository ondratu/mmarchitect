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
    public int  function;
    public uint digits;
    public Gtk.Entry ? entry { get; private set; }

    public PointsEntry () {
        Object(has_entry: true);
        this.points = 0;
        this.function = PointsFce.OWN;
        this.digits = 1;

        //changed.connect(on_changed);
        this.entry = get_child() as Gtk.Entry;
        this.entry.set_width_chars (4);
        this.fill_model ();
        this.set_wrap_width (5);
    }

    private void fill_model () {
        var model = new Gtk.ListStore(2, typeof(int), typeof(string));
        this.set_model(model);
        this.set_entry_text_column (1);

        Gtk.TreeIter it;
        int [] values = PointsFce.values();
        string [] labels = PointsFce.labels();
        for (uint i = 0; i < values.length; i++) {
            model.append(out it);
            model.set_value(it, 0, values[i]);
            model.set_value(it, 1, labels[i]);
        }
    }

    private void update_points() {
        var format = "%%%ug".printf(this.digits);
        var model = this.model as Gtk.ListStore;
        Gtk.TreeIter iter;
        model.get_iter_first (out iter);    // own points are first
        model.set_value(iter, 1, format.printf(this.points));
    }

    public void set_digits(uint digits) {
        this.digits = digits;
        this.update_points ();
    }

    public uint get_digits() {
        return this.digits;
    }

    public void set_points(double points) {
        this.points = points;
        this.update_points();
    }

    public double get_points() {
        return this.points;
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
        this.set_active (pos);
    }

    public int get_function () {
        return this.function;
    }

    public override void changed () {
        if (this.get_active() > 0){
            this.function = this.get_active();
        } else {
            var text = this.get_active_text().replace(",", ".");
            if (Regex.match_simple ("^[0-9]*(\\.)?[0-9]*$", text)) {
                this.points = double.parse(text);
                this.function = PointsFce.OWN;
            } else {
                this.set_points(double.parse(text));
                this.set_active(0);
                this.function = PointsFce.OWN;
            }
        }
    }
}

private class Swatch: Gtk.DrawingArea {
    private Gdk.RGBA rgba;

    public void set_rgba(Gdk.RGBA rgba){
        this.rgba = rgba;
        this.queue_draw();
    }

    public Gdk.RGBA get_rgba() {
        return this.rgba;
    }

    public override bool draw (Cairo.Context cr) {
        var allocation = Gtk.Allocation();
        this.get_allocation (out allocation);

        cr.set_source_rgb (this.rgba.red, this.rgba.green, this.rgba.blue);
        cr.rectangle(0, 0, allocation.width, allocation.height);
        cr.fill_preserve();

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
        this.default_color = node.default_color;
        this.color_widget = new Swatch ();
        this.rgba_lock = true;
        this.window = window;

        this.color_widget.set_rgba(node.rgb);
        this.color_widget.set_size_request(20, 20);
        this.set_image (this.color_widget);
    }

    public Gdk.RGBA get_rgba () {
        return this.color_widget.get_rgba();
    }

    public override void clicked () {
        try {
            var rgba = this.color_widget.get_rgba();

            var builder = new Gtk.Builder ();
            builder.add_from_file (DATA_DIR + "/ui/color_dialog.ui");
            builder.connect_signals (this);

            this.chooser = builder.get_object ("color_dialog")
                    as Gtk.ColorChooserDialog;
            this.chooser.set_transient_for(this.window);
            this.chooser.set_rgba(rgba);

            // couse this settings call dialog_color_changed event
            var radio_default = builder.get_object ("radio_default")
                    as Gtk.RadioButton;
            var radio_parent = builder.get_object ("radio_parent")
                    as Gtk.RadioButton;
            var radio_own = builder.get_object ("radio_own")
                    as Gtk.RadioButton;

            if (this.default_color || rgba.equal(this.node.map.pref.default_color)) {
                radio_default.set_active(true);
            } else if (this.node.parent == null || !rgba.equal(this.node.parent.rgb)) {
                radio_own.set_active(true);
            } else {
                radio_parent.set_active(true);
            }

            this.rgba_lock = false;     // unlock rgba notify
            this.chooser.notify.connect((property) => {
                if (!this.rgba_lock && property.name == "rgba") {
                    radio_own.set_active(true);
                }
            });

            if (this.chooser.run() == Gtk.ResponseType.OK) {
                if (radio_default.get_active()) {
                    this.color_widget.set_rgba(this.node.map.pref.default_color);
                    this.default_color = true;
                } else if (radio_own.get_active()) {
                    this.color_widget.set_rgba(this.chooser.get_rgba());
                    this.default_color = false;
                } else {
                    this.default_color = true;
                    if (this.node.parent != null) {
                        this.color_widget.set_rgba(this.node.parent.rgb);
                    } else {
                        this.color_widget.set_rgba(this.node.map.pref.default_color);
                    }
                }
            }

            this.chooser.destroy();
        } catch (Error e) {
            stderr.printf ("Could not load app UI: %s\n", e.message);
        }
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT color_button_default_toggled")]
    public void default_toggled (Gtk.Widget sender) {
        if ((sender as Gtk.ToggleButton).get_active()){
            this.rgba_lock = true;
            this.chooser.set_rgba(this.node.map.pref.default_color);
            this.rgba_lock = false;
        }
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT color_button_parent_toggled")]
    public void parent_toggled (Gtk.Widget sender) {
        if ((sender as Gtk.ToggleButton).get_active()){
            this.rgba_lock = true;
            if (node.parent != null) {
                this.chooser.set_rgba(this.node.parent.rgb);
            } else {
                this.chooser.set_rgba(this.node.map.pref.default_color);
            }
            this.rgba_lock = false;
        }
    }
}

public class ToggleFlagButton : Gtk.ToggleToolButton {
    public ToggleFlagButton (string flag) {
        name = flag;
        set_label(_(flag));
        set_tooltip_text(_(flag));
        var icon_path = DATA_DIR + "/icons/" + flag + ".svg";

        try {
            var pb = new Gdk.Pixbuf.from_file (icon_path);
            int width, height;
            Gtk.icon_size_lookup (Gtk.IconSize.SMALL_TOOLBAR, out width, out height);
            set_icon_widget (new Gtk.Image.from_pixbuf(
                        pb.scale_simple(width, height, Gdk.InterpType.BILINEAR)));
        } catch (Gdk.PixbufError.UNKNOWN_TYPE e) {
             set_icon_widget (new SVGImage(icon_path, Gtk.IconSize.SMALL_TOOLBAR));
        } catch (Error e) {
            stderr.printf("Icon file %s not found!\n", icon_path);
            set_icon_widget(new Gtk.Image.from_icon_name (
                    "image-missing",
                    Gtk.IconSize.SMALL_TOOLBAR));
        }

    }
}

public class EditForm : Gtk.Box {
    private Node node;
    public Gtk.Entry entry = new Gtk.Entry();
    private Gtk.ScrolledWindow text_scroll = new Gtk.ScrolledWindow (null, null);
    private Gtk.TextView text_view = new Gtk.TextView ();
    private PointsEntry points = new PointsEntry();
    private Gtk.Button btn_save = new Gtk.Button.from_icon_name ("document-save");
    private Gtk.Button btn_close = new Gtk.Button.from_icon_name ("window-close");
    private ColorButton btn_color;
    private Gtk.Toolbar icons_box = new Gtk.Toolbar();
    private Gtk.CssProvider provider = new Gtk.CssProvider();

    public signal void close();
    public signal void expand_change(bool is_expand, int width, int height);
    public bool newone;
    public bool is_expand = false;

    public EditForm (Node node, bool newone, Preferences pref, Gtk.Window window){
        Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);
        // TODO: move application style to css file
        string editform_css = ".editform { border: 1px solid gray; border-radius: 4px; }";
        // TODO: move style provider to application
        var form_provider = new StaticProvider (editform_css);
        try {
            form_provider.load_from_data(editform_css);
        } catch (Error e) {
            stderr.printf ("Problem with style %s\n -> %s\n", editform_css, e.message);
        }

        this.get_style_context().add_class ("editform");
        this.node = node;
        this.newone = newone;

        this.entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY,
                                            "text-editor-symbolic");

        this.entry.set_icon_sensitive (Gtk.EntryIconPosition.SECONDARY, true);
        this.entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Extends edit"));
        this.entry.set_text (node.title);
        this.entry.key_press_event.connect (this.on_key_press_event);
        this.entry.icon_release.connect (this.on_change_expand);

        this.prepare_style (node.font_desc, pref.text_font);
        this.entry.get_style_context().add_class ("editform_entry");

        int width = (node.area.width > NONE_TITLE.length * pref.node_font_size) ?
                node.area.width : NONE_TITLE.length * pref.node_font_size;
        int ico_size = (node.text.length > 0 || node.title.length == 0) ? 0 : ICO_SIZE;
        this.entry.set_size_request (width + pref.font_padding * 2 + ico_size, -1);

        this.points.set_digits(1);
        this.points.set_points(this.node.points);
        this.points.set_function(this.node.function);
        this.points.get_style_context().add_class ("editform_entry");
        this.points.entry.set_size_request(POINTS_LENGTH * pref.node_font_size
                                + pref.font_padding * 2, -1);
        this.points.entry.key_press_event.connect (this.on_key_press_event);

        this.btn_color = new ColorButton (node, window);

        this.btn_save.clicked.connect(() => {save(); close();});
        this.btn_close.clicked.connect(() => {close();});

        this.icons_box.set_style (Gtk.ToolbarStyle.ICONS);
        var flags = node_flags();
        for (uint i = 0; i < flags.length; i++) {
            var tfb = new ToggleFlagButton(flags[i]);
            if (flags[i] in this.node.flags)
                tfb.set_active(true);
            this.icons_box.add (tfb);
        }

        this.text_view.set_wrap_mode (Gtk.WrapMode.WORD);
        this.text_view.get_style_context().add_class ("editform_view");
        this.text_view.buffer.text = node.text;

        this.text_scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        this.text_scroll.get_hscrollbar ().set_size_request (-1,7);
        this.text_scroll.get_vscrollbar ().set_size_request (7,-1);
        this.text_scroll.add (text_view);
        this.text_scroll.set_size_request (-1, pref.text_height);

        var topbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        topbox.pack_start (this.entry);
        topbox.pack_start (this.points, false, false);
        topbox.pack_start (this.btn_color);
        topbox.pack_start (this.btn_save);
        topbox.pack_start (this.btn_close);

        var ebox = new Gtk.EventBox ();
        ebox.add (icons_box);   // becouse direct pack_start crash map background

        this.pack_start (topbox);
        this.pack_start (ebox);
        this.pack_start (this.text_scroll);

        topbox.show ();
        this.entry.show_all ();
        if (node.points != 0)
            this.points.show_all ();
        this.show ();
    }

    public void prepare_style (Pango.FontDescription entry_font,
                               Pango.FontDescription view_font)
    {
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            this.provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        try {
            this.provider.load_from_data(font_to_css(entry_font, "editform_entry")
                                         + font_to_css(view_font, "editform_view"));
        } catch (Error e) {
            stderr.printf ("Problem with style: %s\n", e.message);
        }
    }


    public virtual signal void save (){
        this.newone = false;
        var buffer = text_view.get_buffer ();
        Gtk.TextIter start, end;
        buffer.get_start_iter (out start);
        buffer.get_end_iter (out end);
        this.node.set_text (buffer.get_text (start, end, true));
        this.node.set_rgb (this.btn_color.get_rgba());

        if (this.points.get_function () == PointsFce.OWN) {
            this.node.set_points (this.points.get_points (), PointsFce.OWN);
        } else {
            this.node.set_points (this.node.points, this.points.get_function ());
        }

        // save icons
        this.icons_box.forall((w) => {
            if (!(w is ToggleFlagButton)) return;

            var ttb = w as ToggleFlagButton;
            if (ttb.get_active())
                this.node.flags.add(ttb.name);
            else if (ttb.name in this.node.flags)
                this.node.flags.remove(ttb.name);
        });

        // set title at the end, couse set_title call get_size_request on node
        this.node.set_title (entry.get_text ());
    }

    public bool on_key_press_event (Gdk.EventKey e){
        if (e.keyval == 65307){                                 // Escape
            this.close();
            return true;
        } else if (e.keyval == 65421 || e.keyval == 65293) {    // KP_Enter || Return
            this.save();
            this.close();
            return true;
        } else if (e.keyval == 65471) {                         // F2
            this.do_change_expand ();
            return true;
        }
        return false;                                           // no catch
    }

    public void on_change_expand (Gtk.EntryIconPosition p0, Gdk.Event p1) {
        if (p0 != Gtk.EntryIconPosition.SECONDARY)
            return;
        this.do_change_expand ();
    }

    public void do_change_expand (){
        if (this.is_expand) {
            this.collapse ();
        } else {
            this.do_expand ();
        }
    }

    public void collapse () {
        this.is_expand = false;
        if (this.node.points == 0) {
            this.points.hide ();
        }
        this.text_scroll.hide ();
        this.btn_color.hide ();
        this.btn_save.hide ();
        this.btn_close.hide ();
        this.icons_box.hide ();
    }

    public void do_expand () {
        this.is_expand = true;
        this.show_all();
    }

    // change flag setting of node when toogle tool button is toggled
    public void flag_toogled (Gtk.ToggleToolButton ttb) {
        if (ttb.get_active())
            this.node.flags.add(ttb.name);
        else if (ttb.name in this.node.flags)
            this.node.flags.remove(ttb.name);
    }
}
