function [c, poppedItem] = c_cell_pop(c)
	poppedItem = c{end};
	c = c(1:end-1);
end