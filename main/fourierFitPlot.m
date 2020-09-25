function output = fourierFitPlot(maskInformation, numberTerms, numFrames, ignoreFrames)
output = zeros(numFrames, numberTerms - 1);
for i = 1:numFrames
    if isempty(find(ignoreFrames == i, 1))
        xFit = maskInformation(i).FourierFitX;
        yFit = maskInformation(i).FourierFitY;
        
        xnames = coeffnames(xFit);
        xvals = coeffvalues(xFit);
        
        ynames = coeffnames(yFit);
        yvals = coeffvalues(yFit);
        
        parfor j = 2:numberTerms
            targetCoeffX = "a" + num2str(j);
            targetCoeffY = "b" + num2str(j);
            
            xCoeffVal = xvals(xnames == targetCoeffX);
            yCoeffVal = yvals(ynames == targetCoeffY);
            
            output(i, j - 1) = sqrt(xCoeffVal.^2 + yCoeffVal.^2)./sqrt(xFit.a1.^2 + yFit.b1.^2);
        end
    else
        output(i ,:) = NaN;
    end
end
end
