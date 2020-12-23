classdef incaio
    methods (Static)
        %Returns a cell array of the individual frames in a
        %video specified by the file path to the video
        function [frames, vidPath, vidFile] = loadFrames()
            [vidFile, vidPath] = uigetfile('*.avi');
            if any(vidFile == 0) || any(vidPath == 0)
                return;
            end
            vidObj = VideoReader(append(vidPath, vidFile));
            numFrames = vidObj.NumFrames;
            vidObj = VideoReader(append(vidPath, vidFile));
            %% Read the individual frames into a cell array
            for i = 1:numFrames
                pause(0.01);
                img = readFrame(vidObj);            %Read the Frame
                img = rgb2hsv(img);                 %Convert to HSV
                img = img(:, :, 3);                 %Extract the value matrix
                frames(:, :, i) = img;              %Store the frame in the cell array
            end
        end
        
        %Load in data from a previously analyzed video
        function [app, fullPath] = readFromFile(app)
            %% Load in the Data Table
            [file, path] = uigetfile('*.mat');
            fullPath = append(path, file);
            load(fullPath);
            %% Read in the data to the app variables if they exist in the current workspace
            if exist('frames', 'var') == 1
                app.frames = frames;
            end
            if exist('masks', 'var') == 1
                app.mask = masks;
            end
            if exist('infoStruct', 'var') == 1
                app.maskInformation = infoStruct;
            end
            if exist('ignoreFrames', 'var') == 1
                app.ignoreFrames = ignoreFrames;
            end
            if exist('BubbleRadius', 'var') == 1
                app.radius = BubbleRadius;
            end
            if exist('BubbleArea', 'var') == 1
                app.area = BubbleArea;
            end
            if exist('BubblePerimeter', 'var') == 1
                app.perimeter = BubblePerimeter;
            end
            if exist('BubbleSurfaceArea', 'var') == 1
                app.surfaceArea = BubbleSurfaceArea;
            end
            if exist('BubbleCentroid', 'var') == 1
                app.centroid = BubbleCentroid;
            end
            if exist('BubbleVolume', 'var') == 1
                app.volume = BubbleVolume;
            end
            if exist('BubbleVelocity', 'var') == 1
                app.velocity = BubbleVelocity;
            end
            if exist('numFrames', 'var') == 1
                app.numFrames = numFrames;
            end
            if exist('alternatePlotSet', 'var') == 1
                app.convertedPlotSet = alternatePlotSet;
            end
        end
        
        %Write analyzed data to a file
        function savePath = writeToFile(app)
            %% Read in and import into local variables the data
            frames = app.frames;
            masks = app.mask;
            infoStruct = app.maskInformation;
            ignoreFrames = app.ignoreFrames;
            BubbleRadius = app.radius;
            BubbleArea = app.area;
            BubblePerimeter = app.perimeter;
            BubbleSurfaceArea = app.surfaceArea;
            BubbleCentroid = app.centroid;
            BubbleVolume = app.volume;
            BubbleVelocity = app.velocity;
            numFrames = app.numFrames;
            alternatePlotSet = app.convertedPlotSet;
            %% Write the table to the specified file
            [file, path] = uiputfile('*.mat');
            savePath = append(path, file);
            save(savePath, 'frames', 'masks', 'infoStruct', 'ignoreFrames', 'BubbleRadius', 'BubbleArea', 'BubblePerimeter', ...
                'BubbleSurfaceArea', 'BubbleCentroid', 'BubbleVolume', 'BubbleVelocity', 'numFrames', 'alternatePlotSet', '-v7.3');
        end
        
        %Write analyzed data to an excel spreadsheet
        function exportToExcel(app, ignoreFrames)
            %% Get file path and name
            [file, path] = uiputfile('.xlsx');
            figure(app.UIFigure);
            fullFilePath = append(path, file);
            %% Set up the cell matrix
            coeffNums = zeros(1, app.numFrames);
            for i = 1:app.numFrames
                if isempty(find(ignoreFrames == i, 1))
                    coeffNums(i) = numcoeffs(app.maskInformation(i).FourierFitX);
                else
                    coeffNums(i) = NaN;
                end
            end
            maxCoeffs = max(coeffNums);
            numColumns = 6 + (2*maxCoeffs);
            data = cell(app.numFrames + 1, numColumns);
            %Write in the first row
            data{1, 1} = 'Centroid';
            data{1, 2} = 'Average Radius';
            data{1, 3} = 'Area';
            data{1, 4} = 'Perimeter';
            data{1, 5} = 'Surface Area';
            data{1, 6} = 'Volume';
            for j = 1:maxCoeffs
                data{1, 5 + (2*j)} = "a" + num2str(j - 1);
                data{1, 6 + (2*j)} = "b" + num2str(j - 1);
            end
            %Write in a row for each frame
            for k = 1:app.numFrames
                if isempty(find(ignoreFrames == k, 1))
                    data{1 + k, 1} = num2str(app.maskInformation(k).Centroid(1)) + ", " + num2str(app.maskInformation(k).Centroid(2));
                    data{1 + k, 2} = app.maskInformation(k).AverageRadius;
                    data{1 + k, 3} = app.maskInformation(k).Area;
                    data{1 + k, 4} = app.maskInformation(k).Perimeter;
                    data{1 + k, 5} = app.maskInformation(k).SurfaceArea;
                    data{1 + k, 6} = app.maskInformation(k).Volume;
                    
                    xnames = coeffnames(app.maskInformation(k).FourierFitX);
                    xvals = coeffvalues(app.maskInformation(k).FourierFitX);
                    
                    ynames = coeffnames(app.maskInformation(k).FourierFitY);
                    yvals = coeffvalues(app.maskInformation(k).FourierFitY);
                    
                    for l = 1:numcoeffs(app.maskInformation(k).FourierFitX)
                        targetCoeffX = "a" + num2str(l - 1);
                        targetCoeffY = "b" + num2str(l - 1);
                        
                        xCoeffVal = xvals(xnames == targetCoeffX);
                        yCoeffVal = yvals(ynames == targetCoeffY);
                        data{1 + k, 5 + (2*l)} = xCoeffVal;
                        data{1 + k, 6 + (2*l)} = yCoeffVal;
                    end
                else
                    for m = 1:numColumns
                        data{1 + k, m} = 'NaN';
                    end
                end
            end
            %% Write the cell matrix
            writecell(data, fullFilePath);
        end
        
        %Configure InCA data for IMR
        function data = configureDataForIMR(frames, mask, numFrames, ignoreFrames, maskInformation, convertedPlotSet, numExportTerms)
            % A function to configure InCA data for export to IMR
            % data - an output struct with the fields:
            %     .RoFT - a n x 1 column vector that contains the Fourier Fit radius for
            %     each frame, where n is the number of frames
            %     .t - a n x 1 column vector that contains the timestamp for each
            %     frame, where n is the number of frames
            %     .FTs - a n x 2*k matrix that contains the first k fourier term
            %     amplitudes and where n is the number of frames
            %     .regionprops - a n x 1 struct that contains various
            %     region props data about each frame/mask
            
            %% Extract the radius of each frame and put it in a vector
            radius = zeros(numFrames, 1);
            for i = 1:numFrames
                if isempty(find(ignoreFrames == i, 1))
                    xVal = maskInformation(i).FourierFitX.a1;               %Get the x component of the radius
                    yVal = maskInformation(i).FourierFitY.b1;               %Get the y component of the radius
                    radius(i) = sqrt(xVal^2 + yVal^2);                      %Calculate and store the radius
                end
            end
            
            %% Extract the time stamp for each frame and put it in a vector
            timestamp = convertedPlotSet.TimeVector;
            
            %% Extract the Fourier Fit Amplitudes for each frame
            FourierAmps = zeros(numFrames, numExportTerms);
            for i = 1:numFrames
                if isempty(find(ignoreFrames == i, 1))
                    xFourier = maskInformation(i).FourierFitX;              %Get the xFit for the frame
                    yFourier = maskInformation(i).FourierFitY;              %Get the yFit for the frame
                    xnames = coeffnames(xFourier);                              %Extract the x fit coefficient names
                    ynames = coeffnames(yFourier);                              %Extract the y fit coefficient names
                    xcoeffvals = coeffvalues(xFourier);                         %Extract the x fit coefficient values
                    ycoeffvals = coeffvalues(yFourier);                         %Extract the y fit coefficient values
                    
                    for j = 1:numExportTerms
                        targetCoeffX = "a" + num2str(j);                        %Generate a target x coefficient name
                        targetCoeffY = "b" + num2str(j);                        %Generate a target y coefficent name
                        
                        xVal = xcoeffvals(xnames == targetCoeffX);              %Get the x coefficient value associated with that name
                        yVal = ycoeffvals(ynames == targetCoeffY);              %Get the y coefficient value associated with that name
                        
                        FourierAmps(i, 2*j - 1) = xVal;
                        FourierAmps(i, 2*j) = yVal;
                    end
                end
            end
            
            %% Get regionprops data for each frame
            imageAnalysis = struct('Centroid', cell(numFrames, 1), 'Image', cell(numFrames, 1), 'Orientation', cell(numFrames, 1), ...
                'Perimeter', cell(numFrames, 1), 'PixelIdxList', cell(numFrames, 1), 'PixelList', cell(numFrames, 1), ...
                'WeightedCentroid', cell(numFrames, 1));
            for i = 1:numFrames
                if isempty(find(ignoreFrames == i, 1))
                    %Compute and compile the region props results
                    output= regionprops(mask(:, :, i), 'Centroid', 'Image', 'Orientation', 'Perimeter', 'PixelIdxList', 'PixelList');
                    stats = regionprops(mask(:, :, i), frames(:, :, i), 'WeightedCentroid');
                    output.WeightedCentroid = stats.WeightedCentroid;
                    
                    %Assign the values to the output struct in the correct location
                    imageAnalysis(i).Centroid = output.Centroid;
                    imageAnalysis(i).Image = output.Image;
                    imageAnalysis(i).Orientation = output.Orientation;
                    imageAnalysis(i).Perimeter = output.Perimeter;
                    imageAnalysis(i).PixelIdxList = output.PixelIdxList;
                    imageAnalysis(i).PixelList = output.PixelList;
                    imageAnalysis(i).WeightedCentroid = output.WeightedCentroid;
                end
            end
            
            %% Assign to final output struct
            data.RoFT = radius;
            data.t = timestamp;
            data.FTs = FourierAmps;
            data.regionprops = imageAnalysis;
            
        end
    end
end