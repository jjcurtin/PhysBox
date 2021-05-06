%USAGE: [ChanNum] = GetChanNum(InEEG, Label)
%Returns the integer value channel number for a particular label.  Returns
%ERROR if label not found.   
%see also GetChanNums()
%
%INPUTS
%InEEG:  EEG data set
%Label: Sring value associated wtih channel label (case insensitive)
%
%OUTPUTS
%ChanNum:  Channel number associated with label
%
%Author: John Curtin (jjcurtin@wisc.edu)
%Released: 2008-11-22


function [ChanNum] = GetChanNum(InEEG, Label)
    
    i=1;
    while ~(strcmpi(InEEG.chanlocs(i).labels, Label))
        i=i+1;
        if i > length(InEEG.chanlocs)
            error('Channel label (%s) not found.',Label)
        end
    end

   ChanNum = i;
    
end