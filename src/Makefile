-include ../include.mk

BUILD_DIR ?= .build
STAMP = $(BUILD_DIR)/.stamp

SRC_VALA = $(wildcard *.vala)
SRC_C = $(SRC_VALA:%.vala=$(BUILD_DIR)/%.c)
OBJS = $(SRC_C:%.c=%.o)

PKG_CFLAGS = $(shell pkg-config --cflags $(EXT_PKGS))
PKG_LDFLAGS = $(shell pkg-config --libs $(EXT_PKGS))

ifdef DEBUG # debug is set
    VALAFLAGS += -g -D DEBUG
endif

CFLAGS += -DGETTEXT_PACKAGE='"$(PROGRAM)"'
CFLAGS += -DDATADIR='"$(DATADIR)"'
CFLAGS += -DLOCALEDIR='"$(LOCALEDIR)"'
CFLAGS += -DVERSION='"$(VERSION)"'

# VALAFLAGS += $(foreach flag,$(CFLAGS),-X $(flag))

OUTPUT = $(BUILD_DIR)/$(PROGRAM)

ifdef WINDOWS
    LDFLAGS += -Wl,-subsystem,windows
    VALAFLAGS += -D WINDOWS
    OUTPUT = $(OUTPUT).exe
else
    # missing dependence to math library
    # LDFLAGS += -lm
    #CFLAGS += -Dlocaltime_r=localtime
endif

all: $(OUTPUT)

$(STAMP): $(SRC_VALA) Makefile
	@printf "  VALAC $(SRC_VALA)\n"
	@$(UX)mkdir -p $(BUILD_DIR)
	$(SILENT)$(VALAC) --ccode --directory=$(BUILD_DIR) \
		$(foreach pkg,$(EXT_PKGS),--pkg=$(pkg)) \
		$(VALAFLAGS) \
		$(SRC_VALA)
	@$(UX)touch $@

$(SRC_C): $(STAMP)
	@

$(BUILD_DIR)/%.o: $(BUILD_DIR)/%.c
	@printf "  CC $@\n"
	$(SILENT)$(CC) -MMD $(CFLAGS) $(PKG_CFLAGS) -c $< -o $@

ifndef WINDOWS
$(OUTPUT): $(OBJS)
	@printf "  LD $@\n"
	$(SILENT)$(CC) -o $(OUTPUT) $(OBJS) $(LDFLAGS) $(PKG_LDFLAGS)
else
$(OUTPUT): $(OBJS) ../misc/$(PROGRAM).res
	$(SILENT)$(CC) -o $(OUTPUT) $(OBJS) $(LDFLAGS) $(PKG_LDFLAGS) ../misc/$(PROGRAM).res

endif

# object depences creates by $(CC) -MMD
-include $(OBJS:.o=.d)

clean:
	@printf "Cleaning ...\n"
	@$(RM) -r $(BUILD_DIR)

install: $(OUTPUT)
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	$(INSTALL_PROGRAM) $(OUTPUT) $(DESTDIR)$(PREFIX)/bin

uninstall:
	$(RM) $(DESTDIR)$(PREFIX)/bin/$(OUTPUT)
