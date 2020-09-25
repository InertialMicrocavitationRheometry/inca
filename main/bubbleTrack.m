function maskInformation = bubbleTrack(app, mask, arcLength, doFit, numberTerms, adaptiveTerms, ignoreFrames)
% A function to generate data about each mask 

%% Set up logging 
% fileID = generateDiaryFile("BubbleAnalysisLog");

%% Get number of frames
[~, ~, depth] = size(mask);
% fprintf(fileID, '%s', "Number of frames: " + num2str(depth));
% fprintf(fileID, '\n');

%% Define the struct
% fprintf(fileID, '%s', "Generating struct with fields: Centroid, TrackingPoints, AverageRadius, SurfaceArea, Volume, FourierPoints, FourierFitX, FourierFitY, xData, yData, Area, Perimeter, PerimeterPoints");
% fprintf(fileID, '\n');
maskInformation = struct('Centroid', cell(depth, 1), 'TrackingPoints', cell(depth, 1), 'AverageRadius', cell(depth, 1), ...
    'SurfaceArea', cell(depth, 1), 'Volume', cell(depth, 1), 'FourierPoints', cell(depth, 1),...
    'FourierFitX', cell(depth, 1), 'FourierFitY', cell(depth, 1), 'xData', cell(depth, 1), 'yData', cell(depth, 1), 'Area', cell(depth, 1), 'Perimeter', cell(depth, 1), ...
    'PerimeterPoints', cell(depth, 1));

%% Create the progress bar
wtBr = uiprogressdlg(app.UIFigure, 'Title', 'Please wait', 'Message', 'Calculating...');

%% Analyze the mask for each frame
for d = 1:depth
    
    wtBr.Value = d./depth;
%     fprintf(fileID, '%s', '------------------------------');
%     fprintf(fileID, '\n');
    %Skip any frames that are in the ignore list
    if ~isempty(find(ignoreFrames == d, 1))
        fprintf(fileID, '%s', "Skipping analysis of frame " + num2str(d));
        fprintf(fileID, '\n');
        maskInformation(d).Centroid = NaN;
        maskInformation(d).Area = NaN;
        maskInformation(d).Perimeter = NaN;
        maskInformation(d).PerimeterPoints = NaN;
        maskInformation(d).TrackingPoints = NaN;
        maskInformation(d).FourierPoints = NaN;
        maskInformation(d).FourierFit = NaN;
        maskInformation(d).AverageRadius = NaN;
        maskInformation(d).SurfaceArea = NaN;
        maskInformation(d).Volume = NaN;
        maskInformation(d).FourierFitX = NaN;
        maskInformation(d).FourierFitY = NaN;
        continue;
    else
%         fprintf(fileID, '%s', "Starting analysis of frame " + num2str(d));
%         fprintf(fileID, '\n');
        %Get the mask
        targetMask = mask(:, :, d);
        
        %Use regionprops to get basic mask data
        targetStats = regionprops(targetMask, 'Centroid', 'Area', 'Perimeter');
        
        %Assign that data to the output struct
        maskInformation(d).Centroid = targetStats.Centroid;
%         fprintf(fileID, '%s', "Centroid: " + num2str(targetStats.Centroid));
        fprintf(fileID, '\n');
        
        maskInformation(d).Area = targetStats.Area;
%         fprintf(fileID, '%s', "Area: " + num2str(targetStats.Area));
        fprintf(fileID, '\n');
        
        maskInformation(d).Perimeter = targetStats.Perimeter;
%         fprintf(fileID, '%s', "Perimeter Length: " + num2str(targetStats.Perimeter));
        fprintf(fileID, '\n');
        
        maskInformation(d).PerimeterPoints = generatePerimeterPoints(targetMask);
        
        %Get the tracking points 
        [xVals, yVals] = angularPerimeter(targetMask, [maskInformation(d).Centroid], 50, fileID);
        maskInformation(d).TrackingPoints = [xVals, yVals];
        
        %Calculate the average radius
        center = [maskInformation(d).Centroid];
        maskInformation(d).AverageRadius = mean(sqrt( (center(1) - xVals).^2 + (center(2) - yVals).^2 ), 'all');
%         fprintf(fileID, '%s', "Average Radius: " + num2str(maskInformation(d).AverageRadius));
        fprintf(fileID, '\n');
        
        if doFit
%             fprintf(fileID, '%s', "Fitting Fourier Series to mask perimeter for frame: " + num2str(d));
%             fprintf(fileID, '\n');
            %Get the points for the fourier fit
            [xVals, yVals] = angularPerimeter(targetMask, [maskInformation(d).Centroid], floor( maskInformation(d).Perimeter./arcLength), fileID);
            maskInformation(d).FourierPoints = [xVals, yVals];
%             fprintf(fileID, '%s', "Number of Perimeter Fourier Fit Points: " + num2str(length(xVals)));
%             fprintf(fileID, '\n');
            %Actually do the fourier fit and get the coefficients for the
            %equation
            fprintf(fileID, '%s', "Minimum Arc Length: " + num2str(arcLength));
            fprintf(fileID, '\n');
            fprintf(fileID, '%s', "(Max) Number of Terms in Fit: " + num2str(numberTerms));
            fprintf(fileID, '\n');
            fprintf(fileID, '%s', "Adaptive Number of Terms (T/F): " + num2str(adaptiveTerms)); 
            fprintf(fileID, '\n');
            fprintf(fileID, '%s', "Beginning Fit");
            fprintf(fileID, '\n');
            [xFit, yFit] = fourierFit(xVals, yVals, arcLength, numberTerms, adaptiveTerms,fileID);
            fprintf(fileID, '%s', "Fit complete");
            fprintf(fileID, '\n');
            maskInformation(d).FourierFitX = xFit;
            maskInformation(d).FourierFitY = yFit;
            fprintf(fileID, '%s', "Number of plotting points: " + num2str(length(xData)));
            fprintf(fileID, '\n');
        end
    end
    fprintf(fileID, '%s', "Analysis complete");
    fprintf(fileID, '\n');
end
%% Close waitbar and the diary
close(wtBr);
fclose(fileID);
end

function [xVals, yVals] = angularPerimeter(targetMask, center, noTC, fileID)
fprintf(fileID, '%s', "Generating " + num2str(noTC) + " periemter points");
fprintf(fileID, '\n');
tic;
%Get the perimeter of the mask
targetPerim = bwmorph(bwperim(targetMask), 'thin', Inf);
[row, col] = size(targetMask);
%Create the vector of angles
rad = transpose(0:(2*pi/noTC):(2*pi - (2*pi/noTC)));
%Create the x, y index matrices and the radius matrix
xcoords = repmat(1:col, row, 1);
ycoords = repmat(transpose(1:row), 1, col);
%Create the radian matrix
radian = atan2( (ycoords - center(2)) , (xcoords - center(1)) );
radian(radian < 0) = radian(radian < 0) + 2*pi;
%Set up the temporary points matrix
xVals = zeros(size(rad));
yVals = zeros(size(rad));
[rowRad, ~] = size(rad);
%% Find the x and y coordinates in the radian matrix that correspond to an angle of interest
parfor i = 1:rowRad
    %Get the direction to look in
    lookDirection = rad(i);
    
    %Set up the matrix
    workingRadian = radian - lookDirection;
    workingRadian(~targetPerim) = NaN;
    
    %Find the value of the elements bounding the desired angle
    upperBound = min(min(workingRadian(workingRadian > 0)));
    lowerBound = max(max(workingRadian(workingRadian < 0)));
    if isempty(lowerBound)
        lowerBound = max(max(workingRadian));
    end
    
    %Get the indices of the elements if more than one element is found,
    %take the farther of the two
    [upperRow, upperCol] = find(abs(workingRadian - upperBound) < 0.0001);
    [lowerRow, lowerCol] = find(abs(workingRadian - lowerBound) < 0.0001);
    
    [upperRowSize, ~] = size(upperRow);
    [lowerRowSize, ~] = size(lowerRow);
    
    if upperRowSize > 1
        distance = zeros(size(upperRow));
        for j = 1:upperRowSize
            Y = upperRow(j);
            X = upperCol(j);
            distance(j) = sqrt( (X - center(1)).^2 + (Y - center(2)).^2 );
        end
        [~, maxIdx] = max(distance);
        upperRow = upperRow(maxIdx);
        upperCol = upperCol(maxIdx);
    end
    
    if lowerRowSize > 1
        distance = zeros(size(lowerRow));
        for j = 1:lowerRowSize
            Y = lowerRow(j);
            X = lowerRow(j);
            distance(j) = sqrt( (X - center(1)).^2 + (Y - center(2)).^2 );
        end
        [~, maxIdx] = max(distance);
        lowerRow = lowerRow(maxIdx);
        lowerCol = lowerCol(maxIdx);
    end
    
    %Get the distance from the center of the element to the bubble
    %centroid
    upperRadius = sqrt( (upperCol - center(1)).^2 + (upperRow - center(2)).^2);
    lowerRadius = sqrt( (lowerCol - center(1)).^2 + (lowerRow - center(2)).^2);
    
    %Decide on a weighted radius depending on the proximity of bound
    %values to 0
    range = upperBound - lowerBound;
    upperWeight = (1 - abs(upperBound./range));
    lowerWeight = (1 - abs(lowerBound./range));
    weightedRadius = upperRadius.*upperWeight + lowerRadius.*lowerWeight;
    xVals(i) = weightedRadius.*cos(lookDirection) + center(1);
    yVals(i) = weightedRadius.*sin(lookDirection) + center(2);
end
toc;
fprintf(fileID, '%s', "Perimeter point generation complete");
fprintf(fileID, '\n');
end

function [xFit, yFit, xData, yData] = fourierFit(xPoints, yPoints, arcLength, numberTerms, adaptiveTerms, fileID)
%Get the number of points in the data set
[row, ~] = size(xPoints);
if adaptiveTerms
    %Do a preliminary fit to get radius
    w = 2*pi/(row - 1);
    fitfuncx = fittype( @(a0, a1, x) a0 + a1*cos(x*w));
    xFitPrelim = fit(transpose(1:row), xPoints, fitfuncx);
    
    fitfuncy = fittype( @(b0, b1, x) b0 + b1*sin(x*w));
    yFitPrelim = fit(transpose(1:row), yPoints, fitfuncy);
    
    %Calculate the number of terms in the fourier fit
    r = sqrt(xFitPrelim.a1^2 + yFitPrelim.b1^2);
    calcTerms = floor(r*pi/arcLength);
    if calcTerms < numberTerms
        numberTerms = calcTerms;
    end
    clear fitfuncx fitfuncy xFitPrelim yFitPrelim r arcLength w;
end
%Create the equations to fit to
if numberTerms > length(xPoints)/2
    numberTerms = floor(length(xPoints)/2);
end
if numberTerms == 0
    fprintf(fileID, '%s', "Not enough perimeter points");
    fprintf(fileID, '\n');
end
fprintf(fileID, '%s', "Creating X and Y Fourier function files with " + num2str(numberTerms) + " number of terms");
fprintf(fileID, '\n');
[functionNameX, functionNameY] = createFourierFunc(numberTerms);
    
%Actually fit it for the correct number of terms
ftx = fittype(functionNameX);
xFit = fit(transpose(1:row), xPoints, ftx);
fty = fittype(functionNameY);
yFit = fit(transpose(1:row), yPoints, fty);

%Evaluate the fit 
xData = feval(xFit, 0:1/(row*numberTerms):row);
yData = feval(yFit, 0:1/(row*numberTerms):row);

%Delete the files
fprintf(fileID, '%s', 'Deleting function files');
fprintf(fileID, '\n');
delete('main/xFourierFunc.m');
delete('main/yFourierFunc.m');
end

function output = generatePerimeterPoints(inputMask)
boundaries = cell2mat(bwboundaries(inputMask));
output(:, 1) = boundaries(:, 2);
output(:, 2) = boundaries(:, 1);
end

function [xName, yName] = createFourierFunc(numTerms)
%Create the function name for the x fourier series
xName = "xFourierFunc(x";
for i = 0:numTerms
    xName = xName + ", a" + num2str(i);
end
xName = xName + ")";
%Create the function name for the y fourier series
yName = "yFourierFunc(x";
for j = 0:numTerms
    yName = yName + ", b" + num2str(j);
end
yName = yName + ")";
%Create and open the files for writing
xFile = fopen("main/xFourierFunc.m", 'w');
yFile = fopen("main/yFourierFunc.m", 'w');
%Write in the first line of the function
fprintf(xFile, "function y = " + xName + "\n \n");
fprintf(yFile, "function y = " + yName + "\n \n");
%Write in the function set up
fprintf(xFile, "y = zeros(size(x)); \nw = 2*pi/(max(x) - min(x)); \n \nfor i = 1:length(x) \n \ty(i) = a0");
fprintf(yFile, "y = zeros(size(x)); \nw = 2*pi/(max(x) - min(x)); \n \nfor i = 1:length(x) \n \ty(i) = b0");
for j = 1:numTerms
    fprintf(xFile, "+ a" + num2str(j) + "*cos(" + num2str(j) + "*x(i)*w)");
    fprintf(yFile, "+ b" + num2str(j) + "*sin(" + num2str(j) + "*x(i)*w)");
end
%Finish up the functions
fprintf(xFile, ";\nend\n\nend");
fprintf(yFile, ";\nend\n\nend");
%Close the files
fclose(xFile);
fclose(yFile);
end
