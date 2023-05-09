input_file = fopen("input.txt", "w");
expected_output_file = fopen("expected_output", "w");

min = 2^10;
max = 2^(-10);

for i = 1:100
    a = single(min + (max-min)*rand());
    b = single(min + (max-min)*rand());
    d = rand()
    if (d <= 0.5) & (d > 0.25)
        a = -1*a;
    elseif (d > 0.5) & (d <= 0.75)
        b = -1*b;
    elseif d <= 0.25
        a = a;
        b = b;
    else 
        a = -1*a;
        b = -1*b;
    end
    if a == 0
        a = min + (max-min)*rand(); 
    end
    if b == 0
        b = min + (max-min)*rand();
    end
    c = a + b;
    hex_a = cellstr(num2hex(a));
    dec_a = hex2dec(hex_a);
    bin_a = dec2bin(dec_a, 32);
    hex_b = cellstr(num2hex(b));
    dec_b = hex2dec(hex_b);
    bin_b = dec2bin(dec_b, 32);
    hex_c = cellstr(num2hex(single(c)));
    dec_c = hex2dec(hex_c);
    bin_c = dec2bin(dec_c, 32);
    rst = '0';
    fprintf(input_file, '%s %s %s\n', rst, bin_a, bin_b);
    fprintf(expected_output_file, '%s\n', bin_c);
end

