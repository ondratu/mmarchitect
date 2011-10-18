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

            var dos = new DataOutputStream (
                    file.create (FileCreateFlags.REPLACE_DESTINATION));

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
}
