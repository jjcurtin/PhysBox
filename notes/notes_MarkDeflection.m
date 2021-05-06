function [ EEG COM ] = notes_MarkDeflection( EEG )

    fprintf('notes_MarkDeflection(): Adding notes field for MarkDeflection processing\n')
    EEG.notes.md_nVal = EEG.trials - sum(EEG.reject.rejdeflect); %total valid
    EEG.notes.md_nRej = sum(EEG.reject.rejdeflect); %total reject

   
    COM = 'EEG = notes_MarkDeflection( EEG )';
end

