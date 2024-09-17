function multitaskOrder()
    tasks = {'SMR', 'SSVEP', 'BOTH'};
    
    rng(double(rem(tic,1e6))); % seed random number generator with time
    
    order = randperm(3);
    
    for i = 1:3
        display(tasks{order(i)});
    end
end