function [pxx,nwins,f] = pwelch_masked(dat,mask,window,noverlap,nfft,fs)
%
% function [pxx,nwins,f] = pwelch_masked(dat,mask,window,noverlap,nfft,fs)
%
% dat: vector containing time series
% mask: vector of 0s and 1s indicating good data samples
% window: number of time points for pwelch computation window
% noverlap: number of overlap points for consecutive windows
% nfft: number of fft points used to estimate the psd
% fs: sampling frequency
% this function calls pwelch for each section of good data of 
% length>=window and returns the averaged results and the number of
% windows used in the average

% setup for testing
% dat = rand(1,10000);
% window = 250;
% noverlap = 125;
% nfft = 250;
% fs = 250;
% mask = ones(1,10000); % 40 sec @ 250 Hz
% mask(1:50) = 0;
% mask(150:375) = 0;
% mask(1350:1375) = 0;
% mask(9500:10000) = 0;


nsamps = length(dat);
% find windows of sufficient length
% goodwins is cell array of 2-element vectors containing start/end samples
% of good windows
goodwins = {};
tmp = diff(mask);
pos_spikes = find(tmp>0.5);  % start of good window
neg_spikes = find(tmp<-0.5); % end of good window
if isempty(pos_spikes) & isempty(neg_spikes)  % all good data
    goodwins = {[1 nsamps]};
elseif isempty(pos_spikes) & ~isempty(neg_spikes) % single change from good to bad
    goodwins = {[1 neg_spikes(1)]};
elseif length(pos_spikes) > length(neg_spikes)    % start with bad data end with good
    goodwins = cell(1,length(pos_spikes));
    for i = 1:length(pos_spikes) - 1
        goodwins{i} = [pos_spikes(i)+1 neg_spikes(i)];
    end
    goodwins{length(pos_spikes)} = [pos_spikes(end)+1 nsamps];
elseif length(neg_spikes) > length(pos_spikes)     % start with good data end with bad
    goodwins = cell(1,length(neg_spikes));
    goodwins{1} = [1 neg_spikes(1)];
    for i = 1:length(pos_spikes)
        goodwins{i+1} = [pos_spikes(i)+1 neg_spikes(i+1)];
    end
elseif (length(pos_spikes) == length(neg_spikes)) & (neg_spikes(1) < pos_spikes(1))% start/end with good data
    goodwins = cell(1,length(neg_spikes)+1);
    goodwins{1} = [1 neg_spikes(1)];
    for i = 1:length(pos_spikes) - 1
        goodwins{i+1} = [pos_spikes(i)+1 neg_spikes(i+1)];
    end
    goodwins{length(neg_spikes)+1} = [pos_spikes(end)+1 nsamps];
else                                                                    % start/end bad data
    goodwins = cell(1,length(pos_spikes));
    for i = 1:length(pos_spikes)
        goodwins{i} = [pos_spikes(i)+1 neg_spikes(i)];
    end    
end

% remove any windows of length < window
tmp = goodwins;
clear goodwins
indx = [];
for i = 1:numel(tmp)
    if (tmp{i}(2) - tmp{i}(1) + 1) >= window
        indx = [indx i];
    end
end
goodwins = tmp(indx);
numGoodWins = numel(goodwins);
pxx_tmp = [];
wincount = zeros(1,numGoodWins);
% ready to send each window of good data to pwelch
for iwin = 1:numGoodWins
    startsamp = goodwins{iwin}(1);
    endsamp = goodwins{iwin}(2);
    numsamps = endsamp - startsamp + 1;
    % figure out how many windows with noverlap fit between startsamp and endsamp
    numWholeWins = floor(numsamps/window);
    % add in overlapped windows (one for each except last one)
    numWholeWins = numWholeWins + numWholeWins - 1;
    % add one more if there's room
    if numsamps - floor(numsamps/window)*window > window - noverlap
        numWholeWins = numWholeWins + 1;
    end
    wincount(iwin) = numWholeWins;
    [pxx,f] = pwelch(dat(startsamp:endsamp),window,noverlap,nfft,fs);
    if iwin == 1
        pxx_tmp = pxx*wincount(iwin);  %weight by number of windows used in pwelch
    else
        pxx_tmp = [pxx_tmp pxx*wincount(iwin)]; % append column for each iwin > 1
    end
end
nwins = sum(wincount);
pxx = sum(pxx_tmp,2)/nwins; % compute mean over all windows used
    
    
    
