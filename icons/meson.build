# Install our icons in all the required sizes
icon_sizes = ['16', '24', '32', '48', '64', '128']

foreach i : icon_sizes
    install_data(
        'application' / i + '.png',
        install_dir: get_option('datadir') / 'icons' / 'hicolor' / i + 'x' + i / 'apps',
        rename: meson.project_name() + '.png'
    )
    install_data(
        'application' / i + '.png',
        install_dir: get_option('datadir') / 'icons' / 'hicolor' / i + 'x' + i + '@2' / 'apps',
        rename: project_name + '.png'
    )
endforeach

install_data(
    'application' / 'mmarchitect.svg',
    install_dir: datadir / 'icons' / 'hicolor' / 'scalable' / 'apps'
)
install_data(
    'application' / 'application-x-mmarchitect.svg',
    install_dir: datadir / 'icons' / 'hicolor' / 'scalable' / 'mimetypes'
)

install_data(
    'application' / 'mmarchitect.xpm',
    install_dir: datadir / 'pixmaps'
)

install_data(
    'application' / '64.png',
    install_dir: datadir / 'pixmaps',
    rename: project_name + '.png'
)

icons = [
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
    'done', 'leave', 'idea', 'tip', 'bomb', 'question', 'warning',
    'phone', 'mail', 'bug', 'plan', 'web', 'yes', 'no', 'maybe',
    ]

# program icons
foreach i: icons
    install_data(
        i + '.svg',
        install_dir: pkgdatadir / 'icons'
    )
endforeach

install_data(
    'application' / 'mmarchitect.svg',
    install_dir: pkgdatadir / 'icons'
)

