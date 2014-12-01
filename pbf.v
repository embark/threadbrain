
//=======================================================
//  This code is generated by Terasic System Builder
//=======================================================

module pbf(

	//////////// LED //////////
	LEDG,
	LEDR,

	//////////// KEY //////////
	CPU_RESET_n,
	KEY,

	//////////// SW //////////
	SW,

	//////////// SEG7 //////////
	HEX0,
	HEX1,
	HEX2,
	HEX3 
);

//=======================================================
//  PARAMETER declarations
//=======================================================


//=======================================================
//  PORT declarations
//=======================================================

//////////// LED //////////
output		     [7:0]		LEDG;
output		     [9:0]		LEDR;

//////////// KEY //////////
input 		          		CPU_RESET_n;
input 		     [3:0]		KEY;

//////////// SW //////////
input 		     [9:0]		SW;

//////////// SEG7 //////////
output		     [6:0]		HEX0;
output		     [6:0]		HEX1;
output		     [6:0]		HEX2;
output		     [6:0]		HEX3;




//=======================================================
//  Structural coding
//=======================================================
wire clk = ~KEY[0];

parameter NCORES = 2;

// Shared wires
wire stall [NCORES];

// Fetch <-> ALU
wire branch_en [NCORES];
wire [15:0] branch_val [NCORES];

// Fetch <-> ROM
wire [15:0] fetch_addr [NCORES];
wire [15:0] fetch_data [NCORES];

// Fetch <-> Select
wire [15:0] select_ins [NCORES];

// Select <-> ALU
wire [15:0] ptr_select [NCORES];
wire [15:0] alu_ins [NCORES];
wire [15:0] alu_val [NCORES];

// Select <-> RAM
wire ld_ens [NCORES+1]; // NOTE: we never use the final value.
assign ld_ens[0] = 1'b0;
wire [15:0] ram_ld_data;
wire [15:0] ram_ld_addr = ld_addrs[1];// TODO, switch to NCORES
wire [15:0] ld_addrs [NCORES+1];
assign ld_addrs[0] = 16'hdead;
wire st_en = st_ens[1]; // TODO, switch to NCORES
wire st_ens [NCORES+1];
assign st_ens[0] = 1'b0;
wire [15:0] ram_st_data = st_datas[1]; // TODO, switch to NCORES
wire [15:0] st_datas [NCORES+1];
assign st_datas[0] = 16'hdead;
wire [15:0] ram_st_addr = st_addrs[1]; // TODO, switch to NCORES
wire [15:0] st_addrs [NCORES+1];
assign st_addrs[0] = 16'h0000;

// ALU <-> WB
wire [15:0] wb_val [NCORES];
wire wb_en [NCORES];
wire [15:0] ptr_wb [NCORES];

// Forking context
// valid, ptr, startaddr
wire [NCORES*(1+16+16)-1:0] fork_cxt [NCORES+1];
assign fork_cxt[0] = fork_cxt_reg;
wire [NCORES*(1+16+16)-1:0] fork_cxt_cores = fork_cxt[1]; // read by cores
wire [NCORES-1:0] core_ens_fork [NCORES+1];
assign core_ens_fork[0] = core_ens;// TODO connect forks to each other
wire [NCORES-1:0] core_ens_select = core_ens_fork[1]; // TODO, switch to N
wire [NCORES-1:0] core_ens_fetch;

// Printing
wire [15:0] print [NCORES];

// Registers
wire [NCORES*(1+1+1+16+16)-1:0] rf [2*NCORES]; 
reg  [NCORES*(1+1+1+16+16)-1:0] rf_reg;
reg  [NCORES-1:0] core_ens;
reg  [NCORES*(1+16+16)-1:0] fork_cxt_reg;


// TODO: consider letting +++++ work

genvar i;
generate
    for (i=0; i<1; i=i+1) begin : MAKE_CORES
        fetch(.clk(clk), .core_en(core_ens_fetch[i]), .stall(stall[i]), 
              .branch_en(branch_en[i]), .branch_val(branch_val[i]),
              .fetch_addr(fetch_addr[i]), .fetch_data(fetch_data[i]), 
              .ins(select_ins[i]),
              .fork_cxt(fork_cxt_cores[i]));

        select #(NCORES) 
                (.ins(select_ins[i]), .ptr(ptr_select[i]), 
                 .clk(clk), .stall(stall[i]),
                 .out_ins(alu_ins[i]), .branch_en(branch_en[i]), 
                 .val(alu_val[i]),
                 .ld_en_in(ld_ens[i]), .ld_en_out(ld_ens[i+1]), 
                 .ld_data_in(ram_ld_data), 
                 .ld_addr_in(ld_addrs[i]), .ld_addr_out(ld_addrs[i+1]), 
                 .st_en_in(st_ens[i]), .st_en_out(st_ens[i+1]),
                 .st_data_in(st_datas[i]), .st_data_out(st_datas[i+1]), 
                 .st_addr_in(st_addrs[i]), .st_addr_out(st_addrs[i+1]),
                 .core_en_in(core_ens_select[i]), 
                 .core_en_out(core_ens_fetch[i]),
                 .rf_in(rf[0]), .rf_out(rf[1]));

        alu(.clk(clk), .ins_in(alu_ins[i]), 
            .val_in(alu_val[i]), .val_out(wb_val[i]),
            .wb_en(wb_en[i]), .ptr_select(ptr_select[i]), .ptr_wb(ptr_wb[i]),
            .branch_val(branch_val[i]), .branch_en(branch_en[i]), 
            .print(print[i]),
            .fork_cxt(fork_cxt_cores[i]));

        fork_em #(NCORES)
                (.clk(clk), .ins_in(alu_ins[i]), .ptr(ptr_wb[i]),
                 .core_ens_in(core_ens_fork[i]), 
                 .core_ens_out(core_ens_fork[i+1]),
                 .fork_cxt_in(fork_cxt[0]), .fork_cxt_out(fork_cxt[1]));

        wb #(NCORES)
            (.clk(clk), .rf_in(rf_reg), .rf_out(rf[0]), 
             .val_in(wb_val[i]), .wb_en_in(wb_en[i]), .ptr_in(ptr_wb[i]));

        rom(.address(fetch_addr[i]), 
            .inclock(clk),
            .inclocken(1'b1), 
            .outclock(clk),
            .outclocken(!stall[i]),
            .q(fetch_data[i]));
    end
endgenerate

// rf[1] wb rf[0] -> rf[0] select rf[1] -> rf [1] wb

ram(.address(st_en ? ram_st_addr : ram_ld_addr),
    .clock(clk),
	.data(ram_st_data),
	.wren(st_en),
	.q(ram_ld_data));

// register file -- goes through wb, then select
always @(posedge clk) begin
    rf_reg <= rf[1];
    fork_cxt_reg <= fork_cxt[0];
    core_ens <= core_ens_fetch;
end

initial begin
    integer i;
    for (i=0; i<NCORES; i=i+1) begin
        core_ens[i] = i == 0 ? 1'b1 : 1'b0;
    end
    rf_reg <= 0;
end

/////// DEBUGGING ////////

reg [15:0] debug_disp;

always @(*) begin
    casex (SW[6:0])
        7'b00000xx: debug_disp = rf[1][SW[1:0]*(1+1+1+16+16)    +: 16];
        7'b01000xx: debug_disp = rf[1][SW[1:0]*(1+1+1+16+16)+16 +: 16];
        7'b01100xx: debug_disp = {4'b0000,
                                 3'b000,
                                 rf[1][SW[1:0]*(1+1+1+16+16)+1+1+16+16 +: 1],
                                 3'b000,
                                 rf[1][SW[1:0]*(1+1+1+16+16)+1+16+16   +: 1],
                                 3'b000,
                                 rf[1][SW[1:0]*(1+1+1+16+16)+16+16     +: 1]};
        7'b00001xx: debug_disp = rf[rf_reg][SW[1:0]*(1+1+1+16+16)    +: 16];
        7'b01001xx: debug_disp = rf[rf_reg][SW[1:0]*(1+1+1+16+16)+16 +: 16];
        7'b01101xx: debug_disp = {4'b0000,
                                 3'b000,
                                 rf[rf_reg][SW[1:0]*(1+1+1+16+16)+1+1+16+16 +: 1],
                                 3'b000,
                                 rf[rf_reg][SW[1:0]*(1+1+1+16+16)+1+16+16   +: 1],
                                 3'b000,
                                 rf[rf_reg][SW[1:0]*(1+1+1+16+16)+16+16     +: 1]};
        7'b00011xx: debug_disp = rf[0][SW[1:0]*(1+1+1+16+16)    +: 16];
        7'b01011xx: debug_disp = rf[0][SW[1:0]*(1+1+1+16+16)+16 +: 16];
        7'b01111xx: debug_disp = {4'b0000,
                                 3'b000,
                                 rf[0][SW[1:0]*(1+1+1+16+16)+1+1+16+16 +: 1],
                                 3'b000,
                                 rf[0][SW[1:0]*(1+1+1+16+16)+1+16+16   +: 1],
                                 3'b000,
                                 rf[0][SW[1:0]*(1+1+1+16+16)+16+16     +: 1]};
        7'b10000xx: debug_disp = {4'b0000,
                                  4'b0000,
                                  3'b000,stall[SW[1:0]],
                                  3'b000,branch_en[SW[1:0]]};
        7'b11000xx: debug_disp = SW[0]? ptr_select[SW[1:0]] : ptr_wb[SW[1:0]];
        7'b01110xx: debug_disp = print[SW[1:0]];
        7'b00010xx: debug_disp = SW[0] ? ram_ld_data : fetch_data[SW[1:0]];
        7'b00100xx: debug_disp = SW[0] ? ram_ld_addr : fetch_addr[SW[1:0]];
        7'b10001xx: debug_disp = SW[0] ? alu_val[SW[1:0]] : wb_val[SW[1:0]];
        7'b10011xx: debug_disp = SW[0] ? alu_ins[SW[1:0]] : select_ins[SW[1:0]];
        7'b11111xx: debug_disp = core_ens_fetch;
        default:   debug_disp = 16'h0000;
	endcase
end

seg16({1'b1, debug_disp}, {HEX3,HEX2,HEX1,HEX0});
assign LEDR[9:0] = fetch_data[SW[1:0]][15:6];

endmodule
