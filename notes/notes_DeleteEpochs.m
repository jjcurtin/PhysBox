function [ EEG COM ] = notes_DeleteEpochs( EEG, Method, Count)
    
    fprintf('notes_DeleteEpochs(): Adding notes field for DeleteEpochs processing\n')
    EEG.notes.(['de_n' Method]) = Count;
    
end

