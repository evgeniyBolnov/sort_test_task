//                              -*- Mode: Verilog -*-
// Filename        : sort_node.v
// Description     : comparator swap node
// Status          : Unknown, Use with caution!

module sort_node (/*AUTOARG*/
  // Outputs
  node_o,
  // Inputs
  clk_i, rst_i, clk_en_i, push_i, prev_i, next_i
  ) ;

  parameter DATA_WIDTH = 16;
  parameter DIR        = "UP";

  input clk_i;
  input rst_i;
  input clk_en_i;
  input push_i;

  // argument from previous node
  input  [DATA_WIDTH-1:0] prev_i;
  // argument from next node
  input  [DATA_WIDTH-1:0] next_i;

  output [DATA_WIDTH-1:0] node_o;

  reg    [DATA_WIDTH-1:0] hi;
  reg    [DATA_WIDTH-1:0] low;

  wire   [DATA_WIDTH-1:0] h_val;
  wire   [DATA_WIDTH-1:0] l_val;

  assign h_val = push_i ? hi     : low ;
  assign l_val = push_i ? prev_i : next_i ;

  generate
    if( DIR == "UP" )
    begin
      always @( posedge clk_i or posedge rst_i )
        if( rst_i )
          begin
            hi  <= {DATA_WIDTH{1'b1}};
            low <= {DATA_WIDTH{1'b1}};
          end
        else
          if( clk_en_i )
            begin
              hi  <= ( h_val <= l_val ) ? h_val : l_val;
              low <= ( h_val <= l_val ) ? l_val : h_val;
            end
    end
    else
    begin
      always @( posedge clk_i or posedge rst_i )
        if( rst_i )
          begin
            hi  <= 0;
            low <= 0;
          end
        else
          if( clk_en_i )
            begin
              hi  <= ( h_val >= l_val ) ? h_val : l_val;
              low <= ( h_val >= l_val ) ? l_val : h_val;
            end
    end
  endgenerate

  assign node_o = push_i ? low : hi;

endmodule // sort_node
