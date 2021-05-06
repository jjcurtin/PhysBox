%USAGE: ADouble = isdouble(Obj)
%Returns boolean to indicate if x is from class double
%
%INPUTS
%Obj: a variable/object
%
%OUTPUTS
%ADouble:  boolean to indicate if x is a double
%
%see also: eegplugin_PhysBox(), eeglab()
%
%Author: John Curtin (jjcurtin@wisc.edu)

function ADouble = isdouble(Obj)

try
      if strcmpi(class(Obj),'double')
            ADouble=true;
      else
            ADouble=false;
      end
catch
      ADouble=false;
end

