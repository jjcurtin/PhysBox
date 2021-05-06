function [ EEG COM ] = notes_RejectEpochs (EEG )

    fprintf('notes_RejectEpochs(): Adding notes field for RejectEpochs processing\n')
    EEG.notes.re_nVal = EEG.trials - sum(EEG.reject.rejall); %total valid
    EEG.notes.re_nRej = sum(EEG.reject.rejall); %total reject
    EEG.notes.re_pRej = EEG.notes.re_nRej / EEG.trials;
%     for i=1:size(EEG.reject.rejthreshE,1)  %reject by channel
%         EEG.notes.(['mt_nRej_' EEG.chanlocs(1).labels]) = sum(EEG.reject.rejthreshE(i,:));
%     end
    
    COM = 'EEG = notes_RejectEpochs( EEG )';
end

