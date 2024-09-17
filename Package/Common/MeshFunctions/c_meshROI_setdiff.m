function ROI = c_meshROI_setdiff(ROI1, ROI2)
assert(c_meshROI_isValid(ROI1));
assert(c_meshROI_isValid(ROI2));

ROI = ROI1;

ROI.Vertices(ismember(ROI1.Vertices,ROI2.Vertices)) = [];

ROI.Label = sprintf('(%s-%s)',ROI1.Label,ROI2.Label);

end