%Returns a cell array of the individual frames in a
%video specified by the file path to the video
function [frames, vidPath, vidFile] = loadFrames()
[vidFile, vidPath] = uigetfile('*.avi');
if isempty(vidPath) || isempty(vidFile) || vidPath == '' || vidFile == ''
    return;
end
vidObj = VideoReader(append(vidPath, vidFile));
numFrames = vidObj.NumFrames;
vidObj = VideoReader(append(vidPath, vidFile));
%% Read the individual frames into a cell array
for i = 1:numFrames
    pause(0.01);
    img = readFrame(vidObj);            %Read the Frame
    img = rgb2hsv(img);                 %Convert to HSV
    img = img(:, :, 3);                 %Extract the value matrix
    frames(:, :, i) = img;              %Store the frame in the cell array
end
end
