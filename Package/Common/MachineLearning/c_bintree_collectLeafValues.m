function tree = c_bintree_collectLeafValues(tree,fields)
	if ~iscell(fields)
		fields = {fields};
	end
	
	if tree.isLeaf,
		tree.leafValues = struct();
		for iF = 1:length(fields)
			tree.leafValues.(fields{iF}) = {tree.value.(fields{iF})};
		end
	else
		tree.left = c_bintree_collectLeafValues(tree.left,fields);
		tree.right = c_bintree_collectLeafValues(tree.right,fields);
		for iF = 1:length(fields)
			tree.leafValues.(fields{iF}) = [tree.left.leafValues.(fields{iF}), tree.right.leafValues.(fields{iF})];
		end
	end
end