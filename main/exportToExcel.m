function exportToExcel(app, ignoreFrames)
%% Get file path and name
[file, path] = uiputfile('.xlsx');
figure(app.UIFigure);
fullFilePath = append(path, file);
%% Set up the cell matrix 
coeffNums = zeros(1, app.numFrames);
for i = 1:app.numFrames
    if isempty(find(ignoreFrames == i, 1))
        coeffNums(i) = numcoeffs(app.maskInformation(i).FourierFitX);
    else
        coeffNums(i) = NaN;
    end
end
maxCoeffs = max(coeffNums);
numColumns = 6 + (2*maxCoeffs);
data = cell(app.numFrames + 1, numColumns);
%Write in the first row
data{1, 1} = 'Centroid';
data{1, 2} = 'Average Radius';
data{1, 3} = 'Area';
data{1, 4} = 'Perimeter';
data{1, 5} = 'Surface Area';
data{1, 6} = 'Volume';
for j = 1:maxCoeffs
    data{1, 5 + (2*j)} = "a" + num2str(j - 1);
    data{1, 6 + (2*j)} = "b" + num2str(j - 1);
end
%Write in a row for each frame
for k = 1:app.numFrames
    if isempty(find(ignoreFrames == k, 1))
        data{1 + k, 1} = num2str(app.maskInformation(k).Centroid(1)) + ", " + num2str(app.maskInformation(k).Centroid(2));
        data{1 + k, 2} = app.maskInformation(k).AverageRadius;
        data{1 + k, 3} = app.maskInformation(k).Area;
        data{1 + k, 4} = app.maskInformation(k).Perimeter;
        data{1 + k, 5} = app.maskInformation(k).SurfaceArea;
        data{1 + k, 6} = app.maskInformation(k).Volume;
        
        xnames = coeffnames(app.maskInformation(k).FourierFitX);
        xvals = coeffvalues(app.maskInformation(k).FourierFitX);
        
        ynames = coeffnames(app.maskInformation(k).FourierFitY);
        yvals = coeffvalues(app.maskInformation(k).FourierFitY);
        
        for l = 1:numcoeffs(app.maskInformation(k).FourierFitX)
            targetCoeffX = "a" + num2str(l - 1);
            targetCoeffY = "b" + num2str(l - 1);
            
            xCoeffVal = xvals(xnames == targetCoeffX);
            yCoeffVal = yvals(ynames == targetCoeffY);
            data{1 + k, 5 + (2*l)} = xCoeffVal;
            data{1 + k, 6 + (2*l)} = yCoeffVal;
        end
    else
        for m = 1:numColumns
            data{1 + k, m} = 'NaN';
        end
    end
end
%% Write the cell matrix
writecell(data, fullFilePath);
end
