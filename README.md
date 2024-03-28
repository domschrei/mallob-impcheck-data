# Scalable Trusted SAT Solving with on-the-fly LRAT Checking

This repository features the software references and experimental data for the 2024 SAT conference submission titled as above.
A non-reviewed preprint of this paper is available at [paper-preprint.pdf](paper-preprint.pdf).

## Software

* Mallob (branch `proof23`): https://github.com/domschrei/mallob/tree/e4418e86b3cb8fe1d1b3de0907dd2da05a37078c
  * The standalone proof checker operating on compressed and inverted LRAT proofs is contained in this repository and is built to `<build directory>/standalone_lrat_checker` if you set the CMake build option `-DMALLOB_BUILD_LRAT_MODULES=1`.
* ImpCheck (trusted parser/checker/confirmer modules): https://github.com/domschrei/impcheck
* Gimsatul: https://github.com/arminbiere/gimsatul/tree/09b1b3bcb5d86ef6f75bc9a0f69717c42ced70d4
* drat-trim: https://github.com/marijnheule/drat-trim

After building both Mallob and ImpCheck, copy the executables `impcheck_{parse,check}` built from ImpCheck into Mallob's build directory.

## Experiments

We ran MallobSat as in the following SBATCH script excerpt. Don't forget to define `$f`, `$globallogdir`, and `$localtmpdir`.

```bash
cbbs=$(echo "1500*${SLURM_CPUS_PER_TASK}/2"|bc -l)
cbbs=${cbbs%.*}

# Set one !
## No LRAT config
#timeout=300;  proofopts="-satsolver=c"
## OTFC config
#timeout=300;  proofopts="-satsolver=c! -otfc=1 -mlpt=25``000``000"
## Proof config
#timeout=1800; proofopts="-satsolver=c! -sswl=300 -mempanic=0 -proof=${localtmpdir}/proof.lrat -proof-dir=${localtmpdir}/proof -extmem-disk-dir=${localtmpdir}/disk -cdel=1 -compact-proof=0 -uninvert-proof=0"

cmd="
build/mallob -mono=$f -jwl=$timeout -wam=60``000 \
`#outputs` -q -log=$globallogdir -sro=${globallogdir}/processed-jobs.out -os=1 -s2f=${globallogdir}/model -v=4 \
`#deployment` -rpa=1 -pph=2 -mlpt=50``000``000 -t=${SLURM_CPUS_PER_TASK} \
`#diversification` -isp=0 -div-phases=1 -div-noise=0 -div-seeds=1 -div-elim=0 -div-native=1 -scsd=0 \
`#sharingsetup` -scll=60 -slbdl=60 -csm=3 -cfm=3 -cfci=30 -mscf=5 -bem=1 -aim=1 -rlbd=0 -ilbd=1 -randlbd=0 -scramble-lbds=0 \
`#sharingvolume` -s=0.5 -cbbs=$cbbs -cblm=1 -cblp=250``000 -cusv=1 \
`#randomseed` -seed=0 \
`#disable checking models in on-the-fly checking` -otfcm=0 \
$proofopts
"

# Pre-create global log directory to avoid many concurrent filesystem manips
oldpath=$(pwd)
mkdir -p $globallogdir
cd "$globallogdir"
for rank in $(seq 0 $(($SLURM_NTASKS-1))); do
        mkdir $rank
done
cd "$oldpath"

# Drop hint which file we're solving
echo "$f" > ${globallogdir}/instance.txt

# Export tmp directory as env var
export MALLOB_TMP_DIR="${localtmpdir}/tmp"

# Assemble MPI command options
mpicall="mpirun -n ${SLURM_NTASKS} --bind-to core --map-by socket:PE=${SLURM_CPUS_PER_TASK} \
-x PATH=$PATH -x RDMAV_FORK_SAFE=$RDMAV_FORK_SAFE -x MALLOC_CONF=$MALLOC_CONF -x MALLOB_TMP_DIR=$MALLOB_TMP_DIR"

# Create local directories at *each* node
$mpicall mkdir -p "$localtmpdir" "$MALLOB_TMP_DIR"

# Launch
echo "$(date) JOB $i LAUNCHING"
echo $mpicall -report-bindings $cmd
$mpicall -report-bindings $cmd &
pid=$!
sleep $(($timeout+10)) && kill $pid && ps aux|grep -E "[m]allob|[t]rusted_" &
wait $pid

# Enable to show size of final proof
#$mpicall bash -c "ls -l ${localtmpdir}/proof.lrat 2>/dev/null || :"
# Enable to move final proof to persistent directory
#$mpicall bash -c "mv ${localtmpdir}/proof.lrat ${localtmpdir}/proof.lrat~ 2>/dev/null && mv ${localtmpdir}/proof.lrat~ ${globallogdir}/proof.lrat || :"
# Remove entire tmp directory and any remaining SHMEM files
$mpicall bash -c "rm -rf ${localtmpdir} /dev/shm/edu.kit.iti.mallob.* 2>/dev/null || :"
```


## Data

The gathered experimental data can be found in `results/`.
