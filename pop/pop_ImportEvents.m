%USAGE: [ EEG, COM ] = pop_ImportEvents( EEG, EventFileName  )
%Imports event codes from a text file and replaces eventcode types in SET file
%with these new event codes.  Used for SMA files that are collected with same event
%code (1) for each event.

function [ EEG, COM ] = pop_ImportEvents( EEG, EventFileName )
    COM = 'EEG = pop_ImportEvents(EEG)';
    
    if nargin < 1
        pophelp('pop_ImportEvents');
        return
    end
    
    if nargin < 2
        [Filename Pathname] = uigetfile('*.dat', 'Select Event Code File');
        if  isequal(Filename,0) || isequal(Pathname,0)
            return
        end
        EventFileName = fullfile(Pathname,Filename);        
    end


    EventCodes = dlmread(EventFileName);
    
    if size(EventCodes,1) ~= size(EEG.event,2)
        error('Number of events in SET file (%d) does not match number of events in DAT file (%d)\n\n', size(EEG.event,2), size(EventCodes,1))        
    end

    for i = 1:size(EEG.event,2)
        EEG.event(i).type = EventCodes(i,2);    
    end

    COM = sprintf('pop_ImportCodes(EEG, %s);', EventFileName);
end

