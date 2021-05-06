function [ AdjTime, Index ] = AdjustTime( EEG, TheTime )
%USAGE: [ AdjTime, Index ] = AdjustTime( EEG, TheTime )
%Adjusts time (typically window start or end time) to nearest actual time
%in EEG.times given sampling rate.  Returns the actual sample time and the
%sample index witin EEG.times
%
%INPUTS
%EEG: a continuous or epoched EEG structure
%TheTime:  Time (in ms) to adjust if necessary
%
%OUTPUTS
%AdjTime:  Nearest time to TheTime in EEG.times
%index:    Sample index number of AdjTime in EEG.times
%
%see also eeglab(), eegplugin_PhysBox()
%
%Author: John Curtin (jjcurtin@wisc.edu)

%Revision history
%2011-11-04:  released, JJC
%2011-12-04:  fixed bug in warning b/c of floating point precision issue, JJC

    TimeDiffs = EEG.times - TheTime;
    
    [M Index] = min(abs(TimeDiffs));
    
    AdjTime = EEG.times(Index);
    
    if abs(AdjTime - TheTime) > 100*eps
        fprintf(2, 'WARNING: Time adjusted from %.4f to %.4f\n', TheTime, AdjTime);
    end

end

