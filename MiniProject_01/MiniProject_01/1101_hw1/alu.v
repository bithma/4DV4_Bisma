module alu (
	input               i_clk,
    input               i_rst_n,
    input               i_valid,
    input signed [11:0] i_data_a,
    input signed [11:0] i_data_b,
    input        [2:0]  i_inst,
    output              o_valid,
    output       [11:0] o_data,
    output              o_overflow
);
    
// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
reg  [11:0] o_data_w, o_data_r;
reg         o_valid_w, o_valid_r, v_reg; 
reg         o_overflow_w, o_overflow_r;  
// ---- Add your own wires and registers here if needed ---- //
reg signed [31:0] accum_r; 
reg signed [31:0] accum_w; 
reg signed [12:0] sum13;
reg signed [11:0] reg_a, reg_b;
reg signed [11:0] abs_a,  abs_b;
reg signed [31:0] full_product, scaled; 
reg [2:0] inst_reg, prev_i_inst ;
reg mac_ovf_r, mac_ovf_w;
// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
assign o_valid = o_valid_r;
assign o_data = o_data_r;
assign o_overflow = o_overflow_r;
// ---- Add your own wire data assignments here if needed ---- //

   // assign  abs_a = (i_data_a < 0) ? -i_data_a : i_data_a;
// put these near the top with your other regs/wires

// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //
always@(*) begin
mac_ovf_w = mac_ovf_r;
if (v_reg && prev_i_inst == 3'b011 && inst_reg != 3'b011)
  mac_ovf_w = 1'b0; 

    o_data_w = 12'b0; 
    o_overflow_w = 1'b0;
    o_valid_w = 1'b0; 
    accum_w = accum_r;
    if (v_reg)begin //i_valid) begin
    o_valid_w = 1'b1;
    case(inst_reg)
	3'b000: begin 
	    	o_data_w = i_data_a + i_data_b; 
	   	if ((i_data_a[11] == i_data_b[11]) && (o_data_w[11] != i_data_a[11] )) begin
		   o_overflow_w = 1'b1; 
   		end 
 	end  
  	3'b001: begin 
  		o_data_w = i_data_a - i_data_b;	
          	if ((i_data_a[11] != i_data_b[11]) && (o_data_w[11] != i_data_a[11] )) begin
                   o_overflow_w = 1'b1;
   		end
   	end
      3'b010: begin
  	full_product  = ($signed(reg_a) * $signed(reg_b));
  	full_product  = full_product + 32'sd16;
  	full_product  = full_product >>> 5;

  	o_data_w = full_product[11:0];

  	if (full_product > 32'sd2047 || full_product < -32'sd2048)
    	o_overflow_w = 1'b1;
	end

	3'b011: begin
	full_product = $signed(reg_a) * $signed(reg_b);

  	scaled = (full_product + 32'sd16) >>> 5;   

  	if (prev_i_inst != 3'b011) begin
   	 accum_w   = scaled;
    	mac_ovf_w = 1'b0;
  	end else begin
    	accum_w = accum_r + scaled;
  	end

  	o_data_w = accum_w[11:0];

  	if ($signed(accum_w) > 32'sd2047 || $signed(accum_w) < -32'sd2048)
    	mac_ovf_w = 1'b1;

	  o_overflow_w = mac_ovf_w;
	end

	3'b100: o_data_w = ~(i_data_a ^ i_data_b); 

	3'b101: o_data_w =  (i_data_a > 12'sd0) ? i_data_a : 12'sd0; 
	3'b110: begin 
	
		sum13 = i_data_a + i_data_b;
		o_data_w = sum13  >>> 1 ;
	end 	
	3'b111: begin

        abs_a = i_data_a[11] ? -i_data_a : i_data_a;
  	abs_b = i_data_b[11] ? -i_data_b : i_data_b;	
	o_data_w = (abs_a > abs_b) ? abs_a : abs_b; 

	end

	default: o_data_w = 0;	
	endcase 
	end	
end 
// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //
always@(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        o_data_r <= 0;
        o_overflow_r <= 0;
        o_valid_r <= 0;
	accum_r <= 0; 
	prev_i_inst <= 3'b000;
	mac_ovf_r <= 1'b0; 
    end else begin
	o_valid_r <= v_reg; 
	if (v_reg) begin 
        o_data_r <= o_data_w;
        o_overflow_r <= o_overflow_w;
        o_valid_r <= o_valid_w; 
	accum_r <= accum_w;
      	prev_i_inst <= inst_reg;	
end
end
	if (v_reg && inst_reg == 3'b011) 
	accum_r <= accum_w;
if (v_reg) begin 
	if (inst_reg == 3'b011)
      mac_ovf_r <= mac_ovf_w;
    else
      mac_ovf_r <= 1'b0;  
    end
end

/*always@(negedge i_clk or negedge i_rst_n)begin 

	if (!i_rst_n) begin 
		v_reg <= 0; 
	end else begin 
	v_reg <= i_valid;
	if (i_valid) begin 
	reg_a <= i_data_a; 
	reg_b <= i_data_b;
       inst_reg <= i_inst; 	
end
end
end*/

always @(negedge i_clk or negedge i_rst_n) begin
  if (!i_rst_n) begin
    v_reg    <= 1'b0;
    reg_a    <= 12'sd0;
    reg_b    <= 12'sd0;
    inst_reg <= 3'd0;
  end else begin
    v_reg <= i_valid;
    if (i_valid) begin
      reg_a    <= i_data_a;
      reg_b    <= i_data_b;
      inst_reg <= i_inst;
    end
  end
end
endmodule 
