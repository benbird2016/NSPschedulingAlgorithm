function cost = costFunction_quick(emp, assignments, staff, shifts, shiftsTrans, horizon, sectiondaysoff, covers, onrequestsTrans, offrequestsTrans)

%%MODDED
%%Constraint 1 (Maximum Shift Assignments per day)
penalty1 = 0;
for r = 1:size(assignments,2)
    R = sum(assignments(emp,r,:),3) - ones(size(assignments,1),1);
    R(R<0) = 0;
    R(R>1) = 1;
    penalty1 = penalty1 + sum(R,1);
end

%%MODDED
%%Constraint 2 (Shift Rotation)
penalty2 = 0;
i=1;
j=1;
for day = 1:(horizon-1)
    i=1;
    while i < length(shifts(:,1))+1
        for j = 3:length(shifts(1,:))
            if shiftsTrans(i,j) ~= 0
                if assignments(emp, day, shiftsTrans(i,1)) == 1 && assignments(emp, day+1, shiftsTrans(i,j)) == 1
                    penalty2 = penalty2 + 1;
                end
            end
        end
        i=i+1;
    end
end

%%MODDED
%%Constraint 3 (maximum number of shifts)
rows = size(shifts,1);
penalty3 = 0;
for s = 1:rows
    Q = sum(assignments(emp,:,s),2) - staff(emp,s+1);
    Q(Q<0)=0;
    Q(Q>0)=1;
    penalty3 = penalty3 + sum(Q,1);
end
 
%%MODDED
%%Constraint 4
penalty4 = 0;
lengthCol = length(assignments(1,:,1));
lengthShift = length(assignments(1,1,:)); 
NoOfShifts = length(shifts(:,1));
 
Counter = 0;
for j=1:lengthCol
    for z=1:lengthShift
        if assignments(emp,j,z) == 1;
            Counter = Counter +1; 
        end

    end
end

if Counter > ceil((staff(emp,length(shifts(:,1))+2)/(60*8)))
    penalty4 = penalty4 + Counter - (staff(emp,length(shifts(:,1))+2)/(60*8));
end
if Counter < ceil((staff(emp,length(shifts(:,1))+3)/(60*8)))
    penalty4 = penalty4 + (staff(emp,length(shifts(:,1))+3)/(60*8)) - Counter; 
end


%%MODDED
%%Constraint 5
penalty5 = 0;
%MAXIMUM CONSECUTIVE DAYS
%consecShifts = 0;
for day = 1:horizon-(NoOfShifts+4)
    consecShifts = 0;
    for j = day:day+staff(emp, NoOfShifts+4)
        for k = 1:length(shifts(:,1))
            consecShifts = consecShifts + assignments(emp, j, k);
        end
    end
    if consecShifts > staff(emp, NoOfShifts+4)
        penalty5 = penalty5 + 1;
    end
end

min_consecShifts = 10000;
shiftFlag = 0;
%MINIMUM CONSECUTIVE DAYS

consecShifts = 0;
for day = 1:horizon

     for k = 1:length(shifts(:,1))
          if (assignments(emp,day,k) == 0)
              shiftFlag = shiftFlag + 1;
          end
     end

     if shiftFlag < length(shifts(:,1))
         consecShifts = consecShifts + 1;
     else
         if (consecShifts > 0)
             if(min_consecShifts > consecShifts)
                 min_consecShifts = consecShifts;
                 consecShifts = 0;
             end
         end   
     end

        if min_consecShifts < staff(emp, NoOfShifts+5) && day > 2

        penalty5 = penalty5 + 1;
        end
        shiftFlag = 0;
        min_consecShifts = 10000;
end

%%MODDED
%MINIMUM DAYS OFF
%%Constraint 6
penalty6 = 0;
if staff(emp, NoOfShifts+6) == 2
    for day = 2:horizon-1
        if sum(assignments(emp, day, :),3) == 0 && sum(assignments(emp, day+1, :),3) == 1 && sum(assignments(emp, day-1, :),3) == 1
            penalty6 = penalty6 + 1;
        end
    end
elseif staff(emp, NoOfShifts+6) == 3
    for day = 3:horizon-2
        if sum(assignments(emp, day, :),3) == 0 
            if ((sum(assignments(emp, day+1, :),3) == 0 && sum(assignments(emp, day-1, :),3) == 0)...
                    +(sum(assignments(emp, day+1, :),3) == 0 && sum(assignments(emp, day+2, :),3) == 0)...
                    +(sum(assignments(emp, day-1, :),3) == 0 && sum(assignments(emp, day-2, :),3) == 0)) == 0
                penalty6 = penalty6 + 1;
            end
        end
    end
end


%%MODDED
%%Constraint 7 (Maximum Number of Weekends worked)
penalty7 = 0;
n = horizon/7;
W = zeros(size(staff,1),n);
for r=1:n
   W(emp,r) = sum(assignments(emp,7*r-1,:),3) + sum(assignments(emp,7*r,:),3);
end

W(W>0) = 1;
U = sum(W,2) - staff(emp,end);
U(U<0) = 0;
% U(U>0)=1;
penalty7 = penalty7 + sum(U,1);

%%MODDED
%%Constraint 8 (Employee days off)
columns8 = size(sectiondaysoff,2)-1;
penalty8 = 0;
for r = 1:rows
  for t = 1:columns8
     if assignments(emp,sectiondaysoff(emp,t+1)+1,r)==1
         penalty8 = penalty8 + 1;
     end
  end
end


%%Constraint 9 (Coverage requirments (Soft))
penalty9 = 0;
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
 
cost = ((penalty1 + penalty2 + penalty3 + penalty4 + penalty5 + penalty6 + penalty7 + penalty8)*10000) + penalty9 + penalty10 + penalty11;
%cost = penalty1 + penalty2 + penalty3  + penalty4 + penalty5 + penalty6 + penalty7 + penalty8;
%cost = penalty7;

end


