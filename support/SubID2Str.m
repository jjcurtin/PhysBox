function [SubIDStr] = SubID2Str(SubID,Digits)
%[SubIDStr] = SubID2Str[SubID, Digits] - converts numeric SubID to string
%with leading 0's.  Full length of SubIDStr will be Digits.
%Inputs
%SubID: an integer Subject ID
%Digits:  Total number of digits in SubID including leading zeros
%
%Output
%SubIDStr: SubID in string form including leading zeros
%JJC, 04-07-2007

SubIDStr = int2str(SubID);

while length(SubIDStr) < Digits
    SubIDStr = ['0' SubIDStr];
end;