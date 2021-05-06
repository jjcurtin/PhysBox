%USAGE: [ EEG, COM, f, ym ] = pop_QuantNoise( EEG, Prefix, Path, DisplayFig )
%Adds  info about 60Hz noise to notes filed of EEG and makes FFT figure
%
%INPUTS
%EEG:  A set file
%Prefix: Unique string label to append to figure
%Path:  Path to save the figure
%DisplayFig:  Should fig be displayed or closed immediately
%
%OUTPUTS
%EEG:  A EEG set file with notes field updated
%COM:  processing string for history
%f:  Frequencies from FFT
%ym:  Power from FFT

%Revision History
%2012-02-07, updated to use EEG as input and output.  Changed parameter to Prefix for clarity, JJC

function [ EEG, COM, f, ym ] = pop_QuantNoise( EEG, Prefix, Path, DisplayFig )
    
    %NEED A DIALOG BOX FOR THIS INFO
    if nargin < 4
        DisplayFig = true;
    end
    
    if nargin < 3
        Path = '';
    end    
    
    if nargin < 2
        Prefix = '';
    end
    
    fprintf('\npop_QuantNoise():  Quantifying 60Hz noise for all data channels\n')
    [ym, f] = eeg_FastFourier(EEG, round(4*EEG.srate), [], 1, 100, round(4*EEG.srate));  %this will yield 0.25Hz resolution
    
    if DisplayFig  %called from GUI, make figure
        figure
        plot(f,ym)
        leg=legend(EEG.chanlocs.labels); set(leg,'FontSize',14);ti=title('FFT');set(ti,'FontSize',24)
        xlabel('Frequency (Hz)', 'FontSize',18)
        ylabel('Amplitude (microvolts)', 'FontSize',18)
    end
    
    EEG = notes_QuantNoise(EEG, f, ym, Prefix, Path);
    COM = sprintf('EEG = pop_QuantNoise(EEG, %d);', DisplayFig);
end