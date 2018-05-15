/*
 * DESCRIPTION      Welcome panel with tips and last open files.
 * PROJECT          Mind Map Architect
 * AUTHOR           Ondrej Tuma <mcbig@zeropage.cz>
 *
 * Copyright (C) Ondrej Tuma 2011
 * Code is present with BSD licence.
 */
// modules: Glib

const string ICO_URL = "https://mmarchitect.zeropage.cz/icons/";

namespace Exporter {

    public errordomain ExportError {
        NOT_SUPPORT_YET
    }

    void write_txt (DataOutputStream dos, Node node, int lvl = 0) throws IOError {
        dos.put_string (string.nfill (lvl * 2, ' '));
        if (lvl > 0)
            dos.put_string (" * ");
        string points = (node.points > 0) ? " [" + node.str_points + "]" : "";
        dos.put_string (node.title + points + "\n");
        if (node.text.length > 0) {
            dos.put_string (string.nfill ((lvl * 2) + 3, ' '));
            dos.put_string (node.text + "\n");
        }
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

    void write_html_root (Xml.TextWriter w, Node node){
        w.start_element("h1");

        if (node.points != 0)
            w.write_attribute ("points", node.points.to_string());

        if (!node.default_color)
            w.write_attribute ("style", "color:" + rgb_to_hex(node.rgb) + ";");

        if (node.flags.size > 0){
            foreach (var flag in node.flags) {
                w.start_element("img");
                w.write_attribute("alt", "[" + flag + "]");
                w.write_attribute("src", ICO_URL + flag + ".svg");
                w.write_attribute("height", ICO_SIZE.to_string());
                w.end_element();
            }
        }

        w.write_string(node.title);
        w.end_element();    // h1

        if (node.text != "") {
            w.write_string("\n");
            w.write_element ("p", node.text);
        }

        if (node.children.length () > 0) {     // <ul>
            w.write_string("\n");
            w.start_element ("ul");
        }
        foreach (var n in node.children)
            write_html_node(w, n);
        if (node.children.length () > 0)       // </ul>
            w.end_element ();
    }

    void write_html_node (Xml.TextWriter w, Node node){
        w.start_element("li");            // <li>

        if (node.parent == null && !node.default_color)
            w.write_attribute ("style", "color:" + rgb_to_hex(node.rgb) + ";");
        else if (node.parent != null && !node.rgb.equal(node.parent.rgb))
            //w.write_attribute ("style", "color:" + node.color.to_string()+";");
            w.write_attribute ("style", "color:" + rgb_to_hex(node.rgb) + ";");

        w.start_element("b");

        if (node.flags.size > 0){
            foreach (var flag in node.flags) {
                w.start_element("img");
                w.write_attribute("alt", "[" + flag + "]");
                w.write_attribute("src", ICO_URL + flag + ".svg");
                w.write_attribute("height", ICO_SIZE.to_string());
                w.end_element();
            }
        }

        w.write_string(node.title);
        w.end_element(); // </b>

        if (node.points != 0)
            w.write_attribute ("points", node.points.to_string());

        if (node.text != "") {
            w.write_string("\n");
            w.write_element ("p", node.text);
        }

        if (node.children.length () > 0) {     // <ul>
            w.write_string("\n");
            w.start_element ("ul");
        }
        foreach (var n in node.children)
            write_html_node(w, n);
        if (node.children.length () > 0)       // </ul>
            w.end_element ();
        w.end_element();                    // </li>
    }

    void write_html_meta (Xml.TextWriter w, ...){
        w.start_element ("meta");
        var args = va_list();
        while (true) {
            string? key = args.arg();
            if (key == null) break;  // end of the list
            string? val = args.arg();
            if (val == null) break;  // end of the list

            w.write_attribute (key, val);
        }
        w.end_element ();
    }

    bool export_to_html (string path, Node root, Properties prop) {
        var w = new Xml.TextWriter.filename (path);
        w.set_indent (true);
        w.set_indent_string (" ");

        w.start_element ("html");
        w.start_element ("head");
        write_html_meta (w, "charset", "utf-8");
        write_html_meta (w, "name", "generator", "content", PROGRAM);
        write_html_meta (w, "name", "author", "content", prop.author);
        w.write_element ("title", root.title); //encoding
        w.write_element (
            "style",
            "body {font-family: sans-serif; width: 80%; margin: auto;}");
        w.end_element ();   // </head>

        w.start_element ("body");

        write_html_root (w, root);

        w.end_element();    // </body>
        w.end_element();    // </html>

        w.flush();
        return true;
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

    void write_mm_node (Xml.TextWriter w, Node node){
        foreach (var n in node.children) {
            w.start_element("node");
            w.write_attribute ("TEXT", n.title);
            write_mm_node(w, n);
            w.end_element();
        }
    }

    bool export_to_mm (string path, Node root) {
        var w = new Xml.TextWriter.filename (path);
        w.set_indent (true);
        w.set_indent_string ("\t");

        //w.start_document ();
        w.start_element ("map");
        w.write_attribute("version", "0.9.0");
        w.start_element ("node");
        w.write_attribute ("TEXT", root.title);

        foreach (var n in root.children) {
            w.start_element("node");
            if (n.direction == 0) {
                w.write_attribute ("POSITION", "left");
            } else { //1
                w.write_attribute ("POSITION", "right");
            }
            w.write_attribute ("TEXT", n.title);
            write_mm_node(w, n);
            w.end_element();
        }

        w.end_element();    // </node>
        w.end_element();    // </map>
        //w.end_document();

        w.flush();
        return true;
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
        int width = node.window.get_width ();
        int height = node.window.get_height ();

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
