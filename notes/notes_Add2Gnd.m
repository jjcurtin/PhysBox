function [ EEG COM ] = notes_Add2Gnd( EEG, WarnMsg )
    COM = '[ EEG, COM ] = notes_Add2Gnd( EEG, WarnMsg )';
    
    fprintf('notes_Add2Gnd(): Adding notes field for Add2Gnd processing\n')

    EEG.notes.agWarning = WarnMsg; 

end

