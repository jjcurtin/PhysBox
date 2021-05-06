%USAGE:  [EEG COM] = pop_AvgFigure(EEG, FigChans, Prefix)
%Creates a paneled diagnosic figure for an AVG set by channel.
%Saves the fig as PrefixAvgFigure.fig in the path of EEG.
%Control format (rows, cols) of figure by format of FigChans
%
%INPUTS
%EEG: An epoched AVG EEG
%FigChans: Cell array of channel labels.   Can be 1 or 2-d.  Figure plots
%will follow dimensions (and locations) of this cell array
%Prefix:  Prefix to append to figure filename
%
%OUTPUTS
%EEG:  Unmodified EEG
%COM:  Processing string for history
%
%Author: John Curtin (jjcurtin@wisc.edu)
%Released: 2012-03-01

function [ EEG COM ] = pop_AvgFigure(EEG, FigChans, Prefix)
    COM = '[ COM ] = pop_AvgFigure(EEG)';
    fprintf('\npop_AvgFigure(): Creating paneled figure of AVG by channel\n')
    
    if nargin < 1
        pophelp('pop_AvgFigure');
        return
    end
    
    if nargin < 3
        cbButton = ['tmpchanlocs = EEG(1).chanlocs;'...
                            '[tmp tmpval] = pop_chansel({tmpchanlocs.labels}, ''withindex'', ''on'');'...
                            'set(findobj(gcbf, ''tag'', ''Chans''), ''string'',tmpval);'...
                            'clear tmp tmpchanlocs tmpval']; 

        geometry = {  [1 1 .5] [1 1 .5] };

        uilist = { ...
                 { 'Style', 'text', 'string', 'Channels to Plot' } ...
                 { 'Style', 'edit', 'string', '', 'tag', 'Chans' } ...
                 { 'style' 'pushbutton' 'string'  '...', 'enable' fastif(isempty(EEG.chanlocs), 'off', 'on') ...
                   'callback', cbButton  } ...
                 ...
                 { 'style' 'text'       'string' 'Figure filename prefix' } ...
                 { 'style' 'edit'       'string' '', 'tag' 'Prefix' } ...
                 { } ...
                 };

        [op ud sh Results] = inputgui( geometry, uilist, 'pophelp(''pop_AvgFigure'');', 'Paneled AVG fig by Channel -- pop_AvgFigure()' );
        if isempty(Results); return; end
        
        FigChans = Results.Chans;
        Prefix = Results.Prefix;
    end
    
    %if no data/emptyset, make a blank figure to be safe and return with
    %warning
    if isempty(EEG.data)
        fprintf(2,'\n\nWARNING: Figure requested for emptyset EEG\n\n');
        figure
        FigFilename = [Prefix 'AvgFigure' EEG.subject '.fig'];
        saveas(gcf,fullfile(EEG.filepath, FigFilename)); %save figure to subject's reduction folder        
        close (gcf); %Close figure window            
    end
    
   
   if isempty(EEG.epoch)
       error('pop_AvgFigure() requires an epoched EEG set\n');
   end
   
   %Test that this is an AVG file
   EventCodes = unique(GetTime0Events(EEG));   %Establish list of Event codes
   if length(unique(EventCodes)) < EEG.trials
       error('pop_AvgFigure() requires an averaged (AVG) EEG set\n');
   end
   
    %Create color cube for lines
    if length(EventCodes)  < 7
        cc = colormap(lines(length(EventCodes)));
    else
        cc=colorcube(length(EventCodes)+1); %create list of colors evenly divided within RGB space; last color created is always white, add 1 to prevent non-display.  <8 returns grayscale
    end    
    
    %determine plot configuration
    nRows = size(FigChans,1);
    nCols = size(FigChans, 2);
    
    ChanNums = GetChanNums(EEG,FigChans);   
    
    %get ymin and ymax
    YMin = min(min(min(squeeze(EEG.data(ChanNums,:,:)))));
    YMax = max(max(max(squeeze(EEG.data(ChanNums,:,:)))));
       
    YMin = YMin - .1*abs(YMin); %Pad by 10%
    YMax = YMax + .1*abs(YMax); 
    
    tFigChans = FigChans'; %to work with subplot index by rows
    FigCnt = 0;
    for r = 1:nRows
        for c = 1:nCols
            FigCnt = FigCnt + 1;
            subplot(nRows,nCols,FigCnt); 
            %title(sprintf('%s for SubID: %s',GetChanNum(EEG,prod([r c])), EEGAvg.subject),'fontsize',14);
            xlabel('Time (ms)','fontsize',14); 
            ylabel(sprintf('%s',tFigChans{FigCnt}),'fontsize',14); 
            hold on;
            for n = 1:EEG.trials
                plot(EEG.times, EEG.data(GetChanNum(EEG,tFigChans{FigCnt}),:,n),'color',cc(EventCodes==FindEvent0(EEG,n),:),'LineWidth',2)            
            end

            %put SubID title and condition legend on first fig only
            if FigCnt == 1
                title(sprintf('SubID: %s',EEG.subject),'fontsize',14);
                EventLabels=cell(length(EventCodes),1); %prep entries for legend
                for i=1:length(EventLabels)
                    EventLabels{i}=(num2str(EventCodes(i)));
                end        
                legend(EventLabels, 'Location', 'NorthWest');
            end
            hold off;              
            ylim([YMin YMax]);                
        end 
    end
        
     
    FigFilename = [Prefix 'AvgFigure' EEG.subject '.fig'];
    saveas(gcf,fullfile(EEG.filepath, FigFilename)); %save figure to subject's reduction folder        
    close (gcf); %Close figure window     
end

