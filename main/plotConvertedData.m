function plotConvertedData(app)

if ~isempty(app.radius)
    %Radius Plot
    plot(app.RadiusPlot, app.convertedPlotSet.TimeVector, app.convertedPlotSet.AverageRadius ,"--.", "Color", app.theme.plotStyle);
    hold(app.RadiusPlot, 'on');
    plot(app.RadiusPlot, app.convertedPlotSet.TimeVector(app.currentFrame), app.convertedPlotSet.AverageRadius(app.currentFrame), '*', 'Color', app.theme.markerStyle, 'MarkerSize', 10);
    hold(app.RadiusPlot, 'off');
    
    %Area Plot
    plot(app.AreaPlot, app.convertedPlotSet.TimeVector, app.convertedPlotSet.Area ,"--.", "Color", app.theme.plotStyle);
    hold(app.AreaPlot, 'on');
    plot(app.AreaPlot, app.convertedPlotSet.TimeVector(app.currentFrame), app.convertedPlotSet.Area(app.currentFrame), '*', 'Color', app.theme.markerStyle, 'MarkerSize', 10);
    hold(app.AreaPlot, 'off');
    
    %Perimeter Plot
    plot(app.PerimeterPlot, app.convertedPlotSet.TimeVector, app.convertedPlotSet.Perimeter ,"--.", "Color", app.theme.plotStyle);
    hold(app.PerimeterPlot, 'on');
    plot(app.PerimeterPlot, app.convertedPlotSet.TimeVector(app.currentFrame), app.convertedPlotSet.Perimeter(app.currentFrame), '*', 'Color', app.theme.markerStyle, 'MarkerSize', 10);
    hold(app.PerimeterPlot, 'off');
    
    %Volume Plot
    plot(app.VolumePlot, app.convertedPlotSet.TimeVector, app.convertedPlotSet.Volume, '--.', "Color", app.theme.plotStyle);
    hold(app.VolumePlot, 'on');
    plot(app.VolumePlot, app.convertedPlotSet.TimeVector(app.currentFrame), app.convertedPlotSet.Volume(app.currentFrame), '*', 'Color', app.theme.markerStyle, 'MarkerSize', 10);
    hold(app.VolumePlot, 'off');
    
    %Surface Area Plot
    plot(app.SurfaceAreaPlot, app.convertedPlotSet.TimeVector, app.convertedPlotSet.SurfaceArea, '--.', "Color", app.theme.plotStyle);
    hold(app.SurfaceAreaPlot, 'on');
    plot(app.SurfaceAreaPlot, app.convertedPlotSet.TimeVector(app.currentFrame), app.convertedPlotSet.SurfaceArea(app.currentFrame), '*', 'Color', app.theme.markerStyle, 'MarkerSize', 10);
    hold(app.SurfaceAreaPlot, 'off');
    
    %Centroid Plot
    gradient = zeros(1, 3, app.numFrames);
    gradient(1, 1, :) = linspace(app.colorMap.Start(1), app.colorMap.End(1), app.numFrames);
    gradient(1, 2, :) = linspace(app.colorMap.Start(2), app.colorMap.End(2), app.numFrames);
    gradient(1, 3, :) = linspace(app.colorMap.Start(3), app.colorMap.End(3), app.numFrames);
    plot(app.CentroidPlot, app.convertedPlotSet.Centroid(1, 1), app.convertedPlotSet.Centroid(1, 2), '--*', "Color", gradient(:, :, 1));
    hold(app.CentroidPlot, 'on');
    for d = 2:app.numFrames
        plot(app.CentroidPlot, app.convertedPlotSet.Centroid(d, 1), app.convertedPlotSet.Centroid(d, 2), '--*', 'Color', gradient(:, :, d));
    end
    plot(app.CentroidPlot, app.convertedPlotSet.Centroid(app.currentFrame, 1), app.convertedPlotSet.Centroid(app.currentFrame, 2), '*', 'Color', app.theme.markerStyle, 'MarkerSize', 10);
    hold(app.CentroidPlot, 'off');
    
end
end