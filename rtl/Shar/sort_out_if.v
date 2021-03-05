//                              -*- Mode: Verilog -*-
// Filename        : sort_out_if.v
// Description     : read data from dpram with respected watermark level & packet length,
//                   cteate output stream & handshake with input interface
// Status          : Unknown, Use with caution!

module sort_out_if (/*AUTOARG*/
  // Outputs
  src_data, src_sop, src_eop, src_valid, buf_rdaddress, buf_rden, src_ack,
  // Inputs
  src_clock, src_reset, buf_q, snk_req, tran_len
  );

  `include "log2.inc"

  parameter  DATA_WIDTH = 16;
  parameter  MAX_LENGTH = 256;
  localparam ADDR_WIDTH = alt_clogb2(MAX_LENGTH);

  input                   src_clock;
  input                   src_reset;
  output [DATA_WIDTH-1:0] src_data;
  output                  src_sop;
  output                  src_eop;
  output                  src_valid;

  // dual port ram interface
  input  [DATA_WIDTH-1:0] buf_q;
  output [ADDR_WIDTH-1:0] buf_rdaddress;
  output                  buf_rden;

  // req/ack retiming
  output src_ack;
  input  snk_req;

  // transaction length
  input [ADDR_WIDTH-1:0] tran_len;

  reg   [ADDR_WIDTH-1:0] tran_dcnt;

  reg req_mstb;
  reg src_req;
  reg src_req_d1;
  reg req_rise;
  reg ack;
  reg [1:0] data_rdy;
  reg read_valid;
  reg [ADDR_WIDTH-1:0] src_tran_len;

  localparam [1:0]
    ST_IDLE     = 'h0,
    ST_RD_DATA  = 'h1,
    ST_EOP      = 'h2,
    ST_SEND_ACK = 'h3;

  reg [1:0] state;
  reg [1:0] next_state;

  always @( posedge src_clock )
    { src_req_d1, src_req, req_mstb } <= { src_req, req_mstb, snk_req };

  // request strobe
  always @( posedge src_clock )
    req_rise <= ~src_req_d1 & src_req;

  always @( posedge src_clock )
    data_rdy <= { data_rdy[0], req_rise };

  always @( posedge src_clock )
    read_valid <= ( state == ST_RD_DATA );

  always @( posedge src_clock or posedge src_reset )
    if( src_reset )
      src_tran_len <= 0;
    else
      src_tran_len <= req_rise ? tran_len : src_tran_len;

  always @( posedge src_clock or posedge src_reset )
    if( src_reset )
      tran_dcnt <= 0;
    else
      begin
        if( state == ST_IDLE )
          tran_dcnt <= 0;
        else
          tran_dcnt <= ( state == ST_RD_DATA ) ? ( tran_dcnt + 1'b1 ) : tran_dcnt;
      end

  assign buf_rdaddress = tran_dcnt;

  always @( posedge src_clock )
    ack <= ( state == ST_SEND_ACK ) ? src_req : 0;

  assign src_ack  = ack;
  assign buf_rden = ( req_rise ) || ( state == ST_RD_DATA );

  //
  // send FSM
  //
  always @( posedge src_clock )
    if( src_reset )
      state <= ST_IDLE;
    else
      state <= next_state;

  always @(*)
    begin
      next_state = state;

      case( state )
        ST_IDLE:
          if( req_rise )
            next_state = ST_RD_DATA;

        ST_RD_DATA:
          if( tran_dcnt == src_tran_len )
            next_state = ST_EOP;

        ST_EOP:
          next_state = ST_SEND_ACK;

        ST_SEND_ACK:
          if ( !src_req )
            next_state = ST_IDLE;

        default:
          next_state = ST_IDLE;

      endcase // case (state)
    end

  //
  // single pipeline stage
  //
  reg  [DATA_WIDTH+1:0] out_payload;
  wire [DATA_WIDTH+1:0] in_payload;
  reg                   out_valid;
  wire                  in_valid;

  wire [DATA_WIDTH-1:0] out_data;
  wire                  out_sop;
  wire                  out_eop;

  assign {src_data, src_sop, src_eop} = out_payload;
  assign in_payload = {out_data, out_sop, out_eop};
  assign src_valid = out_valid;

  assign out_data = buf_q;
  assign out_sop  = data_rdy[1];
  assign in_valid = read_valid;

  assign out_eop  = ( state == ST_EOP );
  always @( posedge src_clock or posedge src_reset )
    if( src_reset )
      begin
        out_payload <= 0;
        out_valid   <= 0;
      end
    else
      if( in_valid )
        begin
          out_payload <= in_payload;
          out_valid   <= 1'b1;
        end
      else
       begin
        out_payload[0] <= in_payload[0];
        out_valid      <= 0;
       end

endmodule // sort_out_if
