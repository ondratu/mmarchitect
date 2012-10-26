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
        add (new Gtk.Image.from_stock (Gtk.Stock.CLOSE,
                                       Gtk.IconSize.SMALL_TOOLBAR));
    }
}

public class TabLabel : Gtk.HBox {
    public Gtk.Label label { get; private set; }
    public CloseIco close_button { get; private set; }

    public TabLabel (string title) {
        label = new Gtk.Label(title);
        add(label);

        close_button = new CloseIco();
        add(close_button);

        show_all ();
    }

    public void set_title (string title) {
        label.label = title;
    }
}

public interface ITab : GLib.Object {
    public abstract TabLabel tablabel { get; protected set; }
    public abstract string title { get; set; }
    public signal void closed (ITab tab);
    
}
