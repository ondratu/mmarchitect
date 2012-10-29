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

    public WelcomeTab (Preferences pref) throws Error {
        title = _("Start here");

        tablabel = new TabLabel (title);
        tablabel.close_button.button_press_event.connect(
                (e) => {
                    closed(this);
                    return true;
                });

        set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        stdout.printf("welcome_tab_new_file this: %p\n", this);
        loadui();
        show_all();
    }

    public void loadui () throws Error {
        stdout.printf("welcome_tab_new_file this: %p\n", this);
        var builder = new Gtk.Builder();
        builder.add_from_file (DATA + "/ui/welcome.ui");
        builder.connect_signals (this);

        var mainbox = builder.get_object ("mainbox") as Gtk.HBox;
        add_with_viewport (mainbox);
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT welcome_tab_new_file")]
    public void new_file (Gtk.Widget w, Gdk.EventButton e) {
        stdout.printf("welcome_tab_new_file this: %p and widget: %p\n", this, w);
        sig_new_file(w);
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT welcome_tab_open_file")]
    public void open_file (Gtk.Widget w, Gdk.EventButton e) {
        sig_open_file(w);
    }

    [CCode (instance_pos = -1, cname = "G_MODULE_EXPORT welcome_tab_next_tip")]
    public void next_tip (Gtk.Widget w) {
        stdout.printf ("welcometab_next_tip\n");
    }
} 
