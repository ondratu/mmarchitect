public struct ColorRGBA {
    public double red;
    public double green;
    public double blue;
    public double alpha;

    public ColorRGBA () {
        red     = 0;
        green   = 0;
        blue    = 0;
        alpha   = 1;
    }
}

public abstract class Layer : GLib.Object {
    protected double x;
    protected double y;
    protected double width;
    protected double height;
    public int index;

    protected bool selected;

    public Layer(double x, double y, double width, double height){
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;

        this.selected = false;
    }

    public abstract void expose (Cairo.Context ctx);
    public abstract bool at_layer (Gdk.EventButton event);
    public abstract bool in_area (Gdk.EventExpose event);
    public abstract bool button_press_event (Gdk.EventButton event);
    
    [ CCode ( has_target = false ) ]
    public static int compare (Layer a, Layer b){
        if (a.index < b.index)
            return -1;
        else if (a.index > b.index)
            return 1;
        else
            return 0;   
    }
}

public class LayerArc : Layer {
    protected double radius;
    protected double a1;
    protected double a2;
    
    public ColorRGBA fg;
    public ColorRGBA bg;
    
    public LayerArc(double x, double y, double radius, double a1, double a2){
        base(x - radius, y - radius, radius * 2, radius * 2);
        this.radius = radius;
        this.a1 = a1;
        this.a2 = a2;
    
        fg = ColorRGBA ();
        bg = ColorRGBA () { red = 0.8, blue = 0.8, red = 0.8 };
    }

    public override void expose (Cairo.Context ctx) {
        ctx.arc (x + radius, y + radius, radius, a1, a2);
        ctx.set_source_rgba (bg.red, bg.blue, bg.red, bg.alpha);
        ctx.fill_preserve ();
        if (selected)
            ctx.set_source_rgba (0, 0, 1, 1);
        else
            ctx.set_source_rgba (fg.red, fg.blue, fg.red, bg.alpha);
        ctx.stroke ();
    }

    public override bool at_layer (Gdk.EventButton event) {
        return (event.x >= x && event.y >= y &&
                event.x <= (x + width) && event.y <= (y + height));
    }

    public override bool in_area (Gdk.EventExpose event) {
        //return (event.x >= x && event.y >= y &&
        //        event.x <= (x + width) && event.y <= (y + height));
        // TODO: test jestli je prvek v prekreslene oblasti
        return true;
    }

    public override bool button_press_event (Gdk.EventButton event) {
        selected = ! selected;
        return true; 
    }
}
