%USAGE: [ EEG, COM ] = pop_AverageWaveform( EEG, InEvents, OutEvents, Missing )
%Creates new epoch(s) with average of epochs of type InEVents.  Assigns
%OutEvent(s) as the event type(s) of these new waveform(s).
% 
%INPUTS
%EEG:  An average (AVG) EEG set file
%InEvents:  A cell array that contains numeric arrays.  Each numeric array
%     in this cell array will include all events to include in the new average
%     waveform.  This allows for creation of multiple average waveforms with
%     only one call to this fucntion
%OutEvents: A cell array with numeric event codes.  one event code for each
%     new average waveform to be created
%Missing:  either 'includenan' (default) or 'omitnan'   See help mean.  GUI only
%     provides default option
%
%OUTPUTS
%EEG:  Updated EEG including average waveforms,
%COM:  COM for record of processing

%Revsion History

function [ EEG, COM ] = pop_AverageWaveform( EEG, InEvents, OutEvents, Missing )
    COM = '[ EEG, COM ] = pop_AverageWaveform( EEG )';
    
    if nargin < 1
        pophelp('popAverageWaveform');
        return
    end
    
    if nargin< 4 %Set Missing to 'includenan'
        Missing = 'includenan';
    end
    
    if nargin < 3
        geoh = {[2 2] [2 2]};
                                   
        ui = {...
        { 'style', 'text', 'string', 'Arrays of Events to Average:'}...
        { 'style', 'edit', 'string', '{ [ ] [ ] }', 'tag', 'InEvents'  } ... 
        { 'style', 'text', 'string', 'Event Codes of Average Waveforms:' } ...
        { 'style', 'edit', 'string', '{ 1001  1002 }', 'tag', 'OutEvents'  } ...  
        };

        [a b c Results] = inputgui('geometry', geoh,  'uilist', ui, 'title', 'pop_AverageWaveform() parameters');
         if isempty(Results); return; end
                
        InEvents = eval(Results.InEvents);        
        OutEvents = eval(Results.OutEvents);          
    end
    
    fprintf('\npop_AverageWaveform(): Calculating average waveform across specified event types\n');
        
    if ~isempty(EEG.data)
        for i = 1:length(InEvents)
            fprintf('Average wave(new event = %d) calculated from mean of events %s\n', OutEvents{i}, num2str(InEvents{i}));

            nTrials = size(EEG.epoch,2);
            nEvents = size(EEG.event,2);

            Event0s = GetTime0Events(EEG);
            EpochIndices = ismember(Event0s, InEvents{i});        
            EEG.data(:,:,size(EEG.data,3)+1) = mean(EEG.data(:,:,EpochIndices),3, Missing);

            %update Epoch field
            EEG.trials = nTrials + 1;
            EEG.epoch(nTrials+1).event = nEvents+1;
            EEG.epoch(nTrials+1).eventlatency = 0;
            EEG.epoch(nTrials+1).eventtype = OutEvents{i};
            EEG.epoch(nTrials+1).eventurevent = 0;
            EEG.epoch(nTrials+1).eventcount = 0;        

            %update event field
            EEG.event(nEvents+1).type = OutEvents{i};
            [PreviousEvent0 PreviousIndex0] = FindEvent0(EEG,nTrials);
            EEG.event(nEvents).latency = EEG.event(PreviousIndex0).latency + EEG.pnts;
            EEG.event(EEG.trials).urevent = 0;
            EEG.event(EEG.trials).epoch = nTrials+1;
            EEG.event(EEG.trials).count = 0;
            EEG.event(EEG.trials).varlabel = ['Mean wave for events: ' num2str(InEvents{i})];

        end
    else
        fprintf(2,'\nWarning: EEG is emptyset in pop_AverageWaveform\n');
        return
    end

%     InEventsStr = '{';
%     OutEventsStr = '{';
%     for i=1:length(InEvents)
%         InEventsStr = [InEventsStr '[' num2str(InEvents{i}) '] '];
%         OutEventsStr = [OutEventsStr num2str(OutEvents{i}) ' '];
%     end
%     InEventsStr = [InEventsStr '}'];
%     OutEventsStr = [OutEventsStr '}'];
%     COM = sprintf('EEG = pop_AverageWaveform(EEG, %s, %s);', InEventsStr, OutEventsStr);
    COM = 'EEG = pop_AverageWaveform(EEG)';
end

