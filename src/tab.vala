/*
 * DESCRIPTION      Tab Interface and CloseIco box
 * PROJECT          Mind Map Architect
 * AUTHOR           Ondrej Tuma <mcbig@zeropage.cz>
 *
 * Copyright (C) Ondrej Tuma 2011
 * Code is present with BSD licence.
 */

public class CloseIco : Gtk.EventBox {
    public CloseIco () {
        add (new Gtk.Image.from_icon_name ("window-close",
                                           Gtk.IconSize.SMALL_TOOLBAR));
    }
}

public class TabLabel : Gtk.Box {
    public Gtk.Label label { get; private set; }
    public CloseIco close_button { get; private set; }

    public TabLabel (string title) {
        Object (orientation: Gtk.Orientation.HORIZONTAL, spacing: 10);
        label = new Gtk.Label (title);
        add (label);

        close_button = new CloseIco ();
        add (close_button);

        show_all ();
    }

    public void set_title (string title) {
        label.label = title;
    }
}

public interface ITab : GLib.Object {
    public abstract TabLabel tablabel { get; protected set; }
    public abstract Gtk.Label menulabel { get; protected set; }
    public abstract string title { get; set; }
    public signal void closed (ITab tab);
}
