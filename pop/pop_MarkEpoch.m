%USAGE: [ EEG Indices COM ] = pop_MarkEpoch( EEG, Epochs, Reject )
%Mark epochs for rejection (but do not reject) based on trial number.  
%see also pop_MarkThreshold, pop_MarkMean, pop_eegthresh(), eegplugin+PhysBox(), eeglab()
%
%INPUTS
%EEG:  An epoched EEG struct
%Epochs:  Cell array of trial (epoch) numbers to mark for rejection
%Reject: Boolean to indicate immediate reject (true) or mark for later
%        reject (false)
%
%OUTPUTS
%EEG:  EEG struct with rejmean added to reject field
%Indices:  Indices of rejected epochs
%COM:  EEGLab COM

%Revision History
%2015-07-28:  released, JJC

function [ EEG, Indices, COM ] = pop_MarkEpoch( EEG, Epochs, Reject )
            
    COM = 'EEG = pop_MarkEpoch( EEG );';
    Indices = [];
    
    if nargin < 1  
        pophelp( 'pop_MarkEpoch');
        return
    end
    
    if nargin < 3
        geometry = {  [1 1] [1 1] [1] [1 1 1]};

        uilist = { ...
                 { 'Style', 'text', 'string', 'Trial (Epoch) Numbers' } ...
                 { 'Style', 'edit', 'string', '', 'tag', 'Epochs' } ...
                 ...
                 { 'style' 'text'       'string' 'Reject immediately (vs. mark)' } ...
                 { 'Style' 'checkbox'   'string' '  ' 'tag' 'Reject' } ...
                 ...
                 { } ... 
                 ...
                 { } { 'Style', 'pushbutton', 'string', 'Scroll dataset', 'enable', fastif(length(EEG)>1, 'off', 'on'), 'callback', ...
                                  'eegplot(EEG.data, ''srate'', EEG.srate, ''winlength'', 5, ''limits'', [EEG.xmin EEG.xmax]*1000, ''position'', [100 300 800 500], ''xgrid'', ''off'', ''eloc_file'', EEG.chanlocs);' } {}};

        [op, ud, sh, Results] = inputgui( geometry, uilist, 'pophelp(''pop_MarkEpoch'');', 'Reject Epochs by Trial (Epoch) Number -- pop_MarkEpoch()' );
        if isempty(Results); return; end
        
        Epochs = num2cell(str2double(parsetxt(Results.Epochs)));
        Reject = Results.Reject;
    end    
    
    %convert Epochs to matrix
    Epochs = cell2mat(Epochs);
    
    %set up rejmanual and rejmanualE if it hasnt been set up by other function
    %(e.g., pop_eegplot)
    if ~isfield(EEG.reject, 'rejmanual') || isempty(EEG.reject.rejmanual)
        EEG.reject.rejmanual = zeros(1,EEG.trials);
        EEG.reject.rejmanualE = zeros(EEG.nbchan,EEG.trials);
    end
    
    NewRejects = zeros(1,EEG.trials);
    NewRejects(Epochs) = 1;   
    
    EEG.reject.rejmanual = EEG.reject.rejmanual + NewRejects;
    EEG.reject.rejmanual = EEG.reject.rejmanual > 0;
    
    %Manual only rejects across all channels not channel by channel so set
    %each channel as set in rejmanual
    for i =1:EEG.nbchan
        EEG.reject.rejmanualE(i,:) = EEG.reject.rejmanualE(i,:) + NewRejects;
    end
    
    fprintf ('\npop_MarkEpoch():  Marking trials for rejection based on trial (epoch) number\n');
    fprintf ('%d/%d trials marked for rejection\n', sum(EEG.reject.rejmanual), EEG.trials);
    
    EEG = notes_MarkEpoch(EEG);  %Add info on trials marked for rejection to notes field

    Indices = find(EEG.reject.rejmanual);
    
    if Reject
        EEG = pop_rejepoch(EEG, EEG.reject.rejmanual, 0);        
    end
    
    COM = 'EEG = pop_MarkEpoch( EEG );';
end