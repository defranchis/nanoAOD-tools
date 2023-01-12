function run_test()
{
    cd ~
    source /cvmfs/cms.cern.ch/cmsset_default.sh
    export SCRAM_ARCH=slc7_amd64_gcc820 || return 1
    echo
    echo "==================== setup CMSSW ==============="
    scramv1 project CMSSW CMSSW_11_1_7 || return 1
    cd CMSSW_11_1_7/src || return 1
    eval `scram runtime -sh` || return 1
    mkdir -p PhysicsTools/NanoAODTools
    rsync -r --stats /scripts/ PhysicsTools/NanoAODTools/. || return 1
    source PhysicsTools/NanoAODTools/scripts/install_py2-correctionlib.sh
    echo
    echo "==================== compiling ================"
    scram b || return 1
    
    echo

    echo "==================== signal 2017 ====================="
    python PhysicsTools/NanoAODTools/processors/ST.py --year 2017 --ntags -1 --isSignal --maxEvents 1000 --input=https://github.com/WbWbX/test-files/raw/main/nanox_2022-06-22_v10/WbjToLNu_4f_TuneCP5_13TeV-madgraph-pythia8.root || return 1
    echo
    echo "==================== semileptonic ttbar 2017 ====================="
    python PhysicsTools/NanoAODTools/processors/ST.py --year 2017 --ntags -1 --maxEvents 1000 --input=https://github.com/WbWbX/test-files/raw/main/nanox_2022-06-22_v10/TTToSemiLeptonic_TuneCP5_13TeV-powheg-pythia8.root || return 1
    echo
    echo "==================== single muon 2017 ====================="
    python PhysicsTools/NanoAODTools/processors/ST.py --year 2017 --ntags -1 --isData --maxEvents 1000 --input=https://github.com/WbWbX/test-files/raw/main/nanox_2022-03-01_v6/2017_test_SingleMuon.root || return 1
    echo
    echo "==================== single electron 2017 ====================="
    python PhysicsTools/NanoAODTools/processors/ST.py --year 2017 --ntags -1 --isData --maxEvents 1000 --input=https://github.com/WbWbX/test-files/raw/main/nanox_2022-03-01_v6/2017_test_SingleElectron.root || return 1
    echo
    echo "==================== done ====================="
}

run_test
