%USAGE: [ EEG, COM ] = pop_LoadEGI(SubID, Filename, FilePath )
%Wrapper function to call pop_readegimff() with Curtin lab function naming
%conventions.  Adds SubID and removes DC offset. 
%see pop_readegimff()
%
%INPUTS
%SubID:  SubID as string
%Filename:  File name for data file
%FilePath:  File path for data file
%
%OUTPUTS
%EEG:  EEG SET file
%COM:  Data processing command for history

    
function [ EEG, COM ] = pop_LoadEGI(SubID, Filename, Filepath )

    COM = sprintf('EEG = pop_LoadEGI();');
    
    if nargin < 3
        fprintf('pop_LoadEGI():  Loading EGI file\n');
        EEG = pop_readegimff();      
    else
        fprintf('pop_LoadEGI():  Loading EGI file %s\n', fullfile(Filepath, Filename));
        EEG = pop_readegimff(fullfile(Filepath, Filename));
        EEG.subject = SubID; 
    end
      
    %EEG = pop_RemoveDC(EEG);      %not done automatically.  Should be called directly in processing script  
    %EEG = pop_ConvertEvents(EEG); %not done automatically.  Should be called directly in processing script if needed
end