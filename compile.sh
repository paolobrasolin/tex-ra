mkdir tmp
$1 --output-dir=tmp $2.tex
mv tmp/$2.pdf ./
