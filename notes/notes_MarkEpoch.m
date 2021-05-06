function [ OutEEG, COM ] = notes_MarkEpoch( InEEG )

    fprintf('notes_MarkEpoch(): Adding notes field for MarkEpoch processing\n')
    InEEG.notes.me_nVal = InEEG.trials - sum(InEEG.reject.rejmanual); %total valid
    InEEG.notes.me_nRej = sum(InEEG.reject.rejmanual); %total reject

    
    OutEEG = InEEG;
    COM = 'EEG = notes_MarkEpoch( EEG )';
end

