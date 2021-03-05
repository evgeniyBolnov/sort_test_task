module sync(
    input SignalIn,
    input clkB,
    output SignalOut_clkB
);

// two-stages shift-register to synchronize SignalIn to the clkB clock domain
reg [1:0] SyncA_clkB;
always @(posedge clkB) SyncA_clkB[0] <= SignalIn;   
always @(posedge clkB) SyncA_clkB[1] <= SyncA_clkB[0];   

assign SignalOut_clkB = SyncA_clkB[1];  // new signal synchronized to (=ready to be used in) clkB domain
endmodule