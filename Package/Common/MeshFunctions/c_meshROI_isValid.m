function [isValidated, validatedROI] = c_meshROI_isValid(ROI,varargin)
p = inputParser;
p.addRequired('ROI');
p.addOptional('mesh',[],@c_mesh_isValid);
p.addParameter('doWarn',true,@islogical);
p.addParameter('exhaustive',false,@islogical); % whether to do more computationally expensive checks
p.parse(ROI,varargin{:});
mesh = p.Results.mesh;
doWarn = p.Results.doWarn;
exhaustive = p.Results.exhaustive;

if length(ROI) > 1
	isValidated = false(1,length(ROI));
	validatedROI = ROI;
	if ~isfield(validatedROI,'isValidated')
		[validatedROI.isValidated] = deal(false);
	end
	for iR = 1:length(ROI)
		[isValidated(iR), validatedROI(iR)] = c_meshROI_isValid(ROI(iR),varargin{:});
	end
	isValidated = all(isValidated);
	return;
end

if isstruct(ROI) && isfield(ROI,'isValidated') && ROI.isValidated
	 % set ROI.isValidated=true to skip future validation
	isValidated = true;
	return;
end

isValidated = false;

ROIFields = fieldnames(ROI);
requiredFields = {'Vertices','Label','Color','Seed'};
missingIndices = ~ismember(requiredFields, ROIFields);
if any(missingIndices)
	conditionalWarning(doWarn,'Missing fields: %s',c_toString(requiredFields(missingIndices)));
	return;
end

if ~isempty(ROI.Vertices)
	if ~isvector(ROI.Vertices)
		conditionalWarning(doWarn,'Unexpected Vertices dimensionality');
		return;
	end
	
	if size(ROI.Vertices,1) ~= 1
		conditionalWarning(doWarn,'Transposed Vertices');
		return;
	end
	
	if exhaustive
		if islogical(ROI.Vertices)
			conditionalWarning(doWarn,'Logical rather than numeric indices');
			return;
		end

		if ~c_isinteger(ROI.Vertices)
			conditionalWarning(doWarn,'Non-integer Vertex indices');
			return;
		end
		
		if any(ROI.Vertices<1)
			conditionalWarning(doWarn,'Invalid Vertex index');
		end
	end
	
	if ~isempty(mesh)
		if any(ROI.Vertices > size(mesh.Vertices,1))
			conditionalWarning(doWarn,'Vertex index exceeds number of vertices in mesh');
		end
	end
end

if ~isempty(ROI.Label)
	if ~ischar(ROI.Label)
		conditionalWarning(doWarn,'Label is not string');
		return;
	end
end

if ~isempty(ROI.Color)
	if ~isvector(ROI.Color) || ~isnumeric(ROI.Color) || size(ROI.Color,2)~=3
		conditionalWarning(doWarn,'Color not valid');
		return;
	end
end

if ~isempty(ROI.Seed)
	if ~isvector(ROI.Seed) || ~isnumeric(ROI.Seed) || (~isempty(mesh) && size(ROI.Seed,2) ~= size(mesh.Vertices,2))
		conditionalWarning(doWarn,'Seed not valid');
		return;
	end
end

if nargout >= 2
	validatedROI = ROI;
	validatedROI.isValidated = true;
end

isValidated = true;

end

function conditionalWarning(doWarn,varargin)
	if doWarn
		warning(varargin{:});
	end
end
	
	