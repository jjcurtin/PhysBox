%USAGE:  [EEG COM] = pop_Figure4Panel(EEG, FigChan, Prefix, Save, SameScale)
%Creates a 4 panel diagnosic figure that includes All Epochs, Rejected
%Epochs, Retained Epochs, and Avg Epochs.  Saves the fig as
%PrefixFig4Panel.fig in the path of EEG.
%
%INPUTS
%EEG: An epoched EEG that contains all Epochs and has rejected epochs
%     indicated in reject field
%FigChan:  String to indicate channel label to plot
%Prefix:  Prefix to append to figure filename
%Save: Should fig file be auto saved in Reduce folder using prefix
%SameScale: Boolean to indicate if all y axes have same (default) or independent
%        scales.  Value should be TRUE or FALSE
%
%OUTPUTS
%EEG:  Unmodified EEG
%COM:  Processing string for history

function [ EEG COM ] = pop_Figure4Panel(EEG, FigChan, Prefix, Save, SameScale)
    COM = '[ COM ] = pop_Figure4Panel(EEG )';
    fprintf('\npop_Figure4Panel(): Creating 4 panel diagnostic figure\n')
    

    if nargin < 1
        pophelp('pop_Figure4Panel');
        return
    end
    
    if nargin < 5
    cbButton = ['tmpchanlocs = EEG(1).chanlocs;'...
        '[tmp tmpval] = pop_chansel({tmpchanlocs.labels}, ''withindex'', ''on'', ''selectionmode'', ''single'');'...
        'set(findobj(gcbf, ''tag'', ''Chan''), ''string'',tmpval);'...
        'clear tmp tmpchanlocs tmpval'];
    
    geometry = {  [1 1 .5] [1 1 .5] [2 .25 .25] [2 .25 .25]  };
    
    uilist = { ...
        { 'Style', 'text', 'string', 'Channel to Plot' } ...
        { 'Style', 'edit', 'string', '', 'tag', 'Chan' } ...
        { 'style' 'pushbutton' 'string'  '...', 'enable' fastif(isempty(EEG.chanlocs), 'off', 'on') ...
        'callback', cbButton  } ...
        ...
        { 'style' 'text'       'string' 'Figure filename prefix' } ...
        { 'style' 'edit'       'string' '', 'tag' 'Prefix' } ...
        { } ...
        ...
        { 'Style' 'checkbox'   'string' 'Auto Save and Close' 'tag' 'Save' } ...
        {  } ...
        { } ...
        ...
        { 'Style' 'checkbox'   'string' 'Same Y-Axis Scale' 'tag' 'AutoScale', 'value' 1 } ...
        {  } ...
        { } ...
        };
    
    [op ud sh Results] = inputgui( geometry, uilist, 'pophelp(''pop_Figure4Panel'');', 'Create 4 panel diagnostic figure -- pop_Figure4Panel()' );
    if isempty(Results); return; end
    
    FigChan = Results.Chan;
    Prefix = Results.Prefix;
    Save = Results.Save;
    SameScale = Results.AutoScale;
    end
   
    
    %Establish list of Event codes
    EventCodes = unique(GetTime0Events(EEG));   
    
    %Create color cube for lines
    if length(EventCodes)  < 7
        cc = colormap(lines(length(EventCodes)));
    else
        cc=colorcube(length(EventCodes)+1); %create list of colors evenly divided within RGB space; last color created is always white, add 1 to prevent non-display.  <8 returns grayscale
    end    
    
    %Create four sets to graph
    EEGAll = EEG;
    
    Rejects = FindRejects(EEGAll);
    if sum(Rejects) < EEGAll.trials
        Indices = find(Rejects);
        EEGFin = pop_select( EEGAll, 'notrial', Indices);
        if length(EEGFin.epoch) ==1 || EEGFin.trials==1
            EEGFin = FixSingleEpoch(EEGFin);  %temp fix for bug in EEGLab with epoched files with one epoch
        end        
    else
        EEGFin = eeg_emptyset;  %bug exists with select if all trials deleted.  Same is true of pop_rejepoch()
    end
    
    if sum(~Rejects) < EEGAll.trials
        Indices = find(~Rejects);
        EEGRej = pop_select( EEGAll, 'notrial', Indices);
        if length(EEGRej.epoch) ==1 || EEGRej.trials==1
            EEGRej = FixSingleEpoch(EEGRej);  %temp fix for bug in EEGLab with epoched files with one trial
        end
    else
        EEGRej = eeg_emptyset;  %bug exists with select if all trials deleted.  Same is true of pop_rejepoch()
    end    
    
    EEGAvg = pop_CreateAvg(EEGFin, EventCodes, [], [], [], [], [], 0);  %call but suppress notes
    
    
    
    %get ymin and ymax if same scale used for all (default)
    YMin = min(min(squeeze(EEGAll.data(GetChanNum(EEGAll,FigChan),:,:))));
    YMax = max(max(squeeze(EEGAll.data(GetChanNum(EEGAll,FigChan),:,:))));

    YMin = YMin - .1*abs(YMin);
    YMax = YMax + .1*abs(YMax); %Pad by 10%
           
    %figure
    
    %Figure 1;  All Epochs
    subplot(2,2,1);
    title(sprintf('%d TOTAL epochs for SubID: %s',EEGAll.trials, EEG.subject),'fontsize',14);
    xlabel('Time (ms)','fontsize',14); 
    ylabel('uV','fontsize',14); 
    hold on; %hold graph elements constant while adding trial lines
    for n = 1:EEGAll.trials
        plot(EEGAll.times, EEGAll.data(GetChanNum(EEGAll,FigChan),:,n),'color',cc(EventCodes==FindEvent0(EEGAll,n),:),'LineWidth',2)
    end
    
    %create event labels for legend
%     ECs = unique(GetTime0Events(EEGAll));
%     EventLabels=cell(length(ECs),1); %prep entries for legend
%     for i=1:length(EventLabels)
%         EventLabels{i,1}=(num2str(ECs(i,1)));
%     end        
%     legend(EventLabels, 'Location', 'NorthWest');
    
    hold off;  
    xlim([EEGAll.times(1) EEGAll.times(end)]);
    ylim([YMin YMax]);
    set(gca, 'YLimMode', 'manual')
    set(gca, 'XLimMode', 'manual')
    

%     %Figure 2: Rejected Epochs
%     if EEGRej.trials ==1   %KLUDGE TO FIX 1 TRIAL EPOCHS
%         EEGRej.times = linspace(EEGRej.xmin*1000,EEGRej.xmax*1000, EEGRej.pnts);
% 
%         if length(EEGRej.event) ==1
%             EEGRej.epoch.event = 1;
%             EEGRej.epoch.eventtype = EEGRej.event.type;
%             EEGRej.epoch.eventlatency = 0;
%             
%             EEGRej.event.epoch = 1;
%         else
%             error('only one epoch but mulitple events')
%         end
%     end
        
        
    if EEGRej.trials > 0
        subplot(2,2,2); 
        title(sprintf('%d REJECTED epochs for SubID: %s',EEGRej.trials, EEGRej.subject),'fontsize',14);
        xlabel('Time (ms)','fontsize',14); 
        ylabel('uV','fontsize',14); 
        hold on;

        for n = 1:EEGRej.trials
            plot(EEGRej.times, EEGRej.data(GetChanNum(EEGRej,FigChan),:,n),'color',cc(EventCodes==FindEvent0(EEGRej,n),:),'LineWidth',2)            
        end

        %create event labels for legend
%         ECs = unique(GetTime0Events(EEGRej));
%         EventLabels=cell(length(ECs),1); %prep entries for legend
%         for i=1:length(EventLabels)
%             EventLabels{i,1}=(num2str(ECs(i,1)));
%         end        
%         legend(EventLabels, 'Location', 'NorthWest');
        hold off;  
        xlim([EEGRej.times(1) EEGRej.times(end)]);
        
        if ~SameScale
            YMin = min(min(squeeze(EEGRej.data(GetChanNum(EEGRej,FigChan),:,:))));
            YMax = max(max(squeeze(EEGRej.data(GetChanNum(EEGRej,FigChan),:,:))));

            YMin = YMin - .1*abs(YMin);
            YMax = YMax + .1*abs(YMax); %Pad by 10%
        end   
        ylim([YMin YMax]);
        set(gca, 'YLimMode', 'manual')
        set(gca, 'XLimMode', 'manual')
    end

    
    %Figure 3:  Retained epochs
    if EEGFin.trials> 0
        subplot(2,2,3); 
        title(sprintf('%d RETAINED epochs for SubID: %s',EEGFin.trials, EEGFin.subject),'fontsize',14);
        xlabel('Time (ms)','fontsize',14); 
        ylabel('uV','fontsize',14); 
        hold on;

        for n = 1:EEGFin.trials
            plot(EEGFin.times, EEGFin.data(GetChanNum(EEGFin,FigChan),:,n),'color',cc(EventCodes==FindEvent0(EEGFin,n),:),'LineWidth',2)            
        end

        %create event labels for legend
%         ECs = unique(GetTime0Events(EEGFin));
%         EventLabels=cell(length(ECs),1); %prep entries for legend
%         for i=1:length(EventLabels)
%             EventLabels{i,1}=(num2str(ECs(i,1)));
%         end        
%         legend(EventLabels, 'Location', 'NorthWest');
        hold off;   
        xlim([EEGFin.times(1) EEGFin.times(end)]);

        if ~SameScale
            YMin = min(min(squeeze(EEGFin.data(GetChanNum(EEGFin,FigChan),:,:))));
            YMax = max(max(squeeze(EEGFin.data(GetChanNum(EEGFin,FigChan),:,:))));

            YMin = YMin - .1*abs(YMin);
            YMax = YMax + .1*abs(YMax); %Pad by 10%
        end         
        ylim([YMin YMax]);
        set(gca, 'YLimMode', 'manual')
        set(gca, 'XLimMode', 'manual')
    end
   
    
    %Figure 4:  Avg epochs
    if EEGAvg.trials> 1
        subplot(2,2,4); 
        title(sprintf('%d AVERAGE epochs for SubID: %s',EEGAvg.trials, EEGAvg.subject),'fontsize',14);
        xlabel('Time (ms)','fontsize',14); 
        ylabel('uV','fontsize',14); 
        hold on;
        for n = 1:EEGAvg.trials
            plot(EEGAvg.times, EEGAvg.data(GetChanNum(EEGAvg,FigChan),:,n),'color',cc(EventCodes==FindEvent0(EEGAvg,n),:),'LineWidth',2)            
        end
        %create event labels for legend
        ECs = unique(GetTime0Events(EEGAvg));
        EventLabels=cell(length(ECs),1); %prep entries for legend
        for i=1:length(EventLabels)
            EventLabels{i,1}=(num2str(ECs(i,1)));
        end        
        legend(EventLabels, 'Location', 'NorthWest');
        hold off;   
        xlim([EEGAvg.times(1) EEGAvg.times(end)]);
        
        if ~SameScale
            YMin = min(min(squeeze(EEGAvg.data(GetChanNum(EEGAvg,FigChan),:,:))));
            YMax = max(max(squeeze(EEGAvg.data(GetChanNum(EEGAvg,FigChan),:,:))));

            YMin = YMin - .1*abs(YMin);
            YMax = YMax + .1*abs(YMax); %Pad by 10%
        end   
        ylim([YMin YMax]);
        set(gca, 'YLimMode', 'manual')
        set(gca, 'XLimMode', 'manual')  
    end

    if Save
        FigFilename = [Prefix 'Figure4Panel' EEG.subject '.fig'];
        saveas(gcf,fullfile(EEG.filepath, FigFilename)); %save figure to subject's reduction folder
        close (gcf); %Close figure window
    end       
end

