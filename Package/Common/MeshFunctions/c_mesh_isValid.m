function [isValid, validatedMesh] = c_mesh_isValid(mesh,varargin)
	p = inputParser();
	p.addRequired('mesh');
	p.addParameter('doWarn',true,@islogical);
	p.addParameter('exhaustive',false,@islogical); % whether to do more computationally expensive checks
	p.addParameter('hasSphericalVertices',[],@islogical);
	p.parse(mesh,varargin{:});
	s = p.Results;
	
	if isstruct(mesh) && isfield(mesh,'isValidated') && mesh.isValidated
		 % set mesh.isValidated=true to skip future validation
		isValid = true;
		return;
	end
	
	isValid = false;
	
	meshFields = fieldnames(mesh);
	requiredFields = {'Vertices','Faces'};
	missingIndices = ~ismember(requiredFields, meshFields);
	if any(missingIndices)
		conditionalWarning(s.doWarn,'Missing fields: %s',c_toString(requiredFields(missingIndices)));
		return;
	end
	
	if ~isempty(mesh.Vertices)
		if ~ismatrix(mesh.Vertices)
			conditionalWarning(s.doWarn,'Unexpected Vertices type/dimensionality');
			return;
		end
		
		if ~ismember(size(mesh.Vertices,2),[2 3])
			conditionalWarning(s.doWarn,'Unexpected Vertices size');
			return;
		end
	end
	
	if ~isempty(mesh.Faces)
		if ~ismatrix(mesh.Faces)
			conditionalWarning(s.doWarn,'Unexpected Faces type/dimensionality');
			return;
		end
		
		if ~ismember(size(mesh.Faces,2),[3 4])
			conditionalWarning(s.doWarn,'Unexpected Faces size');
			return;
		end	
		
		if s.exhaustive
			if ~c_isinteger(mesh.Faces)
				conditionalWarning(s.doWarn,'Non-integer indices in Faces');
				return;
			end
			
			extremeVals = extrema(mesh.Faces(:));
			if extremeVals(1) < 1 || extremeVals(2) > size(mesh.Vertices,1)
				conditionalWarning(s.doWarn,'Invalid index in Faces');
				return;
			end
		end
	end
	
	if isfield(mesh,'VertConn') && ~isempty(mesh.VertConn)
		if ~ismatrix(mesh.VertConn) || size(mesh.VertConn,1) ~= size(mesh.Vertices,1) || size(mesh.VertConn,2) ~= size(mesh.Vertices,1)
			conditionalWarning(s.doWarn,'Invalid VertConn size');
			return;
		end
		
		if ~islogical(mesh.VertConn)
			conditionalWarning(s.doWarn,'VertConn not logical');
			return;
		end
	end
	
	if ~isempty(s.hasSphericalVertices)
		if s.hasSphericalVertices && ~c_isFieldAndNonEmpty(mesh,'SphericalVertices')
			conditionalWarning(s.doWarn,'Does not have spherical vertices');
			return;
		elseif ~s.hasSphericalVertices && c_isFieldAndNonEmpty(mesh,'SphericalVertices')
			conditionalWarning(s.doWarn,'Has spherical vertices');
			return;
		elseif s.hasSphericalVertices
			if size(mesh.SphericalVertices,2)~=3
				conditionalWarning(s.doWarn,'Incorrect size of SphericalVertices');
				return;
			end
		end
	end
	
	if nargout >= 2
		validatedMesh = mesh;
		validatedMesh.isValidated = true;
	end
	
	isValid = true;
end

function conditionalWarning(doWarn,varargin)
	if doWarn
		warning(varargin{:});
	end
end
	
	
	
	