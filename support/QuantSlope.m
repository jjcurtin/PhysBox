function [MeanSlope, PercentConsist] = QuantSlope(SlopeArray, SampRate)
%Returns change per ms unit (slope) and consistency of that slope for
%SlopeArray.   Edited on 7-12-10 to correct for samprate issues 
    MeanSlope = 0;
    CntPos = 0;
    CntNeg =0;
    for i=2:length(SlopeArray)
        %fprintf('In quantslope, iteration %d\n',i)
        MeanSlope = MeanSlope + (SlopeArray(i) - SlopeArray(i-1));
        
        if SlopeArray(i) - SlopeArray(i-1) > 0 
            CntPos = CntPos +1;
        else
            CntNeg = CntNeg +1;
        end
    end
    
    MeanSlope = MeanSlope / (length(SlopeArray)-1) * (SampRate/1000);  %Convert to change per ms
    
    if MeanSlope > 0
        PercentConsist = CntPos / (length(SlopeArray) - 1);
    else
        PercentConsist = CntNeg / (length(SlopeArray) - 1);
    end
    
end