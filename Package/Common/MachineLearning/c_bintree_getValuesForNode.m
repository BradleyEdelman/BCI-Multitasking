function [nodeValues,leafValues] = c_bintree_getValuesForNode(tree,IDField,IDValue)
	if isfield(tree.value,IDField) && tree.value.(IDField) == IDValue
		nodeValues = tree.value;
		if isfield(tree,'leafValues')
			leafValues = tree.leafValues;
		else
			leafValues = [];
		end
	else
		if tree.isLeaf
			nodeValues = []; % no match found
			leafValues = [];
		else
			[nodeValues, leafValues] = c_bintree_getValuesForNode(tree.left,IDField,IDValue);
			if isempty(nodeValues) % no match found
				[nodeValues, leafValues] = c_bintree_getValuesForNode(tree.right,IDField,IDValue);
			end
		end
	end
end