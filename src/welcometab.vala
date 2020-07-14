/*
 * DESCRIPTION      Welcome panel with tips and last open files.
 * PROJECT          Mind Map Architect
 * AUTHOR           Ondrej Tuma <mcbig@zeropage.cz>
 *
 * Copyright (C) Ondrej Tuma 2011
 * Code is present with BSD licence.
 */
// modules: gtk+-3.0
// sources: tab.vala tips.vala preferences.vala

[GtkTemplate (ui = "/cz/zeropage/mmarchitect/welcome.ui")]
public class WelcomeTab : Gtk.ScrolledWindow, ITab {
    public TabLabel tablabel { get; protected set; }
    public Gtk.Label menulabel { get; protected set; }
    public string title { get; set; default = _("Start here"); }

    public signal void sig_new_file (Gtk.Widget w);
    public signal void sig_open_file (Gtk.Widget w);
    public signal void sig_open_path (Gtk.Widget w, string path);

    private Tip[] tips;
    public uint tip_index { get; private set; }
    [GtkChild]
    private Gtk.Label tip_title;
    [GtkChild]
    private Gtk.Label tip_body;
    [GtkChild]
    private Gtk.Box file_box;

    private Preferences pref;

    public WelcomeTab (Preferences pref) {
        Object (hscrollbar_policy: Gtk.PolicyType.AUTOMATIC,
                vscrollbar_policy: Gtk.PolicyType.AUTOMATIC);
        this.pref = pref;

        tablabel = new TabLabel (title);
        tablabel.close_button.button_press_event.connect (
                (e) => {
                    closed (this);
                    return true;
                });
        menulabel = new Gtk.Label (title);

        set_recent ();
        set_tips ();

        show_all ();
    }

    public void set_recent () {
        uint nth = 0;
        foreach (var it in pref.get_recent_files ()){
            if (nth == RECENT_FILES){    // max RECENT_FILES
                break;
            }

            var ctime = ClaverTime (it.time);

            string fname = Path.get_basename (it.path);
            fname = fname.substring (0, fname.length - 4);   // skip mma
            string path = it.path;

            // title - file name
            var t_attrs = new Pango.AttrList ();
            t_attrs.insert (Pango.attr_scale_new (1.4));

            var title = new Gtk.Label (null);
            title.set_attributes (t_attrs);

            var osfile = File.new_for_commandline_arg (path);
            // todo: check permisions
            if (osfile.query_exists ()) {
                title.set_markup (@"<a href=\"#open\" title=\"$path\">$fname</a>");
                title.activate_link.connect (
                    (e) => {
                        sig_open_path ((Gtk.Widget) title, path);
                        return true;
                    });
            } else {
                title.set_markup (@"<u>$fname</u>");
                title.set_tooltip_text (path);
                title.set_sensitive (false);
            }

            // time of last opening
            var d_attrs = new Pango.AttrList ();
            d_attrs.insert (Pango.attr_scale_new (0.8));

            var time = new Gtk.Label (ctime.to_string ());
            time.set_attributes (d_attrs);
            time.set_halign (Gtk.Align.END);

            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            box.pack_start (title, false, true, 10);
            box.pack_start (time, true, true, 0);

            file_box.add (box);
            nth++;
        }
    }

    public void set_tips () {
        tips = get_tips ();
        tip_index = (uint32) Random.int_range (0, tips.length);

        tip_title.set_label (tips[tip_index].title);
        tip_body.set_label (tips[tip_index].body);
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT welcome_tab_new_file")]
    public void new_file (Gtk.Widget w, Gdk.EventButton e) {
        sig_new_file (w);
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT welcome_tab_open_file")]
    public void open_file (Gtk.Widget w, Gdk.EventButton e) {
        sig_open_file (w);
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT welcome_tab_next_tip")]
    public void next_tip (Gtk.Widget w, string uri) {
        tip_index++;
        if (tip_index == tips.length) {
            tip_index = 0;
        }

        tip_title.set_label (tips[tip_index].title);
        tip_body.set_label (tips[tip_index].body);
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT welcome_tab_open_uri")]
    public void open_uri (Gtk.Widget w, string uri) {
        try {
#if ! WINDOWS
            Gtk.show_uri_on_window (null, uri, Gdk.CURRENT_TIME);
#else
            GLib.Process.spawn_command_line_async (@"cmd /c start $uri");
#endif
        } catch (Error e) {
            var d = new Gtk.MessageDialog (null,
                    Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
                    Gtk.MessageType.ERROR,
                    Gtk.ButtonsType.CLOSE,
                    e.message);
            d.run ();
            d.destroy ();
        }
    }
}
