%Usage:   [EEG, COM] = pop_AverageMastoid(EEG, M2Chan)
%Re-references CON file from single mastoid to average
%mastoid reference.  Also reduces the output file by one channel (i.e., the
%second mastoid channel is removed)
%
%Inputs:
%EEG - a CNT dataset to be re-references
%
%M2ChanLabel" String value of channel name (preferred) or interger value of the channel containing the other mastoid
%

%Outputs:
%EEG:  Re-referenced EEG set (second mastoid channel is removed from set)
%
%COM: String to record this processing step
%
% See also: eeglab(), pop_select()
%
% Copyright (C) 2006  John J. Curtin, University of Wisconsin-Madison,
% jjcurtin@wisc.edu

%Revision History
%12/06/2006 Released version1, JJC v1
%11-22-2008:  Switched from channel number to channel label, v2, JJC
%01-31-2009:  Fixed warning associated with using a channel number rather than label, v3, JJC
%07-23-2009:  Fixed bug with pop_select parameters, v3, JJC
%2010-01-29:  Fixed bug to remove mastoid channel after re-ref, v5, JJC
%2012-02-15:  updated help and changed input/output parameters to EEG, JJC

function [EEG, COM] = pop_AverageMastoid(EEG,M2ChanLabel)
    fprintf('pop_AverageMastoid(): Re-referencing data set to average mastoid\n');
    COM = '[EEG, COM] = pop_AverageMastoid(EEG)';       

    % display help if EEG not provided
    % ------------------------------------
    if nargin < 1
        pophelp('pop_AverageMastoid');
        return
    end
    
    if EEG.trials > 1
        error('pop_AverageMastoid() does not work on epoched files')
    end

    % pop up window if other parameters not provided
    % -------------
    if nargin < 2
        promptstr    = {'Mastoid Channel Label: '};
        inistr       = {'M2'};
        result       = inputdlg( promptstr, 'Re-Reference Parameters', 1,  inistr);
        if isempty( result ); return; end;
        M2ChanLabel = result{1};
    end

    if ~isnumeric(M2ChanLabel)  %get channel number for label
        M2ChanNum = GetChanNum(EEG,M2ChanLabel);
    else
        M2ChanNum = M2ChanLabel;  % in case old script that provided channel number instead of label
        M2ChanLabel = EEG.chanlocs(M2ChanNum).labels;  %set the M2ChanLabel to string for recording in history
    end

    TotNumChans = size (EEG.chanlocs,2);
    %Check that Channel exists
    if M2ChanNum > TotNumChans
        error('Incorrect channel number selected.  Channel %d outside of valid channel range of 1 - %d.', M2Chan, TotNumChans);
    end

    %Do the re-reference.  NewChannel = OldChannel - .5 * (MastoidChannel)
    MastoidArray = repmat(EEG.data(M2ChanNum,:), TotNumChans,1); %make full array of just mastoid channel repeated by total # channels
    MastoidArray = MastoidArray * 0.5;
    EEG.data = EEG.data - MastoidArray;

    %Delete the mastoid channel from the output data set
    EEG = pop_select(EEG, 'nochannel', {M2ChanLabel});
    
    EEG.ref = 'average mastoid';

    %Return the string command for record of processing
    COM = sprintf('EEG = pop_AverageMastoid(EEG, \''%s\'');', M2ChanLabel);
return
