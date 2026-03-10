module core #(                             //Don't modify interface
	parameter ADDR_W = 32,
	parameter INST_W = 32,
	parameter DATA_W = 32
)(
	input                   i_clk,
	input                   i_rst_n,
	output reg [ ADDR_W-1 : 0 ] o_i_addr,
	input  [ INST_W-1 : 0 ] i_i_inst,
	output reg                 o_d_wen,
	output reg [ ADDR_W-1 : 0 ] o_d_addr,
	output reg [ DATA_W-1 : 0 ] o_d_wdata,
	input  [ DATA_W-1 : 0 ] i_d_rdata,
	output reg [        1 : 0 ] o_status,
	output reg                 o_status_valid
);

//fsm states 
localparam [2:0] ST_FETCH   = 3'd0;
localparam [2:0] ST_DECODE  = 3'd1;
localparam [2:0] ST_EXECUTE = 3'd2;
localparam [2:0] ST_MEMORY  = 3'd3;
localparam [2:0] ST_WBACK   = 3'd4;
localparam [2:0] ST_NEXTPC  = 3'd5;
localparam [2:0] ST_DONE    = 3'd6;


// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
// ---- Add your own wires and registers here if needed ---- //
reg [2:0] state, next_state;

reg [31:0] pc, pc_next;
reg [31:0] inst_reg;

reg [31:0] alu_result_r;
reg        zero_r;
reg        alu_overflow_r;

wire [5:0]  opcode = inst_reg[31:26];
wire [4:0]  rs     = inst_reg[25:21];
wire [4:0]  rt     = inst_reg[20:16];
wire [4:0]  rd     = inst_reg[15:11];
wire [15:0] immed  = inst_reg[15:0];

wire [31:0] pc_plus4 = pc + 32'd4;

////////////Control Unit //////////////////////////////////////////
wire        reg_dst;
wire        alu_src;
wire        mem_to_reg;
wire        reg_write;
wire        mem_read;
wire        mem_write;
wire        branch;
wire        branch_type;

wire [3:0]  alu_opcode;
wire [1:0]  instruction_RI;

control_unit u_control_unit (
    .opcode        (opcode),
    .reg_dst       (reg_dst),
    .alu_src       (alu_src),
    .mem_to_reg    (mem_to_reg),
    .reg_write     (reg_write),
    .mem_read      (mem_read),
    .mem_write     (mem_write),
    .branch        (branch),
    .branch_type   (branch_type),
    .alu_opcode    (alu_opcode),
    .instruction_RI(instruction_RI)
);

wire [3:0] alu_ctrl = alu_opcode;

//Reg File//
wire [31:0] rf_rs_data;
wire [31:0] rf_rt_data;

regfile u_regfile (
    .clk   (i_clk),
    .rst_n (i_rst_n),
    .ra1   (rs),
    .ra2   (rt),
    .wa    (reg_dst ? rd : rt),
    .wd    (mem_to_reg ? i_d_rdata : alu_result_r),
    .we    (reg_write && (state == ST_WBACK)),
    .rd1   (rf_rs_data),
    .rd2   (rf_rt_data)
);

//ALU//

wire [31:0] alu_result;
wire        alu_zero;
wire        alu_overflow;

wire [31:0] alu_a = (state == ST_EXECUTE) ? rf_rs_data : 32'd0;
wire [31:0] alu_b = (state == ST_EXECUTE)
                    ? (alu_src ? {16'b0, immed} : rf_rt_data)
                    : 32'd0;

alu u_alu (
    .a        (alu_a),
    .b        (alu_b),
    .alu_op   ((state == ST_EXECUTE) ? alu_ctrl : 4'd0),
    .result   (alu_result),
    .zero     (alu_zero),
    .overflow (alu_overflow)
);


// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //

// Overflow ////
wire bad_iaddr    = (|pc[31:12]) || (|pc[1:0]);
wire bad_daddr    = (mem_write || mem_to_reg) &&
                    ((|alu_result_r[31:8]) || (|alu_result_r[1:0]));
wire overflow_det = (state == ST_WBACK) &&
                    (alu_overflow_r || bad_iaddr || bad_daddr);


// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //
reg [ADDR_W-1:0] next_iaddr;
reg              next_dwen;
reg [ADDR_W-1:0] next_daddr;
reg [DATA_W-1:0] next_dwdata;
reg [1:0]        next_status;
reg              next_sv;

always @(*) begin
    next_state  = state;
    pc_next     = pc;
    next_iaddr  = o_i_addr;
    next_dwen   = 1'b0;
    next_daddr  = o_d_addr;
    next_dwdata = o_d_wdata;
    next_status = o_status;
    next_sv     = 1'b0;

    case (state)

        ST_FETCH: begin
            next_iaddr = pc;
            next_state = ST_DECODE;
        end
        ST_DECODE: begin
            next_state = ST_EXECUTE;
        end

        ST_EXECUTE: begin
            if (mem_write) begin
                next_dwen   = 1'b1;
                next_daddr  = alu_result;
                next_dwdata = rf_rt_data;
            end else if (mem_to_reg) begin
                next_daddr = alu_result;
            end
            next_state = ST_MEMORY;
        end

        // the wait cycle 
        ST_MEMORY: begin
            next_state = ST_WBACK;
        end

        ST_WBACK: begin
            case (instruction_RI)
                2'b00:   next_status = 2'd0;  // r type
                2'b01:   next_status = 2'd1;  // i type
                2'b10:   next_status = 2'd3;  // EOF
                default: next_status = 2'd0;
            endcase
            if (overflow_det) next_status = 2'd2;

            next_sv    = 1'b1;
            next_state = (overflow_det || instruction_RI == 2'b10)
                         ? ST_DONE : ST_NEXTPC;
        end

        ST_NEXTPC: begin
            if ((branch && !branch_type &&  zero_r) ||
                (branch &&  branch_type && !zero_r))
                pc_next = pc_plus4 + {14'b0, immed, 2'b00};
            else
                pc_next = pc_plus4;

            next_iaddr = pc_next;
            next_state = ST_FETCH;
        end

        ST_DONE:  next_state = ST_DONE;
        default:  next_state = ST_FETCH;
    endcase
end

// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state          <= ST_FETCH;
        pc             <= 32'd0;
        inst_reg       <= 32'd0;
        alu_result_r   <= 32'd0;
        zero_r         <= 1'b0;
        alu_overflow_r <= 1'b0;
        o_i_addr       <= 32'd0;
        o_d_wen        <= 1'b0;
        o_d_addr       <= 32'd0;
        o_d_wdata      <= 32'd0;
        o_status       <= 2'd0;
        o_status_valid <= 1'b0;
    end else begin
        state <= next_state;

        if (state == ST_DECODE)
            inst_reg <= i_i_inst;

        if (state == ST_EXECUTE) begin //need to save the ALU outputs 
            alu_result_r   <= alu_result;
            zero_r         <= alu_zero;
            alu_overflow_r <= alu_overflow;
        end

        if (state == ST_NEXTPC) //make sure pc is updated 
            pc <= pc_next;

        o_i_addr       <= next_iaddr;
        o_d_wen        <= next_dwen;
        o_d_addr       <= next_daddr;
        o_d_wdata      <= next_dwdata;
        o_status       <= next_status;
        o_status_valid <= next_sv;
    end
end

endmodule


