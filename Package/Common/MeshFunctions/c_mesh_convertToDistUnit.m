function mesh = c_mesh_convertToDistUnit(varargin)
p = inputParser();
p.addRequired('mesh',@c_mesh_isValid);
p.addRequired('toUnit',@(x) isscalar(x) || ischar(x));
p.addParameter('fromUnit',[],@(x) isscalar(x) || ischar(x));
p.parse(varargin{:});
s = p.Results;
mesh = s.mesh;

if isempty(s.fromUnit) 
	if ~c_isFieldAndNonEmpty(mesh,'distUnit')
		error('No starting dist unit specified');
	else
		s.fromUnit = mesh.distUnit;
	end
end

scaleFactor = c_convertValuesFromUnitToUnit(1,s.fromUnit,s.toUnit);

if scaleFactor == 1
	%do nothing
	return;
end

mesh.Vertices = mesh.Vertices*scaleFactor;

if isfield(mesh,'SphericalVertices')
	mesh.SphericalVertices = [];
end

if c_isFieldAndNonEmpty(mesh,'VertexAreas')
	mesh.VertexAreas = mesh.VertexAreas*scaleFactor^2;
end

if c_isFieldAndNonEmpty(mesh,'FaceAreas')
	mesh.FaceAreas = mesh.FaceAreas*scaleFactor^2;
end

end