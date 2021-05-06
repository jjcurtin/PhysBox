%USAGE:  [ym, f] = eeg_FastFourier(EEG, nWIN, ch, f1, f2, nFFT)
% eeg_FastFourier calculates the Single-Sided Amplitude Spectrum for
% continuous EEG structure.  Returns the module (magnitude) ym of the FFT 
%evaluated at channels ch (numeric array; default is all channels), between 
%the frequencies f1 (default is 0 Hz) and f2 (default is Nyquist = srate/2).
% f contains the frequency range.  NWin is the length of the windows (in
% samples; defaults to 2*EEG.srate = 2 seconds), nFFT is the number of points in the FFT (defauls to nWin).
%nWin does not need to be a power of 2 although there may be some speed benefit if a power of 2 is used.  
%nFFT defaults to the length of nWIN.  if nFFT is set to be longer than
%nWIN, nWIN is zero padded to the length of nFFT.  If nWIN is longer than
%nFFT, the extra points in nWIN are ignored.
%Frequeny resolution is Fs/nFFT.  Defaults (nFFT = nWIN = 2*Fs) yield 0.5Hz resolution
%Modeled on ERPLAB function  fourieeg() but with important bug fixes and improvments.
% See also fft(), eeglab(), eegplugin_PhysBox()
%Author:  John Curtin (jjcurtin@wisc.edu)
%
%NEED TO CONFIRM IF AVERAGE ACROSS WINDOWS SHOUDL BE DONE AMPLITUDE OR POWER.  I
%CHOOSE POWER BASED ON PWELCH_MASKED
%
%NEED TO CONSIDER BOUNDRY EVENTS

%Revision history
%2011-11-04:  Released, JJC

function [ym, f] = eeg_FastFourier(EEG, nWIN, ch, f1, f2, nFFT)

    if nargin < 1
            ym = [];
            f = [];
            help eeg_FastFourier
            return
    end

    fs    = EEG.srate;
    fNYQ  = fs/2;

    if nargin < 2 || isempty(nWIN)
        nWIN = 2 * EEG.srate;  %2 seconds of data
    end

    if nargin<6 || isempty(nFFT)
            nFFT = nWIN;
            %nFFT = 2^nextpow2(nWIN);  %Not necessary on modern fast computers
    end

    if nargin < 5 || isempty(f2)
        f2 = fNYQ;
    end

    if nargin < 4 || isempty(f1)
        f1 = 0;
    end

    if nargin < 3 || isempty(ch)
       ch = 1:size(EEG.data,1);
    end

    if ~isempty(EEG.epoch)
        error ('eeg_FastFourier() requires continuous SET file')
    end

    nWindows = floor(EEG.pnts/nWIN);   %was round but doesnt seem right?

    %f = fNYQ*linspace(0,1,nFFT/2);   %frequencies to evaluate fft
    f = (0:nFFT-1) * fs/nFFT;  %at these frequencies   (FROM MATLAB)
    NumUniquePts = ceil((nFFT+1)/2);  %ym is symetric, discard second half  (FROM MATLAB)
    %winfft = zeros(nWindows, nFFT/2, length(ch));  %array to hold fft results
    winfft = zeros(nWindows, NumUniquePts, length(ch));  %array to hold fft results

    for k=1:length(ch)
            a = 1; b = nWIN; i = 1;

            while i<=nWindows && b<=EEG.pnts
                
                
                    y = detrend(EEG.data(ch(k),a:b));                    
                    Y = fft(y,nFFT)/nWIN; %normalize based on length of data                    
                    Y = abs(Y);  %take magnitude
                    Y = Y(1:NumUniquePts);  %redudce to first half (second half is symmetric
                    % Since we dropped half the FFT, we multiply Y by 2 to keep the same energy.
                    % The DC component and Nyquist component, if it exists, are unique and should not be multiplied by 2. 
                    if rem(nFFT, 2) % odd nfft excludes Nyquist point 
                      Y(2:end) = Y(2:end)*2;
                    else
                      Y(2:end -1) = Y(2:end-1)*2;
                    end    
                    
                    winfft(i,:,k) = Y;  %take magnitude
                                    
                    a = b - round(nWIN/2); % 50% overlap
                    b = b + round(nWIN/2); % 50% overlap
                    i = i+1;                
                
                
                      %from fouriereeg()                
%                     y = detrend(EEG.data(ch(k),a:b));
%                     Y = fft(y,nFFT)/nWIN;
%                     winfft(i,:,k) = 2*abs(Y(1:nFFT/2));
%                     a = b - round(nWIN/2); % 50% overlap
%                     b = b + round(nWIN/2); % 50% overlap
%                     i = i+1;


                    %From matlab website
%                     y = detrend(EEG.data(ch(k),a:b));
%                     ym = fft(y, nFFT);
%                     
%                     ym = ym(1:NumUniquePts);
% 
%                     ym = abs(ym);  %take magnitude
%                     ym = ym / nWIN;  %normalize based on window length
% 
%                     ym = ym .^2;  %convert to power
% 
%                     % Since we dropped half the FFT, we multiply mx by 2 to keep the same energy.
%                     % The DC component and Nyquist component, if it exists, are unique and should not be multiplied by 2. 
%                     if rem(nFFT, 2) % odd nfft excludes Nyquist point 
%                       ym(2:end) = ym(2:end)*2;
%                     else
%                       ym(2:end -1) = ym(2:end-1)*2;
%                     end
% 
% %                     %Convert back to amplitude (RMS)  %DO THIS CONVERSION AFTER AVERAGING
% %                     ym = ym .^.5;
%                     
%                     winfft(i,:,k) = ym;
%                     a = b - round(nWIN/2); % 50% overlap
%                     b = b + round(nWIN/2); % 50% overlap
%                     i = i+1;                    
            end
    end

    avgfft = mean(winfft,1);
    avgfft = reshape(avgfft,size(avgfft,2), size(avgfft,3));

    f1sam  = find(f<=f1, 1, 'last');   
    f2sam  = find(f<=f2, 1, 'last');  
    f = f(f1sam:f2sam);
    ym = avgfft(f1sam:f2sam,:);


end
%peak voltage of sine wave = sqrt(2) * RMS (amplitude) of sine wave as per FFT

%NOTES
%NOTE THAT THESE SITES SEEM TO BE WRONG!
%http://www.mathworks.com/help/techdoc/math/brentm1-1.html
%http://www.mathworks.com/support/tech-notes/1700/1702.html
%http://www.mathworks.com/support/tech-notes/1700/1703.html




%http://blog.prosig.com/2009/04/22/10-great-fourier-transform-links/
%http://complextoreal.com/tutorial.htm
%http://research.opt.indiana.edu/Library/FourierBook/toc.html


%% Exmple 1:  60 Hz noise, full cycles.  parameters selected to have FFT evaluated at 60 using FFT
% Fs = 2000;				
% 
% % Time vector;
% % To create exactly 4000 points, 
% % we have subtracted 1/Fs
% Duration = 600;  %600 seconds
% t = 0:1/Fs:Duration-1/Fs;
% 
% 		
% % Signal
% y = 2*sin(2*pi*t*60);		
% 
% nfft = 2*Fs; % length(y);
% ym = fft(y, nfft);
% f = Fs*(0:nfft-1)/nfft;  %at these frequencies
% 
% NumUniquePts = ceil((nfft+1)/2);  %ym is symetric, discard second half
% ym = ym(1:NumUniquePts);
% 
% ym = abs(ym);  %take magnitude
% ym = ym / nfft;  %normalize 
% 
% % Since we dropped half the FFT, we multiply mx by 2 to keep the same energy.
% % The DC component and Nyquist component, if it exists, are unique and should not be multiplied by 2. 
% if rem(nfft, 2) % odd nfft excludes Nyquist point 
%   ym(2:end) = ym(2:end)*2;
% else
%   ym(2:end -1) = ym(2:end-1)*2;
% end
% 
% 
% %plot it
% plot(f(1:length(ym)),ym)




%% Examle 2: Same but with eeg_FastFourier

% Fs = 2000;				
% 
% % Time vector;
% % To create exactly 4000 points, 
% % we have subtracted 1/Fs
% Duration = 600;  %600 seconds
% t = 0:1/Fs:Duration-1/Fs;
% 
% 		
% % Signal
% y = 2*sin(2*pi*t*60);		
% 
% 
% 
% %Set up EEG
% EEG = eeg_emptyset;
% EEG.pnts = length(t);
% EEG.data = y;
% EEG.srate = Fs;
% 
% nfft = 2*EEG.srate; % length(y);
% %ym = fft(y, winlen);
% [ym, f] = eeg_FastFourier(EEG, nfft, 1, [], [], nfft);
% 
% %plot it
% plot(f(1:length(ym)),ym)
