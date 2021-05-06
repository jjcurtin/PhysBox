%USAGE: [ nSets ] = ms_CountSets( P )
%Returns number of SETS included in parameter file P.  This is really just
%the number of rows in the P file.  It includes rejected SETS
%
%INPUT
%P: A parameter file structure
%
%OUTPUT
%nSets:  Number of SETS (rows) in the P file
%
%see also eeglab(), eegplugin_PhysBox()
%
%Author: John Curtin (jjcurtin@wisc.edu)

%Revision History
%2011-09-30:  released, JJC

function [ nSets ] = ms_CountSets( P )
    F = fieldnames(P);
    nSets = size(P.(F{1}),1);
end

