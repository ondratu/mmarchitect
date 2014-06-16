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
