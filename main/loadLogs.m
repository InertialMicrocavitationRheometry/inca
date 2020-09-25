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
