function newCellArray = c_insertIntoCellArray(cellArray,toInsert,index)
	newCellArray = [cellArray(1:(index-1)), toInsert, cellArray(index:end)];
end