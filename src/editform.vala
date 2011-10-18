/*
 * FILE             $Id: $
 * DESCRIPTION      Edit form for nodes.
 * PROJECT          Mind Map Architect
 * AUTHOR           Ondrej Tuma <mcbig@zeropage.cz>
 *
 * Copyright (C) Ondrej Tuma 2011
 * Code is present with BSD licence.
 */


public class BgLabel : Gtk.Widget {
    private static string label;
    private Pango.Layout layout;
 
    public BgLabel (string label) {
        this.label = label;
        this.layout = create_pango_layout (label);
    }

    public override void size_request (out Gtk.Requisition requisition) {
        int width, height;
 
        this.layout.get_size (out width, out height);
        requisition.width = width / Pango.SCALE;
        requisition.height = height / Pango.SCALE;
    }

    public override void realize () {
        var attrs = Gdk.WindowAttr () {
            window_type = Gdk.WindowType.CHILD,
            wclass = Gdk.WindowClass.INPUT_OUTPUT,
            event_mask = get_events () | Gdk.EventMask.EXPOSURE_MASK
        };
        this.window = new Gdk.Window (get_parent_window (), attrs, 0);
        this.window.move_resize (this.allocation.x, this.allocation.y,
                                 this.allocation.width, this.allocation.height);
 
        this.window.set_user_data (this);

        this.style = this.style.attach (this.window);
        this.style.set_background (this.window, Gtk.StateType.NORMAL);
        
        set_flags (Gtk.WidgetFlags.REALIZED);
    }

    public override bool expose_event (Gdk.EventExpose event) {
        var cr = Gdk.cairo_create (this.window);
 
        Gdk.cairo_set_source_color (cr, this.style.fg[this.state]);
 
        // And draw the text in the middle of the allocated space
        int fontw, fonth;
        this.layout.get_pixel_size (out fontw, out fonth);
        cr.move_to ((this.allocation.width - fontw) / 2,
                    (this.allocation.height - fonth) / 2);
        Pango.cairo_update_layout (cr, this.layout);
        Pango.cairo_show_layout (cr, this.layout);
 
        return true;
    }
}

public class WidgetRound {
    public WidgetRound ? next;
    public Gtk.Widget widget;

    public WidgetRound (Gtk.Widget w) {
        widget = w;
        next = null;
    }

    public unowned WidgetRound append (Gtk.Widget w) {
        next = new WidgetRound (w);
        return next;
    }

}

public class EditForm : Gtk.VBox {
    public Node node;
    public Gtk.Entry entry;
    public Gtk.ScrolledWindow text_scroll;
    public Gtk.TextView text_view;
    public BgLabel label;
    public Gtk.Entry point;
    public Gtk.ColorButton btn_color;
    public Gtk.Button btn_save;
    public Gtk.Button btn_close;
    public signal void close();
    public signal void expand_change(bool is_expand, int width, int height);
    public bool newone;
    public bool is_expand;
    public WidgetRound ? actives;
    public List<Gtk.Widget> focusable_widgets;

    public EditForm (Node node, bool newone, Preferences pref){
        this.node = node;
        this.newone = newone;

        entry = new Gtk.Entry();
        actives = new WidgetRound (entry);
        var last = actives;
        focusable_widgets = new List<Gtk.Widget> ();
        set_focus_chain (focusable_widgets);

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
                font_desc.get_size() / (pref.dpi / 102.0)));

        entry.modify_font(font_desc);
        int width = (node.area.width > NONE_TITLE.length * FONT_SIZE) ?
                node.area.width : NONE_TITLE.length * FONT_SIZE;
        int ico_size = (node.text.length > 0 || node.title.length == 0) ? 0 : ICO_SIZE;
        entry.set_size_request (width + TEXT_PADDING * 2 + ico_size, -1);
        focusable_widgets.append (entry);

        btn_color = new Gtk.ColorButton.with_color (node.color);
        btn_color.set_can_focus (true);
        last = last.append (btn_color);
        focusable_widgets.append (btn_color);

        btn_save = new Gtk.Button.from_stock (Gtk.Stock.SAVE);
        btn_save.clicked.connect(() => {save(); close();});
        last = last.append (btn_save);
        focusable_widgets.append (btn_save);
        
        btn_close = new Gtk.Button.from_stock (Gtk.Stock.CLOSE);
        btn_close.clicked.connect(() => {close();});
        last = last.append (btn_close);
        focusable_widgets.append (btn_close);

        text_view = new Gtk.TextView ();
        font_desc = pref.font_desc.copy();
        font_desc.set_size (VIEW_FONT_SIZE * Pango.SCALE);
        text_view.modify_font (font_desc);
        text_view.get_buffer().set_text(node.text);
        last = last.append (text_view);
        focusable_widgets.append (text_view);

        text_scroll = new Gtk.ScrolledWindow (null, null);
        text_scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        text_scroll.get_hscrollbar ().set_size_request (-1,7);
        text_scroll.get_vscrollbar ().set_size_request (7,-1);
        text_scroll.add_with_viewport (text_view);
        text_scroll.set_size_request (-1, VIEW_HEIGHT);

        label = new BgLabel (_("Point") + ":");
        point = new Gtk.Entry ();

        var box = new Gtk.HBox(false, 0);
        box.pack_start(entry);
        box.pack_start (btn_color);
        box.pack_start(btn_save);
        box.pack_start(btn_close);

        /*
        var box2 = new Gtk.HBox(false, 0);
        box2.pack_start (label);
        box2.pack_start (point);
        */

        pack_start(box);
        //pack_start(box2);
        pack_start(text_scroll);

        collapse ();
        box.show ();
        //box2.show ();
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
        Gdk.Color color;
        btn_color.get_color (out color);
        node.set_color (color);
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
            return false;
            /*var it = actives;
            while (it != null) {
                if (it.widget.has_focus) {
                    if (it.next != null)
                        it.next.widget.grab_focus ();
                    else
                        actives.widget.grab_focus ();

                    stdout.printf ("next Widget %s has focus\n" ,it.next.widget.name);
                    break;
                }
                stdout.printf ("Widget %s has not focus\n" ,it.widget.name);
                it = it.next;
            
            }
            actives.widget.grab_focus ();
            return true;
            */
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

    public override void set_focus_child (Gtk.Widget ? widget) {
        if (widget != null)
            stdout.printf ("focused child %s\n" ,widget.name);
        else
            stdout.printf ("no child focused\n");
    }

    public void collapse () {
        is_expand = false;
        //label.hide ();
        //point.hide ();
        text_scroll.hide ();
        btn_color.hide ();
        btn_save.hide ();
        btn_close.hide ();
    }

    public void expand () {
        is_expand = true;
        show_all();
    }
}
