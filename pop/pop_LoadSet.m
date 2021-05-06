%USAGE: [ EEG, COM ] = pop_LoadSet(Filename, Filepath )
%wrapper function to call pop_LoadSet with Curtin lab function naming
%conventions.   see pop_loadset()
%
%INPUTS
%Filename: Filename for data set
%Filepath: Path for data set
%
%OUTPUTS
%EEG:  EEG SET file
%COM:  data processing string for history


function [ EEG, COM ] = pop_LoadSet(Filename, Filepath )
    if nargin < 2
        [Filename, Filepath] = uigetfile('*.set', 'Open SET File');
        if  isequal(Filename,0) || isequal(Filepath,0)
            COM = '';
            EEG = eeg_emptyset;
            return
        end        
    end
    
    fprintf('pop_LoadSet():  Loading SET file\n');
    EEG = pop_loadset(Filename, Filepath);  
     
    
    COM = sprintf('EEG = pop_LoadSet(%s, %s);', Filename, Filepath);
    
    
end


