function h = c_plot_imageIn3D(varargin)
if nargin == 0, testfn(); return; end;

p = inputParser();
p.addParameter('CData',[],@(x) isnumeric(x));
p.addParameter('xyz',{},@(x) iscell(x) && length(x)==3 && all(cellfun(@isvector,x)));
p.addParameter('parent',gca,@ishandle);
p.addParameter('patchArgs',{},@iscell);
p.addParameter('transformation',[],@ismatrix); % specify a quaternion transformation for rotation/offset
p.parse(varargin{:});
s = p.Results;

mfilepath=fileparts(which(mfilename));
addpath(fullfile(mfilepath,'./MeshFunctions'));

numDim = 3;
datSize = ones(1,numDim);
datSize(1:ndims(s.CData)) = size(s.CData);

for i=1:numDim
	if isempty(s.xyz) || length(s.xyz)<i || isempty(s.xyz{i})
		s.xyz{i} = 1:datSize(i);
	else
		assert(length(s.xyz{i})==datSize(i));
	end
end

rxdim = find(datSize~=1,1,'first');
assert(~isempty(rxdim));
rydim = find(datSize~=1,1,'last');
assert(~isempty(rydim) && rxdim~=rydim);
rzdim = find(datSize==1,1,'first');
assert(~isempty(rzdim));

% extend coordinates by one interval in positive direction to specify values by face rather than node
for j=1:numDim
	if j==rzdim
		% do not modify rz
		continue;
	end
	dj = median(diff(s.xyz{j}));
	s.xyz{j} = [s.xyz{j} s.xyz{j}(end) + dj];
	% offset by half interval to center coordinates in face center
	s.xyz{j} = s.xyz{j}- dj/2;
end

rx = s.xyz{rxdim};
ry = s.xyz{rydim};
rz = s.xyz{rzdim};
rData = permute(s.CData,[rxdim, rydim, rzdim]);



nodes = nan(length(rx)*length(ry),3);
nodeIndices = nan(length(rx),length(ry));
count = 0;
for ix = 1:length(rx)
	for iy = 1:length(ry)
		count = count + 1;
		coord = [rx(ix), ry(iy)];
		coord = [coord(1:rzdim-1) rz coord(rzdim:end)];
		nodes(count,:) = coord;
		nodeIndices(ix,iy) = count;
	end
end

faces = nan((length(rx)-1)*(length(ry)-1),4);
faceData = nan(size(faces,1),1);
count = 0;
for ix = 1:length(rx)-1
	for iy = 1:length(ry)-1
		count = count + 1;
		faces(count,:) = [nodeIndices(ix,iy), nodeIndices(ix+1,iy), nodeIndices(ix+1,iy+1),nodeIndices(ix,iy+1)];
		faceData(count) = rData(ix,iy);
	end
end

if ~isempty(s.transformation)
	nodes = c_pts_applyQuaternionTransformation(nodes,s.transformation);
end

h = patch('Faces',faces,'Vertices',nodes,...
	'FaceVertexCData',faceData,...
	'FaceColor','flat',...
	'EdgeColor','none',...
	'Parent',s.parent,...
	s.patchArgs{:});

end


function testfn()
dat = rand(100,150,200);

figure;
c_plot_imageIn3D(...
	'CData',dat(:,:,1));
view(3);

end

