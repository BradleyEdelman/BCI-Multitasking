function a = c_extractNumericalValuesFromStructArray(structArray,field)

	s = size(structArray);
	
	a = reshape(cell2mat({structArray.(field)}),s);
end