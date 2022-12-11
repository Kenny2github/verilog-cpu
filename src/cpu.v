`include "defines.vh"

module cpu (
	input wire i_reset,
	input wire i_clk,
	input wire i_load_addr,
	input wire i_load_data,
	input wire i_execute,
	input wire i_input_taken,
	input wire [7:0] i_data_in,
	output wire [7:0] o_data_out,
	output wire o_waiting,
	output wire o_take_input
);
	wire    m_load_addr,
			m_load_data,
			m_load_rip,
			m_load_alu,
			m_write_ram;
	wire [4:0] m_select;
	wire [7:0] m_ram, m_load_reg;
	assign o_data_out = m_ram;

	control u_control(
		.i_reset(i_reset),
		.i_clk(i_clk),
		.i_load_addr(i_load_addr),
		.i_load_data(i_load_data),
		.i_execute(i_execute),
		.i_input_taken(i_input_taken),
		.i_ram_in(m_ram),
		.o_select(m_select),
		.o_load_addr(m_load_addr),
		.o_load_data(m_load_data),
		.o_load_rip(m_load_rip),
		.o_load_alu(m_load_alu),
		.o_write_ram(m_write_ram),
		.o_waiting(o_waiting),
		.o_take_input(o_take_input),
		.o_load_reg(m_load_reg)
	);
	datapath u_datapath(
		.i_reset(i_reset),
		.i_clk(i_clk),
		.i_data_in(i_data_in),
		.i_select(m_select),
		.i_load_addr(m_load_addr),
		.i_load_data(m_load_data),
		.i_load_rip(m_load_rip),
		.i_load_alu(m_load_alu),
		.i_write_ram(m_write_ram),
		.i_load_reg(m_load_reg),
		.o_ram_out(m_ram)
	);
endmodule

module control (
	input wire i_reset,
	input wire i_clk,
	input wire i_load_addr,
	input wire i_load_data,
	input wire i_execute,
	// input wire i_take_input,
	input wire i_input_taken,
	input wire [7:0] i_ram_in,
	output reg [4:0] o_select,
	output reg o_load_addr,
	output reg o_load_data,
	output reg o_load_rip,
	output reg o_load_alu,
	output reg o_write_ram,
	output reg o_waiting,
	output reg o_take_input,
	output reg [7:0] o_load_reg
);
	reg [8:0] m_next_state, m_current_state;
	reg [2:0] m_current_cycle;

	localparam  S_LOAD_ADDR = 9'h000,
				S_LOAD_ADDR_WAIT = 9'h001,
				S_LOAD_DATA = 9'h002,
				S_LOAD_DATA_WAIT = 9'h003,
				// S_WRITE_RAM = 9'h004,
				S_PRE_EXECUTE = 9'h005,
				// S_EXECUTE = 9'h006,
				S_FETCH = 9'h007,
				S_INC_RIP = 9'h008,
				S_WRIM_WAIT = 9'h009,
				// Halt and return to instruction loading
				S_HALT = 9'h100,
				// Do nothing and proceed to next instruction
				S_NOOP = 9'h101,
				// Write physical input to memory address
				// Byte 1 is the memory address
				S_WRIM = 9'h102,
				// Unconditional jump to memory address
				// Byte 1 is the memory address
				S_JUMP = 9'h103,
				// Arithmetic operation
				// Byte 1 is the operation, where the MSB indicates
				// whether the operands are signed
				S_MATH = 9'h104;

	// state table
	always @(*) begin
		m_next_state = m_current_state;
		case (m_current_state)
			S_LOAD_ADDR: begin
				if (i_load_addr) m_next_state = S_LOAD_ADDR_WAIT;
				else if (i_execute) m_next_state = S_PRE_EXECUTE;
			end
			S_LOAD_ADDR_WAIT: if (!i_load_addr) m_next_state = S_LOAD_DATA;
			S_LOAD_DATA: if (i_load_data) m_next_state = S_LOAD_DATA_WAIT;
			S_LOAD_DATA_WAIT: if (!i_load_data) m_next_state = S_LOAD_ADDR;
			// S_WRITE_RAM: m_next_state = S_LOAD_ADDR;
			S_PRE_EXECUTE: if (!i_execute) m_next_state = S_FETCH;
			// wait until cycle 2 to let RAM catch up
			S_FETCH: if (m_current_cycle == 2) m_next_state = 9'b1_0000_0000 | {1'b0, i_ram_in};
			// wait until cycle 2 to let RAM catch up
			S_INC_RIP: if (m_current_cycle == 2) m_next_state = 9'b1_0000_0000 | {1'b0, i_ram_in};
			S_HALT: m_next_state = S_LOAD_ADDR;
			S_NOOP: m_next_state = S_INC_RIP;
			S_WRIM: if (m_current_cycle >= 3) if (i_input_taken) m_next_state = S_WRIM_WAIT;
			S_WRIM_WAIT: if (!i_input_taken) m_next_state = S_INC_RIP;
			// wait until cycle 2 to let RAM catch up
			S_JUMP: if (m_current_cycle == 2) m_next_state = S_FETCH;
		endcase
	end

	// output table
	always @(*) begin
		o_load_addr = 1'b0;
		o_load_data = 1'b0;
		o_load_rip = 1'b0;
		o_load_alu = 1'b0;
		o_write_ram = 1'b0;
		o_waiting = 1'b0;
		o_select = `SEL_D_IN;
		o_take_input = 1'b0;
		o_load_reg = 8'b0;

		case (m_current_state)
			S_LOAD_ADDR: begin
				o_select = `SEL_D_IN;
				o_load_addr = 1'b1;
				o_waiting = 1'b1;
			end
			S_LOAD_DATA: begin
				o_select = `SEL_D_IN;
				o_write_ram = 1'b1;
				o_take_input = 1'b1;
			end
			S_PRE_EXECUTE: begin
				o_select = `SEL_ZERO;
				o_load_rip = 1'b1;
				o_load_addr = 1'b1;
			end
			S_FETCH: if (m_current_cycle == 0) begin
				o_select = `SEL_RIP;
				o_load_addr = 1'b1;
			end
			S_INC_RIP: if (m_current_cycle == 0) begin
				o_select = `SEL_RIP_1;
				o_load_rip = 1'b1;
				o_load_addr = 1'b1;
			end
			S_WRIM: begin
				o_take_input = 1'b1;
				if (m_current_cycle == 0) begin
					// 1. Increment instruction pointer
					// (We could just set MAR, but then that would require
					// incrementing RIP twice after taking input)
					o_select = `SEL_RIP_1;
					o_load_rip = 1'b1;
					o_load_addr = 1'b1;
				end else if (m_current_cycle == 1) begin
					// 2. Wait for RAM
				end else if (m_current_cycle == 2) begin
					// 3. Load address from RAM
					o_select = `SEL_RAM;
					o_load_addr = 1'b1;
				end else begin
					// 4. Write input to RAM at loaded address
					o_select = `SEL_D_IN;
					o_write_ram = 1'b1;
					o_waiting = 1'b1;
					o_take_input = 1'b1;
				end
			end
			S_JUMP: begin
				if (m_current_cycle == 0) begin
					// 1. Get RAM data at RIP + 1
					o_select = `SEL_RIP_1;
					o_load_addr = 1'b1;
				end else begin
					// 2. Set instruction pointer to that data
					o_select = `SEL_RAM;
					o_load_rip = 1'b1;
				end
			end
			S_MATH: begin
				if (m_current_cycle == 0) begin
					// 1. Increment instruction pointer
					o_select = `SEL_RIP_1;
					o_load_rip = 1'b1;
					o_load_addr = 1'b1;
				end else if (m_current_cycle == 1) begin
					// 2. Wait for RAM
				end else if (m_current_cycle == 2) begin
					// 3. Write ALU output
					o_load_alu = 1'b1;
				end else if (m_current_cycle == 3) begin
					// 4. Increment again
					o_select = `SEL_RIP_1;
					o_load_rip = 1'b1;
					o_load_addr = 1'b1;
				end else if (m_current_cycle == 4) begin
					// 5. Wait for RAM
				end else if (m_current_cycle == 5) begin
					// 6.
				end
			end
		endcase
	end

	// synchronize
	always @(posedge i_clk) begin
		if (i_reset) begin
			m_current_state <= S_LOAD_ADDR;
			m_current_cycle <= 3'b0;
		end
		else begin
			if (m_current_state == m_next_state) begin
				// don't loop cycle number; stay at the max instead
				// so that cycle 0 logic doesn't re-run
				if (m_current_cycle != 3'b111) begin
					m_current_cycle <= m_current_cycle + 1;
				end
			end else begin
				m_current_cycle <= 3'b0;
			end
			m_current_state <= m_next_state;
		end
	end
endmodule

module datapath (
	input wire i_reset,
	input wire i_clk,
	input wire [7:0] i_data_in,
	input wire [4:0] i_select,
	input wire i_load_addr,
	input wire i_load_data,
	input wire i_load_rip,
	input wire i_load_alu,
	input wire i_write_ram,
	input wire [7:0] i_load_reg,
	// output wire o_take_input,
	output wire [7:0] o_ram_out
);
				// memory address register
	reg [7:0]   m_MAR,
				m_MDR,
				// instruction pointer
				m_RIP,
				// arithmetic accumulator
				m_RAX,
				// ALU flags register
				m_RFL;
	reg [7:0] m_REG[0:7];
	wire [7:0] m_ram_out;
	assign o_ram_out = m_ram_out;

	reg [7:0] bus;

	ram u_MEM0(
		.address(m_MAR),
		.clock(i_clk),
		.data(bus),
		.wren(i_write_ram),
		.q(m_ram_out)
	);

	wire [7:0] m_alu_out, m_alu_flags;

	alu u_ALU0(
		.i_A(m_REG[0]),
		.i_B(m_REG[1]),
		.i_signed(m_ram_out[7]),
		.i_op(m_ram_out[6:0]),
		.o_G(m_alu_out),
		.o_carry_out(m_alu_flags[0]),
		.o_equal(m_alu_flags[1]),
		.o_less_than(m_alu_flags[2]),
		.o_zero(m_alu_flags[3]),
		.o_one(m_alu_flags[4]),
		.o_overflow(m_alu_flags[5])
	);
	assign m_alu_flags[7:6] = 2'b0;

	always @(*) begin
		case (i_select)
			`SEL_REG0: bus = m_REG[0];
			`SEL_REG1: bus = m_REG[1];
			`SEL_REG2: bus = m_REG[2];
			`SEL_REG3: bus = m_REG[3];
			`SEL_REG4: bus = m_REG[4];
			`SEL_REG5: bus = m_REG[5];
			`SEL_REG6: bus = m_REG[6];
			`SEL_REG7: bus = m_REG[7];
			`SEL_D_IN: bus = i_data_in;
			`SEL_RAX: bus = m_RAX;
			`SEL_RAM: bus = m_ram_out;
			`SEL_RIP: bus = m_RIP;
			`SEL_RIP_1: bus = m_RIP + 8'b1;
			`SEL_ZERO: bus = 8'b0;
			default: bus = 8'b0;
		endcase
	end

	always @(posedge i_clk) begin
		if (i_reset) begin
			m_MAR <= 8'b0;
			m_MDR <= 8'b0;
			m_RIP <= 8'b0;
			m_RAX <= 8'b0;
			m_RFL <= 8'b0;
			m_REG[0] <= 8'b0;
			m_REG[1] <= 8'b0;
			m_REG[2] <= 8'b0;
			m_REG[3] <= 8'b0;
			m_REG[4] <= 8'b0;
			m_REG[5] <= 8'b0;
			m_REG[6] <= 8'b0;
			m_REG[7] <= 8'b0;
		end
		else begin
			if (i_load_addr) m_MAR <= bus;
			// if (i_load_data | i_write_ram) m_MDR <= bus;
			if (i_load_rip) m_RIP <= bus;
			if (i_load_alu) begin
				m_RAX <= m_alu_out;
				m_RFL <= m_alu_flags;
			end
			if (i_load_reg[0]) m_REG[0] <= bus;
			if (i_load_reg[1]) m_REG[1] <= bus;
			if (i_load_reg[2]) m_REG[2] <= bus;
			if (i_load_reg[3]) m_REG[3] <= bus;
			if (i_load_reg[4]) m_REG[4] <= bus;
			if (i_load_reg[5]) m_REG[5] <= bus;
			if (i_load_reg[6]) m_REG[6] <= bus;
			if (i_load_reg[7]) m_REG[7] <= bus;
		end
	end
endmodule
