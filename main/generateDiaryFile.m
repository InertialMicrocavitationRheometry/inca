function fileID = generateDiaryFile(logType)

currentDirectory = pwd;
idcs = strfind(currentDirectory, filesep);
if contains(currentDirectory, "InCA/main") || contains(currentDirectory, "InCA/themes") || contains(currentDirectory, "logs")
    parentDirectory = currentDirectory(1:idcs(end) - 1);
else 
    parentDirectory = currentDirectory;
end
parentDirectory = replace(parentDirectory, "\", "/");
diaryFile =  "InCA/logs/" + logType + " " + datestr(datetime('now'));
diaryFile = replace(diaryFile, ":", "_");
fileID = fopen(parentDirectory + diaryFile + ".log", 'w');

end