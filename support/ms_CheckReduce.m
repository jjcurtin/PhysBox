%USAGE: [ Proceed ] = ms_CheckReduce( File1Indx, File2Indx, ReducedValues, Reject )
%Checks Reduce fields in Parameter file during multi-set reduction to
%determin if these values indicate that the next reduction step is
%approriate/needed.  A variety of checks are performed dependent on the
%inputs for File1Indx and File2Index (see code)
%
%INPUTS
%File1Indx:  The integer file index for the input file for a multi-set function
%File2Indx:  The integer file index for the output file for a multi-set function
%ReducedValues:  A numeric array with values (0/1) for all Reduced fields in the Parameter file for this subject
%Reject: The value (0/1) of the Reject field from the parameter file for this subject
%
%OUTPUTS
%Proceed:  Boolean to indicate if next processing step should be applied
%
%see also:  eegplugin_PhysBox(), eeglab(), pop_ProcessSets(),
%ms_ProcessSets()
%
%Author: John Curtin (jjcurtin@wisc.edu)

%Revision history
%2011-11-04: Released, JJC

function [ Proceed ] = ms_CheckReduce( File1Indx, File2Indx, ReducedValues, Reject )

    if Reject  %first check if it is flagged to Reject in Parameter file
        Proceed = false;
    else
        %Condition 1:  Target input and Output SET files are same
        if (File1Indx == File2Indx)  %If saving over same file (i.e., still processing this target output file)
            Proceed = ~ReducedValues(File1Indx);  %Proceed only if reduction is not comlete for this file
            %if saving over same file and that file is not yet file, also check that all previous files have been processed
            %Otherwise, File1Indx might not exist yet
            if Proceed  && File1Indx > 1  
                Proceed = all(ReducedValues(1:File1Indx-1));  %set proceed to false if not all true                                
            end
        end

        %Condition 2: Target input and output SET files are different
        if ~isempty(File2Indx) && ~(File1Indx == File2Indx)   %if changing to new target output and saving it
            if File1Indx ==0  %if infile is orig, proceed if outfile is not yet reduce
                Proceed = ~ReducedValues(File2Indx);
            else
                if (ReducedValues(File1Indx) && ~ReducedValues(File2Indx))   %Proceed if target infile is reduced and target outfile is not yet reduced
                    Proceed = true;
                else
                    Proceed = false;
                end
            end
        end

        %Condition 3:  No target output SET file (function must output to text
        %(e.g., Scoring Functions, Diagnostic Figure, Export Functions, Grand Average Function)
        if isempty(File2Indx)  %if function Exports to tab delimited from a reduced SET file (known because there is no target output file)
            Proceed = ReducedValues(File1Indx);  %proceed if input file is completely reduced
        end
    end
end

