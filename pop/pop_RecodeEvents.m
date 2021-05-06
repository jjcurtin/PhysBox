%Usage:   [EEG, COM] = pop_RecodeEvents(EEG, OrigEvents, NewEvents).  
%Recodes events in the OrigEvent array to new values provided in the NewEvents array.  
%Arrays must be same length and ordered such that the first Event in OrigEvents
%will be recoded to the first event in NewEvents, and so on....
%
%Inputs:
%EEG - a EEG structure (can be CON or EPH format)
%OrigEvents- A cell array containing event codes to change.
%NewEvents- A cell a'rray containing new event codes to use.  Order must match
%order of OrigEvents in a one to one mapping.
%
%Outputs:
%EEG- EEG set with new event codes
%COM- String to record this processing step
%
% John J. Curtin & Arielle Baskin-Sommers, University of Wisconsin-Madison,
% jjcurtin@wisc.edu
%
%Revision History
%11-21-2008 Released version1, JJC
%2011-10-18:  fixed bug with assignment within epoch table, JJC
%2011-10-29:  fixed another? bug with assignment within epoch table, JJC

function [EEG, COM] = pop_RecodeEvents(EEG,OrigEvents, NewEvents)
    fprintf('\npop_RecodeEvents(): Recoding Events\n');

    COM = '[EEG, COM] = pop_RecodeEvents(EEG)';
    
    % display help if EEG not provided
    % ------------------------------------
    if nargin < 1
        pophelp('pop_RecodeEvents');
        return
    end

    % pop up window if other parameters not provided
    % -------------
    if nargin < 3
        cbEvents = ['if ~isfield(EEG.event, ''type'')' ...
           '   errordlg2(''No type field'');' ...
           'else' ...
           '   tmpevent = EEG.event;' ...
           '   if isnumeric(EEG.event(1).type),' ...
           '        [tmps,tmpstr] = pop_chansel(unique([ tmpevent.type ]));' ...
           '   else,' ...
           '        [tmps,tmpstr] = pop_chansel(unique({ tmpevent.type }));' ...
           '   end;' ...
           '   if ~isempty(tmps)' ...
           '       set(findobj(''parent'', gcbf, ''tag'', ''OrigEvents''), ''string'', tmpstr);' ...
           '   end;' ...
           'end;' ...
           'clear tmps tmpevent tmpv tmpstr tmpfieldnames;' ];

        geometry = {  [1 3 1] [1 3 1]};

        uilist = { ...
             { 'Style', 'text', 'string', 'Original Event Codes (Ordered):' } ...
             { 'Style', 'edit', 'string', '', 'tag', 'OrigEvents' } ...
             { 'style' 'pushbutton' 'string'  '...', 'enable' fastif(isempty(EEG.chanlocs), 'off', 'on') ...
               'callback', cbEvents  } ...
             ...
             { 'Style', 'text', 'string', 'New Event Codes (Ordered):' } ...
             { 'Style', 'edit', 'string', '', 'tag', 'NewEvents' } ...
             { } ...
             };
        [op ud sh Results] = inputgui( geometry, uilist, 'pophelp(''pop_RecodeEvents'');', 'Recode Events -- pop_RecodeEvents()' );
        if isempty(Results); return; end

        OrigEvents = num2cell(str2double(parsetxt(Results.OrigEvents)));
        NewEvents = num2cell(str2double(parsetxt(Results.NewEvents)));
    end
        
    %test that event arrays are same size
    if ~(length(OrigEvents) == length(NewEvents))
        error ('Size of OrigEvents (%d) must equal size of NewEvents (%d) array',length(OrigEvents), length(NewEvents));
    end
    

    %recode event table
    for i = 1:length(EEG.event)

       Index = find([OrigEvents{:}] == EEG.event(i).type);

       if length(Index) > 1
           error('OrigEvents [%s] should have only unique values.', int2str([OrigEvents{:}]));
       end
       if (~isempty(Index))
           EEG.event(i).type = NewEvents{Index};
       end

    end
    
    %recode epoch table if exists
    if  isfield(EEG,'epoch')
        %loop through events within epochs in epoch table and get current/new event type from event table
        for i=1:size(EEG.epoch,2)  
            for j=1:length(EEG.epoch(i).event)
                EEG.epoch(i).eventtype(j) = EEG.event(EEG.epoch(i).event(j)).type;
            end                                     
        end               
    end       
    
   %Return the string command for record of processing
    COM = sprintf('EEG = pop_RecodeEvents(EEG, {%s}, {%s}', int2str([OrigEvents{:}]), int2str([NewEvents{:}]));    
end
