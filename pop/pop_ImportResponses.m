%Usage:   [EEG, COM] = pop_ImportResponses(EEG, TDName)  
%Imports event information from a task data file into a continuous EEG set.  
%Creates rt, correct, and nr fields in event table.
%Task data file should have the following columns/labels
%SubID	TrialNum	EventType	RT	NR	Correct
%RT is in ms
%
%Inputs:
%EEG: a CON SET
%TDName: Path and filename of task data file
%
%Outputs:
%EEG: EEG set with new event fields
%COM: String to record this processing step
%
% See also: eeglab(), eegplugin_PhysBox()

%Revision History
%2011-10-05:    Released, JJC
%2011-10-13:    changed method to load task data to speed processing, JJC

function [EEG, COM] = pop_ImportResponses(EEG, TDName)
    fprintf('pop_ImportResponses(): Importing response data from task data file into event table\n');
    
    COM = 'EEG = pop_ImportResponses(EEG)'; % this initialization ensure that the function will return something
              % if the user press the cancel button                             

    % display help if EEG not provided
    % ------------------------------------
    if nargin < 1
        pophelp('pop_ImportResponses');
        return
    end

    %pop up window if other parameters not provided
    %-------------
    if nargin < 2
         [Filename Pathname] = uigetfile('*.dat', 'Select Task Data File');
        if  isequal(Filename,0) || isequal(Pathname,0)
            return
        end
        TDName = [Pathname Filename];
    end
    
    %TaskData = tdfread(TDName);   %WAY TOO SLOW
    %read task data (much faster)
    d =  importdata(TDName,'\t', 1);
    for i = 1:length(d.colheaders)
        TaskData.(d.colheaders{i}) = d.data(:,i); 
    end
    
    
    %Check that all relevant fields are present
    FN = fieldnames(TaskData);
    if isempty(find(ismember(FN, 'SubID')==1,1))
        error ('SubID field missing from task data file\n');
    end
    if isempty(find(ismember(FN, 'EventType')==1,1))
        error ('EventType field missing from task data file\n');
    end
    if isempty(find(ismember(FN, 'RT')==1,1))
        error ('RT field missing from task data file\n');
    end
    if isempty(find(ismember(FN, 'NR')==1,1))
        error ('NR field missing from task data file\n');
    end
    if isempty(find(ismember(FN, 'Correct')==1,1))
        error ('Correct field missing from task data file\n');
    end
    
    %Determine SubID
    if ischar(EEG.subject)
        SubID = str2double(EEG.subject);
    else
        SubID = EEG.subject;
    end

    %make arrays for this subjects task data
    EventType = TaskData.EventType(TaskData.SubID == SubID);
    RT = TaskData.RT(TaskData.SubID == SubID);
    NR = TaskData.NR(TaskData.SubID == SubID);
    Correct = TaskData.Correct(TaskData.SubID == SubID);

    
    EventList = unique(EventType);  %list of all event codes in TaskData
    nTrials = size(RT,1);

    
    TDCnt = 0;
    MismatchCnt = 0;
    for i=1:size(EEG.event,2)
        if ~isempty(find(EventList == EEG.event(i).type,1))  %this event is in task data
            TDCnt = TDCnt + 1;  %count event
            if TDCnt > nTrials  %check that there is task data remaining
               error('# of Physio Events > # of Task Data Trials\n')
            end

            if EEG.event(i).type == EventType(TDCnt)  %Phys event matches current TD event
                EEG.event(i).rt = RT(TDCnt);
                EEG.event(i).nr = NR(TDCnt);
                EEG.event(i).correct = Correct(TDCnt);

            else  %attempt to adjust for possible missing event codes
                TDCnt = TDCnt + 1;  %check next TD event
                if TDCnt > nTrials || ~(EEG.event(i).type == EventType(TDCnt)) %If no more Task data or event types still dont match
                    error('Events do not match across physiology and task data files\n')
                else
                    MismatchCnt = MismatchCnt + 1;
                    EEG.event(i).rt = RT(TDCnt);
                    EEG.event(i).nr = NR(TDCnt);
                    EEG.event(i).correct = Correct(TDCnt);                               
                end
            end

        else  %no task data for this event
            EEG.event(i).rt = [];
            EEG.event(i).nr = [];
            EEG.event(i).correct = [];                 
        end

    end

    if TDCnt < nTrials  %check that all task data were used
        error('# task data trials (%d) > # physio events (%d)\n', nTrials, TDCnt)
    end

    if MismatchCnt > 0
        fprintf (2,'%d mismatches detected and corrected\n', MismatchCnt);
    end


    %Return the string command for record of processing
    COM = sprintf('EEG = pop_ImportResponses(EEG, ''%s'');', TDName);
 end
