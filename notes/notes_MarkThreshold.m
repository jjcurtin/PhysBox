function [ OutEEG COM ] = notes_MarkThreshold( InEEG )

    fprintf('notes_MarkThreshold(): Adding notes field for MarkThreshold processing\n')
    InEEG.notes.mt_nVal = InEEG.trials - sum(InEEG.reject.rejthresh); %total valid
    InEEG.notes.mt_nRej = sum(InEEG.reject.rejthresh); %total reject
%     for i=1:size(InEEG.reject.rejthreshE,1)  %reject by channel
%         InEEG.notes.(['mt_nRej_' InEEG.chanlocs(1).labels]) = sum(InEEG.reject.rejthreshE(i,:));
%     end
    
    OutEEG = InEEG;
    COM = 'EEG = notes_MarkThreshold( EEG )';
end

