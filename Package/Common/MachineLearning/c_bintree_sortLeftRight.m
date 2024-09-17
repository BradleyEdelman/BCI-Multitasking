function [tree, sortVal] = c_bintree_sortLeftRight(tree,sortField)
	% swap left and right nodes of a tree so that the left value is always less than or equal to right
	if tree.isLeaf
		sortVal = tree.value.(sortField);
		return;
	end

	% sort sub trees
	[tree.left, leftSortVal] = c_bintree_sortLeftRight(tree.left,sortField);
	[tree.right, rightSortVal] = c_bintree_sortLeftRight(tree.right,sortField);
	
	if isfield(tree.value,sortField)
		% return current sort value instead of children sort values
		sortVal = tree.value.(sortField);
	else
		% current node does not have value defined, so pull from children
		sortVal = mean(leftSortVal,rightSortVal);
	end
	
	% sort this node
	if leftSortVal > rightSortVal
		tmp = tree.left;
		tree.left = tree.right;
		tree.right = tmp;
	end
end