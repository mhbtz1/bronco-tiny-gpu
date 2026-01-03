module smolproducer(
    clk,
    rst_n,
    vld,
    rdy,
    next_data,
    data
);
    input clk;
    input rst_n;
    output reg vld;
    input rdy;
    output reg [31:0] next_data;
    output reg [31:0] data;

    always @ (posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        vld <= 0;
        next_data <= 0;
      end 
      else if (!vld) begin
        vld <= 1;
        next_data <= next_data + 1;
        data <= next_data;
      end else if (vld && rdy) begin
        $display ("HANDSHAKE DONE");
        vld <= 0;
      end
    end

endmodule


module smolconsumer(
    clk,
    rst_n,
    vld,
    rdy,
    data
);
    input clk, rst_n;
    input [31:0] data;
    input vld;
    output reg rdy;

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdy <= 0;
        end else if (vld) begin
            $display("data processed = [%08h]", data);
            rdy <= 1;
        end
    end
endmodule