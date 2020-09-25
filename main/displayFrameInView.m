function displayFrameInView(app)
if ~isempty(app.maskInformation)
    if ~isempty(find(app.ignoreFrames == app.currentFrame, 1))
        imshow(app.frames(:, :, app.currentFrame), 'Parent', app.MainPlot);
        app.FrameNumberSpinner.Value = app.currentFrame;
        app.AreaLabel.Text = "Area: " + num2str(app.maskInformation(app.currentFrame).Area);
        app.PerimeterLabel.Text = "Perimeter: " + num2str(app.maskInformation(app.currentFrame).Perimeter);
        app.AverageRadiusLabel.Text = "Average Radius: " + num2str(app.maskInformation(app.currentFrame).AverageRadius);
        app.CentroidLabel.Text = "Centroid " + num2str(app.maskInformation(app.currentFrame).Centroid);
    else
        %Update the main viewer window
        imshow(app.frames(:, :, app.currentFrame), 'Parent', app.MainPlot);
        hold(app.MainPlot, 'on');
        perimeterPoints = app.maskInformation(app.currentFrame).PerimeterPoints;
        X = perimeterPoints(:, 1);
        Y = perimeterPoints(:, 2);
        plot(app.MainPlot, X, Y, 'LineWidth', 3, 'Color', 'r' , "DisplayName", "Mask Boundary");
        center = app.maskInformation(app.currentFrame).Centroid;
        X = center(1);
        Y = center(2);
        plot(app.MainPlot, X, Y, '-b*', 'MarkerSize', 20, 'LineWidth', 2, "DisplayName", "Centroid");
        tracking = app.maskInformation(app.currentFrame).TrackingPoints;
        X = tracking(:, 1);
        Y = tracking(:, 2);
        plot(app.MainPlot, X, Y, ':y*', 'MarkerSize', 10, "DisplayName", "Tracking Points");
        
        if app.FitFourierSeriestoPointsCheckBox.Value
            fourier = app.maskInformation(app.currentFrame).FourierPoints;
            X = fourier(:, 1);
            Y = fourier(:, 2);
            plot(app.MainPlot, X, Y, ':c.', "DisplayName", "Fourier Fit Points");
            plot(app.MainPlot, app.maskInformation(app.currentFrame).xData, app.maskInformation(app.currentFrame).yData, '-m', 'DisplayName', 'FourierFit');
            plot(app.MainPlot, app.maskInformation(app.currentFrame).FourierFitX.a0, app.maskInformation(app.currentFrame).FourierFitY.b0, '-g*', 'MarkerSize', 15, "DisplayName", 'Fourier Fit Centroid')
        end
        
        l = legend(app.MainPlot);
        l.Color = app.theme.fontColor;
        hold(app.MainPlot, 'off');
        
        %Update labels
        app.FrameNumberSpinner.Value = app.currentFrame;
        app.AreaLabel.Text = "Area: " + num2str(app.maskInformation(app.currentFrame).Area);
        app.PerimeterLabel.Text = "Perimeter: " + num2str(app.maskInformation(app.currentFrame).Perimeter);
        app.AverageRadiusLabel.Text = "Average Radius: " + num2str(app.maskInformation(app.currentFrame).AverageRadius);
        app.CentroidLabel.Text = "Centroid " + num2str(app.maskInformation(app.currentFrame).Centroid);
    end
end
end
