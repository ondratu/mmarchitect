class  Importer {
    // TODO: not finished !!

    void read_mm_node_attr (Xml.Node* x, ref CoreNode c) {
        for (Xml.Attr* it = x->properties; it != null; it = it->next) {
            if (it->name == "title"){
                c.title = it->children->content;
            } else if (it->name == "direction"){
                c.direction = int.parse(it->children->content);
            } else if (it->name == "expand"){
                c.is_expand = bool.parse(it->children->content);
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

            } else if (it->name == "text"){
                n.text = it->get_content().strip();
            }
        }
    }

    bool import_from_mm (string path, ref Node root) {
        var r = new Xml.TextReader.filename (path);
        r.read();

        Xml.Node* x = r.expand ();
        if (x == null) {
            stderr.printf ("The xml file node.xml is empty");
            return false;
        }

        // read the file
        for (Xml.Node* it = x->children; it != null; it = it->next) {
            if (it->type != Xml.ElementType.ELEMENT_NODE) {
                continue;
            }

            if (it->name == "info"){
                // read_file_info(it);
                continue;
            }
            
            if (it->name == "settings"){
                //read_file_settings(it);
                continue;
            }
            
            if (it->name == "node"){
                var c = CoreNode();
                read_mm_node_attr(it, ref c);
                root = new Node(c.title);
                read_mm_node(it, root);
            }
        }

        return true;
    }
}
