function resetFunction(app)
% Clear main variables
clear app.frames;
clear app.mask;
clear app.maskInformation;
clear app.videoPath;
clear app.ignoreFrames;
app.currentFrame = 1;
clear app.radius;
clear app.area;
clear app.perimeter;
clear app.surfaceArea;
clear app.centroid;
clear app.volume
clear app.numFrames;
clear app.convertedPlotSet;

%Clear textboxes
app.LoadPath.Value = "";
app.SavePath.Value = "";

%Clear plots and graphs
cla(app.MainPlot);
cla(app.EvolutionPlot);
cla(app.RadiusPlot);
cla(app.TwoDimensionalPlot);
cla(app.ThreeDimensionalPlot);
cla(app.CentroidPlot);
cla(app.AsphericityPlot);

%Reset Fourier Decomp Tab
app.TargetFrameEditField.Value = 1;
app.TermstoDecomposeEditField.Value = 8;
app.DescendingButton.Value = 1;
app.MaintainColormapCheckBox.Value = 1;
delete(app.DecomposedPlotsPanel.Children);
delete(app.MaskOverlayPreviewPanel.Children);
end