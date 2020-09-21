module sort #(
  parameter DATA_WIDTH = 8 ,
  parameter MAX_LENGTH = 16
) (
  input                         snk_reset,
  input                         snk_clock,
  output logic                  snk_ready,
  input                         snk_valid,
  input                         snk_sop  ,
  input                         snk_eop  ,
  input        [DATA_WIDTH-1:0] snk_data ,
  input                         src_reset,
  input                         src_clock,
  output logic                  src_valid,
  output logic                  src_sop  ,
  output logic                  src_eop  ,
  output logic [DATA_WIDTH-1:0] src_data
);

  enum int unsigned { IDLE, INC, SORT, OUT, RESET } snk_state;
  enum int unsigned { NOOP, WAIT, PROCESS } src_state;

  logic [DATA_WIDTH-1:0] inter     [  MAX_LENGTH:0];
  logic                  we_inter  [  MAX_LENGTH:0];
  logic [DATA_WIDTH-1:0] stor_inter[MAX_LENGTH-1:0];

  logic [DATA_WIDTH-1:0] ram[MAX_LENGTH-1:0];

  logic [$clog2(MAX_LENGTH):0] sort_cnt;
  logic [$clog2(MAX_LENGTH):0] data_cnt;
  logic [$clog2(MAX_LENGTH):0] out_cnt ;

  logic out_complete;

  assign inter[0]    = snk_data;
  assign we_inter[0] = snk_valid;

  always_ff @(posedge src_clock or posedge src_reset)
    begin
      if(src_reset)
        begin
          src_valid    <= '0;
          src_sop      <= '0;
          src_eop      <= '0;
          src_data     <= '0;
          out_cnt      <= '0;
          out_complete <= '0;
          src_state    <= NOOP;
        end
      else
        begin
          case (src_state)
            WAIT :
              begin
                src_state    <= (snk_state == OUT ) ? PROCESS : WAIT;
                src_valid    <= '0;
                src_sop      <= '0;
                src_eop      <= '0;
                src_data     <= '0;
                out_cnt      <= '0;
                out_complete <= '0;
              end
            PROCESS :
              begin
                src_state    <= (out_cnt == data_cnt ) ? NOOP : PROCESS;
                out_cnt      <= out_cnt + 1'b1;
                src_data     <= ram[out_cnt];
                src_sop      <= ( out_cnt == 0 );
                src_eop      <= ( out_cnt == data_cnt );
                out_complete <= ( out_cnt == data_cnt );
                src_valid    <= 1'b1;
              end
            default :
              begin
                src_state    <= (snk_state == SORT ) ? WAIT : NOOP;
                src_valid    <= '0;
                src_sop      <= '0;
                src_eop      <= '0;
                src_data     <= '0;
                out_cnt      <= '0;
                out_complete <= '0;
              end
          endcase
        end
    end

  always_ff @(posedge snk_clock or posedge snk_reset)
    begin
      if(snk_reset)
        begin
          sort_cnt  <= '0;
          data_cnt  <= '0;
          snk_ready <= '1;
          snk_state <= RESET;
        end
      else
        begin
          case ( snk_state )
            IDLE :
              begin
                snk_state <= (snk_sop && snk_valid) ? INC  : IDLE;
                data_cnt  <= '0;
                sort_cnt  <= '0;
                snk_ready <= 1'b1;
              end
            INC :
              begin
                snk_state <= ( snk_eop && snk_valid ) ? ( data_cnt < MAX_LENGTH ) ? SORT : OUT : INC;
                data_cnt  <= data_cnt + 1'b1;
                snk_ready <= ~( snk_eop && snk_valid );
              end
            SORT :
              begin
                snk_state     <= (sort_cnt > data_cnt + 1) || ( data_cnt > MAX_LENGTH ) ? OUT  : SORT;
                sort_cnt      <= sort_cnt + 1'b1;
                snk_ready     <= 0;
                ram[sort_cnt] <= stor_inter[sort_cnt];
              end
            OUT :
              begin
                snk_state <= (src_state == NOOP) ? IDLE : OUT;
                if ( out_complete )
                  snk_ready <= 1'b1;
              end
            default :
              begin
                snk_state <= IDLE;
                sort_cnt  <= '0;
                data_cnt  <= '0;
                snk_ready <= '1;
              end
          endcase
        end
    end

  genvar i;

  generate
    for (i = 0; i < MAX_LENGTH; i++)
      begin : sort_queue
        sort_cell #(
          .DATA_WIDTH(DATA_WIDTH)
        ) sort_cell_inst (
          .reset       (snk_reset || src_reset),
          .empty       (snk_state == OUT      ),
          .wr_clk      (snk_clock             ),
          .we          (we_inter[i]           ),
          .wr_data     (inter[i]              ),
          .rd_data     (inter[i+1]            ),
          .storage_data(stor_inter[i]         ),
          .we_o        (we_inter[i+1]         )
        );
      end
  endgenerate

endmodule

module sort_cell #(
  parameter DATA_WIDTH = 8
) (
  input                         reset       ,
  input                         empty       ,
  input                         wr_clk      ,
  input                         we          ,
  input        [DATA_WIDTH-1:0] wr_data     ,
  output logic [DATA_WIDTH-1:0] storage_data,
  output logic [DATA_WIDTH-1:0] rd_data     ,
  output logic                  we_o
);

  always_ff @(posedge wr_clk or posedge reset)
    begin
      if(reset)
        begin
          storage_data <= {DATA_WIDTH{1'b1}};
          rd_data      <= {DATA_WIDTH{1'b1}};
        end
      else
        begin
          if (empty)
            begin
              storage_data <= {DATA_WIDTH{1'b1}};
              rd_data      <= {DATA_WIDTH{1'b1}};
            end
          else
            begin
              if ( we )
                begin
                  if( wr_data < storage_data )
                    begin
                      storage_data <= wr_data;
                      rd_data      <= storage_data;
                    end
                  else
                    rd_data <= wr_data;
                end
              we_o <= we;
            end
        end
    end

endmodule