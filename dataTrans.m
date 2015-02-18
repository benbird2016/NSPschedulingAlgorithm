function data = dataTrans(rawData, shifts, index) 
N = 1;
A = 1;
if index == 1    
    dataTrans = rawData;
    while N <= length(rawData(:,1))
        for i = 1:length(rawData(:,1))
            for j = 1:length(rawData(1,:))
                if rawData(i,j) == rawData(N,1)
                    dataTrans(i,j) = A;
                end
            end
        end
        N = N + 1;
        A = A + 1;
    end
else
    dataTrans = rawData;
    while N <= length(shifts(:,1))
        for i = 1:length(rawData(:,1))
                if rawData(i,3) == shifts(N,1)
                    dataTrans(i,3) = A;
                end
        end
        N = N + 1;
        A = A + 1;
    end   
end

data = dataTrans;