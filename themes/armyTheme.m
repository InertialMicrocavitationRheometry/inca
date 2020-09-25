function output = armyTheme
mainbackgroundColor = [75,83,32]./255;
backgroundColor = [92, 101, 39]./255;
foregroundColor = [247, 252, 202]./255;
axisColor = [255, 255, 232]./255;
plotBackground = [1, 1, 1];
textBackgroundColor = [75,83,32]./255;
fontColor = [255, 255, 232]./255;
plotStyle = [0, 186, 34]./255;
markerStyle = [212, 0, 0]./255;
buttonBackgroundColor = [31, 89, 0]./255;
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