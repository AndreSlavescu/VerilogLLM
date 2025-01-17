// linear implementation

module linear #(
    parameter INPUT_DIM = 768,
    parameter OUTPUT_DIM = 768,
    parameter WIDTH = 16,
    parameter FRACTIONAL_BITS = 8
) (
    input wire clk, // clock pin
    input wire rst, // reset pin
    input wire enable, // enable pin

    // input.shape: [batch_size, input_dim]
    input wire [WIDTH-1:0] input_tensor[INPUT_DIM-1:0],

    // weights.shape: [output_dim, input_dim]
    input wire [WIDTH-1:0] weights[OUTPUT_DIM-1:0][INPUT_DIM-1:0], // 2D weight matrix
    
    // bias.shape: [input_dim]
    // requires inner dimension of weights be equal to bias dim
    input wire [WIDTH-1:0] bias[OUTPUT_DIM-1:0], // scalar bias

    // output.shape: [batch_size, output_size]
    output reg [WIDTH-1:0] output_tensor[OUTPUT_DIM-1:0],
    output reg valid_out // flag for output validity
);
    reg [2*WIDTH-1:0] mul_result; 
    reg [2*WIDTH-1:0] accumulator[OUTPUT_DIM-1:0];
    reg computing;
    reg [31:0] i, j;
    reg [2*WIDTH-1:0] temp_accumulator; 

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_out <= 0;
            computing <= 0;
            for (i = 0; i < OUTPUT_DIM; i = i + 1) begin
                output_tensor[i] <= 0;
                accumulator[i] <= 0;
            end
        end
        else if (enable && !computing) begin
            computing <= 1;
            valid_out <= 0;

            for (i = 0; i < OUTPUT_DIM; i = i + 1) begin
                accumulator[i] <= {{WIDTH{bias[i][WIDTH-1]}}, bias[i]};
            end
        end
        else if (computing) begin
            
            // c = a @ b
            // d = c + bias

            for (i = 0; i < OUTPUT_DIM; i = i + 1) begin
                temp_accumulator = accumulator[i]; 
                
                for (j = 0; j < INPUT_DIM; j = j + 1) begin
                    mul_result = $signed(input_tensor[j]) * $signed(weights[i][j]);
                    temp_accumulator = temp_accumulator + (mul_result >>> FRACTIONAL_BITS);
                end
                
                accumulator[i] <= temp_accumulator;
                
                output_tensor[i] <= temp_accumulator[2*WIDTH-1] ? 
                                    {1'b1, {(WIDTH-1){1'b0}}} :
                                    (temp_accumulator[2*WIDTH-2:WIDTH-1] != 0) ?
                                        {1'b0, {(WIDTH-1){1'b1}}} :
                                        temp_accumulator[WIDTH-1:0];
            end
            computing <= 0;
            valid_out <= 1;
        end
    end
endmodule