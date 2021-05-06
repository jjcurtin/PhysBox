%Usage:   [COM] = pop_OverlayPlot(EEG, ChanLabel, Events)
%Creates an overlay plot for selected events for selected channel
%
%Inputs:
%EEG: an epoched dataset
%ChanLabel: string label of ONE channel
%Events:  Array containing event types of epoch to plot
%
%Outputs:
%COM: String to record this processing step
%
% See also: eeglab()

%
%Revision History
%03-19-2007 Released version1, JJC v1
%08-22-2007  Fixed bug with plotting less than all events, JJC v2
%2011-10-17: Fixed bug with legend labels, JJC

function [COM] = pop_PlotOverlay(EEG, ChanLabel, Events)     

    COM = '[COM] = pop_PlotOverlay(EEG)';

    fprintf('pop_PlotOverlay(): Creating Overlay Plot\n');          

    % display help if EEG not provided
    % ------------------------------------
    if nargin < 1
        pophelp('pop_PlotOverlay');
        return;
    end;	

    if nargin < 3
        ButChan =     ['if ~isfield(EEG.chanlocs, ''labels'')' ...
                       '   errordlg2(''No channel label field'');' ...
                       'else' ...
                       '   [tmps,tmpstr] = pop_chansel(unique({ EEG.chanlocs.labels }));' ...
                       '   if ~isempty(tmps)' ...
                       '       set(findobj(''parent'', gcbf, ''tag'', ''chan''), ''string'', tmpstr);' ...
                       '   end;' ...
                       'end;' ...
                       'clear tmps tmpv tmpstr tmpfieldnames;' ]; 
         ButEvent =   ['if ~isfield(EEG.event, ''type'')' ...
                       '   errordlg2(''No type field'');' ...
                       'else' ...
                       '   if isnumeric(EEG.event(1).type),' ...
                       '        [tmps,tmpstr] = pop_chansel(unique([ EEG.event.type ]));' ...
                       '   else,' ...
                       '        [tmps,tmpstr] = pop_chansel(unique({ EEG.event.type }));' ...
                       '   end;' ...
                       '   if ~isempty(tmps)' ...
                       '       set(findobj(''parent'', gcbf, ''tag'', ''events''), ''string'', tmpstr);' ...
                       '   end;' ...
                       'end;' ...
                       'clear tmps tmpv tmpstr tmpfieldnames;' ];

        geometry = { [2 1 0.5] [2 1 0.5]};
        uilist = {{ 'style' 'text'       'string' 'Channel Label to Plot:' } ...
                  { 'style' 'edit'       'string' '' 'tag' 'chan' } ...
                  { 'style' 'pushbutton' 'string' '...' 'callback' ButChan }...
                  { 'style' 'text'       'string' 'Event to include Plot:' } ...
                  { 'style' 'edit'       'string' '' 'tag' 'events' } ...
                  { 'style' 'pushbutton' 'string' '...' 'callback' ButEvent } };

        [op ud sh Results] = inputgui( geometry, uilist, 'pophelp(''pop_PlotOverlay'')', 'Make Overlay Plot - pop_PlotOverlay()');
        if isempty( Results ); return; end;
        ChanLabel = Results.chan;
        Events = str2double(parsetxt(Results.events));
    end

    ChanNum = 0; %determine index of channel label
    for i = 1:length(EEG.chanlocs)
        if strcmpi(ChanLabel,EEG.chanlocs(i).labels)
            ChanNum = i;
        end
    end
    if ChanNum == 0 %check that index was found
        error('pop_OverlayPlot:InvalChanLabel', 'ERROR: Channel Label(%s) does not exist', ChanLabel);
    end

    OrigData = squeeze(EEG.data(ChanNum,:,:)); %make array of only selected epochs
    Cols = 0;  %keep track of column position in final data set
    FinData = zeros(size(OrigData,1),length(Events));  %set up array to start
    LegendLabels = cell(1,length(Events));
    LegendCtr = 0;
    Event0s = GetTime0Events(EEG);
    for i = 1:length(Event0s)  
        if  any(Events == Event0s(i))
            Cols= Cols+1;
            FinData(:,Cols) = OrigData(:,i);
            LegendCtr = LegendCtr + 1;
            LegendLabels{LegendCtr} = num2str(Event0s(i));
        end
    end
    if size(FinData,2) ~= length(Events)
        error ('Multiple Epochs with Same Event Type Exist\n')
    end

    XTimes =repmat (EEG.times', 1,length(Events));  %make array of same size with time indices
    figure;
    plot(XTimes, FinData);
    legend('show')
    %labels = int2str(Events');
    legend(LegendLabels);
    xlabel('Time (ms)', 'FontSize', 14);
    ylabel([ChanLabel ' (microvolts)'], 'FontSize', 14);

    %Return the string command for record of processing if desired
    COM = sprintf('COM = pop_PlotOverlay(EEG, %s, [%s]);', ChanLabel, int2str(Events));
end
