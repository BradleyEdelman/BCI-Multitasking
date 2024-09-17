function chanlocs = c_EEG_mapElectrodeLocationsByName(varargin)
p = inputParser();
p.addRequired('baseChanlocs'); % the struct to copy into (with numbers and names)
p.addRequired('extraChanlocs'); % the struct to copy information from (with locations and names)
p.parse(varargin{:});

b = p.Results.baseChanlocs;
e = p.Results.extraChanlocs;

eLabels = {e.labels};

extraIndicesUsed = zeros(size(e));

for i=1:length(b)
	newE = b(i);

	label = b(i).labels;
	indices = ismember(lower(eLabels),lower(label));
	if isempty(indices) || sum(indices)==0
		error('Location not found for electrode #%d',i);
	end
	if sum(indices) > 1
		error('Duplicate locations for electrode #%d',i);
	end
	fieldsToCopy = {'X','Y','Z','theta','radius','sph_theta','sph_phi','sph_radius','sph_phi_besa','sph_theta_besa'};
	for j=1:length(fieldsToCopy)
		newE.(fieldsToCopy{j}) = e(indices).(fieldsToCopy{j});
	end
	if isempty(newE.urchan), newE.urchan = i; end;
	if i ~= e(indices).urchan
		warning('Label matched for %s does not have matching urchan',b(i).labels)
	end

	extraIndicesUsed(indices) = true;
	
	chanlocs(i) = newE;
end

if any(~extraIndicesUsed)
	warning('Some location information not used: %d', c_toString(find(~extraIndicesUsed)));
end

end