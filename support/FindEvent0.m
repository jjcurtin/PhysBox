
%USAGE: [Event0Type, Event0Index] = FindEvent0(EEG, EpochNum)
%Returns the event type and event index (from event table) for the event at time 0 in epoch
%EpochNum.  This is useful because some epochs may have multiple events.
%However, we are typically interested in the event that occurs at time 0.
%
%INPUTS
%EEG - an epoched EEG data set
%EpochNum - the index of the epoch in which to find the event at time 0
%
%OUTPUTS
%Event0Type:  The event type for the event at time 0 in EpochNum
%Event0Index- The event number from the event field of the event at time 0 in epoch EpochNum
%
%Author:  John Curtin(jjcurtin@wisc.edu)

%Revision History
%2-11-09-30, released,  JJC
function [Event0Type, Event0Index] = FindEvent0(EEG, EpochNum)
   

    Event0Index = NaN;
    for i=1:length(EEG.epoch(EpochNum).eventlatency)
        if iscell(EEG.epoch(EpochNum).eventlatency)  %check if this is a cell array or normal array
            if (EEG.epoch(EpochNum).eventlatency{i} == 0)  %use {}
                Event0Index = EEG.epoch(EpochNum).event(i);
            end
        else
            if (EEG.epoch(EpochNum).eventlatency(i) == 0)  %use () instead
                Event0Index = EEG.epoch(EpochNum).event(i);
            end
        end
    end
    Event0Type = EEG.event(Event0Index).type;

end