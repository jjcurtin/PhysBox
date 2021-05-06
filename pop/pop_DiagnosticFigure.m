function [ COM ] = pop_DiagnosticFigure(FigChan, Prefix, EEG1, EEG2, EEG3  )
    COM = '[ COM ] = pop_DiagnosticFigure(FigChan )';
    fprintf('pop_DiagnosticFigure(): Creating a diagnostic figure for data integrity checking\n')
    
    nFigs = 3; %assume 3 figs to create

    if nargin < 5
        EEG3 = [];
        nFigs = nFigs -1;
    end
    
    if nargin < 4
        EEG2 = [];
        nFigs = nFigs -1;
    end
    if nargin < 3
        pophelp('pop_DiagnosticFigure');
        return
    end
    
    if ~isempty(EEG2) && ~strcmpi(EEG1.subject,EEG2.subject)
        error('pop_DiagnositicFigure(): SubID does not match for EEG1 (%s) and EEG2 (%s)\n',EEG1.subject, EEG2.subject)
    end
    if ~isempty(EEG3) && ~strcmpi(EEG2.subject,EEG3.subject)
        error('pop_DiagnositicFigure(): SubID does not match for EEG2 (%s) and EEG3 (%s)\n',EEG2.subject, EEG3.subject)
    end    
   
    
    %Establish list of Event codes across SETS
    EventCodes = unique(GetTime0Events(EEG1));   
    if ~isempty(EEG2)
        EventCodes = [EventCodes ;unique(GetTime0Events(EEG2))];
    end
    if ~isempty(EEG3)
        EventCodes = [EventCodes ;unique(GetTime0Events(EEG3))];
    end    
    EventCodes = unique(EventCodes);
    
    %create event labels for legend
    EventLabels=cell(length(EventCodes),1); %prep entries for legend
    for i=1:length(EventLabels)
        EventLabels{i,1}=(num2str(EventCodes(i,1)));
    end    
    

    %Create color cube for lines
    if length(EventCodes)  < 7
        cc = colormap(lines(length(EventCodes)));
    else
        cc=colorcube(length(EventCodes)+1); %create list of colors evenly divided within RGB space; last color created is always white, add 1 to prevent non-display.  <8 returns grayscale
    end    
    
    %get ymin and ymax
    YMin = min(min(squeeze(EEG1.data(GetChanNum(EEG1,FigChan),:,:))));
    YMax = max(max(squeeze(EEG1.data(GetChanNum(EEG1,FigChan),:,:))));
    
    if ~isempty(EEG2)
        YMin = min([min(min(squeeze(EEG2.data(GetChanNum(EEG2,FigChan),:,:)))) YMin]);
        YMax = max([max(max(squeeze(EEG2.data(GetChanNum(EEG2,FigChan),:,:)))) YMax]);
    end
    
    if ~isempty(EEG3)
        YMin = min([min(min(squeeze(EEG3.data(GetChanNum(EEG3,FigChan),:,:)))) YMin]);
        YMax = max([max(max(squeeze(EEG3.data(GetChanNum(EEG3,FigChan),:,:)))) YMax]);
    end    
    YMin = YMin - .1*abs(YMin);
    YMax = YMax + .1*abs(YMax); %Pad by 10%
           
    %figure
    
    %Figure 1;  At least one fig required
    subplot(1,nFigs,1);
    title(sprintf('%d epochs for %s for SubID: %s',EEG1.trials, EEG1.setname, EEG1.subject),'fontsize',14);
    xlabel('Time (ms)','fontsize',14); 
    ylabel('uV','fontsize',14); 
    hold on; %hold graph elements constant while adding trial lines
    for n = 1:EEG1.trials
        plot(EEG1.times, EEG1.data(GetChanNum(EEG1,FigChan),:,n),'color',cc(EventCodes==FindEvent0(EEG1,n),:),'LineWidth',2)
    end
    if nFigs==1
        legend(EventLabels);
    end
    hold off;  
    ylim([YMin YMax]);
    
    if ~isempty(EEG2)
        subplot(1,nFigs,2); 
        title(sprintf('%d epochs for %s for SubID: %s',EEG2.trials, EEG2.setname, EEG2.subject),'fontsize',14);
        xlabel('Time (ms)','fontsize',14); 
        ylabel('uV','fontsize',14); 
        hold on;
        for n = 1:EEG2.trials
            plot(EEG2.times, EEG2.data(GetChanNum(EEG2,FigChan),:,n),'color',cc(EventCodes==FindEvent0(EEG2,n),:),'LineWidth',2)            
        end
        if nFigs==2
            legend(EventLabels);
        end
        hold off;  
        ylim([YMin YMax]);
    end
    
    if ~isempty(EEG3)
        subplot(1,nFigs,3); 
        title(sprintf('%d epochs for %s for SubID: %s',EEG3.trials, EEG3.setname, EEG3.subject),'fontsize',14);
        xlabel('Time (ms)','fontsize',14); 
        ylabel('uV','fontsize',14); 
        hold on;
        for n = 1:EEG3.trials
            plot(EEG3.times, EEG3.data(GetChanNum(EEG3,FigChan),:,n),'color',cc(EventCodes==FindEvent0(EEG3,n),:),'LineWidth',2)            
        end
        if nFigs==3
            legend(EventLabels);
        end
        hold off;   
        ylim([YMin YMax]);
    end    

        
               
    FigFilename = [Prefix 'Diagnostic' EEG1.subject '.fig'];
    saveas(gcf,fullfile(EEG1.filepath, FigFilename)); %save figure to subject's reduction folder        
    close (gcf); %Close figure window     
end

