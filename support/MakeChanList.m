function [ Labels, Indices ] = MakeChanList( EEG, LabelList )
%USAGE: [ Labels, Indices ] = MakeChanList( EEG, LabelList )
%takes list of chan labels of three formats and returns final list and
%indices.  
%Option 1 is {'all'} which returns all channels
%Option 2 is {'exclude', 'label1' 'label2'} which returns all labels except label1 and label2
%Option 3 is {'Label1', 'Label2'} which returns these channels and their
%indices
%
%INPUTS
%EEG:  A EEG structure
%LabelList: A cell array of one of three format options describe above
%
%OUTPUTS
%Labels:  A cell array of channel labels
%Indices: A numeric array of channel indices
%
%see also  eegplugin_PhysBox, GetChanNums(), eeglab()
%
%Author: John Curtin (jjcurtin@wisc.edu)

%Revision history
%%2011-11-08: released, JJC



    if length(LabelList) ==1 && strcmpi(LabelList{1}, 'all')
        Labels = {EEG.chanlocs.labels};
        Indices = GetChanNums(EEG,Labels);
    end

    if length(LabelList) > 1 && strcmpi(LabelList{1}, 'exclude')
        ExcludeIndices = GetChanNums(EEG, LabelList(2:end));
        Indices = setdiff(1:EEG.nbchan, ExcludeIndices);
        Labels = {EEG.chanlocs(Indices).labels};    
    end

    if ~strcmpi(LabelList{1},'all') && ~strcmpi(LabelList{1}, 'exclude')
        Labels = LabelList;
        Indices = GetChanNums(EEG, Labels);
    end




end

