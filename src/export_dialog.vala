/*
 * DESCRIPTION      Map canvas for drawing nodes tree.
 * PROJECT          Mind Map Architect
 * AUTHOR           Ondrej Tuma <mcbig@zeropage.cz>
 *
 * Copyright (C) Ondrej Tuma 2011
 * Code is present with BSD licence.
 */
// modules: gtk+-3.0
// sources: filetab.vala

enum ExportFilterID {
    TXT,
    HTML,
    DHTML,
    PNG,
    MM
}

/* XXX: This can't be use, see https://bugzilla.gnome.org/show_bug.cgi?id=724347

public class ExtendFileFilter : Gtk.FileFilter {
    public uint id;

    [CCode (has_construct_function = false)]
    private ExtendFileFilter () {}

    public static ExtendFileFilter create (string name, string [] patterns,
            uint id = -1)
    {
        var filter = new ExtendFileFilter ();
        filter.set_name (name);
        filter.id = id;
        foreach (var it in patterns)
            filter.add_pattern (it);

        return filter;
    }
}*/

public class ExportDialog : Gtk.FileChooserDialog {
    public FileTab filetab;
    public string default_directory;

    private Gtk.FileFilter txt;
    private Gtk.FileFilter html;
    private Gtk.FileFilter dhtml;
    private Gtk.FileFilter png;
    private Gtk.FileFilter mm;

    public ExportDialog (FileTab filetab, string default_directory,
            Gtk.Window ? _parent)
    {
        // because base keyword create compilation error:
        // chain up to `Gtk.FileChooserDialog.new' not supported
        /*
        // Not work - generates parent a and container errors
        Object(title: _("Export file as"),
               parent: parent,
               action: Gtk.FileChooserAction.SAVE
               );
        */
        this.title = _("Export Map as");
        this.action = Gtk.FileChooserAction.SAVE;

        this.filetab = filetab;
        this.default_directory = default_directory;

        add_button (_("_Cancel"), Gtk.ResponseType.CANCEL);
        add_button (_("_Export As"), Gtk.ResponseType.ACCEPT);
        set_default_response (Gtk.ResponseType.ACCEPT);

        txt = ExportDialog.create_filter (_("Plain Text"),
                    {"*.txt"});
        add_filter (txt);

        html = ExportDialog.create_filter (_("Simple Web Page"),
                    {"*.html", "*.htm"});
        add_filter (html);

        dhtml = ExportDialog.create_filter (_("Dynamic Web Page"),
                    {"*.dhtml", "*.dhtm"});
        add_filter (dhtml);

        png = ExportDialog.create_filter (_("PNG Image"),
                    {"*.png"});
        add_filter (png);

        mm = ExportDialog.create_filter ("Free Mind",
                    {"*.mm"});
        add_filter (mm);

        set_modal (true);
        set_do_overwrite_confirmation (true);
        response.connect (on_response);
        set_path (filetab.filepath);
    }

    public static Gtk.FileFilter create_filter (string name, string [] patterns) {
        var filter = new Gtk.FileFilter ();
        filter.set_filter_name (name);
        foreach (var it in patterns)
            filter.add_pattern (it);

        return filter;
    }

    public uint get_filter_id (){
        var filter = get_filter();
        if (filter == txt)
            return ExportFilterID.TXT;
        else if (filter == html)
            return ExportFilterID.HTML;
        else if (filter == dhtml)
            return ExportFilterID.DHTML;
        else if (filter == png)
            return ExportFilterID.PNG;
        else if (filter == mm)
            return ExportFilterID.MM;

        return -1;
    }

    public void set_path (string filepath = "") {
        if (filepath == "") {
            set_current_folder(default_directory);
            set_current_name(filetab.title);
        } else {
            set_current_folder(GLib.Path.get_dirname(filepath));
            string fname = GLib.Path.get_basename(filepath);
            set_current_name(fname.substring(0, fname.length-4)); // .txt
        }
    }

    protected void restart_response (int response_id){
        GLib.Signal.stop_emission_by_name (this, "response");
        response (response_id);
    }

    public void on_response (int response_id) {
        /* Need check, if file with suffix exist.
         * This is mechanism, for auto appending suffix to file according to
         * filter.
         */
        if (response_id != Gtk.ResponseType.ACCEPT){
            return;
        }

        var fname = get_filename();
        var filter = get_filter();

        if (filter == txt) {
            if (!fname.down().has_suffix(".txt")) {
                if (set_filename( fname + ".txt"))
                    restart_response (response_id);
            }
        } else if (filter == html) {
            if (!fname.down().has_suffix(".htm") && !fname.down().has_suffix(".html")) {
                if (set_filename( fname + ".html"))
                    restart_response (response_id);
            }
        } else if (filter == dhtml) {
            if (!fname.down().has_suffix(".dhtm") && !fname.down().has_suffix(".dhtml")) {
                if (set_filename( fname + ".dhtml"))
                    restart_response (response_id);
            }
        } else if (filter == png) {
            if (!fname.down().has_suffix(".png")) {
                if (set_filename( fname + ".png"))
                    restart_response (response_id);
            }
        } else if (filter == mm) {
            if (!fname.down().has_suffix(".mm")) {
                if (set_filename( fname + ".mm"))
                    restart_response (response_id);
            }
        }
    }

    public string get_suffixed_filename () {
        var fname = get_filename();
        var filter = get_filter();

        if (filter == txt) {
            if (!fname.down().has_suffix(".txt"))
                return fname + ".txt";
        } else if (filter == html) {
            if (!fname.down().has_suffix(".htm") && !fname.down().has_suffix(".html"))
                return fname + ".html";
        } else if (filter == dhtml) {
            if (!fname.down().has_suffix(".dhtm") && !fname.down().has_suffix(".dhtml"))
                return fname + ".dhtml";
        } else if (filter == png) {
            if (!fname.down().has_suffix(".png"))
                return fname + ".png";
        } else if (filter == mm) {
            if (!fname.down().has_suffix(".mm"))
                return fname + ".mm";
        }

        return fname;
    }
}
