//                              -*- Mode: Verilog -*-
// Filename        : sort_in_if.v
// Description     : pass stream data to sort chain,
//                   write sorted values to dpram & hanshake with out interface
// Status          : Unknown, Use with caution!

module sort_in_if (/*AUTOARG*/
  // Outputs
  snk_ready, buf_data, buf_wraddress, buf_wren, snk_req, tran_len,
  // Inputs
  snk_clock, snk_reset, snk_data, snk_sop, snk_eop, snk_valid, src_ack
  ) ;

  `include "log2.inc"

  parameter  DATA_WIDTH = 16;
  parameter  MAX_LENGTH = 256;
  localparam ADDR_WIDTH = alt_clogb2(MAX_LENGTH);


  // input stream interface
  input                  snk_clock;
  input                  snk_reset;
  input [DATA_WIDTH-1:0] snk_data;
  input                  snk_sop;
  input                  snk_eop;
  input                  snk_valid;
  output                 snk_ready;

  // dual port ram interface
  output [DATA_WIDTH-1:0] buf_data;
  output [ADDR_WIDTH-1:0] buf_wraddress;
  output                  buf_wren;

  // req/ack retiming
  input                   src_ack;
  output                  snk_req;

  // transaction length
  output [ADDR_WIDTH-1:0] tran_len;

  // transaction length
  reg [ADDR_WIDTH-1:0] length;
  reg [ADDR_WIDTH-1:0] len_r;
  reg                  valid_length;

  // buffer level ready to transmit
  reg [ADDR_WIDTH-1:0] watermark;

  // dpram address pointer
  reg [ADDR_WIDTH-1:0] buf_addr_p;

  reg  sort_clk_en;
  wire sort_push;

  reg  ack_mstb;
  reg  snk_ack;
  reg  req;
  wire busy;

  localparam [1:0]
    ST_IDLE     = 'h0,
    ST_WR_DATA  = 'h1,
    ST_RD_DATA  = 'h2,
    ST_WAIT_ACK = 'h3;

  reg [1:0] state;
  reg [1:0] next_state;

  assign snk_ready = ( state == ST_IDLE ) || ( state == ST_WR_DATA );

  // sort chain update
  always @(*)
    case( state )
      ST_IDLE:     sort_clk_en = ( snk_sop & snk_valid );
      ST_WR_DATA:  sort_clk_en = snk_valid;
      ST_RD_DATA:  sort_clk_en = 1'b1;
      ST_WAIT_ACK: sort_clk_en = 1'b0;
      default:     sort_clk_en = 1'b0;
    endcase // case ( state )

  // push or pop data to/from sort chain
  assign sort_push = ( snk_sop || ( state == ST_WR_DATA ) ) && snk_valid;

  // ack retiming
  always @( posedge snk_clock )
    { snk_ack, ack_mstb } <= { ack_mstb, src_ack };

  // update transaction length
  always @( posedge snk_clock or posedge snk_reset )
    if( snk_reset )
      valid_length <= 1'b0;
    else
      begin
        if( ( !busy ) && ( !valid_length ) &&
            ( buf_addr_p == watermark ) && ( state == ST_RD_DATA ) )
          begin
            len_r        <= length;
            valid_length <= 1'b1;
          end
        else if ( snk_ack )
          valid_length <= 1'b0;
      end

  // request transmit
  always @( posedge snk_clock or posedge snk_reset )
    if( snk_reset )
      req <= 1'b0;
    else
      begin
        if( ( !busy ) && ( valid_length ) )
          req <= 1'b1;
        else if ( snk_ack )
          req <= 1'b0;
      end

  assign busy = ( req ) || ( snk_ack );

  assign snk_req  = req;
  assign tran_len = len_r;

  always @( posedge snk_clock )
    if( ( state == ST_IDLE ) || snk_ack )
      length <= 0;
    else
      length <= ( ( state == ST_WR_DATA ) && snk_valid ) ? ( length + 1'b1 ) : length;

  always @( posedge snk_clock )
    if( ( ( state == ST_WR_DATA ) && snk_eop ) ||
        ( state == ST_RD_DATA ) )
      begin
        // approximate value of clock ratio 50/133
        // !!! replace with fractional multiplier if arbitrary ratio is needed
        watermark <= ( length >> 1 ) + ( length >> 3 ) + ( length >> 7 );
      end
    else
      watermark <= 0;

  always @( posedge snk_clock )
    if( state == ST_RD_DATA )
      buf_addr_p <= ( buf_addr_p < length ) ? ( buf_addr_p + 1'b1 ) : buf_addr_p;
    else
      buf_addr_p <= 0;

  // write sorted data to dpram
  assign buf_wren      = ( state == ST_RD_DATA );
  assign buf_wraddress = buf_addr_p;

  //
  // receive FSM
  //
  always @( posedge snk_clock )
    if( snk_reset )
      state <= ST_IDLE;
    else
      state <= next_state;

  always @(*)
    begin
      next_state = state;

      case( state )
        ST_IDLE:
          if( snk_sop )
            next_state = ST_WR_DATA;

        ST_WR_DATA:
          if( snk_eop )
            next_state = ST_RD_DATA;

        ST_RD_DATA:
          if( buf_addr_p == length )
            next_state = ST_WAIT_ACK;

        ST_WAIT_ACK:
          if( snk_ack )
            next_state = ST_IDLE;

        default:
          next_state = ST_IDLE;

      endcase // case (state)
    end

  sort_chain #(
               .DATA_WIDTH (DATA_WIDTH),
               .MAX_LENGTH (MAX_LENGTH),
               .DIR        ("UP")
               )
  sort_chain_ins (
                  // Outputs
                  .data_o               (buf_data),
                  // Inputs
                  .clk_i                (snk_clock),
                  .rst_i                (snk_reset),
                  .clk_en_i             (sort_clk_en),
                  .push_i               (sort_push),
                  .data_i               (snk_data)
  );

endmodule // sort_in_if
