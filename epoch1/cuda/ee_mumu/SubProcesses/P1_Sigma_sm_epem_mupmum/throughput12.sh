#!/bin/bash

set +x

omp=0
avxall=0
ep2=0
cpp=1
ab3=0
ggttgg=0
div=0
verbose=0

function usage()
{
  echo "Usage: $0 [-nocpp|[-omp][-avxall]] [-ep2] [-3a3b] [-ggttgg] [-div] [-v]"
  exit 1
}

while [ "$1" != "" ]; do
  if [ "$1" == "-omp" ]; then
    if [ "${cpp}" == "0" ]; then echo "ERROR! Options -omp and -nocpp are incompatible"; usage; fi
    omp=1
    shift
  elif [ "$1" == "-avxall" ]; then
    if [ "${cpp}" == "0" ]; then echo "ERROR! Options -avxall and -nocpp are incompatible"; usage; fi
    avxall=1
    shift
  elif [ "$1" == "-nocpp" ]; then
    if [ "${avxall}" == "1" ]; then echo "ERROR! Options -avxall and -nocpp are incompatible"; usage; fi
    if [ "${omp}" == "1" ]; then echo "ERROR! Options -avxall and -nocpp are incompatible"; usage; fi
    cpp=0
    shift
  elif [ "$1" == "-ep2" ]; then
    ep2=1
    shift
  elif [ "$1" == "-3a3b" ]; then
    ab3=1
    shift
  elif [ "$1" == "-ggttgg" ]; then
    ggttgg=1
    shift
  elif [ "$1" == "-div" ]; then
    div=1
    shift
  elif [ "$1" == "-v" ]; then
    verbose=1
    shift
  else
    usage
  fi
done

exes=

#=====================================
# CUDA (eemumu/epoch1, eemumu/epoch2)
#=====================================
exes="$exes ../../../../../epoch1/cuda/ee_mumu/SubProcesses/P1_Sigma_sm_epem_mupmum/build.none/gcheck.exe"
if [ "${ep2}" == "1" ]; then 
  exes="$exes ../../../../../epoch2/cuda/ee_mumu/SubProcesses/P1_Sigma_sm_epem_mupmum/gcheck.exe"
fi

#=====================================
# C++ (eemumu/epoch1, eemumu/epoch2)
#=====================================
if [ "${cpp}" == "1" ]; then 
  exes="$exes ../../../../../epoch1/cuda/ee_mumu/SubProcesses/P1_Sigma_sm_epem_mupmum/build.none/check.exe"
fi
if [ "${avxall}" == "1" ]; then 
  exes="$exes ../../../../../epoch1/cuda/ee_mumu/SubProcesses/P1_Sigma_sm_epem_mupmum/build.sse4/check.exe"
  exes="$exes ../../../../../epoch1/cuda/ee_mumu/SubProcesses/P1_Sigma_sm_epem_mupmum/build.avx2/check.exe"
fi
if [ "${cpp}" == "1" ]; then 
  exes="$exes ../../../../../epoch1/cuda/ee_mumu/SubProcesses/P1_Sigma_sm_epem_mupmum/build.512y/check.exe"
fi
if [ "${avxall}" == "1" ]; then 
  exes="$exes ../../../../../epoch1/cuda/ee_mumu/SubProcesses/P1_Sigma_sm_epem_mupmum/build.512z/check.exe"
fi
if [ "${ep2}" == "1" ]; then 
  if [ "${cpp}" == "1" ]; then 
    exes="$exes ../../../../../epoch2/cuda/ee_mumu/SubProcesses/P1_Sigma_sm_epem_mupmum/check.exe"
  fi
fi

#=====================================
# CUDA (ggttgg/epoch2)
#=====================================
if [ "${ggttgg}" == "1" ]; then 
  exes="$exes ../../../../../epoch2/cuda/gg_ttgg/SubProcesses/P1_Sigma_sm_gg_ttxgg/gcheck.exe"
fi

#=====================================
# C++ (ggttgg/epoch2)
#=====================================
if [ "${ggttgg}" == "1" ]; then 
  if [ "${cpp}" == "1" ]; then 
    exes="$exes ../../../../../epoch2/cuda/gg_ttgg/SubProcesses/P1_Sigma_sm_gg_ttxgg/check.exe"
  fi
fi

export USEBUILDDIR=1
pushd ../../../../../epoch1/cuda/ee_mumu/SubProcesses/P1_Sigma_sm_epem_mupmum >& /dev/null
pwd
make AVX=none
if [ "${avxall}" == "1" ]; then make AVX=sse4; fi
if [ "${avxall}" == "1" ]; then make AVX=avx2; fi
if [ "${cpp}" == "1" ]; then make AVX=512y; fi # always consider 512y as the C++ reference, even if for clang avx2 is slightly faster
if [ "${avxall}" == "1" ]; then make AVX=512z; fi
popd >& /dev/null

if [ "${ep2}" == "1" ]; then 
  pushd ../../../../../epoch2/cuda/ee_mumu/SubProcesses/P1_Sigma_sm_epem_mupmum >& /dev/null
  pwd
  make
  popd >& /dev/null
fi

if [ "${ggttgg}" == "1" ]; then 
  pushd ../../../../../epoch2/cuda/gg_ttgg/SubProcesses/P1_Sigma_sm_gg_ttxgg >& /dev/null
  pwd
  make
  popd >& /dev/null
fi

function runExe() {
  exe=$1
  args="$2"
  ###echo "runExe $exe $args OMP=$OMP_NUM_THREADS"
  pattern="Process|fptype_sv|OMP threads|EvtsPerSec\[Matrix|MeanMatrix|FP precision|TOTAL       :"
  # Optionally add other patterns here for some specific configurations (e.g. clang)
  pattern="${pattern}|CUCOMPLEX"
  pattern="${pattern}|COMMON RANDOM"
  if [ "${ab3}" == "1" ]; then pattern="${pattern}|3a|3b"; fi
  if perf --version >& /dev/null; then
    # -- Newer version using perf stat
    pattern="${pattern}|instructions|cycles"
    pattern="${pattern}|elapsed"
    if [ "${verbose}" == "1" ]; then set -x; fi
    perf stat $exe $args 2>&1 | egrep "(${pattern})" | grep -v "Performance counter stats"
    set +x
  else
    # -- Older version using time
    # For TIMEFORMAT see https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html
    if [ "${verbose}" == "1" ]; then set -x; fi
    TIMEFORMAT=$'real\t%3lR' && time $exe $args 2>&1 | egrep "(${pattern})"
    set +x
  fi
}

# Profile #registers and %divergence only
function runNcu() {
  exe=$1
  args="$2"
  ###echo "runNcu $exe $args OMP=$OMP_NUM_THREADS"
  if [ "${verbose}" == "1" ]; then set -x; fi
  $(which ncu) --metrics launch__registers_per_thread,sm__sass_average_branch_targets_threads_uniform.pct --target-processes all --kernel-id "::sigmaKin:" --print-kernel-base mangled $exe $args | egrep '(sigmaKin|registers| sm)' | tr "\n" " " | awk '{print $1, $2, $3, $15, $17; print $1, $2, $3, $18, $20$19}'
  set +x
}

# Profile divergence metrics more in detail
# See https://www.pgroup.com/resources/docs/18.10/pdf/pgi18profug.pdf
# See https://docs.nvidia.com/gameworks/content/developertools/desktop/analysis/report/cudaexperiments/kernellevel/branchstatistics.htm
# See https://docs.nvidia.com/gameworks/content/developertools/desktop/analysis/report/cudaexperiments/sourcelevel/divergentbranch.htm
function runNcuDiv() {
  exe=$1
  args="-p 1 32 1"
  ###echo "runNcuDiv $exe $args OMP=$OMP_NUM_THREADS"
  if [ "${verbose}" == "1" ]; then set -x; fi
  ###$(which ncu) --query-metrics $exe $args
  ###$(which ncu) --metrics regex:.*branch_targets.* --target-processes all --kernel-id "::sigmaKin:" --print-kernel-base mangled $exe $args
  ###$(which ncu) --metrics regex:.*stalled_barrier.* --target-processes all --kernel-id "::sigmaKin:" --print-kernel-base mangled $exe $args
  ###$(which ncu) --metrics sm__sass_average_branch_targets_threads_uniform.pct,smsp__warps_launched.sum,smsp__sass_branch_targets.sum,smsp__sass_branch_targets_threads_divergent.sum,smsp__sass_branch_targets_threads_uniform.sum --target-processes all --kernel-id "::sigmaKin:" --print-kernel-base mangled $exe $args | egrep '(sigmaKin| sm)' | tr "\n" " " | awk '{printf "%29s: %-51s %s\n", "", $18, $19; printf "%29s: %-51s %s\n", "", $22, $23; printf "%29s: %-51s %s\n", "", $20, $21; printf "%29s: %-51s %s\n", "", $24, $26}'
  $(which ncu) --metrics sm__sass_average_branch_targets_threads_uniform.pct,smsp__warps_launched.sum,smsp__sass_branch_targets.sum,smsp__sass_branch_targets_threads_divergent.sum,smsp__sass_branch_targets_threads_uniform.sum,smsp__sass_branch_targets.sum.per_second,smsp__sass_branch_targets_threads_divergent.sum.per_second,smsp__sass_branch_targets_threads_uniform.sum.per_second --target-processes all --kernel-id "::sigmaKin:" --print-kernel-base mangled $exe $args | egrep '(sigmaKin| sm)' | tr "\n" " " | awk '{printf "%29s: %-51s %-10s %s\n", "", $18, $19, $22$21; printf "%29s: %-51s %-10s %s\n", "", $28, $29, $32$31; printf "%29s: %-51s %-10s %s\n", "", $23, $24, $27$26; printf "%29s: %-51s %s\n", "", $33, $35}'
  set +x
}

lastExe=
echo -e "\nOn $HOSTNAME ($(nvidia-smi -L | awk '{print $5}')):"
for exe in $exes; do
  if [ ! -f $exe ]; then continue; fi
  if [ "${exe%%/gg_ttgg*}" != "${exe}" ]; then 
    # This is a good GPU middle point: tput is 1.5x lower with "32 256 1", only a few% higher with "128 256 1"
    exeArgs="-p 64 256 1"
    ncuArgs="-p 64 256 1"
  else
    exeArgs="-p 2048 256 12"
    ncuArgs="-p 2048 256 1"
  fi
  if [ "$(basename $exe)" != "$lastExe" ]; then
    echo "========================================================================="
    lastExe=$(basename $exe)
  else
    echo "-------------------------------------------------------------------------"
  fi
  unset OMP_NUM_THREADS
  runExe $exe "$exeArgs"
  if [ "${exe%%/check*}" != "${exe}" ]; then 
    obj=${exe%%/check*}/CPPProcess.o; ./simdSymSummary.sh -stripdir ${obj}
    if [ "${omp}" == "1" ]; then 
      echo "-------------------------------------------------------------------------"
      export OMP_NUM_THREADS=$(nproc --all)
      runExe $exe "$exeArgs"
    fi
  elif [ "${exe%%/gcheck*}" != "${exe}" ]; then 
    runNcu $exe "$ncuArgs"
    if [ "${div}" == "1" ]; then 
      runNcuDiv $exe
    fi
  fi
done
echo "========================================================================="
