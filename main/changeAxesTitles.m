function changeAxesTitles(app, titleType)

switch titleType
    case 'pixels'
        app.RadiusPlot.XLabel.String = "Frame";
        app.RadiusPlot.YLabel.String = "Pixels";
        
        app.AreaPlot.XLabel.String = "Frame";
        app.AreaPlot.YLabel.String = "Square Pixels";
        
        app.PerimeterPlot.XLabel.String = "Frame";
        app.PerimeterPlot.YLabel.String = "Pixels";
        
        app.SurfaceAreaPlot.XLabel.String = "Frame";
        app.SurfaceAreaPlot.YLabel.String = "Square Pixels";
        
        app.VolumePlot.XLabel.String = "Frame";
        app.VolumePlot.YLabel.String = "Cubic Pixels";
        
        app.AsphericityPlot.XLabel.String = "Frame";
    case 'microns'
        app.RadiusPlot.XLabel.String = "Seconds";
        app.RadiusPlot.YLabel.String = "Microns";
        
        app.AreaPlot.XLabel.String = "Seconds";
        app.AreaPlot.YLabel.String = "Square Microns";
        
        app.PerimeterPlot.XLabel.String = "Seconds";
        app.PerimeterPlot.YLabel.String = "Microns";
        
        app.SurfaceAreaPlot.XLabel.String = "Seconds";
        app.SurfaceAreaPlot.YLabel.String = "Square Microns";
        
        app.VolumePlot.XLabel.String = "Seconds";
        app.VolumePlot.YLabel.String = "Cubic Microns";
        
        app.AsphericityPlot.XLabel.String = "Seconds";       
end

end