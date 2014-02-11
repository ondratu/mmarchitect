/*
 * DESCRIPTION      Welcome panel with tips and last open files.
 * PROJECT          Mind Map Architect
 * AUTHOR           Ondrej Tuma <mcbig@zeropage.cz>
 *
 * Copyright (C) Ondrej Tuma 2011
 * Code is present with BSD licence.
 */
// modules: Gtk

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
