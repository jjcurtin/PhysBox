%USAGE: [AvgEEG, COM] = pop_CreateAvg(EEG, EventArray, msepoch, accuracy, epochs, urevents, label, Notes)
%Creates average (AVG) set with epochs that are averages across events in EventArray.   
%Assumes critical event occur at time 0 in epoch. 
%Also creates a field EEG.epoch.eventcount that keeps track of the number
%of trials that contributed to each epoch average
%
%Inputs:
%EEG - a epoched dataset to be averaged
%EventArray- A cell array containing event codes to create average epochs
%
%msepoch:  Use only portion of the epoch for averaging.  [start end]
%          Start and end times are in ms relative to event marker (0 ms)
%
%accuracy:  Include only subset of trials based on accuracy.  Acceptable 
%inputs are 'C' or 'E' or 'A' for Correct, Erorr or All, respectively.  
%All is default
%
%epochs: include subset of epochs in the dataset e.g.,  [1:50] or
%[10:20 50:75].  Default is ALL epochs
%
%urevents:  incluce subset of urevent numbers in the data set.  Similar to
%epochs above to restrict averages to less than all urvents.  Default is
%ALL urevents
%
%label:  makes an event field called 'varlabel' in EEG.event and inserts text into that
%field.  This field is used by other functions for variable naming (i.e.,
%if the averages are correct only, that would be noted in the variable name
%for all conditions)
%
%Notes:  boolean to indicate if notes should be created, Default is true
%
%Outputs:
%EEG- Averaged EEG set.  Contains one epoch for each average
%COM- String to record this processing step
%
% See also: eeglab()
%
% Copyright (C) 2007  John J. Curtin, University of Wisconsin-Madison,
% jjcurtin@wisc.edu

% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%
%Revision History
%03-15-2007 Released version1, JJC v1
%03-15-2007 Fixed COM line to handle array, JJC v2
%03-15-2007 Fixed UREVENT from [] to 0 to avoid error message in check_set, JJC, v3
%03-16-2007 Added button to dialog to list events in dataset, JJC, v4
%04-30-2007 Fixed bug in AllEvents array, JJC v5
%05-01-2007  Added a field to "epoch" to record number of trials for each mean epoch. v6
%05-04-2007  Fixed bug when epoch contains multiple events.  Now uses event rather then epoch field.  v7
%05-04-2007  Fixed bug for when no epochs exist for a specific event type, v8, JJC
%05-08-2007  Fixed bug involving EpochIndices, v9, JJC
%05-10-2007  Added optional parameter msepoch to handle subepoch averages),v10, JJC
%05-10-2007  Added optional parameter accuracy.  V11, JJC
%05-19-2007  Added optional parameter epochs and fixed epoch referencing. v12, JJC
%05-20-2007  Added optional parameters urevent, label and fixed accuracy bug, v13, JJC
%05-20-2007  Fixed event and epoch handling to accomdodate use of pop_mergeset, v14, JJC
%06-01-2007  Updated code to use FindEvent0Index function. Will now use
%event field for all info about events that occur in an epoch, v15, JJC
%08-11-2007  Updated GUI input both to include all optional parameters, v16
%05-12-2008:  Fixed MAJOR bug with selecting epochs., v17, JJC
%2011-10-18: fixed error in line "EEG = notes_CreateAvg(EEG)". Replaced EEG with EEG, abs



function [AvgEEG, COM] = pop_CreateAvg(EEG, EventArray, msepoch, accuracy, epochs, urevents, label, Notes)
fprintf('\npop_CreateAvg(): Creating Average Data Set\n');
COM = '[EEG, COM] = pop_CreateAvg(EEG)'; 

if isempty(EEG.data)
    AvgEEG = EEG;
    fprintf(2, '\nWarning:  EEG is emptyset in pop_CreateAvg().  No averaging performed.\n');
    return
end

if isempty(EEG.epoch)
    warning('pop_CreateAvg() requires an epoched file.  Converting single trial to epoch format\n');
    EEG = FixSingleEpoch(EEG);  %temp fix for bug in EEGLab with epoched files with one epoch
end

if nargin < 1
    AvgEEG = EEG;
	pophelp('pop_CreateAvg');
	return
end

if nargin < 8
    Notes = true;
end

% pop up window if other parameters not provided
% -------------
if nargin < 7
   
    cbEvent = ['if ~isfield(EEG.event, ''type'')' ...
                   '   errordlg2(''No type field'');' ...
                   'else' ...
                   '   if isnumeric(EEG.event(1).type),' ...
                   '        [tmps,tmpstr] = pop_chansel(unique([ EEG.event.type ]));' ...
                   '   else,' ...
                   '        [tmps,tmpstr] = pop_chansel(unique({ EEG.event.type }));' ...
                   '   end;' ...
                   '   if ~isempty(tmps)' ...
                   '       set(findobj(''parent'', gcbf, ''tag'', ''Events''), ''string'', tmpstr);' ...
                   '   end;' ...
                   'end;' ...
                   'clear tmps tmpv tmpstr tmpfieldnames;' ];                             

    geometry = { [3 1 0.5] [2 1] [2 1] [2 1] [2 1] [2 1]};
    uilist = { { 'style' 'text'      'string' 'Event to include in ave dataset:' } ...
               { 'style' 'edit'       'string' '' 'tag' 'Events' } ...
               { 'style' 'pushbutton' 'string' '...' 'callback' cbEvent } ... 
               { 'style' 'text' 'string' 'Epoch window in ms (Start End)'}...
               { 'style' 'edit'       'string' [num2str(EEG.times(1)) '   ' num2str(EEG.times(end))] 'tag' 'msepoch'  } ...
               { 'style' 'text' 'string' 'Accuracy (C=CORRECT; E=ERROR; A=ALL)'}...
               { 'style' 'edit'       'string' 'A' 'tag' 'Accuracy' } ...
               { 'style' 'text' 'string' 'Epoch #s (Default/Blank = ALL)'}...
               { 'style' 'edit'       'string' '' 'tag' 'Epochs' } ...
               { 'style' 'text' 'string' 'UREvent #s (Default/Blank = ALL)'}...
               { 'style' 'edit'       'string' '' 'tag' 'UREvents' } ...
               { 'style' 'text' 'string' 'Variable label (Default/Blank = none)'}...
               { 'style' 'edit'       'string' '' 'tag' 'VarLabel' }...
               };

    [op ud sh Results] = inputgui( geometry, uilist, 'pophelp(''pop_CreateAvg'')', 'Create Avearge Dataset - pop_CreateAvg()');
    if isempty(Results); 
        AvgEEG = EEG;
        return
    end
    
    EventArray = str2num(Results.Events);    
    msepoch = str2num(Results.msepoch);   
    accuracy = upper(Results.Accuracy);    
    epochs = str2num(Results.Epochs);
    urevents = str2num(Results.UREvents);
    label = Results.VarLabel;
end

if iscell(EventArray)
    EventArray = cell2mat(EventArray);  %Convert to numeric array if provided as cell
end


%Check parameters and set to defaults if dont exist
if isempty(msepoch)
    msepoch =  [EEG.times(1) EEG.times(end)];
end
if isempty(accuracy)
    accuracy = 'A'; 
end

if isempty(label)
    label = '';
end

%verify that msepoch times are appropriate
if (msepoch(1) < EEG.times(1)) || (msepoch(1) > EEG.times(end))
    fprintf(2,'WARNING in pop_CreateAvg: epoch start time of %i is invalid.  Start time set to %i', msepoch(1), EEG.times(1));
    msepoch(1) = EEG.times(1);
end
if (msepoch(2) > EEG.times(end)) || (msepoch(2) < msepoch(1))
    fprintf(2,'WARNING in pop_CreateAvg: epoch end time of %i is invalid.  Start time set to %i', msepoch(2), EEG.times(end));
    msepoch(2) = EEG.times(end);
end

%verify that accuracy parameter is valid and that 'correct' field exists if
%C or E is selected
if strcmp(accuracy, 'C') || strcmp(accuracy, 'E')
    if ~isfield(EEG.event, 'correct'); error('ERROR in pop_CreateAvg:  No correct event field'); end
else
    if ~strcmp(accuracy, 'A'); error('ERROR in pop_CreateAvg: Accuracy parameter must be C, E, or A'); end
end

%Convert msepoch to Pnts
Pnts = [find(EEG.times==msepoch(1))  find(EEG.times==msepoch(2))];
    
%Make DiscardEpochs and set all epochs to be retained  
DiscardEpochs = zeros(length(EEG.epoch),1);

%Discard all epochs that are not in epochs array
if ~isempty(epochs)
    for i =1:length(EEG.epoch)
        if isempty(find(epochs == i,1))
            DiscardEpochs(i) =1;
        end
    end
end

%Discard all epochs that are not in urevents array
if ~isempty(urevents)
    for i =1:length(EEG.epoch)
        if isempty(find(urevents == EEG.event(FindEvent0Index(EEG,i)).urevent,1))  %check if urevent number for 0ms event in this epoch should be included
            DiscardEpochs(i) =1;
        end
    end
end

%Discard epoch if doesnt match correct/error criteria
switch accuracy
    case 'C'
    for i = 1:length(EEG.epoch)    
        
        if EEG.event(FindEvent0Index(EEG, i)).correct == 0   %find the event number of the 0ms event in this epoch and use that event number to find accurracy in event field
            DiscardEpochs(i) = 1;
        end
    end
    case 'E'
    for i = 1:length(EEG.epoch)      
        
        if EEG.event(FindEvent0Index(EEG, i)).correct == 1   %find the event number of the 0ms event in this epoch and use that event number to find accurracy in event field
            DiscardEpochs(i) = 1;
        end
    end
end



%Will make array Allevents that will have EPOCHS entries.  It will include
%eventtype for the event at time 0 for each epoch (i.e., it will not
%include events that occur at times other than 0 in each epoch)
AllEvents = zeros(length(EEG.epoch),1);  %Pre-allocate array for all events at time zero in epochs
for i = 1:length(EEG.epoch);  %insert event codes
    
    if isnumeric(EEG.event(FindEvent0Index(EEG, i)).type)
        AllEvents(i) = EEG.event(FindEvent0Index(EEG, i)).type;
    else
        AllEvents(i) = str2double(EEG.event(FindEvent0Index(EEG, i)).type);
    end
end


%Set eventtype to NAN to remove from average if it is a discarded trial
AllEvents(logical(DiscardEpochs)) = NaN;
            
AveData = NaN(EEG.nbchan, (Pnts(2) - Pnts(1) + 1), length(EventArray));  %pre-allocate array for average epochs: Chans by points X events




EventCount(1:length(EventArray)) = 0; %initial array to count the number of trials for each event type
for i = 1:length(EventArray)
    if ~isempty (find(AllEvents==EventArray(i),1))  %Check that event type exists in dataset        
        %This was old code with error
        %EpochIndices = [EEG.event(find(AllEvents==EventArray(i))).epoch]  %Make an array with epoch indices for each event code
        EpochIndices = find(AllEvents==EventArray(i));
        EventCount(i) = length(EpochIndices);  %Determine number of epochs for that event type
        AveData(:,:,i) = mean(EEG.data(:,Pnts(1):Pnts(2),EpochIndices),3);  %average all epochs of this event code and put in page/epoch i
    else
        EventCount(i) = 0;
        AveData(:,Pnts(1):Pnts(2),i) = NaN;   %may not be necessary
        fprintf('WARNING:  No epochs detected for event type: %i\n', EventArray(i));
    end
end

%create new EEG file
AvgEEG = eeg_emptyset;
AvgEEG.subject = EEG.subject;
AvgEEG.nbchan = EEG.nbchan;
AvgEEG.trials = length(EventArray);   %number of trials = number of event types
AvgEEG.data = AveData;     %put in new averaged data
AvgEEG.pnts = Pnts(2) - Pnts(1) + 1;
AvgEEG.times = EEG.times(Pnts(1)):(1000/EEG.srate):EEG.times(Pnts(2));
AvgEEG.xmin = EEG.times(1) / 1000;
AvgEEG.xmax = EEG.times(end) / 1000;
AvgEEG.chanlocs = EEG.chanlocs;
AvgEEG.srate = EEG.srate;
AvgEEG.urevent = EEG.urevent;
AvgEEG.history = EEG.history;
if isfield(EEG, 'scores')
    AvgEEG.scores = EEG.scores;
end

if isfield(EEG, 'notes')
    AvgEEG.notes = EEG.notes;
end

AvgEEG.epoch = [];   %epoch and event fields need to be adjusted to reflect the new (reduced) set of events)
AvgEEG.event = [];
ZeroPt = find(AvgEEG.times ==0);  % find the sample number of the zero time point for the first epoch
for i= 1:length(EventArray);
    AvgEEG.epoch(i).event = i;   %Number the event sequentially
    AvgEEG.epoch(i).eventlatency = 0;  %For now, all events are assumed to be at time 0 of epoch
    AvgEEG.epoch(i).eventtype = EventArray(i); %insert the event code
    AvgEEG.epoch(i).eventurevent = 0;   %Events are now averages rather than single events.  This field is no longer really meaningful.
    AvgEEG.epoch(i).eventcount = EventCount(i);  %makes new field for epoch to store number of trials in each of the epoch averages.

    AvgEEG.event(i).type = EventArray(i);  %insert the event code
    AvgEEG.event(i).latency = ZeroPt;  %event codes are assumed to be at zero point in each epoch.  This keeps track of sample number of zero point for each epoch
    ZeroPt = ZeroPt + AvgEEG.pnts;  %  adjust to zero point of next epoch
    AvgEEG.event(i).urevent = 0;  %Events are now averages rather than single events.  This field is no longer really meaningful.
    AvgEEG.event(i).epoch = i;    
    switch lower(accuracy)
        case 'correct'
            AvgEEG.event(i).correct = 1;
        case 'error'
            AvgEEG.event(i).correct = 0;
    end
    AvgEEG.event(i).count = EventCount(i);  %makes new field for event to store number of trials of this type of event (same as EEG.epoch.eventcount)
    AvgEEG.event(i).varlabel = label;  %adds a label field that is used for variable naming of the average events for export, display, etc
end

AvgEEG.setname = 'AVG Set';

if Notes
    AvgEEG = notes_CreateAvg(AvgEEG);  %Add notes about averages. 
end
    
%Return the string command for record of processing
%COM = sprintf('EEG = pop_CreateAvg(EEG, [%s], [%s], ''%s'', [%s], [%s], ''%s'', ''%s'' %s} );', int2str(EventArray), int2str(msepoch), accuracy, int2str(epochs), int2str(urevents), label, prefix, int2str([figchans{:}]) );
COM = sprintf('EEG = pop_CreateAvg(EEG)');

return