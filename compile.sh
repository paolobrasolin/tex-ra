mkdir tmp
pdflatex --output-dir=tmp $1.tex
mv tmp/$1.pdf ./
