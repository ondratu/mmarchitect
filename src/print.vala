// XXX: could be singleton
public class Print : GLib.Object {

    protected Gtk.PrintOperation po;
    protected Node ? node;

    public Print () {
        po = new Gtk.PrintOperation();
        po.begin_print.connect(begin_print);
        po.draw_page.connect(draw_page);
    }

    public void run (Gtk.Window parent, Node node) {
        // TODO: save setiings
        // default filename to export
        // default page orientation to landscape
        this.node = node;

        try {
            var res = po.run (Gtk.PrintOperationAction.PRINT_DIALOG, parent);
            if (res == Gtk.PrintOperationResult.ERROR)
                po.get_error();                
        } catch (Error e) {
            var dialog = new Gtk.MessageDialog(
                    parent,
                    Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
                    Gtk.MessageType.ERROR,
                    Gtk.ButtonsType.CLOSE,
                    _("Printing error:") + e.message);
            stderr.printf ("%s\n", e.message);
            dialog.run();
        }
    }

    protected void begin_print (Gtk.PrintContext context) {
        po.set_n_pages(1);  // always print map to one page ;)
    }

    protected void draw_page (Gtk.PrintContext context, int page_nr) {
        int width, height;
        double x, y;
        var cr = context.get_cairo_context ();

        node.window.get_size(out width, out height);

        Exporter.cairo_get_translation (width, height, node, out x, out y);
        // TODO: scale and rotate to page...
        
        cr.translate (x, y);
        node.draw_tree(cr);
    }

}
