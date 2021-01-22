classdef bubbleAnalysis
    methods (Static)
        %Pre Process the frames before analyzing them
        function returnFrames = preprocessFrames(app, inputFrames)
                        
            [~, ~, numImages] = size(inputFrames);
            returnFrames = zeros(size(inputFrames));

            if string(app.PreProcessMethod.Value) == "Sharpen"
                for i = 1:numImages
                    returnFrames(:, :, i) = imsharpen(inputFrames(:, :, i),'Amount', 1);
                end
            else
                for i = 1:numImages
                    returnFrames(:, :, i) = imgaussfilt(inputFrames(:, :, i), 1);
                end
            end            
        end
        
        % Generates a mask for the given frame, going forward in time
        function outputMask = maskGen(figure, inputFrames, direction, ignoreFirstFrame)
            % A function to isolate the bubble in each frame, returns an MxNxA logical array where M & N are the image size and A is the number of frames
            
            %% Program input and set up
            [row, col, depth] = size(inputFrames);      %Get the size of the initial frame array
            outputMask = zeros(row, col, depth);        %Create the output frame array
            tic;
            oldData.Center = [col./2, row./2];
            oldData.Size = 0;
            
            %Create the progress bar
            wtBr = uiprogressdlg(figure, 'Title', 'Please wait', 'Message', 'Isolating...', 'Cancelable', 'on');
            
            %% Create mask for each frame
            switch direction
                case 'forward' 
                    range = (1 + ignoreFirstFrame):depth;
                case 'reverse'
                    range = depth:-1:(1 + ignoreFirstFrame);
            end
            for f = range
                wtBr.Message = "Isolating bubble in frame: " + num2str(f) + "/" + num2str(depth);
                if wtBr.CancelRequested
                    break;
                end
                
                %% Get the frame
                targetImage = inputFrames(:, :, f);
                
                %% Create a mask based on color
                grayImage = bubbleAnalysis.colorMask(targetImage, oldData);
                if any(any(grayImage))
                    grayCC = bwconncomp(grayImage, 8);
                    grayStats = regionprops(grayCC, 'Centroid', 'Circularity');
                    grayCenter = grayStats.Centroid;
                end
                
                %% Create a mask based on edges
                edgeImage = bubbleAnalysis.edgeMask(targetImage, oldData);
                if any(any(edgeImage))
                    edgeCC = bwconncomp(edgeImage, 8);
                    edgeStats = regionprops(edgeCC, 'Centroid', 'Circularity');
                    edgeCenter = edgeStats.Centroid;
                end
                
                %% Decide which mask/combination of masks to use
                %If the gray mask is empty use the edge mask
                if ~any(any(grayImage))
                    finalImage = edgeImage;
                    %If the edge mask is empty use the gray mask
                elseif ~any(any(edgeImage))
                    finalImage = grayImage;
                elseif any(any(grayImage)) && any(any(edgeImage))
                    %If both masks are close in size, add them together.
                    if bubbleAnalysis.areCloseInSize(grayImage, edgeImage) && bubbleAnalysis.areCloseInLocation(grayImage, edgeImage)
                        finalImage = grayImage + edgeImage;
                        %If the edge mask is bigger than the gray mask then if there is no
                        %overlap in the regions, add the masks together and isolate the
                        %most likely object. Otherwise, the final masks is where both are
                        %present
                    elseif cellfun(@numel, grayCC.PixelIdxList) < cellfun(@numel, edgeCC.PixelIdxList) && bubbleAnalysis.areCloseInLocation(grayImage, edgeImage)
                        if ~any(any(grayImage & edgeImage))
                            finalImage = bubbleAnalysis.isolateObject(logical(grayImage + edgeImage), targetImage);
                        else
                            finalImage = grayImage & edgeImage;
                        end
                        %If the gray mask is bigger than the edge mask, then if the
                        %circularities are wildly different, use mask logic to figure out
                        %which one to use, otherwise if the ciruclarities are similar then
                        %use the combination of the two masks.
                    elseif cellfun(@numel, grayCC.PixelIdxList) > cellfun(@numel, edgeCC.PixelIdxList) && sqrt((grayCenter(1) - edgeCenter(1)).^2 + (grayCenter(2) - edgeCenter(2)).^2) < 10
                        if abs ( grayStats.Circularity - edgeStats.Circularity ) > 0.15 && grayStats.Circularity > edgeStats.Circularity
                            finalImage = bubbleAnalysis.maskLogic(grayImage, edgeImage, targetImage, oldData);
                        elseif abs( grayStats.Circularity - edgeStats.Circularity) > 0.15 && grayStats.Circularity < edgeStats.Circularity
                            finalImage = bubbleAnalysis.maskLogic(edgeImage, grayImage, targetImage, oldData);
                        elseif abs ( grayStats.Circularity - edgeStats.Circularity ) <= 0.15
                            finalImage = grayImage + edgeImage;
                        end
                        %If both masks are close in size but not close in location, use the
                        %one with the mask that is closer to the center
                    elseif bubbleAnalysis.areCloseInSize(grayImage, edgeImage) && ~bubbleAnalysis.areCloseInLocation(grayImage, edgeImage)
                        finalImage = bubbleAnalysis.closerToCenterMask(grayImage, edgeImage);
                        %If all else fails, use the most circular mask
                    else
                        finalImage = bubbleAnalysis.moreCircularMask(grayImage, edgeImage);
                    end
                end
                
                %% Fault check the final image before assignment
                finalCC = bwconncomp(finalImage, 8);
                
                %If there is more than one object, attempt to isolate the correct object
                if finalCC.NumObjects > 1
                    outputMask(:, :, f) = logical(bubbleAnalysis.isolateObject(finalImage, targetImage), oldData);
                else
                    outputMask(:, :, f) = logical(finalImage);
                end

                %Update the oldData values as long as the mask isn't empty
                if any(any(finalImage))
                    finalCC = bwconncomp(finalImage, 8);
                    oldData.Size = cellfun(@numel, finalCC.PixelIdxList);
                    finalStats = regionprops(finalImage, 'Centroid');
                    oldData.Center = finalStats.Centroid;
                end
                
                %Update the waitbar
                wtBr.Value = f/depth;
            end
            %Close waitbar
            close(wtBr);
        end
        
        %Create a mask based on color
        function grayImg = colorMask(targetImage, oldData)
            %A function to create a mask for the bubble based on pixel intensity values
            
            %Calculate the gray threshold for the image and binarize it based on that, Flip black and white, Get rid of any white pixels connected to the border, Fill any holes in the image
            grayImg = imfill(bwmorph(bwmorph(bwmorph(imclearborder(imcomplement(imbinarize(targetImage, graythresh(targetImage)))), 'clean'), 'diag'), 'bridge'), 'holes');
            %Remove ridiculously small and large objects from the image
            grayImg = bubbleAnalysis.removeOutliers(grayImg);
            %Refresh the connected components list
            CC = bwconncomp(grayImg, 8);
            %If there is still more than one object, attempt to isolate the most likley
            %object
            if CC.NumObjects > 1
                grayImg = bubbleAnalysis.isolateObject(grayImg, targetImage, oldData);
            end
            grayImg = imfill(grayImg, 'holes');
        end
        
        %Create a mask based on edges
        function edgeImage = edgeMask(targetImage, oldData)
            %A function to create a binary mask of the bubble based on edge detection
            [~, threshold] = edge(targetImage, 'Sobel');
            edgeImage = imfill(imclearborder(imcomplement(imdilate(edge(targetImage, 'Sobel', threshold), [strel('line', 3, 90) strel('line', 3, 0)]))), 'holes');
            %Remove ridiculously large and small objects from the image
            edgeImage = bubbleAnalysis.removeOutliers(edgeImage);
            %Refresh the connected components list
            CC = bwconncomp(edgeImage, 8);
            %If there is still more than one object, attempt to isolate the the object
            if CC.NumObjects > 1
                edgeImage = bubbleAnalysis.isolateObject(edgeImage, targetImage, oldData);
            end
        end
        
        %Remove outlier objects in the image
        function mask = removeOutliers(mask)
            %Get rid of ridiculously large and small objects in the mask and objects far from the region of interest
            [row, col] = size(mask);
            %Find the connected components in the image
            CC = bwconncomp(mask, 8);
            stats = regionprops(CC, 'Centroid');
            %Get rid of ridiculously small objects (smaller than 50 square pixels)
            objectSize = cellfun(@numel, CC.PixelIdxList);
            for h = 1:CC.NumObjects
                if objectSize(h) <= 50
                    mask(CC.PixelIdxList{h}) = 0;
                end
            end
            %Get rid of ridiculously big objects (bigger than half the image size)
            for h = 1:CC.NumObjects
                if objectSize(h) > (row.*col/2)
                    mask(CC.PixelIdxList{h}) = 0;
                end
            end
            %Get rid of objects far away from the center (objects that have a centroid
            %more than 200 pixels away from the center
            for j = 1:CC.NumObjects
                objectCenter = stats(j).Centroid;
                if sqrt( (objectCenter(1) - col./2).^2 + (objectCenter(2) - row./2).^2 ) > 200
                    mask(CC.PixelIdxList{j}) = 0;
                end
            end
        end
        
        %Isolate the most likely object to be the bubble in the image
        function mask = isolateObject(mask, targetImage, oldData)
            
            % A function to isolate one object in a binary mask most likely considered to be the bubble based on various characteristics
            CC = bwconncomp(mask, 8);
            stats = regionprops(CC, 'Circularity', 'Centroid');
            
            %Find the object closest in size to the old mask
            sizes = zeros(1, CC.NumObjects);
            for i = 1:CC.NumObjects
                sizes(i) = numel(CC.PixelIdxList{i});
            end
            if oldData.Size == 0
                [~, maxSize] = max(sizes);
            else
                [~, maxSize] = min(abs(sizes - oldData.Size));
            end
            
            %Find the obejct closest to the center of the frame, but not exactly in the center
            distances = zeros(1, CC.NumObjects);
            for i = 1:CC.NumObjects
                center = stats.Centroid;
                oldCenter = oldData.Center;
                distances(i) = sqrt((center(1) - oldCenter(1)).^2 + (center(2) - oldCenter(2)).^2);
            end
            [~, minDist] = min(distances(distances ~= 0));

            %Find the object with the lowest pixel average
            averages = zeros(1, CC.NumObjects);
            for i = 1:CC.NumObjects
                averages(i) = mean(targetImage(CC.PixelIdxList{i}), 'all');
            end
            averages(averages == 0) = 100;
            [~, lowestAvg] = min(averages);
            
            %Calculate the significance value for each object
            significance = distances./sizes.*averages;
            [~, minSig] = min(significance);

            %Decide which object to keep
            if isequaln(maxSize, minDist, lowestAvg, minSig)
                objIdx = minSig;                            %Ideal case
            elseif isequaln(maxSize, lowestAvg, minDist)
                objIdx = maxSize;                           %If the significance value is misleading
            elseif isequaln(minDist, lowestAvg, minSig)
                objIdx = minDist;                           %If the largest object is misleading
            elseif isequaln(minDist, maxSize, minSig)
                objIdx = minDist;                           %If the lowest average is misleading
            elseif isequaln(maxSize, lowestAvg, minSig)
                objIdx = maxSize;                           %If the closest object is misleading
            else
                circularities = [stats.Circularity];
                interestVector = [maxSize, minDist, lowestAvg, minSig];
                newCircularities = zeros(size(circularities));
                newCircularities(:) = NaN;
                for i = 1:length(interestVector)
                    newCircularities(interestVector(i)) = circularities(interestVector(i));
                end
                mostCircular = zeros(size(circularities));
                for i = length(circularities)
                    mostCircular(i) = abs(1 - newCircularities(i));
                end
                [~, objIdx] = min(mostCircular);
            end
            
            %Get rid of the other objects
            for j = 1:CC.NumObjects
                if j == objIdx
                    continue;
                else
                    mask(CC.PixelIdxList{j}) = 0;
                end
            end
        end
        
        %Advanced mask comparision logic that targets mask circularity
        function finalImage = maskLogic(higherCircularityMask, lowerCircularityMask, targetImage, oldData)
            hCMStats = regionprops(higherCircularityMask, 'Circularity');
            finalStatsEither = regionprops(logical(higherCircularityMask + lowerCircularityMask), 'Circularity');
            finalCCEither = bwconncomp(logical(higherCircularityMask + lowerCircularityMask), 8);
            finalStatsBoth = regionprops(logical(higherCircularityMask & lowerCircularityMask), 'Circularity');
            finalCCBoth = bwconncomp(logical(higherCircularityMask & lowerCircularityMask), 8);
            if finalCCEither.NumObjects > 1
                finalStatsEither = regionprops(bubbleAnalysis.isolateObject(logical(higherCircularityMask + lowerCircularityMask), targetImage, oldData), 'Circularity');
            end
            if finalCCBoth.NumObjects == 1
                finalImage = bubbleAnalysis.isolateObject(logical(higherCircularityMask + lowerCircularityMask), targetImage, oldData);
                finalStatsEither = regionprops(finalImage, 'Circularity');
                if finalStatsEither.Circularity > hCMStats.Circularity
                    finalImage = higherCircularityMask + lowerCircularityMask;
                elseif finalStatsBoth.Circularity > hCMStats.Circularity
                    finalImage = higherCircularityMask & lowerCircularityMask;
                else
                    finalImage = higherCircularityMask;
                end
            elseif finalCCBoth.NumObjects == 0
                if finalStatsEither.Circularity > hCMStats.Circularity
                    finalImage = higherCircularityMask + lowerCircularityMask;
                else
                    finalImage = higherCircularityMask;
                end
            end
        end
        
        %Compare the forward and reverse mask sets to determine which one
        %to use
        function finalMask = compareMasks(forwardMask, reverseMask)
            
            %% Preliminary size check
            if size(forwardMask) ~= size(reverseMask)
                error("Unequal mask sizes. Check input variables");
            end
            
            %% Get the number of frames and set up the output mask
            [~, ~, numFrames] = size(forwardMask);
            finalMask = zeros(size(forwardMask));
            
            %% Compare both masks for the same frame
            for i = 1:numFrames
                
                %% Index the forward mask
                forwardTargetMask = forwardMask(:, :, i);
                
                %% Index the reverse mask
                reverseTargetMask = reverseMask(:, :, i);
                
                %% Mask comparision logic
                if ~any(any(forwardTargetMask))
                    finalMask(:, :, i) = reverseTargetMask;         %If the forward mask is empty use the reverse mask
                elseif ~any(any(reverseTargetMask))
                    finalMask(:, :, i) = forwardTargetMask;         %If the reverse mask is empty use the forward mask
                elseif any(any(forwardTargetMask)) && any(any(reverseTargetMask))
                    sameSize = bubbleAnalysis.areCloseInSize(forwardTargetMask, reverseTargetMask);
                    sameLoc = bubbleAnalysis.areCloseInLocation(forwardTargetMask, reverseTargetMask);
                    if sameSize && sameLoc
                        finalMask(:, :, i) = logical(forwardTargetMask + reverseTargetMask);
                    elseif ~sameSize && sameLoc
                        finalMask(:, :, i) = bubbleAnalysis.largerMask(forwardTargetMask, reverseTargetMask);
                    elseif sameSize && ~sameLoc
                        finalMask(:, :, i) = bubbleAnalysis.closerToCenterMask(forwardTargetMask, reverseTargetMask);
                    elseif ~sameSize && ~sameLoc
                        finalMask(:, :, i) = bubbleAnalysis.moreCircularMask(forwardTargetMask, reverseTargetMask);
                    end
                end
            end
        end
        
        %Determine if the objects in the mask are close in size
        function result = areCloseInSize(maskOne, maskTwo)
            maskOneCC = bwconncomp(maskOne);
            maskTwoCC = bwconncomp(maskTwo);
            
            maskOneSize = cellfun(@numel, maskOneCC.PixelIdxList);
            maskTwoSize = cellfun(@numel, maskTwoCC.PixelIdxList);
            
            %Calculate one percent of the size of the smaller mask
            if bubbleAnalysis.largerMask(maskOne, maskTwo) == maskOne
                constraint = 0.1*maskTwoSize;   %If the first mask is bigger the constraint is one percent of the second mask         
            else
                constraint = 0.1*maskTwoSize;   %If the second mask is bigger then the constaint is one percent of the fist mask
            end
            
            if abs( maskOneSize - maskTwoSize) < constraint
                result = 1;
            else
                result = 0;
            end
        end
        
        %Determine if the objects in the mask are close together
        function result = areCloseInLocation(maskOne, maskTwo)
            maskOneStats = regionprops(maskOne, 'Centroid');
            maskTwoStats = regionprops(maskTwo, 'Centroid');
            
            maskOneCenter = maskOneStats.Centroid;
            maskTwoCenter = maskTwoStats.Centroid;
            
            if sqrt((maskOneCenter(1) - maskTwoCenter(1)).^2 + (maskOneCenter(2) - maskTwoCenter(2)).^2) < 10
                result = 1;
            else
                result = 0;
            end
        end
        
        %Return that mask that is the larger of the two
        function returnMask = largerMask(maskOne, maskTwo)
            maskOneCC = bwconncomp(maskOne);
            maskTwoCC = bwconncomp(maskTwo);
            
            maskOneSize = cellfun(@numel, maskOneCC.PixelIdxList);
            maskTwoSize = cellfun(@numel, maskTwoCC.PixelIdxList);
            
            if maskOneSize > maskTwoSize
                returnMask = maskOne;
            else
                returnMask = maskTwo;
            end
        end
        
        %Return the mask that is closer to the center
        function returnMask = closerToCenterMask(maskOne, maskTwo)
            maskOneStats = regionprops(maskOne, 'Centroid');
            maskTwoStats = regionprops(maskTwo, 'Centroid');
            
            maskOneCenter = maskOneStats.Centroid;
            maskTwoCenter = maskTwoStats.Centroid;
            
            [row, col] = size(maskOne);
            
            distanceToCenterOne = sqrt( (maskOneCenter(1) - col./2).^2 + (maskOneCenter(2) - row./2).^2 );
            distanceToCenterTwo = sqrt( (maskTwoCenter(1) - col./2).^2 + (maskTwoCenter(2) - row./2).^2 );
            
            if distanceToCenterOne > distanceToCenterTwo
                returnMask = maskTwo;
            else
                returnMask = maskOne;
            end
        end
        
        %Return the most circular of two masks
        function returnMask = moreCircularMask(maskOne, maskTwo)
            maskOneStats = regionprops(maskOne, 'Circularity');
            maskTwoStats = regionprops(maskTwo, 'Circularity');
            
            maskOneCircle = maskOneStats.Circularity;
            maskTwoCircle = maskTwoStats.Circularity;
            
            if abs(1 - maskOneCircle) > abs(1 - maskTwoCircle)
                returnMask = maskTwo;
            else
                returnMask = maskOne;
            end
        end
        
        %Return a mask in a multiviewpoint video
        function mask = multiViewDetect(frames)
        end
        
        %Analyze the video
        function maskInformation = bubbleTrack(app, mask, arcLength, orientation, doFit, numberTerms, adaptiveTerms, ignoreFrames, style)
            % A function to generate data about each mask
            
            %% Get number of frames
            [~, ~, depth] = size(mask);
            
            %% Define the struct
            maskInformation = struct('Centroid', cell(depth, 1), 'TrackingPoints', cell(depth, 1), 'AverageRadius', cell(depth, 1), ...
                'SurfaceArea', cell(depth, 1), 'Volume', cell(depth, 1), 'FourierPoints', cell(depth, 1),...
                'perimFit', cell(depth, 1), 'perimEq', cell(depth, 1), 'Area', cell(depth, 1), 'Perimeter', cell(depth, 1), ...
                'PerimeterPoints', cell(depth, 1), 'PerimVelocity', cell(depth, 1), 'Orientation', cell(depth, 1));
            
            %% Create the progress bar
            wtBr = uiprogressdlg(app.UIFigure, 'Title', 'Please wait', 'Message', 'Calculating...');
            
            %% Analyze the mask for each frame
            for d = 1:depth
                standardMsg = "Analyzing frame " + num2str(d) + "/" + num2str(depth);
                wtBr.Message = standardMsg;
                wtBr.Value = d./depth;
                %Skip any frames that are in the ignore list
                if ~isempty(find(ignoreFrames == d, 1))
                    maskInformation(d).Centroid = NaN;
                    maskInformation(d).Area = NaN;
                    maskInformation(d).Perimeter = NaN;
                    maskInformation(d).PerimeterPoints = NaN;
                    maskInformation(d).TrackingPoints = NaN;
                    maskInformation(d).FourierPoints = NaN;
                    maskInformation(d).AverageRadius = NaN;
                    maskInformation(d).SurfaceArea = NaN;
                    maskInformation(d).Volume = NaN;
                    maskInformation(d).perimFit = NaN;
                    maskInformation(d).perimEq = NaN;
                    maskInformation(d).PerimVelocity = NaN;
                    maskInformation(d).Orientation = NaN;
                    continue;
                else
                    %Get the mask
                    targetMask = mask(:, :, d);
                    
                    %Use regionprops to get basic mask data
                    wtBr.Message = standardMsg + ": Calculating centroid, area, and perimeter";
                    targetStats = regionprops(targetMask, 'Centroid', 'Area', 'Perimeter', 'Orientation');
                    
                    %Assign that data to the output struct
                    maskInformation(d).Centroid = targetStats.Centroid;
                    
                    maskInformation(d).Area = targetStats.Area;
                    
                    maskInformation(d).Perimeter = targetStats.Perimeter;
                    
                    maskInformation(d).Orientation = targetStats.Orientation;
                    
                    maskInformation(d).PerimeterPoints = bubbleAnalysis.generatePerimeterPoints(targetMask);
                    
                    %Get the tracking points
                    wtBr.Message = standardMsg + ": Generaing tracking points";
                    [xVals, yVals] = bubbleAnalysis.angularPerimeter(targetMask, [maskInformation(d).Centroid], 50);
                    maskInformation(d).TrackingPoints = [xVals, yVals];
                    
                    %Calculate the perimeter velocity as long as we are not
                    %on the first frame and the previous frame was not
                    %ignored
                    if (d > 1) 
                        if ~isnan(maskInformation(d - 1).PerimeterPoints)
                            maskInformation(d).PerimVelocity = zeros(1, 5);
                            maskInformation(d).PerimVelocity(1, :) = bubbleAnalysis.calcPerimVelocity(maskInformation(d).TrackingPoints, maskInformation(d - 1).TrackingPoints);
                        else 
                            maskInformation(d).PerimVelocity = NaN;
                        end
                    else
                        maskInformation(d).PerimVelocity = NaN;
                    end
                    
                    %Calculate the average radius
                    center = [maskInformation(d).Centroid];
                    wtBr.Message = standardMsg + ": Calculating average radius";
                    maskInformation(d).AverageRadius = mean(sqrt( (center(1) - xVals).^2 + (center(2) - yVals).^2 ), 'all');
                    
                    %Translate the bubble to be centered on the axes
                    translatedPoints = bubbleAnalysis.translatePerim(maskInformation(d).PerimeterPoints, center);
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
                    maskInformation(d).SurfaceArea = bubbleAnalysis.calcSurf(rotatedPoints);
                    
                    %Calculate the volume of the bubble (roughly)
                    maskInformation(d).Volume = bubbleAnalysis.calcVol(rotatedPoints);
   
                    if doFit

                        %Get the points for the fourier fit
                        wtBr.Message = standardMsg + ": Generaing Fourier Fit points";
                        [xVals, yVals] = bubbleAnalysis.angularPerimeter(targetMask, [maskInformation(d).Centroid], ...
                            floor( maskInformation(d).Perimeter./arcLength));
                        maskInformation(d).FourierPoints = [xVals, yVals];

                        %Actually do the fourier fit and get the coefficients for the
                        %equation
                        wtBr.Message = standardMsg + ": Fitting " + style + " Fourier Series";
                        [perimFit, perimEq] = bubbleAnalysis.fourierFit(xVals, yVals, numberTerms, adaptiveTerms, style, maskInformation(d).Centroid);
                        maskInformation(d).perimFit = perimFit;
                        maskInformation(d).perimEq = perimEq;
                    end
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
                    perimEq = bubbleAnalysis.genFitEq(perimFit, "polar (standard)");
                case "polar (phase shift)"
                    xPoints = xPoints - centroid(1);
                    yPoints = yPoints - centroid(2);
                    [theta, rho] = cart2pol(xPoints, yPoints);
                    perimFit = fit(theta, rho, ft);
                    perimEq = bubbleAnalysis.genFitEq(perimFit, "polar (phase shift)");
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
            rotationMat = [cosd(theta) sind(theta); -sind(theta) cosd(theta)];
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
        function velocity = calcPerimVelocity(currentFramePoints, oldFramePoints)
            %Calculate the average velocity of the perimeter tracking
            %points over one frame
            avg = mean(sqrt( (oldFramePoints(:, 1) - currentFramePoints(:, 1)).^2 + (oldFramePoints(:, 2) - currentFramePoints(:, 2)).^2));
            
            %Calculate the average velocity of the top of the bubble over
            %one frame
            [~, topCoordOld] = max(oldFramePoints(:, 2));
            [~, topCoordNew] = max(currentFramePoints(:, 2));
            top = sqrt( (oldFramePoints(topCoordOld, 1) - currentFramePoints(topCoordNew, 1)).^2 + ...
                (oldFramePoints(topCoordOld, 2) - currentFramePoints(topCoordNew, 2)).^2);
            
            %Calculate the average velocity of the bottom of the bubble over
            %one frame
            [~, botCoordOld] = min(oldFramePoints(:, 2));
            [~, botCoordNew] = min(currentFramePoints(:, 2));
            bottom = sqrt( (oldFramePoints(botCoordOld, 1) - currentFramePoints(botCoordNew, 1)).^2 + ...
                (oldFramePoints(botCoordOld, 2) - currentFramePoints(botCoordNew, 2)).^2);
            
            %Calculate the average velocity of the left edge of the bubble over
            %one frame
            [~, leftCoordOld] = min(oldFramePoints(:, 1));
            [~, leftCoordNew] = min(currentFramePoints(:, 1));
            left = sqrt( (oldFramePoints(leftCoordOld, 1) - currentFramePoints(leftCoordNew, 1)).^2 + ...
                (oldFramePoints(leftCoordOld, 2) - currentFramePoints(leftCoordNew, 2)).^2);
            
            %Calculate the average velocity of the right edge of the bubble over
            %one frame
            [~, rightCoordOld] = max(oldFramePoints(:, 1));
            [~, rightCoordNew] = max(currentFramePoints(:, 1));
            right = sqrt( (oldFramePoints(rightCoordOld, 1) - currentFramePoints(rightCoordNew, 1)).^2 + ...
                (oldFramePoints(rightCoordOld, 2) - currentFramePoints(rightCoordNew, 2)).^2);
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
        function fitEq = genFitEq(fit, style)
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
                    
                    for i = 1:(numcoeffs(xFit) - 1)
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
                    
                    for i = 1:(numcoeffs(fit)/2)
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
                    
                    for i = 1:(numcoeffs(fit)/2)
                        targetCoeff = "a" + num2str(i);
                        targetAngle = "phi" + num2str(i);
                        
                        coeffval = vals(names == targetCoeff);
                        angleval = vals(names == targetAngle);
                        
                        fitStr = fitStr + "+ " + num2str(coeffval) + "*cos(" + num2str(i) + "*x + " + num2str(angleval) + ")";
                    end
                    fitEq = str2func(fitStr);
            end
        end
    end
end