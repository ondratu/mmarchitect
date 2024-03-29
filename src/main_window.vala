/*
 * DESCRIPTION      Main graphics application object.
 * PROJECT          Mind Map Architect
 * AUTHOR           Ondrej Tuma <mcbig@zeropage.cz>
 *
 * Copyright (C) Ondrej Tuma 2011
 * Code is present with BSD licence.
 */

[GtkTemplate (ui = "/cz/zeropage/mmarchitect/main_window.ui")]
public class MainWindow : Gtk.ApplicationWindow {
    [GtkChild]
    private unowned Gtk.Notebook notebook;

    private Gtk.MenuItem menu_item_cut;
    private Gtk.MenuItem menu_item_copy;
    private Gtk.MenuItem menu_item_paste;
    private Gtk.MenuItem menu_item_delete;

    [GtkChild]
    private unowned Gtk.Menu nodemenu;
    [GtkChild]
    private unowned Gtk.Menu mapmenu;

    private int tabs_counter = 0;
    private Node ? node_clipboard = null;
    private Preferences pref = new Preferences ();
    private string _title;
    private List<Gdk.Pixbuf> icons;

    public MainWindow (string filename = "") {
        _title = title;     // title backup....

        notebook.page_added.connect (
                (w, n) => { // all tabs could be reoederable with drag n drop
                    notebook.set_tab_reorderable (w, true);
                });
        notebook.page_reordered.connect (this.on_page_reordered);

        destroy.connect (Gtk.main_quit);
        set_wm_icons();
        new_file_from_args (filename);
    }

    public void set_wm_icons()
    {
        try {
            int[] sizes = {16, 24, 32, 48, 64, 128};
            foreach (int size in sizes){
                icons.append (new Gdk.Pixbuf.from_file_at_scale(
                        DATADIR + "/icons/mmarchitect.svg",
                        size, size, true));
            }
            set_icon_list (icons);
        } catch (Error e) {
            error ("%s", e.message);
        }
    }

    public void set_sensitive_menu_edit (bool sensitive) {
        menu_item_cut.set_sensitive (sensitive);
        menu_item_copy.set_sensitive (sensitive);
        menu_item_paste.set_sensitive (sensitive);
        menu_item_delete.set_sensitive (sensitive);
    }

    public void disable_menu_edit () {
        set_sensitive_menu_edit (false);
    }

    public void enable_menu_edit () {
        set_sensitive_menu_edit (true);
    }

    public Gtk.FileFilter create_filter (string name, string [] patterns) {
        var filter = new Gtk.FileFilter ();
        filter.set_filter_name (name);
        foreach (var it in patterns) {
            filter.add_pattern (it);
        }
        return filter;
    }

    private void new_file_from_args (owned string fname) {
        start_application_private ();  // open what could be set
        if (fname.length == 0) {            // filename is not specified
            return;
        }

        var osfile = File.new_for_commandline_arg (fname);
        if (osfile.query_exists ()) {
            if (fname.substring (-4).down () == ".mma") {
                open_file_private (fname);
                return;
            }
            if (! import_file_private (fname)) {
                var d = new Gtk.MessageDialog (
                        this,
                        Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
                        Gtk.MessageType.ERROR,
                        Gtk.ButtonsType.CLOSE,
                        _(@"File $fname can't be imported!"));
                d.run ();
                d.destroy ();
            }
        } else {
            if (fname.substring (-4).down () == ".mma")
                fname = fname.substring (-4);
            new_file_private (fname);
        }
    }

    private void new_welcome_tab () {
        var tab = new WelcomeTab (pref);
        tab.closed.connect (on_close_tab);
        tab.sig_new_file.connect (on_new_file);
        tab.sig_open_file.connect (on_open_file);
        tab.sig_open_path.connect (on_open_path);
        this.notebook.set_current_page (notebook.append_page_menu (
                    tab, tab.tablabel, tab.menulabel));
    }

    /* If welcome tab is set in pref and no welcome tab is not in notebook,
       create welcome tab, else create new file tab */
    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_start_application")]
    public void start_application (Gtk.Widget w) {
        start_application_private ();
    }

    private void start_application_private () {
        if (pref.start_with == Start.WELCOME) {
            new_welcome_tab ();
            pref.append_last (WELCOME_FILE);
        }
        else if (pref.start_with == Start.LAST) {
            foreach (var it in pref.get_last_files ()) {
                var osfile = File.new_for_commandline_arg (it);
                if (it == WELCOME_FILE) {
                    new_welcome_tab ();
                    pref.append_last (WELCOME_FILE);
                } else if (osfile.query_exists ()) {
                    open_file_private (it);
                } else {
                    pref.remove_last (it);  // remove last file if not extist
                }
            }
            // when len of last files is zero and no file is open
            if (notebook.get_n_pages () == 0) {
                new_welcome_tab ();
                pref.append_last (WELCOME_FILE);
            }
        } else {
            new_file_private ();
        }
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_welcome_tab")]
    public void welcome_tab (Gtk.Widget w) {
        for (int i = 0; i < notebook.get_n_pages (); i++) {
            var tab = notebook.get_nth_page (i) as ITab;
            if (tab is WelcomeTab) {
                notebook.set_current_page (i);
                return;
            }
        }
        new_welcome_tab ();
        pref.append_last (WELCOME_FILE);
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_new_file")]
    public void new_file (Gtk.Widget w) {
        new_file_private ();
    }

    public void on_new_file (Gtk.Widget w) {
        new_file_private ();
    }

    private void new_file_private (owned string fname = "") {
        if (fname.length == 0) {
            string index = (++tabs_counter).to_string ();
            fname = "map" + index;
        }
        var file = new FileTab.empty (fname, pref, this);
        file.closed.connect (on_close_tab);
        file.mindmap.editform_open.connect (disable_menu_edit);
        file.mindmap.editform_close.connect (enable_menu_edit);
        file.mindmap.node_context_menu.connect ((event) => {
                nodemenu.popup_at_pointer (event);
            });
        file.mindmap.map_context_menu.connect ((event) => {
                mapmenu.popup_at_pointer (event);
            });

        notebook.set_current_page (notebook.append_page_menu (
                                   file, file.tablabel, file.menulabel));
        file.mindmap.grab_focus ();
    }

    private void open_file_private (string fname) {
        var file = new FileTab.from_file (fname, pref, this);
        file.closed.connect (on_close_tab);
        file.mindmap.editform_open.connect (disable_menu_edit);
        file.mindmap.editform_close.connect (enable_menu_edit);
        file.mindmap.node_context_menu.connect ((event) => {
                nodemenu.popup_at_pointer (event);
            });
        file.mindmap.map_context_menu.connect ((event) => {
                mapmenu.popup_at_pointer (event);
            });

        FileTab ? cur = null;
        var pn = notebook.get_current_page ();
        if (pn >= 0) {
            var tab = notebook.get_nth_page (pn) as ITab;
            if (tab is FileTab)
                cur = tab as FileTab;
        }
        if (cur != null && cur.is_saved () && cur.filepath == "") {
            notebook.remove_page (pn);
        }
        notebook.set_current_page (notebook.append_page_menu (
                                   file, file.tablabel, file.menulabel));
        file.mindmap.grab_focus ();
        pref.append_recent (fname);
        pref.append_last (fname);
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_open_file")]
    public void open_file (Gtk.Widget w) {
        open_file_dialog ();
    }

    private void open_file_dialog () {
        var d = new Gtk.FileChooserDialog (
                _("Open file"),
                this,
                Gtk.FileChooserAction.OPEN,
                _("_Cancel"), Gtk.ResponseType.CANCEL,
                _("_Open"), Gtk.ResponseType.ACCEPT
                );
        var filter = new Gtk.FileFilter ();
        filter.set_name ("Mind Map Architect");
        filter.add_pattern ("*.mma");
        d.add_filter (filter);
        d.set_current_folder (this.pref.default_directory);

        if (d.run () == Gtk.ResponseType.ACCEPT) {
            this.open_file_private (d.get_filename ());
        }
        d.destroy ();
    }

    public void on_open_file (Gtk.Widget w) {
        open_file_dialog ();
    }

    public void on_open_path (Gtk.Widget w, string path) {
        var osfile = File.new_for_commandline_arg (path);
        if (osfile.query_exists ()) {
            // todo path.down().has_suffix(".mma")
            if (path.substring (-4).down () == ".mma") {
                open_file_private (path);
                return;
            }
        } else {
            var d = new Gtk.MessageDialog (
                    this,
                    Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
                    Gtk.MessageType.ERROR,
                    Gtk.ButtonsType.CLOSE,
                    _(@"File $path not found!"));
            d.run ();
            d.destroy ();
        }
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_switch_page")]
    public void switch_page (Gtk.Widget w, Gtk.Widget pg, int pn) {
            var cur = (ITab) this.notebook.get_nth_page (pn);
            title = cur.title.split (".")[0];
    }

    private bool import_file_private (string fpath) {
        string fname = Path.get_basename (fpath);

        // TODO: to je spatne, tohle zalezi na extend !!!
        string ext = fname.substring (-3).down ();    // .mm
        fname = fname.substring (0, fname.length - 3); // .mm

        var file = new FileTab.empty (fname, pref, this);
        if (ext == ".mm") {
            Importer.import_from_mm (fpath, file.mindmap);
            file.queue_center ();
        } else {
            file.destroy ();
            return false;
        }

        file.on_mindmap_change (); // file is changed
        file.closed.connect (on_close_tab);
        file.mindmap.editform_open.connect (disable_menu_edit);
        file.mindmap.editform_close.connect (enable_menu_edit);
        file.mindmap.node_context_menu.connect ((event) => {
                nodemenu.popup_at_pointer (event);
            });

        file.mindmap.map_context_menu.connect ((event) => {
                mapmenu.popup_at_pointer (event);
            });

        FileTab ? cur = null;
        var pn = notebook.get_current_page ();
        if (pn >= 0) {
            cur = notebook.get_nth_page (pn) as FileTab;
        }
        if (cur != null && cur.is_saved () && cur.filepath == "") {
            notebook.remove_page (pn);
        }
        notebook.set_current_page (notebook.append_page_menu (
                                   file, file.tablabel, file.menulabel));
        file.mindmap.grab_focus ();
        return true;
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_import_file")]
    public void import_file (Gtk.Widget w) {
        var d = new Gtk.FileChooserDialog (
                _("Import file"),
                this,
                Gtk.FileChooserAction.OPEN,
                _("_Cancel"), Gtk.ResponseType.CANCEL,
                _("_Open"), Gtk.ResponseType.ACCEPT
                );

        var mm = this.create_filter ("Free Mind", {"*.mm"});
        d.add_filter (mm);

        d.set_current_folder (pref.default_directory);

        if (d.run () == Gtk.ResponseType.ACCEPT) {
            this.import_file_private (d.get_filename ());
        }
        d.destroy ();
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_close_current_file")]
    public void close_current_file (Gtk.Widget w) {
        var tab = notebook.get_nth_page (notebook.get_current_page ()) as ITab;
        on_close_tab (tab);
    }

    public override bool delete_event (Gdk.EventAny event) {
        for (int i = 0; i < notebook.get_n_pages (); i++) {
            var tab = notebook.get_nth_page (i) as ITab;
            if (tab is WelcomeTab) {
                continue;
            }

            var file = tab as FileTab;
            if (!file.is_saved ()) {
                notebook.set_current_page (i);
                if (!ask_for_save (file)) {
                    return true;
                }
            }
        }
        return false;
    }

    private bool ask_for_save (FileTab file) {
        var d = new CloseFileDialog (file.title);
        var rv = d.run ();
        d.destroy ();

        if (rv < 1 || rv > 2)   // do not close 0 or something
            return false;
        if (rv == 2) {          // save file
            if (file.filepath != "") {
                file.do_save ();
            } else if (!this.on_save_file_as (file)) {
                return false; // if save as file is cancled, do not close
            }
        }
        return true;
    }

    private void on_close_tab (ITab tab) {
        if (tab is FileTab) {
            var file = tab as FileTab;
            if (!file.is_saved ()) {
                if (!ask_for_save (file))
                    return;
            }
            if (file.filepath != "") {
                pref.remove_last (file.filepath);
            }
        } else { // there is only FileTab and WelcomeTab
            pref.remove_last (WELCOME_FILE);
        }

        var pn = notebook.page_num (tab as Gtk.Widget);
        notebook.remove_page (pn);

        if (notebook.get_n_pages () == 0)
            title = _title;
    }

    public void on_page_reordered (Gtk.Widget w, uint n) {
        var tab = w as ITab;
        if (tab is FileTab) {
            var file = tab as FileTab;
            if (file.filepath != "") {
                pref.reorder_last (file.filepath, n);
            }
        } else {// there is only FileTab and WelcomeTab
            pref.reorder_last (WELCOME_FILE, n);
        }
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_save_current_file")]
    public void save_current_file (Gtk.Widget w) {
        var tab = notebook.get_nth_page (notebook.get_current_page ()) as ITab;
        if (tab is WelcomeTab)
            return;

        var file = tab as FileTab;
        if (file.filepath != "") {
            file.do_save ();
        } else {
            on_save_file_as (file);
        }
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_save_as_current_file")]
    public void save_as_current_file (Gtk.Widget w) {
        var tab = notebook.get_nth_page (notebook.get_current_page ()) as ITab;
        if (tab is WelcomeTab)
            return;

        var file = tab as FileTab;
        on_save_file_as (file);
    }

    public bool on_save_file_as (FileTab file) {
        var d = new Gtk.FileChooserDialog (
                    _("Save file as"),
                    this,
                    Gtk.FileChooserAction.SAVE,
                    _("_Cancel"), Gtk.ResponseType.CANCEL,
                    _("_Save"), Gtk.ResponseType.ACCEPT);
        var filter = new Gtk.FileFilter ();
        filter.set_filter_name ("Mind Map Architect");
        filter.add_pattern ("*.mma");
        d.add_filter (filter);
        d.set_do_overwrite_confirmation (true);

        if (file.filepath == "") {
            d.set_current_folder (pref.default_directory);
            d.set_current_name (file.title);
        } else {
            d.set_current_folder (Path.get_dirname (file.filepath));
            d.set_current_name (Path.get_basename (file.filepath));
        }

        if (d.run () == Gtk.ResponseType.ACCEPT) {
            var fname = d.get_filename ();
            if (fname.substring (-4).down () != ".mma")
                fname += ".mma";

            string ? prev_path = null;
            if (file.is_saved () && file.filepath != "")
                prev_path = file.filepath;

            file.do_save_as (fname);

            title = GLib.Path.get_basename (fname).split (".")[0];

            d.destroy ();
            pref.append_recent (fname);
            pref.append_last (fname);
            if (prev_path != null) {      // file in last list will be replaced
                pref.remove_last (prev_path);
            }
            return true;
        }

        d.destroy ();
        return false;
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_export_current_file")]
    public void export_current_file (Gtk.Widget w) {
        var tab = notebook.get_nth_page (notebook.get_current_page ()) as ITab;
        if (tab is WelcomeTab)
            return;

        var file = tab as FileTab;
        on_export_file (file);
    }

    public bool on_export_file (FileTab filetab) {
        var d = new ExportDialog (filetab, pref.default_directory, this);

        bool retval = false;

        if (d.run () == Gtk.ResponseType.ACCEPT) {
            var fname = d.get_suffixed_filename ();

            switch (d.get_filter_id ()) {
                case ExportFilterID.TXT:
                    retval = Exporter.export_to_txt (fname, filetab.mindmap.root);
                    break;
                case ExportFilterID.HTML:
                    retval = Exporter.export_to_html (fname,
                                        filetab.mindmap.root, filetab.prop);
                    break;
                case ExportFilterID.DHTML:
                    retval = Exporter.export_to_dhtml (fname, filetab.mindmap.root);
                    break;
                case ExportFilterID.PNG:
                    retval = Exporter.export_to_png (fname, filetab.mindmap.root);
                    break;
                case ExportFilterID.MM:
                    retval = Exporter.export_to_mm (fname, filetab.mindmap.root);
                    break;
            }
        }

        d.destroy ();
        return retval;
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_print_current_file")]
    public void print_current_file (Gtk.Widget w) {
        var tab = notebook.get_nth_page (notebook.get_current_page ()) as ITab;
        if (tab is WelcomeTab)
            return;

        var file = tab as FileTab;
        on_print_file (file);
    }

    public void on_print_file (FileTab file) {
        var print = new Print (pref, file.mindmap.root);
        print.run (this);
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_properties_current_file")]
    public void properties_current_file (Gtk.Widget w) {
        var tab = notebook.get_nth_page (notebook.get_current_page ()) as ITab;
        if (tab is WelcomeTab)
            return;

        var file = tab as FileTab;
        if (file.properties_dialog (this)) {
            file.on_mindmap_change ();
        }
    }

    // nodes
    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_node_delete")]
    public void node_delete (Gtk.Widget w) {
        var tab = notebook.get_nth_page (notebook.get_current_page ()) as ITab;
        if (tab is WelcomeTab)
            return;

        var file = tab as FileTab;
        file.mindmap.node_delete ();
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_node_edit")]
    public void node_edit (Gtk.Widget w) {
        var tab = notebook.get_nth_page (notebook.get_current_page ()) as ITab;
        if (tab is WelcomeTab)
            return;

        var file = tab as FileTab;
        file.mindmap.node_edit ();
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_node_copy")]
    public void node_copy (Gtk.Widget w) {
        var tab = notebook.get_nth_page (notebook.get_current_page ()) as ITab;
        if (tab is WelcomeTab)
            return;

        var file = tab as FileTab;
        node_clipboard = file.mindmap.node_copy ();
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_node_paste")]
    public void node_paste (Gtk.Widget w) {
        if (node_clipboard == null)
            return;

        var tab = notebook.get_nth_page (notebook.get_current_page ()) as ITab;
        if (tab is WelcomeTab)
            return;

        var file = tab as FileTab;
        file.mindmap.node_paste (node_clipboard);
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_node_cut")]
    public void node_cut (Gtk.Widget w) {
        var tab = notebook.get_nth_page (notebook.get_current_page ()) as ITab;
        if (tab is WelcomeTab)
            return;

        var file = tab as FileTab;
        node_clipboard = file.mindmap.node_cut ();
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_node_expand")]
    public void node_expand (Gtk.Widget w) {
        var tab = this.notebook.get_nth_page (this.notebook.get_current_page ()) as ITab;
        if (tab is WelcomeTab)
            return;

        var file = tab as FileTab;
        file.mindmap.node_expand ();
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_node_collapse")]
    public void node_collapse (Gtk.Widget w) {
        var tab = this.notebook.get_nth_page (this.notebook.get_current_page ()) as ITab;
        if (tab is WelcomeTab)
            return;

        var file = tab as FileTab;
        file.mindmap.node_collapse ();
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_expand_all")]
    public void expand_all (Gtk.Widget w) {
        var tab = this.notebook.get_nth_page (this.notebook.get_current_page ()) as ITab;
        if (tab is WelcomeTab)
            return;

        var file = tab as FileTab;
        file.mindmap.node_expand_all ();
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_collapse_all")]
    public void collapse_all (Gtk.Widget w) {
        var tab = this.notebook.get_nth_page (this.notebook.get_current_page ()) as ITab;
        if (tab is WelcomeTab)
            return;

        var file = tab as FileTab;
        file.mindmap.node_collapse_all ();
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_node_move_up")]
    public void node_move_up (Gtk.Widget w) {
        var tab = this.notebook.get_nth_page (this.notebook.get_current_page ()) as ITab;
        if (tab is WelcomeTab)
            return;

        var file = tab as FileTab;
        file.mindmap.node_move_up ();
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_node_move_down")]
    public void node_move_down (Gtk.Widget w) {
        var tab = this.notebook.get_nth_page (this.notebook.get_current_page ()) as ITab;
        if (tab is WelcomeTab)
            return;

        var file = tab as FileTab;
        file.mindmap.node_move_down ();
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_node_move_left")]
    public void node_move_left (Gtk.Widget w) {
        var tab = this.notebook.get_nth_page (this.notebook.get_current_page ()) as ITab;
        if (tab is WelcomeTab)
            return;

        var file = tab as FileTab;
        file.mindmap.node_move_left ();
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_node_move_right")]
    public void node_move_right (Gtk.Widget w) {
        var tab = this.notebook.get_nth_page (this.notebook.get_current_page ()) as ITab;
        if (tab is WelcomeTab)
            return;

        var file = tab as FileTab;
        file.mindmap.node_move_right ();
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_check_quit")]
    public void check_quit (Gtk.Widget w) {
        for (int i = 0; i < this.notebook.get_n_pages (); i++) {
            var tab = this.notebook.get_nth_page (i) as ITab;
            if (tab is WelcomeTab)
                continue;

            var file = tab as FileTab;
            if (!file.is_saved ())
                if (!ask_for_save (file))
                    return;
        }

        Gtk.main_quit ();
    }


    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT app_preferences")]
    public void preferences (Gtk.Widget w) {
        if (pref.dialog (this)) {
            for (int i = 0; i < this.notebook.get_n_pages (); i++) {
                var tab = this.notebook.get_nth_page (i) as ITab;
                if (tab is FileTab) {
                    var file = tab as FileTab;
                    file.mindmap.apply_style ();
                }
            }
        }
    }
}
