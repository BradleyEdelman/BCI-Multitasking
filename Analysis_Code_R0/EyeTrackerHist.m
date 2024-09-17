function [xb,yb,hist1]=EyeTrackerHist(histdat,Title)
    
    edges{1}=-.5:.01:1.5;
    edges{2}=-.5:.01:1.5;
    hist = hist3(histdat,'Edges',edges);
    hist1=hist';
    hist1(size(hist,1) + 1, size(hist,2) + 1) = 0;
%     xb = linspace(min(histdat(:,1)),max(histdat(:,1)),size(hist,1)+1);
%     yb = linspace(min(histdat(:,2)),max(histdat(:,2)),size(hist,1)+1);
    xb=edges{1};
    yb=edges{2};
%     title(Title)
%     imagesc(xb,yb,hist1);