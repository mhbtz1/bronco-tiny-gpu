import constants_pkg::*;

// internal communication between the fetch_engine and the matrix_core is done via AXI-stream lite protocol

module fetch_engine(
	// System
	clk, 
	rst_n, 
	// Control Signals
	start,
	op_code,
	cfg_data,
	// Mem Req
	m_req_vld,
	m_req_rdy,
	m_req_addr,
	// Mem Resp
	m_rsp_vld,
	m_rsp_rdy,
	m_rsp_data,
	// Core Src
	src_vld,
	src_rdy,
	src_data
);
	
	input wire clk, rst_n, start;
	input wire [1:0] op_code;
	input wire [ADDR_WIDTH-1:0] cfg_data;
	input wire m_req_rdy;
	input wire m_rsp_vld;
	input wire src_rdy;
	input wire [DATA_WIDTH-1:0] m_rsp_data;

	output reg m_req_vld;
	output reg [ADDR_WIDTH-1:0] m_req_addr;
	output wire src_vld;
	output wire [DATA_WIDTH-1:0] src_data;
	output wire m_rsp_rdy;

	// Configuration registers
	reg [ADDR_WIDTH-1:0] REG_W_BASE;
	reg [ADDR_WIDTH-1:0] REG_X_BASE;

	// Skid buffer for response handling
	skid_buffer skid_buffer_inst(
		.clk(clk),
		.rst_n(rst_n),
		.src_rdy(src_rdy),
		.m_rsp_vld(m_rsp_vld),
		.m_rsp_data(m_rsp_data),
		.src_vld(src_vld),
		.src_data(src_data)
	);

	// FSM states
	localparam IDLE     = 2'b00;
	localparam FETCH_W  = 2'b01;
	localparam FETCH_X  = 2'b10;
	localparam DONE     = 2'b11;
	
	reg [1:0] state;
	reg [4:0] fetch_cnt;

	// Address generation FSM
	always @ (posedge clk or negedge rst_n) 
	begin
		if (!rst_n) begin
			state <= IDLE;
			m_req_vld <= 0;
			m_req_addr <= 0;
			fetch_cnt <= 0;
			REG_W_BASE <= 0;
			REG_X_BASE <= 0;
		end
		else begin
			case (state)
				IDLE: begin
					if (start) begin
						case (op_code)
							2'b00: REG_W_BASE <= cfg_data;  // SET_W_BASE
							2'b01: REG_X_BASE <= cfg_data;  // SET_X_BASE
							2'b10: begin                     // RUN
								state <= FETCH_W;
								fetch_cnt <= 0;
								m_req_vld <= 1;
								m_req_addr <= REG_W_BASE;
							end
						endcase
					end
				end
				
				FETCH_W: begin
					if (m_req_vld && m_req_rdy) begin
						if (fetch_cnt == W_DEPTH - 1) begin
							state <= FETCH_X;
							fetch_cnt <= 0;
							m_req_addr <= REG_X_BASE;
						end
						else begin
							fetch_cnt <= fetch_cnt + 1;
							m_req_addr <= m_req_addr + 1;
						end
					end
				end
				
				FETCH_X: begin
					if (m_req_vld && m_req_rdy) begin
						if (fetch_cnt == X_DEPTH - 1) begin
							state <= DONE;
							m_req_vld <= 0;
						end
						else begin
							fetch_cnt <= fetch_cnt + 1;
							m_req_addr <= m_req_addr + 1;
						end
					end
				end
				
				DONE: begin
					state <= IDLE;
				end
			endcase
		end
	end

	assign m_rsp_rdy = src_rdy;

endmodule