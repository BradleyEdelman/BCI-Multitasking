function c_plot_setEqualAxes(varargin)
p = inputParser();
p.addParameter('axisHandles',[],@(x) all(ishandle(x(:))));
p.addParameter('xlim',[nan, nan],@isvector);
p.addParameter('ylim',[nan, nan],@isvector);
p.addParameter('zlim',[nan, nan],@isvector);
p.addParameter('clim',[nan, nan],@isvector);
p.addParameter('axesToSet','xyzc',@ischar);
p.addParameter('doForceSymmetric',false,@islogical);
p.addParameter('doForceEqualAspect',false,@islogical);
p.addParameter('doLink',true,@islogical);
p.parse(varargin{:});
s = p.Results;

if isempty(s.axisHandles)
	% no handles given, assume we should grab all axes from current figure
	s.axisHandles = gcf;
else
	s.axisHandles = s.axisHandles(:); % reshape any higher dimensions into vector
end

axisHandles = [];
for i=1:length(s.axisHandles)
	if isgraphics(s.axisHandles(i),'Figure')
		% figure handle given, assume we should grab all axes from the figure
		childHandles = findobj(s.axisHandles(i),'Type','axes');
		if ismember('c',s.axesToSet) && ~ismember({'axesToSet'},p.UsingDefaults)
			keyboard %TODO: current code only extracts normal axes from a figure, not colorbars. Add code to get colorbars
		end
		axisHandles = [axisHandles; childHandles];
	elseif isgraphics(s.axisHandles(i),'axes')
		axisHandles = [axisHandles;s.axisHandles(i)];
	else
		error('invalid handle');
	end
end
s.axisHandles = axisHandles;

if s.doForceEqualAspect
	set(s.axisHandles,'DataAspectRatio',[1 1 1]);
end

for j=1:length(s.axesToSet)
	limfield = [lower(s.axesToSet(j)) 'lim'];
	if length(s.doForceSymmetric)==1 % one doForceSymmetric value for all axes
		doForceSymmetric = s.doForceSymmetric;
	else % one doForceSymmetric value for each axis
		assert(length(s.doForceSymmetric)==length(s.axesToSet)); 
		doForceSymmetric = s.doForceSymmetric(j);
	end
	lim = s.(limfield);
	setEqualAxis(s.axisHandles,s.axesToSet(j),lim,doForceSymmetric,s.doLink);
end

end


function setEqualAxis(axisHandles,axisToSet,lim,doSymmetry, doLink)
	assert(length(axisToSet)==1 && ischar(axisToSet));
	fieldOfInterest = [upper(axisToSet) 'Lim'];
	if isnan(lim(1)) % need to autodetect min
		minVal = inf;
		for i=1:length(axisHandles)
			newVal = paren(get(axisHandles(i),fieldOfInterest),1);
			minVal = min(newVal,minVal);
		end
		lim(1) = minVal;
	end
	if isnan(lim(2)) % need to autodetect max
		maxVal = -inf;
		for i=1:length(axisHandles)
			newVal = paren(get(axisHandles(i),fieldOfInterest),2);
			maxVal = max(newVal,maxVal);
		end
		lim(2) = maxVal;
	end
	
	if doSymmetry
		lim = [-1 1]*max(abs(lim));
	end
	
	% set limits
	for i=1:length(axisHandles)
		set(axisHandles(i),fieldOfInterest,lim);
	end
	
	if doLink
		hlink = linkprop(axisHandles,fieldOfInterest);
		ud = get(axisHandles(1),'UserData');
		if iscell(ud) && ~isempty(ud)
			ud{end+1} = ['Link' fieldOfInterest 'Handle'];
			ud{end+1} = hlink;
		else
			ud.(['Link' fieldOfInterest 'Handle']) = hlink;
		end
		set(axisHandles(1),'UserData',ud);
	end
end