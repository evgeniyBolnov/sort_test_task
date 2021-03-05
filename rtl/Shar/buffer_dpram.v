module buffer_dpram (/*AUTOARG*/
  // Outputs
  q,
  // Inputs
  data, rdaddress, rdclock, wraddress, wrclock, wren, rden
  );

  `include "log2.inc"

  parameter  DATA_WIDTH = 32;
  parameter  ENTRIES    = 64;
  localparam ADDR_WIDTH = alt_clogb2(ENTRIES);


  input  [DATA_WIDTH-1:0] data;
  input  [ADDR_WIDTH-1:0] rdaddress;
  input                   rdclock;
  input  [ADDR_WIDTH-1:0] wraddress;
  input                   wrclock;
  input                   wren;
  input                   rden;
  output [DATA_WIDTH-1:0] q;

  altsyncram altsyncram_ins (
            .wren_a         (wren),
            .rden_b         (rden),
            .clock0         (wrclock),
            .clock1         (rdclock),
            .address_a      (wraddress),
            .address_b      (rdaddress),
            .data_a         (data),
            .q_b            (q),
            .aclr0          (1'b0),
            .aclr1          (1'b0),
            .clocken0       (1'b1),
            .clocken1       (1'b1),
            .clocken2       (1'b1),
            .clocken3       (1'b1),
            .eccstatus      (),
            .q_a            (),
            .rden_a         (1'b1),
            .data_b         ({DATA_WIDTH{1'b1}}),
            .wren_b         (1'b0),
            .byteena_b      (1'b1),
            .addressstall_a (1'b0),
            .byteena_a      (1'b1),
            .addressstall_b (1'b0)
            );
  defparam
    altsyncram_ins.intended_device_family = "Cyclone V",
    altsyncram_ins.clock_enable_input_a   = "BYPASS",
    altsyncram_ins.clock_enable_input_b   = "BYPASS",
    altsyncram_ins.clock_enable_output_b  = "BYPASS",
    altsyncram_ins.address_aclr_a         = "NONE",
    altsyncram_ins.address_aclr_b         = "NONE",
    altsyncram_ins.address_reg_b          = "CLOCK1",
    altsyncram_ins.indata_aclr_a          = "NONE",
    altsyncram_ins.lpm_type               = "altsyncram",
    altsyncram_ins.numwords_a             = ENTRIES,
    altsyncram_ins.numwords_b             = ENTRIES,
    altsyncram_ins.operation_mode         = "DUAL_PORT",
    altsyncram_ins.outdata_aclr_b         = "NONE",
    altsyncram_ins.outdata_reg_b          = "UNREGISTERED",
    //altsyncram_ins.outdata_reg_b          = "CLOCK1",
    altsyncram_ins.power_up_uninitialized = "FALSE",
    altsyncram_ins.rdcontrol_reg_b        = "CLOCK1",
    altsyncram_ins.widthad_a              = ADDR_WIDTH,
    altsyncram_ins.widthad_b              = ADDR_WIDTH,
    altsyncram_ins.width_a                = DATA_WIDTH,
    altsyncram_ins.width_b                = DATA_WIDTH,
    altsyncram_ins.width_byteena_a        = 1,
    altsyncram_ins.wrcontrol_aclr_a       = "NONE";

endmodule
