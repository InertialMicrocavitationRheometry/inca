function checkTheme(app)
if app.DefaultButton.Value == true
    newTheme = defaultTheme();
elseif app.DarkButton.Value == true
    newTheme = darkTheme;
elseif app.NightButton.Value == true
    newTheme = nightTheme();
elseif app.ArmyButton.Value == true
    newTheme = armyTheme();
elseif app.LeatherButton.Value == true
    newTheme = leatherTheme();
elseif app.WavesButton.Value == true
    newTheme = wavesTheme();
elseif app.CustomButton.Value == true
    file = uigetfile('*.m');
    fileName  = file(1:end - 2);
    figure(app.UIFigure);
    newTheme = eval(fileName);
end
updateTheme(app, newTheme);
end