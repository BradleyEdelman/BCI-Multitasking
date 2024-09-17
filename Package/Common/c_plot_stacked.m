function handles = c_plot_stacked(varargin)

if nargin == 0, testfn(); return; end;

p = inputParser();
p.addRequired('x',@isvector);
p.addRequired('y',@ismatrix);
p.addParameter('existingHandles',[],@(x) all(ishandle(x)));
p.addParameter('xlabel','',@ischar);
p.addParameter('ylabel','',@ischar);
p.addParameter('ylabels',{},@iscell);
p.addParameter('plotArgs_common',{},@iscell);
p.addParameter('plotArgs_per_names',{},@iscell);
p.addParameter('plotArgs_per_values',{},@iscell);
p.addParameter('plotFn',@plot,@(x) isa(x,'function_handle'));
p.addParameter('warnLimit',100,@isscalar); % warn and pause if number of plots will exceed this limit
p.addParameter('doShowYTicks',false,@islogical);
p.parse(varargin{:});

x = p.Results.x;
y = p.Results.y;

numPts = length(x);
secondDim = find(size(y)==numPts,1,'first');
if isempty(secondDim)
	error('No matching dimension in y');
end
y = shiftdim(y,secondDim-1);
y = reshape(y,size(y,1),[]);
y = y.';

numPlots = size(y,1);
if numPlots > p.Results.warnLimit
	warning('Will plot %d plots, continue?',numPlots);
	pause
end

assert(length(p.Results.plotArgs_per_names)==length(p.Results.plotArgs_per_values));

if ~isempty(p.Results.existingHandles)
	assert(length(p.Results.existingHandles)==numPlots);
end

prevWarnState = warning('off','MATLAB:hg:ColorSpec_None');

% in normalized units
left = 0;
width = 1-2*left;
top = 0.025;
bottom = 0.05;
totalHeight = 1-top-bottom;
singleHeight = totalHeight/numPlots;

set(gcf,'units','normalized');

ylabels = p.Results.ylabels;
if isempty(ylabels);
	for i=1:numPlots
		ylabels{i} = num2str(i);
	end
end

if ~isempty(p.Results.existingHandles)
	handles = p.Results.existingHandles;
else
	handles = nan(1,numPlots);
end
for i=1:numPlots
	singleBottom = 1-top-singleHeight*i;
	
	if isempty(p.Results.existingHandles)
		handles(i) = c_subplot('position',[left singleBottom width singleHeight],'Number',i);
	else
		axes(handles(i));
	end
	
	args = p.Results.plotArgs_common;
	if ~isempty(p.Results.plotArgs_per_names)
		for j=1:length(p.Results.plotArgs_per_names)
			args = [args, p.Results.plotArgs_per_names{j},p.Results.plotArgs_per_values{j}{i}];
		end
	end
	
	p.Results.plotFn(x,y(i,:),args{:});
	
	set(handles(i),'box','off');
	outerPos = get(handles(i),'OuterPosition');
	innerPos = get(handles(i),'Position');
	newPos = [innerPos(1) outerPos(2) innerPos(3) outerPos(4)];
	set(handles(i),'Position',newPos);
	set(get(handles(i),'Children'),'Clipping','off');
	%axis off
	h = ylabel(ylabels{i},'Rotation',0,'HorizontalAlignment','right','VerticalAlignment','middle');
	if i~=numPlots
		% disable other plot components?
		set(handles(i),'XTickLabel',{});
		set(handles(i),'XTick',[]);
		set(handles(i),'XColor',[0.5 0.5 0.5]);
	else
		xlabel(p.Results.xlabel);
	end
end

if ~p.Results.doShowYTicks
	set(handles,'YTickLabel',{});
	set(handles,'YTick',[]);
end

set(handles,'color','none');

linkaxes(flipud(handles));
ylims = extrema(y(:));
if any(isnan(ylims))
	ylim([0 1]);
else
	ylim(extrema(y(:)));
end

if ~isempty(p.Results.ylabel)
	rightBound = max(paren(get(handles(1),'Position'),1)-...
		paren(get(handles(1),'TightInset'),1),0);
	hp = uipanel(...
		'Units','normalized',...
		...%'BackgroundColor','none',...
		'BorderType','none',...
		'Position',[rightBound/8, 0, rightBound*3/4,1]);
	ha = axes('Parent',hp,'Visible','off');
	ht = text('Parent',ha, ...
		'Units','normalized',...
		'HorizontalAlignment','center',...
		'Position',[0.5 0.5],...
		'String',p.Results.ylabel, ...
		'Rotation',90);
end

axes(handles(end));

warning(prevWarnState.state,'MATLAB:hg:ColorSpec_None');

end


function testfn()
N = 1000;
M = 20;

x = linspace(0,10,1000);

y = cumsum(randn(M,N),2);

figure;
c_plot_stacked(x,y,...
	'xlabel','time',...
	'ylabel','magnitude');




end
