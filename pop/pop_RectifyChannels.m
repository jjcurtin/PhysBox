%USAGE:   [EEG, COM] = pop_RectifyChannel(EEG, ChanLabels)
%pop_RectifyChannels() - Rectifies selected channels (v3)
%
%Inputs:
%EEG:       a CON EEG set to be re-references
%ChanList:  Cell array of channel labels.  Accepts 'all' and 'exclude'
%           notation (see MakeChanList)
%
%Outputs:
%EEG: Rectified EEG set
%COM: String to record this processing step
%
% See also: eeglab(), pop_select()

% Copyright (C) 2012  John J. Curtin, University of Wisconsin-Madison,
% jjcurtin@wisc.edu
%
%Revision History
%2012-01-26: released to replace pop_RectifyChannel and pop_RectifyAll(), JJC

function [EEG, COM] = pop_RectifyChannels(EEG,ChanList)

    COM = '[EEG, COM] = pop_RectifyChannels(EEG)';
            
    if nargin < 1  
        pophelp('pop_RectifyChannels')
        return
    end
    
    if nargin < 2
        cbButton = ['tmpchanlocs = EEG(1).chanlocs;'...
                    '[tmp tmpval] = pop_chansel({tmpchanlocs.labels}, ''withindex'', ''on'');'...
                    'set(findobj(gcbf, ''tag'', ''ChanList''), ''string'',tmpval);'...
                    'clear tmp tmpchanlocs tmpval']; 

        geometry = {  [1 3 1] [1] [1 1 1]};

        uilist = { ...
             { 'Style', 'text', 'string', 'Channel list' }, ...
             { 'Style', 'edit', 'string', '', 'tag', 'ChanList' }, ...
             { 'style' 'pushbutton' 'string'  '...', 'enable' fastif(isempty(EEG.chanlocs), 'off', 'on') ...
               'callback', cbButton  }, ...
             ...
             {}...
             ...
             { }, { 'Style', 'pushbutton', 'string', 'Scroll dataset', 'enable', fastif(length(EEG)>1, 'off', 'on'), 'callback', ...
                              'eegplot(EEG.data, ''srate'', EEG.srate, ''winlength'', 5, ''limits'', [EEG.xmin EEG.xmax]*1000, ''position'', [100 300 800 500], ''xgrid'', ''off'', ''eloc_file'', EEG.chanlocs);' } {}};

        [op ud sh Results] = inputgui( geometry, uilist, 'pophelp(''pop_RectifyChannels'');', 'Rectify Channel(s) -- pop_RectifyChannels()' );
        if isempty(Results); return; end
        ChanList = parsetxt(Results.ChanList);
    end
    
    [ ChanList, ChanInds ] = MakeChanList( EEG, ChanList );

    TotNumChans = size (EEG.chanlocs,2);
    if max(ChanInds) > TotNumChans %Check that Channel exists
        error('Incorrect channel numbers selected.  Channel %d outside of valid channel range of 1 - %d.', max(ChanInds), TotNumChans);
    end

    %Rectify.  NewChannel = Abs(OldChannel)
    EEG.data(ChanInds,:) = abs(EEG.data(ChanInds,:));

    fprintf('pop_RectifyChannels(): Rectifying  channels [%s]\n', num2str(ChanInds));
    %Return the string command for record of processing
    COM = sprintf('EEG = pop_RectifyChannel(EEG);');
end
