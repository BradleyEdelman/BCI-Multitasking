function subtree = c_tree_getSubtreeAtNode(tree,nodeName)

	assert(iscell(tree));
	assert(ischar(nodeName));
	
	index = c_tree_getIndexOfNode(tree,nodeName);
	
	subtree = tree;
	for i=1:(length(index)-1)
		subtree = subtree{index(i)};
	end
end