%USAGE: [ EEG, COM ] = pop_LoadAnt(SubID, Filename, FilePath, Trigger )
%Wrapper function to call pop_loadeep() with Curtin lab function naming
%conventions.  Adds SubID and removes DC offset. 
%see pop_loadeep()
%
%INPUTS
%SubID:  SubID as string
%Filename:  File name for data file
%FilePath:  File path for data file
%Trigger: string ('on' or 'off') to indicate if trigger/event code file is present
%
%OUTPUTS
%EEG:  EEG SET file
%COM:  Data processing command for history

%Revision history
%2012-02-04:  released, JJC
    
function [ EEG, COM ] = pop_LoadAnt(SubID, Filename, Filepath, Trigger )

    COM = sprintf('EEG = pop_LoadAnt();');
    EEG = eeg_emptyset;
    
    if nargin < 4
        cbFile = ['[Filename Filepath] = uigetfile(''*.cnt'', ''Open ANT File'');'...   
                  'if ~(isequal(Filename,0) || isequal(Filepath,0))' ...
                  '   ffn = fullfile(Filepath, Filename);' ...
                  '   set(findobj(''parent'', gcbf, ''tag'', ''FullFilePath''), ''string'', ffn);'...
                  'end;'];            

        geometry = { [1 1 1.5] [1 2 .5] [1 1 1.5]};

        uilist = { ...
                 { 'Style', 'text', 'string', 'SubID:' } ...
                 { 'style' 'edit'       'string' ''                'tag' 'SubID' } ... 
                 {}...
                 ...
                 { 'Style', 'text', 'string', 'ANT Path and Filename:' } ...
                 { 'style' 'edit'       'string' ''                'tag' 'FullFilePath' } ...  
                 { 'style' 'pushbutton' 'string' 'Select File'     'callback' cbFile    } ... 
                 ....
                 { 'Style', 'text', 'string', 'Include Triggers' } ...         
                 { 'Style' 'checkbox'   'string' '' 'tag' 'Trigger' 'value' 1} ...
                 {} ...
                 };
                [op ud sh Results] = inputgui( geometry, uilist, 'pophelp(''pop_LoadAnt'');', 'Open ANT file -- pop_LoadANT()' );
                if isempty(Results); return; end

        [Filepath Filename Ext] = fileparts(Results.FullFilePath);
        Filename = [Filename Ext];
        SubID = Results.SubID; 
        if Results.Trigger
            Trigger = 'on';
        else
            Trigger = 'off';
        end        
    end
   
    fprintf('pop_LoadAnt():  Loading ANT file %s\n', fullfile(Filepath, Filename));
    [EEG] = pop_loadeep(fullfile(Filepath, Filename), 'triggerfile', Trigger);
    
    EEG.subject = SubID;    
    %EEG = pop_RemoveDC(EEG);   %not done automatically.  Should be called directly in processing script    
    %EEG = pop_ConvertEvents(EEG);   %not done automatically.  Should be called directly in processing script
end


