module tb;
  reg i_1, i_2, i_3;
  wire o_1, o_2;

  producer dut(.i_1(i_1), .i_2(i_2), .i_3(i_3), .o_1(o_1), .o_2(o_2));

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb);
    $monitor("t=%0t i=%b%b%b o=%b%b", $time, i_1, i_2, i_3, o_1, o_2);

    i_1=0; i_2=0; i_3=0;
    #10 i_1=1;
    #10 i_2=1;
    #10 i_3=1;
    #10 $finish;
  end
endmodule

