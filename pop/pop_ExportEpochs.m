%USAGE:   [Success, COM] = pop_ExportEpochs(EEG, SubID, OutFileName, Append, SortIt)
%Exports an epoched data set to an ascii file for input
%to other softare..  Output has subjects and time as rows and
%epochs/channels as columns.  Intended for use with an Avg epoched file but
%can be used with any epoched file.  Will label epoch with the eventtype
%that is at 0ms.   v5

%
%Inputs:
%EEG: an epoched dataset
%SubID: Subject ID number.  Placed in first column of the output file
%OutFileName: Path/Filename for output file
%Append:  Append to exisitng file (Y or N)
%SortIt:  Sort epochs by event type prior to output (Y or N)

%Outputs:
%Success: Indicates if succeeded or failed
%COM: String to record this processing step
%
% See also: eeglab()
%
% Copyright (C) 2007  John J. Curtin, University of Wisconsin-Madison,
% jjcurtin@wisc.edu

% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%
%Revision History
%04-22-2007 Released version1, JJC v1
%05-20-2007 Now uses EEG.event.varfield for variable names if present.  Fixed reference to event vs. epochs.  Outputs epochs now, v2, JJC
%05-20-2007  Fixed use of _ in var names when varlabel was empty, v3, JJC
%08-22-2007  Fixed problem  with cell arrays and epoched files.  v4, JJC
%02-01-2008  Added an option to sort the epochs by event type before
%outputting.  Necessary if appended multiple subjects into one file so that
%column headings are correct. V5, JJC
%2012-02-15:  Added COM.  Now returns EEG, removed Success, JJC
%
%
%CONSIDER ADDED CHECK THAT OUTPUT MATCHES APPENDED FILE (e.g.,Channels/Events)
%NOTE:  MAY DO BAD THINGS IF EPOCHES ARE MISSING

function [EEG, COM] = pop_ExportEpochs(EEG, SubID, OutFileName, Append, SortIt)

    COM = '[EEG, COM] = pop_ExportEpochs(EEG)';     

    fprintf('pop_ExportEpochs(): Exporting data set to ASCII file\n');


    % display help if EEG not provided
    % ------------------------------------
    if nargin < 1
        pophelp('pop_ExportEpochs');
        return
    end

    % pop up window if other parameters not provided
    % -------------
    if nargin < 5
        [FName PName] = uiputfile('*.dat', 'Save Output File Name as');
        OutFileName = [PName FName];
        promptstr    = {'SubID: ', 'Append [(Y)es or (N)o]: ', 'Sort Epochs [(Y)es or (N)o]:'};
        inistr       = {int2str(EEG.subject), 'Y', 'Y'};
        result       = inputdlg( promptstr, 'Export ASCII Parameters', 1,  inistr);
        if isempty( result ); return; end;
        SubID = str2double(result{1});
        Append = result{2};
        SortIt = result{3};
    end

    %Check if Data set epochs should be sorted
    if SortIt == 'Y'
        EEG = SortEpochs(EEG);
    end

    %Check if output file already exists and if not, adds header
    [fid] = fopen(OutFileName, 'r');
    if fid == -1 %file doesnt exist so create and add header
        [fid] = fopen(OutFileName, 'wt');

        %Create Header
        Header = 'SubID\tTime\t';
        for j = 1:length(EEG.epoch)
            EventLatencies = zeros(length(EEG.epoch(j).eventlatency),1);   %preallocate array to hold latencies of all events for this epoch to find 0ms event later
            for k=1:length(EEG.epoch(j).eventlatency)
                if iscell(EEG.epoch(j).eventlatency) %EEG epoched files use cell arrays for eventlatncy field but my average files dont.  This tests to make it work with both
                    EventLatencies(k) = EEG.epoch(j).eventlatency{k}; 
                else
                    EventLatencies(k) = EEG.epoch(j).eventlatency(k);
                end
            end 

            for i = 1:length(EEG.chanlocs)
                Header = [Header EEG.chanlocs(i).labels  '_'  int2str(EEG.event(EEG.epoch(j).event(find(EventLatencies == 0,1))).type)];

                if isfield(EEG.event, 'varlabel') && ~isempty(EEG.event(EEG.epoch(j).event(find(EventLatencies == 0,1))).varlabel)  %if varlabels exist, append them to variable names
                    Header = [Header '_' EEG.event(EEG.epoch(j).event(find(EventLatencies == 0,1))).varlabel '\t'];
                else
                    Header = [Header '\t'];
                end
            end
        end
        Header = [Header '\n'];
        fprintf(fid, Header);
        fclose(fid);
    else  %file already existed, so just close in prep for dlmwrite below
        fclose(fid);
    end;

    RawArray = EEG.data;
    [rows cols pages] = size (RawArray);

    %reformat into 2-D array of points X Channels/Events
    %Assumes rawdata is in channels X points X events 3-D array to start
    FinalArray = RawArray(:,:,1);
    for i = 2:pages
        FinalArray = [FinalArray;RawArray(:,:,i)];
    end
        FinalArray = FinalArray';

        %Add subID and time columns
        SubIDArray = repmat(SubID,length(EEG.times),1);
        FinalArray = [SubIDArray EEG.times' FinalArray];

    %Output file array as tab delimited text file
    dlmwrite(OutFileName ,FinalArray,'-append', 'delimiter','\t', 'newline','pc');


    %Return the string command for record of processing if desired
    COM = sprintf('[EEG, COM] = pop_ExportEpochs(EEG, %d, %s, %c, %c);', SubID, OutFileName, Append, SortIt);
end
