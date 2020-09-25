function dispEvolution(app)
%Fill in the colormap
position = app.ColorMap.Position;
width = floor(position(3));
height = floor(position(4));
colorMapImage = zeros(height, width, 3);
redLayer = repmat(linspace(app.colorMap.Start(1), app.colorMap.End(1), width), height, 1);
greenLayer = repmat(linspace(app.colorMap.Start(2), app.colorMap.End(2), width), height, 1);
blueLayer = repmat(linspace(app.colorMap.Start(3), app.colorMap.End(3), width), height, 1);
colorMapImage(:, :, 1) = redLayer;
colorMapImage(:, :, 2) = greenLayer;
colorMapImage(:, :, 3) = blueLayer;
app.ColorMap.ImageSource = colorMapImage;
if ~isempty(app.maskInformation)
    [~, ~, depth] = size(app.mask);
    gradient = zeros(1, 3, depth);
    gradient(1, 1, :) = linspace(app.colorMap.Start(1), app.colorMap.End(1), depth);
    gradient(1, 2, :) = linspace(app.colorMap.Start(2), app.colorMap.End(2), depth);
    gradient(1, 3, :) = linspace(app.colorMap.Start(3), app.colorMap.End(3), depth);
    perimeterPoints = app.maskInformation(1).PerimeterPoints;
    if ~isnan(perimeterPoints)
        plot(app.EvolutionPlot, perimeterPoints(:, 1), perimeterPoints(:, 2), 'Color', gradient(:, :, 1));
    end
    hold(app.EvolutionPlot, 'on');
    for d = 2:depth
        if isempty(find(app.ignoreFrames == d, 1))
            perimeterPoints = app.maskInformation(d).PerimeterPoints;
            plot(app.EvolutionPlot, perimeterPoints(:, 1), perimeterPoints(:, 2), 'Color', gradient(:, :, d));
        end
    end
    hold(app.EvolutionPlot, 'off');
end
end
