module  Cell_Compare #(parameter HBIT= 8)(
input clk,
input hold,
input is_input,
input [HBIT-1:0] in_prev,
input [HBIT-1:0] in_next,
output [HBIT-1:0] out
);

reg [HBIT-1:0] higher;
reg [HBIT-1:0] lower;
assign out = is_input ? lower : higher;

wire [HBIT-1:0] cand_h;
wire [HBIT-1:0] cand_l;


assign cand_h= is_input ? higher : lower;
assign cand_l= is_input ? in_prev : in_next;

always@(posedge clk )
    if (~hold)
        begin
            higher <= ( cand_h >= cand_l ) ? cand_h : cand_l;
            lower  <= ( cand_h >= cand_l ) ? cand_l : cand_h;
        end
    else 
        begin 
            higher<= 'h0;
            lower<='h0;
        end
endmodule