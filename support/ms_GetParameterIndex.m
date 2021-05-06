function [ Index ] = ms_GetParameterIndex( P, SubID )

    nSets = ms_CountSets( P );
    Index = 0;
    for i = 1:nSets
        if strcmpi(SubID, strtrim(P.SubID(i,:)))
            Index = i;
            break
        end
    end
    
    if Index ==0
        fprintf(2, 'WARNING: %s not found in Parameter file\n',SubID);
    end
end

