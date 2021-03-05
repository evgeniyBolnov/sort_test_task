module sync_r2w #(parameter ADDRSIZE = 4)  
(
output reg [ADDRSIZE:0] wq2_rptr,   
input      [ADDRSIZE:0] rptr,   
input                   wclk, wrst_n);  

reg [ADDRSIZE:0] wq1_rptr;  

always @(posedge wclk or negedge wrst_n)    
    if (!wrst_n) 
        {wq2_rptr,wq1_rptr} <= 0;
    else         
        {wq2_rptr,wq1_rptr} <= {wq1_rptr,rptr};

endmodule

module sync_w2r #(parameter ADDRSIZE = 4)  
(
output reg [ADDRSIZE:0] rq2_wptr,   
input      [ADDRSIZE:0] wptr,   
input                   rclk, rrst_n);  

reg [ADDRSIZE:0] rq1_wptr;  

always @(posedge rclk or negedge rrst_n)    
    if (!rrst_n) 
        {rq2_wptr,rq1_wptr} <= 0;    
    else         
        {rq2_wptr,rq1_wptr} <= {rq1_wptr,wptr};

endmodule