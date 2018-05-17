-include ../include.mk

MSGINIT = msginit
MSGMERGE = msgmerge
MSGFMT = msgfmt
XGETTEXT = xgtettext

SRC_VALA = $(wildcard ../src/*.vala)
FILES_UI = $(wildcard ../ui/*.ui)

LANGUAGES = $(shell (cat LINGUAS))
FILES_PO = $(foreach file, $(LANGUAGES), $(file:=.po))
FILES_MO = $(foreach file, $(LANGUAGES), $(file:=.mo))

all: $(FILES_MO)

$(PROGRAM).pot: $(SRC_VALA) $(FILES_UI)
	@printf "Updating $@\n"
	@printf "  XGETTEXT $@\n"
	$(SILENT)xgettext -o $@ --language=C --keyword=_ --from-code utf-8 \
		--escape --force-po $(SRC_VALA)
	$(SILENT)xgettext -o $@ -j --language=Glade --keyword=translatable \
		--from-code utf-8 --force-po $(FILES_UI)

update-pot: $(PROGRAM).pot

update-po: $(PROGRAM).pot
	@printf "Updating PO files\n"
	$(SILENT)$(foreach lang, $(LANGUAGES), \
		test -f $(lang).po || $(MSGINIT) --no-translator -l $(lang); \
		printf "  MSGMERGE $(lang).po\n"; \
		$(MSGMERGE) -q --backup=simple --update $(lang).po $(PROGRAM).pot;)

%.mo: %.po
	@printf "  MSGFMT $@\n"
	$(SILENT)$(MSGFMT) -c -o t-$@ $< && mv t-$@ $@

install: $(FILES_MO)
	@printf "Install locales\n"
	$(SILENT)$(foreach lang,$(LANGUAGES), \
		$(UX)mkdir -p $(DESTDIR)$(LOCALEDIR)/$(lang)/LC_MESSAGES ; \
		$(INSTALL_DATA) -v $(lang).mo $(DESTDIR)$(LOCALEDIR)/$(lang)/LC_MESSAGES/$(PROGRAM).mo;)

uninstall:
	$(foreach lang,$(LANGUAGES), \
		$(RM) $(DESTDIR)$(LOCALEDIR)/$(lang)/LC_MESSAGES/$(PROGRAM).mo`;)

clean:
	@printf "Cleaning ...\n"
	@$(RM) -v $(PROGRAM).pot
	@$(RM) -v $(FILES_MO)
	@$(RM) -rf $(LANG_DIR)
