%USAGE:  pop_ViewRejects or pop_ViewRejects (EEG, ViewThreshold, ViewMean, ViewDeflect, ViewManual, Wait, Maximize) 
%Plots data epochs with rejected epochs indicated by previous artifact 
%reject methods (currently threshold, mean level, max deflection, or manual)
%highlighted.  This script does not modify the original EEG file.  It can
%be called in one of two ways.  1.  pop_ViewRejects will prompt to open
%EEG file, select methods to display and and then display.   
%pop_ViewRejects (EEG) will display an EEG file that is
%already in workspace but ask for which artifact methods.
%Providing the first parameters bypasses GUI using defaults for Wait (0)
%and Maximize (1)
%
%Inputs
%EEG:  An epoched EEG structure that has had threshold rejection performed
%ViewThreshold: Boolean to indicate if epochs marked by Threshold should be
%               included for viewing
%ViewMean: Boolean to indicate if epochs marked by Mean Level should be
%          included for viewing
%ViewDeflect:  Boolean to indicate if epochs marked by Max Deflection
%          should be included for viewing 
%ViewManual:  Bolean to indicate if epochs marked manually by
%          Epoch should be included for viewing
%Wait:  Boolean to indicate if matlab should wait till figure closed
%       (useful when called in loop by pop_MultiSet)
%Maximize:  Boolean to indicate if figure should be maximized
%
%Outputs
%EEG:  original/unmodified epoched EEG structure
%COM: String to record this processing step

%Revision history
%2008-11-22:  released version 1, JJC
%2011-09-29:  fixed to display rejection from threshold method, JJC
%2012-01-27:  updated to include option to view threshold, mean or both, JJC
%2015-07-31:  updated to include  opion to view manual rejects, JJC


function [EEG, COM] = pop_ViewRejects(EEG, ViewThreshold, ViewMean, ViewDeflect, ViewManual, Wait, Maximize)

COM = 'EEG = pop_ViewRejects()';


if nargin < 1  %open dataset if not provided
    EEG = pop_loadset;
end
EEGOrig = EEG;

if nargin < 7 || isempty(Maximize)
    Maximize =1;
end

if nargin < 6 || isempty(Wait)
    Wait = 1;
end



if nargin < 5
    geometry = {  [1 1 1 1 1] [1 1 1 1 1] [1 1 1 1 1]};

    uilist = { ...
             { 'style' 'text'       'string' 'View Reject Methods:' } ...
             { 'Style' 'checkbox'   'string' 'Threshold' 'tag' 'ViewThreshold' } ...
             { 'Style' 'checkbox'   'string' 'Mean Level' 'tag' 'ViewMean' } ...
             { 'Style' 'checkbox'   'string' 'Max Deflection' 'tag' 'ViewDeflect' } ...   
             { 'Style' 'checkbox'   'string' 'Manual' 'tag' 'ViewManual' } ...
             ...
             { 'style' 'text'       'string' 'Wait for Figure Close (boolean):' } ...
             { 'Style' 'edit'       'string' '0' 'tag' 'Wait' } ...
             { } ...
             { } ...  
             { } ...
             ...
             { 'style' 'text'       'string' 'Maximize Figure (boolean):' } ...
             { 'Style' 'edit'       'string' '1' 'tag' 'Maximize' } ...
             { } ...
             { } ... 
             { } ...            
             };

    [op ud sh Results] = inputgui( geometry, uilist, 'pophelp(''pop_ViewRejects'');', 'View Rejected Epochs -- pop_ViewRejects()' );
    if isempty(Results); return; end
        
    ViewThreshold = Results.ViewThreshold;
    ViewMean = Results.ViewMean;
    ViewDeflect = Results.ViewDeflect;
    ViewManual = Results.ViewManual;
    Wait =  str2double(Results.Wait);
    Maximize = str2double(Results.Maximize);
    
end

if isempty(EEG.epoch)
    error('pop_ViewRejects does not work with continuous files.  Epoch first!')
end

%Create reject fields if missing or empty
if ~isfield(EEG.reject, 'rejmanual') || isempty(EEG.reject.rejmanual)
    EEG.reject.rejmanual = zeros(1,EEG.trials);
    EEG.reject.rejmanualE = zeros(EEG.nbchan,EEG.trials);
end

if ~isfield(EEG.reject, 'rejmean') || isempty(EEG.reject.rejmean)
    EEG.reject.rejmean = zeros(1,EEG.trials);
    EEG.reject.rejmeanE = zeros(EEG.nbchan,EEG.trials);
end

if ~isfield(EEG.reject, 'rejthresh') || isempty(EEG.reject.rejthresh)
    EEG.reject.rejthresh = zeros(1,EEG.trials);
    EEG.reject.rejthreshE = zeros(EEG.nbchan,EEG.trials);
end

if ~isfield(EEG.reject, 'rejdeflect') || isempty(EEG.reject.rejdeflect)
    EEG.reject.rejdeflect = zeros(1,EEG.trials);
    EEG.reject.rejdeflectE = zeros(EEG.nbchan,EEG.trials);
end


%pop_eegplot using the rejmanual fields to display so we need to add the
%other reject fields to this field if we want to display them.  And we need
%to remove the manual rejects from this field if we dont want to display
%manual rejects

%first remove manual rejects if we dont want to display them
if ~ViewManual
    EEG.reject.rejmanual = zeros(1,EEG.trials);
    EEG.reject.rejmanualE = zeros(EEG.nbchan,EEG.trials);
end

%set manual reject field to be equal to threshold field to display
if ViewThreshold
    EEG.reject.rejmanual = EEG.reject.rejmanual + EEG.reject.rejthresh;
    EEG.reject.rejmanualE = EEG.reject.rejmanualE + EEG.reject.rejthreshE;
end

if ViewMean
    EEG.reject.rejmanual = EEG.reject.rejmanual + EEG.reject.rejmean;
    EEG.reject.rejmanualE = EEG.reject.rejmanualE + EEG.reject.rejmeanE;
end

if ViewDeflect
    EEG.reject.rejmanual = EEG.reject.rejmanual + EEG.reject.rejdeflect;
    EEG.reject.rejmanualE = EEG.reject.rejmanualE + EEG.reject.rejdeflectE;
end

EEG.reject.rejmanual = EEG.reject.rejmanual > 0;
EEG.reject.rejmanualE = EEG.reject.rejmanualE > 0;
    
pop_eegplot( EEG, 1, 1, 0);

    if Maximize
        maximize(gcf)
    end
    
    if Wait
        uiwait(gcf);
    end

EEG = EEGOrig;  %return to original EEG to remove changes to reject.rejmanual
COM = sprintf('[EEG, COM] = pop_ViewRejects(EEG);');
end
