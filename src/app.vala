extern const string GETTEXT_PACKAGE;

public class App : GLib.Object {
    private Gtk.Notebook notebook;
    private Gtk.Window window;
    private int tabs_counter;
    private Node ? node_clipboard;
    private Preferences pref;


    public App () {
        tabs_counter = 0;
        node_clipboard = null;
        pref = new Preferences();
        stdout.printf("GETTEXT_PACKAGE: %s \n", GETTEXT_PACKAGE);
        stdout.printf("DATA: %s \n", DATA);
    }

    public void loadui () throws Error {
        var builder = new Gtk.Builder ();
        builder.add_from_file (DATA + "/ui/main.ui");
        builder.connect_signals (this);
        
        window = builder.get_object("window") as Gtk.Window;
        notebook = builder.get_object("notebook") as Gtk.Notebook;
        set_tooltips (builder);

        window.set_default_icon_from_file (DATA+ "/icons/" + PROGRAM + ".png");
        new_file (window);

        window.destroy.connect (Gtk.main_quit);
        window.delete_event.connect (delete_event);
        window.show_all ();
    }

    public void set_tooltips(Gtk.Builder builder) {
        unowned Gtk.ToolButton tb;

        tb = builder.get_object("toolbutton_open") as Gtk.ToolButton;
        tb.set_tooltip_text(_("Open file"));
        tb = builder.get_object("toolbutton_new") as Gtk.ToolButton;
        tb.set_tooltip_text(_("New file"));
        tb = builder.get_object("toolbutton_save") as Gtk.ToolButton;
        tb.set_tooltip_text(_("Save file"));
        tb = builder.get_object("toolbutton_save_as") as Gtk.ToolButton;
        tb.set_tooltip_text(_("Save file as"));
    }

    public Gtk.FileFilter create_filter (string name, string [] patterns) {
        var filter = new Gtk.FileFilter();
        filter.set_name (name);
        foreach (var it in patterns){
            filter.add_pattern (it);
        }
        return filter;
    }

    [CCode (instance_pos = -1)]
    [CCode (cname = "G_MODULE_EXPORT app_new_file")]
    public void new_file (Gtk.Widget w) {
        string index = (++tabs_counter).to_string();
        var file = new FileTab.empty ("map"+index, pref);
        file.closed.connect (on_close_file);
        notebook.set_current_page (notebook.append_page (file, file.tab));
    }

    [CCode (instance_pos = -1)]
    [CCode (cname = "G_MODULE_EXPORT app_open_file")]
    public void open_file (Gtk.Widget w){
        var d = new Gtk.FileChooserDialog(
                _("Open file"),
                window,
                Gtk.FileChooserAction.OPEN,
                Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
                Gtk.Stock.OPEN, Gtk.ResponseType.ACCEPT
                );
        var filter = new Gtk.FileFilter();
        filter.set_name ("Mind Map Architect");
        filter.add_pattern ("*.mma");
        d.add_filter (filter);
        d.set_current_folder(GLib.Environment.get_home_dir());

        if (d.run() == Gtk.ResponseType.ACCEPT){
            var file = new FileTab.from_file (d.get_filename(), pref);
            file.closed.connect (on_close_file);

            FileTab ? cur = null;
            var pn = notebook.get_current_page ();
            if (pn >= 0)            
                 cur = notebook.get_nth_page (pn) as FileTab;
            if (cur != null && cur.is_saved() && cur.filepath == ""){
                notebook.remove_page (pn);
            }
            notebook.set_current_page (notebook.append_page (file, file.tab));
        }
        d.destroy();
    }
    
    [CCode (instance_pos = -1)]
    [CCode (cname = "G_MODULE_EXPORT app_import_file")]
    public void import_file (Gtk.Widget w){
        var d = new Gtk.FileChooserDialog(
                _("Import file"),
                window,
                Gtk.FileChooserAction.OPEN,
                Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
                Gtk.Stock.OPEN, Gtk.ResponseType.ACCEPT
                );
        
        var mm = create_filter ("Free Mind", {"*.mm"});
        d.add_filter (mm);

        d.set_current_folder(GLib.Environment.get_home_dir());

        if (d.run() == Gtk.ResponseType.ACCEPT){
            string fname = GLib.Path.get_basename(d.get_filename());
            fname = fname.substring(0, fname.length-3); // .mm

            var file = new FileTab.empty (fname, pref);
            Importer.import_from_mm (d.get_filename(), ref file.mindmap.root);
            file.on_mindmap_change (); // file is changed            
            file.closed.connect (on_close_file);

            FileTab ? cur = null;
            var pn = notebook.get_current_page ();
            if (pn >= 0)            
                 cur = notebook.get_nth_page (pn) as FileTab;
            if (cur != null && cur.is_saved() && cur.filepath == ""){
                notebook.remove_page (pn);
            }
            notebook.set_current_page (notebook.append_page (file, file.tab));
        }
        d.destroy();
    }

    [CCode (instance_pos = -1)]
    [CCode (cname = "G_MODULE_EXPORT app_close_current_file")]
    public void close_current_file (Gtk.Widget w) {
        var file = notebook.get_nth_page (notebook.get_current_page ()) as FileTab;
        on_close_file(file);
    }

    public bool delete_event (Gdk.Event event) {
        for (int i = 0; i < notebook.get_n_pages (); i++) {
            var file = notebook.get_nth_page (i) as FileTab;
            if (!file.is_saved()){ 
                notebook.set_current_page (i);
                if (!ask_for_save (file))
                    return true;
            }
        }
        return false;
    }

    private bool ask_for_save (FileTab file) {
        try {
            var builder = new Gtk.Builder ();
            builder.add_from_file (DATA + "/ui/close_file_dialog.ui");

            var d = builder.get_object("dialog") as Gtk.Dialog;
            var w = builder.get_object("warning_label") as Gtk.Label;
            w.label = w.label.replace("%s", file.title);

            var rv = d.run();
            d.destroy();

            if (rv < 1 || rv > 2)   // do not close 0 or something
                return false;
            if (rv == 2) {          // save file
                if (file.filepath != "")
                    file.do_save();
                else if (!on_save_file_as(file))
                    return false; // if save as file is cancled, do not close
            }
        } catch (Error e) {
            // TODO: dialogovy okno o chybe...
            stderr.printf ("%s\n", e.message);
            return false;
        }
        return true;
    }

    private void on_close_file (FileTab file){
        if (!file.is_saved()){
            if (!ask_for_save (file))
                return;
        }

        var pn = notebook.page_num (file);
        notebook.remove_page (pn);
    }

    [CCode (instance_pos = -1)]
    [CCode (cname = "G_MODULE_EXPORT app_save_current_file")]
    public void save_current_file (Gtk.Widget w) {
        var file = notebook.get_nth_page (notebook.get_current_page ()) as FileTab;
        if (file.filepath != "")
            file.do_save();
        else
            on_save_file_as(file);
    }
    
    [CCode (instance_pos = -1)]
    [CCode (cname = "G_MODULE_EXPORT app_save_as_current_file")]
    public void save_as_current_file (Gtk.Widget w) {
        var file = notebook.get_nth_page (notebook.get_current_page ()) as FileTab;
        on_save_file_as(file);
    }

    public bool on_save_file_as (FileTab file){
        var d = new Gtk.FileChooserDialog(
                    _("Save file as"),
                    window,
                    Gtk.FileChooserAction.SAVE,
                    Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
                    Gtk.Stock.SAVE, Gtk.ResponseType.ACCEPT);
        var filter = new Gtk.FileFilter();
        filter.set_name ("Mind Map Architect");
        filter.add_pattern ("*.mma");
        d.add_filter (filter);
        d.set_do_overwrite_confirmation (true);

        if (file.filepath == "") {
            d.set_current_folder(GLib.Environment.get_home_dir());
            d.set_current_name(file.title);
        } else {
            d.set_current_folder(GLib.Path.get_dirname(file.filepath));
            d.set_current_name(GLib.Path.get_basename(file.filepath));
        }
            
        if (d.run() == Gtk.ResponseType.ACCEPT){
            var fname = d.get_filename();
            if (fname.substring(-4).down() != ".mma")
                fname += ".mma";
            file.do_save_as(fname);

            d.destroy();
            return true;
        }

        d.destroy();
        return false;
        
    }

    [CCode (instance_pos = -1)]
    [CCode (cname = "G_MODULE_EXPORT app_export_current_file")]
    public void export_current_file (Gtk.Widget w) {
        var file = notebook.get_nth_page (notebook.get_current_page ()) as FileTab;
        on_export_file(file);
    }

    public bool on_export_file (FileTab file){
        var d = new Gtk.FileChooserDialog(
                    _("Export file as"),
                    window,
                    Gtk.FileChooserAction.SAVE,
                    Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
                    Gtk.Stock.SAVE, Gtk.ResponseType.ACCEPT);

        var txt = create_filter (_("Plain Text"), {"*.txt"});
        d.add_filter (txt);
        var html = create_filter (_("Simple Web Page"), {"*.html", "*.htm"});
        d.add_filter (html);
        var dhtml = create_filter (_("Dynamic Web Page"), {"*.dhtml", "*.dhtm"});
        d.add_filter (dhtml);
        var mm = create_filter ("Free Mind", {"*.mm"});
        d.add_filter (mm);
       
        d.set_do_overwrite_confirmation (true);

        if (file.filepath == "") {
            d.set_current_folder(GLib.Environment.get_home_dir());
            d.set_current_name(file.title);
        } else {
            d.set_current_folder(GLib.Path.get_dirname(file.filepath));
            string fname = GLib.Path.get_basename(file.filepath);
            d.set_current_name(fname.substring(0, fname.length-4)); // .txt
        }
        
        bool retval = false;

        if (d.run() == Gtk.ResponseType.ACCEPT){
            var fname = d.get_filename();
            var filter = d.get_filter();

            if (filter == txt) {
                if (!fname.down().has_suffix(".txt"))
                    fname += ".txt";
                retval = Exporter.export_to_txt(fname, file.mindmap.root);
            } else if (filter == html) {
                if (!fname.down().has_suffix(".htm") && !fname.down().has_suffix(".html"))
                    fname += ".html";
                retval = Exporter.export_to_html(fname, file.mindmap.root);
            } else if (filter == dhtml) {
                if (!fname.down().has_suffix(".dhtm") && !fname.down().has_suffix(".dhtml"))
                    fname += ".dhtml";
                retval = Exporter.export_to_dhtml(fname, file.mindmap.root);
            } else if (filter == mm) {
                if (!fname.down().has_suffix(".mm"))
                    fname += ".mm";
                retval = Exporter.export_to_mm(fname, file.mindmap.root);
            }
        }

        d.destroy();
        return retval;
    }

    // nodes
    [CCode (instance_pos = -1)]
    [CCode (cname = "G_MODULE_EXPORT app_node_delete")]
    public void node_delete (Gtk.Widget w) {
        var file = notebook.get_nth_page (notebook.get_current_page ()) as FileTab;
        file.mindmap.node_delete();     
    }

    
    [CCode (instance_pos = -1)]
    [CCode (cname = "G_MODULE_EXPORT app_node_edit")]
    public void node_edit (Gtk.Widget w) {
        var file = notebook.get_nth_page (notebook.get_current_page ()) as FileTab;
        file.mindmap.node_edit();
    }

    [CCode (instance_pos = -1)]
    [CCode (cname = "G_MODULE_EXPORT app_node_copy")]
    public void node_copy (Gtk.Widget w) {
        var file = notebook.get_nth_page (notebook.get_current_page ()) as FileTab;
        node_clipboard = file.mindmap.node_copy();
    }

    [CCode (instance_pos = -1)]
    [CCode (cname = "G_MODULE_EXPORT app_node_paste")]
    public void node_paste (Gtk.Widget w) {
        var file = notebook.get_nth_page (notebook.get_current_page ()) as FileTab;
        file.mindmap.node_paste(node_clipboard);
    }

    [CCode (instance_pos = -1)]
    [CCode (cname = "G_MODULE_EXPORT app_node_cut")]
    public void node_cut (Gtk.Widget w) {
        var file = notebook.get_nth_page (notebook.get_current_page ()) as FileTab;
        node_clipboard = file.mindmap.node_cut();
    }

    [CCode (instance_pos = -1)]
    [CCode (cname = "G_MODULE_EXPORT app_node_expand")]
    public void node_expand (Gtk.Widget w) {
        var file = notebook.get_nth_page (notebook.get_current_page ()) as FileTab;
        file.mindmap.node_expand();
    }

    [CCode (instance_pos = -1)]
    [CCode (cname = "G_MODULE_EXPORT app_node_collapse")]
    public void node_collapse (Gtk.Widget w) {
        var file = notebook.get_nth_page (notebook.get_current_page ()) as FileTab;
        file.mindmap.node_collapse();
    }

    [CCode (instance_pos = -1)]
    [CCode (cname = "G_MODULE_EXPORT app_expand_all")]
    public void expand_all (Gtk.Widget w) {
        var file = notebook.get_nth_page (notebook.get_current_page ()) as FileTab;
        file.mindmap.node_expand_all ();
    }

    [CCode (instance_pos = -1)]
    [CCode (cname = "G_MODULE_EXPORT app_collapse_all")]
    public void collapse_all (Gtk.Widget w) {
        var file = notebook.get_nth_page (notebook.get_current_page ()) as FileTab;
        file.mindmap.node_collapse_all ();
    }

    [CCode (instance_pos = -1)]
    [CCode (cname = "G_MODULE_EXPORT app_check_quit")]
    public void check_quit (Gtk.Widget w) {
        for (int i = 0; i < notebook.get_n_pages (); i++) {
            var file = notebook.get_nth_page (i) as FileTab;
            if (!file.is_saved()) 
                if (!ask_for_save (file))
                    return;
        }
        
        Gtk.main_quit ();
    }


    [CCode (instance_pos = -1)]
    [CCode (cname = "G_MODULE_EXPORT app_preferences")]
    public void preferences (Gtk.Widget w) {
        if (pref.dialog()) {
            for (int i = 0; i < notebook.get_n_pages (); i++) {
                var file = notebook.get_nth_page (i) as FileTab;
                file.mindmap.apply_style();
            }
        }
    }

    [CCode (instance_pos = -1)]
    [CCode (cname = "G_MODULE_EXPORT app_about")]
    public void about (Gtk.Widget w) {
        try {
            var builder = new Gtk.Builder ();
            builder.add_from_file (DATA + "/ui/about_dialog.ui");

            var d = builder.get_object ("aboutdialog") as Gtk.AboutDialog;
            var p = new Gdk.Pixbuf.from_file (DATA + "/icons/" + PROGRAM + ".png");
            
            d.set_logo (p);
            d.set_version (VERSION);
            d.run();
            d.destroy();
        }  catch (Error e) {
            stderr.printf ("%s\n", e.message);
        }
    }
}
