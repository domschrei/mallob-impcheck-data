#!/bin/bash

export LC_ALL=C

join="join --check-order"
pipejoin="join --check-order -"

dir="$1"

function compute_data() {

	# qtimes
	for f in $dir/table-{nolrat,otfcc,proof,nolratkcl,gimsatul*}-*node* ; do
		sort -k 1,1b $f -o $f
		cat $f | sed 's/ 20V / 20 /g' | awk '$3 > 0 {print $2,$3,$4}' | sort -k 1,1b > $(echo $f | sed 's/table-/qtimes-/g')
	done
	# qtup
	for f in $dir/table-proof-*node* ; do
		cat $f | awk '$3 == 20 && NF >= 5 {print $2,$3,$5}' | sort -k 1,1b > $(echo $f | sed 's/table-/qtup-/g')
	done
	# qtuv
	for f in $dir/validationtable-proof-*node* ; do
		cat $f | sort -k 1,1b | join --check-order $(echo $f | sed 's/validationtable-/table-/g') - \
		| awk '$3 == 20 && NF >= 6 {print $2,$3,$5+$6}' | sort -k 1,1b > $(echo $f | sed 's/validationtable-/qtuv-/g')
	done
	# qproofsizes
	for f in $dir/sizetable-proof-*node* ; do
		cat $f | sort -k 1,1b | join --check-order $(echo $f | sed 's/sizetable-/table-/g') - \
		| awk '$3 == 20 && NF >= 6 {print $2,$3,$6}' | sort -k 1,1b > $(echo $f | sed 's/sizetable-/qproofsizes-/g')
	done
	for f in $dir/sizetable-gimsatul*-*node* ; do
		cat $f | sort -k 1,1b | join --check-order $(echo $f | sed 's/sizetable-/table-/g') - \
		| awk '$3 == 20 {print $2,$3,$NF}' | sort -k 1,1b > $(echo $f | sed 's/sizetable-/qproofsizes-/g')
	done
	# qprooftravtimes
	for f in $dir/validationtraversetimetable-proof-*node* ; do
		cat $f | sort -k 1,1b | join --check-order $(echo $f | sed 's/validationtraversetimetable-/table-/g') - \
		| awk '$3 == 20 && NF >= 6 {print $2,$3,$6}' | sort -k 1,1b > $(echo $f | sed 's/validationtraversetimetable-/qprooftravtimes-/g')
	done
	# qcheckercpuratios
	for f in $dir/checkercputable-otfc*-*node* ; do
		cat $f | sort -k 1,1b | join --check-order $(echo $f | sed 's/checkercputable-/table-/g') - \
		| awk '$3 != "0" && NF >= 5 {print $2,$5/$4}' > $(echo $f | sed 's/checkercputable-/qcheckercpuratios-/g')
	done

	# ramtable
	for f in $dir/ramtable-*-*node* ; do
		cat $f | sort -k 1,1b | join --check-order $(echo $f | sed 's/ramtable-/table-/g') - \
		| sed 's/ 20V / 20 /g' | awk '$3 != 0 && NF == 5 {print $2,$3,$5}' | sort -k 1,1b > $(echo $f | sed 's/ramtable-/qram-/g')
	done
	# cdf
	for f in $dir/qtimes-{nolrat,otfcc,proof,nolratkcl,gimsatul*}-* ; do
		cat $f|awk '{print $3}' | sort -g | awk '{print $1,NR}' > $(echo $f | sed 's/qtimes-/cdf-/g')
	done

	# extrapolate proof TUV for {4,16} nodes
	for x in 4 16; do
		# tuvx = tupx + (tuv - tup - prooftravtime) + (prooftravtime * (proofsize4 / proofsize))

		# tupx + (tuv - tup - prooftravtime)
		$join $dir/qtup-proof-${x}nodes $dir/qtuv-proof-1node \
		| $pipejoin $dir/qtup-proof-1node \
		| $pipejoin $dir/qprooftravtimes-proof-1node \
		| awk 'NF == 9 {print $1, $2, $3 + $5 - $7 - $9}' > .part1

		# prooftravtime * (proofsize4 / proofsize)
		$join $dir/qprooftravtimes-proof-1node $dir/qproofsizes-proof-4nodes \
		| $pipejoin $dir/qproofsizes-proof-1node \
		| awk 'NF == 7 {print $1, $2, $3 * ($5 / $7)}' > .part2

		# add up
		$join .part1 .part2 | awk '{print $1, $2, $3 + $5}' > $dir/qtuv-proof-${x}nodes
	done

	# relative {time,tup,tuv,ram} overheads
	for op in otfcc proof; do
		for f in $dir/qtimes-${op}-*node* $dir/qtup-${op}-*node* $dir/qtuv-${op}-*node* $dir/qram-${op}-*node* ; do
			if [ ! -f $f ]; then continue ; fi
			base=$(echo $f | sed 's/-'$op'-/-nolrat-/g' | sed 's/qtup/qtimes/g' | sed 's/qtuv/qtimes/g')
			if [ ! -f $base ]; then continue ; fi
			join --check-order $base $f | awk '$2 == $4 {print $5/$3}' | sort -g > $(echo $f | sed 's/-'$op'-/-overheads-'$op'-over-nolrat-/g')
		done
	done
}

function plot_boxplots() {

	plot_boxplots.py data/proof24/horeka/run2/qtimes-overheads-otfcc-over-nolrat-{1node,4nodes,16nodes,32nodes} \
	-l='$1{\times}76$' -l='$4{\times}76$' -l='$16{\times}76$' -l='$32{\times}76$' \
	-ymax=7 -title='ST (=TuV)' -ylabel='Relative overhead' \
	-sizex=2.2 -sizey=3 -spacing=0.6 -width=0.4 -yticks=0.0,0.5,1.0,1.5,2.0,3.0,4.0,5.0,6.0,7.0 -grid -rotatelabels=90 \
	~/workspace/paper-sat24-ontheflyproof/img/boxplot.pdf

	sizex=1.65
	plot_boxplots.py data/proof24/horeka/run2/qtimes-overheads-proof-over-nolrat-{1node,4nodes,16nodes} \
	-l='$1{\times}76$' -l='$4{\times}76$' -l='$16{\times}76$' -ylabel='Relative overhead' \
	-grid -rotatelabels=90 -ymax=7 -yticks=0,1,2,3,4,5,6,7 -sizex=$sizex -sizey=3 -spacing=0.6 -width=0.4 -title=ST \
	~/workspace/paper-sat24-ontheflyproof/img/boxplot-proof-qtimes.pdf
	plot_boxplots.py data/proof24/horeka/run2/qtup-overheads-proof-over-nolrat-{1node,4nodes,16nodes} \
	-l='$1{\times}76$' -l='$4{\times}76$' -l='$16{\times}76$' \
	-grid -rotatelabels=90 -ymax=17 -yticks=0,1,2,3,4,5,10,15 -sizex=$sizex -sizey=3 -spacing=0.6 -width=0.4 -title=TuP \
	~/workspace/paper-sat24-ontheflyproof/img/boxplot-proof-qtup.pdf
	plot_boxplots.py data/proof24/horeka/run2/qtuv-overheads-proof-over-nolrat-{1node,4nodes,16nodes} \
	-l='$1{\times}76$' -l='$4{\times}76$' -l='$16{\times}76$' \
	-grid -rotatelabels=90 -ymax=50 -yticks=0,5,10,20,30,40,50 -sizex=$sizex -sizey=3 -spacing=0.6 -width=0.4 -title='TuV$^{\dagger}$' \
	~/workspace/paper-sat24-ontheflyproof/img/boxplot-proof-qtuv.pdf

	for f in ~/workspace/paper-sat24-ontheflyproof/img/boxplot*.pdf ; do
		pdfcrop $f $f
	done
}

function plot_1v1plots() {

	for x in 1node 4nodes 16nodes 32nodes ; do
		plot_1v1.py \
		data/proof24/horeka/run2/qtimes-nolrat-$x -l='Solving time of \textsc{M-nt} [s]' \
		data/proof24/horeka/run2/qtimes-otfcc-$x -l='Solving time of \textsc{M-ImpChk} [s]' \
		-logscale -min=0.1 -max=450 -T=300 -y2=2 -domainlabels=UNSAT,SAT -domainmarkers=x,+ \
		-domaincolors=orange,blue -size=3 -markersize=4 -nolegend \
		-o=/home/dominik/workspace/paper-sat24-ontheflyproof/img/1v1-nolrat-vs-otfc-${x}.pdf
	done
	
	for f in ~/workspace/paper-sat24-ontheflyproof/img/1v1-*.pdf ; do
		pdfcrop $f $f
	done
}

function plot_cdfplots() {

	#-colors=green,green,blue,blue,blue,orange,orange,orange,red,red,red \
	#-linestyles=-,-.,-,--,-.,-,--,-.,-,--,-. \
	plot_curves.py \
	data/proof24/horeka/run2/cdf-{nolrat,otfcc}-32nodes \
	-l='$32{\times}76$ \textsc{nt}' -l='$32{\times}76$ \textsc{ImpChk}' \
	data/proof24/horeka/run2/cdf-{nolrat,otfcc}-16nodes \
	-l='$16{\times}76$ \textsc{nt}' -l='$16{\times}76$ \textsc{ImpChk}' \
	data/proof24/horeka/run2/cdf-{nolrat,proof,otfcc}-4nodes \
	-l='$4{\times}76$ \textsc{nt}' -l='$4{\times}76$ \textsc{Proof}' -l='$4{\times}76$ \textsc{ImpChk}' \
	data/proof24/horeka/run2/cdf-{nolrat,proof,otfcc}-1node \
	-l='$1{\times}76$ \textsc{nt}' -l='$1{\times}76$ \textsc{Proof}' -l='$1{\times}76$ \textsc{ImpChk}' \
	data/proof24/horeka/run2/cdf-gimsatul76-1node -l='$1{\times}76$ \textsc{Gims}.' \
	data/proof24/horeka/run2/cdf-gimsatul38-1node -l='$1{\times}38$ \textsc{Gims}.' \
	-linestyles=:,:,-.,-.,--,--,--,-,-,-,-,: \
	-colors='blue,red,blue,red,blue,orange,red,blue,orange,red,black,black' \
	-nomarkers -miny=0 -maxy=300 -minx=0 -maxx=300 -extend-to-right -xy \
	-sizex=3 -sizey=3.4 -legend-spacing=0.08 -gridx -gridy -ticksx=0,60,120,180,240,300 \
	-labelx='Solving time $t$ [s]' -labely='\# instances solved in $\leq t$' \
	-o=/home/dominik/workspace/paper-sat24-ontheflyproof/img/cdf.pdf
	#data/proof24/horeka/run2/cdf-nolratkcl-1node -l='$1{\times}76$ non-trusted KCL' \

	for f in ~/workspace/paper-sat24-ontheflyproof/img/cdf*.pdf ; do
		pdfcrop $f $f
	done
}

function print_par2table() {

	for x in nolrat proof otfcc gimsatul38 gimsatul76; do
		for m in 1node 4nodes 16nodes 32nodes; do
			f=$dir/qtimes-${x}-${m}
			if [ ! -f $f ]; then continue; fi
			echo "$x & \$$(echo $m|grep -oE "[0-9]+")$ \
			& $(printf "%d %s %.1f" $(cat $f | awk '$2 > 0 {s+=$3;n+=1} END {print n" & "(s + (400-n)*600)/400}')) \
			& $(printf "%d %s %.1f" $(cat $f | awk '$2 == 10 {s+=$3;n+=1} END {print n" & "(s + (200-n)*600)/200}')) \
			& $(printf "%d %s %.1f" $(cat $f | awk '$2 == 20 {s+=$3;n+=1} END {print n" & "(s + (200-n)*600)/200}')) \\\\"
		done
	done | column -t
}

compute_data
#plot_cdfplots
#plot_boxplots
#plot_1v1plots
print_par2table
