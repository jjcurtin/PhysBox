function [ OutEEG, COM ] = notes_RemoveBlinks( InEEG, RawBlinks, Coeffs, MaxBlink, MaxBlinkTime, AveBlink, CorrectedBlinks, BlinkErrCode, Prefix, Path )

    fprintf('notes_RemoveBlinks(): Adding notes field and creating diagnostic figure for RemoveBlinks\n')
    InEEG.notes.rb_BlinkCode = BlinkErrCode;
    InEEG.notes.rb_BlinkMax = MaxBlink;
    InEEG.notes.rb_BlinkMaxTime = MaxBlinkTime;
    if isempty(RawBlinks)
        InEEG.notes.rb_nBlinks = 0;
    else
        InEEG.notes.rb_nBlink = size(RawBlinks,2)-1;
    end
    for i = 1:length(Coeffs)
        InEEG.notes.(['rb_rBlink_' InEEG.chanlocs(i).labels]) = Coeffs(i);
    end
    
    InEEG.notes.rb_BlinksRaw = RawBlinks;  %NOTE: THIS MUST BE REMOVED BEFORE EXPORT
    if ~isempty(CorrectedBlinks)
        InEEG.notes.rb_BlinkRs = CorrectedBlinks;  %NOTE: THIS MUST BE REMOVED BEFORE EXPORT.  However, cant be removed if empty
    end
    
    OutEEG = InEEG;
    COM = '';
            
    %Diagnostic Graphs
    %all blinks subplot
    PlotCreated = false;
    if ~isempty(RawBlinks)
        RawBlinks = RawBlinks - repmat(RawBlinks(1,:),size(RawBlinks,1),1);  %Set first point in series to 0 for all blinks
        subplot(1,3, 1); 
        plot(RawBlinks(:,2:end)); 
        title(sprintf('%d Blinks for SubID: %s ', size(RawBlinks,2)-1, InEEG.subject), 'FontSize', 12);
        xlabel('Sample #', 'FontSize',12)
        ylabel('Magnitude (microvolts)', 'FontSize',12) 
        PlotCreated = true;
    end
    
    %average blinks subplot
    if ~isempty(AveBlink)
        %AveBlink = mean(RawBlinks(:,:,2:end),3);
        AveBlink = AveBlink - repmat(AveBlink(:,1),1,size(AveBlink,2));  %Set first point in series to 0 for Ave blinks
        subplot(1,3,2); 
        plot(AveBlink'); 
        title(['Average Blinks for SubID: ' InEEG.subject], 'FontSize', 12);
        xlabel('Sample #', 'FontSize',12)
        ylabel('Magnitude (microvolts)', 'FontSize',12)         
        legend(InEEG.chanlocs.labels, 'Location', 'Best')  
    end
    
    %corrected blinks subplot
    if ~isempty(CorrectedBlinks)
        CorrectedBlinks = CorrectedBlinks - repmat(CorrectedBlinks(:,1),1,size(CorrectedBlinks,2));  %Set first point in series to 0 for all blinks
        subplot(1,3,3); 
        plot(CorrectedBlinks'); 
        title(['Corrected Average Blinks for SubID: ' InEEG.subject], 'FontSize',  12); 
        xlabel('Sample #', 'FontSize',12)
        ylabel('Magnitude (microvolts)', 'FontSize',12)         
        legend(InEEG.chanlocs.labels, 'Location', 'Best')
    end
    
    %save blink diagnostic graph
    if ~PlotCreated  %create blank fig to save if no plot data availabe.
        figure;
    end
    FigFilename = [Prefix 'Blinks' InEEG.subject '.fig'];
    saveas(gcf, fullfile(Path, FigFilename)); %save figure to subject's reduction folder        
    close (gcf); %Close figure window
end
    
    