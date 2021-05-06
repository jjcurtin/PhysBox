function [ P , COM] = pop_GetParameters(ParameterFile, Details)
    P = [];  %in case user presses cancel
    COM = 'P = pop_GetParameters();';

    if nargin < 2
        Details = true;
    end
    
    if nargin < 1
        [Filename Pathname] = uigetfile('*.dat', 'Open Parameter File');
        if  isequal(Filename,0) || isequal(Pathname,0)
            return
        end
        ParameterFile = fullfile(Pathname, Filename);
    end
    
    fprintf('\nLoading reduction parameters from %s\n', ParameterFile);
    P = tdfread(ParameterFile);
    
    %if present, convert SubID to string, including leading zeros or
    %leading blanks based on the length of SubID and the SubIDDigits.
    if isfield(P, 'SubID')
        MaxSubID = max(P.SubIDDigits);
        SubIDs = repmat(blanks(max(MaxSubID)),size(P.SubID,1),1);
        for i= 1:length(P.SubID)
            StartChar = max(P.SubIDDigits) - P.SubIDDigits(i) + 1;  %first digit position in ragged array with leading blans
            SubIDs(i,StartChar:end) = SubID2Str(P.SubID(i),P.SubIDDigits(i));
        end
        P.SubID = SubIDs;      
    end

    %create RawPath, InPath, ReducePath, and OutPath
    %We use 4 paths as follows:
    %RawPath points to rawdata folder for study
    %InPath points to subjects folder in rawdata
    %ReducePath points to Reduce folder for specific subject. This used to
    %    be in /RawData but more recently is in /Analysis/Project-PaperName/Data/ReducedData/SUBID/ in
    %    subject specific folder
    %OutPath points to Analysis/Project-PaperName/Data/....
    
    if isfield(P, 'RootPath')  %RootPath is vestigal for backward compatibilty;  Set both RawPath and OutPath to RootPath if older processing script
        P.RawPath = P.RootPath;
        P.OutPath = P.RootPath;
        P = rmfield(P,'RootPath');
    end
    
    %set up InPath to point to SubID folder in RawData (/RawData/SUBID/)
    for i= 1:size(P.SubID,1)
        P.InPath(i,:) = [blanks(MaxSubID-P.SubIDDigits(i)) P.RawPath(i,:) strtrim(P.SubID(i,:)) repmat(filesep,size(P.RawPath(i,:),1),1)]; 
    end    
    
    %If ReducePath in parameter file use it. Otherwise, set to subject specific folder in /RawData/SUBID/Reduced/
    if isfield(P,'ReducePath') || isfield(P,'ReducedPath')
        P.RootReducePath = P.ReducePath;  %save root without subject for later use in pop_SaveParameters()
        TmpPath = char(zeros(size(P.SubID,1), size(fullfile(P.ReducePath(1,:),P.SubID(1,:)),2)));
        for i= 1:size(P.SubID,1)
            TmpPath(i,:) = fullfile(P.ReducePath(i,:), strtrim(P.SubID(i,:)));
        end
        P.ReducePath = TmpPath;
    else
        for i= 1:size(P.SubID,1)
            P.ReducePath(i,:) = [P.InPath(i,:) repmat(['Reduce' filesep],size(P.RawPath(i,:),1),1)];  
        end          
    end

    %P.RawPath and P.OutPath requires no additional changes.

    %Create temporary field with Paramater path and file name for later
    %save of this file.  It must be removed before saving using tdfwrite
    P.Self = ParameterFile;
    
    if Details
        fprintf('\nParameter file details:\n')
        fprintf('\tN: %d\n', CountSets(P));
        fprintf('\tN to Reduce: %d\n', sum(all([~P.Reduced ~P.Rejected]')));
        fprintf('\tN Reduced: %d\n', sum(P.Reduced));
        fprintf('\tN Rejected: %d\n\n', sum(logical(P.Rejected)));
    end
end