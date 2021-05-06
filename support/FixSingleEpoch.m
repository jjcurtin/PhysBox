function [ EEG ] = FixSingleEpoch( EEG )
%Mades an epoched file with 1 epoch look like an epoched file again
%EEGLAB removes the epoch field and the event.epoch field
%Should only use this function if you are sure the EEG object is epoched.

    if EEG.trials > 1 || ~isempty(EEG.epoch)
        error('FixSingleEpoch() should only be applied to EEG objects with one epoch/trial')
    end

%     %Fix misnumbering of events in Epoch table
%     for i = 1:length(EEG.epoch(1).event)
%         EEG.epoch(1).event(i) = i;
%     end
%     
%     %add times
%      EEG.times = linspace(EEG.xmin*1000, EEG.xmax*1000, EEG.pnts);

    %Add epoch field back to event table and 
    for i = 1:length(EEG.event)
        EEG.event(i).epoch= 1;
    end
    %Rebuild epoch table
    EEG.epoch.event = 1:length(EEG.event);
    EEG.epoch.eventtype = [EEG.event.type];
    EEG.epoch.eventurevent = [EEG.event.urevent];
    
    %fix odd bug with event latency one sample out of range on occassion
    if ~isempty(find([EEG.event.latency] > EEG.pnts, 1))
        warning('Event latency of %d exceeds max value of %d.  Latency adjusted', EEG.event(find([EEG.event.latency] > EEG.pnts)).latency, EEG.pnts);
        EEG.event(find([EEG.event.latency] > EEG.pnts)).latency = EEG.pnts;
    end
    EEG.epoch.eventlatency = EEG.times([EEG.event.latency]);
end

