function [raw, estimatedTransform] = c_digitizer_alignToPoints(varargin)
p = inputParser();
p.addRequired('raw',@isstruct);
p.addParameter('fiducialsToAlign',[],@isstruct);
p.addParameter('shapePointsToAlign',[],@isstruct);
p.addParameter('electrodesToAlign',[],@isstruct);
p.addParameter('doUseElectrodesAsShapePoints',true,@islogical);
p.parse(varargin{:});
s = p.Results;
raw = s.raw;

if isempty(s.fiducialsToAlign) && isempty(s.shapePointsToAlign) && isempty(s.electrodesToAlign)
	error('No alignment points specified');
end

if ~isempty(s.electrodesToAlign)
	keyboard %TODO: implement alignment of electrodes
end

if ~isempty(s.shapePointsToAlign)
	keyboard %TODO: implement alignment of shape points
	%TODO: check doUseElectrodesAsShapePoints to determine whether to add electrode points to list of shape points
end

if ~isempty(s.fiducialsToAlign)
	assert(c_isFieldAndNonEmpty(raw,'electrodes.fiducials'));
	%TODO: verify that if present, raw.shape.fiducials is identical (or handle any differences)
	
	alignPts = c_struct_mapToArray(s.fiducialsToAlign,{'X','Y','Z'});
	alignPtLabels = {s.fiducialsToAlign.label};
	alignPtLabels = mapFiducialNameToStandard(alignPtLabels);
	
	origPts = c_struct_mapToArray(raw.electrodes.fiducials,{'X','Y','Z'});
	origPtLabels = {raw.electrodes.fiducials.label};
	origPtLabels = mapFiducialNameToStandard(origPtLabels);
	
	% although this is not ideal, handle multiple samples of the same fiducial by averaging before aligment
	[alignPts, alignPtLabels] = averageDuplicateLabeledPoints(alignPts, alignPtLabels);
	[origPts, origPtLabels] = averageDuplicateLabeledPoints(origPts, origPtLabels);
	
	assert(isequal(alignPtLabels,origPtLabels)); %TODO: add code to handle cases where these are not equal (e.g. missing fiducials, different order, etc.)
	
	estimatedTransform = c_pts_estimateAligningTransformation(...
		'stationaryPts',alignPts,...
		'movingPts',origPts);
end

raw = c_digitizer_applyTransform(raw,estimatedTransform);

end

function name = mapFiducialNameToStandard(name)
	if iscell(name)
		for j=1:length(name)
			name{j} = mapFiducialNameToStandard(name{j});
		end
		return;
	end

	correspondingNames = {...
		{'Nasion','NA','X+'},...
		{'LPA','Y+','Left'},...
		{'RPA','Y-','Right'},...
	};
	for i=1:length(correspondingNames)
		if ismember(name,correspondingNames{i})
			name = correspondingNames{i}{1};
			return;
		end
	end
	% if here, name was not recognized
	% (in this case, don't modify name)
end

function [uniquePts, uniqueLabels] = averageDuplicateLabeledPoints(pts,ptLabels)
	assert(length(ptLabels)==size(pts,1));
	uniqueLabels = unique(ptLabels);
	uniquePts = nan(length(uniqueLabels),size(pts,2));
	for iL = 1:length(uniqueLabels)
		indices = ismember(ptLabels,uniqueLabels{iL});
		uniquePts(iL,:) = mean(pts(indices,:),1);
	end
end