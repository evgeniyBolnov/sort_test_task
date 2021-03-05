//                              -*- Mode: Verilog -*-
// Filename        : sort_engine_top.v
// Description     : stream sequential sorting module,
//                   delay = 2*length + handshake overhead
// Status          : Unknown, Use with caution!

module sort_engine_top (/*AUTOARG*/
  // Outputs
  snk_ready, src_data, src_sop, src_eop, src_valid,
  // Inputs
  snk_clock, snk_reset, snk_data, snk_sop, snk_eop, snk_valid, src_clock,
  src_reset
  );

  `include "log2.inc"

  parameter DATA_WIDTH = 16;
  parameter MAX_LENGTH = 256;

  // input interface
  input                  snk_clock;
  input                  snk_reset;
  input [DATA_WIDTH-1:0] snk_data;
  input                  snk_sop;
  input                  snk_eop;
  input                  snk_valid;
  output                 snk_ready;

  // output interface
  input                   src_clock;
  input                   src_reset;
  output [DATA_WIDTH-1:0] src_data;
  output                  src_sop;
  output                  src_eop;
  output                  src_valid;
  //input                  src_ready;

  localparam ADDR_WIDTH = alt_clogb2(MAX_LENGTH);

  // dual port ram interface
  wire [DATA_WIDTH-1:0] buf_data;
  wire [DATA_WIDTH-1:0] buf_q;
  wire [ADDR_WIDTH-1:0] buf_wraddress;
  wire [ADDR_WIDTH-1:0] buf_rdaddress;
  wire                  buf_wren;
  wire                  buf_rden;

  // req/ack retiming
  wire                  src_ack;
  wire                  snk_req;

  // transaction length
  wire [ADDR_WIDTH-1:0] tran_len;

  sort_in_if #(
               .DATA_WIDTH (DATA_WIDTH),
               .MAX_LENGTH (MAX_LENGTH)
  )
  sort_in_if_ins (/*AUTOINST*/
                  // Outputs
                  .snk_ready         (snk_ready),
                  .buf_data          (buf_data[DATA_WIDTH-1:0]),
                  .buf_wraddress     (buf_wraddress[ADDR_WIDTH-1:0]),
                  .buf_wren          (buf_wren),
                  .snk_req           (snk_req),
                  .tran_len          (tran_len[ADDR_WIDTH-1:0]),
                  // Inputs
                  .snk_clock         (snk_clock),
                  .snk_reset         (snk_reset),
                  .snk_data          (snk_data[DATA_WIDTH-1:0]),
                  .snk_sop           (snk_sop),
                  .snk_eop           (snk_eop),
                  .snk_valid         (snk_valid),
                  .src_ack           (src_ack));

  buffer_dpram #(
                 .DATA_WIDTH (DATA_WIDTH),
                 .ENTRIES    (MAX_LENGTH)
  )
  buffer_dpram_ins (
                    // Outputs
                    .q                  (buf_q),
                    // Inputs
                    .data               (buf_data),
                    .rdaddress          (buf_rdaddress),
                    .rdclock            (src_clock),
                    .wraddress          (buf_wraddress),
                    .wrclock            (snk_clock),
                    .wren               (buf_wren),
                    .rden               (buf_rden));

  sort_out_if #(
                .DATA_WIDTH (DATA_WIDTH),
                .MAX_LENGTH (MAX_LENGTH)
  )
  sort_out_if_ins (/*AUTOINST*/
                   // Outputs
                   .src_data            (src_data[DATA_WIDTH-1:0]),
                   .src_sop             (src_sop),
                   .src_eop             (src_eop),
                   .src_valid           (src_valid),
                   .buf_rdaddress       (buf_rdaddress[ADDR_WIDTH-1:0]),
                   .src_ack             (src_ack),
                   .buf_rden            (buf_rden),
                   // Inputs
                   .src_clock           (src_clock),
                   .src_reset           (src_reset),
                   .buf_q               (buf_q[DATA_WIDTH-1:0]),
                   .snk_req             (snk_req),
                   .tran_len            (tran_len[ADDR_WIDTH-1:0]));

endmodule // sort_engine_top
