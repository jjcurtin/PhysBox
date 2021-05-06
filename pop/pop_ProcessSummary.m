%USAGE:  pop_ProcessSummary(P)
%Returnd detailed stats about the processing that was just completed on
%parameter file P
%
%INPUTS
%P  A struct that contains parameters from parameter file
%
%OUTPUTS
%none

function pop_ProcessSummary(P)
    fprintf('\n\n###########################\nPhysBox Processing Summary\n###########################\n')

    SubIDList = '';
    Ctr = 0;
    for s=1:size(P.SubID,1)
        if P.Rejected(s) == -1
            Ctr= Ctr+1;
            SubIDList = sprintf('%s%s\t', SubIDList, P.SubID(s,:));
            if ~mod(Ctr,15)
                SubIDList = sprintf('%s\n', SubIDList);
            end            
        end
    end
    fprintf('%d subject(s) auto-rejected (-1):\n%s\n\n', Ctr, SubIDList)

    SubIDList = '';
    Ctr = 0;
    for s=1:size(P.SubID,1)
        if P.Rejected(s) == 1
            Ctr= Ctr+1;
            SubIDList = sprintf('%s%s\t', SubIDList, P.SubID(s,:));
            if ~mod(Ctr,15)
                SubIDList = sprintf('%s\n', SubIDList);
            end
        end
    end
    fprintf('%d subject(s) user-rejected (1):\n%s\n\n', Ctr, SubIDList)  

    SubIDList = '';
    Ctr = 0;
    for s=1:size(P.SubID,1)
        if P.Rejected(s) == 0
            Ctr= Ctr+1;
            SubIDList = sprintf('%s%s\t', SubIDList, P.SubID(s,:));
            if ~mod(Ctr,15)
                SubIDList = sprintf('%s\n', SubIDList);
            end            
        end
    end
    fprintf('%d subject(s) successfully processed (0):\n%s\n\n', Ctr, SubIDList)        

end

