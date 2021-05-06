%USAGE: [EEG, P] = pop_ProcessSet(EEG, Function, P, SubjectIndex, ParameterIndex)
%This function is the main workhorse for data processing by script.  It is a liaison
%between the individual pop functions and the parameter (P) file.  The P file provides information
%about the  parameters needed for any specific pop function.  The P file also tracks if subjects have been
%rejected and/or reduced already.  Finally the pop functions write output (via notes functions) back to 
%the P file with assistance from pop_ProcessSet.  
%
%
%INPUTS
%EEG: an EEG set file
%Function: A character string that matches the name of a pop function
%without the 'pop_' and the '()'.  It is case sensitive and should use TitleCase
%P: A parameter file
%SubjectIndex: Index of the current subject (row) in the Parameter file to obtain parameters
%ParameterIndex: Optional index to add onto parameter field names when the
%                same pop_function will be called multiple times in one 
%                reduction (e.g., SaveSet uses ssFile1, ssFile2, ssFile3, etc)
%
%OUTPUTS
%EEG:  new EEG set after application of pop function
%P: updated (possibly depending on pop function) parameter file
%
%see also eegplugin_PhysBox()
%
%
%
%This is a list of pop_ functions (and their required parameters) that have
%been implemented in pop_ProcessSet().  See nested functions in code and
%associated pop_ functions for more information about these parameters
%
%Add2Gnd
%       no parameters
%
%AppendNotes   
%     No parameters 
%
%AvgFigure
%     afFigChans
%
%AverageMastoid
%     amReference
%
%AverageWaveform
%    awInEvents
%    awOutEvents   
%    awMissing (includenan is default;  omitnan)
%
%ButterworthFilter
%        bfFilterType
%        bfFilterHz
%        bfFilterOrder 
%        bfNPasses (optional; default is omitted = 2)
%        bfBoundary (optional; default is omitted = [])
%
%Convert2Set  (MULTISET ONLY)
%       csFile
%       csDataType (set, int16, int32, sma, ant, dat)
%       csGain (for sma data type only)
%       csChanLabels (for sma data type only)
%       csTrigger (for ant data type only; on or off)
%
%ConvertEvents
%       no parameters
%
%CreateAvg
%       caAvgEvents
%       caAvgAccuracy (A, C, E; optional, otherwise default = A)
%       caFigChans    
%
%DeleteEpochs
%       deMethod (EVENTS, INDICES)
%       deEvents (required if method = EVENTS)
%       deIndices (required if method = INDICES)
%
%DiagnosticFigure
%       dfFiles
%       dfFigChan
%
%ExportNotes
%       enFile
%
%ExportScores
%       esScores
%
%ExtractEpochs
%       eeEpochEvents
%       eeEpochWin     
%
%Figure4Panel
%       fpFigChan
%       fpSameScale (optional; default is omitted = TRUE)
%
%Figure6Panel
%       fpFigChan
%       fpSameScale (optional; default is omitted = TRUE)
%
%ImportEvents
%       ieEventFile
%
%ImportResponses
%        irFilename
%
%LoadFig
%       lfFile
%
%LoadSet
%       lsFile
%
%MarkDeflection
%        mdDeflect
%        mdChans
%        mdWin   
%
%MarkEpoch
%        meTrials
%
%MarkMean
%        mmThresh
%        mmChans
%        mmWin       
%
%MarkThreshold
%       mtThresh
%       mtChans
%       mtWin
%
%QuantNoise
%       no parameters
%
%RecodeEvents
%       reOrigEvents
%       reNewEvents 
%
%RectifyChannels
%       rcChanList
%
%RejectBreaks
%       rbMaxDelay
%       rbBuffer
%
%RejectEpochs
%       no parameters
%
%RemoveBase
%       rbBaseWin
%
%RemoveBlinks
%       rbBlinkChan
%       rbBlinkDir
%       rbBlinkThresh
%       rbBlinkSlope
%       rbBlinkMinN
%       rbBlinkPerConsist  
%
%RemoveDC
%       no parameters
%
%RemoveEvents
%        reWindow                    
%        reFocalEvents
%        reRejectEvents
%        reDirection       
%
%ResponseEvents
%        reResponseOffset       
%
%SaveSet
%       ssFile
%
%ScoreERP
%       seChans
%       seMethod
%       seWins
%       seLabel (optional)
%
%ScoreMovingWindow
%       smwChan
%       smwSubEpoch
%       smwWindowWidth
%       smwDirection
%
%ScoreStartle
%       ssSTLChans
%       ssSTLWin
%       ssSTLEvents
%
%ScoreWindows
%       swChan
%       swMethod
%       swWins
%
%SelectChannels
%       scChanList

    
function [EEG, P] = pop_ProcessSet(EEG, Function, P, SubjectIndex, ParameterIndex)
    
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Set up Input Parameters
    COM = '[ EEG, P] = pop_ProcessSet( EEG );';

    if nargin < 1
        pophelp('pop_ProcessSet')
        return
    end
    
    if nargin < 5
        ParameterIndex = [];
    end
    
    if nargin < 4
        AllFunctions = sort({...
            'AverageMastoid' 'AverageWaveform' 'ButterworthFilter' 'Convert2Set' 'ConvertEvents' ...
            'CreateAvg' 'DeleteEpochs' 'ExportNotes' 'ExportScores' 'ExtractEpochs' ...
            'Add2Gnd' 'ImportEvents' 'ImportResponses' 'LoadFig' 'LoadSet' ...
            'MarkDeflection' 'MarkEpoch' 'MarkMean' 'MarkThreshold' ...
            'QuantNoise'  'RecodeEvents'  'RectifyChannels' 'RejectBreaks' 'RejectEpochs' ...
            'RemoveBase' 'RemoveBlinks'  'RemoveDC' 'RemoveEvents' 'ResponseEvents'  'ScoreERP' ...
            'ScoreStartle'  'ScoreWindows' 'SelectChannels'...       
        });
        FunctionList = AllFunctions{1};
        for i = 2:length(AllFunctions)
            FunctionList = [FunctionList '|' AllFunctions{i}];
        end
        
        geoh = {[1 1 1] [1 1 1] [1 1 1] [1 1 1] [1 1 1]};
        geov = [1 round(0.75*length(AllFunctions)) 1 1 1];
                                   
        ui = {...
        { 'style', 'text', 'string', 'EEG set' }...
        { 'style', 'edit', 'string', 'EEG', 'tag', 'EEG' } ... 
        {} ...            
        { 'style', 'text', 'string', ['Select Function:' repmat(10,1, round(0.75*length(AllFunctions))-1)]}...
        { 'style', 'listbox', 'string', FunctionList, 'tag', 'Function' } ... 
        {} ...
        ...
        { 'style', 'text', 'string', 'Parameter File' } ...
        { 'style', 'edit', 'string', 'P', 'tag', 'P'  } ...  
        {}...
        ...
        { 'style', 'text', 'string', 'Subject Index' } ...
        { 'style', 'edit', 'string', '1', 'tag', 'SubjectIndex'  } ...
        {}...
        ...
        { 'style', 'text', 'string', 'Parameter index (blank to ignore)' } ...
        { 'style', 'edit', 'string', '', 'tag', 'ParameterIndex'  } ...
        {}...
        };

        [a, b, c, Results] = inputgui('geometry', geoh, 'geomvert', geov, 'uilist', ui, 'title', 'pop_ProcessSet() parameters');
        if isempty(Results); return; end
        
        Function = AllFunctions{Results.Function};        
        EEG = eval(Results.EEG);
        P = eval(Results.P);
        SubjectIndex = str2double(Results.SubjectIndex); 
        ParameterIndex = str2double(Results.ParameterIndex);       
    end
    
  
 %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %Get general parameters needed for most functions
        
    %Get required parameters for ith subject
    SubID = strtrim(P.SubID(SubjectIndex,:));

    RawPath = strtrim(P.RawPath(SubjectIndex,:));
    InPath = strtrim(P.InPath(SubjectIndex,:));
    ReducePath = strtrim(P.ReducePath(SubjectIndex,:));
    OutPath = strtrim(P.OutPath(SubjectIndex,:)); 

    Prefix = strtrim(P.Prefix(SubjectIndex,:)); 

    Rejected = P.Rejected(SubjectIndex);  %Get current reject flag from P file

    Reduced = P.Reduced(SubjectIndex);    

    %create ReducePath if needed
    if ~exist(ReducePath,'dir')
        [Success, Message] = mkdir(ReducePath);
        if not(Success); error(Message); end; 
    end

    
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Apply function
        Proceed = ~Rejected && ~Reduced;  %Determine if this subject should be reduced
        
        if strcmp(Function, 'AppendNotes')  %will AppendNotes for rejected subjects if notes exist
            if Rejected && ~isempty(EEG) && isfield(EEG, 'notes')   %check that EEG exists and has notes
                Proceed = true;
            end
        end
        if strcmp(Function, 'ExportNotes')  %will ExportNotes for rejected subjects if notes exist
            if Rejected && ~isempty(EEG) && isfield(EEG, 'notes')   %check that EEG exists and has notes
                Proceed = true;
            end
        end  



    if Proceed
        
        try 
            eval([Function '();']);   %Call nested sub-function for specific pop function.  See bottom of this script
        catch err
            fprintf(2,'Error in pop_ProcessSet(): %s not supported for multiset processing\n', Function);
            rethrow(err)
        end
        
        if ~isempty(EEG)  %some functions do not take EEG (e.g., DiagnosticFigure)
            EEG = eeg_hist(EEG, COM);    %record function in history

            %Add SubID if needed
            if isempty(EEG.subject)
                EEG.subject = SubID;  
            end

            EEG = eeg_checkset( EEG );  %check file
        end
        
    else  %if Proceed = false
        fprintf('\n\n%s not applied to subject %s\n\n', Function, SubID);
    end
    
    
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Nested functions for calls to individual  pop_ functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Add2Gnd
    function Add2Gnd()   
        [EEG, COM] = pop_Add2Gnd( EEG, fullfile(OutPath, [Prefix 'GND.set']) );
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%AppendNotes
    function AppendNotes()
        P = pop_AppendNotes(P, EEG);
        P = pop_SaveParameters(P, false);   %suppress details on parameter to screen
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%AvgFigure
    function AvgFigure()      
        afFigChans = eval(strtrim(P.afFigChans(SubjectIndex,:)));
        [EEG, COM] = pop_AvgFigure(EEG, afFigChans, Prefix);         
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%AverageMastoid
    function AverageMastoid()        
        amReference = strtrim(P.amReference(SubjectIndex,:));
        [EEG, COM] = pop_AverageMastoid(EEG, amReference);         
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%AverageWaveform
    function AverageWaveform()   
        awInEvents = eval(strtrim(P.(['awInEvents' num2str(ParameterIndex)]) (SubjectIndex,:)));
        awOutEvents = eval(strtrim(P.(['awOutEvents' num2str(ParameterIndex)])(SubjectIndex,:)));  
        if isfield(P, ['awMissing' num2str(ParameterIndex)])  %test if exists for backward compatibility with earlier versions where parameter did not exist
            awMissing = lower(P.(['awMissing' num2str(ParameterIndex)])(SubjectIndex) ); %use lower in case user screws up case
        else
            awMissing = 'includenan';  %default if this parameter not provided for backward compatibility
        end        
        [EEG, COM] = pop_AverageWaveform(EEG,  awInEvents, awOutEvents, awMissing);
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ButterworthFilter
    function ButterworthFilter()        
        bfFilterType = strtrim(P.(['bfFilterType' num2str(ParameterIndex)])(SubjectIndex,:));
        bfFilterHz = P.(['bfFilterHz' num2str(ParameterIndex)])(SubjectIndex,:);
        if ischar(bfFilterHz)  %char if provided array for BP filter
            bfFilterHz = eval(bfFilterHz);
        end
        bfFilterOrder = P.(['bfFilterOrder' num2str(ParameterIndex)])(SubjectIndex); 
        
        if isfield(P, ['bfNPasses' num2str(ParameterIndex)])  %test if exists for backward compatibility with earlier versions where parameter did not exist
            bfNPasses = P.(['bfNPasses' num2str(ParameterIndex)])(SubjectIndex); 
        else
            bfNPasses = 2;  %default if this parameter not provided for backward compatibility
        end
        
        if isfield(P, ['bfBoundary' num2str(ParameterIndex)])  
            bfBoundary = P.(['bfBoundary' num2str(ParameterIndex)])(SubjectIndex); 
        else
            bfBoundary = [];  %defaults to no boundary event as expected for epoched file.  Fix warning?
        end
        
        if strcmpi(bfFilterType, 'LP')
                [EEG, COM] = pop_ButterworthFilter( EEG,  0, bfFilterHz, bfFilterOrder, bfNPasses, bfBoundary ); 
        end
        
        if strcmpi(bfFilterType, 'HP')
                [EEG, COM] = pop_ButterworthFilter( EEG,  bfFilterHz, 0, bfFilterOrder, bfNPasses, bfBoundary );
        end    
        
        if strcmpi(bfFilterType, 'BP')
                [EEG, COM] = pop_ButterworthFilter( EEG,  bfFilterHz{1}, bfFilterHz{2}, bfFilterOrder, bfNPasses, bfBoundary );
        end           
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Convert2Set  (MULTISET ONLY)
    function Convert2Set()
        csFile = strtrim(P.csFile(SubjectIndex,:));
        if strcmpi(csFile, 'NA')  %for cases where there is no leading study prefix ahead of SubID
            csFile = '';
        end
        csDataType = strtrim(P.csDataType(SubjectIndex,:));
        
        switch upper(csDataType)
            case 'SET'
                if exist(fullfile(InPath, [csFile SubID '.set']), 'file')
                    [EEG, COM] = pop_LoadSet( [csFile SubID '.set'], InPath);
                else %didnt find file.  Set temp reject code
                    fprintf(2,'\nWARNING: %s does not exist.  Subject auto-rejected\n', [InPath csFile SubID '.set']);
                    EEG = eeg_emptyset;
                    P.Rejected(SubjectIndex) = -1;  %auto-reject to prevent future processing steps from executing
                    RejectNote = 'Orig file not found';
                    P.RejectNotes = tdfCharAdjust(P.RejectNotes,RejectNote);  %check that char array is wide enough
                    P.RejectNotes(SubjectIndex,1:length(RejectNote)) = RejectNote;
                    P = pop_SaveParameters(P);  %save to disk immediately
                end
                    
            case {'INT16', 'INT32', 'CNT'}
                if exist(fullfile(InPath, [csFile SubID '.cnt']), 'file')
                    if strcmpi(csDataType,'CNT')
                        [EEG, COM] = pop_LoadCnt(SubID, [csFile SubID '.cnt'], InPath, 'auto');
                    else
                        [EEG, COM] = pop_LoadCnt(SubID, [csFile SubID '.cnt'], InPath, csDataType);
                    end
                else  %didnt find file.  Set temp reject code
                    fprintf(2, 'WARNING: \n%s does not exist.  Subject auto-rejected\n', [InPath csFile SubID '.cnt']);
                    EEG = eeg_emptyset;
                    P.Rejected(SubjectIndex) = -1; %auto-reject to prevent future processing steps from executing
                    RejectNote = 'Orig file not found';
                    P.RejectNotes = tdfCharAdjust(P.RejectNotes,RejectNote);  %check that char array is wide enough
                    P.RejectNotes(SubjectIndex,1:length(RejectNote)) = RejectNote;
                    P = pop_SaveParameters(P);
                end        
                
            case  'CURRY'
                if exist(fullfile(InPath, [csFile SubID '.dat']), 'file')
                    [EEG, COM] = pop_LoadCurry(SubID, [csFile SubID '.dat'], InPath);
                else  %didnt find file.  Set temp reject code
                    fprintf(2, 'WARNING: \n%s does not exist.  Subject auto-rejected\n', [InPath csFile SubID '.dat']);
                    EEG = eeg_emptyset;
                    P.Rejected(SubjectIndex) = -1; %auto-reject to prevent future processing steps from executing
                    RejectNote = 'Orig file not found';
                    P.RejectNotes = tdfCharAdjust(P.RejectNotes,RejectNote);  %check that char array is wide enough
                    P.RejectNotes(SubjectIndex,1:length(RejectNote)) = RejectNote;
                    P = pop_SaveParameters(P);
                end          
                
            case 'SMA'
                if exist(fullfile(InPath, [csFile SubID '.sma']), 'file')
                    csGain = P.csGain(SubjectIndex);   %get two additional parameters that only apply to SMA files (gain and chan labels)
                    csChanLabels = eval(strtrim(P.csChanLabels(SubjectIndex,:)));
                    [EEG, COM] = pop_LoadSma(SubID, [csFile SubID '.sma'], InPath, csGain, csChanLabels);
                else  %didnt find file.  Set temp reject code
                    fprintf(2, 'WARNING: \n%s does not exist.  Subject auto-rejected\n', [InPath csFile SubID csDataType]);
                    EEG = eeg_emptyset;
                    P.Rejected(SubjectIndex) = -1; %auto-reject to prevent future processing steps from executing
                    RejectNote = 'Orig file not found';
                    P.RejectNotes = tdfCharAdjust(P.RejectNotes,RejectNote);  %check that char array is wide enough
                    P.RejectNotes(SubjectIndex,1:length(RejectNote)) = RejectNote;
                    P = pop_SaveParameters(P);
                end                    
                
            case 'ANT'
                if exist(fullfile(InPath, [csFile SubID '.cnt']), 'file')  %NOTE: ANT files have .cnt extension
                    csTrigger = P.strtrim(P.csChanLabels(SubjectIndex,:));   %get  additional parameter that only applies to ANT files
                    [EEG, COM] = pop_LoadAnt(SubID, [csFile SubID '.cnt'], InPath, csTrigger);
                else  %didnt find file.  Set temp reject code
                    fprintf(2, 'WARNING: \n%s does not exist.  Subject auto-rejected\n', [InPath csFile SubID csDataType]);
                    EEG = eeg_emptyset;
                    P.Rejected(SubjectIndex) = -1; %auto-reject to prevent future processing steps from executing
                    RejectNote = 'Orig file not found';
                    P.RejectNotes = tdfCharAdjust(P.RejectNotes,RejectNote);  %check that char array is wide enough
                    P.RejectNotes(SubjectIndex,1:length(RejectNote)) = RejectNote;
                    P = pop_SaveParameters(P);
                end      

            case  'EGI'
                if exist(fullfile(InPath, [csFile SubID '.mff']), 'file')
                    [EEG, COM] = pop_LoadEGI(SubID, [csFile SubID '.dat'], InPath);
                else  %didnt find file.  Set temp reject code
                    fprintf(2, 'WARNING: \n%s does not exist.  Subject auto-rejected\n', [InPath csFile SubID '.mff']);
                    EEG = eeg_emptyset;
                    P.Rejected(SubjectIndex) = -1; %auto-reject to prevent future processing steps from executing
                    RejectNote = 'Orig file not found';
                    P.RejectNotes = tdfCharAdjust(P.RejectNotes,RejectNote);  %check that char array is wide enough
                    P.RejectNotes(SubjectIndex,1:length(RejectNote)) = RejectNote;
                    P = pop_SaveParameters(P);
                end                 
                
            otherwise
                error('DataType (%s) not recognized\n', DataType)
        end
        
        if ~P.Rejected(SubjectIndex)  %check if temp rejected above.  If not, finish up            
            EEG.setname = 'CON Set';                
            EEG = notes_Convert2Set(EEG);  %add notes about raw CON file 
        end
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ConvertEvents
    function ConvertEvents()
        [EEG, COM] = pop_ConvertEvents(EEG);         
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CreateAvg
    function CreateAvg()
        caAvgEvents = eval(strtrim(P.(['caAvgEvents' num2str(ParameterIndex)]) (SubjectIndex,:)));
        if isfield(P, ['caAvgAccuracy' num2str(ParameterIndex)])
            caAvgAccuracy = strtrim(P.(['caAvgAccuracy' num2str(ParameterIndex)]) (SubjectIndex,:));
        else
            caAvgAccuracy = 'A';
        end
        
        [EEG, COM] = pop_CreateAvg(EEG,  caAvgEvents, [], caAvgAccuracy, [], [], []);
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%DeleteEpochs
    function DeleteEpochs()
        deMethod = strtrim(P.deMethod(SubjectIndex,:));

        switch upper(deMethod)
            case 'EVENTS'
                deEvents = eval(strtrim(P.deEvents(SubjectIndex,:)));
                [EEG, COM] = pop_DeleteEpochs(EEG,  deMethod, deEvents, []);
        
            case 'INDICES'
                deIndices = eval(strtrim(P.deIndices(SubjectIndex,:)));
                [EEG, COM] = pop_DeleteEpochs(EEG,  deMethod, [], deIndices);         
            otherwise
                error('deMethod (%s) must be ''EVENTS'' or ''INDICES''\n', deMethod);
        end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Diagnostic Figure
    function DiagnosticFigure()
        if isfield(P, 'deFiles')  %to allow for previous incorrect specification of field name
            dfFiles = eval(strtrim(P.deFiles(SubjectIndex,:)));
            dfFigChan = strtrim(P.deFigChan(SubjectIndex,:));
        else
            dfFiles = eval(strtrim(P.dfFiles(SubjectIndex,:)));
            dfFigChan = strtrim(P.dfFigChan(SubjectIndex,:));    
        end
            

        fprintf('\nLoading files for diagnostic figure...\n');
        dfFilename = strtrim(P.(['ssFile' num2str(dfFiles{1})])(SubjectIndex,:));
        EEG1 = pop_loadset( 'filename', [Prefix dfFilename SubID '.set'], 'filepath', ReducePath); 
        
        if length(dfFiles) >1
            dfFilename = strtrim(P.(['ssFile' num2str(dfFiles{2})])(SubjectIndex,:));
            EEG2 = pop_loadset( 'filename', [Prefix dfFilename SubID '.set'], 'filepath', ReducePath);             
        end
        
        if length(dfFiles) >2
            dfFilename = strtrim(P.(['ssFile' num2str(dfFiles{3})])(SubjectIndex,:));
            EEG3 = pop_loadset( 'filename', [Prefix dfFilename SubID '.set'], 'filepath', ReducePath);             
        end        
        
        switch length(dfFiles)
            case 1
                pop_DiagnosticFigure(dfFigChan, Prefix, EEG1);
            case 2
                pop_DiagnosticFigure(dfFigChan, Prefix, EEG1, EEG2);
            case 3
                pop_DiagnosticFigure(dfFigChan, Prefix, EEG1, EEG2, EEG3);
        end
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ExportNotes
    function ExportNotes()
        enFile = strtrim(P.enFile(SubjectIndex,:));
        [EEG, COM] = pop_ExportNotes(EEG, fullfile(OutPath, enFile), 'Y');
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ExportScores
    function ExportScores()
        esScores = strtrim(P.esScores(SubjectIndex,:));
        [EEG, COM] = pop_ExportScores(EEG, esScores, OutPath, 'Y'); 
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ExtractEpochs
    function ExtractEpochs()
        eeEpochEvents = eval(strtrim(P.eeEpochEvents(SubjectIndex,:)));
        eeEpochWin = eval(strtrim(P.eeEpochWin(SubjectIndex,:)));       
        [EEG, COM] = pop_ExtractEpochs( EEG, eeEpochEvents, eeEpochWin, 0);  %Use Boundary = 0 as default
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Figure4Panel
    function Figure4Panel()
        fpFigChan = strtrim(P.fpFigChan(SubjectIndex,:));
        if isfield(P, 'fpSameScale')  %test if exists for backward compatibility with earlier versions where parameter did not exist
            tmp = strtrim(P.fpSameScale(SubjectIndex,:));
            if strcmpi(tmp,'false')
                fpSameScale = 0;
            end
            if strcmpi(tmp,'true')
                fpSameScale = 1;
            end
        else
            fpSameScale = 1;  
        end        
        [EEG, COM] = pop_Figure4Panel( EEG, fpFigChan, Prefix, 1, fpSameScale);
    end

% USE THIS CODE IF WE WANT FLEXIBILITY IN NAMING
%     function Figure4Panel()
%         fpFigChan = strtrim(P.fpFigChan(SubjectIndex,:)); %Find Channel        
%         fpFile = strtrim(P.(['fpFile' num2str(ParameterIndex)])(SubjectIndex,:)); %Find File name in Parameter File
%         if strcmpi(fpFile, 'NA')  %in case user wants no prefix on output file  name
%             fpFile = '';
%         end
%         [EEG, COM] = pop_Figure4Panel(EEG, fpFigChan, fpFile);
%     end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Figure6Panel
    function Figure6Panel()
        fpFigChan = strtrim(P.fpFigChan(SubjectIndex,:));
        if isfield(P, 'fpSameScale')  %test if exists for backward compatibility with earlier versions where parameter did not exist
            tmp = strtrim(P.fpSameScale(SubjectIndex,:));
            if strcmpi(tmp,'false')
                fpSameScale = 0;
            end
            if strcmpi(tmp,'true')
                fpSameScale = 1;
            end
        else
            fpSameScale = 1;  
        end
        [EEG, COM] = pop_Figure6Panel( EEG, fpFigChan, Prefix, 1, fpSameScale);
    end

% USE THIS CODE IF WE WANT FLEXIBILITY IN NAMING
%     function Figure6Panel()
%         fpFigChan = strtrim(P.fpFigChan(SubjectIndex,:)); %Find Channel        
%         fpFile = strtrim(P.(['fpFile' num2str(ParameterIndex)])(SubjectIndex,:)); %Find File name in Parameter File
%         if strcmpi(fpFile, 'NA')  %in case user wants no prefix on output file  name
%             fpFile = '';
%         end
%         [EEG, COM] = pop_Figure6Panel(EEG, fpFigChan, fpFile);
%     end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ImportEvents
    function ImportEvents()  
        ieEventFile = strtrim(P.ieEventFile(SubjectIndex,:));
        [EEG, COM] = pop_ImportEvents (EEG, [InPath ieEventFile  SubID '.dat']);
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ImportResponses
    function ImportResponses()  
        irFilename = strtrim(P.irFilename(SubjectIndex,:));   
        [EEG, COM] = pop_ImportResponses (EEG, [RawPath irFilename]);
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%LoadFig
    function LoadFig()        
        lfFile = strtrim(P.lfFile(SubjectIndex,:));
        COM = pop_LoadFig(fullfile(ReducePath, [lfFile SubID '.fig']) ,1, 1);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%LoadSet
    function LoadSet()        
        lsFile = strtrim(P.lsFile(SubjectIndex,:));
        [EEG, COM] = pop_LoadSet([lsFile SubID '.set'], ReducePath); 
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%MarkDeflection
    function MarkDeflection()         
        mdDeflect = P.mdDeflect(SubjectIndex,:);
        mdChans = eval(strtrim(P.mdChans(SubjectIndex,:)));
        mdWin = eval(strtrim(P.mdWin(SubjectIndex,:)));        

        [EEG, COM] = pop_MarkDeflection(EEG, mdChans, mdDeflect, mdWin, 0);  %Mark but dont reject     
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%MarkEpoch
    function MarkEpoch()         
        meTrials = eval(strtrim(P.(['meTrials' num2str(ParameterIndex)])(SubjectIndex,:)));       

        [EEG, COM] = pop_MarkEpoch(EEG, meTrials, 0);  %Mark but dont reject     
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%MarkMean
    function MarkMean()         
        mmThresh = eval(strtrim(P.mmThresh(SubjectIndex,:)));
        mmChans = eval(strtrim(P.mmChans(SubjectIndex,:)));
        mmWin = eval(strtrim(P.mmWin(SubjectIndex,:)));        

        [EEG, COM] = pop_MarkMean(EEG, mmChans, mmThresh{1}, mmThresh{2}, mmWin, 0);  %Mark but dont reject     
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%MarkThreshold
    function MarkThreshold()
        mtThresh = eval(strtrim(P.mtThresh(SubjectIndex,:)));
        mtChans = eval(strtrim(P.mtChans(SubjectIndex,:)));
        mtWin = eval(strtrim(P.mtWin(SubjectIndex,:))); 
        
        [EEG, COM] = pop_MarkThreshold(EEG, mtChans, mtThresh{1}, mtThresh{2},  mtWin, 0);  %Mark but dont reject     
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%QuantNoise
    function QuantNoise()
        [EEG, COM] = pop_QuantNoise(EEG, Prefix, ReducePath, 0 );   %call without display of fig 
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%RecodeEvents
    function RecodeEvents()
        reOrigEvents = eval(strtrim(P.reOrigEvents(SubjectIndex,:)));
        reNewEvents = eval(strtrim(P.reNewEvents(SubjectIndex,:)));        
        [EEG, COM] = pop_RecodeEvents(EEG, reOrigEvents, reNewEvents);  
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ReductionComplete (MULTISET ONLY)
    function ReductionComplete()
        P.Reduced(SubjectIndex) = 1;
        COM = 'ReductionComplete';
        P = pop_SaveParameters(P);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%RectifyChannels
    function RectifyChannels()
        rcChanList = eval(strtrim(P.rcChanList(SubjectIndex,:)));        

        [EEG, COM] = pop_RectifyChannels(EEG, rcChanList);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%RejectBreaks
    function RejectBreaks()
        rbMaxDelay = P.rbMaxDelay(SubjectIndex);
        rbBuffer = P.rbBuffer(SubjectIndex);
        
        [EEG, COM] = pop_RejectBreaks(EEG, rbMaxDelay, rbBuffer);
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%RejectEpochs
    function RejectEpochs()       
        [EEG, COM, nEpochs] = pop_RejectEpochs(EEG);
        
        
        if ~nEpochs  %no epochs returned after reject
            P.Rejected(SubjectIndex) = -1;   %auto-reject
            P.RejectNotes = tdfCharAdjust(P.RejectNotes,'AllEpochsRejected');  %check that char array is wide enough
            P.RejectNotes(SubjectIndex,1:length('AllEpochsRejected')) = 'AllEpochsRejected';
            P = pop_SaveParameters(P);            
        end        
        
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%RemoveBase
    function RemoveBase()
        rbBaseWin = eval(strtrim(P.rbBaseWin(SubjectIndex,:)));
        [EEG, COM] = pop_RemoveBase(EEG, rbBaseWin);  %convert to ms from s
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%RemoveBlinks
    function RemoveBlinks()
        rbBlinkChan = strtrim(P.rbBlinkChan(SubjectIndex,:));
        rbBlinkDir = strtrim(P.rbBlinkDir(SubjectIndex,:));
        rbBlinkThresh = P.rbBlinkThresh(SubjectIndex);
        rbBlinkSlope = P.rbBlinkSlope(SubjectIndex);
        rbBlinkMinN = P.rbBlinkMinN(SubjectIndex);
        rbBlinkPerConsist = P.rbBlinkPerConsist(SubjectIndex);        
        [EEG, COM, ~, ~, ~, ~, ~, ~, ErrorCode] = pop_RemoveBlinks(EEG,rbBlinkChan,rbBlinkDir,rbBlinkThresh, rbBlinkSlope, 400, rbBlinkMinN, rbBlinkPerConsist, Prefix, ReducePath);                             
        
        if ~strcmpi(ErrorCode, 'Success')  %error in blink correction,  Correction not applied
            P.Rejected(SubjectIndex) = -1;   %auto-reject
            P.RejectNotes = tdfCharAdjust(P.RejectNotes,ErrorCode);  %check that char array is wide enough
            P.RejectNotes(SubjectIndex,1:length(ErrorCode)) = ErrorCode;
            P = pop_SaveParameters(P);            
        end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%RemoveDC
    function RemoveDC()               
        [EEG, COM] = pop_RemoveDC(EEG);  
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ResponseEvents
    function ResponseEvents()
        reResponseOffset = P.reResponseOffset(SubjectIndex);        
        [EEG, COM] = pop_ResponseEvents(EEG, reResponseOffset);  
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%SaveSet
    function SaveSet()     
        ssFile = strtrim(P.(['ssFile' num2str(ParameterIndex)])(SubjectIndex,:));
        if strcmpi(ssFile, 'NA')  %in case user wants no prefix on output file  name
            ssFile = '';
        end
        [EEG, COM] = pop_SaveSet(EEG, [Prefix ssFile SubID '.set'], ReducePath);  
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ScoreERP
    function ScoreERP()
        seChans = eval(strtrim(P.(['seChans' num2str(ParameterIndex)])(SubjectIndex,:)));
        seMethod = strtrim(P.(['seMethod'  num2str(ParameterIndex)])(SubjectIndex,:));
        seWins = eval(strtrim(P.(['seWins'  num2str(ParameterIndex)])(SubjectIndex,:)));   
        if isfield(P, ['seLabel' num2str(ParameterIndex)]) 
            seLabel = strtrim(P.(['seLabel'  num2str(ParameterIndex)])(SubjectIndex,:));
        else
            seLabel = '';
        end
        
        [EEG, COM] = pop_ScoreERP(EEG, seChans, seMethod, seWins, [Prefix seLabel], OutPath);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ScoreMovingWindow
    function ScoreMovingWindow()

        smwChan = strtrim(P.smwChan(SubjectIndex,:));
        smwSubEpoch = eval(P.smwSubEpoch(SubjectIndex,:));
        smwWindowWidth = P.smwWindowWidth(SubjectIndex,:);   
        smwDirection = strtrim(strtrim(P.smwDirection(SubjectIndex,:)));   
        
        [EEG, COM] = pop_ScoreMovingWindow(EEG, smwChan, smwSubEpoch, smwWindowWidth, smwDirection, Prefix, OutPath);
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ScoreStartle
    function ScoreStartle()       

        ssSTLChans = eval(strtrim(P.ssSTLChans(SubjectIndex,:)));
        ssSTLWin = eval(strtrim(P.ssSTLWin(SubjectIndex,:)));
        ssSTLEvents = eval(strtrim(P.ssSTLEvents(SubjectIndex,:)));

        if length(ssSTLChans)==2
            [EEG, COM] = pop_ScoreStartle(EEG, ssSTLChans{1}, ssSTLChans{2}, ssSTLWin, ssSTLEvents, Prefix, OutPath);
        else
            [EEG, COM] = pop_ScoreStartle(EEG, ssSTLChans{1}, 'false', ssSTLWin, ssSTLEvents, Prefix, OutPath);
        end
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ScoreWindows
    function ScoreWindows()

        swChan = strtrim(P.swChan(SubjectIndex,:));
        swMethod = strtrim(P.swMethod(SubjectIndex,:));
        swWins = eval(strtrim(P.swWins(SubjectIndex,:)));      
        
        [EEG, COM] = pop_ScoreWindows(EEG, swChan, swMethod, swWins, Prefix, OutPath);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%SelectChannels
    function SelectChannels()
        scChanList = eval(strtrim(P.scChanList(SubjectIndex,:)));        
        [EEG, COM] = pop_select( EEG, 'channel',scChanList); 
    end

end





