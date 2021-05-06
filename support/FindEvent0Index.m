function [Event0Index] = FindEvent0Index(EEG, EpochNum)
%Returns the event number for the event at time 0 in epoch
%EpochNum.  This is useful because some epochs may have multiple events.
%However, we are always interested in the event that occurs at time 0.
%This function will allow us to find the right event in the event field to
%find other info about this event (e.g., type, rt, accuracy, etc)
%Inputs
%EEG - an EEG data set
%EpochNum - the index of the epoch in which to find the event at time 0
%Outputs
%Event0Index- The event number from the event field of the event at time 0 in epoch EpochNum

%Revision History
%06-01-2007, released v1.  JJC
%07-24-2007, fixed bug to allow EEG.epoch.eventlatency to be a cell array [i.e., changed () to {}]
%07-26-2007:  Further fix to cell issue.  Now check if cell or not and handle appropriately
    
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
end