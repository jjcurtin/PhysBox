%USAGE:  [ EEG, COM ] = pop_RemoveDC( EEG )
%Removes mean DC offset from each channel and returns
%data as double precision to avoid matlab computational errors (default EEGLab format).   Removing mean level offset is important to
%avoid computation errors that can occur if voltages become large and
%exceed 32bit (single) range.
%
%INPUTS
%EEG:  a continuous EEG structure
%
%OUTPUTS
%EEG: a continuous EEG structure with mean level removed from each channel
%COM:    The COM that resulted in this call
%
%Author: John Curtin (jjcurtin@wisc.edu)

%Revision history
%2011-10-5:  Released,  JJC

function [ EEG, COM ] = pop_RemoveDC( EEG )
    if EEG.trials > 1
        error('pop_RemoveDC() must be applied to a continuous file\n')
    end

    fprintf('pop_RemoveDC():  Removing DC (mean) offset from each channel\n');
    
    for i=1:EEG.nbchan    
        EEG.data(i,:) = single(double(EEG.data(i,:)) - mean(double(EEG.data(i,:))));
        %OutEEG.data(i,:) = single(double(OutEEG.data(i,:)) - mean(double(OutEEG.data(i,:))));
    end
    EEG.data = double(EEG.data);
    
    COM = 'EEG = pop_RemoveDC( EEG);';

end

