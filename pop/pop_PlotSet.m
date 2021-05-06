%USAGE: [ COM ] = pop_PlotSet(EEG)
%wrapper function for pop_eegplot() using Curtin naming conventions
%see also  pop_eegplot(), eegplugin_PhysBox()
%
%INPUTS
%EEG: an EEG set file
%
%OUTPUTS
%COM:  Data processing string for history

%Revision history
%2011-12-28: released, JJC



function [ COM ] = pop_PlotSet( EEG )
    pop_eegplot(EEG,1,1,1);
    COM = 'pop_PlotSet(EEG)';
end

