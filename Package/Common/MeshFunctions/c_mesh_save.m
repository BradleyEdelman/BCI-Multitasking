function c_mesh_save(varargin)
p = inputParser();
p.addRequired('output',@ischar); % file to save to
p.addRequired('mesh',@c_mesh_isValid); % mesh to save 
p.parse(varargin{:});
s = p.Results;

c_AddIso2MeshToPath();

[pathstr, filename, extension] = fileparts(s.output);

mesh = s.mesh;

switch(extension)
	case '.off'
		c_AddIso2MeshToPath();
		saveoff(mesh.Vertices,mesh.Faces,s.output);
		
	case '.stl'
		if c_isFieldAndNonEmpty(mesh,'FaceNormals')
			warning('Not saving face normals');
		end
		savestl(mesh.Vertices,mesh.Faces,s.output);
		
	case '.mat'
		c_save(s.output,'-struct','mesh');
		
	otherwise
		error('Unsupported output extension');
end
end
