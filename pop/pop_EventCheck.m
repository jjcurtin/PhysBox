%Usage:   [EventCount,TimingArray,S1S2Array,AvePosArray, COM] = pop_EventCheck(InEEG,EventSpaceArray,S1Array,S2Array, CBArray)
%Checks three properties of the event table to confirm
%that stimulus control program is working correctly.
%1.  Makes a table of all events and their frequencies
%2.  Reports time between a subset of events (e.g., startle probe events)
%3.  Reports time between S1 and S2 events (e.g., cue to startle time)
%4.  Reports the averare serial position and event count of the events listed in CBArray.  
%    Useful to verify counterbalancing of events (such as startle probes)
%
%Inputs:
%InEEG - a CNT dataset that contains event table to be checked
%
%EventSpaceArray- Subset of events to check spacing between (e.g., task 2
%above)
%
%S1Array, S2Array- arrays that contain subset of events S1 and S2,
%respectively.
%
%Outputs:
%EventCount- Array with 2 columns, event type and frequency (e.g, Task 1
%above)
%TimingArray- Array with 4 columns, counter, event type, absolute latency
%in cnt file, time between current event and next event (e.g., Task 2)
%
%S1S2Array - Array with 4 columns, counter, S1 event type, S2 event type,
%time between S1 and S2 (i. e. Task 3)
%
%AvePosArray - Array with 3 columns, Eventcode, ave serial position, count. (i.e., Task 4).
%
%
%Revision History
%8/29/2007 Released version1, JJC v1
%11/17/2007, modified to include ave serial position as 4th task, JJC, v2
%08/31/2008, modified to convert event table to integer using Events2Int, JJC, v3
%03/17/2010, modified to fix bug in CBData, JJC, v4
%2012-02-15, removed pop_ConvertEvents, added COM at start, JJC

function [EventCount,TimingArray,S1S2Array,AvePosArray,COM] = pop_EventCheck(InEEG,EventSpaceArray,S1Array,S2Array, CBArray)
COM = '[EventCount,TimingArray,S1S2Array,AvePosArray,COM] = pop_EventCheck(EEG)';

%initialize in case returns early
EventCount = [];
TimingArray = [];
S1S2Array = [];
AvePosArray = [];

fprintf('pop_CheckEvent(): Examining Event Table\n');

% display help if InEEG not provided
% ------------------------------------
if nargin < 1
	pophelp('pop_EventCheck');
	return
end;	

if nargin < 2
   
    ButEventES = ['if ~isfield(EEG.event, ''type'')' ...
                   '   errordlg2(''No type field'');' ...
                   'else' ...
                   '   if isnumeric(EEG.event(1).type),' ...
                   '        [tmps,tmpstr] = pop_chansel(unique([ EEG.event.type ]));' ...
                   '   else,' ...
                   '        [tmps,tmpstr] = pop_chansel(unique({ EEG.event.type }));' ...
                   '   end;' ...
                   '   if ~isempty(tmps)' ...
                   '       set(findobj(''parent'', gcbf, ''tag'', ''ESevents''), ''string'', tmpstr);' ...
                   '   end;' ...
                   'end;' ...
                   'clear tmps tmpv tmpstr tmpfieldnames;' ]; 
               
   ButEventS1 = ['if ~isfield(EEG.event, ''type'')' ...
   '   errordlg2(''No type field'');' ...
   'else' ...
   '   if isnumeric(EEG.event(1).type),' ...
   '        [tmps,tmpstr] = pop_chansel(unique([ EEG.event.type ]));' ...
   '   else,' ...
   '        [tmps,tmpstr] = pop_chansel(unique({ EEG.event.type }));' ...
   '   end;' ...
   '   if ~isempty(tmps)' ...
   '       set(findobj(''parent'', gcbf, ''tag'', ''S1events''), ''string'', tmpstr);' ...
   '   end;' ...
   'end;' ...
   'clear tmps tmpv tmpstr tmpfieldnames;' ]; 

   ButEventS2 = ['if ~isfield(EEG.event, ''type'')' ...
   '   errordlg2(''No type field'');' ...
   'else' ...
   '   if isnumeric(EEG.event(1).type),' ...
   '        [tmps,tmpstr] = pop_chansel(unique([ EEG.event.type ]));' ...
   '   else,' ...
   '        [tmps,tmpstr] = pop_chansel(unique({ EEG.event.type }));' ...
   '   end;' ...
   '   if ~isempty(tmps)' ...
   '       set(findobj(''parent'', gcbf, ''tag'', ''S2events''), ''string'', tmpstr);' ...
   '   end;' ...
   'end;' ...
   'clear tmps tmpv tmpstr tmpfieldnames;' ]; 

   ButEventCB = ['if ~isfield(EEG.event, ''type'')' ...
   '   errordlg2(''No type field'');' ...
   'else' ...
   '   if isnumeric(EEG.event(1).type),' ...
   '        [tmps,tmpstr] = pop_chansel(unique([ EEG.event.type ]));' ...
   '   else,' ...
   '        [tmps,tmpstr] = pop_chansel(unique({ EEG.event.type }));' ...
   '   end;' ...
   '   if ~isempty(tmps)' ...
   '       set(findobj(''parent'', gcbf, ''tag'', ''CBevents''), ''string'', tmpstr);' ...
   '   end;' ...
   'end;' ...
   'clear tmps tmpv tmpstr tmpfieldnames;' ]; 

    geometry = { [3 1 0.5] [1] [1] [3 1 0.5] [3 1 0.5] [3 1 0.5]};
    uilist = { { 'style' 'text'      'string' 'Check overall spacing for events:' } ...
               { 'style' 'edit'       'string' '' 'tag' 'ESevents' } ...
               { 'style' 'pushbutton' 'string' '...' 'callback' ButEventES }... 
               { 'style' 'text'      'string' '' }...   
               { 'style' 'text'      'string' 'Check S1-S2 spacing for events...' }...             
               { 'style' 'text'      'string' 'S1:' } ...
               { 'style' 'edit'       'string' '' 'tag' 'S1events' } ...
               { 'style' 'pushbutton' 'string' '...' 'callback' ButEventS1 }...
               { 'style' 'text'      'string' 'S2:' } ...
               { 'style' 'edit'       'string' '' 'tag' 'S2events' } ...
               { 'style' 'pushbutton' 'string' '...' 'callback' ButEventS2 }...
               { 'style' 'text'      'string' 'Check ave serial position for events:' } ...
               { 'style' 'edit'       'string' '' 'tag' 'CBevents' } ...
               { 'style' 'pushbutton' 'string' '...' 'callback' ButEventCB }};

    result = inputgui( geometry, uilist, 'pophelp(''pop_EventCheck'')', 'Check Event Table Structure - pop_EventCheck()');
    if isempty(result); return; end
    
    EventSpaceArray = str2num(result{1});
    S1Array = str2num(result{2});
    S2Array = str2num(result{3});
    CBArray = str2num(result{4});
end


%Create array containing event type and latency in milliseconds
 data = zeros(length(InEEG.event),2);
% for i = 1:length(InEEG.event)
%     data(i,1)=InEEG.event(i).type;   %col 1 contains event codes
%     data(i,2)=InEEG.event(i).latency; 
%     data(i,2)=(data(i, 2)/InEEG.srate)*1000;  %col 2 containns latency in ms
% end
% data = sort(data,2,'ascend'); %Sort the data by ascending latency

data(:,1) = [InEEG.event.type];
data(:,2) = [InEEG.event.latency];
data(:,2)=(data(:, 2)/InEEG.srate)*1000; %col 2 containns latency in ms

%NOTE:  REMOVED SORTING B/C NOT NEEDED? AND POSSIBLE MATLAB BUG?
%data = sort(data,2,'ascend'); %Sort the data by ascending latency

%Routine to count occurences of unique event types (task 1).  This is
%always performed and requires no input array
% sortlist = data(:,1);
% sortlist = sort(sortlist);
% EventCount(1,1) = sortlist(1);
% EventCount(1,2) = 1;
% r = 1;
% for i = 2:length(sortlist)
%     if sortlist(i) == sortlist(i-1)   
%         EventCount(r,2) = EventCount(r,2)+1;
%     else
%         r = r+1;
%         EventCount(r,1) = sortlist(i);
%         EventCount(r,2) = 1;
%     end
%     
%     
% end

EventCount = unique(data(:,1));
EventCount(:,2) = 0;
for i = 1:length(data(:,1))
    rowindex = find(EventCount(:,1)==data(i,1));
    EventCount(rowindex,2) = EventCount(rowindex,2) + 1;
end

EventCount  %Output to screen

%Routine to check timing between events in EventSpaceArray
if ~isempty(EventSpaceArray)  %if no EventSpaceArray, skip this task
    d = 1; %Loop to find first relevant event in data array
    while isempty(find(data(d,1) == EventSpaceArray,1)) && d<=length(data)
        d = d+1;
    end

    if d<=length(data) %Put first relevant event as first row
        r = 1;
        TimingArray(r,1) =1;
        TimingArray(r,2:3) =data(d,1:2);

        for i = (d+1):length(data) %Find all other relevant events
            if ~isempty(find(data(i,1) == EventSpaceArray,1));
                r = r +1;
                TimingArray(r,1) =r;
                TimingArray(r,2:3) =data(i,1:2);
                TimingArray(r-1,4) = TimingArray(r,3)-TimingArray(r-1,3); %Subtraction to find timing btw events
            end
        end
    else
        error('pop_EventCheck:NoEventMatch','Events (%d) do not occur within event table',EventSpaceArray)
    end
    
    TimingArray %Output to screen
end


%Routine to calulate S1 - S2 spacing
if ~isempty(S1Array)  %if no S1Array, skip this task
    r = 1;
    d = 1; %Loop to find first relevant event in data array
    S1S2Array = [];
    while d<length(data)  
        if ~isempty(find(data(d,1) == S1Array,1))
            S1Pos = d;  %found an S1
            d=d+1;

            %now look for an S2 (ideally) or another S1 or no more data
            while isempty(find(data(d,1) == S1Array,1)) && isempty(find(data(d,1) == S2Array,1)) && d<length(data)
                d= d+1;
            end
            %found an S2
            if ~isempty(find(data(d,1) == S2Array,1));
                S1S2Array(r,1) = r;
                S1S2Array(r,2) = data(S1Pos,1);
                S1S2Array(r,3) = data(d,1);
                S1S2Array(r,4) = data(d,2)-data(S1Pos,2);
                r = r+1;
            end
        else
            d=d+1;
        end
    end
    
    S1S2Array  %output to screen
end

%Routine to calcuate ave serial position and counts of event types
if ~isempty(CBArray)  %if no CBArray, skip this task
    %AvePosArray = zeros(length(CBArray),3);  %allocate array

   %make array of event data with just CB Events
    r=1;
    for i = 1:size(data)
        if ~isempty(find(CBArray == data(i,1),1))
            CBData(r,1) = data(i,1);
            r= r+1;
        end
    end
    CBData    
     %calculate AvePosArray columns 1 and 2
    AvePosArray = unique(CBData);
    AvePosArray(:,2:3) = 0;
    for i = 1:size(AvePosArray,1)
          AvePosArray(i,2) = length(find(CBData == AvePosArray(i,1)));
          AvePosArray(i,3) = mean(find(CBData == AvePosArray(i,1)));
        
%         if isempty(find(AvePosArray == CBData(i),1)) %if current event in sort list is not already in the AvePosArray, add it and count it
%             AvePosArray(r,1) = CBData(i);
%             AvePosArray(r,2) = 1;  %there is now one event of this type
%             r=r+1;
%         else  %if already was there, find its row in AvePosArray and then increment its count
%             [therow,c] = find(AvePosArray == CBData(i),1);
%             AvePosArray(therow,2) = AvePosArray(therow,2) + 1;
%         end
    end
    
    
    %calculate AvePosArray col 3 (serial position)
    for i = 1:size(AvePosArray,1)
        AvePosArray(i,3) = mean(find(CBData == AvePosArray(i,1)));
    end
    
    AvePosArray  %output to screen
end

    
%Return the string command for record of processing
COM = sprintf('pop_EventCheck(EEG, [%s], [%s], [%s], [%s] )', num2str(EventSpaceArray), num2str(S1Array), num2str(S2Array), num2str(CBArray));

return
