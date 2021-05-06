%Usage: [MeanPowerOut] = MeanPower(RawPowerIn,LowFreq,HighFreq,Exclude60Hz)
%Returns mean power array in a frequency range (LowFreq-HighFreq) for input array RawPowerIn.  Can
%exclude 60Hz from calculations if desired.
%
%Inputs:
%RawPowerIn: Epochs/Conditions+1 X Freqs array of power values.  First row is freqs,
%     remaining rows are power values for different epochs/conditions
%LowFreq,HighFreq: integer values for low and high frequencies for range in
%     which to calculate mean power
%Exclude60Hz: boolean to indicate if 60Hz and its resonance frequencies
%     should be excluded.  If true, will substitute mean of surrouding values
%     (one point on either side)
%
%Outputs:
%MeanPowerOut: Epochs X 1 array of mean power values
%
%see also: eegplugin_PhysBox(), eeglab()
%
%Author: John Curtin(jjcurtin@wisc.edu)

%Revision History
%07-13-2008, released v1.  JJC

function [MeanPowerOut] = MeanPower(RawPowerIn,LowFreq,HighFreq,Exclude60Hz)
    LowIndex = find (RawPowerIn(1,:) >= LowFreq, 1);  %Find index of first freq >= LowFreq
    HighIndex = find (RawPowerIn(1,:) <= HighFreq, 1,'last');  %Find index of last freq <= HighFreq
    
    %if Exclude60Hz is true, substitute average of surround values for 60Hz and its resonance frequencies
    if Exclude60Hz && LowFreq < 60 && HighFreq > 60
        i=1;
        while i <= length(RawPowerIn(1,:))-2
            if mod(RawPowerIn(1,i+1),60) == 0  %check if multiple of 60
                RawPowerIn(2:end,i+1) = (RawPowerIn(2:end,i) + RawPowerIn(2:end,i+2))/2;  %calculate mean of surrounding 2 points
            end
            i=i+1;
        end
    end

    MeanPowerOut = mean(RawPowerIn(2:end,LowIndex:HighIndex),2);
end