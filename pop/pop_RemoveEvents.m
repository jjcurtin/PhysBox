%USAGE:   [EEG, COM] = pop_RemoveEvents(EEG, Window, FocalEvents, RejectEvents, Direction)
%Removes events if another event occurs within a given time window before/after it.
%
%Inputs:
%EEG - a EEG structure (can be CNT or SET format). Parameter is required.
%Window - Time window (in ms) before/after focal event to look for
%         other (reject) events. Parameter is required.
%FocalEvents - Events that will be removed if another event occurs within a
%              time Window of this event. Default is all events.  Can be cell or  numeric
%              array
%RejectEvents - Focal event will be removed only if this RejectEvents is
%               found within the time Window. Default is all events.  Can be cell or
%               numeric array
%Direction - Direction of time Window to look for events that are either
%            before (backward), after (forward), or both before and after (both) Focal
%            event. Default is backward.
%
%Outputs:
%EEG- EEG set with event codes removed
%COM- String to record this processing step
%
% John J. Curtin & Jesse T. Kaye, University of Wisconsin-Madison,
% jjcurtin@wisc.edu



function [EEG, COM] = pop_RemoveEvents(EEG, Window, FocalEvents, RejectEvents, Direction)

    COM = 'EEG = pop_RemoveEvents(EEG)';

    if nargin < 1
        pophelp('pop_RemoveEvents');
        return
    end

    % pop-up GUI
    if nargin < 2
        geometry = { [4 2] [4 2] [4 2] [4 2]};
        uilist = { { 'style' 'text'      'string' 'Window (ms):' } ...
            { 'style' 'edit'       'string' '' 'tag' 'Window' } ...
            { 'style' 'text' 'string' 'Focal Events:'}...
            { 'style' 'edit'       'string' '' } ...
            { 'style' 'text' 'string' 'Reject Events:'}...
            { 'style' 'edit'       'string' '' } ...
            { 'style' 'text' 'string' 'Direction (forward, backward, both)'}...
            { 'style' 'edit'       'string' 'backward' }   };

        result = inputgui( geometry, uilist, 'pophelp(''pop_RemoveEvents'')', 'Remove Events - pop_RemoveEvents()');
        if isempty(result); return; end

        Window = str2double(result(1));
        FocalEvents = parsetxt(result{2});
        RejectEvents = parsetxt(result{3});
        Direction = result{4};
    end

    if iscell(FocalEvents)
        FocalEvents = cell2mat(FocalEvents);
    end
    if iscell(RejectEvents)
        RejectEvents = cell2mat(RejectEvents);
    end

    if isempty(FocalEvents)
        FocalEvents = unique([EEG.event.type]);
    end

    if isempty(RejectEvents)
        RejectEvents = unique([EEG.event.type]);
    end

    if isempty(Direction)
        Direction = 'backward';
    end

    fprintf('pop_RemoveEvents(): %s removal of events\n', Direction);

    SampWin = Window/1000 * EEG.srate; % Convert time window from seconds to samples

    RejIndices = []; % create array to track event numbers to reject
    j=1;

    %RejIndices = zeros(1,length(EEG.event)); % do not need anymore
    for i = 1:length(EEG.event)
        if any(FocalEvents == EEG.event(i).type) % Evaluate event only if it is a Focal Event

            EvtPos = 1; % Event Position to track multiple events before or after Focal Event
            if strcmpi(Direction,'backward') || strcmpi(Direction, 'both') % If Direction is backward or both
                while (i-EvtPos) > 0 && (EEG.event(i).latency - EEG.event(i-EvtPos).latency < SampWin) % While it is not the first event and there are events within the time Window
                    if any(RejectEvents ==EEG.event(i-EvtPos).type) % If the event within the time Window is a Reject Event
                        RejIndices(j) = i; % Add trial number (i) to RejIndices array to reject that trial
                        j = j+1;
                    end
                    EvtPos = EvtPos+1;
                end
            end

            EvtPos = 1; % Event Position to track multiple events before or after Focal Event
            if strcmpi(Direction,'forward') || strcmpi(Direction, 'both') % If Direction is forward or both
                while (i+EvtPos) > 0 && (EEG.event(i).latency - EEG.event(i+EvtPos).latency > SampWin) % While it is not the first event and there are events within the time Window
                    if any(RejectEvents ==EEG.event(i+EvtPos).type) % If the event within the time Window is a Reject Event
                        RejIndices(j) = i; % Add trial number (i) to RejIndices array to reject that trial
                        j = j+1;
                    end
                    EvtPos = EvtPos+1;
                end
            end
            
        end
    end

    EEG.event(RejIndices) = [];

    %Return the string command for record of processing
    COM = sprintf('EEG = pop_RemoveEvents(EEG, %d, {%s}, {%s}, %s)', Window, int2str(FocalEvents), int2str(RejectEvents), Direction);

end
