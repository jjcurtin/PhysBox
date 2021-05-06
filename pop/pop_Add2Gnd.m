%USAGE: [ AvgEEG, COM ] = pop_Add2Gnd( AvgEEG, GndPathFile )
%Adds an Average (AVG) set file to a Grand Average (GND) set file.
%Saves the GND set and also saves an updated copy of AVG with agWarnMsg
%added to the notes field (via call to notes function).  
%AgWarnMsg will note if there was any issue adding 
%The AVG set to the GND set.  Functgion returns this updated AVG set as well
%
%INPUTS
%AvgEEG: An AVG set file.   This EEG set will contain average epochs by
%        event type.  Alternatively, this can be the path and filename of an Avg
%        EEG set file
%GndPathFile:  The path and filename of a Grand Average (GND) set.
%
%OUTPUTS
%AvgEEG:  The updatedAVG EEG set.  This will have an addition to notes
%         field.  This set file is also saved to disk
%COM:   The COM for EEG processing history

%Revision history
%2012-01-31: released, JJC
%2012-02-08:  adds warning in notes and returns rather than error when
%             most problems encountered, JJC
%2012-02-15:  updated help and changed parameter name to GndPathFile, JJC

function [ AvgEEG, COM ] = pop_Add2Gnd( AvgEEG, GndPathFile )
    COM = '[ AvgEEG, COM ] = pop_Add2Gnd();';
    
    if nargin < 2
        avgButton = ['[AvgFilename AvgFilepath] = uigetfile(''*.set'', ''Open AVG Set File'');'...   
                  'if ~(isequal(AvgFilename,0) || isequal(AvgFilepath,0))' ...
                  '   AvgEEG = [AvgFilepath AvgFilename];' ...
                  '   set(findobj(''parent'', gcbf, ''tag'', ''AvgFile''), ''string'', AvgEEG);'...
                  'end;'];  
              
        gndButton = ['[GndFilename GndFilepath] = uiputfile(''*.set'', ''Open GND Set File'');'...   
                  'if ~(isequal(GndFilename,0) || isequal(GndFilepath,0))' ...
                  '   GndEEG = [GndFilename GndFilepath];' ...
                  '   set(findobj(''parent'', gcbf, ''tag'', ''GndFile''), ''string'', GndEEG);'...
                  'end;'];              

        geometry = { [1 1.5 .5] [1 1.5 .5]};
        uilist = { ...
                   { 'style' 'text'       'string' 'AVG Filename (or EEG):'               } ... 
                   { 'style' 'edit'       'string' ''                'tag' 'AvgFile' } ...                   
                   { 'style' 'pushbutton' 'string' 'Select File'     'callback' avgButton    } ... 
                   ...
                   { 'style' 'text'       'string' 'GND Filename:'               } ... 
                   { 'style' 'edit'       'string' ''                'tag' 'GndFile' } ...                   
                   { 'style' 'pushbutton' 'string' 'Select File'     'callback' gndButton    } ... 
                 };

        [op ud sh Results] = inputgui( geometry, uilist, 'pophelp(''pop_Add2Gnd'')', 'Add AVG to Grand Average - pop_Add2Gnd()');
        if isempty(Results); return; end  
        
        if (strcmp(Results.AvgFile, 'EEG'))
            AvgEEG = EEG;   %Take EEG from main workspace
        else
            AvgEEG = Results.AvgFile;
        end
        GndPathFile = Results.GndFile;
    end
        
    %open AvgEEG if needed
    if ~isstruct(AvgEEG)
        [AvgFilePath, AvgFileName, ext] = fileparts(AvgEEG);
        AvgFileName = [AvgFileName ext];
        AvgEEG = pop_LoadSet(AvgFileName, AvgFilePath);
    end
    
    %open GndEEG
    [GndFilePath, GndFileName, ext] = fileparts(GndPathFile);
    GndFileName = [GndFileName ext];        

    if exist(fullfile(GndFilePath, GndFileName), 'file')
        GndExists = true;
        GndEEG = pop_LoadSet(GndFileName, GndFilePath);
    else
        GndExists = false;
    end 

    fprintf('\npop_Add2Gnd(): Adding AVG to Grand Average(GND) %s\n', fullfile(GndFilePath, GndFileName));

    if ~GndExists  %if GND does not exist set it to AVG
        GndEEG = AvgEEG;
        
        GndEEG.N = 1;
        GndEEG.subject = {AvgEEG.subject};
        GndEEG.filename = GndFileName;
        GndEEG.filepath = GndFilePath;
        
        if isfield(GndEEG,'notes')
            GndEEG = rmfield(GndEEG,'notes');
        end
        if isfield(GndEEG, 'scores')
            GndEEG = rmfield(GndEEG,'scores');
        end
        GndEEG = rmfield(GndEEG,'urevent'); 
        
        GndEEG.event = rmfield(GndEEG.event,'count');
        GndEEG.event = rmfield(GndEEG.event,'varlabel');
        GndEEG.event = rmfield(GndEEG.event,'urevent');      
        GndEEG.epoch = rmfield(GndEEG.epoch,'eventcount');
        GndEEG.epoch = rmfield(GndEEG.epoch,'eventurevent');       
    
    else  %If GND does exist add AVG to it (weighed of course)
        if ismember(AvgEEG.subject,GndEEG.subject)
            fprintf(2, '\nError in pop_Add2Gnd(): Duplicate subject (%s) not added to GND\n\n', AvgEEG.subject);
            WarnMsg = 'duplicate SubID not added';
            AvgEEG = notes_Add2Gnd(AvgEEG, WarnMsg);
            AvgEEG.saved = 'no';
            pop_SaveSet(AvgEEG);   
            return
        end
        
       %Perform important consistency checks
        if ~(GndEEG.nbchan == AvgEEG.nbchan)
            fprintf(2, '\n\nError in pop_Add2Gnd(): ''nbchan'' field does not match across GND (%d) and current SET (%d)\n\n', GndEEG.nbchan,AvgEEG.nbchan); 
            WarnMsg = 'nbchan inconsistency';
            AvgEEG = notes_Add2Gnd(AvgEEG, WarnMsg);
            AvgEEG.saved = 'no';
            pop_SaveSet(AvgEEG);            
            return
        end 
        if ~(GndEEG.trials == AvgEEG.trials)
            fprintf(2, '\nError in pop_Add2Gnd(): ''trials'' field does not match across GND (%d) and current SET (%d)\n\n', GndEEG.trials,AvgEEG.trials);
            WarnMsg = 'trials inconsistency';
            AvgEEG = notes_Add2Gnd(AvgEEG, WarnMsg);
            AvgEEG.saved = 'no';
            pop_SaveSet(AvgEEG);              
            return
        end
            
        if ~(GndEEG.pnts == AvgEEG.pnts)
            fprintf(2, '\nError in pop_Add2Gnd(): ''pnts'' field does not match across GND (%d) and current SET (%d)\n\n', GndEEG.pnts,AvgEEG.pnts);
            WarnMsg = 'pnts inconsistency';
            AvgEEG = notes_Add2Gnd(AvgEEG, WarnMsg);
            AvgEEG.saved = 'no';
            pop_SaveSet(AvgEEG);              
            return
        end
        if ~(GndEEG.srate == AvgEEG.srate)
            fprintf(2, '\nError in pop_Add2Gnd(): ''srate'' field does not match across GND (%d) and current SET (%d)\n\n', GndEEG.srate,AvgEEG.srate);
            WarnMsg = 'srate inconsistency';
            AvgEEG = notes_Add2Gnd(AvgEEG, WarnMsg);
            AvgEEG.saved = 'no';
            pop_SaveSet(AvgEEG);              
            return
        end
        if ~(GndEEG.xmin == AvgEEG.xmin)
            fprintf(2, '\nError in pop_Add2Gnd(): ''xmin'' field does not match across GND (%d) and current SET (%d)\n\n', GndEEG.xmin,AvgEEG.xmin);
            WarnMsg = 'xmin inconsistency';
            AvgEEG = notes_Add2Gnd(AvgEEG, WarnMsg);
            AvgEEG.saved = 'no';
            pop_SaveSet(AvgEEG);              
            return
        end
        if ~(GndEEG.xmax == AvgEEG.xmax)
            fprintf(2, '\nError in pop_Add2Gnd(): ''xmax'' field does not match across GND (%d) and current SET (%d)\n\n', GndEEG.xmax,AvgEEG.xmax);
            WarnMsg = 'xmax inconsistency';
            AvgEEG = notes_Add2Gnd(AvgEEG, WarnMsg);
            AvgEEG.saved = 'no';
            pop_SaveSet(AvgEEG);              
            return
        end
        if min(GndEEG.times == AvgEEG.times)< 1
            fprintf(2, '\nError in pop_Add2Gnd(): ''times'' field does not match across GND and current SET\n\n');
            WarnMsg = 'times inconsistency';
            AvgEEG = notes_Add2Gnd(AvgEEG, WarnMsg);
            AvgEEG.saved = 'no';
            pop_SaveSet(AvgEEG);              
            return
        end

        %Check that channel labels and order match
        for j=1:GndEEG.nbchan
            if ~strcmp(GndEEG.chanlocs(j).labels, AvgEEG.chanlocs(j).labels)
                fprintf(2, '\nError in pop_Add2Gnd(): Channel lables/order do not match across GND and current SET\n\n');
                WarnMsg = 'channel label inconsistency';
                AvgEEG = notes_Add2Gnd(AvgEEG, WarnMsg);
                AvgEEG.saved = 'no';
                pop_SaveSet(AvgEEG);                  
                return
            end
        end
        
        %Check event types and orders match
        if ~all(GetTime0Events(GndEEG) == GetTime0Events(AvgEEG)); 
            fprintf(2, '\nError in pop_Add2Gnd(): Event type/order does not match across GND and current SET\n\n'); 
            WarnMsg = 'event type inconsistency';
            AvgEEG = notes_Add2Gnd(AvgEEG, WarnMsg);
            AvgEEG.saved = 'no';
            pop_SaveSet(AvgEEG);              
            return
        end             
        
        %Check that data size matches and if so add in new data
        if min(size(GndEEG.data) == size(AvgEEG.data))<1
            fprintf(2, '\nError in pop_Add2Gnd(): ''data'' field dimensions do not match across GND and current SET\n\n');
            WarnMsg = 'data field size inconsistency';
            AvgEEG = notes_Add2Gnd(AvgEEG, WarnMsg);
            AvgEEG.saved = 'no';
            pop_SaveSet(AvgEEG);              
            return
        else
            GndEEG.data = GndEEG.N * GndEEG.data + AvgEEG.data; %add in new data, weighting GND by N 
            GndEEG.data = GndEEG.data / (GndEEG.N + 1);
            GndEEG.N = GndEEG.N + 1;
            GndEEG.subject = {GndEEG.subject{:} AvgEEG.subject};            
        end        
    end
    GndEEG.saved = 'no';
    pop_SaveSet(GndEEG, GndFileName, GndFilePath);
    WarnMsg = 'Success';
    AvgEEG = notes_Add2Gnd(AvgEEG, WarnMsg);
    AvgEEG.saved = 'no';
    pop_SaveSet(AvgEEG);
end

