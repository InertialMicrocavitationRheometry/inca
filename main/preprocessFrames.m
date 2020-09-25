function returnFrames = preprocessFrames(app, inputFrames)

fileID = generateDiaryFile("FramePreProcessingLog");

[~, ~, numImages] = size(inputFrames);
returnFrames = zeros(size(inputFrames));

fprintf(fileID, '%s', "Beginning Frame Preprocessing");
fprintf(fileID, '\n');
fprintf(fileID, '%s', "User input selection: ");
fprintf(fileID, '\n');
fprintf(fileID, '%s', "Sharpen frames before detection: " + num2str(app.SharpenButton.Value));
fprintf(fileID, '\n');
fprintf(fileID, '%s', "Soften frames before detection: " + num2str(app.SoftenButton.Value));
fprintf(fileID, '\n');
fprintf(fileID, '%s', "Filter strength: " + num2str(app.FilterStrengthSpinner.Value));
fprintf(fileID, '\n');

if app.SharpenButton.Value
    for i = 1:numImages
        fprintf(fileID, '%s', "Sharpening frame: " + num2str(i));
        fprintf(fileID, '\n');
        returnFrames(:, :, i) = imsharpen(inputFrames(:, :, i),'Amount', app.FilterStrengthSpinner.Value);
        fprintf(fileID, '%s', "Complete");
        fprintf(fileID, '\n');
    end
else
    for i = 1:numImages
        fprintf(fileID, '%s', "Softening frame: " + num2str(i));
        fprintf(fileID, '\n');
        returnFrames(:, :, i) = imgaussfilt(inputFrames(:, :, i), app.FilterStrengthSpinner.Value);
        fprintf(fileID, '%s', "Complete");
        fprintf(fileID, '\n');
    end
end

fclose(fileID);

end