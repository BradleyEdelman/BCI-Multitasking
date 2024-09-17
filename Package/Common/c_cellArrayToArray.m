function array = c_cellArrayToArray(varargin)
	p = inputParser();
	p.addRequired('cellArray',@iscell);
	p.addParameter('doDiscardUncommonFields',true,@islogical); % if false, missing fields will be set to []
	p.addParameter('doWarnOnUncommonFields',true,@islogical);
	p.parse(varargin{:});
	s = p.Results;
	cellArray = s.cellArray;
	
	if isstruct(cellArray{1})
		assert(all(cellfun(@isstruct,cellArray)));
		
		fieldNames = cellfun(@fieldnames,cellArray,'UniformOutput',false);
		allFields = c_union(fieldNames{:});
		commonFields = c_intersect(fieldNames{:});
		missingFields = setdiff(allFields,commonFields);
		
		if ~isempty(missingFields) && s.doWarnOnUncommonFields
			if s.doDiscardUncommonFields
				warning('Discarding fields because they are not present in all elements of input: %s',c_toString(missingFields));
			else
				warning('Setting values of missing fields %s to []',c_toString(missingFields));
			end
		end
		
		if s.doDiscardUncommonFields
			fieldsInOutput = commonFields;
		else
			fieldsInOutput = allFields;
		end
		structArgs = cell(1,length(fieldsInOutput)*2);
		structArgs(1:2:end) = fieldsInOutput;
		array = struct(structArgs{:});
		
		for i=1:length(cellArray)
			for iF = 1:length(missingFields)
				if s.doDiscardUncommonFields
					if isfield(cellArray{i},missingFields{iF})
						cellArray{i} = rmfield(cellArray{i},missingFields{iF});
					end
				else
					if ~isfield(cellArray{i},missingFields{iF})
						cellArray{i}.(missingFields{iF}) = [];
					end
				end
			end
			if i==1
				array = cellArray{i};
			else
				array(i) = cellArray{i};
			end
		end
	elseif isscalar(cellArray{1})
		assert(all(cellfun(@isscalar,cellArray)));
		keyboard %TODO
	else
		error('Unsupported cell array type');
	end

end