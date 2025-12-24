import constants_pkg::*;

module skid_buffer(
	//inputs 
	clk, m_rsp_vld, m_rsp_data,
	//outputs
	src_vld, src_data,
);

	input clk, m_rsp_vld, m_rsp_data;
	output src_vld, src_data;

	reg skid_reg;
	reg [DATA_WIDTH-1:0] src_data;

	always @ (posedge clk) begin
		if (src_rdy) begin
			src_data <= m_rsp_data;
		end
		
		if (!src_rdy && m_rsp_vld) begin
			skid_reg <= m_rsp_data;
			src_vld <= 1;
		end
	end
endmodule