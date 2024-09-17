function buffer=bci_ESI_UpdateBuffer(buffer,updatecount)

count=buffer.trialcount;
data=buffer.trial;
dim=updatecount(1);
targetididx=updatecount(2:end);
                                            
% FIND MINIMUM OF DIMENSION TRIAL COUNT
mincount=min(count(dim,:)-1);
if isequal(mincount,0)
    mincount=1;
end


% KEEP EQUAL TRIALS/CYCLES FROM EACH TARGET IN BUFFER
if ~isempty(data)
    dimbuffer=horzcat(data{dim,1}{1:mincount},data{dim,2}{1:mincount});
else
    dimbuffer=[];
end                                        

% Occurs at the end of a trial/cycle
count(dim,(targetididx==1))=count(dim,(targetididx==1))+1;

buffer.trialcount=count;
buffer.mintrial(dim)=mincount;
buffer.totaltrial{dim}=dimbuffer;
