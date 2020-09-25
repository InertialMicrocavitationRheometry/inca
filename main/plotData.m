function plotData(app, radius, area, perimeter, surfaceArea, volume, centroid)
if ~isempty(radius)
    %Radius Plot
    app.RadiusPlot.XLim = [1, app.numFrames];
    plot(app.RadiusPlot, 1:app.numFrames, radius ,"--.", "Color", app.theme.plotStyle);
    hold(app.RadiusPlot, 'on');
    plot(app.RadiusPlot, app.currentFrame, radius(app.currentFrame), '*', 'Color', app.theme.markerStyle, 'MarkerSize', 10);
    hold(app.RadiusPlot, 'off');
    
    %Area Plot
    app.AreaPlot.XLim = [1, app.numFrames];
    plot(app.AreaPlot, 1:app.numFrames, area, '--.', "Color", app.theme.plotStyle);
    hold(app.AreaPlot, 'on');
    plot(app.AreaPlot, app.currentFrame, area(app.currentFrame), '*', 'Color', app.theme.markerStyle, 'MarkerSize', 10);
    hold(app.AreaPlot, 'off');
    
    %Perimeter Plot
    app.PerimeterPlot.XLim = [1, app.numFrames];
    plot(app.PerimeterPlot, 1:app.numFrames, perimeter,'--.', "Color", app.theme.plotStyle);
    hold(app.PerimeterPlot, 'on');
    plot(app.PerimeterPlot, app.currentFrame, perimeter(app.currentFrame), '*', 'Color', app.theme.markerStyle, 'MarkerSize', 10);
    hold(app.PerimeterPlot, 'off');
    
    %Volume Plot
    app.VolumePlot.XLim = [1, app.numFrames];
    plot(app.VolumePlot, 1:app.numFrames, volume, '--.', "Color", app.theme.plotStyle);
    hold(app.VolumePlot, 'on');
    plot(app.VolumePlot, app.currentFrame, volume(app.currentFrame), '*', 'Color', app.theme.markerStyle, 'MarkerSize', 10);
    hold(app.VolumePlot, 'off');
    
    %Surface Area Plot
    app.SurfaceAreaPlot.XLim = [1, app.numFrames];
    plot(app.SurfaceAreaPlot, 1:app.numFrames, surfaceArea, '--.', "Color", app.theme.plotStyle);
    hold(app.SurfaceAreaPlot, 'on');
    plot(app.SurfaceAreaPlot, app.currentFrame, surfaceArea(app.currentFrame), '*', 'Color', app.theme.markerStyle, 'MarkerSize', 10);
    hold(app.SurfaceAreaPlot, 'off');
    
    %Centroid Plot
    gradient = zeros(1, 3, app.numFrames);
    gradient(1, 1, :) = linspace(app.colorMap.Start(1), app.colorMap.End(1), app.numFrames);
    gradient(1, 2, :) = linspace(app.colorMap.Start(2), app.colorMap.End(2), app.numFrames);
    gradient(1, 3, :) = linspace(app.colorMap.Start(3), app.colorMap.End(3), app.numFrames);
    plot(app.CentroidPlot, centroid(1, 1), centroid(1, 2), '--*', "Color", gradient(:, :, 1));
    hold(app.CentroidPlot, 'on');
    for d = 2:app.numFrames
        plot(app.CentroidPlot, centroid(d, 1), centroid(d, 2), '--*', 'Color', gradient(:, :, d));
    end
    plot(app.CentroidPlot, centroid(app.currentFrame, 1), centroid(app.currentFrame, 2), '*', 'Color', app.theme.markerStyle, 'MarkerSize', 10);
    hold(app.CentroidPlot, 'off');
    
end
end
