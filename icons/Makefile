-include ../include.mk

all:
clean:

install:
	mkdir -p $(DESTDIR)$(DATADIR)/icons
	$(INSTALL_DATA) *.svg $(DESTDIR)$(DATADIR)/icons
	$(INSTALL_DATA) mmarchitect.png $(DESTDIR)$(DATADIR)/icons
	mkdir -p $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps
	mkdir -p $(DESTDIR)$(PREFIX)/share/icons/hicolor/128x128/apps
	mkdir -p $(DESTDIR)$(PREFIX)/share/icons/hicolor/64x64/apps
	mkdir -p $(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/apps
	mkdir -p $(DESTDIR)$(PREFIX)/share/icons/hicolor/32x32/apps
	mkdir -p $(DESTDIR)$(PREFIX)/share/pixmaps
	$(INSTALL_DATA) $(PROGRAM).svg $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps
	$(INSTALL_DATA) $(PROGRAM)_128.png $(DESTDIR)$(PREFIX)/share/icons/hicolor/128x128/apps/$(PROGRAM).png
	$(INSTALL_DATA) $(PROGRAM).png $(DESTDIR)$(PREFIX)/share/icons/hicolor/64x64/apps
	$(INSTALL_DATA) $(PROGRAM)_48.png $(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/apps/$(PROGRAM).png
	$(INSTALL_DATA) $(PROGRAM)_32.png $(DESTDIR)$(PREFIX)/share/icons/hicolor/32x32/apps/$(PROGRAM).png
	$(INSTALL_DATA) $(PROGRAM).png $(DESTDIR)$(PREFIX)/share/pixmaps
	$(INSTALL_DATA) $(PROGRAM).xpm $(DESTDIR)$(PREFIX)/share/pixmaps

uninstall:
	$(RM) -r $(DESTDIR)$(DATADIR)/icons
	$(RM) $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps/$(PROGRAM).svg
	$(RM) $(DESTDIR)$(PREFIX)/share/icons/hicolor/128x128/apps/$(PROGRAM).png
	$(RM) $(DESTDIR)$(PREFIX)/share/icons/hicolor/64x64/apps/$(PROGRAM).png
	$(RM) $(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/apps/$(PROGRAM).png
	$(RM) $(DESTDIR)$(PREFIX)/share/icons/hicolor/32x32/apps/$(PROGRAM).png
	$(RM) $(DESTDIR)$(PREFIX)/share/pixmaps/$(PROGRAM).png
	$(RM) $(DESTDIR)$(PREFIX)/share/pixmaps/$(PROGRAM).xpm
