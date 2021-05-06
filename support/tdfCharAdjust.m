function [ NewStringField ] = tdfCharAdjust( StringField, NewString )
%tdf structures have some problems with string data.  Specficially, new strings 
%dded to a field must be same length (width) as the other entries.  If narrower, the
%assigment just has to be handled correctly 
%     TDF.stringfield (4,1:length(NewString)) = NewString;
%However, if the the new string is wider, the char array needs to first be 
%adjusted to the width of the new string before adding it to the array.
%tdfCharAdjust checks if a width adjustment is necessary and if so, does
%it.  It does NOT add the string. 
%USAGE: 
    %check to make sure NewString is truly a string (row vector)
    if size(NewString,1) > 1
        error('NewString must be row vector\n')
    end
    
    OrigLength = size(StringField,1);
    OrigWidth = size(StringField,2);
    NewWidth = size(NewString,2);
    if NewWidth > OrigWidth
        NewStringField = repmat(' ', OrigLength, NewWidth);
        for i=1:OrigLength
            NewStringField(i,1:OrigWidth) = StringField(i,:);
        end
    else
        NewStringField = StringField;
    end

end

%Example
% Test.f1 = ['abc';'def';'gji']
% NewString = '1234'
% Test.f1 = tdfCharAdjust(Test.f1,NewString)
% Test.f1(4,1:length(NewString)) = NewString