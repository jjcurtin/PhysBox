%USAGE: [ EEG, COM, nEpochos ] = pop_RejectEpochs( EEG, Notes )
%Rejects epochs that have been  marked by threshold, mean, or max deflection methods
%Returns EEG with these epochs removed.   see also pop_MarkThreshold(), 
%pop_MarkMean(), and pop_MarkDeflection(), pop_select()
%
%INPUTS
%EEG:  An epoched EEG set
%Notes:  boolean to indicate if notes should be saved to parameter file.
%Default is true
%
%OUTPUTS
%EEG:  EEG set with rejected epochs removed
%COM:  processing string for history
%nEpochs:  Number of epochs remaining.   Useful for error checking

function [ EEG, COM, nEpochs ] = pop_RejectEpochs( EEG, Notes )
    COM = 'EEG = pop_RejectEpochs( EEG )';


    if nargin < 1
        pophelp('pop_RejectEpochs');
        nEpochs = 0;
        return
    end

    if nargin < 2 || isempty(Notes)
        Notes = true;
    end
    
    if isempty(EEG.epoch)
        error('pop_RejectEpochs requires epoched dataset\n');
    end

    Rejects = FindRejects(EEG);  %support function to aggregate across supported reject fields
    
    fprintf('\npop_RejectEpochs(): Rejecting %d/%d epochs...\n', sum(Rejects), EEG.trials);
    
    EEG.reject.rejall = Rejects;
    if Notes
        EEG = notes_RejectEpochs(EEG);
    end
    
    %call after notes so trials still exist to count
    if sum(Rejects) < EEG.trials
        Indices = find(Rejects);
        EEG = pop_select( EEG, 'notrial', Indices);
    else  %bug exists with select if all trials deleted.  Same is true of pop_rejepoch()
        %EEG = eeg_emptyset;
        EEG.trials = 0;
        EEG.data = [];
        EEG.epoch = [];
        EEG.event = [];
        EEG.reject = [];
    end
    
    nEpochs = EEG.trials;
    
    if nEpochs ==1
        EEG = FixSingleEpoch(EEG);  %temp fix for bug in EEGLab with epoched files with one epoch
    end
    
    COM = fprintf('EEG = pop_RejectEpochs(EEG, %d);', Notes);


end

