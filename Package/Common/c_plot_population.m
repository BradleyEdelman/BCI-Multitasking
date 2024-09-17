function c_plot_population(varargin)
%% 
% function to provide wrapper for generating boxplots, scatter plots, or (not yet implemented) histograms

if nargin == 0
	testfn();
	return;
end

p = inputParser();
p.addRequired('data',@(x) iscell(x) || ismatrix(x)); % one column or one cell element per group
p.addParameter('labels',{},@iscell); % group labels
p.addParameter('positions',[],@isvector); % if empty, will be autoset 1:numGroups
p.addParameter('style','auto',@(x) ischar(x) || iscellstr(x)); % valid: 'auto','box','scatter','violin',{'box','scatter'},etc.
p.addParameter('axis',[],@ishandle); % if empty will use gca
p.addParameter('boxplotArgs',{},@iscell);
p.addParameter('boxplot_doPlotMean',true,@islogical);
p.addParameter('scatterArgs',{},@iscell);
p.addParameter('violinArgs',{},@iscell);
p.addParameter('offset',0,@(x) isscalar(x) || isvector(x)); % if non-scalar, length should match number of styles
p.addParameter('doLabel',true,@islogical);
p.parse(varargin{:});
s = p.Results;

if isempty(s.axis)
	s.axis = gca;
end


if iscell(s.data)
	numGroups = length(s.data);
else
	numGroups = size(s.data,2);
end

if isempty(s.positions)
	s.positions = 1:numGroups;
else
	assert(length(s.positions)==numGroups);
	if size(s.positions,1) > size(s.positions,2)
		s.positions = s.positions.';
	end
end

if isempty(s.labels)
	if numGroups > 1
		s.labels = arrayfun(@num2str,s.positions(1:numGroups),'UniformOutput',false);
	else
		s.labels {''};
	end
else
	assert(length(s.labels)==numGroups);
end


if strcmpi(s.style,'auto')
	if iscell(s.data)
		maxNumPts = max(cellfun(@length,s.data));
	else
		maxNumPts = size(s.data,1);
	end

	if maxNumPts < 10 
		% do scatter plot
		s.style = 'scatter';
	else
		s.style = 'box';
	end
end

if iscell(s.data)
	dataCatDim = c_findFirstNonsingletonDimension(s.data{1});
end


%% handle combined plot styles
if iscellstr(s.style)
	
	if length(s.style)==1
		c_plot_population(varargin{:},'style',s.style{1});
		return;
	end
	
	if numGroups > 1
		defaultOffset = min(diff(sort(s.positions)))/length(s.style)*2/3;
	else
		defaultOffset = 1 / length(s.style)*2/3;
	end
	defaultWidth = defaultOffset*0.9;
	
	for iS = 1:length(s.style)
		style = s.style{iS};
		switch(style)
			case 'scatter'
				if isempty(s.scatterArgs)
					s.scatterArgs = {'k.'}; % use black dots as markers by default if doing a combined plot
				end
			case 'box'
				tmp = c_cellToStruct(s.boxplotArgs);
				if ~isfield(tmp,'widths')
					tmp.widths = defaultWidth;
				end
				s.boxplotArgs = c_structToCell(tmp);
			case 'violin'
				tmp = c_cellToStruct(s.violinArgs);
				if ~isfield(tmp,'maxWidth')
					tmp.maxWidth = defaultWidth;
				end
				s.violinArgs = c_structToCell(tmp);
			otherwise
				warning('Style %s not customized for combined plots',style);
		end
		
		c_plot_population(varargin{:},...
			'style',style,...
			'offset',defaultOffset*(-(length(s.style)-1)/2+iS-1),...
			'scatterArgs',s.scatterArgs,...
			'boxplotArgs',s.boxplotArgs,...
			'violinArgs',s.violinArgs,...
			'doLabel',false);
		
		if iS == 1
			if ishold(s.axis);
				prevHold = 'on';
			else
				prevHold = 'off';
			end
			hold(s.axis,'on');
		end
	end
	hold(s.axis,prevHold);
	
	set(s.axis,'XTick',s.positions(1:numGroups),'XTickLabels',s.labels);
	
	return
end
			
%% single plot styles
switch(s.style)
	case 'scatter'
		%%
		%TODO: add options to 'jitter' scattered points that would be overlapping along horizontal direction
		% (to effectively generate a violin plot with a distribution of scattered points)
		
		if iscell(s.data)
			x = [];
			tmpData = [];
			for ig=1:numGroups
				tmpData = cat(dataCatDim,tmpData,s.data{ig});
				x = [x, repmat(s.positions(ig),1,length(s.data{ig}))];
			end
		else
			x = repmat(s.positions(1:numGroups),size(s.data,1),1);
			x = reshape(x,1,[]);
			tmpData = reshape(s.data,1,[]);
		end
		
		x = x + s.offset;
		
		scatter(s.axis,x,tmpData,s.scatterArgs{:});
		xlim(s.axis,extrema([x - s.offset,x])+[-1 1]*0.5);
		ylim(extrema(tmpData(:))+[-0.1 0.1]*diff(extrema(tmpData(:))));
		if numGroups > 1 && s.doLabel
			set(s.axis,'XTick',s.positions(1:numGroups),'XTickLabels',s.labels);
		else
			set(s.axis,'XTick',[],'XTickLabels',[]);
		end
		
	case 'box'
		%%
		defaultBoxplotArgs = {...
			'positions',s.positions + s.offset,...
			'notch','on'};
		if any(cellfun(@length,s.labels)>5)
			% if any label is too long, rotate all labels 90 degrees
			defaultBoxplotArgs = [defaultBoxplotArgs,...
				'labelorientation','inline'];
		end
		
		if iscell(s.data)
			% restructure data and labels into format expected by boxplot
			tmpData = [];
			tmpGrps = [];
			tmpLabels = [];
			for ig=1:numGroups
				tmpData = cat(dataCatDim,tmpData, s.data{ig});
				tmpGrps = [tmpGrps, repmat(ig,1,length(s.data{ig}))];
				tmpLabels = [tmpLabels, repmat(s.labels(ig),1,length(s.data{ig}))];
			end
		else
			tmpData = s.data;
			tmpGrps = repmat(1:numGroups,size(s.data,1),1);
			tmpGrps = reshape(tmpGrps,1,[]);
			tmpLabels = s.labels;
		end
		
		if s.boxplot_doPlotMean
			tmp = c_cellToStruct(s.boxplotArgs);
			if isfield(tmp,'widths')
				width = tmp.widths/2;
			else
				width = min(diff(sort(s.positions)))/3/2;
			end
			
			prevHold = ishold(s.axis);
			hold(s.axis,'on');
			%keyboard
			for iG = 1:numGroups
				meanVal = nanmean(tmpData(tmpGrps==iG));
				pos = s.positions(iG) + s.offset;
				line(pos+[-1 1]*width/2,[meanVal meanVal],'parent',s.axis,'color',[1 1 1]*0.5,'LineWidth',1.5);
			end
		end
		
		boxplot(s.axis,tmpData,tmpGrps,...
			'labels',tmpLabels,...
			defaultBoxplotArgs{:},...
			s.boxplotArgs{:});
		
		if s.boxplot_doPlotMean && ~prevHold
			hold(s.axis,'off');
		end
	
		if numGroups == 1 || ~s.doLabel
			set(s.axis,'XTick',[],'XTickLabels',{' '});
		end
		
	case 'violin'
		%%
		% parse violin args
		ip = inputParser();
		ip.addParameter('kernelBandwidth','globalAuto',@(x) isscalar(x) || ismember(x,{'auto','globalAuto'}));
		ip.addParameter('kernelBandwidthAutoSmoothness',1,@isscalar);
		ip.addParameter('maxWidth',NaN,@isscalar); % if NaN, will be set to min(diff(sort(positions)))*0.9
		ip.addParameter('numSmoothedPoints',100,@isscalar);
		ip.addParameter('doSymmetric',true,@islogical);
		ip.addParameter('doFill',true,@islogical);
		ip.parse(s.violinArgs{:});
		is = ip.Results;
		
		if strcmpi(is.kernelBandwidth,'globalAuto')
			% calculate bandwidth of smoothing kernel to use across all groups
			if iscell(s.data)
				groupData = s.data{1};
				dim = c_findFirstNonsingletonDimension(groupData);
				for iG = 2:numGroups
					groupData = cat(dim,groupData,s.data{iG});
				end
			else
				groupData = reshape(s.data,[],1);
			end
			[~,~,bw] = ksdensity(groupData);
			is.kernelBandwidth = bw*is.kernelBandwidthAutoSmoothness;
		end
		
		if isnan(is.maxWidth)
			if numGroups > 1
				is.maxWidth = min(diff(sort(s.positions)))*0.9;
			else
				is.maxWidth = 0.9;
			end
		end
		
		
		f = nan(is.numSmoothedPoints,numGroups);
		xi = nan(is.numSmoothedPoints,numGroups);
		for iG = 1:numGroups
			if iscell(s.data)
				tmpData = s.data{iG};
			else
				tmpData = s.data(:,iG);
			end
			ksdensityArgs = {...
				'npoints',is.numSmoothedPoints,...
			};
			if strcmpi(is.kernelBandwidth,'auto')
				if is.kernelBandwidthAutoSmoothness ~= 1
					[~,~,bw] = ksdensity(tmpData,ksdensityArgs{:});
					bw = bw * is.kernelBandwidthAutoSmoothness;
					[f(:,iG),xi(:,iG)] = ksdensity(tmpData,ksdensityArgs{:},'bandwidth',bw);
				else
					[f(:,iG),xi(:,iG)] = ksdensity(tmpData,ksdensityArgs{:});
				end
			else
				[f(:,iG),xi(:,iG)] = ksdensity(tmpData,ksdensityArgs{:},'bandwidth',is.kernelBandwidth);
			end
		end
		
		% normalize densities across groups
		minDensity = 0;
		maxDensity = max(f(:));
		
		f = f / maxDensity * is.maxWidth;
		
		if is.doSymmetric
			f = f/2;
		end
		
		% plot 
		prevHold = ishold(s.axis);
		for iG = 1:numGroups
			colorOrderIndex = s.axis.ColorOrderIndex;
			c = s.axis.ColorOrder(s.axis.ColorOrderIndex,:);
			if is.doFill
				if is.doSymmetric
					x = s.positions(iG) + s.offset + cat(1,-f(:,iG),flipud(f(:,iG)));
					y = cat(1,xi(:,iG),flipud(xi(:,iG)));
				else
					x = s.positions(iG) + s.offset + f(:,iG);
					y = xi(:,iG);
				end
				fill(x,y,c,'FaceAlpha',0.5,'parent',s.axis);
				
				if iG == 1, hold(s.axis,'on'); end
			end
			plot(s.axis,s.positions(iG) + s.offset + f(:,iG), xi(:,iG),'Color',c);
			if iG == 1, hold(s.axis,'on'); end
			if is.doSymmetric
				plot(s.axis,s.positions(iG) + s.offset- f(:,iG), xi(:,iG),'Color',c);
			end
			s.axis.ColorOrderIndex = mod(colorOrderIndex,size(s.axis.ColorOrder,1))+1;
		end
		if ~prevHold
			hold(s.axis,'off');
		end
		
		xlim(s.axis,extrema([s.positions,s.positions+s.offset])+[-1 1]*is.maxWidth*1.5);
		ylim(extrema(xi(:))+[-0.1 0.1]*diff(extrema(xi(:))));
		if numGroups > 1 && s.doLabel
			set(s.axis,'XTick',s.positions(1:numGroups),'XTickLabels',s.labels);
		else
			set(s.axis,'XTick',[],'XTickLabels',{' '});
		end
		
	case 'boxAndScatter'
		
		% legacy syntax, convert to newer syntax
		
		c_plot_population(varargin{:},'style',{'box','scatter'});
		
	otherwise
		error('Invalid plot style: %s',s.style);
end


end

function testfn()

grp1 = randn(20,1);
grp2 = randn(20,1) + 1;
grp3 = (randn(20,1)+5) .* ((rand(20,1)>0.5)-0.5)*2;

labels = {'Group 1','Group 2'};

if 1
figure('name','Population plot test 1');
data = {grp1, grp2};
c_plot_population(data,'labels',labels);

figure('name','Population plot test 2');
ha = gca;
figure('name','should be empty');
data = [grp1, grp2];
c_plot_population(data,'labels',labels,'axis',ha);

figure('name','Population plot test 3');
data = [grp1, grp2];
c_plot_population(data);

figure('name','Population plot test 4');
data = [grp1, grp2];
c_plot_population(data,'labels',labels,'style','scatter');

figure('name','Population plot test 5');
data = [grp1, grp2];
c_plot_population(data,'labels',labels,'style','boxAndScatter');

figure('name','Population plot test 6');
data = [grp1, grp3];
c_plot_population(data,'labels',labels,'style','violin');

figure('name','Population plot test 7');
data = [grp1, grp3];
c_plot_population(data,'labels',labels,'style',{'box','violin'});
end

figure('name','Population plot test 7');
data = [grp1, grp2, grp3];
c_plot_population(data,...
	'boxplot_doPlotMean',true,...
	'labels',{'Group 1','Group 2','Group 3'},'style',{'box','violin','scatter'});

end





