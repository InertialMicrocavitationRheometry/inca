classdef bubbleAnalysis
    methods (Static)
       
        %Analyze the video
        function maskInformation = bubbleTrack(app, mask, arcLength, orientation, doFit, numberTerms, adaptiveTerms, ignoreFrames, style)
            % A function to generate data about each mask
            
            %% Get number of frames
            [~, ~, depth, views] = size(mask);
            
            %% Define the struct
            maskInformation = struct('Centroid', cell(depth, views), 'TrackingPoints', cell(depth, views), 'AverageRadius', cell(depth, views), ...
                'SurfaceArea', cell(depth, views), 'Volume', cell(depth, views), 'FourierPoints', cell(depth, views),...
                'perimFit', cell(depth, views), 'perimEq', cell(depth, views), 'Area', cell(depth, views), 'Perimeter', cell(depth, views), ...
                'PerimeterPoints', cell(depth, views), 'PerimVelocity', cell(depth, views), 'Orientation', cell(depth, views), 'FitRadius', cell(depth, views), ...
                'FitArea', cell(depth, views), 'FitPerim', cell(depth, views), 'SurfPoints', cell(depth, views), 'surfFit', cell(depth, views), ...
                'surfEq', cell(depth, views), 'FitSA', cell(depth, views), 'FitVol', cell(depth, views));
            
            %% Create the progress bar
            wtBr = uiprogressdlg(app.UIFigure, 'Title', 'Please wait', 'Message', 'Calculating...');
            
            %% Analyze the mask for each frame
            for d = 1:depth
                for v = 1:views
                    standardMsg = "Analyzing mask " + num2str(v) + "/" + num2str(views) + " in frame " + num2str(d) + "/" + num2str(depth);
                    wtBr.Message = standardMsg;
                    wtBr.Value = (d)./(depth);
                    %Skip any frames that are in the ignore list
                    if ~isempty(find(ignoreFrames == d, 1))
                        maskInformation(d, v).Centroid = NaN;
                        maskInformation(d, v).Area = NaN;
                        maskInformation(d, v).Perimeter = NaN;
                        maskInformation(d, v).PerimeterPoints = NaN;
                        maskInformation(d, v).TrackingPoints = NaN;
                        maskInformation(d, v).FourierPoints = NaN;
                        maskInformation(d, v).AverageRadius = NaN;
                        maskInformation(d, v).SurfaceArea = NaN;
                        maskInformation(d, v).Volume = NaN;
                        maskInformation(d, v).perimFit = NaN;
                        maskInformation(d, v).perimEq = NaN;
                        maskInformation(d, v).PerimVelocity = NaN;
                        maskInformation(d, v).Orientation = NaN;
                        maskInformation(d, v).FitRadius = NaN;
                        maskInformation(d, v).FitArea = NaN;
                        maskInformation(d, v).FitPerim = NaN;
                        maskInformation(d).FitSA = NaN;
                        maskInformation(d).FitVol = NaN;
                        maskInformation(d).SurfPoints = NaN;
                        maskInformation(d).surfFit = NaN;
                        maskInformation(d).surfEq = NaN;
                        continue;
                    elseif ~any(any(mask(:, :, d, 1)))
                        maskInformation(d, v).Centroid = NaN;
                        maskInformation(d, v).Area = NaN;
                        maskInformation(d, v).Perimeter = NaN;
                        maskInformation(d, v).PerimeterPoints = NaN;
                        maskInformation(d, v).TrackingPoints = NaN;
                        maskInformation(d, v).FourierPoints = NaN;
                        maskInformation(d, v).AverageRadius = NaN;
                        maskInformation(d, v).SurfaceArea = NaN;
                        maskInformation(d, v).Volume = NaN;
                        maskInformation(d, v).perimFit = NaN;
                        maskInformation(d, v).perimEq = NaN;
                        maskInformation(d, v).PerimVelocity = NaN;
                        maskInformation(d, v).Orientation = NaN;
                        maskInformation(d, v).FitRadius = NaN;
                        maskInformation(d, v).FitArea = NaN;
                        maskInformation(d, v).FitPerim = NaN;
                        maskInformation(d).FitSA = NaN;
                        maskInformation(d).FitVol = NaN;
                        maskInformation(d).SurfPoints = NaN;
                        maskInformation(d).surfFit = NaN;
                        maskInformation(d).surfEq = NaN;
                        continue;
                    else
                        %Get the mask
                        targetMask = mask(:, :, d, v);
                        
                        %Use regionprops to get basic mask data
                        wtBr.Message = standardMsg + ": Calculating centroid, area, and perimeter";
                        targetStats = regionprops(targetMask, 'Centroid', 'Area', 'Perimeter', 'Orientation');
                        
                        %Assign that data to the output struct
                        maskInformation(d, v).Centroid = targetStats.Centroid;
                        
                        maskInformation(d, v).Area = targetStats.Area;
                        
                        maskInformation(d, v).Perimeter = targetStats.Perimeter;
                        
                        maskInformation(d, v).Orientation = targetStats.Orientation;
                        
                        maskInformation(d, v).PerimeterPoints = bubbleAnalysis.generatePerimeterPoints(targetMask);
                        
                        %Get the tracking points
                        wtBr.Message = standardMsg + ": Generaing tracking points";
                        [xVals, yVals] = bubbleAnalysis.angularPerimeter(targetMask, [maskInformation(d, v).Centroid], app.TPField.Value);
                        maskInformation(d, v).TrackingPoints = [xVals, yVals];
                        
                        %Calculate the perimeter velocity as long as we are not
                        %on the first frame and the previous frame was not
                        %ignored
                        if (d > 1)
                            if ~isnan(maskInformation(d - 1, v).PerimeterPoints)
                                maskInformation(d, v).PerimVelocity = zeros(1, 5);
                                
                                %Index Tracking Points
                                currentFramePoints = bubbleAnalysis.translatePerim(maskInformation(d, v).TrackingPoints, maskInformation(d, v).Centroid);
                                oldFramePoints = bubbleAnalysis.translatePerim(maskInformation(d - 1, v).TrackingPoints, maskInformation(d - 1, v).Centroid);
                                
                                %Convert to Polar
                                [currentTheta, currentRho] = cart2pol(currentFramePoints(:, 1), currentFramePoints(:, 2));
                                [oldTheta, oldRho] = cart2pol(oldFramePoints(:, 1), oldFramePoints(:, 2));
                                
                                %Concatenate Arrays
                                currentPolar = [currentTheta, currentRho];
                                oldPolar = [oldTheta, oldRho];
                                
                                %Calculate velocity
                                maskInformation(d, v).PerimVelocity(1, :) = bubbleAnalysis.calcPerimVelocity(currentPolar, oldPolar);
                            else
                                maskInformation(d, v).PerimVelocity = NaN;
                            end
                        else
                            maskInformation(d, v).PerimVelocity = NaN;
                        end
                        
                        %Calculate the average radius
                        center = [maskInformation(d, v).Centroid];
                        wtBr.Message = standardMsg + ": Calculating average radius";
                        maskInformation(d, v).AverageRadius = mean(sqrt( (center(1) - xVals).^2 + (center(2) - yVals).^2 ), 'all');
                        
                        %Translate the bubble to be centered on the axes
                        translatedPoints = bubbleAnalysis.translatePerim(maskInformation(d, v).PerimeterPoints, center);
                        switch orientation
                            case "horizontal"
                                angle = 0;
                            case "vertical"
                                angle = 90;
                            case "major"
                                angle = targetStats.Orientation;
                            case "minor"
                                angle = targetStats.Orientation + 90;
                        end
                        
                        %Rotate the bubble to be in its desired orientation
                        rotatedPoints = bubbleAnalysis.rotatePerim(translatedPoints, angle);
                        
                        %Calculate the surface area of the bubble (roughly)
                        maskInformation(d, v).SurfaceArea = bubbleAnalysis.calcSurf(rotatedPoints);
                        
                        %Calculate the volume of the bubble (roughly)
                        maskInformation(d, v).Volume = bubbleAnalysis.calcVol(rotatedPoints);
                        
                        if doFit
                            %Get the points for the fourier fit
                            wtBr.Message = standardMsg + ": Generaing Fourier Fit points";
                            [xVals, yVals] = bubbleAnalysis.angularPerimeter(targetMask, [maskInformation(d, v).Centroid], ...
                                floor( maskInformation(d, v).Perimeter./arcLength));
                            maskInformation(d, v).FourierPoints = [xVals, yVals];
                            
                            %Actually do the fourier fit and get the coefficients for the
                            %equation
                            wtBr.Message = standardMsg + ": Fitting " + style + " 2D Fourier Series";
                            [perimFit, perimEq] = bubbleAnalysis.fourierFit(xVals, yVals, numberTerms, adaptiveTerms, style, maskInformation(d, v).Centroid);
                            maskInformation(d, v).perimFit = perimFit;
                            maskInformation(d, v).perimEq = perimEq;
                            
                            wtBr.Message = standardMsg + ": Calculating 2D fit metrics";
                            switch style
                                case "parametric"
                                    maskInformation(d, v).FitRadius = sqrt( perimFit.a1^2 + perimFit.b1^2 );
                                case "polar (standard)"
                                    syms x
                                    str = func2str(bubbleAnalysis.genFitEq(perimFit, "polar (standard)", app.MetricTermsField.Value));
                                    symEq = str2sym(str(5:end));
                                    maskInformation(d, v).FitRadius = perimFit.r;
                                    maskInformation(d, v).FitArea = int(0.5*(symEq^2), x, 0, 2*pi);
                                    maskInformation(d, v).FitPerim = int(sqrt( symEq^2 + diff(symEq, x)^2 ), x, 0, 2*pi);
                                case "polar (phase shift)"
                                    syms x
                                    str = func2str(bubbleAnalysis.genFitEq(perimFit, "polar (phase shift)", app.MetricTermsField.Value));
                                    symEq = str2sym(str(5:end));
                                    maskInformation(d, v).FitRadius = perimFit.a0;
                                    maskInformation(d, v).FitArea = int(0.5*(symEq^2), x, 0, 2*pi);
                                    maskInformation(d, v).FitPerim = int(sqrt( symEq^2 + diff(symEq, x)^2 ), x, 0, 2*pi);
                            end
                            
                        end
                    end
                end
                
                %Generate 3D point cloud if fit was done
                if doFit
                end
            end
            %% Close waitbar and the diary
            close(wtBr);
        end
        
        %Generate the evenly angularly spaced tracking points
        function [xVals, yVals] = angularPerimeter(targetMask, center, noTC)
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
            for i = 1:rowRad
                %Get the direction to look in
                lookDirection = rad(i);
                
                %Set up the matrix
                workingRadian = radian - lookDirection;
                workingRadian(~targetPerim) = NaN;
                
                %Find the value of the elements bounding the desired angle
                upperBound = min(min(workingRadian(workingRadian > 0)));
                lowerBound = max(max(workingRadian(workingRadian < 0)));
                if isempty(upperBound)
                    upperBound = min(min(workingRadian));
                end
                if isempty(lowerBound)
                    lowerBound = max(max(workingRadian));
                end
                
                %Get the indices of the elements if more than one element is found,
                %take the farther of the two
                try 
                    [upperRow, upperCol] = find(abs(workingRadian - upperBound) < 0.0001);
                    [lowerRow, lowerCol] = find(abs(workingRadian - lowerBound) < 0.0001);
                catch ME
                    pause;
                end
                
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
        end
        
        %Fit a fourier function to the x and y points on the mask
        function [perimFit, perimEq] = fourierFit(xPoints, yPoints, maxTerms, adaptiveTerms, style, centroid)
            % Calculate optimal number of terms based on Nyquil (Nyquist) sampling
            numberTerms = bubbleAnalysis.calcNumTerms(xPoints, adaptiveTerms, maxTerms);
            if numberTerms == 0
                exit;
            end

            %Generate the fit type based on which Fourier format the user
            %wants to use
            ft = bubbleAnalysis.genFitType(numberTerms, style);
            
            %Actually fit it for the correct number of terms
            switch style
                case "parametric"
                    perimFit{1} = fit(transpose(1:length(xPoints)), xPoints, ft{1}, 'problem', 2*pi/(length(xPoints) - 1));
                    perimFit{2} = fit(transpose(1:length(yPoints)), yPoints, ft{2}, 'problem', 2*pi/(length(yPoints) - 1));
                    perimEq = bubbleAnalysis.genFitEq(perimFit, "parametric");
                case "polar (standard)"
                    xPoints = xPoints - centroid(1);
                    yPoints = yPoints - centroid(2);
                    [theta, rho] = cart2pol(xPoints, yPoints);
                    perimFit = fit(theta, rho, ft);
                    perimEq = bubbleAnalysis.genFitEq(perimFit, "polar (standard)", numcoeffs(perimFit));
                case "polar (phase shift)"
                    xPoints = xPoints - centroid(1);
                    yPoints = yPoints - centroid(2);
                    [theta, rho] = cart2pol(xPoints, yPoints);
                    perimFit = fit(theta, rho, ft);
                    perimEq = bubbleAnalysis.genFitEq(perimFit, "polar (phase shift)", numcoeffs(perimFit));
            end
        end
        
        %Extract all the perimeter points from the mask
        function output = generatePerimeterPoints(inputMask)
            boundaries = cell2mat(bwboundaries(inputMask));
            output(:, 1) = boundaries(:, 2);
            output(:, 2) = boundaries(:, 1);
        end
        
        %Translate the bubble to be centered on the axes
        function translatedPoints = translatePerim(originalPoints, centroid)
            translatedPoints = zeros(size(originalPoints));
            translatedPoints(:, 1) = originalPoints(:, 1) - centroid(1);
            translatedPoints(:, 2) = originalPoints(:, 2) - centroid(2);
        end
        
        %Rotate the bubble perimeter points so that the specified axis is
        %the horizontal axis (rotate by angle theta)
        function rotatedPoints = rotatePerim(originalPoints, theta)
            rotationMat = [cosd(-theta) sind(-theta); -sind(-theta) cosd(-theta)];
            rotatedPoints = (rotationMat*originalPoints')';
        end
        
        %Calculate the surface area of the bubble by breaking it into
        %frustrums
        function surfaceArea = calcSurf(perimeterPoints)
            topSum = 0;
            bottomSum = 0;
            parfor i = 1:2
                if i == 1
                    %Create a matrix of all the points above the X axis
                    aboveX = perimeterPoints(perimeterPoints(:, 2) > 0, :);
                    
                    %Create a vector of the x and y points
                    XVals = aboveX(:, 1);
                    YVals = aboveX(:, 2);
                    
                    %Sort the points so that the x vals are ascending 
                    [sortedX, sortIndex] = sort(XVals);
                    sortedY = YVals(sortIndex);
                    
                    %Calculate the surface area of each frustrum
                    for j = 1:length(sortedX) - 1
                        %Get the index of the right most element that
                        %hasn't already been evaluated
                        idx = length(sortedX) - j + 1;
                        %Get the right radius of the frustrum
                        R1 = abs(sortedY(idx));
                        
                        %Get the left radius of the frustrum
                        R2 = abs(sortedY(idx - 1));
                        
                        %Get the height of the frustrum
                        h = sortedX(idx) - sortedX(idx - 1);
                        
                        %Calculate the surface area and add it to the running
                        %total
                        topSum = topSum + (pi/2*(R1 + R2)*sqrt((R1 - R2)^2 + h^2)); 
                    end
                elseif i == 2
                    %Create a matrix of all the points below the X axis
                    belowX = perimeterPoints(perimeterPoints(:, 2) < 0, :);
                    
                    %Create a vector of the x and y points
                    XVals = belowX(:, 1);
                    YVals = belowX(:, 2);
                    
                    %Sort the points so that the x vals are ascending 
                    [sortedX, sortIndex] = sort(XVals);
                    sortedY = YVals(sortIndex);
                    
                    %Calculate the surface area of each frustrum
                    for j = 1:length(sortedX) - 1
                        %Get the index of the right most element that
                        %hasn't already been evaluated
                        idx = length(sortedX) - j + 1;
                        %Get the right radius of the frustrum
                        R1 = abs(sortedY(idx));
                        
                        %Get the left radius of the frustrum
                        R2 = abs(sortedY(idx - 1));
                        
                        %Get the height of the frustrum
                        h = sortedX(idx) - sortedX(idx - 1);
                        
                        %Calculate the surface area and add it to the running
                        %total
                        bottomSum = bottomSum + (pi/2*(R1 + R2)*sqrt((R1 - R2)^2 + h^2)); 
                    end
                end
            end
            surfaceArea = topSum + bottomSum;
        end
        
        %Calculate the volume of the bubble by breaking it into frustrums
        function volume = calcVol(perimeterPoints)
            topSum = 0;
            bottomSum = 0;
            parfor i = 1:2
                if i == 1
                    %Create a matrix of all the points above the X axis
                    aboveX = perimeterPoints(perimeterPoints(:, 2) > 0, :);
                    
                    %Create a vector of the x and y points
                    XVals = aboveX(:, 1);
                    YVals = aboveX(:, 2);
                    
                    %Sort the points so that the x vals are ascending 
                    [sortedX, sortIndex] = sort(XVals);
                    sortedY = YVals(sortIndex);
                    
                    %Calculate the surface area of each frustrum
                    for j = 1:length(sortedX) - 1
                        %Get the index of the right most element that
                        %hasn't already been evaluated
                        idx = length(sortedX) - j + 1;
                        %Get the right radius of the frustrum
                        R1 = abs(sortedY(idx));
                        
                        %Get the left radius of the frustrum
                        R2 = abs(sortedY(idx - 1));
                        
                        %Get the height of the frustrum
                        h = sortedX(idx) - sortedX(idx - 1);
                        
                        %Calculate the surface area and add it to the running
                        %total
                        topSum = topSum + pi/6*h*(R1^2 + R1*R2 + R2^2);
                    end
                elseif i == 2
                    %Create a matrix of all the points below the X axis
                    belowX = perimeterPoints(perimeterPoints(:, 2) < 0, :);
                    
                    %Create a vector of the x and y points
                    XVals = belowX(:, 1);
                    YVals = belowX(:, 2);
                    
                    %Sort the points so that the x vals are ascending 
                    [sortedX, sortIndex] = sort(XVals);
                    sortedY = YVals(sortIndex);
                    
                    %Calculate the surface area of each frustrum
                    for j = 1:length(sortedX) - 1
                        %Get the index of the right most element that
                        %hasn't already been evaluated
                        idx = length(sortedX) - j + 1;
                        %Get the right radius of the frustrum
                        R1 = abs(sortedY(idx));
                        
                        %Get the left radius of the frustrum
                        R2 = abs(sortedY(idx - 1));
                        
                        %Get the height of the frustrum
                        h = sortedX(idx) - sortedX(idx - 1);
                        
                        %Calculate the surface area and add it to the running
                        %total
                        bottomSum = bottomSum + pi/6*h*(R1^2 + R1*R2 + R2^2);
                    end
                end
            end
            volume = topSum + bottomSum;
        end
        
        %Calculate perimeter velocity
        function velocity = calcPerimVelocity(current, old)
            
            % Calculate the average velocity of the perimeter tracking
            % points over one frame
            avg = mean(current(:, 2) - old(:, 2));
            
            % Calculate the velocity of the topmost perimeter tracking
            % point over one frame
            [~, currentTopIdx] = min(abs(current(:, 1) - 3.*pi/.2));
            [~, oldTopIdx] = min(abs(old(:, 1) - 3.*pi./2));
            top = current(currentTopIdx, 2) - old(oldTopIdx, 2);
            
            % Calculate the velocity of the bottommost perimeter tracking
            % point over one frame
            [~, currentBotIdx] = min(abs(current(:, 1) - pi./2));
            [~, oldBotIdx] = min(abs(old(:, 1) - pi./2));
            bottom = current(currentBotIdx, 2) - old(oldBotIdx, 2);
            
            % Calculate the velocity of the rightmost periemter tracking
            % point over one frame
            [~, currentRightIdx] = min(current(:, 1));
            [~, oldRightIdx] = min(old(:, 1));
            right = current(currentRightIdx, 2) - old(oldRightIdx, 2);
            
            % Calculate the velocity of the leftmost perimeter tracking
            % ponit over one frame
            [~, currentLeftIdx] = min(abs(current(:, 1) - pi));
            [~, oldLeftIdx] = min(abs(current(:, 1) - pi));
            left = current(currentLeftIdx, 2) - old(oldLeftIdx, 2);
                        
            velocity = [avg, top, bottom, left, right];
        end
        
        %Generate a 3 cloud of points that represents the bubble
        function surfacePoints = genSurface(perimeterPoints, minArc)
            topSurf = [];
            botSurf = [];
            parfor i = 1:2
                if i == 1
                    %Create a matrix of all the points above the X axis
                    aboveX = perimeterPoints(perimeterPoints(:, 2) > 0, :);
                    
                    %Create a vector of the x and y points
                    XVals = aboveX(:, 1);
                    YVals = aboveX(:, 2);
                    
                    %Sort the points so that the x vals are ascending 
                    [sortedX, sortIndex] = sort(XVals);
                    sortedY = YVals(sortIndex);
                    
                    %Generate a circle of points for each (x, y) pairs
                    for j = 1:length(sortedX)
                        %Index the X value we are working with (since
                        %rotating around the X axis)
                        targX = sortedX(j);
                        
                        %The radius of the rotated circle is equal to the y
                        %value
                        radius = sortedY(j);
                        
                        %The perimeter of the circle 
                        cirPerim = 2*pi*radius;
                            
                        %The number of points for the circle so that the
                        %arc length between points is greater than or equal
                        %to the minArc length (div by 2 because half
                        %circle)
                        numPoints = floor(cirPerim/minArc)/2;
                        
                        %The vector of angles to evaluate the equation of
                        %the circle at 
                        theta = linspace(0, pi, numPoints);
                        
                        %Generate the Y and Z points
                        YVals = radius*cos(theta);
                        ZVals = radius*sin(theta);
                        
                        %Generate a vector of X values for the circle
                        XVals = repmat(targX, length(YVals), 1);
                        
                        %Concatenate the vectors togther
                        cirPoints = [XVals, YVals', ZVals']; 
                        
                        %Concatenate the points to the end of the existing
                        %array
                        topSurf = [topSurf; cirPoints];
                    end
                elseif i == 2
                    %Create a matrix of all the points above the X axis
                    belowX = perimeterPoints(perimeterPoints(:, 2) < 0, :);
                    
                    %Create a vector of the x and y points
                    XVals = belowX(:, 1);
                    YVals = belowX(:, 2);
                    
                    %Sort the points so that the x vals are ascending 
                    [sortedX, sortIndex] = sort(XVals);
                    sortedY = YVals(sortIndex);
                    
                    %Generate a circle of points for each (x, y) pairs
                    for j = 1:length(sortedX)
                        %Index the X value we are working with (since
                        %rotating around the X axis)
                        targX = sortedX(j);
                        
                        %The radius of the rotated circle is equal to the y
                        %value
                        radius = abs(sortedY(j));
                        
                        %The perimeter of the circle 
                        cirPerim = 2*pi*radius;
                            
                        %The number of points for the circle so that the
                        %arc length between points is greater than or equal
                        %to the minArc length (div by 2 because half
                        %circle)
                        numPoints = floor(cirPerim/minArc)/2;
                        
                        %The vector of angles to evaluate the equation of
                        %the circle at 
                        theta = linspace(0, -pi, numPoints);
                        
                        %Generate the Y and Z points
                        YVals = radius*cos(theta);
                        ZVals = radius*sin(theta); %Multiply by negative 1 because this is technically the bottom half of the circle
                        
                        %Generate a vector of X values for the circle
                        XVals = repmat(targX, length(YVals), 1);
                        
                        %Concatenate the vectors togther
                        cirPoints = [XVals, YVals', ZVals']; 
                        
                        %Concatenate the points to the end of the existing
                        %array
                        botSurf = [botSurf; cirPoints];
                    end
                end
            end
            surfacePoints = [topSurf; botSurf];
        end
        
        %Recalculate the surface area and volume if selection is changed
        function info = reCalcSurfandVolume(info, rotAxis, numFrames, ignoreFrames)
            for i = 1:numFrames
                if isempty(find(ignoreFrames == i, 1))
                    translatedPerim = bubbleAnalysis.translatePerim(info(i).PerimeterPoints, info(i).Centroid);
                    switch rotAxis
                        case 'horizontal'
                            angle = 0;
                        case 'vertical'
                            angle = 90;
                        case 'major'
                            angle = info(i).Orientation;
                        case 'minor'
                            angle = info(i).Orientation + 90;
                    end
                    rotatedPerim = rotatePerim(translatedPerim, angle);
                    info(i).SurfaceArea = bubbleAnalysis.calcSurf(rotatedPerim);
                    info(i).Volume = bubbleAnalysis.calcVol(rotatedPerim);
                end
            end
        end
        
        % A function to calculate the number of terms in the bubble fit
        % equation dependent on Nyquist sampling (half the number of points
        % minus 1)
        function numTerms = calcNumTerms(xPoints, adaptiveTerms, maxTerms)
            numTerms = floor((length(xPoints) - 1)/2);
            if ~adaptiveTerms
                if numTerms > maxTerms
                    numTerms = maxTerms;
                end
            end
        end
        
        % A function to generate the fit type depending on the user defined
        % number of terms and user defined fit style
        function ft = genFitType(numTerms, style)
            switch style
                case "parametric"
                    Xcoeffs = cell(1, numTerms + 1);
                    Ycoeffs = cell(1, numTerms + 1);
                    Xterms = cell(1, numTerms + 1);
                    Yterms = cell(1, numTerms + 1);
                    
                    for i = 1:numTerms
                        Xcoeffs{i} = append('a', char(num2str(i)));
                        Ycoeffs{i} = append('b', char(num2str(i)));
                        Xterms{i} = append('cos(', char(num2str(i)), '*w*x)');
                        Yterms{i} = append('sin(', char(num2str(i)), '*w*x)');
                    end
                    Xcoeffs{end} = 'a0';
                    Ycoeffs{end} = 'b0';
                    Xterms{end} = '1';
                    Yterms{end} = '1';
                    
                    ft{1} = fittype(Xterms, 'coefficients', Xcoeffs, 'problem', 'w');
                    ft{2} = fittype(Yterms, 'coefficients', Ycoeffs, 'problem', 'w');
                case "polar (standard)"
                    %% Initialize the coefficient and term cell arrays
                    coeffs = cell(1, 2*numTerms + 1);
                    terms = cell(1, 2*numTerms + 1);
                    
                    %% Create the coefficient cell array
                    for j = 1:numTerms
                        coeffs{2*j - 1} = append('a', char(num2str(j)));
                        coeffs{2*j} = append('b', char(num2str(j)));
                    end
                    coeffs{end} = 'r';
                    
                    %% Create the terms cell array
                    for k = 1:numTerms
                        terms{2*k - 1} = append('cos(', char(num2str(k)), '*x)');
                        terms{2*k} = append('sin(', char(num2str(k)), '*x)');
                    end
                    terms{end} = '1';
                    
                    %% Create the fit type
                    ft = fittype(terms, 'coefficients', coeffs);
                case "polar (phase shift)"
                    %% Start the string function
                    strFunc = "@(a0, ";
                    
                    %% Input vars
                    for i = 1:numTerms
                        strFunc = strFunc + "a" + num2str(i) + ", ";
                    end
                    for i = 1:numTerms
                        strFunc = strFunc + "phi" + num2str(i) + ", ";
                    end
                    strFunc = strFunc + "x) a0";
                    
                    %% Terms
                    for i = 1:numTerms
                        strFunc = strFunc + " + a" + num2str(i) + ".*cos(" + num2str(i) + ".*x + phi" + num2str(i) + ")";
                    end
                    
                    %% Create the fit type
                    ft = fittype(str2func(strFunc));
            end
        end
        
        % A Function to reconstruct the resulting fit into a usable
        % equation based on the fit style
        function fitEq = genFitEq(fit, style, terms)
            switch style
                case "parametric"
                    xFit = fit{1};
                    yFit = fit{2};
                    
                    xw = xFit.w;
                    yw = yFit.w;
                    
                    xnames = coeffnames(xFit);
                    ynames = coeffnames(yFit);
                    
                    xvals = coeffvalues(xFit);
                    yvals = coeffvalues(yFit);
                    
                    xStr = "@(x) " + num2str(xFit.a0) + " ";
                    yStr = "@(x) " + num2str(yFit.b0) + " ";
                    
                    for i = 1:(terms - 1)
                        targetCoeffX = "a" + num2str(i);
                        targetCoeffY = "b" + num2str(i);
                        
                        xCoeffVal = xvals(xnames == targetCoeffX);
                        yCoeffVal = yvals(ynames == targetCoeffY);
                        
                        xStr = xStr + "+ " + num2str(xCoeffVal) + "*cos(" + num2str(i) + "*" + num2str(xw) + "*x)";
                        yStr = yStr + "+ " + num2str(yCoeffVal) + "*sin(" + num2str(i) + "*" + num2str(yw) + "*x)";
                    end
                    fitEq{1} = str2func(xStr);
                    fitEq{2} = str2func(yStr);
                case "polar (standard)"
                    names = coeffnames(fit);
                    
                    vals = coeffvalues(fit);
                    
                    fitStr = "@(x) " + num2str(fit.r) + " ";
                    
                    for i = 1:(terms/2)
                        targetCoeffX = "a" + num2str(i);
                        targetCoeffY = "b" + num2str(i);
                        
                        xVal = vals(names == targetCoeffX);
                        yVal = vals(names == targetCoeffY);
                        
                        fitStr = fitStr + "+ " + num2str(xVal) + "*cos(" + num2str(i) + "*x) + " + num2str(yVal) + "*sin(" + num2str(i) + "*x)";
                    end
                    fitEq = str2func(fitStr);
                case "polar (phase shift)"
                    names = coeffnames(fit);
                    
                    vals = coeffvalues(fit);
                    
                    fitStr = "@(x) " + num2str(fit.a0) + " ";
                    
                    for i = 1:(terms/2)
                        targetCoeff = "a" + num2str(i);
                        targetAngle = "phi" + num2str(i);
                        
                        coeffval = vals(names == targetCoeff);
                        angleval = vals(names == targetAngle);
                        
                        fitStr = fitStr + "+ " + num2str(coeffval) + "*cos(" + num2str(i) + "*x + " + num2str(angleval) + ")";
                    end
                    fitEq = str2func(fitStr);
            end
        end
        
        %A function to generate a 3D point cloud from the Fourier Fits
        function points = genCloud(slices, resolution, varargin)
            views = length(varargin);
            switch views
                case 1
                case 2
                case 3
            end
        end
        
        %A function to convert our local definition of spherical coordinates to
        %universal cartesian coordinates
        function cartPoints = convertToCart(r, theta, phi)
            
            cartPoints = [r.*cos(theta).*cos(phi), r.*cos(theta).*sin(phi), r.*sin(theta)];
            
        end
        
        %A function to fit a surface to our 3D point cloud
        function [fit, equation] = sphFit(r, theta, phi, thetamodes, phimodes)
        end
        
        % A function to generate the spherical fit type for the rotated 3D
        % point cloud of the bubble perimeter fit
        function ft = genSphFitType(thetamodes, phimodes)
        end
        
        % A function to reconstruct the resulting fit into a usable
        % equation based on the fit and number of vibration modes desired
        function fitEq = genSphFitEq(fit, thetamodes, phimodes)
        end
        
    end
end