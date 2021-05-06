%USAGE: [ EEG, COM ] = pop_SaveSet(EEG, Filename, Filepath )
%wrapper function to call pop_saveset to save with current path and filename
%with Curtin lab function naming conventions.   see pop_saveset()
%
%INPUTS
%EEG: an EEG set
%Filename:  filename for save.  If blank, will use currently assigned
%           filename. If no currently assigned filename, will prompt for filename
%Filepath:  Path for save.  Same is true for defaults
%
%OUTPUTS
%EEG:  saved EEG 
%COM: string processing command for history

function [ EEG, COM ] = pop_SaveSet(EEG, Filename, Filepath )

    COM = '[ EEG, COM ] = pop_SaveSet(EEG )';
    if nargin < 3
        if isempty(EEG.filename) || isempty(EEG.filepath)
            EEG = pop_saveset( EEG);  %ask for file name and path
        else
            fprintf('\npop_SaveSet(): Saving set file as %s\n', fullfile(EEG.filepath, EEG.filename));
            EEG = pop_saveset( EEG, 'filename', EEG.filename, 'filepath', EEG.filepath);  
        end
    else  %save with new names
        EEG.filename = Filename;
        EEG.filepath = Filepath;
        EEG = pop_saveset( EEG, 'filename', EEG.filename, 'filepath', EEG.filepath);  
        fprintf('\npop_SaveSet(): Saving set file as %s\n', fullfile(Filepath, Filename));
    end
end


