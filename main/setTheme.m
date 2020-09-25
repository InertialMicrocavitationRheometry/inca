function setTheme(app, theme)
if theme == "default"
    app.DefaultButton.Value = true;
elseif theme == "dark"
    app.DarkButton.Value = true;
elseif theme == "night"
    app.NightButton.Value = true;
elseif theme == "army"
    app.ArmyButton.value = true;
elseif theme == "leather"
    app.LeatherButton.Value = true;
elseif theme == "waves"
    app.WavesButton.Value = true;
end
checkTheme(app);
end