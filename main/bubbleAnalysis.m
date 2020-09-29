classdef bubbleAnalysis
    methods (Static)
        %Pre Process the frames before analyzing them
        function returnFrames = preprocessFrames(app, inputFrames)
            
            fileID = logging.generateDiaryFile("FramePreProcessingLog");
            
            [~, ~, numImages] = size(inputFrames);
            returnFrames = zeros(size(inputFrames));
            
            % fprintf(fileID, '%s', "Beginning Frame Preprocessing");
            % fprintf(fileID, '\n');
            % fprintf(fileID, '%s', "User input selection: ");
            % fprintf(fileID, '\n');
            % fprintf(fileID, '%s', "Sharpen frames before detection: " + num2str(app.SharpenButton.Value));
            % fprintf(fileID, '\n');
            % fprintf(fileID, '%s', "Soften frames before detection: " + num2str(app.SoftenButton.Value));
            % fprintf(fileID, '\n');
            % fprintf(fileID, '%s', "Filter strength: " + num2str(app.FilterStrengthSpinner.Value));
            % fprintf(fileID, '\n');
            
            if app.SharpenButton.Value
                for i = 1:numImages
                    %         fprintf(fileID, '%s', "Sharpening frame: " + num2str(i));
                    %         fprintf(fileID, '\n');
                    returnFrames(:, :, i) = imsharpen(inputFrames(:, :, i),'Amount', app.FilterStrengthSpinner.Value);
                    %         fprintf(fileID, '%s', "Complete");
                    %         fprintf(fileID, '\n');
                end
            else
                for i = 1:numImages
                    %         fprintf(fileID, '%s', "Softening frame: " + num2str(i));
                    %         fprintf(fileID, '\n');
                    returnFrames(:, :, i) = imgaussfilt(inputFrames(:, :, i), app.FilterStrengthSpinner.Value);
                    %         fprintf(fileID, '%s', "Complete");
                    %         fprintf(fileID, '\n');
                end
            end
            
            % fclose(fileID);
            
        end
        
        % Generates a mask for the given frame, going forward in time
        function outputMask = maskGenForward(app, inputFrames)
            % A function to isolate the bubble in each frame, returns an MxNxA logical array where M & N are the image size and A is the number of frames
            fileID = logging.generateDiaryFile("BubbleDetectionLog");
            
            %% Program input and set up
            [row, col, depth] = size(inputFrames);      %Get the size of the initial frame array
            outputMask = zeros(row, col, depth);        %Create the output frame array
            tic;
            oldData.Center = [col./2, row./2];
            oldData.Size = 0;
            %Create the progress bar
            wtBr = uiprogressdlg(app.UIFigure, 'Title', 'Please wait', 'Message', 'Isolating...', 'Cancelable', 'on');
            
            %% Create mask for each frame
            for f = (1 + app.IgnoreFirstFrameCheckBox.Value):depth
                wtBr.Message = "Isolating bubble in frame " + num2str(f) + "/" + num2str(depth);
                %     fprintf(fileID, '%s', '------------------------------');
                %     fprintf(fileID, '\n');
                %     fprintf(fileID, '%s', "Generating mask for frame " + num2str(f));
                %     fprintf(fileID, '\n');
                if wtBr.CancelRequested
                    break;
                end
                
                %% Get the frame
                targetImage = inputFrames(:, :, f);
                
                %% Create a mask based on color
                %     fprintf(fileID, '%s', "Generating gray mask");
                %     fprintf(fileID, '\n');
                grayImage = bubbleAnalysis.colorMask(targetImage, oldData, fileID);
                if any(any(grayImage))
                    grayCC = bwconncomp(grayImage, 8);
                    grayStats = regionprops(grayCC, 'Centroid', 'Circularity');
                    grayCenter = grayStats.Centroid;
                    %         fprintf(fileID, '%s', "Gray mask generated");
                    %         fprintf(fileID, '\n');
                else
                    %         fprintf(fileID, '%s', "No gray mask generated for frame " + num2str(f));
                    %         fprintf(fileID, '\n');
                end
                
                %% Create a mask based on edges
                %     fprintf(fileID, '%s', "Generating edge mask");
                %     fprintf(fileID, '\n');
                edgeImage = bubbleAnalysis.edgeMask(targetImage, oldData, fileID);
                if any(any(edgeImage))
                    edgeCC = bwconncomp(edgeImage, 8);
                    edgeStats = regionprops(edgeCC, 'Centroid', 'Circularity');
                    edgeCenter = edgeStats.Centroid;
                    %         fprintf(fileID, '%s', "Edge mask generated");
                    %         fprintf(fileID, '\n');
                else
                    %         fprintf(fileID, '%s', "No edge mask generated for frame " + num2str(f));
                    %         fprintf(fileID, '\n');
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
                            finalImage = bubbleAnalysis.isolateObject(logical(grayImage + edgeImage), targetImage, fileID);
                        else
                            finalImage = grayImage & edgeImage;
                        end
                        %If the gray mask is bigger than the edge mask, then if the
                        %circularities are wildly different, use mask logic to figure out
                        %which one to use, otherwise if the ciruclarities are similar then
                        %use the combination of the two masks.
                    elseif cellfun(@numel, grayCC.PixelIdxList) > cellfun(@numel, edgeCC.PixelIdxList) && sqrt((grayCenter(1) - edgeCenter(1)).^2 + (grayCenter(2) - edgeCenter(2)).^2) < 10
                        if abs ( grayStats.Circularity - edgeStats.Circularity ) > 0.15 && grayStats.Circularity > edgeStats.Circularity
                            finalImage = bubbleAnalysis.maskLogic(grayImage, edgeImage, targetImage, oldData, fileID);
                        elseif abs( grayStats.Circularity - edgeStats.Circularity) > 0.15 && grayStats.Circularity < edgeStats.Circularity
                            finalImage = bubbleAnalysis.maskLogic(edgeImage, grayImage, targetImage, oldData, fileID);
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
                    outputMask(:, :, f) = logical(bubbleAnalysis.isolateObject(finalImage, targetImage), oldData, fileID);
                else
                    outputMask(:, :, f) = logical(finalImage);
                end
                %     fprintf(fileID, '%s', "Final mask assigned for frame " + num2str(f));
                %     fprintf(fileID, '\n');
                
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
            % fclose(fileID);
        end
        
        % Generates a mask for the given frame, going backwards in time
        function outputMask = maskGenReverse(app, inputFrames)
            % A function to isolate the bubble in each frame, returns an MxNxA logical array where M & N are the image size and A is the number of frames
            fileID = logging.generateDiaryFile("BubbleReverseDetectionLog");
            
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
                wtBr.Message = "Isolating bubble in frame " + num2str(f) + "/" + num2str(depth);
                %                 fprintf(fileID, '%s', '------------------------------');
                %                 fprintf(fileID, '\n');
                %                 fprintf(fileID, '%s', "Generating mask for frame " + num2str(f));
                %                 fprintf(fileID, '\n');
                if wtBr.CancelRequested
                    break;
                end
                
                %% Get the frame
                targetImage = inputFrames(:, :, f);
                
                %% Create a mask based on color
                %                 fprintf(fileID, '%s', "Generating gray mask");
                %                 fprintf(fileID, '\n');
                grayImage = bubbleAnalysis.colorMask(targetImage, oldData, fileID);
                if any(any(grayImage))
                    grayCC = bwconncomp(grayImage, 8);
                    grayStats = regionprops(grayCC, 'Centroid', 'Circularity');
                    grayCenter = grayStats.Centroid;
                    %                     fprintf(fileID, '%s', "Gray mask generated");
                    %                     fprintf(fileID, '\n');
                else
                    %                     fprintf(fileID, '%s', "No gray mask generated for frame " + num2str(f));
                    %                     fprintf(fileID, '\n');
                end
                
                %% Create a mask based on edges
                %                 fprintf(fileID, '%s', "Generating edge mask");
                %                 fprintf(fileID, '\n');
                edgeImage = bubbleAnalysis.edgeMask(targetImage, oldData, fileID);
                if any(any(edgeImage))
                    edgeCC = bwconncomp(edgeImage, 8);
                    edgeStats = regionprops(edgeCC, 'Centroid', 'Circularity');
                    edgeCenter = edgeStats.Centroid;
                    %                     fprintf(fileID, '%s', "Edge mask generated");
                    %                     fprintf(fileID, '\n');
                else
                    %                     fprintf(fileID, '%s', "No edge mask generated for frame " + num2str(f));
                    %                     fprintf(fileID, '\n');
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
                            finalImage = bubbleAnalysis.isolateObject(logical(grayImage + edgeImage), targetImage, fileID);
                        else
                            finalImage = grayImage & edgeImage;
                        end
                        %If the gray mask is bigger than the edge mask, then if the
                        %circularities are wildly different, use mask logic to figure out
                        %which one to use, otherwise if the ciruclarities are similar then
                        %use the combination of the two masks.
                    elseif cellfun(@numel, grayCC.PixelIdxList) > cellfun(@numel, edgeCC.PixelIdxList) && sqrt((grayCenter(1) - edgeCenter(1)).^2 + (grayCenter(2) - edgeCenter(2)).^2) < 10
                        if abs ( grayStats.Circularity - edgeStats.Circularity ) > 0.15 && grayStats.Circularity > edgeStats.Circularity
                            finalImage = bubbleAnalysis.maskLogic(grayImage, edgeImage, targetImage, oldData, fileID);
                        elseif abs( grayStats.Circularity - edgeStats.Circularity) > 0.15 && grayStats.Circularity < edgeStats.Circularity
                            finalImage = bubbleAnalysis.maskLogic(edgeImage, grayImage, targetImage, oldData, fileID);
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
                    outputMask(:, :, f) = logical(bubbleAnalysis.isolateObject(finalImage, targetImage), oldData, fileID);
                else
                    outputMask(:, :, f) = logical(finalImage);
                end
                %                 fprintf(fileID, '%s', "Final mask assigned for frame " + num2str(f));
                %                 fprintf(fileID, '\n');
                
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
            %             fclose(fileID);
        end
        
        %Create a mask based on color
        function grayImg = colorMask(targetImage, oldData, fileID)
            %A function to create a mask for the bubble based on pixel intensity values
            
            %Calculate the gray threshold for the image and binarize it based on that, Flip black and white, Get rid of any white pixels connected to the border, Fill any holes in the image
            grayImg = imfill(bwmorph(bwmorph(bwmorph(imclearborder(imcomplement(imbinarize(targetImage, graythresh(targetImage)))), 'clean'), 'diag'), 'bridge'), 'holes');
            %Remove ridiculously small and large objects from the image
            grayImg = bubbleAnalysis.removeOutliers(grayImg);
            %Refresh the connected components list
            CC = bwconncomp(grayImg, 8);
            %If there is still more than one object, attempt to isolate the most likley
            %object
            % fprintf(fileID, '%s', "Number of objects before isolation: " + num2str(CC.NumObjects));
            % fprintf(fileID, '\n');
            if CC.NumObjects > 1
                grayImg = bubbleAnalysis.isolateObject(grayImg, targetImage, oldData, fileID);
            end
            grayImg = imfill(grayImg, 'holes');
        end
        
        %Create a mask based on edges
        function edgeImage = edgeMask(targetImage, oldData, fileID)
            %A function to create a binary mask of the bubble based on edge detection
            [~, threshold] = edge(targetImage, 'Sobel');
            edgeImage = imfill(imclearborder(imcomplement(imdilate(edge(targetImage, 'Sobel', threshold*0.01), [strel('line', 3, 90) strel('line', 3, 0)]))), 'holes');
            %Remove ridiculously large and small objects from the image
            edgeImage = bubbleAnalysis.removeOutliers(edgeImage);
            %Refresh the connected components list
            CC = bwconncomp(edgeImage, 8);
            %If there is still more than one object, attempt to isolate the the object
            % fprintf(fileID, '%s', "Number of objects before isolation: " + num2str(CC.NumObjects));
            % fprintf(fileID, '\n');
            if CC.NumObjects > 1
                edgeImage = bubbleAnalysis.isolateObject(edgeImage, targetImage, oldData, fileID);
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
            % fprintf(fileID, '%s', "Size index: " + num2str(maxSize));
            % fprintf(fileID, '\n');
            
            %Find the obejct closest to the center of the frame, but not exactly in the center
            distances = zeros(1, CC.NumObjects);
            for i = 1:CC.NumObjects
                center = stats.Centroid;
                oldCenter = oldData.Center;
                distances(i) = sqrt((center(1) - oldCenter(1)).^2 + (center(2) - oldCenter(2)).^2);
            end
            [~, minDist] = min(distances(distances ~= 0));
            % fprintf(fileID, '%s', "Closest object index: " + num2str(minDist));
            % fprintf(fileID, '\n');
            
            %Find the object with the lowest pixel average
            averages = zeros(1, CC.NumObjects);
            for i = 1:CC.NumObjects
                averages(i) = mean(targetImage(CC.PixelIdxList{i}), 'all');
            end
            averages(averages == 0) = 100;
            [~, lowestAvg] = min(averages);
            % fprintf(fileID, '%s', "Lowest pixel average object index: " + num2str(lowestAvg));
            % fprintf(fileID, '\n');
            
            %Calculate the significance value for each object
            significance = distances./sizes.*averages;
            [~, minSig] = min(significance);
            % fprintf(fileID, '%s', "Most significant object index: " + num2str(minSig));
            % fprintf(fileID, '\n');
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
                %     fprintf(fileID, '%s', "Resorting to fallback: Object Circularity");
                %     fprintf(fileID, '\n');
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
            % fprintf(fileID, '%s', "Final object index: " + num2str(objIdx));
            % fprintf(fileID, '\n');
            
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
        function finalImage = maskLogic(higherCircularityMask, lowerCircularityMask, targetImage, oldData, fileID)
            hCMStats = regionprops(higherCircularityMask, 'Circularity');
            finalStatsEither = regionprops(logical(higherCircularityMask + lowerCircularityMask), 'Circularity');
            finalCCEither = bwconncomp(logical(higherCircularityMask + lowerCircularityMask), 8);
            finalStatsBoth = regionprops(logical(higherCircularityMask & lowerCircularityMask), 'Circularity');
            finalCCBoth = bwconncomp(logical(higherCircularityMask & lowerCircularityMask), 8);
            if finalCCEither.NumObjects > 1
                finalStatsEither = regionprops(bubbleAnalysis.isolateObject(logical(higherCircularityMask + lowerCircularityMask), targetImage, oldData, fileID), 'Circularity');
            end
            if finalCCBoth.NumObjects == 1
                finalImage = bubbleAnalysis.isolateObject(logical(higherCircularityMask + lowerCircularityMask), targetImage, oldData, fileID);
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
            
            %             fileID = logging.generateDiaryFile("MaskComparisionLog");
            
            %% Preliminary size check
            if size(forwardMask) ~= size(reverseMask)
                %                 fprintf(fileID, '%s', "Unequal mask sizes. Check input variables");
                %                 fprintf(fileID, '\n');
                error("Unequal mask sizes. Check input variables");
            end
            
            %% Get the number of frames and set up the output mask
            [~, ~, numFrames] = size(forwardMask);
            finalMask = zeros(size(forwardMask));
            
            %% Compare both masks for the same frame
            for i = 1:numFrames
                %                 fprintf(fileID, '%s', '------------------------------');
                %                 fprintf(fileID, '\n');
                %                 fprintf(fileID, '%s', "Comparing masks for frame: " + num2str(i));
                %                 fprintf(fileID, '\n');
                
                %% Index the forward mask
                forwardTargetMask = forwardMask(:, :, i);
                
                %% Index the reverse mask
                reverseTargetMask = reverseMask(:, :, i);
                
                %% Mask comparision logic
                if ~any(any(forwardTargetMask))
                    finalMask(:, :, i) = reverseTargetMask;         %If the forward mask is empty use the reverse mask
                    %                     fprintf(fileID, '%s', 'Forward mask empty. Using reverse mask');
                    %                     fprintf(fileID, '\n');
                elseif ~any(any(reverseTargetMask))
                    finalMask(:, :, i) = forwardTargetMask;         %If the reverse mask is empty use the forward mask
                    %                     fprintf(fileID, '%s', 'Reverse mask empty. Using forward mask');
                    %                     fprintf(fileID, '\n');
                elseif any(any(forwardTargetMask)) && any(any(reverseTargetMask))
                    sameSize = bubbleAnalysis.areCloseInSize(forwardTargetMask, reverseTargetMask);
                    sameLoc = bubbleAnalysis.areCloseInLocation(forwardTargetMask, reverseTargetMask);
                    if sameSize && sameLoc
                        finalMask(:, :, i) = logical(forwardTargetMask + reverseTargetMask);
                        %                         fprintf(fileID, '%s', 'Using logical combination of both masks');
                        %                         fprintf(fileID, '\n');
                    elseif ~sameSize && sameLoc
                        finalMask(:, :, i) = bubbleAnalysis.largerMask(forwardTargetMask, reverseTargetMask);
                        %                         fprintf(fileID, '%s', 'Using the larger mask');
                        %                         fprintf(fileID, '\n');
                    elseif sameSize && ~sameLoc
                        finalMask(:, :, i) = bubbleAnalysis.closerToCenterMask(forwardTargetMask, reverseTargetMask);
                        %                         fprintf(fileID, '%s', 'Using the mask closer to the center');
                        %                         fprintf(fileID, '\n');
                    elseif ~sameSize && ~sameLoc
                        finalMask(:, :, i) = bubbleAnalysis.moreCircularMask(forwardTargetMask, reverseTargetMask);
                        %                         fprintf(fileID, '%s', 'Using the more circular mask');
                        %                         fprintf(fileID, '\n');
                    end
                else
                    %                     fprintf(fileID, '%s', 'Both masks empty');
                    %                     fprintf(fileID, '\n');
                end
            end
            %             fclose(fileID);
        end
        
        %Determine if the objects in the mask are close in size
        function result = areCloseInSize(maskOne, maskTwo)
            maskOneCC = bwconncomp(maskOne);
            maskTwoCC = bwconncomp(maskTwo);
            
            maskOneSize = cellfun(@numel, maskOneCC.PixelIdxList);
            maskTwoSize = cellfun(@numel, maskTwoCC.PixelIdxList);
            
            if abs( maskOneSize - maskTwoSize) < 75
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
        
        %Analyze the video
        function maskInformation = bubbleTrack(app, mask, arcLength, orientation, doFit, numberTerms, adaptiveTerms, ignoreFrames)
            % A function to generate data about each mask
            
            %% Set up logging
            fileID = logging.generateDiaryFile("BubbleAnalysisLog");
            
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
                standardMsg = "Analyzing frame " + num2str(d) + "/" + num2str(depth);
                wtBr.Message = standardMsg;
                wtBr.Value = d./depth;
                %     fprintf(fileID, '%s', '------------------------------');
                %     fprintf(fileID, '\n');
                %Skip any frames that are in the ignore list
                if ~isempty(find(ignoreFrames == d, 1))
                    %         fprintf(fileID, '%s', "Skipping analysis of frame " + num2str(d));
                    %         fprintf(fileID, '\n');
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
                    wtBr.Message = standardMsg + ": Calculating centroid, area, and perimeter";
                    targetStats = regionprops(targetMask, 'Centroid', 'Area', 'Perimeter', 'Orientation');
                    
                    %Assign that data to the output struct
                    maskInformation(d).Centroid = targetStats.Centroid;
                    %         fprintf(fileID, '%s', "Centroid: " + num2str(targetStats.Centroid));
                    %         fprintf(fileID, '\n');
                    
                    maskInformation(d).Area = targetStats.Area;
                    %         fprintf(fileID, '%s', "Area: " + num2str(targetStats.Area));
                    %         fprintf(fileID, '\n');
                    
                    maskInformation(d).Perimeter = targetStats.Perimeter;
                    %         fprintf(fileID, '%s', "Perimeter Length: " + num2str(targetStats.Perimeter));
                    %         fprintf(fileID, '\n');
                    
                    maskInformation(d).PerimeterPoints = bubbleAnalysis.generatePerimeterPoints(targetMask);
                    
                    %Get the tracking points
                    wtBr.Message = standardMsg + ": Generaing tracking points";
                    [xVals, yVals] = bubbleAnalysis.angularPerimeter(targetMask, [maskInformation(d).Centroid], 50, fileID);
                    maskInformation(d).TrackingPoints = [xVals, yVals];
                    
                    %Calculate the average radius
                    center = [maskInformation(d).Centroid];
                    wtBr.Message = standardMsg + ": Calculating average radius";
                    maskInformation(d).AverageRadius = mean(sqrt( (center(1) - xVals).^2 + (center(2) - yVals).^2 ), 'all');
                    %         fprintf(fileID, '%s', "Average Radius: " + num2str(maskInformation(d).AverageRadius));
                    %         fprintf(fileID, '\n');
                    
                    %Translate the bubble to be centered on the axes
                    translatedPoints = bubbleAnalysis.translatePerim(maskInformation(d).PerimeterPoints, center);
                    switch orientation
                        case 'horizontal'
                            angle = 0;
                        case 'vertical'
                            angle = 90;
                        case 'major'
                            angle = targetStats.Orientation;
                        case 'minor' 
                            angle = targetStats.Orientation + 90;
                    end
                    
                    %Rotate the bubble to be in its desired orientation
                    rotatedPoints = bubbleAnalysis.rotatePerim(translatedPoints, angle);
                    
                    %Calculate the surface area of the bubble (roughly)
                    maskInformation(d).SurfaceArea = bubbleAnalysis.calcSurf(rotatedPoints);
                    
                    %Calculate the volume of the bubble (roughly)
                    maskInformation(d).Volume = bubbleAnalysis.calcVol(rotatedPoints);
   
                    if doFit
                        %             fprintf(fileID, '%s', "Fitting Fourier Series to mask perimeter for frame: " + num2str(d));
                        %             fprintf(fileID, '\n');
                        %Get the points for the fourier fit
                        wtBr.Message = standardMsg + ": Generaing Fourier Fit points";
                        [xVals, yVals] = bubbleAnalysis.angularPerimeter(targetMask, [maskInformation(d).Centroid], floor( maskInformation(d).Perimeter./arcLength), fileID);
                        maskInformation(d).FourierPoints = [xVals, yVals];
                        %             fprintf(fileID, '%s', "Number of Perimeter Fourier Fit Points: " + num2str(length(xVals)));
                        %             fprintf(fileID, '\n');
                        %Actually do the fourier fit and get the coefficients for the
                        %equation
                        %             fprintf(fileID, '%s', "Minimum Arc Length: " + num2str(arcLength));
                        %             fprintf(fileID, '\n');
                        %             fprintf(fileID, '%s', "(Max) Number of Terms in Fit: " + num2str(numberTerms));
                        %             fprintf(fileID, '\n');
                        %             fprintf(fileID, '%s', "Adaptive Number of Terms (T/F): " + num2str(adaptiveTerms));
                        %             fprintf(fileID, '\n');
                        %             fprintf(fileID, '%s', "Beginning Fit");
                        %             fprintf(fileID, '\n');
                        wtBr.Message = standardMsg + ": Fitting parametric Fourier Series";
                        [xFit, yFit, xData, yData] = bubbleAnalysis.fourierFit(xVals, yVals, arcLength, numberTerms, adaptiveTerms,fileID);
                        %             fprintf(fileID, '%s', "Fit complete");
                        %             fprintf(fileID, '\n');
                        maskInformation(d).FourierFitX = xFit;
                        maskInformation(d).FourierFitY = yFit;
                        maskInformation(d).xData = xData;
                        maskInformation(d).yData = yData;
                        %             fprintf(fileID, '%s', "Number of plotting points: " + num2str(length(xData)));
                        %             fprintf(fileID, '\n');
                    end
                end
                %     fprintf(fileID, '%s', "Analysis complete");
                %     fprintf(fileID, '\n');
            end
            %% Close waitbar and the diary
            close(wtBr);
            % fclose(fileID);
        end
        
        %Generate the evenly angularly spaced tracking points
        function [xVals, yVals] = angularPerimeter(targetMask, center, noTC, fileID)
            % fprintf(fileID, '%s', "Generating " + num2str(noTC) + " periemter points");
            % fprintf(fileID, '\n');
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
            % fprintf(fileID, '%s', "Perimeter point generation complete");
            % fprintf(fileID, '\n');
        end
        
        %Fit a fourier function to the x and y points on the mask
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
                %     fprintf(fileID, '%s', "Not enough perimeter points");
                %     fprintf(fileID, '\n');
            end
            % fprintf(fileID, '%s', "Creating X and Y Fourier function files with " + num2str(numberTerms) + " number of terms");
            % fprintf(fileID, '\n');
            [functionNameX, functionNameY] = bubbleAnalysis.createFourierFunc(numberTerms);
            
            %Actually fit it for the correct number of terms
            ftx = fittype(functionNameX);
            xFit = fit(transpose(1:row), xPoints, ftx);
            fty = fittype(functionNameY);
            yFit = fit(transpose(1:row), yPoints, fty);
            
            %Evaluate the fit
            xData = feval(xFit, 0:1/(row*numberTerms):row);
            yData = feval(yFit, 0:1/(row*numberTerms):row);
            
            %Delete the files
            % fprintf(fileID, '%s', 'Deleting function files');
            % fprintf(fileID, '\n');
            delete('main/xFourierFunc.m');
            delete('main/yFourierFunc.m');
        end
        
        %Extract all the perimeter points from the mask
        function output = generatePerimeterPoints(inputMask)
            boundaries = cell2mat(bwboundaries(inputMask));
            output(:, 1) = boundaries(:, 2);
            output(:, 2) = boundaries(:, 1);
        end
        
        %Create the Fourier Function files dependent on the number of terms
        %in the fit
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
        
    end
end