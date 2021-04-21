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
            refinedFrames = zeros(size(frames));
            [~, ~, depth] = size(frames);
            for i = 1:depth
                minVal = min(min(frames(:,:, i)));
                maxVal = max(max(frames(:, :,i)));
                slope = 1./(maxVal - minVal);
                refinedFrames(:, :, i) = slope.*(frames(:, :, i) - minVal);
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
            targetImage = bubbleDetection.preprocessFrames(targetImage, style, value);
            %Calculate the gray threshold for the image and binarize it based on that, Flip black and white, Get rid of any white pixels connected to the border, Fill any holes in the image
            if flip
                grayImg = imfill(bwmorph(bwmorph(bwmorph(imclearborder(imcomplement(imbinarize(targetImage, graythresh))), 'clean'), 'diag'), 'bridge'), 'holes');
            else
                grayImg = imfill(bwmorph(bwmorph(bwmorph(imclearborder(imbinarize(targetImage, graythresh)), 'clean'), 'diag'), 'bridge'), 'holes');
            end
            %Remove ridiculously small and large objects from the image
            grayImg = bubbleDetection.removeOutliers(grayImg);
            %Refresh the connected components list
            CC = bwconncomp(grayImg, 8);
            %If there is still more than one object, attempt to isolate the most likley
            %object
            if CC.NumObjects > 1
                grayImg = bubbleDetection.isolateObject(grayImg, targetImage, oldData);
            end
            grayImg = imfill(grayImg, 'holes');
        end
        
        function edgeImage = edgeMask(targetImage, oldData, edgethresh, style, value)
            %A function to create a binary mask of the bubble based on edge detection
            targetImage = bubbleDetection.preprocessFrames(targetImage, style, value);
            
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
                        if any(any(overlap))
                            %If an overlap region exists, find the centroid
                            %and split the image according the the centroid
                            %of the overlapping region
                            stats = regionprops(overlap, 'Centroid');
                            try 
                                center = round(stats.Centroid);
                            catch ME
                                pause(0.5);
                            end
                            
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
                            %Find the edges of the bubble
                            tempMask = edge(img, 'Canny');
                            dilatedMask = imdilate(imdilate(mask, strel('line', 10, 0)), strel('line', 10, 90));
                            tempMask(~dilatedMask) = 0;
                            tempMask = imfill(tempMask, 'holes');
                            
                            tempCC = bwconncomp(tempMask);
                            if tempCC.NumObjects == views
                                [left, right] = bubbleDetection.separateViews(img, tempMask, 2);
                            elseif tempCC.NumObjects < views
                                left = zeros(size(mask));
                                right = zeros(size(mask));
                                pause(0.5);
                            elseif tempCC.NumObjects > views
                                left = zeros(size(mask));
                                right = zeros(size(mask));
                                pause(0.5);
                            end
                        end
                    end
                    
                else
                    %If the mask is empty teturn empty masks
                    left = zeros(size(mask));
                    right = zeros(size(mask));
                end
            elseif CC.NumObjects > views
                %Return empty masks
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
            else
                grayImg = imfill(bwmorph(bwmorph(bwmorph(imclearborder(imbinarize(img, gt)), 'clean'), 'diag'), 'bridge'), 'holes');
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
            grayImg = imfill(grayImg, 'holes');
            
        end
        
        function edgeImg = multiEdge(img, et, estyle, eval, views)
            
            %Preprocess the frame
            img = bubbleDetection.preprocessFrames(img, estyle, eval);
            
            %Create the initial mask based on edges
            edgeImg = imclearborder(imfill(bwmorph(edge(img, 'Sobel', et), 'bridge'), 'holes'));
            
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
            
            %Find the two elements that are numerically the closest
            %together
            A = abs(repmat(vec, length(vec), 1) - repmat(vec', 1, length(vec)));
            A(A == 0) = NaN;
            B = min(A);
            C = find(B == min(B));
            idx1temp = C(1);
            idx2temp = C(2);
            
            %Check that they meet the tolerance
            tolerance = abs(1 - vec(idx1temp)./vec(idx2temp)); 
            if tolerance > tol
                %If the two values do not meet the tolerance, find the one
                %closest to the target value
                if isnumeric(targ)
                    [~, idx2] = min(abs(A) - targ);
                    idx1 = 0;
                elseif targ == 'max'
                    [~, idx2] = max(A);
                    idx1 = 0;
                elseif targ == 'min'
                    [~, idx2] = min(A);
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
            [val1, avg1temp] = min(averages);
            averages(averages == val1) = NaN;
            [~, avg2temp] = min(averages);
            
            %Make sure the object with the lower index is first
            if avg1temp < avg2temp
                avg1 = avg1temp;
                avg2 = avg2temp;
            elseif avg2temp < avg1temp
                avg1 = avg2temp;
                avg2 = avg1temp;
            else 
                avg1 = 0;
                avg2 = 0;
            end
            
            %Calculate the significance values for all objects
            significance = (heights.*averages)./sizes;
            [val1, sig1temp] = min(significance);
            significance(significance == val1) = NaN;
            [~, sig2temp] = min(significance);
            
            %Make sure the object with the lower index is first
            if sig1temp < sig2temp
                sig1 = sig1temp;
                sig2 = sig2temp;
            elseif sig2temp < sig1temp
                sig1 = sig2temp;
                sig2 = sig1temp;
            else 
                sig1 = 0;
                sig2 = 0;
            end
            
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
