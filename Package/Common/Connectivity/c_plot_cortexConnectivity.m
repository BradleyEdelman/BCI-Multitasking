function c_plot_cortexConnectivity(varargin)

persistent PathModified;
if isempty(PathModified)
	mfilepath=fileparts(which(mfilename));
	%addpath(fullfile(mfilepath,'../MeshFunctions'));
	addpath(fullfile(mfilepath,'../ThirdParty/FromBrainstorm/anatomy'));
	addpath(fullfile(mfilepath,'../ThirdParty/FromEConnectome/tools/DTFVisualization/'));
	PathModified = true;
end

if nargin==0
	testfn();
	return;
end

p = inputParser();
p.addParameter('connectivityMatrix',@(x) isnumeric(x) && size(x,1)==size(x,2));
p.addParameter('mesh_cortex','',@(x) ischar(x) || isstruct(x)); % path to load, or raw struct
p.addParameter('meshScalar',1,@isscalar); % for converting distance units
p.addParameter('ROIs',[],@isstruct);
p.addParameter('ROIAlpha',0.5,@isscalar);
p.addParameter('ConnectivityLimits',0.9,@isvector); % Threshold on which connections to show. 
% If a scalar, defines a relative minimum. If a tuple, defines absolute min/max limits.
p.addParameter('ArrowSizeLimits',[0.5 2],@isvector);
p.addParameter('freqIndex',1,@isscalar);
p.addParameter('timeIndex',1,@isscalar);
p.addParameter('doInflate',true,@islogical);
p.addParameter('doShadeSulci',true,@islogical);
p.addParameter('doCenter',true,@islogical);
p.addParameter('doDoublePlot',false,@islogical);
p.parse(varargin{:});
s = p.Results;

%% import / parse cortex mesh


mesh_cortex = s.mesh_cortex;

% load from file if needed
if ischar(mesh_cortex)
	assert(exist(mesh_cortex,'file')>0);
	mesh_cortex = load(mesh_cortex);
	tmpFields = fieldnames(mesh_cortex);
	if length(tmpFields)==1
		% original mesh was saved as a struct, pull out
		mesh_cortex = mesh_cortex.(tmpFields{1}); 
	end % else we assume separate variables representing mesh are already in variable
end
	
% convert from different struct formats to common format
if ~c_isFieldAndNonEmpty(mesh_cortex,'Vertices') || ~c_isFieldAndNonEmpty(mesh_cortex,'Faces');
	keyboard %TODO
end

% assume format is now mesh.Vertices, mesh.Faces

mesh_cortex.Vertices = mesh_cortex.Vertices * s.meshScalar;

%keyboard

if s.doShadeSulci
	if ~c_isFieldAndNonEmpty(mesh_cortex,'SulciMap')
		mesh_cortex.VertConn = tess_vertconn(mesh_cortex.Vertices,mesh_cortex.Faces);
		mesh_cortex.SulciMap = tess_sulcimap(mesh_cortex);
	end
else
	if isfield(mesh_cortex,'SulciMap')
		mesh_cortex = rmfield(mesh_cortex,'SulciMap');
	end
end

if s.doInflate
	mesh_cortex = c_smooth_surf(mesh_cortex);
end

if s.doCenter
	bounds = extrema(mesh_cortex.Vertices,[],1);
	origCenter = mean(bounds,2)';
	mesh_cortex.Vertices = bsxfun(@minus,mesh_cortex.Vertices,origCenter);
end

%keyboard

%% ROIs
% format: 
%	ROIs.nodeIndices: 1xN cell array, with each element being a variable length vector of indices into cortex mesh nodes describing ROI membership
%	ROIs.centers: (optional) Nx3 coordinates of ROI centers (auto-calculated if not specified)
%	ROIs.centerIndices (optional), as above, but indices into mesh nodes instead of coordinates
%	ROIs.labels: (optional) cell array of strings
%	ROIs.colors: (optional) Nx3 one color for each ROI

ROIs = s.ROIs;

ROIs = c_convertROIs(ROIs,'toFormat','eConnectome');

numROIs = length(ROIs.nodeIndices);

if c_isFieldAndNonEmpty(ROIs,'centers') && ~s.doInflate
	ROIs.centers = ROIs.centers * s.meshScalar;
	if s.doCenter
		ROIs.centers = bsxfun(@minus,ROIs.centers,origCenter);
	end
else
	% calculate ROI centers
	if c_isFieldAndNonEmpty(ROIs,'centerIndices') && 0
		ROIs.centers = mesh_cortex.Vertices(ROIs.centerIndices,:);
	else
		%calculate center as center of 'mass' on inflated surface, then project back
		tmp = c_smooth_surf(mesh_cortex);
		for r=1:length(ROIs.nodeIndices)
			tmpCenter = mean(tmp.Vertices(ROIs.nodeIndices{r},:),1);
			candidateCenters = tmp.Vertices(ROIs.nodeIndices{r},:);
			[~,centerCandidateIndex] = min(c_norm(bsxfun(@minus,tmpCenter,candidateCenters),2,2));
			ROIs.centers(r,:) = mesh_cortex.Vertices(ROIs.nodeIndices{r}(centerCandidateIndex),:);
		end
	end
end
assert(length(ROIs.centers)==numROIs);

if ~c_isFieldAndNonEmpty(ROIs,'labels')
	for r=1:numROIs
		ROIs.labels{r} = num2str(r);
	end
end
assert(length(ROIs.labels)==numROIs);

%% Plotting



% cortex mesh and ROIs

% set up node colors by ROI
defaultColor = [0.7 0.7 0.9];

if ~c_isFieldAndNonEmpty(ROIs,'colors')
	ROIs.colors = ROIColors(numROIs);
end

roiCData = repmat(defaultColor,size(mesh_cortex.Vertices,1),1);
roiAlpha = zeros(size(mesh_cortex.Vertices,1),1);
% assume that no one node belongs to more than 1 ROI
for r=1:numROIs
	roiNodeIndices = ROIs.nodeIndices{r};
	roiCData(roiNodeIndices,:) = repmat(ROIs.colors(r,:),length(roiNodeIndices),1);
	roiAlpha(roiNodeIndices) = s.ROIAlpha;
end

% connectivity
if isscalar(s.ConnectivityLimits)
	s.ConnectivityLimits = [max(s.connectivityMatrix(:))*s.ConnectivityLimits inf];
end

regeneratePlot(mesh_cortex, ROIs, roiCData, roiAlpha, s, s.ConnectivityLimits(1),s.ConnectivityLimits(2));
view([-72, 40]);
h = uicontrol(...
	'style','slider',...
	'units','pixel',...
	'position',[20 20 300 20],...
	'Value',s.ConnectivityLimits(1),...
	'Min',0,...
	'Max',max(s.connectivityMatrix(:)));
set(h,'tag','c_NonPrinting');
addlistener(h,'ContinuousValueChange',@(hObject, event) regeneratePlot(...
	mesh_cortex, ROIs, roiCData,roiAlpha,s,get(hObject,'Value'),s.ConnectivityLimits(2)));
set(gcf,'toolbar','figure');

end

function regeneratePlot(mesh_cortex, ROIs, roiCData, roiAlpha, s, lowerLim, upperLim)

	cla
	
	plotSurfaceArgs = {...
		'edgeColor','none',...
		'faceAlpha',1,...
		'view',[],...
		'renderingMode',1};
	
	if c_isFieldAndNonEmpty(mesh_cortex,'SulciMap')
		c_plotSurface(mesh_cortex.Vertices,mesh_cortex.Faces,...
			'nodeData',bsxfun(@times,(4-mesh_cortex.SulciMap)/4,[0.7 0.7 0.9]),...
			plotSurfaceArgs{:});
	else
		c_plotSurface(mesh_cortex.Vertices,mesh_cortex.Faces,...
			plotSurfaceArgs{:});
	end
	
	c_plotSurface(mesh_cortex.Vertices,mesh_cortex.Faces,...
		'edgeColor','none',...
		'nodeData',roiCData,...
		'faceAlpha',roiAlpha,...
		'view',[],...
		'faceoffsetbias',-0.0001,...
		'renderingMode',2);

	opt = struct(...
		'Channels','all',...
		'ValLim',[lowerLim upperLim],...
		'ArSzLt',s.ArrowSizeLimits/1e3);

	drawdtfconngraph(s.connectivityMatrix(:,:,s.freqIndex,s.timeIndex), ROIs.centers, opt);
	
	drawnow

end


function cmap = ROIColors(num)
	%adapted from eConnectome 
	if num < 1
		return;
	end
	basecolors = zeros(7,3);
	basecolors(1,:) = [0.0, 0.5, 0.0];
	basecolors(2,:) = [0, 0.6, 0.9];
	basecolors(3,:) = [0.6, 0.42, 0.56];
	basecolors(4,:) = [0.7, 0.5, 0.2];
	basecolors(5,:) = [0.5, 0.5, 1.0];
	basecolors(6,:) = [0.1, 0.9, 0.1];
	basecolors(7,:) = [0.9, 0.4, 0.2];

	% repeat the 7 colors
	cmap = zeros(num,3);
	for i = 1:num
		j = mod(i,7);
		if j == 0
			j = 7;
		end
		cmap(i,:) = basecolors(j,:);
	end
end

function testfn()
	c_plot_cortexConnectivityFromBrainstorm();
end