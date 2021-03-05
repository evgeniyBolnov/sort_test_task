
module counter_conv #(
	parameter DATA_WIDTH = 32,
	parameter MAX_LENGTH = 32
) (
	input      [(DATA_WIDTH-1):0] snk_data ,
	input                         snk_clock,
	input                         snk_reset,
	input                         snk_eop  ,
	input                         snk_sop  ,
	input                         snk_valid,
	output                        snk_ready,
	output reg [(DATA_WIDTH-1):0] src_data ,
	input                         src_clock, src_reset,
	output reg                    src_eop  ,
	output reg                    src_sop  ,
	output reg                    src_valid
);

initial src_data  = 0;
initial src_valid = 0;

localparam ADRWIDTH = $clog2(MAX_LENGTH);

localparam waiting = 2'd0;
localparam sort    = 2'd1;
localparam change  = 2'd2;
localparam check   = 2'd3;

reg [1:0] state = waiting;

//------------------Логика входного интерфейса 
reg [ADRWIDTH-1:0] incntr   = 0; //счетчик входных слов
reg                reciving = 0; //признак приема

reg [(DATA_WIDTH-1):0] inbuf = 0;

reg snk_valid_sig = 0;
reg snk_eop_sig   = 0; //буферы задержки

always @ (posedge snk_clock or posedge snk_reset)
	if(snk_reset)
		begin
			snk_valid_sig <= 1'b0;
			snk_eop_sig   <= 1'b0;
			reciving      <= 1'b0;///асинхронный сброс входного интерфейса
		end
	else
		begin
			if (snk_sop)
				begin
					reciving <= 1'b1;
					incntr   <= '0;
				end	//при получении сигнала старт
			if	(snk_eop_sig)
				reciving <= 1'b0;						//при получении сигнала энд
			snk_valid_sig <= snk_valid;snk_eop_sig<=snk_eop;
			inbuf         <= snk_data;
			if(reciving && snk_valid_sig)
				incntr <= incntr+1'b1;
		end

//----------------------Объявление памяти
reg [ADRWIDTH:0] sortcntr               ; //счетчик слов сортировки
reg [ADRWIDTH:0] outcntr  = MAX_LENGTH+1; //счетчик выходного интерфейса
reg              we_b_sig = 0           ; //сигнал записи

reg  [DATA_WIDTH-1:0] data_b_sig                                  ; //
wire [  ADRWIDTH-1:0] addr_b_sig = state==waiting?outcntr:sortcntr; //адрес слова для сортировки и выходного интерфейса

wire unsigned [DATA_WIDTH-1:0] q_b_sig;

true_dual_port_ram_dual_clock #(
	.DATA_WIDTH(DATA_WIDTH),
	.ADDR_WIDTH(ADRWIDTH  )
) true_dual_port_ram_dual_clock_inst (
	.data_a(inbuf                  ), // input [DATA_WIDTH-1:0] data_a_sig
	.data_b(data_b_sig             ), // input [DATA_WIDTH-1:0] data_b_sig
	.addr_a(incntr                 ), // input [ADDR_WIDTH-1:0] addr_a_sig
	.addr_b(addr_b_sig             ), // input [ADDR_WIDTH-1:0] addr_b_sig
	.we_a  (reciving&&snk_valid_sig), // input  we_a_sig
	.we_b  (we_b_sig               ), // input  we_b_sig
	.clk_a (snk_clock              ), // input  clk_a_sig
	.clk_b (src_clock              ), // input  clk_b_sig
	.q_a   (                       ), // output [DATA_WIDTH-1:0] q_a_sig
	.q_b   (q_b_sig                )  // output [DATA_WIDTH-1:0] q_b_sig
);

//------------------------------Логика сортировки 
reg sortend = 0; //сигнал окончания сортировки
reg[2:0]cnt=0;

reg unsigned [DATA_WIDTH-1:0] min     = '1;
reg unsigned [DATA_WIDTH-1:0] max     = '0; //буферы минимального и максимального значений
reg unsigned [DATA_WIDTH-1:0] lowbuf      ;
reg unsigned [DATA_WIDTH-1:0] highbuf     ; //буферы содержимого верхней и нижней границ сортировки
reg          [  ADRWIDTH-1:0] minadr      ;

reg[ADRWIDTH-1:0]maxadr;//буферы адресов минимального и максимального значений

reg                 mindetect                            ;
reg                 maxdetect                            ; //сигналы обнаружения наибольшего и наименьшего
reg  [ADRWIDTH-1:0] lowborder                            ; //////////////////////////////нижняя и
wire [ADRWIDTH-1:0] highborder = (MAX_LENGTH-1)-lowborder; ///верхняя границы текущей иттерации

always @ (posedge src_clock or posedge src_reset)
	if(src_reset)
		begin
			sortend   <= 1'b0;
			lowborder <= 'b0;
			min       <= '1;
			max       <= '0;////асинхронный сброс сортировки
			sortcntr  <= '0;
			state     <= waiting;cnt<=3'd0;
		end
	else
		begin
			mindetect <= q_b_sig<min;//
			maxdetect <= q_b_sig>max;//обнаружен мин/макс
			case(state)
				waiting :
					begin
						sortend   <= 1'b0;
						lowborder <= 'b0;
						min       <= '1;
						max       <= '0;
						sortcntr  <= '0;
						cnt       <= 3'd0;
						if(snk_eop)
							state <= sort;//по окончании приема
					end
				sort :
					begin// перебор значений массива от нижней до верхней границы текущей иттерации и поиск в них экстремумов
						cnt <= cnt+3'd1;
						if(sortcntr==highborder+1'b1)
							state <= check; //окончание иттерации
						if(lowborder==MAX_LENGTH>>1)
							begin
								state   <= waiting;
								sortend <= 1'b1;
							end//окончание сортировки по достижении нежней границы середины массива

						if(cnt==3'd2)
							begin ////задержка на обращение к памяти и отработку компараторов(для большей производительности при широких словах)
								if(mindetect)
									begin
										min<=q_b_sig;
										minadr<=sortcntr;
									end //запись в буферы мин/макс значений
								if(maxdetect)
									begin
										max<=q_b_sig;
										maxadr<=sortcntr;
									end //и их позиций в массиве
								sortcntr <= sortcntr+1'b1;
								cnt<=3'd0;
							end
					end
				change :
					begin
						cnt <= cnt+3'd1;
						case(cnt)
							3'd0 :
								begin
									sortcntr<=lowborder;
								end	 	//запрос слова с нижней границы
							3'd1 :
								begin
									sortcntr<=highborder;
								end	//с верхней
							3'd2 :
								begin
									lowbuf<=q_b_sig;
								end 		 	//
							3'd3 :
								begin
									we_b_sig<=1'b1;
									highbuf<=q_b_sig;
									sortcntr <= minadr;
									data_b_sig<=lowbuf;
								end//запись содержимого нижней границы в адрес мин. значения
							3'd4 :
								begin
									sortcntr<=maxadr;
									data_b_sig<=highbuf;
								end//верхней
							3'd5 :
								begin	sortcntr<=lowborder;
									data_b_sig<=min;
								end//запись мин. значения в нижнюю границу
							3'd6 :
								begin
									sortcntr<=highborder;
									data_b_sig<=max;
								end//макс. значения
							3'd7 :
								begin
									we_b_sig<=1'b0;//снятие сигнала записи
									state     <= sort; 	//возврат к перебору
									lowborder <= lowborder+1'b1;//сокращение области поиска
									sortcntr  <= lowborder+1'b1;
									min       <= '1;max<='0;	//обнуление мин. и макс. значений
								end
						endcase
					end
				check :
					begin//в случае нахождения мин/макс значений на противоположных
						if(maxadr==lowborder)
							begin
								minadr<=maxadr;
								maxadr<=minadr;
							end//границах нынешней иттерации,
						if(minadr==highborder)
							begin
								minadr<=maxadr;
								maxadr<=minadr;
							end//адреса мин и макс значений меняются местами
						state <= change;
						cnt   <= 3'd0;
					end
			endcase
		end

//-----------------------------Логика выходного интерфейса

reg snk_ready_sig = 1;
reg src_eop_sig   = 0;
reg src_sop_sig   = 0;

assign snk_ready = snk_ready_sig;

always @ (posedge src_clock or posedge src_reset)
	if(src_reset)
		begin
			snk_ready_sig <= 1'b1;
			src_eop_sig   <= 1'b0;
			src_sop_sig   <= 1'b0;//асинхронный сброс для выходного интерфейса
			outcntr       <= MAX_LENGTH+1;
			src_valid     <= 1'b0;
		end
	else
		begin
			snk_ready_sig <= snk_eop?1'b0:(src_eop?1'b1:snk_ready_sig);//
			src_eop       <= src_eop_sig;
			src_sop       <= src_sop_sig;
			if(sortend)
				outcntr <= '0;//если закончилась сортировка, то начинается передача массива на выход
			if(outcntr!=MAX_LENGTH+1)
				begin
					src_data <= q_b_sig;
					outcntr  <= outcntr+1'b1;
				end
			src_sop_sig <= outcntr==0;	//сигнал старта выхода
			src_eop_sig <= outcntr==MAX_LENGTH-1;//сигнал окончания выхода
			src_valid   <= src_sop_sig?1'b1:(src_eop?1'b0:src_valid);//сигнал достоверности выхода
		end 


endmodule