# Mind Map Architect

[![Build](https://github.com/ondratu/mmarchitect/actions/workflows/build.yml/badge.svg)](https://github.com/ondratu/mmarchitect/actions/workflows/build.yml)
[![Pre-commit](https://github.com/ondratu/mmarchitect/actions/workflows/pre-commit.yml/badge.svg)](https://github.com/ondratu/mmarchitect/actions/workflows/pre-commit.yml)

Mind Map Architect is a mind mapping tool for brainstorming, for a single
person just as for a team. Mind maps are also useful for todo lists, notes or
work planning.

## Features

* colors for each idea and its branches
* automatic width of the branch lines
* plain text notes for each idea
* editor styling (fonts, colors, rising)
* FreeMind import and export, including icons and colors
* simple HTML export
* translated to many languages

See [TODO.md](TODO.md) for the planned features.

## Installation

The program is written in [Vala](https://vala.dev/), uses GTK 3 and is built
with [Meson](https://mesonbuild.com/):

```shell
meson setup build
meson compile -C build
meson test -C build
sudo meson install -C build
```

See [INSTALL](INSTALL) for the details and for building on Windows. The
program is built and tested on Linux (x86_64 and aarch64), NetBSD and Windows
(x86_64 and aarch64) by the [CI](.github/workflows/build.yml).

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md). Translations are managed on
[Weblate](https://hosted.weblate.org/projects/mmarchitect/), please use it
instead of editing the `po` files by hand.

## Changes and license

* [ChangeLog](ChangeLog) lists the changes between versions
* [COPYING](COPYING) is the license

## Links

* Ondrej Tuma <http://zeropage.cz>
* Project pages <http://mmarchitect.zeropage.cz>
* Sourceforge <http://sourceforge.net/projects/mmarchitect>

Copyright 2011-2023 Ondrej Tuma
