/*
 * DESCRIPTION      FileTab Class
 * PROJECT          Mind Map Architect
 * AUTHOR           Ondrej Tuma <mcbig@zeropage.cz>
 *
 * Copyright (C) Ondrej Tuma 2011
 * Code is present with BSD licence.
 */

// modules: Gtk

public class FileTab : Gtk.ScrolledWindow, ITab {
    public TabLabel tablabel { get; protected set; }
    public string title { get; set; }

    public MindMap mindmap;

    public string filepath;

    private bool saved;
    private FilePreferences file_pref;

    private FileTab(string t, Preferences pref){
        title = t;

        tablabel = new TabLabel (title);
        tablabel.close_button.button_press_event.connect(
                (e) => {
                    closed(this);
                    return true;
                });

        mindmap = new MindMap (pref);
        mindmap.change.connect (on_mindmap_change);
        mindmap.focus_changed.connect (on_focus_changed);
        set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        add_with_viewport(mindmap);

        file_pref = new FilePreferences (pref);
    }

    public FileTab.empty(string title, Preferences pref){
        this(title, pref);
        saved = true;
        tablabel.set_title (title+"*");
        filepath = "";
        show_all();
    }

    public FileTab.from_file(string path, Preferences pref){
        this(GLib.Path.get_basename(path), pref);
        do_load(path);
        show_all();
        event_after.connect(center_root_node);
    }

    private void set_saved (bool state){
        if (saved == state)
            return;

        saved = state;
        set_title ();
    }

    private void set_title (string newtitle = "") {
        if (newtitle != "")
            title = newtitle;

        if (saved)
            tablabel.set_title (title);
        else
            tablabel.set_title (title+"*");
    }

    public bool is_saved (){
        return saved;
    }

    public void on_mindmap_change() {
        set_saved (false);
    }

    public void on_focus_changed (double x, double y, double width, double height) {

        var ha = get_hadjustment();
        var va = get_vadjustment();

        // horizontal scrolling
        double val = ha.get_value();
        if ( (x + width) > (ha.get_page_size() + val) )     // if end of node is not visible
            val = (x + width) - ha.get_page_size() + PAGE_PADDING;
        if ( x < val )                                      // if start of node is not visible
            val = x - PAGE_PADDING;
        if ( val != ha.get_value() )
            ha.set_value (val);

        // vertical scrolling
        val = va.get_value();
        if ( (y + height) > (va.get_page_size() + val) )
            val = (y + height) - va.get_page_size() + PAGE_PADDING;
        if ( y < val )
            val = y - PAGE_PADDING;
        if ( val != va.get_value() )
            va.set_value (val);
    }

    public void center_root_node () {
        double x, y;
        mindmap.refresh_tree();
        mindmap.get_translation (out x, out y);
        int xx = (int) GLib.Math.lrint(x);
        int yy = (int) GLib.Math.lrint(y);

        var ha = get_hadjustment();
        var va = get_vadjustment();

        ha.set_value (mindmap.root.area.x + xx - ha.get_page_size() / 2);
        va.set_value (mindmap.root.area.y + yy - va.get_page_size() / 2);

        event_after.disconnect(center_root_node);
    }

    private void write_file_info (Xml.TextWriter w) {
        w.start_element ("info");

        w.write_element ("author", file_pref.author);

        w.end_element ();
    }

    private void write_file_settings (Xml.TextWriter w) {
        w.start_element ("settings");

        w.write_element ("rise_method", RisingMethod.to_string (
                                                file_pref.rise_method));
        w.write_element ("points", IdeaPoints.to_string (
                                                file_pref.points));
        w.write_element ("function", PointsFunction.to_string (
                                                file_pref.function));
        w.write_element ("rise_ideas", file_pref.rise_ideas.to_string ());
        w.write_element ("rise_branches", file_pref.rise_branches.to_string ());

        w.end_element ();
    }

    private void write_node(Node node, Xml.TextWriter w){
        w.start_element ("node");
        w.write_attribute ("title", node.title);

        if (node.parent != null && node.direction != Direction.AUTO &&
                node.direction != node.parent.direction)
            w.write_attribute ("direction", node.direction.to_string());

        w.write_attribute ("expand", node.is_expand.to_string());

        if (node.parent == null && !node.default_color)
            w.write_attribute ("color", node.color.to_string());
        else if (node.parent != null && !node.color.equal(node.parent.color))
            w.write_attribute ("color", node.color.to_string());

        if (node.points != 0)
            w.write_attribute ("points", node.points.to_string());

        if (node.text != "")
            w.write_element ("text", node.text);

        foreach (var n in node.children) {
            write_node(n, w);
        }
        w.end_element();
    }

    public bool do_save_as (string path) {
        var w = new Xml.TextWriter.filename (path);
        w.set_indent (true);
        w.set_indent_string ("\t");

        w.start_document ();
        w.start_element ("map");

        // w.write_comment ("Some info about software");
        write_file_info (w);
        write_file_settings (w);
        write_node (mindmap.root, w);

        w.end_element();
        w.end_document();

        w.flush();

        filepath = path;
        set_title(GLib.Path.get_basename(filepath));
        set_saved(true);
        return true;
    }

    public bool do_save (){
        return do_save_as(filepath);
    }

    private void read_node_attr (Xml.Node* x, ref CoreNode c) {
        for (Xml.Attr* it = x->properties; it != null; it = it->next) {
            if (it->name == "title"){
                c.title = it->children->content;
            } else if (it->name == "direction"){
                c.direction = int.parse(it->children->content);
            } else if (it->name == "expand"){
                c.is_expand = bool.parse(it->children->content);
            } else if (it->name == "color"){
                Gdk.Color.parse (it->children->content, out c.color);
                c.default_color = false;
            } else if (it->name == "points"){
                c.points = double.parse(it->children->content);
            }
        }
    }

    private void read_node(Xml.Node* x, Node n){
        for (Xml.Node* it = x->children; it != null; it = it->next) {
            if (it->type != Xml.ElementType.ELEMENT_NODE) {
                continue;
            }

            if (it->name == "node"){
                var c = CoreNode();
                read_node_attr(it, ref c);
                var child = n.add(c.title, c.direction, c.is_expand);

                if (!c.default_color) {
                    child.color = c.color;
                    child.default_color = false;
                }
                child.points = c.points;

                read_node(it, child);

            } else if (it->name == "text"){
                n.text = it->get_content().strip();
            }
        }
    }

    private void read_file_info (Xml.Node* x) {
        for (Xml.Node* it = x->children; it != null; it = it->next) {
            if (it->type != Xml.ElementType.ELEMENT_NODE) {
                continue;
            }

            if (it->name == "author"){
                file_pref.author = it->get_content().strip();
            }
        }
    }

    private void read_file_settings (Xml.Node* x) {
        for (Xml.Node* it = x->children; it != null; it = it->next) {
            if (it->type != Xml.ElementType.ELEMENT_NODE) {
                continue;
            }

            if (it->name == "rise_method"){
                file_pref.rise_method = RisingMethod.parse(it->get_content().strip());
            } else if (it->name == "points"){
                file_pref.points = IdeaPoints.parse(it->get_content().strip());
            } else if (it->name == "function"){
                file_pref.function = PointsFunction.parse(it->get_content().strip());
            } else if (it->name == "rise_ideas"){
                file_pref.rise_ideas = bool.parse(it->get_content().strip());
            } else if (it->name == "rise_branches"){
                file_pref.rise_branches = bool.parse(it->get_content().strip());
            }
        }
    }

    public bool do_load (string path) {
        var r = new Xml.TextReader.filename (path);
        r.read();

        Xml.Node* x = r.expand ();
        if (x == null) {
            stderr.printf ("The %s file is empty.",
                    GLib.Path.get_basename(path));
            return false;
        }

        // read the file
        Node ? root = null;
        for (Xml.Node* it = x->children; it != null; it = it->next) {
            if (it->type != Xml.ElementType.ELEMENT_NODE) {
                continue;
            }

            if (it->name == "info"){
                read_file_info(it);
            }

            if (it->name == "settings"){
                read_file_settings(it);
            }

            if (it->name == "node"){
                var c = CoreNode();
                read_node_attr(it, ref c);
                root = mindmap.create_new_root(c);
                read_node(it, root);
            }
        }

        if (root == null){
            stderr.printf ("The %s file have no mind.",
                    GLib.Path.get_basename(path));
            return false;
        }

        root.zip();    // sort main node children
        filepath = path;
        set_saved(true);
        return true;
    }

    public bool properties () {
        return file_pref.dialog();
    }

    ~FileTab(){
        //stdout.printf ("file destructor ...\n");
    }

}
