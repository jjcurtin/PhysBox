function COM = pop_CheckERP(P)
%This function checks the summary file output from reduction of a CNT file in EEGlab.    

%Revision History: 
%2011-10-28: added the ERP_ prefix to the file name (line 100). abs 
%2011-10-28: modified to be generic based on P file, JJC

    if nargin < 1
        P = pop_GetParameters();
    end
          
    clc
    hist(P.cs_SessionTime(~P.Rejected==1))
    mST = mean(P.cs_SessionTime(~P.Rejected==1));
    sST = std(P.cs_SessionTime(~P.Rejected==1));
    FullTitle = sprintf('Session Time\nMean= %.1f; SD= %.1f', mST, sST);
    title(FullTitle, 'fontsize', 14)
    xlabel('Time (minutes)', 'fontsize', 14)
    ylabel('Frequency', 'fontsize', 14)
    uiwait
    
    hist(P.cs_nEvents(~P.Rejected==1))
    mTE = mode(P.cs_nEvents(~P.Rejected==1));
    rTE = max(P.cs_nEvents(~P.Rejected==1)) - min(P.cs_nEvents(~P.Rejected==1));
    FullTitle = sprintf('Total Event Count\nMode= %d; Range= %d', mTE, rTE);
    title(FullTitle, 'fontsize', 14)
    xlabel('Total Event Count', 'fontsize', 14)
    ylabel('Frequency', 'fontsize', 14)
    uiwait   
    
    hist(P.qn_fftMean(~P.Rejected==1))
    m60 = mean(P.qn_fftMean(~P.Rejected==1));
    s60 = std(P.qn_fftMean(~P.Rejected==1));    
    FullTitle = sprintf('Mean 60Hz Amplitude\nMean= %.1f; SD= %.1f', m60, s60);
    title(FullTitle, 'fontsize', 14)
    xlabel('Amplitude', 'fontsize', 14)
    ylabel('Frequency', 'fontsize', 14)
    uiwait   
    
    hist(P.rb_BlinkMax(~P.Rejected==1))
    mBM = mean(P.rb_BlinkMax(~P.Rejected==1));
    sBM = std(P.rb_BlinkMax(~P.Rejected==1));     
    FullTitle = sprintf('Maximum Blink Magnitude\nMean= %.1f; SD= %.1f', mBM, sBM);
    title(FullTitle, 'fontsize', 14)
    xlabel('Magnitude (microvolts)', 'fontsize', 14)
    ylabel('Frequency', 'fontsize', 14)
    uiwait          
    
    hist(P.rb_nBlink(~P.Rejected==1))
    mBC = mean(P.rb_nBlink(~P.Rejected==1));
    sBC = std(P.rb_nBlink(~P.Rejected==1));    
    FullTitle = sprintf('Number of Blinks Detected\nMean= %.1f; SD= %.1f', mBC, sBC);
    title(FullTitle, 'fontsize', 14)
    xlabel('Blink Count', 'fontsize', 14)
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
                fprintf(1 + (abs(P.cs_nEvents(i) - mTE) > 0), '\t# Events: %d\n', P.cs_nEvents(i));
                fprintf('\n');
                
                fprintf(1 + (abs(P.qn_fftMean(i) - m60) > nSDs*s60), '\tMean 60Hz Noise (microvolts): %3.1f\n', P.qn_fftMean(i));
                fprintf('\n');
                

                fprintf(1 + (~strcmpi(strtrim(P.rb_BlinkCode(i,:)), 'Success')),'\tBlink Correction Outcome: %s\n', P.rb_BlinkCode(i,:));  %in red script
                fprintf(1+ (abs(P.rb_BlinkMax(i) - mBM) > nSDs*sBM),'\tMax Blink: %.1f microvolts @ %.1f seconds\n', P.rb_BlinkMax(i), P.rb_BlinkMaxTime(i));
                fprintf(1+ (P.rb_nBlink(i) < 50), '\t# Blinks Detected: %d\n', P.rb_nBlink(i));
                FzR = P.rb_rBlink_Fz(i);
                CzR = P.rb_rBlink_Cz(i);
                PzR = P.rb_rBlink_Pz(i);
                if (P.rbBlinkDir(i) =='N' && (FzR > CzR  || CzR > PzR)) || (P.rbBlinkDir(i) =='P' && (FzR < CzR  || CzR < PzR))
                    fprintf(2, '\tMidline (Fz, Cz, Pz) Blink Coefficients: %.3f, %.3f, %.3f\n', FzR, CzR, PzR);
                else
                    fprintf('\tMidline (Fz, Cz, Pz) Blink Coefficients: %.3f, %.3f, %.3f\n', FzR, CzR, PzR);
                end
                fprintf('\n');    
                
                if exist([P.RootPath(i,:) P.SubID(i,:) '\Reduce\' strtrim(P.Prefix(i,:)) 'FFT' P.SubID(i,:) '.fig'], 'file')
                    open([P.RootPath(i,:) P.SubID(i,:) '\Reduce\' strtrim(P.Prefix(i,:)) 'FFT' P.SubID(i,:) '.fig']);
                    movegui('southwest');
                    uiwait
                else
                    fprintf(2,'\\nnWARNING, Diagnositic Figure not found:  %s\n\n', [P.RootPath(i,:) P.SubID(i,:) '\Reduce\' strtrim(P.Prefix(i,:)) 'FFT' P.SubID(i,:) '.fig']);
                end

                if exist([P.RootPath(i,:) P.SubID(i,:) '\Reduce\' 'ERPBlinks' P.SubID(i,:) '.fig'], 'file')
                    open([P.RootPath(i,:) P.SubID(i,:) '\Reduce\' 'ERPBlinks' P.SubID(i,:) '.fig']);
                    movegui('southeast');   
                    uiwait
                else
                    fprintf(2,'\\nnWARNING, Diagnositic Figure not found:  %s\n\n', [P.RootPath(i,:) P.SubID(i,:) '\Reduce\' 'ERPBlinks' P.SubID(i,:) '.fig']);
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
    COM = 'pop_CheckERP()';
end
