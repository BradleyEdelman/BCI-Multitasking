function c_convertMesh(varargin)
mfilepath=fileparts(which(mfilename));
p = inputParser();
p.addParameter('input','',@ischar); %file to load from %TODO: also allow direct matrix input
p.addParameter('output','',@ischar); %file to save to %TODO: return raw matrix if this is empty
p.addParameter('iso2meshPath',fullfile(mfilepath,'../ThirdParty/iso2mesh'),@ischar);
p.addParameter('transformMat',[],@ismatrix);
p.parse(varargin{:});
s = p.Results;

if nargin==0,testfn(); return; end;

if ~exist(s.iso2meshPath,'dir')
	error('Iso2mesh library not at specified path: %s',s.iso2meshPath);
end
addpath(s.iso2meshPath);

% assume input is a filename
assert(exist(s.input,'file')>0);

[pathstr, filename, extension] = fileparts(s.input);

mesh = c_mesh_load(s.input);
node = mesh.Vertices;
elem = mesh.Faces;

if ~isempty(s.transformMat)
	figure; c_plotSurface(node,elem); axis on
	
% 	newNode = ((s.transformMat)*cat(2,node,ones(size(node,1),1))')';
	newNode = (pinv(s.transformMat)*cat(2,node,ones(size(node,1),1))')';
	newNode = newNode(:,1:3);
	
	node = newNode;
	
	figure; c_plotSurface(newNode,elem); axis on;	
end



[pathstr, filename, extension] = fileparts(s.output);

switch(extension)
	case '.stl'
		savestl(node,elem,s.output);
	otherwise
		error('Unsupported output extension');
end



end


function testfn()
	input = 'D:\TMSData\TMS-Working\MeshingAndFEM\S01-template\Surfaces\gm_fixed3.off';
	output = 'D:\TMSData\TMS-Working\MeshingAndFEM\S01-template\Surfaces\gm_fixed3_invtransform.stl';
	fsTransformMat = [];
% 	fsTransformMat = [...
% 		0 0 1 -119.5;
% 		-1 0 0 158;
% 		0 1 0 -127;
% 		0 0 0 1];
	fsTransformMat = [...
		1 0 0 -0.5;
		0 1 0 -30;
		0 0 1 5;
		0 0 0 1];
	c_convertMesh('input',input,'output',output,'transformMat',fsTransformMat);
end