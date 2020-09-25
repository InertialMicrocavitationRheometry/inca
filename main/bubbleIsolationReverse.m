function outputMask = bubbleIsolationReverse(app, inputFrames)
% A function to isolate the bubble in each frame, returns an MxNxA logical array where M & N are the image size and A is the number of frames
fileID = generateDiaryFile("BubbleReverseDetectionLog");

%% Program input and set up
[row, col, depth] = size(inputFrames);      %Get the size of the initial frame array
outputMask = zeros(row, col, depth);        %Create the output frame array
tic;
oldData.Center = [col./2, row./2];
oldData.Size = 0;
%Create the progress bar
wtBr = uiprogressdlg(app.UIFigure, 'Title', 'Please wait', 'Message', 'Isolating...', 'Cancelable', 'on');

%% Create mask for each frame
for f = depth:-1:(1 + app.IgnoreFirstFrameCheckBox.Value)

    fprintf(fileID, '%s', '------------------------------');
    fprintf(fileID, '\n');
    fprintf(fileID, '%s', "Generating mask for frame " + num2str(f));
    fprintf(fileID, '\n');
    if wtBr.CancelRequested
        break;
    end
    
    %% Get the frame
    targetImage = inputFrames(:, :, f);
    
    %% Create a mask based on color
    fprintf(fileID, '%s', "Generating gray mask");
    fprintf(fileID, '\n');
    grayImage = colorMask(targetImage, oldData, fileID);
    if any(any(grayImage))
        grayCC = bwconncomp(grayImage, 8);
        grayStats = regionprops(grayCC, 'Centroid', 'Circularity');
        grayCenter = grayStats.Centroid;
        fprintf(fileID, '%s', "Gray mask generated");
        fprintf(fileID, '\n');
    else
        fprintf(fileID, '%s', "No gray mask generated for frame " + num2str(f));
        fprintf(fileID, '\n');
    end
    
    %% Create a mask based on edges
    fprintf(fileID, '%s', "Generating edge mask");
    fprintf(fileID, '\n');
    edgeImage = edgeMask(targetImage, oldData, fileID);
    if any(any(edgeImage))
        edgeCC = bwconncomp(edgeImage, 8);
        edgeStats = regionprops(edgeCC, 'Centroid', 'Circularity');
        edgeCenter = edgeStats.Centroid;
        fprintf(fileID, '%s', "Edge mask generated");
        fprintf(fileID, '\n');
    else
        fprintf(fileID, '%s', "No edge mask generated for frame " + num2str(f));
        fprintf(fileID, '\n');
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
        if abs( cellfun(@numel, grayCC.PixelIdxList) - cellfun(@numel, edgeCC.PixelIdxList) ) < 75 && sqrt((grayCenter(1) - edgeCenter(1)).^2 + (grayCenter(2) - edgeCenter(2)).^2) < 10
            finalImage = grayImage + edgeImage;
        %If the edge mask is bigger than the gray mask then if there is no
        %overlap in the regions, add the masks together and isolate the
        %most likely object. Otherwise, the final masks is where both are
        %present
        elseif cellfun(@numel, grayCC.PixelIdxList) < cellfun(@numel, edgeCC.PixelIdxList) && sqrt((grayCenter(1) - edgeCenter(1)).^2 + (grayCenter(2) - edgeCenter(2)).^2) < 10
            if ~any(any(grayImage & edgeImage))
                finalImage = isolateObject(logical(grayImage + edgeImage), targetImage, fileID);
            else
                finalImage = grayImage & edgeImage;
            end 
        %If the gray mask is bigger than the edge mask, then if the
        %circularities are wildly different, use mask logic to figure out
        %which one to use, otherwise if the ciruclarities are similar then
        %use the combination of the two masks.
        elseif cellfun(@numel, grayCC.PixelIdxList) > cellfun(@numel, edgeCC.PixelIdxList) && sqrt((grayCenter(1) - edgeCenter(1)).^2 + (grayCenter(2) - edgeCenter(2)).^2) < 10
            if abs ( grayStats.Circularity - edgeStats.Circularity ) > 0.15 && grayStats.Circularity > edgeStats.Circularity
                finalImage = maskLogic(grayImage, edgeImage, targetImage, oldData, fileID);
            elseif abs( grayStats.Circularity - edgeStats.Circularity) > 0.15 && grayStats.Circularity < edgeStats.Circularity
                finalImage = maskLogic(edgeImage, grayImage, targetImage, oldData, fileID);
            elseif abs ( grayStats.Circularity - edgeStats.Circularity ) <= 0.15
                finalImage = grayImage + edgeImage;
            end
        %If both masks are close in size but not close in location, use the
        %one with the mask that is closer to the center
        elseif abs( cellfun(@numel, grayCC.PixelIdxList) - cellfun(@numel, edgeCC.PixelIdxList) ) < 75 && sqrt((grayCenter(1) - edgeCenter(1)).^2 + (grayCenter(2) - edgeCenter(2)).^2) > 10
            if sqrt( (grayCenter(1) - col./2).^2 + (grayCenter(2) - row./2).^2 ) < sqrt( (edgeCenter(1) - col./2).^2 + (edgeCenter(2) - row./2).^2 )
                finalImage = grayImage;
            else
                finalImage = edgeImage;
            end
        %If all else fails, use the most circular mask
        else
            if abs( 1 - edgeStats.Circularity ) < abs( 1 - grayStats.Circularity )
                finalImage = edgeImage;
            else
                finalImage = grayImage;
            end
        end
    end
    
    %% Fault check the final image before assignment
    finalCC = bwconncomp(finalImage, 8);
    
    %If there is more than one object, attempt to isolate the correct object
    if finalCC.NumObjects > 1
        outputMask(:, :, f) = logical(isolateObject(finalImage, targetImage), oldData, fileID);
    else
        outputMask(:, :, f) = logical(finalImage);
    end
    fprintf(fileID, '%s', "Final mask assigned for frame " + num2str(f));
    fprintf(fileID, '\n');
    
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
fclose(fileID);
end

function grayImg = colorMask(targetImage, oldData, fileID)
%A function to create a mask for the bubble based on pixel intensity values

%Calculate the gray threshold for the image and binarize it based on that, Flip black and white, Get rid of any white pixels connected to the border, Fill any holes in the image
grayImg = imfill(bwmorph(bwmorph(bwmorph(imclearborder(imcomplement(imbinarize(targetImage, graythresh(targetImage)))), 'clean'), 'diag'), 'bridge'), 'holes');
%Remove ridiculously small and large objects from the image
grayImg = removeOutliers(grayImg);
%Refresh the connected components list
CC = bwconncomp(grayImg, 8);
%If there is still more than one object, attempt to isolate the most likley
%object
fprintf(fileID, '%s', "Number of objects before isolation: " + num2str(CC.NumObjects));
fprintf(fileID, '\n');
if CC.NumObjects > 1
    grayImg = isolateObject(grayImg, targetImage, oldData, fileID);
end
grayImg = imfill(grayImg, 'holes');
end

function edgeImage = edgeMask(targetImage, oldData, fileID)
%A function to create a binary mask of the bubble based on edge detection
[~, threshold] = edge(targetImage, 'Sobel');
edgeImage = imfill(imclearborder(imcomplement(imdilate(edge(targetImage, 'Sobel', threshold*0.01), [strel('line', 3, 90) strel('line', 3, 0)]))), 'holes');
%Remove ridiculously large and small objects from the image
edgeImage = removeOutliers(edgeImage);
%Refresh the connected components list
CC = bwconncomp(edgeImage, 8);
%If there is still more than one object, attempt to isolate the the object
fprintf(fileID, '%s', "Number of objects before isolation: " + num2str(CC.NumObjects));
fprintf(fileID, '\n');
if CC.NumObjects > 1
    edgeImage = isolateObject(edgeImage, targetImage, oldData, fileID);
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

function mask = isolateObject(mask, targetImage, oldData, fileID)

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
fprintf(fileID, '%s', "Size index: " + num2str(maxSize));
fprintf(fileID, '\n');

%Find the obejct closest to the center of the frame, but not exactly in the center
distances = zeros(1, CC.NumObjects);
for i = 1:CC.NumObjects
    center = stats.Centroid;
    oldCenter = oldData.Center;
    distances(i) = sqrt((center(1) - oldCenter(1)).^2 + (center(2) - oldCenter(2)).^2);
end
[~, minDist] = min(distances(distances ~= 0));
fprintf(fileID, '%s', "Closest object index: " + num2str(minDist));
fprintf(fileID, '\n');

%Find the object with the lowest pixel average
averages = zeros(1, CC.NumObjects);
for i = 1:CC.NumObjects
    averages(i) = mean(targetImage(CC.PixelIdxList{i}), 'all');
end
averages(averages == 0) = 100;
[~, lowestAvg] = min(averages);
fprintf(fileID, '%s', "Lowest pixel average object index: " + num2str(lowestAvg));
fprintf(fileID, '\n');

%Calculate the significance value for each object
significance = distances./sizes.*averages;
[~, minSig] = min(significance);
fprintf(fileID, '%s', "Most significant object index: " + num2str(minSig));
fprintf(fileID, '\n');
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
    fprintf(fileID, '%s', "Resorting to fallback: Object Circularity");
    fprintf(fileID, '\n');
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
fprintf(fileID, '%s', "Final object index: " + num2str(objIdx));
fprintf(fileID, '\n');

%Get rid of the other objects
for j = 1:CC.NumObjects
    if j == objIdx
        continue;
    else
        mask(CC.PixelIdxList{j}) = 0;
    end
end
end

function finalImage = maskLogic(higherCircularityMask, lowerCircularityMask, targetImage, oldData, fileID)
hCMStats = regionprops(higherCircularityMask, 'Circularity');
finalStatsEither = regionprops(logical(higherCircularityMask + lowerCircularityMask), 'Circularity');
finalCCEither = bwconncomp(logical(higherCircularityMask + lowerCircularityMask), 8);
finalStatsBoth = regionprops(logical(higherCircularityMask & lowerCircularityMask), 'Circularity');
finalCCBoth = bwconncomp(logical(higherCircularityMask & lowerCircularityMask), 8);
if finalCCEither.NumObjects > 1
    finalStatsEither = regionprops(isolateObject(logical(higherCircularityMask + lowerCircularityMask), targetImage, oldData, fileID), 'Circularity');
end
if finalCCBoth.NumObjects == 1
    finalImage = isolateObject(logical(higherCircularityMask + lowerCircularityMask), targetImage, oldData, fileID);
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
