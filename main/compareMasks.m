function finalMask = compareMasks(forwardMask, reverseMask)

fileID = generateDiaryFile("MaskComparisionLog");

%% Preliminary size check
if size(forwardMask) ~= size(reverseMask)
    fprintf(fileID, '%s', "Unequal mask sizes. Check input variables");
    fprintf(fileID, '\n');
    error("Unequal mask sizes. Check input variables");
end

%% Get the number of frames and set up the output mask
[~, ~, numFrames] = size(forwardMask);
finalMask = zeros(size(forwardMask));

%% Compare both masks for the same frame
for i = 1:numFrames
    fprintf(fileID, '%s', '------------------------------');
    fprintf(fileID, '\n');
    fprintf(fileID, '%s', "Comparing masks for frame: " + num2str(i));
    fprintf(fileID, '\n');
    
    %% Index the forward mask
    forwardTargetMask = forwardMask(:, :, i);           
    
    %% Index the reverse mask
    reverseTargetMask = reverseMask(:, :, i); 
    
    %% Mask comparision logic
    if ~any(any(forwardTargetMask))
        finalMask(:, :, i) = reverseTargetMask;         %If the forward mask is empty use the reverse mask
        fprintf(fileID, '%s', 'Forward mask empty. Using reverse mask');
        fprintf(fileID, '\n');
    elseif ~any(any(reverseTargetMask))
        finalMask(:, :, i) = forwardTargetMask;         %If the reverse mask is empty use the forward mask 
        fprintf(fileID, '%s', 'Reverse mask empty. Using forward mask');
        fprintf(fileID, '\n');
    elseif any(any(forwardTargetMask)) && any(any(reverseTargetMask))
        sameSize = areCloseInSize(forwardTargetMask, reverseTargetMask);
        sameLoc = areCloseInLocation(forwardTargetMask, reverseTargetMask);
        if sameSize && sameLoc
            finalMask(:, :, i) = logical(forwardTargetMask + reverseTargetMask);
            fprintf(fileID, '%s', 'Using logical combination of both masks');
            fprintf(fileID, '\n');
        elseif ~sameSize && sameLoc
            finalMask(:, :, i) = largerMask(forwardTargetMask, reverseTargetMask);
            fprintf(fileID, '%s', 'Using the larger mask');
            fprintf(fileID, '\n');
        elseif sameSize && ~sameLoc
            finalMask(:, :, i) = closerToCenterMask(forwardTargetMask, reverseTargetMask);
            fprintf(fileID, '%s', 'Using the mask closer to the center');
            fprintf(fileID, '\n');
        elseif ~sameSize && ~sameLoc
            finalMask(:, :, i) = moreCircularMask(forwardTargetMask, reverseTargetMask);
            fprintf(fileID, '%s', 'Using the more circular mask');
            fprintf(fileID, '\n');
        end
    else
        fprintf(fileID, '%s', 'Both masks empty');
        fprintf(fileID, '\n');
    end
end
fclose(fileID);
end

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