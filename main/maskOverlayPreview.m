function ignoreFrames = maskOverlayPreview(parent, frames, mask)
panel = uipanel('Parent', parent, 'Position', [parent.Position(1) + 20, parent.Position(2) + 20, 1080, 720], 'Visible', 'off', 'BackgroundColor', [0.1, 0.1 0.1]);

panel.Visible = 'on';
end