%Usage:   [EEG, COM] = pop_ScoreMovingWindow(EEG, Chan, SubEpoch, WindowWidth, Direction, Prefix, Path)
%Finds window (of user defined width) in trials within epoched file with
%the highest/lowest (dependinding on Direction) mean response and returns that mean and the start/end time of
%the window.
%
%Inputs:
%EEG: an epoched dataset
%Chan:    channel label to score.
%SubEpoch: Cell array with start and end times in ms within epoch to include for scoring
%WindowWidth: Width of window in ms for calculating mean
%Direction:  Search for 'max' or 'min' mean response.  Use min if searching
%     for negative response
%Prefix:  Prefix label for dat files that are exported (e.g., smwCRG_,
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
% Copyright (C) 2015  John J. Curtin, University of Wisconsin-Madison,
% jjcurtin@wisc.edu


function [EEG, COM] = pop_ScoreMovingWindow(EEG, Chan, SubEpoch, WindowWidth, Direction, Prefix, Path)
    
    COM = '[EEG, COM] = pop_ScoreMovingWindow(EEG);'; % these initializations ensure that the function will return something
              % if the user press the cancel button        
    
    % display help and error if EEG not provided
    if nargin < 1  %calls help if no arguments are provided to function
        pophelp('pop_ScoreMovingWindow');
        return
    end	              
              
    %error if file is not epoched 
    if isempty(EEG.epoch)
        error('pop_ScoreWindows() does not work on continuous files\n')
    end           
       
    % pop up window if other arguments not provided.  
    %NEED TO UPDATE
    if nargin < 7  %calls dialog box if less than 7 arguments are provided to function

        cbChan = ['tmpchanlocs = EEG(1).chanlocs;'...
                '[tmp tmpval] = pop_chansel({tmpchanlocs.labels}, ''withindex'', ''on'', ''selectionmode'', ''single'');'...
                'set(findobj(gcbf, ''tag'', ''ChanList''), ''string'',tmpval);'...
                'clear tmp tmpchanlocs tmpval'];         

        cbPath = ['[rp] = uigetdir([], ''Select Output Path'');'...   
                  'if ~(isequal(rp,0))' ...
                  '   set(findobj(''parent'', gcbf, ''tag'', ''RootPath''), ''string'', rp);'...
                  'end;'];              

        geometry = { [1 .5 .5] [1 .5 .5] [1 .5 .5] [1 .5 .5] [1 .5 .5] [1 .5 .5] };
        uilist = {...
                  { 'style' 'text'       'string' 'Channel to Score:' } ...
                  { 'style' 'edit'       'string' '' 'tag' 'Chan' } ...
                  { 'style' 'pushbutton' 'string' '...' 'callback' cbChan } ...
                  ...              
                  { 'style' 'text'       'string' 'Start/End Time (in ms) for portion of epoch to score (e.g., 1000 3000' } ...
                  { 'style' 'edit'       'string' '' 'tag' 'SubEpoch' } ...
                  { } ...
                  ...              
                  { 'style' 'text'       'string' 'Scoring Window Width (in ms)' } ...
                  { 'style' 'edit'       'string' '' 'tag' 'WindowWidth' } ...
                  { } ...    
                  ...
                  { 'style' 'text'       'string' 'Find minimum or maximum mean value (MIN, MAX)' } ...
                  { 'style' 'edit'       'string' 'MAX' 'tag' 'Direction' } ...
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
        Chan = Results.Chan;
        SubEpoch = parsetxt(Results.SubEpoch);
        WindowWidth = str2double(Results.WindowWidth);
        Direction = upper(Results.Direction);
        Prefix = Results.Prefix;
        Path = Results.OutPath;
        
        if length(SubEpoch) ~= 2
            error('SubEpoch must contain two values for start and end time of sub-epoch to score\n');
        end        
        if ischar(SubEpoch{1}) %from GUI
            SubEpoch{1} = str2double(SubEpoch{1});
            SubEpoch{2} = str2double(SubEpoch{2});
        end
    end
   
    if length(SubEpoch) ~= 2  %test outside of GUI as well
        error('SubEpoch must contain two values for start and end time of sub-epoch to score\n');
    end
    
    if ~(strcmpi(Direction,'MAX') || strcmpi(Direction,'MIN'))
        error('Direction (%s) must be either MIN or MAX\n', Direction);
    end
    
    ChanNum = GetChanNum( EEG, Chan );
    
    fprintf('pop_ScoreMovingWindow(): Scoring mean response in moving window across sub-epoch\n');  %displays message on screen that function is running 

    %get index for start and end times
    [ AdjStartTime, IndexStartTime ] = AdjustTime( EEG, SubEpoch{1});
    [ AdjEndTime, IndexEndTime ] = AdjustTime( EEG, SubEpoch{2});

    %convert WindowWidth from ms to samples
    WindowWidthSamples = WindowWidth * (EEG.srate/1000);
    
    if (IndexEndTime - IndexStartTime)< WindowWidthSamples  %check that there is at least one window within the SubEpoch
        error('SubEpoch width must be wider than WindowWidth\n');
    end
    
    Scores = struct('Trial', (1:EEG.trials)', 'EventCode', zeros(EEG.trials,1), 'WindowMean', zeros(EEG.trials,1), 'WindowStart', zeros(EEG.trials,1), 'WindowEnd', zeros(EEG.trials,1), 'Reject', zeros(EEG.trials,1)); 

    for i = 1:EEG.trials  %Insert event types.   Can be saved as either numeric or string in the event field but should always represent a number
        if isnumeric(EEG.event(FindEvent0Index(EEG,i)).type)
            Scores.EventCode(i) = EEG.event(FindEvent0Index(EEG,i)).type;
        else
            Scores.EventCode(i) = str2double(EEG.event(FindEvent0Index(EEG,i)).type);
        end
    end
   
    %Find window with max/min mean response within each trial/epoch
    for i = 1:EEG.trials
        
        %Calculate first window mean outside of loop as start value for later comparisons
        WindowMean = mean(squeeze(EEG.data(ChanNum,IndexStartTime:(IndexStartTime+(WindowWidthSamples-1)),i)));
        WindowStart = EEG.times(IndexStartTime);
        WindowEnd = EEG.times(IndexStartTime+(WindowWidthSamples-1));
        for j = (IndexStartTime+1):((IndexEndTime)-(WindowWidthSamples-1))  %now loop through remaining windows in SubEpoch i if they exist
            
            TmpMean = mean(squeeze(EEG.data(ChanNum,j:(j+(WindowWidthSamples-1)),i)));

            if strcmpi(Direction,'MAX') && TmpMean > WindowMean
                WindowMean = TmpMean;
                WindowStart = EEG.times(j);
                WindowEnd = EEG.times(j+(WindowWidthSamples-1));
            end

            if strcmpi(Direction, 'MIN') && TmpMean < WindowMean
                WindowMean = TmpMean;
                WindowStart = EEG.times(j);
                WindowEnd = EEG.times(j+(WindowWidthSamples-1));            
            end
        end
        Scores.WindowMean(i) = WindowMean;
        Scores.WindowStart(i) = WindowStart;
        Scores.WindowEnd(i) = WindowEnd;
    end
    
    %Reject field
    %0=not rejected, 1= auto reject, 2=manual reject
    if isempty(EEG.reject.rejmanual) %setup rejmanual if empty for use next
        EEG.reject.rejmanual = zeros(1,EEG.trials);
    end
    Scores.Reject = (FindRejects(EEG) + EEG.reject.rejmanual)';  %count rejmanual twice to get to 2.... Transpose to match structure of SCORES

    %add Scores field to EEG and max subfield label for this reduction
    Label = [Prefix num2str(round(AdjStartTime)) 'to' num2str(round(AdjEndTime)) '_' Direction, num2str(WindowWidth)];
    EEG.scores.(Label) = Scores;

    %Append this set of scores to appropriate named file
    pop_ExportScores(EEG, Label, Path, 'Y');

 
    %Return the string command for record of processing if desired
    COM = sprintf('EEG = pop_ScoreMovingWindow(EEG);');
end