function output = defaultTheme
mainbackgroundColor = [0.94, 0.94, 0.94];
backgroundColor = [0.94, 0.94, 0.94];
foregroundColor = [0, 0, 0];
axisColor = [0.15, 0.15, 0.15];
plotBackground = [1, 1, 1];
textBackgroundColor = [1, 1, 1];
fontColor = [0, 0, 0];
plotStyle = [0, 0.447, 0.741];
markerStyle = 'g';
buttonBackgroundColor = [0.96, 0.96, 0.96];
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