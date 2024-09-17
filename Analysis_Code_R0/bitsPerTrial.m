function [ITR] = bitsPerTrial(numtargets,accuracy)
ITR=log2(numtargets)+accuracy*log2(accuracy)+(1-accuracy)*log2((1-accuracy)/(numtargets-1));