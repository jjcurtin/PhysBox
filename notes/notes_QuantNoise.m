%USAGE: function [ EEG COM ] = notes_QuantNoise( EEG, f, ym, Prefix, Path )
%adds info about FFT on CON file to notes field and makes/saves FFT figure

%Revision history
%2011-10-13: released, JJC
%2011-10-13:  added SubID to title, JJC
%2011-10-24:  added mean 60 Hz field.  Added prefix label to fig name
%2012-02-07: updated to use EEG as input and output.  Changed parameter to Prefix for clarity, JJC

function [ EEG COM ] = notes_QuantNoise( EEG, f, ym, Prefix, Path )
    fprintf('notes_QuantNoise(): Adding notes field and creating diagnostic figure for QuantNoise processing\n')    
    EEG.notes.qn_FFT_f = f;
    EEG.notes.qn_FFT_ym = ym;
    
    EEG.notes.qn_fftMean = 0;
    [m index] = min(abs(f-60));  %get index of freq closest to 60Hz
    for i= 1:length(EEG.chanlocs)
        EEG.notes.(['qn_fft' EEG.chanlocs(i).labels]) = ym(index,i);
        fprintf('%2.2f Hz amplitude for %s = %4.1f\n', f(index), EEG.chanlocs(i).labels, ym(index,i))
        EEG.notes.qn_fftMean = EEG.notes.qn_fftMean + ym(index,i);
    end   
    EEG.notes.qn_fftMean = EEG.notes.qn_fftMean / length(EEG.chanlocs);
    fprintf('MEAN %2.2f Hz amplitude = %4.1f\n', f(index), EEG.notes.qn_fftMean );
    
    figure
    plot(f,ym)
    leg=legend(EEG.chanlocs.labels); set(leg,'FontSize',14);ti=title(['FFT for SubID: ' EEG.subject]);set(ti,'FontSize',24)
    xlabel('Frequency (Hz)', 'FontSize',18)
    ylabel('Amplitude (microvolts)', 'FontSize',18)    

    FigFilename = ['FFT' EEG.subject '.fig'];
    saveas(gcf, fullfile(Path, [Prefix FigFilename])); %save figure to subject's reduction folder        
    close (gcf); %Close figure window    
    
    COM = sprintf('EEG = notes_QuantNoise(EEG, f, ym);');  
end