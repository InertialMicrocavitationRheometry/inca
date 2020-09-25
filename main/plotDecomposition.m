function plotDecomposition(app, points)
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
