# Dependencies

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
  * valac
  * gettext

# Build and Install

```shell
# setup meson
meson setup build

# run build
meson compile -C build

# run tests
meson test -C build

# install mmarchitect as root
sudo meson install -C build

# or local run
DATADIR=. ./build/src/mmarchitect
```

See [INSTALL](INSTALL) for building on Windows.

# Checks before a commit

The code style and the spelling are checked by
[pre-commit](https://pre-commit.com/), see `.pre-commit-config.yaml`:

```shell
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

The `vala-lint` hook needs the `io.elementary.vala-lint` tool from your
distribution, it is not run in the CI. Do not put whitespace errors or new
warnings in the sources.

# Continuous integration

Every push and pull request to `master` is built and tested by GitHub Actions
(`.github/workflows`):

  * `build.yml` builds with Meson and runs `meson test` on Linux (x86_64 and
    aarch64), NetBSD (best effort, its failure does not block a merge) and
    Windows (x86_64 and aarch64, MSYS2)
  * `pre-commit.yml` runs the pre-commit hooks

Make sure that these pass before asking for a merge.

# Generating pot file

MMarchitect is hosted on weblate translation tool:
https://hosted.weblate.org/projects/mmarchitect/, please use this tool if you
want to contribute translations.

```shell
# after setting up the Meson build directory
cd build

# generate pot file
ninja mmarchitect-pot

# regenerate and propagate changes to every po file
ninja mmarchitect-update-po
```
