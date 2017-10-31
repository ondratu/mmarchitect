/*
 * DESCRIPTION      Tip struct and tips static data
 * PROJECT          Mind Map Architect
 * AUTHOR           Ondrej Tuma <mcbig@zeropage.cz>
 *
 * Copyright (C) Ondrej Tuma 2011
 * Code is present with BSD licence.
 */

public enum TipCategory {
    APP,
    MINDMAP
}

public struct Tip {
    public uint category;
    public string title;
    public string body;

    public Tip(string title, string body, uint category = TipCategory.APP) {
        this.title = title;
        this.body = body;
        this.category = category;
    }
}

public static Tip[] get_tips () {
    Tip[] tips = {
        Tip(_("Moving with Ideas"),
            _("You can move with ideas by key shortcuts. You can use CTRL - Arrow UP, Down, Left or Right to move with selected Ideas.")),

        Tip(_("Using Mind Maps as TODO list"),
            _("Mind Maps could be use as TODO lists. You have more tree like possibility with mind maps, like categories, importance or difficulty."),
            TipCategory.MINDMAP)
    };

    return tips;
}
