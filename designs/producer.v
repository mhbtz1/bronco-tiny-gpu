import constants_pkg::*;

// internal communication between the fetch_engine and the matrix_core is done via AXI-stream lite protocol

module fetch_engine(
					//
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
					m_rsp_data,
					// Core Src
					src_vld,
					src_rdy,
					src_data,
					);
	
	input clk, rst_n, start, op_code, cfg_data;
	input m_req_rdy;
	input m_rsp_vld, m_rsp_data;
	input src_rdy;

	output m_req_vld, m_req_addr;
	output src_vld, src_data;

	reg [ADDR_WIDTH-1:0] request_fsm_addr_state = 0;

	reg [W_DEPTH-1:0] mat_weights;
	reg [X_DEPTH-1:0] vec_inputs;
	reg skid_buffer_state;

	matrix_core matrix_core_inst(
		.clk(clk),
		.rst_n(rst_n),
		.src_vld(m_req_vld),
		.src_rdy(m_req_rdy),
		.src_data(m_req_data),
		.snk_vld(m_rsp_vld),
		.snk_rdy(m_rsp_rdy),
		.snk_data(m_rsp_data)
	);

	skid_buffer skid_buffer_inst(
		.clk(clk),
		.m_rsp_vld(m_rsp_vld),
		.m_rsp_data(m_rsp_data),
		.src_vld(src_vld),
		.src_data(src_data)
	);

	always @ (posedge clk) 
	begin
	end
endmodule