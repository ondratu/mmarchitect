/*
 * DESCRIPTION      Welcome panel with tips and last open files.
 * PROJECT          Mind Map Architect
 * AUTHOR           Ondrej Tuma <mcbig@zeropage.cz>
 *
 * Copyright (C) Ondrej Tuma 2011
 * Code is present with BSD licence.
 */

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

    public WelcomeTab (Preferences pref) throws Error {
        title = _("Start here");

        tablabel = new TabLabel (title);
        tablabel.close_button.button_press_event.connect(
                (e) => {
                    closed(this);
                    return true;
                });

        set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);

        loadui();
        set_tips ();
        
        show_all();
    }

    public void loadui () throws Error {
        var builder = new Gtk.Builder();
        builder.add_from_file (DATA + "/ui/welcome.ui");
        builder.connect_signals (this);

        var mainbox = builder.get_object ("mainbox") as Gtk.HBox;
        add_with_viewport (mainbox);

        tip_title = builder.get_object ("tip_title") as Gtk.Label;
        tip_body = builder.get_object ("tip_body") as Gtk.Label;
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
} 
