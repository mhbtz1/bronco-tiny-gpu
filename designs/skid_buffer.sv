import constants_pkg::*;

module skid_buffer(
	//inputs 
	clk,
	rst_n,
	src_rdy,
	m_rsp_vld,
	m_rsp_data,
	//outputs
	src_vld,
	src_data
);

	input wire clk, rst_n;
	input wire src_rdy;
	input wire m_rsp_vld;
	input wire [DATA_WIDTH-1:0] m_rsp_data;
	
	output reg src_vld;
	output reg [DATA_WIDTH-1:0] src_data;

	reg [DATA_WIDTH-1:0] skid_reg;
	reg skid_valid;

	always @ (posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			src_vld <= 0;
			src_data <= 0;
			skid_reg <= 0;
			skid_valid <= 0;
		end
		else begin
			if (src_rdy) begin
				if (skid_valid) begin
					$display("[%0t] SKID_BUFFER: Passing through buffered data = 0x%h", $time, skid_reg);
					src_data <= skid_reg;    
					src_vld <= 1;            
					skid_valid <= 0;         
				end
				else if (m_rsp_vld) begin
					$display("[%0t] SKID_BUFFER: Passing through new data from memory = 0x%h", $time, m_rsp_data);
					src_data <= m_rsp_data;  
					src_vld <= 1;            
				end
				else begin
					src_vld <= 0; 
				end
			end
			else if (m_rsp_vld && !skid_valid) begin
				skid_reg <= m_rsp_data; 
				skid_valid <= 1;
			end
		end
	end

endmodule