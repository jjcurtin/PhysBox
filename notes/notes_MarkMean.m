function [ OutEEG COM ] = notes_MarkMean( InEEG )

    fprintf('notes_MarkMean(): Adding notes field for MarkMean processing\n')
    InEEG.notes.mm_nVal = InEEG.trials - sum(InEEG.reject.rejmean); %total valid
    InEEG.notes.mm_nRej = sum(InEEG.reject.rejmean); %total reject

    
    OutEEG = InEEG;
    COM = 'EEG = notes_MarkMean( EEG )';
end

