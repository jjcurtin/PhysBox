%USAGE:   [EEG, COM] = pop_ResponseEvents(EEG, Offset).  
%Adds event codes for response locked averaging for events that have Response (RT) or Accuracy (Correct) 
%information in event table.  New response event codes are = to stim code + offset.  
%Response events not added for stimulus events that did not require a
%response (e.g., startle probes) or for which no response was made (i.e., NR=1)
%
%Inputs:
%EEG - a epoched dataset to be averaged
%Offset:  This value is added to stimulus event codes to determine new event code
%that indicates response event to that stimulus
%
%Outputs:
%EEG- Averaged EEG set.  Contains one epoch for each average
%COM- String to record this processing step
%
% See also: eeglab(), eegplugin_PhysBox()

%Revision History
%11-08-2008 Released version1, JJC v1
%11-09-2008:  Fixed input dialog box and added check for RT field, JJC
%2011-10-05:  removed Selected events array



function [EEG, COM] = pop_ResponseEvents(EEG, Offset)
    fprintf('\npop_ResponseEvents(): Adding response locked event codes\n');
    
    COM = '[EEG, COM] = pop_ResponseEvents(EEG);'; % this initialization ensure that the function will return something
              % if the user press the cancel button            
    if ~isempty(EEG.epoch)
        error('pop_ResponseEvents() only works on continuous files.\n');
    end
    if ~ isfield(EEG.event, 'rt')
        error('pop_ResponseEvents(): Event table does not contain ''rt'' field.');
    end

    if ~ isfield(EEG.event, 'nr')
        error('pop_ResponseEvents(): Event table does not contain ''nr'' field.');
    end

    % display help if EEG not provided
    % ------------------------------------
    if nargin < 1
        pophelp('pop_ResponseEvents')
        return
    end

    % pop up window if other parameters not provided
    % -------------
    if nargin < 2  %calls dialog box if less than 6 arguments are provided to function
        geometry = { [1 .5]};
        uilist = { ...
                   { 'style' 'text'       'string' 'Response Event Type Offest:'          } ...
                   { 'style' 'edit'       'string' '1000'                'tag' 'Offset'   } ...
                 };

        [op ud sh Results] = inputgui( geometry, uilist, 'pophelp(''pop_ResponseEvents'')', 'Add Response Events - pop_ResponseEvents()');
        if isempty(Results); return; end  

        Offset = str2double(Results.Offset);
    end     

    for i =1:size(EEG.event,2)
        if (~isempty(EEG.event(i).rt)  && EEG.event(i).nr ==0)  %Event has RT data and its not a NR trial
            EEG.event(size(EEG.event,2)+1).type = EEG.event(i).type + Offset;  %Add event at end of table.  Will be moved by CheckSet()
            EEG.event(size(EEG.event,2)).latency = EEG.event(i).latency + EEG.event(i).rt;
            EEG.event(size(EEG.event,2)).rt = EEG.event(i).rt;
            EEG.event(size(EEG.event,2)).correct = EEG.event(i).correct;
            EEG.event(size(EEG.event,2)).nr = EEG.event(i).nr;
            EEG.event(size(EEG.event,2)).urevent = 0;
        end
    end

    EEG = eeg_checkset( EEG );  %Will rebuild the epoch table

    %Return the string command for record of processing
    COM = sprintf('EEG = pop_ResponseEvents(EEG, %d);', Offset);
return