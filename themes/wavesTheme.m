function output = wavesTheme 
mainbackgroundColor = [57, 154, 250]./255;
backgroundColor = [143, 199, 255]./255;
foregroundColor = [0, 42, 84]./255;
axisColor = [0.15, 0.15, 0.15];
plotBackground = [1, 1, 1];
textBackgroundColor = [1, 1, 1];
fontColor = [0, 42, 84]./255;
plotStyle = [23, 164, 230]./255;
markerStyle = [0, 0, 255]./255;
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