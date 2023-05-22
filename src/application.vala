extern const string GETTEXT_PACKAGE;
extern const string LOCALEDIR;
extern const string DATADIR;

string ? DATA_DIR = null;

public class Application : Gtk.Application {
    private static bool version = false;
    private static string filename = "";

    private const OptionEntry[] options = {
        { "version", 0,
          0, OptionArg.NONE, ref version,
          "Display version number", null },
        { "", 0,
          OptionFlags.FILENAME, OptionArg.CALLBACK, (void*) parse_filename,
          null, "FILE" },
        { null }
    };

    public Application () {
        Object (application_id: "cz.zeropage.MMArchitect",
                flags: ApplicationFlags.HANDLES_COMMAND_LINE);

        add_main_option_entries (options);

        set_accels_for_action("app.new-window", {"<Control>n", null});
        set_accels_for_action("app.quit", {"<Control>q", null});
    }

    public override void startup () {
        base.startup ();

        var action = new SimpleAction("new-window", null);
        action.activate.connect (() => {
            hold();
            add_window (new MainWindow ());
            active_window.present ();
            release();
        });
        add_action (action);

        action = new SimpleAction("quit", null);
        action.activate.connect (() => {
            quit ();
        });
        add_action (action);

        action = new SimpleAction ("about", null);
        action.activate.connect (() => {
            var dialog = new AboutDialog ();
            dialog.present ();
        });
        add_action (action);
    }

    public override void activate () {
        this.hold ();
        base.activate ();

        if (this.get_active_window () == null) {
            this.add_window (new MainWindow ());
        }

        this.active_window.present ();
        this.release ();
    }

    public bool parse_filename(string option_name, string? val, void* data) {
        // TODO: check file extensions, access and so on
        filename = option_name;     // becaouse there is only one string
        return true;
    }

    public override int handle_local_options (VariantDict options) {
        if (version) {
            stdout.printf ("mmarchitect - Version 0.0.0\n");
            return 0;           // just like help
        }

        return -1;
    }

    // is called when handle_local_options return -1
    public override int command_line (ApplicationCommandLine command_line) {
        this.hold ();

        this.add_window (new MainWindow (filename));
        this.active_window.present ();
        this.release ();

        return 0;
    }

    public override void open (File[] files, string hint) {
        stdout.printf (@"open hint:$hint\n is not implement yet");
    }
}

int main(string[] args) {
    string ? lc_time = null;

    DATA_DIR = Environment.get_variable ("DATADIR");
    if (DATA_DIR == null){
        DATA_DIR = DATADIR;
    }

    #if ! WINDOWS
    lc_time = Environment.get_variable ("LC_TIME");
    if (lc_time == null) {
        lc_time = Environment.get_variable ("LC_ALL");
    }
    if (lc_time == null) {
        lc_time = Environment.get_variable ("LANG");
    }
#else
    lc_time = Win32.getlocale ();
#endif
    if (lc_time != null) {
        GLib.Intl.setlocale (LocaleCategory.TIME, lc_time);
    }

    string ? locale_dir = null;
    locale_dir = GLib.Environment.get_variable ("LOCALEDIR");
    if (locale_dir == null) {
        locale_dir = LOCALEDIR;
    }

    Intl.bindtextdomain (GETTEXT_PACKAGE, locale_dir);
    Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain (GETTEXT_PACKAGE);

    return new Application ().run (args);
}
