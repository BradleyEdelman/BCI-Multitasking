function out = c_GUI_visualize3DMatrix(varargin)

%% add dependencies
mfilepath=fileparts(which(mfilename));
addpath(fullfile(mfilepath,'./ThirdParty/uisplitpane'));
addpath(fullfile(mfilepath,'./MeshFunctions'));
%% parse input

if nargin == 0
	testfn();
	return;
end
p = inputParser();
p.addParameter('data',[],@(x) isnumeric(x) || islogical(x));
p.addParameter('axisData',{},@iscell); % one element for each dimension
p.addParameter('labels',{},@iscell); % one string for each dimension
p.addParameter('projectionFn',@mean,@(x) isa(x,'function_handle'));
p.addParameter('ndim',3,@isscalar); % any value other than 3 not yet supported
p.addParameter('sliceAxis',3,@isscalar);
p.addParameter('sliceIndex',1,@isscalar);
p.addParameter('doForceSymmetricColor',false,@islogical);
p.addParameter('doLinkColorbars',true,@islogical);
p.addParameter('clim',[nan nan],@isnumeric);
p.addParameter('title','Visualize 3D matrix',@ischar);
p.addParameter('colormap','',@ischar);
p.addParameter('doForceSingleton',false,@islogical);
p.addParameter('doPlotProjections',true,@islogical);
p.addParameter('doPlotSliceIn3D',false,@islogical);
p.addParameter('dataAspectRatio',[],@isvector); % set to [1 1 1] to plot isotropic data
p.addParameter('transformation',[],@ismatrix); % quaternion representing global spatial transformation for 3D plot
p.parse(varargin{:});
s = p.Results;

if isempty(s.axisData)
	for i=1:s.ndim
		s.axisData{i} = 1:size(s.data,i);
	end
end

if isempty(s.labels)
	for i=1:s.ndim
		s.labels{i} = sprintf('Dimension %d', i);
	end
end

for i=1:s.ndim
	if abs(diff(extrema(abs(diff(s.axisData{i}))))) > 0.01*abs(median(diff(s.axisData{i})))
		error('Plotting code requires that axis data be uniformly spaced');
	end
end

%% initialization

out = struct();

if s.doForceSingleton
	global h_vis3dfig;
	if ~isempty(h_vis3dfig) && ishandle(h_vis3dfig)
		close(h_vis3dfig);
	end
	h_vis3dfig = figure('name',s.title,...
		'SizeChangedFcn',@(h,e) callback_GUI_setPositions());
	guiH.fig = h_vis3dfig;
else
	guiH.fig = figure('name',s.title,...
		'SizeChangedFcn',@(h,e) callback_GUI_setPositions());
end

resizeFigureWindow(guiH.fig,[0 0 1 1]);

[guiH.buttonPanel, guiH.nonButtonPanel, ~] = uisplitpane(guiH.fig,'Orientation','horizontal','DividerLocation',0.1);
[guiH.mainAxPanel, guiH.secondaryAxPanel, ~] = uisplitpane(guiH.nonButtonPanel,'Orientation','horizontal');

% settings
sy = 0;
dy = 0.05;
guiH.settings_sliceAxisBG = uibuttongroup(...
	'Parent',guiH.buttonPanel,...
	'Title','Slice axis',...
	'Position',[0 sy 1 0.05*s.ndim],... %TODO: set position in callback_GUI_setPositions
	'SelectionChangedFcn',@callback_GUI_sliceAxisBGChanged);
sy = sy + guiH.settings_sliceAxisBG.Position(4) + dy;

for i=1:s.ndim
	guiH.settings_sliceAxisBtns(i) = uicontrol(guiH.settings_sliceAxisBG,...
		'Style','radiobutton',...
		'Units','normalized',...
		'Position',[0.1 1-1/(s.ndim+1)*i 1 1/(s.ndim+1)],...
		'String',s.labels{i},...
		'HandleVisibility','off');
	if i==s.sliceAxis
		guiH.settings_sliceAxisBG.SelectedObject = guiH.settings_sliceAxisBtns(i);
	end
end

guiH.settings_sliceIndexSldr = uicontrol(guiH.buttonPanel,...
	'Style','slider',...
	'Units','normalized',...
	'Position',[0 sy 1 0.03],...
	'Min',min(s.axisData{s.sliceAxis}),...
	'Max',max(s.axisData{s.sliceAxis}),...
	'Value',s.axisData{s.sliceAxis}(s.sliceIndex),...
	'String','Slice');
sy = sy + guiH.settings_sliceIndexSldr.Position(4);
addlistener(guiH.settings_sliceIndexSldr,'Value','PostSet',@(~,~) callback_GUI_sliceSlider(...
		guiH.settings_sliceIndexSldr.Value));
guiH.settings_sliceIndexTxt = uicontrol(guiH.buttonPanel,...
	'Style','text',...
	'Units','normalized',...
	'Position',[0 sy 1 0.03],...
	'String','Slice');
sy = sy + guiH.settings_sliceIndexTxt.Position(4) + dy;

guiH.settings_plotPanel = uipanel(guiH.buttonPanel,...
	'Title','Plotting options',...
	'Units','normalized',...
	'Position',[0 sy 1 0.05*3]);
sy = sy + guiH.settings_plotPanel.Position(4) + dy;
guiH.settings_doPlotProjections = uicontrol(guiH.settings_plotPanel,...
	'Style','checkbox',...
	'Units','normalized',...
	'Position',[0 0 1 0.2],...
	'Value',s.doPlotProjections,...
	'String','Do plot projections',...
	'Callback',@(h,e) callback_GUI_updateSettingAndRedraw('doPlotProjections',h.Value==h.Max));
guiH.settings_doPlotSliceIn3D = uicontrol(guiH.settings_plotPanel,...
	'Style','checkbox',...
	'Units','normalized',...
	'Position',[0 0.2 1 0.2],...
	'Value',s.doPlotSliceIn3D,...
	'String','Do plot slice in 3D',...
	'Callback',@(h,e) callback_GUI_updateSettingAndRedraw('doPlotSliceIn3D',h.Value==h.Max));


guiH.settings_colorPanel = uipanel(guiH.buttonPanel,...
	'Title','Color axes',...
	'Units','normalized',...
	'Position',[0 sy 1 0.05*3]);
sy = sy + guiH.settings_colorPanel.Position(4) + dy;
guiH.settings_colorDoSymmetric = uicontrol(guiH.settings_colorPanel,...
	'Style','checkbox',...
	'Units','normalized',...
	'Position',[0 0 1 0.2],...
	'Value',s.doForceSymmetricColor,...
	'String','Symmetric colorbars',...
	'Callback',@(h,e) callback_GUI_doSymmetricChanged(h.Value==h.Max));
guiH.settings_colorDoSymmetric = uicontrol(guiH.settings_colorPanel,...
	'Style','checkbox',...
	'Units','normalized',...
	'Position',[0 0.2 1 0.2],...
	'Value',s.doLinkColorbars,...
	'String','Link colorbars',...
	'Callback',@(h,e) callback_GUI_doLinkColorbarsChanged(h.Value==h.Max));

% axes
guiH.mainAx = axes(...
	'Parent',guiH.mainAxPanel,...
	'ButtonDownFcn',@callback_GUI_axisClick);

out.MainAxH = guiH.mainAx;

guiH.sliceAx = axes(...
	'Parent',guiH.secondaryAxPanel);

out.SliceAxH = guiH.sliceAx;


callback_GUI_redraw();


% Sx = []; Sy = []; Sz = [];
% %Sx = linspace(min(s.x),max(s.x),10);
% Sz = s.z;
% 
% %contourslice(guiH.mainAx, s.y,s.x,s.z,s.data,Sx,Sy,Sz);
% pcolor(guiH.mainAx,s.y,s.x,s.data(:,:,1));
% 
% h=slice(guiH.mainAx,s.y,s.x,s.z,s.data,Sx,Sy,5.5);
% 
% h.EdgeColor = 'none';

	%% Callbacks
	
	function callback_GUI_updateSettingAndRedraw(settingName,newValue)
		s.(settingName) = newValue;
		callback_GUI_redraw();
	end
	
	function callback_GUI_redraw()
		
		if c_isFieldAndNonEmpty(guiH,'projections')
			delete(guiH.projections);
			guiH.projections = [];
		end
		
		if s.doPlotProjections
			for i=1:s.ndim
				projectedData{i} = s.projectionFn(s.data,i);

				xyz = s.axisData;
				if i==3
					xyz{i} = min(xyz{i});
				else
					xyz{i} = max(xyz{i});
				end

				guiH.projections(i) = c_plot_imageIn3D(...
					'CData',projectedData{i},...
					'xyz',xyz,...
					'parent',guiH.mainAx,...
					'transformation',s.transformation,...
					'PatchArgs',{'ButtonDownFcn',@callback_GUI_axisClick});

				hold(guiH.mainAx,'on');
				axis(guiH.mainAx,'tight');
			end
		end
		
		callback_GUI_redrawSliceIn3D();
		
		s.mainAxLims = cellfun(@extrema,s.axisData,'UniformOutput',false);
		s.mainAxLimsTrans = s.mainAxLims;
		if ~isempty(s.transformation)
			tmp = [-1 -1 -1; -1 -1 1; -1 1 -1; 1 -1 -1; -1 1 1; 1 1 -1; 1 -1 1; 1 1 1];
			mult = [];
			offset = [];
			for i=1:s.ndim
				mult(i) = diff(s.mainAxLims{i})/2;
				offset(i) = mean(s.mainAxLims{i});
			end
			tmp = bsxfun(@plus,bsxfun(@times,tmp,mult),offset);
			tmp= c_pts_applyQuaternionTransformation(tmp,s.transformation);
			for i=1:s.ndim
				s.mainAxLimsTrans{i} = extrema(tmp(:,i));
			end
		end
		
		if ~isempty(s.dataAspectRatio)
			if all(s.dataAspectRatio~=s.dataAspectRatio(1)) && ~isempty(s.transformation)
				error('Nonisotropic aspect ratio and spatial transformations not currently supported together');
			end
			set(guiH.mainAx,'DataAspectRatio',s.dataAspectRatio,'DataAspectRatioMode','manual');
		end
		
		xlim(s.mainAxLimsTrans{1});
		ylim(s.mainAxLimsTrans{2});
		zlim(s.mainAxLimsTrans{3});
		
		view(guiH.mainAx,3);
		xlabel(guiH.mainAx,s.labels{1});
		ylabel(guiH.mainAx,s.labels{2});
		zlabel(guiH.mainAx,s.labels{3});

		hc = colorbar(guiH.mainAx,'location','NorthOutside');
		% if s.doForceSymmetricColor
		% 	guiH.mainAx.CLim = [-1 1]*max(abs(extrema(guiH.mainAx.CLim)));
		% end
		if length(s.labels) > s.ndim
			% last label is color axis
			xlabel(hc,s.labels{s.ndim+1});
		end

		callback_GUI_sliceAxisBGChanged([],struct('NewValue',struct('String',s.labels{s.sliceAxis})));

		callback_GUI_sliceIndexChanged();

		callback_GUI_refreshColorbars();
	end

	function callback_GUI_redrawSliceIn3D()
		if c_isFieldAndNonEmpty(guiH,'sliceIn3D')
			delete(guiH.sliceIn3D);
			guiH.sliceIn3D = [];
		end
		
		if s.doPlotSliceIn3D
			permuteOrder = 1:s.ndim;
			permuteOrder(s.sliceAxis) = 1;
			permuteOrder(1) = s.sliceAxis;
			sliceData = permute(s.data,permuteOrder);
			sliceData = sliceData(s.sliceIndex,:,:); % does not extend to higher dimensions;
			sliceData = ipermute(sliceData,permuteOrder);
			xyz = s.axisData;
			xyz{s.sliceAxis} = s.axisData{s.sliceAxis}(s.sliceIndex);
			guiH.sliceIn3D = c_plot_imageIn3D(...
				'CData',sliceData,...
				'xyz',xyz,...
				'transformation',s.transformation,...
				'parent',guiH.mainAx);
			
			if c_isFieldAndNonEmpty(s,'mainAxLimsTrans')
				xlim(s.mainAxLimsTrans{1});
				ylim(s.mainAxLimsTrans{2});
				zlim(s.mainAxLimsTrans{3});
			end
		end
	end
		

	function callback_GUI_sliceAxisBGChanged(~,e)
		newSliceAxisIndex = find(ismember(s.labels,e.NewValue.String),1,'first');
		assert(~isempty(newSliceAxisIndex));
% 		c_saySingle('New slice axis: %s',s.labels{newSliceAxisIndex});
		s.sliceAxis = newSliceAxisIndex;
		cla(guiH.sliceAx);
		dims = [s.sliceAxis,1:s.sliceAxis-1,s.sliceAxis+1:s.ndim];
		xlabel(guiH.sliceAx,s.labels{dims(2)});
		ylabel(guiH.sliceAx,s.labels{dims(3)});
		%TODO: call function to refresh slice plot as needed
		
		guiH.settings_sliceIndexSldr.Min = min(s.axisData{s.sliceAxis});
		guiH.settings_sliceIndexSldr.Max = max(s.axisData{s.sliceAxis});
		guiH.settings_sliceIndexSldr.SliderStep = [1 1]*abs(median(diff(s.axisData{s.sliceAxis})))/diff(extrema(s.axisData{s.sliceAxis}));

		if s.sliceIndex > length(s.axisData{s.sliceAxis})
			s.sliceIndex = 1;
		end
		
		guiH.settings_sliceIndexSldr.Value = s.axisData{s.sliceAxis}(s.sliceIndex);
		
		callback_GUI_sliceIndexChanged();
	end

	function callback_GUI_setPositions()
	%TODO
	end

	function callback_GUI_axisClick(h,e)
		if strcmpi(h.Type,'patch')
			% find index of closest point in slice axis
			[~,s.sliceIndex] = min(abs(e.IntersectionPoint(s.sliceAxis) - s.axisData{s.sliceAxis}));
			
			if ~isempty(s.transformation)
				warning('Spatial transformations not yet incorporated into axis click code'); %TODO
			end
			
			pts = num2cell(e.IntersectionPoint);
% 			c_saySingle('Clicked on patch at (%.3g,%.3g,%.3g), %s=%.3g',pts{:},s.labels{s.sliceAxis},s.axisData{s.sliceAxis}(s.sliceIndex));
			
% 			ha = h.Parent;
% 			scatter3(ha,pts{:});
			
			callback_GUI_sliceIndexChanged();
		else
			c_saySingle('Clicked outside of patch');
		end
	end

	function callback_GUI_sliceSlider(val)
		% find index of closest point in slice axis
		[~,s.sliceIndex] = min(abs(val - s.axisData{s.sliceAxis}));
		
		callback_GUI_sliceIndexChanged();
	end

	function callback_GUI_doSymmetricChanged(doSymmetric)
		s.doForceSymmetricColor = doSymmetric;
		callback_GUI_refreshColorbars();
	end

	function callback_GUI_doLinkColorbarsChanged(doLink)
		s.doLinkColorbars = doLink;
		callback_GUI_refreshColorbars();
	end

	function callback_GUI_refreshColorbars()
		if s.doLinkColorbars
			guiH.sliceAx.CLim = guiH.mainAx.CLim;
		else
			for h = [guiH.mainAx, guiH.sliceAx]
				caxis(h,'auto');
			end
		end
		
		if any(~isnan(s.clim))
			for h = [guiH.mainAx, guiH.sliceAx]
				clim = h.CLim;
				for k=1:2
					if ~isnan(s.clim(k))
						clim(k)=s.clim(k);
					end
				end
				caxis(h,clim);
			end
		end
		
		if s.doForceSymmetricColor
			for h = [guiH.mainAx, guiH.sliceAx]
				h.CLim = [-1 1]*max(abs(extrema(h.CLim)));
			end
		else
			if s.doLinkColorbars
				guiH.sliceAx.CLim = guiH.mainAx.CLim;
			end
		end
		
		if ~isempty(s.colormap)
			if ischar(s.colormap)
				colormap(s.colormap);
			end
		end
	end

		


	function callback_GUI_sliceIndexChanged()
		
		mytime = cputime;
		accessTimeQueue('append',mytime);
		pause(0.1);
		maxTime = accessTimeQueue('remove',mytime);
		if mytime ~= maxTime
			% this call is old, do not continue with it
			return;
		end
			
		dims = [s.sliceAxis,1:s.sliceAxis-1,s.sliceAxis+1:s.ndim];
		tmpData = permute(s.data,dims);
		sliceSize = size(tmpData); sliceSize = sliceSize(2:end);
		sliceData = tmpData(s.sliceIndex,:);
		sliceData = reshape(sliceData,sliceSize);
		
		callback_GUI_redrawSliceIn3D();
		
		% update slice plot
		h = imagesc(s.axisData{dims(2)},s.axisData{dims(3)},sliceData.','parent',guiH.sliceAx);
		if ~isempty(s.dataAspectRatio)
			set(guiH.sliceAx,'DataAspectRatio',s.dataAspectRatio(dims([2 3 1])),'DataAspectRatioMode','manual');
		end
		xlim(guiH.sliceAx,s.mainAxLims{dims(2)});
		ylim(guiH.sliceAx,s.mainAxLims{dims(3)});
		set(guiH.sliceAx,'YDir','normal');
		%h.EdgeColor = 'none';
		xlabel(guiH.sliceAx,s.labels{dims(2)});
		ylabel(guiH.sliceAx,s.labels{dims(3)});
		title(guiH.sliceAx,sprintf('%s = %.3g',s.labels{s.sliceAxis},s.axisData{s.sliceAxis}(s.sliceIndex)));
		
		% match color scale of slice to color scale of main plot
		hcslice = colorbar(guiH.sliceAx,'location','NorthOutside');
		if s.doLinkColorbars
			guiH.sliceAx.CLim = guiH.mainAx.CLim;
		elseif s.doForceSymmetricColor
			guiH.sliceAx.CLim = [-1 1]*max(abs(extrema(guiH.sliceAx.CLim)));
		end
		if length(s.labels) > s.ndim
			% last label is color axis
			xlabel(hcslice,s.labels{s.ndim+1});
		end
		
		% update lines on 3d plot
		persistent hSliceLines;
		if ~isempty(hSliceLines)
			delete(hSliceLines);
		end
		hSliceLines = [];
		z = s.axisData{s.sliceAxis}(s.sliceIndex);
% 		x = extrema(s.axisData{dims(2)});
% 		y = extrema(s.axisData{dims(3)});
		x = s.mainAxLims{dims(2)};
		y = s.mainAxLims{dims(3)};
		coords = {[x(1) x(1) x(2) x(2) x(1)],[y(1) y(2) y(2) y(1) y(1)],[1 1 1 1 1]*z};
		idims = [1:s.sliceAxis-1 s.ndim s.sliceAxis:s.ndim-1];
		coords = coords(idims);
		if ~isempty(s.transformation)
			tmp = cell2mat(coords.').';
			tmp = c_pts_applyQuaternionTransformation(tmp,s.transformation);
			for i=1:s.ndim
				coords{i} = tmp(:,i);
			end
		end
		hSliceLines = line(coords{:},'Parent',guiH.mainAx,'Color',[0 0 0]);
		
		
		
	end
		
	
end

function [maxTime, numTimes] = accessTimeQueue(action,time)
	persistent times;
	switch(action)
		case 'append'
			times = [times, time];
		case 'remove'
			i = find(times==time,1,'first');
			times(i) = [];
		otherwise
			error('invalid');
	end
	maxTime = max(times);
	numTimes = length(times);
end



%%
function testfn()
	if 0 
		pathToLoad = './tmp.mat';
		varsToLoad = {'mat','x','y','z','xLabel','yLabel','zLabel'};

		input = load(pathToLoad,varsToLoad{:});
		
		%TODO: tmp, delete
		if isscalar(input.z)
			input.z = 1:input.z;
		end
		input.mat = abs(input.mat);
		input.mat = pow2db(input.mat);

		tmp = input.y;
		input.y = input.x;
		input.x = tmp;
		input.mat = permute(input.mat,[2 1 3]);
		tmp = input.yLabel;
		input.yLabel = input.xLabel;
		input.xLabel = tmp;

		c_GUI_visualize3DMatrix(...
			'data',input.mat,...
			'axisData',{input.x,input.y,input.z},...
			'labels',{input.xLabel,input.yLabel,input.zLabel}...
			);
	else
		dat = rand(50,100,150);
		c_GUI_visualize3DMatrix(...
			'data',dat);
	end
	
	
	
end



