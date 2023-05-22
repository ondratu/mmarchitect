// modules: gtk+-3.0
// sources: consts.vala node.vala

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

[GtkTemplate (ui = "/cz/zeropage/mmarchitect/color_dialog.ui")]
public class ColorDialog : Gtk.ColorChooserDialog {
    [GtkChild]
    public unowned Gtk.RadioButton radio_default;
    [GtkChild]
    public unowned Gtk.RadioButton radio_parent;
    [GtkChild]
    public unowned Gtk.RadioButton radio_own;

    private Node node;
    private bool rgba_lock;

    public ColorDialog (Gtk.Window parent, Node node, Gdk.RGBA rgba) {
        set_transient_for (parent);
        this.node = node;
        set_rgba (rgba);

        rgba_lock = false;     // unlock rgba notify
        notify.connect ((property) => {
            if (!rgba_lock && property.name == "rgba") {
                radio_own.set_active (true);
            }
        });

    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT color_button_default_toggled")]
    public void default_toggled (Gtk.Widget sender) {
        if (((Gtk.ToggleButton) sender).get_active ()){
            rgba_lock = true;
            set_rgba (node.map.pref.default_color);
            rgba_lock = false;
        }
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT color_button_parent_toggled")]
    public void parent_toggled (Gtk.Widget sender) {
        if (((Gtk.ToggleButton) sender).get_active ()){
            rgba_lock = true;
            if (node.parent != null) {
                set_rgba (node.parent.rgb);
            } else {
                set_rgba (node.map.pref.default_color);
            }
            rgba_lock = false;
        }
    }
}

public class ColorButton : Gtk.Button {
    private Node node;
    private Swatch color_widget;
    private bool default_color;

    private unowned Gtk.Window window;

    public ColorButton (Node node, Gtk.Window window) {
        this.node = node;
        default_color = node.default_color;
        color_widget = new Swatch ();
        this.window = window;

        color_widget.set_rgba (node.rgb);
        color_widget.set_size_request (20, 20);
        set_image (this.color_widget);
    }

    public Gdk.RGBA get_rgba () {
        return color_widget.get_rgba ();
    }

    public override void clicked () {
        var rgba = color_widget.get_rgba ();

        var chooser = new ColorDialog (window, node, rgba);

        if (default_color || rgba.equal (node.map.pref.default_color)) {
            chooser.radio_default.set_active (true);
        } else if (node.parent == null || !rgba.equal (node.parent.rgb)) {
            chooser.radio_own.set_active (true);
        } else {
            chooser.radio_parent.set_active (true);
        }

        if (chooser.run () == Gtk.ResponseType.OK) {
            if (chooser.radio_default.get_active ()) {
                color_widget.set_rgba (node.map.pref.default_color);
                default_color = true;
            } else if (chooser.radio_own.get_active ()) {
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
    }
}
