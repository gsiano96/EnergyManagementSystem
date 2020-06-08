function y = obtainMonthConditions(probabilities, periodVect, monthLen)
    a = probabilities(1);
    b = probabilities(2);
    c = probabilities(3);
    d = probabilities(4);
    
    for i=1:monthLen
        expa = a*mvnrnd(a,var(periodVect,1));
        expb = b*mvnrnd(b,var(periodVect,1));
        expc = c*mvnrnd(c,var(periodVect,1));
        expd = d*mvnrnd(d,var(periodVect,1));
        [maxim,index] = max([expa,expb,expc,expd]);
        conditions(i) = index;
    end
    if(monthLen<31)
        conditions(monthLen:31)=0;
    end
    
    y = conditions';
end