%USAGE: [ EEG  COM ] = pop_ExtractEpochs( EEG, Events, EphWin, Boundary ) 
%Wrapper function to call pop_epochs with Curtin lab function naming
%conventions and a correction to epoch window length
%Assumes epoch includes time 0
%see pop_epoch() for details
%
%INPUTS
%EEG:  A CON EEG set
%Events:  Cell array with numeric events to time lock for extracting epochs
%EphWin:  Cell array with start and end time of Epoch in ms
%Boundary:  Numeric event code for boundary event (typically 0)
%
%OUTPUTS
%EEG: An epoched EEG set
%COM:  COM for recoridng processing

%Revision history
%2012-02-15:  Changed output parameter to EEG, JJC

function [ EEG  COM ] = pop_ExtractEpochs( EEG, Events, EphWin, Boundary )   
    COM = 'pop_ExtractEpochs( EEG )';
    
    if nargin < 1
        pophelp('pop_ExtractEpochs');
        return
    end
    
    if nargin < 4
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
           '       set(findobj(''parent'', gcbf, ''tag'', ''Events''), ''string'', tmpstr);' ...
           '   end;' ...
           'end;' ...
           'clear tmps tmpevent tmpv tmpstr tmpfieldnames;' ];

        geometry = { [2 1 0.5] [2 1 0.5] [2 1.5] [2 1 0.5] };
        uilist = { {'style' 'text'       'string' 'Time-locking event(s):' } ...
                  { 'style' 'edit'       'string' '' 'tag' 'Events' } ...
                  { 'style' 'pushbutton' 'string' '...' 'callback' cbEvents } ...
                  ...
                  { 'style' 'text'       'string' 'Epoch Window [start, end] in ms' } ...
                  { 'style' 'edit'       'string' '-500 1500', 'tag' 'EphWin' } ...
                  { } ...
                  ...
                  { 'style' 'text'       'string' 'Name for the new dataset' } ...
                  { 'style' 'edit'       'string'  fastif(isempty(EEG.setname), '', 'EPH'), 'tag' 'FileLabel' } ...
                  ...
                  { 'style' 'text'       'string' 'Boundary event code' } ...
                  { 'style' 'edit'       'string' '0','tag' 'Boundary' } { } };

        [op ud sh Results] = inputgui( geometry, uilist, 'pophelp(''pop_ExtractEpochs'');', 'Extract Epochs -- pop_ExtractEpochs()' );
        if isempty(Results); return; end

        Events = parsetxt(Results.Events);
        EphWin = parsetxt(Results.EphWin);
        EphWin{1} = str2double(EphWin{1});
        EphWin{2} = str2double(EphWin{2});
        Boundary = str2double(Results.Boundary);
    end
    
    fprintf('\npop_ExtractEpochs(): Extracting epochs...\n');
    
    if iscell(EphWin)
        EphWin = cell2mat(EphWin);
    end

    %Convert EphWin from ms to seconds
    EphWin(1) = EphWin(1) / 1000;
    EphWin(2) = EphWin(2) / 1000;
    
    EphWin(2) = EphWin(2) + 1/EEG.srate;  %add one more sample to window to account for zero  (assumes epochs always include 0)

    
    [EEG Indices COM] = pop_epoch(EEG, Events, EphWin);
        
    %remove boundary events of type = 0.   'Boundary' string events were removed by pop_epoch if they still existed.
    if isnumeric(EEG.event(1).type)  
        Events = [EEG.event.type];
        BEphIndices = [EEG.event(Events == Boundary).epoch];
        if ~isempty(BEphIndices)
            EEG = pop_select(EEG, 'notrial', BEphIndices);  
            fprintf('Removing %d epochs with Boundary (type= %d) events.  %d Epochs remaining\n', length(BEphIndices), Boundary, EEG.trials);
        end
    end   
end

