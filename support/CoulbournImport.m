function [EEG] = CoulbournImport(FileName, PathName, SRate, SampsChan, ChanFocus, Events, SaveSet, Prefix)
%usage: [EEG] = CoulbournImport(PathFileName, SRate, SampsChan,ChanFocus, Events)
%Imports one channel of epoched text data from Coulbourn multichannel data file
%Input  text file is single string of points X channels X epochs
%Coulbourn allows for different number of points per channel.  
%INPUTS
%FileName: file name for input file
%PathName: path for input file
%SRate: sample rate
%SampsChan: an array of length=#Channels. Each entry is number of samples
%      in an epoch for that channel
%ChanFocus:  Channel number to import (can only do one b/c channels may
%      have different number of points)
%Events:  Array of length = number epochs with event code for each epoch
%SaveSet:  Save the Set file with same name as inputfile
%Prefix:  A prefix to add to the output file name for the .set file
%
%OUTPUTS
%EEG:  An EEG data structure

%Revision history
%2010-12-4, released, JJC
%2011-03-03:  added Prefix parameter, JJC

%for testing with Eileen Ahrean data
%     PathName = 'P:\UW\Users\Curtin\Consult\Active\Ahearn\';
%     FileName = 'sub 77 llh 11-24-08.a2d';
%     SRate = 1000;
%     SampsChan = [200 200 3000 3000];
%     ChanFocus = 1;
%     Events = [];
%     SaveSet = true;
    
    
    %check that pathname ends with \   
    if PathName(length(PathName)) ~= '\'
        PathName = [PathName '\'];
    end
    
    %Open Data file
    DataStream = dlmread([PathName FileName]);
    
    
    %set various parameters about file
    SampsEpoch = sum(SampsChan);
    NumEpochs = length(DataStream) / SampsEpoch;
    NumChans = length(SampsChan);
    
    %if no event codes provided, set all events to 1
    if isempty(Events)
        Events = ones(NumEpochs,1);
    end
    
    %check that number events match number epochs
    if length(Events) ~= NumEpochs
        error('#Event codes (%d) does not equal #Epochs (%d)', length(Events), NumEpochs)
    end
    
    %create channel mask to extract relevant channel
    ChanMask = false(SampsEpoch,1);
    Index = 1;
    for i = 1:NumChans
        if i == ChanFocus
            ChanMask(Index:(Index+SampsChan(i)-1)) = true(1,SampsChan(i));            
        end
        Index = Index+SampsChan(i);
    end
    
    %configure data 
    Data = zeros(1,SampsChan(ChanFocus),NumEpochs);  %3d data array: chans X samps X epochs
    Index = 1;
    for i = 1:NumEpochs
        FullEpoch = DataStream(Index:(Index+SampsEpoch-1));
        Data(1,:,i) = FullEpoch(ChanMask);
        Index = Index + SampsEpoch;
    end

    %Set up EEG data structure
    EEG = eeg_emptyset();   %create empty EEG data structure 
    EEG.setname = 'Raw Epoched Data';
    EEG.filename = FileName;
    EEG.filepath = PathName;
    EEG.nbchan = 1;
    EEG.trials = NumEpochs;
    EEG.pnts = SampsChan(ChanFocus);
    EEG.srate = SRate;
    EEG.times = 0 + ((0:(EEG.pnts-1)) * (1000/EEG.srate));
    EEG.xmin = EEG.times(1);
    EEG.xmax = EEG.times(EEG.pnts);
    EEG.data = Data;
    EEG.chanlocs(1).labels = ['Channel' int2str(ChanFocus)];
    EEG.chanlocs(1).refs = '';
    EEG.ref = 'common';
    
    %make event, urevent, and epoch tables
    latency = 1;
    for i=1:NumEpochs
       EEG.event(i).type = Events(i);
       EEG.event(i).latency = latency;
       latency = latency + EEG.pnts;
       EEG.event(i).urevent = i;
       EEG.event(i).epoch = i;
       
       EEG.urevent(i).type = Events(i);
       EEG.urevent(i).latency = latency;  %this info is not available given the data is collected as epoched
       
       EEG.epoch(i).event = i;
       EEG.epoch(i).eventlatency = 0;   %all event codest occur at time 0
       EEG.epoch(i).eventtype = Events(i);
       EEG.epoch(i).urevent = i;
    end
    
    if SaveSet
        OutFileName = [Prefix  FileName(1:(strfind(FileName,'.a2d')-1)) '.set'];
        EEG = pop_saveset(EEG, 'filename', OutFileName, 'filepath', PathName, 'check', 'on', 'savemode', 'onefile'); 
    end
   
end