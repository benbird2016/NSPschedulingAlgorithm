%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%MIE562 Scheduling - Final Project - Nurse Scheduling Problem
%Due Date: Wednesday December 3, 2014
%Authors: Olawale Adeniji, Kyle Booth, Yrysguli Kairedan, Anis Rabie
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%0. INITIAL SET-UP
%0.1 Raw Data Input
staff = csvread('data/sectionstaff1.csv');
shifts = csvread('data/sectionshifts1.csv');
covers = csvread('data/sectioncover1.csv');
sectionDaysOff = csvread('data/sectiondaysoff1.csv');
onRequests = csvread('data/sectionshiftonrequests1.csv');
offRequests = csvread('data/sectionshiftoffrequests1.csv');
%0.2 Raw Data Format Manipulation
shiftsTrans = dataTrans(shifts,1,1);
onRequestsTrans = dataTrans(onRequests, shifts, 2);
offRequestsTrans = dataTrans(offRequests, shifts, 2);
%0.3 Global Parameter Input & Matrix Pre-Allocation
horizon = 14;
softcost_matrix = [0];
stageTwoCost_matrix = [0];
stageThreeCost_matrix = [0];
final_solution = zeros(length(staff), horizon, length(shifts(:,1)));
null_row = zeros(1, horizon);
if length(shifts(:,1)) < 2
assignment_matrix = zeros(length(staff), horizon, length(shifts(:,1)));
stageTwo_assignments = zeros(length(staff), horizon, length(shifts(:,1)));
stageThree_assignments = zeros(length(staff), horizon, length(shifts(:,1)));
else
assignment_matrix = zeros(length(staff), horizon, length(shifts(:,1)));
stageTwo_assignments = zeros(length(staff), horizon, length(shifts(:,1)));
stageThree_assignments = zeros(length(staff), horizon, length(shifts(:,1)));
end
%0.4 Program Print-Out: Initial Infeasible Starting Point
fprintf('\nPowering Up.\n\nStarting with following infeasible solution:\n');
assignment_matrix
fprintf('First Fit Heuristic Activated for Feasible Initial Solution.\n');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%1. INITIAL SOLUTION HEURISTICS
%1.1 Input Parameters
it = 0;
matrixIndex = 0;
bestSoftCost = 100000;
%1.2 Initial Solution - First Fit Heuristic
while it < 100
assignments = zeros(length(staff), horizon, length(shifts(:,1)));
lengthRow = length(assignments(:,1,1));
lengthCol = length(assignments(1,:,1));
lengthShift = length(assignments(1,1,:));
assignmentDummy = assignments;
Die = 0;
count=1;
sStart = 1;
sStartLast = 1;
dStart = 1;
Flag = 0;
while count <= lengthRow
%Looping through employees.
for j=1:lengthRow
repeat = 1;
%This repeat loop is only trigered if the repeat triger is
%activated, see below.
while repeat < 2
round = 1;
%Two rounds of shift assignments are done here. The first
%starts from whatever shift the heuristic decided for this
%employee and the second starts from shift 1.
while round < 3
%Looping through shifts.
for i=sStart:lengthShift
if Flag == 1
y = horizon;
%Looping through days backward.
while y > 0
assignmentDummy(j,y,i) = 1;
%Checking for feasibility of suggested
%assignment.
PenaltyCheck = constraintCheck(assignmentDummy(j,:,:), staff, shifts, shiftsTrans, horizon, sectionDaysOff, covers, j, y, Flag);
if PenaltyCheck == 0
assignments(j,y,i) =1;
end
assignmentDummy = assignments;
y = y - 1;
end
else
%Looping through days forward.
for z=dStart:lengthCol
assignmentDummy(j,z,i) = 1;
PenaltyCheck = constraintCheck(assignmentDummy(j,:,:), staff, shifts, shiftsTrans, horizon, sectionDaysOff, covers, j, z, Flag);
if PenaltyCheck == 0
assignments(j,z,i) =1;
end
assignmentDummy = assignments;
end
end
end
round = round+1;
sStart = 1;
end
%Changing the start shift for assignment attempts.
sStartLast = sStart;
sStart = sStartLast+1;
if sStart > lengthShift
sStart=1;
sStartLast = sStart;
end
if j < length(staff)
if staff(j+1, sStart+1)==0
sStart = 1;
sStartLast = sStart;
end
%
if staff(j+1,sStart+1)==min(staff(j+1,2:length(shifts(1,:))))
sStart = 1;
sStartLast = sStart;
end
%
end
%Setting the start day as 1 or 2 based on random variable.
if Die < 0.5
dStart = 1;
else
dStart = 2;
end
%Too Constrained Exception (Forces assignments to start on
%the first day if employee is "too constrained" based on
%constraints for the given instance")
tooConstrained = 0;
c = 0;
if j < length(staff)
while c < length(shifts(:,1))+1
if staff(j+1, c+1) == 0
tooConstrained = tooConstrained + 1;
end
c = c + 1;
end
end
if tooConstrained > 0
dStart = 1;
end
%Random Variable
Die = rand;
%
repeat = repeat + 1;
%If no feasible set of assignments are found for an employee
%by making forward assignments from day 1 -> horizon, the
%following block of code trigers a backward assignment
%sequence from horizon -> day 1.
if sum(sum(assignments(j,:,:)),3) < ceil((staff(j,length(shifts(:,1))+3)/(60*8)))
assignments(j,:,:);
Flag = 1;
repeat = repeat - 1;
assignments(j,:,:) = zeros(1,horizon, length(shifts(:,1)));
assignmentDummy = assignments;
else
Flag = 0;
end
%
end
end
count = count+1;
end
%Calculation of soft cost for first fit heuristic.
softcost = softCost(assignments,shifts, horizon, covers, onRequestsTrans, offRequestsTrans);
duplicate = 0;
for i = 1:size(softcost_matrix,2)
if softcost == softcost_matrix(:,i)
duplicate = duplicate + 1;
end
i = i+1;
end
if duplicate == 0
matrixIndex = matrixIndex + 1;
softcost_matrix(:,matrixIndex) = softcost;
if length(shifts(:,1)) < 2
assignment_matrix(:,:,matrixIndex) = assignments;
else
assignment_matrix(:,:,:,matrixIndex) = assignments;
end
end
%Update of the best softcost (not important for iterative search)
if softcost < bestSoftCost
assignmentsFinal = assignments;
bestSoftCost = softcost
end
if it == 0
fprintf('First Feasible Solution Generated:\n');
assignment_matrix
end
it = it+1;
end
%1.2 Program Print-Out: First Fit Heuristic Results
fprintf('Best Cost of all generated feasible sets: %d.\n\n', bestSoftCost);
fprintf('Feasible Sets Generated: %d.\n\nIterative Local Search Initiated. Assessing Neighbourhood #1.\n\n', size(softcost_matrix,2))
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%2. ITERATIVE, VARIABLE NEIGHBOURHOOD LOCAL SEARCH
%2.1 Input Parameters
z = 1;
stageTwoBestCost = bestSoftCost;
swap_matrix = zeros(1, size(softcost_matrix,2));
%2.2 Local Search - Neighbourhood 1 - Single Element Changes
while z < size(softcost_matrix,2)+1
swapCount1 = 0;
swapCount2 = 0;
if length(shifts(:,1)) < 2
assignments = assignment_matrix(:,:,z);
else
assignments = assignment_matrix(:,:,:,z);
end
assignmentDummy = assignments;
BestCost = softcost_matrix(:,z);
PreviousBestCost = softcost_matrix(:,z);
searchLoop = 0;
while searchLoop < 1
Flag = 0;
while Flag < 1
for iii = 1:lengthShift
for i=1:lengthRow
if staff(i,1+iii) ~= 0
if isequal(assignments(i,:,iii),null_row) == 0
for ii =1:lengthCol
if assignments(i,ii,iii) == 1
assignmentDummy(i,ii,iii) = 0;
CurrentCost = costFunction_quick(i, assignmentDummy, staff, shifts, shiftsTrans, horizon, sectionDaysOff, covers, onRequestsTrans, offRequestsTrans);
if CurrentCost < BestCost
BestCost = CurrentCost;
Bidx1 = i;
Bidx2 = ii;
Bidx3 = iii;
swapCount1 = swapCount1 + 1;
swap_matrix(:,z) = swap_matrix(:,z) + 1;
end
assignmentDummy = assignments;
end
end
end
end
end
end
if BestCost == PreviousBestCost;
Flag = 1;
else
assignments(Bidx1, Bidx2, Bidx3) = 0;
assignments;
BestCost;
end
PreviousBestCost = BestCost;
end
PreviousBestCost = BestCost;
Flag = 0;
assignmentDummy = assignments;
while Flag < 1
for iii = 1:lengthShift
for i=1:lengthRow
if staff(i,1+iii) ~= 0
for ii =1:lengthCol
if assignments(i,ii,iii) == 0
assignmentDummy(i,ii,iii) = 1;
CurrentCost = costFunction_quick(i, assignmentDummy, staff, shifts, shiftsTrans, horizon, sectionDaysOff, covers, onRequestsTrans, offRequestsTrans);
if CurrentCost < BestCost
BestCost = CurrentCost;
Bidx1 = i;
Bidx2 = ii;
Bidx3 = iii;
swapCount2 = swapCount2 + 1;
swap_matrix(:,z) = swap_matrix(:,z) + 1;
end
assignmentDummy = assignments;
end
end
end
end
end
if BestCost == PreviousBestCost;
Flag = 1;
else
assignments(Bidx1, Bidx2, Bidx3) = 1;
assignments;
BestCost;
end
PreviousBestCost = BestCost;
end
searchLoop = searchLoop + 1;
end
if BestCost < stageTwoBestCost
stageTwoBestCost = BestCost;
end
stageTwoCost_matrix(:,z) = BestCost;
if length(shifts(:,1)) < 2
stageTwo_assignments(:,:,z) = assignments;
else
stageTwo_assignments(:,:,:,z) = assignments;
end
fprintf('Analyzing Feasible Set #%d. Best Cost Found: %d\n', z, BestCost);
z = z + 1;
end
stageTwoBestCost_final = stageTwoBestCost;
fprintf('\nBest Cost from Local Search Neighbourhood #1: %d\n\n', stageTwoBestCost_final);
fprintf('Variable Neighbourhood Search Continued. Assessing Neighbourhood #2.\n\n');
%2.3 Local Search - Neighbourhood 2 - Double Element Changes
stageThree_BestCost = 0;
z = 1;
while z < size(softcost_matrix,2)+1
if length(shifts(:,1)) < 2
assignments = stageTwo_assignments(:,:,z);
else
assignments = stageTwo_assignments(:,:,:,z);
end
swapCount3 = 0;
row = 1;
Flag = 0;
BestCost = stageTwoCost_matrix(:,z);
fprintf('Solution Set %d, N-1 Cost: %d. Neighbourhood #2 Optimization:\n\n', z, BestCost);
PreviousBestCost = stageTwoCost_matrix(:,z);
while Flag < 1
row = 1;
assignmentDummy = assignments;
solutionFlag = 0;
Bidx1 = 0;
Bidx2 = 0;
Bidx3 = 0;
Cidx1 = 0;
Cidx2 = 0;
Cidx3 = 0;
while solutionFlag < 1
if row == length(assignments(:,1,1))
solutionFlag = 1;
end
ii = 1;
while ii < lengthCol + 1 && solutionFlag == 0
iii = 1;
while iii < lengthShift + 1 && solutionFlag == 0
if staff(row,1+iii) ~= 0
if assignmentDummy(row,ii,iii) == 1
assignmentDummy(row,ii,iii) = 0;
else
assignmentDummy(row,ii,iii) = 1;
end
assignmentDummy2 = assignmentDummy;
jj = 1;
while jj < lengthCol + 1 && solutionFlag == 0
jjj = 1;
while jjj < lengthShift + 1 && solutionFlag == 0
if assignmentDummy2(row,jj,jjj) == 1
assignmentDummy2(row,jj,jjj) = 0;
else
assignmentDummy2(row,jj,jjj) = 1;
end
CurrentCost = costFunction_quick(row, assignmentDummy2, staff, shifts, shiftsTrans, horizon, sectionDaysOff, covers, onRequestsTrans, offRequestsTrans);
if CurrentCost < BestCost
solutionFlag = 1; %First improvement kicks out of loop
BestCost = CurrentCost;
Bidx1 = row;
Bidx2 = ii;
Bidx3 = iii;
Cidx1 = row;
Cidx2 = jj;
Cidx3 = jjj;
end
assignmentDummy2 = assignmentDummy;
jjj = jjj + 1;
end
jj = jj + 1;
end
assignmentDummy = assignments;
end
iii = iii + 1;
end
ii = ii + 1;
end
row = row + 1;
end
if (Cidx1 > 0)
if assignments(Bidx1, Bidx2, Bidx3) == 0
assignments(Bidx1, Bidx2, Bidx3) = 1;
else
assignments(Bidx1, Bidx2, Bidx3) = 0;
end
if assignments(Cidx1, Cidx2, Cidx3) == 0
assignments(Cidx1, Cidx2, Cidx3) = 1;
else
assignments(Cidx1,Cidx2,Cidx3) = 0;
end
swapCount3 = swapCount3 + 1;
swap_matrix(:,z) = swap_matrix(:,z) + 1;
end
if BestCost == PreviousBestCost;
Flag = 1;
final_solution = assignments;
final_swaps = swap_matrix(:,z);
end
fprintf('Best Cost: %d. Next Iteration.\n', BestCost);
row = 1;
PreviousBestCost = BestCost;
end
if BestCost < stageTwoBestCost_final
stageTwoBestCost_final = BestCost;
end
stageThreeCost_matrix(:,z) = BestCost;
if length(shifts(:,1)) < 2
stageThree_assignments(:,:,z) = assignments;
else
stageThree_assignments(:,:,:,z) = assignments;
end
fprintf('\nSolution Set %d, N-2 Optimized Cost: %d.\n\n', z, BestCost);
z = z+1;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%3. FINAL OUTPUT
stageThree_BestCost = stageTwoBestCost_final;
stageThree_BestCost;
fprintf('Program Complete. Best Cost Found: %d.\n\n', stageThree_BestCost);
fprintf('Neighbourhood #1 Swaps: %d.\nNeighbourhood #2 Swaps: %d.\n\nTotal Swaps Performed: %d.\n', swapCount1 + swapCount2, swapCount3, final_swaps);
final_solution

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%2. ITERATIVE, VARIABLE NEIGHBOURHOOD LOCAL SEARCH
%2.1 Input Parameters
z = 1;
%2.2 Local Search - Neighbourhood 1 - Single Element Changes
while z < size(softcost_matrix,2)+1
swapCount1 = 0;
swapCount2 = 0;
if length(shifts(:,1)) < 2
assignments = stageThree_assignments(:,:,z);
else
assignments = stageThree_assignments(:,:,:,z);
end
assignmentDummy = assignments;
BestCost = stageThreeCost_matrix(:,z);
PreviousBestCost = stageThreeCost_matrix(:,z);
searchLoop = 0;
while searchLoop < 1
Flag = 0;
while Flag < 1
for iii = 1:lengthShift
for i=1:lengthRow
if staff(i,1+iii) ~= 0
if isequal(assignments(i,:,iii),null_row) == 0
for ii =1:lengthCol
if assignments(i,ii,iii) == 1
assignmentDummy(i,ii,iii) = 0;
CurrentCost = costFunction_quick(i, assignmentDummy, staff, shifts, shiftsTrans, horizon, sectionDaysOff, covers, onRequestsTrans, offRequestsTrans);
if CurrentCost < BestCost
BestCost = CurrentCost;
Bidx1 = i;
Bidx2 = ii;
Bidx3 = iii;
swapCount1 = swapCount1 + 1;
swap_matrix(:,z) = swap_matrix(:,z) + 1;
end
assignmentDummy = assignments;
end
end
end
end
end
end
if BestCost == PreviousBestCost;
Flag = 1;
else
assignments(Bidx1, Bidx2, Bidx3) = 0;
assignments;
BestCost;
end
PreviousBestCost = BestCost;
end
PreviousBestCost = BestCost;
Flag = 0;
assignmentDummy = assignments;
while Flag < 1
for iii = 1:lengthShift
for i=1:lengthRow
if staff(i,1+iii) ~= 0
for ii =1:lengthCol
if assignments(i,ii,iii) == 0
assignmentDummy(i,ii,iii) = 1;
CurrentCost = costFunction_quick(i, assignmentDummy, staff, shifts, shiftsTrans, horizon, sectionDaysOff, covers, onRequestsTrans, offRequestsTrans);
if CurrentCost < BestCost
BestCost = CurrentCost;
Bidx1 = i;
Bidx2 = ii;
Bidx3 = iii;
swapCount2 = swapCount2 + 1;
swap_matrix(:,z) = swap_matrix(:,z) + 1;
end
assignmentDummy = assignments;
end
end
end
end
end
if BestCost == PreviousBestCost;
Flag = 1;
else
assignments(Bidx1, Bidx2, Bidx3) = 1;
assignments;
BestCost;
end
PreviousBestCost = BestCost;
end
searchLoop = searchLoop + 1;
end
if BestCost < stageTwoBestCost
stageTwoBestCost = BestCost;
end
stageTwoCost_matrix(:,z) = BestCost;
if length(shifts(:,1)) < 2
stageTwo_assignments(:,:,z) = assignments;
else
stageTwo_assignments(:,:,:,z) = assignments;
end
fprintf('Analyzing Feasible Set #%d. Best Cost Found: %d\n', z, BestCost);
z = z + 1;
end

stageTwoBestCost
