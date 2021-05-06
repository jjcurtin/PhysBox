%USAGE: Rejects  = FindRejects(EEG, Method)
%Returns an array of 0s and 1s the size of EEG.trials.  1s indicate
%trials that are rejected by any of the currently established methods.  These methods
%are currently limited to pop_MarkThreshold(), pop_MarkMean(),
%pop_MarkDeflection(), and pop_MarkEpoch()
%
%INPUTS
%EEG: An EEG set
%Method: String identifying which Rejects to find: all, automatically
%rejected or manually rejected. Must be labeled 'all', 'auto', or 'manual'
%
%OUTPUTS
%Rejects:  numeric array of 0s and 1s the size of EEG.trials.  1s indicate
%          rejected trials

function [ Rejects ] = FindRejects(EEG, Method)

if nargin < 2
    Method = 'all';
end

if isempty(EEG.epoch)
    error('FindRejects() required epoched EEG set\n')
end

%add rejmean field if not set
if ~isfield(EEG.reject, 'rejmean')  || isempty(EEG.reject.rejmean)
    EEG.reject.rejmean = zeros(1,EEG.trials);
end

%add rejdeflect field if not set
if ~isfield(EEG.reject, 'rejdeflect') || isempty(EEG.reject.rejdeflect)
    EEG.reject.rejdeflect = zeros(1,EEG.trials);
end

%add rejmanual field if not set
if ~isfield(EEG.reject, 'rejmanual') || isempty(EEG.reject.rejmanual)
    EEG.reject.rejmanual = zeros(1,EEG.trials);
end

if strcmpi(Method,'all');
    %currently only rejects based on threshold, mean, max deflection, and epoch methods
    Rejects = sum([EEG.reject.rejthresh; EEG.reject.rejmean; EEG.reject.rejdeflect; EEG.reject.rejmanual],1);
       
elseif strcmpi(Method,'manual');
    Rejects = sum(EEG.reject.rejmanual,1);
       
elseif strcmpi(Method,'auto');
    Rejects = sum([EEG.reject.rejthresh; EEG.reject.rejmean; EEG.reject.rejdeflect],1);
    
else
    error('Method must be either all, manual, or auto');
end
Rejects = Rejects > 0;
end