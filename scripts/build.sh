set -eu



lockfile="build.lock"

if [ ! -e $lockfile ]; then
   trap "rm -f $lockfile; exit" INT TERM EXIT
   touch $lockfile
   
   mkdir -p dist

   pandoc main.tex -f latex --mathjax https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js -t html5 -o dist/index.html -H styles/whitepaper.css --self-contained

   rm $lockfile
   trap - INT TERM EXIT
else
   echo "already building... If stuck, delete ${lockfile}"
fi