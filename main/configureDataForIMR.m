function data = configureDataForIMR(frames, mask, numFrames, ignoreFrames, maskInformation, convertedPlotSet, numExportTerms)
% A function to configure InCA data for export to IMR
% data - an output struct with the fields:
%     .RoFT - a n x 1 column vector that contains the Fourier Fit radius for
%     each frame, where n is the number of frames
%     .t - a n x 1 column vector that contains the timestamp for each
%     frame, where n is the number of frames
%     .FTs - a n x 2*k matrix that contains the first k fourier term
%     amplitudes and where n is the number of frames
%     .regionprops - a n x 1 struct that contains various
%     region props data about each frame/mask

%% Extract the radius of each frame and put it in a vector
radius = zeros(numFrames, 1);
for i = 1:numFrames
    if isempty(find(ignoreFrames == i, 1))
        xVal = maskInformation(i).FourierFitX.a1;               %Get the x component of the radius
        yVal = maskInformation(i).FourierFitY.b1;               %Get the y component of the radius                        
        radius(i) = sqrt(xVal^2 + yVal^2);                      %Calculate and store the radius
    end
end

%% Extract the time stamp for each frame and put it in a vector
timestamp = convertedPlotSet.TimeVector;

%% Extract the Fourier Fit Amplitudes for each frame
FourierAmps = zeros(numFrames, numExportTerms);
for i = 1:numFrames
    if isempty(find(ignoreFrames == i, 1))
        xFourier = maskInformation(i).FourierFitX;              %Get the xFit for the frame
        yFourier = maskInformation(i).FourierFitY;              %Get the yFit for the frame
        xnames = coeffnames(xFourier);                              %Extract the x fit coefficient names
        ynames = coeffnames(yFourier);                              %Extract the y fit coefficient names
        xcoeffvals = coeffvalues(xFourier);                         %Extract the x fit coefficient values
        ycoeffvals = coeffvalues(yFourier);                         %Extract the y fit coefficient values
        
        for j = 1:numExportTerms
            targetCoeffX = "a" + num2str(j);                        %Generate a target x coefficient name
            targetCoeffY = "b" + num2str(j);                        %Generate a target y coefficent name
            
            xVal = xcoeffvals(xnames == targetCoeffX);              %Get the x coefficient value associated with that name
            yVal = ycoeffvals(ynames == targetCoeffY);              %Get the y coefficient value associated with that name
            
            FourierAmps(i, 2*j - 1) = xVal;
            FourierAmps(i, 2*j) = yVal;
        end
    end
end

%% Get regionprops data for each frame
imageAnalysis = struct('Centroid', cell(numFrames, 1), 'Image', cell(numFrames, 1), 'Orientation', cell(numFrames, 1), ...
    'Perimeter', cell(numFrames, 1), 'PixelIdxList', cell(numFrames, 1), 'PixelList', cell(numFrames, 1), ...
    'WeightedCentroid', cell(numFrames, 1));
for i = 1:numFrames
    if isempty(find(ignoreFrames == i, 1))
        %Compute and compile the region props results
        output= regionprops(mask(:, :, i), 'Centroid', 'Image', 'Orientation', 'Perimeter', 'PixelIdxList', 'PixelList');
        stats = regionprops(mask(:, :, i), frames(:, :, i), 'WeightedCentroid');
        output.WeightedCentroid = stats.WeightedCentroid;
        
        %Assign the values to the output struct in the correct location
        imageAnalysis(i).Centroid = output.Centroid;
        imageAnalysis(i).Image = output.Image;
        imageAnalysis(i).Orientation = output.Orientation;
        imageAnalysis(i).Perimeter = output.Perimeter;
        imageAnalysis(i).PixelIdxList = output.PixelIdxList;
        imageAnalysis(i).PixelList = output.PixelList;
        imageAnalysis(i).WeightedCentroid = output.WeightedCentroid;
    end
end

%% Assign to final output struct
data.RoFT = radius;
data.t = timestamp;
data.FTs = FourierAmps;
data.regionprops = imageAnalysis;

end