function [handles,trialstruct]=bci_ESI_BCIESIExtractParamaters2(handles,trainfiles)


numfiles=size(trainfiles,1);

chanidxinclude=cell(1,numfiles);
vertidxinclude=cell(1,numfiles);
clusteridxinclude=cell(1,numfiles);
baselength=zeros(1,numfiles);
triallength=zeros(1,numfiles);
numwin=zeros(1,numfiles);
numtrial=zeros(1,numfiles);
numfreq=zeros(1,numfiles);
freqvect=cell(1,numfiles);

% LOAD THE SELECTED DAT FILE
for i=1:numfiles
    
    load(trainfiles{i});
    
    chanidxinclude{i}=dat.param.chanidxinclude;
    vertidxinclude{i}=dat.param.vertidxinclude;
	clusteridxinclude{i}=dat.param.clusteridxinclude;
    
    baselength(i)=dat.param.baselength;
    triallength(i)=dat.param.triallength;
    numwin(i)=dat.param.numwin;
    numtrial(i)=dat.param.numtrial;
    
    numfreq(i)=dat.param.numfreq;
    freqvect{i}=dat.param.freqvect;
    
end
trialstruct.numwin=sum(numwin,2);
trialstruct.numtrial=sum(numtrial,2);

combinations=combnk(1:numfiles,2);

% CHANIDXINCLUDE
for i=1:size(combinations,1)
    
    if ~isequal(chanidxinclude{combinations(i,1)},chanidxinclude{combinations(i,2)})
        error('INCONSISTENT EEG CHANNELS AMONG TRAINING FILES');
    end
    
end
trialstruct.chanidxinclude=chanidxinclude{1};

% VERTIDXINCLUDE
for i=1:size(combinations,1)
    
    if ~isequal(vertidxinclude{combinations(i,1)},vertidxinclude{combinations(i,2)})
        error('INCONSISTENT SOURCE DIPOLES AMONG TRAINING FILES');
    end
    
end
trialstruct.vertidxinclude=vertidxinclude{1};

% CLUSTERIDXINCLUDE
for i=1:size(combinations,1)
    
    if ~isequal(clusteridxinclude{combinations(i,1)},clusteridxinclude{combinations(i,2)})
        error('INCONSISTENT SOURCE CLUSTERS AMONG TRAINING FILES');
    end
    
end
trialstruct.clusteridxinclude=clusteridxinclude{1};

% BASELENGTH
for i=1:size(combinations,1)
    
    if ~isequal(baselength(combinations(i,1)),baselength(combinations(i,2)))
        error('INCONSISTENT BASELINE LENGTH AMONG TRAINING FILES');
    end
    
end
trialstruct.baselength=baselength(1);

% TRIALLENGTH
for i=1:size(combinations,1)
    
    if ~isequal(triallength(combinations(i,1)),triallength(combinations(i,2)))
        error('INCONSISTENT TRIAL LENGTH AMONG TRAINING FILES');
    end
    
end
trialstruct.triallength=triallength(1);

% FREQVECT
for i=1:size(combinations,1)
    
    if ~isequal(freqvect{combinations(i,1)},freqvect{combinations(i,2)})
        error('INCONSISTENT FREQUENCIY VECTORS AMONG TRAINING FILES');
    end
    
end
trialstruct.freqvect=freqvect{1};

% NUMFREQ
for i=1:size(combinations,1)
    
    if ~isequal(numfreq(combinations(i,1)),numfreq(combinations(i,2)))
        error('INCONSISTENT NUMBER OF FREQUENCIES AMONG TRAINING FILES');
    end
    
end
trialstruct.numfreq=numfreq(1);


% for i=1:size(combinations,1)
%     
%     if ~isequal(winpnts(combinations(i,1)),winpnts(combinations(i,2)))
%         error('INCONSISTENT WINDOWED DATA POINTS AMONG TRAINING FILES');
%     end
%     
% end
% trialstruct.winpnts=winpnts(1);


    

