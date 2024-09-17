function LogScaleAxes(axh, axn)

if nargin < 2
	axn = [1,2];
end

if ismember(1,axn)
	axh.XScale = 'log';
end
if ismember(2,axn)
	axh.YScale = 'log';
end
if ismember(3,axn)
	axh.ZScale = 'log';
end

end