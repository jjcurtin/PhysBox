function [ AvgEEG COM ] = notes_CreateAvg( AvgEEG )
    fprintf('notes_CreateAvg(): Adding notes field for CreateAvg processing\n')
    for i = 1:AvgEEG.trials
        AvgEEG.notes.(['ca_nVal' num2str(AvgEEG.epoch(i).eventtype)]) = AvgEEG.epoch(i).eventcount;
    end
        
    COM = '[ OutEEG COM ] = notes_CreateAvg( TrialEEG, AvgEEG, Prefix )';
end

