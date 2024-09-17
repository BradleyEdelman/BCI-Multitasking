function c_plot_setDataCursorForDatetimeX(figHandle)
	if nargin < 1
		figHandle = gcf;
	end
	dcmObj = datacursormode(figHandle);
	dcmObj.UpdateFcn = @updateFcn;
end

function str = updateFcn(~,eventObj)
	pos = eventObj.Position;
	dt = datetime(eventObj.Position(1),'convertFrom','datenum');
	str = sprintf('%s\n%s',c_toString(dt),c_toString(pos(2)));
end