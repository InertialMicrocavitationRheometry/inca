classdef logging
    methods (Static)
        %Generate and return a file ID for writing to log files
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
        
        %Load the log files for the viewer
        function output = loadLogs(filenames)
            for i = 1:length(filenames)
                fid = fopen(filenames{i}, 'r');
                j = 1;
                while ~feof(fid)
                    tline = string(fgetl(fid));
                    output(j, i) = tline;
                    j = j + 1;
                end
                fclose(fid);
            end
        end

    end
end