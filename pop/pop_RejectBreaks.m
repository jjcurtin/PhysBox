%USAGE: [EEG, COM] = pop_RejectBreaks(EEG, MaxDelay, BufferTime) 
%Rejects long periods without event codes (typically breaks) for situations
%where these breaks may contain a lot of artifact
%
%INPUTS:
%EEG: A continuous EEG dataset
%MaxDelay:  Finds periods greater that MaxDelay (in ms) with no events and deletes these periods
%BufferTime:  preserves this buffer (in ms) at start/end of deleted periods
%
%OUTPUTS:
%EEG- EEG file with break periods removed
%COM- String to record this processing step
%
% John J. Curtin & Arielle Baskin-Sommers, University of Wisconsin-Madison,
% jjcurtin@wisc.edu
%
%Revision History
%11-21-2008 Released version1, JJC v1
%2012-02-03: updated to reflect current approaches and fix bug?, JJC

function [EEG, COM] = pop_RejectBreaks(EEG, MaxDelay, BufferTime)
    
fprintf('pop_RejectBreaks(): Removing break periods from CON file...version1\n');
    COM = '[EEG, COM] = pop_RejectBreaks(EEG)'; 
    

    % display help if EEG not provided
    % ------------------------------------
    if nargin < 1
        pophelp('pop_RejectBreaks');
        return
    end

    if nargin < 3
        geometry = { [1 .5] [1 .5]};
        uilist = { ...
                   { 'style' 'text'       'string' 'Maximum No Event Period (ms)'  } ...
                   { 'style' 'edit'       'string' '10000'     'tag' 'MaxDelay'                } ...            
                   { 'style' 'text'       'string' 'Buffer (ms)'             } ... 
                   { 'style' 'edit'       'string' '2000'    'tag' 'Buffer'             } ...
                 };

        [op ud sh Results] = inputgui( geometry, uilist, 'pophelp(''pop_RejectBreaks'')', 'Reject Break Periods - pop_RejectBreaks()');
        if isempty(Results); return; end  

        MaxDelay = str2double(Results.MaxDelay);
        BufferTime = str2double(Results.Buffer);
    end   
        
    MaxDelaySamp = MaxDelay/1000 * EEG.srate;  %convert to s and then samps
    BufferTimeSamp = BufferTime/1000 * EEG.srate; %convert to s and then samps
    
    %Delete start of file to first event if >MaxDelay
    if EEG.event(1).latency > MaxDelaySamp   %SWITCHED FORM < TO >
        fprintf('Break rejected before first event\n')
        EEG = pop_select(EEG, 'nopoint' ,[1 (EEG.event(1).latency-BufferTimeSamp)]);
        i=2; %start loop below at i=2 to ignore first (boundry) event
    else 
        i=1; %else start loop with first event
    end
    
   
    while i < (length(EEG.event))
        if(EEG.event(i+1).latency - EEG.event(i).latency) > MaxDelaySamp  
            fprintf('Break rejected after event number %d\n', EEG.event(i).urevent)
            EEG = pop_select(EEG, 'nopoint' ,[(EEG.event(i).latency + BufferTimeSamp) (EEG.event(i+1).latency-BufferTimeSamp)]);            
            EEG = Events2Int(EEG);
            i = i+2;
        else
            i=i+1;
        end
        
    end
    
    %Delete end of file if longer than MaxDelay
    if EEG.pnts - EEG.event(i).latency > MaxDelaySamp
        fprintf('Break rejected after last event\n')
        EEG = pop_select(EEG, 'nopoint' ,[(EEG.event(i).latency + BufferTimeSamp) EEG.pnts]);
    end    
    

    %Return the string command for record of processing
    COM = sprintf('EEG = pop_RejectBreak(EEG, [%s], [%s]', int2str(MaxDelay), int2str(BufferTime));
end
