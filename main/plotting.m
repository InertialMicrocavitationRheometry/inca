classdef plotting
    methods (Static)
        
        %Generates the converted plot set
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
        
        %Generates the data for the main overview and centroid plots
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
        
        %Generates data for a normalized radius plot
        function normalizedRadius = noramlizedRadiusPlot(info, numFrames, ignoreFrames)
            rawRadius = zeros(1, numFrames);
            parfor i = 1:numFrames
                if isempty(find(ignoreFrames == i, 1))
                    xFit = info(i).FourierFitX;
                    yFit = info(i).FourierFitY;
                    rawRadius(i) = sqrt(xFit.a1^2 + yFit.b1^2);
                else
                    rawRadius(i) = NaN;
                end
            end
            normalizedRadius = rawRadius./max(rawRadius);
        end
        
        %Generates the data for the asphericity plot
        function output = fourierFitPlot(maskInformation, numberTerms, numFrames, ignoreFrames)
            output = zeros(numFrames, numberTerms - 1);
            for i = 1:numFrames
                if isempty(find(ignoreFrames == i, 1))
                    xFit = maskInformation(i).FourierFitX;
                    yFit = maskInformation(i).FourierFitY;
                    
                    xnames = coeffnames(xFit);
                    xvals = coeffvalues(xFit);
                    
                    ynames = coeffnames(yFit);
                    yvals = coeffvalues(yFit);
                    
                    parfor j = 2:numberTerms
                        targetCoeffX = "a" + num2str(j);
                        targetCoeffY = "b" + num2str(j);
                        
                        xCoeffVal = xvals(xnames == targetCoeffX);
                        yCoeffVal = yvals(ynames == targetCoeffY);
                        
                        output(i, j - 1) = sqrt(xCoeffVal.^2 + yCoeffVal.^2)./sqrt(xFit.a1.^2 + yFit.b1.^2);
                    end
                else
                    output(i ,:) = NaN;
                end
            end
        end
        
        %Changes axes titles to frame/px or micron/second
        function changeAxesTitles(app, titleType)
            switch titleType
                case 'pixels'
                    %Update the average radius plot labels
                    app.RadiusPlot.XLabel.String = "Frame";
                    app.RadiusPlot.YLabel.String = "Pixels";
                    
                    %Update the area and perimeter plot labels
                    app.TwoDimensionalPlot.XLabel.String = "Frame";
                    yyaxis(app.TwoDimensionalPlot, 'left');
                    app.TwoDimensionalPlot.YLabel.String = "Area (Square Pixels)";
                    yyaxis(app.TwoDimensionalPlot, 'right');
                    app.TwoDimensionalPlot.YLabel.String = "Perimeter (Pixels)";
                    
                    %Update the surface area and volume labels
                    app.ThreeDimensionalPlot.XLabel.String = "Frame";
                    yyaxis(app.ThreeDimensionalPlot, 'left');
                    app.ThreeDimensionalPlot.YLabel.String = "Surface Area (Square Pixels)";
                    yyaxis(app.ThreeDimensionalPlot, 'right');
                    app.ThreeDimensionalPlot.YLabel.String = "Volume (Cubic Pixels)";
                    
                    %Update the asphericity plot
                    app.AsphericityPlot.XLabel.String = "Frame";
                case 'microns'
                    
                    %Update the average radius plot labels
                    app.RadiusPlot.XLabel.String = "Seconds";
                    app.RadiusPlot.YLabel.String = "Microns";
                    
                    %Update the area and perimeter plot labels
                    app.TwoDimensionalPlot.XLabel.String = "Seconds";
                    yyaxis(app.TwoDimensionalPlot, 'left');
                    app.TwoDimensionalPlot.YLabel.String = "Area (Square Microns)";
                    yyaxis(app.TwoDimensionalPlot, 'right');
                    app.TwoDimensionalPlot.YLabel.String = "Perimeter (Microns)";
                    
                    %Update the surface area and volume labels
                    app.ThreeDimensionalPlot.XLabel.String = "Seconds";
                    yyaxis(app.ThreeDimensionalPlot, 'left');
                    app.ThreeDimensionalPlot.YLabel.String = "Surface Area (Square Microns)";
                    yyaxis(app.ThreeDimensionalPlot, 'right');
                    app.ThreeDimensionalPlot.YLabel.String = "Volume (Cubic Microns)";
                    
                    app.AsphericityPlot.XLabel.String = "Seconds";
            end
        end
        
        %Plots the Fourier Asphericity
        function plotFourier(app)
            yyaxis(app.AsphericityPlot, "left");
            cla(app.AsphericityPlot);
            yyaxis(app.AsphericityPlot, "right");
            cla(app.AsphericityPlot);
            app.AsphericityPlot.XLim = [1, app.numFrames];
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
                points = plotting.fourierFitPlot(app.maskInformation, app.TermstoPlotEditField.Value, app.numFrames, app.ignoreFrames);
                
                yyaxis(app.AsphericityPlot, 'left');
                
                plot(app.AsphericityPlot, 1:app.numFrames, points(:, 1),"Color", cmap(1, :), "LineStyle","-", "Marker", "none");
                
                app.AsphericityPlot.YColor = cmap(end - 1, :);
                
                hold(app.AsphericityPlot, 'on');
                
                for d = 2:(app.TermstoPlotEditField.Value - 1)
                    plot(app.AsphericityPlot, 1:app.numFrames, points(:, d),"Color", cmap(d, :), "LineStyle","-", "Marker", "none");
                    
                end
                hold(app.AsphericityPlot, 'off');
                
                normalizedRadius = plotting.noramlizedRadiusPlot(app.maskInformation, app.numFrames, app.ignoreFrames);
                
                yyaxis(app.AsphericityPlot, 'right');
                ylabel(app.AsphericityPlot, "R/Rmax");
                app.AsphericityPlot.YColor = app.theme.axisColor;
                
                r = plot(app.AsphericityPlot, 1:app.numFrames, normalizedRadius, "LineStyle", "-", "Marker", "none", "Color", [1, 1, 1]);
                
                legend(app.AsphericityPlot, r, "R/max(R)", "TextColor", [1, 1 ,1]);
                
            end
        end
        
        %Plots the Fourier Asphericity in alternate axes
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
                points = plotting.fourierFitPlot(app.maskInformation, app.TermstoPlotEditField.Value, app.numFrames, app.ignoreFrames);
                
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
        
        %Generates the Fourier Decomposition Data
        function output = fourierDecomposition(info, targetFrame, numTerms, sortOrder)
            output = cell((numTerms - 1), 2);
            xFit = info(targetFrame).FourierFitX;
            yFit = info(targetFrame).FourierFitY;
            xnames = coeffnames(xFit);
            ynames = coeffnames(yFit);
            xvals = coeffvalues(xFit);
            yvals = coeffvalues(yFit);
            asphericity = zeros(1, (numTerms - 1));
            parfor i = 2:numTerms
                targetCoeffX = "a" + num2str(i);
                targetCoeffY = "b" + num2str(i);
                
                xCoeffVal = xvals(xnames == targetCoeffX);
                yCoeffVal = yvals(ynames == targetCoeffY);
                
                asphericity(i - 1) = sqrt(xCoeffVal.^2 + yCoeffVal.^2)./sqrt(xFit.a1.^2 + yFit.b1.^2);
            end
            switch sortOrder
                case "ascending"
                    for j = 2:numTerms
                        
                        [~, cmapIdx] = min(asphericity);    %Get the index of the term with the smallest asphericity
                        output{j - 1, 2} = cmapIdx + 1;     %Assign it to the second column in the output cell array (will be used for colormaping)
                        t = transpose(0:0.01:2*pi);         %Set up the input vector
                        
                        xCoeffVal = xvals(xnames == "a" + num2str(cmapIdx));     %Get the x coefficient for the target term
                        yCoeffVal = yvals(ynames == "b" + num2str(cmapIdx));     %Get the y coefficient for the target term
                        
                        xEq = xFit.a0 + xFit.a1*cos(t) + xCoeffVal*cos(cmapIdx*t);      %Calculate the new x values
                        yEq = yFit.b0 + yFit.b1*sin(t) + yCoeffVal*sin(cmapIdx*t);      %Calculate the new y values
                        
                        points = [xEq, yEq];            %Concatenate the vectors together
                        output{j - 1, 1} = points;      %Assign to the output variable
                        
                        asphericity(cmapIdx) = NaN;     %Replace the highest valued term with NaN
                    end
                case "descending"
                    for j = 2:numTerms
                        
                        [~, cmapIdx] = max(asphericity);    %Get the index of the term with the largest asphericity
                        output{j - 1, 2} = cmapIdx + 1;     %Assign it to the second column in the output cell array (will be used for colormaping)
                        t = transpose(0:0.01:2*pi);         %Set up the input vector
                        
                        xCoeffVal = xvals(xnames == "a" + num2str(cmapIdx));     %Get the x coefficient for the target term
                        yCoeffVal = yvals(ynames == "b" + num2str(cmapIdx));     %Get the y coefficient for the target term
                        
                        xEq = xFit.a0 + xFit.a1*cos(t) + xCoeffVal*cos(cmapIdx*t);      %Calculate the new x values
                        yEq = yFit.b0 + yFit.b1*sin(t) + yCoeffVal*sin(cmapIdx*t);      %Calculate the new y values
                        
                        points = [xEq, yEq];            %Concatenate the vectors together
                        output{j - 1, 1} = points;      %Assign to the output variable
                        
                        asphericity(cmapIdx) = NaN;     %Replace the highest valued term with NaN
                    end
            end
        end
        
        %Plots the Fourier Decomposition
        function plotFourierDecomp(app, points)
            [row, ~] = size(points);
            cmap = viridis(row);
            panelPos = app.DecomposedPlotsPanel.Position;
            for i = 1:row
                axishandle = uiaxes(app.DecomposedPlotsPanel, "Position", [(10 + (i - 1)*(panelPos(3) - 20)), 25, panelPos(3) - 20, panelPos(4) - 60], "DataAspectRatio", [1, 1, 1],"PlotBoxAspectRatio", [1,0.8062157221206582,0.8062157221206582], ...
                    "BackgroundColor", app.theme.backgroundColor, "XColor", app.theme.axisColor, "YColor", app.theme.axisColor, "ZColor", app.theme.axisColor, ...
                    "Color", app.theme.plotBackground);
                axishandle.Title.String = "";
                if app.MaintainColormapCheckBox.Value
                    dataPoints = [points{i, 1}];
                    plot(axishandle, dataPoints(:,1), dataPoints(:, 2), "Color", cmap(points{i, 2} - 1, :), "DisplayName", "Term " + num2str(points{i, 2}));
                    legend(axishandle, "Color", app.theme.fontColor);
                else
                    dataPoints = points{i, 1};
                    plot(axishandle, dataPoints(:,1), dataPoints(:, 2), "Color", cmap(i, :), "DisplayName", "Term " + num2str(points{i, 2}));
                    legend(axishandle, "Color", app.theme.fontColor);
                end
            end
            axishandle = uiaxes(app.DecomposedPlotsPanel, "Position", [(10 + (row)*(panelPos(3) - 20)), 25, (panelPos(3) - 20), panelPos(4) - 60], "DataAspectRatio", [1, 1, 1], "PlotBoxAspectRatio", [1,0.8062157221206582,0.8062157221206582],...
                "BackgroundColor", app.theme.backgroundColor, "XColor", app.theme.axisColor, "YColor", app.theme.axisColor, "ZColor", app.theme.axisColor, ...
                "Color", app.theme.plotBackground);
            axishandle.Title.String = "";
            hold(axishandle, 'on');
            for j = 1:row
                if app.MaintainColormapCheckBox.Value
                    dataPoints = [points{j, 1}];
                    plot(axishandle, dataPoints(:,1), dataPoints(:, 2), "Color", cmap(points{j, 2} - 1, :), "DisplayName", "Term " + num2str(points{j, 2}));
                    legend(axishandle, "Color", app.theme.fontColor);
                else
                    dataPoints = points{j, 1};
                    plot(axishandle, dataPoints(:,1), dataPoints(:, 2), "Color", cmap(j, :), "DisplayName", "Term " + num2str(points{j, 2}));
                    legend(axishandle, "Color", app.theme.fontColor);
                end
            end
            hold(axishandle, 'off');
        end
        
        %Plot the Data in the Overview and Centroid Tabs
        function plotData(app, radius, area, perimeter, surfaceArea, volume, centroid)
            if ~isempty(radius)
                %Radius Plot
                app.RadiusPlot.XLim = [1, app.numFrames];
                plot(app.RadiusPlot, 1:app.numFrames, radius ,"--.");
                hold(app.RadiusPlot, 'on');
                plot(app.RadiusPlot, app.currentFrame, radius(app.currentFrame), '*', 'Color', app.theme.markerStyle, 'MarkerSize', 10);
                hold(app.RadiusPlot, 'off');
                
                %Area and Perimeter Plot
                app.TwoDimensionalPlot.XLim = [1, app.numFrames];
                yyaxis(app.TwoDimensionalPlot, 'left');
                plot(app.TwoDimensionalPlot, 1:app.numFrames, area, '--.');
                hold(app.TwoDimensionalPlot, 'on');
                plot(app.TwoDimensionalPlot, app.currentFrame, area(app.currentFrame), '*', 'Color', app.theme.markerStyle, 'MarkerSize', 10);
                hold(app.TwoDimensionalPlot, 'off');
                yyaxis(app.TwoDimensionalPlot, 'right');
                plot(app.TwoDimensionalPlot, 1:app.numFrames, perimeter,'--.');
                hold(app.TwoDimensionalPlot, 'on');
                plot(app.TwoDimensionalPlot, app.currentFrame, perimeter(app.currentFrame), '*', 'Color', app.theme.markerStyle, 'MarkerSize', 10);
                hold(app.TwoDimensionalPlot, 'off');
                
                %Surface Area and Volume Plots
                app.ThreeDimensionalPlot.XLim = [1, app.numFrames];
                yyaxis(app.ThreeDimensionalPlot, 'left');
                plot(app.ThreeDimensionalPlot, 1:app.numFrames, surfaceArea, '--.');
                hold(app.ThreeDimensionalPlot, 'on');
                plot(app.ThreeDimensionalPlot, app.currentFrame, surfaceArea(app.currentFrame), '*', 'Color', app.theme.markerStyle, 'MarkerSize', 10);
                hold(app.ThreeDimensionalPlot, 'off');
                yyaxis(app.ThreeDimensionalPlot, 'right');
                plot(app.ThreeDimensionalPlot, 1:app.numFrames, volume, '--.');
                hold(app.ThreeDimensionalPlot, 'on');
                plot(app.ThreeDimensionalPlot, app.currentFrame, volume(app.currentFrame), '*', 'Color', app.theme.markerStyle, 'MarkerSize', 10);
                hold(app.ThreeDimensionalPlot, 'off');
                
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
        
        %Plot the Data in the Overview and Centroid Tabs in the alternate
        %axes
        function plotConvertedData(app)
            
            if ~isempty(app.radius)
                %Radius Plot
                app.RadiusPlot.XLim = [app.convertedPlotSet.TimeVector(1), app.convertedPlotSet.TimeVector(end)];
                plot(app.RadiusPlot, app.convertedPlotSet.TimeVector, app.convertedPlotSet.AverageRadius ,"--.");
                hold(app.RadiusPlot, 'on');
                plot(app.RadiusPlot, app.convertedPlotSet.TimeVector(app.currentFrame), app.convertedPlotSet.AverageRadius(app.currentFrame), '*', 'Color', app.theme.markerStyle, 'MarkerSize', 10);
                hold(app.RadiusPlot, 'off');
                
                %Area and Perimeter Plot
                app.TwoDimensionalPlot.XLim = [app.convertedPlotSet.TimeVector(1), app.convertedPlotSet.TimeVector(end)];
                yyaxis(app.TwoDimensionalPlot, 'left');
                plot(app.TwoDimensionalPlot, app.convertedPlotSet.TimeVector, app.convertedPlotSet.Area, '--.');
                hold(app.TwoDimensionalPlot, 'on');
                plot(app.TwoDimensionalPlot, app.convertedPlotSet.TimeVector(app.currentFrame), app.convertedPlotSet.Area(app.currentFrame), '*', 'Color', app.theme.markerStyle, 'MarkerSize', 10);
                hold(app.TwoDimensionalPlot, 'off');
                yyaxis(app.TwoDimensionalPlot, 'right');
                plot(app.TwoDimensionalPlot, app.convertedPlotSet.TimeVector, app.convertedPlotSet.Perimeter,'--.');
                hold(app.TwoDimensionalPlot, 'on');
                plot(app.TwoDimensionalPlot, app.convertedPlotSet.TimeVector(app.currentFrame), app.convertedPlotSet.Perimeter(app.currentFrame), '*', 'Color', app.theme.markerStyle, 'MarkerSize', 10);
                hold(app.TwoDimensionalPlot, 'off');
                
                %Surface Area and Volume Plots
                app.ThreeDimensionalPlot.XLim = [app.convertedPlotSet.TimeVector(1), app.convertedPlotSet.TimeVector(end)];
                yyaxis(app.ThreeDimensionalPlot, 'left');
                plot(app.ThreeDimensionalPlot, app.convertedPlotSet.TimeVector, app.convertedPlotSet.SurfaceArea, '--.');
                hold(app.ThreeDimensionalPlot, 'on');
                plot(app.ThreeDimensionalPlot, app.convertedPlotSet.TimeVector(app.currentFrame), app.convertedPlotSet.SurfaceArea(app.currentFrame), '*', 'Color', app.theme.markerStyle, 'MarkerSize', 10);
                hold(app.ThreeDimensionalPlot, 'off');
                yyaxis(app.ThreeDimensionalPlot, 'right');
                plot(app.ThreeDimensionalPlot, app.convertedPlotSet.TimeVector, app.convertedPlotSet.Volume, '--.');
                hold(app.ThreeDimensionalPlot, 'on');
                plot(app.ThreeDimensionalPlot, app.convertedPlotSet.TimeVector(app.currentFrame), app.convertedPlotSet.Volume(app.currentFrame), '*', 'Color', app.theme.markerStyle, 'MarkerSize', 10);
                hold(app.ThreeDimensionalPlot, 'off');
                
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
        
        %Display the current frame and the overlays in the main viewer
        function displayCurrentFrame(app)
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
                    
                    legend(app.MainPlot);
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
        
        %Display the perimeter evolution overlay
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

    end
end