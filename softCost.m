function cost = SoftCost(assignments,shifts, horizon, covers, onrequestsTrans, offrequestsTrans)
 
%%Constraint 9
penalty9 = 0;
rows = size(shifts,1);
for r = 0:horizon-1 %days
    for s = 1:rows %shifts
        t = sum(assignments(:,r+1,s),1) - covers(rows*r+s,end-2);
        penalty9 = penalty9 + max(0,t) + (-100)*min(t,0);
    end
end

%%Constraint 10 (Shift on requests)
penalty10 = 0;
for r = 1:size(onrequestsTrans,1)
    if assignments(onrequestsTrans(r,1),onrequestsTrans(r,2)+1, onrequestsTrans(r,3))==0
        penalty10 = penalty10 + onrequestsTrans(r,4);
    end
end

%%Constraint 11 (Shift off requests)
penalty11 = 0;
for r = 1:size(offrequestsTrans,1)
    if assignments(offrequestsTrans(r,1),offrequestsTrans(r,2)+1, offrequestsTrans(r,3))==1
        penalty11 = penalty11 + offrequestsTrans(r,4);
    end
end

cost = penalty9 + penalty10 + penalty11;
end