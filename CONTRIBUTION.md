# Dependecies

MMarchitect need these libraries:

  * glib-2.0
  * gobject-2.0
  * gmodule-2.0
  * gtk+-3.0 (3.20 and above)
  * cairo
  * libxml-2.0
  * gee-0.8 (0.20 and above)
  * librsvg-2.0

And these tools:

  * meson
  * ninja
  * gettext

# Build and Install

```shell
# setup meson
meson build

# run build
cd build
ninja

# install mmarchitect as root
sudo ninja install
```

# Generating pot file

MMarchitect is hosted on weblate translation tool:
https://hosted.weblate.org/projects/mmarchitect/, please use this tool if you
want to contrib with translating.

```shell
# after setting up meson build
cd build

# generate pot file
ninja mmarchitect-pot

# regenerate and propagate changes to every po file
ninja mmarchitect-update-po
```
