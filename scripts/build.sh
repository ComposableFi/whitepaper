set -eu



lockfile="build.lock"

if [ ! -e $lockfile ]; then
   trap "rm -f $lockfile; exit" INT TERM EXIT
   touch $lockfile
   
   mkdir -p dist

   pandoc main.tex -f latex -t html -s -o dist/index.html -H styles/whitepaper.css

   rm $lockfile
   trap - INT TERM EXIT
else
   echo "already building... If stuck, delete ${lockfile}"
fi