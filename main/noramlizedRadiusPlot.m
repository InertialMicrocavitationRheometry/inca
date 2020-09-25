function normalizedRadius = noramlizedRadiusPlot(info, numFrames, ignoreFrames)
rawRadius = zeros(1, numFrames);
parfor i = 1:numFrames
    if isempty(find(ignoreFrames == i, 1))
        xFit = info(i).FourierFitX;
        yFit = info(i).FourierFitY;
        rawRadius(i) = sqrt(xFit.a1^2 + yFit.b1^2);
    else
        rawRadius(i) = NaN;
    end
end
normalizedRadius = rawRadius./max(rawRadius);
end
