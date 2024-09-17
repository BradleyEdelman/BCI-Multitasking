function LogLabelAxes(axh, axn, doSetCallbacks)

if nargin < 3
	doSetCallbacks = true;
end
if nargin < 2
	axn = [1,2];
end

if islogical(axn)
	axn = find(axn); % convert to indices
end

persistent warningSuppressed
if isempty(warningSuppressed)
	warning('off','MATLAB:warn_r14_stucture_assignment');
	warningSuppressed = true;
end

%set(axh,'UserData','[isLogLabeled]');
axh.UserData.isLogLabeled = true;
axh.UserData.logLabelAxes = axn;

SubLogLabelAxes(axh,axn);

if doSetCallbacks
	if ~strcmp('colorbar',axh.Type)
		set(zoom(axh),'ActionPostCallback',@(x,y) SupLogLabelAxes(axh,axn)); 
		set(pan(getParentFigure(axh)),'ActionPostCallback',@(x,y) SupLogLabelAxes(axh,axn) );
		set(rotate3d(axh),'ActionPostCallback',@(x,y) SupLogLabelAxes(axh,axn)); 
	else
		axh.addlistener('Hit', @(x,y) SupLogLabelAxes(axh,axn));
	end
 	set(getParentFigure(axh),'ResizeFcn',@(x,y) SupLogLabelAxes(axh,axn));
	
	
	
else
	if ismember(1,axn)
		axh.XTickMode = 'manual';
	end
	if ismember(2,axn)
		axh.YTickMode = 'manual';
	end
	if ismember(3,axn)
		axh.ZTickMode = 'manual';
	end
end

end

function SupLogLabelAxes(axh,axn)
	persistent inCallback
	%inCallback = [];
    if ~isempty(inCallback),  return;  end
    inCallback = 1;  % prevent callback re-entry (not 100% fool-proof)
 
	figh = getParentFigure(axh);
	axes = [findobj(figh,'type','axes'); findobj(figh,'type','ColorBar')];
	for i=1:length(axes)
		%if ~isempty(strfind(axes(i).UserData,'[isLogLabeled]'))
		if isfield(axes(i).UserData,'isLogLabeled') && axes(i).UserData.isLogLabeled
			SubLogLabelAxes(axes(i),axes(i).UserData.logLabelAxes)
		end
	end
	
	inCallback = [];
end

function SubLogLabelAxes(axh,axn)

if ismember(1,axn) && ~strcmp(axh.Type,'colorbar')
	%axh.XTickLabel = round(10.^axh.XTick,3,'significant'); 
	axh.XTickLabel = round(ilogForPlot(axh.XTick),3,'significant'); 
end
if ismember(2,axn) && ~strcmp(axh.Type,'colorbar')
	%axh.YTickLabel = round(10.^axh.YTick,3,'significant');
	axh.YTickLabel = round(ilogForPlot(axh.YTick),3,'significant');
end
if ismember(3,axn) && ~strcmp(axh.Type,'colorbar')
	%axh.ZTickLabel = round(10.^axh.ZTick,3,'significant');
	axh.ZTickLabel = round(ilogForPlot(axh.ZTick),3,'significant');
end
if ismember(4,axn) && strcmp(axh.Type,'colorbar')
	% colorbar
	set(axh,'YTickLabel',round(ilogForPlot(get(axh,'YTick')),3,'significant'));
end

end

function fig = getParentFigure(fig)
% from http://www.mathworks.com/matlabcentral/newsreader/view_thread/31402
% if the object is a figure or figure descendent, return the
% figure. Otherwise return [].
while ~isempty(fig) & ~strcmp('figure', get(fig,'type'))
  fig = get(fig,'parent');
end
end