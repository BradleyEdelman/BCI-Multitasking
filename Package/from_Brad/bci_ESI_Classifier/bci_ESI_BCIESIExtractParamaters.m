function [handles,trialstruct]=bci_ESI_BCIESIExtractParamaters(handles,trainfiles)


numfiles=size(trainfiles,1);

length=zeros(1,numfiles);
chanidxinclude=cell(1,numfiles);
vertidxinclude=cell(1,numfiles);
clusteridxinclude=cell(1,numfiles);
numfreq=zeros(1,numfiles);

% LOAD THE SELECTED DAT FILE
parcellation=get(handles.parcellation,'value');
for i=1:numfiles
    
    load(trainfiles{i});
    
    length(i)=size(Dat,2);
    chanidxinclude{i}=Dat(1).chanidxinclude;
    vertidxinclude{i}=Dat(1).vertidxinclude;
    if ismember(parcellation,[2,3])
        clusteridxinclude{i}=Dat(1).clusteridxinclude;
    end
    
    numfreq(i)=Dat(1).numfreq;
    freqvect{i}=Dat(1).freqvect;
    winpnts(i)=Dat(1).winpnts;
    
end
trialstruct.length=sum(length,2);

combinations=combnk(1:numfiles,2);
for i=1:size(combinations,1)
    
    if ~isequal(chanidxinclude{combinations(i,1)},chanidxinclude{combinations(i,2)})
        error('INCONSISTENT EEG CHANNELS AMONG TRAINING FILES');
    end
    
end
trialstruct.chanidxinclude=chanidxinclude{1};


for i=1:size(combinations,1)
    
    if ~isequal(vertidxinclude{combinations(i,1)},vertidxinclude{combinations(i,2)})
        error('INCONSISTENT SOURCE DIPOLES AMONG TRAINING FILES');
    end
    
end
trialstruct.vertidxinclude=vertidxinclude{1};


for i=1:size(combinations,1)
    
    if ~isequal(clusteridxinclude{combinations(i,1)},clusteridxinclude{combinations(i,2)})
        error('INCONSISTENT SOURCE CLUSTERS AMONG TRAINING FILES');
    end
    
end
trialstruct.clusteridxinclude=clusteridxinclude{1};


for i=1:size(combinations,1)
    
    if ~isequal(numfreq(combinations(i,1)),numfreq(combinations(i,2)))
        error('INCONSISTENT NUMBER OF FREQUENCIES AMONG TRAINING FILES');
    end
    
end
trialstruct.numfreq=numfreq(1);

for i=1:size(combinations,1)
    
    if ~isequal(freqvect{combinations(i,1)},freqvect{combinations(i,2)})
        error('INCONSISTENT FREQUENCIY VECTORS AMONG TRAINING FILES');
    end
    
end
trialstruct.freqvect=freqvect{1};

for i=1:size(combinations,1)
    
    if ~isequal(winpnts(combinations(i,1)),winpnts(combinations(i,2)))
        error('INCONSISTENT WINDOWED DATA POINTS AMONG TRAINING FILES');
    end
    
end
trialstruct.winpnts=winpnts(1);


    

