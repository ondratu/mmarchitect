/*
 * FILE             $Id: $
 * DESCRIPTION      Importers from FreeMind, ...
 * PROJECT          Mind Map Architect
 * AUTHOR           Ondrej Tuma <mcbig@zeropage.cz>
 *
 * Copyright (C) Ondrej Tuma 2011
 * Code is present with BSD licence.
 */

// modules: Gtk

namespace  Importer {

    void read_mm_node_attr (Xml.Node* x, ref CoreNode c) {
        for (Xml.Attr* it = x->properties; it != null; it = it->next) {
            if (it->name == "TEXT"){
                c.title = it->children->content;
            } else if (it->name == "POSITION"){
                c.direction = (it->children->content == "right") ? Direction.RIGHT : Direction.LEFT;
            } else if (it->name == "FOLDED"){
                c.is_expand = !bool.parse(it->children->content);
            }
        }
    }

    void read_mm_node_icon (Xml.Node* x, Node c) {
        for (Xml.Attr* it = x->properties; it != null; it = it->next) {
            if (it->name == "BUILTIN"){
                if (it->children->content.substring(0, 5) == "full-"){
                    int number = int.parse(it->children->content.substring(5,1));
                    c.flags.add(number.to_string());
                } else {
                    c.flags.add(it->children->content);
                }
            }
        }
    }

    void read_mm_node(Xml.Node* x, Node n){
        for (Xml.Node* it = x->children; it != null; it = it->next) {
            if (it->type != Xml.ElementType.ELEMENT_NODE) {
                continue;
            }

            if (it->name == "node"){
                var c = CoreNode();
                read_mm_node_attr(it, ref c);
                var child = n.add(c.title, c.direction, c.is_expand);
                read_mm_node(it, child);

            } else if (it->name == "richcontent"){
                n.text = it->get_content().strip();
            } else if (it->name == "hook"){
                read_mm_node(it, n);
            } else if (it->name == "text"){
                n.text = it->get_content().strip();     // read text from hook
            } else if (it->name == "icon") {
                read_mm_node_icon(it, n);
            } else {
                stderr.printf("unknown child node `%s'\n", it->name);
            }
        }
    }

    bool import_from_mm (string path, MindMap mindmap) {
        var r = new Xml.TextReader.filename (path);
        r.read();

        Xml.Node* x = r.expand ();
        if (x == null) {
            stderr.printf ("The xml file node.xml is empty");
            return false;
        }

        Node ? root = null;
        // read the file
        for (Xml.Node* it = x->children; it != null; it = it->next) {
            if (it->type != Xml.ElementType.ELEMENT_NODE) {
                continue;
            }

            if (it->name == "node"){
                var c = CoreNode();
                read_mm_node_attr(it, ref c);
                root = mindmap.create_new_root(c);
                read_mm_node(it, root);
            }
        }

        return (root != null);
    }
}
