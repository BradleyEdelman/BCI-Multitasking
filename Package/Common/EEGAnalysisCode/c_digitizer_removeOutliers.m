function raw = c_digitizer_removeOutliers(varargin)
p = inputParser();
p.addRequired('raw',@isstruct);
p.addParameter('removeElectrodes',true,@islogical);
p.addParameter('removeShapePoints',false,@islogical);
p.parse(varargin{:});
s = p.Results;
raw = s.raw;

if ~s.removeElectrodes && ~s.removeShapePoints
	warning('Not changing anything');
	return;
end

if s.removeShapePoints
	error('Not yet supported');
end

% use center of fiducials as center
fiducialsXYZ = c_struct_mapToArray(raw.electrodes.fiducials,{'X','Y','Z'});
center = mean(fiducialsXYZ,1);

if s.removeElectrodes
	xyz = c_struct_mapToArray(raw.electrodes.electrodes,{'X','Y','Z'});
	
	%center = mean(xyz);
	
	distsFromCenter = c_norm(bsxfun(@minus,xyz,center),2,2);
	
	outlierThreshold = iqr(distsFromCenter)*10;
	
	indicesToRemove = distsFromCenter > outlierThreshold;
	
	numToRemove = sum(indicesToRemove);
	if numToRemove == 0
		c_saySingle('Not removing any electrodes');
	else
		c_say('Removing %d electrodes',numToRemove);
		c_saySingle('%s',c_toString({raw.electrodes.electrodes(indicesToRemove).label}));
		c_sayDone();

		raw.electrodes.electrodes = raw.electrodes.electrodes(~indicesToRemove); %TODO: update urchan or other channel number fields as needed
	end
end
end