mmarchitect-c-$(VERSION) is c source ready source package, which could be
compiled on systems where vala is not present in right version. Standard -c-
package is configured with /usr/local prefix, but you can create your-self
with c-source Makefile rule. For examle like this:

    $ PREFIX=/usr make c-source

After that, you can use this package to compile and install Mind Map Architect
on another system with same config settings. For examle like this:

    $ make
    $ make install

On debian (squeeze for example) coud be use this:

    $ dh_auto_build
    $ dh_auto_test
    $ fakeroot make -f debian/rules binary
    $ sudo dpkg -i ../mmarchitect_${VERSION}_amd64.deb

If you can create sing changes file do:

    $ dpkg-genchanges > ../mmarchitect_${VERSION}_amd64.changes
    $ debsign ../mmarchitect_${VERSION}_amd64.changes
