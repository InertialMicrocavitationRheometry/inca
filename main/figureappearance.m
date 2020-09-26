classdef figureappearance
    methods (Static)
        %Sets a radio button
        function setTheme(app, theme)
            if theme == "default"
                app.DefaultButton.Value = true;
            elseif theme == "dark"
                app.DarkButton.Value = true;
            elseif theme == "night"
                app.NightButton.Value = true;
            elseif theme == "army"
                app.ArmyButton.value = true;
            elseif theme == "leather"
                app.LeatherButton.Value = true;
            elseif theme == "waves"
                app.WavesButton.Value = true;
            end
            figureappearance.checkTheme(app);
        end
        
        %Checks which radio button is selected
        function checkTheme(app)
            if app.DefaultButton.Value == true
                newTheme = defaultTheme();
            elseif app.DarkButton.Value == true
                newTheme = darkTheme;
            elseif app.NightButton.Value == true
                newTheme = nightTheme();
            elseif app.ArmyButton.Value == true
                newTheme = armyTheme();
            elseif app.LeatherButton.Value == true
                newTheme = leatherTheme();
            elseif app.WavesButton.Value == true
                newTheme = wavesTheme();
            elseif app.CustomButton.Value == true
                file = uigetfile('*.m');
                fileName  = file(1:end - 2);
                figure(app.UIFigure);
                newTheme = eval(fileName);
            end
            figureappearance.updateTheme(app, newTheme);
        end
        
        %Rewrites the theme struct
        function updateTheme(app, newTheme)
            app.theme.mainbackgroundColor = newTheme{1};
            app.theme.backgroundColor = newTheme{2};
            app.theme.foregroundColor = newTheme{3};
            app.theme.axisColor = newTheme{4};
            app.theme.plotBackground = newTheme{5};
            app.theme.textBackgroundColor = newTheme{6};
            app.theme.fontColor = newTheme{7};
            app.theme.plotStyle = newTheme{8};
            app.theme.markerStyle = newTheme{9};
            app.theme.buttonBackgroundColor = newTheme{10};
            app.colorMap.Start = newTheme{11};
            app.colorMap.End = newTheme{12};
            figureappearance.changeTheme(app);
        end
        
        %Changes the theme
        function changeTheme(app)
            %Set the background color for the app
            app.UIFigure.Color = app.theme.mainbackgroundColor;
            
            %Set the theme for the bubble main viewer panel and
            %components
            app.MainViewerPanel.BackgroundColor = app.theme.backgroundColor;
            app.MainViewerPanel.ForegroundColor = app.theme.foregroundColor;
            
            app.ViewerTab.BackgroundColor = app.theme.backgroundColor;
            app.EvolutionOverlayTab.BackgroundColor = app.theme.backgroundColor;
            
            app.MainPlot.BackgroundColor = app.theme.backgroundColor;
            app.MainPlot.XColor = app.theme.axisColor;
            app.MainPlot.YColor = app.theme.axisColor;
            app.MainPlot.ZColor = app.theme.axisColor;
            app.MainPlot.GridColor = app.theme.axisColor;
            app.MainPlot.Color = app.theme.plotBackground;
            
            app.AreaLabel.FontColor = app.theme.fontColor;
            app.PerimeterLabel.FontColor = app.theme.fontColor;
            app.AverageRadiusLabel.FontColor = app.theme.fontColor;
            app.CentroidLabel.FontColor = app.theme.fontColor;
            app.Frame1Label.FontColor = app.theme.fontColor;
            app.Frame180Label.FontColor = app.theme.fontColor;
            
            app.FrameNumberSpinner.FontColor = app.theme.fontColor;
            app.FrameNumberSpinner.BackgroundColor = app.theme.textBackgroundColor;
            app.FrameNumberSpinnerLabel.FontColor = app.theme.fontColor;
            
            app.PreviousFrameButton.FontColor = app.theme.fontColor;
            app.PreviousFrameButton.BackgroundColor = app.theme.buttonBackgroundColor;
            
            app.NextFrameButton.FontColor = app.theme.fontColor;
            app.NextFrameButton.BackgroundColor = app.theme.buttonBackgroundColor;
            
            %Set the theme for the mask preview panel
            app.MaskOverlayPreviewPanel.BackgroundColor = app.theme.backgroundColor;
            app.MaskOverlayPreviewPanel.ForegroundColor = app.theme.foregroundColor;
            
            %Set the theme for the control panel and components
            app.ControlPanel.BackgroundColor = app.theme.backgroundColor;
            app.ControlPanel.ForegroundColor = app.theme.foregroundColor;
            
            %Control Panel Tabs
            app.FileTab.BackgroundColor = app.theme.backgroundColor;
            app.DetectionTab.BackgroundColor = app.theme.backgroundColor;
            app.AnalysisTab.BackgroundColor = app.theme.backgroundColor;
            app.CameraSettingsTab.BackgroundColor = app.theme.backgroundColor;
            app.ThemesTab.BackgroundColor = app.theme.backgroundColor;
            app.IMRTab.BackgroundColor = app.theme.backgroundColor;
            
            %File Tabs
            app.LoadNewVideoButton.FontColor = app.theme.fontColor;
            app.LoadNewVideoButton.BackgroundColor = app.theme.buttonBackgroundColor;
            
            app.VideoPath.FontColor = app.theme.fontColor;
            app.VideoPath.BackgroundColor = app.theme.textBackgroundColor;
            app.PathEditFieldLabel.FontColor = app.theme.fontColor;
            
            app.SaveDataButton.FontColor = app.theme.fontColor;
            app.SaveDataButton.BackgroundColor = app.theme.buttonBackgroundColor;
            
            app.SavePath.FontColor = app.theme.fontColor;
            app.SavePath.BackgroundColor = app.theme.textBackgroundColor;
            
            app.LoadDataButton.FontColor = app.theme.fontColor;
            app.LoadDataButton.BackgroundColor = app.theme.buttonBackgroundColor;
            
            app.LoadPath.FontColor = app.theme.fontColor;
            app.LoadPath.BackgroundColor = app.theme.textBackgroundColor;
            
            %Detection Tab
            app.IgnoreFirstFrameCheckBox.FontColor = app.theme.fontColor;
            app.MultibubbleAnalysisCheckBox.FontColor = app.theme.fontColor;
            app.RunDetectionBothWaysCheckBox.FontColor = app.theme.fontColor;
            app.PreProcessFramesCheckBox.FontColor = app.theme.fontColor;
            app.FrameIgnoreWarningCheckBox.FontColor = app.theme.fontColor;
            app.FramePreprocessingMethodButtonGroup.BackgroundColor = app.theme.backgroundColor;
            app.FramePreprocessingMethodButtonGroup.ForegroundColor = app.theme.foregroundColor;
            app.SharpenButton.FontColor = app.theme.fontColor;
            app.SoftenButton.FontColor = app.theme.fontColor;
            app.FilterStrengthSpinner.BackgroundColor = app.theme.backgroundColor;
            app.FilterStrengthSpinner.FontColor = app.theme.fontColor;
            app.FilterStrengthSpinnerLabel.FontColor = app.theme.fontColor;
            app.FilterStrengthSpinnerLabel.BackgroundColor = app.theme.backgroundColor;
            
            %Analysis Tab
            app.MinArcLengthSpinner.FontColor = app.theme.fontColor;
            app.MinArcLengthSpinner.BackgroundColor = app.theme.textBackgroundColor;
            app.MinArcLengthSpinnerLabel.FontColor = app.theme.fontColor;
            
            app.FitFourierSeriestoPointsCheckBox.FontColor = app.theme.fontColor;
            
            app.NumberofTermsinFitButtonGroup.ForegroundColor = app.theme.foregroundColor;
            app.NumberofTermsinFitButtonGroup.BackgroundColor = app.theme.backgroundColor;
            app.FixedButton.FontColor = app.theme.fontColor;
            app.ArcLengthdependentButton.FontColor = app.theme.fontColor;
            app.MaxNumberofTermsEditField.FontColor = app.theme.fontColor;
            app.MaxNumberofTermsEditField.BackgroundColor = app.theme.backgroundColor;
            app.MaxNumberofTermsEditFieldLabel.BackgroundColor = app.theme.backgroundColor;
            app.MaxNumberofTermsEditFieldLabel.FontColor = app.theme.fontColor;
            app.TermstoPlotEditField.FontColor = app.theme.fontColor;
            app.TermstoPlotEditField.BackgroundColor = app.theme.backgroundColor;
            app.TermstoPlotEditFieldLabel.BackgroundColor = app.theme.backgroundColor;
            app.TermstoPlotEditFieldLabel.FontColor = app.theme.fontColor;
            
            %Camera Settings Tab
            app.MicronPixelEditField.FontColor = app.theme.fontColor;
            app.MicronPixelEditField.BackgroundColor = app.theme.backgroundColor;
            app.MicronPixelEditFieldLabel.FontColor = app.theme.fontColor;
            app.FPSEditField.FontColor = app.theme.fontColor;
            app.FPSEditField.BackgroundColor = app.theme.backgroundColor;
            app.FPSEditFieldLabel.FontColor = app.theme.fontColor;
            app.PlotAxesSettingsButtonGroup.ForegroundColor = app.theme.foregroundColor;
            app.PlotAxesSettingsButtonGroup.BackgroundColor = app.theme.backgroundColor;
            app.PxFrameButton.FontColor = app.theme.fontColor;
            app.MicronSecondsButton.FontColor = app.theme.fontColor;
            app.UpdateButton.BackgroundColor = app.theme.buttonBackgroundColor;
            app.UpdateButton.FontColor = app.theme.foregroundColor;
            
            %IMR Tab
            app.ExportDataDirectlytoIMRButton.FontColor = app.theme.fontColor;
            app.ExportDataDirectlytoIMRButton.BackgroundColor = app.theme.buttonBackgroundColor;
            app.NumberFourierTermstoExportEditField.FontColor = app.theme.fontColor;
            app.NumberFourierTermstoExportEditField.BackgroundColor = app.theme.backgroundColor;
            app.NumberFourierTermstoExportEditFieldLabel.BackgroundColor = app.theme.backgroundColor;
            app.NumberFourierTermstoExportEditFieldLabel.FontColor = app.theme.fontColor;
            app.SaveIMRDatatoFileButton.BackgroundColor = app.theme.buttonBackgroundColor;
            app.SaveIMRDatatoFileButton.FontColor = app.theme.fontColor;
            app.CompileMultipleIMRDataSetsButton.BackgroundColor = app.theme.buttonBackgroundColor;
            app.CompileMultipleIMRDataSetsButton.FontColor = app.theme.fontColor;
            app.IncludeCurrentAnalysisCheckBox.FontColor = app.theme.fontColor;
            
            %Themes Tab
            app.OptionsButtonGroup.ForegroundColor = app.theme.foregroundColor;
            app.OptionsButtonGroup.BackgroundColor = app.theme.backgroundColor;
            app.DefaultButton.FontColor = app.theme.fontColor;
            app.NightButton.FontColor = app.theme.fontColor;
            app.DarkButton.FontColor = app.theme.fontColor;
            app.ArmyButton.FontColor = app.theme.fontColor;
            app.ApplyButton.FontColor = app.theme.fontColor;
            app.LeatherButton.FontColor = app.theme.fontColor;
            app.WavesButton.FontColor = app.theme.fontColor;
            app.CustomButton.FontColor = app.theme.fontColor;
            app.ApplyButton.BackgroundColor = app.theme.buttonBackgroundColor;
            
            %Control Panel Buttons
            app.BeginBubbleAnalysisButton.FontColor = app.theme.fontColor;
            app.BeginBubbleAnalysisButton.BackgroundColor = app.theme.buttonBackgroundColor;
            
            app.BeginBubbleDetectionButton.FontColor = app.theme.fontColor;
            app.BeginBubbleDetectionButton.BackgroundColor = app.theme.buttonBackgroundColor;
            
            app.RePlotFourierDataButton.FontColor = app.theme.fontColor;
            app.RePlotFourierDataButton.BackgroundColor = app.theme.buttonBackgroundColor;
            
            app.ExporttoExcelButton.FontColor = app.theme.fontColor;
            app.ExporttoExcelButton.BackgroundColor = app.theme.buttonBackgroundColor;
            
            %Set theme for bubble statistics panel and components
            app.AnalysisResultsPanel.ForegroundColor = app.theme.foregroundColor;
            app.AnalysisResultsPanel.BackgroundColor = app.theme.backgroundColor;
            
            app.OverviewTab.BackgroundColor = app.theme.backgroundColor;
            
            app.AverageRadiusPanel.BackgroundColor = app.theme.backgroundColor;
            app.AverageRadiusPanel.ForegroundColor = app.theme.foregroundColor;
            
            app.RadiusPlot.BackgroundColor = app.theme.backgroundColor;
            app.RadiusPlot.XColor = app.theme.axisColor;
            app.RadiusPlot.YColor = app.theme.axisColor;
            app.RadiusPlot.ZColor = app.theme.axisColor;
            app.RadiusPlot.GridColor = app.theme.axisColor;
            app.RadiusPlot.Color = app.theme.plotBackground;
            
            app.AreaandPerimeterPanel.BackgroundColor = app.theme.backgroundColor;
            app.AreaandPerimeterPanel.ForegroundColor = app.theme.foregroundColor;
            
            app.TwoDimensionalPlot.BackgroundColor = app.theme.backgroundColor;
            app.TwoDimensionalPlot.XColor = app.theme.axisColor;
            app.TwoDimensionalPlot.ZColor = app.theme.axisColor;
            app.TwoDimensionalPlot.GridColor = app.theme.axisColor;
            app.TwoDimensionalPlot.Color = app.theme.plotBackground;
            
            app.SurfaceAreaandVolumePanel.BackgroundColor = app.theme.backgroundColor;
            app.SurfaceAreaandVolumePanel.ForegroundColor = app.theme.foregroundColor;
            
            app.ThreeDimensionalPlot.BackgroundColor = app.theme.backgroundColor;
            app.ThreeDimensionalPlot.XColor = app.theme.axisColor;
            app.ThreeDimensionalPlot.ZColor = app.theme.axisColor;
            app.ThreeDimensionalPlot.GridColor = app.theme.axisColor;
            app.ThreeDimensionalPlot.Color = app.theme.plotBackground;
            
            app.CentroidTab.BackgroundColor = app.theme.backgroundColor;
            
            app.CentroidPlot.BackgroundColor = app.theme.backgroundColor;
            app.CentroidPlot.XColor = app.theme.axisColor;
            app.CentroidPlot.YColor = app.theme.axisColor;
            app.CentroidPlot.ZColor = app.theme.axisColor;
            app.CentroidPlot.GridColor = app.theme.axisColor;
            app.CentroidPlot.Color = app.theme.plotBackground;
            
            app.FourierFitDataTab.BackgroundColor = app.theme.backgroundColor;
            
            app.ndTermLabel.BackgroundColor = app.theme.backgroundColor;
            app.ndTermLabel.FontColor = app.theme.fontColor;
            app.LastTermLabel.BackgroundColor = app.theme.backgroundColor;
            app.LastTermLabel.FontColor = app.theme.fontColor;
            
            app.FourierDecompositionTab.BackgroundColor = app.theme.backgroundColor;
            
            app.DecompositionSettingsPanel.BackgroundColor = app.theme.backgroundColor;
            app.DecompositionSettingsPanel.ForegroundColor = app.theme.foregroundColor;
            
            app.TargetFrameEditField.BackgroundColor = app.theme.backgroundColor;
            app.TargetFrameEditField.FontColor = app.theme.fontColor;
            app.TargetFrameEditFieldLabel.BackgroundColor = app.theme.backgroundColor;
            app.TargetFrameEditFieldLabel.FontColor = app.theme.fontColor;
            
            app.TermstoDecomposeEditField.BackgroundColor = app.theme.backgroundColor;
            app.TermstoDecomposeEditField.FontColor = app.theme.fontColor;
            app.TermstoDecomposeEditFieldLabel.BackgroundColor = app.theme.backgroundColor;
            app.TermstoDecomposeEditFieldLabel.FontColor = app.theme.fontColor;
            
            app.SortOrderButtonGroup.BackgroundColor = app.theme.backgroundColor;
            app.SortOrderButtonGroup.ForegroundColor = app.theme.foregroundColor;
            app.AscendingButton.FontColor = app.theme.fontColor;
            app.DescendingButton.FontColor = app.theme.fontColor;
            app.MaintainColormapCheckBox.FontColor = app.theme.fontColor;
            
            app.DecomposeButton.BackgroundColor = app.theme.backgroundColor;
            app.DecomposeButton.FontColor = app.theme.fontColor;
            
            app.DecomposedPlotsPanel.BackgroundColor = app.theme.backgroundColor;
            app.DecomposedPlotsPanel.ForegroundColor = app.theme.foregroundColor;
            
            plotting.plotData(app, app.radius, app.area, app.perimeter, app.surfaceArea, app.volume, app.centroid);
            plotting.displayCurrentFrame(app);
        end
        
    end
end