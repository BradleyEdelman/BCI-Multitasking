function buffer=bci_ESI_StoreBuffer(buffer,storage)

warehouse=buffer.(storage.buffertype);
count=buffer.(strcat(storage.buffertype,'count'));

if strcmp(storage.buffertype,'trial')
    
    if count(storage.dim,storage.targidx)>storage.limit
        % SHIFT DATA VECTORS WITHIN TRIAL BUFFER TO KEEP MOST RECENT
        warehouse{storage.dim,storage.targidx}=circshift(warehouse{storage.dim,storage.targidx},[0 -1]);
        count(storage.dim,storage.targidx)=storage.limit;
        warehouse{storage.dim,storage.targidx}(end)=cell(1);
    end
    warehouse{storage.dim,storage.targidx}{count(storage.dim,storage.targidx)}(:,storage.win)=storage.data;

elseif strcmp(storage.buffertype,'window')
    
    if size(warehouse{storage.dim,storage.targidx},2)>=storage.limit
        % SHIFT WINDOWS WITHIN WINDOW BUFFER TO KEEP MOST RECENT
        warehouse{storage.dim,storage.targidx}=circshift(warehouse{storage.dim,storage.targidx},[0 -1]);
        warehouse{storage.dim,storage.targidx}(:,end)=[];
    end
    warehouse{storage.dim,storage.targidx}=[warehouse{storage.dim,storage.targidx} storage.data];
    
end

buffer.(storage.buffertype)=warehouse;
buffer.(strcat(storage.buffertype,'count'))=count;