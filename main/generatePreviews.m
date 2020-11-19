function generatePreviews(app, frames, mask)
%% A function to generate mask overlay previews for InCA.

%Get the size of the image and the number of frames
[height, width, app.numFrames] = size(frames);

%Get the size of the InCA main window
parentPos = app.UIFigure.Position;

%Create a panel on top of the existing window to house the mask previews
MaskOverlayPreviewPanel = uipanel('Parent', app.UIFigure, 'BorderType', 'line', 'Position', [50, 50, parentPos(3) - 100, parentPos(4) - 100], ...
    'BackgroundColor', [0.1 0.1 0.1], 'Scrollable', 'on', 'AutoResizeChildren', 'off');
parentPos = MaskOverlayPreviewPanel.Position;

%Create a panel within the mask preview panel to house the thumbnails
ScrollPanel = uipanel('Parent', MaskOverlayPreviewPanel, 'BorderType', 'none', 'Position', [1 1, parentPos(3)/5, parentPos(4) - 5],...
    'BackgroundColor', [0 0 0], 'Scrollable', 'on', 'AutoResizeChildren', 'off');
panelPos = ScrollPanel.Position;

%Create the main viewer for the masks
mainAxes = uiaxes(MaskOverlayPreviewPanel, 'AmbientLightColor', [0 0 0], 'FontName', 'Roboto', 'FontSize', 12, 'XColor', [1 1 1], ...
                'YColor', [1 1 1], 'Color', [0 0 0], 'BackgroundColor', [0 0 0], 'Position', [parentPos(3)/5, 55, parentPos(3)*4/5, parentPos(4) - 60]);

%Create the requried buttons: close, accept, reject, next, and previous
buttonWidth = floor((parentPos(3)*4/5 - 30)/6);

%Previous Button
uibutton(MaskOverlayPreviewPanel, 'push', 'FontName', 'Roboto Medium', 'FontSize', 10, ...
    'Icon', 'baseline_skip_previous_white_48dp.png', 'IconAlignment', 'top', 'Text', 'PREVIOUS', 'VerticalAlignment', 'bottom', 'FontColor', [1 1 1], ...
    'Position', [parentPos(3)/5 + 5, 5, 100, 50], 'BackgroundColor', [0, 0.29, 1], "ButtonPushedFcn", {@previousClicked});
%Next Button
uibutton(MaskOverlayPreviewPanel, 'push', 'Text', 'NEXT', 'FontName', 'Roboto', 'FontSize', 10, 'FontColor', [1 1 1], 'Icon', ...
    'baseline_skip_next_white_48dp.png', 'IconAlignment', 'top', 'VerticalAlignment', 'bottom', 'Position', ...
    [parentPos(3) - 100 - 5, 5, 100, 50], 'BackgroundColor', [0 0.29 1], "ButtonPushedFcn", {@nextClicked, app.numFrames});
%Reject Button
uibutton(MaskOverlayPreviewPanel, 'push', 'FontName', 'Roboto Medium', 'FontSize', 10, 'Icon', 'baseline_close_white_48dp.png', 'IconAlignment', 'top', 'Text',...
    'REJECT', 'VerticalAlignment', 'bottom', 'FontColor', [1 1 1], 'ButtonPushedFcn', {@rejectClicked, app}, 'Position', ...
    [parentPos(3)/5 + 110 ,5, 100, 50], 'BackgroundColor', [176 0 32]./255);
%Accpet Button
uibutton(MaskOverlayPreviewPanel, 'push', 'FontName', 'Roboto Medium', 'FontSize', 10, 'Icon', 'baseline_done_white_48dp.png', 'IconAlignment', 'top', 'Text',...
    'ACCEPT', 'VerticalAlignment', 'bottom', 'FontColor', [1 1 1], 'ButtonPushedFcn', {@acceptClicked, app}, 'Position', ...
    [parentPos(3) - 210 ,5, 100, 50], 'BackgroundColor', [8 226 55]./255);
%Close Button
uibutton(MaskOverlayPreviewPanel, 'push', 'FontName', 'Roboto Medium', 'FontSize', 14, 'Text', 'SAVE & CLOSE', 'FontColor', [1 1 1], 'ButtonPushedFcn', ...
    {@closeClicked, MaskOverlayPreviewPanel},'Position', [parentPos(3)/5 + (parentPos(3)*2/5 - 50), 5, 100, 50], 'BackgroundColor', [0 0.29 1]);


%Populate the thumbnail panel
for i = 1:app.numFrames
    index = (app.numFrames + 1) - i;
    if isempty(find(app.ignoreFrames == index, 1))
        if any(any(mask(:, :, index)))
        uiimage(ScrollPanel, "ScaleMethod",'scaledown', 'ImageSource', ...
            labeloverlay(frames(:, :, index), mask(:, :, index)), "Position", [5, (5 + (i - 1)*(height/width*panelPos(4))), panelPos(3) - 10, height/width*(panelPos(4) - 10)], ...
            "ImageClickedFcn", {@imageClicked},'Tooltip', "Click to ignore frame " + num2str(index) + " during calculations", 'Tag', num2str(index));
        else
            image = zeros(size(frames(:, :, index)));
            image(:, :, 3) = frames(:, :, index);
            image = hsv2rgb(image);
            uiimage(ScrollPanel, "ScaleMethod",'scaledown', 'ImageSource', ...
                image, "Position", [5, (5 + (i - 1)*(height/width*panelPos(4))), panelPos(3) - 10, height/width*(panelPos(4) - 10)], ...
                "ImageClickedFcn", {@imageClicked},'Tooltip', "Click to ignore frame " + num2str(index) + " during calculations", 'Tag', num2str(index));
        end
    else
        if any(any(mask(:, :, index)))
        uiimage(ScrollPanel, "ScaleMethod",'scaledown', 'ImageSource', ...
            labeloverlay(frames(:, :, index), ones(size(frames(:, :, index))), 'Colormap', 'autumn'), "Position", [5, (5 + (i - 1)*(height/width*panelPos(4))), panelPos(3) - 10, height/width*(panelPos(4) - 10)], ...
            "ImageClickedFcn", {@imageClicked},'Tooltip', "This frame will be ignored during bubble analysis", 'Tag', num2str(index));
        else
            image = zeros(size(frames(:, :, index)));
            image(:, :, 3) = frames(:, :, index);
            image = hsv2rgb(image);
            uiimage(ScrollPanel, "ScaleMethod",'scaledown', 'ImageSource', ...
                labeloverlay(image, ones(size(frames(:, :, index))), 'Colormap', 'autumn'), "Position", [5, (5 + (i - 1)*(height/width*panelPos(4))), panelPos(3) - 10, height/width*(panelPos(4) - 10)], ...
                "ImageClickedFcn", {@imageClicked},'Tooltip', "This frame will be ignored during bubble analysis", 'Tag', num2str(index));
        end
    end
end

%Scroll to the top of the panel when done and show the first frame in the
%main viewer
scroll(ScrollPanel, 'top');
imshow(labeloverlay(frames(:, :, 1), mask(:, :, 1)), 'Parent', mainAxes);
frameInView = 1;

    %% Image Clicked Function
    function imageClicked(src, ~)
        frameNo = str2double(src.Tag);
        frameInView = frameNo;
        imshow(labeloverlay(frames(:, :, frameNo), mask(:, :, frameNo)), 'Parent', mainAxes);
    end

    %% Close Button Function
    function closeClicked(~, ~, MaskOverlayPreviewPanel)
        delete(MaskOverlayPreviewPanel);
    end

    %% Next Button Function
    function nextClicked(~, ~, topLim)
        if frameInView == topLim
            frameInView = 1;
            imshow(labeloverlay(frames(:, :, frameInView), mask(:, :, frameInView)), 'Parent', mainAxes);
        else
            frameInView = frameInView + 1;
            imshow(labeloverlay(frames(:, :, frameInView), mask(:, :, frameInView)), 'Parent', mainAxes);
        end
    end

    %% Previous Button Function
    function previousClicked(~, ~)
        if frameInView == 1
            frameInView = app.numFrames;
            imshow(labeloverlay(frames(:, :, frameInView), mask(:, :, frameInView)), 'Parent', mainAxes);
        else
            frameInView = frameInView - 1;
            imshow(labeloverlay(frames(:, :, frameInView), mask(:, :, frameInView)), 'Parent', mainAxes);
        end
    end

    %% Accept Button Function
    function acceptClicked(~, ~, app)
        app.ignoreFrames = app.ignoreFrames(app.ignoreFrames ~= frameInView);
        frameofInterest = findobj(ScrollPanel, 'Tag', num2str(frameInView));
        if any(any(app.mask(:, :, frameInView)))
            frameofInterest.ImageSource = labeloverlay(app.frames(:, :, frameInView), app.mask(:, :, frameInView));
        else
            plainimage = zeros(size(app.frames(:, :, frameInView)));
            plainimage(:, :, 3) = app.frames(:, :, frameInView);
            plainimage = hsv2rgb(plainimage);
            frameofInterst.ImageSource = plainimage;
        end
        frameofInterst.Tooltip = "Click to ignore frame " + num2str(frameInView) + " during calculations";
        uialert(app.UIFigure, 'This frame will be used during bubble analysis', 'Message', 'Icon', 'success');
    end

    %% Reject Button Clicked
    function rejectClicked(~, ~, app)
        app.ignoreFrames(length(app.ignoreFrames) + 1) = frameInView;
        frameofInterest = findobj(ScrollPanel, 'Tag', num2str(frameInView));
        dontUseMask = ones(size(app.frames(:, :, frameInView)));
        frameofInterest.ImageSource = labeloverlay(app.frames(:, :, frameInView), dontUseMask, 'Colormap', 'autumn');
        frameofInterset.Tooltip = "This frame will be ignored during bubble analysis";
        uialert(app.UIFigure, 'This frame will be ignored during bubble analysis', 'Message');
    end
            
end
