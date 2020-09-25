function updateTheme(app, newTheme)
app.theme.mainbackgroundColor = newTheme{1};
app.theme.backgroundColor = newTheme{2};
app.theme.foregroundColor = newTheme{3};
app.theme.axisColor = newTheme{4};
app.theme.plotBackground = newTheme{5};
app.theme.textBackgroundColor = newTheme{6};
app.theme.fontColor = newTheme{7};
app.theme.plotStyle = newTheme{8};
app.theme.markerStyle = newTheme{9};
app.theme.buttonBackgroundColor = newTheme{10};
app.colorMap.Start = newTheme{11};
app.colorMap.End = newTheme{12};
changeTheme(app);
end