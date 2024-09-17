function Brainsight = c_Brainsight_setDateTimes(Brainsight)
	% add a datetime field to each sample calculated from date and time fields parsed into matlab datetime format
	dates = c_struct_mapToArray(Brainsight.samples,{'Date'})';
	times = c_struct_mapToArray(Brainsight.samples,{'Time'})';
	
	% convert s,ms to fractional seconds
	times(:,3) = times(:,3) + times(:,4)/1e3;
	times = times(:,1:3);
	
	datetimevecs = [dates, times];
	
	% convert to matlab datetime format
	datetimes = datetime(datetimevecs);
	
	Brainsight.samples = c_array_mapToStruct(datetimes,{'datetime'},Brainsight.samples);
end