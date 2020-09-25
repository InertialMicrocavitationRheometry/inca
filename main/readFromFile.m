function [app, fullPath] = readFromFile(app)
%% Load in the Data Table
[file, path] = uigetfile('*.mat');
fullPath = append(path, file);
load(fullPath);
%% Read in the data to the app variables if they exist in the current workspace
if exist('frames', 'var') == 1
    app.frames = frames;
end
if exist('masks', 'var') == 1
    app.mask = masks;
end
if exist('infoStruct', 'var') == 1
    app.maskInformation = infoStruct;
end
if exist('ignoreFrames', 'var') == 1
    app.ignoreFrames = ignoreFrames;
end
if exist('BubbleRadius', 'var') == 1
    app.radius = BubbleRadius;
end
if exist('BubbleArea', 'var') == 1
    app.area = BubbleArea;
end
if exist('BubblePerimeter', 'var') == 1
    app.perimeter = BubblePerimeter;
end
if exist('BubbleSurfaceArea', 'var') == 1
    app.surfaceArea = BubbleSurfaceArea;
end
if exist('BubbleCentroid', 'var') == 1
    app.centroid = BubbleCentroid;
end
if exist('BubbleVolume', 'var') == 1
    app.volume = BubbleVolume;
end
if exist('numFrames', 'var') == 1
    app.numFrames = numFrames;
end
if exist('alternatePlotSet', 'var') == 1
    app.convertedPlotSet = alternatePlotSet;
end
end
