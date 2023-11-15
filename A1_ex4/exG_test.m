% Example usage:
x = 1464;  % Replace with your desired value of x
result = ex_golomb_encoding(x);
disp(result);  % Display the result
a = ex_golomb_decoding('00101');
disp(a);


% Function to perform the operation
function binaryString = ex_golomb_encoding(x)
    % a non-positive integer x≤0 is mapped to an even integer −2x, while a positive integer x>0 is mapped to an odd integer 2x−1.
    if x>0
        binaryValue = dec2bin(2*x - 1 + 1);    
    else
        binaryValue = dec2bin(-2*x + 1);
    end
    % Count the number of bits
    bitCount = length(binaryValue);
    
    % Subtract 1 from the count
    zeroCount = bitCount - 1;
    
    % Write that number of starting zero bits preceding the previous bit string
    binaryString = strcat(repmat('0', 1, zeroCount), binaryValue);
end

function x = ex_golomb_decoding(binaryString)
    % Count the number of leading zeros
    zeroCount = find(binaryString == '1', 1, 'first') - 1;
    
    % Determine the length and extract the binary representation of the mapped value
    bitCount = zeroCount + 1;
    binaryValue = binaryString(zeroCount + 1 : zeroCount + bitCount);
    
    % Convert the binary representation back to decimal
    mappedValue = bin2dec(binaryValue) - 1;  % Subtract 1 because 1 was added during encoding
    
    % Reverse the mapping to obtain the original value of x
    if mod(mappedValue, 2) == 0  % Mapped value is even, so original x was non-positive
        x = -mappedValue / 2;
    else  % Mapped value is odd, so original x was positive
        x = (mappedValue + 1) / 2;
    end
end