function outmat=nonanmean(varargin)

tmp=cat(3,varargin{:});
tmp2=zeros(size(tmp,1),size(tmp,2));
count=zeros(1,4);
for i=1:size(tmp,3)
    for j=1:4
        if sum(isnan(tmp(j,:,i)),2)~=9
            tmp2(j,:)=tmp2(j,:)+tmp(j,:,i);
            count(j)=count(j)+1;
        end
    end
end
outmat=tmp2./repmat(count',[1,9]);
