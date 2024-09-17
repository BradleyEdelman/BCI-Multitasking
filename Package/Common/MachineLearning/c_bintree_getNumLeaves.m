function numLeaves = c_bintree_getNumLeaves(tree)
	if tree.isLeaf
		numLeaves = 1;
	else
		numLeaves = c_bintree_getNumLeaves(tree.left) + c_bintree_getNumLeaves(tree.right);
	end
end