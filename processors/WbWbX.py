import os
import sys
import math
import argparse
import random
import ROOT
import numpy as np

from PhysicsTools.NanoAODTools.postprocessing.framework.postprocessor import PostProcessor
from PhysicsTools.NanoAODTools.postprocessing.framework.datamodel import Collection, Object
from PhysicsTools.NanoAODTools.postprocessing.framework.eventloop import Module
from PhysicsTools.NanoAODTools.modules import *

parser = argparse.ArgumentParser()

parser.add_argument('--isData', dest='isData', action='store_true', default=False)
parser.add_argument('--isSignal', dest='isSignal', action='store_true', default=False)
parser.add_argument('--year', dest='year', action='store', type=int, default=2016)
parser.add_argument('--input', dest='inputFiles', action='append', default=[])
parser.add_argument('--maxEntries', '-N', type=int, default=None)
parser.add_argument('output', nargs=1)
parser.add_argument('--step', type=int, default=0, help='stepnumber of the analysis workflow to run (can only run one step at a time)')


args = parser.parse_args()
print(args)

globalOptions = {
    "isData": args.isData,
    "isSignal": args.isSignal,
    "year": args.year
}

isMC = not args.isData


preskim = {
            2016: '(HLT_IsoMu24 == 1) || (HLT_IsoTkMu24 == 1) || (HLT_Ele32_eta2p1_WPTight_Gsf==1)',
            2017: '(HLT_Ele30_eta2p1_WPTight_Gsf_CentralPFJet35_EleCleaned == 1) || (HLT_Ele35_WPTight_Gsf == 1) || (HLT_IsoMu27==1)',
            2018: '(HLT_IsoMu24 == 1) || (HLT_Ele30_eta2p1_WPTight_Gsf_CentralPFJet35_EleCleaned == 1) || (HLT_Ele32_WPTight_Gsf == 1)'
          }


# TODO Final Event selection
selection = 'nElectron + nMuon == 1'



# TODO add correct WP
btagWP ={
            2016: 0.5,
            2017: 0.5,
            2018: 0.5
        }









##############
##  STEP 1  ##
##############


# apply preskim only to background
preskimcut = ''
if not args.isSignal:
    preskimcut = preskim[args.year]



step1_analyzerChain = [

#TODO particle selections/filters

#TODO particle selections/filters

    #MuonSelection(
        #inputCollection=lambda event: Collection(event, "Muon"),
        #outputName="tightMuons",
        #storeKinematics=['pt','eta'],
        #storeWeights=True,
        #muonMinPt=minMuonPt[globalOptions["year"]],
        #triggerMatch=True,
        #muonID=MuonSelection.TIGHT,
        #muonIso=MuonSelection.TIGHT,
        #globalOptions=globalOptions
    #),

    #EventSkim(selection=lambda event: event.ntightMuons > 0),
    #SingleMuonTriggerSelection(
        #inputCollection=lambda event: event.tightMuons,
        #outputName="IsoMuTrigger",
        #storeWeights=True,
        #globalOptions=globalOptions
    #),

    #EventSkim(selection=lambda event: event.IsoMuTrigger_flag > 0),
    #MuonVeto(
        #inputCollection=lambda event: event.tightMuons_unselected,
        #outputName = "vetoMuons",
        #muonMinPt = 10.,
        #muonMaxEta = 2.4,
        #globalOptions=globalOptions
    #),
    #MetFilter(
        #globalOptions=globalOptions,
        #outputName="MET_filter"
    #),
    #JetSelection(
        #inputCollection=lambda event: Collection(event,"Jet"),
        #leptonCollectionDRCleaning=lambda event: event.tightMuons,
        #jetMinPt=30.,
        #jetMaxEta=4.7,
        #jetId=JetSelection.LOOSE,
        #outputName="selectedJets",
        #globalOptions=globalOptions
    #)




#TODO weights calculation

#TODO scale factor calculation

#TODO Jet to GenJet matching

]

# add Wb generator to signal sample
if args.isSignal:
    step1_analyzerChain.append(WbGen())



step1 = PostProcessor(
    args.output[0],
    args.inputFiles,
    postfix='_1',
    cut=preskimcut,
    modules=step1_analyzerChain,
    friend=False,
    outputbranchsel='processors/step1.txt',
    maxEntries=args.maxEntries,
)




##############
##  STEP 2  ##
##############

step2_analyzerChain = [

# TODO apply btagging WP

# TODO apply b charge tagger

# TODO drop special tagger variables




]



step2 = PostProcessor(
    args.output[0],
    args.inputFiles,
    postfix='_2',
    cut='',
    modules=step2_analyzerChain,
    friend=False,
    outputbranchsel='processors/step2.txt',
    maxEntries=args.maxEntries,
)




##############
##  STEP 3  ##
##############



step3_analyzerChain = [


# TODO W/Wb reco

# TODO add smeared truth

# TODO apply binning for asymmetry





]



step3 = PostProcessor(
    args.output[0],
    args.inputFiles,
    postfix='_3',
    cut=selection,
    modules=step3_analyzerChain,
    friend=False,
    outputbranchsel='processors/step3.txt',
    maxEntries=args.maxEntries,
)





# Run analysis

if args.step == 0:
    print('Nothing todo. Take a break!')
elif args.step == 1:
    step1.run()
elif args.step == 2:
    step2.run()
elif args.step == 3:
    step3.run()
else:
    print('Step not specified. Mismatch!')