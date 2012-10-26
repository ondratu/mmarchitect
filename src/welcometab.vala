/*
 * DESCRIPTION      Welcome panel with tips and last open files.
 * PROJECT          Mind Map Architect
 * AUTHOR           Ondrej Tuma <mcbig@zeropage.cz>
 *
 * Copyright (C) Ondrej Tuma 2011
 * Code is present with BSD licence.
 */

public class WelcomeTab : Gtk.VBox, ITab {
    public TabLabel tablabel { get; private set; }
    public string title { get; set; }

    //public signal void closed(ITab tab);
    
    public WelcomeTab (Preferences pref) {
        title = _("Start here");

        tablabel = new TabLabel (title);
        tablabel.close_button.button_press_event.connect(
                (e) => {
                    closed(this);
                    return true;
                });
    }
} 
