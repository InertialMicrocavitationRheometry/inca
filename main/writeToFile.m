function savePath = writeToFile(app)
%% Read in and import into local variables the data
frames = app.frames;
masks = app.mask;
infoStruct = app.maskInformation;
ignoreFrames = app.ignoreFrames;
BubbleRadius = app.radius;
BubbleArea = app.area;
BubblePerimeter = app.perimeter;
BubbleSurfaceArea = app.surfaceArea;
BubbleCentroid = app.centroid;
BubbleVolume = app.volume;
numFrames = app.numFrames;
alternatePlotSet = app.convertedPlotSet;
%% Write the table to the specified file
[file, path] = uiputfile('*.mat');
savePath = append(path, file);
save(savePath, 'frames', 'masks', 'infoStruct', 'ignoreFrames', 'BubbleRadius', 'BubbleArea', 'BubblePerimeter', ...
    'BubbleSurfaceArea', 'BubbleCentroid', 'BubbleVolume', 'numFrames', 'alternatePlotSet', '-v7.3');
end
