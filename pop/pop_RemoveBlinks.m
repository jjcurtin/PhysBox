%pop_RemoveBlinks() - Removes eyeblink artifact in EEGLab dataset via
%Regression procedure based on Semlitsch et al. 1986 (version 16)
%
%Usage:   [EEG, COM, ECBlinks, Coeffs, MaxBlink, MaxDeflectTime, AveBlink, CorrectedAveBlink, ErrorCode] = pop_RemoveBlinks(EEG,EyeChanLabel,BlinkDir,Threshold, Slope, MSDur, MinBlinks, PerConsist, Prefix, Path)
%
%Inputs:
%EEG - a CNT dataset to be blink corrected
%
%EyeChanLabel- the channel label of the channel containing VEOG signal
%
%BlinkDir- The direction of the blink.  1= positive, -1= negative
%
%Threshold- Used to detect onset of blink.  This the the proportion of the
%max blink that will indicate the start of a blink epoch
%
%Slope- The min slope between start of epoch and 25% into the Blink Epoch
%to qualify as a blink ie, blinks should have relatively sharp increase at
%start of epoch.  This is measured as change per ms.  
%This is a new parameter not included in the Semlistch algorithm
%
%MSDur- Duration of the blink epoch in ms
%
%MinBlinks- Minimum number of blinks necessary to apply the correction
%
%PerConsist:  This parameter is minimum percentage of consistent
%point-by-point changes that should be in the same direction as the rising
%and falling slope to indicate that the deflection is a blink.  Default is
%.95.  May lower to include more blinks.  This is a new parameter not
%included in Semlistch and goes with the Slope parameter above.
%
%Prefix:  Prefix for Blink figure filename
%
%Path:  Path for Blink figure file name
%
%Outputs:
%EEG- blink corrected EEG set (eye channel is not altered)
%
%COM- String to record this processing step
%
%ECBlinks- this is a Points X Blinks+1 array.  The first column contains
%the blink used to determine Max Deflection.  The 2 - N remaining columns
%contain each blink used to calculate the average.
%
%Coeffs- This is a Channels X 1 vector that contains the blink coefficients
%
%MaxBlink- This is the size of the max blink used for blink detection
%
%AveBlink:  A channels X SampDur array with Average blink for that channel
%for all detected blinks
%
%CorrectedAveBlink:  A channels X SampDur array with Average blink for that channel
%for all detected blinks after blink correct.  Allows view of how well it
%worked.
%
%ErrorCode:  0= success, 1=No max blink found, 2= too few blinks detected; 
%NOTE: uses QuantSlope function in Curtin Toolbox
%
%Other variables
%AllBlinks is a 3 dimensional array (R X C X P) that contains all
%identified blinks for all channels.  Rows represent channels, columns represent
%samples, pages represent individual blinks.  The first page is the max blink that is used to determine
%threshold.  This blink is centered on its peak. It is not used to
%determine coefficients.  Instead it is made available to check the
%performance of the blink correction routine.  pages 2-N contain actual
%blinks that start at the point where value exceeds MaxDeflect*Threshold
%
% Copyright (C) 2006  John J. Curtin, University of Wisconsin-Madison,
% jjcurtin@wisc.edu

%Revision History
%12/05/2006 Released version1, JJC v1
%12/05/2006 Fixed small bug in sprintf format statement for COM, JJC v2
%12/06/2006 Revised COM to match format of other eeglab functions, JJC v3
%08/08/2007 Fixed bug with EyeChan being variable, Slopes that are negative
%and handled issues with blink identification when DC offsets exist, JJC v4
%08/10/2007 Major overhaul.  Changed to P/N for blink dir.  Centered blink window on blink maximum for all blinks.   Added rising and falling slope
%           criteria for max blink and all blinks, JJC v5
%08-24-2007 Added output to screen to indicate location of max blink, JJC v6
%10-27-2007 Fixed bug with slope calculations.  Now calculates slope as change per ms (which is samp rate independent), JJC, v7
%07-14,2008:  Changed method of finding max blink deflection and actual blinks. Now, the Rising and trailing slopes must be of a certain magnitude AND 95
%             95% consistent (consider making a parameter in future) in the same direction when point to point
%             difference scores are calculated, JJC, ABS, v8
%08-31-2008:  when fails to find enough blinks, it graphs max blink and blinks it finds, v9
%11-06-2009:  Changed Percent consistent to a parameter rather than hard coded as .95, v10
%11-22-2008:  Changed to use channel label, JJC, v11
%01-31-2009:  fixed bug related to using number rather than text for channel label, v12, JJC
%2010-01-29:  Function now returns max blink as final parameterm V13, JJC
%2010-07-12:  added correction for samprate to QuantSlope, V14, JJC
%2011-03-07:  added two new return matrices for checking: AveBlink, CorrectedAveBlink, v15, JJC
%2011-03-09:  Added ErrorCode and MaxDeflectTime to returned parameters.
%             No longer errors out on no max blink or too few blinks.   Use ErrorCode to
%             determine success, v15
%2011-04-11:  Fixed bug with CorrectedAveBlink, JJC, v16
%2011-05-06:  Modified calculation of Blink size to be max point vs. sampdur/2 points previousm JJC, v17
%2011-10-15:  major change to search routine for blinks to increase speed, JJC
%2011-12-01:  added notes even when too few blinks detected
%2012-02-01:  updated GUI, JJC
%
%TO DO?
%Consider adding max blink max size parameter?
 
function [EEG, COM, ECBlinks, Coeffs, MaxDeflect, MaxDeflectTime, AveBlink, CorrectedAveBlink, ErrorCode] = pop_RemoveBlinks(EEG,EyeChanLabel,BlinkDir,Threshold, Slope, MSDur, MinBlinks, PerConsist, Prefix, Path)
    fprintf('\npop_RemoveBlinks(): Removing blink artifact via regression method\n');
    
    %Initializations
    COM = '[EEG, COM, ECBlinks, Coeffs, MaxDeflect, MaxDeflectTime, AveBlink, CorrectedAveBlink, ErrorCode] = pop_RemoveBlinks(EEG);';
    ECBlinks = [];  %assign to empty array to prevent error on return
    AveBlink = [];   %assign to empty array to prevent error on return
    CorrectedAveBlink = [];  %assign to empty array to prevent error on return
    Coeffs = zeros(EEG.nbchan,1);  %assign in case of early return    
    ErrorCode = 'Success';   %Assume  no error to start    
    
    % display help if EEG not provided
    % ------------------------------------
    if nargin < 1
        pophelp('pop_RemoveBlinks');
        return
    end

    if ~isempty(EEG.epoch)
        error('pop_RemoveBlinks() does not work on epoched files')
    end
    
    %Can call without these parameters
    if nargin < 10
        Path = pwd;
    end
    if nargin < 9
        Prefix = '';
    end

    %NEED TO UPDATE TO INCLUDE PATH AND PREFIX WITH ABOVE DEFAULTS
    % pop up window if other parameters not provided
    if nargin < 8        
        cbButton = ['tmpchanlocs = EEG(1).chanlocs;'...
                            '[tmp tmpval] = pop_chansel({tmpchanlocs.labels}, ''selectionmode'', ''single'', ''withindex'', ''on'');'...
                            'set(findobj(gcbf, ''tag'', ''EyeChan''), ''string'',tmpval);'...
                            'clear tmp tmpchanlocs tmpval']; 

        geometry = {  [1 .5 .5] [1 .5 .5] [1 .5 .5] [1 .5 .5] [1 .5 .5] [1 .5 .5] [1 .5 .5]};

        uilist = { ...
                 { 'Style', 'text', 'string', 'Eyeblink Channel Label' } ...
                 { 'Style', 'edit', 'string', '', 'tag', 'EyeChan' } ...
                 { 'style' 'pushbutton' 'string'  '...', 'enable' fastif(isempty(EEG.chanlocs), 'off', 'on') ...
                   'callback', cbButton  } ...
                 ...
                 { 'style' 'text'       'string' 'Blink Direction (P or N)' } ...
                 { 'style' 'edit'       'string' 'N', 'tag' 'BlinkDir' } ...
                 { } ...
                 ...
                 { 'style' 'text'       'string' 'Blink Threshold' } ...
                 { 'style' 'edit'       'string' '.10' 'tag' 'Threshold' } ...
                 { } ...
                 ...
                 { 'style' 'text'       'string' 'Blink Slope' } ...
                 { 'style' 'edit'       'string' '2', 'tag' 'Slope' } ...
                 { } ...         
                 ...
                 { 'style' 'text'       'string' 'Blink Epoch (ms)' } ...
                 { 'style' 'edit'       'string' '400', 'tag' 'BlinkDur' } ...
                 { } ... 
                 ...
                 { 'style' 'text'       'string' 'Min Blinks' } ...
                 { 'style' 'edit'       'string' '20', 'tag' 'MinBlinks' } ...
                 { } ... 
                 ...
                 { 'style' 'text'       'string' 'Proportion Consistent Sample Change' } ...
                 { 'style' 'edit'       'string' '.95', 'tag' 'PerConsist' } ...
                 { } ...
                 };
     
        [op ud sh Results] = inputgui( geometry, uilist, 'pophelp(''pop_RemoveBliniks'');', 'Remove Blink Artifact -- pop_RemoveBlinks()' );
        if isempty(Results); return; end
                                           
        EyeChanLabel = Results.EyeChan;
        BlinkDir = upper(Results.BlinkDir);
        Threshold = str2double(Results.Threshold);
        Slope = abs(str2double(Results.Slope));  %later code assumes that slope is always listed as positive
        MSDur = str2double(Results.BlinkDur);
        MinBlinks = str2double(Results.MinBlinks);
        PerConsist = str2double(Results.PerConsist);
    end

    EyeChanNum = GetChanNum(EEG,EyeChanLabel);

    %Check that BlinkDir is either P or N
    if not (strcmpi(BlinkDir, 'P') || strcmpi(BlinkDir, 'N'))
        error('pop_RemoveBlinks:IncorrectBlinkDir', 'Blink Direction must be P or N');
    end

    SampDur = (MSDur / 1000) * EEG.srate;


    if strcmpi(BlinkDir, 'P')  
        BlinkChanData = EEG.data(EyeChanNum,:);
    else
        BlinkChanData = -1* EEG.data(EyeChanNum,:); 
    end
    
   
    %Coeffs(GetChanNum(EEG,EyeChanLabel),1) = 1;  %one in VEOG, 0 in all others to start.

    
    
    BlinkChange = zeros(1,length(BlinkChanData));
    for i= (round(SampDur/2+1)):(length(BlinkChanData) - round(SampDur/2));  %start in a half sample duration and end a half sample before end
        BlinkChange(i) = BlinkChanData(i) - BlinkChanData(i-round(SampDur/2));  %calc diff scores
    end
        
    
    %find the MAX DEFLECTION
    %criteria for this epoch are that it is the max deflection (point - preceeding point sampdur points back) that also has a rising slow between the 25% sampdur points preceeding and
    %itself >= Slope and a trailing slope between the max deflection and 25% sampdur points forward and itself of >= Slope (in other words steep rise and fall as well
    %as magnitude calculated as change per ms).  In addition, point to point change must be 95% in same direction (to avoid big noise with high
    %frequency change in window
    MoreBlinks = true;
    MaxDeflect = 0;
    MDI = 0;    
    while ~MDI && MoreBlinks  
        [PosMaxDeflect, PosMDI] = max(BlinkChange);
        if PosMaxDeflect  %only test if found non-zero deflection.  Otherwise, done        
            [MeanRS,PerConsistRS] = QuantSlope(BlinkChanData((PosMDI-round(SampDur/4)):PosMDI), EEG.srate);
            [MeanTS,PerConsistTS] = QuantSlope(BlinkChanData(PosMDI:(PosMDI+round(SampDur/4))), EEG.srate); 
            if (MeanRS >= Slope) && (MeanTS <= (Slope*-1)) && (PerConsistRS > PerConsist) && (PerConsistTS > PerConsist)
                     MaxDeflect = PosMaxDeflect;
                     MDI = PosMDI;
            else
                BlinkChange((PosMDI - round(SampDur/2)):(PosMDI + round(SampDur/2))) = 0;  %set to zero and go find next biggest change in while loop
            end
        else
            MoreBlinks=false;  %only 0's remaining blink change
        end
    end
   
    MaxDeflectTime = MDI/EEG.srate;
    fprintf('The max blink of %5.0f microvolts detected at %5.0f seconds\n', MaxDeflect, MaxDeflectTime);

    if MaxDeflect ==0  %failed to find a max blink that met criteria
        fprintf('WARNING: No blink met MaxBlinkDefect criteria\n\n');
        ErrorCode = 'Error: NoMaxBlink';
        EEG = notes_RemoveBlinks(EEG, [], Coeffs, MaxDeflect, MaxDeflectTime, [], [], ErrorCode, Prefix, Path);    %add notes to EEG 
        
        return        
    end

    %Save the max blink in the first page of AllBlinks.  Will be included later in ECBlinks for return for data checking
    AllBlinks(:,:,1) = EEG.data(:,round(MDI-(SampDur/2)):round(MDI+(SampDur/2)-1));

    % Start loop to EXTRACT BLINKS.  Criteria to find blink are:
    %   1. value => MaxDeflect*Threshold
    %   2. Mean point X Point Slope of line from itself to 25% of sampdur forward and back  >= than Slope
    %   3. The direction of the point by point change (instananeous slope) must be 95% consistent in the 25% rising and trailing windows

    BlinkChange = zeros(1,length(BlinkChanData));
    for i= (round(SampDur/2+1)):(length(BlinkChanData) - round(SampDur/2));  %start in a half sample duration and end a half sample before end
        BlinkChange(i) = BlinkChanData(i) - BlinkChanData(i-round(SampDur/2));  %calc diff scores
    end    
        
    BlinkIdx = 1; % first page is for max blink.  Pages 2 - N are for the N-1 blinks that will be used for average blink creation
    BlinkStartStop = zeros(3000,2); %used to save start and end values for all blinks.  Blinks X 2 (start, end).  Preallocate for 3000 blinks.
    BlinkFound = false;
    [PosBlink, PosBI] = max(BlinkChange);
    fprintf('Identifying individual blinks...\n')
    while PosBlink >= (MaxDeflect*Threshold)      

        [MeanRS,PerConsistRS] = QuantSlope(BlinkChanData((PosBI-round(SampDur/4)):PosBI), EEG.srate); 
        [MeanTS,PerConsistTS] = QuantSlope(BlinkChanData(PosBI:(PosBI+round(SampDur/4))), EEG.srate);
        %Check rising and trailing slopes and consistency of slopes
        if (MeanRS >= Slope) && (MeanTS <= (Slope*-1)) && (PerConsistRS > PerConsist) && (PerConsistTS > PerConsist)
            BlinkIdx = BlinkIdx + 1; %count blink     
            AllBlinks(:,:,BlinkIdx) = EEG.data(:,round(PosBI-(SampDur/2)):round(PosBI+(SampDur/2)-1));
            BlinkStartStop(BlinkIdx-1,:) = [round(PosBI-(SampDur/2))  round(PosBI+(SampDur/2)-1)];  
            BlinkFound = true;
        end
        BlinkChange((PosBI - round(SampDur/2)):(PosBI + round(SampDur/2))) = 0;  %remove that section 
        [PosBlink, PosBI] = max(BlinkChange);  %check for next blink
        if ~mod(BlinkIdx,10) && BlinkFound
            fprintf('%d...',BlinkIdx)
        end
        if ~mod(BlinkIdx,100) && BlinkFound
            fprintf('\n')
        end
        BlinkFound = false;
    end


    %Save info for blinks on EyeChanNum to return for data checking purposes.
    ECBlinks = reshape (AllBlinks(EyeChanNum,:,:),size(AllBlinks,2),size(AllBlinks,3));

    %Check that enough blinks were detected.
    if size (ECBlinks,2)-1 < MinBlinks
        fprintf('\nWARNING: Only %d blinks detected.  This does not exceed minimum criteria of %d blinks\n\n', size(ECBlinks,2)-1, MinBlinks);
        ErrorCode = 'Error: TooFewBlinks';
        EEG = notes_RemoveBlinks(EEG, ECBlinks, Coeffs, MaxDeflect, MaxDeflectTime, [], [], ErrorCode, Prefix, Path);    %add notes to EEG                     
        return
    else
        fprintf('\n%d blinks detected\n', size (ECBlinks,2)-1);
    end

    %Calculate AverageBlink for each channel by averaging across pages 2 to N
    AveBlink = mean(AllBlinks(:,:,2:end),3);   %this is also returned for checking purposes
    
    %Calculate coeffs; b = cov (EOG,EEG)/var(EOG)
    BlinkCov = cov(AveBlink');  %tranposed to make rows = samples, and columns = vars
    Coeffs = BlinkCov(:,EyeChanNum) / BlinkCov(EyeChanNum,EyeChanNum);  %this matrix is returned by function for data checking
    
    %Remove EOG from all channels;
    fprintf('Removing blink artifact from all channels...\n')
    ExpandCoeffs = repmat(Coeffs,1,EEG.pnts); % expand Channels X 1 to Channels X Points
    ExpandEyeChan = repmat(EEG.data(EyeChanNum,:),EEG.nbchan,1);  %Expand 1 X Points to Channels X Points
    EyeChanDataHold = EEG.data(EyeChanNum,:);  %hold to restore in a moment
    EEG.data(:,:) = EEG.data(:,:) - (ExpandCoeffs(:,:) .* ExpandEyeChan(:,:)); %corrected EEG = original EEG - b * EOG
    EEG.data(EyeChanNum,:) = EyeChanDataHold;  % restore blink channel for data checking later
    
    %Calculate corrected ave blinks for integrity check for correction
    BlinkStartStop = BlinkStartStop(1:(size (ECBlinks,2)-1),:);  %shrink array to only include num of blinks (was preallocated to 3000 rows)
    CorrectedBlinks = zeros(EEG.nbchan, SampDur, (size (ECBlinks,2)-1));  %preallocate
    for i = 1:(size (ECBlinks,2)-1)  %loop for total number of blinks
        CorrectedBlinks(:,:,i) = EEG.data(:,BlinkStartStop(i,1):BlinkStartStop(i,2));
        CorrectedAveBlink = mean(CorrectedBlinks,3);  %return for data checking        
    end
        
    
    EEG = notes_RemoveBlinks(EEG, ECBlinks, Coeffs, MaxDeflect, MaxDeflectTime, AveBlink, CorrectedAveBlink, ErrorCode, Prefix, Path);    %add notes to EEG 
    COM = sprintf('EEG = pop_RemoveBlinks(EEG, \''%s\'', \''%s\'', %3.2f, %d, %d, %d, %3.2f);', EyeChanLabel, BlinkDir, Threshold, Slope, MSDur, MinBlinks, PerConsist);           
end
