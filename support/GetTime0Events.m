function [ EventArray ] = GetTime0Events( EEG )
%USAGE: [ EventArray ] = GetTime0Events( EEG )
%Returns a numeric array of all event types at time0 across all epochs.
%
%INPUTS
%EEG: an epoched EEG struture
%
%OUTPUTS
%A numeric array with event types
%
%see also eegplugin_PhysBox(), eeglab()
%
%Author: John Curtin (jjcurtin@wisc.edu)

%Revision history
%2011-09-30:  released, JJC

    EventArray = zeros(EEG.trials,1);  
    for i = 1:EEG.trials
        Event = FindEvent0(EEG, i);
        if ischar(Event)
            EventArray(i) = str2double(Event);
        else
            EventArray(i) = Event;
        end
    end

end

