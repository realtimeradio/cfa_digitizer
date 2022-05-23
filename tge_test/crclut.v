`timescale 1ns/1ps

module crclut #(
  // IWIDTH is width of LUT input.
  parameter IWIDTH = 8,
  // OWIDTH is width of LUT output.  This is the width of the CRC check value,
  // which is one less than the order of the CRC polynomial.
  parameter OWIDTH = 32,
  // POLY is the CRC polynomial, excluding the msb.  This should be the
  // "normal" representaion, even if the desired CRC implementation is
  // lsb-first.
  parameter POLY = 32'h04C11DB7,
  // XN is the n in the x**n factor for this LUT.  It is essentially the
  // number of zeros that are assumed to be appended to the input.
  parameter XN = 0,
  // LSB_FIRST describes bit ordering of input and output.  When LSB_FIRST is
  // true, the input words are assumed to be bit-reversed and the output word
  // is also bit reversed.
  parameter LSB_FIRST = 1
)(
  input  [IWIDTH-1:0] addr,
  output [OWIDTH-1:0] data
);

  // Lookup table that is OWIDTH wide and 2**IWIDTH deep
  reg [OWIDTH-1:0] lut [0:2**IWIDTH-1];
  integer i;

  function [OWIDTH-1:0] lutinit(input [IWIDTH-1:0] a);
    integer i;
    reg [OWIDTH-1:0] b;
    reg msb;
    begin
      // Initialize upper IWIDTH bits of b to a, others to 0
      b = {a, {OWIDTH-IWIDTH{1'b0}}};

      if(LSB_FIRST)
        // Bit reverse a into the upper IWIDTH bits of b.
        for(i=0; i<IWIDTH; i=i+1)
          b[OWIDTH-1-i] = a[i];

      // Divide IWIDTH+XN terms of zero-padded input by POLY.
      for(i=0; i<IWIDTH+XN; i=i+1) begin
        msb = b[OWIDTH-1];
        b = {b[OWIDTH-2:0], 1'b0};
        if(msb)
          b = b ^ POLY;
      end // for

      if(LSB_FIRST)
        // Bit reverse b into lutinit
        for(i=0; i<OWIDTH; i=i+1)
          lutinit[OWIDTH-1-i] = b[i];
      else
        lutinit = b;
    end
  endfunction

  initial begin
    for(i=0; i<2**IWIDTH; i=i+1)
      lut[i] = lutinit(i);

    //i='h00; $display("lutinit[%x] = %x", i, lutinit(i));
    //i='h80; $display("lutinit[%x] = %x", i, lutinit(i));
    //$display("lutinit[0] = %b", lutinit(0));
  end // initial

  assign data = lut[addr];

endmodule
