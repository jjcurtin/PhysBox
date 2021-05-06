%USAGE: [ EEG, COM ] = pop_LoadCnt(SubID, Filename, Filepath, DataFormat )
%Wrapper function to call pop_loadcnt with Curtin lab function naming
%conventions.  Adds SubID, removes DC offset and converts event table to integer   
%see pop_loadcnt()
%
%INPUTS
%SubID:  SubID as string
%Filename:  File name for data set
%Filepath:  Path for data set
%DataFormat: 'int16' or 'int32' or 'auto' (best option)
%
%OUTPUTS
%EEG:  EEG SET File
%COM:  Data processing string for history

%Revision history
%2012-01-26:  added pop_RemoveDC and pop_ConvertEvents, JJC
%2012-02-01:  added new GUI dialog, JJC
    
function [ EEG, COM ] = pop_LoadCnt(SubID, Filename, Filepath, DataFormat )

    COM = sprintf('EEG = pop_LoadCnt();');
    EEG = eeg_emptyset;
    
    if nargin < 4
        cbFile = ['[Filename Filepath] = uigetfile(''*.cnt'', ''Open CNT File'');'...   
                  'if ~(isequal(Filename,0) || isequal(Filepath,0))' ...
                  '   ffn = fullfile(Filepath, Filename);' ...
                  '   set(findobj(''parent'', gcbf, ''tag'', ''FullFilePath''), ''string'', ffn);'...
                  'end;'];       
        callback16 = 'set(findobj(gcbf, ''tag'', ''Bit32''), ''value'', ~get(gcbo, ''value'')); set(findobj(gcbf, ''tag'', ''auto''), ''value'', ~get(gcbo, ''value''));';
        callback32 = 'set(findobj(gcbf, ''tag'', ''Bit16''), ''value'', ~get(gcbo, ''value'')); set(findobj(gcbf, ''tag'', ''auto''), ''value'', ~get(gcbo, ''value''));';
        callbackAD = 'set(findobj(gcbf, ''tag'', ''Bit16''), ''value'', ~get(gcbo, ''value'')); set(findobj(gcbf, ''tag'', ''Bit32''), ''value'', ~get(gcbo, ''value''));';    

        geometry = { [1 1 1.5] [1 2 .5] [1 .83 .83 .83]};

        uilist = { ...
                 { 'Style', 'text', 'string', 'SubID:' } ...
                 { 'style' 'edit'       'string' ''                'tag' 'SubID' } ... 
                 {}...
                 ...
                 { 'Style', 'text', 'string', 'CNT Path and Filename:' } ...
                 { 'style' 'edit'       'string' ''                'tag' 'FullFilePath' } ...  
                 { 'style' 'pushbutton' 'string' 'Select'     'callback' cbFile    } ... 
                 ....
                 { 'Style', 'text', 'string', 'Data type' } ...         
                 { 'Style' 'checkbox'   'string' '16 bit' 'tag' 'Bit16' 'value' 0 'callback' callback16 } ...
                 { 'Style' 'checkbox'   'string' '32 bit' 'tag' 'Bit32' 'value' 0 'callback' callback32} ...
                 { 'Style' 'checkbox'   'string' 'auto-detect' 'tag' 'auto' 'value' 1 'callback' callbackAD} ...
                 };
                [op ud sh Results] = inputgui( geometry, uilist, 'pophelp(''pop_LoadCnt'');', 'Open CNT file -- pop_LoadCnt()' );
                if isempty(Results); return; end

        [Filepath Filename Ext] = fileparts(Results.FullFilePath);
        Filename = [Filename Ext];
        SubID = Results.SubID;
        if Results.Bit16
            DataFormat = 'int16';
        end
        if Results.Bit32
            DataFormat = 'int32';
        end    
        if Results.auto
            DataFormat = 'auto';
        end
    end

    fprintf('pop_LoadCnt():  Loading CNT file %s\n', fullfile(Filepath, Filename));
    [EEG] = pop_loadcnt(fullfile(Filepath, Filename), 'dataformat', DataFormat);
    
    EEG.subject = SubID;    
    %EEG = pop_RemoveDC(EEG);   %not done automatically.  Should be called directly in processing script     
    %EEG = pop_ConvertEvents(EEG);   %not done automatically.  Should be called directly in processing script
end


