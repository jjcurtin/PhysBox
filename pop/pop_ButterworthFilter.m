
%USAGE:  EEG = pop_ButterworthFilter( InEEG, locutoff, hicutoff, filterorder, NPasses, boundary)
%Applies low, high or bandpass butterworth filter to CON or EPH file.
%Uses matlab's filtfilt to do forward and backward application.   This
%function uses part of the code from Luck's ERPLab to implement the
%butterworth filter.
%
%INPUTS:
%EEG         - input dataset
%locutoff    - lower edge of the frequency pass band (Hz)  {0 -> lowpass}
%hicutoff    - higher edge of the frequency pass band (Hz) {0 -> highpass}
%filterorder - length of the filter in points.  Must be even b/c of filtfilt()
%nPasses - number of passes can be 1 for forward using filter() or 2 for zero-phase shift
%          forward-reverse using filtfilt()
%boundary    - numeric event code for boundary events (only valid for continuous data)
%
%Outputs:
%EEG   (filtered) output dataset
%COM:  COM to record processing



function [EEG, COM] = pop_ButterworthFilter( EEG, locutoff, hicutoff, filterorder, NPasses, boundary)
    if nargin < 1
        help pop_ButterworthFliter
        return
    end

    COM = 'EEG = pop_ButterworthFilter( EEG )';

    if nargin < 6        
        geoh = {[2 0.5] [2 0.5] [2 0.5] [2 0.5] [2 0.5]};
                                   
        ui = {...
        { 'style', 'text', 'string', 'High Pass frequency cutoff (0 for Low-Pass only):'}...
        { 'style', 'edit', 'string', '0', 'tag', 'lowcutoff'  } ... 
        { 'style', 'text', 'string', 'Low Pass frequency cutoff (0 for High-Pass only)' } ...
        { 'style', 'edit', 'string', '0', 'tag', 'hicutoff'  } ...  
        { 'style', 'text', 'string', 'Filter order (must be even if # Passes=2):' } ...
        { 'style', 'edit', 'string', '2', 'tag', 'filterorder'  } ...
        { 'style', 'text', 'string', '# Passes (1=forward; 2=forward-reverse)' } ...
        { 'style', 'edit', 'string', '2', 'tag', 'NPasses'  } ...
        { 'style', 'text', 'string', 'boundary event code:' } ...
        { 'style', 'edit', 'string', '0', 'tag', 'boundary'  } ...
        };

        [a b c Results] = inputgui('geometry', geoh,  'uilist', ui, 'title', 'pop_ButterworthFilter() parameters');
        if isempty(Results); return; end        
        
        locutoff = str2double(Results.lowcutoff);        
        hicutoff = str2double(Results.hicutoff);  
        filterorder = str2double(Results.filterorder);
        NPasses = str2double(Results.NPasses);
        boundary = str2double(Results.boundary);    
    end
    
    fprintf('\npop_ButterworthFilter(): Applying Butterworth filter\n');
 
    if NPasses < 1 || NPasses > 2
        error('nPasses (%d) must be 1 (forward) or 2 (forward-reverse)\n', NPasses);
    end
    
    chanArray = 1:EEG.nbchan;
    fnyq  = 0.5*EEG.srate;       % half sample rate

    if exist('filtfilt','file') ~= 2
        error('Butterworth filter requires signal processing toolbox\n');
    end

    if locutoff == 0 && hicutoff == 0
          error('locutoff and hicutoff cannot both be zero')
    end

    if EEG.pnts <= 3*filterorder
          error('Length of data (%d) must be more than 3x the filter order (%d)', EEG.pnts, filterorder);
    end

    if ~isempty(EEG.epoch)
        boundary = []; % not allowed for epoched data
    end

    if locutoff >= fnyq
          error('Low cutoff frequency (%d) cannot be >= srate (%d)/2', locutoff, EEG.srate);
    end

    if hicutoff >= fnyq
          error('High cutoff frequency (%d) cannot be >= srate (%d)/2', hicutoff, EEG.srate);      
    end 

    if mod(filterorder,2)~=0
          error('Filter order (%d) must be even because of the forward-reverse filtering  in FiltFilt().', filterorder)
    end


    %CONSIDER CHECK IF DEFAULT boundary EVENTS EXIST (type 0)

    if NPasses ==2
        theorder = filterorder/2; % Because of filtfilt performs a forward-reverse filtering, it doubles the filter order
    else
        theorder = filterorder;
    end
    
    if hicutoff>0 && locutoff==0  % Low Pass
        [b,a]   = butter(theorder,hicutoff/fnyq); % low pass filter
        labelf = 'Low-pass';
    end

    if hicutoff==0 && locutoff>0   % High Pass
        [b,a]   = butter(theorder,locutoff/fnyq, 'high'); % high pass filter  
        labelf = 'High-pass';
    end

    if hicutoff>0 && locutoff>0 && (hicutoff>locutoff)   % Band Pass
        [bl,al]   = butter(theorder,hicutoff/fnyq);
        [bh,ah]   = butter(theorder,locutoff/fnyq, 'high');
        b  = [bl; bh];
        a  = [al; ah];      
        labelf = 'Band-pass';
    end


    if ~isempty(boundary)  %only continuous data
        if ~isempty(EEG.event)
            events = [EEG.event.type]; %array of all event codes
            indxbound  = find(events==boundary);  %index of boundary event codes
        else   % no events in file
            indxbound = [];
        end
            

        if ~isempty(indxbound)

            %I DONT GET THIS CODE.  KEEP TEST WITH ERROR BUT COMMENT OUT ALL
            %ELSE TO SEE IF IT GETS CALLED
            timerange = [ EEG.xmin*1000 EEG.xmax*1000 ];
            if timerange(1)/1000~=EEG.xmin || timerange(2)/1000~=EEG.xmax
                  error('FilterError.  Consult code in eeg_Butterworth Filter')
    %               posi = round( (timerange(1)/1000-EEG.xmin)*EEG.srate )+1;
    %               posf = min(round( (timerange(2)/1000-EEG.xmin)*EEG.srate )+1, EEG.pnts );
    %               pntrange = posi:posf;
            end
            if exist('pntrange', 'var')
                  latebound = [ EEG.event(indxbound).latency ] - 0.5 - pntrange(1) + 1;
                  latebound(latebound>=pntrange(end) - pntrange(1)) = [];
                  latebound(latebound<1) = [];
                  latebound = [0 latebound pntrange(end) - pntrange(1)];
            else
                  latebound = [0 [ EEG.event(indxbound).latency ] - 0.5 EEG.pnts ];  %not sure about -.5 but rounded below
            end
            latebound = round(latebound);  %effectively removes the -.5 above
        else
            latebound = [0 EEG.pnts];
        end
    else
          latebound = [0 EEG.pnts];
    end

    nibound   = length(latebound);

    %
    % Warning off
    %
    %warning off MATLAB:singularMatrix

    for j=1:EEG.trials
          q=1;
          while q<=nibound-1  % segments among boundaries

                bp1 = latebound(q)+1;
                bp2 = latebound(q+1);

                if length(bp1:bp2)>3*filterorder

                      if j==1
                            if nibound>2
                                  fprintf('%s filtering data from segment %g to %g (in samples), please wait...\n', labelf, bp1, bp2)
                            else
                                  fprintf('%s filtering data, please wait...\n', labelf);
                            end
                      end
                      if size(b,1)>1    %bandpass        

                          if isdouble(EEG.data)
                                if NPasses ==1
                                    EEG.data(chanArray,bp1:bp2,j) = filter(b(1,:),a(1,:), EEG.data(chanArray,bp1:bp2,j)')';
                                    EEG.data(chanArray,bp1:bp2,j) = filter(b(2,:),a(2,:), EEG.data(chanArray,bp1:bp2,j)')';                                    
                                else
                                    EEG.data(chanArray,bp1:bp2,j) = filtfilt(b(1,:),a(1,:), EEG.data(chanArray,bp1:bp2,j)')';
                                    EEG.data(chanArray,bp1:bp2,j) = filtfilt(b(2,:),a(2,:), EEG.data(chanArray,bp1:bp2,j)')';
                                end
                          else
                                if NPasses ==1
                                    EEG.data(chanArray,bp1:bp2,j) = single(filter(b(1,:),a(1,:), double(EEG.data(chanArray,bp1:bp2,j))')');
                                    EEG.data(chanArray,bp1:bp2,j) = single(filter(b(2,:),a(2,:), double(EEG.data(chanArray,bp1:bp2,j))')');                                     
                                else
                                    EEG.data(chanArray,bp1:bp2,j) = single(filtfilt(b(1,:),a(1,:), double(EEG.data(chanArray,bp1:bp2,j))')');
                                    EEG.data(chanArray,bp1:bp2,j) = single(filtfilt(b(2,:),a(2,:), double(EEG.data(chanArray,bp1:bp2,j))')');     
                                end
                          end

                      else
                            % Butterworth lowpass or highpass
                            if isdouble(EEG.data)
                                if NPasses ==1
                                    EEG.data(chanArray,bp1:bp2,j) = filter(b,a, EEG.data(chanArray,bp1:bp2,j)')';
                                else
                                    EEG.data(chanArray,bp1:bp2,j) = filtfilt(b,a, EEG.data(chanArray,bp1:bp2,j)')';
                                end
                            else
                                if NPasses ==1
                                    EEG.data(chanArray,bp1:bp2,j) = single(filter(b,a, double(EEG.data(chanArray,bp1:bp2,j))')');
                                else
                                    EEG.data(chanArray,bp1:bp2,j) = single(filtfilt(b,a, double(EEG.data(chanArray,bp1:bp2,j))')');
                                end
                            end
                      end
                else
                      fprintf(2, 'WARNING: EEG segment from sample %d to %d was not filtered.\n', bp1,bp2);
                      fprintf(2, 'More than 3*filterorder points are required to apply filter.\n\n');
                end

                if nnz(isnan(EEG.data(chanArray,bp1:bp2,j)));  %nans in data
                    error('Data include undefined numerical points');
                end            
                q = q + 1;
          end
    end
    fprintf('Filtering complete.\n\n')


    if ~isempty(boundary)
        boundaryval = num2str(boundary);
    else
        boundaryval = '[]';
    end

    COM = sprintf( 'EEG = pop_ButterworthFilter(EEG, %d, %d, %d, %d, %s);',locutoff, hicutoff, filterorder, NPasses, boundaryval);
    return    
end