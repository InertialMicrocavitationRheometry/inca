classdef plotting
    methods (Static)        
        %Generates the data for the main overview and centroid plots
        function plotSet = generatePlotData(app)
            
            info = app.maskInformation;
            if isempty(info)
                return;
            end
            [~, col] = size(info);
            
            plotSet = struct('radius', zeros(col, app.numFrames), 'perimeter', zeros(col, app.numFrames), 'area', zeros(col, app.numFrames), 'surfaceArea', zeros(col, app.numFrames), ...
                'volume', zeros(col, app.numFrames), 'centroid', zeros(app.numFrames, 2, col), 'velocity', zeros(app.numFrames, 6, col), 'orientation', zeros(col, app.numFrames), ...
                'fitradius', zeros(col, app.numFrames), 'fitarea', zeros(col, app.numFrames), 'fitperim', zeros(col, app.numFrames), 'fitsa', zeros(1, app.numFrames), ...
                'fitvol', zeros(1, app.numFrames));
            
            plotSet.time = 0:(1/app.FPSField.Value):(app.numFrames - 1).*(1/app.FPSField.Value);
            
            for i = 1:app.numFrames
                for j = 1:col
                    if isempty(info(i, j))
                        continue;
                    end
                    
                    %Converted Radius
                    if ~isempty(info(i, j).AverageRadius)
                        plotSet.radius(j, i) = info(i, j).AverageRadius.*app.MPXField.Value;
                    else
                        plotSet.radius(j, i) = NaN;
                    end
                    
                    %Converted Area
                    if ~isempty(info(i, j).Area)
                        plotSet.area(j, i) = info(i, j).Area.*(app.MPXField.Value).^2;
                    else
                        plotSet.area(j, i) = NaN;
                    end
                    
                    %Converted Perimeter
                    if ~isempty(info(i, j).Perimeter)
                        plotSet.perimeter(j, i) = info(i, j).Perimeter.*app.MPXField.Value;
                    else
                        plotSet.perimeter(j, i) = NaN;
                    end
                    
                    %Converted Surface Area
                    if ~isempty(info(i, j).SurfaceArea)
                        plotSet.surfaceArea(j, i) = info(i, j).SurfaceArea*(app.MPXField.Value).^2;
                    else
                        plotSet.surfaceArea(j, i) = NaN;
                    end
                    
                    %Converted Volume
                    if ~isempty(info(i, j).Volume)
                        plotSet.volume(j, i) = info(i, j).Volume*(app.MPXField.Value).^3;
                    else
                        plotSet.volume(j, i) = NaN;
                    end
                    
                    %Converted Centroid
                    if ~isempty(info(i, j).Centroid)
                        plotSet.centroid(i, :, j) = info(i, j).Centroid*app.MPXField.Value;
                    else
                        plotSet.centroid(i, :, j) = [NaN, NaN];
                    end
                    
                    %Converted Perimeter Velocity
                    plotSet.velocity(:, 1, j) = plotting.genVelocityX(plotSet.time);
                    if ~isempty(info(i, j).PerimVelocity)
                        if ~isnan(info(i, j).PerimVelocity)
                            plotSet.velocity(i, 2:6, j) = info(i, j).PerimVelocity*app.FPSField.Value*app.MPXField.Value;
                        else
                            plotSet.velocity(i, :, j) = [NaN, NaN, NaN, NaN, NaN, NaN];
                        end
                    end
                    
                    %Converted Orientation
                    if ~isempty(info(i, j).Orientation)
                        if ~isnan(info(i, j).Orientation)
                            plotSet.orientation(j, i) = info(i, j).Orientation;
                        else
                            plotSet.orientation(j, i) = NaN;
                        end
                    end
                    
                    %Converted Fit Radius
                    if ~isempty(info(i, j).FitRadius)
                        if ~isnan(info(i, j).FitRadius)
                            plotSet.fitradius(j, i) = info(i, j).FitRadius*app.MPXField.Value;
                        else
                            plotSet.fitradius(j, i) = NaN;
                        end
                    end
                    
                    %Converted Fit Area
                    if ~isempty(info(i, j).FitArea)
                        if ~isnan(info(i, j).FitArea)
                            plotSet.fitarea(j, i) = info(i, j).FitArea*(app.MPXField.Value)^2;
                        else
                            plotSet.fitarea(j, i) = NaN;
                        end
                    end
                    
                    %Converted Fit Perimeter
                    if ~isempty(info(i, j).FitPerim)
                        if ~isnan(info(i, j).FitPerim)
                            plotSet.fitperim(j, i) = info(i, j).FitPerim*app.MPXField.Value;
                        else
                            plotSet.fitperim(j, i) = NaN;
                        end
                    end
                    
                    %Converted Fit Surface Area
                    if j == 1
                        if ~isempty(info(i).FitSA)
                            if ~isnan(info(i).FitSA)
                                plotSet.fitSA(i) = info(i).FitSA.*(app.MPXField.Value)^2;
                            else
                                plotSet.fitSA(i) = NaN;
                            end
                        end
                        
                        %Converted Fit Volume
                        if ~isempty(info(i).FitVol)
                            if ~isnan(info(i).FitVol)
                                plotSet.fitvol(i) = info(i).FitVol.*(app.MPXField.Value)^3;
                            else
                                plotSet.fitvol(i) = NaN;
                            end
                        end
                    end
                                       
                end
            end
            
        end
        
        %Generates data for a normalized radius plot
        function normalizedRadius = noramlizedRadiusPlot(info, numFrames, ignoreFrames, style)
            rawRadius = zeros(1, numFrames);
            switch style
                case "parametric"
                    for i = 1:numFrames
                        if isempty(find(ignoreFrames == i, 1)) && ~isnumeric(info(i).perimFit{1})
                            xFit = info(i).perimFit{1};
                            yFit = info(i).perimFit{2};
                            rawRadius(i) = sqrt(xFit.a1^2 + yFit.b1^2);
                        else
                            rawRadius(i) = NaN;
                        end
                    end
                    normalizedRadius = rawRadius./max(rawRadius);
                case "polar (standard)"
                    for i = 1:numFrames
                        if isempty(find(ignoreFrames == i, 1)) && ~isnumeric(info(i).perimFit)
                            rawRadius(i) = info(i).perimFit.r;
                        else
                            rawRadius(i) = NaN;
                        end
                    end
                    normalizedRadius = rawRadius./max(rawRadius);
                case "polar (phase shift)"
                    for i = 1:numFrames
                        if isempty(find(ignoreFrames == i, 1)) && ~isumeric(info(i).perimFit)
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
                            
                            if isnumeric(xFit)
                                output(:, :) = NaN;
                                return;
                            end
                            
                            xnames = coeffnames(xFit);
                            xno = numcoeffs(xFit) - 1;
                            xvals = coeffvalues(xFit);
                            
                            ynames = coeffnames(yFit);
                            yvals = coeffvalues(yFit);
                            yno = numcoeffs(yFit) - 1;
                            
                            if xno < numberTerms && xno == yno
                                limit = xno;
                            elseif xno == 0 || yno == 0
                                output(i, :) = NaN;
                                continue;
                            else
                                limit = numberTerms;
                            end
                            
                            parfor j = 2:limit
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
                            
                            if isnumeric(perimFit)
                                output(:, :) = NaN;
                                return;
                            end
                            
                            names = coeffnames(perimFit);
                            nocoeff = (numcoeffs(perimFit) - 1)./2;
                            vals = coeffvalues(perimFit);
                            
                            if nocoeff < numberTerms
                                limit = nocoeff;
                            elseif nocoeff == 0
                                output(i, :) = NaN;
                                continue;
                            else
                                limit = numberTerms;
                            end
                            
                            for j = 1:limit
                                targetCoeffX = "a" + num2str(j);
                                targetCoeffY = "b" + num2str(j);
                                
                                xval = vals(names == targetCoeffX);
                                yval = vals(names == targetCoeffY);
                                
                                try 
                                    output(i, j) = (xval + yval)./perimFit.r;
                                catch ME
                                    pause;
                                end
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
                            
                            if isnumeric(perimFit)
                                output(:, :) = NaN;
                                return;
                            end
                            
                            names = coeffnames(perimFit);
                            nocoeffs = (numcoeffs(perimFit) - 1)./2;
                            vals = coeffvalues(perimFit);
                            
                            if nocoeffs < numberTerms
                                limit = nocoeffs;
                            elseif nocoeffs == 0
                                output(i, :) = NaN;
                                continue;
                            else
                                limit = numberTerms;
                            end
                            
                            for j = 1:limit
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
        
        %Plots the Fourier Asphericity
        function plotFourier(app)
            yyaxis(app.AsphericityPlot, "left");
            cla(app.AsphericityPlot);
            hold(app.AsphericityPlot, 'on');
            yyaxis(app.AsphericityPlot, "right");
            cla(app.AsphericityPlot);
            hold(app.AsphericityPlot, 'on');
            app.AsphericityPlot.XLim = [0, app.plotSet.time(end)];
            if app.FourierFitToggle.UserData
                %Get the color map set up
                cmap = viridis(app.TermsofInterestField.Value);
                plotorder = {'-', ':'};
                [~, views] = size(app.maskInformation);
                for i = 1:views
                    %Plot the data points
                    points = plotting.fourierFitPlot(app.maskInformation(:, i), app.TermsofInterestField.Value, app.numFrames, app.ignoreFrames, ...
                        lower(string(app.FitType.ButtonGroup.SelectedObject.Text)));
                    
                    yyaxis(app.AsphericityPlot, 'left');
                    app.AsphericityPlot.YColor = cmap(end - 1, :);
                    
                    [~, col] = size(points);
                    for d = 1:col
                        plot(app.AsphericityPlot, app.plotSet.time, points(:, d),"Color", cmap(d, :), "LineStyle",plotorder{i}, "Marker", "none", 'LineWidth', 1.5);
                    end
                    
                    normalizedRadius = plotting.noramlizedRadiusPlot(app.maskInformation(:, i), app.numFrames, app.ignoreFrames, ...
                        lower(string(app.FitType.ButtonGroup.SelectedObject.Text)));
                    
                    yyaxis(app.AsphericityPlot, 'right');
                    ylabel(app.AsphericityPlot, "R/Rmax");
                    app.AsphericityPlot.YColor = [1, 1, 1];
                    
                    r = plot(app.AsphericityPlot, app.plotSet.time, normalizedRadius, "LineStyle", plotorder{i}, "Marker", "none", "Color", [1, 1, 1], 'LineWidth', 1.5);
                end
                legend(app.AsphericityPlot, r, "R/max(R)", "TextColor", [1, 1 ,1]);
                yyaxis(app.AsphericityPlot, 'left');
                hold(app.AsphericityPlot, 'off');
                yyaxis(app.AsphericityPlot, 'right');
                hold(app.AsphericityPlot, 'off');
            end
        end
        
        %Generates the Fourier Decomposition Data
        function output = fourierDecomposition(info, targetFrame, numTerms, sortOrder, style)
            switch style
                case "parametric"
                    xFit = info(targetFrame).perimFit{1};
                    yFit = info(targetFrame).perimFit{2};
                    xnames = coeffnames(xFit);
                    xno = (numcoeffs(xFit) - 1)./2;
                    ynames = coeffnames(yFit);
                    xvals = coeffvalues(xFit);
                    yvals = coeffvalues(yFit);
                    yno = (numcoeffs(yFit) - 1)./2;
                    if numTerms > xno && xno == yno
                        limit = xno;
                    else
                        limit = numTerms;
                    end
                    output = cell((limit - 1), 2);
                    asphericity = zeros(1, (limit - 1));
                    parfor i = 2:limit
                        targetCoeffX = "a" + num2str(i);
                        targetCoeffY = "b" + num2str(i);
                        
                        xCoeffVal = xvals(xnames == targetCoeffX);
                        yCoeffVal = yvals(ynames == targetCoeffY);
                        
                        asphericity(i - 1) = sqrt(xCoeffVal.^2 + yCoeffVal.^2)./sqrt(xFit.a1.^2 + yFit.b1.^2);
                    end
                    switch sortOrder
                        case "ascending"
                            for j = 2:limit
                                
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
                            for j = 2:limit
                                
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
                    fit = info(targetFrame).perimFit;
                    fitcoeffs = coeffnames(fit);
                    fitvals = coeffvalues(fit);
                    
                    if numTerms > ((numcoeffs(fit) - 1)/2)
                        limit = ((numcoeffs(fit) - 1)/2);
                    else
                        limit = numTerms;
                    end
                    asphericity = zeros(1, limit);
                    output = cell(limit, 2);
                    for i = 1:limit
                        targetCoeffX = "a" + num2str(i);
                        targetCoeffY = "b" + num2str(i);
                        
                        xCoeffVal = fitvals(fitcoeffs == targetCoeffX);
                        yCoeffVal = fitvals(fitcoeffs == targetCoeffY);
                        asphericity(i) = (xCoeffVal + yCoeffVal)./fit.r;
                    end
                    for j = 1:limit
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
                    fit = info(targetFrame).perimFit;
                    fitcoeffs = coeffnames(fit);
                    fitvals = coeffvalues(fit);
                    if numTerms > ((numcoeffs(fit) - 1)/2)
                        limit = ((numcoeffs(fit) - 1)/2);
                    else
                        limit = numTerms;
                    end
                    output = cell(limit, 2);
                    asphericity = zeros(1, limit);
                    for i = 1:limit
                        targetCoeffX = "a" + num2str(i);
                        
                        xCoeffVal = fitvals(fitcoeffs == targetCoeffX);
                        
                        asphericity(i) = xCoeffVal./fit.a0;
                    end
                    for j = 1:limit
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
        function plotFourierDecomp(~, points)
            [row, ~] = size(points);
            cmap = viridis(row);
            DecompFig = uifigure('WindowState', 'maximized', 'Scrollable', 'on');
            panelPos = DecompFig.Position;
            for h = 1:row
                vals(h) = points{h, 2};
            end
            if max(vals) > row
                for i = 1:row
                    axishandle = uiaxes(DecompFig, "Position", [(10 + (i - 1)*(panelPos(3) - 20)), 25, panelPos(3) - 20, panelPos(4) - 70], "DataAspectRatio", [1, 1, 1],"PlotBoxAspectRatio", [1,0.8062157221206582,0.8062157221206582], ...
                        "BackgroundColor", [0 0 0], "XColor", [1 1 1], "YColor", [1 1 1], "ZColor", [1 1 1], "Color", [0 0 0]);
                    axishandle.Title.String = "";
                    dataPoints = [points{i, 1}];
                    plot(axishandle, dataPoints(:,1), dataPoints(:, 2), "Color", cmap(points{i, 2} - 1, :), "DisplayName", "Term " + num2str(points{i, 2}), 'LineWidth', 2);
                    legend(axishandle, "Color", [1 1 1]);
                end
                axishandle = uiaxes(DecompFig, "Position", [(10 + (row)*(panelPos(3) - 20)), 25, (panelPos(3) - 20), panelPos(4) - 70], "DataAspectRatio", [1, 1, 1], "PlotBoxAspectRatio", [1,0.8062157221206582,0.8062157221206582],...
                    "BackgroundColor", [0 0 0], "XColor", [1 1 1], "YColor", [1 1 1], "ZColor", [1 1 1], ...
                    "Color", [0 0 0]);
                axishandle.Title.String = "";
                hold(axishandle, 'on');
                for j = 1:row
                    dataPoints = [points{j, 1}];
                    plot(axishandle, dataPoints(:,1), dataPoints(:, 2), "Color", cmap(points{j, 2} - 1, :), "DisplayName", "Term " + num2str(points{j, 2}), 'LineWidth', 2);
                    legend(axishandle, "Color", [1 1 1]);
                end
                hold(axishandle, 'off');
            else
                for i = 1:row
                    axishandle = uiaxes(DecompFig, "Position", [(10 + (i - 1)*(panelPos(3) - 20)), 25, panelPos(3) - 20, panelPos(4) - 70], "DataAspectRatio", [1, 1, 1],"PlotBoxAspectRatio", [1,0.8062157221206582,0.8062157221206582], ...
                        "BackgroundColor", [0 0 0], "XColor", [1 1 1], "YColor", [1 1 1], "ZColor", [1 1 1], "Color", [0 0 0]);
                    axishandle.Title.String = "";
                    dataPoints = [points{i, 1}];
                    plot(axishandle, dataPoints(:,1), dataPoints(:, 2), "Color", cmap(points{i, 2}, :), "DisplayName", "Term " + num2str(points{i, 2}), 'LineWidth', 2);
                    legend(axishandle, "Color", [1 1 1]);
                end
                axishandle = uiaxes(DecompFig, "Position", [(10 + (row)*(panelPos(3) - 20)), 25, (panelPos(3) - 20), panelPos(4) - 70], "DataAspectRatio", [1, 1, 1], "PlotBoxAspectRatio", [1,0.8062157221206582,0.8062157221206582],...
                    "BackgroundColor", [0 0 0], "XColor", [1 1 1], "YColor", [1 1 1], "ZColor", [1 1 1], ...
                    "Color", [0 0 0]);
                axishandle.Title.String = "";
                hold(axishandle, 'on');
                for j = 1:row
                    dataPoints = [points{j, 1}];
                    plot(axishandle, dataPoints(:,1), dataPoints(:, 2), "Color", cmap(points{j, 2}, :), "DisplayName", "Term " + num2str(points{j, 2}), 'LineWidth', 2);
                    legend(axishandle, "Color", [1 1 1]);
                end
                hold(axishandle, 'off');
            end
        end
        
        %Plot the data from the mask analysis
        function plotData(plotset, radiusHandle, twoDHandle, threeDHandle, centerHandle, orientationHandle, numFrames)
            line = 1.5;
            plotorder = {'-', ':', '--'};
            markerorder = {'o', 's', '^'};
            
            hold(radiusHandle, 'on');
            
            yyaxis(twoDHandle, 'left');
            hold(twoDHandle, 'on');
            yyaxis(twoDHandle, 'right');
            hold(twoDHandle, 'on');
            
            yyaxis(threeDHandle, 'left');
            hold(threeDHandle, 'on');
            yyaxis(threeDHandle, 'right');
            hold(threeDHandle, 'on');
            
            if ~isempty(plotset.radius)
                [row, ~] = size(plotset.radius);
                for i = 1:row
                    %Radius Plot
                    radiusHandle.XLim = [plotset.time(1), plotset.time(end)];
                    plot(radiusHandle, plotset.time, plotset.radius(i, :) , '-w', 'LineWidth', line, 'LineStyle', plotorder{i});
                    
                    %Area and Perimeter Plot
                    twoDHandle.XLim = [plotset.time(1), plotset.time(end)];
                    yyaxis(twoDHandle, 'left');
                    plot(twoDHandle, plotset.time, plotset.area(i, :), 'LineWidth', line, 'LineStyle', plotorder{i});
                    yyaxis(twoDHandle, 'right');
                    plot(twoDHandle, plotset.time, plotset.perimeter(i, :), 'LineWidth', line, 'LineStyle', plotorder{i});
                    
                    %Surface Area and Volume Plots
                    threeDHandle.XLim = [plotset.time(1), plotset.time(end)];
                    yyaxis(threeDHandle, 'left');
                    plot(threeDHandle, plotset.time, plotset.surfaceArea(i, :), 'LineWidth', line, 'LineStyle', plotorder{i});
                    yyaxis(threeDHandle, 'right');
                    plot(threeDHandle, plotset.time, plotset.volume(i, :), 'LineWidth', line, 'LineStyle', plotorder{i});
                    
                    %Set up blue-red time gradient
                    gradient = zeros(1, 3, numFrames);
                    gradient(1, 1, :) = linspace(178/255, 33/255, numFrames);
                    gradient(1, 2, :) = linspace(24/255, 102/255, numFrames);
                    gradient(1, 3, :) = linspace(43/255, 172/255, numFrames);
                    
                    [~, maxR] = max( sqrt(plotset.centroid(:, 1, i).^2 + plotset.centroid(:, 2, i).^2) );
                    normX = plotset.centroid(maxR, 1, i);
                    normY = plotset.centroid(maxR, 2, i);
                    
                    %Centroid Plot
                    hold(centerHandle, 'on');
                    for d = 1:numFrames
                        plot(centerHandle, plotset.centroid(d, 1, i)./normX, plotset.centroid(d, 2, i)./normY, 'Marker', markerorder{i}, 'Color', gradient(:, :, d));
                    end
                    
                    hold(centerHandle, 'off');
                    
                    %Orientation Plot
                    hold(orientationHandle, 'on');
                    for d = 1:numFrames
                        polarplot(orientationHandle, plotset.orientation(i, d), i, 'Marker', markerorder{i}, "Color", gradient(:, :, d));
                    end
                    
                    orientationHandle.Color = [0.1 0.1 0.1];
                    orientationHandle.GridColor = [0.95 0.95 0.95];
                    orientationHandle.ThetaColor = [0.95 0.95 0.95];
                    orientationHandle.RColor = [0.95 0.95 0.95];
                    title(orientationHandle, "MAJOR AXIS ORIENTATION", 'Color', [0.95 0.95 0.95]);
                    
                    hold(orientationHandle, 'off');
                end
            end
            
            hold(radiusHandle, 'off');
            
            yyaxis(twoDHandle, 'left');
            hold(twoDHandle, 'off');
            yyaxis(twoDHandle, 'right');
            hold(twoDHandle, 'off');
            
            yyaxis(threeDHandle, 'left');
            hold(threeDHandle, 'off');
            yyaxis(threeDHandle, 'right');
            hold(threeDHandle, 'off');
        end
        
        %Plot the Data from the fourier fit
        function plotFourierData(plotset, radiusHandle, twoDHandle)
            line = 1.5;
            
            hold(radiusHandle, 'on');
            
            yyaxis(twoDHandle, 'left');
            hold(twoDHandle, 'on');
            yyaxis(twoDHandle, 'right');
            hold(twoDHandle, 'on');
            
            if ~isempty(plotset.radius)
                [views, ~] = size(plotset.fitradius);
                plotorder = {'-', ':', '--'};
                for i = 1:views
                    %Radius Plot
                    radiusHandle.XLim = [plotset.time(1), plotset.time(end)];
                    plot(radiusHandle, plotset.time, plotset.fitradius(i, :), 'Color', 'w', 'LineWidth', line, 'LineStyle', plotorder{i});
                    
                    %Area and Perimeter Plot
                    twoDHandle.XLim = [plotset.time(1), plotset.time(end)];
                    yyaxis(twoDHandle, 'left');
                    plot(twoDHandle, plotset.time, plotset.fitarea(i, :), 'LineWidth', line, 'LineStyle', plotorder{i});
                    yyaxis(twoDHandle, 'right');
                    plot(twoDHandle, plotset.time, plotset.fitperim(i, :), 'LineWidth', line, 'LineStyle', plotorder{i});
                    
%                     %Surface Area and Volume
%                     threeDHandle.XLim = [plotset.time(1), plotset.time(end)];
%                     yyaxis(threeDHandle, 'left');
%                     plot(threeDHandle, plotset.time, plotset.fitSA, 'LineWidth', line);
%                     yyaxis(threeDHandle, 'right');
%                     plot(threeDHandle, plotset.time, plotset.fitvol, 'LineWidth', line);
                end
            end
            
                        
            hold(radiusHandle, 'off');
            
            yyaxis(twoDHandle, 'left');
            hold(twoDHandle, 'off');
            yyaxis(twoDHandle, 'right');
            hold(twoDHandle, 'off');
            
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
                        
                        [~, views] = size(app.maskInformation);
                        for i = 1:views
                            perimeterPoints = app.maskInformation(app.currentFrame, i).PerimeterPoints;
                            center = app.maskInformation(app.currentFrame, i).Centroid;
                            tracking = app.maskInformation(app.currentFrame, i).TrackingPoints;
                            plot(app.MainPlot, perimeterPoints(:, 1), perimeterPoints(:, 2), 'r', ...
                                center(1), center(2), 'b*',...
                                tracking(:, 1), tracking(:, 2), 'y*', 'LineWidth', 1.5, 'MarkerSize', 3);
                            if app.FourierFitToggle.UserData
                                fourier = app.maskInformation(app.currentFrame, i).FourierPoints;
                                plot(app.MainPlot, fourier(:, 1), fourier(:, 2), 'c.', "DisplayName", "Fourier Fit Points", 'MarkerSize', 5, 'LineWidth', 2);
                                fit = app.maskInformation(app.currentFrame, i).perimEq;
                                if iscell(fit)
                                    xFunc = fit{1};
                                    yFunc = fit{2};
                                    xData = xFunc(linspace(1, length(fourier(:, 1)), numcoeffs(app.maskInformation(app.currentFrame, i).perimFit{1}).*25));
                                    yData = yFunc(linspace(1, length(fourier(:, 2)), numcoeffs(app.maskInformation(app.currentFrame, i).perimFit{2}).*25));
                                else
                                    rFunc = fit;
                                    rData = rFunc(linspace(0, 2*pi, numcoeffs(app.maskInformation(app.currentFrame, i).perimFit)./2.*25));
                                    [xraw, yraw] = pol2cart(linspace(0, 2*pi, numcoeffs(app.maskInformation(app.currentFrame, i).perimFit)./2.*25), rData);
                                    xData = xraw + app.maskInformation(app.currentFrame, i).Centroid(1);
                                    yData = yraw + app.maskInformation(app.currentFrame, i).Centroid(2);
                                end
                                plot(app.MainPlot, xData, yData, '-g', 'DisplayName', 'FourierFit', 'LineWidth', 1);
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
                info = app.maskInformation;
                [~, views] = size(info);
                [~, ~, depth, ~] = size(app.mask);
                gradient = zeros(1, 3, depth);
                gradient(1, 1, :) = linspace(178/255, 33/255, depth);
                gradient(1, 2, :) = linspace(24/255, 102/255, depth);
                gradient(1, 3, :) = linspace(43/255, 172/255, depth);
                
                for i = 1:views
                    
                    perimeterPoints = info(1, i).PerimeterPoints;
                    if ~isnan(perimeterPoints)
                        plot(app.EvolutionPlot, perimeterPoints(:, 1), perimeterPoints(:, 2), 'Color', gradient(:, :, 1));
                    end
                    hold(app.EvolutionPlot, 'on');
                    for d = 2:depth
                        if isempty(find(app.ignoreFrames == d, 1))
                            perimeterPoints = app.maskInformation(d, i).PerimeterPoints;
                            plot(app.EvolutionPlot, perimeterPoints(:, 1), perimeterPoints(:, 2), 'Color', gradient(:, :, d));
                        end
                    end
                    hold(app.EvolutionPlot, 'off');
                    
                end
            end
        end
        
        function timeOut = genVelocityX(time)
            frames = length(time);
            timeOut = (0.5:(frames - 0.5)).*time(2);
        end
        
        %Display the velocities of various points of the bubble perimeter
        function plotVelocity(velocityPlot, velocityData)
            velocityPlot.XLim = [velocityData(1, 1) velocityData(end, 1)];
            
            plotorder = {'-', ':'};
            [~, ~, views] = size(velocityData);
            hold(velocityPlot, 'on');
            
            for i = 1:views
                
                %Plot the average velocity
                plot(velocityPlot, velocityData(:, 1, i), velocityData(:, 2, i), 'w', 'LineWidth', 1.5);
                
                %Plot the top velocity
                plot(velocityPlot, velocityData(:, 1, i), velocityData(:, 3, i), 'Color', [0, 73, 255]./255, 'LineWidth', 1.5, 'LineStyle', plotorder{i});
                
                %Plot the bottom velocity
                plot(velocityPlot, velocityData(:, 1, i), velocityData(:, 4, i), 'Color', [255, 183, 0]./255, 'LineWidth', 1.5, 'LineStyle', plotorder{i});
                
                %Plot the left velocity
                plot(velocityPlot, velocityData(:, 1, i), velocityData(:, 5, i), 'Color', [183, 0, 255]./255, 'LineWidth', 1.5, 'LineStyle', plotorder{i});
                
                %Plot the right velocity
                plot(velocityPlot, velocityData(:, 1, i), velocityData(:, 6, i), 'Color', [255, 0, 72]./255, 'LineWidth', 1.5, 'LineStyle', plotorder{i});
                
                legend(velocityPlot, "Average", "Top Extrema", "Bottom Extrema", "Left Extrema", "Right Extrema", 'Location', 'best', 'TextColor', [1 1 1]);
            end
            
            hold(velocityPlot, 'off');
        end

    end
end