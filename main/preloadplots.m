function premadePlots = preloadplots(maskInformation, numFrames, axesHandle)

premadePlots = struct('MaskCentroid', cell(numFrames, 1), 'MaskPerim', cell(numFrames, 1), 'TrackingPoints', cell(numFrames, 1), ...
    'FourierPoints', cell(numFrames, 1), 'FourierCentroid', cell(numFrames, 1), 'FourierFit', cell(numFrames, 1));
set(axesHandle, 'YDir', 'reverse');

for i = 1:numFrames
    premadePlots(i).MaskCentroid = plot(axesHandle, maskInformation(i).Centroid(1), maskInformation(i).Centroid(2), 'g*', 'MarkerSize', 20);
    premadePlots(i).MaskPerim = plot(axesHandle, maskInformation(i).PerimeterPoints(:, 1), maskInformation(i).PerimeterPoints(:, 2));
end

end