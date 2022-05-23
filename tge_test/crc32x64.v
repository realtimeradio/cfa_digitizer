`timescale 1ns/1ps

// crc32x64 is a CRC32 generator that processes 64 bits (8 bytes) at one time.
// Input bit sequence must be padded to a multiple of 64 bits, if needed.

module crc32x64 (
  input clk,
  input ce,
  input valid_in,         // init and data are valid
  input init_in,          // start a new CRC calculation
  input [63:0] data_in,   // 64 bits of input data
  output valid_out,       // crc output is valid
  output init_out,        // crc output is start of new sequence
  output [63:0] data_out, // 64 bits of input data
  output [31:0] crc       // 32 bit output CRC
);

reg  [ 6:0] valid_pipeline = 0; // Pipeline for valid signal
reg  [ 6:0] init_pipeline  = 0; // Pipeline for init signal
reg  [63:0] data_pipeline[6:0]; // Pipeline for data signal

wire [31:0] lut_out_wire [7:0]; // "Input LUT" output wires
reg  [31:0] lut_out_reg  [7:0]; // Registered LUT output

reg  [31:0] xor_out_reg_0 = 0;  // Registered xor output
reg  [31:0] xor_out_reg_1 = 0;  // Registered xor output
reg  [31:0] xor_out_reg = 0;    // Registered xor output

wire [31:0] acclut_out [3:0];   // "Accum LUT" output wires
reg  [31:0] crc_reg = 0;        // CRC value
reg  [31:0] out_reg = -1;       // Output register (TODO: Make optional?)

integer i;
genvar  g;

// Initialize data_pipeline and lut_out_reg for simulation (and FPGA?)
initial begin
  for(i=0; i<7; i=i+1)
    data_pipeline[i] = 0;
  for(i=0; i<8; i=i+1)
    lut_out_reg[i] = 0;
end

// Generate 8 crcluts for the inputs
generate
  for(g=0; g<8; g=g+1) begin: input_luts
    crclut #(
      .XN(8*g)
    ) lut (
      .addr(data_pipeline[1][8*g+:8]),
      .data(lut_out_wire[g])
    );
  end
endgenerate

// Clock the valid, init, and data pipelines
always @(posedge clk) begin
  if(ce) begin
    valid_pipeline <= {valid_pipeline[5:0], valid_in};
    // init pipeline for accumulator
    init_pipeline <= {init_pipeline[5:0], init_in};
    data_pipeline[0] <= data_in;

    // TODO Make this input inversion a parameter.
    // Invert 32 MSbs of data on init for data_pipeline[1].
    // Un-invert 32 MSbs of data on init for data_pipeline[2].
    for(i=0; i<2; i=i+1) begin
      data_pipeline[i+1][63:32] <= init_pipeline[i] & valid_pipeline[i]
                                ? ~data_pipeline[i][63:32]
                                :  data_pipeline[i][63:32];
      data_pipeline[i+1][31:0 ] <= data_pipeline[i][31:0];
    end

    for(i=2; i<6; i=i+1)
      data_pipeline[i+1] <= data_pipeline[i];
  end
end

// Clock the input pipeline
always @(posedge clk) begin
  if(ce) begin
    // LUT output regsters
    for(i=0; i<8; i=i+1)
      lut_out_reg[i] <= lut_out_wire[i];

    // Pipelined XOR tree - 1st stage
    xor_out_reg_0 <= lut_out_reg[0]^lut_out_reg[1]^lut_out_reg[2]^lut_out_reg[3];
    xor_out_reg_1 <= lut_out_reg[4]^lut_out_reg[5]^lut_out_reg[6]^lut_out_reg[7];

    // Pipelined XOR tree - 2nd stage
    xor_out_reg <= xor_out_reg_0 ^ xor_out_reg_1;
  end // if(ce)
end // alwyas @(posedge clk)

// Generate 4 crcluts for the accumulator
generate
  for(g=0; g<4; g=g+1) begin: accum_luts
    crclut #(
      .XN(8*g+32)
    ) lut (
      .addr(crc_reg[31-8*g-:8]),
      .data(acclut_out[g])
    );
  end
endgenerate

// Clock the accumulator and output registers
always @(posedge clk) begin
  if(ce & valid_pipeline[4]) begin
    if(init_pipeline[4])
      crc_reg <= xor_out_reg;
    else
      crc_reg <= acclut_out[0]^acclut_out[1]^acclut_out[2]^acclut_out[3]^xor_out_reg;
  end

  if(ce) begin
    // Invert output
    // TODO Make this outout inversion a parameter
    out_reg <= ~crc_reg;
  end
end // alwyas @(posedge clk)

// Drive output
assign valid_out = valid_pipeline[6];
assign init_out = init_pipeline[6];
assign data_out = data_pipeline[6];
assign crc = out_reg;

endmodule
