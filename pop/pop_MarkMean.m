%USAGE: [ EEG Indices COM ] = pop_MarkMean( EEG, ChanList, LoMean, HiMean, WinTimes, Reject )
%Mark epochs for rejection (but do not reject) if mean voltage in window
%exceeds threshold.
%see also pop_MarkThreshold, pop_eegthresh(), eegplugin+PhysBox(), eeglab()
%
%INPUTS
%EEG:  An epoched EEG struct
%ChanList:  Cell array of channel labels.  Accepts 'all' and 'exclude'
%           notation (see MakeChanList)
%LoMean:  Lower threshold level.  [] for no lower test
%HiMean threshold level.  [] for no upper test
%WinTimes:  Cell array of window Start and End time in ms
%Reject: Boolean to indicate immediate reject (true) or mark for later
%        reject (false)
%
%OUTPUTS
%EEG:  EEG struct with rejmean added to reject field
%Indices:  Indices of rejected epochs
%COM:  EEGLab COM

%Revision History
%2011-11-25:  released, JJC
%2011-12-04:  added notes function, JJC

function [ EEG Indices COM ] = pop_MarkMean( EEG, ChanList, LoMean, HiMean, WinTimes, Reject )
            
    COM = 'pop_MarkMean( EEG );';
    Indices = [];
    
    if nargin < 1  
        pophelp( 'pop_MarkMean');
        return
    end
    
    if nargin < 6
        cbButton = ['tmpchanlocs = EEG(1).chanlocs;'...
                            '[tmp tmpval] = pop_chansel({tmpchanlocs.labels}, ''withindex'', ''on'');'...
                            'set(findobj(gcbf, ''tag'', ''ChanList''), ''string'',tmpval);'...
                            'clear tmp tmpchanlocs tmpval']; 

        geometry = {  [1 1 .5] [1 1 .5] [1 1 .5] [1 1 .5] [1 1 .5] [1] [1 1 1]};

        uilist = { ...
                 { 'Style', 'text', 'string', 'Channels' } ...
                 { 'Style', 'edit', 'string', '', 'tag', 'ChanList' } ...
                 { 'style' 'pushbutton' 'string'  '...', 'enable' fastif(isempty(EEG.chanlocs), 'off', 'on') ...
                   'callback', cbButton  } ...
                 ...
                 { 'style' 'text'       'string' 'Window [start, end] in ms' } ...
                 { 'style' 'edit'       'string' [num2str(EEG.xmin * 1000)  '     ' num2str(EEG.xmax * 1000)], 'tag' 'WinTimes' } ...
                 { } ...
                 ...
                 { 'style' 'text'       'string' 'Low Mean Level (Blank = ignore)' } ...
                 { 'style' 'edit'       'string' '' 'tag' 'LoMean' } ...
                 { } ...
                 ...
                 { 'style' 'text'       'string' 'High Mean Level (Blank = ignore)' } ...
                 { 'style' 'edit'       'string' '', 'tag' 'HiMean' } ...
                 { } ...         
                 ...
                 { 'style' 'text'       'string' 'Reject immediately (vs. mark)' } ...
                 { 'Style' 'checkbox'   'string' '  ' 'tag' 'Reject' } ...
                 { } ... 
                 ...
                 { } ... 
                 ...
                 { } { 'Style', 'pushbutton', 'string', 'Scroll dataset', 'enable', fastif(length(EEG)>1, 'off', 'on'), 'callback', ...
                                  'eegplot(EEG.data, ''srate'', EEG.srate, ''winlength'', 5, ''limits'', [EEG.xmin EEG.xmax]*1000, ''position'', [100 300 800 500], ''xgrid'', ''off'', ''eloc_file'', EEG.chanlocs);' } {}};

        [op ud sh Results] = inputgui( geometry, uilist, 'pophelp(''pop_MarkMean'');', 'Reject Epochs by Mean Level -- pop_MarkMean()' );
        if isempty(Results); return; end
        
        %[ChanInds ChanList] = eeg_decodechan(EEG.chanlocs, Results.ChanList);
        ChanList =  parsetxt(Results.ChanList);
        WinTimes = parsetxt(Results.WinTimes);
        LoMean = str2double(Results.LoMean);
        HiMean = str2double(Results.HiMean); 
        Reject = Results.Reject;
    end    
    
    if ischar(WinTimes{1}) %from GUI        
        StartTime = str2double(WinTimes{1});
        EndTime = str2double(WinTimes{2});
    else
        StartTime = WinTimes{1};
        EndTime = WinTimes{2};
    end
    
    [ ChanList, ChanInds ] = MakeChanList( EEG, ChanList );  %allows for 'all' and 'exclude' notation
               
    IgnoreInds = setdiff(1:EEG.nbchan,ChanInds);
    
    [ AdjStartTime, StartIndex ] = AdjustTime( EEG, StartTime );
    [ AdjEndTime, EndIndex ] = AdjustTime( EEG, EndTime );


    EEG.reject.rejmean = zeros(1,EEG.trials);
    EEG.reject.rejmeanE = zeros(EEG.nbchan,EEG.trials);
    
    if ~isempty(LoMean)
        lrejt = mean(EEG.data(:,StartIndex:EndIndex,:),2);
        lrej =  reshape(lrejt, EEG.nbchan, EEG.trials);
        lrej = lrej < LoMean;
        lrej(IgnoreInds,:) = 0;  
        EEG.reject.rejmeanE = lrej;
        EEG.reject.rejmean = sum([EEG.reject.rejmean; lrej],1);          
    end
    
    if ~isempty(HiMean)
        urejt =  mean(EEG.data(:,StartIndex:EndIndex,:),2);
        urej = reshape(urejt, EEG.nbchan, EEG.trials);
        urej = urej > HiMean;
        urej(IgnoreInds,:) = 0;
        EEG.reject.rejmeanE = EEG.reject.rejmeanE + urej;
        EEG.reject.rejmean = sum([EEG.reject.rejmean; urej],1);  
    end    
    
    EEG.reject.rejmean = EEG.reject.rejmean > 0; 
    EEG.reject.rejmeanE = EEG.reject.rejmeanE >0;
    fprintf ('\npop_MarkMean():  Marking trials for rejection based on mean levels in window\n');
    fprintf ('%d/%d trials marked for rejection\n', sum(EEG.reject.rejmean), EEG.trials);
    
    EEG = notes_MarkMean(EEG);  %Add info on trials marked for rejection to notes field

    Indices = find(EEG.reject.rejmean);
    
    if Reject
        EEG = pop_rejepoch(EEG, EEG.reject.rejmean, 0);        
    end
    
    COM = 'EEG = pop_MarkMean( EEG );';
end

