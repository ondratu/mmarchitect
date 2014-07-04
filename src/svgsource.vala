// modules: Gtk

public bool set_source_svg (Cairo.Context cr, string file_name,
                            double x, double y, int width = 20, int height = 20 )
{
    Rsvg.Handle svg;
    var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, width, height);
    var context = new Cairo.Context (surface);

    try {
        svg = new Rsvg.Handle.from_file(file_name);
        //context.translate(0,0);
        context.scale (1.0 * width / svg.width, 1.0 * height / svg.height);
        svg.render_cairo(context);
        cr.set_source_surface(surface, x, y);
        return true;
    } catch (Error e) {
        context.set_source_rgb (1.0, 0.2, 0.2);
        context.set_line_width (1.5);
        context.move_to (width / 1.5, height / 1.5);
        context.line_to (width - 1, height - 1);
        context.move_to (width - 1, height / 1.5);
        context.line_to (width / 1.5, height - 1);
        context.stroke();
        cr.set_source_surface(surface, x, y);
        // stock
        return false;
    }
}

public class SVGImage : Gtk.Widget {
    private string file_name;
    private int width;
    private int height;

    public SVGImage (string file_name, Gtk.IconSize icon_size) {
        draw.connect (do_draw);
        this.file_name = file_name;
        Gtk.icon_size_lookup (icon_size, out width, out height);
        set_size_request (width, height);
    }

    /*
    public override void size_request (out Gtk.Requisition requisition) {
        requisition = Gtk.Requisition (){
        width = this.width, height = this.height};
    }
    */

    public override void realize () {
        var attrs = Gdk.WindowAttr () {
            window_type = Gdk.WindowType.CHILD,
            wclass = Gdk.WindowWindowClass.INPUT_OUTPUT,
            event_mask = get_events () | Gdk.EventMask.EXPOSURE_MASK
        };
        var window = new Gdk.Window (get_parent_window (), attrs, 0);
        set_window (window);

        var allocation = Gtk.Allocation();
        get_allocation (out allocation);
        window.move_resize (allocation.x, allocation.y,
                            allocation.width, allocation.height);

        window.set_user_data (this);

        this.style = this.style.attach (window);
        this.style.set_background (window, Gtk.StateType.NORMAL);

        //set_flags (Gtk.WidgetFlags.REALIZED);
        set_realized (true);
    }

    public bool do_draw (Cairo.Context cr) {
        //cr.rectangle (event.area.x, event.area.y,
        //              event.area.width, event.area.height);
        cr.translate (0.5, 0.5);
        set_source_svg (cr, file_name, 0, 0, width, height);
        cr.paint ();
        return false;
    }
}
