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
                [~, ~, layer] = size(img);
                if layer > 1
                	img = rgb2hsv(img);                 %Convert to HSV
                    img = img(:, :, 3);                 %Extract the value matrix
                end
                spec = whos('img');
                class = string(spec.class);
                switch class
                    case "uint8"
                        img = double(img)./(2.^8 - 1);
                    case "uint16"
                        img = double(img)./(2.^16 - 1);
                    case "uint32"
                        img = double(img)./(2.^32 - 1);
                    case "uint64"
                        img = double(img)./(2.^64 - 1);
                    case "double"
                        img = img;
                    otherwise 
                        img = double(img)./max(img, [], 'all');
                end
                frames(:, :, i) = img;              %Store the frame in the cell array
            end
        end
        
        %Load in data from a previously analyzed video
        function [app, fullPath] = readFromFile(app)
            %% Load in the Data Table
            [file, path] = uigetfile('*.mat');
            if all(file == 0) && all(path == 0)
                fullPath = '';
                return;
            end
            fullPath = append(path, file);
            load(fullPath);
            %% Read in the data to the app variables if they exist in the current workspace
            if exist('frames', 'var') == 1
                app.frames = frames;
                [~, ~, app.numFrames] = size(frames);
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
            if exist('BubblePlotSet', 'var') == 1
                app.plotSet = BubblePlotSet;
            end
            if exist('InCASettings', 'var') == 1
                incaio.setSettings(InCASettings, app);
            end
        end
        
        %Write analyzed data to a file
        function savePath = writeToFile(app)
            %% Read in and import into local variables the data
            frames = app.frames;                            %Raw frames
            masks = app.mask;                               %Binary masks
            infoStruct = app.maskInformation;               %Analysis Results
            ignoreFrames = app.ignoreFrames;                %Frames to Ignore
            BubblePlotSet = app.plotSet;                    %Plotting Data
            InCASettings = incaio.compileSettings(app);     %User Specified Settings
            %% Write the table to the specified file
            [file, path] = uiputfile('*.mat');
            if all(file == 0) && all(path == 0)
                savePath = '';
                return;
            else
                savePath = append(path, file);
                save(savePath, 'frames', 'masks', 'infoStruct', 'ignoreFrames', 'BubblePlotSet', 'InCASettings', '-v7.3');
            end
        end
        
        %Compile current user-specified settings
        function settings = compileSettings(app)
            
            %Detection Settings
            settings.multiview = app.MultiviewToggle.UserData;
            settings.iff = app.IFFToggle.UserData;
            settings.ic = app.ICToggle.UserData;
            settings.rt = app.RTToggle.UserData;
            settings.vl = app.VLToggle.UserData;
            settings.vl_bs = app.BSRadioButton.Value;
            settings.vl_ga = app.GARadioButton.Value;
            settings.cstyle = app.CStyle.Value;
            settings.cval = app.CVal.Value;
            settings.autocolor = app.AutoColorToggle.UserData;
            settings.colorthresh = app.ColorThresholdField.Value;
            settings.estyle = app.EStyle.Value;
            settings.eval = app.EVal.Value;
            settings.autoedge = app.AutoEdgeToggle.UserData;
            settings.edgethresh = app.EdgeThresholdField.Value;
            
            %Analysis Settings
            settings.mpx = app.MPXField.Value;
            settings.fps = app.FPSField.Value;
            settings.tp = app.TPField.Value;
            settings.rotaxis = app.RotationAxis.ButtonGroup.SelectedObject;
            settings.ff = app.FourierFitToggle.UserData;
            settings.ft = app.FitType.ButtonGroup.SelectedObject;
            settings.minarc = app.MinArcLengthField.Value;
            settings.at = app.AdaptiveTermsToggle.UserData;
            settings.mt = app.MaxTermsField.Value;
            settings.toi = app.TermsofInterestField.Value;
            settings.metric_terms = app.MetricTermsField.Value;
            
        end
        
        %Set user-specified settings
        function setSettings(settings, app)
            
            %Detection settings
            if settings.multiview
                app.MultiviewToggle.UserData = 1;
                app.MultiviewToggle.ImageSource = 'toggle_on_detection.svg';
            else
                app.MultiviewToggle.UserData = 0;
                app.MultiviewToggle.ImageSource = 'toggle_off.svg';
            end
            
            if settings.iff 
                app.IFFToggle.UserData = 1;
                app.IFFToggle.ImageSource = 'toggle_on_detection.svg';
            else
                app.IFFToggle.UserData = 0;
                app.IFFToggle.ImageSource = 'toggle_off.svg';
            end
            
            if settings.ic 
                app.ICToggle.UserData = 1;
                app.ICToggle.ImageSource = 'toggle_on_detection.svg';
            else
                app.ICToggle.UserData = 0;
                app.ICToggle.ImageSource = 'toggle_off.svg';
            end
            
            if settings.rt
                app.RTToggle.UserData = 1;
                app.RTToggle.ImageSource = 'toggle_on_detection.svg';
            else
                app.RTToggle.UserData = 0;
                app.RTToggle.ImageSource = 'toggle_off.svg';
            end
            
            if settings.vl
                app.VLToggle.UserData = 1;
                app.VLToggle.ImageSource = 'toggle_on_detection.svg';
                app.GARadioButton.Enable = 'on';
                app.BSRadioButton.Enable = 'on';
                
                if settings.vl_bs
                    app.BSRadioButton.Value = 1;
                else
                    app.GARadioButton.Value = 1;
                end
                
                if app.BSRadioButton.Value
                    app.BSField.Enable = 'on';
                end
            else
                app.VLToggle.UserData = 0;
                app.VLToggle.ImageSource = 'toggle_off.svg';
                app.GARadioButton.Enable = 'off';
                app.BSRadioButton.Enable = 'off';
                app.BSField.Enable = 'off';
            end
            
            app.CStyle.Value = settings.cstyle;
            app.CVal.Value = settings.cval;
            app.ColorThresholdField.Value = settings.colorthresh;
            app.EStyle.Value = settings.estyle;
            app.EVal.Value = settings.eval;
            app.EdgeThresholdField.Value = settings.edgethresh;
            
            if settings.autocolor 
                app.AutoColorToggle.UserData = 1;
                app.AutoColorToggle.ImageSource = 'toggle_on_detection.svg';
            else
                app.AutoColorToggle.UserData = 0;
                app.AutoColorToggle.ImageSource = 'toggle_off.svg';
            end
            
            if settings.autoedge
                app.AutoEdgeToggle.UserData = 1;
                app.AutoEdgeToggle.ImageSource = 'toggle_on_detection.svg';
                app.EdgeThresholdField.Enable = 'off';
            else
                app.AutoEdgeToggle.UserData = 0;
                app.AutoEdgeToggle.ImageSource = 'toggle_off.svg';
                app.EdgeThresholdField.Enable = 'on';
            end
            
            % Analysis Settings
            app.MPXField.Value = settings.mpx;
            app.FPSField.Value = settings.fps;
            app.TPField.Value = settings.tp;
            try 
                app.RotationAxis.ButtonGroup.SelectedObject = settings.rotaxis;
                app.FitType.ButtonGroup.SelectedObject = settings.ft;
            catch me
                %app.LogExceptions(me);
            end
            app.MinArcLengthField.Value = settings.minarc;
            app.MaxTermsField.Value = settings.mt;
            app.TermsofInterestField.Value = settings.toi;
            app.MetricTermsField.Value = settings.metric_terms;
            
            if settings.ff
                app.FourierFitToggle.UserData = 1;
                app.FourierFitToggle.ImageSource = 'toggle_on_analysis.svg';
                app.AdaptiveTermsToggle.Enable = 'on';
                app.FitType.PolarSButton.Enable = 'on';
                app.FitType.PolarPButton.Enable = 'on';
                app.FitType.ParametricButton.Enable = 'on';
                app.MinArcLengthField.Enable = 'on';
                app.MaxTermsField.Enable = 'on';
                app.TermsofInterestField.Enable = 'on';
                app.MetricTermsField.Enable = 'on';
            else
                app.FourierFitToggle.UserData = 0;
                app.FourierFitToggle.ImageSource = 'toggle_off.svg';
                app.AdaptiveTermsToggle.Enable = 'off';
                app.FitType.PolarSButton.Enable = 'off';
                app.FitType.PolarPButton.Enable = 'off';
                app.FitType.ParametricButton.Enable = 'off';
                app.MinArcLengthField.Enable = 'off';
                app.MaxTermsField.Enable = 'off';
                app.TermsofInterestField.Enable = 'off';
                app.MetricTermsField.Enable = 'off';
            end
            
            if settings.at
                app.AdaptiveTermsToggle.UserData = 1;
                app.AdaptiveTermsToggle.ImageSource = 'toggle_on_analysis.svg';
            else
                app.AdaptiveTermsToggle.UserData = 0;
                app.AdaptiveTermsToggle.ImageSource = 'toggle_off.svg';
            end
                        
                
            
        end
    end
end