%Usage:   [EEG, COM] = pop_ScoreWindows(EEG, {Chan, Method, Windows, Prefix, Path)
%Scores MEAN, MIN or MAX in pre-defined windows in epoched file
%
%Inputs:
%EEG: an epoched dataset
%Chan:    channel label to score.
%Method: 'MEAN', 'MIN', or 'MAX'.
%Windows: cell array of pairs of start and end times for scoring windows e.g., {start1 end2 start2 end2}.  
%         Window borders in MS values (accurate to tenth of ms)
%Prefix:  Prefix label for dat files that are exported (e.g., ERP_,
%Path:    Path to save DAT file
%
%Outputs:
%EEG: an EEG data structure with new subfields in field called Scores.
%Subfields are added to scores with labels for this reduction.  These subfields have their own
%fields for scores for each channel by event combo
%
%COM: String to record this processing step
%
% See also: eeglab(). tdfread(), tdfwrite()
%
% Copyright (C) 2011  John J. Curtin, University of Wisconsin-Madison,
% jjcurtin@wisc.edu

%Revision History
%2011-09-27 Released version1, JJC v1
%2011-09-28:  Added Scores field
%2011-10-19:  modfied to handle mutliple windows, JJC
%2011-11-03:  debugged error in AdjustTime endtime indexing, MJS

function [EEG, COM] = pop_ScoreWindows(EEG, Chan, Method, Windows, Prefix, Path)
    
    COM = '[EEG, COM] = pop_ScoreWindows(EEG);'; % these initializations ensure that the function will return something
              % if the user press the cancel button        
    
    % display help and error if EEG not provided
    if nargin < 1  %calls help if no arguments are provided to function
        pophelp('pop_ScoreWindows');
        return
    end	              
              
    %error if file is not epoched 
    if isempty(EEG.epoch)
        error('pop_ScoreWindows() does not work on continuous files\n')
    end           
       
    % pop up window if other arguments not provided.  Will score all channels by default
    if nargin < 6  %calls dialog box if less than 3 arguments are provided to function

        cbChan = ['tmpchanlocs = EEG(1).chanlocs;'...
                '[tmp tmpval] = pop_chansel({tmpchanlocs.labels}, ''withindex'', ''on'', ''selectionmode'', ''single'');'...
                'set(findobj(gcbf, ''tag'', ''ChanList''), ''string'',tmpval);'...
                'clear tmp tmpchanlocs tmpval'];         

        cbPath = ['[rp] = uigetdir([], ''Select Output Path'');'...   
                  'if ~(isequal(rp,0))' ...
                  '   set(findobj(''parent'', gcbf, ''tag'', ''RootPath''), ''string'', rp);'...
                  'end;'];              

        geometry = { [1 .5 .5] [1 .5 .5] [1 .5 .5] [1 .5 .5] [1 .5 .5] };
        uilist = {...
                  { 'style' 'text'       'string' 'Channel to Score:' } ...
                  { 'style' 'edit'       'string' 'ALL' 'tag' 'Chan' } ...
                  { 'style' 'pushbutton' 'string' '...' 'callback' cbChan } ...
                  ...
                  { 'style' 'text'       'string' 'Scoring Method (MEAN, MIN, MAX)' } ...
                  { 'style' 'edit'       'string' 'MEAN' 'tag' 'Method' } ...
                  { } ...
                  ...              
                  { 'style' 'text'       'string' 'Start/End (in ms) for Scoring Window(s) (e.g., 300 400 400 500' } ...
                  { 'style' 'edit'       'string' '' 'tag' 'Windows' } ...
                  { } ...
                  ...
                  { 'style' 'text'       'string' 'Score file Prefix' } ...
                  { 'style' 'edit'       'string' '', 'tag' 'Prefix' } ...
                  { } ...
                  ...
                  { 'style' 'text'       'string' 'RootPath for output files:' } ...
                  { 'style' 'edit'       'string' ' ' 'tag' 'RootPath' } ...
                  { 'style' 'pushbutton' 'string' '...' 'callback' cbPath } ...
                  };

        [op ud sh Results] = inputgui( geometry, uilist, 'pophelp(''pop_ScoreWindows'');', 'Score Windows -- pop_ScoreWindows()' );
        if isempty(Results); return; end

        %assign inputs from dialog box stored in cell array called result to appropriate variables
        Method = upper(Results.Method);
        Windows = parsetxt(Results.Windows);
        Prefix = Results.Prefix;
        Path = Results.OutPath;
        Chan = Results.Chan;
    end
    
    if rem(length(Windows),2)
        error('Windows must contain pairs (start end) of values\n');
    end
    
    ChanNum = GetChanNum( EEG, Chan );
    
    if ischar(Windows{1}) %from GUI        
        for i = 1:length(Windows)
            Windows{i} = str2double(Windows{i});
        end
    end   
    
    Method = upper(Method);  %for consistency below
    
    fprintf('pop_ScoreWindows(): Scoring %s response in fixed window\n', Method);  %displays message on screen that function is running 
    for w=1:2:(length(Windows)-1)  %Loop through different windows
        fprintf('Scoring %s in window: %0.2f - %0.2f ms\n', Method, Windows{w}, Windows{w+1});  %displays message on screen that function is running    
        
        %get index for start and end times
        [ AdjStartTime, IndexStartTime ] = AdjustTime( EEG, Windows{w});
        [ AdjEndTime, IndexEndTime ] = AdjustTime( EEG, Windows{w+1});
         
        Scores = struct('Trial', (1:EEG.trials)', 'EventCode', zeros(EEG.trials,1), 'BaseMin', zeros(EEG.trials,1), 'BaseMax', zeros(EEG.trials,1), 'Mag', zeros(EEG.trials,1), 'Reject', zeros(EEG.trials,1)); 

        for i = 1:EEG.trials  %Insert event types.   Can be saved as either numeric or string in the event field but should always represent a number
            if isnumeric(EEG.event(FindEvent0Index(EEG,i)).type)
                Scores.EventCode(i) = EEG.event(FindEvent0Index(EEG,i)).type;
            else
                Scores.EventCode(i) = str2double(EEG.event(FindEvent0Index(EEG,i)).type);
            end
        end
        
        %Score Mag
        switch upper(Method)
            case 'MAX'
                SM = max(EEG.data(ChanNum,IndexStartTime:IndexEndTime,:),[],2);
            case 'MIN'
                SM = min(EEG.data(ChanNum,IndexStartTime:IndexEndTime,:),[],2);
            case 'MEAN'
                SM = mean(EEG.data(ChanNum,IndexStartTime:IndexEndTime,:), 2);
        end
                                
        SM = squeeze(SM);
        Scores.Mag = SM;  %Insert Mags
        
        %Base Min and Max
        Time0 = find(abs(EEG.times)< 100*eps);  %find < eps rather than ==0 to correct for floating point problems
        BaseMins = squeeze(min(EEG.data(ChanNum,1:Time0,:),[],2));
        BaseMaxs = squeeze(max(EEG.data(ChanNum,1:Time0,:),[],2));
        Scores.BaseMin = BaseMins;
        Scores.BaseMax = BaseMaxs;        
        
        %Reject field
        %0=not rejected, 1= auto reject, 2=manual reject
        if isempty(EEG.reject.rejmanual) %setup rejmanual if empty for use next
            EEG.reject.rejmanual = zeros(1,EEG.trials);
        end
        Scores.Reject = (FindRejects(EEG) + EEG.reject.rejmanual)';  %count rejmanual twice to get to 2.... Transpose to match structure of SCORES
        
        %add Scores field to EEG and max subfield label for this reduction
        if AdjStartTime < 0 && AdjEndTime < 0
            Label = [Prefix upper(Method(1:2)) 'neg' num2str(round(abs(AdjStartTime))) '_neg' num2str(round(abs(AdjEndTime)))]; %convert negaitve time window to pos - both Start and End
        elseif AdjStartTime < 0
            Label = [Prefix upper(Method(1:2)) 'neg' num2str(round(abs(AdjStartTime))) '_' num2str(round(abs(AdjEndTime)))]; %convert negaitve time window to pos - Start only
        elseif AdjEndTime < 0
            Label = [Prefix upper(Method(1:2)) num2str(round(abs(AdjStartTime))) '_neg' num2str(round(abs(AdjEndTime)))]; %convert negaitve time window to pos - End only
        else
            Label = [Prefix upper(Method(1:2)) num2str(round(AdjStartTime)) '_' num2str(round(AdjEndTime))];
        end
        EEG.scores.(Label) = Scores;
        %Append this set of scores to appropriate named file
        pop_ExportScores(EEG, Label, Path, 'Y');
    end
 
    %Return the string command for record of processing if desired
    COM = sprintf('EEG = pop_ScoreWindows(EEG);');
end