%USAGE: [ EEG Indices COM ] = pop_MarkDeflection( EEG, ChanList, MaxDeflect, WinTimes, Reject )
%Mark epochs for rejection (but do not reject) if max voltage deflection (max - min voltage) in window
%exceeds MaxDeflect.
%see also pop_MarkThreshold(), pop_MarkMean(), pop_eegthresh(), eegplugin_PhysBox(), eeglab()
%
%INPUTS
%EEG:  An epoched EEG struct
%ChanList:  Cell array of channel labels.  Accepts 'all' and 'exclude'
%           notation (see MakeChanList)
%MaxDeflect:  Maximum tolerable deflection (max - min) within specified
%             window
%WinTimes:  Cell array of window Start and End time in ms
%Reject: Boolean to indicate immediate reject (true) or mark for later
%        reject (false)
%
%OUTPUTS
%EEG:  EEG struct with rejmean added to reject field
%Indices:  Indices of rejected epochs
%COM:  COM to record processing 

%Revision History
%2012-02-21:  released, JJC

function [ EEG Indices COM ] = pop_MarkDeflection( EEG, ChanList, MaxDeflect, WinTimes, Reject )
            
    COM = 'pop_MarkDeflection( EEG )';
    Indices = [];
    
    if nargin < 1  
        pophelp( 'pop_MarkDeflection');
        return
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%UPDATE DIALOG%%%%%%%%%%%%%%%%%%
    if nargin < 5
        cbButton = ['tmpchanlocs = EEG(1).chanlocs;'...
                            '[tmp tmpval] = pop_chansel({tmpchanlocs.labels}, ''withindex'', ''on'');'...
                            'set(findobj(gcbf, ''tag'', ''ChanList''), ''string'',tmpval);'...
                            'clear tmp tmpchanlocs tmpval']; 

        geometry = {  [1 1 .5] [1 1 .5] [1 1 .5] [1 1 .5] [1] [1 1 1]};

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
                 { 'style' 'text'       'string' 'Maximum Deflection' } ...
                 { 'style' 'edit'       'string' '' 'tag' 'MaxDeflect' } ...
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

        [op ud sh Results] = inputgui( geometry, uilist, 'pophelp(''pop_MarkDeflection'');', 'Reject Epochs by Max Deflection -- pop_MarkDeflection()' );
        if isempty(Results); return; end
        
        %[ChanInds ChanList] = eeg_decodechan(EEG.chanlocs, Results.ChanList);
        ChanList =  parsetxt(Results.ChanList);
        WinTimes = parsetxt(Results.WinTimes);
        MaxDeflect = str2double(Results.MaxDeflect);
        Reject = Results.Reject;
    end    
    
    fprintf ('pop_MarkDeflection(): marking trials with deflections that exceed %d for rejection\n', MaxDeflect);
    
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


    if ~isfield(EEG.reject, 'rejdeflect')  %set reject fields to 0 if they dont exist from previous call to MarkDeflect
        EEG.reject.rejdeflect = zeros(1,EEG.trials);
        EEG.reject.rejdeflectE = zeros(EEG.nbchan,EEG.trials);
    end
       
    rejE = max(EEG.data(:,StartIndex:EndIndex,:),[],2) - min(EEG.data(:,StartIndex:EndIndex,:),[],2);
    rejE = squeeze(rejE);
    if EEG.nbchan ==1
        rejE = rejE'; %sqeeze transposes data if only one channel.  Fix
    end
        
    rejE = rejE > MaxDeflect; 
    rejE(IgnoreInds,:) = 0;   %set all ignored channels to not rejected
    if EEG.nbchan ==1
        rej = rejE;  %if only one change, rej and rejE are identical
    else
        rej = max(rejE);   %get max across channels (if any are 1, epoch is rejected
    end
    
    EEG.reject.rejdeflect = max(EEG.reject.rejdeflect,rej);  %if previously rejected, still rejected.  If newly rejected, now rejected 
    EEG.reject.rejdeflectE = max(EEG.reject.rejdeflectE,rejE);  %if previously rejected, still rejected.  If newly rejected, now rejected
    
    fprintf ('%d/%d trials marked for rejection\n', sum(EEG.reject.rejdeflect), EEG.trials);
    
    EEG = notes_MarkDeflection(EEG);  %Add info on trials marked for rejection to notes field

    Indices = find(EEG.reject.rejdeflect);
    
    if Reject
        EEG = pop_rejepoch(EEG, EEG.reject.rejdeflect, 0);        
    end
    
    COM = 'EEG = pop_MarkDeflect EEG );';
end

