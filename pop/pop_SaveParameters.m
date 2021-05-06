%USAGE: [ P ] = pop_SaveParameters(P, Details)
%saves the Parameter file to disk and then reloads and returns P
%
%INPUT
%P:  A parameter file to save to disk
%Details:  Boolean to output details to screen.  Default is true
%
%OUTPUT
%P   The same parameter file
%
%see also: eegplugin_PhysBox(), pop_ProcessSets(), eeglab()
%
%Author: John Curtin(jjcurtin@wisc.edu)

%Revision history
%2011-11-04: released, JJC
%2011-11-07: notify user if parameter file is locked, JJC

function [ P , COM] = pop_SaveParameters(P, Details)

    COM = 'P = pop_SaveParameters(P);';   
    if nargin < 1
        help pop_SaveParameters
        return
    end
    
    if nargin < 2
        Details = true;
    end

    %remove  temp fields
    P = rmfield(P, 'InPath');
    
    ParameterFile = P.Self;  %Get filename for Parameter file
    P = rmfield(P, 'Self');  %remove this temporary field
    
    %ReducePath needs to be rebuilt from root (or just removed from older
    %versions of PhysBox that did not specify ReducePath
    if isfield(P,'RootReducePath')
        P.ReducePath = P.RootReducePath;
        P = rmfield(P, 'RootReducePath');  %remove this temporary field
    else
        P = rmfield(P, 'ReducePath');  %remove this temporary field
    end
        
    %check if can write to filename and then write or prompt to close file
    fid = fopen(ParameterFile,'w');
    if fid == -1
        ErrMsg = sprintf('Parameter file locked (e.g., file open in Excel)\nClose file and then click OK to proceed');
        CloseDlg = questdlg(ErrMsg, 'Parameter File Save Error', 'OK', 'OK');            
        if strcmpi(CloseDlg, 'OK') 
            tdfwrite(ParameterFile, P, 'N'); %overwite Parameter file on disk
        else
            error('\n\nERROR: Parameter file not saved\n\n')
        end        
    else
        fclose(fid);
        tdfwrite(ParameterFile, P, 'N'); %overwite Parameter file on disk
    end
    
    %Reload Parameter file from Disk
    P = pop_GetParameters(ParameterFile, Details);
    fprintf('Parameter file saved to %s\n', P.Self);    
end

