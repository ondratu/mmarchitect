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

executable(project_name,
  sources: [sources, resources],
  dependencies: dependencies,
  vala_args: [resource_args],
  install: true)
