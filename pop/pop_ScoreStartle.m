%Usage:   [EEG, COM, STL] = pop_ScoreStartle(EEG, ORBLabel, PRBLabel, MSWin, Events, Prefix, RootPath)
%Score startle response in pre-defined window in epoched file
%
%Inputs:
%EEG: an epoched dataset
%ORBLabel: Channel labels for ORB channel
%PRBLabel: Channel label for PRB channel.  'false' to skip probe measurement.
%MSWin: Window borders in MS values (accurate to tenth of ms)
%Events:  Cell array with event codes to score
%Prefix:  Prefix added to the diagnositc figure
%RootPath:  Root path for saving DAT files.  Fig file saved in Reduce
%
%Outputs:
%EEG:  an EEG data structure with a new field called Scores.  Scores
%contains two subfields called STL20_100 (or whatever the start and end windows are) with its own fields and STLMean.
%STL20_100: A data structure with scores for each trial (in arrays) with following fields
     %Trial:  trial number
     %EventCode:  the event code
     %BaseMin:  minimum value from pre-probe baseline
     %BaseMax:  maximum value from pre-probe baseline
     %STLLat:  latency of STL peak response in ms
     %STLMag:  magnitude of peak response in microvolts
     %PRBLat:  latency of PRB voltage peak response in ms
     %PRBMag:  magnitude of PRB voltage peak response in microvolts     
     %NR:  No response trial (i.e. STLMag does not exceed max value in same direction from baseline
     %Reject:  Marked for rejection.  0 = No, 1= Auto marked; 2 = User marked
%STLMean : includes one row for aggregate scores by event code;  NOTE: THIS HAS BEEN REMOVED FOR NOW
%STL is returned and contains the STL20_100 structure
%COM: String to record this processing step
%
% See also: eeglab(). tdfread(), tdfwrite()
%
% Copyright (C) 2011  John J. Curtin, University of Wisconsin-Madison,
% jjcurtin@wisc.edu

%Revision History
%2011-08-17 Released version1, JJC v1
%2011-08-17 Corrected input arg order, minor bug fixes MJS
%2011-08-17 added PRB scoring for mag and latency, removed direction, moved SubID to start of arg list, changed PeakLat to STLLat JJC, v2
%2011-08-17 bug fixes, MJS
%2011-09-27: added message to command line to indicate where scores saved if called via GUI, JJC
%2011-09-28: added Scores field.  Removed SubID parameter.  Now returns EEG, JJC
%2011-11-02: Replaced STL with Prefix, Named STL field STLTrial.  Changed STLMean field to include latency, JJC
%2011-11-23:  rewrote assuming bad trials removed in previous processing step, JJC
%2011-01-02:  fixed bug with use of false for PrbLabel, JJC
%2015-07-29:  added reject to STL and removed stlmean calculations

function [EEG, COM, STL] = pop_ScoreStartle(EEG, ORBLabel, PRBLabel, MSWin, Events, Prefix, RootPath)

    fprintf('\npop_ScoreStartle(): Scoring Startle Epochs\n');  %displays message on screen that function is running

    COM = '[EEG, COM, STL] = pop_ScoreStartle(EEG )';  %Initialze COM in case of early function return         

    if nargin < 1  %calls help if no arguments are provided to function
        pophelp('pop_ScoreStartle');
        return
    end	

    if isempty(EEG.epoch)
        error('pop_ScoreStartle does not work on continuous files')
    end

    % pop up window if other arguments not provided
    % -------------
    if nargin < 7 
                
        cbEvents = ['if ~isfield(EEG.event, ''type'')' ...
                   '   errordlg2(''No type field'');' ...
                   'else' ...
                   '   tmpevent = EEG.event;' ...
                   '   if isnumeric(EEG.event(1).type),' ...
                   '        [tmps,tmpstr] = pop_chansel(unique([ tmpevent.type ]));' ...
                   '   else,' ...
                   '        [tmps,tmpstr] = pop_chansel(unique({ tmpevent.type }));' ...
                   '   end;' ...
                   '   if ~isempty(tmps)' ...
                   '       set(findobj(''parent'', gcbf, ''tag'', ''Events''), ''string'', tmpstr);' ...
                   '   end;' ...
                   'end;' ...
                   'clear tmps tmpevent tmpv tmpstr tmpfieldnames;' ];

        cbORB = ['tmpchanlocs = EEG(1).chanlocs;'...
                '[tmp tmpval] = pop_chansel({tmpchanlocs.labels}, ''withindex'', ''on'');'...
                'set(findobj(gcbf, ''tag'', ''ORB''), ''string'',tmpval);'...
                'clear tmp tmpchanlocs tmpval']; 

        cbPRB = ['tmpchanlocs = EEG(1).chanlocs;'...
                '[tmp tmpval] = pop_chansel({tmpchanlocs.labels}, ''withindex'', ''on'');'...
                'set(findobj(gcbf, ''tag'', ''PRB''), ''string'',tmpval);'...
                'clear tmp tmpchanlocs tmpval'];         

        cbPath = ['[rp] = uigetdir([], ''Select RootPath'');'...   
                  'if ~(isequal(rp,0))' ...
                  '   set(findobj(''parent'', gcbf, ''tag'', ''RootPath''), ''string'', rp);'...
                  'end;'];              

        geometry = { [1 1 .5] [1 1 .5] [1 1 .5] [1 1 .5] [1 1 .5] [1 1 .5] };
        uilist = {...
                  { 'style' 'text'       'string' 'ORB label:' } ...
                  { 'style' 'edit'       'string' 'ORB' 'tag' 'ORB' } ...
                  { 'style' 'pushbutton' 'string' '...' 'callback' cbORB } ...
                  ...
                  { 'style' 'text'       'string' 'PRB label (false if none):' } ...
                  { 'style' 'edit'       'string' 'PRB' 'tag' 'PRB' } ...
                  { 'style' 'pushbutton' 'string' '...' 'callback' cbPRB } ...
                  ...              
                  { 'style' 'text'       'string' 'STL events:' } ...
                  { 'style' 'edit'       'string' '' 'tag' 'Events' } ...
                  { 'style' 'pushbutton' 'string' '...' 'callback' cbEvents } ...
                  ...
                  { 'style' 'text'       'string' 'Scoring window [start, end] in ms' } ...
                  { 'style' 'edit'       'string' '20 100', 'tag' 'MSWin' } ...
                  { } ...
                  ...
                  { 'style' 'text'       'string' 'File/Variable name prefix' } ...
                  { 'style' 'edit'       'string'  'mSTL', 'tag' 'Prefix' } ...
                  {  } ...
                  ...
                  { 'style' 'text'       'string' 'RootPath for output files:' } ...
                  { 'style' 'edit'       'string' ' ' 'tag' 'RootPath' } ...
                  { 'style' 'pushbutton' 'string' '...' 'callback' cbPath } ...
                  };

        [op ud sh Results] = inputgui( geometry, uilist, 'pophelp(''pop_ScoreStartle'');', 'Score Startle -- pop_ScoreStartle()' );
        if isempty(Results); return; end

        ORBLabel = Results.ORB;
        PRBLabel = Results.PRB;
        MSWin = parsetxt(Results.MSWin);
        Prefix = Results.Prefix;
        Events = str2double(Results.Events);
        RootPath = [Results.RootPath '\'];        
    end     
    
    if ischar(MSWin{1}) %from GUI        
        MSStartTime = str2double(MSWin{1});
        MSEndTime = str2double(MSWin{2});
    else
        MSStartTime = MSWin{1};
        MSEndTime = MSWin{2};
    end        
    
    if iscell(Events)
        Events = cell2mat(Events);
    end
    
    %define and allocate data structure
    STL = struct('Trial', (1:EEG.trials)', 'EventCode', zeros(EEG.trials,1), 'BaseMin', zeros(EEG.trials,1), 'BaseMax', zeros(EEG.trials,1), 'STLLat', zeros(EEG.trials,1), 'STLMag', zeros(EEG.trials,1), 'PRBLat', zeros(EEG.trials,1), 'PRBMag', zeros(EEG.trials,1), 'NR', zeros(EEG.trials,1), 'Reject', zeros(EEG.trials,1)); 
   
    for i = 1:EEG.trials  %Insert event types.   Can be saved as either numeric or string in the event field but should always represent a number
        if isnumeric(EEG.event(FindEvent0Index(EEG,i)).type)
            STL.EventCode(i) = EEG.event(FindEvent0Index(EEG,i)).type;
        else
            STL.EventCode(i) = str2double(EEG.event(FindEvent0Index(EEG,i)).type);
        end
    end
    [ AdjStartTime, IndexStartTime ] = AdjustTime( EEG, MSStartTime);
    [ AdjEndTime, IndexEndTime ] = AdjustTime( EEG, MSEndTime);

     
    %STL Mag and STL Peak Latency
    ORBNum = GetChanNum(EEG,ORBLabel);
    [SM,SI] = max(EEG.data(ORBNum,IndexStartTime:IndexEndTime,:),[],2);
    SM = squeeze(SM);
    SI = squeeze(SI);
    SI = SI + IndexStartTime -1; %reference to full rather than reduced array indices
    MSI = EEG.times(SI);  %Change from index back to mstime
    STL.STLMag = SM;  %Insert STLMags
    STL.STLMag(STL.STLMag < 0) = 0;   %Set negative magnitude values to 0
    STL.STLLat = MSI'; %Insert latency (ms) .... Transpose to match structure of STL
    
    %PRB Mag and PRB latency
    if ~strcmpi(PRBLabel,'false')
        PRBNum = GetChanNum(EEG,PRBLabel);
        [PM,PI] = max(EEG.data(PRBNum,IndexStartTime:IndexEndTime,:),[],2);
        PM = squeeze(PM);
        PI = squeeze(PI);
        PI = PI + IndexStartTime -1; %reference to full rather than reduced array indices
        MPI = EEG.times(PI);  %Change from index back to mstime
        STL.PRBMag = PM;  %Insert PRBMags
        STL.PRBLat = MPI'; %Insert latency (ms) .... Transpose to match structure of STL        
    end

    %Base Min and Max
    Time0 = find(abs(EEG.times)< 100*eps);  %find < eps rather than ==0 to correct for floating point problems
    BaseMins = squeeze(min(EEG.data(ORBNum,1:Time0,:),[],2));
    BaseMaxs = squeeze(max(EEG.data(ORBNum,1:Time0,:),[],2));
    STL.BaseMin = BaseMins;
    STL.BaseMax = BaseMaxs;
    
    %NR code
    %if max deflection exceeds threshold    
    STL.NR = SM <= BaseMaxs;  %flag as No response if response <= base max
    
    %Reject code
    %0=not rejected, 1= auto reject, 2=manual reject
    if isempty(EEG.reject.rejmanual) %setup rejmanual if empty for use next
        EEG.reject.rejmanual = zeros(1,EEG.trials);
    end
    STL.Reject = (FindRejects(EEG) + EEG.reject.rejmanual)';  %count rejmanual twice to get to 2.... Transpose to match structure of STL
    
%     %Calcuate STL mean scores by event and other subject level info about startle
%     for i = 1:length(Events) %calculate mean of startle for each event type
%         if isnan(mean(STL.STLMag(STL.EventCode==Events(i))))
%             STLMean.([Prefix int2str(Events(i))]) = 'NA';
%         else
%             STLMean.([Prefix int2str(Events(i))]) = mean(STL.STLMag(STL.EventCode==Events(i)));
%         end
%     end       
    
    EEG.scores.([Prefix 'Trial' num2str(round(AdjStartTime)) '_' num2str(round(AdjEndTime))])  = STL;
%     EEG.scores.([Prefix 'Mean' num2str(round(AdjStartTime)) '_' num2str(round(AdjEndTime))]) = STLMean;
    
    EEG = notes_ScoreStartle(EEG, STL); 
    
    %Append trial level scores to appropriately named file in the rootpath
    EEG = pop_ExportScores(EEG, [Prefix 'Trial' num2str(round(AdjStartTime)) '_' num2str(round(AdjEndTime))], RootPath, 'Y');
    
    %Append mean level scores to appropriately named file in the rootpath
%     EEG = pop_ExportScores(EEG, [Prefix 'Mean' num2str(round(AdjStartTime)) '_' num2str(round(AdjEndTime))], RootPath, 'Y');          
        
    %Return the string command for record of processing if desired
    COM = sprintf('EEG = pop_ScoreStartle(EEG, \''%s\'', \''%s\'', %d, %d, \''%s\'',\''%s\'', [%s]);', ORBLabel, PRBLabel, AdjStartTime, AdjEndTime, Prefix, RootPath, num2str(Events));    
end

