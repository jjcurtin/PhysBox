%USAGE: [ P ] = pop_MultiSet( P, Function, ssFileIndex, OptParams  )   
%This function is designed to execute pop functions on all reduced 
%(and typically not rejected) subjects in a parameter file without the need to
%put it in a loop (in contrast to pop_ProcessSet).  This function is designed to
%be used at the command line (or by GUI) after primary processing is complete.
%It is only implemented for a subset of pop functions that are useful after primary processing
%at the command line.  For example, ScoreERP will likely be called many times as 
%you consider various windows and scoring methods.  Similarly LoadFig and ViewRejects
%are intended to be used after primary processing to check the validity of that processing.
%It is expected that additional necessary parameters will be passed to the pop function
%via the use of the OptParams parameter in pop_MultiSet().
%The functions that are implemented along with the parameters that need to be
%supplied via OptParams is provided below.
%As noted earlier, the specific pop function will generally be applied to
%all Reduced but not Rejected subjects in the P file.  Exceptions include
%ExportNotes and AppendNotes which will include Rejected subjects to the
%degree that notes exist for them.  LoadFig can take all or unchecked
%parameter as well
%
%INPUT PARAMETERS
%P:  A Parameter (P) file
%Function: A character string that matches the name of a pop function
%          without the 'pop_' and the '()'.  It is case sensitive and should use TitleCase
%ssFileIndex: This is the index of the ssFile field in the P file with the name of the EEG file 
%             required to execute this pop function.  It is not necessary for all pop functions as 
%             some (e.g., LoadFig) do not require an EEG file.
%OptParams:  This  is a cell array that allows input of any additional
%            parameters needed by the pop function.  As a cell aray, it is quite
%            flexible and can entries in this cell array can take varied forms.  See
%            below for details on the  requirements for any specific pop function
%
%OUTPUT PARAMETERS
%P: an updated (possibly) P file.  Currently, none of these fuctions update
%   P but it is included for consistency and use in scripting.
%
%see also pop_ProccesSet(), eegplugin_PhysBox()
%
%
%
%This is a list of pop_ functions (and their required parameters) that have
%been implemented for use in pop_MultiSet()
%
%Add2Gnd
%       ssFileIndex (indicates which ssFile field to obtain EEG AVG filename)
%
%AppendNotes   
%       ssFileIndex (indicates which ssFile field to obtain EEG filename with notes field to Append)
%
%DiagnosticFigure
%       OptParams contains {dfFiles  dfFigChan}
%
%ExportNotes
%       ssFileIndex (indicates which ssFile field to obtain EEG filename with notes field to Export)
%
%ExportScores
%       ssFileIndex (indicates which ssFile field to obtain EEG filename with scores field to Export)
%
%LoadFig
%       OptParams contains {Filename, WhichFiles} where Filename is a string to
%       indicate file name of fig file without SubID and .fig at the end
%       WhichFiles is a second (optional) string that is set to 'all' or 'unchecked' (default if blank) to
%       indicate if it should loop through all or only unchecked subjects
%
%ScoreERP
%       ssFileIndex (indicates which ssFile field to obtain EEG AVG filename to score ERP and add scores field)
%       OptParams contains {seChans  seMethod  seWins}
%
%ScoreMovingWindow
%       ssFileIndex (indicates which ssFile field to obtain EEG EPH or AVG filename to score moving windows and add scores field)
%       OptParams contains {smwChan, smwSubEpoch, smwWindowWidth, smwDirection}
%
%ScoreStartle
%       ssFileIndex (indicates which ssFile field to obtain EEG EPH filename to score STL and add scores field)
%       OptParams contains {ssSTLChans, ssSTLWin, ssSTLEvents};    
%
%ScoreWindows
%       ssFileIndex (indicates which ssFile field to obtain EEG EPH or AVG filename to score windows and add scores field)
%       OptParams contains {swChan, swMethod, swWins}
%
%ViewRejects
%       OptParams contains three booleans (ViewThreshold, ViewMean, ViewDeflect}
%       if OptParams is empty, default  is to set all values to 1



function [ P ] = pop_MultiSet( P, Function, ssFileIndex, OptParams  )   
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Set up Input Parameters

    if nargin < 1
        pophelp('pop_MultiSet')
        return
    end
    
    if nargin < 4
        OptParams = {};
    end
    if nargin < 3
        ssFileIndex = [];
    end

    
    if nargin < 2
        AllFunctions = sort({...
            'AppendNotes' 'ExportNotes' 'ExportScores' 'Add2Gnd' 'LoadFig'  ...
            'ViewRejects' 'ScoreERP' 'ScoreMovingWindow' 'ScoreStartle'  'ScoreWindows'...       
        });
        FunctionList = AllFunctions{1};
        for i = 2:length(AllFunctions)
            FunctionList = [FunctionList '|' AllFunctions{i}];
        end
        
        geoh = {[1 1 1] [1 1 1] [1 1 1] [1 1 1]};
        geov = [round(0.75*length(AllFunctions)) 1 1 1 1];
                                   
        ui = {...
        { 'style', 'text', 'string', ['Select Function:' repmat(10,1, round(0.75*length(AllFunctions))-1)]}...
        { 'style', 'listbox', 'string', FunctionList, 'tag', 'Function' } ... 
        {} ...
        ...
        { 'style', 'text', 'string', 'Parameter file' } ...
        { 'style', 'edit', 'string', 'P', 'tag', 'P'  } ...  
        {}...
        ...
        { 'style', 'text', 'string', 'ssFileIndex (blank to ignore)' } ...
        { 'style', 'edit', 'string', '', 'tag', 'ssFileIndex'  } ...
        {}...
        ...
        { 'style', 'text', 'string', 'Optional Parameters (empty to ignore)' } ...
        { 'style', 'edit', 'string', '{   }', 'tag', 'OptParams'  } ...
        {}...
        };

        [a b c Results] = inputgui('geometry', geoh, 'geomvert', geov, 'uilist', ui, 'title', 'pop_ProcessSets() parameters');
        if isempty(Results); return; end
        
        Function = AllFunctions{Results.Function};        
        P = eval(Results.P); 
        ssFileIndex = str2double(Results.ssFileIndex);
        OptParams = eval(Results.OptParams);        
    end
    
   
 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Initial processsing steps (execute once)

   %unique steps for ExportScores (delete previous SCORES so that it can be replaced by this new set
    if strcmp(Function, 'ExportScores')
        OutPath = strtrim(P.OutPath(1,:));  %assumes OutPath is the same for all subjects
        if exist(fullfile(OutPath, [OptParams{1} '.dat']), 'file')
            delete (fullfile(OutPath, [OptParams{1} '.dat']));  %Deletes previous text file b/c this will be fully recreated with all reduced subjects
        end
    end
    
    %unique steps for ExportNotes (delete previous NOTES so that it can be replaced by this new set
    if strcmp(Function, 'ExportNotes')
        OutPath = strtrim(P.OutPath(1,:));  %assumes OutPath is the same for all subjects
        if exist(fullfile(OutPath, OptParams{1}), 'file')
            delete (fullfile(OutPath, OptParams{1}));  %Deletes previous text file b/c this will be fully recreated with all reduced subjects
        end
    end    
    
    %unique steps for ScoreMovingWindow (delete previous SCORES dat files so that they can be replaced by this new set
    if strcmp(Function, 'ScoreMovingWindow')
        OutPath = strtrim(P.OutPath(1,:));  %assumes OutPath is the same for all subjects
        Prefix = strtrim(P.Prefix(1,:));     %assumes Prefix is same for all subjects    
        
        if isempty(OptParams)  %can be passed as OptParams or in Parameter file
            smwSubEpoch = strtrim(P.smwSubEpoch(1,:));  %assumes same for all subjects
            smwWindowWidth = eval(strtrim(P.smwWindowWidth(1,:))); %assumes same for all subjects
            smwDirection = eval(strtrim(P.smwDirection(1,:))); %assumes same for all subjects
        else
            smwSubEpoch =   OptParams{2};
            smwWindowWidth = OptParams{3};      
            smwDirection = OptParams{4};  
        end          
        
        smwDirection = upper(smwDirection);
        DatName = fullfile(OutPath, [Prefix num2str(smwSubEpoch{1}) 'to' num2str(smwSubEpoch{2}) '_' smwDirection, num2str(smwWindowWidth) '.dat']);
        if exist(DatName, 'file')
            delete (DatName);  %Deletes previous text file b/c this will be fully recreated with all reduced subjects
        end
    end    
    
    %unique steps for ScoreStartle (delete previous DAT files so that they can be replaced by this new
    if strcmp(Function, 'ScoreStartle')
        OutPath = strtrim(P.OutPath(1,:));  %assumes OutPath is the same for all subjects
        Prefix = strtrim(P.Prefix(1,:));  %assumes Prefix is same for all subjects
        if exist(fullfile(OutPath, [[Prefix 'Trial' num2str(OptParams{2}{1}) '_' num2str(OptParams{2}{2})] '.dat']), 'file')
            delete (fullfile(OutPath, [[Prefix 'Trial' num2str(OptParams{2}{1}) '_' num2str(OptParams{2}{2})] '.dat']));  %Deletes previous trials file b/c this will be fully recreated with all reduced subjects
        end
        %removed next lines for now
%         if exist(fullfile(OutPath, [[Prefix 'Mean' num2str(OptParams{2}{1}) '_' num2str(OptParams{2}{2})] '.dat']), 'file')
%             delete (fullfile(OutPath, [[Prefix 'Mean' num2str(OptParams{2}{1}) '_' num2str(OptParams{2}{2})] '.dat']));  %Deletes previous Means file b/c this will be fully recreated with all reduced subjects
%         end        
    end      
    
    %unique steps for ScoreWindows (delete previous SCORES dat files so that they can be replaced by this new set
    if strcmp(Function, 'ScoreWindows')
        OutPath = strtrim(P.OutPath(1,:));  %assumes OutPath is the same for all subjects
        Prefix = strtrim(P.Prefix(1,:));     %assumes Prefix is same for all subjects    
        
        if isempty(OptParams)  %can be passed as OptParams or in Parameter file
            swMethod = strtrim(P.swMethod(1,:));  %assumes same for all subjects
            swWins = eval(strtrim(P.swWins(1,:))); %assumes same for all subjects
        else
            swMethod =   OptParams{2};
            swWins = OptParams{3};            
        end          
        
        swMethod = upper(swMethod(1:2));
        for w=1:2:(length(swWins)-1)
            DatName = fullfile(OutPath, [Prefix swMethod(1:2) num2str(swWins{w}) '_' num2str(swWins{w+1}) '.dat']);
            if exist(DatName, 'file')
                delete (DatName);  %Deletes previous text file b/c this will be fully recreated with all reduced subjects
            end
        end
    end    
    
    %unique steps for ScoreERP (delete previous SCORES dat files so that they can be replaced by this new set
    if strcmp(Function, 'ScoreERP')
        OutPath = strtrim(P.OutPath(1,:));  %assumes OutPath is the same for all subjects
        Prefix = strtrim(P.Prefix(1,:));     %assumes Prefix is same for all subjects    
        
        if isempty(OptParams)  %can be passed as OptParams or in Parameter file
            seMethod = strtrim(P.seMethod(1,:));  %assumes same for all subjects
            seWins = eval(strtrim(P.seWins(1,:))); %assumes same for all subjects
        else
            seMethod =   OptParams{2};
            seWins = OptParams{3};            
        end          
        
        seMethod = upper(seMethod(1:2));
        for w=1:2:(length(seWins)-1)
            DatName = fullfile(OutPath, [Prefix seMethod(1:2) num2str(seWins{w}) '_' num2str(seWins{w+1}) '.dat']);
            if exist(DatName, 'file')
                delete (DatName);  %Deletes previous text file b/c this will be fully recreated with all reduced subjects
            end
        end
    end       
    
    
    %unique steps for Add2Gnd (delete previous GND so that it can be replaced by all reduced files in one step
    if strcmp(Function, 'Add2Gnd')
        OutPath = strtrim(P.OutPath(1,:));  %assumes OutPath is the same for all subjects
        Prefix = strtrim(P.Prefix(1,:));      %assumes prefix is same for all subjects
        if exist(fullfile(OutPath, [Prefix 'GND.set']), 'file')
            delete (fullfile(OutPath, [Prefix 'GND.set']));  %Deletes previous GND file b/c this will be fully recreated with all reduced subjects
        end
    end  
    
 %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %Loop for each subject/row in parameter file
    nSets = CountSets(P);
    for i=1:nSets
        
        %Get required parameters for ith subject
        SubID = strtrim(P.SubID(i,:));
        
        RawPath = strtrim(P.RawPath(i,:));
        InPath = strtrim(P.InPath(i,:));
        ReducePath = strtrim(P.ReducePath(i,:));
        OutPath = strtrim(P.OutPath(i,:)); 
        
        Prefix = strtrim(P.Prefix(i,:)); 
        
        Rejected = P.Rejected(i);  %Get current reject flag from P file
        Reduced = P.Reduced(i);  %Get current Reduced flag from P file
                   
        if ~isempty(ssFileIndex)
            if strcmpi(strtrim(P.(['ssFile' num2str(ssFileIndex)])(i,:)),'NA')  %if file name has no leading characters
                Filename = '';
            else
                Filename = strtrim(P.(['ssFile' num2str(ssFileIndex)])(i,:));
            end
        end
                              
        %create ReducePath if needed
        if ~exist(ReducePath,'dir')
            [Success, Message] = mkdir(ReducePath);
            if not(Success); error(Message); end; 
        end      
                
                
        Proceed = ~Rejected && Reduced;  %Determine if this subject should be reduced
        
        if strcmp(Function, 'AppendNotes')  %will AppendNotes for rejected subjects if notes exist
            if Rejected
                Proceed = true;
            end
        end
        if strcmp(Function, 'ExportNotes')  %will ExportNotes for rejected subjects if notes exist
            if Rejected
                Proceed = true;
            end
        end        
        
        if strcmp(Function, 'LoadFig')  %will not LoadFig if checked and set to unchecked via OptParams
            if (length(OptParams) == 1 || strcmpi(OptParams{2}, 'unchecked')) && P.Checked(i)
                Proceed = false;
            end
        end        
        
        if Proceed
            try 
                eval([Function '();']);   %Call sub-function for specific pop function.  See bottom of this script
            catch err
                fprintf(2,'Error in pop_MultiSet(): %s not supported for multiset processing\n', Function);
                rethrow(err)
            end
                               
            if SaveSet  %for each subject for all functions that have changed data
                EEG = eeg_hist(EEG, COM);    %record function in history

                %Save file
                EEG = eeg_checkset( EEG );  
                [EEG, COM] = pop_saveset(EEG, 'filename', [Prefix Filename SubID '.set'], 'filepath', ReducePath, 'savemode', 'onefile');    
            end
            
            
        else  %if Proceed = false
            fprintf('\n\n%s not applied to subject %s\n\n', Function, SubID);
        end
    end

 %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %Final Processing Steps (Execute once)
    
    %unique steps for Add2Gnd
    if strcmp(Function, 'Add2Gnd')
        pop_SaveParameters(P);
    end  
    
    %unique steps for AppendNotes
    if strcmp(Function, 'AppendNotes')
        pop_SaveParameters(P);
    end      


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Nested functions for calls to individual  pop_ functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Add2Gnd
    function Add2Gnd()
        SaveSet = true;  %updated warning message for Add2GndNotes
        fprintf('\npop_MultiSet(): Adding Average (AVG) set for %s to Grand Average (GND) set\n', SubID);
        EEG = pop_loadset( 'filename', [Prefix Filename SubID '.set'], 'filepath', ReducePath);
               
        [EEG, COM] = pop_Add2Gnd( EEG, fullfile(OutPath, [Prefix 'GND.set']) );       %EEG updated with new notes
        P = pop_AppendNotes(P, EEG);
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%AppendNotes
    function AppendNotes()
        SaveSet = false;  %No changes to SET file 
        fprintf('\npop_MultiSet(): Appending notes to Parameter file for %s\n', SubID);
        
        FileIndex = ssFileIndex;
        FileOpen = false;
        while FileIndex > 0 && ~FileOpen  %loop back looking for a file that might have notes
            if strcmpi(strtrim(P.(['ssFile' num2str(FileIndex)])(i,:)),'NA')  %if file name has no leading characters
                Filename = '';
            else
                Filename = strtrim(P.(['ssFile' num2str(FileIndex)])(i,:));
            end            
            if exist(fullfile(ReducePath, [Prefix Filename SubID '.set']), 'file') 
                EEG = pop_loadset( 'filename', [Prefix Filename SubID '.set'], 'filepath', ReducePath);
                FileOpen = true;
            else
                FileIndex = FileIndex -1;
            end
        end
        
        
        %Need to check that file was made b/c this includes all subjects (even rejects, etc)
        if FileOpen
            P = pop_AppendNotes(P, EEG);
        else
            fprintf('No notes available to append for %s\n', SubID) 
        end
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Diagnostic Figure
    function DiagnosticFigure()
        SaveSet = false;      %no need to save SET file (no changes)
        deFiles = OptParams{1};
        deFigChan = OptParams{2};
        
        fprintf('\npop_MultiSet(): Creating Diagnostic Figure for %s\n', SubID);       
                
        Filename = strtrim(P.(['ssFile' num2str(deFiles{1})])(i,:));
        EEG1 = pop_loadset( 'filename', [Prefix Filename SubID '.set'], 'filepath', ReducePath); 
        
        if length(deFiles) >1
            Filename = strtrim(P.(['ssFile' num2str(deFiles{2})])(i,:));
            EEG2 = pop_loadset( 'filename', [Prefix Filename SubID '.set'], 'filepath', ReducePath);             
        end
        
        if length(deFiles) >2
            Filename = strtrim(P.(['ssFile' num2str(deFiles{3})])(i,:));
            EEG3 = pop_loadset( 'filename', [Prefix Filename SubID '.set'], 'filepath', ReducePath);             
        end        
        
        switch length(deFiles)
            case 1
                pop_DiagnosticFigure(deFigChan, Prefix, EEG1);
            case 2
                pop_DiagnosticFigure(deFigChan, Prefix, EEG1, EEG2);
            case 3
                pop_DiagnosticFigure(deFigChan, Prefix, EEG1, EEG2, EEG3);
        end
        
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ExportNotes
    function ExportNotes()
        SaveSet = false;      %no need to save SET file (no changes)
        fprintf('\npop_MultiSet(): Exporting NOTES field for %s to %s\n', SubID, [OutPath OptParams{1}]);
        
        FileIndex = ssFileIndex;
        FileOpen = false;
        while FileIndex > 0 && ~FileOpen  %loop back looking for a file that might have notes
            if strcmpi(strtrim(P.(['ssFile' num2str(FileIndex)])(i,:)),'NA')  %if file name has no leading characters
                Filename = '';
            else
                Filename = strtrim(P.(['ssFile' num2str(FileIndex)])(i,:));
            end            
            if exist(fullfile(ReducePath, [Prefix Filename SubID '.set']), 'file') 
                EEG = pop_loadset( 'filename', [Prefix Filename SubID '.set'], 'filepath', ReducePath);
                FileOpen = true;
            else
                FileIndex = FileIndex -1;
            end
        end
        
        
        %Need to check that file was made b/c this includes all subjects (even rejects, etc)
        if FileOpen
            P = pop_AppendNotes(P, EEG);
        else
            fprintf('No notes available to export for %s\n', SubID) 
        end
        
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ExportScores
    function ExportScores()
        SaveSet = false;  %no need to save SET.  No changes
        fprintf('\npop_MultiSet(): Exporting %s SCORES field(s) for %s to %s\n', SubID, fullfile(OutPath, [OptParams{1} '.dat']));
        EEG = pop_loadset( 'filename', [Prefix Filename SubID '.set'], 'filepath', ReducePath);
        
        [EEG, COM] = pop_ExportScores(EEG, OptParams{1}, OutPath, 'Y'); 
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%LoadFig
    function LoadFig()
        SaveSet = false;  %No SET file to save
        
        fprintf('\npop_MultiSet(): Loading %s figure for SubID: %s\n', OptParams{1}, SubID);
                            
        COM = pop_LoadFig(fullfile(ReducePath, [OptParams{1} SubID '.fig']) ,1, 1);
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ScoreERP
    function ScoreERP()
        SaveSet = true;
        
        if isempty(OptParams)
            seChans = eval(strtrim(P.seChans(i,:)));
            seMethod = strtrim(P.seMethod(i,:));
            seWins = eval(strtrim(P.seWins(i,:)));
        else
            seChans = OptParams{1}; 
            seMethod =   OptParams{2};
            seWins = OptParams{3};            
        end        
        
        fprintf('\npop_MultiSet(): Scoring ERPs by %s for %s\n', seMethod, SubID);
        EEG = pop_loadset( 'filename', [Prefix Filename SubID '.set'], 'filepath', ReducePath);
           
        [EEG, COM] = pop_ScoreERP(EEG, seChans, seMethod, seWins, Prefix, OutPath);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ScoreMovingWindow
    function ScoreMovingWindow()
        SaveSet = true;
        
        smwChan = OptParams{1}; 
        smwSubEpoch =   OptParams{2};
        smwWindowWidth = OptParams{3};
        smwDirection = OptParams{4};
        
        fprintf('\npop_MultiSet(): Scoring mean moving window for %s\n', SubID);
        
        EEG = pop_loadset( 'filename', [Prefix Filename SubID '.set'], 'filepath', ReducePath);        
        [EEG, COM] = pop_ScoreMovingWindow(EEG, smwChan, smwSubEpoch, smwWindowWidth, smwDirection, Prefix, OutPath);
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ScoreStartle
    function ScoreStartle()
        SaveSet = true;        
        fprintf('\npop_MultiSet(): Scoring STL for %s\n', SubID);
        
        ssSTLChans = OptParams{1};  %ORB and PRB labels
        ssSTLWin =   OptParams{2};
        ssSTLEvents = OptParams{3};            
        
        EEG = pop_loadset( 'filename', [Prefix Filename SubID '.set'], 'filepath', ReducePath);        
        [EEG, COM] = pop_ScoreStartle(EEG, ssSTLChans{1}, ssSTLChans{2}, ssSTLWin, ssSTLEvents, Prefix, OutPath);
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ScoreWindows
    function ScoreWindows()
        SaveSet = true;
        
        swChan = OptParams{1}; 
        swMethod =   OptParams{2};
        swWins = OptParams{3};                   
        
        fprintf('\npop_MultiSet(): Scoring %s in window(s) for %s\n', swMethod, SubID);
        
        EEG = pop_loadset( 'filename', [Prefix Filename SubID '.set'], 'filepath', ReducePath);        
        [EEG, COM] = pop_ScoreWindows(EEG, swChan, swMethod, swWins, Prefix, OutPath);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ViewRejects
    function ViewRejects()
        SaveSet = false;
        fprintf('\npop_MultiSet(): Viewing Retained/Rejected Epochs for %s\n', SubID);
        
        EEG = pop_loadset( 'filename', [Prefix Filename SubID '.set'], 'filepath', ReducePath);
        if isempty(OptParams)
            ViewThreshold = 1;
            ViewMean = 1;
            ViewDeflect = 1;
            ViewManual = 1;
        else
            ViewThreshold = OptParams{1};
            ViewMean = OptParams{2};
            ViewDeflect = OptParams{3};
            ViewManual = OptParams{4};
        end
        [EEG, COM] = pop_ViewRejects(EEG, ViewThreshold, ViewMean, ViewDeflect, ViewManual);
    end        
       
end





