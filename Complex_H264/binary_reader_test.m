% Define binary string
binaryString = '0100100100100100';

% Write binary string to a file
writeBinary('binaryData.txt', binaryString);

% Read binary string from the file
readString = readBinary('binaryData.txt');

% Display the read string
disp(readString);



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

function binaryString = readBinary(filename)
    % Open the file with read permission
    fileId = fopen(filename, 'rt');
    
    % Check if the file has been opened successfully
    if fileId == -1
        error('Failed to open file for reading.');
    end
    
    % Read the text from the file
    binaryString = fscanf(fileId, '%c');
    
    % Close the file
    fclose(fileId);
end
