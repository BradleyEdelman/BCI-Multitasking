function [Best,BestMD]=bci_ESI_MahalExtract(X1,X2,numchan,numtopfeat)

if ~isequal(rem(size(X1,2),numchan),0) || ~isequal(rem(size(X2,2),numchan),0)
    fprintf(2,'\nFEATURE VECTOR SIZE NOT A MULTIPLE OF THE # OF CHANNELS\n');
elseif ~isequal(size(X1,2),size(X2,2))
    fprintf(2,'\nFEATURE VECTOR SIZES INCONSISTENT\n');
else
    
    n1=size(X1,1);
    n2=size(X2,1);
    Best=zeros(1,size(X1,2)+1);
    
    for i=2:numtopfeat+1
        
        % Look for next best feature to add
        for j=1:size(X1,2)
            
            if ismember(j,Best)
                MD(j)=0;
            else
                
                mu1=mean(X1(:,[Best(find(Best~=0)) j]),1);
                mu2=mean(X2(:,[Best(find(Best~=0)) j]),1);
                
                X1center=X1(:,[Best(find(Best~=0)) j]);
                X2center=X2(:,[Best(find(Best~=0)) j]);
                
                X1cov=cov(X1center);
                X2cov=cov(X2center);
                
                PC=(n1*X1cov+n2*X2cov)/(n1+n2-2);
                
                M=(mu2-mu1)/PC*(mu2-mu1)';
                MD(j)=abs(sqrt(M));
                
            end
        end
        
        BestMD(i)=max(MD);
        best=find(MD==BestMD(i));
        Best(i)=best(1);
    
%         Besttmp=Best;
%         Besttmp(Besttmp==0)=[]
%         % Go back through all previously added features
%         for j=size(Besttmp,2):-1:1
%             removeidx=j;
        
    end
end

Best=Best(2:end);
Best(Best==0)=[];
Best=Best(:);

BestMD=BestMD(2:end);
BestMD=BestMD(:);
    
    