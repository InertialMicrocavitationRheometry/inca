function output = darkTheme()
mainbackgroundColor = [54, 54, 54]./255;
backgroundColor = [49, 61, 89]./255;
foregroundColor = [255, 254, 235]./255;
axisColor = [255, 251, 196]./255;
plotBackground = [22, 27, 41]./255;
textBackgroundColor = [0.15, 0.15, 0.15];
fontColor = [0.98, 0.98, 0.98];
plotStyle = [41, 97, 255]./255;
markerStyle = [45, 255, 41]./255;
buttonBackgroundColor = [0, 2, 107]./255;
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