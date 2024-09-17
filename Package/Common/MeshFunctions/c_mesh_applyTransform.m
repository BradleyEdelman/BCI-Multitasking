function mesh = c_mesh_applyTransform(varargin)
p = inputParser();
p.addRequired('mesh',@isstruct);
p.addParameter('quaternion',[],@ismatrix);
p.parse(varargin{:});
s = p.Results;

mesh = s.mesh;

mesh.Vertices = c_pts_applyQuaternionTransformation(mesh.Vertices,s.quaternion);

%TODO: also update face orientations if present, etc.

end