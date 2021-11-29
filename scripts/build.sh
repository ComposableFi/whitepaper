set -eu

lockfile="build.lock"

if [ ! -e $lockfile ]; then
   trap "rm -f $lockfile; exit" INT TERM EXIT
   touch $lockfile

   mkdir -p dist

   # The option: -H styles/whitepaper.css \ hides the references.
   pandoc -s -f markdown \
             --toc \
             --filter pandoc-crossref \
             --citeproc \
             --mathjax=https://cdn.jsdelivr.net/npm/mathjax@3.0.1/es5/tex-mml-chtml.js \
             --bibliography=references.bib \
             --csl=styles/csl/ieee.csl \
             -H styles/whitepaper.css \
             -t html5 \
             --metadata title="Composable Finance\
             Whitepaper" \
             --metadata link-citations=true \
             -o site/index.html whitepaper.md

   rm $lockfile
   trap - INT TERM EXIT
else
   echo "already building... If stuck, delete ${lockfile}"
fi