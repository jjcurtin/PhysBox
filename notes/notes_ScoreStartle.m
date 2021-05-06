function [ OutEEG COM ] = notes_ScoreStartle( InEEG, STL )

    fprintf('notes_ScoreStartle(): Adding notes field for ScoreStartle processing\n')

    InEEG.notes.ss_nVal = sum(~FindRejects(InEEG, 'all'));  %total number of valid trials
    
    UniqueEventCodes = unique(GetTime0Events(InEEG));
    InEEG.notes.ss_nConditions = length(UniqueEventCodes); %number of unique events/conditions

    %count of valid trials by condition/event code
    EventCodes = GetTime0Events(InEEG);
    for i = 1:length(UniqueEventCodes)
       InEEG.notes.(['ss_nVal' int2str(UniqueEventCodes(i))]) = sum(EventCodes==UniqueEventCodes(i) & ~FindRejects(InEEG, 'all')'); % # trials per event         
    end  
    
    InEEG.notes.ss_nRejTot = sum(FindRejects(InEEG, 'all'));  %n and percent rejected overall
    InEEG.notes.ss_pRejTot = sum(FindRejects(InEEG, 'all')) / InEEG.trials;
    InEEG.notes.ss_nRejAuto = sum(FindRejects(InEEG, 'auto'));  %n and percent rejected auto
    InEEG.notes.ss_pRejAuto = sum(FindRejects(InEEG, 'auto')) / InEEG.trials;
    InEEG.notes.ss_nRejUser = sum(FindRejects(InEEG, 'manual')); %n and percent rejected manual/user
    InEEG.notes.ss_pRejUser = sum(FindRejects(InEEG, 'manual')) / InEEG.trials;
 
    InEEG.notes.ss_BaseRange = mean(STL.BaseMax(STL.Reject==0) - STL.BaseMin(STL.Reject==0)); %mean of baseline range across trials     
    InEEG.notes.ss_nNR = sum(STL.NR(STL.Reject==0)); % # NR trials
    InEEG.notes.ss_pNR = sum(STL.NR(STL.Reject==0)) /  (size(STL.Trial,1) - InEEG.notes.ss_nRejTot); %percent NR trials      
    InEEG.notes.ss_MeanSTLMag = mean(STL.STLMag(STL.Reject==0));
    InEEG.notes.ss_MeanSTLLat = mean(STL.STLLat(STL.Reject==0));
    InEEG.notes.ss_MeanPRBMag = mean(STL.PRBMag(STL.Reject==0));
    InEEG.notes.ss_MeanPRBLat = mean(STL.PRBLat(STL.Reject==0));    
    
    OutEEG = InEEG;
    COM = sprintf('EEG = notes_ScoreSTL(EEG, STL);');       
end