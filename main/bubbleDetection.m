classdef bubbleDetection
    methods (Static)
        function refinedFrames = removeTimeStamps(frames)
            %Calculates number of frames
            [~, ~, depth] = size(frames);
            
            %Sets up output Matrix
            refinedFrames = zeros(size(frames));
            
            %Sets the value of any pure black or pure white pixels to NaN
            %so they aren't considered during thresholding and other
            %detection-related algorithms
            for i = 1:depth
                img = frames(:, :, i);
                img(img == 0) = NaN;
                img(img == 1) = NaN;
                refinedFrames(:, :, i) = img;
            end
        end
        
        function refinedFrames = normalizeLighting(frames, style, iff, refFrame)
            [~, ~, numFrames] = size(frames);
            refinedFrames = zeros(size(frames));
            switch style
                case "background subtraction"
                    % Substract the gray level of the refrence frame from
                    % all of the other frames (recommended)
                    refinedFrames = zeros(size(frames));
                    for i = 1:numFrames
                        refinedFrames(:, :, i) = abs( frames(:, :, i) - refFrame );
                    end
                case "gray-level normalization"
                    % Calculate the average gray level of each frame and
                    % average it, multiply each frame by a calculated
                    % intensity factor to normalize the lighting (not
                    % recommended)
                    avg = zeros(numFrames, 1);
                    for i = (1 + iff):numFrames
                        selFrame = frames(:, :, 1);
                        avg(i) = mean(selFrame(selFrame >= graythresh(selFrame)), 'all');
                    end
                    grayAvg = mean(avg);
                    for i = 1:numFrames
                        img = frames(:, :, i)*(grayAvg./avg(i));
                        img(img < 0) = 0.01;
                        refinedFrames(:, :, i) = img;
                    end
            end                  
        end
        
        function refinedFrames = increaseContrast(frames)
            refinedFrames = zeros(size(frames));                                    %Initialize the output matrix (preallocation)
            [~, ~, depth] = size(frames);                                           %Calculate the number of frames
            for i = 1:depth         
                minVal = min(min(frames(:,:, i)));                                  %Find the minimum value in the frame
                maxVal = max(max(frames(:, :,i)));                                  %Find the maximum value in the frame
                slope = 1./(maxVal - minVal);                                       %Find the slope of the line that extends the range
                refinedFrames(:, :, i) = slope.*(frames(:, :, i) - minVal);         %Calculate the new frame using the slope and y-intercept
            end
        end
        
        function refinedFrames = preprocessFrames(frames, style, value)
            [~, ~, depth] = size(frames);
            refinedFrames = zeros(size(frames));
            for i = 1:depth
                switch style
                    case "sharpen"
                        refinedFrames(:, :, i) = imsharpen(frames(:, :, i), 'Amount', value);
                    case "soften"
                        refinedFrames(:, :, i) = imgaussfilt(frames(:, :, i), value);
                    case "none"
                        refinedFrames = frames;
                end
            end
        end
        
        function mask = removeOutliers(mask)
            %Get rid of ridiculously large and small objects in the mask and objects far from the region of interest
            [row, col] = size(mask);
            %Find the connected components in the image
            CC = bwconncomp(mask, 8);
            stats = regionprops(CC, 'Centroid');
            %Get rid of ridiculously small objects (smaller than 50 square pixels)
            objectSize = cellfun(@numel, CC.PixelIdxList);
            for h = 1:CC.NumObjects
                if objectSize(h) <= 1./5000*row*col
                    mask(CC.PixelIdxList{h}) = 0;
                end
            end
            %Get rid of ridiculously big objects (bigger than half the image size)
%             for h = 1:CC.NumObjects
%                 if objectSize(h) > (row.*col/2)
%                     mask(CC.PixelIdxList{h}) = 0;
%                 end
%             end
            %Get rid of objects far away from the center (objects that have a centroid
            %more than 200 pixels away from the center
            for j = 1:CC.NumObjects
                objectCenter = stats(j).Centroid;
                if sqrt( (objectCenter(1) - col./2).^2 + (objectCenter(2) - row./2).^2 ) > 200
                    mask(CC.PixelIdxList{j}) = 0;
                end
            end
        end
        
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
        
        function grayImg = colorMask(targetImage, oldData, graythresh, style, value, flip)
            %A function to create a mask for the bubble based on pixel intensity values
            
            %Preprocess the frame
            targetImage = bubbleDetection.preprocessFrames(targetImage, style, value);
            
            %Calculate the gray threshold for the image and binarize it based on that, Flip black and white, Get rid of any white pixels connected to the border, Fill any holes in the image
            if flip
                grayImg = imfill(bwmorph(bwmorph(bwmorph(imclearborder(imcomplement(imbinarize(targetImage, graythresh))), 'clean'), 'diag'), 'bridge'), 'holes');
            else
                grayImg = imfill(bwmorph(bwmorph(bwmorph(imclearborder(imbinarize(targetImage, graythresh)), 'clean'), 'diag'), 'bridge'), 'holes');
            end
            
            %Remove outlier objects from the image
            grayImg = bubbleDetection.removeOutliers(grayImg);
            
            %Refresh the connected components list
            CC = bwconncomp(grayImg, 8);
            
            %If there is still more than one object, attempt to isolate the most likley
            %object
            if CC.NumObjects > 1
                grayImg = bubbleDetection.isolateObject(grayImg, targetImage, oldData);
            end
            
            %Fill any holes
            grayImg = imfill(grayImg, 'holes');
        end
        
        function edgeImage = edgeMask(targetImage, oldData, edgethresh, style, value)
            %A function to create a binary mask of the bubble based on edge detection
            
            %Preprocess the image if needed
            targetImage = bubbleDetection.preprocessFrames(targetImage, style, value);
            
            %Create the initial binary mask
            edgeImage = imfill(imclearborder(imcomplement(imdilate(edge(targetImage, 'Sobel', edgethresh), [strel('line', 3, 90) strel('line', 3, 0)]))), 'holes');
            
            %Remove ridiculously large and small objects from the image
            edgeImage = bubbleDetection.removeOutliers(edgeImage);
            
            %Refresh the connected components list
            CC = bwconncomp(edgeImage, 8);
            
            %If there is still more than one object, attempt to isolate the the object
            if CC.NumObjects > 1
                edgeImage = bubbleDetection.isolateObject(edgeImage, targetImage, oldData);
            end
        end
        
        function outputMask = mixMasks(maskone, masktwo, value)
           
            if ~any(any(maskone))                                   % If maskone is empty, use masktwo
                outputMask = masktwo;
            elseif ~any(any(masktwo))                               % If masktwo is empty, use maskone
                outputMask = maskone;
            elseif any(any(maskone)) && any(any(masktwo))           % Mix the masks if neither are empty
                outputMask = imbinarize(maskone.*(100 - value) + masktwo.*value);
            end
            
        end
        
        function outputMask = runDetection(frames, gt, edgethresh, maskmix, iff, cstyle, cval, estyle, eval, figure, autocolor, autoedge, flip)
             % A function to isolate the bubble in each frame, returns an MxNxA logical array where M & N are the image size and A is the number of frames
            
            %% Program input and set up
            [row, col, depth] = size(frames);      %Get the size of the initial frame array
            outputMask = zeros(row, col, depth);        %Create the output frame array
            tic;
            oldData.Center = [col./2, row./2];
            oldData.Size = 0;
            
            %Create the progress bar
            wtBr = uiprogressdlg(figure, 'Title', 'Please wait', 'Message', 'Isolating...', 'Cancelable', 'on');
            
            %% Create mask for each frame
            for f = (1 + iff):depth
                wtBr.Message = "Isolating bubble in frame: " + num2str(f) + "/" + num2str(depth);
                if wtBr.CancelRequested
                    break;
                end
                
                %% Get the frame
                targetImage = frames(:, :, f);
                
                %% Create a mask based on color
                if autocolor 
                    gt = graythresh(targetImage);
                end
                grayImage = bubbleDetection.colorMask(targetImage, oldData, gt, cstyle, cval, flip);
                
                %% Create a mask based on edges
                if autoedge
                    [~, edgethresh] = edge(targetImage, 'Sobel');
                end
                edgeImage = bubbleDetection.edgeMask(targetImage, oldData, edgethresh, estyle, eval);
                
                %% Decide which mask/combination of masks to use
                finalImage = bubbleDetection.mixMasks(grayImage, edgeImage, maskmix);

                %Update the oldData values as long as the mask isn't empty
                if any(any(finalImage))
                    finalCC = bwconncomp(finalImage, 8);
                    oldData.Size = cellfun(@numel, finalCC.PixelIdxList);
                    finalStats = regionprops(finalImage, 'Centroid');
                    oldData.Center = finalStats.Centroid;
                end
                
                %Assign the final mask to the output array
                outputMask(:, :, f) = finalImage;
                
                %Update the waitbar
                wtBr.Value = f/depth;
            end
            %Close waitbar
            close(wtBr);
        end
        
        function [left, right] = separateViews(img, mask, views)
            
            %Calculate the number of objects in the mask
            CC = bwconncomp(mask);
            
            %If the number of objects in the mask matches the number of
            %views
            if CC.NumObjects == views
                stats = regionprops(CC, 'Centroid', 'PixelIdxList');        %Calculate the centroids of the objects
                centroid(1, :) = stats(1).Centroid;                         %Assign the centroid value
                centroid(2, :) = stats(2).Centroid;                         %Assign the centroid value
                
                %Assign the left most object in the mask to the left mask
                %and the right most object in the masks to the right mask
                if centroid(1, 1) < centroid(2, 1)
                    left = zeros(size(mask));
                    right = zeros(size(mask));
                    left(stats(1).PixelIdxList) = 1;
                    right(stats(2).PixelIdxList) = 1;
                elseif centroid(1, 1) > centroid(2, 1)
                    left = zeros(size(mask));
                    right = zeros(size(mask));
                    right(stats(1).PixelIdxList) = 1;
                    left(stats(2).PixelIdxList) = 1;
                end
            
            %If the number of objects in the mask is less than the number
            %of views (most likely overlap)
            elseif CC.NumObjects < views
                
                %Check if the mask is nonempty
                if any(any(mask))
                    
                    %Create a temporary image with just the bubbles
                    temp = zeros(size(img));    
                    temp(mask) = img(mask);
                    temp(~mask) = NaN;
                    
                    %Find overlapping regions (dark regions shared between
                    %the bubbles)
                    overlap = bwmorph(imclearborder(imcomplement(imbinarize(temp, graythresh(temp)))), 'clean');
                    
                    %If more than one overlapping region exists, find the
                    %biggest one
                    CCoverlap = bwconncomp(overlap, 8);
                    if CCoverlap.NumObjects > 1                        
                        %Tabulate the object sizes
                        sizes = cellfun(@numel, CCoverlap.PixelIdxList);
                        [~, biggest] = max(sizes);
                        for i = 1:CCoverlap.NumObjects
                            if i == biggest 
                                continue;
                            else
                                overlap(CCoverlap.PixelIdxList{i}) = 0;
                            end
                        end
                    end
                                        
                    %Subtract the overlapping regions from the image mask
                    mask(overlap) = 0;
                    
                    %Recompute the number of objects in the image mask
                    CC = bwconncomp(mask);
                    
                    if CC.NumObjects == views
                        %If the number of objects equals the number of
                        %views, split the mask (recusive function) add the
                        %overlap regions and return the final masks
                        
                        [leftSplit, rightSplit] = bubbleDetection.separateViews(img, mask, views);
                        left = leftSplit + overlap;
                        right = rightSplit + overlap;
                        
                    elseif CC.NumObjects > views
                        %If the number of objects is greater than the
                        %number of views return empty masks (we shouldn't
                        %get to this point
                        
                        left = zeros(size(mask));
                        right = zeros(size(mask));
                        
                    elseif CC.NumObjects < views
                        %If the number of objects is less than the number
                        %of views, the bubbles are most likely either
                        %overlapping or just barely touching 
                        
                        if any(any(overlap))
                            %If an overlap region exists, find the centroid
                            %and split the image according the the centroid
                            %of the overlapping region
                            
                            stats = regionprops(overlap, 'Centroid', 'Orientation');           %Calculate the centroid
                            center = round(stats.Centroid);                                             %Assign the centroid to a new variable (easier access)
                            
                            %Initialize the left and right split masks
                            leftSplit = zeros(size(mask));
                            rightSplit = zeros(size(mask));
                            
                            %Split the original mask into left and right
                            %halves
                            leftSplit(:, 1:center(1)) = mask(:, 1:center(1));
                            rightSplit(:, (center(1) + 1):end) = mask(:, (center(1)+1):end);
                            
                            %Add the overlapping region to both masks and
                            %assign to the output variables
                            left = leftSplit + overlap;
                            right = rightSplit + overlap;
                            
                        else 
                            %If an overlap region does not exist 
                            %create a new mask based on the Canny 
                            %filter for finer edge detection
                            tempMask = imfill(bwmorph(bwmorph(edge(img, 'Canny'), 'bridge'), 'diag'), 'holes');
                            tempMask = bubbleDetection.removeOutliers(tempMask);
                            
                            %Remove any objects that are not within the
                            %original mask (with some tolerance)
                            dilatedMask = imdilate(imdilate(mask, strel('line', 10, 0)), strel('line', 10, 90));
                            tempMask(~dilatedMask) = 0;
                            
                            %Find the number of connected objects in the
                            %new mask
                            tempCC = bwconncomp(tempMask);
                            
                            if tempCC.NumObjects == views
                                %If the number of objects in the new mask is
                                %the same as the number of views,
                                %recursively call this function to separate
                                %the views
                                
                                [left, right] = bubbleDetection.separateViews(img, tempMask, 2);
                                
                            elseif tempCC.NumObjects < views
                                %If the number of objects in the new mask
                                %is less than the number of views, split
                                %the mask at its thinnest point (as long as
                                %the number of objects is one)
                                
                                if tempCC.NumObjects == 1
                                    
                                    boundaries = cell2mat(bwboundaries(tempMask));      %Get the matrix coordinates of the points on the perimeter
                                    xPoints = boundaries(:, 2);                         %Extract the x coordinates
                                    yPoints = boundaries(:, 1);                         %Extract the y coordinates
                                    
                                    dist = zeros(size(xPoints));                        %Preallocate the vector
                                    for i = 1:length(xPoints)
                                        targetVal = xPoints(i);                         %Index the current element in the xPoints vector
                                        
                                        yVals = yPoints(xPoints == targetVal);          %Find the values of the y-coordinates that match with that x-value
                                        
                                        dist(i) = abs(max(yVals) - min(yVals));         %Find the difference in the y-values and assign to the distance vector
                                    end
                                    
                                    [~, minIdx] = min(dist);                            %Find the indices of the points with the smallest y-value difference
                                    xMin = xPoints(minIdx);                             %Find the x points corresponding to the points with the smallest y-value difference
                                    
                                    if length(xMin) > 2
                                        %If the number of corresponding x
                                        %points is greater than two return
                                        %empty masks (for now)
                                        left = zeros(size(mask));
                                        right = zeros(size(mask));
                                        
                                    elseif length(xMin) == 2
                                        %If the number of corresponding x
                                        %points is equal to two, make sure
                                        %the x-points are the same
                                        
                                        if xMin(1) == xMin(2)
                                            %If the points are the same,
                                            %split the original mask at
                                            %this point
                                            
                                            left = zeros(size(mask));
                                            right = zeros(size(mask));
                                            left(:, 1:xMin(1)) = mask(:, 1:xMin(1));
                                            right(:, (xMin(1) + 1):end) = mask(:, (xMin(1)+1):end);
                                            
                                        else
                                            %If the points don't have the
                                            %same value return empty masks
                                            %(for now)
                                            
                                            imshow(labeloverlay(img, tempMask));
                                            left = zeros(size(mask));
                                            right = zeros(size(mask));
                                        end
                                        
                                    else
                                        
                                        left = zeros(size(mask));
                                        right = zeros(size(mask));
                                        
                                    end
                                    
                                else
                                    %Return empty masks if the number of
                                    %objects is greater than one but less
                                    %than the number of views
                                    
                                    imshow(labeloverlay(img, tempMask));
                                    left = zeros(size(mask));
                                    right = zeros(size(mask));
                                    
                                end

                                
                            elseif tempCC.NumObjects > views
                                %If the number of objects in the new mask
                                %is greater than the number of views,
                                %attempt to isolate the correct objects and
                                %then recursively call this function to
                                %separate the views as long as the two
                                %masks are not identical (so an infinite
                                %loop doesn't happen). If the two masks are
                                %identical... idk

                                tempCCC = bwconncomp(tempMask);                                             %Find the number of new connected components
                                
                                if tempCCC.NumObjects > 1
                                    %If the number of new connected
                                    %components is greater than the number
                                    %of views attempt to whittle down the
                                    %number of objects
                                    tempMask = bubbleDetection.removeOutliers(tempMask);
                                    tempMask = bubbleDetection.whittleObjects(tempMask, img);       
                                end
                                
                                if ~isequal(tempMask, mask)
                                    %As long as the old mask and new mask
                                    %aren't apprioximately equal, recursively call the
                                    %function to separate the views
                                    
                                    tempCCCC = bwconncomp(tempMask);
                                    if (tempCCCC.NumObjects == CC.NumObjects) && (tempCCCC.NumObjects < views)
                                        tempSize = numel(tempCCCC.PixelIdxList{1});         %Get the size of the object in the temp mask
                                        maskSize = numel(CC.PixelIdxList{1});               %Get the size of the object in the orig mask
                                        
                                        if abs(1 - tempSize/maskSize) < 0.05
                                            %If the sizes are within ten
                                            %percent of each other (~ish)
                                            %then split the mask down the
                                            %middle
                                            
                                            if tempCCCC.NumObjects == 1
                                                
                                                boundaries = cell2mat(bwboundaries(tempMask));      %Get the matrix coordinates of the points on the perimeter
                                                xPoints = boundaries(:, 2);                         %Extract the x coordinates
                                                yPoints = boundaries(:, 1);                         %Extract the y coordinates
                                                
                                                dist = zeros(size(xPoints));                        %Preallocate the vector
                                                for i = 1:length(xPoints)
                                                    targetVal = xPoints(i);                         %Index the current element in the xPoints vector
                                                    
                                                    yVals = yPoints(xPoints == targetVal);          %Find the values of the y-coordinates that match with that x-value
                                                    
                                                    dist(i) = abs(max(yVals) - min(yVals));         %Find the difference in the y-values and assign to the distance vector
                                                end
                                                
                                                [~, minIdx] = min(dist);                            %Find the indices of the points with the smallest y-value difference
                                                xMin = xPoints(minIdx);                             %Find the x points corresponding to the points with the smallest y-value difference
                                                
                                                if length(xMin) > 2
                                                    %If the number of corresponding x
                                                    %points is greater than two return
                                                    %empty masks (for now)
                                                    left = zeros(size(mask));
                                                    right = zeros(size(mask));
                                                    
                                                elseif length(xMin) == 2
                                                    %If the number of corresponding x
                                                    %points is equal to two, make sure
                                                    %the x-points are the same
                                                    
                                                    if xMin(1) == xMin(2)
                                                        %If the points are the same,
                                                        %split the original mask at
                                                        %this point
                                                        
                                                        left = zeros(size(mask));
                                                        right = zeros(size(mask));
                                                        left(:, 1:xMin(1)) = mask(:, 1:xMin(1));
                                                        right(:, (xMin(1) + 1):end) = mask(:, (xMin(1)+1):end);
                                                        
                                                    else
                                                        %If the points don't have the
                                                        %same value return empty masks
                                                        %(for now)
                                                        
                                                        left = zeros(size(mask));
                                                        right = zeros(size(mask));
                                                    end
                                                    
                                                elseif length(xMin) == 1
                                                    %If the number of
                                                    %corresponding x points
                                                    %is one split along
                                                    %centroid
                                                    
                                                    tempStats = regionprops(tempMask, 'Centroid');
                                                    center = round(tempStats.Centroid);
                                                    [~, width] = size(tempMask);
                                                    
                                                    newdist = dist;
                                                    newdist(xPoints > (center(1) + 0.1*width)) = NaN;
                                                    newdist(xPoints < (center(1) - 0.1*width)) = NaN;
                                                    
                                                    [~, minIdx] = min(newdist);
                                                    xMin = xPoints(minIdx);
                                                    
                                                    
                                                    left = zeros(size(mask));
                                                    right = zeros(size(mask));
                                                    
                                                    if length(xMin) > 1
                                                        left(:, 1:xMin(1)) = tempMask(:, 1:xMin(1));
                                                        right(:, (xMin(1) + 1):end) = mask(:, (xMin(1) + 1):end);
                                                    elseif length(xMin) == 1
                                                        left(:, 1:xMin) = tempMask(:, 1:xMin);
                                                        right(:, (xMin + 1):end) = mask(:, (xMin + 1):end);
                                                    end

                                                                                                        
                                                end
                                                
                                            else
                                                %Return empty masks if the number of
                                                %objects is greater than one but less
                                                %than the number of views
                                                
                                                left = zeros(size(mask));
                                                right = zeros(size(mask));
                                                
                                            end
                                            
                                        else
                                            
                                            left = zeros(size(mask));
                                            right = zeros(size(mask));
                                            
                                        end
                                        
                                    elseif tempCCCC.NumObjects > CC.NumObjects
                                        
                                        [left, right] = bubbleDetection.separateViews(img, tempMask, views);
                                        
                                    else
                                        
                                        left = zeros(size(mask));
                                        right = zeros(size(mask));
                                        
                                    end
                                else
                                    
                                    left = zeros(size(mask));
                                    right = zeros(size(mask));
                                    pause(0.5); 
                                    
                                end
                                
                            else
                                
                                left = zeros(size(mask));
                                right = zeros(size(mask));
                                
                            end
                                                        
                        end
                        
                    else
                        
                        left = zeros(size(mask));
                        right = zeros(size(mask));
                        
                    end
                    
                else
                    %If the mask is empty return empty masks                    
                    left = zeros(size(mask));
                    right = zeros(size(mask));

                end
                
            elseif CC.NumObjects > views
                %Return empty masks if the number of objects is greater
                %than the number of views (should not get to this point)
                
                left = zeros(size(mask));
                right = zeros(size(mask));
                
            end
        end
        
        function grayImg = multiColor(img, gt, cstyle, cval, flip, views)
            
            %Preprocess
            img = bubbleDetection.preprocessFrames(img, cstyle, cval);                      
            
            %Create the initial binary mask
            if flip
                grayImg = imfill(bwmorph(bwmorph(bwmorph(imclearborder(imcomplement(imbinarize(img, gt))), 'clean'), 'diag'), 'bridge'), 'holes');
                % Binarize, flip black and white, remove border connected
                % pixels, remove lone pixles, remove diagonal pixels,
                % bridge small gaps, fill holes
            else
                grayImg = imfill(bwmorph(bwmorph(bwmorph(imclearborder(imbinarize(img, gt)), 'clean'), 'diag'), 'bridge'), 'holes');
                % Binarize, remove border connected
                % pixels, remove lone pixles, remove diagonal pixels,
                % bridge small gaps, fill holes
            end
            
            %Remove very small and very large objects
            grayImg = bubbleDetection.removeOutliers(grayImg);
            
            %Refresh the number of objects in the image
            CC = bwconncomp(grayImg, 8);
            
            %If there are more objects than the number of views, reduce the
            %number of objects to the number of views based on various
            %critera
            if CC.NumObjects > views
                grayImg = bubbleDetection.whittleObjects(grayImg, img);
            end
            
            grayImg = imfill(grayImg, 'holes');                                 %Fill any holes
            
        end
        
        function edgeImg = multiEdge(img, et, estyle, eval, views)
            
            %Preprocess the frame
            img = bubbleDetection.preprocessFrames(img, estyle, eval);
            
            %Create the initial mask based on edges
            edgeImg = imclearborder(imfill(bwmorph(edge(img, 'Sobel', et), 'bridge'), 'holes'));
                %Create the edge mask with a sobel filter and specified
                %threshold, bridge any small gaps, fill any holes, remove
                %border connnected pixels
            
            %Remove ridiculously large and small objects from the image
            edgeImg = bubbleDetection.removeOutliers(edgeImg);
            
            %Refresh the connected components list
            CC = bwconncomp(edgeImg, 8);
            
            %If there is still more than one object, reduce the number of
            %objects to the number of views based on various criteria
            if CC.NumObjects > views
                edgeImg = bubbleDetection.whittleObjects(edgeImg, img);
            end
            
        end
        
        function [idx1, idx2] = compareVector(vec, targ)
            %Constants
            tol = 0.2;
            
            %If there is only one element in the vector return that element
            if length(vec) == 1
                idx1 = 0;
                idx2 = 1;
                return;
            end
            
            %Find the two elements that are numerically the closest
            %together
            A = abs(repmat(vec, length(vec), 1) - repmat(vec', 1, length(vec)));    %Create the difference array
            A(A == 0) = NaN;                                                        %Set elements = 0 to NaN
            B = min(A);                                                             %Find the minimum in each column
            C = find(B == min(B));                                                  %Find indices of the two elements that match the minimum in B
            idx1temp = C(1);                                                        %Extract the first index
            idx2temp = C(2);                                                        %Extract the second index
            
            %Check that they meet the tolerance
            tolerance = abs(1 - vec(idx1temp)./vec(idx2temp)); 
            
            if tolerance > tol
                %If the two values do not meet the tolerance, find the one
                %closest to the target value
                if isnumeric(targ)
                    [~, idx2] = min(abs(vec) - targ);
                    idx1 = 0;
                elseif targ == 'max'
                    [~, idx2] = max(vec);
                    idx1 = 0;
                elseif targ == 'min'
                    [~, idx2] = min(vec);
                    idx1 = 0;
                end
            elseif tolerance <= tol
                if idx1temp < idx2temp
                    idx1 = idx1temp;
                    idx2 = idx2temp;
                elseif idx2temp < idx1temp
                    idx1 = idx2temp;
                    idx2 = idx2temp;
                end
            end
            
           
        end
        
        function outmask = whittleObjects(mask, targetImage)
            
            % A function to isolate one object in a binary mask most likely considered to be the bubble based on various characteristics
            CC = bwconncomp(mask, 8);
            stats = regionprops(CC, 'Circularity', 'Centroid', 'PixelIdxList');
            
            [~, col] = size(mask);
                       
            %Find the two objects closest to each other in size
            sizes = zeros(1, CC.NumObjects);
            for i = 1:CC.NumObjects
                sizes(i) = numel(CC.PixelIdxList{i});
            end
            [size1, size2] = bubbleDetection.compareVector(sizes, 'max');
            
            %Find the two objects that have a centroid on a similar y level
            heights = zeros(1, CC.NumObjects);
            for i = 1:CC.NumObjects
                center = stats(i).Centroid;
                heights(i) = center(2);
            end
            [height1, height2] = bubbleDetection.compareVector(heights, col./2);
            
            %Find the two objects with the lowest pixel average
            averages = zeros(1, CC.NumObjects);
            for i = 1:CC.NumObjects
                averages(i) = mean(targetImage(CC.PixelIdxList{i}), 'all');
            end
            [avg1, avg2] = bubbleDetection.compareVector(averages, 'min');
            
            %Calculate the significance values for all objects
            significance = (heights.*averages)./sizes;
            [sig1, sig2] = bubbleDetection.compareVector(significance, 'min');
            
            %Decide which object to keep
            if isequaln(size1, height1, avg1, sig1)
                objIdx = size1;                             %Ideal case
            elseif isequaln(size1, avg1, height1)
                objIdx = size1;                             %If the significance value is misleading
            elseif isequaln(height1, avg1, sig1)
                objIdx = height1;                           %If the object size is misleading
            elseif isequaln(height1, size1, sig1)
                objIdx = height1;                           %If the lowest average is misleading
            elseif isequaln(size1, avg1, sig1)
                objIdx = size1;                             %If the closest object is misleading
            else 
                objIdx = 0;
            end
            
            if isequaln(size2, height2, avg2, sig2)
                objIdx2 = size2;                             %Ideal case
            elseif isequaln(size2, avg2, height2)
                objIdx2 = size2;                             %If the significance value is misleading
            elseif isequaln(height2, avg2, sig2)
                objIdx2 = height2;                           %If the object size is misleading
            elseif isequaln(height2, size2, sig2)
                objIdx2 = height2;                           %If the lowest average is misleading
            elseif isequaln(size2, avg2, sig2)
                objIdx2 = size2;                             %If the closest object is misleading
            else
                objIdx2 = 0;
            end
            
            %Get rid of the other objects
            for j = 1:CC.NumObjects
                if j == objIdx
                    continue;     
                elseif j == objIdx2
                    continue;
                else
                    mask(CC.PixelIdxList{j}) = 0;
                end
            end
                        
            outmask = mask;
        end

        function outputMask = multiDetect(frames, gt, edgethresh, maskmix, iff, cstyle, cval, estyle, eval, figure, autocolor, autoedge, flip, views, ignoreFrames, originalFrames)
            
            [row, col, depth] = size(frames);
            outputMask = zeros(row, col, depth, views);
            
            wtBr = uiprogressdlg(figure, 'Title', 'Please wait', 'Message', 'Isolating...', 'Cancelable', 'on');
                       
            for f = (1 + iff):depth
                if ~isempty(find(ignoreFrames == f, 1))
                    continue;
                else
                    wtBr.Message = "Isolating bubbles in frame: " + num2str(f) + "/" + num2str(depth);
                    if wtBr.CancelRequested
                        break;
                    end
                    
                    %% Get the frame
                    targetImage = frames(:, :, f);
                    
                    if ~flip
                        originalImage = originalFrames(:, :, f);
                    else
                        originalImage = targetImage;
                    end
                    
                    %% Create a mask based on color
                    if autocolor
                        gt = graythresh(targetImage);
                    end
                    grayImage = bubbleDetection.multiColor(targetImage, gt, cstyle, cval, flip, views);

                    [leftGray, rightGray] = bubbleDetection.separateViews(originalImage, grayImage, views);
                    
                    %% Create a mask based on edges
                    if autoedge
                        [~, edgethresh] = edge(targetImage, 'Sobel');
                    end
                    edgeImage = bubbleDetection.multiEdge(targetImage, edgethresh, estyle, eval, views);
                    [leftEdge, rightEdge] = bubbleDetection.separateViews(originalImage, edgeImage, views);
                    
                    %% Decide which mask/combination of masks to use
                    leftFinal = bubbleDetection.mixMasks(leftGray, leftEdge, maskmix);
                    rightFinal = bubbleDetection.mixMasks(rightGray, rightEdge, maskmix);
                    
                    %Assign the final mask to the output array
                    outputMask(:, :, f, 1) = leftFinal;
                    outputMask(:, :, f, 2) = rightFinal;
                    
                    %Update the waitbar
                    wtBr.Value = f/depth;
                end
            end
            %Close waitbar
            close(wtBr);
            
        end
                
    end
end
