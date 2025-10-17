`timescale 1ns/1ps
`default_nettype none

module rns16 (
  input  wire        clk,
  input  wire        rst_n,

  // Bus entrée (8 bits parallèles, 2 cycles = 16 bits)
  input  wire [7:0]  in_byte,
  input  wire        in_valid,
  output wire        in_ready,

  // Bus sortie (16 bits après +2)
  output reg  [15:0] out_word,
  output reg         out_valid,
  input  wire        out_ready
);

// ====================================================
// Phase 1 — Capture 16b depuis bus 8b (LSB puis MSB)
// ====================================================
reg  [7:0]  x_lo;
reg         have_lo;     // 1 = LSB déjà capturé
reg         v0;          // 1-cycle pulse : mot 16b prêt
reg  [15:0] x0_16;

wire in_fire = in_valid & in_ready;

// Entrée toujours prête en dehors du reset
assign in_ready = rst_n;

always @(posedge clk) begin
  if (!rst_n) begin
    have_lo <= 1'b0;
    v0      <= 1'b0;
    x_lo    <= 8'd0;
    x0_16   <= 16'd0;
  end else begin
    v0 <= 1'b0;                 // défaut : pas de pulse
    if (in_fire) begin
      if (!have_lo) begin
        // 1er octet : LSB
        x_lo    <= in_byte;
        have_lo <= 1'b1;
      end else begin
        // 2e octet : MSB -> mot complet + pulse v0
        x0_16   <= {in_byte, x_lo};
        have_lo <= 1'b0;
        v0      <= 1'b1;        // **pulse 1 cycle**
      end
    end
  end
end



  // ====================================================
  // Phase 2 — Binaire -> RNS (7,11,13,15,17,19,23,29,31)
  //            Par nibbles : x = n3 n2 n1 n0, avec 16^i mod m
  //            LUT 16 entrées pour c_i*nibble % m (aucun multiplieur)
  // ====================================================

  wire [3:0] n0 = x0_16[3:0];
  wire [3:0] n1 = x0_16[7:4];
  wire [3:0] n2 = x0_16[11:8];
  wire [3:0] n3 = x0_16[15:12];

  reg        v1;
  reg  [4:0] r7, r11, r13, r15, r17, r19, r23, r29, r31; // 5 bits suffisent (<=31)

  // ---------- LUT 16-entrées: (c_i * nibble) % m ----------
  // Générées pour chaque (mod m, coefficient c_i = 16^i % m)

    
// ============================
// LUTs pour m=7, c = [1,2,4,1]
// ============================
  function [4:0] lut16_m7_c0; 
  input [3:0] n; reg [4:0] lut; 
  begin
    case (n)
      4'd0: lut = 5'd0;  4'd1: lut = 5'd1;  4'd2: lut = 5'd2;  4'd3: lut = 5'd3;
      4'd4: lut = 5'd4;  4'd5: lut = 5'd5;  4'd6: lut = 5'd6;  4'd7: lut = 5'd0;
      4'd8: lut = 5'd1;  4'd9: lut = 5'd2;  4'd10:lut = 5'd3;  4'd11:lut = 5'd4;
      4'd12:lut = 5'd5;  4'd13:lut = 5'd6;  4'd14:lut = 5'd0;  4'd15:lut = 5'd1;
    endcase 
	 lut16_m7_c0 = lut; 
	end endfunction
	 
  function [4:0] lut16_m7_c1;
  input [3:0] n; reg [4:0] lut; 
  begin
    case (n)
      4'd0: lut = 5'd0;  4'd1: lut = 5'd2;  4'd2: lut = 5'd4;  4'd3: lut = 5'd6;
      4'd4: lut = 5'd1;  4'd5: lut = 5'd3;  4'd6: lut = 5'd5;  4'd7: lut = 5'd0;
      4'd8: lut = 5'd2;  4'd9: lut = 5'd4;  4'd10:lut = 5'd6;  4'd11:lut = 5'd1;
      4'd12:lut = 5'd3;  4'd13:lut = 5'd5;  4'd14:lut = 5'd0;  4'd15:lut = 5'd2;
    endcase 
	 lut16_m7_c1 = lut; 
	 end endfunction
	 
  function [4:0] lut16_m7_c2;
  input [3:0] n; reg [4:0] lut;
  begin
    case (n)
      4'd0: lut = 5'd0;  4'd1: lut = 5'd4;  4'd2: lut = 5'd1;  4'd3: lut = 5'd5;
      4'd4: lut = 5'd2;  4'd5: lut = 5'd6;  4'd6: lut = 5'd3;  4'd7: lut = 5'd0;
      4'd8: lut = 5'd4;  4'd9: lut = 5'd1;  4'd10:lut = 5'd5;  4'd11:lut = 5'd2;
      4'd12:lut = 5'd6;  4'd13:lut = 5'd3;  4'd14:lut = 5'd0;  4'd15:lut = 5'd4;
    endcase lut16_m7_c2 = lut; 
	 end endfunction
	 
  function [4:0] lut16_m7_c3; 
  input [3:0] n; reg [4:0] lut; 
  begin
    case (n)
      4'd0: lut = 5'd0;  4'd1: lut = 5'd1;  4'd2: lut = 5'd2;  4'd3: lut = 5'd3;
      4'd4: lut = 5'd4;  4'd5: lut = 5'd5;  4'd6: lut = 5'd6;  4'd7: lut = 5'd0;
      4'd8: lut = 5'd1;  4'd9: lut = 5'd2;  4'd10:lut = 5'd3;  4'd11:lut = 5'd4;
      4'd12:lut = 5'd5;  4'd13:lut = 5'd6;  4'd14:lut = 5'd0;  4'd15:lut = 5'd1;
    endcase lut16_m7_c3 = lut; 
	 end endfunction
  
  
  // ============================
// LUTs pour m = 11 c = [1,5,3,4]
// ============================
function [4:0] lut16_m11_c0;  // c0 = 1
  input [3:0] n; reg [4:0] lut;
begin
  case (n)
    4'd0:  lut = 5'd0;   4'd1:  lut = 5'd1;   4'd2:  lut = 5'd2;   4'd3:  lut = 5'd3;
    4'd4:  lut = 5'd4;   4'd5:  lut = 5'd5;   4'd6:  lut = 5'd6;   4'd7:  lut = 5'd7;
    4'd8:  lut = 5'd8;   4'd9:  lut = 5'd9;   4'd10: lut = 5'd10;  4'd11: lut = 5'd0;
    4'd12: lut = 5'd1;   4'd13: lut = 5'd2;   4'd14: lut = 5'd3;   4'd15: lut = 5'd4;
  endcase
  lut16_m11_c0 = lut;
end
endfunction

function [4:0] lut16_m11_c1;  // c1 = 5
  input [3:0] n; reg [4:0] lut;
begin
  case (n)
    4'd0:  lut = 5'd0;   4'd1:  lut = 5'd5;   4'd2:  lut = 5'd10;  4'd3:  lut = 5'd4;
    4'd4:  lut = 5'd9;   4'd5:  lut = 5'd3;   4'd6:  lut = 5'd8;   4'd7:  lut = 5'd2;
    4'd8:  lut = 5'd7;   4'd9:  lut = 5'd1;   4'd10: lut = 5'd6;   4'd11: lut = 5'd0;
    4'd12: lut = 5'd5;   4'd13: lut = 5'd10;  4'd14: lut = 5'd4;   4'd15: lut = 5'd9;
  endcase
  lut16_m11_c1 = lut;
end
endfunction

function [4:0] lut16_m11_c2;  // c2 = 3
  input [3:0] n; reg [4:0] lut;
begin
  case (n)
    4'd0:  lut = 5'd0;   4'd1:  lut = 5'd3;   4'd2:  lut = 5'd6;   4'd3:  lut = 5'd9;
    4'd4:  lut = 5'd1;   4'd5:  lut = 5'd4;   4'd6:  lut = 5'd7;   4'd7:  lut = 5'd10;
    4'd8:  lut = 5'd2;   4'd9:  lut = 5'd5;   4'd10: lut = 5'd8;   4'd11: lut = 5'd0;
    4'd12: lut = 5'd3;   4'd13: lut = 5'd6;   4'd14: lut = 5'd9;   4'd15: lut = 5'd1;
  endcase
  lut16_m11_c2 = lut;
end
endfunction

function [4:0] lut16_m11_c3;  // c3 = 4
  input [3:0] n; reg [4:0] lut;
begin
  case (n)
    4'd0:  lut = 5'd0;   4'd1:  lut = 5'd4;   4'd2:  lut = 5'd8;   4'd3:  lut = 5'd1;
    4'd4:  lut = 5'd5;   4'd5:  lut = 5'd9;   4'd6:  lut = 5'd2;   4'd7:  lut = 5'd6;
    4'd8:  lut = 5'd10;  4'd9:  lut = 5'd3;   4'd10: lut = 5'd7;   4'd11: lut = 5'd0;
    4'd12: lut = 5'd4;   4'd13: lut = 5'd8;   4'd14: lut = 5'd1;   4'd15: lut = 5'd5;
  endcase
  lut16_m11_c3 = lut;
end
endfunction

// ============================
// LUTs pour m = 13 c = [1,3,9,1]
// ============================
function [4:0] lut16_m13_c0;  // c0 = 1
  input [3:0] n; reg [4:0] lut;
begin
  case (n)
    4'd0:  lut = 5'd0;   4'd1:  lut = 5'd1;   4'd2:  lut = 5'd2;   4'd3:  lut = 5'd3;
    4'd4:  lut = 5'd4;   4'd5:  lut = 5'd5;   4'd6:  lut = 5'd6;   4'd7:  lut = 5'd7;
    4'd8:  lut = 5'd8;   4'd9:  lut = 5'd9;   4'd10: lut = 5'd10;  4'd11: lut = 5'd11;
    4'd12: lut = 5'd12;  4'd13: lut = 5'd0;   4'd14: lut = 5'd1;   4'd15: lut = 5'd2;
  endcase
  lut16_m13_c0 = lut;
end
endfunction

function [4:0] lut16_m13_c1;  // c1 = 3
  input [3:0] n; reg [4:0] lut;
begin
  case (n)
    4'd0:  lut = 5'd0;   4'd1:  lut = 5'd3;   4'd2:  lut = 5'd6;   4'd3:  lut = 5'd9;
    4'd4:  lut = 5'd12;  4'd5:  lut = 5'd2;   4'd6:  lut = 5'd5;   4'd7:  lut = 5'd8;
    4'd8:  lut = 5'd11;  4'd9:  lut = 5'd1;   4'd10: lut = 5'd4;   4'd11: lut = 5'd7;
    4'd12: lut = 5'd10;  4'd13: lut = 5'd0;   4'd14: lut = 5'd3;   4'd15: lut = 5'd6;
  endcase
  lut16_m13_c1 = lut;
end
endfunction

function [4:0] lut16_m13_c2;  // c2 = 9
  input [3:0] n; reg [4:0] lut;
begin
  case (n)
    4'd0:  lut = 5'd0;   4'd1:  lut = 5'd9;   4'd2:  lut = 5'd5;   4'd3:  lut = 5'd1;
    4'd4:  lut = 5'd10;  4'd5:  lut = 5'd6;   4'd6:  lut = 5'd2;   4'd7:  lut = 5'd11;
    4'd8:  lut = 5'd7;   4'd9:  lut = 5'd3;   4'd10: lut = 5'd12;  4'd11: lut = 5'd8;
    4'd12: lut = 5'd4;   4'd13: lut = 5'd0;   4'd14: lut = 5'd9;   4'd15: lut = 5'd5;
  endcase
  lut16_m13_c2 = lut;
end
endfunction

function [4:0] lut16_m13_c3;  // c3 = 1
  input [3:0] n; reg [4:0] lut;
begin
  case (n)
    4'd0:  lut = 5'd0;   4'd1:  lut = 5'd1;   4'd2:  lut = 5'd2;   4'd3:  lut = 5'd3;
    4'd4:  lut = 5'd4;   4'd5:  lut = 5'd5;   4'd6:  lut = 5'd6;   4'd7:  lut = 5'd7;
    4'd8:  lut = 5'd8;   4'd9:  lut = 5'd9;   4'd10: lut = 5'd10;  4'd11: lut = 5'd11;
    4'd12: lut = 5'd12;  4'd13: lut = 5'd0;   4'd14: lut = 5'd1;   4'd15: lut = 5'd2;
  endcase
  lut16_m13_c3 = lut;
end
endfunction
  

// ============================
// m = 15, c = [1,1,1,1]
// ============================
function [4:0] lut16_m15_c0; input [3:0] n; reg [4:0] lut; begin
  case (n)
    4'd0: lut = 5'd0;   4'd1: lut = 5'd1;   4'd2: lut = 5'd2;   4'd3: lut = 5'd3;
    4'd4: lut = 5'd4;   4'd5: lut = 5'd5;   4'd6: lut = 5'd6;   4'd7: lut = 5'd7;
    4'd8: lut = 5'd8;   4'd9: lut = 5'd9;   4'd10:lut = 5'd10;  4'd11:lut = 5'd11;
    4'd12:lut = 5'd12;  4'd13:lut = 5'd13;  4'd14:lut = 5'd14;  4'd15:lut = 5'd0;
  endcase
  lut16_m15_c0 = lut;
end endfunction

function [4:0] lut16_m15_c1; input [3:0] n; reg [4:0] lut; begin
  case (n)
    4'd0: lut = 5'd0;   4'd1: lut = 5'd1;   4'd2: lut = 5'd2;   4'd3: lut = 5'd3;
    4'd4: lut = 5'd4;   4'd5: lut = 5'd5;   4'd6: lut = 5'd6;   4'd7: lut = 5'd7;
    4'd8: lut = 5'd8;   4'd9: lut = 5'd9;   4'd10:lut = 5'd10;  4'd11:lut = 5'd11;
    4'd12:lut = 5'd12;  4'd13:lut = 5'd13;  4'd14:lut = 5'd14;  4'd15:lut = 5'd0;
  endcase
  lut16_m15_c1 = lut;
end endfunction

function [4:0] lut16_m15_c2; input [3:0] n; reg [4:0] lut; begin
  case (n)
    4'd0: lut = 5'd0;   4'd1: lut = 5'd1;   4'd2: lut = 5'd2;   4'd3: lut = 5'd3;
    4'd4: lut = 5'd4;   4'd5: lut = 5'd5;   4'd6: lut = 5'd6;   4'd7: lut = 5'd7;
    4'd8: lut = 5'd8;   4'd9: lut = 5'd9;   4'd10:lut = 5'd10;  4'd11:lut = 5'd11;
    4'd12:lut = 5'd12;  4'd13:lut = 5'd13;  4'd14:lut = 5'd14;  4'd15:lut = 5'd0;
  endcase
  lut16_m15_c2 = lut;
end endfunction

function [4:0] lut16_m15_c3; input [3:0] n; reg [4:0] lut; begin
  case (n)
    4'd0: lut = 5'd0;   4'd1: lut = 5'd1;   4'd2: lut = 5'd2;   4'd3: lut = 5'd3;
    4'd4: lut = 5'd4;   4'd5: lut = 5'd5;   4'd6: lut = 5'd6;   4'd7: lut = 5'd7;
    4'd8: lut = 5'd8;   4'd9: lut = 5'd9;   4'd10:lut = 5'd10;  4'd11:lut = 5'd11;
    4'd12:lut = 5'd12;  4'd13:lut = 5'd13;  4'd14:lut = 5'd14;  4'd15:lut = 5'd0;
  endcase
  lut16_m15_c3 = lut;
end endfunction


// ============================
// m = 17, c = [1,16,1,16]
// ============================
function [4:0] lut16_m17_c0; input [3:0] n; reg [4:0] lut; begin
  case (n)
    4'd0: lut = 5'd0;   4'd1: lut = 5'd1;   4'd2: lut = 5'd2;   4'd3: lut = 5'd3;
    4'd4: lut = 5'd4;   4'd5: lut = 5'd5;   4'd6: lut = 5'd6;   4'd7: lut = 5'd7;
    4'd8: lut = 5'd8;   4'd9: lut = 5'd9;   4'd10:lut = 5'd10;  4'd11:lut = 5'd11;
    4'd12:lut = 5'd12;  4'd13:lut = 5'd13;  4'd14:lut = 5'd14;  4'd15:lut = 5'd15;
  endcase
  lut16_m17_c0 = lut;
end endfunction

function [4:0] lut16_m17_c1; input [3:0] n; reg [4:0] lut; begin
  case (n)
    4'd0: lut = 5'd0;   4'd1: lut = 5'd16;  4'd2: lut = 5'd15;  4'd3: lut = 5'd14;
    4'd4: lut = 5'd13;  4'd5: lut = 5'd12;  4'd6: lut = 5'd11;  4'd7: lut = 5'd10;
    4'd8: lut = 5'd9;   4'd9: lut = 5'd8;   4'd10:lut = 5'd7;   4'd11:lut = 5'd6;
    4'd12:lut = 5'd5;   4'd13:lut = 5'd4;   4'd14:lut = 5'd3;   4'd15:lut = 5'd2;
  endcase
  lut16_m17_c1 = lut;
end endfunction

function [4:0] lut16_m17_c2; input [3:0] n; reg [4:0] lut; begin
  case (n)
    4'd0: lut = 5'd0;   4'd1: lut = 5'd1;   4'd2: lut = 5'd2;   4'd3: lut = 5'd3;
    4'd4: lut = 5'd4;   4'd5: lut = 5'd5;   4'd6: lut = 5'd6;   4'd7: lut = 5'd7;
    4'd8: lut = 5'd8;   4'd9: lut = 5'd9;   4'd10:lut = 5'd10;  4'd11:lut = 5'd11;
    4'd12:lut = 5'd12;  4'd13:lut = 5'd13;  4'd14:lut = 5'd14;  4'd15:lut = 5'd15;
  endcase
  lut16_m17_c2 = lut;
end endfunction

function [4:0] lut16_m17_c3; input [3:0] n; reg [4:0] lut; begin
  case (n)
    4'd0: lut = 5'd0;   4'd1: lut = 5'd16;  4'd2: lut = 5'd15;  4'd3: lut = 5'd14;
    4'd4: lut = 5'd13;  4'd5: lut = 5'd12;  4'd6: lut = 5'd11;  4'd7: lut = 5'd10;
    4'd8: lut = 5'd9;   4'd9: lut = 5'd8;   4'd10:lut = 5'd7;   4'd11:lut = 5'd6;
    4'd12:lut = 5'd5;   4'd13:lut = 5'd4;   4'd14:lut = 5'd3;   4'd15:lut = 5'd2;
  endcase
  lut16_m17_c3 = lut;
end endfunction


// ============================
// m = 19, c = [1,16,9,11]
// ============================
function [4:0] lut16_m19_c0; input [3:0] n; reg [4:0] lut; begin
  case (n)
    4'd0: lut = 5'd0;   4'd1: lut = 5'd1;   4'd2: lut = 5'd2;   4'd3: lut = 5'd3;
    4'd4: lut = 5'd4;   4'd5: lut = 5'd5;   4'd6: lut = 5'd6;   4'd7: lut = 5'd7;
    4'd8: lut = 5'd8;   4'd9: lut = 5'd9;   4'd10:lut = 5'd10;  4'd11:lut = 5'd11;
    4'd12:lut = 5'd12;  4'd13:lut = 5'd13;  4'd14:lut = 5'd14;  4'd15:lut = 5'd15;
  endcase
  lut16_m19_c0 = lut;
end endfunction

function [4:0] lut16_m19_c1; input [3:0] n; reg [4:0] lut; begin
  case (n)
    4'd0: lut = 5'd0;   4'd1: lut = 5'd16;  4'd2: lut = 5'd13;  4'd3: lut = 5'd10;
    4'd4: lut = 5'd7;   4'd5: lut = 5'd4;   4'd6: lut = 5'd1;   4'd7: lut = 5'd17;
    4'd8: lut = 5'd14;  4'd9: lut = 5'd11;  4'd10:lut = 5'd8;   4'd11:lut = 5'd5;
    4'd12:lut = 5'd2;   4'd13:lut = 5'd18;  4'd14:lut = 5'd15;  4'd15:lut = 5'd12;
  endcase
  lut16_m19_c1 = lut;
end endfunction

function [4:0] lut16_m19_c2; input [3:0] n; reg [4:0] lut; begin
  case (n)
    4'd0: lut = 5'd0;   4'd1: lut = 5'd9;   4'd2: lut = 5'd18;  4'd3: lut = 5'd8;
    4'd4: lut = 5'd17;  4'd5: lut = 5'd7;   4'd6: lut = 5'd16;  4'd7: lut = 5'd6;
    4'd8: lut = 5'd15;  4'd9: lut = 5'd5;   4'd10:lut = 5'd14;  4'd11:lut = 5'd4;
    4'd12:lut = 5'd13;  4'd13:lut = 5'd3;   4'd14:lut = 5'd12;  4'd15:lut = 5'd2;
  endcase
  lut16_m19_c2 = lut;
end endfunction

function [4:0] lut16_m19_c3; input [3:0] n; reg [4:0] lut; begin
  case (n)
    4'd0: lut = 5'd0;   4'd1: lut = 5'd11;  4'd2: lut = 5'd3;   4'd3: lut = 5'd14;
    4'd4: lut = 5'd6;   4'd5: lut = 5'd17;  4'd6: lut = 5'd9;   4'd7: lut = 5'd1;
    4'd8: lut = 5'd12;  4'd9: lut = 5'd4;   4'd10:lut = 5'd15;  4'd11:lut = 5'd7;
    4'd12:lut = 5'd18;  4'd13:lut = 5'd10;  4'd14:lut = 5'd2;   4'd15:lut = 5'd13;
  endcase
  lut16_m19_c3 = lut;
end endfunction


// ============================
// m = 23, c = [1,16,3,2]
// ============================
function [4:0] lut16_m23_c0; input [3:0] n; reg [4:0] lut; begin
  case (n)
    4'd0: lut = 5'd0;   4'd1: lut = 5'd1;   4'd2: lut = 5'd2;   4'd3: lut = 5'd3;
    4'd4: lut = 5'd4;   4'd5: lut = 5'd5;   4'd6: lut = 5'd6;   4'd7: lut = 5'd7;
    4'd8: lut = 5'd8;   4'd9: lut = 5'd9;   4'd10:lut = 5'd10;  4'd11:lut = 5'd11;
    4'd12:lut = 5'd12;  4'd13:lut = 5'd13;  4'd14:lut = 5'd14;  4'd15:lut = 5'd15;
  endcase
  lut16_m23_c0 = lut;
end endfunction

function [4:0] lut16_m23_c1; input [3:0] n; reg [4:0] lut; begin
  case (n)
    4'd0: lut = 5'd0;   4'd1: lut = 5'd16;  4'd2: lut = 5'd9;   4'd3: lut = 5'd2;
    4'd4: lut = 5'd18;  4'd5: lut = 5'd11;  4'd6: lut = 5'd4;   4'd7: lut = 5'd20;
    4'd8: lut = 5'd13;  4'd9: lut = 5'd6;   4'd10:lut = 5'd22;  4'd11:lut = 5'd15;
    4'd12:lut = 5'd8;   4'd13:lut = 5'd1;   4'd14:lut = 5'd17;  4'd15:lut = 5'd10;
  endcase
  lut16_m23_c1 = lut;
end endfunction

function [4:0] lut16_m23_c2; input [3:0] n; reg [4:0] lut; begin
  case (n)
    4'd0: lut = 5'd0;   4'd1: lut = 5'd3;   4'd2: lut = 5'd6;   4'd3: lut = 5'd9;
    4'd4: lut = 5'd12;  4'd5: lut = 5'd15;  4'd6: lut = 5'd18;  4'd7: lut = 5'd21;
    4'd8: lut = 5'd1;   4'd9: lut = 5'd4;   4'd10:lut = 5'd7;   4'd11:lut = 5'd10;
    4'd12:lut = 5'd13;  4'd13:lut = 5'd16;  4'd14:lut = 5'd19;  4'd15:lut = 5'd22;
  endcase
  lut16_m23_c2 = lut;
end endfunction

function [4:0] lut16_m23_c3; input [3:0] n; reg [4:0] lut; begin
  case (n)
    4'd0: lut = 5'd0;   4'd1: lut = 5'd2;   4'd2: lut = 5'd4;   4'd3: lut = 5'd6;
    4'd4: lut = 5'd8;   4'd5: lut = 5'd10;  4'd6: lut = 5'd12;  4'd7: lut = 5'd14;
    4'd8: lut = 5'd16;  4'd9: lut = 5'd18;  4'd10:lut = 5'd20;  4'd11:lut = 5'd22;
    4'd12:lut = 5'd1;   4'd13:lut = 5'd3;   4'd14:lut = 5'd5;   4'd15:lut = 5'd7;
  endcase
  lut16_m23_c3 = lut;
end endfunction


// ============================
// m = 29, c = [1,16,24,7]
// ============================
function [4:0] lut16_m29_c0; input [3:0] n; reg [4:0] lut; begin
  case (n)
    4'd0: lut = 5'd0;   4'd1: lut = 5'd1;   4'd2: lut = 5'd2;   4'd3: lut = 5'd3;
    4'd4: lut = 5'd4;   4'd5: lut = 5'd5;   4'd6: lut = 5'd6;   4'd7: lut = 5'd7;
    4'd8: lut = 5'd8;   4'd9: lut = 5'd9;   4'd10:lut = 5'd10;  4'd11:lut = 5'd11;
    4'd12:lut = 5'd12;  4'd13:lut = 5'd13;  4'd14:lut = 5'd14;  4'd15:lut = 5'd15;
  endcase
  lut16_m29_c0 = lut;
end endfunction

function [4:0] lut16_m29_c1; input [3:0] n; reg [4:0] lut; begin
  case (n)
    4'd0: lut = 5'd0;   4'd1: lut = 5'd16;  4'd2: lut = 5'd3;   4'd3: lut = 5'd19;
    4'd4: lut = 5'd6;   4'd5: lut = 5'd22;  4'd6: lut = 5'd9;   4'd7: lut = 5'd25;
    4'd8: lut = 5'd12;  4'd9: lut = 5'd28;  4'd10:lut = 5'd15;  4'd11:lut = 5'd2;
    4'd12:lut = 5'd18;  4'd13:lut = 5'd5;   4'd14:lut = 5'd21;  4'd15:lut = 5'd8;
  endcase
  lut16_m29_c1 = lut;
end endfunction

function [4:0] lut16_m29_c2; input [3:0] n; reg [4:0] lut; begin
  case (n)
    4'd0: lut = 5'd0;   4'd1: lut = 5'd24;  4'd2: lut = 5'd19;  4'd3: lut = 5'd14;
    4'd4: lut = 5'd9;   4'd5: lut = 5'd4;   4'd6: lut = 5'd28;  4'd7: lut = 5'd23;
    4'd8: lut = 5'd18;  4'd9: lut = 5'd13;  4'd10:lut = 5'd8;   4'd11:lut = 5'd3;
    4'd12:lut = 5'd27;  4'd13:lut = 5'd22;  4'd14:lut = 5'd17;  4'd15:lut = 5'd12;
  endcase
  lut16_m29_c2 = lut;
end endfunction

function [4:0] lut16_m29_c3; input [3:0] n; reg [4:0] lut; begin
  case (n)
    4'd0: lut = 5'd0;   4'd1: lut = 5'd7;   4'd2: lut = 5'd14;  4'd3: lut = 5'd21;
    4'd4: lut = 5'd28;  4'd5: lut = 5'd6;   4'd6: lut = 5'd13;  4'd7: lut = 5'd20;
    4'd8: lut = 5'd27;  4'd9: lut = 5'd5;   4'd10:lut = 5'd12;  4'd11:lut = 5'd19;
    4'd12:lut = 5'd26;  4'd13:lut = 5'd4;   4'd14:lut = 5'd11;  4'd15:lut = 5'd18;
  endcase
  lut16_m29_c3 = lut;
end endfunction


// ============================
// m = 31, c = [1,16,8,4]
// ============================
function [4:0] lut16_m31_c0; input [3:0] n; reg [4:0] lut; begin
  case (n)
    4'd0: lut = 5'd0;   4'd1: lut = 5'd1;   4'd2: lut = 5'd2;   4'd3: lut = 5'd3;
    4'd4: lut = 5'd4;   4'd5: lut = 5'd5;   4'd6: lut = 5'd6;   4'd7: lut = 5'd7;
    4'd8: lut = 5'd8;   4'd9: lut = 5'd9;   4'd10:lut = 5'd10;  4'd11:lut = 5'd11;
    4'd12:lut = 5'd12;  4'd13:lut = 5'd13;  4'd14:lut = 5'd14;  4'd15:lut = 5'd15;
  endcase
  lut16_m31_c0 = lut;
end endfunction

function [4:0] lut16_m31_c1; input [3:0] n; reg [4:0] lut; begin
  case (n)
    4'd0: lut = 5'd0;   4'd1: lut = 5'd16;  4'd2: lut = 5'd1;   4'd3: lut = 5'd17;
    4'd4: lut = 5'd2;   4'd5: lut = 5'd18;  4'd6: lut = 5'd3;   4'd7: lut = 5'd19;
    4'd8: lut = 5'd4;   4'd9: lut = 5'd20;  4'd10:lut = 5'd5;   4'd11:lut = 5'd21;
    4'd12:lut = 5'd6;   4'd13:lut = 5'd22;  4'd14:lut = 5'd7;   4'd15:lut = 5'd23;
  endcase
  lut16_m31_c1 = lut;
end endfunction

function [4:0] lut16_m31_c2; input [3:0] n; reg [4:0] lut; begin
  case (n)
    4'd0: lut = 5'd0;   4'd1: lut = 5'd8;   4'd2: lut = 5'd16;  4'd3: lut = 5'd24;
    4'd4: lut = 5'd1;   4'd5: lut = 5'd9;   4'd6: lut = 5'd17;  4'd7: lut = 5'd25;
    4'd8: lut = 5'd2;   4'd9: lut = 5'd10;  4'd10:lut = 5'd18;  4'd11:lut = 5'd26;
    4'd12:lut = 5'd3;   4'd13:lut = 5'd11;  4'd14:lut = 5'd19;  4'd15:lut = 5'd27;
  endcase
  lut16_m31_c2 = lut;
end endfunction

function [4:0] lut16_m31_c3; input [3:0] n; reg [4:0] lut; begin
  case (n)
    4'd0: lut = 5'd0;   4'd1: lut = 5'd4;   4'd2: lut = 5'd8;   4'd3: lut = 5'd12;
    4'd4: lut = 5'd16;  4'd5: lut = 5'd20;  4'd6: lut = 5'd24;  4'd7: lut = 5'd28;
    4'd8: lut = 5'd1;   4'd9: lut = 5'd5;   4'd10:lut = 5'd9;   4'd11:lut = 5'd13;
    4'd12:lut = 5'd17;  4'd13:lut = 5'd21;  4'd14:lut = 5'd25;  4'd15:lut = 5'd29;
  endcase
  lut16_m31_c3 = lut;
end endfunction


function [4:0] reduce_sum_mod7;
  input [7:0] t; reg [7:0] s;
begin
  s = t;
  if (s >= 8'd21) s = s - 8'd21;
  else if (s >= 8'd14) s = s - 8'd14;
  else if (s >= 8'd7 ) s = s - 8'd7;
  reduce_sum_mod7 = s[4:0];
end
endfunction

function [4:0] reduce_sum_mod11;
  input [7:0] t; reg [7:0] s;
begin
  s = t;
  if (s >= 8'd33) s = s - 8'd33;
  else if (s >= 8'd22) s = s - 8'd22;
  else if (s >= 8'd11) s = s - 8'd11;
  reduce_sum_mod11 = s[4:0];
end
endfunction

function [4:0] reduce_sum_mod13;
  input [7:0] t; reg [7:0] s;  // (paramètre m supprimé)
begin
  s = t;
  if (s >= 8'd39) s = s - 8'd39;
  else if (s >= 8'd26) s = s - 8'd26;
  else if (s >= 8'd13) s = s - 8'd13;
  reduce_sum_mod13 = s[4:0];
end
endfunction

function [4:0] reduce_sum_mod15;
  input [7:0] t; reg [7:0] s;
begin
  s = t;
  if (s >= 8'd45) s = s - 8'd45;
  else if (s >= 8'd30) s = s - 8'd30;
  else if (s >= 8'd15) s = s - 8'd15;
  reduce_sum_mod15 = s[4:0];
end
endfunction

function [4:0] reduce_sum_mod17;
  input [7:0] t; reg [7:0] s;
begin
  s = t;
  if (s >= 8'd51) s = s - 8'd51;
  else if (s >= 8'd34) s = s - 8'd34;
  else if (s >= 8'd17) s = s - 8'd17;
  reduce_sum_mod17 = s[4:0];
end
endfunction

function [4:0] reduce_sum_mod19;
  input [7:0] t; reg [7:0] s;
begin
  s = t;
  if (s >= 8'd57) s = s - 8'd57;
  else if (s >= 8'd38) s = s - 8'd38;
  else if (s >= 8'd19) s = s - 8'd19;
  reduce_sum_mod19 = s[4:0];
end
endfunction

function [4:0] reduce_sum_mod23;
  input [7:0] t; reg [7:0] s;
begin
  s = t;
  if (s >= 8'd69) s = s - 8'd69;
  else if (s >= 8'd46) s = s - 8'd46;
  else if (s >= 8'd23) s = s - 8'd23;
  reduce_sum_mod23 = s[4:0];
end
endfunction

function [4:0] reduce_sum_mod29;
  input [7:0] t; reg [7:0] s;
begin
  s = t;
  if (s >= 8'd87) s = s - 8'd87;
  else if (s >= 8'd58) s = s - 8'd58;
  else if (s >= 8'd29) s = s - 8'd29;
  reduce_sum_mod29 = s[4:0];
end
endfunction

function [4:0] reduce_sum_mod31;
  input [7:0] t; reg [7:0] s;
begin
  s = t;
  if (s >= 8'd93) s = s - 8'd93;
  else if (s >= 8'd62) s = s - 8'd62;
  else if (s >= 8'd31) s = s - 8'd31;
  reduce_sum_mod31 = s[4:0];
end
endfunction
  

  always @(posedge clk) begin
    if (!rst_n) begin
      v1 <= 1'b0;
      r7<=0; r11<=0; r13<=0; r15<=0; r17<=0; r19<=0; r23<=0; r29<=0; r31<=0;
    end else begin
      v1 <= v0;
      if (v0) begin
        // r_m = sum_i LUT(c_i * nibble_i) mod m
        r7  <= reduce_sum_mod7( lut16_m7_c0(n0)+lut16_m7_c1(n1)+lut16_m7_c2(n2)+lut16_m7_c3(n3));
        r11 <= reduce_sum_mod11( lut16_m11_c0(n0)+lut16_m11_c1(n1)+lut16_m11_c2(n2)+lut16_m11_c3(n3));
        r13 <= reduce_sum_mod13( lut16_m13_c0(n0)+lut16_m13_c1(n1)+lut16_m13_c2(n2)+lut16_m13_c3(n3));
        r15 <= reduce_sum_mod15( lut16_m15_c0(n0)+lut16_m15_c1(n1)+lut16_m15_c2(n2)+lut16_m15_c3(n3));
        r17 <= reduce_sum_mod17( lut16_m17_c0(n0)+lut16_m17_c1(n1)+lut16_m17_c2(n2)+lut16_m17_c3(n3));
        r19 <= reduce_sum_mod19( lut16_m19_c0(n0)+lut16_m19_c1(n1)+lut16_m19_c2(n2)+lut16_m19_c3(n3));
        r23 <= reduce_sum_mod23( lut16_m23_c0(n0)+lut16_m23_c1(n1)+lut16_m23_c2(n2)+lut16_m23_c3(n3));
        r29 <= reduce_sum_mod29( lut16_m29_c0(n0)+lut16_m29_c1(n1)+lut16_m29_c2(n2)+lut16_m29_c3(n3));
        r31 <= reduce_sum_mod31( lut16_m31_c0(n0)+lut16_m31_c1(n1)+lut16_m31_c2(n2)+lut16_m31_c3(n3));
      end
    end
  end

  // ====================================================
  // Phase 3 — Opération (+2) en RNS (neuf moduli)
  // ====================================================
  reg        v2;
  reg  [4:0] r7p, r11p, r13p, r15p, r17p, r19p, r23p, r29p, r31p;

  function [4:0] add_mod2; input [4:0] a; input [5:0] m; reg [5:0] t; begin
    t = {1'b0,a} + 6'd2;
    if (t >= m) t = t - m;
    add_mod2 = t[4:0];
  end endfunction

  always @(posedge clk) begin
    if (!rst_n) begin
      v2 <= 1'b0;
      r7p<=0;r11p<=0;r13p<=0;r15p<=0;r17p<=0;r19p<=0;r23p<=0;r29p<=0;r31p<=0;
    end else begin
      v2 <= v1;
      if (v1) begin
        r7p  <= add_mod2(r7 ,  6'd7 );
        r11p <= add_mod2(r11,  6'd11);
        r13p <= add_mod2(r13,  6'd13);
        r15p <= add_mod2(r15,  6'd15);
        r17p <= add_mod2(r17,  6'd17);
        r19p <= add_mod2(r19,  6'd19);
        r23p <= add_mod2(r23,  6'd23);
        r29p <= add_mod2(r29,  6'd29);
        r31p <= add_mod2(r31,  6'd31);
      end
    end
  end

// ====================================================
// Phase 4 — CRT pipeliné "mod M" à chaque addition
// ====================================================
localparam [36:0] M = 37'd100280245065;

// Addition modulaire : retourne (a+b) mod M
function [36:0] add_modM;
  input [36:0] a, b;
  reg   [37:0] s;   // 0..(2*M-2) < 2^38
begin
  s = {1'b0,a} + {1'b0,b};
  if (s >= {1'b0,M}) s = s - {1'b0,M};
  add_modM = s[36:0];
end
endfunction

// ---- 4a: ROMs T* -> registres (37b) ----
reg        v3a;
reg [36:0] T7_r, T11_r, T13_r, T15_r, T17_r, T19_r, T23_r, T29_r, T31_r;
always @(posedge clk) begin
  if (!rst_n) begin
    v3a<=1'b0;
    T7_r<=0; T11_r<=0; T13_r<=0; T15_r<=0; T17_r<=0; T19_r<=0; T23_r<=0; T29_r<=0; T31_r<=0;
  end else begin
    v3a <= v2;
    if (v2) begin
      T7_r  <= T7 (r7p );
      T11_r <= T11(r11p);
      T13_r <= T13(r13p);
      T15_r <= T15(r15p);
      T17_r <= T17(r17p);
      T19_r <= T19(r19p);
      T23_r <= T23(r23p);
      T29_r <= T29(r29p);
      T31_r <= T31(r31p);
    end
  end
end

// ---- 4b: niveau 1 (première addition + lecture LUT) -> registres (37b) ----
reg        v3b;
reg [36:0] L1a, L1b, L1c, L1d, L1e;
always @(posedge clk) begin
  if (!rst_n) begin
    v3b<=1'b0; L1a<=0; L1b<=0; L1c<=0; L1d<=0; L1e<=0;
  end else begin
    v3b <= v3a;
    if (v3a) begin
      L1a <= add_modM(T7_r , T11_r);
      L1b <= add_modM(T13_r, T15_r);
      L1c <= add_modM(T17_r, T19_r);
      L1d <= add_modM(T23_r, T29_r);
      L1e <= T31_r; // branche seule
    end
  end
end

// ---- 4c: niveau 2 -> registres (37b) ----
reg        v3c;
reg [36:0] L2a, L2b, L2e;
always @(posedge clk) begin
  if (!rst_n) begin
    v3c<=1'b0; L2a<=0; L2b<=0; L2e<=0;
  end else begin
    v3c <= v3b;
    if (v3b) begin
      L2a <= add_modM(L1a, L1b);
      L2b <= add_modM(L1c, L1d);
      L2e <= L1e;            // alignement pipeline
    end
  end
end

// ---- 4d: (L2a + L2b) mod M -> registre --------
reg        v4;
reg [36:0] S4_mod;
reg [15:0] y4;
reg        v3d;
reg [36:0] sum_ab;
always @(posedge clk) begin
  if (!rst_n) begin
    v3d   <= 1'b0;
    sum_ab<= 37'd0;
  end else begin
    v3d <= v3c;
    if (v3c) sum_ab <= add_modM(L2a, L2b);
  end
end

// ---- 4e: (sum_ab + L2e) mod M -> S4_mod / y4 ----
wire [36:0] S4_mod_next = add_modM(sum_ab, L2e);

always @(posedge clk) begin
  if (!rst_n) begin
    v4     <= 1'b0;
    S4_mod <= 37'd0;
    y4     <= 16'd0;
  end else begin
    v4 <= v3d;                    // alignement de la validité
    if (v3d) begin
      S4_mod <= S4_mod_next;
      y4     <= S4_mod_next[15:0];
    end
  end
end

  
    // ====================================================
  // Phase 5 — Skid buffer de sortie (handshake propre)
  // ====================================================
  reg  [15:0] y5;
  reg         v5;

  // Prêt interne : on (ré)charge le buffer si vide ou si le consommateur avance
  wire s5_ready = (~v5) | out_ready;

  always @(posedge clk) begin
    if (!rst_n) begin
      v5        <= 1'b0;
      y5        <= 16'd0;
      out_valid <= 1'b0;
      out_word  <= 16'd0;
    end else begin
      // Capture depuis Phase 4 quand le buffer peut avancer
      if (s5_ready) begin
        v5 <= v4;
        if (v4) y5 <= y4;
      end

      // Publication
      out_valid <= v5;
      out_word  <= y5;
    end
  end



  // Mini-ROMs Ti: (r * A_i) % P   — ordonné: 7,11,13,15,17,19,23,29,31
  function [36:0] T7;
  input [4:0] r;
  begin
    case (r)
      5'd0  : T7 = 37'd0;
      5'd1  : T7 = 37'd28651498590;
      5'd2  : T7 = 37'd57302997180;
      5'd3  : T7 = 37'd85954495770;
      5'd4  : T7 = 37'd14325749295;
      5'd5  : T7 = 37'd42977247885;
      5'd6  : T7 = 37'd71628746475;
      default: T7 = 37'd0;
    endcase
  end
endfunction

function [36:0] T11;
  input [4:0] r;
  begin
    case (r)
      5'd0  : T11 = 37'd0;
      5'd1  : T11 = 37'd91163859150;
      5'd2  : T11 = 37'd82047473235;
      5'd3  : T11 = 37'd72931087320;
      5'd4  : T11 = 37'd63814701405;
      5'd5  : T11 = 37'd54698315490;
      5'd6  : T11 = 37'd45581929575;
      5'd7  : T11 = 37'd36465543660;
      5'd8  : T11 = 37'd27349157745;
      5'd9  : T11 = 37'd18232771830;
      5'd10 : T11 = 37'd9116385915;
      default: T11 = 37'd0;
    endcase
  end
endfunction

function [36:0] T13;
  input [4:0] r;
  begin
    case (r)
      5'd0  : T13 = 37'd0;
      5'd1  : T13 = 37'd53997055035;
      5'd2  : T13 = 37'd7713865005;
      5'd3  : T13 = 37'd61710920040;
      5'd4  : T13 = 37'd15427730010;
      5'd5  : T13 = 37'd69424785045;
      5'd6  : T13 = 37'd23141595015;
      5'd7  : T13 = 37'd77138650050;
      5'd8  : T13 = 37'd30855460020;
      5'd9  : T13 = 37'd84852515055;
      5'd10 : T13 = 37'd38569325025;
      5'd11 : T13 = 37'd92566380060;
      5'd12 : T13 = 37'd46283190030;
      default: T13 = 37'd0;
    endcase
  end
endfunction

function [36:0] T15;
  input [4:0] r;
  begin
    case (r)
      5'd0  : T15 = 37'd0;
      5'd1  : T15 = 37'd6685349671;
      5'd2  : T15 = 37'd13370699342;
      5'd3  : T15 = 37'd20056049013;
      5'd4  : T15 = 37'd26741398684;
      5'd5  : T15 = 37'd33426748355;
      5'd6  : T15 = 37'd40112098026;
      5'd7  : T15 = 37'd46797447697;
      5'd8  : T15 = 37'd53482797368;
      5'd9  : T15 = 37'd60168147039;
      5'd10 : T15 = 37'd66853496710;
      5'd11 : T15 = 37'd73538846381;
      5'd12 : T15 = 37'd80224196052;
      5'd13 : T15 = 37'd86909545723;
      5'd14 : T15 = 37'd93594895394;
      default: T15 = 37'd0;
    endcase
  end
endfunction

function [36:0] T17;
  input [4:0] r;
  begin
    case (r)
      5'd0  : T17 = 37'd0;
      5'd1  : T17 = 37'd17696513835;
      5'd2  : T17 = 37'd35393027670;
      5'd3  : T17 = 37'd53089541505;
      5'd4  : T17 = 37'd70786055340;
      5'd5  : T17 = 37'd88482569175;
      5'd6  : T17 = 37'd5898837945;
      5'd7  : T17 = 37'd23595351780;
      5'd8  : T17 = 37'd41291865615;
      5'd9  : T17 = 37'd58988379450;
      5'd10 : T17 = 37'd76684893285;
      5'd11 : T17 = 37'd94381407120;
      5'd12 : T17 = 37'd11797675890;
      5'd13 : T17 = 37'd29494189725;
      5'd14 : T17 = 37'd47190703560;
      5'd15 : T17 = 37'd64887217395;
      5'd16 : T17 = 37'd82583731230;
      default: T17 = 37'd0;
    endcase
  end
endfunction

function [36:0] T19;
  input [4:0] r;
  begin
    case (r)
      5'd0  : T19 = 37'd0;
      5'd1  : T19 = 37'd58056983985;
      5'd2  : T19 = 37'd15833722905;
      5'd3  : T19 = 37'd73890706890;
      5'd4  : T19 = 37'd31667445810;
      5'd5  : T19 = 37'd89724429795;
      5'd6  : T19 = 37'd47501168715;
      5'd7  : T19 = 37'd5277907635;
      5'd8  : T19 = 37'd63334891620;
      5'd9  : T19 = 37'd21111630540;
      5'd10 : T19 = 37'd79168614525;
      5'd11 : T19 = 37'd36945353445;
      5'd12 : T19 = 37'd95002337430;
      5'd13 : T19 = 37'd52779076350;
      5'd14 : T19 = 37'd10555815270;
      5'd15 : T19 = 37'd68612799255;
      5'd16 : T19 = 37'd26389538175;
      5'd17 : T19 = 37'd84446522160;
      5'd18 : T19 = 37'd42223261080;
      default: T19 = 37'd0;
    endcase
  end
endfunction

function [36:0] T23;
  input [4:0] r;
  begin
    case (r)
      5'd0  : T23 = 37'd0;
      5'd1  : T23 = 37'd87200213100;
      5'd2  : T23 = 37'd74120181135;
      5'd3  : T23 = 37'd61040149170;
      5'd4  : T23 = 37'd47960117205;
      5'd5  : T23 = 37'd34880085240;
      5'd6  : T23 = 37'd21800053275;
      5'd7  : T23 = 37'd8720021310;
      5'd8  : T23 = 37'd95920234410;
      5'd9  : T23 = 37'd82840202445;
      5'd10 : T23 = 37'd69760170480;
      5'd11 : T23 = 37'd56680138515;
      5'd12 : T23 = 37'd43600106550;
      5'd13 : T23 = 37'd30520074585;
      5'd14 : T23 = 37'd17440042620;
      5'd15 : T23 = 37'd4360010655;
      5'd16 : T23 = 37'd91560223755;
      5'd17 : T23 = 37'd78480191790;
      5'd18 : T23 = 37'd65400159825;
      5'd19 : T23 = 37'd52320127860;
      5'd20 : T23 = 37'd39240095895;
      5'd21 : T23 = 37'd26160063930;
      5'd22 : T23 = 37'd13080031965;
      default: T23 = 37'd0;
    endcase
  end
endfunction

function [36:0] T29;
  input [4:0] r;
  begin
    case (r)
      5'd0  : T29 = 37'd0;
      5'd1  : T29 = 37'd41495273820;
      5'd2  : T29 = 37'd82990547640;
      5'd3  : T29 = 37'd24205576395;
      5'd4  : T29 = 37'd65700850215;
      5'd5  : T29 = 37'd6915878970;
      5'd6  : T29 = 37'd48411152790;
      5'd7  : T29 = 37'd89906426610;
      5'd8  : T29 = 37'd31121455365;
      5'd9  : T29 = 37'd72616729185;
      5'd10 : T29 = 37'd13831757940;
      5'd11 : T29 = 37'd55327031760;
      5'd12 : T29 = 37'd96822305580;
      5'd13 : T29 = 37'd38037334335;
      5'd14 : T29 = 37'd79532608155;
      5'd15 : T29 = 37'd20747636910;
      5'd16 : T29 = 37'd62242910730;
      5'd17 : T29 = 37'd3457939485;
      5'd18 : T29 = 37'd44953213305;
      5'd19 : T29 = 37'd86448487125;
      5'd20 : T29 = 37'd27663515880;
      5'd21 : T29 = 37'd69158789700;
      5'd22 : T29 = 37'd10373818455;
      5'd23 : T29 = 37'd51869092275;
      5'd24 : T29 = 37'd93364366095;
      5'd25 : T29 = 37'd34579394850;
      5'd26 : T29 = 37'd76074668670;
      5'd27 : T29 = 37'd17289697425;
      5'd28 : T29 = 37'd58784971245;
      default: T29 = 37'd0;
    endcase
  end
endfunction

function [36:0] T31;
  input [4:0] r;
  begin
    case (r)
      5'd0  : T31 = 37'd0;
      5'd1  : T31 = 37'd16174233075;
      5'd2  : T31 = 37'd32348466150;
      5'd3  : T31 = 37'd48522699225;
      5'd4  : T31 = 37'd64696932300;
      5'd5  : T31 = 37'd80871165375;
      5'd6  : T31 = 37'd97045398450;
      5'd7  : T31 = 37'd12939386460;
      5'd8  : T31 = 37'd29113619535;
      5'd9  : T31 = 37'd45287852610;
      5'd10 : T31 = 37'd61462085685;
      5'd11 : T31 = 37'd77636318760;
      5'd12 : T31 = 37'd93810551835;
      5'd13 : T31 = 37'd9704539845;
      5'd14 : T31 = 37'd25878772920;
      5'd15 : T31 = 37'd42053005995;
      5'd16 : T31 = 37'd58227239070;
      5'd17 : T31 = 37'd74401472145;
      5'd18 : T31 = 37'd90575705220;
      5'd19 : T31 = 37'd6469693230;
      5'd20 : T31 = 37'd22643926305;
      5'd21 : T31 = 37'd38818159380;
      5'd22 : T31 = 37'd54992392455;
      5'd23 : T31 = 37'd71166625530;
      5'd24 : T31 = 37'd87340858605;
      5'd25 : T31 = 37'd3234846615;
      5'd26 : T31 = 37'd19409079690;
      5'd27 : T31 = 37'd35583312765;
      5'd28 : T31 = 37'd51757545840;
      5'd29 : T31 = 37'd67931778915;
      5'd30 : T31 = 37'd84106011990;
      default: T31 = 37'd0;
    endcase
  end
endfunction
endmodule 

`default_nettype wire