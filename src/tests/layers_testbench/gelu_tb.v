module gelu_tb;
    // test parameters
    parameter INPUT_DIM = 4;
    parameter OUTPUT_DIM = 4;
    parameter WIDTH = 16;
    parameter FRACTIONAL_BITS = 8;
    
    // DUT signals
    reg clk;
    reg rst;
    reg enable;
    reg [WIDTH-1:0] input_tensor[INPUT_DIM-1:0];
    wire [WIDTH-1:0] output_tensor[OUTPUT_DIM-1:0];
    wire valid_out;
    
    // init the gelu module
    gelu #(
        .INPUT_DIM(INPUT_DIM),
        .OUTPUT_DIM(OUTPUT_DIM),
        .WIDTH(WIDTH),
        .FRACTIONAL_BITS(FRACTIONAL_BITS)
    ) dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .input_tensor(input_tensor),
        .output_tensor(output_tensor),
        .valid_out(valid_out)
    );
    
    // clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // test stimulus
    initial begin
`ifdef VCD_DUMP_PATH
        $dumpfile(`VCD_DUMP_PATH);
`else
        $dumpfile("gelu_tb.vcd");
`endif
        $dumpvars(0, gelu_tb);
        
        // init signals
        rst = 1;
        enable = 0;
        
        // init input tensor with test values
        // Testing different ranges to verify GELU behavior
        input_tensor[0] = 16'h0100;  // 1.0
        input_tensor[1] = 16'hFF00;  // -1.0
        input_tensor[2] = 16'h0200;  // 2.0
        input_tensor[3] = 16'hFE00;  // -2.0
        
        // enable 
        #10 rst = 0;
        #10 enable = 1;
        
        @(posedge valid_out);
        
        $display("Test Results:");
        $display("Input tensor:");
        for (integer i = 0; i < INPUT_DIM; i = i + 1) begin
            $display("  input[%0d] = %h", i, input_tensor[i]);
        end
        
        $display("Output tensor (GELU activation):");
        for (integer i = 0; i < OUTPUT_DIM; i = i + 1) begin
            $display("  output[%0d] = %h", i, output_tensor[i]);
        end
        
        // delay
        #100 $finish;
    end
endmodule
