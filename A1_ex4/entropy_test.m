clear
clc

% Given matrix
input = [-31 9  8  4;
          3  1  -45  0; 
         -3  57  4  0;
          4  0   0   0;
          4 9 8 1;
          5 5 6 0];
width = 6;
height = 4;
coeff_bin = 'coeff.txt';
entropy(input, width, height, coeff_bin)




% output = reorder(input);
% output_RLE = customRLE(output,i);
% output
% output_RLE
% 
% output_entropy = expGolombExtended(output_RLE);
% output_entropy
% writeBinary(coeff_bin, output_entropy);

function entropy(input, width, height, coeff_bin)
    output = reorder(input);
    output_RLE = customRLE(output,width, height);
    output_entropy = expGolombExtended(output_RLE);
    writeBinary(coeff_bin, output_entropy);
end



% order in document
function output = reorder(input)
    % Assume input is an 8x8 matrix
    [rows, cols] = size(input);
    output = zeros(1, rows*cols);
    index = 1;
    for sum = 0:(rows+cols-2)
        for i = 0:sum
            j = sum - i;
            if (i < rows) && (j < cols)
                output(index) = input(i+1, j+1);
                index = index + 1;
            end
        end
    end
end

% zigzag order
function output = zigzag_order(input)
    % Assume input is an 8x8 matrix
    [rows, cols] = size(input);
    output = zeros(1, rows*cols);
    index = 1;
    for sum = 0:(rows+cols-2)
        if mod(sum, 2) == 0  % Even sum: move from bottom-left to top-right
            for j = 0:sum
                i = sum - j;
                if (i < rows) && (j < cols)
                    output(index) = input(i+1, j+1);
                    index = index + 1;
                end
            end
        else  % Odd sum: move from top-right to bottom-left
            for i = 0:sum
                j = sum - i;
                if (i < rows) && (j < cols)
                    output(index) = input(i+1, j+1);
                    index = index + 1;
                end
            end
        end
    end
end

function encoded = customRLE(seq,width, height)
    encoded = [];  % Initialize an empty array to store the encoded sequence
    n = width*height;  % Get the length of the input sequence
    i = 1;  % Initialize the index variable

    while i <= n
        runStart = i;  % Store the start index of the current run
        if seq(i) ~= 0
            % Handle non-zero run
            while i <= n && seq(i) ~= 0
                i = i + 1;
            end
            runLength = i - runStart;  % Compute the length of the run
            encoded = [encoded, -runLength, seq(runStart:i-1)];  % Append the run length and the numbers to the encoded sequence
        else
            % Handle zero run
            while i <= n && seq(i) == 0
                i = i + 1;
            end
            runLength = i - runStart;  % Compute the length of the run
            if i <= n  % Check if there are more non-zero numbers
                encoded = [encoded, runLength];  % Append the run length to the encoded sequence
            else
                encoded = [encoded, 0];  % Append 0 to indicate that the rest of the elements are zeros
            end
        end
    end
end


function coded = expGolombExtended(input)
    % Initialize an empty array to store the coded sequence
    coded = '';
    
    % Loop through each element in the input sequence
    for i = 1:length(input)
        % Get the current value
        val = input(i);
        
        % Map the input value to a non-negative integer
        if val<= 0
            mappedVal = -2*val;
        else
            mappedVal = 2*val-1;
        end    
        
        mappedVal = round(mappedVal);
        
        % Get the Exponential-Golomb code of the mapped value
        egCode = expGolomb(mappedVal);
        
        % Append the Exponential-Golomb code to the coded sequence
        coded = [coded, egCode];
    end
end

function code = expGolomb(num)
    % Compute the length of the binary part
    binLen = floor(log2(num + 1)) + 1;
    
    % Compute the prefix (a string of binLen - 1 zeros)
    prefix = repmat('0', 1, binLen - 1);
    
    % Compute the binary representation of num + 1
    binary = dec2bin(num + 1, binLen);
    
    % Concatenate the prefix and binary parts to form the Exponential-Golomb code
    code = [prefix, binary];
end


function writeBinary(filename, binaryString)
    % Open the file with write permission
    fileId = fopen(filename, 'wt');
    
    % Check if the file has been opened successfully
    if fileId == -1
        error('Failed to open file for writing.');
    end
    
    % Write the binary string to the file
    fprintf(fileId, '%s', binaryString);
    
    % Close the file
    fclose(fileId);
end







