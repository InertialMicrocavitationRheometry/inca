classdef InCA < matlab.apps.AppBase
    
    % Properties that correspond to app components
    properties (Access = public)
        UIFigure
        Version = 23;
        TabGroup
        HomeTab
        DetectionTab
        AnalysisTab
        LogsTab
        
        %Home
        HomeImage                       %Done
        VersionLabel                    %Done
        NewButton                       %Done
        NewPath                         %Done
        OpenButton                      %Done
        OpenPath                        %Done
        SaveButton                      %Done
        SavePath                        %Done
        BatchButton                     %Done
        BatchPanel
        
        %Detect
        Scrollpane                      %Done       %The scrollpane that houses all of the image previews
        CalibrationFrame                %Done       %The uiimage component used for calibrating the detection settings or refining the current frame
        AutoColorToggle                 %Done       %The uiimage component that represents the toggle instructing if InCA should automatically generate a threshold for color based image processing
        AutoColorLabel                  %Done       %The label accompanying the above uiimage component
        ColorThresholdLabel             %Done       %The label accompanying the below uieditfield component
        ColorThresholdField             %Done       %The uieditfield component that houses the gray thresh value
        CStyleLabel                     %Done       %The label accompanying the below component
        CStyle                          %Done       %The Drop down that determines the style of preprocessing to be used on the images for color-based mask generation
        CValLabel                       %Done       %The label accompanying the below component
        CVal                            %Done       %The uieditfield component containing the intensity of the preprocessing filter
        ColorMask                       %Done       %The uiimage component that houses the resulting overlay from color-based image mask generation
        EdgeThresholdLabel              %Done       %The label component accompanying the below component
        EdgeThresholdField              %Done       %The edge equivalent for ColorThresholdField
        AutoEdgeToggle                  %Done       %The edge equivalent for AutoColorToggle
        AutoEdgeLabel                   %Done       %The edge equivalent for AutoColorLabel
        EStyle                          %Done       %The Drop down that determines the style of preprocessing to be used on images for edge-based mask generation
        EStyleLabel                     %Done       %The label accompanyying the above component
        EValLabel                       %Done       %The label accompanying the below component
        EVal                            %Done       %The uieditfield component containing the intesnity of the preprocessing filter
        EdgeMask                        %Done       %The uiimage component that houses the resulting overlay from edge-based mask generation
        MixerLabel                      %Done 
        MixerSlider                     %Done
        FinalMaskViewer                 %Done
        NextFrameDetectionButton        %Done
        PreviousFrameDetectionButton    %Done
        ResetDetectionButton            %Done
        ViewResultButton                %Done
        RefineButton                    %Done
        RunDetectionButton              %Done
        AcceptFrameButton               %Done
        RejectFrameButton               %Dohe
        MultiviewToggle                 %Done
        MultiviewLabel                  %Done
        IFFToggle                       %Done
        IFFLabel                        %Done
        ICToggle                        %Done
        ICLabel                         %Done
        RTToggle                        %Done
        RTLabel                         %Done
        ColorLabel                      %Done
        EdgeLabel                       %Done
        VLToggle                        %Done
        VLLabel                         %Done
        NLButtonGroup                   %Done
        BSRadioButton                   %Done
        BSField                         %Done
        BSLabel                         %Done
        GARadioButton                   %Done
        
        %Analyze
        FPSLabel                        %Done
        FPSField                        %Done
        MPXLabel                        %Done
        MPXField                        %Done
        TPLabel                         %Done
        TPField                         %Done
        FourierFitToggle                %Done
        FourierFitToggleLabel           %Done
        AdaptiveTermsToggleLabel        %Done
        AdaptiveTermsToggle             %Done
        MinArcLengthLabel               %Done
        MinArcLengthField               %Done
        MaxTermsLabel                   %Done
        MaxTermsField                   %Done
        TermsofInterestLabel            %Done
        TermsofInterestField            %Done
        MetricTermsLabel                %Done
        MetricTermsField                %Done
        JumpFrameLabel                  %Done
        JumpFrameField                  %Done
        NextFrameButton                 %Done
        PreviousFrameButton             %Done
        TargetFrameLabel                %Done
        TargetFrameField                %Done
        DecompositionTermsLabel         %Done
        DecompositionTermsField         %Done
        DecomposeButton                 %Done
        DecompositionPanel              %Done
        SphFitLabel
        SphFitToggle
        PhiModesLabel
        PhiModesField
        ThetaModesLabel
        ThetaModesField
        RotationAxis                    %Done
        FitType                         %Done
        AnalyzeButton                   %Done
        ViewerPanel                     %Done
        PlotPanel                       %Done
        SettingsPanel                   %Done
        RefreshPlotsButton              %Done
        
        RadiusPlot                      %Done
        TwoDimensionalPlot              %Done
        ThreeDimensionalPlot            %Done
        VelocityPlot                    %Done
        CentroidPlot                    %Done
        CentroidFirst                   %Done
        CentroidLast                    %Done
        OrientationPlot                 %Done
        EvolutionPlot                   %Done
        EvolutionFirst                  %Done
        EvolutionLast                   %Done
        MainPlot                        %Done
        AsphericityPlot                 %Done
        FourierSecond                   %Done
        FourierLast                     %Done
        FourierColorMap                 %Done
        RadiusFitPlot                   %Done
        TwoDimensionalFitPlot           %Done
        InspectFrameButton              %Done
        
        %Log
        LogArea                         %Done
        DownloadButton                  %Done
    end
    
    properties (Access = public)
        frames = []
        mask = []
        maskInformation
        ignoreFrames = []
        currentFrame = 1
        numFrames
        plotSet
        frameInterval
        batchmode
        workingFrame
        initialized = 0;
    end
    
    methods (Access = private)
        
        function checkVersion(app)
            try
                options = weboptions('Timeout', Inf);
                newestVersion = str2double(string(webread('https://raw.githubusercontent.com/estradalab/inca/master/version.txt', options)));
                if newestVersion > app.Version
                    uialert(app.UIFigure, 'A newer version of InCA is available. An update is recommended.', 'Newer version detected', 'Icon', 'warning');
                elseif newestVersion < app.Version
                    UpdateLogs(app, 'Welcome developer :)');
                else
                    UpdateLogs(app, 'InCA is up-to-date');
                end
                UpdateLogs(app, append('Latest Released Version: ', num2str(newestVersion./10)));
            catch me
                uialert(app.UIFigure, me.message, append('Version Check Error: ', me.identifier), 'Icon', 'error');
                LogExceptions(app, me);
            end
        end
        
        function resetFunction(app)
            try
                % Clear main variables
                clear app.frames;
                clear app.mask;
                clear app.maskInformation;
                clear app.ignoreFrames;
                app.currentFrame = 1;
                clear app.numFrames;
                clear app.plotSet;
                clear app.workingFrame;
                delete(app.Scrollpane.Children);
                app.ColorMask.ImageSource = 'icon.png';
                app.EdgeMask.ImageSource = 'icon.png';
                app.CalibrationFrame.ImageSource = 'icon.png';
                cla(app.FinalMaskViewer);
                
                app.NewPath.Value = '';
                app.OpenPath.Value = '';
                app.SavePath.Value = '';
                app.BatchButton.Value = 0;
                
                %Clear plots and graphs
                cla(app.MainPlot);
                cla(app.EvolutionPlot);
                cla(app.RadiusPlot);
                yyaxis(app.TwoDimensionalPlot, 'left');
                cla(app.TwoDimensionalPlot);
                yyaxis(app.TwoDimensionalPlot, 'right');
                cla(app.TwoDimensionalPlot);
                yyaxis(app.ThreeDimensionalPlot, 'left');
                cla(app.ThreeDimensionalPlot);
                yyaxis(app.ThreeDimensionalPlot, 'right');
                cla(app.ThreeDimensionalPlot);
                cla(app.CentroidPlot);
                cla(app.OrientationPlot);
                cla(app.VelocityPlot);
                cla(app.RadiusFitPlot);
                yyaxis(app.TwoDimensionalFitPlot, 'left');
                cla(app.TwoDimensionalFitPlot);
                yyaxis(app.TwoDimensionalFitPlot, 'right');
                cla(app.TwoDimensionalFitPlot);
                yyaxis(app.AsphericityPlot, 'left');
                cla(app.AsphericityPlot);
                yyaxis(app.AsphericityPlot, 'right');
                cla(app.AsphericityPlot);
                
                %Reset Fourier Decomp Tab
                app.TargetFrameField.Value = 1;
                app.TermsofInterestField.Value = 8;
                app.MetricTermsField.Value = 5;
                
            catch me
                uialert(app.UIFigure, me.message, append('Reset Error: ', me.identifier), 'Icon', 'error');
            end
        end
        
        function populateScrollpane(app)
            
            f = uiprogressdlg(app.UIFigure, 'Indeterminate', 'on');         %Progress bar
            delete(app.Scrollpane.Children);                                %Clear the scrollpane
            UpdateLogs(app, 'Populating Detection Scrollpane...');          %Update logs
            panelPos = app.Scrollpane.Position;                             %Get the current scrollpane position
            [row, col] = size(app.frames(:, :, 1));                         %Calculate the image size
            imgHeight = row./col.*(panelPos(3) - 20);                       %Calculate uiimage height
            
            for i = 1:app.numFrames
                
                index = (app.numFrames + 1) - i;
                                
                if ~app.MultiviewToggle.UserData
                %Single view point code 
                
                    %Check if a mask exists for a frame
                    if ~any(any(app.mask(:, :, index)))
                        img = zeros([size(app.frames(:, :, index)), 3]);
                        img(:, :, 3) = app.frames(:, :, index);
                        scrollpaneImage = hsv2rgb(img);
                    else
                        scrollpaneImage = labeloverlay(app.frames(:, :, index), app.mask(:, :, index));
                    end
                    
                    %Populate the uiimage component with the frame/mask
                    if isempty(find(app.ignoreFrames == index, 1))
                        uiimage(app.Scrollpane, "ScaleMethod",'scaledown', 'ImageSource', scrollpaneImage, ...
                            'Position', [5, (10 + (i - 1)*(imgHeight + 10)), panelPos(3) - 20, imgHeight], "ImageClickedFcn", {@imgClicked, app}, ...
                            'Tooltip', "Click to use frame " + num2str(index) + " for calibration", 'Tag', num2str(index));
                    else
                        uiimage(app.Scrollpane, "ScaleMethod",'scaledown', 'ImageSource', ...
                            labeloverlay(app.frames(:, :, index), ones(size(app.frames(:, :, index))), 'Colormap', 'autumn'), "Position", ...
                            [5, (10 + (i - 1)*(imgHeight + 10)), panelPos(3) - 20, imgHeight], "ImageClickedFcn", {@imgClicked, app},'Tooltip', ...
                            "This frame will be ignored during bubble analysis", 'Tag', num2str(index));
                    end
                    
                else
                % Multiview point code 
                
                    %Check if a mask exists for the frame 
                    if ~any(any(app.mask(:, :, index, 1)))
                        img = zeros([size(app.frames(:, :, index)), 3]);
                        img(:, :, 3) = app.frames(:, :, index);
                        scrollpaneImage = hsv2rgb(img);
                    else
                        left = app.mask(:, :, index, 1);
                        right = app.mask(:, :, index, 2);
                        right(right == 1) = 2;
                        scrollpaneImage = labeloverlay(app.frames(:, :, index), left + right, 'Colormap', [0 0 1; 0 1 0; 0 1 1]);
                    end
                    
                    %Populate the uiimage component with the frame/mask
                    if isempty(find(app.ignoreFrames == index, 1))
                        uiimage(app.Scrollpane, "ScaleMethod",'scaledown', 'ImageSource', scrollpaneImage, ...
                            'Position', [5, (10 + (i - 1)*(imgHeight + 10)), panelPos(3) - 20, imgHeight], "ImageClickedFcn", {@imgClicked, app}, ...
                            'Tooltip', "Click to use frame " + num2str(index) + " for calibration", 'Tag', num2str(index));
                    else
                        uiimage(app.Scrollpane, "ScaleMethod",'scaledown', 'ImageSource', ...
                            labeloverlay(app.frames(:, :, index), ones(size(app.frames(:, :, index))), 'Colormap', 'autumn'), "Position", ...
                            [5, (10 + (i - 1)*(imgHeight + 10)), panelPos(3) - 20, imgHeight], "ImageClickedFcn", {@imgClicked, app},'Tooltip', ...
                            "This frame will be ignored during bubble analysis", 'Tag', num2str(index));
                    end
                    
                end
            end
            
            %Callback for what happens if an image is clicked
            function imgClicked(src, ~, app)
                app.workingFrame = str2double(src.Tag);         %Set the working frame
                SetCalibrationFrame(app)                        %Execute calibration set-up code
            end
            
            UpdateLogs(app, 'Population complete');             %Update logs
            close(f);                                           %Close progress bar
        end
        
        function UpdateLogs(app, newText)
            newText = string(newText);
            app.LogArea.Value = [app.LogArea.Value; newText];
        end
        
        function LogExceptions(app, ME)
            UpdateLogs(app, ' ');
            UpdateLogs(app, '---Error Encountered---');
            UpdateLogs(app, append('   MATLAB Exception message: ', ME.message));
            UpdateLogs(app, append('   MATALB Exception identifier: ', ME.identifier));
            stacksize = size(ME.stack, 1);
            UpdateLogs(app, '   ---Begin Stacktrace---');
            for i = 1:stacksize
                UpdateLogs(app, append('      Line ', num2str(ME.stack(i).line), ' in ', ME.stack(i).name));
            end
            UpdateLogs(app, '   ---End Stacktrace---');
            UpdateLogs(app, '---End Error---');
            UpdateLogs(app, ' ');
        end
        
        function SetCalibrationFrame(app)
            g = uiprogressdlg(app.UIFigure, 'Indeterminate', 'on');                 %Progress bar
            
            src = findobj(app.Scrollpane, 'Tag', num2str(app.workingFrame));        %Get the image that was clicked 
            
            app.CalibrationFrame.ImageSource = src.ImageSource;                     %Set the calibration image to the image that was clicked in the scollpane
            
            if ~any(any(app.mask(:, :, app.workingFrame)))
                %If no masks exists, convert the scrollpane/calibration
                %image into an RGB image for the final mask viewer
                mat = zeros([size(app.frames(:, :, app.workingFrame)), 3]);
                mat(:, :, 3) = app.frames(:, :, app.workingFrame);
                finalViewerImg = hsv2rgb(mat);
            else
                if isempty(find(app.ignoreFrames == app.workingFrame, 1))
                    %If the frame is not one to be ignored, then overlay
                    %the mask onto the image with the default color scheme
                    if ~app.MultiviewToggle.UserData
                        %Single view point code
                        finalViewerImg = labeloverlay(app.frames(:, :, app.workingFrame), app.mask(:, :, app.workingFrame));
                    else
                        %Multi view point code
                        left = app.mask(:, :, app.workingFrame, 1);
                        right = app.mask(:, :, app.workingFrame, 2);
                        right(right == 1) = 2;
                        finalViewerImg = labeloverlay(app.frames(:, :, app.workingFrame), left + right, 'Colormap', [0 0 1; 0 1 0; 0 1 1]);
                    end
                else
                    %If the mask is being ignored, overlay the image with
                    %the red colormap
                    if ~app.MultiviewToggle.UserData
                        finalViewerImg = labeloverlay(app.frames(:, :, app.workingFrame), app.mask(:, :, app.workingFrame), 'Colormap', 'autumn');
                    else
                        finalViewerImg = labeloverlay(app.frames(:, :, app.workingFrame), ...
                            app.mask(:, :, app.workingFrame, 1) + app.mask(:, :, app.workingFrame, 2), 'Colormap', 'autumn');
                    end
                end
            end
            
            %Get the raw frame that was clicked
            calibrationImage = app.frames(:, :, app.workingFrame);
            
            %Normalize the lighting if needed
            if app.VLToggle.UserData
                calibrationImage = bubbleDetection.normalizeLighting(calibrationImage, lower(string(app.NLButtonGroup.SelectedObject.Text)), app.IFFToggle.UserData, ...
                    app.frames(:, :, app.BSField.Value));
            end           
            
            %Increase the contrast if needed
            if app.ICToggle.UserData
                calibrationImage = bubbleDetection.increaseContrast(calibrationImage);
            end
            
            %Remove the timestamps if needed
            if app.RTToggle.UserData
                calibrationImage = bubbleDetection.removeTimeStamps(calibrationImage);
            end
                       
            %Set the generic old data
            [row, col] = size(calibrationImage);
            oldData.Center = [col./2, row./2];
            oldData.Size = 0;
            
            %Get or set the color threshold 
            if app.AutoColorToggle.UserData || app.ColorThresholdField.Value == 0
                app.ColorThresholdField.Value = graythresh(calibrationImage);
            end
            
            
            %Get or set the edge threshold 
            if app.AutoEdgeToggle.UserData || app.EdgeThresholdField.Value == 0
                [~, thresh] = edge(calibrationImage, 'Sobel');
                if isnan(thresh)
                    thresh = 0;
                end
                app.EdgeThresholdField.Value = thresh;
            end
            
            %Attempt to generate color and edge masks for the frame
            try
                if ~app.MultiviewToggle.UserData
                    %Single view point code
                    colorMask = bubbleDetection.colorMask(calibrationImage, oldData, app.ColorThresholdField.Value, lower(string(app.CStyle.Value)), app.CVal.Value, ...
                        ~app.BSRadioButton.Value);
                    edgeMask = bubbleDetection.edgeMask(calibrationImage, oldData, app.EdgeThresholdField.Value, lower(string(app.EStyle.Value)), app.EVal.Value);
                else
                    %Multi view point code
                    colorMask = bubbleDetection.multiColor(calibrationImage, app.ColorThresholdField.Value, ...
                        lower(string(app.CStyle.Value)), app.CVal.Value, ~app.BSRadioButton.Value, 2);
                    edgeMask = bubbleDetection.multiEdge(calibrationImage, app.EdgeThresholdField.Value, lower(string(app.EStyle.Value)), app.EVal.Value, 2);
                end
            catch ME
                uialert(app.UIFigure, ME.message, append('Calibration Frame Error: ', ME.identifier), 'Icon', 'error');
                LogExceptions(app, ME);
            end
            
            
            %Create an rgb matrix representing the calibration
            %image
            [row, col] = size(calibrationImage);
            hsv = zeros(row, col, 3);
            hsv(:, :, 3) = calibrationImage;
            rgb = hsv2rgb(hsv);
            
            colorImgSrc = rgb;                               %Create a copy for the color mask image
            rlayer = colorImgSrc(:, :, 1);                   %Separate out the red layer
            glayer = colorImgSrc(:, :, 2);                   %Separate out the green layer
            blayer = colorImgSrc(:, :, 3);                   %Separate out the blue layer
            thinColor = bwmorph(colorMask, 'remove');        %Thin the mask to a one pixel thick outline
            rlayer(thinColor) = 0;                           %Set the red layer equal to 0 where the mask is true
            glayer(thinColor) = 0;                           %Set the green layer equal to 0 where the mask is true
            blayer(thinColor) = 1;                           %Set the blue layer equal to 1 where the mask is true
            
            %Recombine the layers
            colorImgSrc(:, :, 1) = rlayer;                   
            colorImgSrc(:, :, 2) = glayer;
            colorImgSrc(:, :, 3) = blayer;
            
            %See above comments
            edgeImgSrc = rgb;
            rlayer = edgeImgSrc(:, :, 1);
            glayer = edgeImgSrc(:, :, 2);
            blayer = edgeImgSrc(:, :, 3);
            thinEdge = bwmorph(edgeMask, 'remove');
            rlayer(thinEdge) = 0;
            glayer(thinEdge) = 0;
            blayer(thinEdge) = 1;
            edgeImgSrc(:, :, 1) = rlayer;
            edgeImgSrc(:, :, 2) = glayer;
            edgeImgSrc(:, :, 3) = blayer;
            
            %Show the Color and Edge Masks
            app.ColorMask.ImageSource = colorImgSrc;
            app.EdgeMask.ImageSource = edgeImgSrc;
            
            imshow(finalViewerImg ,'Parent', app.FinalMaskViewer);
            app.UpdateLogs("Calibration frame set to: " + num2str(app.workingFrame));
            drawnow;
            close(g);
        end
    end
    
    
    % Callbacks that handle component events
    methods (Access = private)
        
        % Code that executes after component creation
        function startupFcn(app)
            app.initialized = true;
            checkVersion(app);
            figureSizeChanged(app, 0);
            UpdateLogs(app, "Initialization complete.");
            UpdateLogs(app, append('Computer Architecture: ', computer));
            UpdateLogs(app, append('InCA Version: ', num2str(app.Version./10)));
        end
        
        function figureSizeChanged(app, ~)
            %Main Resizing
            f = uiprogressdlg(app.UIFigure, 'Indeterminate', 'on');
            pause(0.5);
            UpdateLogs(app, 'Resizing components...');
            position = app.UIFigure.Position;
            app.TabGroup.Position = [1 1 position(3) position(4)];
            drawnow;
            pause(0.5);
            
            %Home Tab Resizing
            tabPos = app.HomeTab.InnerPosition;
            pause(0.5);
            imgSize = floor(tabPos(3)/3);
            app.HomeImage.Position = [(tabPos(3)./6 - 5), (tabPos(4)/2 - (imgSize/2)), imgSize, imgSize];
            app.VersionLabel.Position = [tabPos(3) - 120, 5, 120, 30];
            app.NewButton.Position = [(tabPos(3)/2 + 5), (tabPos(4)/2 + (imgSize/2) - 30), 90, 30];
            app.NewPath.Position = [(tabPos(3)/2 + 100), (tabPos(4)/2 + (imgSize/2) - 30), (tabPos(3)/3 - 90), 30];
            app.OpenButton.Position = [(tabPos(3)/2 + 5), (tabPos(4)/2 + (imgSize/2) - 70), 90, 30];
            app.OpenPath.Position = [(tabPos(3)/2 + 100), (tabPos(4)/2 + (imgSize/2) - 70), (tabPos(3)/3 - 90), 30];
            app.SaveButton.Position = [(tabPos(3)/2 + 5), (tabPos(4)/2 + (imgSize/2) - 110), 90, 30];
            app.SavePath.Position = [(tabPos(3)/2 + 100), (tabPos(4)/2 + (imgSize/2) - 110), (tabPos(3)/3 - 90), 30];
            
            %Detection Tab Resizing
            tabPos = app.DetectionTab.Position;
            buttonWidth = ((2*tabPos(3)./5) - 15)./3;
            app.Scrollpane.Position = [1, 1, tabPos(3)./5, 992];
            
            app.ResetDetectionButton.Position = [(tabPos(3)./5) + 5, 10, buttonWidth, 30];
            app.ViewResultButton.Position = [(tabPos(3)./5) + 10 + buttonWidth, 10, buttonWidth, 30];
            app.RefineButton.Position = [(tabPos(3)./5) + 15 + 2*buttonWidth, 10, buttonWidth, 30];
            app.MixerLabel.Position = [(tabPos(3)./5) + 15, 105, tabPos(3).*2./5 - 20, 30];
            app.MixerSlider.Position = [(tabPos(3)./5) + 10, 80, ((2*tabPos(3)./5) - 20), 3];
            
            app.ColorMask.Position = [(tabPos(3)./5) + 5, 135, (tabPos(3)./5) - 10, (tabPos(3)./7) - 10];
            app.EdgeMask.Position = [(2*tabPos(3)./5) + 5, 135, (tabPos(3)./5) - 10, (tabPos(3)./7) - 10];
            
            app.MultiviewLabel.Position = [2.*(tabPos(3))./5 + 65, 962, ((tabPos(3))./5) - 60, 20];
            app.MultiviewToggle.Position = [2.*(tabPos(3))./5 + 10, 962, 40, 20];
            app.IFFLabel.Position = [(tabPos(3)).*2./5 + 65, 932, ((tabPos(3))./5) - 60, 20];
            app.IFFToggle.Position = [(tabPos(3)).*2./5 + 10, 932, 40, 20];
            app.ICToggle.Position = [(tabPos(3)).*2./5 + 10, 902, 40, 20];
            app.ICLabel.Position = [(tabPos(3)).*2./5 + 65, 902, ((tabPos(3))./5) - 60, 20];
            app.RTToggle.Position = [(tabPos(3)).*2./5 + 10, 872, 40, 20];
            app.RTLabel.Position = [(tabPos(3)).*2./5 + 65, 872, ((tabPos(3))./5) - 60, 20];
            app.VLToggle.Position = [(tabPos(3)).*2./5 + 10, 842, 40, 20];
            app.VLLabel.Position = [(tabPos(3)).*2./5 + 65, 842, ((tabPos(3))./5) - 60, 20];
            app.NLButtonGroup.Position = [(tabPos(3)).*2./5 + 10, 782, ((tabPos(3))./5) - 20, 55];
            app.BSRadioButton.Position = [5, 30, app.NLButtonGroup.Position(3) - 10, 20];
            app.GARadioButton.Position = [5, 5, app.NLButtonGroup.Position(3) - 10, 20];
            app.BSLabel.Position = [(tabPos(3)).*2./5 + 10, 747, ((tabPos(3)./5 - 30)./2), 25];
            app.BSField.Position = [(tabPos(3)).*2./5 + ((tabPos(3)./5 - 30)./2) + 20, 747, ((tabPos(3)./5 - 30)./2), 25];
            
            app.RunDetectionButton.Position = [2.*(tabPos(3)./5) + 10, 687, (tabPos(3)./5) - 20, 50];
            app.CalibrationFrame.Position = [(tabPos(3)./5) + 10, 734, (tabPos(3)./5) - 10, 248];
            
            app.ColorLabel.Position = [(tabPos(3)./5) + 10, 657, tabPos(3)./5 - 20, 25];
            app.EdgeLabel.Position = [2.*(tabPos(3)./5) + 10, 657, tabPos(3)./5 - 20, 25];
            
            app.CStyleLabel.Position = [(tabPos(3)./5) + 20, 624, (tabPos(3)./5 - 40)./2, 25];
            app.CStyle.Position = [(3.*tabPos(3)./10) + 20, 624, (tabPos(3)./5 - 40)./2, 25];
            app.CValLabel.Position = [(tabPos(3)./5) + 20, 589, (tabPos(3)./5 - 40)./2, 25];
            app.CVal.Position = [(3.*tabPos(3)./10) + 20, 589, (tabPos(3)./5 - 40)./2, 25];
            app.AutoColorToggle.Position = [(tabPos(3)./5) + 20, 559, 40, 20];
            app.AutoColorLabel.Position = [(tabPos(3)./5) + 70, 559, tabPos(3)./5 - 80, 20];
            app.ColorThresholdLabel.Position = [(tabPos(3)./5) + 20, 524, (tabPos(3)./5 - 40)./2, 25];
            app.ColorThresholdField.Position = [(3.*tabPos(3)./10) + 20, 524, (tabPos(3)./5 - 40)./2, 25];
            
            app.EStyleLabel.Position = [2.*(tabPos(3)./5) + 20, 624, (tabPos(3)./5 - 40)./2, 25];
            app.EStyle.Position = [(5.*tabPos(3)./10) + 20, 624, (tabPos(3)./5 - 40)./2, 25];
            app.EValLabel.Position = [2.*(tabPos(3)./5) + 20, 589, (tabPos(3)./5 - 40)./2, 25];
            app.EVal.Position = [(5.*tabPos(3)./10) + 20, 589, (tabPos(3)./5 - 40)./2, 25];
            app.AutoEdgeToggle.Position = [2*(tabPos(3)./5) + 20, 559, 40, 20];
            app.AutoEdgeLabel.Position = [2*(tabPos(3)./5) + 70, 559, tabPos(3)./5 - 80, 20];
            app.EdgeThresholdLabel.Position = [2.*(tabPos(3)./5) + 20, 524, (tabPos(3)./5 - 40)./2, 25];
            app.EdgeThresholdField.Position = [(5.*tabPos(3)./10) + 20, 524, (tabPos(3)./5 - 40)./2, 25];
            
            app.FinalMaskViewer.Position = [tabPos(3)*3./5 + 10, 70, (tabPos(3).*2./5 - 20), 912];
            app.PreviousFrameDetectionButton.Position = [tabPos(3) - (tabPos(3).*2./5 - 20), 10, ((tabPos(3)*2./5) - 60)./5, 50];
            app.NextFrameDetectionButton.Position = [tabPos(3)*3./5 + 4.*(((tabPos(3)*2./5) - 60)./5) + 40, 10, ((tabPos(3)*2./5) - 60)./5, 50];
            app.AcceptFrameButton.Position = [tabPos(3)*3./5 + 3.*(((tabPos(3)*2./5) - 60)./5) + 30, 10, ((tabPos(3)*2./5) - 60)./5, 50];
            app.RejectFrameButton.Position = [tabPos(3)*3./5 + 1.*(((tabPos(3)*2./5) - 60)./5) + 30, 10, ((tabPos(3)*2./5) - 60)./5, 50];
            
            
            %Analysis Tab Resizing
            tabPos = app.AnalysisTab.Position;
            app.PreviousFrameButton.Position = [10, 5, (tabPos(3)./5 - 30)/2, 35];
            app.NextFrameButton.Position = [tabPos(3)/10 + 5, 5, (tabPos(3)./5 - 30)/2, 35];
            app.JumpFrameLabel.Position = [10, 45, (tabPos(3)./5 - 30)/2, 25];
            app.JumpFrameField.Position = [tabPos(3)/10 + 5, 45, (tabPos(3)./5 - 30)/2, 25];
            app.AnalyzeButton.Position = [10, 75, tabPos(3)./5 - 20, 35];
            app.RefreshPlotsButton.Position = [10, 115, tabPos(3)./5 - 20, 35];
            app.InspectFrameButton.Position = [10, 155, tabPos(3)./5 - 20, 35];
            
            %Settings Panel Resizing
            app.SettingsPanel.Position = [1, 195, tabPos(3)./5, tabPos(4) - 195];
            panelPos = app.SettingsPanel.Position;
            app.MPXLabel.Position = [10, panelPos(4) - 30, (panelPos(3) - 30)./2, 25];
            app.MPXField.Position = [panelPos(3)./2 + 5, panelPos(4) - 30, (panelPos(3) - 30)./2 - 40, 25];
            app.FPSLabel.Position = [10, panelPos(4) - 60, (panelPos(3) - 30)./2, 25];
            app.FPSField.Position = [panelPos(3)./2 + 5, panelPos(4) - 60, (panelPos(3) - 30)./2 - 40, 25];
            app.TPLabel.Position = [10, panelPos(4) - 90, (panelPos(3) - 30)./2, 25];
            app.TPField.Position = [panelPos(3)./2 + 5, panelPos(4) - 90, (panelPos(3) - 30)./2 - 40, 25];
            
            app.RotationAxis.ButtonGroup.Position = [10, panelPos(4) - 240, panelPos(3) - 40, 140];
            app.RotationAxis.VerticalButton.Position = [5, 5, app.RotationAxis.ButtonGroup.Position(3) - 10, 25];
            app.RotationAxis.HorizontalButton.Position = [5, 35, app.RotationAxis.ButtonGroup.Position(3) - 10, 25];
            app.RotationAxis.MinorButton.Position = [5, 65, app.RotationAxis.ButtonGroup.Position(3) - 10, 25];
            app.RotationAxis.MajorButton.Position =  [5, 95, app.RotationAxis.ButtonGroup.Position(3) - 10, 25];
            
            app.FourierFitToggle.Position = [10, panelPos(4) - 275, 40, 20];
            app.FourierFitToggleLabel.Position = [60, panelPos(4) - 275, panelPos(3) - 70, 20];
            
            app.FitType.ButtonGroup.Position = [10, panelPos(4) - 400, panelPos(3) - 40, 110];
            app.FitType.ParametricButton.Position = [5, 5, app.FitType.ButtonGroup.Position(3) - 10, 25];
            app.FitType.PolarPButton.Position = [5, 35, app.FitType.ButtonGroup.Position(3) - 10, 25];
            app.FitType.PolarSButton.Position = [5, 65, app.FitType.ButtonGroup.Position(3) - 10, 25];
            
            app.MinArcLengthLabel.Position = [10, panelPos(4) - 430, (panelPos(3) - 30)./2, 25];
            app.MinArcLengthField.Position = [panelPos(3)./2 + 5, panelPos(4) - 430, (panelPos(3) - 30)./2 - 40, 25];
            
            app.AdaptiveTermsToggle.Position = [10, panelPos(4) - 460, 40, 20];
            app.AdaptiveTermsToggleLabel.Position = [60, panelPos(4) - 460, panelPos(3) - 70, 20];
            
            app.MaxTermsLabel.Position = [10, panelPos(4) - 490, (panelPos(3) - 30)./2, 25];
            app.MaxTermsField.Position = [panelPos(3)./2 + 5, panelPos(4) - 490, (panelPos(3) - 30)./2 - 40, 25];
            app.TermsofInterestLabel.Position = [10, panelPos(4) - 520, (panelPos(3) - 30)./2, 25];
            app.TermsofInterestField.Position = [panelPos(3)./2 + 5, panelPos(4) - 520, (panelPos(3) - 30)./2 - 40, 25];
            app.MetricTermsLabel.Position = [10, panelPos(4) - 550, (panelPos(3) - 30)./2, 25];
            app.MetricTermsField.Position = [panelPos(3)./2 + 5, panelPos(4) - 550, (panelPos(3) - 30)./2 - 40, 25];
            
            app.DecompositionPanel.Position = [10 panelPos(4) - 680, panelPos(3) - 40, 125];
            subPanel = app.DecompositionPanel.Position;
            app.DecomposeButton.Position = [10 5,  subPanel(3) - 20, 35];
            app.DecompositionTermsLabel.Position = [10, 45, (subPanel(3) - 30)./2, 25];
            app.DecompositionTermsField.Position = [subPanel(3)./2 + 5, 45, (subPanel(3) - 30)./2, 25];
            app.TargetFrameLabel.Position = [10, 75, (subPanel(3) - 30)./2, 25];
            app.TargetFrameField.Position = [subPanel(3)./2 + 5, 75, (subPanel(3) - 30)./2, 25];
            
            
            scroll(app.SettingsPanel, 'top');
            
            %Plot Panel Resizing
            app.PlotPanel.Position = [tabPos(3)./5, 1, 4*tabPos(3)/5 - tabPos(4)./2, tabPos(4)];
            panelPos = app.PlotPanel.Position;
            app.FourierSecond.Position = [5, 5, 105 40];
            app.FourierLast.Position = [panelPos(3) - 105, 5, 100, 40];
            app.FourierColorMap.Position = [115, 5, panelPos(3) - 225, 40];
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
            app.AsphericityPlot.Position = [10, 50, panelPos(3) - 40, panelPos(4)./2];
            app.TwoDimensionalFitPlot.Position = [10, (panelPos(4)./2 + 60), panelPos(3) - 40, panelPos(3)./3];
            app.RadiusFitPlot.Position = [10, (panelPos(4)./2 + 60) + 1*(panelPos(3)./3 + 10), panelPos(3) - 40, panelPos(3)./3];
            app.CentroidFirst.Position = [5, (panelPos(4)./2 + 60) + 2*(panelPos(3)./3 + 10) + 10, 100 40];
            app.CentroidLast.Position = [panelPos(3) - 125, (panelPos(4)./2 + 60) + 2*(panelPos(3)./3 + 10) + 10, 100, 40];
            app.CentroidPlot.OuterPosition = [10, (panelPos(4)./2 + 60) + 2*(panelPos(3)./3 + 10) + 60, (panelPos(3) - 30)./2,(panelPos(3) - 30)./2];
            app.OrientationPlot.OuterPosition = [panelPos(3)./2 + 5, (panelPos(4)./2 + 60) + 2*(panelPos(3)./3 + 10) + 60, (panelPos(3) - 50)./2, (panelPos(3) - 50)./2];
            app.VelocityPlot.Position = [10, panelPos(4)./2 + 105 + 2*(panelPos(3)./3 + 10) + panelPos(3)./2 , panelPos(3) - 40, panelPos(3)./3];
            app.ThreeDimensionalPlot.Position = [10, panelPos(4)./2 + 105 + 3*(panelPos(3)./3 + 10) + panelPos(3)./2 , panelPos(3) - 40, panelPos(3)./3];
            app.TwoDimensionalPlot.Position = [10, panelPos(4)./2 + 105 + 4*(panelPos(3)./3 + 10) + panelPos(3)./2 , panelPos(3) - 40, panelPos(3)./3];
            app.RadiusPlot.Position = [10, panelPos(4)./2 + 105 + 5*(panelPos(3)./3 + 10) + panelPos(3)./2 , panelPos(3) - 40, panelPos(3)./3];
            scroll(app.PlotPanel, 'top');
            
            %Viewer Panel Resizing
            app.ViewerPanel.Position = [tabPos(3) - tabPos(4)./2, 1, tabPos(4)./2, tabPos(4)];
            panelPos = app.ViewerPanel.Position;
            app.MainPlot.OuterPosition = [10, panelPos(4)./2 + 10, panelPos(3) - 20, (panelPos(4) - 30)./2];
            app.EvolutionFirst.Position = [10, 5, 100, 40];
            app.EvolutionLast.Position = [panelPos(3) - 100, 5, 90, 40];
            app.EvolutionPlot.OuterPosition = [10, 50, panelPos(3) - 20, (panelPos(4)./2 - 50)];
            
            %Logs Tab Resizing'
            tabPos = app.LogsTab.Position;
            app.LogArea.Position = [10, 10, (tabPos(3) - 20), (tabPos(4) - 20)];
            app.DownloadButton.Position = [tabPos(3) - 90, 30, 70, 70];
            
            UpdateLogs(app, 'Resize Complete');
            drawnow;
            close(f);
            
        end
        
        function NewClicked(app, ~)
            app.batchmode = false;
            UpdateLogs(app, 'Loading new video...');
            try
                resetFunction(app);
                f = uiprogressdlg(app.UIFigure, 'Title', "Please Wait", 'Message', "Loading video...", 'Indeterminate', 'on');
                [app.frames, vidPath, vidFile] = incaio.loadFrames();
                app.NewPath.Value = append(vidPath, vidFile);
                UpdateLogs(app, append('Loading video from: ', app.NewPath.Value));
                figure(app.UIFigure);
                [~, ~, app.numFrames] = size(app.frames);
                UpdateLogs(app, append('Number of Frames: ', num2str(app.numFrames)));
                app.mask = zeros(size(app.frames));
                try
                    populateScrollpane(app);
                catch mesub
                    uialert(app.UIFigure, mesub.message, append('Scrollpane Open Error: ', mesub.identifier), 'Icon', 'error');
                    LogExceptions(app, mesub);
                end
                close(f);
                uialert(app.UIFigure, 'Video loaded!', 'Success', 'Icon',"success", "Modal", true);
            catch mesub
                uialert(app.UIFigure, mesub.message, append('File Open Error: ', mesub.identifier), 'Icon', 'error');
                LogExceptions(app, mesub);
            end
        end
        
        function OpenClicked(app, ~)
            w = uiprogressdlg(app.UIFigure, "Title", 'Please wait', 'Message', 'Loading data...', 'Indeterminate',"on");
            try
                resetFunction(app);
                [app, op] = incaio.readFromFile(app);
                if string(op) ~= ''
                    app.OpenPath.Value = op;
                end
                populateScrollpane(app);
                RefreshClicked(app);
            catch me
                uialert(app.UIFigure, me.message, append('Open Error: ', me.identifier), 'Icon', 'error');
                LogExceptions(app, me);
            end
            figure(app.UIFigure);
            pause(0.01);
            close(w);
        end
        
        function SaveClicked(app, ~)
            UpdateLogs(app, "Saving analysis...");
            try
                f = uiprogressdlg(app.UIFigure, "Title", "Please wait", 'Message', 'Saving...', "Indeterminate", "on");
                savePath = incaio.writeToFile(app);
                if string(savePath) ~= ''
                    app.SavePath.Value = savePath;
                    uialert(app.UIFigure, "Save complete!", 'Message', 'Icon', "success");
                    figure(app.UIFigure);
                end
                close(f);
                UpdateLogs(app, append("Success! Analysis saved to: ", app.SavePath.Value));
            catch me
                uialert(app.UIFigure, me.message, append('Save Error: ', me.identifier), 'Icon', 'error');
                LogExceptions(app, me);
            end
        end
        
        function BatchClicked(app, ~)
            if app.BatchButton.Value
                app.BatchPanel.Enable = 'on';
            else
                app.BatchPanel.Enable = 'off';
            end
        end
        
        function ResetDetectionClicked(app, ~)
            app.MixerSlider.Value = 50;
            calImgThree = rgb2hsv(app.CalibrationFrame.ImageSource);
            calImg = calImgThree(:, :, 3);
            app.ColorThresholdField.Value = graythresh(calImg);
            [~, thresh] = edge(calImg, 'Sobel');
            app.EdgeThresholdField.Value = thresh;
        end
        
        function ViewResultClicked(app, ~)
            f = uiprogressdlg(app.UIFigure, 'Indeterminate', 'on', 'Title', 'Please wait', 'Message', 'Refining...');
            calibrationImage = app.frames(:, :, app.workingFrame);
            
            %Normalize the lighting if needed
            if app.VLToggle.UserData
                calibrationImage = bubbleDetection.normalizeLighting(calibrationImage, lower(string(app.NLButtonGroup.SelectedObject.Text)), app.IFFToggle.UserData, ...
                    app.frames(:, :, app.BSField.Value));
            end
            
            %Increase the contrast if needed
            if app.ICToggle.UserData
                calibrationImage = bubbleDetection.increaseContrast(calibrationImage);
            end
            
            %Remove the timestamps if needed
            if app.RTToggle.UserData
                calibrationImage = bubbleDetection.removeTimeStamps(calibrationImage);
            end
            
            %Set generic old data values
            [row, col] = size(calibrationImage);
            oldData.Center = [col./2, row./2];
            oldData.Size = 0;
            
            try
                %Get or set the color threshold value
                if ~app.AutoColorToggle.UserData
                    gt = app.ColorThresholdField.Value;    
                else
                    gt = graythresh(calibrationImage);
                end
                
                %Get or set the edge threshold value
                if ~app.AutoEdgeToggle.UserData
                    et = app.EdgeThresholdField.Value;
                else
                    [~, et] = edge(calibrationImage, 'Sobel');
                end
                
                %Determine if the image needs to be flipped during color
                %masking
                flip = ~app.BSRadioButton.Value && ~app.VLToggle.UserData;
                
                %Create and mix the color and edge masks
                if ~app.MultiviewToggle.UserData
                    colorMask = bubbleDetection.colorMask(calibrationImage, oldData, gt, lower(string(app.CStyle.Value)), app.CVal.Value, ...
                        flip);
                    edgeMask = bubbleDetection.edgeMask(calibrationImage, oldData, et, lower(string(app.EStyle.Value)), app.EVal.Value);
                    finalMask = bubbleDetection.mixMasks(colorMask, edgeMask, app.MixerSlider.Value);
                else
                    colorMask = bubbleDetection.multiColor(calibrationImage, gt, lower(string(app.CStyle.Value)), app.CVal.Value, ...
                        flip, 2);
                    edgeMask = bubbleDetection.multiEdge(calibrationImage, et, lower(string(app.EStyle.Value)), app.EVal.Value, 2);
                    finalMask = bubbleDetection.mixMasks(colorMask, edgeMask, app.MixerSlider.Value);
                end
                
                %Create an rgb matrix representing the calibration
                %image
                [row, col] = size(calibrationImage);
                hsv = zeros(row, col, 3);
                hsv(:, :, 3) = calibrationImage;
                rgb = hsv2rgb(hsv);
                
                colorImgSrc = rgb;                               %Create a copy for the color mask image
                rlayer = colorImgSrc(:, :, 1);                   %Separate out the red layer
                glayer = colorImgSrc(:, :, 2);                   %Separate out the green layer
                blayer = colorImgSrc(:, :, 3);                   %Separate out the blue layer
                thinColor = bwmorph(colorMask, 'remove');        %Thin the mask to a one pixel thick outline
                rlayer(thinColor) = 0;                           %Set the red layer equal to 0 where the mask is true
                glayer(thinColor) = 0;                           %Set the green layer equal to 0 where the mask is true
                blayer(thinColor) = 1;                           %Set the blue layer equal to 1 where the mask is true
                colorImgSrc(:, :, 1) = rlayer;                   %Recombine the layers
                colorImgSrc(:, :, 2) = glayer;
                colorImgSrc(:, :, 3) = blayer;
                
                edgeImgSrc = rgb;
                rlayer = edgeImgSrc(:, :, 1);
                glayer = edgeImgSrc(:, :, 2);
                blayer = edgeImgSrc(:, :, 3);
                thinEdge = bwmorph(edgeMask, 'remove');
                rlayer(thinEdge) = 0;
                glayer(thinEdge) = 0;
                blayer(thinEdge) = 1;
                edgeImgSrc(:, :, 1) = rlayer;
                edgeImgSrc(:, :, 2) = glayer;
                edgeImgSrc(:, :, 3) = blayer;
                
                %Set the image for the preview images
                app.ColorMask.ImageSource = colorImgSrc;
                app.EdgeMask.ImageSource = edgeImgSrc;
                
                %Split the masks if needed
                if app.MultiviewToggle.UserData
                    [left, right] = bubbleDetection.separateViews(app.frames(:, :, app.workingFrame), finalMask, 2);
                    right(right == 1) = 2;
                    finalMask = left + right;
                end
                
                %Show the mask in the final mask viewer
                imshow(labeloverlay(app.frames(:, :, app.workingFrame), finalMask, 'Colormap', [0 0 1; 0 1 0; 0 1 1]), 'Parent', app.FinalMaskViewer);
            catch ME
                uialert(app.UIFigure, ME.message, append('Mask Preview Error: ', ME.identifier), 'Icon', 'error');
                LogExceptions(app, ME);
            end
            close(f);
        end
        
        function RefineClicked(app, ~)
            f = uiprogressdlg(app.UIFigure, 'Indeterminate', 'on', 'Title', 'Please wait', 'Message', 'Refining...');
            calibrationImage = app.frames(:, :, app.workingFrame);
            
            %Normalize the lighting if needed
            if app.VLToggle.UserData
                calibrationImage = bubbleDetection.normalizeLighting(calibrationImage, lower(string(app.NLButtonGroup.SelectedObject.Text)), app.IFFToggle.UserData, ...
                    app.frames(:, :, app.BSField.Value));
            end
            
            %Increase the contrast if needed
            if app.ICToggle.UserData
                calibrationImage = bubbleDetection.increaseContrast(calibrationImage);
            end
            
            %Remove the timestamps if needed
            if app.RTToggle.UserData
                calibrationImage = bubbleDetection.removeTimeStamps(calibrationImage);
            end
            
            %Set generic old data values
            [row, col] = size(calibrationImage);
            oldData.Center = [col./2, row./2];
            oldData.Size = 0;
            
            try
                %Get or set the color threshold value
                if ~app.AutoColorToggle.UserData
                    gt = app.ColorThresholdField.Value;    
                else
                    gt = graythresh(calibrationImage);
                end
                
                %Get or set the edge threshold value
                if ~app.AutoEdgeToggle.UserData
                    et = app.EdgeThresholdField.Value;
                else
                    [~, et] = edge(calibrationImage, 'Sobel');
                end
                
                %Determine if the image needs to be flipped during color
                %masking
                flip = ~app.BSRadioButton.Value && ~app.VLToggle.UserData;
                
                %Create and mix the color and edge masks
                if ~app.MultiviewToggle.UserData
                    colorMask = bubbleDetection.colorMask(calibrationImage, oldData, gt, lower(string(app.CStyle.Value)), app.CVal.Value, ...
                        flip);
                    edgeMask = bubbleDetection.edgeMask(calibrationImage, oldData, et, lower(string(app.EStyle.Value)), app.EVal.Value);
                    finalMask = bubbleDetection.mixMasks(colorMask, edgeMask, app.MixerSlider.Value);
                else
                    colorMask = bubbleDetection.multiColor(calibrationImage, gt, lower(string(app.CStyle.Value)), app.CVal.Value, ...
                        flip, 2);
                    edgeMask = bubbleDetection.multiEdge(calibrationImage, et, lower(string(app.EStyle.Value)), app.EVal.Value, 2);
                    finalMask = bubbleDetection.mixMasks(colorMask, edgeMask, app.MixerSlider.Value);
                end
                
                %Create an rgb matrix representing the calibration
                %image
                [row, col] = size(calibrationImage);
                hsv = zeros(row, col, 3);
                hsv(:, :, 3) = calibrationImage;
                rgb = hsv2rgb(hsv);
                
                colorImgSrc = rgb;                               %Create a copy for the color mask image
                rlayer = colorImgSrc(:, :, 1);                   %Separate out the red layer
                glayer = colorImgSrc(:, :, 2);                   %Separate out the green layer
                blayer = colorImgSrc(:, :, 3);                   %Separate out the blue layer
                thinColor = bwmorph(colorMask, 'remove');        %Thin the mask to a one pixel thick outline
                rlayer(thinColor) = 0;                           %Set the red layer equal to 0 where the mask is true
                glayer(thinColor) = 0;                           %Set the green layer equal to 0 where the mask is true
                blayer(thinColor) = 1;                           %Set the blue layer equal to 1 where the mask is true
                colorImgSrc(:, :, 1) = rlayer;                   %Recombine the layers
                colorImgSrc(:, :, 2) = glayer;
                colorImgSrc(:, :, 3) = blayer;
                
                edgeImgSrc = rgb;
                rlayer = edgeImgSrc(:, :, 1);
                glayer = edgeImgSrc(:, :, 2);
                blayer = edgeImgSrc(:, :, 3);
                thinEdge = bwmorph(edgeMask, 'remove');
                rlayer(thinEdge) = 0;
                glayer(thinEdge) = 0;
                blayer(thinEdge) = 1;
                edgeImgSrc(:, :, 1) = rlayer;
                edgeImgSrc(:, :, 2) = glayer;
                edgeImgSrc(:, :, 3) = blayer;
                
                %Set the image for the preview images
                app.ColorMask.ImageSource = colorImgSrc;
                app.EdgeMask.ImageSource = edgeImgSrc;
                
                %Assign the final masks to the output array
                if app.MultiviewToggle.UserData
                    [left, right] = bubbleDetection.separateViews(app.frames(:, :, app.workingFrame), finalMask, 2);
                    app.mask(:, :, app.workingFrame, 1) = left;
                    app.mask(:, :, app.workingFrame, 2) = right;
                    right(right == 1) = 2;
                    finalMask = left + right;
                else
                    app.mask(:, :, app.workingFrame) = finalMask;
                end
                
                %Show the mask in the final mask viewer
                imshow(labeloverlay(app.frames(:, :, app.workingFrame), finalMask, 'Colormap', [0 0 1; 0 1 0; 0 1 1]), 'Parent', app.FinalMaskViewer);
            catch ME
                uialert(app.UIFigure, ME.message, append('Mask Preview Error: ', ME.identifier), 'Icon', 'error');
                LogExceptions(app, ME);
            end
            
            %Update the scrollpane image
            src = findobj(app.Scrollpane, 'Tag', num2str(app.workingFrame));
            src.ImageSource = labeloverlay(app.frames(:, :, app.workingFrame), finalMask, 'Colormap', [0 0 1; 0 1 0; 0 1 1]);
            
            %Remove the current frame from the ignore frames list (if its
            %there)
            app.ignoreFrames = app.ignoreFrames(app.ignoreFrames ~= app.workingFrame);
            
            %Update the calibration image
            app.CalibrationFrame.ImageSource = labeloverlay(app.frames(:, :, app.workingFrame), finalMask, 'Colormap', [0 0 1; 0 1 0; 0 1 1]);
            close(f);
        end
        
        function RunDetection(app, ~)
            try
                %Enable final mask viewer buttons
                app.NextFrameDetectionButton.Enable = 'on';
                app.PreviousFrameDetectionButton.Enable = 'on';
                app.AcceptFrameButton.Enable = 'on';
                app.RejectFrameButton.Enable = 'on';
                
                %Copy the original frames into a new variable in case they
                %need to be preprocessed
                framesNew = app.frames;
                
                %Normalize lighting if desired
                if app.VLToggle.UserData
                    framesNew = bubbleDetection.normalizeLighting(framesNew, lower(string(app.NLButtonGroup.SelectedObject.Text)), app.IFFToggle.UserData, ...
                        app.frames(:, :, app.BSField.Value));
                end
                
                %Increase the contrast if desired
                if app.ICToggle.UserData
                    framesNew = bubbleDetection.increaseContrast(framesNew);
                end
                
                %Remove Embeded Timestamps if any
                if app.RTToggle.UserData
                    framesNew = bubbleDetection.removeTimeStamps(framesNew);
                end               
                
                
                %If the first frame should be ignored, add it to the array
                %of frames to ignore
                if app.IFFToggle.UserData
                    app.ignoreFrames(end + 1) = 1;
                end
                
                %Determine if the mask needs to be flipped during color
                %masking
                flip = ~app.BSRadioButton.Value && ~app.VLToggle.UserData;
                
                %Run Detection on the Preprocessed Frames
                if ~app.MultiviewToggle.UserData
                    %Mask generation for single viewpoint videos
                    app.mask = bubbleDetection.runDetection(framesNew, app.ColorThresholdField.Value, app.EdgeThresholdField.Value, app.MixerSlider.Value, ...
                        app.IFFToggle.UserData, lower(string(app.CStyle.Value)), app.CVal.Value, lower(string(app.EStyle.Value)), app.EVal.Value, app.UIFigure, ...
                        app.AutoColorToggle.UserData, app.AutoEdgeToggle.UserData, flip);
                else
                    %Mask generation for multi viewpoint videos 
                    app.mask = bubbleDetection.multiDetect(framesNew, app.ColorThresholdField.Value, app.EdgeThresholdField.Value, app.MixerSlider.Value, ...
                        app.IFFToggle.UserData, lower(string(app.CStyle.Value)), app.CVal.Value, lower(string(app.EStyle.Value)), app.EVal.Value, app.UIFigure, ...
                        app.AutoColorToggle.UserData, app.AutoEdgeToggle.UserData, flip, 2, app.ignoreFrames, app.frames);
                end
                
                %Attempt to repopulate the scrollpane with the new masks
                try
                    populateScrollpane(app);
                catch ME
                    uialert(app.UIFigure, ME.message, append('Mask Preview Error: ', ME.identifier), 'Icon', 'error');
                    LogExceptions(app, ME);
                end
                
            catch ME
                uialert(app.UIFigure, ME.message, append('Mask Detection Error: ', ME.identifier), 'Icon', 'error');
                LogExceptions(app, ME);
            end
        end
        
        function PDClicked(app, ~)
            if app.workingFrame == 1 + app.IFFToggle.UserData
                app.workingFrame = app.numFrames;
            else
                app.workingFrame = app.workingFrame -1;
            end
            SetCalibrationFrame(app);
        end
        
        function NDClicked(app, ~)
            if app.workingFrame == app.numFrames
                app.workingFrame = 1 + app.IFFToggle.UserData;
            else
                app.workingFrame = app.workingFrame + 1;
            end
            SetCalibrationFrame(app);
        end
        
        function AcceptClicked(app, ~)
            app.ignoreFrames = app.ignoreFrames(app.ignoreFrames ~= app.workingFrame);
            frameofInterest = findobj(app.Scrollpane, 'Tag', num2str(app.workingFrame));
            if any(any(app.mask(:, :, app.workingFrame, 1)))
                if ~app.MultiviewToggle.UserData
                    frameofInterest.ImageSource = labeloverlay(app.frames(:, :, app.workingFrame), app.mask(:, :, app.workingFrame));
                    app.CalibrationFrame.ImageSource = labeloverlay(app.frames(:, :, app.workingFrame), app.mask(:, :, app.workingFrame));
                else
                    frameofInterest.ImageSource = labeloverlay(app.frames(:, :, app.workingFrame), ...
                        app.mask(:, :, app.workingFrame, 1) + app.mask(:, :, app.workingFrame, 2));
                    app.CalibrationFrame.ImageSource = labeloverlay(app.frames(:, :, app.workingFrame), ...
                        app.mask(:, :, app.workingFrame, 1) + app.mask(:, :, app.workingFrame, 2));
                end
            else
                plainimage = zeros(size(app.frames(:, :, app.workingFrame)));
                plainimage(:, :, 3) = app.frames(:, :, app.workingFrame);
                plainimage = hsv2rgb(plainimage);
                frameofInterst.ImageSource = plainimage;
                app.CalibrationFrame.ImageSource = plainimage;
            end
            frameofInterst.Tooltip = "Click to ignore frame " + num2str(app.workingFrame) + " during calculations";
            if ~app.MultiviewToggle.UserData
                imshow(labeloverlay(app.frames(:, :, app.workingFrame), app.mask(:, :, app.workingFrame), 'Colormap', [0 0.9 0.3]), 'Parent', app.FinalMaskViewer);
            else
                imshow(labeloverlay(app.frames(:, :, app.workingFrame), app.mask(:, :, app.workingFrame, 1) + app.mask(:, :, app.workingFrame, 2), ...
                    'Colormap', [0 0.9 0.3]), 'Parent', app.FinalMaskViewer);
            end
            UpdateLogs(app, append("Will not ignore frame: ", num2str(app.workingFrame)));
            drawnow;
        end
        
        function RejectClicked(app, ~)
            app.ignoreFrames(length(app.ignoreFrames) + 1) = app.workingFrame;
            frameofInterest = findobj(app.Scrollpane, 'Tag', num2str(app.workingFrame));
            dontUseMask = ones(size(app.frames(:, :, app.workingFrame)));
            frameofInterest.ImageSource = labeloverlay(app.frames(:, :, app.workingFrame), dontUseMask, 'Colormap', 'autumn');
            app.CalibrationFrame.ImageSource = labeloverlay(app.frames(:, :, app.workingFrame), dontUseMask, 'Colormap', 'autumn');
            frameofInterset.Tooltip = "This frame will be ignored during bubble analysis";
            if ~app.MultiviewToggle.UserData
                imshow(labeloverlay(app.frames(:, :, app.workingFrame), app.mask(:, :, app.workingFrame), 'Colormap', 'autumn'), 'Parent', app.FinalMaskViewer);
            else 
                imshow(labeloverlay(app.frames(:, :, app.workingFrame), app.mask(:, :, app.workingFrame, 1) + app.mask(:, :, app.workingFrame, 2)...
                    , 'Colormap', 'autumn'), 'Parent', app.FinalMaskViewer);
            end
            UpdateLogs(app, append("Ignoring frame: ", num2str(app.workingFrame)));
            drawnow;
        end
        
        function AnalyzePushed(app, ~)
            clear app.maskInformation
            clear app.plotSet
            
            %Check the conversion factors
            if app.MPXField.Value == 1 && app.FPSField.Value == 1
                confirm = uiconfirm(app.UIFigure, 'Default conversion factors have not been altered. Continue with current conversion factors?', ...
                    'Please confirm', 'Icon', 'warning', 'Options', {'Continue', 'Cancel'});
                if string(confirm) == "Cancel"
                    return;
                end
            end
            
            %Analyze the masks
            try
                app.maskInformation = bubbleAnalysis.bubbleTrack(app, app.mask, app.MinArcLengthField.Value, ...
                    lower(string(app.RotationAxis.ButtonGroup.SelectedObject.Text)),...
                    app.FourierFitToggle.UserData, app.MaxTermsField.Value, app.AdaptiveTermsToggle.UserData, app.ignoreFrames, ...
                    lower(string(app.FitType.ButtonGroup.SelectedObject.Text)));
            catch ME
                uialert(app.UIFigure, ME.message, append('Analysis Error: ', ME.identifier), 'Icon', 'error');
                LogExceptions(app, ME);
            end
            
            %Generate the plot data
            f = uiprogressdlg(app.UIFigure ,"Title", "Please wait", "Message", "Configuring for plotting...", "Indeterminate","on");
            try
                app.plotSet = plotting.generatePlotData(app);
            catch ME
                close(f);
                uialert(app.UIFigure, ME.message, append('Plot Data Generation Error: ', ME.identifier), 'Icon', 'error');
                LogExceptions(app, ME);
            end
            
            %Try to plot the data
            try
                plotting.displayCurrentFrame(app);
                plotting.dispEvolution(app);
                plotting.plotData(app.plotSet, app.RadiusPlot, app.TwoDimensionalPlot, app.ThreeDimensionalPlot, app.CentroidPlot, app.OrientationPlot, app.numFrames);
                plotting.plotVelocity(app.VelocityPlot, app.plotSet.velocity);
                if app.FourierFitToggle.UserData
                    plotting.plotFourier(app);
                    plotting.plotFourierData(app.plotSet, app.RadiusFitPlot, app.TwoDimensionalFitPlot);
                    app.TargetFrameField.Enable = 'on';
                    app.DecompositionTermsField.Enable = 'on';
                    app.DecomposeButton.Enable = 'on';
                end
            catch ME
                close(f);
                uialert(app.UIFigure, ME.message, append('Plotting Error: ', ME.identifier), 'Icon', 'error');
                LogExceptions(app, ME);
            end
            
            drawnow;
            pause(0.01);
            close(f);
        end
        
        function RefreshClicked(app, ~)
            f = uiprogressdlg(app.UIFigure, "Title", 'Please wait', 'Message', 'Refreshing Plots...', 'Indeterminate', 'on');
            UpdateLogs(app, "Updating Plots...");
            
            %Clear plots and graphs
            cla(app.MainPlot);
            cla(app.EvolutionPlot);
            cla(app.RadiusPlot);
            yyaxis(app.TwoDimensionalPlot, 'left');
            cla(app.TwoDimensionalPlot);
            yyaxis(app.TwoDimensionalPlot, 'right');
            cla(app.TwoDimensionalPlot);
            yyaxis(app.ThreeDimensionalPlot, 'left');
            cla(app.ThreeDimensionalPlot);
            yyaxis(app.ThreeDimensionalPlot, 'right');
            cla(app.ThreeDimensionalPlot);
            cla(app.CentroidPlot);
            cla(app.OrientationPlot);
            cla(app.VelocityPlot);
            cla(app.RadiusFitPlot);
            yyaxis(app.TwoDimensionalFitPlot, 'left');
            cla(app.TwoDimensionalFitPlot);
            yyaxis(app.TwoDimensionalFitPlot, 'right');
            cla(app.TwoDimensionalFitPlot);
            yyaxis(app.AsphericityPlot, 'left');
            cla(app.AsphericityPlot);
            yyaxis(app.AsphericityPlot, 'right');
            cla(app.AsphericityPlot);
            drawnow;
            
            try
                app.plotSet = plotting.generatePlotData(app);
            catch ME
                close(f);
                uialert(app.UIFigure, ME.message, append('Plot Data Generation Error: ', ME.identifier), 'Icon', 'error');
                LogExceptions(app, ME);
            end
            try
                plotting.displayCurrentFrame(app);
                plotting.dispEvolution(app);
                plotting.plotData(app.plotSet, app.RadiusPlot, app.TwoDimensionalPlot, app.ThreeDimensionalPlot, app.CentroidPlot, app.OrientationPlot, app.numFrames);
                plotting.plotVelocity(app.VelocityPlot, app.plotSet.velocity);
                if app.FourierFitToggle.UserData
                    plotting.plotFourier(app);
                    plotting.plotFourierData(app.plotSet, app.RadiusFitPlot, app.TwoDimensionalFitPlot);
                    app.TargetFrameField.Enable = 'on';
                    app.DecompositionTermsField.Enable = 'on';
                    app.DecomposeButton.Enable = 'on';
                end
            catch ME
                close(f);
                uialert(app.UIFigure, ME.message, append('Plotting Error: ', ME.identifier), 'Icon', 'error');
                LogExceptions(app, ME);
            end
            drawnow;
            close(f);
        end
        
        function InspectPushed(app, ~)
            f = uiprogressdlg(app.UIFigure, 'Indeterminate', 'on', 'Title', 'Please wait', 'Message', 'Launching frame inspector...');
            UpdateLogs(app, "Launching Frame Inpsector");
            try
                info.PerimeterPoints = app.maskInformation(app.currentFrame, :).PerimeterPoints;
                info.Centroid = app.maskInformation(app.currentFrame, :).Centroid;
                info.TrackingPoints = app.maskInformation(app.currentFrame, :).TrackingPoints;
                if app.FourierFitToggle.UserData
                    info.FourierPoints = app.maskInformation(app.currentFrame, :).FourierPoints;
                    if iscell(app.maskInformation(app.currentFrame, :).perimEq)
                        xFunc = app.maskInformation(app.currentFrame, :).perimEq{1};
                        yFunc = app.maskInformation(app.currentFrame, :).perimEq{2};
                        info.xData = xFunc(linspace(1, length(app.maskInformation(app.currentFrame, :).FourierPoints(:, 1)), ...
                            numcoeffs(app.maskInformation(app.currentFrame, :).perimFit{1}).*25));
                        info.yData = yFunc(linspace(1, length(app.maskInformation(app.currentFrame, :).FourierPoints(:, 2)), ...
                            numcoeffs(app.maskInformation(app.currentFrame, :).perimFit{2}).*25));
                    else
                        rFunc = app.maskInformation(app.currentFrame, :).perimEq;
                        rData = rFunc(linspace(0, 2*pi, 1000));
                        [xraw, yraw] = pol2cart(linspace(0, 2*pi, 1000), rData);
                        info.xData = xraw + app.maskInformation(app.currentFrame, :).Centroid(1);
                        info.yData = yraw + app.maskInformation(app.currentFrame, :).Centroid(2);
                    end
                end
                orientation = app.maskInformation(app.currentFrame, :).Orientation;
                frameInspector(app.frames(:, :, app.currentFrame), app.mask(:, :, app.currentFrame, :), info, app.FourierFitToggle.UserData, 5, ...
                    orientation);
            catch me
                uialert(app.UIFigure, me.message, append('Frame Inspection Display Error: ', me.identifier), 'Icon', 'error');
                LogExceptions(app, me);
            end
            close(f);
        end
        
        function NextFrameClicked(app, ~)
            if app.currentFrame == app.numFrames
                app.currentFrame = 1;
            else
                app.currentFrame = app.currentFrame + 1;
            end
            plotting.displayCurrentFrame(app);
            app.JumpFrameField.Value = app.currentFrame;
            drawnow;
        end
        
        function PreviousFrameClicked(app, ~)
            if app.currentFrame == 1
                app.currentFrame = app.numFrames;
            else
                app.currentFrame = app.currentFrame - 1;
            end
            plotting.displayCurrentFrame(app);
            app.JumpFrameField.Value = app.currentFrame;
            drawnow;
        end
        
        function JumpChanged(app, ~)
            value = app.JumpFrameField.Value;
            app.currentFrame = value;
            plotting.displayCurrentFrame(app);
            drawnow;
        end
        
        function DecomposeClicked(app, ~)
            try
                f = uiprogressdlg(app.UIFigure ,"Title", "Please wait", "Message", "Decomposing", "Indeterminate","on");
                decompPlots = plotting.fourierDecomposition(app.maskInformation, app.TargetFrameField.Value, app.TermsofInterestField.Value, "descending", ...
                    lower(string(app.FitType.ButtonGroup.Text)));
                f.Title = "Plotting...";
                plotting.plotFourierDecomp(app, decompPlots);
                close(f);
            catch me
                uialert(app.UIFigure, me.message, append('Decomposition Error: ', me.identifier), 'Icon', 'error');
            end
        end
    end
    
    % Component initialization
    methods (Access = private)
        
        % Create UIFigure and components
        function createComponents(app)
            
            %% Set up
            if ~isdeployed
                addpath('main');
                addpath('icons');
            end
            clc
            gcp; %Start a parallel pool if one is not alread running
            
            %Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off', 'Position', [1, 41, 1920, 1017], 'WindowState', 'maximized', ...
                'AutoResizeChildren', 'off', 'Name', 'InCA', 'Icon', 'Icon.png', 'Scrollable', 'on', 'Color', [.1 .1 .1]);
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @figureSizeChanged, true);
            
            %Create the tabs
            app.TabGroup = uitabgroup(app.UIFigure);
            app.HomeTab = uitab(app.TabGroup, 'Title', 'HOME', 'BackgroundColor', [0.1, 0.1, 0.1], 'AutoResizeChildren', 'off', ...
                'ForegroundColor', [0.1, 0.1, 0.1], 'Scrollable', 'on');
            app.DetectionTab = uitab(app.TabGroup, 'Title', 'DETECTION', 'BackgroundColor', [0.1, 0.1, 0.1], 'AutoResizeChildren', 'off', ...
                'ForegroundColor', [0.1, 0.1, 0.1], 'Scrollable', 'on');
            app.AnalysisTab = uitab(app.TabGroup, 'Title', 'ANALYSIS', 'BackgroundColor', [0.1, 0.1, 0.1], 'AutoResizeChildren', 'off', ...
                'ForegroundColor', [0.1, 0.1, 0.1], 'Scrollable', 'on');
            app.LogsTab = uitab(app.TabGroup, 'Title', 'LOGS', 'BackgroundColor', [0.1, 0.1, 0.1], 'AutoResizeChildren', 'off', ...
                'ForegroundColor', [0.1, 0.1, 0.1], 'Scrollable', 'on');
            
            %% Populate the home tab
            app.HomeImage = uiimage('Parent', app.HomeTab, 'ImageSource', 'Logo_with_Text.svg');
            app.VersionLabel = uilabel('Parent', app.HomeTab, 'Text', "VERSION: " + num2str(app.Version./10), 'FontName', 'Arial', 'FontColor', [0.9, 0.9, 0.9], ...
                'FontSize', 16);
            
            %New Button
            app.NewButton = uibutton(app.HomeTab, 'push', 'Text', "NEW", 'FontName', 'ArialMedium', 'FontColor', [0.95, 0.95, 0.95], 'FontSize', 14, ...
                'Icon', 'baseline_add_white_48dp.png', 'IconAlignment', 'left', 'BackgroundColor', [0.1, 0.29, 1]);
            app.NewButton.ButtonPushedFcn = createCallbackFcn(app, @NewClicked, true);
            app.NewPath = uieditfield(app.HomeTab, 'FontName', 'Arial', 'FontSize', 14, 'BackgroundColor', [0.15, 0.15 0.15], ...
                'FontColor', [0.95, 0.95, 0.95], 'HorizontalAlignment', 'left', 'Editable', 'off');
            
            %Open Button
            app.OpenButton = uibutton(app.HomeTab, 'push', 'FontName', 'ArialMedium', 'FontSize', 14, ...
                'Icon', 'baseline_folder_open_white_48dp.png', 'IconAlignment', 'left', 'Text', 'OPEN', 'FontColor', [0.95 0.95 0.95], ...
                'BackgroundColor', [0.1, 0.29, 1], 'Tooltip', 'Open a previously analyzed video');
            app.OpenButton.ButtonPushedFcn = createCallbackFcn(app, @OpenClicked, true);
            app.OpenPath = uieditfield(app.HomeTab, 'FontName', 'Arial', 'FontSize', 14, 'BackgroundColor', [0.15, 0.15 0.15], ...
                'FontColor', [0.95, 0.95, 0.95], 'HorizontalAlignment', 'left', 'Editable', 'off');
            
            %Save Button
            app.SaveButton = uibutton(app.HomeTab, 'push', 'FontName', 'ArialMedium', 'FontSize', 14, ...
                'Icon', 'baseline_save_white_48dp.png', 'IconAlignment', 'left', 'Text', 'SAVE', 'VerticalAlignment', 'bottom', 'FontColor', [0.95 0.95 0.95], ...
                'BackgroundColor', [0.1, 0.29, 1], 'Tooltip', 'Save current analysis to file');
            app.SaveButton.ButtonPushedFcn = createCallbackFcn(app, @SaveClicked, true);
            app.SavePath = uieditfield(app.HomeTab, 'FontName', 'Arial', 'FontSize', 14, 'BackgroundColor', [0.15, 0.15 0.15], ...
                'FontColor', [0.95, 0.95, 0.95], 'HorizontalAlignment', 'left', 'Editable', 'off');
            
            %Batch Analysis
            %             app.BatchButton = uibutton(app.HomeTab, 'state', 'Value', false, 'FontName', 'ArialMedium', 'FontSize', 14, 'FontColor', [0.95 0.95 0.95], ...
            %                 'Icon', 'baseline_dynamic_feed_white_48dp.png', 'IconAlignment', 'left', 'Text', 'BATCH PROCESS VIDEOS', 'BackgroundColor', [0.1, 0.29, 1], ...
            %                 'Position', [(tabPos(3)/2 + 5), (tabPos(4)/2 + (imgSize/2) - 150), 215, 30]);
            %             app.BatchButton.ValueChangedFcn = createCallbackFcn(app, @BatchClicked, true);
            %             app.BatchPanel = uipanel(app.HomeTab, 'Enable', 'off', 'BackgroundColor', [0.1, 0.1, 0.1], 'AutoResizeChildren', 'off', 'Scrollable', 'off', ...
            %                 'BorderType', 'none', 'Position', [(tabPos(3)/2 + 5), (tabPos(4)/2 - (imgSize/2) + 30), (tabPos(3)/3), (imgSize - 185)]);
            %             uilabel(app.BatchPanel, 'Text', 'COMING SOON...', 'FontName', 'Arial Medium', 'FontSize', 16, 'FontColor', [0.95, 0.95, 0.95], ...
            %                 'Position', [1 1 app.BatchPanel.Position(3), app.BatchPanel.Position(4)]);
            
            %% Populate the detection tab
            app.Scrollpane = uipanel(app.DetectionTab, 'BackgroundColor', [0.1, 0.1, 0.1], 'AutoResizeChildren', 'off', 'Scrollable', 'on', ...
                'BorderType', 'none');
            
            %Reset Detection
            app.ResetDetectionButton = uibutton(app.DetectionTab, 'push', 'FontName', 'ArialMedium', 'FontSize', 14, 'FontColor', [0.1, 0.1 0.1], ...
                'BackgroundColor', [255, 183, 0]./255, 'Icon', 'refresh-black-48dp.svg', 'IconAlignment', 'left', 'Text', 'RESET', ...
                'Tooltip', 'Reset the detection settings back to default');
            app.ResetDetectionButton.ButtonPushedFcn = createCallbackFcn(app, @ResetDetectionClicked, true);
            
            %View Result
            app.ViewResultButton = uibutton(app.DetectionTab, 'push', 'FontName', 'ArialMedium', 'FontSize', 14, 'FontColor', [0.1, 0.1 0.1], ...
                'BackgroundColor', [255, 183, 0]./255, 'Icon', 'visibility-black-48dp.svg', 'IconAlignment', 'left', 'Text', 'VIEW RESULT', ...
                'Tooltip', 'View the final mask for the calibration frame based on the current detection settings');
            app.ViewResultButton.ButtonPushedFcn = createCallbackFcn(app, @ViewResultClicked, true);
            
            
            %Refine Frame
            app.RefineButton = uibutton(app.DetectionTab, 'push', 'FontName', 'ArialMedium', 'FontSize', 14, 'FontColor', [0.1, 0.1 0.1], ...
                'BackgroundColor', [255, 183, 0]./255, 'Icon', 'tune-black-48dp.svg', 'IconAlignment', 'left', 'Text', 'REFINE FRAME', ...
                'Tooltip', 'Refine and set the mask for the current frame (will not apply current settings to all frames for mask generation)');
            app.RefineButton.ButtonPushedFcn = createCallbackFcn(app, @RefineClicked, true);
            
            %Frame Mixer
            app.MixerLabel = uilabel(app.DetectionTab, 'Text', 'MASK MIXING', 'FontName', 'ArialMedium', 'FontColor', [0.95, 0.95, 0.95], ...
                'FontSize', 16, 'Tooltip', 'This slider determines the ratio to which to mix the masks to produce the final masks', 'HorizontalAlignment', 'center');
            app.MixerSlider = uislider(app.DetectionTab, 'MajorTicks', [], 'Limits', [0 100], 'Value', 50, 'MinorTicks', [], 'FontName', ...
                'ArialMedium', 'FontSize', 15, 'FontColor', [0.95, 0.95, 0.95], 'MajorTickLabels', {}, ...
                'Tooltip', 'This slider determines the ratio to which to mix the masks to produce the final masks');
            
            %Mask Preivew Images
            app.ColorMask = uiimage(app.DetectionTab, 'ScaleMethod', 'scaledown', 'ImageSource', 'Icon.png');
            app.EdgeMask = uiimage(app.DetectionTab, 'ScaleMethod', 'scaledown', 'ImageSource', 'Icon.png');
            
            %Multiview
            app.MultiviewLabel = uilabel(app.DetectionTab, 'Text', 'MULTIVIEW', 'FontName', 'ArialMedium', 'FontColor', [0.95, 0.95, 0.95], ...
                'FontSize', 14, 'Tooltip', 'This informs InCA to expect a frame with two viewpoints of the same bubble');
            app.MultiviewToggle = uiimage(app.DetectionTab, 'ScaleMethod', 'scaledown', 'ImageClickedFcn', {@toggleClicked}, ...
                'ImageSource', 'toggle_off.svg', 'Tag', "Detection", 'UserData', 0);
            
            %Ignore First Frame
            app.IFFLabel = uilabel(app.DetectionTab, 'Text', 'IGNORE FIRST FRAME', 'FontName', 'ArialMedium', 'FontColor', [0.95, 0.95, 0.95], ...
                'FontSize', 14, 'Tooltip', 'Ignore the first frame of the video (common with high speed cameras)');
            app.IFFToggle = uiimage(app.DetectionTab, 'ScaleMethod', 'scaledown', 'ImageClickedFcn', {@toggleClicked}, 'Tag', "Detection", ...
                'ImageSource', 'toggle_on_detection.svg', 'UserData', 1);
            
            %Increase Contrast
            app.ICToggle = uiimage(app.DetectionTab, 'ScaleMethod', 'scaledown', 'ImageClickedFcn', {@toggleClicked}, ...
                'ImageSource', 'toggle_off.svg', 'Tag', "Detection", 'UserData', 0);
            app.ICLabel = uilabel(app.DetectionTab, 'Text', 'INCREASE CONTRAST', 'FontName', 'ArialMedium', 'FontColor', [0.95, 0.95, 0.95], ...
                'FontSize', 14, 'Tooltip', 'Increase the contrast of all the images to utilize the full dynamic range of color');
            
            %Remove Embeded Timestamps
            app.RTToggle = uiimage(app.DetectionTab, 'ScaleMethod', 'scaledown', 'ImageClickedFcn', {@toggleClicked}, ...
                'ImageSource', 'toggle_off.svg', 'Tag', "Detection", 'UserData', 0);
            app.RTLabel = uilabel(app.DetectionTab, 'Text', 'REMOVE TIMESTAMPS', 'FontName', 'ArialMedium', 'FontColor', [0.95, 0.95, 0.95], ...
                'FontSize', 14, 'Tooltip', 'If the frames contain embeded timestamps, have InCA remove them before detection begins');
            
            %Fix Variable Lighting
            app.VLToggle = uiimage(app.DetectionTab, 'ScaleMethod', 'scaledown', 'ImageClickedFcn', {@vltoggleClicked, app}, ...
                'ImageSource', 'toggle_off.svg', 'Tag', "Detection", 'UserData', 0);
            app.VLLabel = uilabel(app.DetectionTab, 'Text', 'NORMALIZE LIGHTING', 'FontName', 'ArialMedium', 'FontColor', [0.95, 0.95, 0.95], ...
                'FontSize', 14, 'Tooltip', 'If there are large variations in average frame intensity, have InCA try to smoothen those out.');
            app.NLButtonGroup = uibuttongroup(app.DetectionTab, 'FontName', 'Arial', 'BorderType', 'none', 'BackgroundColor', [0.1 0.1 0.1], ...
                'ForegroundColor', [0.95 0.95 0.95], 'AutoResizeChildren', 'off', 'Tooltip', 'Type of frame lighting normalization', ...
                'SelectionChangedFcn', {@NLSelChanged, app});
            app.BSRadioButton = uiradiobutton(app.NLButtonGroup, 'Text', 'BACKGROUND SUBTRACTION', 'FontName', 'Arial', 'FontSize', 14, 'FontColor', ...
                [0.95 0.95 0.95], 'Value', 1, 'Enable', 'off', 'Tooltip', ...
                "Use a reference frame to substract the background from the remaining video frames");
            app.GARadioButton = uiradiobutton(app.NLButtonGroup, 'Text', 'GRAY-LEVEL NORMALIZATION', 'FontName', 'Arial', 'FontSize', 14, 'FontColor', ...
                [0.95 0.95 0.95], 'Value', 1, 'Enable', 'off', 'Tooltip', ...
                "Average all of the the background gray areas and use an intensity factor to normalize frame lighting to the average value");
            app.BSLabel = uilabel(app.DetectionTab, 'Text', 'Reference Frame: ', 'FontName', 'ArialMedium', 'FontColor', [0.95, 0.95, 0.95], ...
                'FontSize', 16, 'Tooltip', 'Which frame should be used as the reference for gray level subtraction');
            app.BSField = uieditfield('numeric', 'Parent', app.DetectionTab, 'FontName', 'Arial', 'FontSize', 14, 'BackgroundColor', [0.15, 0.15 0.15], ...
                'FontColor', [0.95, 0.95, 0.95], 'HorizontalAlignment', 'right', 'Value', 1, 'Enable', 'off');
            
            %Run Detection Button
            app.RunDetectionButton =  uibutton(app.DetectionTab, 'push', 'FontName', 'ArialMedium', 'FontSize', 14, 'FontColor', [0.1, 0.1 0.1], ...
                'BackgroundColor', [255, 183, 0]./255, 'Icon', 'search-black-48dp.svg', 'IconAlignment', 'left', 'Text', 'RUN DETECTION', ...
                'Tooltip', 'Run detection for all frames using the current settings');
            app.RunDetectionButton.ButtonPushedFcn = createCallbackFcn(app, @RunDetection, true);
            
            %Chosen Frame for Calibration
            app.CalibrationFrame = uiimage(app.DetectionTab, 'ScaleMethod', 'scaledown', 'ImageSource', 'Icon.png');
            
            %Sub Mask Section Labels
            app.ColorLabel = uilabel(app.DetectionTab, 'Text', 'INTENSITY DETECTION', 'FontName', 'ArialMedium', 'FontColor', [0.95, 0.95, 0.95], ...
                'FontSize', 16, 'Tooltip', 'Settings below correspond to calibration of the mask made through frame intensity analysis.', ...
                'HorizontalAlignment', 'center', 'FontWeight', 'bold');
            app.EdgeLabel = uilabel(app.DetectionTab, 'Text', 'EDGE DETECTION', 'FontName', 'ArialMedium', 'FontColor', [0.95, 0.95, 0.95], ...
                'FontSize', 16, 'Tooltip', 'Settings below correspond to calibration of the mask made through edge detection algorithms.', ...
                'HorizontalAlignment', 'center', 'FontWeight', 'bold');
            
            %Color Detection Settings
            app.CStyleLabel = uilabel(app.DetectionTab, 'Text', 'Preprocessing:', 'FontName', 'ArialMedium', 'FontColor', [0.95, 0.95, 0.95], ...
                'FontSize', 16, 'Tooltip', 'What type of frame preprocessing should be applied before generating an intensity mask.');
            app.CStyle = uidropdown(app.DetectionTab, 'Items', {'None', 'Sharpen', 'Soften'}, 'Value', 'None', 'FontName', 'ArialMedium', ...
                'FontColor', [0.95, 0.95, 0.95], 'BackgroundColor', [0.1 0.1 0.1],'Tooltip', 'Preprocess the frames for increased detection accuracy');
            app.CValLabel = uilabel(app.DetectionTab, 'Text', 'Filter Size:', 'FontName', 'ArialMedium', 'FontColor', [0.95, 0.95, 0.95], ...
                'FontSize', 16, 'Tooltip', 'How intense the preprocessing should be');
            app.CVal = uieditfield('numeric', 'Parent', app.DetectionTab, 'FontName', 'Arial', 'FontSize', 14, 'BackgroundColor', [0.15, 0.15 0.15], ...
                'FontColor', [0.95, 0.95, 0.95], 'HorizontalAlignment', 'right');
            app.AutoColorToggle = uiimage(app.DetectionTab, 'ScaleMethod', 'scaledown', 'ImageClickedFcn', {@actoggleClicked, app}, ...
                'ImageSource', 'toggle_off.svg', 'Tag', "Detection", 'UserData', 0, 'Tooltip', 'Automatically calculate a threshold for each frame');
            app.AutoColorLabel = uilabel(app.DetectionTab, 'Text', 'Automatic Color Thresholding', 'FontName', 'ArialMedium', 'FontColor', [0.95, 0.95, 0.95], ...
                'FontSize', 16, 'Tooltip', 'Automatically calculate a threshold for each frame');
            app.ColorThresholdLabel = uilabel(app.DetectionTab, 'Text', 'Intensity Threshold:', 'FontName', 'ArialMedium', 'FontColor', [0.95, 0.95, 0.95], ...
                'FontSize', 16, 'Tooltip', 'What value is used for binarizing the image');
            app.ColorThresholdField = uieditfield('numeric', 'Parent', app.DetectionTab, 'FontName', 'Arial', 'FontSize', 14, 'BackgroundColor', [0.15, 0.15 0.15], ...
                'FontColor', [0.95, 0.95, 0.95], 'HorizontalAlignment', 'right', 'Tooltip', 'What value is used for binarizing the image');
            
            %Edge Detection Settings
            app.EStyleLabel = uilabel(app.DetectionTab, 'Text', 'Preprocessing:', 'FontName', 'ArialMedium', 'FontColor', [0.95, 0.95, 0.95], ...
                'FontSize', 16, 'Tooltip', 'What type of frame preprocessing should be applied before generating an edge mask.');
            app.EStyle = uidropdown(app.DetectionTab, 'Items', {'None', 'Sharpen', 'Soften'}, 'Value', 'None', 'FontName', 'ArialMedium', ...
                'FontColor', [0.95, 0.95, 0.95], 'BackgroundColor', [0.1 0.1 0.1],'Tooltip', 'Preprocess the frames for increased detection accuracy');
            app.EValLabel = uilabel(app.DetectionTab, 'Text', 'Filter Size:', 'FontName', 'ArialMedium', 'FontColor', [0.95, 0.95, 0.95], ...
                'FontSize', 16, 'Tooltip', 'How intense the preprocessing should be');
            app.EVal = uieditfield('numeric', 'Parent', app.DetectionTab, 'FontName', 'Arial', 'FontSize', 14, 'BackgroundColor', [0.15, 0.15 0.15], ...
                'FontColor', [0.95, 0.95, 0.95], 'HorizontalAlignment', 'right');
            app.AutoEdgeToggle = uiimage(app.DetectionTab, 'ScaleMethod', 'scaledown', 'ImageClickedFcn', {@aetoggleClicked, app}, ...
                'ImageSource', 'toggle_off.svg', 'Tag', "Detection", 'UserData', 0, 'Tooltip', 'Automatically calcualte a threshold for each frame');
            app.AutoEdgeLabel = uilabel(app.DetectionTab, 'Text', 'Automatic Edge Thresholding', 'FontName', 'ArialMedium', 'FontColor', [0.95, 0.95, 0.95], ...
                'FontSize', 16, 'Tooltip', 'Automatically calculate a threshold for each frame');
            app.EdgeThresholdLabel = uilabel(app.DetectionTab, 'Text', 'Edge Threshold:', 'FontName', 'ArialMedium', 'FontColor', [0.95, 0.95, 0.95], ...
                'FontSize', 16, 'Tooltip', 'Threshold for the edge filter');
            app.EdgeThresholdField = uieditfield('numeric', 'Parent', app.DetectionTab, 'FontName', 'Arial', 'FontSize', 14, 'BackgroundColor', [0.15, 0.15 0.15], ...
                'FontColor', [0.95, 0.95, 0.95], 'HorizontalAlignment', 'right', 'Tooltip', 'Threshold for the edge filter');
            
            %View and Evaluate
            app.FinalMaskViewer = uiaxes(app.DetectionTab, 'FontName', 'Arial', 'FontSize', 14, 'YDir', 'reverse', 'Box', 'on', ...
                'BoxStyle', 'full', 'XTick', [], 'YTick', [], 'Color', [0.1 0.1 0.1], 'BackgroundColor', [0.1 0.1 0.1], 'XColor', ...
                [0.95 0.95 0.95], 'YColor', [0.95 0.95 0.95], 'AmbientLightColor', [0.1 0.1 0.1]);
            
            %Previous Frame
            app.PreviousFrameDetectionButton = uibutton(app.DetectionTab, 'push', 'FontName', 'Arial', 'FontSize', 12, ...
                'Icon', 'skip_previous-black-48dp.svg', 'IconAlignment', 'top', 'Text', 'PREVIOUS', 'VerticalAlignment', 'bottom', 'FontColor', [0.1 0.1 0.1], ...
                'BackgroundColor', [255, 183, 0]./255, 'Enable', 'off');
            app.PreviousFrameDetectionButton.ButtonPushedFcn = createCallbackFcn(app, @PDClicked, true);
            
            %Next Frame
            app.NextFrameDetectionButton = uibutton(app.DetectionTab, 'push', 'FontName', 'Arial', 'FontSize', 12, ...
                'Icon', 'skip_next-black-48dp.svg', 'IconAlignment', 'top', 'Text', 'NEXT', 'VerticalAlignment', 'bottom', 'FontColor', [0.1 0.1 0.1], ...
                'BackgroundColor', [255, 183, 0]./255, 'Enable', 'off');
            app.NextFrameDetectionButton.ButtonPushedFcn = createCallbackFcn(app, @NDClicked, true);
            
            %Accept Mask
            app.AcceptFrameButton = uibutton(app.DetectionTab, 'push', 'FontName', 'Arial', 'FontSize', 12, ...
                'Icon', 'check_circle_outline-black-48dp.svg', 'IconAlignment', 'top', 'Text', 'ACCEPT', 'VerticalAlignment', 'bottom', 'FontColor', ...
                [0.1, 0.1, 0.1], 'BackgroundColor', [255, 183, 0]./255, 'Enable', 'off');
            app.AcceptFrameButton.ButtonPushedFcn = createCallbackFcn(app, @AcceptClicked, true);
            
            %Reject Mask
            app.RejectFrameButton = uibutton(app.DetectionTab, 'push', 'FontName', 'Arial', 'FontSize', 12, ...
                'Icon', 'highlight_off-black-48dp.svg', 'IconAlignment', 'top', 'Text', 'REJECT', 'VerticalAlignment', 'bottom', 'FontColor', ...
                [0.1, 0.1, 0.1], 'BackgroundColor', [255, 183, 0]./255, 'Enable', 'off');
            app.RejectFrameButton.ButtonPushedFcn = createCallbackFcn(app, @RejectClicked, true);
            
            %% Populate the analysis tab
            app.SettingsPanel = uipanel(app.AnalysisTab, 'BackgroundColor', [0.1, 0.1, 0.1], 'AutoResizeChildren', 'off', 'Scrollable', 'on', ...
                'BorderType', 'none');
            
            app.AnalyzeButton = uibutton(app.AnalysisTab, 'push', 'FontName', 'Arial', 'FontSize', 14, ...
                'Icon', 'polymer-white-48dp.svg', 'IconAlignment', 'left', 'Text', 'ANALYZE', 'VerticalAlignment', 'center', 'FontColor', ...
                [0.95, 0.95, 0.95], 'BackgroundColor', [183 0 255]./255, 'Tooltip', 'Execute the analysis with the current settings');
            app.AnalyzeButton.ButtonPushedFcn = createCallbackFcn(app, @AnalyzePushed, true);
            
            app.RefreshPlotsButton = uibutton(app.AnalysisTab, 'push', 'FontName', 'Arial', 'FontSize', 14, ...
                'Icon', 'refresh-white-48dp.svg', 'IconAlignment', 'left', 'Text', 'REFRESH PLOTS', 'VerticalAlignment', 'center', 'FontColor', ...
                [0.95 0.95 0.95], 'BackgroundColor', [183 0 255]./255, 'Tooltip', 'Refresh the current plots');
            app.RefreshPlotsButton.ButtonPushedFcn = createCallbackFcn(app, @RefreshClicked, true);
            
            app.InspectFrameButton = uibutton(app.AnalysisTab, 'push', 'FontName', 'Arial', 'FontSize', 14, ...
                'Icon', 'pageview-white-18dp.svg', 'IconAlignment', 'left', 'Text', 'INSPECT CURRENT FRAME', 'VerticalAlignment', 'center', 'FontColor', ...
                [0.95 0.95 0.95], 'BackgroundColor', [183 0 255]./255, 'Tooltip', 'Open the current frame in InCA frame inspector');
            app.InspectFrameButton.ButtonPushedFcn = createCallbackFcn(app, @InspectPushed, true);
            
            %Micron to Pixel Input
            app.MPXLabel = uilabel(app.SettingsPanel, 'Text', 'MICRON/PIXEL:', 'FontName', 'Arial', 'FontColor', [0.95 0.95 0.95], 'FontSize', 14, ...
                'HorizontalAlignment', 'left', 'Tooltip', 'Ratio of Microns to Pixels');
            app.MPXField = uieditfield('numeric', 'Parent', app.SettingsPanel, 'FontName', 'Arial','FontSize', 14, 'BackgroundColor', [0.15 0.15 0.15], ...
                'FontColor', [0.95 0.95 0.95], 'Limits', [0 Inf], 'Value', 1, 'Tooltip', 'Ratio of Microns to Pixels');
            
            %FPS Input
            app.FPSLabel = uilabel(app.SettingsPanel, 'Text', 'VIDEO FPS:', 'FontName', 'Arial', 'FontColor', [0.95 0.95 0.95], 'FontSize', 14,'HorizontalAlignment', 'left' ,...
                'Tooltip', 'Camera frames per second');
            app.FPSField = uieditfield('numeric', 'Parent', app.SettingsPanel, 'FontName', 'Arial','FontSize', 14, 'BackgroundColor', [0.15 0.15 0.15], ...
                'FontColor', [0.95 0.95 0.95], 'Limits', [1 Inf], 'Value', 1, 'Tooltip', 'Camera frames per second');
            
            %Number of Perimeter Tracking Points
            app.TPLabel = uilabel(app.SettingsPanel, 'Text', 'TRACKING POINTS:', 'FontName', 'Arial', 'FontSize', 14, 'FontColor', [0.95 0.95 0.95], ...
                'HorizontalAlignment', 'left', 'Tooltip', 'The number of tracking points InCA should generate when calculating average radius and average velocity');
            app.TPField = uieditfield('numeric', 'Parent', app.SettingsPanel, 'FontName', 'Arial', 'FontSize', 14, 'BackgroundColor', [0.15 0.15 0.15], ...
                'FontColor', [0.95 0.95 0.95], 'Limits', [1 Inf], 'Value', 50, 'Tooltip', app.TPLabel.Tooltip);
            
            %Rotation Axis for 3D Properties
            app.RotationAxis.ButtonGroup = uibuttongroup(app.SettingsPanel, 'Title', 'ROTATION AXIS', 'FontName', 'Arial', 'FontSize', 14, 'BorderType', ...
                'none', 'BackgroundColor', [0.1 0.1 0.1], 'ForegroundColor', [0.95 0.95 0.95], 'AutoResizeChildren', 'off', 'Tooltip', ...
                'Rotation axis for calculating 3D bubble properties from the mask');
            app.RotationAxis.MajorButton = uiradiobutton(app.RotationAxis.ButtonGroup, 'Text', 'MAJOR', 'FontName', 'Arial', 'FontSize', 14, 'FontColor', ...
                [0.95 0.95 0.95], 'Value', 1, 'Tooltip', "Rotate perimeter about mask's major axis");
            app.RotationAxis.MinorButton = uiradiobutton(app.RotationAxis.ButtonGroup, 'Text', 'MINOR', 'FontName', 'Arial', 'FontSize', 14, 'FontColor', ...
                [0.95 0.95 0.95], 'Value', 0, 'Tooltip', "Rotate perimeter about mask's minor axis");
            app.RotationAxis.HorizontalButton = uiradiobutton(app.RotationAxis.ButtonGroup, 'Text', 'HORIZONTAL', 'FontName', 'Arial', 'FontSize', 14, 'FontColor', ...
                [0.95 0.95 0.95], 'Value', 0, 'Tooltip', "Rotate perimeter about horizontal axis");
            app.RotationAxis.VerticalButton = uiradiobutton(app.RotationAxis.ButtonGroup, 'Text', 'VERTICAL', 'FontName', 'Arial', 'FontSize', 14, 'FontColor', ...
                [0.95 0.95 0.95], 'Value', 0, 'Tooltip', "Rotate perimeter about vertical axis");
            
            %Fourier Toggle
            app.FourierFitToggle = uiimage(app.SettingsPanel, 'ScaleMethod', 'scaledown', 'ImageClickedFcn', {@ftoggleClicked, app}, ...
                'ImageSource', 'toggle_off.svg', 'Tag', "Analysis", 'UserData', 0, 'Tooltip', ...
                'This informs InCA to fit a Fourier Series to the Perimeter of the bubble and conduct an analysis');
            app.FourierFitToggleLabel = uilabel(app.SettingsPanel, 'Text', 'FOURIER FIT ANALYSIS', 'FontName', 'ArialMedium', 'FontColor', [0.95, 0.95, 0.95], ...
                'FontSize', 14, 'Tooltip', 'This informs InCA to fit a Fourier Series to the Perimeter of the bubble and conduct an analysis');
            
            %Fourier Fit Type
            app.FitType.ButtonGroup = uibuttongroup(app.SettingsPanel, 'Title', 'FOURIER FIT TYPE', 'FontName', 'Arial', 'FontSize', 14, 'BorderType', ...
                'none', 'BackgroundColor', [0.1 0.1 0.1], 'ForegroundColor', [0.95 0.95 0.95], 'AutoResizeChildren', 'off');
            app.FitType.PolarSButton = uiradiobutton(app.FitType.ButtonGroup, 'Text', 'POLAR (STANDARD)', 'FontName', 'Arial', 'FontSize', 14, 'FontColor', ...
                [0.95 0.95 0.95], 'Value', 1, 'Enable', 'off');
            app.FitType.PolarPButton = uiradiobutton(app.FitType.ButtonGroup, 'Text', 'POLAR (PHASE SHIFT)', 'FontName', 'Arial', 'FontSize', 14, 'FontColor', ...
                [0.95 0.95 0.95], 'Value', 0, 'Enable', 'off');
            app.FitType.ParametricButton = uiradiobutton(app.FitType.ButtonGroup, 'Text', 'PARAMETRIC', 'FontName', 'Arial', 'FontSize', 14, 'FontColor', ...
                [0.95 0.95 0.95], 'Value', 0, 'Enable', 'off');
            
            %Minimum Fourier Arc Length Input
            app.MinArcLengthLabel = uilabel(app.SettingsPanel, 'Text', 'MINIMUM ARC LENGTH:', 'FontName', 'Arial', 'FontColor', [0.95 0.95 0.95], 'FontSize', 14, ...
                'HorizontalAlignment', 'left', 'Tooltip', 'This is the minimum perimeter arc length between points to be used for the Fourier Series perimeter fit');
            app.MinArcLengthField = uieditfield('numeric', 'Parent', app.SettingsPanel, 'FontName', 'Arial','FontSize', 14, 'BackgroundColor', [0.15 0.15 0.15], ...
                'FontColor', [0.95 0.95 0.95], 'Value', 3, 'Limits', [1 Inf], 'Enable', 'off', 'Tooltip', ...
                'This is the minimum perimeter arc length between points to be used for the Fourier Series perimeter fit');
            
            %Adaptive Terms Toggle
            app.AdaptiveTermsToggle = uiimage(app.SettingsPanel, 'ScaleMethod', 'scaledown', 'ImageClickedFcn', {@toggleClicked}, ...
                'ImageSource', 'toggle_off.svg', 'Tag', "Analysis", 'UserData', 0, 'Enable', 'off', 'Tooltip', ...
                'This informs InCA to use a variable number of modes for each frame, while not going over the defined maximum');
            app.AdaptiveTermsToggleLabel = uilabel(app.SettingsPanel, 'Text', 'VARIABLE MODES', 'FontName', 'ArialMedium', 'FontColor', [0.95, 0.95, 0.95], ...
                'FontSize', 14, 'Tooltip', 'This informs InCA to use a variable number of Fourier Vibration modss for each frame, while not going over the defined maximum');
            
            %Max Fourier Terms Input
            app.MaxTermsLabel = uilabel(app.SettingsPanel, 'Text', 'MAX VIBRATION MODES:', 'FontName', 'Arial', 'FontColor', [0.95 0.95 0.95], 'FontSize', 14, ...
                'HorizontalAlignment', 'left', 'Tooltip', ...
                'The maximum number of modes to use in the Fourier Series perimeter fit. This value is the maximum number of modes regardless of if adaptive terms are used.');
            app.MaxTermsField = uieditfield('numeric', 'Parent', app.SettingsPanel, 'FontName', 'Arial', 'FontSize', 14, 'BackgroundColor', [0.15 0.15 0.15], ...
                'FontColor', [0.95 0.95 0.95], 'Value', 40, 'Limits', [1 Inf], 'Enable', 'off', 'Tooltip', ...
                'The maximum number of vibration modes to use in the Fourier Series perimeter fit. This value is the maximum number of modes regardless of if adaptive modes are used.');
            
            %Terms of Interest Input
            app.TermsofInterestLabel = uilabel(app.SettingsPanel, 'Text', 'MODES TO PLOT:', 'FontName', 'Arial', 'FontColor', [0.95 0.95 0.95], 'FontSize', 14, ...
                'HorizontalAlignment', 'left');
            app.TermsofInterestField = uieditfield('numeric', 'Parent', app.SettingsPanel, 'FontName','Arial', 'FontSize', 14, 'BackgroundColor', [0.15 0.15 0.15], ...
                'FontColor', [0.95 0.95 0.95], 'Value', 8, 'Limits', [1 Inf], 'Enable', 'off');
            
            %Metric Terms Input
            app.MetricTermsLabel = uilabel(app.SettingsPanel, 'TEXT', 'MODES FOR METRICS:', 'FontName', 'Arial', 'FontColor', [0.95 0.95 0.95], 'FontSize', 14, ...
                'HorizontalAlignment', 'left', 'Tooltip', ...
                'This value is the number of modes InCA will use to calculate fit metrics such as base fit radius, area, and perimeter. More modes are more accurate but require more calculation time.');
            app.MetricTermsField = uieditfield('numeric', 'Parent', app.SettingsPanel, 'FontName','Arial', 'FontSize', 14, 'BackgroundColor', [0.15 0.15 0.15], ...
                'FontColor', [0.95 0.95 0.95], 'Value', 5, 'Limits', [1 Inf], 'Enable', 'off', 'Tooltip', ...
                'This value is the number of modes InCA will use to calculate fit metrics such as base fit radius, area, and perimeter. More modes are more accurate but require more calculation time.');
            
            
            %Fourier Decomposition
            app.DecompositionPanel = uipanel(app.SettingsPanel, 'Title', 'FOURIER DECOMPOSITION', 'FontName', 'Arial', 'FontSize', 14, ...
                'BackgroundColor', [0.1 0.1 0.1], 'AutoResizeChildren', 'off', 'Scrollable', 'off', 'BorderType', 'none', 'ForegroundColor', [0.95 0.95 0.95]);
            app.TargetFrameLabel = uilabel(app.DecompositionPanel, 'Text', 'TARGET FRAME:', 'FontName', 'Arial', 'FontSize', 14, 'FontColor', [0.95 0.95 0.95]);
            app.TargetFrameField = uieditfield('numeric', 'Parent', app.DecompositionPanel, 'FontName','Arial', 'FontSize', 14, 'BackgroundColor', [0.15 0.15 0.15], ...
                'FontColor', [0.95 0.95 0.95], 'Value', 1, 'Limits', [1 Inf], 'Enable', 'off');
            app.DecompositionTermsLabel = uilabel(app.DecompositionPanel, 'Text', 'NO. MODES:', 'FontName', 'Arial', 'FontSize', 14, 'FontColor', [0.95 0.95 0.95]);
            app.DecompositionTermsField = uieditfield('numeric', 'Parent', app.DecompositionPanel, 'FontName','Arial', 'FontSize', 14, 'BackgroundColor', [0.15 0.15 0.15], ...
                'FontColor', [0.95 0.95 0.95], 'Value', 8, 'Limits', [1 Inf], 'Enable', 'off');
            app.DecomposeButton = uibutton(app.DecompositionPanel, 'push', 'FontName', 'Arial', 'FontSize', 14, 'Text', 'DECOMPOSE', 'VerticalAlignment', ...
                'center', 'FontColor', [0.95, 0.95, 0.95], 'BackgroundColor', [183 0 255]./255, 'Enable', 'off');
            
            %Frame Navigation
            app.NextFrameButton = uibutton(app.AnalysisTab, 'push', 'FontName', 'Arial', 'FontSize', 14, 'Text', 'NEXT FRAME', 'VerticalAlignment', 'center', 'Icon', ...
                'skip_next-white-48dp.svg', 'IconAlignment', 'right', 'FontColor', [0.95 0.95 0.95], 'BackgroundColor', [183 0 255]./255);
            app.NextFrameButton.ButtonPushedFcn = createCallbackFcn(app, @NextFrameClicked, true);
            app.PreviousFrameButton = uibutton(app.AnalysisTab, 'push', 'FontName', 'Arial', 'FontSize', 14, 'Text', 'PREVIOUS FRAME', 'VerticalAlignment', 'center', 'Icon', ...
                'skip_previous-white-48dp.svg', 'IconAlignment', 'left', 'FontColor', [0.95 0.95 0.95], 'BackgroundColor', [183 0 255]./255);
            app.PreviousFrameButton.ButtonPushedFcn = createCallbackFcn(app, @PreviousFrameClicked, true);
            app.JumpFrameLabel = uilabel(app.AnalysisTab, 'Text', 'JUMP TO FRAME:', 'FontName', 'Arial', 'FontSize', 14, 'FontColor', [0.95 0.95 0.95]);
            app.JumpFrameField = uieditfield('numeric', 'Parent', app.AnalysisTab, 'FontName', 'Arial', 'FontSize', 14, 'BackgroundColor', [0.15 0.15 0.15], ...
                'FontColor', [0.95 0.95 0.95], 'Value', 1, 'Limits', [1 Inf]);
            app.JumpFrameField.ValueChangedFcn = createCallbackFcn(app, @JumpChanged, true);
            
            
            app.PlotPanel = uipanel(app.AnalysisTab, 'BackgroundColor', [0.1, 0.1, 0.1], 'AutoResizeChildren', 'off', 'Scrollable', 'on', ...
                'BorderType', 'none');
            
            %Average Radius Plot
            app.RadiusPlot = uiaxes(app.PlotPanel, 'FontName', 'ArialMedium', 'FontSize', 12, 'XColor', [0.95 0.95 0.95], ...
                'YColor', [0.95 0.95 0.95], 'Color', [0.1 0.1 0.1], 'Clipping', 'on', 'PositionConstraint', 'outerposition');
            title(app.RadiusPlot, "AVERAGE RADIUS", 'Color', [0.95 0.95 0.95]);
            xlabel(app.RadiusPlot, "TIME (s)");
            ylabel(app.RadiusPlot, "RADIUS (micron)");
            disableDefaultInteractivity(app.RadiusPlot);
            
            %Area and Perimeter Plot
            app.TwoDimensionalPlot = uiaxes(app.PlotPanel, 'FontName', 'ArialMedium', 'FontSize', 12, 'XColor', [0.95 0.95 0.95], ...
                'YColor', [183 0 255]./255, 'Color', [0.1 0.1 0.1], 'ColorOrder', [0.7176 0 1; 1 0 0.2824], 'Clipping', 'on', ...
                'PositionConstraint', 'outerposition');
            title(app.TwoDimensionalPlot, "AREA AND PERIMETER", 'Color', [0.95 0.95 0.95]);
            xlabel(app.TwoDimensionalPlot, "TIME (s)");
            ylabel(app.TwoDimensionalPlot, "AREA (micron^2)");
            yyaxis(app.TwoDimensionalPlot, 'right');
            ylabel(app.TwoDimensionalPlot, "PERIMETER (micron)");
            app.TwoDimensionalPlot.YColor = [255 0 72]./255;
            yyaxis(app.TwoDimensionalPlot, 'left');
            app.TwoDimensionalPlot.YColor = [183 0 255]./255;
            disableDefaultInteractivity(app.TwoDimensionalPlot);
            
            %Surface Area and Volume Plot
            app.ThreeDimensionalPlot = uiaxes(app.PlotPanel, 'FontName', 'ArialMedium', 'FontSize', 12, 'XColor', [0.95 0.95 0.95], ...
                'YColor', [183 0 255]./255, 'Color', [0.1 0.1 0.1], 'ColorOrder', [0.7176 0 1; 1 0 0.2824], 'Clipping', 'on', ...
                'PositionConstraint', 'outerposition');
            title(app.ThreeDimensionalPlot, "SURFACE AREA AND VOLUME", 'Color', [0.95 0.95 0.95]);
            xlabel(app.ThreeDimensionalPlot, "TIME (s)");
            ylabel(app.ThreeDimensionalPlot, "SURFACE AREA (micron^2)");
            yyaxis(app.ThreeDimensionalPlot, 'right');
            ylabel(app.ThreeDimensionalPlot, "VOLUME (micron^3)");
            app.ThreeDimensionalPlot.YColor = [255 0 72]./255;
            yyaxis(app.ThreeDimensionalPlot, 'left');
            app.ThreeDimensionalPlot.YColor = [183 0 255]./255;
            disableDefaultInteractivity(app.ThreeDimensionalPlot);
            
            %Velocity Plot
            app.VelocityPlot = uiaxes(app.PlotPanel, 'FontName', 'ArialMedium', 'FontSize', 12, 'XColor', [0.95 0.95 0.95], ...
                'YColor', [0.95 0.95 0.95], 'Color', [0.1 0.1 0.1], 'Clipping', 'on', 'PositionConstraint', 'outerposition');
            title(app.VelocityPlot, "RADIAL PERIMETER VELOCITY", 'Color', [0.95 0.95 0.95]);
            xlabel(app.VelocityPlot, "TIME (s)");
            ylabel(app.VelocityPlot, "VELOCITY (micron/s)");
            disableDefaultInteractivity(app.VelocityPlot);
            
            %Acceleration Plot
            %             app.AccelerationPlot = uiaxes(app.PlotPanel, 'FontName', 'ArialMedium', 'FontSize', 12, 'XColor', [0.95 0.95 0.95], ...
            %                 'YColor', [0.95 0.95 0.95], 'Color', [0.1 0.1 0.1], 'Clipping', 'on', 'PositionConstraint', 'outerposition');
            %             title(app.AccelerationPlot, "RADIAL PERIMETER ACCELERATION", 'Color', [0.95 0.95 0.95]);
            %             xlabel(app.AccelerationPlot, "TIME (s)");
            %             ylabel(app.AccelerationPlot, "ACCELERATION (micron/s^2)");
            %             disableDefaultInteractivity(app.AccelerationPlot);
            
            %Major Axis Orientation
            app.OrientationPlot = polaraxes(app.PlotPanel, 'AmbientLightColor', [0.1 0.1 0.1], 'FontName', 'Arial', 'RColor', [0.95, 0.95, 0.95], ...
                'ThetaColor', [0.95, 0.95, 0.95], 'Color', [0.1 0.1 0.1], 'GridColor', [0.95 0.95 0.95], 'Units', 'pixels', ...
                'PositionConstraint', 'outerposition');
            title(app.OrientationPlot, "MAJOR AXIS ORIENTATION", 'Color', [0.95 0.95 0.95]);
            disableDefaultInteractivity(app.OrientationPlot);
            
            %Centroid Coordinates
            app.CentroidPlot = uiaxes(app.PlotPanel, 'XColor', [0.95 0.95 0.95], 'YColor', [0.95 0.95 0.95], 'Color', [0.1 0.1 0.1], ...
                'Box', 'on', 'FontName', 'Arial', 'Clipping', 'on', 'PositionConstraint', 'outerposition');
            title(app.CentroidPlot, "CENTROID COORDINATES", 'Color', [0.95 0.95 0.95]);
            app.CentroidFirst = uilabel(app.PlotPanel, 'Text', 'FIRST FRAME', 'FontColor', [178, 24, 43]./255, 'FontName', 'Arial Medium', ...
                'FontSize', 14);
            app.CentroidLast = uilabel(app.PlotPanel, 'Text', 'LAST FRAME', 'FontColor', [33, 102, 172]./255, 'FontName', 'Arial Medium', ...
                'FontSize', 14);
            disableDefaultInteractivity(app.CentroidPlot);
            
            %Fit Radius
            app.RadiusFitPlot = uiaxes(app.PlotPanel, 'FontName', 'ArialMedium', 'FontSize', 12, 'XColor', [0.95 0.95 0.95], ...
                'YColor', [0.95 0.95 0.95], 'Color', [0.1 0.1 0.1], 'Clipping', 'on', 'PositionConstraint', 'outerposition');
            title(app.RadiusFitPlot, "BASE FIT RADIUS", 'Color', [0.95 0.95 0.95]);
            xlabel(app.RadiusFitPlot, "TIME (s)");
            ylabel(app.RadiusFitPlot, "RADIUS (micron)");
            disableDefaultInteractivity(app.RadiusFitPlot);
            
            %Fit Area and Perimeter
            app.TwoDimensionalFitPlot = uiaxes(app.PlotPanel, 'FontName', 'ArialMedium', 'FontSize', 12, 'XColor', [0.95 0.95 0.95], ...
                'YColor', [183 0 255]./255, 'Color', [0.1 0.1 0.1], 'ColorOrder', [0.7176 0 1; 1 0 0.2824], 'Clipping', 'on', 'PositionConstraint', 'outerposition');
            title(app.TwoDimensionalFitPlot, "FIT AREA AND PERIMETER", 'Color', [0.95 0.95 0.95]);
            xlabel(app.TwoDimensionalFitPlot, "TIME (s)");
            ylabel(app.TwoDimensionalFitPlot, "AREA (micron^2)");
            yyaxis(app.TwoDimensionalFitPlot, 'right');
            ylabel(app.TwoDimensionalFitPlot, "PERIMETER (micron)");
            app.TwoDimensionalFitPlot.YColor = [255 0 72]./255;
            yyaxis(app.TwoDimensionalFitPlot, 'left');
            app.TwoDimensionalFitPlot.YColor = [183 0 255]./255;
            disableDefaultInteractivity(app.TwoDimensionalFitPlot);
            
            %Fourier Vibration Mode
            app.AsphericityPlot = uiaxes(app.PlotPanel, 'XColor', [0.95 0.95 0.95], 'Color', [0.1 0.1 0.1], ...
                'BackgroundColor', [0.1 0.1 0.1], 'FontName', 'Arial Medium', 'Clipping', 'on', 'PositionConstraint', 'outerposition');
            title(app.AsphericityPlot, "RELATIVE ACIRCULARITY", 'Color', [0.95 0.95 0.95]);
            xlabel(app.AsphericityPlot, "TIME (s)");
            yyaxis(app.AsphericityPlot, 'right');
            ylabel(app.AsphericityPlot, "NORMALIZED RADIUS", 'Color', [0.95 0.95 0.95]);
            app.AsphericityPlot.YColor = [0.95 0.95 0.95];
            yyaxis(app.AsphericityPlot, 'left');
            ylabel(app.AsphericityPlot, "VIBRATION MODE INTENSITY");
            cmap = viridis(64);
            app.AsphericityPlot.YColor = cmap(end, :);
            app.FourierSecond = uilabel(app.PlotPanel, 'Text', 'SECOND TERM', 'FontColor', [0.95 0.95 0.95], 'FontName', 'Arial Medium', 'FontSize', 14);
            app.FourierLast = uilabel(app.PlotPanel, 'Text', 'LAST TERM', 'FontColor', [0.95 0.95 0.95], 'FontName', 'Arial Medium', 'FontSize', 14);
            app.FourierColorMap = uiimage(app.PlotPanel);
            disableDefaultInteractivity(app.AsphericityPlot);
            
            app.ViewerPanel = uipanel(app.AnalysisTab, 'BackgroundColor', [0.1, 0.1, 0.1], 'AutoResizeChildren', 'off', 'Scrollable', 'on', ...
                'BorderType', 'none');
            
            app.MainPlot = uiaxes(app.ViewerPanel, 'DataAspectRatio', [1 1 1], 'FontName', 'Arial', 'FontSize', 14, 'YDir', 'reverse', 'Box', 'on', ...
                'BoxStyle', 'full', 'XTick', [], 'YTick', [], 'Color', [0.1 0.1 0.1], 'BackgroundColor', [0.1 0.1 0.1], 'XColor', ...
                [0.95 0.95 0.95], 'YColor', [0.95 0.95 0.95], 'Clipping', 'on');
            
            app.EvolutionFirst = uilabel(app.ViewerPanel, 'Text', 'FIRST FRAME', 'FontColor', [178, 24, 43]./255, 'FontName', 'Arial Medium', ...
                'FontSize', 14);
            app.EvolutionLast = uilabel(app.ViewerPanel, 'Text', 'LAST FRAME', 'FontColor', [33, 102, 172]./255, 'FontName', 'Arial Medium', ...
                'FontSize', 14);
            app.EvolutionPlot = uiaxes(app.ViewerPanel, 'XColor', [0.95 0.95 0.95], 'YColor', [0.95 0.95 0.95], 'Color', [0.1 0.1 0.1], ...
                'BackgroundColor', [0.1 0.1 0.1], 'DataAspectRatio', [1 1 1], 'Box', 'on', 'XTick', [], 'YTick', [], 'YDir', 'reverse', 'Clipping', 'on');
            title(app.EvolutionPlot, "PERIMETER EVOLUTION OVERLAY", 'FontName', 'Arial Medium', 'Color', [0.95 0.95 0.95]);
            disableDefaultInteractivity(app.EvolutionPlot);
            scroll(app.ViewerPanel, 'top');
            
            %% Populate the logs tab
            app.LogArea = uitextarea(app.LogsTab, 'WordWrap', 'off', 'FontName', 'Courier', 'FontSize', 14, 'FontColor', [0, 255, 75]./255, 'BackgroundColor', ...
                [0, 0, 0], 'Editable', 'on', 'Value', ["Initializing..."], 'Enable', 'on');
            app.DownloadButton = uiimage(app.LogsTab, 'ScaleMethod', 'scaledown', 'ImageSource', 'download.svg', 'ImageClickedFcn', {@downloadLogs, app});
            
            %% Finish things up
            drawnow;
            app.UIFigure.Visible = 'on';
            
            %% Universal callbacks
            function toggleClicked(src, ~)
                if src.UserData == 1
                    src.UserData = 0;
                    src.ImageSource = 'toggle_off.svg';
                elseif src.UserData == 0
                    src.UserData = 1;
                    switch src.Tag
                        case "Detection"
                            src.ImageSource = 'toggle_on_detection.svg';
                        case "Analysis"
                            src.ImageSource = 'toggle_on_analysis.svg';
                    end
                end
                
            end
            
            function ftoggleClicked(src, ~, app)
                if src.UserData == 1
                    src.UserData = 0;
                    src.ImageSource = 'toggle_off.svg';
                    app.AdaptiveTermsToggle.Enable = 'off';
                    app.FitType.PolarSButton.Enable = 'off';
                    app.FitType.PolarPButton.Enable = 'off';
                    app.FitType.ParametricButton.Enable = 'off';
                    app.MinArcLengthField.Enable = 'off';
                    app.MaxTermsField.Enable = 'off';
                    app.TermsofInterestField.Enable = 'off';
                    app.MetricTermsField.Enable = 'off';
                elseif src.UserData == 0
                    src.UserData = 1;
                    src.ImageSource = 'toggle_on_analysis.svg';
                    app.AdaptiveTermsToggle.Enable = 'on';
                    app.FitType.PolarSButton.Enable = 'on';
                    app.FitType.PolarPButton.Enable = 'on';
                    app.FitType.ParametricButton.Enable = 'on';
                    app.MinArcLengthField.Enable = 'on';
                    app.MaxTermsField.Enable = 'on';
                    app.TermsofInterestField.Enable = 'on';
                    app.MetricTermsField.Enable = 'on';
                end
            end
            
            function actoggleClicked(src, ~, app)
                if src.UserData == 1
                    src.UserData = 0;
                    src.ImageSource = 'toggle_off.svg';
                    app.ColorThresholdField.Enable = 'on';
                elseif src.UserData == 0
                    src.UserData = 1;
                    src.ImageSource = 'toggle_on_detection.svg';
                    app.ColorThresholdField.Enable = 'off';
                end
            end
            
            function aetoggleClicked(src, ~, app)
                if src.UserData == 1
                    src.UserData = 0;
                    src.ImageSource = 'toggle_off.svg';
                    app.EdgeThresholdField.Enable = 'on';
                elseif src.UserData == 0
                    src.UserData = 1;
                    src.ImageSource = 'toggle_on_detection.svg';
                    app.EdgeThresholdField.Enable = 'off';
                end
            end
            
            function vltoggleClicked(src, ~, app)
                if src.UserData == 1
                    src.UserData = 0;
                    src.ImageSource = 'toggle_off.svg';
                    app.GARadioButton.Enable = 'off';
                    app.BSRadioButton.Enable = 'off';
                    app.BSField.Enable = 'off';
                elseif src.UserData == 0
                    src.UserData = 1;
                    src.ImageSource = 'toggle_on_detection.svg';
                    app.GARadioButton.Enable = 'on';
                    app.BSRadioButton.Enable = 'on';
                    if app.BSRadioButton.Value
                        app.BSField.Enable = 'on';
                    end
                end
            end
            
            function NLSelChanged(~, ~, app)
                if app.BSRadioButton.Value
                    app.BSField.Enable = 'on';
                else
                    app.BSField.Enable = 'off';
                end
            end
            
            function downloadLogs(~, ~, app)
                f = uiprogressdlg(app.UIFigure, 'Title', 'Please wait', 'Message', 'Downloading Logs...', 'Indeterminate', 'on');
                
                logText = app.LogArea.Value;
                [file, path] = uiputfile('*.log');
                if isequal(file, 0) || isequal(path, 0)
                    return;
                else
                    filepath = append(path, file);
                end
                
                fID = fopen(filepath, 'w');
                for i = 1:length(logText)
                    fprintf(fID, '%c', logText{i});
                    fprintf(fID, '\n');
                end
                fclose(fID);
                close(f);
            end
        end
    end
    
    % App creation and deletion
    methods (Access = public)
        
        % Construct app
        function app = InCA
            
            % Create UIFigure and components
            createComponents(app)
            
            % Register the app with App Designer
            registerApp(app, app.UIFigure)
            
            % Execute the startup function
            runStartupFcn(app, @startupFcn)
            
            if nargout == 0
                clear app
            end
        end
        
        % Code that executes before app deletion
        function delete(app)
            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
            clear;
        end
    end
end