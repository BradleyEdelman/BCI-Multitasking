function mesh = c_mesh_calculateSphericalVertices(varargin)
% project a mesh outward to a spherical surface, preserving a one-to-one correspondence between vertices
p = inputParser();
p.addRequired('mesh',@c_mesh_isValid);
p.addParameter('SphericalCenter',[],@isvector); % if empty, will be automatically calculated
p.parse(varargin{:});
s = p.Results;
mesh = s.mesh;

if isempty(s.SphericalCenter)
	mesh.SphericalCenter = mean(mesh.Vertices,1);
else
	mesh.SphericalCenter = s.SphericalCenter;
end

centeredVertices = bsxfun(@minus,mesh.Vertices,mesh.SphericalCenter);

% based on https://en.wikipedia.org/wiki/Spherical_coordinate_system

% calculate radii
mesh.SphericalVertices(:,1) = c_norm(centeredVertices,2,2);

% calculate inclination angles, in degrees
mesh.SphericalVertices(:,2) = acosd(centeredVertices(:,3)./mesh.SphericalVertices(:,1));

% calculate azimuthal angle, in degrees
mesh.SphericalVertices(:,3) = atan2d(centeredVertices(:,2), centeredVertices(:,1));

end