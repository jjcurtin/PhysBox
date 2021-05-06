%Usage: [EEG] = pop_ConvertEvents(EEG)
%Checks if event table in EEG is numeric or character.  If numeric,
%nothing is done.  However, if the data type is char (as happens when
%boundry events exist), the event.type field is converted to double and
%events of type char are recorded as 0.   Should be performed on CON file.
%NOTE:  All event types (other than boundary) must be numeric.
%MUST OCCUR AFTER RESAMPLING.


%Revision History
%2008-07-14:  released, JJC, v1
%2009-08-29:   discovered bug in script. bug generates error during
%              resampling and is related to treatment of latency of urevent.
%              temporary fix is to run ConvertEvents after resampling, MJS
%2011-09-30:   Added COM as returned parameter, JJC
%2012-02-08:   Added isfield check for urevent before copying, JJC

function [EEG, COM] = pop_ConvertEvents(EEG)
    COM = '[EEG, COM] = pop_ConvertEvents(EEG)';
    
    if nargin < 1
        pophelp('pop_ConvertEvents');
        return
    end
    
    fprintf('pop_ConvertEvents(): Converting event table to integer\n'); 
    if ~isempty(EEG.epoch)  %Check that file is not already epoched
        error('File type must be continuous!')
    end  

    if ~isnumeric(EEG.event(1).type) %test if conversion to double is necessary
        
        %Initialize NewEvent Structure and copy latency and urevent fields
        [NewEvent(1:size(EEG.event,2)).type] = deal(-1);
        [NewEvent(1:size(EEG.event,2)).latency] = deal(EEG.event.latency);
        if isfield(EEG, 'urevent')
            [NewEvent(1:size(EEG.event,2)).urevent] = deal(EEG.event.urevent);
        end
        
        for i = 1:size((EEG.event),2)
            if (isnan(str2double(EEG.event(i).type)))
                NewEvent(i).type = 0;
                fprintf('Converting NON-INTEGER event(%s) to 0\n', EEG.event(i).type);
            else
                NewEvent(i).type = str2double(EEG.event(i).type);
            end
        end
        EEG.event = NewEvent;
    end
    
    COM = 'EEG = pop_ConvertEvents(EEG)';
end
