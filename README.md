# mallob-impcheck-data
Software references and experimental data for SAT'24 submission "Scalable Trusted SAT Solving with on-the-fly LRAT Checking"

## Software

* MallobSat: https://github.com/domschrei/mallob/tree/proof23
  * The standalone proof checker operating on compressed and inverted LRAT proofs is contained in this repository and is built to `<build directory>/standalone_lrat_checker` if you set the CMake build option `-DMALLOB_BUILD_CPP_LRAT_MODULES=1`.
* ImpCheck (trusted parser/checker/confirmer modules): https://github.com/domschrei/impcheck

After building both, copy the executables `impcheck_{parse,check}` into Mallob's build directory.

## Experimental Data

*to be added*
