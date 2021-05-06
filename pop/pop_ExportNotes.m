%USAGE:   [EEG, COM, Success] = pop_ExportScores(EEG, OutFilename, Append)
%pop_pop_ExportNotes() - Exports notes from from reduction (e.g., startle response, ERP)
%that were provided by series of other functions and saved in notes field
%of SET file
%Notes are written to a tab delimited file.  Can be appended to an existing file
%or overwrite/create a new file.  
%Notes should all be single entries (no arrays).  This function will ignore
%multi-row notes fields for export.
%
%Inputs:
%EEG: an epoched EEG structure
%OutFileName: Path and Filename for output file.
%Append:  Append to exisitng file (Y or N).  Default is 'Y'
%
%Outputs:
%EEG:  the EEG structure (no changes but command in history via GUI
%COM: String to record this processing step
%
% See also: eeglab(), eegplugin_PhysLab(), various notes_ functions
%
% Copyright (C) 2011  John J. Curtin, University of Wisconsin-Madison,
% jjcurtin@wisc.edu

%
%Revision History
%2011-09-28: released, JJC
%2011-10-13: added code to remove numeric fields with multiple columns, JJC
%2011-10-16: added code to remove additional field if problematic blink reduction, ABS
%2011-10-18: Cleaned code to remove inappropriate fields, JJC
%2012-02-15:  update help, added COM at start, changed input/output
%             parameters to EEG, JJC

function [EEG, COM] = pop_ExportNotes(EEG, OutFilename, Append)

    COM = '[EEG, COM] = pop_ExportNotes(EEG)';           

    if ~isfield(EEG, 'notes')
        error ('EEG does not have notes field\n')
    end

    % display help if EEG not provided
    % ------------------------------------
    if nargin < 1
        pophelp('pop_ExportNotes');
        return
    end

    % pop up window if other parameters not provided
    % -------------
    if nargin < 3
        [FName PName] = uiputfile('*.dat', 'Save Output File Name as');
        OutFilename = [PName FName];
        promptstr    = {'Append [(Y)es or (N)o]: '};
        inistr       = {'Y'};
        result       = inputdlg( promptstr, 'Export Notes Parameters', 1,  inistr);
        if isempty( result ); return; end;
        Append = result{1};
    end
    Append = upper(Append);
    if ~(strcmp(Append, 'Y') || strcmp(Append, 'N'))
        error ('Append (%s) must be Y or N\n', Append)
    end

    fprintf('pop_ExportNotes(): Exporting notes to %s\n', OutFilename);

    if isfield(EEG,'notes')
        %Make Notes Struct and add SubID field
        Notes = EEG.notes;


        %Remove fields that arent appropriate for export
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


        if ~isempty(EEG.subject)
            Notes.SubID = EEG.subject;
        else
            error ('EEG subject field is empty\n')
        end

        %reorder fields for SubID first
        FinalFields = [{'SubID'}; NotesFields];
        Notes = orderfields(Notes, FinalFields);

        %write Scores to file
        tdfwrite(OutFilename, Notes, Append)
    else
        fprintf('No notes exist for %\n', EEG.subject)
    end    

    %Return the string command for record of processing if desired
    COM = sprintf('[EEG, COM] = pop_ExportNotes(EEG, \''%s\'', \''%s\'');', OutFilename, Append);
end
