function subtree = c_tree_getSubtreeAtNodeIndex(tree,nodeIndex)

	assert(iscell(tree));
	assert(isnumeric(nodeIndex));
	
	subtree = tree;
	for i=1:(length(nodeIndex))
		if nodeIndex(i)==0
			break;
		end
		subtree = subtree{nodeIndex(i)};
	end
end