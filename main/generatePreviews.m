function generatePreviews(app, frames, mask)
%% A function to generate mask overlay previews for InCA.
[height, width, app.numFrames] = size(frames);
panelPos = app.MaskOverlayPreviewPanel.Position;
for i = 1:app.numFrames
    
    index = (app.numFrames + 1) - i;
    if isempty(find(app.ignoreFrames == index, 1))
        contextMenu = uicontextmenu(app.UIFigure);
        mitem = uimenu(contextMenu, "Text", "View frame " + num2str(index) + " in larger window");
        mitem.MenuSelectedFcn = {@openLarger, app, width, height};
        mitem.Tag = num2str(index);
        if any(any(mask(:, :, index)))
        uiimage(app.MaskOverlayPreviewPanel, "ScaleMethod",'scaledown', 'ImageSource', ...
            labeloverlay(frames(:, :, index), mask(:, :, index)), "Position", [5, (5 + (i - 1)*(height/width*panelPos(4))), panelPos(3) - 10, height/width*(panelPos(4) - 10)], ...
            "ImageClickedFcn", {@imageClicked, app},'Tooltip', "Click to ignore frame " + num2str(index) + " during calculations", 'Tag', num2str(index)...
            ,"ContextMenu", contextMenu);
        else
            image = zeros(size(frames(:, :, index)));
            image(:, :, 3) = frames(:, :, index);
            image = hsv2rgb(image);
            uiimage(app.MaskOverlayPreviewPanel, "ScaleMethod",'scaledown', 'ImageSource', ...
                image, "Position", [5, (5 + (i - 1)*(height/width*panelPos(4))), panelPos(3) - 10, height/width*(panelPos(4) - 10)], ...
                "ImageClickedFcn", {@imageClicked, app},'Tooltip', "Click to ignore frame " + num2str(index) + " during calculations", 'Tag', num2str(index)...
                ,"ContextMenu", contextMenu);
        end
    else
        contextMenu = uicontextmenu(app.UIFigure);
        mitem = uimenu(contextMenu, "Text", "View frame " + num2str(index) + " in larger window");
        mitem.MenuSelectedFcn = {@openLarger, app, width, height};
        mitem.Tag = num2str(index);
        if any(any(mask(:, :, index)))
        uiimage(app.MaskOverlayPreviewPanel, "ScaleMethod",'scaledown', 'ImageSource', ...
            labeloverlay(frames(:, :, index), ones(size(frames(:, :, index))), 'Colormap', 'autumn'), "Position", [5, (5 + (i - 1)*(height/width*panelPos(4))), panelPos(3) - 10, height/width*(panelPos(4) - 10)], ...
            "ImageClickedFcn", {@imageClicked, app},'Tooltip', "This frame will be ignored during bubble analysis", 'Tag', num2str(index) + "NaN"...
            ,"ContextMenu", contextMenu);
        else
            image = zeros(size(frames(:, :, index)));
            image(:, :, 3) = frames(:, :, index);
            image = hsv2rgb(image);
            uiimage(app.MaskOverlayPreviewPanel, "ScaleMethod",'scaledown', 'ImageSource', ...
                labeloverlay(image, ones(size(frames(:, :, index))), 'Colormap', 'autumn'), "Position", [5, (5 + (i - 1)*(height/width*panelPos(4))), panelPos(3) - 10, height/width*(panelPos(4) - 10)], ...
                "ImageClickedFcn", {@imageClicked, app},'Tooltip', "This frame will be ignored during bubble analysis", 'Tag', num2str(index) + "NaN"...
                ,"ContextMenu", contextMenu);
        end
    end
end

scroll(app.MaskOverlayPreviewPanel, 'top');

    %% Image Clicked Function
    function imageClicked(src, ~, app)
        if contains(src.Tag, "NaN")
            src.Tag = erase(src.Tag, "NaN");
            frameNo = str2double(src.Tag);
            src.Tooltip = "Click to ignore frame " + num2str(frameNo) + " during calculations";
            if any(any(app.mask(:, :, frameNo)))
                src.ImageSource = labeloverlay(app.frames(:, :, frameNo), app.mask(:, :, frameNo));
            else
                plainimage = zeros(size(app.frames(:, :, frameNo)));
                plainimage(:, :, 3) = app.frames(:, :, frameNo);
                plainimage = hsv2rgb(plainimage);
                src.ImageSource = plainimage;
            end
            app.ignoreFrames = app.ignoreFrames(app.ignoreFrames ~= frameNo);
            if app.FrameIgnoreWarningCheckBox.Value
                uialert(app.UIFigure, "Frame " + num2str(frameNo) + " will NOT be ignored during bubble analysis" , 'Message', 'Icon', 'info');
            end
        else
            frameNo = str2double(src.Tag);
            src.Tag = src.Tag + "NaN";
            src.Tooltip = "This frame will be ignored during bubble analysis";
            app.ignoreFrames(length(app.ignoreFrames) + 1) = frameNo;
            dontUseMask = ones(size(app.frames(:, :, frameNo)));
            src.ImageSource = labeloverlay(app.frames(:, :, frameNo), dontUseMask, 'Colormap', 'autumn');
            if app.FrameIgnoreWarningCheckBox.Value
                uialert(app.UIFigure, "Frame " + num2str(frameNo) + " will be ignored during bubble analysis" , 'Message', 'Icon', 'info');
            end
        end
        
    end

    %% Open Larger Function
    function openLarger(src, ~, app, width, height)
        fig = uifigure("Position", [200, 200, width, height]);
        uiimage(fig, "Position", [0, 0, width, height], 'ImageSource', labeloverlay(app.frames(:, :, str2double(src.Tag)), app.mask(:, :, str2double(src.Tag))), "ScaleMethod", 'scaledown');
    end
end
