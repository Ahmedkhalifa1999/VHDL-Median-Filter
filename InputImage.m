function image = InputImage(txtPath, imagePath)
%Convert Image to binary data for TestBench

fid = fopen(txtPath, 'w');




for i = 1:100
    for j = 1:100
        binary = dec2bin(image(i,j),8);
        fprintf(fid, '%s', binary);
    end
    for j = 1:100
        binary = dec2bin(image(i+1,j),8);
        fprintf(fid, '%s', binary);
    end
    for j = 1:100
        binary = dec2bin(image(i+2,j),8);
        fprintf(fid, '%s', binary);
    end
    fprintf(fid, '\n');
end

fclose(fid);
end

