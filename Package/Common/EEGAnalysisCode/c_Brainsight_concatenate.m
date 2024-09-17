function combinedData = c_Brainsight_concatenate(varargin) 
	p = inputParser;
	p.addRequired('dataToMerge',@(x) iscell(x)); % cell array of Brainsight structs to merge
	p.parse(varargin{:});
	s = p.Results;
	
	dataToMerge = s.dataToMerge;
	
	assert(~isempty(dataToMerge));
	for iD = 1:length(dataToMerge)
		assert(isstruct(dataToMerge{iD}));
	end
	
	fieldsToAssertEqual = {'version','coordinateSystem','planLandmarks'};
	for iF = 1:length(fieldsToAssertEqual)
		for iD = 2:length(dataToMerge)
			if ~isequal(dataToMerge{1}.(fieldsToAssertEqual{iF}), dataToMerge{iD}.(fieldsToAssertEqual{iF}))
				error('Field %s is not equal between datasets to merge.',fieldsToAssertEqual{iF});
			end
		end
	end
	
	fieldsToAssertEmpty = {'electrodes'};
	for iF = 1:length(fieldsToAssertEmpty)
		for iD = 1:length(dataToMerge)
			if ~c_isEmptyOrEmptyStruct(dataToMerge{iD}.(fieldsToAssertEmpty{iF}))
				error('Field %s is not empty. Concatenation not currently supported for this field.',fieldsToAssertEmpty{iF});
			end
		end
	end
	
	combinedData = dataToMerge{1};
	
	fieldsToUnion = {'targets'};
	for iF = 1:length(fieldsToUnion)
		field = fieldsToUnion{iF};
		for iD = 2:length(dataToMerge)
			combinedData.(field) = c_structArray_union(combinedData.(field),dataToMerge{iD}.(field));
		end
	end
	
	fieldsToConcatenate = {'samples','sessLandmarks'};
	for iF = 1:length(fieldsToConcatenate)
		field = fieldsToConcatenate{iF};
		dim = c_findFirstNonsingletonDimension(combinedData.(field));
		for iD = 2:length(dataToMerge)
			combinedData.(field) = cat(dim,combinedData.(field),dataToMerge{iD}.(field));
		end
	end
end