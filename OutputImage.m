function image = OutputImage(txtPath)
%Convert Binary Output to Image

fid = fopen(txtPath);

text = strsplit(fread(fid, '*char')', '\n');

image = uint8(zeros([100,100]));
for i = 1:100
   row = cell2mat(text(i));
   for j = 1:100
       image(i,j) = uint8(bin2dec(row(1, (j*8)-7:j*8)));
   end
end

imshow(image, [0,255]);



fclose(fid);
end