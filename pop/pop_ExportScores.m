%USAGE:   [EEG, COM] = pop_ExportScores(EEG, Label, OutFileName, Append)
%Exports scores from epochs (e.g., startle response, P3)
%that were provided by other functions (e.g., pop_ScoreSTL, pop_ScoreWindow).
%Scores are written to a tab delimited file.  Can be appended to an existing file
%or overwrite/create a new file.  
%
%Inputs:
%EEG: an epoched EEG structure
%Label:  field name for the scores to export (e.g., STL, Mean300_600)
%OutFileName: Path/Filename for output file
%Append:  Append to exisitng file (Y or N)
%
%Outputs:
%EEG:  the EEG structure (no changes but command in history via GUI
%COM: String to record this processing step
%Success: Indicates if succeeded or failed
%
% See also: eeglab()
%
% Copyright (C) 2011  John J. Curtin, University of Wisconsin-Madison,
% jjcurtin@wisc.edu

%
%Revision History
%2011-09-28: released, JJC
%2011-12-28:  fixed bug with determining lenght of SubID, JJC
%2012-02-15:  Removed Success, JJC

function [EEG, COM] = pop_ExportScores(EEG, ScoreField, OutPath, Append)

    COM = '[EEG, COM] = pop_ExportScores(EEG)';      

    if ~isfield(EEG, 'scores')
        error ('EEG does not have scores field\n')
    end

    % display help if EEG not provided
    % ------------------------------------
    if nargin < 1
        pophelp('pop_ExportScores');
        return
    end

    % pop up window if other parameters not provided
    % -------------
    if nargin < 4
        cbDir = [' Filepath = uigetdir(''Select Output Path'');'...   
                  'if ~ isequal(Filepath,0)' ...
                  '   set(findobj(''parent'', gcbf, ''tag'', ''OutPath''), ''string'', Filepath);'...
                  'end;'];                   

        cbField = ['if ~isfield(EEG, ''scores'')' ...
                   '   errordlg2(''No scores field'');' ...
                   'else' ...
                   '   [tmps,tmpstr] = pop_chansel(fieldnames(EEG.scores));' ...
                   '   if ~isempty(tmps)' ...
                   '       set(findobj(''parent'', gcbf, ''tag'', ''ScoreField''), ''string'', tmpstr);' ...
                   '   end;' ...
                   'end;' ...
                   'clear tmps tmpstr;' ];          

        geometry = { [1 1 .5] [1 1 .5]  [1 1 .5] [1 1 .5]};
        uilist = { ...
                   { 'style' 'text'       'string' 'SubID:'                                } ...
                   { 'style' 'edit'       'string' EEG.subject  'tag' 'SubID'         } ...
                   {  } ...
                   ...
                   { 'style' 'text'       'string' 'Score field to export:'         } ...
                   { 'style' 'edit'       'string' ''                'tag' 'ScoreField' } ...
                   { 'style' 'pushbutton' 'string' '...'     'callback' cbField    } ... 
                   ...
                   { 'style' 'text'       'string' 'Output file'         } ...
                   { 'style' 'edit'       'string' ''                'tag' 'OutPath' } ...
                   { 'style' 'pushbutton' 'string' '...'     'callback' cbDir    } ... 
                   ...
                   { 'style' 'text'       'string' 'Append (Y/N):'                                } ...
                   { 'style' 'edit'       'string' 'Y'                'tag' 'Apend'         } ...
                   { }...
                 };

        [op ud sh Results] = inputgui( geometry, uilist, 'pophelp(''pop_ExportScores'')', 'Export Scores - pop_ExportScores()');
        if isempty(Results); return; end  

        EEG.subject = Results.SubID;
        OutPath = Results.OutPath;
        ScoreField= Results.ScoreField;
        Append = Results.Append;
    end

    %Get SubID if not present in EEG
    if isempty(EEG.subject)
        geometry = { [1 1]};
        uilist = { ...
                   { 'style' 'text'       'string' 'SubID:'                  } ...
                   { 'style' 'edit'       'string' ''  'tag' 'SubID'         } ...
                 };

        [op ud sh Results] = inputgui( geometry, uilist, 'pophelp(''pop_ExportScores'')', 'Export Scores - pop_ExportScores()');
        if isempty(Results); return; end     
        EEG.subject = Results.SubID;
    end

    Append = upper(Append);
    if ~(strcmp(Append, 'Y') || strcmp(Append, 'N'))
        error ('Append (%s) must be Y or N\n', Append)
    end

    fprintf('\npop_ExportScores(): Exporting scores (Score Field = %s) to %s\n', ScoreField, fullfile(OutPath, [ScoreField '.dat']));

    %Make Scores Struct and add SubID field with appropriate length
    Scores = EEG.scores.(ScoreField);
    LabelFields = fieldnames(Scores);
    Scores.SubID = repmat(EEG.subject,size(Scores.(LabelFields{1}),1),1);

    %reorder fields for SubID first
    FinalFields = {'SubID', LabelFields{:}};
    Scores = orderfields(Scores, FinalFields);

    %write Scores to file
    tdfwrite(fullfile(OutPath, [ScoreField '.dat']), Scores, Append)

    %Return the string command for record of processing if desired
    COM = sprintf('[EEG, COM] = pop_ExportScores(EEG, \''%s\'', \''%s\'', \''%s\'');', ScoreField, OutPath, Append);
return
