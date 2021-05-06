function tdfwrite(filename,st, append)
%
% function tdfwrite(filename,st, append)
%
% Saves structure st into filename
% st is a data structure of the format created by tdfread('file.tab');
% It has fields for each variable in the data structure.  These will be the variable names in the text faile.
% Each field contains an array (numeric or char) for subjects/trials.
% Data will be appended (Y; default) or can write over file (append = N)
%
% Warning: When appending, does not check for match of columns/variables.
%
% Warning: General format %.20g is used for numerical values. It works fine most
% of the time. Some applications may need to change the output format.
%
% Rafael Palacios, Oct 2009
%
%Revision histor
%2011-08-17, added append without rewrite of header, JJC
%2011-09-28, fixed bug to overwrite file when not appending, JJC
%2011-12-28:  added detail to error message, JJC

%%Error checking
if nargin< 3
    append = 'Y';
end

if nargin < 2,
    error('Must provide filename and structure object\n')
end

if (~ischar(filename))
    error('First argument must be the name of the file');
end

if (~isstruct(st))
    error('Second argument must be a strcuture');
end

%Field names
names=fieldnames(st);
rows=size(getfield(st,names{1}),1);

%Check that all fields have same length
for j=2:length(names)
    if (rows~=size(st.(names{j}),1))
        error('The length (%d) of field %s is different than the length (%d) of first field (%s)',size(st.(names{j}),1), names{j},rows, names{1});
    end
end

%Determine if header should be added to file
if exist(filename, 'file') && upper(append) == 'Y'
    WriteHeader = false;
else
    WriteHeader = true;
end

%%
if upper(append) == 'Y'
    [fp,message]=fopen(filename,'a');
else
    [fp,message]=fopen(filename,'w');
end


if (fp==-1)
    error('Error opening file: %s',message);
end

if WriteHeader
    %header
    fprintf(fp,'%s',names{1});
    fprintf(fp,'\t%s',names{2:end});
    fprintf(fp,'\n');
end

%values
for i=1:rows
    for j=1:length(names)
        if (j~=1)
            fprintf(fp,'\t');
        end
        v=getfield(st,names{j});
        if (ischar(v(1,1)))
            fprintf(fp,'%s',v(i,:));
        else
            fprintf(fp,'%.20g',v(i));  %general format
        end
    end
    fprintf(fp,'\n');
end
fclose(fp);
