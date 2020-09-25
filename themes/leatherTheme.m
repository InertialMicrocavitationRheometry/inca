function output = leatherTheme
mainbackgroundColor = [122, 37, 0]./255;
backgroundColor = [181, 106, 0]./255;
foregroundColor = [224, 224, 224]./255;
axisColor = [222, 220, 224]./255;
plotBackground = [120, 120, 120]./255;
textBackgroundColor = [122, 37, 0]./255;
fontColor = [250, 250, 250]./255;
plotStyle = [255, 237, 209]./255;
markerStyle = [122, 37, 0]./255;
buttonBackgroundColor = [143, 74, 0]./255;
Start = [178, 24, 43]./255;
End = [33, 102, 172]./255;

output = cell(12, 1);
output{1} = mainbackgroundColor;
output{2} = backgroundColor;
output{3} = foregroundColor;
output{4} = axisColor;
output{5} = plotBackground;
output{6} = textBackgroundColor;
output{7} = fontColor;
output{8} = plotStyle;
output{9} = markerStyle;
output{10} = buttonBackgroundColor;
output{11} = Start;
output{12} = End;
end