%USAGE: [ P, COM] = pop_AppendNotes(P, EEG)
%Appends notes from notes field of EEG to Parameter file (P).   
%IMPORTANT: This pop_ function does NOT save Parameter file to disk.  
%When using pop_ function directly, call
%pop_SaveParameters() after all notes for all subjects have been added to P.  
%When pop_AppendNotes() is called via multiset
%proccesing (pop_ProcessSet or pop_MultiSet), Parameter file is saved at end automatically
%
%INPUTS
%EEG:  An EEG set file
%P:  A Parameter file
%
%OUTPUTS
%P:  updated parameter file
%COM:  command


%Revision history
%2012-02-03:  released, JJC

function [ P, COM] = pop_AppendNotes(P, EEG)
    COM = '[ P, COM ] = pop_AppendNotes(P)';

    if nargin < 1
        pophelp('pop_AppendNotes');
        return
    end

    if nargin < 2
        geometry = { [1 .5] [1 .5]};
        uilist = { ...
                   { 'style' 'text'       'string' 'Parameter file variable name:'  } ...
                   { 'style' 'edit'       'string' 'P'     'tag' 'P'                } ...            
                   { 'style' 'text'       'string' 'EEG variable name:'             } ... 
                   { 'style' 'edit'       'string' 'EEG'    'tag' 'EEG'             } ...
                 };

        [op ud sh Results] = inputgui( geometry, uilist, 'pophelp(''pop_AppendNotes'')', 'Append Notes to Parameter File - pop_AppendNotes()');
        if isempty(Results); return; end  

        EEG = eval(Results.EEG);
        P = eval(Results.P);
    end   
    
    fprintf('\npop_AppendNotes():  Appending notes to Parameter file\n');
    
    if isfield(EEG,'notes')
        Index = ms_GetParameterIndex(P, EEG.subject);

        %Make Notes Struct and add SubID field
        Notes = EEG.notes;

        %remove fields that have multiple rows of data
        NotesFields = fieldnames(Notes);
        for j=1:length(NotesFields)
            %remove for multiple rows or empty
            if (size(Notes.(NotesFields{j}),1) > 1) || isempty(Notes.(NotesFields{j}))
                Notes = rmfield(Notes, NotesFields{j}); 
            else    
                %remove for multiple columns but not b/c char data
                if ~ischar(Notes.(NotesFields{j})) && size(Notes.(NotesFields{j}),2)>1  
                    Notes = rmfield(Notes, NotesFields{j});  
                end
            end
        end
        NotesFields = fieldnames(Notes);  %Update for final fields

        for j=1:length(NotesFields)
            %field exists in P and note is numeric
            if isfield(P, NotesFields{j}) && isnumeric(Notes.(NotesFields{j})) 
                P.(NotesFields{j})(Index) = Notes.(NotesFields{j});
            end 

            %field exists in P and note is char
            if isfield(P, NotesFields{j}) && ischar(Notes.(NotesFields{j})) 
                P.(NotesFields{j}) = tdfCharAdjust(P.(NotesFields{j}),Notes.(NotesFields{j}));
                P.(NotesFields{j})(Index,1:length(Notes.(NotesFields{j}))) = Notes.(NotesFields{j});                    
            end      

            %field does not exist in P and note is numeric
            if ~isfield(P, NotesFields{j}) && isnumeric(Notes.(NotesFields{j})) 
                P.(NotesFields{j}) = NaN(size(P.SubID,1),1);  %make field and fill with NaN for numeric data

                P.(NotesFields{j})(Index) = Notes.(NotesFields{j});

            end   

            %field does not exist in P and note is char
            if ~isfield(P, NotesFields{j}) && ischar(Notes.(NotesFields{j})) 
                P.(NotesFields{j}) = repmat('NA',size(P.SubID,1),1);  %make field and fill with NA for char data
                P.(NotesFields{j}) = tdfCharAdjust(P.(NotesFields{j}),Notes.(NotesFields{j}));
                P.(NotesFields{j})(Index,1:length(Notes.(NotesFields{j}))) = Notes.(NotesFields{j});  
            end                   
        end
    else
        fprintf('No notes exist for %\n', EEG.subject)
    end

end

