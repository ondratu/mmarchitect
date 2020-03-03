project(
    'mmarchitect', 'vala', 'c',
    version: '0.6.0')

gnome = import('gnome')
i18n = import('i18n')

version = meson.project_version()
project_name = meson.project_name()

prefix = get_option('prefix')

bindir = join_paths(prefix, get_option('bindir'))
datadir = join_paths(prefix, get_option('datadir'))
localedir = join_paths(prefix, get_option('localedir'))
pkgdatadir = join_paths(datadir, project_name)

dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gmodule-2.0'),
    dependency('gtk+-3.0'),
    dependency('cairo'),
    dependency('libxml-2.0'),
    dependency('gee-0.8'),
    dependency('librsvg-2.0'),
]

subdir('ui')
subdir('icons')
subdir('misc')
subdir('po')
subdir('src')

summary = [
  '',
  '------',
  '@0@ @1@'.format(project_name, version),
  '',
  'Directories:',
  '         prefix: @0@'.format(prefix),
  '        datadir: @0@'.format(datadir),
  '------',
]

message('\n'.join(summary))

executable(
    project_name,
    [sources, resources],
    dependencies: dependencies,
    vala_args: [resource_args])
