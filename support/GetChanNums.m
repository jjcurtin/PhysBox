%USAGE: [ChanNums] = GetChanNums(EEG, Label)
%Returns the integer channel numbers for a cell array of channel labels. 
%
%INPUTS
%InEEG:  EEG data set
%Label: A cell array (1 or 2 dimensional) with srings for each channel label
%
%OUTPUTS
%ChanNums:  a numeric array of channel numbers associated with each label
%
%see also:  GetChanNum(), eegplugin_PhysBox(), eeglab()
%
%Author: John Curtin (jjcurtin@wisc.edu)
%Released: 2011-11-04

function [ ChanNums ] = GetChanNums( EEG, ChanList )

    nChans = prod(size(ChanList));  %to accomodate 2 dimensional lists

    ChanNums = zeros(1,nChans);

    for i = 1:nChans
        ChanNums(i) = find(ismember({EEG.chanlocs.labels}, ChanList{i}));    
    end
end
