%USAGE: COM = pop_CheckStartle(P)
%This function checks the summary file output from reduction for STL.    

%Revision History: 
%2011-10-28: added the ERP_ prefix to the file name (line 100). abs 
%2011-10-28: modified to be generic based on P file, JJC
%2011-11-23:  updated for new ScoreStartle output, JJC
%2012-01-21: edited most field names of calls to the P struct to reflect recent changes in parameter file column labeling, MJS

function COM = pop_CheckStartle(P)
    if nargin < 1
        P = pop_GetParameters();
    end
          
    clc
    
    %Session time
    hist(P.cs_SessionTime(~P.Rejected==1))
    mST = mean(P.cs_SessionTime(~P.Rejected==1));
    sST = std(P.cs_SessionTime(~P.Rejected==1));
    FullTitle = sprintf('Session Time\nMean= %.1f; SD= %.1f', mST, sST);
    title(FullTitle, 'fontsize', 14)
    xlabel('Time (minutes)', 'fontsize', 14)
    ylabel('Frequency', 'fontsize', 14)
    uiwait 
 
    %Number of Conditions   
    hist(P.ss_nConditions(~P.Rejected==1))
    mNC = mode(P.ss_nConditions(~P.Rejected==1));
    rNC = max(P.ss_nConditions(~P.Rejected==1)) - min(P.ss_nConditions(~P.Rejected==1));
    FullTitle = sprintf('Number of Conditions\nMode= %d; Range= %d', mNC, rNC);
    title(FullTitle, 'fontsize', 14)
    xlabel('Trials', 'fontsize', 14)
    ylabel('Frequency', 'fontsize', 14)
    uiwait     
    
    %Raw Number of trials   
    hist(P.re_nVal(~P.Rejected==1)+ P.re_nRej(~P.Rejected==1))
    mNT = mode(P.re_nVal(~P.Rejected==1)+ P.re_nRej(~P.Rejected==1));
    rNT = max(P.re_nVal(~P.Rejected==1)+ P.re_nRej(~P.Rejected==1)) - min(P.re_nVal(~P.Rejected==1)+ P.re_nRej(~P.Rejected==1));
    FullTitle = sprintf('Raw Number of Startle Trials\nMode= %d; Range= %d', mNT, rNT);
    title(FullTitle, 'fontsize', 14)
    xlabel('Trials', 'fontsize', 14)
    ylabel('Frequency', 'fontsize', 14)
    uiwait       
    
    
    %Number of rejected trials
    hist(P.re_nRej(~P.Rejected==1))
    mRT = mean(P.re_nRej(~P.Rejected==1));
    sRT = std(P.re_nRej(~P.Rejected==1)) - min(P.re_nRej(~P.Rejected==1));
    FullTitle = sprintf('Number of Rejected Startle Trials\nMean= %.1f; SD= %.1f', mRT, sRT);
    title(FullTitle, 'fontsize', 14)
    xlabel('Trials', 'fontsize', 14)
    ylabel('Frequency', 'fontsize', 14)
    uiwait      
    
    %Final Number trials for each event type
    fields = fieldnames(P);
    EventFields = strfind(fields, 'ss_nVal');
    fCtr = 0;
    for i=1:length(fields)
        if (~isempty(EventFields{i})) && (~strcmp('ss_nVal', fields{i}))  %contains but not only ss_nVal
            fCtr = fCtr+1;
            hist(P.(fields{i})(~P.Rejected==1))
            mEC(fCtr) = mode(P.(fields{i})(~P.Rejected==1));
            rEC(fCtr) = max(P.(fields{i})(~P.Rejected==1)) - min(P.(fields{i})(~P.Rejected==1));
            EventFieldNames{fCtr} = fields{i};
            FullTitle = sprintf('Final Number trials for %s\nMode= %d; Range = %d', fields{i}, mEC(fCtr), rEC(fCtr));
            title(FullTitle, 'fontsize', 14)
            xlabel('Event Count', 'fontsize', 14)
            ylabel('Frequency', 'fontsize', 14)
            uiwait                              
        end
    end
    
   
    %60 Hz noise
    hist(P.qn_fftORB(~P.Rejected==1))   %NOTE: THIS ASSUMES ORB channel LABELED ORB
    m60 = mean(P.qn_fftORB(~P.Rejected==1));
    s60 = std(P.qn_fftORB(~P.Rejected==1));    
    FullTitle = sprintf('Mean 60Hz Amplitude for ORB\nMean= %.1f; SD= %.1f', m60, s60);
    title(FullTitle, 'fontsize', 14)
    xlabel('Amplitude', 'fontsize', 14)
    ylabel('Frequency', 'fontsize', 14)
    uiwait   

    %Base Range
    hist(P.ss_BaseRange(~P.Rejected==1)) 
    mBR = mean(P.ss_BaseRange(~P.Rejected==1));
    sBR = std(P.ss_BaseRange(~P.Rejected==1));    
    FullTitle = sprintf('Mean Baseline Deflection Range\nMean= %.1f; SD= %.1f', mBR, sBR);
    title(FullTitle, 'fontsize', 14)
    xlabel('Amplitude', 'fontsize', 14)
    ylabel('Frequency', 'fontsize', 14)
    uiwait         
    
    %Percent No Responses
    hist(P.ss_pNR(~P.Rejected==1))
    mNR = mean(P.ss_pNR(~P.Rejected==1));
    sNR = std(P.ss_pNR(~P.Rejected==1));     
    FullTitle = sprintf('Percent No Response Trials\nMean= %.1f; SD= %.1f', mNR, sNR);
    title(FullTitle, 'fontsize', 14)
    xlabel('Percent', 'fontsize', 14)
    ylabel('Frequency', 'fontsize', 14)
    uiwait        
    
    %Mean STL Mag
    hist(P.ss_MeanSTLMag(~P.Rejected==1))
    mSM = mean(P.ss_MeanSTLMag(~P.Rejected==1));
    sSM = std(P.ss_MeanSTLMag(~P.Rejected==1));    
    FullTitle = sprintf('Mean STL Magnitude\nMean= %.1f; SD= %.1f', mSM, sSM);
    title(FullTitle, 'fontsize', 14)
    xlabel('Magnitude (microvolts)', 'fontsize', 14)
    ylabel('Frequency', 'fontsize', 14)
    uiwait  
    
    %Mean STL Latency
    hist(P.ss_MeanSTLLat(~P.Rejected==1))
    mSL = mean(P.ss_MeanSTLLat(~P.Rejected==1));
    sSL = std(P.ss_MeanSTLLat(~P.Rejected==1));    
    FullTitle = sprintf('Mean STL Latency\nMean= %.1f; SD= %.1f', mSL, sSL);
    title(FullTitle, 'fontsize', 14)
    xlabel('Latency (ms)', 'fontsize', 14)
    ylabel('Frequency', 'fontsize', 14)
    uiwait       
    
    %Mean PRB Mag
    hist(P.ss_MeanPRBMag(~P.Rejected==1))
    mPM = mean(P.ss_MeanPRBMag(~P.Rejected==1));
    sPM = std(P.ss_MeanPRBMag(~P.Rejected==1));    
    FullTitle = sprintf('Mean PRB Magnitude\nMean= %.1f; SD= %.1f', mPM, sPM);
    title(FullTitle, 'fontsize', 14)
    xlabel('Magnitude (microvolts)', 'fontsize', 14)
    ylabel('Frequency', 'fontsize', 14)
    uiwait  
    
    %Mean PRB Latency
    hist(P.ss_MeanPRBLat(~P.Rejected==1))
    mPL = mean(P.ss_MeanPRBLat(~P.Rejected==1));
    sPL = std(P.ss_MeanPRBLat(~P.Rejected==1));    
    FullTitle = sprintf('Mean PRB Latency\nMean= %.1f; SD= %.1f', mPL, sPL);
    title(FullTitle, 'fontsize', 14)
    xlabel('Latency (ms)', 'fontsize', 14)
    ylabel('Frequency', 'fontsize', 14)
    uiwait      
    
    CheckSub = questdlg('', 'User Input Requested', 'Check Individual Subjects', 'Exit', 'Check Individual Subjects');            
    if strcmpi(CheckSub, 'Check Individual Subjects')   

        close all
    
        %loop trhough all subjects
        nSets = ms_CountSets(P);
        for i=1:nSets
            check = true;  %assume checking unless reject or already checked
            if (P.Rejected(i)==1)  %will check auto rejects
                check = false;
            end
            if P.Checked(i)
                check = false;
            end
            if check
                clc %clear command window
                fprintf('Checking SubID: %s\n', P.SubID(i,:))
                fprintf('\tReject Status:  %d\n', P.Rejected(i));
                fprintf('\tReject Notes:  %s\n', P.RejectNotes(i,:));
                fprintf('\tComments:  %s\n', P.Comments(i,:));
                fprintf('\n');
                
                nSDs = 2.5; %flag if 2.5 SDs from mean or greater
                fprintf(1 + (abs(P.cs_SessionTime(i) - mST) > nSDs*sST), '\tSession Time (minutes): %.2f\n', P.cs_SessionTime(i));             
                fprintf('\n');
                
                fprintf(1 + (abs(P.re_nVal(i) + P.re_nRej(i) - mNT) > 0), '\tRaw Number of Trials: %d\n', P.re_nVal(i)+ P.re_nRej(i));   
                fprintf(1 + (abs(P.ss_nConditions(i) - mNC) > 0), '\tRaw Number of Conditions (Event Types): %d\n', P.ss_nConditions(i));   
                fprintf(1 + (P.re_nRej(i)/(P.re_nRej(i)+P.ss_nVal(i)) > .20), '\tNumber of Rejected Trials: %d\n', P.re_nRej(i));   % VERIFY nRej and pRej are coded here correctly!! -MJS, 01-21-2012
                fprintf(1 + (P.re_nRej(i)/(P.re_nRej(i)+P.ss_nVal(i)) > .20), '\tProportion of Rejected Trials: %0.2f\n\n', P.re_pRej(i));
                
                for j = 1:fCtr
                    fprintf(1 + (abs(P.(EventFieldNames{j})(i) - mEC(j)) > 0), '\tFinal Number of Trials for %s: %d\n', EventFieldNames{j}, P.(EventFieldNames{j})(i));
                end
                fprintf('\n');                
                
                fprintf(1 + (abs(P.qn_fftORB(i) - m60) > nSDs*s60), '\tMean 60Hz Noise (microvolts) for ORB: %.1f\n', P.qn_fftORB(i));
                fprintf(1 + (abs(P.ss_BaseRange(i) - mBR) > nSDs*sBR), '\tMean Baseline Deflection Range: %.1f\n', P.ss_BaseRange(i));   
                fprintf(1 + (P.ss_pNR(i) > .40), '\tPercent No Response Trials: %.2f\n', P.ss_pNR(i));                     
                fprintf('\n');
                
                fprintf(1 + (abs(P.ss_MeanSTLMag(i) - mSM) > nSDs*sSM), '\tMean STL Magniude (microvolts): %.1f\n', P.ss_MeanSTLMag(i));
                fprintf(1 + (abs(P.ss_MeanSTLLat(i) - mSL) > nSDs*sSL), '\tMean STL Latency (ms): %.1f\n', P.ss_MeanSTLLat(i)); 
                fprintf(1 + (abs(P.ss_MeanPRBMag(i) - mPM) > nSDs*sPM), '\tMean PRB Magnitude: %.1f\n', P.ss_MeanPRBMag(i));  
                fprintf(1 + (abs(P.ss_MeanPRBLat(i) - mPL) > nSDs*sPL), '\tMean PRB Latency(ms): %.2f\n', P.ss_MeanPRBLat(i));                     
                fprintf('\n');                                 
                
                if exist([P.RootPath(i,:) P.SubID(i,:) '\Reduce\' strtrim(P.Prefix(i,:)) 'FFT' P.SubID(i,:) '.fig'], 'file')
                    open([P.RootPath(i,:) P.SubID(i,:) '\Reduce\' strtrim(P.Prefix(i,:)) 'FFT' P.SubID(i,:) '.fig']);
                    movegui('southwest');
                    uiwait
                else
                    fprintf(2,'\n\nWARNING, FFT diagnostic figure not found:  %s\n\n', [P.RootPath(i,:) P.SubID(i,:) '\Reduce\' strtrim(P.Prefix(i,:)) 'FFT' P.SubID(i,:) '.fig']);
                end

                if exist([P.RootPath(i,:) P.SubID(i,:) '\Reduce\' strtrim(P.Prefix(i,:)) 'AVG' P.SubID(i,:) '.fig'], 'file')
                    open([P.RootPath(i,:) P.SubID(i,:) '\Reduce\' strtrim(P.Prefix(i,:)) 'AVG' P.SubID(i,:) '.fig']);
                    movegui('southeast');   
                    uiwait
                else
                    fprintf(2,'\\nnWARNING, STL Diagnostic figure not found:  %s\n\n', [P.RootPath(i,:) P.SubID(i,:) '\Reduce\' strtrim(P.Prefix(i,:)) 'STL' P.SubID(i,:) '.fig']);
                end                    

                ViewData = questdlg('', 'User Input Requested', 'View CNT/SET', 'Next Subject', 'Exit', 'Next Subject');
                close all
                if strcmpi(ViewData, 'View CNT/SET')   
                     eeglab redraw
                     uiwait
                     Next = questdlg('', 'User Input Requested', 'Next Subject', 'Exit', 'Next Subject');
                     if strcmpi(Next, 'Exit')
                         break;
                     end
                else            
                    if strcmpi(ViewData, 'Exit') 
                        break;  %break out of for loop
                    end
                end
            end
        end        
    end
    
    fprintf(2,'\n\nIMPORTANT: Make sure Checked and other relevent fields in Parameter file are updated\n');
    COM = 'pop_CheckStartle()';
end
