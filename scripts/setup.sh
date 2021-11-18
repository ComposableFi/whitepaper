PANDOC="https://github.com/jgm/pandoc/releases/download/2.16/pandoc-2.16-1-amd64.deb"
PANDOCCROSSREF="https://github.com/lierdakil/pandoc-crossref/releases/download/v0.3.12.1/pandoc-crossref-Linux.tar.xz"

wget -c $PANDOC -O pandoc.deb
apt-get install ./pandoc.deb -y
apt-get autopurge pandoc-data

wget -c $PANDOCCROSSREF -O pandoc-crossref.tar.xz
tar -xf pandoc-crossref.tar.xz
mv pandoc-crossref /usr/local/bin/
chmod a+x /usr/local/bin/pandoc-crossref
mkdir -p /usr/local/man/man1
mv pandoc-crossref.1  /usr/local/man/man1