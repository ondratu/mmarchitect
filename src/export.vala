namespace Exporter {
    
    public errordomain ExportError {
        NOT_SUPPORT_YET
    }


    // TODO: text of node
    void write_txt (DataOutputStream dos, Node node, int lvl = 0) throws IOError {
        dos.put_string (string.nfill (lvl * 2, ' '));
        if (lvl > 0)
            dos.put_string (" - ");
        dos.put_string (node.title + "\n");
        foreach (var it in node.children) {
            write_txt (dos, it, lvl + 1);
        }
    }

    bool export_to_txt (string path, Node root) {
        try {
            var file = File.new_for_path (path);
            
            // TODO: making backup (second param) could be configurable
            var dos = new DataOutputStream (
                    file.replace (null, false, FileCreateFlags.REPLACE_DESTINATION));

            write_txt (dos, root);

            return true;
        } catch (Error e) {
            stderr.printf ("%s\n", e.message);
            return false;
        }
    }

    bool export_to_html (string path, Node root) {
        try {
            throw new ExportError.NOT_SUPPORT_YET ("HTML is not support yet!");
            //return true;
        } catch (Error e) {
            stderr.printf ("%s\n", e.message);
            return false;
        }
    }

    bool export_to_dhtml (string path, Node root) {
        try {
            throw new ExportError.NOT_SUPPORT_YET ("DHTML is not support yet!");
            //return true;
        } catch (Error e) {
            stderr.printf ("%s\n", e.message);
            return false;
        }
    }

    bool export_to_mm (string path, Node root) {
        try {
            throw new ExportError.NOT_SUPPORT_YET ("FreeMind is not support yet!");
            //return true;
        } catch (Error e) {
            stderr.printf ("%s\n", e.message);
            return false;
        }
    }


    void cairo_get_translation (int width, int height, Node node, out double x, out double y) {
        int dist = (node.full_right.width - node.full_left.width).abs()  / 2;

        if (node.full_right.width > node.full_left.width){
            x = GLib.Math.lrint (width / 2 - dist ) + 0.5;
        } else {
            x = GLib.Math.lrint (width / 2 + dist ) + 0.5;
        }

        y = GLib.Math.lrint (height / 2 - node.get_higher_full() / 2) + 0.5; 
    }

    bool export_to_png (string path, Node node) {
        int width, height;
        node.window.get_size(out width, out height);

        var surface = new Cairo.ImageSurface(Cairo.Format.RGB24, width, height);
        var cr = new Cairo.Context(surface);

        // fill empty white bacground
        cr.rectangle (0, 0, width, height);
        cr.set_source_rgb (1, 1, 1);
        cr.fill_preserve();

        double x, y;
        cairo_get_translation (width, height, node, out x, out y);

        cr.translate (x, y);
        node.draw_tree(cr);
        var status = surface.write_to_png (path);
        return (status == Cairo.Status.SUCCESS);    // SUCCESS = true :)
    }
}
