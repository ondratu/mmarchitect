[Setup]
AppName=Mind Map Architect
AppPublisher=Ondrej Tuma
AppPublisherURL=http://zeropage.cz
AppVerName=Mind Map Architect 0.4.0
DefaultDirName={pf}\Mind Map Architect
DefaultGroupName=Mind Map Architect
LicenseFile=COPYING
OutputDir=.
SourceDir=..
Uninstallable=yes

[Icons]
Name: "{commonprograms}\{groupname}\Mind Map Architect"; Filename: "{app}\bin\mmarchitect.exe"

[Files]
Source: "c:\vala-0.12.0\bin\freetype6.dll"; DestDir: "{app}\bin"
Source: "c:\vala-0.12.0\bin\iconv.dll"; DestDir: "{app}\bin"
Source: "c:\vala-0.12.0\bin\intl.dll"; DestDir: "{app}\bin"
Source: "c:\vala-0.12.0\bin\libatk-1.0-0.dll"; DestDir: "{app}\bin"
Source: "c:\vala-0.12.0\bin\libcairo-2.dll"; DestDir: "{app}\bin"
Source: "c:\vala-0.12.0\bin\libexpat-1.dll"; DestDir: "{app}\bin"
Source: "c:\vala-0.12.0\bin\libfontconfig-1.dll"; DestDir: "{app}\bin"
Source: "c:\vala-0.12.0\bin\libgdk_pixbuf-2.0-0.dll"; DestDir: "{app}\bin"
Source: "c:\vala-0.12.0\bin\libgdk-win32-2.0-0.dll"; DestDir: "{app}\bin"
Source: "c:\vala-0.12.0\bin\libgio-2.0-0.dll"; DestDir: "{app}\bin"
Source: "c:\vala-0.12.0\bin\libglib-2.0-0.dll"; DestDir: "{app}\bin"
Source: "c:\vala-0.12.0\bin\libgmodule-2.0-0.dll"; DestDir: "{app}\bin"
Source: "c:\vala-0.12.0\bin\libgobject-2.0-0.dll"; DestDir: "{app}\bin"
Source: "c:\vala-0.12.0\bin\libgthread-2.0-0.dll"; DestDir: "{app}\bin"
Source: "c:\vala-0.12.0\bin\libgtk-win32-2.0-0.dll"; DestDir: "{app}\bin"
Source: "c:\vala-0.12.0\bin\libpango-1.0-0.dll"; DestDir: "{app}\bin"
Source: "c:\vala-0.12.0\bin\libpangocairo-1.0-0.dll"; DestDir: "{app}\bin"
Source: "c:\vala-0.12.0\bin\libpangoft2-1.0-0.dll"; DestDir: "{app}\bin"
Source: "c:\vala-0.12.0\bin\libpangowin32-1.0-0.dll"; DestDir: "{app}\bin"
Source: "c:\vala-0.12.0\bin\libpng14-14.dll"; DestDir: "{app}\bin"
Source: "c:\vala-0.12.0\bin\libxml2.dll"; DestDir: "{app}\bin"
Source: "c:\vala-0.12.0\bin\zlib1.dll"; DestDir: "{app}\bin"

Source: "icons\*"; DestDir: "{app}\share\mmarchitect\icons"
Source: "ui\*"; DestDir: "{app}\share\mmarchitect\ui"
Source: ".langs\*"; DestDir: "{app}\share\locale"
Source: "mmarchitect.exe"; DestDir: "{app}\bin\"

[Run]
Filename: "cmd"; Parameters: "/c mkdir etc\gtk-2.0 & bin\gdk-pixbuf-query-loaders.exe > etc\gtk-2.0\gdk-pixbuf.loaders"; WorkingDir: "{app}"; Flags: runhidden

[UninstallDelete]
Type: files; Name: "{app}\etc\gtk-2.0\gdk-pixbuf.loaders"
Type: dirifempty; Name: "{app}\etc\gtk-2.0"
Type: dirifempty; Name: "{app}\etc"






