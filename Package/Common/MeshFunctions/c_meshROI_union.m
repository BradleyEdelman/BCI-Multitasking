function ROI = c_meshROI_union(varargin)
% c_meshROI_union: combine mesh ROIs
% e.g. 
%		combinedROI = c_meshROI_union(ROI1,ROI2) 
% or
%		ROIs = [ROI1, ROI2];
%		combinedROI = c_meshROI_union(ROIs);

if nargin==1
	ROIs = varargin{1};
	assert(isstruct(ROIs));
else
	ROIs = varargin{1};
	assert(isstruct(ROIs));
	
	if isfield(ROIs,'isValidated')
		ROIs = rmfield(ROIs,'isValidated');
	end
	
	for iR = 2:nargin
		newROI = varargin{iR};
		if isfield(newROI,'isValidated')
			newROI = rmfield(newROI,'isValidated');
		end
		ROIs(iR) = newROI;
	end
end
if length(ROIs) <= 1
	% only one (or zero) ROIs, nothing to merge
	ROI = ROIs;
	return;
end

ROI = struct();

vertices = {ROIs.Vertices};
nonsingletonDim = c_findFirstNonsingletonDimension(ROIs(1).Vertices); % assume same for all ROIs
ROI.Vertices = cat(nonsingletonDim, vertices{:});
ROI.Vertices = unique(ROI.Vertices); % remove duplicate indices

ROI.Label = c_toString({ROIs.Label});

if 0
	% set new color to mean of input colors
	roiColors = c_struct_mapToArray(ROIs,{'Color'});
	assert(ismember(size(roiColors,2),[1 3])); % scalar or vector colors
	meanColor = mean(roiColors,1);
	ROI.Color = meanColor;
else
	% set new color to color of first ROI
	ROI.Color = ROIs(1).Color;
end

ROI.Seed = ROIs(1).Seed; % use first seed as seed for all (since mean doesn't make sense)

end
