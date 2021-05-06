
%Usage:   [EEG, COM] = pop_ScoreERP(EEG, {ChanList, Method, Windows, Prefix, Path)
%Scores MEAN, MIN or MAX in pre-defined window in epoched file
%
%Inputs:
%EEG: an epoched dataset
%ChanList:  cell array including list of channel labels to score.  Can use
%'all' or 'exclude' notation (see MakeChanList)
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

function [EEG, COM] = pop_ScoreERP(EEG, ChanList, Method, Windows, Prefix, Path)
    
    COM = '[EEG, COM] = pop_ScoreERP(EEG);'; % these initializations ensure that the function will return something
              % if the user press the cancel button        
    
    % display help and error if EEG not provided
    if nargin < 1 
        pophelp('pop_ScoreERP');
        return
    end	              
              
    %error if file is not epoched 
    if isempty(EEG.epoch)
        error('pop_ScoreERP() does not work on continuous files\n')
    end   
    
    %error if file is NOT an AVG file
    EventList = GetTime0Events(EEG);    
    if length(EventList) > length(unique(EventList))  %must have more than one event per type
        error('pop_ScoreERP() intended for Average (AVG) files\n')
    end        
       
    % pop up window if other arguments not provided.  Will score all channels by default
    if nargin < 6  %calls dialog box if less than 6 arguments are provided to function

        cbChanList = ['tmpchanlocs = EEG(1).chanlocs;'...
                '[tmp tmpval] = pop_chansel({tmpchanlocs.labels}, ''withindex'', ''on'');'...
                'set(findobj(gcbf, ''tag'', ''ChanList''), ''string'',tmpval);'...
                'clear tmp tmpchanlocs tmpval'];         

        cbPath = ['[rp] = uigetdir([], ''Select Output Path'');'...   
                  'if ~(isequal(rp,0))' ...
                  '   set(findobj(''parent'', gcbf, ''tag'', ''RootPath''), ''string'', rp);'...
                  'end;'];              

        geometry = { [1 .5 .5] [1 .5 .5] [1 .5 .5] [1 .5 .5] [1 .5 .5] };
        uilist = {...
                  { 'style' 'text'       'string' 'Channels to Score:' } ...
                  { 'style' 'edit'       'string' 'ALL' 'tag' 'ChanList' } ...
                  { 'style' 'pushbutton' 'string' '...' 'callback' cbChanList } ...
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

        [~, ~, ~, Results] = inputgui( geometry, uilist, 'pophelp(''pop_ScoreERP'');', 'Score ERPs -- pop_ScoreERP()' );
        if isempty(Results); return; end

        %assign inputs from dialog box stored in cell array called result to appropriate variables
        Method = upper(Results.Method);
        Windows = parsetxt(Results.Windows);
        Prefix = Results.Prefix;
        Path = Results.RootPath;
        ChanList = parsetxt(Results.ChanList);
    end
    
    if rem(length(Windows),2)
        error('Windows must contain pairs (start end) of values\n');
    end
    
    [ChanList, ~] = MakeChanList( EEG, ChanList );
    
    if ischar(Windows{1}) %from GUI        
        for i = 1:length(Windows)
            Windows{i} = str2double(Windows{i});
        end
    end   
    
    Method = upper(Method);  %for consistency below
    
    fprintf('pop_ScoreERP(): Scoring %s response in fixed window\n', Method);  %displays message on screen that function is running 
    for w=1:2:(length(Windows)-1)  %Loop through different windows
        fprintf('Scoring %s in window: %0.2f - %0.2f ms\n', Method, Windows{w}, Windows{w+1});  %displays message on screen that function is running    
        %get index for start and end times
        [ AdjStartTime, IndexStartTime ] = AdjustTime( EEG, Windows{w});
        [ AdjEndTime, IndexEndTime ] = AdjustTime( EEG, Windows{w+1});
         
        Scores = [];  %initialize this level of structure to prepare for subfields below
        %loop to score trials within channels in ChanList
        for i = 1:length(ChanList)
            for j = 1:EEG.trials            
                %get event code and convert to string if needed
                if isnumeric(EEG.event(FindEvent0Index(EEG,j)).type)
                    EventCode =  num2str(EEG.event(FindEvent0Index(EEG,j)).type);
                else
                    EventCode =  EEG.event(FindEvent0Index(EEG,j)).type;
                end

                switch (Method)                
                    case 'MEAN'                           
                        VarName = ['ME' num2str(round(AdjStartTime)) '_' num2str(round(AdjEndTime)) '_' ChanList{i} '_' EventCode];                        
                        Scores.(VarName) = mean(EEG.data(GetChanNum(EEG,ChanList{i}),IndexStartTime:IndexEndTime,j));
                    case 'MAX'
                        VarName = ['MA' num2str(round(AdjStartTime)) '_' num2str(round(AdjEndTime)) '_' ChanList{i} '_' EventCode];
                        Scores.(VarName) = max(EEG.data(GetChanNum(EEG,ChanList{i}),IndexStartTime:IndexEndTime,j));
                    case 'MIN'
                        VarName = ['MI' num2str(round(AdjStartTime)) '_' num2str(round(AdjEndTime)) '_' ChanList{i} '_' EventCode];
                        Scores.(VarName) = min(EEG.data(GetChanNum(EEG,ChanList{i}),IndexStartTime:IndexEndTime,j));                    
                end
            end              
        end

        %add Scores field to EEG and max subfield label for this reduction
        Label = [Prefix upper(Method(1:2)) num2str(round(AdjStartTime)) '_' num2str(round(AdjEndTime))];
        EEG.scores.(Label) = Scores;
        
        %Append this set of scores to appropriate named file
        pop_ExportScores(EEG, Label, Path, 'Y');
    end
 
    %Return the string command for record of processing if desired
    Chans = sprintf('{\''%s\''', ChanList{1});
    for i = 2:length(ChanList)
        Chans = sprintf('%s \''%s\''', Chans, ChanList{i});
    end
    Chans = [Chans '}'];
    Wins = sprintf('[%s] ', num2str([Windows{:}])); 
    COM = sprintf('EEG = pop_ScoreERP(EEG, %s, %s, %s);', Chans, Method, Wins );
end