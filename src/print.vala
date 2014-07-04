/*
 * DESCRIPTION      Printing support of mind map.
 * PROJECT          Mind Map Architect
 * AUTHOR           Ondrej Tuma <mcbig@zeropage.cz>
 *
 * Copyright (C) Ondrej Tuma 2011
 * Code is present with BSD licence.
 */

// XXX: could be singleton
public class Print : GLib.Object {

    protected Gtk.PrintOperation po;
    protected Node ? node;
    protected Preferences pref;

    public Print (Preferences pref, Node node) {
        // XXX: page orientation and output-uri could be saved to
        // map file
        this.pref = pref;
        this.node = node;

        po = new Gtk.PrintOperation ();
        po.set_embed_page_setup (true);

        // load page setup from preference file
        var page_setup = new Gtk.PageSetup ();
        page_setup.set_orientation (Gtk.PageOrientation.LANDSCAPE); // default
        // pref.load_page_setup (page_setup);
        po.set_default_page_setup(page_setup);

        // load settings from preference file
        var print_settings = new Gtk.PrintSettings ();
        pref.load_print_settings (print_settings);
        //print_settings.set("output-uri", filename);
        po.set_print_settings (print_settings);

        po.begin_print.connect (begin_print);
        po.draw_page.connect (draw_page);
    }

    public void run (Gtk.Window parent) {
        try {
            var res = po.run (Gtk.PrintOperationAction.PRINT_DIALOG, parent);
            
            if (res == Gtk.PrintOperationResult.ERROR)
                po.get_error();

            // store settings to preference file
            if (res != Gtk.PrintOperationResult.CANCEL)
                pref.save_print_settings(po.get_print_settings ());

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
        int width = node.window.get_width ();
        int height = node.window.get_height ();
        double x, y, page_height, page_width, scale_width, scale_height;

        var cr = context.get_cairo_context ();

        page_width = context.get_width ();
        page_height = context.get_height ();

        scale_width = page_width / width;
        scale_height = page_height / height;

        Exporter.cairo_get_translation (width, height, node, out x, out y);

        if (scale_width < 1 && scale_width < scale_height )
            cr.scale (scale_width, scale_width);
        else if (scale_height < 1 && scale_height < scale_width )
            cr.scale (scale_height, scale_height);

        cr.translate (x, y);
        node.draw_tree(cr);
    }

}
