function [ OutEEG COM ] = notes_Convert2Set( InEEG )
%adds info about CON file to notes field for later data integrity checking
%USAGE: [ OutEEG COM ] = notes_Convert2Set( InEEG )

%Revision history
%2011-10-5: released, JJC
    fprintf('notes_Convert2Set(): Adding notes field for Convert2Set processing\n')

    InEEG.notes.cs_SessionTime = InEEG.xmax/60;  %length of session in minutes
    InEEG.notes.cs_nEvents = size(InEEG.event,2);  %total number of events in CON fil
     
     OutEEG = InEEG;
     COM = sprintf('EEG = notes_Convert2Set(EEG);');  
end