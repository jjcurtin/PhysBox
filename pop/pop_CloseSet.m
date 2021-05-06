%USAGE: [ ALLEEG, COM ] = pop_CloseSet(ALLEEG, Indices )
%wrapper function to call pop_delset() to close set file(s)
%with Curtin lab function naming conventions.   
%see pop_delset() for further details
%
%
%INPUTS
%ALLEEG:  A structure that contins one to many EEG structs
%Indices:  The indices in ALLEEG to indicate sets to close
%
%OUTPUTS:  
%ALLEEG:  Updated ALLEEG
%COM:  COM to record processing step


function [ ALLEEG, COM ] = pop_CloseSet(ALLEEG, Indices )
    COM = '[ ALLEEG, COM ] = pop_CloseSet(ALLEEG)';
    if nargin< 1
        pophelp('pop_CloseSet');
        return
    end
    
    if nargin < 2 || isempty(Indices)
        [ALLEEG, COM] = pop_delset(ALLEEG);
    else
        [ALLEEG, COM] = pop_delset(ALLEEG, Indices);
    end
end


