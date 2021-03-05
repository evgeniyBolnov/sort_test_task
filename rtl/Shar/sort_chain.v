//                              -*- Mode: Verilog -*-
// Filename        : sort_chain.v
// Description     : sequential sorting module, ordering set by DIR parameter
// Status          : Unknown, Use with caution!

module sort_chain (/*AUTOARG*/
  // Outputs
  data_o,
  // Inputs
  clk_i, rst_i, clk_en_i, push_i, data_i
  ) ;

  parameter DATA_WIDTH = 16;
  parameter MAX_LENGTH = 256;
  parameter DIR        = "UP";

  input clk_i;
  input rst_i;
  input clk_en_i;

  // push_i = 1 - write data
  // push_i = 0 - read data (pop)
  input push_i;

  input  [DATA_WIDTH-1:0] data_i;
  output [DATA_WIDTH-1:0] data_o;

  localparam DEPTH = (MAX_LENGTH+1)/2;

  wire [DATA_WIDTH-1:0] prev_i [0:DEPTH-1];
  wire [DATA_WIDTH-1:0] next_i [0:DEPTH-1];
  wire [DATA_WIDTH-1:0] node_o [0:DEPTH-1];

  genvar i;
  generate
    for( i = 0; i < DEPTH ; i=i+1 )
      begin : g_s_node // generate sort nodes
        sort_node #(
                   .DATA_WIDTH (DATA_WIDTH),
                   .DIR        (DIR)
        )
        sort_node_ins (
                       // Outputs
                       .node_o         (node_o[i]),
                       // Inputs
                       .prev_i         (prev_i[i]),
                       .next_i         (next_i[i]),
                       /*AUTOINST*/
                       // Inputs
                       .clk_i          (clk_i),
                       .rst_i          (rst_i),
                       .clk_en_i       (clk_en_i),
                       .push_i         (push_i));
      end

    for( i = 0; i < DEPTH-1 ; i=i+1 )
      begin : g_s_conn // generate sort nodes connection
        assign prev_i[i+1] = node_o[i];
        assign next_i[i]   = node_o[i+1];
      end
  endgenerate

  generate
    if( DIR == "UP" )
      assign next_i[DEPTH-1] = {DATA_WIDTH{1'b1}};
    else
      assign next_i[DEPTH-1] = 0;
  endgenerate

  assign prev_i[0] = data_i;
  assign data_o    = node_o[0];

endmodule // sort_chain
