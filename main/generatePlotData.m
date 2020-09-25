function [radius, area, perimeter, surfaceArea, volume, centroid] = generatePlotData(app)

info = app.maskInformation;
numFrames = app.numFrames;

%Set up the output variables
radius = zeros(numFrames, 1);
area = zeros(numFrames, 1);
perimeter = zeros(numFrames, 1);
surfaceArea = zeros(numFrames, 1);
volume = zeros(numFrames, 1);
centroid = zeros(numFrames, 2);
for i = 1:numFrames
    
    if ~isempty(info(i).AverageRadius)
        radius(i) = info(i).AverageRadius;
    end
    
    if ~isempty(info(i).Area)
        area(i) = info(i).Area;
    end
    
    if ~isempty(info(i).Perimeter)
        perimeter(i) = info(i).Perimeter;
    end
    
    if ~isempty(info(i).SurfaceArea)
        surfaceArea(i) = info(i).SurfaceArea;
    end
    
    if ~isempty(info(i).Volume)
        volume(i) = info(i).Volume;
    end
    
    if ~isempty(info(i).Centroid)
        centroid(i, :) = info(i).Centroid;
    end
end
end
