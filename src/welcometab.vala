/*
 * DESCRIPTION      Welcome panel with tips and last open files.
 * PROJECT          Mind Map Architect
 * AUTHOR           Ondrej Tuma <mcbig@zeropage.cz>
 *
 * Copyright (C) Ondrej Tuma 2011
 * Code is present with BSD licence.
 */
// modules: gtk+-3.0

public class WelcomeTab : Gtk.ScrolledWindow, ITab {
    public TabLabel tablabel { get; protected set; }
    public Gtk.Label menulabel { get; protected set; }
    public string title { get; set; default = _("Start here"); }

    public signal void sig_new_file (Gtk.Widget w);
    public signal void sig_open_file (Gtk.Widget w);
    public signal void sig_open_path (Gtk.Widget w, string path);

    private Tip[] tips;
    public uint tip_index { get; private set; }
    private Gtk.Label tip_title;
    private Gtk.Label tip_body;
    private Gtk.Box file_box;

    private Preferences pref;

    public WelcomeTab (Preferences pref) throws Error {
        Object (hscrollbar_policy: Gtk.PolicyType.AUTOMATIC,
                vscrollbar_policy: Gtk.PolicyType.AUTOMATIC);
        this.pref = pref;

        this.tablabel = new TabLabel (title);
        this.tablabel.close_button.button_press_event.connect (
                (e) => {
                    this.closed (this);
                    return true;
                });
        this.menulabel = new Gtk.Label (title);

        this.loadui();
        this.set_recent ();
        this.set_tips ();

        this.show_all();
    }

    private void loadui () throws Error {
        var builder = new Gtk.Builder();
        builder.add_from_file (DATA + "/ui/welcome.ui");
        builder.connect_signals (this);

        var mainbox = builder.get_object ("mainbox") as Gtk.Box;
        this.add (mainbox);

        this.tip_title = builder.get_object ("tip_title") as Gtk.Label;
        this.tip_body = builder.get_object ("tip_body") as Gtk.Label;
        this.file_box = builder.get_object ("file_box") as Gtk.Box;

        // set tooltip
        unowned Gtk.Button bt;
        bt = builder.get_object ("open_file_button") as Gtk.Button;
        bt.set_tooltip_text (_("Open file"));
        bt = builder.get_object ("new_file_button") as Gtk.Button;
        bt.set_tooltip_text (_("New file"));

        unowned Gtk.EventBox bx;
        bx = builder.get_object ("open_file_eventbox") as Gtk.EventBox;
        bx.set_tooltip_text (_("Open file"));
        bx = builder.get_object ("new_file_eventbox") as Gtk.EventBox;
        bx.set_tooltip_text (_("New file"));
    }

    public void set_recent () {
        uint nth = 0;
        foreach (var it in this.pref.get_recent_files()){
            if (nth == RECENT_FILES)    // max RECENT_FILES
                break;

            var ctime = ClaverTime(it.time);

            string fname = GLib.Path.get_basename(it.path);
            fname = fname.substring(0, fname.length - 4);   // skip mma
            string path = it.path;

            // title - file name
            var t_attrs = new Pango.AttrList ();
            t_attrs.insert(Pango.attr_scale_new (1.4));

            var title = new Gtk.Label (null);
            title.set_attributes (t_attrs);

            var osfile = File.new_for_commandline_arg(path);
            // todo: check permisions
            if (osfile.query_exists ()) {
                title.set_markup (@"<a href=\"#open\" title=\"$path\">$fname</a>");
                title.activate_link.connect(
                    (e) => {
                        sig_open_path (title as Gtk.Widget, path);
                        return true;
                    });
            } else {
                title.set_markup (@"<u>$fname</u>");
                title.set_tooltip_text(path);
                title.set_sensitive (false);
            }

            // time of last opening
            var d_attrs = new Pango.AttrList ();
            d_attrs.insert(Pango.attr_scale_new (0.8));

            var time = new Gtk.Label (ctime.to_string());
            time.set_attributes (d_attrs);
            time.set_halign (Gtk.Align.END);

            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            box.pack_start (title, false, true, 10);
            box.pack_start (time, true, true, 0);

            this.file_box.add (box);
            nth++;
        }
    }

    public void set_tips () {
        this.tips = get_tips ();
        this.tip_index = (uint32) GLib.Random.int_range(0, tips.length);

        this.tip_title.set_label (this.tips[this.tip_index].title);
        this.tip_body.set_label (this.tips[this.tip_index].body);
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT welcome_tab_new_file")]
    public void new_file (Gtk.Widget w, Gdk.EventButton e) {
        this.sig_new_file (w);
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT welcome_tab_open_file")]
    public void open_file (Gtk.Widget w, Gdk.EventButton e) {
        this.sig_open_file (w);
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT welcome_tab_next_tip")]
    public void next_tip (Gtk.Widget w, string uri) {
        this.tip_index++;
        if (this.tip_index == this.tips.length)
            this.tip_index = 0;

        this.tip_title.set_label (this.tips[this.tip_index].title);
        this.tip_body.set_label (this.tips[this.tip_index].body);
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT welcome_tab_open_uri")]
    public void open_uri (Gtk.Widget w, string uri) {
        try {
#if ! WINDOWS
            Gtk.show_uri(null, uri, Gdk.CURRENT_TIME);
#else
            GLib.Process.spawn_command_line_async(@"cmd /c start $uri");
#endif
        } catch (Error e) {
            var d = new Gtk.MessageDialog(null,
                    Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
                    Gtk.MessageType.ERROR,
                    Gtk.ButtonsType.CLOSE,
                    e.message);
            d.run();
            d.destroy();
        }
    }

}
