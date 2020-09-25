function convertedPlotSet = convertUnits(app)

%Convert frames to seconds
time = 0:app.frameInterval:(app.numFrames - 1)*app.frameInterval;
convertedPlotSet.TimeVector = time;

%Convert the basic analysis things to microns from pixels
convertedPlotSet.AverageRadius = app.radius.*app.MicronPixelEditField.Value;
convertedPlotSet.Area = app.area.*(app.MicronPixelEditField.Value).^2;
convertedPlotSet.Perimeter = app.perimeter.*app.MicronPixelEditField.Value;
convertedPlotSet.SurfaceArea = app.surfaceArea.*(app.MicronPixelEditField.Value).^2;
convertedPlotSet.Volume = app.volume.*(app.MicronPixelEditField.Value).^3;
convertedPlotSet.Centroid = app.centroid.*app.MicronPixelEditField.Value;

end

