/*
 * DESCRIPTION      Welcome panel with tips and last open files.
 * PROJECT          Mind Map Architect
 * AUTHOR           Ondrej Tuma <mcbig@zeropage.cz>
 *
 * Copyright (C) Ondrej Tuma 2011
 * Code is present with BSD licence.
 */

public struct ClaverTime {
    private time_t val;
    private time_t now;

    public ClaverTime (time_t tv_sec){
        this.val = tv_sec;
        time_t (out this.now);
    }

    public string to_string () {
        uint64 vdays = val / 86400;    // 60 * 60 * 24
        uint64 ndays = now / 86400;    // 60 * 60 * 24
        uint64 days =  ndays - vdays;

        // couse localtime_r is no available on win32
#if ! WINDOWS
        var gtime = GLib.Time.local (val);

        if (days == 0)
            return gtime.format (_("Today %H:%M"));
        if (days == 1)
            return gtime.format (_("Yesterday %H:%M"));
        if (days < 7)
            return gtime.format ("%A %H:%M");

        return gtime.format ("%d. %B %Y");
#else
        var gtime = GLib.TimeVal ();
        gtime.tv_sec = val;

        string iso = gtime.to_iso8601();
        string Y = iso.substring(0,4);
        string m = iso.substring(5,2);
        string d = iso.substring(8,2);
        //string H = iso.substring(11,2);
        //string M = iso.substring(14,2);

        if (days == 0)
            return _("Today");     // bad time without timezone
            // return _(@"Today $H:$M");
        if (days == 1)
            return _("Yesterday"); // bad time without timezone
            // return _(@"Yesterday $H:$M");
        //if (days < 7)
        //    return @"$d. $m. $H:$M";

        return @"$d. $m. $Y";
#endif
    }
}

public class WelcomeTab : Gtk.ScrolledWindow, ITab {
    public TabLabel tablabel { get; private set; }
    public string title { get; set; }

    public signal void sig_new_file (Gtk.Widget w);
    public signal void sig_open_file (Gtk.Widget w);
    public signal void sig_open_path (Gtk.Widget w, string path);

    private Tip[] tips;
    public uint tip_index { get; private set; }
    private Gtk.Label tip_title;
    private Gtk.Label tip_body;
    private Gtk.VBox file_box;

    private Preferences pref;

    public WelcomeTab (Preferences pref) throws Error {
        this.pref = pref;
        title = _("Start here");

        tablabel = new TabLabel (title);
        tablabel.close_button.button_press_event.connect(
                (e) => {
                    closed(this);
                    return true;
                });

        set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);

        loadui();
        set_recent ();
        set_tips ();

        show_all();
    }

    private void loadui () throws Error {
        var builder = new Gtk.Builder();
        builder.add_from_file (DATA + "/ui/welcome.ui");
        builder.connect_signals (this);

        var mainbox = builder.get_object ("mainbox") as Gtk.HBox;
        add_with_viewport (mainbox);

        tip_title = builder.get_object ("tip_title") as Gtk.Label;
        tip_body = builder.get_object ("tip_body") as Gtk.Label;

        file_box = builder.get_object ("file_box") as Gtk.VBox;

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
        foreach (var it in pref.get_recent_files()){
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
            title.set_alignment (0, (float) 0.5);
            title.set_padding (10, 0);

            var osfile = File.new_for_commandline_arg(path);
            // todo: check permisions
            if (osfile.query_exists ()) {
                title.set_markup (@"<a href=\"#open\" title=\"$path\">$fname</a>");
                title.activate_link.connect(
                    (e) => {
                        sig_open_path(title as Gtk.Widget, path);
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
            time.set_alignment (1, (float) 0.5);

            var box = new Gtk.VBox (false, 0);
            box.add (title);
            box.add (time);

            file_box.add (box);
            nth++;
        }
    }

    public void set_tips () {
        tips = get_tips ();
        tip_index = (uint32) GLib.Random.int_range(0, tips.length);

        tip_title.set_label (tips[tip_index].title);
        tip_body.set_label (tips[tip_index].body);
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT welcome_tab_new_file")]
    public void new_file (Gtk.Widget w, Gdk.EventButton e) {
        sig_new_file(w);
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT welcome_tab_open_file")]
    public void open_file (Gtk.Widget w, Gdk.EventButton e) {
        sig_open_file(w);
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT welcome_tab_next_tip")]
    public void next_tip (Gtk.Widget w, string uri) {
        tip_index++;
        if (tip_index == tips.length)
            tip_index = 0;

        tip_title.set_label (tips[tip_index].title);
        tip_body.set_label (tips[tip_index].body);
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
