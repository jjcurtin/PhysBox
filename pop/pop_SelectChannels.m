%USAGE: [ EEG  COM ] = pop_SelectChannels( EEG, ChanList )
%Wrapper function to call pop_select() to select channels with Curtin lab function naming
%conventions.   
%see also pop_select()
%
%INPUTS
%EEG: An EEG data structure
%ChanList:  A cell array of channel labels to select.  Can use 'all' or
%'exclude' notation (see MakeChanList)
%
%OUTPUTS
%OutEEG:  Reduced EEG data structure
%COM: EEG command line

%Revision History
%2012-01-26:  released, JJC


function [ EEG  COM ] = pop_SelectChannels( EEG, ChanList )

    COM = 'pop_SelectChannels( EEG)';

    if nargin < 1  
        pophelp('pop_SelectChannels')
        return
    end
    
    if nargin < 2
        cbButton = ['tmpchanlocs = EEG(1).chanlocs;'...
                    '[tmp tmpval] = pop_chansel({tmpchanlocs.labels}, ''withindex'', ''on'');'...
                    'set(findobj(gcbf, ''tag'', ''ChanLabels''), ''string'',tmpval);'...
                    'clear tmp tmpchanlocs tmpval']; 

        geometry = {  [1 3 1] [1] [1 1 1]};

        uilist = { ...
             { 'Style', 'text', 'string', 'Channel range' }, ...
             { 'Style', 'edit', 'string', '', 'tag', 'ChanLabels' }, ...
             { 'style' 'pushbutton' 'string'  '...', 'enable' fastif(isempty(EEG.chanlocs), 'off', 'on') ...
               'callback', cbButton  }, ...
             ...
             {}...
             ...
             { }, { 'Style', 'pushbutton', 'string', 'Scroll dataset', 'enable', fastif(length(EEG)>1, 'off', 'on'), 'callback', ...
                              'eegplot(EEG.data, ''srate'', EEG.srate, ''winlength'', 5, ''limits'', [EEG.xmin EEG.xmax]*1000, ''position'', [100 300 800 500], ''xgrid'', ''off'', ''eloc_file'', EEG.chanlocs);' } {}};

        [op ud sh Results] = inputgui( geometry, uilist, 'pophelp(''pop_SelectChannels'');', 'Select Channels -- pop_SelectChannels()' );
        if isempty(Results); return; end
        ChanList = parsetxt(Results.ChanLabels);
    end
    
    [ ChanList, ChanInds ] = MakeChanList( EEG, ChanList );
        
    EEG = pop_select( EEG, 'channel',ChanList); 
    COM = sprintf('EEG = pop_SelectChannels( EEG );');
        
end

