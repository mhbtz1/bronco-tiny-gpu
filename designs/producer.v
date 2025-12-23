import constants::*;

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
					m_rsp_rdy,
					m_req_addr
					);
	
	input clk, rst_n, start, op_code, cfg_data, m_req_vld, m_req_rdy, m_req_addr;
	output m_rsp_vld;
	output m_rsp_rdy;
	output m_req_addr;

	reg [ADDR_WIDTH-1:0] request_fsm_addr_state = m_req_addr;

	reg [W_DEPTH-1:0] mat_weights;
	reg [X_DEPTH-1:0] vec_inputs;
	reg skid_buffer_state;

	always @ (posedge clk) 
	begin
	  if (op_code == constants::FETCH_ENGINE_RUN) begin
		
	  end

	  if 
	end


endmodule