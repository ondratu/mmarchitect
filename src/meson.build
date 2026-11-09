# add_project_arguments('-DGETTEXT_PACKAGE="mmarchitect"', language: 'c')
# add_project_arguments('-DDATADIR="../"', language: 'c')
# add_project_arguments('-DLOCALEDIR="./"', language: 'c')
# add_project_arguments('-DVERSION="0.5.0"', language: 'c')

add_project_arguments('-DGETTEXT_PACKAGE="@0@"'.format(project_name),
                      language:'c')
add_project_arguments('-DDATADIR="@0@"'.format(pkgdatadir), language: 'c')
add_project_arguments('-DLOCALEDIR="@0@"'.format(localedir), language: 'c')
add_project_arguments('-DVERSION="@0@"'.format(version), language: 'c')


conf_data = configuration_data()
conf_data.set('PROJECT_NAME', project_name)
conf_data.set('DATADIR', datadir)
conf_data.set('PKGDATADIR',pkgdatadir)
conf_data.set('GETTEXT_PACKAGE', project_name)
conf_data.set('VERSION', version)

# config_header = configure_file(
#    input: 'config.vala.in',
#    output: 'config.vala',
#    configuration: conf_data
# )

sources = files(
    'application.vala',
    'clavertime.vala',
    'consts.vala',
    'color_dialog.vala',
    'css.vala',
    'dialogs.vala',
    'editform.vala',
    'export_dialog.vala',
    'export.vala',
    'filetab.vala',
    'import.vala',
    'main_window.vala',
    'mapwidgets.vala',
    'mindmap.vala',
    'node.vala',
    'preferences.vala',
    'print.vala',
    'properties.vala',
    'svgsource.vala',
    'tab.vala',
    'tips.vala',
    'welcometab.vala'
)

extra_vala_args = []
if host_machine.system() == 'windows'
  extra_vala_args += ['-D', 'WINDOWS']
endif

mmarchitect = executable(project_name,
  sources: [sources, resources],
  dependencies: dependencies,
  vala_args: [resource_args, extra_vala_args],
  install: true)

# Starts without a display, so it is usable as a smoke test of the build
test('version', mmarchitect,
  args: ['--version'],
  env: {'DATADIR': meson.project_source_root()})
