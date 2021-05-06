%USAGE: [ EEG COM ] = pop_DeleteEpochs( EEG, Method, Events, Indices)
%For 'EVENTS' method, deletes epochs that contain event types listed in cell array Events.
%For 'INDICES' method, deletes epoch numbers listed in cell array Indices
%
%INPUTS
%EEG: An epoched (EPH) EEG set
%Method: string (EVENTS or INDICES) to indicate how to identify epochs to
%        delete
%Events:  Required cell array if Method = EVENTS.  Will delete epoch if these events
%         are anywhere in a specific epoch (not only time0).  [] if not using
%         this method
%Indices: Required cell array if Method = INDICES.  Will delete epochs with these
%         indices
%
%OUTPUTS
%EEG:  Updated EEG set
%COM: COM for recording processing step

%Revision history
%2012-02-15:  update help, added COM at start



function [ EEG COM ] = pop_DeleteEpochs( EEG, Method, Events, Indices)
    COM = '[EEG COM] = pop_DeleteEpochs(EEG);';

    if nargin < 1
        pophelp('pop_DeleteEpochs');
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

        geometry = { [1 1 .5] [1 1 .5] [1 1 .5]};
        uilist = { ...
                   { 'style' 'text'       'string' 'Method(Events or Indices):'          } ...
                   { 'style' 'edit'       'string' ''                'tag' 'Method'      } ...
                   {  }...
                   ...
                   { 'style' 'text'       'string' 'Events (Blank = ignore)'             } ... 
                   { 'style' 'edit'       'string' ''           'tag' 'Events'   } ...           
                   { 'style' 'pushbutton' 'string' ''     'callback' cbEvents    } ... 
                   ...
                   { 'style' 'text'       'string' 'Indices (Blank = ignore)'             } ... 
                   { 'style' 'edit'       'string' ''           'tag' 'Indices'   } ...
                   { }...
                 };

        [op ud sh Results] = inputgui( geometry, uilist, 'pophelp(''pop_DeleteEpochs'')', 'Delete Epochs - pop_DeleteEpochs()');
        if isempty(Results); return; end  

        Method = Results.Method;
        Events = parsetxt(Results.Events);
        for i = 1:length(Events)
            Events{i} = str2double(Events{i});
        end
        Indices = parsetxt(Results.Indices);
    end

    
    switch upper(Method)
        case 'EVENTS'
           if iscell(Events)
                Events = cell2mat(Events);
           end 
           DelIndices = zeros(length(EEG.epoch),1);
           DelCnt = 0;            
           
           for i=1:length(EEG.epoch)
                CurrentEvents = [EEG.epoch(i).eventtype{:}];
                if any(ismember(Events, CurrentEvents))
                    DelCnt = DelCnt + 1;
                    DelIndices(DelCnt) = i;
                end       
            end

            DelIndices = DelIndices(1:DelCnt);  %get rid of remaining zeros
            fprintf('pop_DeleteEpochs(): Deleting %d epochs by %s method\n', DelCnt, Method);
            EEG = pop_select( EEG,'notrial', DelIndices);    
            EEG = notes_DeleteEpochs(EEG, Method, DelCnt);
        
        case 'INDICES'
            if iscell(Indices)
                Indices = cell2mat(Indices);
            end        
            
            fprintf('pop_DeleteEpochs(): Deleting %d epochs by %s method\n', length(Indices), Method);
            EEG = pop_select( EEG,'notrial', Indices);
            EEG = notes_DeleteEpochs(EEG, Method, length(Indices));
    end

    COM = '[EEG COM] = pop_DeleteEpochs(EEG);';
 
end