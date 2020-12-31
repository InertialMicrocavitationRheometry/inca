classdef plotting
    methods (Static)
        
        %Generates the converted plot set
        function convertedPlotSet = convertUnits(app)
            
            %Convert frames to seconds
            frameInterval = 1/app.FPSField.Value;
            convertedPlotSet.TimeVector = 0:frameInterval:(app.numFrames - 1)*frameInterval;
            
            %Convert the basic analysis things to microns from pixels
            convertedPlotSet.AverageRadius = app.radius.*app.MicronPxField.Value;
            convertedPlotSet.Area = app.area.*(app.MicronPxField.Value).^2;
            convertedPlotSet.Perimeter = app.perimeter.*app.MicronPxField.Value;
            convertedPlotSet.SurfaceArea = app.surfaceArea.*(app.MicronPxField.Value).^2;
            convertedPlotSet.Volume = app.volume.*(app.MicronPxField.Value).^3;
            convertedPlotSet.Centroid = app.centroid.*app.MicronPxField.Value;
            
        end
        
        %Generates the data for the main overview and centroid plots
        function [radius, area, perimeter, surfaceArea, volume, centroid, velocity] = generatePlotData(app)
            
            info = app.maskInformation;
            if isempty(info)
                return;
            end
            numFrames = app.numFrames;
            
            %Set up the output variables
            radius = zeros(numFrames, 1);
            area = zeros(numFrames, 1);
            perimeter = zeros(numFrames, 1);
            surfaceArea = zeros(numFrames, 1);
            volume = zeros(numFrames, 1);
            velocity = zeros(numFrames, 6);
            centroid = zeros(numFrames, 2);
            velocity(:, 1) = 0.5:(numFrames - 0.5);
            for i = 1:numFrames
                
                if isempty(info(i))
                    continue;
                end
                
                if ~isempty(info(i).AverageRadius)
                    radius(i) = info(i).AverageRadius;
                else 
                    radius(i) = NaN;
                end
                
                if ~isempty(info(i).Area)
                    area(i) = info(i).Area;
                else
                    area(i) = NaN;
                end
                
                if ~isempty(info(i).Perimeter)
                    perimeter(i) = info(i).Perimeter;
                else
                    perimeter(i) = NaN;
                end
                
                if ~isempty(info(i).SurfaceArea)
                    surfaceArea(i) = info(i).SurfaceArea;
                else 
                    surfaceArea(i) = NaN;
                end
                
                if ~isempty(info(i).Volume)
                    volume(i) = info(i).Volume;
                else 
                    volume(i) = NaN;
                end
                
                if ~isempty(info(i).Centroid)
                    centroid(i, :) = info(i).Centroid;
                else
                    centroid(i) = [NaN, NaN];
                end
                
                if ~isempty(info(i).PerimVelocity)
                    if ~isnan(info(i).PerimVelocity)
                        velocity(i, 2:end) = info(i).PerimVelocity;
                    else
                        velocity(i, 2:end) = [NaN, NaN, NaN, NaN, NaN];
                    end
                end
            end
        end
        
        %Generates data for a normalized radius plot
        function normalizedRadius = noramlizedRadiusPlot(info, numFrames, ignoreFrames, style)
            rawRadius = zeros(1, numFrames);
            switch style
                case "parametric"
                    parfor i = 1:numFrames
                        if isempty(find(ignoreFrames == i, 1))
                            xFit = info(i).perimFit{1};
                            yFit = info(i).perimFit{2};
                            rawRadius(i) = sqrt(xFit.a1^2 + yFit.b1^2);
                        else
                            rawRadius(i) = NaN;
                        end
                    end
                    normalizedRadius = rawRadius./max(rawRadius);
                case "polar (standard)"
                    parfor i = 1:numFrames
                        if isempty(find(ignoreFrames == i, 1))
                            rawRadius(i) = info(i).perimFit.r;
                        else
                            rawRadius(i) = NaN;
                        end
                    end
                    normalizedRadius = rawRadius./max(rawRadius);
                case "polar (phase shift)"
                    parfor i = 1:numFrames
                        if isempty(find(ignoreFrames == i, 1))
                            rawRadius(i) = info(i).perimFit.a0;
                        else
                            rawRadius(i) = NaN;
                        end
                    end
                    normalizedRadius = rawRadius./max(rawRadius);
            end
        end
        
        %Generates the data for the asphericity plot
        function output = fourierFitPlot(maskInformation, numberTerms, numFrames, ignoreFrames, style)
            switch style 
                case "parametric"   
                    output = zeros(numFrames, numberTerms - 1);
                    for i = 1:numFrames
                        if isempty(find(ignoreFrames == i, 1))
                            
                            xFit = maskInformation(i).perimFit{1};
                            yFit = maskInformation(i).perimFit{2};
                            
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
                case "polar (standard)"
                    output = zeros(numFrames, numberTerms);
                    for i = 1:numFrames
                        if isempty(find(ignoreFrames == i, 1))
                            perimFit = maskInformation(i).perimFit;
                            
                            names = coeffnames(perimFit);
                            
                            vals = coeffvalues(perimFit);
                            
                            for j = 1:numberTerms
                                targetCoeffX = "a" + num2str(j);
                                targetCoeffY = "b" + num2str(j);
                                
                                xval = vals(names == targetCoeffX);
                                yval = vals(names == targetCoeffY);
                                
                                output(i, j) = (xval + yval)./perimFit.r;
                            end
                        else 
                            output(i, :) = NaN;
                        end
                    end
                case "polar (phase shift)"
                    output = zeros(numFrames, numberTerms);
                    for i = 1:numFrames
                        if isempty(find(ignoreFrames == i, 1))
                            perimFit = maskInformation(i).perimFit;
                            
                            names = coeffnames(perimFit);
                            
                            vals = coeffvalues(perimFit);
                            
                            for j = 1:numberTerms
                                targetCoeff = "a" + num2str(j);

                                coeffval = vals(names == targetCoeff);
                                
                                output(i, j) = coeffval./perimFit.a0;
                            end
                        else 
                            output(i, :) = NaN;
                        end
                    end
            end
        end
        
        %Changes axes titles to frame/px or micron/second
        function changeAxesTitles(app, titleType)
            switch titleType
                case 'pixels'
                    %Update the average radius plot labels
                    app.RadiusPlot.XLabel.String = "FRAME";
                    app.RadiusPlot.Title.String = "AVERAGE RADIUS (PX/FRAME)";
                    
                    %Update the area and perimeter plot labels
                    app.TwoDimensionalPlot.XLabel.String = "FRAME";
                    app.TwoDimensionalPlot.Title.String = "AREA AND PERIMETER (PX/FRAME)";
                    
                    %Update the surface area and volume labels
                    app.ThreeDimensionalPlot.XLabel.String = "FRAME";
                    app.ThreeDimensionalPlot.Title.String = "SURFACE AREA AND VOLUME (PX/FRAME)";
                    
                    %Update the asphericity plot
                    app.AsphericityPlot.XLabel.String = "FRAME";
                    
                    %Update the velocity plot
                    app.VelocityPlot.XLabel.String = "FRAME";
                    app.VelocityPlot.Title.String = "PERIMETER VELOCITY (PX/FRAME)";
                case 'microns'
                    app.RadiusPlot.XLabel.String = "SECONDS";
                    app.RadiusPlot.Title.String = "AVERAGE RADIUS (MICRON/S)";
                    
                    %Update the area and perimeter plot labels
                    app.TwoDimensionalPlot.XLabel.String = "SECONDS";
                    app.TwoDimensionalPlot.Title.String = "AREA AND PERIMETER (MICRON/S)";
                    
                    %Update the surface area and volume labels
                    app.ThreeDimensionalPlot.XLabel.String = "SECONDS";
                    app.ThreeDimensionalPlot.Title.String = "SURFACE AREA AND VOLUME (MICRON/S)";
                    
                    %Update the asphericity plot
                    app.AsphericityPlot.XLabel.String = "SECONDS";
                    
                    %Update the velocity plot
                    app.VelocityPlot.XLabel.String = "SECONDS";
                    app.VelocityPlot.Title.String = "PERIMETER VELOCITY (MICRON/S)";
            end
        end
        
        %Plots the Fourier Asphericity
        function plotFourier(app)
            yyaxis(app.AsphericityPlot, "left");
            cla(app.AsphericityPlot);
            yyaxis(app.AsphericityPlot, "right");
            cla(app.AsphericityPlot);
            app.AsphericityPlot.XLim = [1, app.numFrames];
            if app.FourierFitToggle.UserData
                %Get the color map set up
                cmap = viridis(app.TermsofInterestField.Value);
                
                %Plot the data points
                points = plotting.fourierFitPlot(app.maskInformation, app.TermsofInterestField.Value, app.numFrames, app.ignoreFrames, lower(string(app.FitType.Value)));
                
                yyaxis(app.AsphericityPlot, 'left');
                
                plot(app.AsphericityPlot, 1:app.numFrames, points(:, 1),"Color", cmap(1, :), "LineStyle","-", "Marker", "none", 'LineWidth', 1.5);
                
                app.AsphericityPlot.YColor = cmap(end - 1, :);
                
                hold(app.AsphericityPlot, 'on');
                [~, col] = size(points);
                for d = 2:col
                    plot(app.AsphericityPlot, 1:app.numFrames, points(:, d),"Color", cmap(d, :), "LineStyle","-", "Marker", "none", 'LineWidth', 1.5);
                end
                hold(app.AsphericityPlot, 'off');
                
                normalizedRadius = plotting.noramlizedRadiusPlot(app.maskInformation, app.numFrames, app.ignoreFrames, lower(string(app.FitType.Value)));
                
                yyaxis(app.AsphericityPlot, 'right');
                ylabel(app.AsphericityPlot, "R/Rmax");
                app.AsphericityPlot.YColor = [1, 1, 1];
                
                r = plot(app.AsphericityPlot, 1:app.numFrames, normalizedRadius, "LineStyle", "-", "Marker", "none", "Color", [1, 1, 1], 'LineWidth', 1.5);
                
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
            if app.FourierFitToggle.UserData
                %Get the color map set up
                cmap = viridis(app.TermsofInterestField.Value - 1);
                
                %Plot the data points
                points = plotting.fourierFitPlot(app.maskInformation, app.TermsofInterestField.Value, app.numFrames, app.ignoreFrames);
                
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
                app.AsphericityPlot.YColor = [0, 0, 0];
                
                r = plot(app.AsphericityPlot, app.convertedPlotSet.TimeVector, normalizedRadius, "LineStyle", "-", "Marker", "none", "Color", [1, 1, 1]);
                
                legend(app.AsphericityPlot, r, "R/max(R)", "TextColor", [1, 1, 1]);
            end
        end
        
        %Generates the Fourier Decomposition Data
        function output = fourierDecomposition(info, targetFrame, numTerms, sortOrder, style)
            switch style
                case "parametric"
                    output = cell((numTerms - 1), 2);
                    xFit = info(targetFrame).perimFit{1};
                    yFit = info(targetFrame).perimFit{2};
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
                                
                                asphericity(cmapIdx) = NaN;     %Replace the lowest valued term with NaN
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
                case "polar (standard)"
                    output = cell(numTerms, 2);
                    fit = info(targetFrame).perimFit;
                    fitcoeffs = coeffnames(fit);
                    fitvals = coeffvalues(fit);
                    asphericity = zeros(1, numTerms);
                    for i = 1:numTerms
                        targetCoeffX = "a" + num2str(i);
                        targetCoeffY = "b" + num2str(i);
                        
                        xCoeffVal = fitvals(fitcoeffs == targetCoeffX);
                        yCoeffVal = fitvals(fitcoeffs == targetCoeffY);
                        
                        asphericity(i) = (xCoeffVal + yCoeffVal)./fit.r;
                    end
                    for j = 1:numTerms
                        [~, cmapIdx] = max(asphericity);                %Get the index of the term with the largest asphericity
                        output{j, 2} = cmapIdx;                         %Assign it to the second column in the output cell array (will be used for colormaping)
                        t = transpose(linspace(0, 2*pi, 1000));         %Set up the input vector
                        
                        xCoeffVal = fitvals(fitcoeffs == "a" + num2str(cmapIdx));     %Get the x coefficient for the target term
                        yCoeffVal = fitvals(fitcoeffs == "b" + num2str(cmapIdx));     %Get the y coefficient for the target term
                        
                        rEq = fit.r + xCoeffVal.*cos(cmapIdx.*t) + yCoeffVal.*sin(cmapIdx.*t);
                        
                        [x, y] = pol2cart(t, rEq);      %Convert to cartesian for plotting
                        
                        points =  [x, y] ;              %Convert to cartesian for plotting
                        output{j, 1} = points;          %Assign to the output variable
                        
                        asphericity(cmapIdx) = NaN;     %Replace the highest valued term with NaN
                    end
                case "polar (phase shift)"
                    output = cell(numTerms, 2);
                    fit = info(targetFrame).perimFit;
                    fitcoeffs = coeffnames(fit);
                    fitvals = coeffvalues(fit);
                    asphericity = zeros(1, numTerms);
                    for i = 1:numTerms
                        targetCoeffX = "a" + num2str(i);
                        
                        xCoeffVal = fitvals(fitcoeffs == targetCoeffX);
                        
                        asphericity(i) = xCoeffVal./fit.a0;
                    end
                    for j = 1:numTerms
                        [~, cmapIdx] = max(asphericity);                %Get the index of the term with the largest asphericity
                        output{j, 2} = cmapIdx;                         %Assign it to the second column in the output cell array (will be used for colormaping)
                        t = transpose(linspace(0, 2*pi, 1000));         %Set up the input vector
                        
                        xCoeffVal = fitvals(fitcoeffs == "a" + num2str(cmapIdx));     %Get the x coefficient for the target term
                        yCoeffVal = fitvals(fitcoeffs == "phi" + num2str(cmapIdx));     %Get the y coefficient for the target term
                        
                        rEq = fit.a0 + xCoeffVal.*cos(cmapIdx.*t + yCoeffVal);
                        
                        [x, y] = pol2cart(t, rEq);      %Convert to cartesian for plotting
                        
                        points =  [x, y] ;              %Convert to cartesian for plotting
                        output{j, 1} = points;          %Assign to the output variable
                        
                        asphericity(cmapIdx) = NaN;     %Replace the highest valued term with NaN
                    end
            end
        end
        
        %Plots the Fourier Decomposition
        function plotFourierDecomp(app, points)
            [row, ~] = size(points);
            cmap = viridis(row);
            panelPos = app.DecomposedPlotsPanel.Position;
            for h = 1:row
                vals(h) = points{h, 2};
            end
            if max(vals) > row
                for i = 1:row
                    axishandle = uiaxes(app.DecomposedPlotsPanel, "Position", [(10 + (i - 1)*(panelPos(3) - 20)), 25, panelPos(3) - 20, panelPos(4) - 60], "DataAspectRatio", [1, 1, 1],"PlotBoxAspectRatio", [1,0.8062157221206582,0.8062157221206582], ...
                        "BackgroundColor", [0 0 0], "XColor", [1 1 1], "YColor", [1 1 1], "ZColor", [1 1 1], "Color", [0 0 0]);
                    axishandle.Title.String = "";
                    dataPoints = [points{i, 1}];
                    plot(axishandle, dataPoints(:,1), dataPoints(:, 2), "Color", cmap(points{i, 2} - 1, :), "DisplayName", "Term " + num2str(points{i, 2}));
                    legend(axishandle, "Color", [1 1 1]);
                end
                axishandle = uiaxes(app.DecomposedPlotsPanel, "Position", [(10 + (row)*(panelPos(3) - 20)), 25, (panelPos(3) - 20), panelPos(4) - 60], "DataAspectRatio", [1, 1, 1], "PlotBoxAspectRatio", [1,0.8062157221206582,0.8062157221206582],...
                    "BackgroundColor", [0 0 0], "XColor", [1 1 1], "YColor", [1 1 1], "ZColor", [1 1 1], ...
                    "Color", [0 0 0]);
                axishandle.Title.String = "";
                hold(axishandle, 'on');
                for j = 1:row
                    dataPoints = [points{j, 1}];
                    plot(axishandle, dataPoints(:,1), dataPoints(:, 2), "Color", cmap(points{j, 2} - 1, :), "DisplayName", "Term " + num2str(points{j, 2}));
                    legend(axishandle, "Color", [1 1 1]);
                end
                hold(axishandle, 'off');
            else
                for i = 1:row
                    axishandle = uiaxes(app.DecomposedPlotsPanel, "Position", [(10 + (i - 1)*(panelPos(3) - 20)), 25, panelPos(3) - 20, panelPos(4) - 60], "DataAspectRatio", [1, 1, 1],"PlotBoxAspectRatio", [1,0.8062157221206582,0.8062157221206582], ...
                        "BackgroundColor", [0 0 0], "XColor", [1 1 1], "YColor", [1 1 1], "ZColor", [1 1 1], "Color", [0 0 0]);
                    axishandle.Title.String = "";
                    dataPoints = [points{i, 1}];
                    plot(axishandle, dataPoints(:,1), dataPoints(:, 2), "Color", cmap(points{i, 2}, :), "DisplayName", "Term " + num2str(points{i, 2}));
                    legend(axishandle, "Color", [1 1 1]);
                end
                axishandle = uiaxes(app.DecomposedPlotsPanel, "Position", [(10 + (row)*(panelPos(3) - 20)), 25, (panelPos(3) - 20), panelPos(4) - 60], "DataAspectRatio", [1, 1, 1], "PlotBoxAspectRatio", [1,0.8062157221206582,0.8062157221206582],...
                    "BackgroundColor", [0 0 0], "XColor", [1 1 1], "YColor", [1 1 1], "ZColor", [1 1 1], ...
                    "Color", [0 0 0]);
                axishandle.Title.String = "";
                hold(axishandle, 'on');
                for j = 1:row
                    dataPoints = [points{j, 1}];
                    plot(axishandle, dataPoints(:,1), dataPoints(:, 2), "Color", cmap(points{j, 2}, :), "DisplayName", "Term " + num2str(points{j, 2}));
                    legend(axishandle, "Color", [1 1 1]);
                end
                hold(axishandle, 'off');
            end
        end
        
        %Plot the Data in the Overview and Centroid Tabs
        function plotData(radius, area, perimeter, surfaceArea, volume, centroid, ...
                radiusHandle, twoDHandle, threeDHandle, centerHandle, numFrames, currentFrame)
            line = 1.5;
            if ~isempty(radius)
                %Radius Plot
                radiusHandle.XLim = [1, numFrames];
                plot(radiusHandle, 1:numFrames, radius , '-w', currentFrame, radius(currentFrame), '*g', 'LineWidth', line);
                
                %Area and Perimeter Plot
                twoDHandle.XLim = [1, numFrames];
                yyaxis(twoDHandle, 'left');
                plot(twoDHandle, 1:numFrames, area, currentFrame, area(currentFrame), '*g', 'LineWidth', line);
                yyaxis(twoDHandle, 'right');
                plot(twoDHandle, 1:numFrames, perimeter, currentFrame, perimeter(currentFrame), '*g', 'LineWidth', line);
                
                %Surface Area and Volume Plots
                threeDHandle.XLim = [1, numFrames];
                yyaxis(threeDHandle, 'left');
                plot(threeDHandle, 1:numFrames, surfaceArea, currentFrame, surfaceArea(currentFrame), '*g', 'LineWidth', line);
                yyaxis(threeDHandle, 'right');
                plot(threeDHandle, 1:numFrames, volume, currentFrame, volume(currentFrame), '*g', 'LineWidth', line);
                
                %Centroid Plot
                gradient = zeros(1, 3, numFrames);
                gradient(1, 1, :) = linspace(178/255, 33/255, numFrames);
                gradient(1, 2, :) = linspace(24/255, 102/255, numFrames);
                gradient(1, 3, :) = linspace(43/255, 172/255, numFrames);
                plot(centerHandle, centroid(1, 1), centroid(1, 2), '--*', "Color", gradient(:, :, 1));
                hold(centerHandle, 'on');
                for d = 2:numFrames
                    plot(centerHandle, centroid(d, 1), centroid(d, 2), '--*', 'Color', gradient(:, :, d));
                end                
                hold(centerHandle, 'off');
            end
        end
        
        %Plot the Data in the Overview and Centroid Tabs in the alternate
        %axes
        function plotConvertedData(plotSet, radiusHandle, twoDHandle, threeDHandle, centerHandle, currentFrame, numFrames)
            
            if ~isempty(plotSet.AverageRadius)
                %Radius Plot
                radiusHandle.XLim = [plotSet.TimeVector(1), plotSet.TimeVector(end)];
                plot(radiusHandle, plotSet.TimeVector, plotSet.AverageRadius , '-w', ...
                    plotSet.TimeVector(currentFrame), plotSet.AverageRadius(currentFrame), '*g');
                
                %Area and Perimeter Plot
                twoDHandle.XLim = [plotSet.TimeVector(1), plotSet.TimeVector(end)];
                yyaxis(twoDHandle, 'left');
                plot(twoDHandle, plotSet.TimeVector, plotSet.Area, plotSet.TimeVector(currentFrame), plotSet.Area(currentFrame) ,'*g');
                yyaxis(twoDHandle, 'right');
                plot(twoDHandle, plotSet.TimeVector, plotSet.Perimeter, plotSet.TimeVector(currentFrame), plotSet.Perimeter(currentFrame), '*g');
                
                %Surface Area and Volume Plots
                threeDHandle.XLim = [plotSet.TimeVector(1), plotSet.TimeVector(end)];
                yyaxis(threeDHandle, 'left');
                plot(threeDHandle, plotSet.TimeVector, plotSet.SurfaceArea, plotSet.TimeVector(currentFrame), plotSet.SurfaceArea(currentFrame), '*g');
                yyaxis(threeDHandle, 'right');
                plot(threeDHandle, plotSet.TimeVector, plotSet.Volume, plotSet.TimeVector(currentFrame), plotSet.Volume(currentFrame), '*g');

                %Centroid Plot
                gradient = zeros(1, 3, numFrames);
                gradient(1, 1, :) = linspace(178/255, 33/255, numFrames);
                gradient(1, 2, :) = linspace(24/255, 102/255, numFrames);
                gradient(1, 3, :) = linspace(43/255, 172/255, numFrames);
                plot(centerHandle, plotSet.Centroid(1, 1), plotSet.Centroid(1, 2), '--*', "Color", gradient(:, :, 1));
                hold(centerHandle, 'on');
                for d = 2:numFrames
                    plot(centerHandle, plotSet.Centroid(d, 1), plotSet.Centroid(d, 2), '--*', 'Color', gradient(:, :, d));
                end
                hold(centerHandle, 'off');
            end
        end
        
        %Display the current frame and the overlays in the main viewer
        function displayCurrentFrame(app)
            if ~isempty(app.maskInformation)
                if ~isempty(app.ignoreFrames)
                    if ~isempty(find(app.ignoreFrames == app.currentFrame, 1))
                        imshow(app.frames(:, :, app.currentFrame), 'Parent', app.MainPlot);
                    elseif isempty(app.mask(:, :, app.currentFrame))
                        imshow(app.frames(:, :, app.currentFrame), 'Parent', app.MainPlot);
                    else
                        %Update the main viewer window
                        imshow(app.frames(:, :, app.currentFrame), 'Parent', app.MainPlot);
                        hold(app.MainPlot, 'on');
                        
                        for i = 1:2
                            if i == 1
                                perimeterPoints = app.maskInformation(app.currentFrame).PerimeterPoints;
                                center = app.maskInformation(app.currentFrame).Centroid;
                                tracking = app.maskInformation(app.currentFrame).TrackingPoints;
                                plot(app.MainPlot, perimeterPoints(:, 1), perimeterPoints(:, 2), 'r', ...
                                    center(1), center(2), 'b*',...
                                    tracking(:, 1), tracking(:, 2), 'y*', 'LineWidth', 1.5, 'MarkerSize', 5);
                            elseif i == 2
                                if app.FourierFitToggle.UserData
                                    fourier = app.maskInformation(app.currentFrame).FourierPoints;
                                    plot(app.MainPlot, fourier(:, 1), fourier(:, 2), 'c.', "DisplayName", "Fourier Fit Points", 'MarkerSize', 5, 'LineWidth', 2);
                                    fit = app.maskInformation(app.currentFrame).perimEq;
                                    if iscell(fit)
                                        xFunc = fit{1};
                                        yFunc = fit{2};
                                        xData = xFunc(linspace(1, length(fourier(:, 1)), numcoeffs(app.maskInformation(app.currentFrame).perimFit{1}).*25));
                                        yData = yFunc(linspace(1, length(fourier(:, 2)), numcoeffs(app.maskInformation(app.currentFrame).perimFit{2}).*25));
                                    else
                                        rFunc = fit;
                                        rData = rFunc(linspace(0, 2*pi, numcoeffs(app.maskInformation(app.currentFrame).perimFit)./2.*25));
                                        [xraw, yraw] = pol2cart(linspace(0, 2*pi, numcoeffs(app.maskInformation(app.currentFrame).perimFit)./2.*25), rData);
                                        xData = xraw + app.maskInformation(app.currentFrame).Centroid(1);
                                        yData = yraw + app.maskInformation(app.currentFrame).Centroid(2);
                                    end
                                    plot(app.MainPlot, xData, yData, '-g', 'DisplayName', 'FourierFit', 'LineWidth', 1);
                                end
                            end
                        end
                        
                        hold(app.MainPlot, 'off');
                    end
                end
            end
        end
        
        %Display the perimeter evolution overlay
        function dispEvolution(app)
            if ~isempty(app.maskInformation)
                [~, ~, depth] = size(app.mask);
                gradient = zeros(1, 3, depth);
                gradient(1, 1, :) = linspace(178/255, 33/255, app.numFrames);
                gradient(1, 2, :) = linspace(24/255, 102/255, app.numFrames);
                gradient(1, 3, :) = linspace(43/255, 172/255, app.numFrames);
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
        
        %Display the velocities of various points of the bubble perimeter
        function plotVelocity(velocityPlot, velocityData)
            velocityPlot.XLim = [1, length(velocityData(:, 1))];
            %Plot the average velocity
            plot(velocityPlot, velocityData(:, 1), velocityData(:, 2), '-w', 'LineWidth', 1.5);
            hold(velocityPlot, 'on');
            
            %Plot the top velocity 
            plot(velocityPlot, velocityData(:, 1), velocityData(:, 3), 'Color', [0, 73, 255]./255, 'LineWidth', 1.5);
            
            %Plot the bottom velocity
            plot(velocityPlot, velocityData(:, 1), velocityData(:, 4), 'Color', [255, 183, 0]./255, 'LineWidth', 1.5);
            
            %Plot the left velocity
            plot(velocityPlot, velocityData(:, 1), velocityData(:, 5), 'Color', [183, 0, 255]./255, 'LineWidth', 1.5);
            
            %Plot the right velocity
            plot(velocityPlot, velocityData(:, 1), velocityData(:, 6), 'Color', [255, 0, 72]./255, 'LineWidth', 1.5);
            
            legend(velocityPlot, "Average", "Top Extrema", "Bottom Extrema", "Left Extrema", "Right Extrema", 'Location', 'northeast', 'TextColor', [1 1 1]);
            hold(velocityPlot, 'off');
        end

    end
end