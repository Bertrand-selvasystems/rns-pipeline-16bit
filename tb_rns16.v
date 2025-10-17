`timescale 1ns/1ps
`default_nettype none

`define DUT_NAME rns16

module tb_rns16;
  // Horloge / reset
  reg clk, rst_n;

  // DUT I/O
  reg  [7:0]  in_byte;
  reg         in_valid;
  wire        in_ready;

  wire [15:0] out_word;
  wire        out_valid;
  reg         out_ready;

  // ===== Instance DUT =====
  `DUT_NAME dut (
    .clk(clk), .rst_n(rst_n),
    .in_byte(in_byte), .in_valid(in_valid), .in_ready(in_ready),
    .out_word(out_word), .out_valid(out_valid), .out_ready(out_ready)
  );

  // Horloge 100 MHz
  initial clk = 1'b0;
  always #5 clk = ~clk;

  // Sortie toujours prête (tu peux mettre un motif pour tester le back-pressure)
  initial out_ready = 1'b1;

  // ===== Scoreboard =====
  reg [15:0] exp_fifo [0:65535];
  integer wr_ptr, rd_ptr;

  task push_expected(input [15:0] x);
    begin
      exp_fifo[wr_ptr] = x + 16'd2; // wrap 16 bits implicite
      wr_ptr = wr_ptr + 1;
    end
  endtask

  // Handshake détection
  wire out_fire = out_valid & out_ready;


// (Optionnel) only: out_valid pendant reset = interdit
always @(posedge clk) begin
  if (!rst_n && out_valid) begin
    $display("[%0t] ERROR: out_valid actif pendant reset", $time);
    $fatal(1);
  end
end

// Checker : consomme UNIQUEMENT au handshake
always @(posedge clk) begin
  if (rst_n && out_fire) begin
    if (rd_ptr >= wr_ptr) begin
      $display("[%0t] ERROR: FIFO underflow (rd=%0d wr=%0d)", $time, rd_ptr, wr_ptr);
      $fatal(1);
    end
    if (out_word !== exp_fifo[rd_ptr]) begin
      $display("[%0t] MISMATCH: got=%0d (0x%04h) exp=%0d (0x%04h) idx=%0d",
               $time, out_word, out_word, exp_fifo[rd_ptr], exp_fifo[rd_ptr], rd_ptr);
      $fatal(1);
    end
    rd_ptr = rd_ptr + 1;
  end
end

 
 
  // ===== Driver d'entrée (8b -> 16b LSB puis MSB) =====
  task send_word16(input [15:0] v);
    begin
      // Byte LSB
      @(posedge clk);
      while (!in_ready) @(posedge clk);
      in_byte  <= v[7:0];
      in_valid <= 1'b1;
      @(posedge clk);
      in_valid <= 1'b0;

      // Byte MSB
      @(posedge clk);
      while (!in_ready) @(posedge clk);
      in_byte  <= v[15:8];
      in_valid <= 1'b1;
      push_expected(v); // mot complet acquis côté DUT
      @(posedge clk);
      in_valid <= 1'b0;
    end
  endtask

  // ===== Stimuli =====
  integer i;
  initial begin
    in_byte = 8'd0; in_valid = 1'b0; wr_ptr = 0; rd_ptr = 0;

    // Reset
    rst_n = 1'b0; repeat (4) @(posedge clk); rst_n = 1'b1;

    // Balayage 0..65535 (raccourcis possibles : i += 7, etc.)
    for (i = 0; i < 65536; i = i + 1) begin
      send_word16(i[15:0]);
    end

    // Attendre vidange complète
    wait (rd_ptr == wr_ptr);
    repeat (4) @(posedge clk);

    $display("OK !");
    $finish;
  end
endmodule

`default_nettype wire
