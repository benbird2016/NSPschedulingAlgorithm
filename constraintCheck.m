function Check = ConstraintCheck(assignments, staff, shifts, shiftsTrans, horizon, sectiondaysoff, covers, employee, currentDay, Flag)

%%Constraint 1 (Maximum Shift Assignments per day)
penalty1 = 0;
for r = 1:size(assignments,2)
    R = sum(assignments(:,r,:),3) - ones(size(assignments,1),1);
    R(R<0) = 0;
    R(R>1) = 1;
    penalty1 = penalty1 + sum(R,1);
end

%%Constraint 2 (Shift Rotation)
penalty2 = 0;
emp = 1;
for day = 1:(horizon-1)
    i=1;
    while i < length(shifts(:,1))+1
        for j = 3:length(shifts(1,:))
            if shiftsTrans(i,j) ~= 0
                if assignments(emp, day, shiftsTrans(i,1)) == 1 && assignments(emp, day+1, shiftsTrans(i,j)) == 1
                    penalty2 = penalty2 +1;
                end
            end
        end
        i=i+1;
    end
end


%%Constraint 3 (Maximum number of shifts)
rows = size(shifts,1);
penalty3 = 0;
for s = 1:rows
    Q = sum(assignments(:,:,s),2) - staff(employee,s+1);
    Q(Q<0)=0;
    Q(Q>0)=1;
    penalty3 = penalty3 + sum(Q,1);
    %
    if currentDay > 1 && currentDay < horizon
        if Flag==0 && (staff(employee,s+1))~=0
            if (sum(sum(assignments(1, :, s)),3) == (staff(employee,s+1))) && (sum(assignments(1, currentDay-1, s), 3)== 0 && sum(assignments(1, currentDay+1, s), 3)==0 && sum(assignments(1, currentDay, s), 3)==1)
                penalty3=penalty3+1;
            end
        elseif Flag==1 && (staff(employee,s+1))~=0
            if (sum(sum(assignments(1, :, s)),3) == (staff(employee,s+1))) && (sum(assignments(1, currentDay+1, s), 3)== 0 && sum(assignments(1, currentDay-1, s), 3)== 0 && sum(assignments(1, currentDay, s), 3)==1)
                penalty3=penalty3+1;
            end
        end
    end
    %
end


%%Constraint 4 (Maximum and Minimum total shifts in horizon)
penalty4 = 0;

lengthDays = length(assignments(1,:,1));
lengthShift = length(assignments(1,1,:)); 
 
i=1;
Counter = 0;
for j=1:lengthDays
    for z=1:lengthShift
        if assignments(i,j,z) == 1;
            Counter = Counter +1; 
        end

    end
end

if Counter > ceil((staff(employee,length(shifts(:,1))+2)/(60*8)))
    penalty4 = penalty4 + Counter - (staff(employee,length(shifts(:,1))+2)/(60*8));
end
%     if Counter < (staff(i,length(shifts(:,1))+3)/(60*8))
%         penalty4 = penalty4 + (staff(i,length(shifts(:,1))+3)/(60*8)) - Counter; 
%     end
    

%Constraint 5 (Maximum and minimum consecutive shifts) 
%%MAX
penalty5 = 0;
NoOfShifts = length(shifts(:,1));

emp = 1;
for day = staff(emp, NoOfShifts+4)+1:horizon
    consecShifts = 0;
    for j = day-staff(emp, NoOfShifts+4):day
        for k = 1:length(shifts(:,1))
            consecShifts = consecShifts + assignments(emp, j, k);
        end
    end
    if consecShifts > staff(emp, NoOfShifts+4)
        penalty5 = penalty5 + 1;
    end
end


%%MIN
if Flag == 0
    if currentDay > 1 && currentDay < horizon
        if length(sectiondaysoff(employee,:)) > 2 
            if or(currentDay+1 == sectiondaysoff(employee,2)+1, currentDay+1 == sectiondaysoff(employee,3)+1) && sum(assignments(1, currentDay-1, :), 3)== 0
                penalty5 = penalty5+1;
            end
        else
            if currentDay+1 == sectiondaysoff(employee,2)+1 && sum(assignments(1, currentDay-1, :), 3)== 0
                penalty5 = penalty5+1;
            end
        end
        if (sum(sum(assignments(1, :, :)),3)-1 > ceil((staff(employee,length(shifts(:,1))+2)/(60*8)))-2) && sum(assignments(1, currentDay-1, :), 3)== 0
            penalty5=penalty5+1;
        end
        %
        previousW = 0;
        for i=1:floor(horizon/7)
            previousW = previousW + sum(assignments(1, i*7, :), 3) + sum(assignments(1, (i*7)-1, :), 3);
        end
        if mod(currentDay+2,7)==0 && previousW >= staff(employee,end) && sum(assignments(1, currentDay-1, :), 3)== 0
            penalty5 = penalty5+1;
        end
        %
    end
    % Exception for edges of the horizon 
    else
    if currentDay > 1 && currentDay < horizon
        if length(sectiondaysoff(1,:)) > 2 
            if or(currentDay-1 == sectiondaysoff(employee,2)+1, currentDay-1 == sectiondaysoff(employee,3)+1) && sum(assignments(1, currentDay+1, :), 3)== 0
                penalty5 = penalty5+1;
            end
        else
            if currentDay-1 == sectiondaysoff(employee,2)+1 && sum(assignments(1, currentDay+1, :), 3)== 0
                penalty5 = penalty5+1;
            end
        end
        if (sum(sum(assignments(1, :, :)),3)-1 > (staff(employee,length(shifts(:,1))+2)/(60*8))-2) && sum(assignments(1, currentDay+1, :), 3)== 0
            penalty5=penalty5+1;
        end
        %
        previousW = 0;
        for i=1:floor(horizon/7)
            previousW = previousW + sum(assignments(1, i*7, :), 3) + sum(assignments(1, (i*7)-1, :), 3);
        end
        if mod(currentDay-1,7)==0 && previousW >= staff(employee,end) && sum(assignments(1, currentDay+1, :), 3)== 0
            penalty5 = penalty5+1;
        end
        %
    end
end
%               

%%Constraint 6 (Minimum conseuctive days off)
penalty6 = 0;
emp = 1;
if staff(employee, NoOfShifts+6) == 2
    for day = 2:horizon-1
        if sum(assignments(emp, day, :)) == 0 && sum(assignments(emp, day+1, :)) == 1 && sum(assignments(emp, day-1, :)) == 1
            penalty6 = penalty6 + 1;
        end
    end
elseif staff(employee, NoOfShifts+6) == 3
    %
    if sum(assignments(emp, 2, :)) == 0 && (sum(assignments(emp, 3, :))+sum(assignments(emp, 4, :)))~=2
        if (sum(assignments(emp, 1, :)) == 0)+((sum(assignments(emp, 3, :)) == 0 & sum(assignments(emp, 4, :)) == 0)) == 0
            penalty6 = penalty6+1;
        end
    end
    %
    if sum(assignments(emp, horizon-1, :)) == 0 && (sum(assignments(emp, horizon-2, :))+sum(assignments(emp, horizon-3, :)))~=2
        if ((sum(assignments(emp, horizon, :)) == 0)+(sum(assignments(emp, horizon-2, :)) == 0 & sum(assignments(emp, horizon-3, :)) == 0)) == 0
            penalty6 = penalty6+1;
        end
    end
    %
    for day = 3:horizon-2
        if sum(assignments(emp, day, :)) == 0 
            if ((sum(assignments(emp, day+1, :)) == 0 & sum(assignments(emp, day-1, :)) == 0)...
                    +(sum(assignments(emp, day+1, :)) == 0 & sum(assignments(emp, day+2, :)) == 0)...
                    +(sum(assignments(emp, day-1, :)) == 0 & sum(assignments(emp, day-2, :)) == 0)) == 0
                penalty6 = penalty6 + 1;
            end
        end
    end
end


%%Constraint 7 (Maximum Number of Weekends worked)
penalty7 = 0;
n = horizon/7;
W = zeros(1,n);
for r=1:n
    W(:,r) = sum(assignments(:,7*r-1,:),3) + sum(assignments(:,7*r,:),3);
end
W(W>1) = 1;
U = sum(W,2) - staff(employee,end);
U(U<0) = 0;
U(U>0) = 1;
penalty7 = penalty7 + sum(U,1);

%%Constraint 8 (Employee days off)
columns8 = size(sectiondaysoff,2)-1;
penalty8 = 0;
for r = 1:rows
  for t = 1:columns8
     if assignments(:,sectiondaysoff(employee,t+1)+1,r)==1
         penalty8 = penalty8+1;
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

%%Cost calculation
cost = penalty1+penalty2+penalty3+penalty4+penalty5+penalty6+penalty7+penalty8;

if cost > 0
    Check = 1;
else
    Check = 0;
end
end







