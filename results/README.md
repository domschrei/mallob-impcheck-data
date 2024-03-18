
## Experimental Data

The individual data files in `data/` are structured as follows:
* `{,ram,size,validation,validationtraversetime}table-*`: Raw data extracted from logs; featuring either the running times or the respective property in the file name.
* `cdf-*`: Data points for CDF ("inverted cactus") plots, i.e., running times sorted in ascending order coupled with the cumulative solved instances at that point.
* `q{checkercpuratios,proofsizes,prooftravtimes,ram,times,tup,tuv}-*` (q = "qualified"): Instance file name, found result (10=SAT, 20=UNSAT), and the value of the respective property in the file name.
* `*-overheads-*`: precomputed raw list of overheads (ratios) of a certain property of approach X over approach Y.

`bash report.sh data/` re-generates all derived result files from the base result files (`data/*table*`).  
Edit the bottom of `report.sh` to also output plots; in these cases, you need the content of the repository https://github.com/domschrei/plotscripts in your `$PATH`.
