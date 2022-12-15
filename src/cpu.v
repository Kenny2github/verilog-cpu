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
			m_load_rax,
			m_write_ram;
	wire [4:0] m_select;
	wire [7:0] m_ram, m_load_reg, m_alu_flags;
	assign o_data_out = m_ram;

	control u_control(
		.i_reset(i_reset),
		.i_clk(i_clk),
		.i_load_addr(i_load_addr),
		.i_load_data(i_load_data),
		.i_execute(i_execute),
		.i_input_taken(i_input_taken),
		.i_ram_in(m_ram),
		.i_alu_flags(m_alu_flags),
		.o_select(m_select),
		.o_load_addr(m_load_addr),
		.o_load_data(m_load_data),
		.o_load_rip(m_load_rip),
		.o_load_alu(m_load_alu),
		.o_load_rax(m_load_rax),
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
		.i_load_rax(m_load_rax),
		.i_write_ram(m_write_ram),
		.i_load_reg(m_load_reg),
		.o_alu_flags(m_alu_flags),
		.o_ram_out(m_ram)
	);
endmodule

module control (
	input wire i_reset,
	input wire i_clk,
	input wire i_load_addr,
	input wire i_load_data,
	input wire i_execute,
	input wire i_input_taken,
	input wire [7:0] i_ram_in,
	input wire [7:0] i_alu_flags,
	output reg [4:0] o_select,
	output reg o_load_addr,
	output reg o_load_data,
	output reg o_load_rip,
	output reg o_load_alu,
	output reg o_load_rax,
	output reg o_write_ram,
	output reg o_waiting,
	output reg o_take_input,
	output reg [7:0] o_load_reg
);
	reg [8:0] m_next_state, m_current_state;
	reg [2:0] m_current_cycle;

	reg [7:0] m_reg_select, m_next_reg_select;
	reg m_load_reg_select;

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
				// Byte 2 is the register code for the 2nd operand
				// (the 1st operand is always RAX)
				S_MATH = 9'h104,
				// Load register from memory
				// Byte 1 is the register code to write to
				// Byte 2 is the memory address to fetch from
				S_LDFM = 9'h105,
				// Load register from immediate
				// Byte 1 is the register code to write to
				// Byte 2 is the immediate value to write
				S_LDFI = 9'h106,
				// Load register from register memory address
				// Byte 1 is the register code to write to
				// Byte 2 is the register code
				// containing the memory address to fetch from
				S_LDFR = 9'h107,
				// Load register from register
				// Byte 1 is the register code to write to
				// Byte 2 is the register code to write from
				S_CPFR = 9'h108,
				// Store register to memory
				/**
				 * Note that there is no "store immediate".
				 * This is because there's no good way to implement it
				 * without adding dedicated "instruction argument" registers.
				 */
				// Byte 1 is the register code to write from
				// Byte 2 is the memory address to write to
				S_STOM = 9'h109,
				// Jump if the ALU zero flag is not set
				// Byte 1 is the memory address to jump to
				S_JINZ = 9'h10a,
				// Jump if the ALU equals flag is set
				// Byte 1 is the memory address to jump to
				S_JIEQ = 9'h10b,
				// Jump if the ALU less than flag is set
				// Byte 1 is the memory address to jump to
				S_JILT = 9'h10c,
				// Jump if the ALU flags equals and less than are not set
				// Byte 1 is the memory address to jump to
				S_JIGT = 9'h10d,
				// Pause to let the user see the data at the specified addr
				// Byte 1 is the memory address to show
				S_SHOM = 9'h10e,
				S_ZZZZ = 9'h1ff; // dummy instruction to make diffs look nicer

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
			S_PRE_EXECUTE: if (!i_execute) m_next_state = S_FETCH;
			S_FETCH: if (m_current_cycle == 2) m_next_state = 9'b1_0000_0000 | {1'b0, i_ram_in};
			S_INC_RIP: if (m_current_cycle == 2) m_next_state = 9'b1_0000_0000 | {1'b0, i_ram_in};
			S_HALT: m_next_state = S_LOAD_ADDR;
			S_NOOP: m_next_state = S_INC_RIP;
			S_WRIM: if (m_current_cycle >= 3) if (i_input_taken) m_next_state = S_WRIM_WAIT;
			S_WRIM_WAIT: if (!i_input_taken) m_next_state = S_INC_RIP;
			S_JUMP: if (m_current_cycle == 2) m_next_state = S_FETCH;
			S_LDFM, S_LDFR: if (m_current_cycle == 5) m_next_state = S_INC_RIP;
			S_MATH, S_LDFI, S_CPFR: if (m_current_cycle == 3) m_next_state = S_INC_RIP;
			S_STOM: if (m_current_cycle == 4) m_next_state = S_INC_RIP;
			S_JINZ: begin
				if (m_current_cycle == 0 && i_alu_flags[`ZERO_BIT]) m_next_state = S_INC_RIP;
				else if (m_current_cycle == 2) m_next_state = S_FETCH;
			end
			S_JIEQ: begin
				if (m_current_cycle == 0 && !i_alu_flags[`EQUAL_BIT]) m_next_state = S_INC_RIP;
				else if (m_current_cycle == 2) m_next_state = S_FETCH;
			end
			S_JILT: begin
				if (m_current_cycle == 0 && !i_alu_flags[`LESS_THAN_BIT]) m_next_state = S_INC_RIP;
				else if (m_current_cycle == 2) m_next_state = S_FETCH;
			end
			S_JIGT: begin
				if (m_current_cycle == 0 && (
					i_alu_flags[`LESS_THAN_BIT] || i_alu_flags[`EQUAL_BIT]
				)) m_next_state = S_INC_RIP;
				else if (m_current_cycle == 2) m_next_state = S_FETCH;
			end
			S_SHOM: if (m_current_cycle >= 3) if (i_input_taken) m_next_state = S_WRIM_WAIT;
		endcase
	end

	// output table
	always @(*) begin
		o_load_addr = 1'b0;
		o_load_data = 1'b0;
		o_load_rip = 1'b0;
		o_load_alu = 1'b0;
		o_load_rax = 1'b0;
		o_write_ram = 1'b0;
		o_waiting = 1'b0;
		o_select = `SEL_D_IN;
		o_take_input = 1'b0;
		o_load_reg = 8'b0;
		m_load_reg_select = 1'b0;
		m_next_reg_select = 8'b0;

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
				end else if (m_current_cycle == 1) begin
					// 2. Wait for RAM
				end else begin
					// 3. Set instruction pointer to that data
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
					// Also increment RIP again while waiting
					o_select = `SEL_RIP_1;
					o_load_rip = 1'b1;
					o_load_addr = 1'b1;
				end else if (m_current_cycle == 2) begin
					// 3. Choose register based on RAM output
					m_next_reg_select = i_ram_in;
					m_load_reg_select = 1'b1;
				end else begin
					// 4. Choose register and write ALU output
					// ALU opcode is always from RAM output
					// RAX and RFL are always set by ALU output
					o_select = m_reg_select;
					o_load_alu = 1'b1;
				end
			end
			S_LDFM: begin
				if (m_current_cycle == 0) begin
					// 1. Increment instruction pointer
					o_select = `SEL_RIP_1;
					o_load_rip = 1'b1;
					o_load_addr = 1'b1;
				end else if (m_current_cycle == 1) begin
					// 2. Wait for RAM
					// Also increment RIP again while waiting
					o_select = `SEL_RIP_1;
					o_load_rip = 1'b1;
					o_load_addr = 1'b1;
				end else if (m_current_cycle == 2) begin
					// 3. Choose register based on RAM output
					m_next_reg_select = i_ram_in;
					m_load_reg_select = 1'b1;
				end else if (m_current_cycle == 3) begin
					// 4. Load address from RAM output
					o_select = `SEL_RAM;
					o_load_addr = 1'b1;
				end else if (m_current_cycle == 4) begin
					// 5. Wait for RAM
				end else begin
					// 6. Write RAM to register
					o_select = `SEL_RAM;
					case (m_reg_select)
						`SEL_REG0: o_load_reg[0] = 1'b1;
						`SEL_REG1: o_load_reg[1] = 1'b1;
						`SEL_REG2: o_load_reg[2] = 1'b1;
						`SEL_REG3: o_load_reg[3] = 1'b1;
						`SEL_REG4: o_load_reg[4] = 1'b1;
						`SEL_REG5: o_load_reg[5] = 1'b1;
						`SEL_REG6: o_load_reg[6] = 1'b1;
						`SEL_REG7: o_load_reg[7] = 1'b1;
						`SEL_RAX: o_load_rax = 1'b1;
					endcase
				end
			end
			S_LDFI: begin
				if (m_current_cycle == 0) begin
					// 1. Increment instruction pointer
					o_select = `SEL_RIP_1;
					o_load_rip = 1'b1;
					o_load_addr = 1'b1;
				end else if (m_current_cycle == 1) begin
					// 2. Wait for RAM
					// Also increment RIP again while waiting
					o_select = `SEL_RIP_1;
					o_load_rip = 1'b1;
					o_load_addr = 1'b1;
				end else if (m_current_cycle == 2) begin
					// 3. Choose register based on RAM output
					m_next_reg_select = i_ram_in;
					m_load_reg_select = 1'b1;
				end else begin
					// 4. Write RAM to register
					o_select = `SEL_RAM;
					case (m_reg_select)
						`SEL_REG0: o_load_reg[0] = 1'b1;
						`SEL_REG1: o_load_reg[1] = 1'b1;
						`SEL_REG2: o_load_reg[2] = 1'b1;
						`SEL_REG3: o_load_reg[3] = 1'b1;
						`SEL_REG4: o_load_reg[4] = 1'b1;
						`SEL_REG5: o_load_reg[5] = 1'b1;
						`SEL_REG6: o_load_reg[6] = 1'b1;
						`SEL_REG7: o_load_reg[7] = 1'b1;
						`SEL_RAX: o_load_rax = 1'b1;
					endcase
				end
			end
			S_LDFR: begin
				if (m_current_cycle == 0) begin
					// 1. Increment instruction pointer
					o_select = `SEL_RIP_1;
					o_load_rip = 1'b1;
					o_load_addr = 1'b1;
				end else if (m_current_cycle == 1) begin
					// 2. Wait for RAM
					// Also increment RIP again while waiting
					o_select = `SEL_RIP_1;
					o_load_rip = 1'b1;
					o_load_addr = 1'b1;
				end else if (m_current_cycle == 2) begin
					// 3. Choose register based on RAM output
					m_next_reg_select = i_ram_in;
					m_load_reg_select = 1'b1;
				end else if (m_current_cycle == 3) begin
					// 4. Load address from register from RAM output
					o_select = i_ram_in;
					o_load_addr = 1'b1;
				end else if (m_current_cycle == 4) begin
					// 5. Wait for RAM
				end else begin
					// 6. Write RAM to register
					o_select = `SEL_RAM;
					case (m_reg_select)
						`SEL_REG0: o_load_reg[0] = 1'b1;
						`SEL_REG1: o_load_reg[1] = 1'b1;
						`SEL_REG2: o_load_reg[2] = 1'b1;
						`SEL_REG3: o_load_reg[3] = 1'b1;
						`SEL_REG4: o_load_reg[4] = 1'b1;
						`SEL_REG5: o_load_reg[5] = 1'b1;
						`SEL_REG6: o_load_reg[6] = 1'b1;
						`SEL_REG7: o_load_reg[7] = 1'b1;
						`SEL_RAX: o_load_rax = 1'b1;
					endcase
				end
			end
			S_CPFR: begin
				if (m_current_cycle == 0) begin
					// 1. Increment instruction pointer
					o_select = `SEL_RIP_1;
					o_load_rip = 1'b1;
					o_load_addr = 1'b1;
				end else if (m_current_cycle == 1) begin
					// 2. Wait for RAM
					// Also increment RIP again while waiting
					o_select = `SEL_RIP_1;
					o_load_rip = 1'b1;
					o_load_addr = 1'b1;
				end else if (m_current_cycle == 2) begin
					// 3. Choose register based on RAM output
					m_next_reg_select = i_ram_in;
					m_load_reg_select = 1'b1;
				end else begin
					// 4. Load register from register from RAM output
					o_select = i_ram_in;
					case (m_reg_select)
						`SEL_REG0: o_load_reg[0] = 1'b1;
						`SEL_REG1: o_load_reg[1] = 1'b1;
						`SEL_REG2: o_load_reg[2] = 1'b1;
						`SEL_REG3: o_load_reg[3] = 1'b1;
						`SEL_REG4: o_load_reg[4] = 1'b1;
						`SEL_REG5: o_load_reg[5] = 1'b1;
						`SEL_REG6: o_load_reg[6] = 1'b1;
						`SEL_REG7: o_load_reg[7] = 1'b1;
						`SEL_RAX: o_load_rax = 1'b1;
					endcase
				end
			end
			S_STOM: begin
				if (m_current_cycle == 0) begin
					// 1. Increment instruction pointer
					o_select = `SEL_RIP_1;
					o_load_rip = 1'b1;
					o_load_addr = 1'b1;
				end else if (m_current_cycle == 1) begin
					// 2. Wait for RAM
					// Also increment RIP again while waiting
					o_select = `SEL_RIP_1;
					o_load_rip = 1'b1;
					o_load_addr = 1'b1;
				end else if (m_current_cycle == 2) begin
					// 3. Choose register based on RAM output
					m_next_reg_select = i_ram_in;
					m_load_reg_select = 1'b1;
				end else if (m_current_cycle == 3) begin
					// 4. Load address from RAM output
					o_select = `SEL_RAM;
					o_load_addr = 1'b1;
				end else begin
					// 5. Write RAM from register
					o_select = m_reg_select;
					o_write_ram = 1'b1;
				end
			end
			S_JINZ, S_JIEQ, S_JILT, S_JIGT: begin
				if (m_current_cycle == 0) begin
					// 1. Get RAM data at RIP + 1
					o_select = `SEL_RIP_1;
					o_load_addr = 1'b1;
					o_load_rip = 1'b1;
				end else if (m_current_cycle == 1) begin
					// 2. Wait for RAM
					// This will never be reached if condition
					// not met (see state table)
				end else begin
					// 3. Set instruction pointer to that data
					o_select = `SEL_RAM;
					o_load_rip = 1'b1;
				end
			end
			S_SHOM: begin
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
					// 4. Indicate that we're waiting for a continue
					o_take_input = 1'b1;
				end
			end
		endcase
	end

	// synchronize
	always @(posedge i_clk) begin
		if (i_reset) begin
			m_current_state <= S_LOAD_ADDR;
			m_current_cycle <= 3'b0;
			m_reg_select <= 8'b0;
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
			if (m_load_reg_select) m_reg_select <= m_next_reg_select;
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
	input wire i_load_rax,
	input wire i_write_ram,
	input wire [7:0] i_load_reg,
	output wire [7:0] o_alu_flags,
	output wire [7:0] o_ram_out
);
				// memory address register
	reg [7:0]   m_MAR,
				// instruction pointer
				m_RIP,
				// arithmetic accumulator
				m_RAX,
				// ALU flags register
				m_RFL;
	reg [7:0]	m_REG0, m_REG1, m_REG2, m_REG3,
				m_REG4, m_REG5, m_REG6, m_REG7;
	wire [7:0] m_ram_out;
	assign o_ram_out = m_ram_out;
	assign o_alu_flags = m_RFL;

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
		.i_A(m_RAX),
		.i_B(bus),
		.i_signed(m_ram_out[7]),
		.i_op(m_ram_out[6:0]),
		.o_G(m_alu_out),
		.o_carry_out(m_alu_flags[`CARRY_OUT_BIT]),
		.o_equal(m_alu_flags[`EQUAL_BIT]),
		.o_less_than(m_alu_flags[`LESS_THAN_BIT]),
		.o_zero(m_alu_flags[`ZERO_BIT]),
		.o_one(m_alu_flags[`ONE_BIT]),
		.o_overflow(m_alu_flags[`OVERFLOW_BIT]),
		.o_undefined(m_alu_flags[`UNDEFINED_BIT])
	);
	assign m_alu_flags[7] = 1'b0;

	always @(*) begin
		case (i_select)
			`SEL_REG0: bus = m_REG0;
			`SEL_REG1: bus = m_REG1;
			`SEL_REG2: bus = m_REG2;
			`SEL_REG3: bus = m_REG3;
			`SEL_REG4: bus = m_REG4;
			`SEL_REG5: bus = m_REG5;
			`SEL_REG6: bus = m_REG6;
			`SEL_REG7: bus = m_REG7;
			`SEL_D_IN: bus = i_data_in;
			`SEL_RAX: bus = m_RAX;
			`SEL_RFL: bus = m_RFL;
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
			m_RIP <= 8'b0;
			m_RAX <= 8'b0;
			m_RFL <= 8'b0;
			m_REG0 <= 8'b0;
			m_REG1 <= 8'b0;
			m_REG2 <= 8'b0;
			m_REG3 <= 8'b0;
			m_REG4 <= 8'b0;
			m_REG5 <= 8'b0;
			m_REG6 <= 8'b0;
			m_REG7 <= 8'b0;
		end
		else begin
			if (i_load_addr) m_MAR <= bus;
			if (i_load_rip) m_RIP <= bus;
			if (i_load_alu) begin
				m_RAX <= m_alu_out;
				m_RFL <= m_alu_flags;
			end
			if (i_load_rax) m_RAX <= bus;
			if (i_load_reg[0]) m_REG0 <= bus;
			if (i_load_reg[1]) m_REG1 <= bus;
			if (i_load_reg[2]) m_REG2 <= bus;
			if (i_load_reg[3]) m_REG3 <= bus;
			if (i_load_reg[4]) m_REG4 <= bus;
			if (i_load_reg[5]) m_REG5 <= bus;
			if (i_load_reg[6]) m_REG6 <= bus;
			if (i_load_reg[7]) m_REG7 <= bus;
		end
	end
endmodule
