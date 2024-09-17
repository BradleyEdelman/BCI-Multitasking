function [smrhit,smrmiss,smrabort]=SSVEP_Congruency(ExcelFile)

%         bothmulti=zeros(1,8); onemultissvep=zeros(1,8); onemultismr=zeros(1,8); nonemulti=zeros(1,8); 
%         multissvephits=zeros(1,8); multissvepmisses=zeros(1,8);
%         conghits=zeros(1,8); congmisses=zeros(1,8); nonconghits=zeros(1,8); noncongmisses=zeros(1,8);

smrhit=struct('count',zeros(1,8),'ssvephit',zeros(1,8),'ssvepmiss',zeros(1,8),'ssvepabort',zeros(1,8),...
    'conghits',zeros(1,8),'congmisses',zeros(1,8),'nonconghits',zeros(1,8),...
    'noncongmisses',zeros(1,8));
smrabort=struct('count',zeros(1,8),'ssvephit',zeros(1,8),'ssvepmiss',zeros(1,8),'ssvepabort',zeros(1,8),...
    'conghits',zeros(1,8),'congmisses',zeros(1,8),'nonconghits',zeros(1,8),...
    'noncongmisses',zeros(1,8));
smrmiss=struct('count',zeros(1,8),'ssvephit',zeros(1,8),'ssvepmiss',zeros(1,8),'ssvepabort',zeros(1,8),...
    'conghits',zeros(1,8),'congmisses',zeros(1,8),'nonconghits',zeros(1,8),...
    'noncongmisses',zeros(1,8));
        
for k=1:8
    % Load individual sheet from excel files
    data=xlsread(ExcelFile,k);
    if isequal(size(data,2),7)
        % Identify where SMR trials start
        SMRtrial=find(~isnan(data(:,1)));
        SMRtrial(end+1)=size(data,1);

        for j=1:size(SMRtrial,1)-1

            % Result for SMR
            if isequal(data(SMRtrial(j),3),0)
                SMR{j}=0;
            elseif isequal(data(SMRtrial(j),2),data(SMRtrial(j),3))
                SMR{j}=1;
            else
                SMR{j}=-1;
            end

            % Result for SSVEP (per SMR trial)
            SSVEPidx=SMRtrial(j):SMRtrial(j+1)-1;
            SSVEP{j}=[]; Cong{j}=[];
            for l=1:size(SSVEPidx,2)

                if isequal(data(SSVEPidx(l),7),0)
                    SSVEP{j}(end+1)=0;
                elseif isequal(data(SSVEPidx(l),6),data(SSVEPidx(l),7))
                    SSVEP{j}(end+1)=1;
                else
                    SSVEP{j}(end+1)=-1;
                end

                % Congruency
                if isequal(data(SMRtrial(j),2),1)

                    if ismember(data(SSVEPidx(l),6),[1 2])
                        Cong{j}(end+1)=1;
                    else
                        Cong{j}(end+1)=0;
                    end

                elseif isequal(data(SMRtrial(j),2),2)

                    if ismember(data(SSVEPidx(l),6),[3 4])
                        Cong{j}(end+1)=1;
                    else
                        Cong{j}(end+1)=0;
                    end

                elseif isequal(data(SMRtrial(j),2),3)

                    if ismember(data(SSVEPidx(l),6),[2 4])
                        Cong{j}(end+1)=1;
                    else
                        Cong{j}(end+1)=0;
                    end

                elseif isequal(data(SMRtrial(j),2),4)

                    if ismember(data(SSVEPidx(l),6),[1 3])
                        Cong{j}(end+1)=1;
                    else
                        Cong{j}(end+1)=0;
                    end

                elseif isnan(data(SMRtrial(j),2))
                    Cong{j}=0;

                end

            end


        end
                
        for j=1:size(SMRtrial,1)-1
                    
            % True Multitask
            ssvephits=size(find(SSVEP{j}==1),2);
            ssvepmisses=size(find(SSVEP{j}==-1),2);
            ssvepaborts=size(find(SSVEP{j}==0),2);

            smrresult=SMR{j};

            % Avoid initial aborts
            if j<=5 && isequal(SMR{j},0) && isequal(size(SSVEP{j},2),4)
            else

                if isequal(smrresult,1)
                    smrhit.count(k)=smrhit.count(k)+1;

                    smrhit.ssvephit(k)=smrhit.ssvephit(k)+ssvephits;
                    smrhit.ssvepmiss(k)=smrhit.ssvepmiss(k)+ssvepmisses;
                    smrhit.ssvepabort(k)=smrhit.ssvepabort(k)+ssvepaborts;

                    % Congruency (SSVEP)
                    smrhit.conghits(k)=smrhit.conghits(k)+size(find(Cong{j}==1 & SSVEP{j}==1),2);
                    smrhit.congmisses(k)=smrhit.congmisses(k)+size(find(Cong{j}==1 & SSVEP{j}==-1),2);

                    smrhit.nonconghits(k)=smrhit.nonconghits(k)+size(find(Cong{j}==0 & SSVEP{j}==1),2);
                    smrhit.noncongmisses(k)=smrhit.noncongmisses(k)+size(find(Cong{j}==0 & SSVEP{j}==-1),2);


                elseif isequal(smrresult,0)

                    smrabort.count(k)=smrabort.count(k)+1;

                    smrabort.ssvephit(k)=smrabort.ssvephit(k)+ssvephits;
                    smrabort.ssvepmiss(k)=smrabort.ssvepmiss(k)+ssvepmisses;
                    smrabort.ssvepabort(k)=smrabort.ssvepabort(k)+ssvepaborts;

                    % Congruency (SSVEP)
                    smrabort.conghits(k)=smrabort.conghits(k)+size(find(Cong{j}==1 & SSVEP{j}==1),2);
                    smrabort.congmisses(k)=smrabort.congmisses(k)+size(find(Cong{j}==1 & SSVEP{j}==-1),2);

                    smrabort.nonconghits(k)=smrabort.nonconghits(k)+size(find(Cong{j}==0 & SSVEP{j}==1),2);
                    smrabort.noncongmisses(k)=smrabort.noncongmisses(k)+size(find(Cong{j}==0 & SSVEP{j}==-1),2);

                elseif isequal(smrresult,-1)

                    smrmiss.count(k)=smrmiss.count(k)+1;

                    smrmiss.ssvephit(k)=smrmiss.ssvephit(k)+ssvephits;
                    smrmiss.ssvepmiss(k)=smrmiss.ssvepmiss(k)+ssvepmisses;
                    smrmiss.ssvepabort(k)=smrmiss.ssvepabort(k)+ssvepaborts;

                    % Congruency (SSVEP)
                    smrmiss.conghits(k)=smrmiss.conghits(k)+size(find(Cong{j}==1 & SSVEP{j}==1),2);
                    smrmiss.congmisses(k)=smrmiss.congmisses(k)+size(find(Cong{j}==1 & SSVEP{j}==-1),2);

                    smrmiss.nonconghits(k)=smrmiss.nonconghits(k)+size(find(Cong{j}==0 & SSVEP{j}==1),2);
                    smrmiss.noncongmisses(k)=smrmiss.noncongmisses(k)+size(find(Cong{j}==0 & SSVEP{j}==-1),2);

                end


%                 % Must be a hit in both modalities
%                 if ssvephits>=1 && isequal(smrresult,1)
%                     bothmulti(k)=bothmulti(k)+1;
% 
%                     multissvephits(k)=multissvephits(k)+ssvephits;
%                     multissvepmisses(k)=multissvepmisses(k)+ssvepmisses;
% 
%                     % Congruency (SSVEP)
%                     conghits(k)=conghits(k)+size(find(Cong{j}==1 & SSVEP{j}==1),2);
%                     congmisses(k)=congmisses(k)+size(find(Cong{j}==1 & SSVEP{j}==-1),2);
% 
%                     nonconghits(k)=nonconghits(k)+size(find(Cong{j}==0 & SSVEP{j}==1),2);
%                     noncongmisses(k)=noncongmisses(k)+size(find(Cong{j}==0 & SSVEP{j}==-1),2);
% 
%                 % Hit one of the modalities
%                 elseif ssvephits>=1 && ~isequal(smrresult,1)
%                     onemultissvep(k)=onemultissvep(k)+1;
%                 elseif isequal(ssvephits,0) && isequal(smrresult,1)
%                     onemultismr(k)=onemultismr(k)+1;
%                 % Hit none of the modalities
%                 else
%                     nonemulti(k)=nonemulti(k)+1;
%                 end

            end
            
        end
        
    end
    
end