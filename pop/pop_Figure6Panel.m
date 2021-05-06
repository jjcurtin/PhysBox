%USAGE:  [EEG COM] = pop_Figure6Panel(EEG, FigChan, Prefix, Save, SameScale)
%Creates a 6 panel diagnosic figure that includes All Epochs, All Rejected Epochs
%Auto Rejected Epochs, Manually Rejected Epochs, Retained Epochs, and Avg Epochs.
%Saves the fig as PrefixFig6PanelSubID.fig in the path of EEG.
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

function [ EEG, COM ] = pop_Figure6Panel(EEG, FigChan, Prefix, Save, SameScale)

fprintf('\npop_Figure6Panel(): Creating 6 panel diagnostic figure\n')


if nargin < 1
    pophelp('pop_Figure6Panel');
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
    
    [op ud sh Results] = inputgui( geometry, uilist, 'pophelp(''pop_Figure6Panel'');', 'Create 6 panel diagnostic figure -- pop_Figure6Panel()' );
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

%Create six sets to graph
EEGAll = EEG;

%Create EEGFin for Final included trials
Rejects = FindRejects(EEGAll);
if sum(Rejects) < EEGAll.trials
    Indices = find(Rejects);
    EEGFin = pop_select( EEGAll, 'notrial', Indices);
    if length(EEGFin.epoch) ==1 || isempty(EEGFin.epoch)
        EEGFin = FixSingleEpoch(EEGFin);  %temp fix for bug in EEGLab with epoched files with one epoch
    end
else
    EEGFin = eeg_emptyset;  %bug exists with select if all trials deleted.  Same is true of pop_rejepoch()
end

if sum(~Rejects) < EEGAll.trials
    Indices = find(~Rejects);
    EEGRej = pop_select( EEGAll, 'notrial', Indices);
    if length(EEGRej.epoch) ==1 || isempty(EEGRej.epoch)
        EEGRej = FixSingleEpoch(EEGRej);  %temp fix for bug in EEGLab with epoched files with one epoch
    end
else
    EEGRej = eeg_emptyset;  %bug exists with select if all trials deleted.  Same is true of pop_rejepoch()
end


%Create EEGRejAuto for Auto Rejects
Method = 'auto';
Rejects = FindRejects(EEGAll, Method);
if sum(~Rejects) < EEGAll.trials
    Indices = find(~Rejects);
    EEGRejAuto = pop_select( EEGAll, 'notrial', Indices);
    if length(EEGRejAuto.epoch) ==1 || isempty(EEGRejAuto.epoch)
        EEGRejAuto = FixSingleEpoch(EEGRejAuto);  %temp fix for bug in EEGLab with epoched files with one epoch
    end
else
    EEGRejAuto = eeg_emptyset;  %bug exists with select if all trials deleted.  Same is true of pop_rejepoch()
end


%Create EEGRejManual for Manaul Rejects
Method = 'manual';
Rejects = FindRejects(EEGAll, Method);
if sum(~Rejects) < EEGAll.trials
    Indices = find(~Rejects);
    EEGRejManual = pop_select( EEGAll, 'notrial', Indices);
    if length(EEGRejManual.epoch) ==1 || isempty(EEGRejManual.epoch)
        EEGRejManual = FixSingleEpoch(EEGRejManual);  %temp fix for bug in EEGLab with epoched files with one epoch
    end
else
    EEGRejManual = eeg_emptyset;  %bug exists with select if all trials deleted.  Same is true of pop_rejepoch()
end


%Create Average
EEGAvg = pop_CreateAvg(EEGFin, EventCodes, [], [], [], [], [], 0);  %call but suppress notes


%get ymin and ymax if same scale used for all (default)
YMin = min(min(squeeze(EEGAll.data(GetChanNum(EEGAll,FigChan),:,:))));
YMax = max(max(squeeze(EEGAll.data(GetChanNum(EEGAll,FigChan),:,:))));

YMin = YMin - .1*abs(YMin);
YMax = YMax + .1*abs(YMax); %Pad by 10%

%figure

%Figure 1;  All Epochs
subplot(2,3,1);
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
ylim([YMin YMax]);  %this one used this scale regardles if SameScale is TRUE or FALSE
set(gca, 'YLimMode', 'manual')
set(gca, 'XLimMode', 'manual')



%Figure 2:  Retained epochs
if EEGFin.trials> 0
    subplot(2,3,2);
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


%Figure 3:  Avg epochs
% if EEGAvg.trials ==1   %KLUDGE TO FIX 1 TRIAL EPOCHS
%     EEGAvg.times = linspace(EEGAvg.xmin*1000,EEGAvg.xmax*1000, EEGAvg.pnts) ;
%     
% %     if length(EEGAvg.event) ==1
% %         EEGAvg.epoch.event = 1;
% %         EEGAvg.epoch.eventtype = EEGAvg.event.type;
% %         EEGAvg.epoch.eventlatency = 0;
% %         
% %         EEGAvg.event.epoch = 1;
% %     else
% %         error('only one epoch but mulitple events')
% %     end
% end
if EEGAvg.trials> 0
    subplot(2,3,3);
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


%Figure 4: All Rejected Epochs
% if EEGRej.trials ==1   %KLUDGE TO FIX 1 TRIAL EPOCHS
%     EEGRej.times = linspace(EEGRej.xmin*1000,EEGRej.xmax*1000, EEGRej.pnts) ;
%     
%     if length(EEGRej.event) ==1
%         EEGRej.epoch.event = 1;
%         EEGRej.epoch.eventtype = EEGRej.event.type;
%         EEGRej.epoch.eventlatency = 0;
%         
%         EEGRej.event.epoch = 1;
%     else
%         error('only one epoch but mulitple events')
%     end
% end


if EEGRej.trials > 0
    subplot(2,3,4);
    title(sprintf('%d All REJECTED epochs for SubID: %s',EEGRej.trials, EEGRej.subject),'fontsize',14);
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



%Figure 5: Auto Rejected Epochs
% if EEGRejAuto.trials ==1   %KLUDGE TO FIX 1 TRIAL EPOCHS
%     EEGRejAuto.times = linspace(EEGRejAuto.xmin*1000,EEGRejAuto.xmax*1000, EEGRejAuto.pnts);
%     
%     if length(EEGRejAuto.event) ==1
%         EEGRejAuto.epoch.event = 1;
%         EEGRejAuto.epoch.eventtype = EEGRejAuto.event.type;
%         EEGRejAuto.epoch.eventlatency = 0;
%         
%         EEGRejAuto.event.epoch = 1;
%     else
%         error('only one epoch but mulitple events')
%     end
% end


if EEGRejAuto.trials > 0
    subplot(2,3,5);
    title(sprintf('%d Auto REJECTED epochs for SubID: %s',EEGRejAuto.trials, EEGRejAuto.subject),'fontsize',14);
    xlabel('Time (ms)','fontsize',14);
    ylabel('uV','fontsize',14);
    hold on;
    
    for n = 1:EEGRejAuto.trials
        plot(EEGRejAuto.times, EEGRejAuto.data(GetChanNum(EEGRejAuto,FigChan),:,n),'color',cc(EventCodes==FindEvent0(EEGRejAuto,n),:),'LineWidth',2)
    end
    
    %create event labels for legend
    %         ECs = unique(GetTime0Events(EEGRejAuto));
    %         EventLabels=cell(length(ECs),1); %prep entries for legend
    %         for i=1:length(EventLabels)
    %             EventLabels{i,1}=(num2str(ECs(i,1)));
    %         end
    %         legend(EventLabels, 'Location', 'NorthWest');
    hold off;
    xlim([EEGRejAuto.times(1) EEGRejAuto.times(end)]);
    
    if ~SameScale
        YMin = min(min(squeeze(EEGRejAuto.data(GetChanNum(EEGRejAuto,FigChan),:,:))));
        YMax = max(max(squeeze(EEGRejAuto.data(GetChanNum(EEGRejAuto,FigChan),:,:))));

        YMin = YMin - .1*abs(YMin);
        YMax = YMax + .1*abs(YMax); %Pad by 10%
    end   
    ylim([YMin YMax]);
    set(gca, 'YLimMode', 'manual')
    set(gca, 'XLimMode', 'manual')
end

%Figure 6: Manual Rejected Epochs
% if EEGRejManual.trials ==1   %KLUDGE TO FIX 1 TRIAL EPOCHS
%     EEGRejManual.times = linspace(EEGRejManual.xmin*1000,EEGRejManual.xmax*1000, EEGRejManual.pnts);
%     
%     if length(EEGRejManual.event) ==1
%         EEGRejManual.epoch.event = 1;
%         EEGRejManual.epoch.eventtype = EEGRejManual.event.type;
%         EEGRejManual.epoch.eventlatency = 0;
%         
%         EEGRejManual.event.epoch = 1;
%     else
%         error('only one epoch but mulitple events')
%     end
% end


if EEGRejManual.trials > 0
    subplot(2,3,6);
    title(sprintf('%d Manual REJECTED epochs for SubID: %s',EEGRejManual.trials, EEGRejManual.subject),'fontsize',14);
    xlabel('Time (ms)','fontsize',14);
    ylabel('uV','fontsize',14);
    hold on;
    
    for n = 1:EEGRejManual.trials
        plot(EEGRejManual.times, EEGRejManual.data(GetChanNum(EEGRejManual,FigChan),:,n),'color',cc(EventCodes==FindEvent0(EEGRejManual,n),:),'LineWidth',2)
    end
    
    %create event labels for legend
    %         ECs = unique(GetTime0Events(EEGRejManual));
    %         EventLabels=cell(length(ECs),1); %prep entries for legend
    %         for i=1:length(EventLabels)
    %             EventLabels{i,1}=(num2str(ECs(i,1)));
    %         end
    %         legend(EventLabels, 'Location', 'NorthWest');
    hold off;
    xlim([EEGRejManual.times(1) EEGRejManual.times(end)]);
    
    if ~SameScale
        YMin = min(min(squeeze(EEGRejManual.data(GetChanNum(EEGRejManual,FigChan),:,:))));
        YMax = max(max(squeeze(EEGRejManual.data(GetChanNum(EEGRejManual,FigChan),:,:))));

        YMin = YMin - .1*abs(YMin);
        YMax = YMax + .1*abs(YMax); %Pad by 10%
    end   
    ylim([YMin YMax]);
    set(gca, 'YLimMode', 'manual')
    set(gca, 'XLimMode', 'manual')
end

if Save
    FigFilename = [Prefix 'Figure6Panel' EEG.subject '.fig'];
    saveas(gcf,fullfile(EEG.filepath, FigFilename)); %save figure to subject's reduction folder
    close (gcf); %Close figure window
end

COM = '[EEG, COM] = pop_Figure6Panel(EEG )';
end

