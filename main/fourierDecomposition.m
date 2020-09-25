function output = fourierDecomposition(info, targetFrame, numTerms, sortOrder)
output = cell((numTerms - 1), 2);
xFit = info(targetFrame).FourierFitX;
yFit = info(targetFrame).FourierFitY;
xnames = coeffnames(xFit);
ynames = coeffnames(yFit);
xvals = coeffvalues(xFit);
yvals = coeffvalues(yFit);
asphericity = zeros(1, (numTerms - 1));
parfor i = 2:numTerms
    targetCoeffX = "a" + num2str(i);
    targetCoeffY = "b" + num2str(i);
    
    xCoeffVal = xvals(xnames == targetCoeffX);
    yCoeffVal = yvals(ynames == targetCoeffY);
    
    asphericity(i - 1) = sqrt(xCoeffVal.^2 + yCoeffVal.^2)./sqrt(xFit.a1.^2 + yFit.b1.^2);
end
switch sortOrder
    case "ascending"
        for j = 2:numTerms
            
            [~, cmapIdx] = min(asphericity);    %Get the index of the term with the smallest asphericity
            output{j - 1, 2} = cmapIdx + 1;     %Assign it to the second column in the output cell array (will be used for colormaping)
            t = transpose(0:0.01:2*pi);         %Set up the input vector
            
            xCoeffVal = xvals(xnames == "a" + num2str(cmapIdx));     %Get the x coefficient for the target term
            yCoeffVal = yvals(ynames == "b" + num2str(cmapIdx));     %Get the y coefficient for the target term
            
            xEq = xFit.a0 + xFit.a1*cos(t) + xCoeffVal*cos(cmapIdx*t);      %Calculate the new x values
            yEq = yFit.b0 + yFit.b1*sin(t) + yCoeffVal*sin(cmapIdx*t);      %Calculate the new y values
            
            points = [xEq, yEq];            %Concatenate the vectors together
            output{j - 1, 1} = points;      %Assign to the output variable
            
            asphericity(cmapIdx) = NaN;     %Replace the highest valued term with NaN
        end
    case "descending"
        for j = 2:numTerms
            
            [~, cmapIdx] = max(asphericity);    %Get the index of the term with the largest asphericity
            output{j - 1, 2} = cmapIdx + 1;     %Assign it to the second column in the output cell array (will be used for colormaping)
            t = transpose(0:0.01:2*pi);         %Set up the input vector
            
            xCoeffVal = xvals(xnames == "a" + num2str(cmapIdx));     %Get the x coefficient for the target term
            yCoeffVal = yvals(ynames == "b" + num2str(cmapIdx));     %Get the y coefficient for the target term
            
            xEq = xFit.a0 + xFit.a1*cos(t) + xCoeffVal*cos(cmapIdx*t);      %Calculate the new x values
            yEq = yFit.b0 + yFit.b1*sin(t) + yCoeffVal*sin(cmapIdx*t);      %Calculate the new y values
            
            points = [xEq, yEq];            %Concatenate the vectors together
            output{j - 1, 1} = points;      %Assign to the output variable
            
            asphericity(cmapIdx) = NaN;     %Replace the highest valued term with NaN
        end
end
end
