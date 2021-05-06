function [ EEGFin ] = MergeCNT( StudyID, SubID, Prefix1, Prefix2, PrefixFin, DataType )
%[ EEGFin ] = MergeCNT( StudyID, SubID, Prefix1, Prefix2, PrefixFin, DataType )
%Opens and merges two CNT files together.  Saves and returns the final SET
%file.  Assumes typical Curtin file paths and names
%
%INPUTS
%StudyID:   String input for Study Name
%SubID:  String input for StudyID (including leading zeros)
%Prefix1  Prefix for filename for first CNT file
%Prefix2: Prefixe for filename for second CNT file
%PrefixFin:  Prefix for filename for merged SET file
%DataType:  int32(default) or int16
%
%OUTPUTS
%EEGFin: Merged files as EEG structure
%
%see also: eegplugin_PhysBox(), eeglab()
%
%Author: John Curtin(jjcurtin@wisc.edu)

%Revision History
%2011-09-27:  Released, JJC

    %set default for datatype
    if nargin < 6
        DataType = 'int32';
    end

    EEG1 = pop_loadcnt(['P:\UW\StudyData\' StudyID '\RawData\' SubID '\' Prefix1 SubID '.cnt'] , 'dataformat', DataType);
    EEG1 = eeg_checkset( EEG1 );
    sprintf('\n\n');
    EEG2 = pop_loadcnt(['P:\UW\StudyData\' StudyID '\RawData\' SubID '\' Prefix2 SubID '.cnt'] , 'dataformat', DataType);
    EEG2 = eeg_checkset( EEG2 );
    sprintf('\n\n');

    EEGFin = pop_mergeset( EEG1, EEG2, 0);
    EEGFin = eeg_checkset( EEGFin );
    sprintf('\n\n');
    
    EEGFin = pop_saveset( EEGFin, 'filename',[PrefixFin SubID '.set'],'filepath',['P:\UW\StudyData\' StudyID '\RawData\' SubID]);
end

