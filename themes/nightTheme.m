function output = nightTheme
mainbackgroundColor = [0, 0, 0];
backgroundColor = [43, 43, 43]./255;
foregroundColor = [0.96, 0.96, 0.96];
axisColor = [0.94, 0.94, 0.94];
plotBackground = [0, 0, 0];
textBackgroundColor = [0.15, 0.15, 0.15];
fontColor = [0.96, 0.96, 0.96];
plotStyle = [0, 0, 1];
markerStyle = [0, 1, 0];
buttonBackgroundColor = [0.2, 0.2, 0.2];
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