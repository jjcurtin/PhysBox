%USAGE: [ EEG, COM ] = pop_LoadSma(SubID, Filename, Filepath, Gain, ChanLabels  )
%wrapper function to call pop_snapread with Curtin lab function naming
%conventions.   see pop_snapread()
%SubID:  SubID as string
%Filename:  Filename of data file
%Filepath: Path of data file
%Gain:  gain applied to data during acquistion 
%ChanLabels:  Cell array with channel labels of all data channels.  Empty
%             for default (numeric) labels
%
%OUTPUTS
%EEG:  EEG Set file
%COM:  Data processing string for history

%Revision History
%2012-01-02:  added parameter to set channel labels, JJC, DEB
%2012-01-02"  added dialog box, JJC
  
function [ EEG, COM ] = pop_LoadSma(SubID, Filename, Filepath, Gain, ChanLabels )
    EEG = eeg_emptyset;
    COM = '[ EEG, COM ] = pop_LoadSma()';
    
    if nargin < 5
        ChanLabels = {};
    end
    
    if nargin < 4
              
        cbFile = ['[Filename Filepath] = uigetfile(''*.sma'', ''Open SMA File'');'...   
                  'if ~(isequal(Filename,0) || isequal(Filepath,0))' ...
                  '   ffn = fullfile(Filepath, Filename);' ...
                  '   set(findobj(''parent'', gcbf, ''tag'', ''FullFilePath''), ''string'', ffn);'...
                  'end;'];                                                               
        
        geometry = { [1 .5 2] [1 2 .5] [1 .5 2] [1 2 .5]};
        uilist = { ...
                 { 'Style', 'text', 'string', 'SubID:' } ...
                 { 'style' 'edit'       'string' ''                'tag' 'SubID' } ... 
                 {}...
                 ...
                 { 'Style', 'text', 'string', 'SMA Path and Filename:' } ...
                 { 'style' 'edit'       'string' ''                'tag' 'FullFilePath' } ...  
                 { 'style' 'pushbutton' 'string' 'Select File'     'callback' cbFile    } ... 
                 ....
                 { 'style' 'text'       'string' 'Gain:'                                } ...
                 { 'style' 'edit'       'string' '5000'             'tag' 'Gain'         } ...
                 {}...
                 ...
                 { 'style' 'text'       'string' 'Ordered Channel Labels(Blank for default labels)'} ... 
                 { 'style' 'edit'       'string' ''           'tag' 'ChanLabels'   } ...
                 {}...
                 };

        [op ud sh Results] = inputgui( geometry, uilist, 'pophelp(''pop_LoadSma'')', 'Load SMA file - pop_LoadSma()');
        if isempty(Results); return; end  
        
        [Filepath, Filename, Ext] = fileparts(Results.FullFilePath);
        Filename = [Filename Ext];
        SubID = Results.SubID;
        Gain = str2double(Results.Gain);
        ChanLabels = parsetxt(Results.ChanLabels); 
    end
    
    fprintf('pop_LoadSma():  Loading SMA files %\n', fullfile(Filepath, Filename));            
    [EEG] = pop_snapread(fullfile(Filepath, Filename), 1);
    
    EEG.data(:,:) = EEG.data(:,:) / Gain * 10^6;  %remove hardward gain and convert from volts to microvolts
    
    fprintf('pop_LoadSma():  Adding channel labels\n');    
    if ~isempty(ChanLabels) && ~(length(ChanLabels) == size(EEG.data,1))
        ChanLabels = {};
        fprintf(2,'\nWARNING: Incorrect # of channel labels.  Channel labels replaced with numeric indices\n\n');
    end
    
    for i = 1:size(EEG.data,1)
        if ~isempty(ChanLabels)
            EEG.chanlocs(i).labels = ChanLabels{i};
        else
            EEG.chanlocs(i).labels = i;
        end
    end
    
    EEG.subject = SubID;
    %EEG = pop_RemoveDC(EEG);     %not done automatically.  Should be called directly in processing script   
    %EEG = pop_ConvertEvents(EEG);   %not done automatically.  Should be called directly in processing script
    
    COM = sprintf('EEG = pop_LoadSma();');  
end


