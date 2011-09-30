/*
 * FILE             $Id: $
 * DESCRIPTION      Edit form for nodes.
 * PROJECT          Mind Map Architect
 * AUTHOR           Ondrej Tuma <mcbig@zeropage.cz>
 *
 * Copyright (C) Ondrej Tuma 2011
 * Code is present with BSD licence.
 */

public class EditForm : Gtk.VBox {
    public Node node;
    public Gtk.Entry entry;
    public Gtk.ScrolledWindow text_scroll;
    public Gtk.TextView text_view;
    public Gtk.Button btn_save;
    public Gtk.Button btn_close;
    public signal void close();
    public signal void expand_change(bool is_expand, int width, int height);
    public bool newone;
    public bool is_expand;

    public EditForm (Node node, bool newone, AppSettings app_set){
        this.node = node;
        this.newone = newone;

        entry = new Gtk.Entry();
        try {
            var ico = new Gdk.Pixbuf.from_file (DATA + "/icons/comment_edit.png");
            entry.set_icon_from_pixbuf (Gtk.EntryIconPosition.SECONDARY, ico);
        } catch (Error e) {
            stderr.printf ("%s\n", e.message);
            entry.set_icon_from_stock (Gtk.EntryIconPosition.SECONDARY, Gtk.Stock.EDIT);
        }
        
        entry.set_icon_sensitive (Gtk.EntryIconPosition.SECONDARY, true);
        entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Extends edit"));
        entry.set_text (node.title);
        entry.key_press_event.connect (on_key_press_event);
        entry.icon_release.connect (on_change_expand);
        
        var font_desc = node.font_desc.copy();
        font_desc.set_size ((int) GLib.Math.lrint (
                font_desc.get_size() / (app_set.dpi / 102.0)));

        entry.modify_font(font_desc);
        int width = (node.area.width > NONE_TITLE.length * FONT_SIZE) ?
                node.area.width : NONE_TITLE.length * FONT_SIZE;
        int ico_size = (node.text.length > 0) ? 0 : ICO_SIZE;
        entry.set_size_request (width + TEXT_PADDING * 2 + ico_size, -1);
        
        btn_save = new Gtk.Button.from_stock (Gtk.Stock.SAVE);
        btn_save.clicked.connect(() => {save(); close();});
        btn_close = new Gtk.Button.from_stock (Gtk.Stock.CLOSE);
        btn_close.clicked.connect(() => {close();});

        text_view = new Gtk.TextView ();
        font_desc = app_set.font_desc.copy();
        font_desc.set_size (VIEW_FONT_SIZE * Pango.SCALE);
        text_view.modify_font (font_desc);
        text_view.get_buffer().set_text(node.text);

        text_scroll = new Gtk.ScrolledWindow (null, null);
        text_scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        text_scroll.get_hscrollbar ().set_size_request (-1,7);
        text_scroll.get_vscrollbar ().set_size_request (7,-1);
        text_scroll.add_with_viewport (text_view);
        text_scroll.set_size_request (-1, VIEW_HEIGHT);

        var box = new Gtk.HBox(false, 0);
        box.pack_start(entry);
        box.pack_start(btn_save);
        box.pack_start(btn_close);
        pack_start(box);
        pack_start(text_scroll);

        collapse ();
        box.show ();
        entry.show_all ();
        show ();
    }

    public virtual signal void save (){
        newone = false;
        node.set_title (entry.get_text ());
        var buffer = text_view.get_buffer ();
        Gtk.TextIter start, end;
        buffer.get_start_iter (out start);
        buffer.get_end_iter (out end);
        node.set_text (buffer.get_text (start, end, true));
    }

    public bool on_key_press_event (Gdk.EventKey e){
        if (e.keyval == 65307){
            close();
            return true;
        } else if (e.keyval == 65421 || e.keyval == 65293) {
            save();
            close();
            return true;
        } else if (e.keyval == 65471) {
            do_change_expand ();
            return true;
        } else if (e.keyval == 65289 && is_expand) {
            btn_save.grab_focus ();
            return true;
        }

        //stdout.printf ("EditForm key press %s (%u)\n",
        //        Gdk.keyval_name(e.keyval), e.keyval);
        return false;
    }

    public void on_change_expand (Gtk.EntryIconPosition p0, Gdk.Event p1) {
        if (p0 != Gtk.EntryIconPosition.SECONDARY)
            return;

        do_change_expand ();
    }

    public void do_change_expand (){
        if (is_expand)
            collapse ();
        else
            expand ();

        //int width, height;
        //get_size_request (out width, out height);
        //expand_change(is_expand, allocation.width, allocation.height);
    }

    public void collapse () {
        is_expand = false;
        text_scroll.hide ();
        btn_save.hide ();
        btn_close.hide ();
    }

    public void expand () {
        is_expand = true;
        show_all();
    }
}
