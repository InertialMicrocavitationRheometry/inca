function plotConvertedFourier(app)
yyaxis(app.AsphericityPlot, "left");
cla(app.AsphericityPlot);
yyaxis(app.AsphericityPlot, "right");
cla(app.AsphericityPlot);
app.AsphericityPlot.XLim = [app.convertedPlotSet.TimeVector(1), app.convertedPlotSet.TimeVector(end)];
if app.FitFourierSeriestoPointsCheckBox.Value
    %Get the color map set up
    cmap = viridis(app.TermstoPlotEditField.Value - 1);
    
    %Fill in the colormap bar for reference
    position = app.FourierColorMap.Position;
    width = floor(position(3));
    height = floor(position(4));
    colorMapImage = zeros(height, width, 3);
    
    imageMap = viridis(width);
    
    redLine = transpose(imageMap(:, 1));
    greenLine = transpose(imageMap(:, 2));
    blueLine = transpose(imageMap(:, 3));
    
    redLayer = repmat(redLine, height, 1);
    greenLayer = repmat(greenLine, height, 1);
    blueLayer = repmat(blueLine, height, 1);
    
    colorMapImage(:, :, 1) = redLayer;
    colorMapImage(:, :, 2) = greenLayer;
    colorMapImage(:, :, 3) = blueLayer;
    app.FourierColorMap.ImageSource = colorMapImage;
    
    %Plot the data points
    points = fourierFitPlot(app.maskInformation, app.TermstoPlotEditField.Value, app.numFrames, app.ignoreFrames);
    
    yyaxis(app.AsphericityPlot, 'left');
    
    plot(app.AsphericityPlot, app.convertedPlotSet.TimeVector, points(:, 1),"Color", cmap(1, :), "LineStyle","-", "Marker", "none");
    
    app.AsphericityPlot.YColor = cmap(end - 1, :);
    
    hold(app.AsphericityPlot, 'on');
    
    for d = 2:(app.TermstoPlotEditField.Value - 1)
        plot(app.AsphericityPlot, app.convertedPlotSet.TimeVector, points(:, d),"Color", cmap(d, :), "LineStyle","-", "Marker", "none");
        
    end
    hold(app.AsphericityPlot, 'off');
    
    normalizedRadius = plotting.noramlizedRadiusPlot(app.maskInformation, app.numFrames, app.ignoreFrames);
    
    yyaxis(app.AsphericityPlot, 'right');
    ylabel(app.AsphericityPlot, "R/Rmax");
    app.AsphericityPlot.YColor = app.theme.axisColor;
    
    r = plot(app.AsphericityPlot, app.convertedPlotSet.TimeVector, normalizedRadius, "LineStyle", "-", "Marker", "none", "Color", [1, 1, 1]);
    
    legend(app.AsphericityPlot, r, "R/max(R)", "TextColor", [1, 1, 1]);
    
    
end
end
