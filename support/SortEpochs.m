function [OutEEG] = SortEpochs(InEEG)
%This function sorts epochs in ascending order based on event time at time
%0 of each epoch.   The new OUTEEG file will have the epoch table
%re-ordered and (obviously) the data re-ordered.  It does not change the
%event table. Instead it maintains the origninal ordering in that table in
%case order matters. This means that the epochs will still plot in their
%normal order as well.   I imagine this function to be used mostly by
%pop_ExportAscii if the files being exported and appended have epochs that
%are not ordered correctly.
%Inputs
%InEEG - an EEG data set

%Outputs
%OutEEG- new data set with sorted epochs

%Revision History
%02-01-2008, released v1.  JJC
        
OutEEG = eeg_emptyset;  % returns empty EEG dataset if function exits early

%Make Array with Epoch Event types
EventArray = zeros(length(InEEG.epoch),1);
for i = 1:length(InEEG.epoch)
    EventArray(i) = InEEG.event(FindEvent0Index(InEEG,i)).type;
end

%sort this array by event types andreatin sortindex
[Sorted, SortIndex] = sort(EventArray);

%Re-order epoch info
OutEEG = InEEG;
OutEEG.epoch(:) = InEEG.epoch(SortIndex);
%OutEEG.epoch(1:6)
%OutEEG.event(1:6)
%Re-order data
OutEEG.data(:,:,:) = InEEG.data(:,:,SortIndex);
   
end