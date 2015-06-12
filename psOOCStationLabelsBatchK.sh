#!/bin/bash 

#
# Make sure you have saved/exported/converted initial file 
#	from .xls to .csv (Comma Separated Value).
#
printf "Processing input file into new CSV.\n"

time ./recolumnD.pl $1   | grep -v ^\# > BDW6.csv



printf "Splitting\n"
# Hard code split 400 lines per file
time split -l400 -d -a3 BDW6.csv sm
numfiles=$(( $(wc -l BDW6.csv | awk '{print $1}') / 400 ))    ### integer will round down
printf "numfiles = $numfiles\n"


cat > header.plt << EOF
reset
set terminal postscript landscape color font "Times,8"
set datafile separator ",";
set ylabel "millivolts"; 
set grid lt 1 lw 1 lc rgb "#bbbbbb"  
set grid noxtics
set xlabel "Station [100ft]";
set title "Boardwalk\n  Interrupted Survey \n March 1 2013"  
set yrange [0:-2500]
set bmargin at screen 0.00
set lmargin at screen 0.05
set tmargin at screen 0.95
set ytics  0,-250,-2500  
set tics out
set key box noopaque  


EOF

> runit.plt 
cat header.plt >> runit.plt 

printf "Writing runit.plt from a loop\n"
time for (( i = 0 ; i <= $numfiles ; i++ )) 
	do \
a=`printf sm%03d $i`
awk -v sq="'" -F, ' length($3) > 4  \
        {print "set label " $1+1.0 " " sq  $1 substr($3,0,60) sq " at " $1+5 ",-60 rotate left "}' $a;

	printf "\
pause 0 \n  
set output 'x%03d.eps' \n\
set xrange [ $(( $i*1000)) : $(( ($i+1)*1000))  ] \n
plot \
'sm%03d' using 1:4:xtic(2) w l title 'On',  \
'sm%03d' using 1:5 w l title 'Off', \
'sm%03d' using 1:6  title 'outside of -850 and -1250' points .5, \
-850  w l linestyle 4 title '-850mV', \
-1250 w l linestyle 4 title '-1250mV' \n" \
	$i $i $i $i

set xtics $(( $i*1000)),100,$(( ($i+1)*1000))   \n
printf "unset label\n\n"

done >> runit.plt

printf " Gnuplotting gnuplot.exe  runit.plt\n"
time gnuplot  runit.plt

printf " cat x*.eps > bigX.ps\n"
time cat x*.eps > bigX.ps
printf " converting to PDF\n"
time ps2pdf bigX.ps bigX$$.pdf
printf " done \n"
rm *.eps  
rm sm???

