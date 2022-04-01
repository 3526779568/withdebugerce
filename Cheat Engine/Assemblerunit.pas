unit Assemblerunit;

//todo: case

{$MODE Delphi}

interface

{$ifdef jni}
uses  sysutils, ProcessHandlerUnit;
{$endif}

{$ifdef windows}
uses dialogs,LCLIntf,sysutils,imagehlp, ProcessHandlerUnit;
{$endif}

const opcodecount=1104; //I wish there was a easier way than to handcount



type TTokenType=(
  ttInvalidtoken, ttRegister8Bit, ttRegister16Bit, ttRegister32Bit, ttRegister64Bit, ttRegister8BitWithPrefix, //ttRegister64Bit and ttRegister8BitWithPrefix is just internal to set the rexflags
  ttRegisterMM, ttRegisterXMM, ttRegisterST, ttRegisterSreg,
  ttRegisterCR, ttRegisterDR, ttMemoryLocation, ttMemoryLocation8,
  ttMemoryLocation16, ttMemoryLocation32, ttMemoryLocation64,
  ttMemoryLocation80, ttMemoryLocation128, ttValue);


//opcode part (bytes)
type Textraopcode=(eo_none,
                   eo_reg0,eo_reg1,eo_reg2,eo_reg3,eo_reg4,eo_reg5,eo_reg6,eo_reg7, // /digit
                   eo_reg, //  /r
                   eo_cb,eo_cw,eo_cd,eo_cp,
                   eo_ib,eo_iw,eo_id,
                   eo_prb,eo_prw,eo_prd,
                   eo_pi
                  );


//parameter part
type tparam=(par_noparam,
             //constant
             par_1,
             par_3,
             par_al,
             par_ax,
             par_eax,
             par_cl,
             par_dx,
             par_cs,
             par_ds,
             par_es,
             par_ss,
             par_fs,
             par_gs,
             //regs
             par_r8,
             par_r16,
             par_r32,
             par_r64, //just for a few occasions
             par_mm,
             par_xmm,
             par_st,
             par_st0,
             par_sreg,
             par_cr,
             par_dr,
             //memorylocs
             par_m8,
             par_m16,
             par_m32,
             par_m64,
             par_m80,
             par_m128,
             par_moffs8,
             par_moffs16,
             par_moffs32,
             //regs+memorylocs
             par_rm8,
             par_rm16,
             par_rm32,
             par_r32_m16,
             par_mm_m32,
             par_mm_m64,
             par_xmm_m32,
             par_xmm_m64,
             par_xmm_m128,

            //values
             par_imm8,
             par_imm16,
             par_imm32,
             //relatives
             par_rel8,
             par_rel16,
             par_rel32);

type topcode=record
  mnemonic: string;
  opcode1,opcode2: textraopcode;
  paramtype1,paramtype2,paramtype3: tparam;
  bytes:byte;
  bt1,bt2,bt3,bt4: byte;
  signed: boolean;
  norexw: boolean;
  invalidin64bit: boolean;
  invalidin32bit: boolean;
  canDoAddressSwitch: boolean; //does it support the 0x67 address switch (e.g lea)
  defaulttype: boolean;
 // RexPrefixOffset: byte; //if specified specifies which byte should be used for the rexw (e.g f3 before rex )
end;


const opcodes: array [1..opcodecount] of topcode =(
{ok}  (mnemonic:'AAA';opcode1:eo_none;opcode2:eo_none;paramtype1:par_noparam;paramtype2:par_noparam;paramtype3:par_noparam;bytes:1;bt1:$37;bt2:0;bt3:0), //no param
{ok}  (mnemonic:'AAD';opcode1:eo_none;opcode2:eo_none;paramtype1:par_noparam;paramtype2:par_noparam;paramtype3:par_noparam;bytes:2;bt1:$d5;bt2:$0a;bt3:0),
{ok}  (mnemonic:'AAD';opcode1:eo_ib;opcode2:eo_none;paramtype1:par_imm8;paramtype2:par_noparam;paramtype3:par_noparam;bytes:1;bt1:$d5;bt2:0;bt3:0),
{ok}  (mnemonic:'AAM';opcode1:eo_none;paramtype1:par_noparam;bytes:2;bt1:$d4;bt2:$0a),
{ok}  (mnemonic:'AAM';opcode1:eo_ib;paramtype1:par_imm8;bytes:1;bt1:$d4),
{ok}  (mnemonic:'AAS';opcode1:eo_none;paramtype1:par_noparam;bytes:1;bt1:$3F),
{ok}  (mnemonic:'ADC';opcode1:eo_ib;paramtype1:par_AL;paramtype2:par_imm8;bytes:1;bt1:$14),
{ok}  (mnemonic:'ADC';opcode1:eo_iw;paramtype1:par_AX;paramtype2:par_imm16;bytes:2;bt1:$66;bt2:$15),
{ok}  (mnemonic:'ADC';opcode1:eo_id;paramtype1:par_EAX;paramtype2:par_imm32;bytes:1;bt1:$15),
{ok}  (mnemonic:'ADC';opcode1:eo_reg2;opcode2:eo_ib;paramtype1:par_rm8;paramtype2:par_imm8;bytes:1;bt1:$80),//verified
  (mnemonic:'ADC';opcode1:eo_reg2;opcode2:eo_iw;paramtype1:par_rm16;paramtype2:par_imm16;bytes:2;bt1:$66;bt2:$81),
  (mnemonic:'ADC';opcode1:eo_reg2;opcode2:eo_id;paramtype1:par_rm32;paramtype2:par_imm32;bytes:1;bt1:$81),
  (mnemonic:'ADC';opcode1:eo_reg2;opcode2:eo_ib;paramtype1:par_rm16;paramtype2:par_imm8;bytes:2;bt1:$66;bt2:$83; signed: true),
  (mnemonic:'ADC';opcode1:eo_reg2;opcode2:eo_ib;paramtype1:par_rm32;paramtype2:par_imm8;bytes:1;bt1:$83; signed: true),
  (mnemonic:'ADC';opcode1:eo_reg;paramtype1:par_rm8;paramtype2:par_r8;bytes:1;bt1:$10),
  (mnemonic:'ADC';opcode1:eo_reg;paramtype1:par_rm16;paramtype2:par_r16;bytes:2;bt1:$66;bt2:$11),
  (mnemonic:'ADC';opcode1:eo_reg;paramtype1:par_rm32;paramtype2:par_r32;bytes:1;bt1:$11),
  (mnemonic:'ADC';opcode1:eo_reg;paramtype1:par_r8;paramtype2:par_rm8;bytes:1;bt1:$12),
  (mnemonic:'ADC';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:2;bt1:$66;bt2:$13),
  (mnemonic:'ADC';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:1;bt1:$13),

  (mnemonic:'ADD';opcode1:eo_ib;paramtype1:par_AL;paramtype2:par_imm8;bytes:1;bt1:$04),
  (mnemonic:'ADD';opcode1:eo_iw;paramtype1:par_AX;paramtype2:par_imm16;bytes:2;bt1:$66;bt2:$05),
  (mnemonic:'ADD';opcode1:eo_id;paramtype1:par_EAX;paramtype2:par_imm32;bytes:1;bt1:$05),
  (mnemonic:'ADD';opcode1:eo_reg0;opcode2:eo_ib;paramtype1:par_rm8;paramtype2:par_imm8;bytes:1;bt1:$80),
  (mnemonic:'ADD';opcode1:eo_reg0;opcode2:eo_iw;paramtype1:par_rm16;paramtype2:par_imm16;bytes:2;bt1:$66;bt2:$81),
  (mnemonic:'ADD';opcode1:eo_reg0;opcode2:eo_id;paramtype1:par_rm32;paramtype2:par_imm32;bytes:1;bt1:$81),
  (mnemonic:'ADD';opcode1:eo_reg0;opcode2:eo_ib;paramtype1:par_rm16;paramtype2:par_imm8;bytes:2;bt1:$66;bt2:$83; signed: true),
  (mnemonic:'ADD';opcode1:eo_reg0;opcode2:eo_ib;paramtype1:par_rm32;paramtype2:par_imm8;bytes:1;bt1:$83; signed: true),
  (mnemonic:'ADD';opcode1:eo_reg;paramtype1:par_rm32;paramtype2:par_r32;bytes:1;bt1:$01),
  (mnemonic:'ADD';opcode1:eo_reg;paramtype1:par_rm16;paramtype2:par_r16;bytes:2;bt1:$66;bt2:$01),
  (mnemonic:'ADD';opcode1:eo_reg;paramtype1:par_rm8;paramtype2:par_r8;bytes:1;bt1:$00),
  (mnemonic:'ADD';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:1;bt1:$03),
  (mnemonic:'ADD';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:2;bt1:$66;bt2:$03),
  (mnemonic:'ADD';opcode1:eo_reg;paramtype1:par_r8;paramtype2:par_rm8;bytes:1;bt1:$02),

  (mnemonic:'ADDPD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$58), //should be xmm1,xmm2/m128 but is also handled in all the others, in fact all other modrm types have it, hmmmmm....
  (mnemonic:'ADDPS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:2;bt1:$0f;bt2:$58), //I gues all reg,reg/mem can be handled like this. (oh well, i'm too lazy to change the code)
  (mnemonic:'ADDSD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m64;bytes:3;bt1:$f2;bt2:$0f;bt3:$58),
  (mnemonic:'ADDSS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m32;bytes:3;bt1:$f3;bt2:$0f;bt3:$58),

  (mnemonic:'AND';opcode1:eo_ib;paramtype1:par_AL;paramtype2:par_imm8;bytes:1;bt1:$24),
  (mnemonic:'AND';opcode1:eo_iw;paramtype1:par_AX;paramtype2:par_imm16;bytes:2;bt1:$66;bt2:$25),
  (mnemonic:'AND';opcode1:eo_id;paramtype1:par_EAX;paramtype2:par_imm32;bytes:1;bt1:$25),
  (mnemonic:'AND';opcode1:eo_reg4;opcode2:eo_ib;paramtype1:par_rm8;paramtype2:par_imm8;bytes:1;bt1:$80),
  (mnemonic:'AND';opcode1:eo_reg4;opcode2:eo_iw;paramtype1:par_rm16;paramtype2:par_imm16;bytes:2;bt1:$66;bt2:$81),
  (mnemonic:'AND';opcode1:eo_reg4;opcode2:eo_id;paramtype1:par_rm32;paramtype2:par_imm32;bytes:1;bt1:$81),
  (mnemonic:'AND';opcode1:eo_reg4;opcode2:eo_ib;paramtype1:par_rm16;paramtype2:par_imm8;bytes:2;bt1:$66;bt2:$83; signed: true),
  (mnemonic:'AND';opcode1:eo_reg4;opcode2:eo_ib;paramtype1:par_rm32;paramtype2:par_imm8;bytes:1;bt1:$83; signed: true),
  (mnemonic:'AND';opcode1:eo_reg;paramtype1:par_rm8;paramtype2:par_r8;bytes:1;bt1:$20),
  (mnemonic:'AND';opcode1:eo_reg;paramtype1:par_rm16;paramtype2:par_r16;bytes:2;bt1:$66;bt2:$21),
  (mnemonic:'AND';opcode1:eo_reg;paramtype1:par_rm32;paramtype2:par_r32;bytes:1;bt1:$21),
  (mnemonic:'AND';opcode1:eo_reg;paramtype1:par_r8;paramtype2:par_rm8;bytes:1;bt1:$22),
  (mnemonic:'AND';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:2;bt1:$66;bt2:$23),
  (mnemonic:'AND';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:1;bt1:$23),

  (mnemonic:'ANDNPD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$ff),
  (mnemonic:'ANDNPS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:2;bt1:$0f;bt2:$55),

  (mnemonic:'ANDPD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$54),
  (mnemonic:'ANDPS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:2;bt1:$0f;bt2:$54),

  (mnemonic:'ARPL';opcode1:eo_reg;paramtype1:par_rm16;paramtype2:par_r16;bytes:1;bt1:$63), //eo_reg means I just need to find the reg and address
  (mnemonic:'BOUND';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:2;bt1:$66;bt2:$62),
  (mnemonic:'BOUND';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:1;bt1:$62),
  (mnemonic:'BSF';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$bc),
  (mnemonic:'BSF';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$bc),
  (mnemonic:'BSR';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$bd),
  (mnemonic:'BSR';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$bd),
  (mnemonic:'BSWAP';opcode1:eo_prd;paramtype1:par_r32;bytes:2;bt1:$0f;bt2:$c8), //eo_prd
  (mnemonic:'BSWAP';opcode1:eo_prw;paramtype1:par_r16;bytes:3;bt1:$66;bt2:$0f;bt3:$c8), //eo_prw

  (mnemonic:'BT';opcode1:eo_reg;paramtype1:par_rm16;paramtype2:par_r16;bytes:3;bt1:$66;bt2:$0f;bt3:$a3),
  (mnemonic:'BT';opcode1:eo_reg;paramtype1:par_rm32;paramtype2:par_r32;bytes:2;bt1:$0f;bt2:$a3),
  (mnemonic:'BT';opcode1:eo_reg4;opcode2:eo_ib;paramtype1:par_rm16;paramtype2:par_imm8;bytes:3;bt1:$66;bt2:$0f;bt3:$ba),
  (mnemonic:'BT';opcode1:eo_reg4;opcode2:eo_ib;paramtype1:par_rm32;paramtype2:par_imm8;bytes:2;bt1:$0f;bt2:$ba),

  (mnemonic:'BTC';opcode1:eo_reg;paramtype1:par_rm16;paramtype2:par_r16;bytes:3;bt1:$66;bt2:$0f;bt3:$bb),
  (mnemonic:'BTC';opcode1:eo_reg;paramtype1:par_rm32;paramtype2:par_r32;bytes:2;bt1:$0f;bt2:$bb),
  (mnemonic:'BTC';opcode1:eo_reg7;opcode2:eo_ib;paramtype1:par_rm16;paramtype2:par_imm8;bytes:3;bt1:$66;bt2:$0f;bt3:$ba),
  (mnemonic:'BTC';opcode1:eo_reg7;opcode2:eo_ib;paramtype1:par_rm32;paramtype2:par_imm8;bytes:2;bt1:$0f;bt2:$ba),

  (mnemonic:'BTR';opcode1:eo_reg;paramtype1:par_rm16;paramtype2:par_r16;bytes:3;bt1:$66;bt2:$0f;bt3:$b3),
  (mnemonic:'BTR';opcode1:eo_reg;paramtype1:par_rm32;paramtype2:par_r32;bytes:2;bt1:$0f;bt2:$b3),
  (mnemonic:'BTR';opcode1:eo_reg6;opcode2:eo_ib;paramtype1:par_rm16;paramtype2:par_imm8;bytes:3;bt1:$66;bt2:$0f;bt3:$ba),
  (mnemonic:'BTR';opcode1:eo_reg6;opcode2:eo_ib;paramtype1:par_rm32;paramtype2:par_imm8;bytes:2;bt1:$0f;bt2:$ba),

  (mnemonic:'BTS';opcode1:eo_reg;paramtype1:par_rm16;paramtype2:par_r16;bytes:3;bt1:$66;bt2:$0f;bt3:$ab),
  (mnemonic:'BTS';opcode1:eo_reg;paramtype1:par_rm32;paramtype2:par_r32;bytes:2;bt1:$0f;bt2:$ab),
  (mnemonic:'BTS';opcode1:eo_reg5;opcode2:eo_ib;paramtype1:par_rm16;paramtype2:par_imm8;bytes:3;bt1:$66;bt2:$0f;bt3:$ba),
  (mnemonic:'BTS';opcode1:eo_reg5;opcode2:eo_ib;paramtype1:par_rm32;paramtype2:par_imm8;bytes:2;bt1:$0f;bt2:$ba),
  //no $66 $E8 because it makes the address it jumps to 16 bit
  (mnemonic:'CALL';opcode1:eo_cd;paramtype1:par_rel32;bytes:1;bt1:$e8),
  //also no $66 $ff /2
  (mnemonic:'CALL';opcode1:eo_reg2;paramtype1:par_rm32;bytes:1;bt1:$ff;norexw:true),
  (mnemonic:'CBW';opcode1:eo_none;paramtype1:par_noparam;bytes:2;bt1:$66;bt2:$98),
  (mnemonic:'CDQ';bytes:1;bt1:$99),
  (mnemonic:'CDQE';bytes:2;bt1:$48;bt2:$98),

  (mnemonic:'CLC';bytes:1;bt1:$f8),
  (mnemonic:'CLD';bytes:1;bt1:$fc),
  (mnemonic:'CLFLUSH';opcode1:eo_reg7;paramtype1:par_m8;bytes:2;bt1:$0f;bt2:$ae),
  (mnemonic:'CLI';bytes:1;bt1:$fa),
  (mnemonic:'CLTS';bytes:2;bt1:$0f;bt2:$06),
  (mnemonic:'CMC';bytes:1;bt1:$f5),
  (mnemonic:'CMOVA';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$47),
  (mnemonic:'CMOVA';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$47),
  (mnemonic:'CMOVAE';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$43),
  (mnemonic:'CMOVAE';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$43),
  (mnemonic:'CMOVB';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$42),
  (mnemonic:'CMOVB';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$42),
  (mnemonic:'CMOVBE';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$46),
  (mnemonic:'CMOVBE';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$46),
  (mnemonic:'CMOVC';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$42),
  (mnemonic:'CMOVC';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$42),
  (mnemonic:'CMOVE';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$44),
  (mnemonic:'CMOVE';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$44),
  (mnemonic:'CMOVG';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$4f),
  (mnemonic:'CMOVG';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$4f),
  (mnemonic:'CMOVGE';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$4d),
  (mnemonic:'CMOVGE';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$4d),
  (mnemonic:'CMOVL';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$4c),
  (mnemonic:'CMOVL';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$4c),
  (mnemonic:'CMOVLE';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$4e),
  (mnemonic:'CMOVLE';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$4e),
  (mnemonic:'CMOVNA';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$46),
  (mnemonic:'CMOVNA';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$46),
  (mnemonic:'CMOVNAE';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$42),
  (mnemonic:'CMOVNAE';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$42),
  (mnemonic:'CMOVNB';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$43),
  (mnemonic:'CMOVNB';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$43),
  (mnemonic:'CMOVNBE';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$47),
  (mnemonic:'CMOVNBE';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$47),
  (mnemonic:'CMOVNC';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$43),
  (mnemonic:'CMOVNC';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$43),
  (mnemonic:'CMOVNE';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$45),
  (mnemonic:'CMOVNE';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$45),
  (mnemonic:'CMOVNG';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$4e),
  (mnemonic:'CMOVNG';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$4e),
  (mnemonic:'CMOVNGE';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$4c),
  (mnemonic:'CMOVNGE';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$4c),
  (mnemonic:'CMOVNL';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$4d),
  (mnemonic:'CMOVNL';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$4d),
  (mnemonic:'CMOVNLE';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$4f),
  (mnemonic:'CMOVNLE';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$4f),
  (mnemonic:'CMOVNO';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$41),
  (mnemonic:'CMOVNO';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$41),
  (mnemonic:'CMOVNP';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$4b),
  (mnemonic:'CMOVNP';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$4b),
  (mnemonic:'CMOVNS';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$49),
  (mnemonic:'CMOVNS';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$49),
  (mnemonic:'CMOVNZ';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$45),
  (mnemonic:'CMOVNZ';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$45),
  (mnemonic:'CMOVO';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$40),
  (mnemonic:'CMOVO';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$40),
  (mnemonic:'CMOVP';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$4a),
  (mnemonic:'CMOVP';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$4a),
  (mnemonic:'CMOVPE';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$4a),
  (mnemonic:'CMOVPE';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$4a),
  (mnemonic:'CMOVPO';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$4b),
  (mnemonic:'CMOVPO';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$4b),
  (mnemonic:'CMOVS';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$48),
  (mnemonic:'CMOVS';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$48),
  (mnemonic:'CMOVZ';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$44),
  (mnemonic:'CMOVZ';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$44),



  (mnemonic:'CMP';opcode1:eo_ib;paramtype1:par_AL;paramtype2:par_imm8;bytes:1;bt1:$3C), //2 bytes
  (mnemonic:'CMP';opcode1:eo_iw;paramtype1:par_AX;paramtype2:par_imm16;bytes:2;bt1:$66;bt2:$3D), //4 bytes
  (mnemonic:'CMP';opcode1:eo_id;paramtype1:par_EAX;paramtype2:par_imm32;bytes:1;bt1:$3D), //5 bytes
  (mnemonic:'CMP';opcode1:eo_reg7;opcode2:eo_ib;paramtype1:par_rm8;paramtype2:par_imm8;bytes:1;bt1:$80),
  (mnemonic:'CMP';opcode1:eo_reg7;opcode2:eo_ib;paramtype1:par_rm16;paramtype2:par_imm8;bytes:2;bt1:$66;bt2:$83; signed: true),
  (mnemonic:'CMP';opcode1:eo_reg7;opcode2:eo_ib;paramtype1:par_rm32;paramtype2:par_imm8;bytes:1;bt1:$83; signed: true),


  (mnemonic:'CMP';opcode1:eo_reg7;opcode2:eo_iw;paramtype1:par_rm16;paramtype2:par_imm16;bytes:2;bt1:$66;bt2:$81),
  (mnemonic:'CMP';opcode1:eo_reg7;opcode2:eo_id;paramtype1:par_rm32;paramtype2:par_imm32;bytes:1;bt1:$81),
  (mnemonic:'CMP';opcode1:eo_reg;paramtype1:par_rm8;paramtype2:par_r8;bytes:1;bt1:$38),
  (mnemonic:'CMP';opcode1:eo_reg;paramtype1:par_rm16;paramtype2:par_r16;bytes:2;bt1:$66;bt2:$39),
  (mnemonic:'CMP';opcode1:eo_reg;paramtype1:par_rm32;paramtype2:par_r32;bytes:1;bt1:$39),
  (mnemonic:'CMP';opcode1:eo_reg;paramtype1:par_r8;paramtype2:par_rm8;bytes:1;bt1:$3A),
  (mnemonic:'CMP';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:2;bt1:$66;bt2:$3B),
  (mnemonic:'CMP';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:1;bt1:$3B),

  (mnemonic:'CMPPD';opcode1:eo_reg;opcode2:eo_ib;paramtype1:par_xmm;paramtype2:par_xmm_m128;paramtype3:par_imm8;bytes:3;bt1:$66;bt2:$0f;bt3:$c2),
  (mnemonic:'CMPPS';opcode1:eo_reg;opcode2:eo_ib;paramtype1:par_xmm;paramtype2:par_xmm_m128;paramtype3:par_imm8;bytes:2;bt1:$0f;bt2:$c2),

  (mnemonic:'CMPSB';bytes:1;bt1:$a6),
  (mnemonic:'CMPSD';bytes:1;bt1:$a7),
  (mnemonic:'CMPSD';opcode1:eo_reg;opcode2:eo_ib;paramtype1:par_xmm;paramtype2:par_xmm_m64;paramtype3:par_imm8;bytes:3;bt1:$f2;bt2:$0f;bt3:$c2),
  (mnemonic:'CMPSS';opcode1:eo_reg;opcode2:eo_ib;paramtype1:par_xmm;paramtype2:par_xmm_m32;paramtype3:par_imm8;bytes:3;bt1:$f3;bt2:$0f;bt3:$c2),
  (mnemonic:'CMPSW';bytes:2;bt1:$66;bt2:$a7),
  (mnemonic:'CMPXCHG';opcode1:eo_reg;paramtype1:par_rm8;paramtype2:par_r8;bytes:2;bt1:$0f;bt2:$b0),
  (mnemonic:'CMPXCHG';opcode1:eo_reg;paramtype1:par_rm16;paramtype2:par_r16;bytes:3;bt1:$66;bt2:$0f;bt3:$b1),
  (mnemonic:'CMPXCHG';opcode1:eo_reg;paramtype1:par_rm32;paramtype2:par_r32;bytes:2;bt1:$0f;bt2:$b1),
  (mnemonic:'CMPXCHG8B';opcode1:eo_reg1;paramtype1:par_m64;bytes:2;bt1:$0f;bt2:$c7), //no m64 as eo, seems it's just a /1

  (mnemonic:'COMISD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m64;bytes:3;bt1:$66;bt2:$0f;bt3:$2f),
  (mnemonic:'COMISS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m32;bytes:2;bt1:$0f;bt2:$2f),

  (mnemonic:'CPUID';bytes:2;bt1:$0f;bt2:$a2),
  (mnemonic:'CQO';bytes:2;bt1:$48;bt2:$99),
  (mnemonic:'CVTDQ2PD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m64;bytes:3;bt1:$f3;bt2:$0f;bt3:$e6),  //just a gues, the documentation didn't say anything about a /r, and the disassembler of delphi also doesn't recognize it
  (mnemonic:'CVTDQ2PS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:2;bt1:$0f;bt2:$5b),
  (mnemonic:'CVTPD2DQ';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$f2;bt2:$0f;bt3:$e6),
  (mnemonic:'CVTPD2PI';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$2d),

  (mnemonic:'CVTPD2PS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$5a),
  (mnemonic:'CVTPI2PD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_mm_m64;bytes:3;bt1:$66;bt2:$0f;bt3:$2a),
  (mnemonic:'CVTPI2PS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$2a),
  (mnemonic:'CVTPS2DQ';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$5b),

  (mnemonic:'CVTPS2PD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m64;bytes:2;bt1:$0f;bt2:$5a),
  (mnemonic:'CVTPS2PI';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_xmm_m64;bytes:2;bt1:$0f;bt2:$2d),
  (mnemonic:'CVTSD2SI';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_xmm_m64;bytes:3;bt1:$f2;bt2:$0f;bt3:$2d),
  (mnemonic:'CVTSD2SS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m64;bytes:3;bt1:$f2;bt2:$0f;bt3:$5a),
  (mnemonic:'CVTSI2SD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_rm32;bytes:3;bt1:$f2;bt2:$0f;bt3:$2a),
  (mnemonic:'CVTSI2SS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_rm32;bytes:3;bt1:$f3;bt2:$0f;bt3:$2a),

  (mnemonic:'CVTSS2SD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m32;bytes:3;bt1:$f3;bt2:$0f;bt3:$5a),
  (mnemonic:'CVTSS2SI';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_xmm_m32;bytes:3;bt1:$f3;bt2:$0f;bt3:$2d),

  (mnemonic:'CVTTPD2DQ';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$e6),
  (mnemonic:'CVTTPD2PI';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$2c),

  (mnemonic:'CVTTPS2PI';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_xmm_m64;bytes:3;bt1:$0f;bt2:$2c),
  (mnemonic:'CVTTSD2SI';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_xmm_m64;bytes:3;bt1:$f2;bt2:$0f;bt3:$2c),
  (mnemonic:'CVTTSS2SI';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_xmm_m64;bytes:3;bt1:$f3;bt2:$0f;bt3:$2c),

  (mnemonic:'CWD';bytes:1;bt1:$99),
  (mnemonic:'CWDE';opcode1:eo_none;paramtype1:par_noparam;bytes:1;bt1:$98),
  (mnemonic:'DAA';bytes:1;bt1:$27),
  (mnemonic:'DAS';bytes:1;bt1:$2F),
  (mnemonic:'DEC';opcode1:eo_prw;paramtype1:par_r16;bytes:2;bt1:$66;bt2:$48;invalidin64bit:true),
  (mnemonic:'DEC';opcode1:eo_prd;paramtype1:par_r32;bytes:1;bt1:$48;invalidin64bit:true),
  (mnemonic:'DEC';opcode1:eo_reg1;paramtype1:par_rm8;bytes:1;bt1:$fe),
  (mnemonic:'DEC';opcode1:eo_reg1;paramtype1:par_rm16;bytes:2;bt1:$66;bt2:$ff),
  (mnemonic:'DEC';opcode1:eo_reg1;paramtype1:par_rm32;bytes:1;bt1:$ff),
  (mnemonic:'DIV';opcode1:eo_reg6;paramtype1:par_rm8;bytes:1;bt1:$f6),
  (mnemonic:'DIV';opcode1:eo_reg6;paramtype1:par_rm16;bytes:2;bt1:$66;bt2:$f7),
  (mnemonic:'DIV';opcode1:eo_reg6;paramtype1:par_rm32;bytes:1;bt1:$f7),
  (mnemonic:'DIVPD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$5e),
  (mnemonic:'DIVPS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:2;bt1:$0f;bt2:$5e),
  (mnemonic:'DIVSD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m64;bytes:3;bt1:$f2;bt2:$0f;bt3:$5e),
  (mnemonic:'DIVSS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m32;bytes:3;bt1:$f3;bt2:$0f;bt3:$5e),
  (mnemonic:'EMMS';bytes:2;bt1:$0f;bt2:$77),
  (mnemonic:'ENTER';opcode1:eo_iw;opcode2:eo_ib;paramtype1:par_imm16;paramtype2:par_imm8;bytes:1;bt1:$c8),
  (mnemonic:'F2XM1';bytes:2;bt1:$d9;bt2:$f0),
  (mnemonic:'FABS';bytes:2;bt1:$d9;bt2:$e1),
  (mnemonic:'FADD';opcode1:eo_reg0;paramtype1:par_m32;bytes:1;bt1:$d8; norexw:true),
  (mnemonic:'FADD';opcode1:eo_reg0;paramtype1:par_m64;bytes:1;bt1:$dc; norexw:true),
  (mnemonic:'FADD';opcode1:eo_pi;paramtype1:par_st0;paramtype2:par_st;bytes:2;bt1:$d8;bt2:$c0),
  (mnemonic:'FADD';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$d8;bt2:$c0),
  (mnemonic:'FADD';opcode1:eo_pi;paramtype1:par_st;paramtype2:par_st0;bytes:2;bt1:$dc;bt2:$c0),
  (mnemonic:'FADDP';opcode1:eo_pi;paramtype1:par_st;paramtype2:par_st0;bytes:2;bt1:$de;bt2:$c0),
  (mnemonic:'FADDP';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$de;bt2:$c0),
  (mnemonic:'FADDP';bytes:2;bt1:$de;bt2:$c1),

  (mnemonic:'FBLD';opcode1:eo_reg4;paramtype1:par_m80;bytes:1;bt1:$df),
  (mnemonic:'FBSTP';opcode1:eo_reg6;paramtype1:par_m80;bytes:1;bt1:$df),
  (mnemonic:'FCHS';bytes:2;bt1:$D9;bt2:$e0),
  (mnemonic:'FCLEX';bytes:3;bt1:$9b;bt2:$db;bt3:$e2),
  (mnemonic:'FCMOVB';opcode1:eo_pi;paramtype1:par_st0;paramtype2:par_st;bytes:2;bt1:$DA;bt2:$c0),
  (mnemonic:'FCMOVB';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$DA;bt2:$c0),
  (mnemonic:'FCMOVBE';opcode1:eo_pi;paramtype1:par_st0;paramtype2:par_st;bytes:2;bt1:$DA;bt2:$d0),
  (mnemonic:'FCMOVBE';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$DA;bt2:$d0),
  (mnemonic:'FCMOVE';opcode1:eo_pi;paramtype1:par_st0;paramtype2:par_st;bytes:2;bt1:$DA;bt2:$c8),
  (mnemonic:'FCMOVE';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$DA;bt2:$c8),
  (mnemonic:'FCMOVNB';opcode1:eo_pi;paramtype1:par_st0;paramtype2:par_st;bytes:2;bt1:$DB;bt2:$c0),
  (mnemonic:'FCMOVNB';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$DB;bt2:$c0),
  (mnemonic:'FCMOVNBE';opcode1:eo_pi;paramtype1:par_st0;paramtype2:par_st;bytes:2;bt1:$DB;bt2:$d0),
  (mnemonic:'FCMOVNBE';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$DB;bt2:$d0),
  (mnemonic:'FCMOVNE';opcode1:eo_pi;paramtype1:par_st0;paramtype2:par_st;bytes:2;bt1:$DB;bt2:$c8),
  (mnemonic:'FCMOVNE';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$DB;bt2:$c8),
  (mnemonic:'FCMOVNU';opcode1:eo_pi;paramtype1:par_st0;paramtype2:par_st;bytes:2;bt1:$DB;bt2:$d8),
  (mnemonic:'FCMOVNU';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$DB;bt2:$d8),
  (mnemonic:'FCMOVU';opcode1:eo_pi;paramtype1:par_st0;paramtype2:par_st;bytes:2;bt1:$DA;bt2:$d8),
  (mnemonic:'FCMOVU';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$DA;bt2:$d8),
  (mnemonic:'FCOM';opcode1:eo_reg2;paramtype1:par_m32;bytes:1;bt1:$d8; norexw: true),
  (mnemonic:'FCOM';opcode1:eo_reg2;paramtype1:par_m64;bytes:1;bt1:$dc; norexw: true),
  (mnemonic:'FCOM';opcode1:eo_pi;paramtype1:par_st0;paramtype2:par_st;bytes:2;bt1:$d8;bt2:$d0),  
  (mnemonic:'FCOM';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$d8;bt2:$d0),
  (mnemonic:'FCOM';bytes:2;bt1:$d8;bt2:$d1),
  (mnemonic:'FCOMP';opcode1:eo_reg3;paramtype1:par_m32;bytes:1;bt1:$d8; norexw: true),
  (mnemonic:'FCOMP';opcode1:eo_reg3;paramtype1:par_m64;bytes:1;bt1:$dc; norexw: true),
  (mnemonic:'FCOMP';opcode1:eo_pi;paramtype1:par_st0;paramtype2:par_st;bytes:2;bt1:$d8;bt2:$d8),
  (mnemonic:'FCOMP';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$d8;bt2:$d8),
  (mnemonic:'FCOMP';bytes:2;bt1:$d8;bt2:$d9),
  (mnemonic:'FCOMI';opcode1:eo_pi;paramtype1:par_st0;paramtype2:par_st;bytes:2;bt1:$db;bt2:$f0),
  (mnemonic:'FCOMI';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$db;bt2:$f0),
  (mnemonic:'FCOMIP';opcode1:eo_pi;paramtype1:par_st0;paramtype2:par_st;bytes:2;bt1:$df;bt2:$f0),
  (mnemonic:'FCOMIP';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$df;bt2:$f0),
  (mnemonic:'FCOMPP';bytes:2;bt1:$de;bt2:$d9),

  (mnemonic:'FCOMPP';bytes:2;bt1:$de;bt2:$d9),
  (mnemonic:'FCOS';bytes:2;bt1:$D9;bt2:$ff),

  (mnemonic:'FDECSTP';bytes:2;bt1:$d9;bt2:$f6),

  (mnemonic:'FDIV';opcode1:eo_reg6;paramtype1:par_m32;bytes:1;bt1:$d8; norexw: true),
  (mnemonic:'FDIV';opcode1:eo_reg6;paramtype1:par_m64;bytes:1;bt1:$dc; norexw: true),
  (mnemonic:'FDIV';opcode1:eo_pi;paramtype1:par_st0;paramtype2:par_st;bytes:2;bt1:$d8;bt2:$f0),
  (mnemonic:'FDIV';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$d8;bt2:$f0),  
  (mnemonic:'FDIV';opcode1:eo_pi;paramtype1:par_st;paramtype2:par_st0;bytes:2;bt1:$dc;bt2:$f8),
  (mnemonic:'FDIVP';opcode1:eo_pi;paramtype1:par_st;paramtype2:par_st0;bytes:2;bt1:$de;bt2:$f8),
  (mnemonic:'FDIVP';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$de;bt2:$f8),  
  (mnemonic:'FDIVP';bytes:2;bt1:$de;bt2:$f9),
  (mnemonic:'FDIVR';opcode1:eo_reg7;paramtype1:par_m32;bytes:1;bt1:$d8; norexw: true),
  (mnemonic:'FDIVR';opcode1:eo_reg7;paramtype1:par_m64;bytes:1;bt1:$dc; norexw: true),
  (mnemonic:'FDIVR';opcode1:eo_pi;paramtype1:par_st0;paramtype2:par_st;bytes:2;bt1:$d8;bt2:$f8),
  (mnemonic:'FDIVR';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$d8;bt2:$f8),  
  (mnemonic:'FDIVR';opcode1:eo_pi;paramtype1:par_st;paramtype2:par_st0;bytes:2;bt1:$dc;bt2:$f0),
  (mnemonic:'FDIVRP';opcode1:eo_pi;paramtype1:par_st;paramtype2:par_st0;bytes:2;bt1:$de;bt2:$f0),
  (mnemonic:'FDIVRP';bytes:2;bt1:$de;bt2:$f1),
  (mnemonic:'FFREE';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$dd;bt2:$c0),

  (mnemonic:'FIADD';opcode1:eo_reg0;paramtype1:par_m32;bytes:1;bt1:$DA),
  (mnemonic:'FIADD';opcode1:eo_reg0;paramtype1:par_m16;bytes:1;bt1:$DE),

  (mnemonic:'FICOM';opcode1:eo_reg2;paramtype1:par_m32;bytes:1;bt1:$da),
  (mnemonic:'FICOM';opcode1:eo_reg2;paramtype1:par_m16;bytes:1;bt1:$de),
  (mnemonic:'FICOMP';opcode1:eo_reg3;paramtype1:par_m32;bytes:1;bt1:$da),
  (mnemonic:'FICOMP';opcode1:eo_reg3;paramtype1:par_m16;bytes:1;bt1:$de),

  (mnemonic:'FIDIV';opcode1:eo_reg6;paramtype1:par_m32;bytes:1;bt1:$da),
  (mnemonic:'FIDIV';opcode1:eo_reg6;paramtype1:par_m16;bytes:1;bt1:$de),

  (mnemonic:'FIDIVR';opcode1:eo_reg7;paramtype1:par_m32;bytes:1;bt1:$da),
  (mnemonic:'FIDIVR';opcode1:eo_reg7;paramtype1:par_m16;bytes:1;bt1:$de),


  (mnemonic:'FILD';opcode1:eo_reg0;paramtype1:par_m32;bytes:1;bt1:$db; norexw: true), //screw this, going for a default of m32
  (mnemonic:'FILD';opcode1:eo_reg0;paramtype1:par_m16;bytes:1;bt1:$df; norexw: true),
  (mnemonic:'FILD';opcode1:eo_reg5;paramtype1:par_m64;bytes:1;bt1:$df; norexw: true),

  (mnemonic:'FIMUL';opcode1:eo_reg1;paramtype1:par_m32;bytes:1;bt1:$da; norexw: true),
  (mnemonic:'FIMUL';opcode1:eo_reg1;paramtype1:par_m16;bytes:1;bt1:$de; norexw: true),

  (mnemonic:'FINCSTP';bytes:2;bt1:$d9;bt2:$f7),
  (mnemonic:'FINIT';bytes:3;bt1:$9b;bt2:$db;bt3:$e3),

  (mnemonic:'FIST';opcode1:eo_reg2;paramtype1:par_m32;bytes:1;bt1:$db; norexw: true),
  (mnemonic:'FIST';opcode1:eo_reg2;paramtype1:par_m16;bytes:1;bt1:$df; norexw: true),

  (mnemonic:'FISTP';opcode1:eo_reg3;paramtype1:par_m32;bytes:1;bt1:$db; norexw: true),
  (mnemonic:'FISTP';opcode1:eo_reg3;paramtype1:par_m16;bytes:1;bt1:$df; norexw: true),
  (mnemonic:'FISTP';opcode1:eo_reg7;paramtype1:par_m64;bytes:1;bt1:$df; norexw: true),

  (mnemonic:'FISTTP';opcode1:eo_reg1;paramtype1:par_m32;bytes:1;bt1:$db; norexw: true),
  (mnemonic:'FISTTP';opcode1:eo_reg1;paramtype1:par_m16;bytes:1;bt1:$df; norexw: true),
  (mnemonic:'FISTTP';opcode1:eo_reg1;paramtype1:par_m64;bytes:1;bt1:$dd; norexw: true),

  (mnemonic:'FISUB';opcode1:eo_reg4;paramtype1:par_m32;bytes:1;bt1:$da; norexw: true),
  (mnemonic:'FISUB';opcode1:eo_reg4;paramtype1:par_m16;bytes:1;bt1:$de; norexw: true),
  (mnemonic:'FISUBR';opcode1:eo_reg5;paramtype1:par_m32;bytes:1;bt1:$da; norexw: true),
  (mnemonic:'FISUBR';opcode1:eo_reg5;paramtype1:par_m16;bytes:1;bt1:$de; norexw: true),

  (mnemonic:'FLD';opcode1:eo_reg0;paramtype1:par_m32;bytes:1;bt1:$d9; norexw: true),
  (mnemonic:'FLD';opcode1:eo_reg0;paramtype1:par_m64;bytes:1;bt1:$dd; norexw: true),
  (mnemonic:'FLD';opcode1:eo_reg5;paramtype1:par_m80;bytes:1;bt1:$db; norexw: true),
  (mnemonic:'FLD';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$d9;bt2:$c0; norexw: true),

  (mnemonic:'FLD1';bytes:2;bt1:$d9;bt2:$e8),
  (mnemonic:'FLDCW';opcode1:eo_reg5;paramtype1:par_m16;bytes:1;bt1:$d9),
  (mnemonic:'FLDENV';opcode1:eo_reg4;paramtype1:par_m32;bytes:1;bt1:$d9),
  (mnemonic:'FLDL2E';bytes:2;bt1:$d9;bt2:$ea),
  (mnemonic:'FLDL2T';bytes:2;bt1:$d9;bt2:$e9),
  (mnemonic:'FLDLG2';bytes:2;bt1:$d9;bt2:$ec),
  (mnemonic:'FLDLN2';bytes:2;bt1:$d9;bt2:$ed),
  (mnemonic:'FLDPI';bytes:2;bt1:$d9;bt2:$eb),
  (mnemonic:'FLDZ';bytes:2;bt1:$d9;bt2:$ee),

  (mnemonic:'FMUL';opcode1:eo_reg1;paramtype1:par_m32;bytes:1;bt1:$d8; norexw: true),
  (mnemonic:'FMUL';opcode1:eo_reg1;paramtype1:par_m64;bytes:1;bt1:$dc; norexw: true),
  (mnemonic:'FMUL';opcode1:eo_pi;paramtype1:par_st0;paramtype2:par_st;bytes:2;bt1:$d8;bt2:$C8),
  (mnemonic:'FMUL';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$d8;bt2:$C8),
  (mnemonic:'FMUL';opcode1:eo_pi;paramtype1:par_st;paramtype2:par_st0;bytes:2;bt1:$dc;bt2:$C8),
  (mnemonic:'FMULP';opcode1:eo_pi;paramtype1:par_st;paramtype2:par_st0;bytes:2;bt1:$de;bt2:$C8),
  (mnemonic:'FMULP';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$de;bt2:$C8),
  (mnemonic:'FMULP';bytes:2;bt1:$de;bt2:$c9),


  (mnemonic:'FNINIT';bytes:2;bt1:$db;bt2:$e3),
  (mnemonic:'FNCLEX';bytes:2;bt1:$Db;bt2:$e2),
  (mnemonic:'FNOP';bytes:2;bt1:$d9;bt2:$d0),
  (mnemonic:'FNSAVE';opcode1:eo_reg6;paramtype1:par_m32;bytes:1;bt1:$dd),

  (mnemonic:'FNSTCW';opcode1:eo_reg7;paramtype1:par_m16;bytes:1;bt1:$d9),
  (mnemonic:'FNSTENV';opcode1:eo_reg6;paramtype1:par_m32;bytes:1;bt1:$d9),

  (mnemonic:'FNSTSW';paramtype1:par_ax;bytes:2;bt1:$df;bt2:$e0),
  (mnemonic:'FNSTSW';opcode1:eo_reg7;paramtype1:par_m16;bytes:1;bt1:$dd),


  (mnemonic:'FPATAN';bytes:2;bt1:$d9;bt2:$f3),
  (mnemonic:'FPREM';bytes:2;bt1:$d9;bt2:$f8),
  (mnemonic:'FPREM1';bytes:2;bt1:$d9;bt2:$f5),
  (mnemonic:'FPTAN';bytes:2;bt1:$d9;bt2:$f2),
  (mnemonic:'FRNDINT';bytes:2;bt1:$d9;bt2:$fc),
  (mnemonic:'FRSTOR';opcode1:eo_reg4;paramtype1:par_m32;bytes:1;bt1:$dd),

  (mnemonic:'FSAVE';opcode1:eo_reg6;paramtype1:par_m32;bytes:2;bt1:$9b;bt2:$dd),

  (mnemonic:'FSCALE';bytes:2;bt1:$d9;bt2:$fd),
  (mnemonic:'FSIN';bytes:2;bt1:$d9;bt2:$fe),
  (mnemonic:'FSINCOS';bytes:2;bt1:$d9;bt2:$fb),
  (mnemonic:'FSQRT';bytes:2;bt1:$d9;bt2:$fa),

  (mnemonic:'FST';opcode1:eo_reg2;paramtype1:par_m32;bytes:1;bt1:$d9; norexw: true),
  (mnemonic:'FST';opcode1:eo_reg2;paramtype1:par_m64;bytes:1;bt1:$dd; norexw: true),
  (mnemonic:'FST';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$dd;bt2:$d0; norexw: true),
  (mnemonic:'FSTCW';opcode1:eo_reg7;paramtype1:par_m16;bytes:2;bt1:$9b;bt2:$d9),
  (mnemonic:'FSTENV';opcode1:eo_reg6;paramtype1:par_m32;bytes:2;bt1:$9b;bt2:$d9),
  (mnemonic:'FSTP';opcode1:eo_reg3;paramtype1:par_m32;bytes:1;bt1:$d9; norexw: true),
  (mnemonic:'FSTP';opcode1:eo_reg3;paramtype1:par_m64;bytes:1;bt1:$dd; norexw: true),
  (mnemonic:'FSTP';opcode1:eo_reg7;paramtype1:par_m80;bytes:1;bt1:$db; norexw: true),
  (mnemonic:'FSTP';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$dd;bt2:$d8; norexw: true),


  (mnemonic:'FSTSW';opcode1:eo_reg7;paramtype1:par_m16;bytes:2;bt1:$9b;bt2:$dd),
  (mnemonic:'FSTSW';paramtype1:par_ax;bytes:3;bt1:$9b;bt2:$df;bt3:$e0),


  (mnemonic:'FSUB';opcode1:eo_reg4;paramtype1:par_m32;bytes:1;bt1:$d8; norexw: true),
  (mnemonic:'FSUB';opcode1:eo_reg4;paramtype1:par_m64;bytes:1;bt1:$dc; norexw: true),
  (mnemonic:'FSUB';opcode1:eo_pi;paramtype1:par_st0;paramtype2:par_st;bytes:2;bt1:$d8;bt2:$e0; norexw: true),
  (mnemonic:'FSUB';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$dc;bt2:$e8; norexw: true),
  (mnemonic:'FSUB';opcode1:eo_pi;paramtype1:par_st;paramtype2:par_st0;bytes:2;bt1:$dc;bt2:$e8; norexw: true),
  (mnemonic:'FSUBP';opcode1:eo_pi;paramtype1:par_st;paramtype2:par_st0;bytes:2;bt1:$de;bt2:$e8; norexw: true),
  (mnemonic:'FSUBP';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$de;bt2:$e8; norexw: true),
  (mnemonic:'FSUBP';bytes:2;bt1:$de;bt2:$e9; norexw: true),
  (mnemonic:'FSUBR';opcode1:eo_reg5;paramtype1:par_m32;bytes:1;bt1:$d8; norexw: true),
  (mnemonic:'FSUBR';opcode1:eo_reg5;paramtype1:par_m64;bytes:1;bt1:$dc; norexw: true),
  (mnemonic:'FSUBR';opcode1:eo_pi;paramtype1:par_st0;paramtype2:par_st;bytes:2;bt1:$d8;bt2:$e8; norexw: true),
  (mnemonic:'FSUBR';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$d8;bt2:$e8; norexw: true),
  (mnemonic:'FSUBR';opcode1:eo_pi;paramtype1:par_st;paramtype2:par_st0;bytes:2;bt1:$dc;bt2:$e0; norexw: true),
  (mnemonic:'FSUBRP';opcode1:eo_pi;paramtype1:par_st;paramtype2:par_st0;bytes:2;bt1:$de;bt2:$e0; norexw: true),
  (mnemonic:'FSUBRP';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$de;bt2:$e0; norexw: true),
  (mnemonic:'FSUBRP';bytes:2;bt1:$de;bt2:$e1; norexw: true),
  (mnemonic:'FTST';bytes:2;bt1:$d9;bt2:$e4),

  (mnemonic:'FUCOM';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$dd;bt2:$e0),
  (mnemonic:'FUCOM';bytes:2;bt1:$dd;bt2:$e1),
  (mnemonic:'FUCOMI';opcode1:eo_pi;paramtype1:par_st0;paramtype2:par_st;bytes:2;bt1:$db;bt2:$e8),
  (mnemonic:'FUCOMI';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$db;bt2:$e8),
  (mnemonic:'FUCOMIP';opcode1:eo_pi;paramtype1:par_st0;paramtype2:par_st;bytes:2;bt1:$df;bt2:$e8),
  (mnemonic:'FUCOMIP';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$df;bt2:$e8),
  (mnemonic:'FUCOMP';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$dd;bt2:$e8),
  (mnemonic:'FUCOMP';bytes:2;bt1:$dd;bt2:$e9),
  (mnemonic:'FUCOMPP';bytes:2;bt1:$da;bt2:$e9),

  (mnemonic:'FWAIT';bytes:1;bt1:$9b),
  
  (mnemonic:'FXAM';bytes:2;bt1:$d9;bt2:$e5),
  (mnemonic:'FXCH';opcode1:eo_pi;paramtype1:par_st;bytes:2;bt1:$d9;bt2:$c8),
  (mnemonic:'FXCH';bytes:2;bt1:$d9;bt2:$c9),
  (mnemonic:'FXRSTOR';opcode1:eo_reg1;paramtype1:par_m32;bytes:2;bt1:$0f;bt2:$ae),
  (mnemonic:'FXSAVE';opcode1:eo_reg0;paramtype1:par_m32;bytes:2;bt1:$0f;bt2:$ae),
  (mnemonic:'FXTRACT';bytes:2;bt1:$d9;bt2:$f4),
  (mnemonic:'FYL2X';bytes:2;bt1:$d9;bt2:$f1),
  (mnemonic:'FYL2XP1';bytes:2;bt1:$d9;bt2:$f9),

  (mnemonic:'HLT';bytes:1;bt1:$f4),

  (mnemonic:'IDIV';opcode1:eo_reg7;paramtype1:par_rm8;bytes:1;bt1:$f6),
  (mnemonic:'IDIV';opcode1:eo_reg7;paramtype1:par_rm16;bytes:2;bt1:$66;bt2:$f7),
  (mnemonic:'IDIV';opcode1:eo_reg7;paramtype1:par_rm32;bytes:1;bt1:$f7),


  (mnemonic:'IMUL';opcode1:eo_reg5;paramtype1:par_rm8;bytes:1;bt1:$f6),
  (mnemonic:'IMUL';opcode1:eo_reg5;paramtype1:par_rm16;bytes:2;bt1:$66;bt2:$f7),
  (mnemonic:'IMUL';opcode1:eo_reg5;paramtype1:par_rm32;bytes:1;bt1:$f7),

  (mnemonic:'IMUL';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$af),
  (mnemonic:'IMUL';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$af),

  (mnemonic:'IMUL';opcode1:eo_reg;opcode2:eo_ib;paramtype1:par_r16;paramtype2:par_rm16;paramtype3:par_imm8;bytes:2;bt1:$66;bt2:$6b),
  (mnemonic:'IMUL';opcode1:eo_reg;opcode2:eo_ib;paramtype1:par_r32;paramtype2:par_rm32;paramtype3:par_imm8;bytes:1;bt1:$6b),

  (mnemonic:'IMUL';opcode1:eo_reg;opcode2:eo_iw;paramtype1:par_r16;paramtype2:par_imm16;bytes:2;bt1:$66;bt2:$69),
  (mnemonic:'IMUL';opcode1:eo_reg;opcode2:eo_id;paramtype1:par_r32;paramtype2:par_imm32;bytes:1;bt1:$69),

  (mnemonic:'IMUL';opcode1:eo_reg;opcode2:eo_ib;paramtype1:par_r16;paramtype2:par_imm8;bytes:2;bt1:$66;bt2:$6b),
  (mnemonic:'IMUL';opcode1:eo_reg;opcode2:eo_ib;paramtype1:par_r32;paramtype2:par_imm8;bytes:1;bt1:$6b),

  (mnemonic:'IMUL';opcode1:eo_reg;opcode2:eo_iw;paramtype1:par_r16;paramtype2:par_rm16;paramtype3:par_imm16;bytes:2;bt1:$66;bt2:$69),
  (mnemonic:'IMUL';opcode1:eo_reg;opcode2:eo_id;paramtype1:par_r32;paramtype2:par_rm32;paramtype3:par_imm32;bytes:1;bt1:$69),



  (mnemonic:'IN';opcode1:eo_ib;paramtype1:par_al;paramtype2:par_imm8;bytes:1;bt1:$e4),
  (mnemonic:'IN';opcode1:eo_ib;paramtype1:par_ax;paramtype2:par_imm8;bytes:2;bt1:$66;bt2:$e5),
  (mnemonic:'IN';opcode1:eo_ib;paramtype1:par_eax;paramtype2:par_imm8;bytes:1;bt1:$e5),

  (mnemonic:'IN';paramtype1:par_al;paramtype2:par_dx;bytes:1;bt1:$ec),
  (mnemonic:'IN';paramtype1:par_ax;paramtype2:par_dx;bytes:2;bt1:$66;bt2:$ed),
  (mnemonic:'IN';paramtype1:par_eax;paramtype2:par_dx;bytes:1;bt1:$ed),

  (mnemonic:'INC';opcode1:eo_prw;paramtype1:par_r16;bytes:2;bt1:$66;bt2:$40;invalidin64bit:true),
  (mnemonic:'INC';opcode1:eo_prd;paramtype1:par_r32;bytes:1;bt1:$40;invalidin64bit:true),
  (mnemonic:'INC';opcode1:eo_reg0;paramtype1:par_rm8;bytes:1;bt1:$fe),
  (mnemonic:'INC';opcode1:eo_reg0;paramtype1:par_rm16;bytes:2;bt1:$66;bt2:$ff),
  (mnemonic:'INC';opcode1:eo_reg0;paramtype1:par_rm32;bytes:1;bt1:$ff),

  (mnemonic:'INSB';bytes:1;bt1:$6c),
  (mnemonic:'INSD';bytes:1;bt1:$6d),
  (mnemonic:'INSW';bytes:2;bt1:$66;bt2:$6d),

  (mnemonic:'INT';paramtype1:par_3;bytes:1;bt1:$cc),
  (mnemonic:'INT';opcode1:eo_ib;paramtype1:par_imm8;bytes:1;bt1:$cd),
  (mnemonic:'INTO';bytes:1;bt1:$ce),

  (mnemonic:'INVD';bytes:2;bt1:$0f;bt2:$08),
  (mnemonic:'INVLPG';opcode1:eo_reg7;paramtype1:par_m32;bytes:2;bt1:$0f;bt2:$01),

  (mnemonic:'IRET';bytes:2;bt1:$66;bt2:$cf),
  (mnemonic:'IRETD';bytes:1;bt1:$cf),
  (mnemonic:'IRETQ';bytes:2;bt1:$48;bt2:$cf),

  (mnemonic:'JA';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$77),
  (mnemonic:'JA';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$87),
  (mnemonic:'JAE';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$73),
  (mnemonic:'JAE';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$83),
  (mnemonic:'JB';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$72),
  (mnemonic:'JB';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$82),
  (mnemonic:'JBE';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$76),
  (mnemonic:'JBE';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$86),
  (mnemonic:'JC';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$72),
  (mnemonic:'JC';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$82),

  (mnemonic:'JCXZ';opcode1:eo_cb;paramtype1:par_rel8;bytes:2;bt1:$66;bt2:$e3),
  (mnemonic:'JE';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$74),
  (mnemonic:'JE';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$84),
  (mnemonic:'JECXZ';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$e3),
  (mnemonic:'JG';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$7f),
  (mnemonic:'JG';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$8f),
  (mnemonic:'JGE';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$7d),
  (mnemonic:'JGE';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$8d),
  (mnemonic:'JL';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$7c),
  (mnemonic:'JL';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$8c),
  (mnemonic:'JLE';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$7e),
  (mnemonic:'JLE';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$8e),

  (mnemonic:'JMP';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$eb),
  (mnemonic:'JMP';opcode1:eo_cd;paramtype1:par_rel32;bytes:1;bt1:$e9),
  (mnemonic:'JMP';opcode1:eo_reg4;paramtype1:par_rm32;bytes:1;bt1:$ff;norexw:true),



  (mnemonic:'JNA';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$76),
  (mnemonic:'JNA';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$86),
  (mnemonic:'JNAE';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$72),
  (mnemonic:'JNAE';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$82),
  (mnemonic:'JNB';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$73),
  (mnemonic:'JNB';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$83),
  (mnemonic:'JNBE';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$77),
  (mnemonic:'JNBE';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$87),
  (mnemonic:'JNC';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$73),
  (mnemonic:'JNC';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$83),
  (mnemonic:'JNE';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$75),
  (mnemonic:'JNE';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$85),
  (mnemonic:'JNG';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$7e),
  (mnemonic:'JNG';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$8e),
  (mnemonic:'JNGE';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$7c),
  (mnemonic:'JNGE';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$8c),
  (mnemonic:'JNL';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$7d),
  (mnemonic:'JNL';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$8d),

  (mnemonic:'JNLE';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$7f),
  (mnemonic:'JNLE';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$8f),
  (mnemonic:'JNO';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$71),
  (mnemonic:'JNO';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$81),
  (mnemonic:'JNP';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$7b),
  (mnemonic:'JNP';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$8b),
  (mnemonic:'JNS';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$79),
  (mnemonic:'JNS';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$89),
  (mnemonic:'JNZ';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$75),
  (mnemonic:'JNZ';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$85),
  (mnemonic:'JO';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$70),
  (mnemonic:'JO';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$80),
  (mnemonic:'JP';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$7a),
  (mnemonic:'JP';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$8a),
  (mnemonic:'JPE';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$7a),
  (mnemonic:'JPE';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$8a),
  (mnemonic:'JPO';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$7b),
  (mnemonic:'JPO';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$8b),
  (mnemonic:'JS';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$78),
  (mnemonic:'JS';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$88),
  (mnemonic:'JZ';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$74),
  (mnemonic:'JZ';opcode1:eo_cd;paramtype1:par_rel32;bytes:2;bt1:$0f;bt2:$84),

  (mnemonic:'LAHF';bytes:1;bt1:$9f),
  (mnemonic:'LAR';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$02),
  (mnemonic:'LAR';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$02),

  (mnemonic:'LDDQU';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_m128;bytes:3;bt1:$f2;bt2:$0f;bt3:$f0),
  (mnemonic:'LDMXCSR';opcode1:eo_reg2;paramtype1:par_m32;bytes:2;bt1:$0f;bt2:$ae),
  (mnemonic:'LDS';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_m16;bytes:2;bt1:$66;bt2:$c5),
  (mnemonic:'LDS';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_m32;bytes:1;bt1:$c5),

  (mnemonic:'LEA';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_m16;bytes:2;bt1:$66;bt2:$8d;canDoAddressSwitch:true),
  (mnemonic:'LEA';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_m32;bytes:1;bt1:$8d;canDoAddressSwitch:true),
  (mnemonic:'LEAVE';bytes:1;bt1:$c9),

  (mnemonic:'LES';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:2;bt1:$66;bt2:$c4),
  (mnemonic:'LES';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:1;bt1:$c4),
  (mnemonic:'LFENCE';bytes:3;bt1:$0f;bt2:$ae;bt3:$e8),

  (mnemonic:'LFS';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_m16;bytes:3;bt1:$66;bt2:$0f;bt3:$b4),
  (mnemonic:'LFS';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_m32;bytes:2;bt1:$0f;bt2:$b4),

  (mnemonic:'LGDT';opcode1:eo_reg2;paramtype1:par_m16;bytes:2;bt1:$0f;bt2:$01),
  (mnemonic:'LGDT';opcode1:eo_reg2;paramtype1:par_m32;bytes:2;bt1:$0f;bt2:$01),


  (mnemonic:'LGS';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_m16;bytes:3;bt1:$66;bt2:$0f;bt3:$b5),
  (mnemonic:'LGS';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_m32;bytes:2;bt1:$0f;bt2:$b5),

  (mnemonic:'LIDT';opcode1:eo_reg3;paramtype1:par_m16;bytes:2;bt1:$0f;bt2:$01),
  (mnemonic:'LIDT';opcode1:eo_reg3;paramtype1:par_m32;bytes:2;bt1:$0f;bt2:$01),


  (mnemonic:'LLDT';opcode1:eo_reg2;paramtype1:par_rm16;bytes:2;bt1:$0f;bt2:$00),
  (mnemonic:'LMSW';opcode1:eo_reg6;paramtype1:par_rm16;bytes:2;bt1:$0f;bt2:$01),

  (mnemonic:'LODSB';bytes:1;bt1:$ac),
  (mnemonic:'LODSD';bytes:1;bt1:$ad),
  (mnemonic:'LODSW';bytes:2;bt1:$66;bt2:$ad),

  (mnemonic:'LOOP';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$e2),
  (mnemonic:'LOOPE';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$e1),
  (mnemonic:'LOOPNE';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$e0),
  (mnemonic:'LOOPNZ';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$e0),
  (mnemonic:'LOOPZ';opcode1:eo_cb;paramtype1:par_rel8;bytes:1;bt1:$e1),

  (mnemonic:'LSL';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:3;bt1:$66;bt2:$0f;bt3:$03),
  (mnemonic:'LSL';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$03),

  (mnemonic:'LSS';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_m16;bytes:3;bt1:$66;bt2:$0f;bt3:$b2),
  (mnemonic:'LSS';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_m32;bytes:2;bt1:$0f;bt2:$b2),

  (mnemonic:'LTR';opcode1:eo_reg3;paramtype1:par_rm16;bytes:2;bt1:$0f;bt2:$00),

  (mnemonic:'MASKMOVDQU';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_mm;bytes:3;bt1:$66;bt2:$0f;bt3:$f7),
  (mnemonic:'MASKMOVQ';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm;bytes:2;bt1:$0f;bt2:$f7),
  (mnemonic:'MAXPD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$5f),
  (mnemonic:'MAXPS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:2;bt1:$0f;bt2:$5f),
  (mnemonic:'MAXSD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m64;bytes:3;bt1:$f2;bt2:$0f;bt3:$5f),
  (mnemonic:'MAXSS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m32;bytes:3;bt1:$f3;bt2:$0f;bt3:$5f),
  (mnemonic:'MFENCE';bytes:3;bt1:$0f;bt2:$ae;bt3:$f0),
  (mnemonic:'MINPD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$5d),
  (mnemonic:'MINPS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:2;bt1:$0f;bt2:$5d),
  (mnemonic:'MINSD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m64;bytes:3;bt1:$f2;bt2:$0f;bt3:$5d),
  (mnemonic:'MINSS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m32;bytes:3;bt1:$f3;bt2:$0f;bt3:$5d),

  (mnemonic:'MOV';opcode1:eo_id;paramtype1:par_al;paramtype2:par_moffs8;bytes:1;bt1:$a0),
  (mnemonic:'MOV';opcode1:eo_id;paramtype1:par_ax;paramtype2:par_moffs16;bytes:2;bt1:$66;bt2:$a1),
  (mnemonic:'MOV';opcode1:eo_id;paramtype1:par_eax;paramtype2:par_moffs32;bytes:1;bt1:$a1),
  (mnemonic:'MOV';opcode1:eo_id;paramtype1:par_moffs8;paramtype2:par_al;bytes:1;bt1:$a2),
  (mnemonic:'MOV';opcode1:eo_id;paramtype1:par_moffs16;paramtype2:par_ax;bytes:2;bt1:$66;bt2:$a3),
  (mnemonic:'MOV';opcode1:eo_id;paramtype1:par_moffs32;paramtype2:par_eax;bytes:1;bt1:$a3),

  (mnemonic:'MOV';opcode1:eo_reg;paramtype1:par_rm8;paramtype2:par_r8;bytes:1;bt1:$88),
  (mnemonic:'MOV';opcode1:eo_reg;paramtype1:par_rm16;paramtype2:par_r16;bytes:2;bt1:$66;bt2:$89),
  (mnemonic:'MOV';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:1;bt1:$8b), //8b prefered over 89 in case of r32,r32
  (mnemonic:'MOV';opcode1:eo_reg;paramtype1:par_rm32;paramtype2:par_r32;bytes:1;bt1:$89),
  (mnemonic:'MOV';opcode1:eo_reg;paramtype1:par_r8;paramtype2:par_rm8;bytes:1;bt1:$8a),
  (mnemonic:'MOV';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:2;bt1:$66;bt2:$8b),

  (mnemonic:'MOV';opcode1:eo_reg;paramtype1:par_rm16;paramtype2:par_sreg;bytes:2;bt1:$66;bt2:$8c),
  (mnemonic:'MOV';opcode1:eo_reg;paramtype1:par_sreg;paramtype2:par_rm16;bytes:2;bt1:$66;bt2:$8e),



  (mnemonic:'MOV';opcode1:eo_prb;paramtype1:par_r8;paramtype2:par_imm8;bytes:1;bt1:$b0),
  (mnemonic:'MOV';opcode1:eo_prw;paramtype1:par_r16;paramtype2:par_imm16;bytes:2;bt1:$66;bt2:$b8),
  (mnemonic:'MOV';opcode1:eo_prd;paramtype1:par_r32;paramtype2:par_imm32;bytes:1;bt1:$b8),

  (mnemonic:'MOV';opcode1:eo_reg0;paramtype1:par_rm8;paramtype2:par_imm8;bytes:1;bt1:$c6),
  (mnemonic:'MOV';opcode1:eo_reg0;paramtype1:par_rm16;paramtype2:par_imm16;bytes:2;bt1:$66;bt2:$c7),
  (mnemonic:'MOV';opcode1:eo_reg0;paramtype1:par_rm32;paramtype2:par_imm32;bytes:1;bt1:$c7),

  (mnemonic:'MOV';opcode1:eo_reg;paramtype1:par_CR;paramtype2:par_r32;bytes:2;bt1:$0f;bt2:$22),
  (mnemonic:'MOV';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_CR;bytes:2;bt1:$0f;bt2:$20),

  (mnemonic:'MOV';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_DR;bytes:2;bt1:$0f;bt2:$21),
  (mnemonic:'MOV';opcode1:eo_reg;paramtype1:par_DR;paramtype2:par_r32;bytes:2;bt1:$0f;bt2:$23),

  (mnemonic:'MOVAPD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$28),

  (mnemonic:'MOVAPS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:2;bt1:$0f;bt2:$28),
  (mnemonic:'MOVAPS';opcode1:eo_reg;paramtype1:par_xmm_m128;paramtype2:par_xmm;bytes:2;bt1:$0f;bt2:$29),

  (mnemonic:'MOVD';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$6e),
  (mnemonic:'MOVD';opcode1:eo_reg;paramtype1:par_rm32;paramtype2:par_mm;bytes:2;bt1:$0f;bt2:$7e),

  (mnemonic:'MOVD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_rm32;bytes:3;bt1:$66;bt2:$0f;bt3:$6e),
  (mnemonic:'MOVD';opcode1:eo_reg;paramtype1:par_rm32;paramtype2:par_xmm;bytes:3;bt1:$66;bt2:$0f;bt3:$7e),

  (mnemonic:'MOVDQ2Q';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_xmm;bytes:3;bt1:$f2;bt2:$0f;bt3:$d6),
  (mnemonic:'MOVDQA';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$6f),
  (mnemonic:'MOVDQA';opcode1:eo_reg;paramtype1:par_xmm_m128;paramtype2:par_xmm;bytes:3;bt1:$66;bt2:$0f;bt3:$7f),

  (mnemonic:'MOVDQU';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$f3;bt2:$0f;bt3:$6f),
  (mnemonic:'MOVDQU';opcode1:eo_reg;paramtype1:par_xmm_m128;paramtype2:par_xmm;bytes:3;bt1:$f3;bt2:$0f;bt3:$7f),

  (mnemonic:'MOVHLPS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm;bytes:2;bt1:$0f;bt2:$12),

  (mnemonic:'MOVHPD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_m64;bytes:3;bt1:$66;bt2:$0f;bt3:$16),
  (mnemonic:'MOVHPD';opcode1:eo_reg;paramtype1:par_m64;paramtype2:par_xmm;bytes:3;bt1:$66;bt2:$0f;bt3:$17),

  (mnemonic:'MOVHPS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_m64;bytes:2;bt1:$0f;bt2:$16),
  (mnemonic:'MOVHPS';opcode1:eo_reg;paramtype1:par_m64;paramtype2:par_xmm;bytes:2;bt1:$0f;bt2:$17),

  (mnemonic:'MOVLHPS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm;bytes:2;bt1:$0f;bt2:$16),

  (mnemonic:'MOVLPD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_m64;bytes:3;bt1:$66;bt2:$0f;bt3:$12),
  (mnemonic:'MOVLPD';opcode1:eo_reg;paramtype1:par_m64;paramtype2:par_xmm;bytes:3;bt1:$66;bt2:$0f;bt3:$13),

  (mnemonic:'MOVLPS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_m64;bytes:2;bt1:$0f;bt2:$12),
  (mnemonic:'MOVLPS';opcode1:eo_reg;paramtype1:par_m64;paramtype2:par_xmm;bytes:2;bt1:$0f;bt2:$13),

  (mnemonic:'MOVMSKPD';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_xmm;bytes:3;bt1:$66;bt2:$0f;bt3:$50),
  (mnemonic:'MOVMSKPS';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_xmm;bytes:2;bt1:$0f;bt2:$50),
  (mnemonic:'MOVNTDQ';opcode1:eo_reg;paramtype1:par_m128;paramtype2:par_xmm;bytes:3;bt1:$66;bt2:$0f;bt3:$e7),
  (mnemonic:'MOVNTI';opcode1:eo_reg;paramtype1:par_m32;paramtype2:par_r32;bytes:2;bt1:$0f;bt2:$c3),

  (mnemonic:'MOVNTPD';opcode1:eo_reg;paramtype1:par_m128;paramtype2:par_xmm;bytes:3;bt1:$66;bt2:$0f;bt3:$2b),
  (mnemonic:'MOVNTPS';opcode1:eo_reg;paramtype1:par_m128;paramtype2:par_xmm;bytes:2;bt1:$0f;bt2:$2b),

  (mnemonic:'MOVNTQ';opcode1:eo_reg;paramtype1:par_m64;paramtype2:par_mm;bytes:2;bt1:$0f;bt2:$e7),


  (mnemonic:'MOVQ';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$6f),
  (mnemonic:'MOVQ';opcode1:eo_reg;paramtype1:par_mm_m64;paramtype2:par_mm;bytes:2;bt1:$0f;bt2:$7f),

  (mnemonic:'MOVQ';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m64;bytes:3;bt1:$f3;bt2:$0f;bt3:$7e),
  (mnemonic:'MOVQ';opcode1:eo_reg;paramtype1:par_xmm_m64;paramtype2:par_xmm;bytes:3;bt1:$66;bt2:$0f;bt3:$d6),

  (mnemonic:'MOVQ';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$6e),
  (mnemonic:'MOVQ';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_rm32;bytes:3;bt1:$66;bt2:$0f;bt3:$6e),
  (mnemonic:'MOVQ';opcode1:eo_reg;paramtype1:par_rm32;paramtype2:par_xmm;bytes:3;bt1:$66;bt2:$0f;bt3:$7e),



  (mnemonic:'MOVQ2DQ';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_mm;bytes:3;bt1:$66;bt2:$0f;bt3:$d6),

  (mnemonic:'MOVSB';bytes:1;bt1:$a4),
  (mnemonic:'MOVSD';bytes:1;bt1:$a5),

  (mnemonic:'MOVSD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m64;bytes:3;bt1:$f2;bt2:$0f;bt3:$10),
  (mnemonic:'MOVSD';opcode1:eo_reg;paramtype1:par_xmm_m64;paramtype2:par_xmm;bytes:3;bt1:$f2;bt2:$0f;bt3:$11),

  (mnemonic:'MOVSS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m32;bytes:3;bt1:$f3;bt2:$0f;bt3:$10),
  (mnemonic:'MOVSS';opcode1:eo_reg;paramtype1:par_m32;paramtype2:par_xmm;bytes:3;bt1:$f3;bt2:$0f;bt3:$11),
  (mnemonic:'MOVSW';bytes:2;bt1:$66;bt2:$a5),

  (mnemonic:'MOVSX';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm8;bytes:3;bt1:$66;bt2:$0f;bt3:$be),
  (mnemonic:'MOVSX';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm8;bytes:2;bt1:$0f;bt2:$be),
  (mnemonic:'MOVSX';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm16;bytes:2;bt1:$0f;bt2:$bf),
  (mnemonic:'MOVSXD';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:1;bt1:$63),   //actuall r64,rm32 but the usage of the 64-bit register turns it into a rex_w itself

  (mnemonic:'MOVUPD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$10),
  (mnemonic:'MOVUPD';opcode1:eo_reg;paramtype1:par_xmm_m128;paramtype2:par_xmm;bytes:3;bt1:$66;bt2:$0f;bt3:$11),

  (mnemonic:'MOVUPS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:2;bt1:$0f;bt2:$10),
  (mnemonic:'MOVUPS';opcode1:eo_reg;paramtype1:par_xmm_m128;paramtype2:par_xmm;bytes:2;bt1:$0f;bt2:$11),

  (mnemonic:'MOVZX';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm8;bytes:3;bt1:$66;bt2:$0f;bt3:$b6),
  (mnemonic:'MOVZX';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm8;bytes:2;bt1:$0f;bt2:$b6),
  (mnemonic:'MOVZX';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm16;bytes:2;bt1:$0f;bt2:$b7),

  (mnemonic:'MUL';opcode1:eo_reg4;paramtype1:par_rm8;bytes:1;bt1:$f6),
  (mnemonic:'MUL';opcode1:eo_reg4;paramtype1:par_rm16;bytes:2;bt1:$66;bt2:$f7),
  (mnemonic:'MUL';opcode1:eo_reg4;paramtype1:par_rm32;bytes:1;bt1:$f7),

  (mnemonic:'MULPD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$59),
  (mnemonic:'MULPS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:2;bt1:$0f;bt2:$59),
  (mnemonic:'MULSD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m64;bytes:3;bt1:$f2;bt2:$0f;bt3:$59),
  (mnemonic:'MULSS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m32;bytes:3;bt1:$f3;bt2:$0f;bt3:$59),

  (mnemonic:'NEG';opcode1:eo_reg3;paramtype1:par_rm8;bytes:1;bt1:$f6),
  (mnemonic:'NEG';opcode1:eo_reg3;paramtype1:par_rm16;bytes:2;bt1:$66;bt2:$f7),
  (mnemonic:'NEG';opcode1:eo_reg3;paramtype1:par_rm32;bytes:1;bt1:$f7),

  (mnemonic:'NOP';bytes:1;bt1:$90),  //NOP nop Nop nOp noP NoP nOp NOp nOP

  (mnemonic:'NOT';opcode1:eo_reg2;paramtype1:par_rm8;bytes:1;bt1:$f6),
  (mnemonic:'NOT';opcode1:eo_reg2;paramtype1:par_rm16;bytes:2;bt1:$66;bt2:$f7),
  (mnemonic:'NOT';opcode1:eo_reg2;paramtype1:par_rm32;bytes:1;bt1:$f7),

  (mnemonic:'OR';opcode1:eo_ib;paramtype1:par_AL;paramtype2:par_imm8;bytes:1;bt1:$0c),
  (mnemonic:'OR';opcode1:eo_iw;paramtype1:par_AX;paramtype2:par_imm16;bytes:2;bt1:$66;bt2:$0d),
  (mnemonic:'OR';opcode1:eo_id;paramtype1:par_EAX;paramtype2:par_imm32;bytes:1;bt1:$0d),
  (mnemonic:'OR';opcode1:eo_reg1;opcode2:eo_ib;paramtype1:par_rm8;paramtype2:par_imm8;bytes:1;bt1:$80),
  (mnemonic:'OR';opcode1:eo_reg1;opcode2:eo_iw;paramtype1:par_rm16;paramtype2:par_imm16;bytes:2;bt1:$66;bt2:$81),
  (mnemonic:'OR';opcode1:eo_reg1;opcode2:eo_id;paramtype1:par_rm32;paramtype2:par_imm32;bytes:1;bt1:$81),
  (mnemonic:'OR';opcode1:eo_reg1;opcode2:eo_ib;paramtype1:par_rm16;paramtype2:par_imm8;bytes:2;bt1:$66;bt2:$83; signed: true),
  (mnemonic:'OR';opcode1:eo_reg1;opcode2:eo_ib;paramtype1:par_rm32;paramtype2:par_imm8;bytes:1;bt1:$83; signed: true),

  (mnemonic:'OR';opcode1:eo_reg;paramtype1:par_rm8;paramtype2:par_r8;bytes:1;bt1:$08),
  (mnemonic:'OR';opcode1:eo_reg;paramtype1:par_rm16;paramtype2:par_r16;bytes:2;bt1:$66;bt2:$09),
  (mnemonic:'OR';opcode1:eo_reg;paramtype1:par_rm32;paramtype2:par_r32;bytes:1;bt1:$09),
  (mnemonic:'OR';opcode1:eo_reg;paramtype1:par_r8;paramtype2:par_rm8;bytes:1;bt1:$0a),
  (mnemonic:'OR';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:2;bt1:$66;bt2:$0b),
  (mnemonic:'OR';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:1;bt1:$0b),

  (mnemonic:'ORPD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$56),
  (mnemonic:'ORPS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:2;bt1:$0f;bt2:$56),

  (mnemonic:'OUT';opcode1:eo_ib;paramtype1:par_imm8;paramtype2:par_al;bytes:1;bt1:$e6),
  (mnemonic:'OUT';opcode1:eo_ib;paramtype1:par_imm8;paramtype2:par_ax;bytes:2;bt1:$66;bt2:$e7),
  (mnemonic:'OUT';opcode1:eo_ib;paramtype1:par_imm8;paramtype2:par_eax;bytes:1;bt1:$e7),

  (mnemonic:'OUT';paramtype1:par_dx;paramtype2:par_al;bytes:1;bt1:$ee),
  (mnemonic:'OUT';paramtype1:par_dx;paramtype2:par_ax;bytes:2;bt1:$66;bt2:$ef),
  (mnemonic:'OUT';paramtype1:par_dx;paramtype2:par_eax;bytes:1;bt1:$ef),

  (mnemonic:'OUTSB';bytes:1;bt1:$6e),
  (mnemonic:'OUTSD';bytes:1;bt1:$6f),
  (mnemonic:'OUTSW';bytes:2;bt1:$66;bt2:$6f),

  (mnemonic:'PACKSSDW';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$6b),
  (mnemonic:'PACKSSDW';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$6b),

  (mnemonic:'PACKSSWB';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$63),
  (mnemonic:'PACKSSWB';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$63),


  (mnemonic:'PACKUSWB';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$67),
  (mnemonic:'PACKUSWB';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$67),

  (mnemonic:'PADDB';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$fc),
  (mnemonic:'PADDB';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$fc),

  (mnemonic:'PADDD';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$fe),
  (mnemonic:'PADDD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$fe),

  (mnemonic:'PADDQ';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$d4),
  (mnemonic:'PADDQ';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$d4),

  (mnemonic:'PADDSB';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$ec),
  (mnemonic:'PADDSB';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$ec),

  (mnemonic:'PADDSW';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$ed),
  (mnemonic:'PADDSW';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$ed),

  (mnemonic:'PADDUSB';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$dc),
  (mnemonic:'PADDUSB';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$dc),

  (mnemonic:'PADDUSW';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$dd),
  (mnemonic:'PADDUSW';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$dd),

  (mnemonic:'PADDW';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$fd),
  (mnemonic:'PADDW';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$fd),


  (mnemonic:'PAND';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$db),
  (mnemonic:'PAND';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$db),

  (mnemonic:'PANDN';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$df),
  (mnemonic:'PANDN';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$df),

  (mnemonic:'PAUSE';bytes:2;bt1:$f3;bt2:$90),

  (mnemonic:'PAVGB';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$e0),
  (mnemonic:'PAVGB';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$e0),

  (mnemonic:'PAVGW';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$e3),
  (mnemonic:'PAVGW';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$e3),

  (mnemonic:'PCMPEQB';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$74),
  (mnemonic:'PCMPEQB';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$74),

  (mnemonic:'PCMPEQD';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$76),
  (mnemonic:'PCMPEQD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$76),

  (mnemonic:'PCMPEQW';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$75),
  (mnemonic:'PCMPEQW';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$75),

  (mnemonic:'PCMPGTB';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$64),
  (mnemonic:'PCMPGTB';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$64),

  (mnemonic:'PCMPGTD';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$66),
  (mnemonic:'PCMPGTD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$66),

  (mnemonic:'PCMPGTW';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$65),
  (mnemonic:'PCMPGTW';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$65),

  (mnemonic:'PCPPS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:2;bt1:$0f;bt2:$53),
  (mnemonic:'PCPSS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$f3;bt2:$0f;bt3:$53),

  (mnemonic:'PEXTRW';opcode1:eo_reg;opcode2:eo_ib;paramtype1:par_r32;paramtype2:par_mm;paramtype3:par_imm8;bytes:2;bt1:$0f;bt2:$c5),
  (mnemonic:'PEXTRW';opcode1:eo_reg;opcode2:eo_ib;paramtype1:par_r32;paramtype2:par_xmm;paramtype3:par_imm8;bytes:3;bt1:$66;bt2:$0f;bt3:$c5),

  (mnemonic:'PINSRW';opcode1:eo_reg;opcode2:eo_ib;paramtype1:par_mm;paramtype2:par_r32_m16;paramtype3:par_imm8;bytes:2;bt1:$0f;bt2:$c4),
  (mnemonic:'PINSRW';opcode1:eo_reg;opcode2:eo_ib;paramtype1:par_xmm;paramtype2:par_r32_m16;paramtype3:par_imm8;bytes:3;bt1:$66;bt2:$0f;bt3:$c4),

  (mnemonic:'PMADDWD';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$f5),
  (mnemonic:'PMADDWD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$f5),

  (mnemonic:'PMAXSW';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$ee),
  (mnemonic:'PMAXSW';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$ee),

  (mnemonic:'PMAXUB';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$de),
  (mnemonic:'PMAXUB';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$de),

  (mnemonic:'PMINSW';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$ea),
  (mnemonic:'PMINSW';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$ea),

  (mnemonic:'PMINUB';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$da),
  (mnemonic:'PMINUB';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$da),

  (mnemonic:'PMOVMSKB';opcode1:eo_reg;opcode2:eo_ib;paramtype1:par_r32;paramtype2:par_mm;paramtype3:par_imm8;bytes:2;bt1:$0f;bt2:$d7),
  (mnemonic:'PMOVMSKB';opcode1:eo_reg;opcode2:eo_ib;paramtype1:par_r32;paramtype2:par_xmm;paramtype3:par_imm8;bytes:3;bt1:$66;bt2:$0f;bt3:$d7),

  (mnemonic:'PMULHUW';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$e4),
  (mnemonic:'PMULHUW';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$e4),

  (mnemonic:'PMULHW';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$e5),
  (mnemonic:'PMULHW';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$e5),

  (mnemonic:'PMULLD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:4;bt1:$66;bt2:$0f;bt3:$38;bt4:$40),

  (mnemonic:'PMULLW';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$d5),
  (mnemonic:'PMULLW';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$d5),

  (mnemonic:'PMULUDQ';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$f4),
  (mnemonic:'PMULUDQ';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$f4),

  (mnemonic:'POP';opcode1:eo_prd;paramtype1:par_r32;bytes:1;bt1:$58; norexw: true),
  (mnemonic:'POP';opcode1:eo_prw;paramtype1:par_r16;bytes:2;bt1:$66;bt2:$58),

  (mnemonic:'POP';opcode1:eo_reg0;paramtype1:par_rm32;bytes:1;bt1:$8f),
  (mnemonic:'POP';opcode1:eo_reg0;paramtype1:par_rm16;bytes:2;bt1:$66;bt2:$8f),

  (mnemonic:'POP';paramtype1:par_ds;bytes:1;bt1:$1f),
  (mnemonic:'POP';paramtype1:par_es;bytes:1;bt1:$07),
  (mnemonic:'POP';paramtype1:par_ss;bytes:1;bt1:$17),
  (mnemonic:'POP';paramtype1:par_fs;bytes:2;bt1:$0f;bt2:$a1),
  (mnemonic:'POP';paramtype1:par_gs;bytes:2;bt1:$0f;bt2:$a9),

  (mnemonic:'POPA';bytes:2;bt1:$66;bt2:$61),
  (mnemonic:'POPAD';bytes:1;bt1:$61),
  (mnemonic:'POPALL';bytes:1;bt1:$61),

  (mnemonic:'POPF';bytes:2;bt1:$66;bt2:$9d),
  (mnemonic:'POPFD';bytes:1;bt1:$9d; invalidin64bit: true),
  (mnemonic:'POPFQ';bytes:1;bt1:$9d; invalidin32bit: true),

  (mnemonic:'POR';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$eb),
  (mnemonic:'POR';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$eb),

  (mnemonic:'PREFETCH0';opcode1:eo_reg1;paramtype1:par_m8;bytes:2;bt1:$0f;bt2:$18),
  (mnemonic:'PREFETCH1';opcode1:eo_reg2;paramtype1:par_m8;bytes:2;bt1:$0f;bt2:$18),
  (mnemonic:'PREFETCH2';opcode1:eo_reg3;paramtype1:par_m8;bytes:2;bt1:$0f;bt2:$18),
  (mnemonic:'PREFETCHA';opcode1:eo_reg0;paramtype1:par_m8;bytes:2;bt1:$0f;bt2:$18),

  (mnemonic:'PREFETCHW';opcode1:eo_reg1;paramtype1:par_m8;bytes:2;bt1:$0f;bt2:$0d),
  (mnemonic:'PREFETCHWT1';opcode1:eo_reg2;paramtype1:par_m8;bytes:2;bt1:$0f;bt2:$0d),

  (mnemonic:'PSADBW';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$f6),
  (mnemonic:'PSADBW';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$f6),

  (mnemonic:'PSHUFD';opcode1:eo_reg;opcode2:eo_ib;paramtype1:par_xmm;paramtype2:par_xmm_m128;paramtype3:par_imm8;bytes:3;bt1:$66;bt2:$0f;bt3:$70),
  (mnemonic:'PSHUFHW';opcode1:eo_reg;opcode2:eo_ib;paramtype1:par_xmm;paramtype2:par_xmm_m128;paramtype3:par_imm8;bytes:3;bt1:$f3;bt2:$0f;bt3:$70),
  (mnemonic:'PSHUFLW';opcode1:eo_reg;opcode2:eo_ib;paramtype1:par_xmm;paramtype2:par_xmm_m128;paramtype3:par_imm8;bytes:3;bt1:$f2;bt2:$0f;bt3:$70),
  (mnemonic:'PSHUFW';opcode1:eo_reg;opcode2:eo_ib;paramtype1:par_mm;paramtype2:par_mm_m64;paramtype3:par_imm8;bytes:2;bt1:$0f;bt2:$70),


  (mnemonic:'PSLLD';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$f2),
  (mnemonic:'PSLLD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$f2),

  (mnemonic:'PSLLD';opcode1:eo_reg6;opcode2:eo_ib;paramtype1:par_mm;paramtype2:par_imm8;bytes:2;bt1:$0f;bt2:$72),
  (mnemonic:'PSLLD';opcode1:eo_reg6;opcode2:eo_ib;paramtype1:par_xmm;paramtype2:par_imm8;bytes:3;bt1:$66;bt2:$0f;bt3:$72),

  (mnemonic:'PSLLDQ';opcode1:eo_reg7;opcode2:eo_ib;paramtype1:par_xmm;paramtype2:par_imm8;bytes:3;bt1:$66;bt2:$0f;bt3:$73),

  (mnemonic:'PSLLQ';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$f3),
  (mnemonic:'PSLLQ';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$f3),

  (mnemonic:'PSLLQ';opcode1:eo_reg6;opcode2:eo_ib;paramtype1:par_mm;paramtype2:par_imm8;bytes:2;bt1:$0f;bt2:$73),
  (mnemonic:'PSLLQ';opcode1:eo_reg6;opcode2:eo_ib;paramtype1:par_xmm;paramtype2:par_imm8;bytes:3;bt1:$66;bt2:$0f;bt3:$73),


  (mnemonic:'PSLLW';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$f1),
  (mnemonic:'PSLLW';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$f1),

  (mnemonic:'PSLLW';opcode1:eo_reg6;opcode2:eo_ib;paramtype1:par_mm;paramtype2:par_imm8;bytes:2;bt1:$0f;bt2:$71),
  (mnemonic:'PSLLW';opcode1:eo_reg6;opcode2:eo_ib;paramtype1:par_xmm;paramtype2:par_imm8;bytes:3;bt1:$66;bt2:$0f;bt3:$71),

  (mnemonic:'PSQRTPS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:2;bt1:$0f;bt2:$52),
  (mnemonic:'PSQRTSS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m32;bytes:3;bt1:$f3;bt2:$0f;bt3:$52),


  (mnemonic:'PSRAD';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$e2),
  (mnemonic:'PSRAD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$e2),

  (mnemonic:'PSRAD';opcode1:eo_reg4;opcode2:eo_ib;paramtype1:par_mm;paramtype2:par_imm8;bytes:2;bt1:$0f;bt2:$72),
  (mnemonic:'PSRAD';opcode1:eo_reg4;opcode2:eo_ib;paramtype1:par_xmm;paramtype2:par_imm8;bytes:3;bt1:$66;bt2:$0f;bt3:$72),

  (mnemonic:'PSRAW';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$e1),
  (mnemonic:'PSRAW';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$e1),

  (mnemonic:'PSRAW';opcode1:eo_reg4;opcode2:eo_ib;paramtype1:par_mm;paramtype2:par_imm8;bytes:2;bt1:$0f;bt2:$71),
  (mnemonic:'PSRAW';opcode1:eo_reg4;opcode2:eo_ib;paramtype1:par_xmm;paramtype2:par_imm8;bytes:3;bt1:$66;bt2:$0f;bt3:$71),



  (mnemonic:'PSRLD';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$d2),
  (mnemonic:'PSRLD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$d2),

  (mnemonic:'PSRLD';opcode1:eo_reg2;opcode2:eo_ib;paramtype1:par_mm;paramtype2:par_imm8;bytes:2;bt1:$0f;bt2:$72),
  (mnemonic:'PSRLD';opcode1:eo_reg2;opcode2:eo_ib;paramtype1:par_xmm;paramtype2:par_imm8;bytes:3;bt1:$66;bt2:$0f;bt3:$72),
  (mnemonic:'PSRLDQ';opcode1:eo_reg3;opcode2:eo_ib;paramtype1:par_xmm;paramtype2:par_imm8;bytes:3;bt1:$66;bt2:$0f;bt3:$73),

  (mnemonic:'PSRLQ';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$d3),
  (mnemonic:'PSRLQ';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$d3),

  (mnemonic:'PSRLQ';opcode1:eo_reg2;opcode2:eo_ib;paramtype1:par_mm;paramtype2:par_imm8;bytes:2;bt1:$0f;bt2:$73),
  (mnemonic:'PSRLQ';opcode1:eo_reg2;opcode2:eo_ib;paramtype1:par_xmm;paramtype2:par_imm8;bytes:3;bt1:$66;bt2:$0f;bt3:$73),

  (mnemonic:'PSRLW';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$d1),
  (mnemonic:'PSRLW';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$d1),

  (mnemonic:'PSRLW';opcode1:eo_reg2;opcode2:eo_ib;paramtype1:par_mm;paramtype2:par_imm8;bytes:2;bt1:$0f;bt2:$71),
  (mnemonic:'PSRLW';opcode1:eo_reg2;opcode2:eo_ib;paramtype1:par_xmm;paramtype2:par_imm8;bytes:3;bt1:$66;bt2:$0f;bt3:$71),



  (mnemonic:'PSUBB';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$f8),
  (mnemonic:'PSUBB';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$f8),

  (mnemonic:'PSUBD';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$fa),
  (mnemonic:'PSUBD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$fa),

  (mnemonic:'PSUBQ';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$fb),
  (mnemonic:'PSUBQ';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$fb),

  (mnemonic:'PSUBSB';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$e8),
  (mnemonic:'PSUBSB';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$e8),

  (mnemonic:'PSUBSW';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$e9),
  (mnemonic:'PSUBSW';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$e9),


  (mnemonic:'PSUBUSB';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$d8),
  (mnemonic:'PSUBUSB';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$d8),

  (mnemonic:'PSUBUSW';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$d9),
  (mnemonic:'PSUBUSW';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$d9),


  (mnemonic:'PSUBW';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$f9),
  (mnemonic:'PSUBW';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$f9),


  (mnemonic:'PSUSB';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$e8),
  (mnemonic:'PSUSB';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$e8),

  (mnemonic:'PSUSW';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$e9),
  (mnemonic:'PSUSW';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$e9),


  (mnemonic:'PUNPCKHBW';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$68),
  (mnemonic:'PUNPCKHBW';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$68),

  (mnemonic:'PUNPCKHDQ';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$6a),
  (mnemonic:'PUNPCKHDQ';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$6a),

  (mnemonic:'PUNPCKHQDQ';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$6d),

  (mnemonic:'PUNPCKHWD';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$69),
  (mnemonic:'PUNPCKHWD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$69),

  (mnemonic:'PUNPCKLBW';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$60),
  (mnemonic:'PUNPCKLBW';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$60),

  (mnemonic:'PUNPCKLDQ';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$62),
  (mnemonic:'PUNPCKLDQ';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$62),

  (mnemonic:'PUNPCKLQDQ';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$6c),

  (mnemonic:'PUNPCKLWD';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$61),
  (mnemonic:'PUNPCKLWD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$61),


  (mnemonic:'PUSH';opcode1:eo_ib;paramtype1:par_imm8;bytes:1;bt1:$6a),
  (mnemonic:'PUSH';opcode1:eo_id;paramtype1:par_imm32;bytes:1;bt1:$68),
//  (mnemonic:'PUSH';opcode1:eo_iw;paramtype1:par_imm16;bytes:2;bt1:$66;bt2:$68),


  (mnemonic:'PUSH';opcode1:eo_prd;paramtype1:par_r32;bytes:1;bt1:$50;norexw: true),
  (mnemonic:'PUSH';opcode1:eo_prw;paramtype1:par_r16;bytes:2;bt1:$66;bt2:$50),

  (mnemonic:'PUSH';opcode1:eo_reg6;paramtype1:par_rm32;bytes:1;bt1:$ff),
  (mnemonic:'PUSH';opcode1:eo_reg6;paramtype1:par_rm16;bytes:2;bt1:$66;bt2:$ff),


  (mnemonic:'PUSH';paramtype1:par_CS;bytes:1;bt1:$0e),
  (mnemonic:'PUSH';paramtype1:par_ss;bytes:1;bt1:$16),
  (mnemonic:'PUSH';paramtype1:par_ds;bytes:1;bt1:$1e),
  (mnemonic:'PUSH';paramtype1:par_es;bytes:1;bt1:$06),
  (mnemonic:'PUSH';paramtype1:par_fs;bytes:2;bt1:$0f;bt2:$a0),
  (mnemonic:'PUSH';paramtype1:par_gs;bytes:2;bt1:$0f;bt2:$a8),

  (mnemonic:'PUSHA';bytes:2;bt1:$66;bt2:$60;invalidin64bit: true),
  (mnemonic:'PUSHAD';bytes:1;bt1:$60;invalidin64bit: true),
  (mnemonic:'PUSHALL';bytes:1;bt1:$60;invalidin64bit: true),
  (mnemonic:'PUSHF';bytes:2;bt1:$66;bt2:$9c),
  (mnemonic:'PUSHFD';bytes:1;bt1:$9c;invalidin64bit: true),
  (mnemonic:'PUSHFQ';bytes:1;bt1:$9c;invalidin32bit: true),

  (mnemonic:'PXOR';opcode1:eo_reg;paramtype1:par_mm;paramtype2:par_mm_m64;bytes:2;bt1:$0f;bt2:$ef),
  (mnemonic:'PXOR';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$ef),

  (mnemonic:'RCL';opcode1:eo_reg2;paramtype1:par_rm8;paramtype2:par_1;bytes:1;bt1:$d0),
  (mnemonic:'RCL';opcode1:eo_reg2;paramtype1:par_rm8;paramtype2:par_cl;bytes:1;bt1:$d2),
  (mnemonic:'RCL';opcode1:eo_reg2;opcode2:eo_ib;paramtype1:par_rm8;paramtype2:par_imm8;bytes:1;bt1:$c0),

  (mnemonic:'RCL';opcode1:eo_reg2;paramtype1:par_rm16;paramtype2:par_1;bytes:2;bt1:$66;bt2:$d1),
  (mnemonic:'RCL';opcode1:eo_reg2;paramtype1:par_rm16;paramtype2:par_cl;bytes:2;bt1:$66;bt2:$d3),
  (mnemonic:'RCL';opcode1:eo_reg2;opcode2:eo_ib;paramtype1:par_rm16;paramtype2:par_imm8;bytes:2;bt1:$66;bt2:$c1),

  (mnemonic:'RCL';opcode1:eo_reg2;paramtype1:par_rm32;paramtype2:par_1;bytes:1;bt1:$d1),
  (mnemonic:'RCL';opcode1:eo_reg2;paramtype1:par_rm32;paramtype2:par_cl;bytes:1;bt1:$d3),
  (mnemonic:'RCL';opcode1:eo_reg2;opcode2:eo_ib;paramtype1:par_rm32;paramtype2:par_imm8;bytes:1;bt1:$c1),

  (mnemonic:'RCPSS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m32;bytes:3;bt1:$f3;bt2:$0f;bt3:$53),
  (mnemonic:'RCPPS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:2;bt1:$0f;bt2:$53),


  (mnemonic:'RCR';opcode1:eo_reg3;paramtype1:par_rm32;paramtype2:par_1;bytes:1;bt1:$d1),
  (mnemonic:'RCR';opcode1:eo_reg3;paramtype1:par_rm32;paramtype2:par_cl;bytes:1;bt1:$d3),
  (mnemonic:'RCR';opcode1:eo_reg3;opcode2:eo_ib;paramtype1:par_rm32;paramtype2:par_imm8;bytes:1;bt1:$c1),

  (mnemonic:'RCR';opcode1:eo_reg3;paramtype1:par_rm16;paramtype2:par_1;bytes:2;bt1:$66;bt2:$d1),
  (mnemonic:'RCR';opcode1:eo_reg3;paramtype1:par_rm16;paramtype2:par_cl;bytes:2;bt1:$66;bt2:$d3),
  (mnemonic:'RCR';opcode1:eo_reg3;opcode2:eo_ib;paramtype1:par_rm16;paramtype2:par_imm8;bytes:2;bt1:$66;bt2:$c1),

  (mnemonic:'RCR';opcode1:eo_reg3;paramtype1:par_rm8;paramtype2:par_1;bytes:1;bt1:$d0),
  (mnemonic:'RCR';opcode1:eo_reg3;paramtype1:par_rm8;paramtype2:par_cl;bytes:1;bt1:$d2),
  (mnemonic:'RCR';opcode1:eo_reg3;opcode2:eo_ib;paramtype1:par_rm8;paramtype2:par_imm8;bytes:1;bt1:$c0),




  (mnemonic:'RDMSR';bytes:2;bt1:$0f;bt2:$32),
  (mnemonic:'RDPMC';bytes:2;bt1:$0f;bt2:$33),
  (mnemonic:'RDTSC';bytes:2;bt1:$0f;bt2:$31),

  (mnemonic:'RET';bytes:1;bt1:$c3),
  (mnemonic:'RET';bytes:1;bt1:$cb),
  (mnemonic:'RET';opcode1:eo_iw;paramtype1:par_imm16;bytes:1;bt1:$c2),
  (mnemonic:'RETN';bytes:1;bt1:$c3),
  (mnemonic:'RETN';opcode1:eo_iw;paramtype1:par_imm16;bytes:1;bt1:$c2),




  (mnemonic:'ROL';opcode1:eo_reg0;paramtype1:par_rm32;paramtype2:par_1;bytes:1;bt1:$d1),
  (mnemonic:'ROL';opcode1:eo_reg0;paramtype1:par_rm32;paramtype2:par_cl;bytes:1;bt1:$d3),
  (mnemonic:'ROL';opcode1:eo_reg0;opcode2:eo_ib;paramtype1:par_rm32;paramtype2:par_imm8;bytes:1;bt1:$c1),

  (mnemonic:'ROL';opcode1:eo_reg0;paramtype1:par_rm16;paramtype2:par_1;bytes:2;bt1:$66;bt2:$d1),
  (mnemonic:'ROL';opcode1:eo_reg0;paramtype1:par_rm16;paramtype2:par_cl;bytes:2;bt1:$66;bt2:$d3),
  (mnemonic:'ROL';opcode1:eo_reg0;opcode2:eo_ib;paramtype1:par_rm16;paramtype2:par_imm8;bytes:2;bt1:$66;bt2:$c1),

  (mnemonic:'ROL';opcode1:eo_reg0;paramtype1:par_rm8;paramtype2:par_1;bytes:1;bt1:$d0),
  (mnemonic:'ROL';opcode1:eo_reg0;paramtype1:par_rm8;paramtype2:par_cl;bytes:1;bt1:$d2),
  (mnemonic:'ROL';opcode1:eo_reg0;opcode2:eo_ib;paramtype1:par_rm8;paramtype2:par_imm8;bytes:1;bt1:$c0),

  (mnemonic:'ROR';opcode1:eo_reg1;paramtype1:par_rm32;paramtype2:par_1;bytes:1;bt1:$d1),
  (mnemonic:'ROR';opcode1:eo_reg1;paramtype1:par_rm32;paramtype2:par_cl;bytes:1;bt1:$d3),
  (mnemonic:'ROR';opcode1:eo_reg1;opcode2:eo_ib;paramtype1:par_rm32;paramtype2:par_imm8;bytes:1;bt1:$c1),

  (mnemonic:'ROR';opcode1:eo_reg1;paramtype1:par_rm16;paramtype2:par_1;bytes:2;bt1:$66;bt2:$d1),
  (mnemonic:'ROR';opcode1:eo_reg1;paramtype1:par_rm16;paramtype2:par_cl;bytes:2;bt1:$66;bt2:$d3),
  (mnemonic:'ROR';opcode1:eo_reg1;opcode2:eo_ib;paramtype1:par_rm16;paramtype2:par_imm8;bytes:2;bt1:$66;bt2:$c1),

  (mnemonic:'ROR';opcode1:eo_reg1;paramtype1:par_rm8;paramtype2:par_1;bytes:1;bt1:$d0),
  (mnemonic:'ROR';opcode1:eo_reg1;paramtype1:par_rm8;paramtype2:par_cl;bytes:1;bt1:$d2),
  (mnemonic:'ROR';opcode1:eo_reg1;opcode2:eo_ib;paramtype1:par_rm8;paramtype2:par_imm8;bytes:1;bt1:$c0),



  (mnemonic:'RSM';bytes:2;bt1:$0f;bt2:$aa),


  (mnemonic:'RSQRTPS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:2;bt1:$0f;bt2:$52),
  (mnemonic:'RSQRTSS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m32;bytes:3;bt1:$f3;bt2:$0f;bt3:$52),



  (mnemonic:'SAHF';bytes:1;bt1:$9e),

  (mnemonic:'SAL';opcode1:eo_reg4;paramtype1:par_rm32;paramtype2:par_1;bytes:1;bt1:$d1),
  (mnemonic:'SAL';opcode1:eo_reg4;paramtype1:par_rm32;paramtype2:par_cl;bytes:1;bt1:$d3),
  (mnemonic:'SAL';opcode1:eo_reg4;opcode2:eo_ib;paramtype1:par_rm32;paramtype2:par_imm8;bytes:1;bt1:$c1),

  (mnemonic:'SAL';opcode1:eo_reg4;paramtype1:par_rm16;paramtype2:par_1;bytes:2;bt1:$66;bt2:$d1),
  (mnemonic:'SAL';opcode1:eo_reg4;paramtype1:par_rm16;paramtype2:par_cl;bytes:2;bt1:$66;bt2:$d3),
  (mnemonic:'SAL';opcode1:eo_reg4;opcode2:eo_ib;paramtype1:par_rm16;paramtype2:par_imm8;bytes:2;bt1:$66;bt2:$c1),

  (mnemonic:'SAL';opcode1:eo_reg4;paramtype1:par_rm8;paramtype2:par_1;bytes:1;bt1:$d0),
  (mnemonic:'SAL';opcode1:eo_reg4;paramtype1:par_rm8;paramtype2:par_cl;bytes:1;bt1:$d2),
  (mnemonic:'SAL';opcode1:eo_reg4;opcode2:eo_ib;paramtype1:par_rm8;paramtype2:par_imm8;bytes:1;bt1:$c0),

  (mnemonic:'SAR';opcode1:eo_reg7;paramtype1:par_rm32;paramtype2:par_1;bytes:1;bt1:$d1),
  (mnemonic:'SAR';opcode1:eo_reg7;paramtype1:par_rm32;paramtype2:par_cl;bytes:1;bt1:$d3),
  (mnemonic:'SAR';opcode1:eo_reg7;opcode2:eo_ib;paramtype1:par_rm32;paramtype2:par_imm8;bytes:1;bt1:$c1),

  (mnemonic:'SAR';opcode1:eo_reg7;paramtype1:par_rm16;paramtype2:par_1;bytes:2;bt1:$66;bt2:$d1),
  (mnemonic:'SAR';opcode1:eo_reg7;paramtype1:par_rm16;paramtype2:par_cl;bytes:2;bt1:$66;bt2:$d3),
  (mnemonic:'SAR';opcode1:eo_reg7;opcode2:eo_ib;paramtype1:par_rm16;paramtype2:par_imm8;bytes:2;bt1:$66;bt2:$c1),

  (mnemonic:'SAR';opcode1:eo_reg7;paramtype1:par_rm8;paramtype2:par_1;bytes:1;bt1:$d0),
  (mnemonic:'SAR';opcode1:eo_reg7;paramtype1:par_rm8;paramtype2:par_cl;bytes:1;bt1:$d2),
  (mnemonic:'SAR';opcode1:eo_reg7;opcode2:eo_ib;paramtype1:par_rm8;paramtype2:par_imm8;bytes:1;bt1:$c0),

  (mnemonic:'SBB';opcode1:eo_ib;paramtype1:par_AL;paramtype2:par_imm8;bytes:1;bt1:$1c),
  (mnemonic:'SBB';opcode1:eo_iw;paramtype1:par_AX;paramtype2:par_imm16;bytes:2;bt1:$66;bt2:$1d),
  (mnemonic:'SBB';opcode1:eo_id;paramtype1:par_EAX;paramtype2:par_imm32;bytes:1;bt1:$1d),
  (mnemonic:'SBB';opcode1:eo_reg3;opcode2:eo_ib;paramtype1:par_rm8;paramtype2:par_imm8;bytes:1;bt1:$80),
  (mnemonic:'SBB';opcode1:eo_reg3;opcode2:eo_iw;paramtype1:par_rm16;paramtype2:par_imm16;bytes:2;bt1:$66;bt2:$80),
  (mnemonic:'SBB';opcode1:eo_reg3;opcode2:eo_id;paramtype1:par_rm32;paramtype2:par_imm32;bytes:1;bt1:$81),
  (mnemonic:'SBB';opcode1:eo_reg3;opcode2:eo_ib;paramtype1:par_rm16;paramtype2:par_imm8;bytes:2;bt1:$66;bt2:$83; signed: true),
  (mnemonic:'SBB';opcode1:eo_reg3;opcode2:eo_ib;paramtype1:par_rm32;paramtype2:par_imm8;bytes:1;bt1:$83; signed: true),
  (mnemonic:'SBB';opcode1:eo_reg;paramtype1:par_rm8;paramtype2:par_r8;bytes:1;bt1:$18),
  (mnemonic:'SBB';opcode1:eo_reg;paramtype1:par_rm16;paramtype2:par_r16;bytes:2;bt1:$66;bt2:$19),
  (mnemonic:'SBB';opcode1:eo_reg;paramtype1:par_rm32;paramtype2:par_r32;bytes:1;bt1:$19),
  (mnemonic:'SBB';opcode1:eo_reg;paramtype1:par_r8;paramtype2:par_rm8;bytes:1;bt1:$1a),
  (mnemonic:'SBB';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:2;bt1:$66;bt2:$1b),
  (mnemonic:'SBB';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:1;bt1:$1b),

  (mnemonic:'SCASB';bytes:1;bt1:$ae),
  (mnemonic:'SCASD';bytes:1;bt1:$af),
  (mnemonic:'SCASW';bytes:2;bt1:$66;bt2:$af),


  (mnemonic:'SETA';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$97;defaulttype:true),
  (mnemonic:'SETAE';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$93;defaulttype:true),
  (mnemonic:'SETB';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$92;defaulttype:true),
  (mnemonic:'SETBE';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$96;defaulttype:true),
  (mnemonic:'SETC';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$92;defaulttype:true),
  (mnemonic:'SETE';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$94;defaulttype:true),
  (mnemonic:'SETG';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$9f;defaulttype:true),
  (mnemonic:'SETGE';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$9d;defaulttype:true),
  (mnemonic:'SETL';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$9c;defaulttype:true),
  (mnemonic:'SETLE';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$9e;defaulttype:true),
  (mnemonic:'SETNA';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$96;defaulttype:true),

  (mnemonic:'SETNAE';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$92;defaulttype:true),
  (mnemonic:'SETNB';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$93;defaulttype:true),
  (mnemonic:'SETNBE';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$97;defaulttype:true),
  (mnemonic:'SETNC';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$93;defaulttype:true),
  (mnemonic:'SETNE';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$95;defaulttype:true),
  (mnemonic:'SETNG';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$9e;defaulttype:true),
  (mnemonic:'SETNGE';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$9c;defaulttype:true),
  (mnemonic:'SETNL';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$9d;defaulttype:true),
  (mnemonic:'SETNLE';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$9f;defaulttype:true),
  (mnemonic:'SETNO';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$91;defaulttype:true),
  (mnemonic:'SETNP';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$9b;defaulttype:true),

  (mnemonic:'SETNS';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$99;defaulttype:true),
  (mnemonic:'SETNZ';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$95;defaulttype:true),
  (mnemonic:'SETO';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$90;defaulttype:true),
  (mnemonic:'SETP';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$9a;defaulttype:true),
  (mnemonic:'SETPE';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$9a;defaulttype:true),
  (mnemonic:'SETPO';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$9b;defaulttype:true),
  (mnemonic:'SETS';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$98;defaulttype:true),
  (mnemonic:'SETZ';opcode1:eo_reg;paramtype1:par_rm8;bytes:2;bt1:$0f;bt2:$94;defaulttype:true),

  (mnemonic:'SFENCE';bytes:3;bt1:$0f;bt2:$ae;bt3:$f8),

  (mnemonic:'SGDT';opcode1:eo_reg0;paramtype1:par_m32;bytes:2;bt1:$0f;bt2:$01),

  (mnemonic:'SHL';opcode1:eo_reg4;paramtype1:par_rm32;bytes:1;bt1:$d1),
  (mnemonic:'SHL';opcode1:eo_reg4;paramtype1:par_rm32;paramtype2:par_1;bytes:1;bt1:$d1),
  (mnemonic:'SHL';opcode1:eo_reg4;paramtype1:par_rm16;paramtype2:par_1;bytes:2;bt1:$66;bt2:$d1),
  (mnemonic:'SHL';opcode1:eo_reg4;paramtype1:par_rm8;paramtype2:par_1;bytes:1;bt1:$d0),
  (mnemonic:'SHL';opcode1:eo_reg4;paramtype1:par_rm8;paramtype2:par_cl;bytes:1;bt1:$d2),
  (mnemonic:'SHL';opcode1:eo_reg4;opcode2:eo_ib;paramtype1:par_rm8;paramtype2:par_imm8;bytes:1;bt1:$c0),

  (mnemonic:'SHL';opcode1:eo_reg4;paramtype1:par_rm16;paramtype2:par_cl;bytes:2;bt1:$66;bt2:$d3),
  (mnemonic:'SHL';opcode1:eo_reg4;opcode2:eo_ib;paramtype1:par_rm16;paramtype2:par_imm8;bytes:2;bt1:$66;bt2:$c1),

  (mnemonic:'SHL';opcode1:eo_reg4;paramtype1:par_rm32;paramtype2:par_cl;bytes:1;bt1:$d3),
  (mnemonic:'SHL';opcode1:eo_reg4;opcode2:eo_ib;paramtype1:par_rm32;paramtype2:par_imm8;bytes:1;bt1:$c1),



  (mnemonic:'SHLD';opcode1:eo_reg;opcode2:eo_ib;paramtype1:par_rm16;paramtype2:par_r16;paramtype3:par_imm8;bytes:3;bt1:$66;bt2:$0f;bt3:$a4),
  (mnemonic:'SHLD';opcode1:eo_reg;paramtype1:par_rm16;paramtype2:par_r16;paramtype3:par_cl;bytes:3;bt1:$66;bt2:$0f;bt3:$a5),

  (mnemonic:'SHLD';opcode1:eo_reg;opcode2:eo_ib;paramtype1:par_rm32;paramtype2:par_r32;paramtype3:par_imm8;bytes:2;bt1:$0f;bt2:$a4),
  (mnemonic:'SHLD';opcode1:eo_reg;paramtype1:par_rm32;paramtype2:par_r32;paramtype3:par_cl;bytes:2;bt1:$0f;bt2:$a5),


  (mnemonic:'SHR';opcode1:eo_reg5;paramtype1:par_rm8;paramtype2:par_1;bytes:1;bt1:$d0),
  (mnemonic:'SHR';opcode1:eo_reg5;paramtype1:par_rm8;paramtype2:par_cl;bytes:1;bt1:$d2),
  (mnemonic:'SHR';opcode1:eo_reg5;opcode2:eo_ib;paramtype1:par_rm8;paramtype2:par_imm8;bytes:1;bt1:$c0),

  (mnemonic:'SHR';opcode1:eo_reg5;paramtype1:par_rm16;paramtype2:par_1;bytes:2;bt1:$66;bt2:$d1),
  (mnemonic:'SHR';opcode1:eo_reg5;paramtype1:par_rm16;paramtype2:par_cl;bytes:2;bt1:$66;bt2:$d3),
  (mnemonic:'SHR';opcode1:eo_reg5;opcode2:eo_ib;paramtype1:par_rm16;paramtype2:par_imm8;bytes:2;bt1:$66;bt2:$c1),

  (mnemonic:'SHR';opcode1:eo_reg5;paramtype1:par_rm32;bytes:1;bt1:$d1),
  (mnemonic:'SHR';opcode1:eo_reg5;paramtype1:par_rm32;paramtype2:par_1;bytes:1;bt1:$d1),
  (mnemonic:'SHR';opcode1:eo_reg5;paramtype1:par_rm32;paramtype2:par_cl;bytes:1;bt1:$d3),
  (mnemonic:'SHR';opcode1:eo_reg5;opcode2:eo_ib;paramtype1:par_rm32;paramtype2:par_imm8;bytes:1;bt1:$c1),

  (mnemonic:'SHRD';opcode1:eo_reg;opcode2:eo_ib;paramtype1:par_rm32;paramtype2:par_r32;paramtype3:par_imm8;bytes:2;bt1:$0f;bt2:$ac),
  (mnemonic:'SHRD';opcode1:eo_reg;paramtype1:par_rm32;paramtype2:par_r32;paramtype3:par_cl;bytes:2;bt1:$0f;bt2:$ad),

  (mnemonic:'SHUFPD';opcode1:eo_reg;opcode2:eo_ib;paramtype1:par_xmm;paramtype2:par_xmm_m128;paramtype3:par_imm8;bytes:3;bt1:$66;bt2:$0f;bt3:$c6),
  (mnemonic:'SHUFPS';opcode1:eo_reg;opcode2:eo_ib;paramtype1:par_xmm;paramtype2:par_xmm_m128;paramtype3:par_imm8;bytes:2;bt1:$0f;bt2:$c6),

  (mnemonic:'SIDT';opcode1:eo_reg1;paramtype1:par_m32;bytes:2;bt1:$0f;bt2:$01),
  (mnemonic:'SLDT';opcode1:eo_reg0;paramtype1:par_rm16;bytes:2;bt1:$0f;bt2:$00),

  (mnemonic:'SMSW';opcode1:eo_reg4;paramtype1:par_rm16;bytes:2;bt1:$0f;bt2:$01),

  (mnemonic:'SQRTPD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$51),
  (mnemonic:'SQRTPS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:2;bt1:$0f;bt2:$51),
  (mnemonic:'SQRTSD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m64;bytes:3;bt1:$f2;bt2:$0f;bt3:$51),
  (mnemonic:'SQRTSS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m32;bytes:3;bt1:$f3;bt2:$0f;bt3:$51),

  (mnemonic:'STC';bytes:1;bt1:$f9),
  (mnemonic:'STD';bytes:1;bt1:$fd),
  (mnemonic:'STI';bytes:1;bt1:$fb),

  (mnemonic:'STMXCSR';opcode1:eo_reg3;paramtype1:par_m32;bytes:2;bt1:$0f;bt2:$ae),

  (mnemonic:'STOSB';bytes:1;bt1:$aa),
  (mnemonic:'STOSD';bytes:1;bt1:$ab),
  (mnemonic:'STOSW';bytes:2;bt1:$66;bt2:$ab),

  (mnemonic:'STR';opcode1:eo_reg1;paramtype1:par_rm16;bytes:2;bt1:$0f;bt2:$00),


  (mnemonic:'SUB';opcode1:eo_ib;paramtype1:par_AL;paramtype2:par_imm8;bytes:1;bt1:$2c),
  (mnemonic:'SUB';opcode1:eo_iw;paramtype1:par_AX;paramtype2:par_imm16;bytes:2;bt1:$66;bt2:$2d),
  (mnemonic:'SUB';opcode1:eo_id;paramtype1:par_EAX;paramtype2:par_imm32;bytes:1;bt1:$2d),
  (mnemonic:'SUB';opcode1:eo_reg5;opcode2:eo_ib;paramtype1:par_rm8;paramtype2:par_imm8;bytes:1;bt1:$80),
  (mnemonic:'SUB';opcode1:eo_reg5;opcode2:eo_iw;paramtype1:par_rm16;paramtype2:par_imm16;bytes:2;bt1:$66;bt2:$81),
  (mnemonic:'SUB';opcode1:eo_reg5;opcode2:eo_id;paramtype1:par_rm32;paramtype2:par_imm32;bytes:1;bt1:$81),
  (mnemonic:'SUB';opcode1:eo_reg5;opcode2:eo_ib;paramtype1:par_rm16;paramtype2:par_imm8;bytes:2;bt1:$66;bt2:$83; signed: true),
  (mnemonic:'SUB';opcode1:eo_reg5;opcode2:eo_ib;paramtype1:par_rm32;paramtype2:par_imm8;bytes:1;bt1:$83; signed: true),
  (mnemonic:'SUB';opcode1:eo_reg;paramtype1:par_rm8;paramtype2:par_r8;bytes:1;bt1:$28),
  (mnemonic:'SUB';opcode1:eo_reg;paramtype1:par_rm16;paramtype2:par_r16;bytes:2;bt1:$66;bt2:$29),
  (mnemonic:'SUB';opcode1:eo_reg;paramtype1:par_rm32;paramtype2:par_r32;bytes:1;bt1:$29),
  (mnemonic:'SUB';opcode1:eo_reg;paramtype1:par_r8;paramtype2:par_rm8;bytes:1;bt1:$2a),
  (mnemonic:'SUB';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:2;bt1:$66;bt2:$2b),
  (mnemonic:'SUB';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:1;bt1:$2b),

  (mnemonic:'SUBPD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$5c),
  (mnemonic:'SUBPS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:2;bt1:$0f;bt2:$5c),
  (mnemonic:'SUBSD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m64;bytes:3;bt1:$f2;bt2:$0f;bt3:$5c),
  (mnemonic:'SUBSS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m32;bytes:3;bt1:$f3;bt2:$0f;bt3:$5c),
  (mnemonic:'SWAPGS';bytes:3;bt1:$0f;bt2:$01;bt3:$f8),

  (mnemonic:'SYSCALL';bytes:2;bt1:$0f;bt2:$05{; invalidin32bit:true}),
  (mnemonic:'SYSENTER';bytes:2;bt1:$0f;bt2:$34),
  (mnemonic:'SYSEXIT';bytes:2;bt1:$0f;bt2:$35),


  (mnemonic:'TEST';opcode1:eo_ib;paramtype1:par_AL;paramtype2:par_imm8;bytes:1;bt1:$a8),
  (mnemonic:'TEST';opcode1:eo_iw;paramtype1:par_AX;paramtype2:par_imm16;bytes:2;bt1:$66;bt2:$a9),
  (mnemonic:'TEST';opcode1:eo_id;paramtype1:par_EAX;paramtype2:par_imm32;bytes:1;bt1:$a9),

  (mnemonic:'TEST';opcode1:eo_reg0;opcode2:eo_ib;paramtype1:par_rm8;paramtype2:par_imm8;bytes:1;bt1:$f6),
  (mnemonic:'TEST';opcode1:eo_reg0;opcode2:eo_iw;paramtype1:par_rm16;paramtype2:par_imm16;bytes:2;bt1:$66;bt2:$f7),
  (mnemonic:'TEST';opcode1:eo_reg0;opcode2:eo_id;paramtype1:par_rm32;paramtype2:par_imm32;bytes:1;bt1:$f7),

  (mnemonic:'TEST';opcode1:eo_reg;paramtype1:par_rm8;paramtype2:par_r8;bytes:1;bt1:$84),
  (mnemonic:'TEST';opcode1:eo_reg;paramtype1:par_rm16;paramtype2:par_r16;bytes:2;bt1:$66;bt2:$85),
  (mnemonic:'TEST';opcode1:eo_reg;paramtype1:par_rm32;paramtype2:par_r32;bytes:1;bt1:$85),


  (mnemonic:'UCOMISD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m64;bytes:3;bt1:$66;bt2:$0f;bt3:$2e),
  (mnemonic:'UCOMISS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m32;bytes:2;bt1:$0f;bt2:$2e),

  (mnemonic:'UD2';bytes:2;bt1:$0f;bt2:$0b),

  (mnemonic:'UNPCKHPD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$15),
  (mnemonic:'UNPCKHPS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:2;bt1:$0f;bt2:$15),

  (mnemonic:'UNPCKLPD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$14),
  (mnemonic:'UNPCKLPS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:2;bt1:$0f;bt2:$14),

  (mnemonic:'VERR';opcode1:eo_reg4;paramtype1:par_rm16;bytes:2;bt1:$0f;bt2:$00),
  (mnemonic:'VERW';opcode1:eo_reg5;paramtype1:par_rm16;bytes:2;bt1:$0f;bt2:$00),

  (mnemonic:'VMCALL';bytes:3;bt1:$0f;bt2:$01;bt3:$c1),  
  (mnemonic:'VMCLEAR';opcode1:eo_reg6;paramtype1:par_m64;bytes:3;bt1:$66;bt2:$0f;bt3:$c7),
  (mnemonic:'VMLAUNCH';bytes:3;bt1:$0f;bt2:$01;bt3:$c2),
  (mnemonic:'VMPTRLD';opcode1:eo_reg6;paramtype1:par_m64;bytes:2;bt1:$0f;bt2:$c7),
  (mnemonic:'VMPTRST';opcode1:eo_reg7;paramtype1:par_m64;bytes:2;bt1:$0f;bt2:$c7),
  (mnemonic:'VMREAD';opcode1:eo_reg;paramtype1:par_rm32;paramtype2:par_r32;bytes:2;bt1:$0f;bt2:$78),
  (mnemonic:'VMRESUME';bytes:3;bt1:$0f;bt2:$01;bt3:$c3),
  (mnemonic:'VMWRITE';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:2;bt1:$0f;bt2:$79),  
  (mnemonic:'VMXOFF';bytes:3;bt1:$0f;bt2:$01;bt3:$c4),
  (mnemonic:'VMXON';opcode1:eo_reg6;paramtype1:par_m64;bytes:3;bt1:$f3;bt2:$0f;bt3:$c7),





  (mnemonic:'WAIT';bytes:1;bt1:$9b),
  (mnemonic:'WBINVD';bytes:2;bt1:$0f;bt2:$09),
  (mnemonic:'WRMSR';bytes:2;bt1:$0f;bt2:$30),

  (mnemonic:'XADD';opcode1:eo_reg;paramtype1:par_rm8;paramtype2:par_r8;bytes:2;bt1:$0f;bt2:$c0),
  (mnemonic:'XADD';opcode1:eo_reg;paramtype1:par_rm16;paramtype2:par_r16;bytes:3;bt1:$66;bt2:$0f;bt3:$c1),
  (mnemonic:'XADD';opcode1:eo_reg;paramtype1:par_rm32;paramtype2:par_r32;bytes:2;bt1:$0f;bt2:$c1),

  (mnemonic:'XCHG';opcode1:eo_prd;paramtype1:par_eax;paramtype2:par_r32;bytes:1;bt1:$90),
  (mnemonic:'XCHG';opcode1:eo_prw;paramtype1:par_ax;paramtype2:par_r16;bytes:2;bt1:$66;bt2:$90),

  (mnemonic:'XCHG';opcode1:eo_prw;paramtype1:par_r16;paramtype2:par_ax;bytes:2;bt1:$66;bt2:$90),

  (mnemonic:'XCHG';opcode1:eo_prd;paramtype1:par_r32;paramtype2:par_eax;bytes:1;bt1:$90),

  (mnemonic:'XCHG';opcode1:eo_reg;paramtype1:par_rm8;paramtype2:par_r8;bytes:1;bt1:$86),
  (mnemonic:'XCHG';opcode1:eo_reg;paramtype1:par_r8;paramtype2:par_rm8;bytes:1;bt1:$86),

  (mnemonic:'XCHG';opcode1:eo_reg;paramtype1:par_rm16;paramtype2:par_r16;bytes:2;bt1:$66;bt2:$87),
  (mnemonic:'XCHG';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:2;bt1:$66;bt2:$87),

  (mnemonic:'XCHG';opcode1:eo_reg;paramtype1:par_rm32;paramtype2:par_r32;bytes:1;bt1:$87),
  (mnemonic:'XCHG';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:1;bt1:$87),

  (mnemonic:'XLATB';bytes:1;bt1:$d7),

  (mnemonic:'XOR';opcode1:eo_ib;paramtype1:par_AL;paramtype2:par_imm8;bytes:1;bt1:$34),
  (mnemonic:'XOR';opcode1:eo_iw;paramtype1:par_AX;paramtype2:par_imm16;bytes:2;bt1:$66;bt2:$35),
  (mnemonic:'XOR';opcode1:eo_id;paramtype1:par_EAX;paramtype2:par_imm32;bytes:1;bt1:$35),
  (mnemonic:'XOR';opcode1:eo_reg6;opcode2:eo_ib;paramtype1:par_rm8;paramtype2:par_imm8;bytes:1;bt1:$80),
  (mnemonic:'XOR';opcode1:eo_reg6;opcode2:eo_id;paramtype1:par_rm32;paramtype2:par_imm32;bytes:1;bt1:$81),
  (mnemonic:'XOR';opcode1:eo_reg6;opcode2:eo_iw;paramtype1:par_rm16;paramtype2:par_imm16;bytes:2;bt1:$66;bt2:$81),
  (mnemonic:'XOR';opcode1:eo_reg6;opcode2:eo_ib;paramtype1:par_rm16;paramtype2:par_imm8;bytes:2;bt1:$66;bt2:$83; signed: true),
  (mnemonic:'XOR';opcode1:eo_reg6;opcode2:eo_ib;paramtype1:par_rm32;paramtype2:par_imm8;bytes:1;bt1:$83; signed: true),
  (mnemonic:'XOR';opcode1:eo_reg;paramtype1:par_rm8;paramtype2:par_r8;bytes:1;bt1:$30),
  (mnemonic:'XOR';opcode1:eo_reg;paramtype1:par_rm16;paramtype2:par_r16;bytes:2;bt1:$66;bt2:$31),
  (mnemonic:'XOR';opcode1:eo_reg;paramtype1:par_rm32;paramtype2:par_r32;bytes:1;bt1:$31),
  (mnemonic:'XOR';opcode1:eo_reg;paramtype1:par_r8;paramtype2:par_rm8;bytes:1;bt1:$32),
  (mnemonic:'XOR';opcode1:eo_reg;paramtype1:par_r16;paramtype2:par_rm16;bytes:2;bt1:$66;bt2:$33),
  (mnemonic:'XOR';opcode1:eo_reg;paramtype1:par_r32;paramtype2:par_rm32;bytes:1;bt1:$33),

  (mnemonic:'XORPD';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:3;bt1:$66;bt2:$0f;bt3:$57),
  (mnemonic:'XORPS';opcode1:eo_reg;paramtype1:par_xmm;paramtype2:par_xmm_m128;bytes:2;bt1:$0f;bt2:$57;),

  (mnemonic:'XRSTOR';opcode1:eo_reg5;paramtype1:par_m32;bytes:2;bt1:$0f;bt2:$ae; norexw:true),
  (mnemonic:'XRSTOR64';opcode1:eo_reg5;paramtype1:par_m64;bytes:3;bt1:$48;bt2:$0f;bt3:$ae; norexw:true),

  (mnemonic:'XSAVE';opcode1:eo_reg4;paramtype1:par_m32;bytes:2;bt1:$0f;bt2:$ae; norexw:true),
  (mnemonic:'XSAVE64';opcode1:eo_reg4;paramtype1:par_m64;bytes:3;bt1:$48;bt2:$0f;bt3:$ae; norexw:true)
);



type
  PIndexArray=^TIndexArray;
  TIndex=record
    startentry: integer;
    SubIndex: PIndexArray;
    NextEntry: integer;
  end;
  TIndexArray=array [0..25] of TIndex;

type ttokens=array of string;
type TAssemblerBytes=array of byte;

type TAssemblerEvent=procedure(address:qword; instruction: string; var bytes: TAssemblerBytes) of object;

type TassemblerPreference=(apNone, apShort, apLong);

function Assemble(opcode:string; address: ptrUint;var bytes: TAssemblerBytes; assemblerPreference: TassemblerPreference=apNone; skiprangecheck: boolean=false): boolean;
function GetOpcodesIndex(opcode: string): integer;

//function tokenize(opcode:string; var tokens: ttokens): boolean;
function gettokentype(var token:string;token2: string): TTokenType;
function getreg(reg: string;exceptonerror:boolean): integer; overload;
function getreg(reg: string): integer; overload;
function TokenToRegisterbit(token:string): TTokenType;


type TSingleLineAssembler=class
  private
    RexPrefix: Byte;
    RexPrefixLocation: integer; //index into the bytes array
    relativeAddressLocation: integer; //index into the bytes array containing the start of th relative 4 byte address
    actualdisplacement: qword;
    needsAddressSwitchPrefix: boolean;

    function getRex_W: boolean;
    procedure setRex_W(state: boolean);
    function getRex_R: boolean;
    procedure setRex_R(state: boolean);
    function getRex_X: boolean;
    procedure setRex_X(state: boolean);
    function getRex_B: boolean;
    procedure setRex_B(state: boolean);

    procedure setrm(var modrm: byte;i: byte);
    procedure setsibindex(var sib: byte; i:byte);
    procedure setsibbase(var sib:byte; i:byte);
    procedure setmodrm(var modrm:tassemblerbytes;address:string; offset: integer);
    procedure createsibscaleindex(var sib:byte;reg:string);
    procedure addopcode(var bytes:tassemblerbytes;i:integer);
    function createModRM(var bytes: tassemblerbytes;reg:integer;param: string):boolean;
    function getreg(reg: string;exceptonerror:boolean): integer; overload;
    function getreg(reg: string): integer; overload;

    function HandleTooBigAddress(opcode: string; address: ptrUint;var bytes: TAssemblerBytes; actualdisplacement: integer): boolean;
  public
    function Assemble(opcode:string; address: ptrUint;var bytes: TAssemblerBytes;assemblerPreference: TassemblerPreference=apNone; skiprangecheck: boolean=false): boolean;

    property REX_W: boolean read getRex_W write setRex_W;
    property REX_R: boolean read getRex_R write setRex_R;
    property REX_X: boolean read getRex_X write setRex_X;
    property REX_B: boolean read getRex_B write setRex_B;

end;

var SingleLineAssembler: TSingleLineAssembler;


var parameter1,parameter2,parameter3: integer;
    opcodenr: integer;

    assemblerindex: TIndexArray;

function registerAssembler(m: TAssemblerEvent): integer;
procedure unregisterAssembler(id: integer);


implementation

{$ifdef jni}
uses symbolhandler, assemblerArm, Parsers, NewKernelHandler;
{$endif}

{$ifdef windows}
uses {$ifndef autoassemblerdll}CEFuncProc,{$endif}symbolhandler, lua, luahandler,
  lualib, assemblerArm, Parsers, NewKernelHandler, LuaCaller;
{$endif}

resourcestring
  rsInvalidRegister = 'Invalid register';
  rsInvalid = 'Invalid';
  rsInvalidMultiplier = 'Invalid multiplier';
  rsWTFIsA = 'WTF is a ';
  rsIDontUnderstandWhatYouMeanWith = 'I don''t understand what you mean with ';
  rsNegativeRegistersCanNotBeEncoded = 'Negative registers can not be encoded';
  rsInvalidAddress = 'Invalid address';
  rsTheAssemblerTriedToSetARegisteValueThatIsTooHigh = 'The assembler tried to set a register value that is too high';
  rsAssemblerError = 'Assembler error';
  rsOffsetTooBig = 'offset too big';
var ExtraAssemblers: array of TAssemblerEvent;


function registerAssembler(m: TAssemblerEvent): integer;
var i: integer;
begin
  for i:=0 to length(ExtraAssemblers)-1 do
  begin
    if assigned(ExtraAssemblers[i])=false then
    begin
      ExtraAssemblers[i]:=m;
      result:=i;
      exit;
    end
  end;

  result:=length(ExtraAssemblers);
  setlength(ExtraAssemblers, result+1);
  ExtraAssemblers[result]:=m;
end;

procedure unregisterAssembler(id: integer);
begin
  if id<length(ExtraAssemblers) then
  begin
    {$ifndef unix}
    CleanupLuaCall(TMethod(ExtraAssemblers[id]));
    {$endif}
    ExtraAssemblers[id]:=nil;
  end;
end;


function GetOpcodesIndex(opcode: string): integer;
{
will return the first entry in the opcodes list for this opcode
If not found, -1
}
var i: integer;
    index1,index2: integer;
    bestindex: PIndexArray;
    minindex,maxindex: integer;
begin
  opcode:=uppercase(opcode);
  result:=-1;
  if length(opcode)>0 then
  begin
    index1:=ord(opcode[1])-ord('A');
    if (index1<0) or (index1>25) then exit; //not alphabetical

    bestindex:=@assemblerindex[index1];
    if (bestindex[0].startentry=-1) then exit;

    if (assemblerindex[index1].SubIndex<>nil) and (length(opcode)>1) then
    begin
      index2:=ord(opcode[2])-ord('A');
      if (index2>=0) and (index2<=25) then
      begin
        bestindex:=@assemblerindex[index1].SubIndex[index2];
        if bestindex[0].startentry=-1 then exit; //no subitem2
      end;  //else not alphabetical

    end;

    minindex:=bestindex[0].startentry;
    maxindex:=bestindex[0].NextEntry;

    if maxindex=-1 then
      if assemblerindex[index1].NextEntry<>-1 then
        maxindex:=assemblerindex[index1].NextEntry
      else
        maxindex:=opcodecount;

    if maxindex>opcodecount then
    begin
     // messagebox(0,pchar(opcode+':'+inttostr(maxindex)),'aaa',0);
      maxindex:=opcodecount;
    end;

    //now scan from minindex to maxindex for opcode
    for i:=minindex to maxindex do
      if opcodes[i].mnemonic=opcode then
      begin
        result:=i; //found it
        exit;
      end else if opcodes[i].mnemonic[1]<>opcode[1] then exit;

    //still here, not found, -1
  end;
end;

function isMemoryLocationDefault(parameter:string):boolean;
begin
  result:=(parameter[1]='[') and (parameter[length(parameter)]=']');
end;

procedure Add(var bytes: Tassemblerbytes; const A: array of byte);
var i: integer;
begin
  setlength(bytes,length(bytes)+length(a));
  for i:=0 to length(a)-1 do
    bytes[length(bytes)-length(a)+i]:=a[i];
end;

procedure AddWord(var Bytes: TAssemblerbytes; a: word);
begin
  add(bytes,[byte(a)]);
  add(bytes,[byte(a shr 8)]);
end;

procedure AddDword(var bytes: tassemblerbytes; a: dword);
begin
  add(bytes,[byte(a)]);
  add(bytes,[byte(a shr 8)]);
  add(bytes,[byte(a shr 16)]);
  add(bytes,[byte(a shr 24)]);
end;

procedure AddQword(var bytes: tassemblerbytes; a: int64);
begin
  add(bytes,[byte(a)]);
  add(bytes,[byte(a shr 8)]);
  add(bytes,[byte(a shr 16)]);
  add(bytes,[byte(a shr 24)]);
  add(bytes,[byte(a shr 32)]);
  add(bytes,[byte(a shr 40)]);
  add(bytes,[byte(a shr 48)]);
  add(bytes,[byte(a shr 56)]);
end;

procedure AddString(var bytes: Tassemblerbytes; s: string);
var i,j: integer;
begin
  j:=length(bytes);
  setlength(bytes,length(bytes)+length(s)-2); //not the quotes;

  for i:=2 to length(s)-1 do
  begin
    bytes[j]:=ord(s[i]);
    inc(j);
  end;
end;

function SignedValueToType(value: integer): integer;
begin
  result:=8;

  if ((value<-128) or (value>127)) then result:=16;
  if ((value<-32768) or (value>32767)) then result:=32;


end;

function ValueToType(value: dword): integer;
begin
  result:=32;
  if value<=$ffff then
  begin
    result:=16;
    if value>=$8000 then result:=32;
  end;

  if value<=$ff then
  begin
    result:=8;
    if value>=$80 then result:=16;
  end;

  if result=32 then
  begin
    if integer(value)<0 then
    begin
      if integer(value)>=-128 then result:=8 else
      if integer(value)>=-32768 then result:=16;
    end;
  end;
end;

function StringValueToType(value: string): integer;
var x: dword;
    err: integer;
begin
  //this function converts a sttring to a valuetype depending on how it is written
  result:=0;

  val(value,x,err);
  if err>0 then exit;

  if length(value)=17 then result:=64 else
  if length(value)=9 then result:=32 else
  if length(value)=5 then
  begin
   result:=16;
   if x>65535 then result:=32;
  end
  else
  if length(value)=3 then
  begin
    result:=8;
    if x>255 then
      result:=16;
  end;

  if result=0 then result:=ValueToType(x); //not a specific ammount of characters given
end;


{old obsolete but still being called}
function getreg(reg: string;exceptonerror:boolean): integer; overload;
begin
  result:=-1;
  if (reg='RAX') or (reg='EAX') or (reg='AX') or (reg='AL') or (reg='MM0') or (reg='XMM0') or (reg='ST(0)') or (reg='ST') or (reg='ES') or (reg='CR0') or (reg='DR0') then result:=0;
  if (reg='RCX') or (reg='ECX') or (reg='CX') or (reg='CL') or (reg='MM1') or (reg='XMM1') or (reg='ST(1)') or (reg='CS') or (reg='CR1') or (reg='DR1') then result:=1;
  if (reg='RDX') or (reg='EDX') or (reg='DX') or (reg='DL') or (reg='MM2') or (reg='XMM2') or (reg='ST(2)') or (reg='SS') or (reg='CR2') or (reg='DR2') then result:=2;
  if (reg='RBX') or (reg='EBX') or (reg='BX') or (reg='BL') or (reg='MM3') or (reg='XMM3') or (reg='ST(3)') or (reg='DS') or (reg='CR3') or (reg='DR3') then result:=3;
  if (reg='SPL') or (reg='RSP') or (reg='ESP') or (reg='SP') or (reg='AH') or (reg='MM4') or (reg='XMM4') or (reg='ST(4)') or (reg='FS') or (reg='CR4') or (reg='DR4') then result:=4;
  if (reg='BPL') or (reg='RBP') or (reg='EBP') or (reg='BP') or (reg='CH') or (reg='MM5') or (reg='XMM5') or (reg='ST(5)') or (reg='GS') or (reg='CR5') or (reg='DR5') then result:=5;
  if (reg='SIL') or (reg='RSI') or (reg='ESI') or (reg='SI') or (reg='DH') or (reg='MM6') or (reg='XMM6') or (reg='ST(6)') or (reg='HS') or (reg='CR6') or (reg='DR6') then result:=6;
  if (reg='DIL') or (reg='RDI') or (reg='EDI') or (reg='DI') or (reg='BH') or (reg='MM7') or (reg='XMM7') or (reg='ST(7)') or (reg='IS') or (reg='CR7') or (reg='DR7') then result:=7;
  if (reg='R8') then result:=8;
  if (reg='R9') then result:=9;
  if (reg='R10') then result:=10;
  if (reg='R11') then result:=11;
  if (reg='R12') then result:=12;
  if (reg='R13') then result:=13;
  if (reg='R14') then result:=14;
  if (reg='R15') then result:=15;

  if (result=-1) and exceptonerror then raise exception.Create(rsInvalidRegister);
end;

function getreg(reg: string): integer; overload;
begin
  result:=getreg(reg,true);
end;
{^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^}

function TSingleLineAssembler.getreg(reg: string;exceptonerror:boolean): integer; overload;
begin
  result:=1000;
  if (reg='RAX') or (reg='EAX') or (reg='AX') or (reg='AL') or (reg='MM0') or (reg='XMM0') or (reg='ST(0)') or (reg='ST') or (reg='ES') or (reg='CR0') or (reg='DR0') then result:=0;
  if (reg='RCX') or (reg='ECX') or (reg='CX') or (reg='CL') or (reg='MM1') or (reg='XMM1') or (reg='ST(1)') or (reg='CS') or (reg='CR1') or (reg='DR1') then result:=1;
  if (reg='RDX') or (reg='EDX') or (reg='DX') or (reg='DL') or (reg='MM2') or (reg='XMM2') or (reg='ST(2)') or (reg='SS') or (reg='CR2') or (reg='DR2') then result:=2;
  if (reg='RBX') or (reg='EBX') or (reg='BX') or (reg='BL') or (reg='MM3') or (reg='XMM3') or (reg='ST(3)') or (reg='DS') or (reg='CR3') or (reg='DR3') then result:=3;
  if (reg='RSP') or (reg='ESP') or (reg='SP') or (reg='AH') or (reg='MM4') or (reg='XMM4') or (reg='ST(4)') or (reg='FS') or (reg='CR4') or (reg='DR4') then result:=4;
  if (reg='RBP') or (reg='EBP') or (reg='BP') or (reg='CH') or (reg='MM5') or (reg='XMM5') or (reg='ST(5)') or (reg='GS') or (reg='CR5') or (reg='DR5') then result:=5;
  if (reg='RSI') or (reg='ESI') or (reg='SI') or (reg='DH') or (reg='MM6') or (reg='XMM6') or (reg='ST(6)') or (reg='HS') or (reg='CR6') or (reg='DR6') then result:=6;
  if (reg='RDI') or (reg='EDI') or (reg='DI') or (reg='BH') or (reg='MM7') or (reg='XMM7') or (reg='ST(7)') or (reg='IS') or (reg='CR7') or (reg='DR7') then result:=7;
  if processhandler.is64Bit then
  begin
    if (reg='SPL') then result:=4 else
    if (reg='BPL') then result:=5 else
    if (reg='SIL') then result:=6 else
    if (reg='DIL') then result:=7 else
    if (reg='R8') or (reg='R8D') or (reg='R8W') or (reg='R8L') or (reg='MM8') or (reg='XMM8') or (reg='ST(8)') or (reg='JS') or (reg='CR8') or (reg='DR8') then result:=8;
    if (reg='R9') or (reg='R9D') or (reg='R9W') or (reg='R9L') or (reg='MM9') or (reg='XMM9') or (reg='ST(9)') or (reg='KS') or (reg='CR9') or (reg='DR9') then result:=9;
    if (reg='R10') or (reg='R10D') or (reg='R10W') or (reg='R10L') or (reg='MM10') or (reg='XMM10') or (reg='ST(10)') or (reg='KS') or (reg='CR10') or (reg='DR10') then result:=10;
    if (reg='R11') or (reg='R11D') or (reg='R11W') or (reg='R11L') or (reg='MM11') or (reg='XMM11') or (reg='ST(11)') or (reg='LS') or (reg='CR11') or (reg='DR11') then result:=11;
    if (reg='R12') or (reg='R12D') or (reg='R12W') or (reg='R12L') or (reg='MM12') or (reg='XMM12') or (reg='ST(12)') or (reg='MS') or (reg='CR12') or (reg='DR12') then result:=12;
    if (reg='R13') or (reg='R13D') or (reg='R13W') or (reg='R13L') or (reg='MM13') or (reg='XMM13') or (reg='ST(13)') or (reg='NS') or (reg='CR13') or (reg='DR13') then result:=13;
    if (reg='R14') or (reg='R14D') or (reg='R14W') or (reg='R14L') or (reg='MM14') or (reg='XMM14') or (reg='ST(14)') or (reg='OS') or (reg='CR14') or (reg='DR14') then result:=14;
    if (reg='R15') or (reg='R15D') or (reg='R15W') or (reg='R15L') or (reg='MM15') or (reg='XMM15') or (reg='ST(15)') or (reg='PS') or (reg='CR15') or (reg='DR15') then result:=15;
  end;

  if (result=1000) and exceptonerror then raise exception.Create(rsInvalidRegister);
end;

function TSingleLineAssembler.getreg(reg: string): integer; overload;
begin
  result:=getreg(reg,true);
end;



function TokenToRegisterbit(token:string): TTokenType;
//todo: Optimize with a case statement A->AL/AH/AX , B->BL/ .....
begin
  result:=ttRegister32bit;

  if token='AL' then result:=ttRegister8bit else
  if token='CL' then result:=ttRegister8bit else
  if token='DL' then result:=ttRegister8bit else
  if token='BL' then result:=ttRegister8bit else
  if token='AH' then result:=ttRegister8bit else
  if token='CH' then result:=ttRegister8bit else
  if token='DH' then result:=ttRegister8bit else
  if token='BH' then result:=ttRegister8bit else

  if token='AX' then result:=ttRegister16bit else
  if token='CX' then result:=ttRegister16bit else
  if token='DX' then result:=ttRegister16bit else
  if token='BX' then result:=ttRegister16bit else
  if token='SP' then result:=ttRegister16bit else
  if token='BP' then result:=ttRegister16bit else
  if token='SI' then result:=ttRegister16bit else
  if token='DI' then result:=ttRegister16bit else

  if token='EAX' then result:=ttRegister32bit else
  if token='ECX' then result:=ttRegister32bit else
  if token='EDX' then result:=ttRegister32bit else
  if token='EBX' then result:=ttRegister32bit else
  if token='ESP' then result:=ttRegister32bit else
  if token='EBP' then result:=ttRegister32bit else
  if token='ESI' then result:=ttRegister32bit else
  if token='EDI' then result:=ttRegister32bit else

  if token='MM0' then result:=ttRegisterMM else
  if token='MM1' then result:=ttRegisterMM else
  if token='MM2' then result:=ttRegisterMM else
  if token='MM3' then result:=ttRegisterMM else
  if token='MM4' then result:=ttRegisterMM else
  if token='MM5' then result:=ttRegisterMM else
  if token='MM6' then result:=ttRegisterMM else
  if token='MM7' then result:=ttRegisterMM else

  if token='XMM0' then result:=ttRegisterXMM else
  if token='XMM1' then result:=ttRegisterXMM else
  if token='XMM2' then result:=ttRegisterXMM else
  if token='XMM3' then result:=ttRegisterXMM else
  if token='XMM4' then result:=ttRegisterXMM else
  if token='XMM5' then result:=ttRegisterXMM else
  if token='XMM6' then result:=ttRegisterXMM else
  if token='XMM7' then result:=ttRegisterXMM else


  if token='ST' then result:=ttRegisterST else
  if token='ST(0)' then result:=ttRegisterST else
  if token='ST(1)' then result:=ttRegisterST else
  if token='ST(2)' then result:=ttRegisterST else
  if token='ST(3)' then result:=ttRegisterST else
  if token='ST(4)' then result:=ttRegisterST else
  if token='ST(5)' then result:=ttRegisterST else
  if token='ST(6)' then result:=ttRegisterST else
  if token='ST(7)' then result:=ttRegisterST else

  if token='ES' then result:=ttRegistersreg else
  if token='CS' then result:=ttRegistersreg else
  if token='SS' then result:=ttRegistersreg else
  if token='DS' then result:=ttRegistersreg else
  if token='FS' then result:=ttRegistersreg else
  if token='GS' then result:=ttRegistersreg else
  if token='HS' then result:=ttRegistersreg else
  if token='IS' then result:=ttRegistersreg else

  if token='CR0' then result:=ttRegisterCR else
  if token='CR1' then result:=ttRegisterCR else
  if token='CR2' then result:=ttRegisterCR else
  if token='CR3' then result:=ttRegisterCR else
  if token='CR4' then result:=ttRegisterCR else
  if token='CR5' then result:=ttRegisterCR else
  if token='CR6' then result:=ttRegisterCR else
  if token='CR7' then result:=ttRegisterCR else


  if token='DR0' then result:=ttRegisterDR else
  if token='DR1' then result:=ttRegisterDR else
  if token='DR2' then result:=ttRegisterDR else
  if token='DR3' then result:=ttRegisterDR else
  if token='DR4' then result:=ttRegisterDR else
  if token='DR5' then result:=ttRegisterDR else
  if token='DR6' then result:=ttRegisterDR else
  if token='DR7' then result:=ttRegisterDR else

  if processhandler.is64Bit then
  begin
    if token='RAX' then result:=ttRegister64bit else
    if token='RCX' then result:=ttRegister64bit else
    if token='RDX' then result:=ttRegister64bit else
    if token='RBX' then result:=ttRegister64bit else
    if token='RSP' then result:=ttRegister64bit else
    if token='RBP' then result:=ttRegister64bit else
    if token='RSI' then result:=ttRegister64bit else
    if token='RDI' then result:=ttRegister64bit else
    if token='R8' then result:=ttRegister64bit else
    if token='R9' then result:=ttRegister64bit else
    if token='R10' then result:=ttRegister64bit else
    if token='R11' then result:=ttRegister64bit else
    if token='R12' then result:=ttRegister64bit else
    if token='R13' then result:=ttRegister64bit else
    if token='R14' then result:=ttRegister64bit else
    if token='R15' then result:=ttRegister64bit else

    if token='SPL' then result:=ttRegister8BitWithPrefix else
    if token='BPL' then result:=ttRegister8BitWithPrefix else
    if token='SIL' then result:=ttRegister8BitWithPrefix else
    if token='DIL' then result:=ttRegister8BitWithPrefix else


    if token='R8L' then result:=ttRegister8Bit else
    if token='R9L' then result:=ttRegister8Bit else
    if token='R10L' then result:=ttRegister8Bit else
    if token='R11L' then result:=ttRegister8Bit else
    if token='R12L' then result:=ttRegister8Bit else
    if token='R13L' then result:=ttRegister8Bit else
    if token='R14L' then result:=ttRegister8Bit else
    if token='R15L' then result:=ttRegister8Bit else

    if token='R8W' then result:=ttRegister16Bit else
    if token='R9W' then result:=ttRegister16Bit else
    if token='R10W' then result:=ttRegister16Bit else
    if token='R11W' then result:=ttRegister16Bit else
    if token='R12W' then result:=ttRegister16Bit else
    if token='R13W' then result:=ttRegister16Bit else
    if token='R14W' then result:=ttRegister16Bit else
    if token='R15W' then result:=ttRegister16Bit else

    if token='R8D' then result:=ttRegister32Bit else
    if token='R9D' then result:=ttRegister32Bit else
    if token='R10D' then result:=ttRegister32Bit else
    if token='R11D' then result:=ttRegister32Bit else
    if token='R12D' then result:=ttRegister32Bit else
    if token='R13D' then result:=ttRegister32Bit else
    if token='R14D' then result:=ttRegister32Bit else
    if token='R15D' then result:=ttRegister32Bit else

    if token='XMM8' then result:=ttRegisterXMM else
    if token='XMM9' then result:=ttRegisterXMM else
    if token='XMM10' then result:=ttRegisterXMM else
    if token='XMM11' then result:=ttRegisterXMM else
    if token='XMM12' then result:=ttRegisterXMM else
    if token='XMM13' then result:=ttRegisterXMM else
    if token='XMM14' then result:=ttRegisterXMM else
    if token='XMM15' then result:=ttRegisterXMM else

    if token='CR8' then result:=ttRegisterCR else
    if token='CR9' then result:=ttRegisterCR else
    if token='CR10' then result:=ttRegisterCR else
    if token='CR11' then result:=ttRegisterCR else
    if token='CR12' then result:=ttRegisterCR else
    if token='CR13' then result:=ttRegisterCR else
    if token='CR14' then result:=ttRegisterCR else
    if token='CR15' then result:=ttRegisterCR;
  end;

end;

function gettokentype(var token:string;token2: string): TTokenType;
var err: integer;
    temp:string;
    i64: int64;
begin
  result:=ttInvalidtoken;
  if length(token)=0 then exit;

  result:=tokenToRegisterbit(token);

  //filter these 2 words
  token:=StringReplace(token,'LONG ','',[rfIgnoreCase]);
  token:=StringReplace(token,'SHORT ','',[rfIgnoreCase]);
  token:=StringReplace(token,'FAR ','',[rfIgnoreCase]);   

  temp:=ConvertHexStrToRealStr(token);
  val(temp,i64,err);
  if err=0 then
  begin
    result:=ttValue;
    token:=temp;
  end;


  //see if it is a memorylocation
  //can start with [ or ptr [
  //temp:=StringReplace(token,'PTR [', '[',[rfIgnoreCase]);


  if pos('[',token)>0 then
  begin
    if (pos('DQWORD ',token)>0) then result:=ttMemorylocation128 else
    if (pos('TBYTE ',token)>0) then result:=ttMemorylocation80 else
    if (pos('TWORD ',token)>0) then result:=ttMemorylocation80 else
    if (pos('QWORD ',token)>0) then result:=ttMemorylocation64 else
    if (pos('DWORD ',token)>0) then result:=ttMemorylocation32 else
    if (pos('WORD ',token)>0) then result:=ttMemorylocation16 else
    if (pos('BYTE ',token)>0) then result:=ttMemorylocation8 else
      result:=ttMemorylocation;
  end;

  if result=ttMemorylocation then
  begin
    if token2='' then
    begin
      result:=ttMemorylocation32;
      exit;
    end;

    //I need the helper param to figure it out
    case TokenToRegisterbit(token2) of
      ttRegister8bit,ttRegister8BitWithPrefix:
        result:=ttMemorylocation8;
      ttRegistersreg, TTRegister16bit:
        result:=ttMemorylocation16;
      ttRegister64Bit:
        result:=ttMemoryLocation64;

      else result:=ttMemorylocation32;
    end;
  end;

end;

function isrm8(parametertype:TTokenType): boolean;
begin
  result:=(parametertype=ttMemorylocation8) or (parametertype=ttRegister8bit);
end;

function isrm16(parametertype:TTokenType): boolean;
begin
  result:=(parametertype=ttmemorylocation16) or (parametertype=ttregister16bit);
end;

function isrm32(parametertype:TTokenType): boolean;
begin
  result:=(parametertype=ttmemorylocation32) or (parametertype=ttregister32bit);
end;

function ismm_m32(parametertype:TTokenType): boolean;
begin
  result:=(parametertype=ttRegisterMM) or (parametertype=ttMemorylocation32);
end;

function ismm_m64(parametertype:TTokenType): boolean;
begin
  result:=(parametertype=ttRegisterMM) or (parametertype=ttMemorylocation64);
end;

function isxmm_m32(parametertype:TTokenType): boolean;
begin
  result:=(parametertype=ttRegisterXMM) or (parametertype=ttMemorylocation32);
end;

function isxmm_m64(parametertype:TTokenType): boolean;
begin
  result:=(parametertype=ttRegisterXMM) or (parametertype=ttMemorylocation64);
end;

function isxmm_m128(parametertype:TTokenType):boolean;
begin
  result:=(parametertype=ttRegisterXMM) or (parametertype=ttMemorylocation128);
end;

function rewrite(var token:string): boolean;
var i,j,err,err2: integer;
    a,b: qword;
    tokens: array of string;
    last: integer;

    temp: string;
    haserror: boolean;
    inQuote: boolean;
    quotechar: char;
begin
  if length(token)=0 then exit(false); //empty string


  quotechar:=#0;

  setlength(tokens,0);
  result:=false;
  last:=-1;



  { 5.4: special pointer notation case }
  if (length(token)>4) and (token[1]+token[2]='[[') and (token[length(token)]=']') then
  begin
    //looks like a pointer in a address specifier (idiot user detected...)


    temp:='['+inttohex(symhandler.getaddressfromname(copy(token,2,length(token)-2), false,haserror),8)+']';
    if not haserror then
      token:=temp
    else
      raise exception.create(rsInvalid);
  end;


  { 5.4 ^^^ }

  temp:='';
  i:=1;
  inquote:=false;
  while i<=length(token) do
  begin
    if token[i] in ['''', '"'] then
    begin
      if inQuote then
      begin
        if token[i]=quotechar then
          inQuote:=false;
      end
      else
      begin
        //start of a quote
        quotechar:=token[i];
        inquote:=true;
      end;
    end;

    if not inquote then
    begin
      if token[i] in ['[',']','+','-'] then
      begin
        if temp<>'' then
        begin
          setlength(tokens,length(tokens)+1);
          tokens[length(tokens)-1]:=temp;
          temp:='';
        end;
        setlength(tokens,length(tokens)+1);
        tokens[length(tokens)-1]:=token[i];
        inc(i);
        continue;
      end;
    end;
    temp:=temp+token[i];
    inc(i);
  end;

  if temp<>'' then
  begin
    setlength(tokens,length(tokens)+1);
    tokens[length(tokens)-1]:=temp;
    temp:='';
  end;


  for i:=0 to length(tokens)-1 do
  begin
    if (length(tokens[i])>=1) and (not (tokens[i][1] in ['[',']','+','-','*'])) then //3/16/2011: 11:15 (replaced or with and)
    begin
      val('$'+tokens[i],j,err);
      if (err<>0) and (getreg(tokens[i],false)=-1) then    //not a hexadecimal value and not a register
      begin
        temp:=inttohex(symhandler.getaddressfromname(tokens[i], false, haserror,nil),8);
        if not haserror then
          tokens[i]:=temp //can be rewritten as a hexadecimal
        else
        begin
          if (i<length(tokens)-1) then
          begin
            //perhaps it can be concatenated with the next one
            if (length(tokens[i+1])>0) and (not (tokens[i+1][1] in ['''','"','[',']','(',')'])) then //not an invalid token char
            begin
              tokens[i+1]:=tokens[i]+tokens[i+1];
              tokens[i]:='';
            end;
          end;
        end;
      end;
    end;
  end;


  //do some calculations

  //check multiply first
  for i:=1 to length(tokens)-2 do
  begin
    if tokens[i]='*' then
    begin
      val('$'+tokens[i-1],a,err);
      val('$'+tokens[i+1],b,err2);
      if (err=0) and (err2=0) then
      begin
        a:=a*b;
        tokens[i-1]:=inttohex(a,8);
        tokens[i]:='';
        tokens[i+1]:='';
      end;
    end;
  end;

  for i:=1 to length(tokens)-2 do
  begin
    //get the value of the token before and after this token
    val('$'+tokens[i-1],a,err);
    val('$'+tokens[i+1],b,err2);
    //if no error, check if this token is a mathemetical value
    if (err=0) and (err2=0) then
    begin
      case tokens[i][1] of
        '+':
        begin
          a:=a+b;
          tokens[i-1]:=inttohex(a,8);
          tokens[i]:='';
          tokens[i+1]:='';
        end;

        '-':
        begin
          a:=a-b;
          tokens[i-1]:=inttohex(a,8);
          tokens[i]:='';
          tokens[i+1]:='';
        end;
      end;
    end
    else
    begin
      if (err2=0) and (tokens[i]<>'') and (tokens[i][1]='-') and (tokens[i-1]<>'#') then //before is not a valid value, but after it is. and this is a -  (so -value) (don't mess with #-10000)
      begin
        tokens[i]:='+';
        tokens[i+1]:=inttohex(-b,8);
      end;
    end;
  end;


  token:='';
  for i:=0 to length(tokens)-1 do
    token:=token+tokens[i];

  setlength(tokens,0);
  result:=true;
end;


function tokenize(opcode:string; var tokens: ttokens): boolean;
var i,j,last: integer;

    quoted: boolean;
    quotechar: char;

    t: string;
    ispartial: boolean;
begin
  quotechar:=#0;
  setlength(tokens,0);

  while (length(opcode)>0) and ((opcode[length(opcode)]=' ') or (opcode[length(opcode)]=',')) do
    opcode:=copy(opcode,1,length(opcode)-1);

  last:=1;
  quoted:=false;
  for i:=1 to length(opcode) do
  begin

    //check if this is a quote char
    if (opcode[i]='''') or (opcode[i]='"') then
    begin
      if quoted then //check if it's the end quote
      begin
        if opcode[i]=quotechar then
          quoted:=false;
      end
      else
      begin
        quoted:=true;
        quotechar:=opcode[i];
      end;
    end;

    //check if we encounter a token seperator. (space or , )
    //but only check when it's not inside a quoted string
    if (i=length(opcode)) or ((not quoted) and ((opcode[i]=' ') or (opcode[i]=',')))  then
    begin


      setlength(tokens,length(tokens)+1);
      if i=length(opcode) then
        j:=i-last+1
      else
        j:=i-last;

      tokens[length(tokens)-1]:=copy(opcode,last,j);


      if (j>0) and (tokens[length(tokens)-1][1]<>'$') and ((j<7) or (pos('KERNEL_',uppercase(tokens[length(tokens)-1]))=0)) then //only uppercase if it's not kernel_
      begin
        //don't uppercase empty strings, kernel_ strings or strings starting with $

        if length(tokens[length(tokens)-1])>2 then
        begin
          if not (tokens[length(tokens)-1][1] in ['''', '"']) then //if not a quoted string then make it uppercase
            tokens[length(tokens)-1]:=uppercase(tokens[length(tokens)-1]);
        end
        else
          tokens[length(tokens)-1]:=uppercase(tokens[length(tokens)-1]);
      end;


      //6.1: Optimized this lookup. Instead of a 18 compares a full string lookup on each token it now only compares up to 4 times
      t:=tokens[length(tokens)-1];


      isPartial:=false;
      if length(t)>=3 then //3 characters are good enough to get the general idea, then do a string compare to verify
      begin
        case t[1] of
          'B' : //Byte, BYTE PTR
          begin
            if (t[2]='Y') and (t[3]='T') then //could be BYTE
              isPartial:=(t='BYTE') or (t='BYTE PTR');

          end;

          'D': //DQWORD, DWORD, DQWORD PTR, DWORD PTR
          begin
            case t[2] of
              'Q' : //DQWORD or DQWORD PTR
              begin
                if t[3]='W' then
                  isPartial:=(t='DQWORD') or (t='DQWORD PTR');
              end;

              'W' : //DWORD or DWORD PTR
              begin
                if t[3]='O' then
                  isPartial:=(t='DWORD') or (t='DWORD PTR');
              end;
            end;
          end;

          'F' : //FAR
          begin
            if (t[2]='A') and (t[3]='R') then
              isPartial:=(t='FAR');
          end;

          'L' : //LONG
          begin
            if (t[2]='O') and (t[3]='N') then
              isPartial:=(t='LONG');
          end;

          'Q': //QWORD, QWORD PTR
          begin
            if (t[2]='W') and (t[3]='O') then //could be QWORD
              isPartial:=(t='QWORD') or (t='QWORD PTR');
          end;

          'S' : //SHORT
          begin
            if (t[2]='H') and (t[3]='O') then
              isPartial:=(t='SHORT');
          end;

          'T': //TBYTE, TWORD, TBYTE PTR, TWORD PTR,
          begin
            case t[2] of
              'B' : //TBYTE or TBYTE PTR
              begin
                if t[3]='Y' then
                  isPartial:=(t='TBYTE') or (t='TBYTE PTR');
              end;

              'W' : //TWORD or TWORD PTR
              begin
                if t[3]='O' then
                  isPartial:=(t='TWORD') or (t='TWORD PTR');
              end;
            end;

          end;

          'W' : //WORD, WORD PTR
          begin
            if (t[2]='O') and (t[3]='R') then //could be WORD
              isPartial:=(t='WORD') or (t='WORD PTR');
          end;

        end;
      end;

      if ispartial then
      begin
        setlength(tokens,length(tokens)-1)
      end
      else
      begin
        last:=i+1;

        if (length(tokens)>1) then
        begin
          //Rewrite
          rewrite(tokens[length(tokens)-1]);
        end;
      end;
    end;

  end;

  //remove useless tokens
  i:=0;
  while i<length(tokens) do
  begin
    if (tokens[i]='') or (tokens[i]=' ') or (tokens[i]=',') then
    begin
      for j:=i to length(tokens)-2 do
        tokens[j]:=tokens[j+1];
      setlength(tokens,length(tokens)-1);
      continue;
    end;
    inc(i);
  end;

  result:=true;
end;

procedure setsibscale(var sib: byte;i:byte);
begin
  //showmessage('sibscale: i='+inttostr(i));
  sib:=(sib and $3f) or (i shl 6);
end;

procedure TSingleLineAssembler.setsibindex(var sib: byte; i:byte);
begin
  sib:=(sib and $c7) or ((i and 7) shl 3);
  if i>7 then
    REX_X:=true;
end;

procedure TSingleLineAssembler.setsibbase(var sib:byte; i:byte);
begin
  sib:=(sib and $f8) or (i and 7);
  if i>7 then
    REX_B:=true;
end;


procedure TSingleLineAssembler.setrm(var modrm: byte;i: byte);
begin
  modrm:=(modrm and $f8) or (i and 7);
  if i>7 then
    REX_B:=true;
end;

procedure setmod(var modrm: byte;i: byte);
begin
  modrm:=(modrm and $3f) or (i shl 6);
end;

function getmod(modrm: byte):byte;
begin
  result:=modrm shr 6;
end;

procedure TSingleLineAssembler.createsibscaleindex(var sib:byte;reg:string);
var
  i: integer;
  hasmultiply: boolean;
begin
  hasmultiply:=false;

  for i:=1 to length(reg)-1 do
  begin

    if reg[i]='*' then
    begin
      hasmultiply:=true;
      case reg[i+1] of
        '1': setsibscale(sib, 0);
        '2': setsibscale(sib, 1); //*2
        '4': setsibscale(sib, 2); //*4
        '8': setsibscale(sib, 3); //*8
        else
          raise exception.create(rsInvalidMultiplier);

      end;

      if length(reg)>i+1 then
        raise exception.create(rsInvalidMultiplier);

      break;
    end;


  end;

  if not hasmultiply then
    setsibscale(sib, 0);

  if not processhandler.is64Bit then
  begin
    if pos('EAX',reg)>0 then setsibindex(sib,0) else
    if pos('ECX',reg)>0 then setsibindex(sib,1) else
    if pos('EDX',reg)>0 then setsibindex(sib,2) else
    if pos('EBX',reg)>0 then setsibindex(sib,3) else
    if ((reg='') or (pos('ESP',reg)>0)) then setsibindex(sib,4) else //if esp it is invalid, but if the user types it it'll compile
    if pos('EBP',reg)>0 then setsibindex(sib,5) else
    if pos('ESI',reg)>0 then setsibindex(sib,6) else
    if pos('EDI',reg)>0 then setsibindex(sib,7) else
      raise exception.Create(rsWTFIsA+reg);
  end
  else
  begin
    if pos('RAX',reg)>0 then setsibindex(sib,0) else
    if pos('RCX',reg)>0 then setsibindex(sib,1) else
    if pos('RDX',reg)>0 then setsibindex(sib,2) else
    if pos('RBX',reg)>0 then setsibindex(sib,3) else
    if ((reg='') or (pos('RSP',reg)>0)) then setsibindex(sib,4) else //if esp it is invalid, but if the user types it it'll compile
    if pos('RBP',reg)>0 then setsibindex(sib,5) else
    if pos('RSI',reg)>0 then setsibindex(sib,6) else
    if pos('RDI',reg)>0 then setsibindex(sib,7) else
    if pos('R8',reg)>0 then setsibindex(sib,8) else
    if pos('R9',reg)>0 then setsibindex(sib,9) else
    if pos('R10',reg)>0 then setsibindex(sib,10) else
    if pos('R11',reg)>0 then setsibindex(sib,11) else
    if pos('R12',reg)>0 then setsibindex(sib,12) else
    if pos('R13',reg)>0 then setsibindex(sib,13) else
    if pos('R14',reg)>0 then setsibindex(sib,14) else
    if pos('R15',reg)>0 then setsibindex(sib,15) else
    begin
      //in case addressswitch is needed
      if pos('EAX',reg)>0 then setsibindex(sib,0) else
      if pos('ECX',reg)>0 then setsibindex(sib,1) else
      if pos('EDX',reg)>0 then setsibindex(sib,2) else
      if pos('EBX',reg)>0 then setsibindex(sib,3) else
      if pos('ESP',reg)>0 then setsibindex(sib,4) else
      if pos('EBP',reg)>0 then setsibindex(sib,5) else
      if pos('ESI',reg)>0 then setsibindex(sib,6) else
      if pos('EDI',reg)>0 then setsibindex(sib,7) else
        raise exception.Create(rsWTFIsA+reg);

      //still here, so I guess so
      needsAddressSwitchPrefix:=true;
    end;

  end;
end;



procedure TSingleLineAssembler.setmodrm(var modrm:tassemblerbytes;address:string; offset: integer);
var regs: string;
    disp,test: qword;
    i,j,k: integer;
    start: integer;
    increase: boolean;

    go: boolean;
    splitup: array of string;
    temp:string;

    reg1,reg2: string;
    reg: array[-1..1] of string;
    found: boolean;
begin
  //first split the address string up
  setlength(splitup,0);
  found:=false;
  go:=false;
  start:=1;
  for i:=1 to length(address) do
  begin
    if i=length(address) then
    begin
      if not (address[i] in ['+','-']) then
      begin
        setlength(splitup,length(splitup)+1);
        splitup[length(splitup)-1]:=copy(address,start,(i+1)-start);
      end;
    end
    else
    if not (address[i] in ['+','-']) then go:=true
    else
    if address[i] in ['+','-'] then
    begin
      if go then
      begin
        setlength(splitup,length(splitup)+1);
        splitup[length(splitup)-1]:=copy(address,start,i-start);
        start:=i; //copy the + or - sign
        go:=false;
      end;
    end;
  end;

  disp:=0;
  regs:='';
  for i:=0 to length(splitup)-1 do
  begin
    increase:=true;
    for j:=1 to length(splitup[i]) do
      if (splitup[i][j] in ['+','-']) then
      begin
        if splitup[i][j]='-' then increase:=not increase;
      end else
      begin
        if j=length(splitup[i]) then
          temp:=copy(splitup[i],j,length(splitup[i])-j+1)
        else
          temp:=copy(splitup[i],j,length(splitup[i])-j+1);
        break;
      end;

    if length(temp)=0 then raise exception.Create(rsIDontUnderstandWhatYouMeanWith+address);
    if temp[1]='$' then val(temp,test,j) else val('$'+temp,test,j);

    if j>0 then //a register or a stupid user
    begin
      if increase=false then
        raise exception.create(rsNegativeRegistersCanNotBeEncoded);
      regs:=regs+temp+'+';
    end
    else
    begin  //a value
      if increase then inc(disp,test) else dec(disp,test);
    end;


  end;
  if length(regs)>0 then regs:=copy(regs,1,length(regs)-1);

  //regs and disp are now set
  //compare the regs with posibilities     (only 1 time +, and only 1 time *)
  j:=0; k:=0;

  for i:=1 to length(regs) do
  begin
    if regs[i]='+' then inc(j);
    if regs[i]='*' then inc(k);
  end;

  if (j>1) or (k>1) then raise exception.Create(rsIDontUnderstandWhatYouMeanWith+address);

  if disp=0 then setmod(modrm[0],0) else
  if (integer(disp)>=-128) and (integeR(disp)<=127) then setmod(modrm[0],1) else setmod(modrm[0],2);


  reg1:='';
  reg2:='';
  if pos('+',regs)>0 then
  begin
    reg1:=copy(regs,1,pos('+',regs)-1);
    reg2:=copy(regs,pos('+',regs)+1,length(regs));

    k:=2;
  end else
  begin
    reg1:=regs;
    k:=1;
  end;

  reg[-1]:=reg1;
  reg[1]:=reg2;

  k:=1;



  if (reg1<>'') and (reg2='') and (pos('*',reg1)>0) then
  begin
    setmod(modrm[0],0);
    setrm(modrm[0],4);
    setlength(modrm,2);
    setsibbase(modrm[1],5);
    createsibscaleindex(modrm[1],reg[-1]);
    adddword(modrm,disp);
    found:=true;

  end;

  if (reg[k]='') and (reg[-k]='') then
  begin
    //no registers, just a address
    setrm(modrm[0],5);
    setmod(modrm[0],0);

    if processhandler.is64Bit then
    begin
      if disp<=$7FFFFFFF then
      begin
        //this can be solved with an 0x25 SIB byte
        setlength(modrm,2);
        setrm(modrm[0],4);
        setsibbase(modrm[1],5); //no base
        setsibindex(modrm[1],4);
        setsibscale(modrm[1],0);
      end
      else
      begin
        actualdisplacement:=disp;
        relativeAddressLocation:=offset+1;
      end;
    end;

    adddword(modrm,disp);

    found:=true;
  end;

  try

    if (reg[k]='ESP') or (reg[-k]='ESP') or (reg[k]='RSP') or (reg[-k]='RSP') then //esp takes precedence
    begin
      if reg[-k]='ESP' then k:=-k;
      if reg[-k]='RSP' then k:=-k;

      setrm(modrm[0],4);
      setlength(modrm,2);
      setsibbase(modrm[1],4);
      createsibscaleindex(modrm[1],reg[-k]);
      found:=true;
      exit;
    end;

    if (reg[k]='EAX') or (reg[-k]='EAX') or (reg[k]='RAX') or (reg[-k]='RAX') then
    begin
      if reg[-k]='EAX' then k:=-k;
      if reg[-k]='RAX' then k:=-k;

      if (reg[-k]<>'') then //sib needed
      begin
        setrm(modrm[0],4);
        setlength(modrm,2);

        setsibbase(modrm[1],0);
        createsibscaleindex(modrm[1],reg[-k]);
      end else setrm(modrm[0],0); //no sib needed
      found:=true;
      exit;
    end;

    if (reg[k]='ECX') or (reg[-k]='ECX') or (reg[k]='RCX') or (reg[-k]='RCX') then
    begin
      if reg[-k]='ECX' then k:=-k;
      if reg[-k]='RCX' then k:=-k;

      if (reg[-k]<>'') then //sib needed
      begin
        setrm(modrm[0],4);
        setlength(modrm,2);
        setsibbase(modrm[1],1);
        createsibscaleindex(modrm[1],reg[-k]);
      end else setrm(modrm[0],1); //no sib needed
      found:=true;
      exit;
    end;

    if (reg[k]='EDX') or (reg[-k]='EDX') or (reg[k]='RDX') or (reg[-k]='RDX') then
    begin
      if reg[-k]='EDX' then k:=-k;
      if reg[-k]='RDX' then k:=-k;

      if (reg[-k]<>'') then //sib needed
      begin
        setrm(modrm[0],4);
        setlength(modrm,2);
        setsibbase(modrm[1],2);
        createsibscaleindex(modrm[1],reg[-k]);
      end else setrm(modrm[0],2); //no sib needed
      found:=true;
      exit;
    end;

    if (reg[k]='EBX') or (reg[-k]='EBX') or (reg[k]='RBX') or (reg[-k]='RBX') then
    begin
      if reg[-k]='EBX' then k:=-k;
      if reg[-k]='RBX' then k:=-k;

      if (reg[-k]<>'') then //sib needed
      begin
        setrm(modrm[0],4);
        setlength(modrm,2);
        setsibbase(modrm[1],3);
        createsibscaleindex(modrm[1],reg[-k]);
      end else setrm(modrm[0],3); //no sib needed
      found:=true;
      exit;
    end;


    if (reg[k]='ESP') or (reg[-k]='ESP') or (reg[k]='RSP') or (reg[-k]='RSP') then
    begin
      if reg[-k]='ESP' then k:=-k;
      if reg[-k]='RSP' then k:=-k;


      setrm(modrm[0],4);
      setlength(modrm,2);
      setsibbase(modrm[1],4);
      createsibscaleindex(modrm[1],reg[-k]);
      found:=true;
      exit;
    end;

    if (reg[k]='EBP') or (reg[-k]='EBP') or (reg[k]='RBP') or (reg[-k]='RBP') then
    begin
      if reg[-k]='EBP' then k:=-k;
      if reg[-k]='RBP' then k:=-k;

      if disp=0 then setmod(modrm[0],1);

      if (reg[-k]<>'') then //sib needed
      begin
        setrm(modrm[0],4);
        setlength(modrm,2);
        setsibbase(modrm[1],5);
        createsibscaleindex(modrm[1],reg[-k]);
      end else setrm(modrm[0],5); //no sib needed
      found:=true;
      exit;
    end;

    if (reg[k]='ESI') or (reg[-k]='ESI') or (reg[k]='RSI') or (reg[-k]='RSI') then
    begin
      if reg[-k]='ESI' then k:=-k;
      if reg[-k]='RSI' then k:=-k;

      if (reg[-k]<>'') then //sib needed
      begin
        setrm(modrm[0],4);
        setlength(modrm,2);
        setsibbase(modrm[1],6);
        createsibscaleindex(modrm[1],reg[-k]);
      end else setrm(modrm[0],6); //no sib needed
      found:=true;
      exit;
    end;

    if (reg[k]='EDI') or (reg[-k]='EDI') or (reg[k]='RDI') or (reg[-k]='RDI') then
    begin
      if reg[-k]='EDI' then k:=-k;
      if reg[-k]='RDI' then k:=-k;

      if (reg[-k]<>'') then //sib needed
      begin
        setrm(modrm[0],4);
        setlength(modrm,2);
        setsibbase(modrm[1],7);
        createsibscaleindex(modrm[1],reg[-k]);
      end else setrm(modrm[0],7); //no sib needed
      found:=true;
      exit;
    end;

    if processhandler.is64Bit then
    begin
      if (reg[k]='R8') or (reg[-k]='R8') then
      begin
        if reg[-k]='R8' then k:=-k;

        if (reg[-k]<>'') then //sib needed
        begin
          setrm(modrm[0],4);
          setlength(modrm,2);
          setsibbase(modrm[1],8);
          createsibscaleindex(modrm[1],reg[-k]);
        end else setrm(modrm[0],8); //no sib needed
        found:=true;
        exit;
      end;

      if (reg[k]='R9') or (reg[-k]='R9') then
      begin
        if reg[-k]='R9' then k:=-k;

        if (reg[-k]<>'') then //sib needed
        begin
          setrm(modrm[0],4);
          setlength(modrm,2);
          setsibbase(modrm[1],9);
          createsibscaleindex(modrm[1],reg[-k]);
        end else setrm(modrm[0],9); //no sib needed
        found:=true;
        exit;
      end;

      if (reg[k]='R10') or (reg[-k]='R10') then
      begin
        if reg[-k]='R10' then k:=-k;

        if (reg[-k]<>'') then //sib needed
        begin
          setrm(modrm[0],4);
          setlength(modrm,2);
          setsibbase(modrm[1],10);
          createsibscaleindex(modrm[1],reg[-k]);
        end else setrm(modrm[0],10); //no sib needed
        found:=true;
        exit;
      end;

      if (reg[k]='R11') or (reg[-k]='R11') then
      begin
        if reg[-k]='R11' then k:=-k;

        if (reg[-k]<>'') then //sib needed
        begin
          setrm(modrm[0],4);
          setlength(modrm,2);
          setsibbase(modrm[1],11);
          createsibscaleindex(modrm[1],reg[-k]);
        end else setrm(modrm[0],11); //no sib needed
        found:=true;
        exit;
      end;

      if (reg[k]='R12') or (reg[-k]='R12') then
      begin

        if reg[-k]='R12' then k:=-k;

        setrm(modrm[0],4);
        setlength(modrm,2);
        setsibbase(modrm[1],12);
        createsibscaleindex(modrm[1],reg[-k]);
        found:=true;
        exit;
      end;

      if (reg[k]='R13') or (reg[-k]='R13') then
      begin
        if reg[-k]='R13' then k:=-k;
        if disp=0 then setmod(modrm[0],1);


        if (reg[-k]<>'') then //sib needed
        begin
          setrm(modrm[0],4);
          setlength(modrm,2);
          setsibbase(modrm[1],13);
          createsibscaleindex(modrm[1],reg[-k]);
        end else setrm(modrm[0],13); //no sib needed
        found:=true;
        exit;
      end;

      if (reg[k]='R14') or (reg[-k]='R14') then
      begin
        if reg[-k]='R14' then k:=-k;

        if (reg[-k]<>'') then //sib needed
        begin
          setrm(modrm[0],4);
          setlength(modrm,2);
          setsibbase(modrm[1],14);
          createsibscaleindex(modrm[1],reg[-k]);
        end else setrm(modrm[0],14); //no sib needed
        found:=true;
        exit;
      end;

      if (reg[k]='R15') or (reg[-k]='R15') then
      begin
        if reg[-k]='R15' then k:=-k;

        if (reg[-k]<>'') then //sib needed
        begin
          setrm(modrm[0],4);
          setlength(modrm,2);
          setsibbase(modrm[1],15);
          createsibscaleindex(modrm[1],reg[-k]);
        end else setrm(modrm[0],15); //no sib needed
        found:=true;
        exit;
      end;

    end;


  finally
    if not found then raise exception.create(rsInvalidAddress);

    i:=getmod(modrm[0]);
    if i=1 then add(modrm,[byte(disp)]);
    if i=2 then adddword(modrm,disp);
  end;



 // hgihkjjkjj
end;

function TSingleLineAssembler.createModRM(var bytes: tassemblerbytes;reg:integer;param: string):boolean;
var address: string;
    modrm: tassemblerbytes;
    i,j: integer;
begin
  setlength(modrm,1);
  modrm[0]:=0;
  result:=false;

  address:=copy(param,pos('[',param)+1,pos(']',param)-pos('[',param)-1);
  if address='' then
  begin
    //register //modrm c0 to ff
    setmod(modrm[0],3);
    if (param='RAX') or (param='EAX') or (param='AX') or (param='AL') or (param='MM0') or (param='XMM0') then setrm(modrm[0],0) else
    if (param='RCX') or (param='ECX') or (param='CX') or (param='CL') or (param='MM1') or (param='XMM1') then setrm(modrm[0],1) else
    if (param='RDX') or (param='EDX') or (param='DX') or (param='DL') or (param='MM2') or (param='XMM2') then setrm(modrm[0],2) else
    if (param='RBX') or (param='EBX') or (param='BX') or (param='BL') or (param='MM3') or (param='XMM3') then setrm(modrm[0],3) else
    if (param='SPL') or (param='RSP') or (param='ESP') or (param='SP') or (param='AH') or (param='MM4') or (param='XMM4') then setrm(modrm[0],4) else
    if (param='BPL') or (param='RBP') or (param='EBP') or (param='BP') or (param='CH') or (param='MM5') or (param='XMM5') then setrm(modrm[0],5) else
    if (param='SIL') or (param='RSI') or (param='ESI') or (param='SI') or (param='DH') or (param='MM6') or (param='XMM6') then setrm(modrm[0],6) else
    if (param='DIL') or (param='RDI') or (param='EDI') or (param='DI') or (param='BH') or (param='MM7') or (param='XMM7') then setrm(modrm[0],7) else
    if (param='R8') or (param='R8D') or (param='R8W') or (param='R8L') or (param='MM8') or (param='XMM8') then setrm(modrm[0],8) else
    if (param='R9') or (param='R9D') or (param='R9W') or (param='R9L') or (param='MM9') or (param='XMM9') then setrm(modrm[0],9) else
    if (param='R10') or (param='R10D') or (param='R10W') or (param='R10L') or (param='MM10') or (param='XMM10') then setrm(modrm[0],10) else
    if (param='R11') or (param='R11D') or (param='R11W') or (param='R11L') or (param='MM11') or (param='XMM11') then setrm(modrm[0],11) else
    if (param='R12') or (param='R12D') or (param='R12W') or (param='R12L') or (param='MM12') or (param='XMM12') then setrm(modrm[0],12) else
    if (param='R13') or (param='R13D') or (param='R13W') or (param='R13L') or (param='MM13') or (param='XMM13') then setrm(modrm[0],13) else
    if (param='R14') or (param='R14D') or (param='R14W') or (param='R14L') or (param='MM14') or (param='XMM14') then setrm(modrm[0],14) else
    if (param='R15') or (param='R15D') or (param='R15W') or (param='R15L') or (param='MM15') or (param='XMM15') then setrm(modrm[0],15) else
    raise exception.Create(rsIDontUnderstandWhatYouMeanWith+param);
  end else setmodrm(modrm,address, length(bytes));

  //setreg
  if reg>7 then
  begin
    if processhandler.is64bit then
    begin
      REX_R:=true;
    end
    else
      raise exception.Create(rsTheAssemblerTriedToSetARegisteValueThatIsTooHigh);
  end;
  if reg=-1 then reg:=0;

  reg:=reg and 7;
  modrm[0]:=modrm[0]+(reg shl 3);

  j:=length(bytes);
  setlength(bytes,length(bytes)+length(modrm));
  for i:=0 to length(modrm)-1 do
    bytes[j+i]:=modrm[i];


  result:=true;
end;

procedure TSingleLineAssembler.addopcode(var bytes:tassemblerbytes;i:integer);
begin
  RexPrefixLocation:=length(bytes);

  if opcodes[i].bt1 in [$66, $f2, $f3] then
    inc(RexPrefixLocation); //mandatory prefixes come before the rex byte

  add(bytes,[opcodes[i].bt1]);
  if opcodes[i].bytes>1 then add(bytes,[opcodes[i].bt2]);
  if opcodes[i].bytes>2 then add(bytes,[opcodes[i].bt3]);
  if opcodes[i].bytes>3 then add(bytes,[opcodes[i].bt4]);
end;

function eoToReg(eo:TExtraOpcode):integer;
begin
  result:=-1;
  case eo of
    eo_reg0: result:=0;
    eo_reg1: result:=1;
    eo_reg2: result:=2;
    eo_reg3: result:=3;
    eo_reg4: result:=4;
    eo_reg5: result:=5;
    eo_reg6: result:=6;
    eo_reg7: result:=7;
  end;
end;

function TSingleLineAssembler.getRex_W: boolean;
begin
  result:=((rexprefix shr 3) and 1)=1;
end;

procedure TSingleLineAssembler.setRex_W(state: boolean);
{
Set bit 3 to the appropriate state
}
begin
  if state then
    rexprefix:=(rexprefix and $f7) or 8
  else
    rexprefix:=(rexprefix and $F7)
end;

function TSingleLineAssembler.getRex_R: boolean;
begin
  result:=((rexprefix shr 2) and 1)=1;
end;

procedure TSingleLineAssembler.setRex_R(state: boolean);
{
Set bit 2 to the appropriate state
}
begin
  if state then
    rexprefix:=(rexprefix and $fb) or 4
  else
    rexprefix:=(rexprefix and $Fb)

end;

function TSingleLineAssembler.getRex_X: boolean;
begin
  result:=((rexprefix shr 1) and 1)=1;
end;

procedure TSingleLineAssembler.setRex_X(state: boolean);
{
Set bit 2 to the appropriate state
}
begin
  if state then
    rexprefix:=(rexprefix and $fd) or 2
  else
    rexprefix:=(rexprefix and $Fd)

end;

function TSingleLineAssembler.getRex_B: boolean;
begin
  result:=(rexprefix and 1)=1;
end;

procedure TSingleLineAssembler.setRex_B(state: boolean);
{
Set bit 2 to the appropriate state
}
begin
  if state then
    rexprefix:=(rexprefix and $fe) or 1
  else
    rexprefix:=(rexprefix and $Fe)

end;



function Assemble(opcode:string; address: ptrUint;var bytes: TAssemblerBytes; assemblerPreference: TassemblerPreference=apNone; skiprangecheck: boolean=false): boolean;
begin
  result:=SingleLineAssembler.assemble(opcode, address, bytes, assemblerPreference, skiprangecheck);
end;

function TSingleLineAssembler.Assemble(opcode:string; address: ptrUint;var bytes: TAssemblerBytes;assemblerPreference: TassemblerPreference=apNone; skiprangecheck: boolean=false): boolean;
var tokens: ttokens;
    i,j,k,l: integer;
    v,v2: qword;
    mnemonic,nroftokens: integer;
    oldParamtype1, oldParamtype2: TTokenType;
    paramtype1,paramtype2,paramtype3: TTokenType;
    parameter1,parameter2,parameter3: string;
    vtype,v2type: integer;
    signedvtype,signedv2type: integer;

    startoflist,endoflist: integer;

    tempstring: string;
    overrideShort, overrideLong, overrideFar: boolean;

    is64bit: boolean;


    b: byte;
    br: PTRUINT;
    canDoAddressSwitch: boolean;

begin
  needsAddressSwitchPrefix:=false;


  setlength(bytes,0);
  is64bit:=processhandler.is64Bit;


  {$ifdef checkassembleralphabet}
  for i:=2 to opcodecount do
    if opcodes[i].mnemonic<opcodes[i-1].mnemonic then raise exception.Create('FUCK YOU! THE PROGRAMMER WAS STUPID ENOUGH TO MESS THIS PART UP IN PART '+IntToStr(i)+' '+opcodes[i-1].mnemonic+'<'+opcodes[i].mnemonic);
  {$endif}

  relativeAddressLocation:=-1;
  rexprefix:=0;
  result:=false;

  tokenize(opcode,tokens);

  nroftokens:=length(tokens);


  if nroftokens=0 then exit;

  if tokens[0][1]='A' then  //A* //allign
  begin
    if tokens[0]='ALIGN' then
    begin
      if nroftokens>=2 then
      begin
        i:=HexStrToInt(tokens[1]);

        if nroftokens>=3 then
          b:=HexStrToInt(tokens[2])
        else
          b:=0;

        k:=i-(address mod i);

        if k=i then exit(true);

        for i:=0 to k-1 do
          Add(bytes, b);

        result:=true;
        exit;
      end;
    end;
  end;

  if tokens[0][1]='D' then  //D*
  begin
    if tokens[0]='DB' then
    begin
      for i:=1 to nroftokens-1 do
      begin
        if tokens[i][1]='''' then //string
        begin
          //find the original non uppercase stringpos in the opcode
          j:=pos(tokens[i],uppercase(opcode));

          if j>0 then
          begin
            tempstring:=copy(opcode,j,length(tokens[i]));
            addstring(bytes,tempstring);
          end
          else addstring(bytes,tokens[i]); //lets try to save face...
        end
        else
        begin    //db 00 00 ?? ?? ?? ?? 00 00
          if ((length(tokens[i])>=1) and (tokens[i][1] in ['?','*'])) and
             ((length(tokens[i])<2) or ((length(tokens[i])=2) and (tokens[i][2]=tokens[i][1]))) then
          begin
            //wildcard
            v:=0;
            ReadProcessMemory(processhandle,pointer(address+i-1), @b, 1, br);
            add(bytes, b);
          end
          else
            add(bytes,[HexStrToInt(tokens[i])]);
        end;
      end;

      result:=true;
      exit;
    end;

    if tokens[0]='DW' then
    begin
      for i:=1 to nroftokens-1 do
        addword(bytes,HexStrToInt(tokens[i]));

      result:=true;
      exit;
    end;

    if tokens[0]='DD' then
    begin
      for i:=1 to nroftokens-1 do
        adddword(bytes,HexStrToInt(tokens[i]));

      result:=true;
      exit;
    end;

    if tokens[0]='DQ' then
    begin
      for i:=1 to nroftokens-1 do
        addqword(bytes,HexStrToInt64(tokens[i]));

      result:=true;
      exit;
    end;
  end;

  for i:=0 to length(ExtraAssemblers)-1 do
  begin
    if assigned(ExtraAssemblers[i]) then
      ExtraAssemblers[i](address, opcode, bytes);

    result:=length(bytes)>0;
    if result then exit;
  end;


  if processhandler.SystemArchitecture=archarm then
  begin
    //handle it by the arm assembler
   // for i:=0 to nroftokens do
   //   tempstring:=tempstring+tokens[i]+' ';   //seperators like "," are gone, but the armassembler doesn't really care about that  (only tokens matter)

    result:=ArmAssemble(address, opcode, bytes);
    exit;
  end;




  mnemonic:=-1;
  for i:=0 to length(tokens)-1 do
  begin
    if not ((tokens[i]='LOCK') or (tokens[i]='REP') or (tokens[i]='REPNE') or (tokens[i]='REPE')) then
    begin
      mnemonic:=i;
      break;
    end;
  end;

  if mnemonic=-1 then exit;

  setlength(bytes,mnemonic);
  for i:=0 to mnemonic-1 do
  begin
    if tokens[i]='REP' then bytes[i]:=$f3 else
    if tokens[i]='REPNE' then bytes[i]:=$f2 else
    if tokens[i]='REPE' then bytes[i]:=$f3 else
    if tokens[i]='LOCK' then bytes[i]:=$f0;
  end;


  //this is just to speed up the finding of the right opcode
  //I could have done a if mnemonic=... then ... else if mnemonic=... then ..., but that would be slow, VERY SLOW


  if (nroftokens-1)>=mnemonic+1 then parameter1:=tokens[mnemonic+1] else parameter1:='';
  if (nroftokens-1)>=mnemonic+2 then parameter2:=tokens[mnemonic+2] else parameter2:='';
  if (nroftokens-1)>=mnemonic+3 then parameter3:=tokens[mnemonic+3] else parameter3:='';

  overrideShort:=Pos('SHORT ',parameter1)>0;
  overrideLong:=(Pos('LONG ',parameter1)>0);
  if processhandler.is64Bit then
    overrideFar:=(Pos('FAR ',parameter1)>0)
  else
    overrideLong:=overrideLong or (Pos('FAR ',parameter1)>0);


  if not (overrideShort or overrideLong) and (assemblerPreference<>apNone) then //no override chooce by the user and not a normal preference
  begin
    if assemblerPreference=apLong then
      overrideLong:=true
    else if assemblerPreference=apShort then
      overrideShort:=true;
  end;


  paramtype1:=gettokentype(parameter1,parameter2);
  paramtype2:=gettokentype(parameter2,parameter1);
  paramtype3:=gettokentype(parameter3,'');

  if processhandler.is64Bit then
  begin
    if (paramtype1=ttRegister8BitWithPrefix) then
    begin
      RexPrefix:=RexPrefix or $40; //it at least has a prefix now
      paramtype1:=ttRegister8Bit;
    end;

    if (paramtype2=ttRegister8BitWithPrefix) then
    begin
      RexPrefix:=RexPrefix or $40; //it at least has a prefix now
      paramtype2:=ttRegister8Bit;
    end;

    if (paramtype1=ttRegister64Bit) then
    begin
      REX_W:=true;   //64-bit opperand
      paramtype1:=ttRegister32Bit; //we can use the normal 32-bit interpretation assembler code
    end;

    if (paramtype2=ttRegister64bit) then
    begin
      REX_W:=true;
      paramtype2:=ttRegister32bit;
      if paramtype1=ttMemoryLocation64 then paramtype1:=ttMemoryLocation32;
    end;

    if paramtype1=ttMemoryLocation64 then
    begin
      REX_W:=true;
      paramtype1:=ttMemoryLocation32;
    end;

    if paramtype2=ttMemoryLocation64 then
    begin
      REX_W:=true;
      paramtype2:=ttMemoryLocation32;
    end;
  end;



  if tokens[0][1]='R' then //R*
  begin
    if (length(tokens)=2) and (length(tokens[0])=4) and (copy(tokens[0],1,3)='RES') then //only 2 tokens, the first token is 4 chars and it starts with RES
    begin
      //RES* X

      case tokens[0][4] of
        'B' : i:=1; //1 byte long entries
        'W' : i:=2; //2 byte long entries
        'D' : i:=4; //4 byte long entries
        'Q' : i:=8; //8 byte long entries
        else raise exception.create(rsInvalid);
      end;

      i:=i*strtoint(tokens[1]);
      setlength(bytes, i);
      for j:=0 to i-1 do
        bytes[j]:=0; //init the bytes to 0 (actually it should be uninitialized, but really... (Use structs for that)

      result:=true;
      exit;
    end;
  end;

  if (paramtype1>=ttMemorylocation) and (paramtype1<=ttMemorylocation128) then
  begin
    if pos('ES:',parameter1)>0 then
    begin
      setlength(bytes,length(bytes)+1);
      bytes[length(bytes)-1]:=$26;
    end;

    if pos('CS:',parameter1)>0 then
    begin
      setlength(bytes,length(bytes)+1);
      bytes[length(bytes)-1]:=$2e;
    end;

    if pos('SS:',parameter1)>0 then
    begin
      setlength(bytes,length(bytes)+1);
      bytes[length(bytes)-1]:=$36;
    end;

{
    if pos('DS:',parameter1)>0 then
    begin
      //don't set it, unless bp in 16 bit addressing mode is used (0x67 prefix)
      //which is a notation ce does NOT support and will never support, so, bye bye
      //setlength(bytes,length(bytes)+1);
      //bytes[length(bytes)-1]:=$3e;
    end;
    }

    if pos('FS:',parameter1)>0 then
    begin
      setlength(bytes,length(bytes)+1);
      bytes[length(bytes)-1]:=$64;
    end;

    if pos('GS:',parameter1)>0 then
    begin
      setlength(bytes,length(bytes)+1);
      bytes[length(bytes)-1]:=$65;
    end;
  end;

  if (paramtype2>=ttMemorylocation) and (paramtype2<=ttMemorylocation128) then
  begin
    if pos('ES:',parameter2)>0 then
    begin
      setlength(bytes,length(bytes)+1);
      bytes[length(bytes)-1]:=$26;
    end;

    if pos('CS:',parameter2)>0 then
    begin
      setlength(bytes,length(bytes)+1);
      bytes[length(bytes)-1]:=$2e;
    end;

    if pos('SS:',parameter2)>0 then
    begin
      setlength(bytes,length(bytes)+1);
      bytes[length(bytes)-1]:=$36;
    end;

    {
    if pos('DS:',parameter2)>0 then
    begin
      setlength(bytes,length(bytes)+1);
      bytes[length(bytes)-1]:=$3e;
    end;
    }

    if pos('FS:',parameter2)>0 then
    begin
      setlength(bytes,length(bytes)+1);
      bytes[length(bytes)-1]:=$64;
    end;

    if pos('GS:',parameter2)>0 then
    begin
      setlength(bytes,length(bytes)+1);
      bytes[length(bytes)-1]:=$65;
    end;
  end;


  v:=0;
  v2:=0;
  vtype:=0;
  v2type:=0;

  if paramtype1=ttValue then
  begin
    v:=StrToQWordEx(parameter1);
    vtype:=StringValueToType(parameter1);
  end;

  if paramtype2=ttValue then
  begin
    if paramtype1<>ttValue then
    begin
      v:=StrToQWordEx(parameter2);
      vtype:=StringValueToType(parameter2);
    end
    else
    begin
      //first v field is already in use, use v2
      v2:=StrToQWordEx(parameter2);
      v2type:=StringValueToType(parameter2);
    end;
  end;

  if paramtype3=ttValue then
  begin
    if paramtype1<>ttvalue then
    begin
      v:=StrToQWordEx(parameter3);
      vtype:=StringValueToType(parameter3);
    end
    else
    begin
      //first v field is already in use, use v2
      v2:=StrToQWordEx(parameter3);
      v2type:=StringValueToType(parameter3);
    end;
  end;

  signedvtype:=SignedValueToType(v);
  signedv2type:=SignedValueToType(v2);


  result:=false;

  //to make it easier for people that don't like the relative addressing limit
  if (not overrideShort) and (not overrideLong) and (processhandler.is64Bit) then   //if 64-bit and no override is given
  begin
    //check if this is a jmp or call with relative value
    if (tokens[mnemonic]='JMP') or (tokens[mnemonic]='CALL') then
    begin
      if paramtype1=ttValue then
      begin
        //if the relative distance is too big, then replace with with jmp/call [2], jmp+8, DQ address
        if address>v then
          v2:=address-v
        else
          v2:=v-address;


        if (v2>$7fffffff) or (overrideFar) then //the user WANTS it to be called as a 'far' jump even if it's not needed
        begin
          //restart
          setlength(bytes,0);
          rexprefix:=0;

          add(bytes,[$ff]);
          if (tokens[mnemonic]='JMP') then
          begin
            add(bytes,[$25]);
            AddDword(bytes, 0);
          end
          else
          begin
            add(bytes,[$15]); //call
            AddDword(bytes, 2);
            Add(bytes, [$eb, $08]);
          end;

          AddQword(bytes,v);
          result:=true;
          exit;
        end;
      end;

    end;
  end;


  j:=GetOpcodesIndex(tokens[mnemonic]); //index scan, better than sorted
  if j=-1 then exit;

  startoflist:=j;
  endoflist:=startoflist;

  while (endoflist<=opcodecount) and (opcodes[endoflist].mnemonic=tokens[mnemonic]) do inc(endoflist);
  dec(endoflist);


  try

  while j<=opcodecount do
  begin
    if opcodes[j].mnemonic<>tokens[mnemonic] then exit;

    if (opcodes[j].invalidin32bit and (not is64bit)) or (opcodes[j].invalidin64bit and (is64bit)) then
    begin
      inc(j);
      continue;
    end;

    oldParamtype1:=paramtype1;
    oldParamtype2:=paramtype2;

    if (opcodes[j].norexw) then
    begin
      //undo rex_w change
      if paramtype1=ttMemoryLocation32 then
        paramtype1:=gettokentype(parameter1,parameter2);

      if paramtype2=ttMemoryLocation32 then
        paramtype2:=gettokentype(parameter2,parameter3);
    end;


    canDoAddressSwitch:=opcodes[j].canDoAddressSwitch;


    case opcodes[j].paramtype1 of
      par_noparam: if (parameter1='') then     //no param
      begin
        //no param
        if (opcodes[j].paramtype2=par_noparam) and (parameter2='') then
        begin
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            //no_param,no_param,no_param

            if (opcodes[j].opcode1=eo_none) and (opcodes[j].opcode1=eo_none) then
            begin
              //eo_none,eo_none--no_param,no_param,no_param
              addopcode(bytes,j);
              result:=true;
              exit;
            end;
          end;
        end;
      end;

      par_imm8: if (paramtype1=ttValue) then
      begin
        //imm8,
        if (opcodes[j].paramtype2=par_al) and (parameter2='AL') then
        begin
          //imm8,al
          addopcode(bytes,j);
          add(bytes,[v]);
          result:=true;
          exit;
        end;

        if (opcodes[j].paramtype2=par_ax) and (parameter2='AX') then
        begin
          //imm8,ax /?
          addopcode(bytes,j);
          add(bytes,[v]);
          result:=true;
          exit;
        end;

        if (opcodes[j].paramtype2=par_eax) and ((parameter2='EAX') or (parameter2='RAX')) then
        begin
          //imm8,eax
          addopcode(bytes,j);
          add(bytes,[v]);
          result:=true;
          exit;
        end;



        if (opcodes[j].paramtype2=par_noparam) and (parameter2='') then
        begin
          if vtype=16 then
          begin
            //see if there is also a 'opcode imm16' variant
            k:=startoflist;
            while (k<=opcodecount) and (opcodes[k].mnemonic=tokens[mnemonic]) do
            begin
              if (opcodes[k].paramtype1=par_imm16) then
              begin
                addopcode(bytes,k);
                addword(bytes,v);
                result:=true;
                exit;
              end;

              inc(k);
            end;
          end;



          if (vtype=32) or (signedvtype>8) then
          begin
            //see if there is also a 'opcode imm32' variant
            k:=startoflist;
            while (k<=opcodecount) and (opcodes[k].mnemonic=tokens[mnemonic]) do
            begin
              if (opcodes[k].paramtype1=par_imm32) then
              begin
                addopcode(bytes,k);
                adddword(bytes,v);
                result:=true;
                exit;
              end;

              inc(k);
            end;
          end;


          //op imm8
          addopcode(bytes,j);
          add(bytes,[byte(v)]);
          result:=true;
          exit;
        end;
      end;

      par_imm16: if (paramtype1=ttValue) then
      begin
        //imm16,
        if (opcodes[j].paramtype2=par_noparam) and (parameter2='') then
        begin
          //imm16

          if (vtype=32) or (signedvtype>8) then
          begin
            //see if there is also a 'opcode imm32' variant
            k:=startoflist;
            while (k<=opcodecount) and (opcodes[k].mnemonic=tokens[mnemonic]) do
            begin
              if (opcodes[k].paramtype1=par_imm32) then
              begin
                addopcode(bytes,k);
                adddword(bytes,v);
                result:=true;
                exit;
              end;

              inc(k);
            end;
          end;

          addopcode(bytes,j);
          addword(bytes,v);
          result:=true;
          exit;
        end;


        if (opcodes[j].paramtype2=par_imm8) and (paramtype2=ttValue) then
        begin
          //imm16,imm8,
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            addopcode(bytes,j);
            addword(bytes,v);
            add(bytes,[v2]);
            result:=true;
            exit;
          end;
        end;
      end;

      par_imm32: if (paramtype1=ttValue) then
      begin
        if (opcodes[j].paramtype2=par_noparam) and (parameter2='') then
        begin
          //imm32
          addopcode(bytes,j);
          addDword(bytes,v);
          result:=true;
          exit;
        end;
      end;

      par_moffs8: if ((paramtype1=ttMemorylocation8) or (ismemorylocationdefault(parameter1)  )) then
      begin
        if (opcodes[j].paramtype2=par_al) and (parameter2='AL') then
        begin
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            k:=pos('[',parameter1);
            l:=pos(']',parameter1);
            val('$'+copy(parameter1,k+1,l-k-1),v,k);
            if k=0 then
            begin
              //verified, it doesn't have a registerbase in it
              addopcode(bytes,j);

              if processhandler.is64Bit then
                addQword(bytes,v)
              else
                addDword(bytes,v);

              result:=true;
              exit;
            end;
          end;
        end;
      end;

      par_moffs16: if ((paramtype1=ttMemorylocation16) or (ismemorylocationdefault(parameter1)  )) then
      begin
        if (opcodes[j].paramtype2=par_ax) and (parameter2='AX') then
        begin
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            k:=pos('[',parameter1);
            l:=pos(']',parameter1);
            val('$'+copy(parameter1,k+1,l-k-1),v,k);
            if k=0 then
            begin
              //verified, it doesn't have a registerbase in it
              addopcode(bytes,j);
              if processhandler.is64Bit then
                addqword(bytes,v)
              else
                adddword(bytes,v);

              result:=true;
              exit;
            end;
          end;
        end;
      end;

      par_moffs32: if (paramtype1=ttMemorylocation32) then
      begin
        if (opcodes[j].paramtype2=par_eax) and ((parameter2='EAX') or (parameter2='RAX')) then
        begin
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            k:=pos('[',parameter1);
            l:=pos(']',parameter1);
            val('$'+copy(parameter1,k+1,l-k-1),v,k);
            if k=0 then
            begin
              //verified, it doesn't have a registerbase in it
              addopcode(bytes,j);
              if processhandler.is64Bit then
                addqword(bytes,v)
              else
                adddword(bytes,v);

              result:=true;
              exit;
            end;
          end;
        end;
      end;

      par_3: if (paramtype1=ttValue) and (v=3) then
      begin
        //int 3
        addopcode(bytes,j);
        result:=true;
        exit;
      end;

      PAR_AL: if (parameter1='AL') then
      begin
        //AL,

        if (opcodes[j].paramtype2=par_dx) and (parameter2='DX') then
        begin
          //opcode al,dx
          addopcode(bytes,j);
          result:=true;
          exit;
        end;

        if (opcodes[j].paramtype2=par_imm8) and (paramtype2=ttValue) then
        begin
          //AL,imm8
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            if (opcodes[j].opcode1=eo_ib) and (opcodes[j].opcode2=eo_none) then
            begin
              //verified: AL,imm8
              addopcode(bytes,j);
              add(bytes,[byte(v)]);
              result:=true;
              exit;
            end;
          end;

        end;

        if (opcodes[j].paramtype2=par_moffs8) and ((paramtype2=ttMemorylocation8) or (ismemorylocationdefault(parameter2)  ))  then
        begin
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            k:=pos('[',parameter2);
            l:=pos(']',parameter2);
            val('$'+copy(parameter2,k+1,l-k-1),v,k);
            if k=0 then
            begin
              //verified, it doesn't have a registerbase in it
              addopcode(bytes,j);
              if processhandler.is64Bit then
                addqword(bytes,v)
              else
                adddword(bytes,v);

              result:=true;
              exit;
            end;


          end;
        end;
      end;

      PAR_AX: if (parameter1='AX') then
      begin
        //AX,
        if (opcodes[j].paramtype2=par_noparam) and (parameter2='') then
        begin
          //opcode AX
          addopcode(bytes,j);
          result:=true;
          exit;
        end;

        if (opcodes[j].paramtype2=par_dx) and (parameter2='DX') then
        begin
          //opcode ax,dx
          addopcode(bytes,j);
          result:=true;
          exit;
        end;

        //r16
        if (opcodes[j].paramtype2=par_r16) and (paramtype2=ttRegister16bit) then
        begin
          //eax,r32
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            //r32,eax
            if opcodes[j].opcode1=eo_prw then
            begin
              //opcode+rd
              addopcode(bytes,j);
              inc(bytes[length(bytes)-1],getreg(parameter2));
              result:=true;
              exit;
            end;
          end;
        end;


        if (opcodes[j].paramtype2=par_imm16) and (paramtype2=ttValue) then
        begin
          //AX,imm16
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            //params confirmed it is a ax,imm16
            if (opcodes[j].opcode1=eo_iw) and (opcodes[j].opcode2=eo_none) then
            begin
              addopcode(bytes,j);
              addword(bytes,word(v));
              result:=true;
              exit;
            end;
          end;
        end;

        if (opcodes[j].paramtype2=par_moffs16) and ((paramtype2=ttMemorylocation16) or (ismemorylocationdefault(parameter2)  ))  then
        begin
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            k:=pos('[',parameter2);
            l:=pos(']',parameter2);
            val('$'+copy(parameter2,k+1,l-k-1),v,k);
            if k=0 then
            begin
              //verified, it doesn't have a registerbase in it
              addopcode(bytes,j);
              if processhandler.is64bit then
                addqword(bytes,v)
              else
                adddword(bytes,v);

              result:=true;
              exit;
            end;
          end;
        end;

      end;

      PAR_EAX: if ((parameter1='EAX') or (parameter1='RAX')) then
      begin
        //eAX,
        if (opcodes[j].paramtype2=par_dx) and (parameter2='DX') then
        begin
          //opcode eax,dx
          addopcode(bytes,j);
          result:=true;
          exit;
        end;

        //r32
        if (opcodes[j].paramtype2=par_r32) and (paramtype2=ttRegister32bit) then
        begin
          //eax,r32
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            //r32,eax
            if opcodes[j].opcode1=eo_prd then
            begin
              //opcode+rd
              addopcode(bytes,j);
              k:=getreg(parameter2);
              if k>7 then
              begin
                rex_b:=true; //extention to the opcode field
                k:=k and 7;
              end;

              inc(bytes[length(bytes)-1],k);
              result:=true;
              exit;
            end;
          end;
        end;

        if (opcodes[j].paramtype2=par_imm8) and (paramtype2=ttValue) then
        begin
          //eax,imm8

          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            addopcode(bytes,j);
            add(bytes,[v]);
            result:=true;
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_imm32) and (paramtype2=ttValue) then
        begin
          //EAX,imm32,

          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            //eax,imm32

            if signedvtype=8 then
            begin
              //check if there isn't a rm32,imm8 , since that's less bytes
              k:=startoflist;
              while (k<=opcodecount) and (opcodes[k].mnemonic=tokens[mnemonic]) do
              begin
                if (opcodes[k].paramtype1=par_rm32) and
                   (opcodes[k].paramtype2=par_imm8) then
                begin
                  //yes, there is
                  addopcode(bytes,k);
                  result:=createmodrm(bytes,eotoreg(opcodes[k].opcode1),parameter1);
                  add(bytes,[v]);
                  exit;
                end;
                inc(k);
              end;
            end;

            if (opcodes[j].opcode1=eo_id) and (opcodes[j].opcode2=eo_none) then
            begin
              addopcode(bytes,j);
              adddword(bytes,v);
              result:=true;
              exit;
            end;
          end;
        end;

        if (opcodes[j].paramtype2=par_moffs32) and ((paramtype2=ttMemorylocation32) or (ismemorylocationdefault(parameter2)  ))  then
        begin
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            k:=pos('[',parameter2);
            l:=pos(']',parameter2);
            val('$'+copy(parameter2,k+1,l-k-1),v,k);
            if k=0 then
            begin
              //verified, it doesn't have a registerbase in it
              addopcode(bytes,j);

              if processhandler.is64Bit then
                addqword(bytes,v)
              else
                adddword(bytes,v);

              result:=true;
              exit;
            end;
          end;
        end;

      end;


      par_dx: if (parameter1='DX') then
      begin
        if (opcodes[j].paramtype2=par_al) and (parameter2='AL') then
        begin
          addopcode(bytes,j);
          result:=true;
          exit;
        end;

        if (opcodes[j].paramtype2=par_ax) and (parameter2='AX') then
        begin
          addopcode(bytes,j);
          result:=true;
          exit;
        end;

        if (opcodes[j].paramtype2=par_eax) and ((parameter2='EAX') or (parameter2='RAX')) then
        begin
          addopcode(bytes,j);
          result:=true;
          exit;
        end;
      end;

      par_cs: if (parameter1='CS') then
      begin
        if (opcodes[j].paramtype2=par_noparam) and (parameter2='') then
        begin
          addopcode(bytes,j);
          result:=true;
          exit;
        end;
      end;

      par_ds: if (parameter1='DS') then
      begin
        if (opcodes[j].paramtype2=par_noparam) and (parameter2='') then
        begin
          addopcode(bytes,j);
          result:=true;
          exit;
        end;
      end;

      par_es: if (parameter1='ES') then
      begin
        if (opcodes[j].paramtype2=par_noparam) and (parameter2='') then
        begin
          addopcode(bytes,j);
          result:=true;
          exit;
        end;
      end;

      par_ss: if (parameter1='SS') then
      begin
        if (opcodes[j].paramtype2=par_noparam) and (parameter2='') then
        begin
          addopcode(bytes,j);
          result:=true;
          exit;
        end;
      end;

      par_fs: if (parameter1='FS') then
      begin
        if (opcodes[j].paramtype2=par_noparam) and (parameter2='') then
        begin
          addopcode(bytes,j);
          result:=true;
          exit;
        end;
      end;

      par_gs: if (parameter1='GS') then
      begin
        if (opcodes[j].paramtype2=par_noparam) and (parameter2='') then
        begin
          addopcode(bytes,j);
          result:=true;
          exit;
        end;
      end;

      par_r8: if (paramtype1=ttRegister8bit) then
      begin
        if (opcodes[j].paramtype2=par_noparam) and (parameter2='') then
        begin
          //opcode r8
          if opcodes[j].opcode1=eo_prb then
          begin
            //opcode+rd
            addopcode(bytes,j);
            k:=getreg(parameter1);
            if k>7 then
            begin
              REX_B:=true;
              k:=k and 7;
            end;
            inc(bytes[length(bytes)-1],k);
            result:=true;
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_imm8) and (paramtype2=ttValue) then
        begin
          //r8, imm8
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            if opcodes[j].opcode1=eo_prb then
            begin
              addopcode(bytes,j);
              k:=getreg(parameter1);
              if k>7 then
              begin
                rex_b:=true; //extension to the opcode
                k:=k and 7;
              end;
              inc(bytes[length(bytes)-1],k);
              add(bytes,[v]);
              result:=true;
              exit;
            end;
          end;
        end;

        if (opcodes[j].paramtype2=par_rm8) and (isrm8(paramtype2)) then
        begin
          //r8,rm8
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter1),parameter2);
            exit;
          end;
        end;
      end;

      par_r16: if (paramtype1=ttRegister16bit) then
      begin
        if (opcodes[j].paramtype2=par_noparam) and (parameter2='') then
        begin
          //opcode r16
          if opcodes[j].opcode1=eo_prw then
          begin
            //opcode+rw
            addopcode(bytes,j);
            k:=getreg(parameter1);
            if k>7 then
            begin
              rex_b:=true;
              k:=k and 7;
            end;
            inc(bytes[length(bytes)-1],k);
            result:=true;
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_ax) and (parameter2='AX') then
        begin
          //r16,ax,
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            //r16,ax
            if opcodes[j].opcode1=eo_prw then
            begin
              //opcode+rd
              addopcode(bytes,j);
              k:=getreg(parameter1);
              if k>7 then
              begin
                rex_b:=true;
                k:=k and 7;
              end;
              inc(bytes[length(bytes)-1],k);
              result:=true;
              exit;
            end;
          end;
        end;


        if (opcodes[j].paramtype2=par_imm8) and (paramtype2=ttValue) then
        begin
          //r16, imm8
          if (opcodes[j].opcode1=eo_reg) and (opcodes[j].opcode2=eo_ib) then
          begin
            if vtype>8 then
            begin
              //search for r16/imm16
              k:=startoflist;
              while (k<=opcodecount) and (opcodes[k].mnemonic=tokens[mnemonic]) do
              begin
                if (opcodes[k].paramtype1=par_r16) and
                   (opcodes[k].paramtype2=par_imm16) then
                begin
                  if (opcodes[k].opcode1=eo_reg) and (opcodes[j].opcode2=eo_ib) then
                  begin
                    addopcode(bytes,k);
                    result:=createmodrm(bytes,getreg(parameter1),parameter1);
                    addword(bytes,v);
                    exit;
                  end;
                end;
                inc(k);
              end;

            end;


            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter1),parameter2);
            add(bytes,[v]);
          end;
        end;

        if (opcodes[j].paramtype2=par_imm16) and (paramtype2=ttValue) then
        begin
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            if opcodes[j].opcode1=eo_prw then
            begin
              addopcode(bytes,j);
              k:=getreg(parameter1);
              if k>7 then
              begin
                rex_b:=true;
                k:=k and 7;
              end;

              inc(bytes[length(bytes)-1],k);
              addword(bytes,v);
              result:=true;
              exit;
            end;
          end;
        end;

        if (opcodes[j].paramtype2=par_rm8) and (isrm8(paramtype2)) then
        begin
          //r16,r/m8 (eg: movzx)
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter1),parameter2);
            exit;
          end;

        end;

        if (opcodes[j].paramtype2=par_rm16) and (isrm16(paramtype2)) then
        begin
          //r16,r/m16
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter1),parameter2);
            exit;
          end;

          if (opcodes[j].paramtype3=par_imm8) and (paramtype3=ttValue) then
          begin
            if (opcodes[j].opcode2=eo_ib) then
            begin
              //r16,r/m16,imm8
              if vtype>8 then
              begin
                //see if there is a //r16,r/m16,imm16
                k:=startoflist;
                while (k<=opcodecount) and (opcodes[k].mnemonic=tokens[mnemonic]) do
                begin
                  if (opcodes[k].paramtype1=par_r16) and
                     (opcodes[k].paramtype2=par_rm16) and
                     (opcodes[k].paramtype3=par_imm16) then
                  begin
                    addopcode(bytes,k);
                    result:=createmodrm(bytes,getreg(parameter1),parameter2);
                    addword(bytes,v);
                    exit;
                  end;
                  inc(k);
                end;
              end;

              addopcode(bytes,j);
              result:=createmodrm(bytes,getreg(parameter1),parameter2);
              add(bytes,[v]);
              exit;
            end;
          end;
        end;
      end;

      par_r32: if (paramtype1=ttRegister32bit) then
      begin
        if (opcodes[j].paramtype2=par_noparam) and (parameter2='') then
        begin
          //opcode r32
          if opcodes[j].opcode1=eo_prd then
          begin
            //opcode+rd
            addopcode(bytes,j);
            k:=getreg(parameter1);
            if k>7 then
            begin
              rex_b:=true;
              k:=k and 7;
            end;
            inc(bytes[length(bytes)-1],k);
            result:=true;
            exit;
          end
          else
          begin
            //reg0..reg7
            addopcode(bytes,j);
            result:=createmodrm(bytes,eotoreg(opcodes[j].opcode1),parameter1);
            exit;
          end;
        end;




        //eax
        if (opcodes[j].paramtype2=par_eax) and ((parameter2='EAX') or (parameter2='RAX')) then
        begin
          //r32,eax,
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            //r32,eax
            if opcodes[j].opcode1=eo_prd then
            begin
              //opcode+rd
              addopcode(bytes,j);
              k:=getreg(parameter1);
              if k>7 then
              begin
                rex_b:=true;
                k:=k and 7;
              end;
              inc(bytes[length(bytes)-1],k);
              result:=true;
              exit;
            end;
          end;
        end;


        if (opcodes[j].paramtype2=par_mm) and (paramtype2=ttRegistermm) then
        begin
          //r32, mm,
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter1),parameter2);
            exit;
          end;

          if (opcodes[j].paramtype3=par_imm8) and (paramtype3=ttValue) then
          begin
            //r32, mm,imm8
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter1),parameter2);
            add(bytes,[v]);
            exit;
          end;

        end;


        if (opcodes[j].paramtype2=par_xmm) and (paramtype2=ttRegisterxmm) then
        begin
          //r32,xmm,
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter2),parameter1);
            exit;
          end;

          if (opcodes[j].paramtype3=par_imm8) and (paramtype3=ttValue) then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter2),parameter1);
            add(bytes,[v]);
            exit;
          end;

        end;

        if (opcodes[j].paramtype2=par_cr) and (paramtype2=ttRegistercr) then
        begin
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter2),parameter1);
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_dr) and (paramtype2=ttRegisterdr) then
        begin
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter2),parameter1);
            exit;
          end;
        end;


        if (opcodes[j].paramtype2=par_xmm_m32) and (isxmm_m32(paramtype2)) then
        begin
          //r32,xmm/m32
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter1),parameter2);
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_mm_m64) and (ismm_m64(paramtype2) or ((paramtype2=ttMemorylocation32) and (parameter2[1]='['))) then
        begin
          //r32,mm/m64
          addopcode(bytes,j);
          result:=createmodrm(bytes,getreg(parameter1),parameter2);
          exit;
        end;

        if (opcodes[j].paramtype2=par_xmm_m64) and (isxmm_m64(paramtype2) or ((paramtype2=ttMemorylocation32) and (parameter2[1]='['))) then
        begin
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter1),parameter2);
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_xmm_m128) and (isxmm_m64(paramtype2) or ((paramtype2=ttMemorylocation32) and (parameter2[1]='['))) then
        begin
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter1),parameter2);
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_m32) and (paramtype2=ttMemorylocation32) then
        begin
          //r32,m32,
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            //r32,m32
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter1),parameter2);
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_rm8) and (isrm8(paramtype2) or (ismemorylocationdefault(parameter2))) then
        begin
          //r32,rm8
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter1),parameter2);
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_rm16) and (isrm16(paramtype2) or (ismemorylocationdefault(parameter2))) then
        begin
          //r32,rm16
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter1),parameter2);
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_rm32) and (isrm32(paramtype2)) then
        begin
          //r32,r/m32
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter1),parameter2);
            exit;
          end;

          if (opcodes[j].paramtype3=par_imm8) and (paramtype3=ttValue) then
          begin
            if (opcodes[j].opcode2=eo_ib) then
            begin
              if vtype>8 then
              begin
                k:=startoflist;
                while (k<=endoflist) and (opcodes[k].mnemonic=tokens[mnemonic]) do
                begin
                  if (opcodes[k].paramtype1=par_r32) and
                     (opcodes[k].paramtype2=par_rm32) and
                     (opcodes[k].paramtype3=par_imm32) then
                  begin
                    addopcode(bytes,k);
                    result:=createmodrm(bytes,getreg(parameter1),parameter2);
                    adddword(bytes,v);
                    exit;
                  end;
                  inc(k);
                end;
              end;


              //r32,r/m32,imm8
              addopcode(bytes,j);
              result:=createmodrm(bytes,getreg(parameter1),parameter2);
              add(bytes,[v]);
              exit;
            end;
          end;

        end;


        if (opcodes[j].paramtype2=par_imm32) and (paramtype2=ttValue) then
        begin
          //r32,imm32
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            if opcodes[j].opcode1=eo_prd then
            begin
              addopcode(bytes,j);
              k:=getreg(parameter1);
              if k>7 then
              begin
                rex_b:=true;
                k:=k and 7;
              end;

              inc(bytes[length(bytes)-1],k);
              if self.REX_W then
                addqword(bytes,v)
              else
                adddword(bytes,v);
              result:=true;
              exit;
            end;

            if opcodes[j].opcode1=eo_reg then  //probably imul reg,imm32
            begin
              if signedvtype=8 then
              begin
                k:=startoflist;
                while (k<=endoflist) and (opcodes[k].mnemonic=tokens[mnemonic]) do //check for an reg,imm8
                begin
                  if (opcodes[k].paramtype1=par_r32) and
                     (opcodes[k].paramtype2=par_imm8) then
                  begin
                    addopcode(bytes,k);
                    createmodrm(bytes,getreg(parameter1),parameter1);
                    add(bytes,[byte(v)]);
                    result:=true;
                    exit;
                  end;
                  inc(k);
                end;
              end;

              addopcode(bytes,j);
              createmodrm(bytes,getreg(parameter1),parameter1);
              AddDword(bytes,v);
              result:=true;
              exit;
            end;
          end;
        end;


        if (opcodes[j].paramtype2=par_imm8) and (paramtype2=ttValue) then
        begin
          //r32, imm8

            if opcodes[j].opcode1=eo_prd then
            begin
              addopcode(bytes,j);
              createmodrm(bytes,eotoreg(opcodes[j].opcode1),parameter1);
              add(bytes,[byte(v)]);
              result:=true;
              exit;
            end;

            if opcodes[j].opcode1=eo_reg then  //probably imul r32,imm8
            begin
              addopcode(bytes,j);
              createmodrm(bytes,getreg(parameter1),parameter1);
              add(bytes,[byte(v)]);
              result:=true;
              exit;
            end;

        end;

      end;

      par_sreg: if (paramtype1=ttRegistersreg) then
      begin
        if (opcodes[j].paramtype2=par_rm16) and (isrm16(paramtype2)) then
        begin
          //sreg,rm16
          addopcode(bytes,j);
          result:=createmodrm(bytes,getreg(parameter1),parameter2);
          exit;
        end;
      end;

      par_cr: if (paramtype1=ttRegistercr) then
      begin
        if (opcodes[j].paramtype2=par_r32) and (paramtype2=ttRegister32bit) then
        begin
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter1),parameter2);
            exit;
          end;
        end;
      end;

      par_dr:  if (paramtype1=ttRegisterdr) then
      begin
        if (opcodes[j].paramtype2=par_r32) and (paramtype2=ttRegister32bit) then
        begin
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter1),parameter2);
            exit;
          end;
        end;
      end;

      par_rm8: if (isrm8(paramtype1) or (ismemorylocationdefault(parameter1) and opcodes[j].defaulttype) ) then
      begin
        //r/m8,
        if (opcodes[j].paramtype2=par_noparam) and (parameter2='') then
        begin
          //opcode r/m8
          addopcode(bytes,j);
          result:=createmodrm(bytes,eotoreg(opcodes[j].opcode1),parameter1);
          exit;
        end;

        if (opcodes[j].paramtype2=par_1) and (paramtype2=ttValue) and (v=1) then
        begin
          addopcode(bytes,j);
          result:=createmodrm(bytes,eotoreg(opcodes[j].opcode1),parameter1);
          exit;
        end;

        if (opcodes[j].paramtype2=par_cl) and (parameter2='CL') then
        begin
          addopcode(bytes,j);
          result:=createmodrm(bytes,eotoreg(opcodes[j].opcode1),parameter1);
          exit;
        end;


        if (opcodes[j].paramtype2=par_imm8) and (paramtype2=ttValue) then
        begin
          //r/m8,imm8,
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            //verified it IS r/m8,imm8
            addopcode(bytes,j);
            createmodrm(bytes,eoToReg(opcodes[j].opcode1),parameter1);
            add(bytes,[byte(v)]);
            result:=true;
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_r8) and (paramtype2=ttRegister8bit) then
        begin
          // r/m8,r8
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter2),parameter1);
            exit;
          end;
        end;
      end;

      par_rm16: if (isrm16(paramtype1)) then
      begin
        //r/m16,
        if (opcodes[j].paramtype2=par_noparam) and (parameter2='') then
        begin
          //opcode r/m16
          addopcode(bytes,j);
          result:=createmodrm(bytes,eotoreg(opcodes[j].opcode1),parameter1);
          exit;
        end;

        if (opcodes[j].paramtype2=par_1) and (paramtype2=ttValue) and (v=1) then
        begin
          addopcode(bytes,j);
          result:=createmodrm(bytes,eotoreg(opcodes[j].opcode1),parameter1);
          exit;
        end;

        if (opcodes[j].paramtype2=par_imm8) and (paramtype2=ttValue) then
        begin
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            if vtype=16 then
            begin
              //perhaps there is a r/m16,imm16
              k:=startoflist;
              while k<=endoflist do
              begin
                if opcodes[k].mnemonic<>tokens[mnemonic] then break; //nope, so continue with r/m,imm16
                if ((opcodes[k].paramtype1=par_rm16) and (opcodes[k].paramtype2=par_imm16)) and ((opcodes[k].paramtype3=par_noparam) and (parameter3='')) then
                begin
                  //yes, there is
                  //r/m16,imm16
                  addopcode(bytes,k);
                  createmodrm(bytes,eoToReg(opcodes[k].opcode1),parameter1);
                  addword(bytes,word(v));
                  result:=true;
                  exit;
                end;
                inc(k);
              end;
            end;
            //nope, so it IS r/m16,8
            addopcode(bytes,j);
            createmodrm(bytes,eoToReg(opcodes[j].opcode1),parameter1);
            add(bytes,[byte(v)]);
            result:=true;
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_imm16) and (paramtype2=ttValue) then
        begin
          //r/m16,imm
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            if vtype=8 then
            begin
              //see if there is a r/m16,imm8 (or if this is the one) (optimisation)
              k:=startoflist;
              while k<=endoflist do
              begin
                if opcodes[k].mnemonic<>tokens[mnemonic] then break; //nope, so continue with r/m,imm16
                if ((opcodes[k].paramtype1=par_rm16) and (opcodes[k].paramtype2=par_imm8)) and ((opcodes[k].paramtype3=par_noparam) and (parameter3='')) then
                begin
                  //yes, there is
                  //r/m16,imm8
                  addopcode(bytes,k);
                  createmodrm(bytes,eoToReg(opcodes[k].opcode1),parameter1);
                  add(bytes,[byte(v)]);
                  result:=true;
                  exit;
                end;
                inc(k);
              end;
            end;

            addopcode(bytes,j);
            createmodrm(bytes,eoToReg(opcodes[j].opcode1),parameter1);
            addword(bytes,word(v));
            result:=true;
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_r16) and (paramtype2=ttRegister16bit) then
        begin
          //r/m16,r16,

          if (opcodes[j].paramtype3=par_cl) and (parameter3='CL') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter2),parameter1);
            exit;
          end;

          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter2),parameter1);
            exit;
          end;

          if (opcodes[j].paramtype3=par_imm8) and (paramtype3=ttValue) then
          begin
            //rm16, r16,imm8
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter2),parameter1);
            add(bytes,[v]);
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_sreg) and (paramtype2=ttRegistersreg) then
        begin
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            //r/m16,sreg
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter2),parameter1);
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_cl) and (parameter2='CL') then
        begin
          //rm16,cl
          addopcode(bytes,j);
          result:=createmodrm(bytes,eotoreg(opcodes[j].opcode1),parameter1);
          exit;
        end;

      end;

      par_rm32: if (isrm32(paramtype1) or isrm32(oldParamtype1)) then
      begin
        //r/m32,
        if (opcodes[j].paramtype2=par_noparam) and (parameter2='') then
        begin
          //no 2nd parameter so it is 'opcode r/m32'
          addopcode(bytes,j);
          result:=createmodrm(bytes,eoToReg(opcodes[j].opcode1),parameter1);
          exit;
        end;

        if (opcodes[j].paramtype2=par_1) and (paramtype2=ttValue) and (v=1) then
        begin
          addopcode(bytes,j);
          result:=createmodrm(bytes,eotoreg(opcodes[j].opcode1),parameter1);
          exit;
        end;


        if (opcodes[j].paramtype2=par_imm8) and (paramtype2=ttValue) then
        begin
          //rm32,imm8
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin

            if (vtype>8) or (opcodes[j].signed and (signedvtype>8)) then
            begin
              //the user requests a bigger than 8-bit value, so see if there is also a rm32,imm32 (there are no r/m32,imm16)
              k:=startoflist;
              while k<=endoflist do
              begin
                if opcodes[k].mnemonic<>tokens[mnemonic] then break;
                if ((opcodes[k].paramtype1=par_rm32) and (opcodes[k].paramtype2=par_imm32)) and ((opcodes[k].paramtype3=par_noparam) and (parameter3='')) then
                begin
                  //yes, there is
                  addopcode(bytes,k);
                  createmodrm(bytes,eoToReg(opcodes[k].opcode1),parameter1);
                  adddword(bytes,v);
                  result:=true;
                  exit;
                end;
                inc(k);
              end;
            end;

            //r/m32,imm8
            addopcode(bytes,j);
            createmodrm(bytes,eoToReg(opcodes[j].opcode1),parameter1);
            add(bytes,[byte(v)]);
            result:=true;
            exit;
          end;
        end;


        if (opcodes[j].paramtype2=par_imm32) and (paramtype2=ttValue) then
        begin
          //r/m32,imm
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            if signedvtype=8 then
            begin
              //see if there is a r/m32,imm8 (or if this is the one) (optimisation)
              k:=startoflist;
              while k<=endoflist do
              begin
                if opcodes[k].mnemonic<>tokens[mnemonic] then break; //nope, so continue with r/m,imm16
                if ((opcodes[k].paramtype1=par_rm32) and (opcodes[k].paramtype2=par_imm8)) and ((opcodes[k].paramtype3=par_noparam) and (parameter3='')) and ((not opcodes[k].signed) or (signedvtype=8)) then
                begin
                  //yes, there is
                  addopcode(bytes,k);
                  createmodrm(bytes,eoToReg(opcodes[k].opcode1),parameter1);
                  add(bytes,[byte(v)]);
                  result:=true;
                  exit;
                end;
                inc(k);
              end;
            end;
            //no there's none
            addopcode(bytes,j);
            createmodrm(bytes,eoToReg(opcodes[j].opcode1),parameter1);
            adddword(bytes,v);
            result:=true;
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_cl) and (parameter2='CL') then
        begin
          //rm32,cl
          addopcode(bytes,j);
          result:=createmodrm(bytes,eotoreg(opcodes[j].opcode1),parameter1);
          exit;
        end;


        if (opcodes[j].paramtype2=par_r32) and (paramtype2=ttRegister32bit) then
        begin
          //r/m32,r32
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter2),parameter1);
            exit;
          end;

          if (opcodes[j].paramtype3=par_cl) and (parameter3='CL') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter2),parameter1);
            exit;
          end;

          if (opcodes[j].paramtype3=par_imm8) and (paramtype3=ttValue) then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter2),parameter1);
            add(bytes,[v]);
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_mm) and (paramtype2=ttRegistermm) then
        begin
          //r32/m32,mm,
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            //r32/m32,mm
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter2), parameter1);

          end;

        end;

        if (opcodes[j].paramtype2=par_xmm) and (paramtype2=ttRegisterxmm) then
        begin
          //r32/m32,xmm,  (movd for example)
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            //r32/m32,xmm
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter2), parameter1);

          end;

        end;
      end;

      par_mm: if (paramtype1=ttRegistermm) then
      begin
        //mm,xxxxx
        if (opcodes[j].paramtype2=par_imm8) and (paramtype2=ttValue) then
        begin
          //mm,imm8
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,eotoreg(opcodes[j].opcode1),parameter1);
            add(bytes,[v]);
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_mm) and (paramtype2=ttRegistermm) then
        begin
          addopcode(bytes,j);
          result:=createmodrm(bytes,getreg(parameter1),parameter2);
          exit;
        end;

        if (opcodes[j].paramtype2=par_xmm) and (paramtype2=ttRegisterxmm) then
        begin
          //mm,xmm
          addopcode(bytes,j);
          result:=createmodrm(bytes,getreg(parameter1),parameter2);
          exit;
        end;

        if (opcodes[j].paramtype2=par_r32_m16) and ( (paramtype1=ttRegister32bit) or (paramtype2=ttMemorylocation16) or ismemorylocationdefault(parameter2) ) then
        begin
          //mm,r32/m16,
          if (opcodes[j].paramtype3=par_imm8) and (paramtype3=ttValue) then
          begin
            //imm8
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter1),parameter2);
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_rm32) and (isrm32(paramtype2)) then
        begin
          //mm,rm32
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            //xmm,rm32
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter1),parameter2);
            exit;
          end;
        end;




        if (opcodes[j].paramtype2=par_xmm_m32) and (isxmm_m32(paramtype2)) then
        begin
          //mm,xmm/m32
          addopcode(bytes,j);
          result:=createmodrm(bytes,getreg(parameter1),parameter2);
          exit;
        end;

        if (opcodes[j].paramtype2=par_mm_m64) and (ismm_m64(paramtype2) or ((paramtype2=ttMemorylocation32) and (parameter2[1]='['))) then
        begin
          //mm,mm/m64
          addopcode(bytes,j);
          result:=createmodrm(bytes,getreg(parameter1),parameter2);
          exit;
        end;

        if (opcodes[j].paramtype2=par_xmm_m64) and (isxmm_m64(paramtype2) or ((paramtype2=ttMemorylocation32) and (parameter2[1]='['))) then
        begin
          //mm,xmm/m64
          addopcode(bytes,j);
          result:=createmodrm(bytes,getreg(parameter1),parameter2);
          exit;
        end;

        if (opcodes[j].paramtype2=par_xmm_m128) and (isxmm_m128(paramtype2) or ((paramtype2=ttMemorylocation32) and (parameter2[1]='['))) then
        begin
          //mm,xmm/m128
          addopcode(bytes,j);
          result:=createmodrm(bytes,getreg(parameter1),parameter2);
          exit;
        end;
      end;

      par_mm_m64: if (ismm_m64(paramtype1) or ((paramtype1=ttMemorylocation32) and (parameter1[1]='['))) then
      begin
        if (opcodes[j].paramtype2=par_mm) and (paramtype2=ttRegistermm) then
        begin
          //mm/m64, mm
          addopcode(bytes,j);
          result:=createmodrm(bytes,getreg(parameter2),parameter1);
          exit;
        end;
      end;

      par_xmm_m64: if (isxmm_m64(paramtype1) or ((paramtype1=ttMemorylocation32) and (parameter1[1]='[')))  then
      begin
        //xmm/m64,
        if (opcodes[j].paramtype2=par_xmm) and (paramtype2=ttRegisterxmm) then
        begin
          //xmm/m64, xmm
          addopcode(bytes,j);
          result:=createmodrm(bytes,getreg(parameter2),parameter1);
          exit;
        end;
      end;

      par_xmm_m128: if (isxmm_m128(paramtype1) or ((paramtype1=ttMemorylocation32) and (parameter1[1]='[')))  then
      begin
        //xmm/m128,
        if (opcodes[j].paramtype2=par_xmm) and (paramtype2=ttRegisterxmm) then
        begin
          //xmm/m128, xmm
          addopcode(bytes,j);
          result:=createmodrm(bytes,getreg(parameter2),parameter1);
          exit;
        end;
      end;

      par_xmm: if (paramtype1=ttRegisterxmm) then
      begin
        if (opcodes[j].paramtype2=par_imm8) and (paramtype2=ttValue) then
        begin
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,eotoreg(opcodes[j].opcode1),parameter1);
            add(bytes,[v]);
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_mm) and (paramtype2=ttRegistermm) then
        begin
          //xmm,xmm
          addopcode(bytes,j);
          result:=createmodrm(bytes,getreg(parameter1),parameter2);
          exit;
        end;


        if (opcodes[j].paramtype2=par_xmm) and (paramtype2=ttRegisterxmm) then
        begin
          //xmm,xmm
          addopcode(bytes,j);
          result:=createmodrm(bytes,getreg(parameter1),parameter2);
          exit;
        end;

        if (opcodes[j].paramtype2=par_m64) and ((paramtype2=ttMemorylocation64) or (ismemorylocationdefault(parameter2))) then
        begin
          addopcode(bytes,j);
          result:=createmodrm(bytes,getreg(parameter1),parameter2);
          exit;
        end;

        if (opcodes[j].paramtype2=par_m128) and ((paramtype2=ttMemoryLocation128) or (ismemorylocationdefault(parameter2))) then
        begin
          addopcode(bytes,j);
          result:=createmodrm(bytes,getreg(parameter1),parameter2);
          exit;
        end;

        if (opcodes[j].paramtype2=par_rm32) and (isrm32(paramtype2)) then
        begin
          //xmm,rm32,
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            //xmm,rm32
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter1),parameter2);
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_mm_m64) and (ismm_m64(paramtype2) or ((paramtype2=ttMemorylocation32) and (parameter2[1]='['))) then
        begin
          //xmm,mm/m64
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            //xmm,mm/m64
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter1),parameter2);
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_xmm_m32) and isxmm_m32(paramtype2) then
        begin
          //even if the user didn't intend for it to be xmm,m64 it will be, that'll teach the lazy user to forget opperand size
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            //xmm,xmm/m32
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter1),parameter2);
            exit;
          end;

          if (opcodes[j].paramtype3=par_imm8) and (paramtype3=ttValue) then
          begin
            addopcode(bytes,j);
            createmodrm(bytes,getreg(parameter1),parameter2);
            add(bytes,[v]);
            result:=true;
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_xmm_m64) and (isxmm_m64(paramtype2) or ((paramtype2=ttMemorylocation32) and (parameter2[1]='[')))  then
        begin
          //even if the user didn't intend for it to be xmm,m64 it will be, that'll teach the lazy user to forget opperand size
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            //xmm,xmm/m64
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter1),parameter2);
            exit;
          end;

          if (opcodes[j].paramtype3=par_imm8) and (paramtype3=ttValue) then
          begin
            addopcode(bytes,j);
            createmodrm(bytes,getreg(parameter1),parameter2);
            add(bytes,[v]);
            result:=true;
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_xmm_m128) and (isxmm_m128(paramtype2) or ((paramtype2=ttMemorylocation32) and (parameter2[1]='[')))  then
        begin
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            //xmm,xmm/m128
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter1),parameter2);
            exit;
          end;

          if (opcodes[j].paramtype3=par_imm8) and (paramtype3=ttValue) then
          begin
            addopcode(bytes,j);
            createmodrm(bytes,getreg(parameter1),parameter2);
            add(bytes,[v]);
            result:=true;
            exit;
          end;
        end;

      end;

      par_m8: if ((paramtype1=ttMemorylocation8) or ismemorylocationdefault(parameter1)) then
      begin
        //m8,xxx
        if (opcodes[j].paramtype2=par_noparam) and (parameter2='') then
        begin
          //m8
          //                                 //check if it is especially designed to be 32 bit, or if it is a default anser
          //verified, it is a 8 bit location, and if it was detected as 8 it was due to defaulting to 32
          addopcode(bytes,j);
          result:=createmodrm(bytes,eotoreg(opcodes[j].opcode1),parameter1);
          exit;
        end;
      end;

      par_m16:
      begin
        if ((paramtype1=ttMemorylocation16) or ismemorylocationdefault(parameter1)) then
        begin
          if (opcodes[j].paramtype2=par_noparam) and (parameter2='') then
          begin
            //opcode+rd
            addopcode(bytes,j);
            result:=createmodrm(bytes,eotoreg(opcodes[j].opcode1),parameter1);
            exit;
          end;
        end;

      end;

      par_m32: if (paramtype1=ttMemorylocation32) then
      begin
        if (opcodes[j].paramtype2=par_noparam) and (parameter2='') then
        begin
          addopcode(bytes,j);
          result:=createmodrm(bytes,eotoreg(opcodes[j].opcode1),parameter1);
          exit;
        end;

        if (opcodes[j].paramtype2=par_r32) then
        begin
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,eotoreg(opcodes[j].opcode1),parameter1);
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_xmm) and ((paramtype2=ttRegisterxmm) or ismemorylocationdefault(parameter2)  ) then
        begin
          if (opcodes[j].paramtype3=par_noparam) or (parameter3='') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter2),parameter1);
            exit;
          end;
        end;
      end;

      par_m64:
      if (paramtype1=ttMemorylocation64) or (paramtype1=ttMemorylocation32)  then
      begin
        //m64,
        if (opcodes[j].paramtype2=par_noparam) and (parameter2='') then
        begin
          //m64
          //

          if (gettokentype(parameter1,parameter2)=ttMemoryLocation64) or ismemorylocationdefault(parameter1) then
          begin
            //verified, it is a 64 bit location, and if it was detected as 32 it was due to defaulting to 32
            addopcode(bytes,j);
            result:=createmodrm(bytes,eotoreg(opcodes[j].opcode1),parameter1);
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_xmm) and ((paramtype2=ttRegisterxmm) or ismemorylocationdefault(parameter2)  ) then
        begin
          if (opcodes[j].paramtype3=par_noparam) or (parameter3='') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter2),parameter1);
            exit;
          end;
        end;

        if (opcodes[j].paramtype2=par_xmm) and ((paramtype2=ttRegisterxmm) or ismemorylocationdefault(parameter2)  ) then
        begin
          if (opcodes[j].paramtype3=par_noparam) or (parameter3='') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter2),parameter1);
            exit;
          end;
        end;

      end;

      par_m80: if ((paramtype1=ttMemorylocation80) or ((paramtype1=ttMemorylocation32) and (parameter1[1]='[')))  then
      begin
        if (opcodes[j].paramtype2=par_noparam) and (parameter2='') then
        begin
          addopcode(bytes,j);
          result:=createmodrm(bytes,eotoreg(opcodes[j].opcode1),parameter1);
          exit;
        end;
      end;

      par_m128: if ((paramtype1=ttMemorylocation128) or (ismemorylocationdefault(parameter1))) then
      begin
        if (opcodes[j].paramtype2=par_xmm) and (paramtype2=ttRegisterxmm) then
        begin
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            addopcode(bytes,j);
            result:=createmodrm(bytes,getreg(parameter2),parameter1);
            exit;
          end;
        end;
      end;

      par_rel8: if (paramtype1=ttValue) then
      begin
        if (opcodes[j].paramtype2=par_noparam) and (parameter2='') then
        begin
          //rel8

          if (parameter1[1] in ['-','+']) then
          begin
            if ((not overrideShort) and (vtype>8)) or (overrideLong) then
            begin
              //see if there is a 32 bit equivalent opcode (notice I dont do rel 16 because that'll completely screw up eip)
              k:=startoflist;
              while (k<=opcodecount) and (opcodes[k].mnemonic=tokens[mnemonic]) do
              begin
                if (opcodes[k].paramtype1=par_rel32) and (opcodes[k].paramtype2=par_noparam) then
                begin
                  //yes, there is a 32 bit version
                  addopcode(bytes,k);
                  adddword(bytes,v);
                  result:=true;
                  exit;
                end;
                inc(k);
              end;

            end;


            addopcode(bytes,j);
            add(bytes,[v]);
            result:=true;
            exit;
          end
          else
          begin
            //user typed in a direct address

  //        if (not overrideShort) and ((OverrideLong) or (valueTotype(      v-address-       (opcodes[j].bytes+1) )>8) ) then
            if (not overrideShort) and ((OverrideLong) or (valueToType(DWord(v-address-Integer(opcodes[j].bytes+1)))>8) ) then
            begin
              //the user tried to find a relative address out of it's reach
              //see if there is a 32 bit version of the opcode
              k:=startoflist;
              while (k<=opcodecount) and (opcodes[k].mnemonic=tokens[mnemonic]) do
              begin
                if (opcodes[k].paramtype1=par_rel32) and (opcodes[k].paramtype2=par_noparam) then
                begin
                  //yes, there is a 32 bit version
                  addopcode(bytes,k);
                  adddword(bytes,v-address-(opcodes[k].bytes+4));
                  result:=true;
                  exit;
                end;
                inc(k);
              end;
            end
            else
            begin
              //8 bit version

              addopcode(bytes,j);

              add(bytes,[v-address-(opcodes[j].bytes+1)]);
              result:=true;
              exit;
            end;
          end;

        end;
      end;

      par_rel32:  if (paramtype1=ttValue) then
      begin
        if (opcodes[j].paramtype2=par_noparam) and (parameter2='') then
        begin
          if parameter1[1] in ['-','+'] then
          begin
            //opcode rel32

            addopcode(bytes,j);
            adddword(bytes,v);
            result:=true;
            exit;
          end else
          begin
            //user typed in a direct address
            addopcode(bytes,j);

            adddword(bytes,v-address-(opcodes[j].bytes+4));
            result:=true;
            exit;
          end;
        end;
      end;

      par_st0: if ((parameter1='ST(0)') or (parameter1='ST')) then
      begin
        //st(0),
        if (opcodes[j].paramtype2=par_st) and (paramtype2=ttRegisterst) then
        begin
          //st(0),st(x),
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            if (opcodes[j].opcode1=eo_pi) then
            begin
              //opcode+i
              addopcode(bytes,j);
              k:=getreg(parameter2);
              if k>7 then
              begin
                rex_b:=true;
                k:=k and 7;
              end;
              inc(bytes[length(bytes)-1],k);
              result:=true;
              exit;
            end;

          end;
        end;
      end;

      par_st:  if (paramtype1=ttRegisterst) then
      begin
        //st(x),
        if (opcodes[j].paramtype2=par_noparam) and (parameter2='') then
        begin
          //st(x)
          addopcode(bytes,j);
          k:=getreg(parameter1);
          if k>7 then
          begin
            rex_b:=true;
            k:=k and 7;
          end;
          inc(bytes[length(bytes)-1],k);
          result:=true;
          exit;
        end;

        if (opcodes[j].paramtype2=par_st0) and ((parameter2='ST(0)') or (parameter2='ST')) then
        begin
          //st(x),st(0)
          if (opcodes[j].paramtype3=par_noparam) and (parameter3='') then
          begin
            if (opcodes[j].opcode1=eo_pi) then
            begin
              //opcode+i
              addopcode(bytes,j);
              k:=getreg(parameter1);
              if k>7 then
              begin
                rex_b:=true;
                k:=k and 7;
              end;
              inc(bytes[length(bytes)-1],k);
              result:=true;
              exit;
            end;

          end;
        end;
      end;

    end;


    paramtype1:=oldParamtype1;
    paramtype2:=oldParamtype2;

    inc(j);
  end;

  finally
    if result then
    begin
      //insert rex prefix if needed
      if processhandler.is64bit then
      begin
        if opcodes[j].norexw then
          REX_W:=false;

        if RexPrefix<>0 then
        begin
          if RexPrefixLocation=-1 then raise exception.create(rsAssemblerError);
          RexPrefix:=RexPrefix or $40; //just make sure this is set
          setlength(bytes,length(bytes)+1);
          for i:=length(bytes)-1 downto RexPrefixLocation+1 do
            bytes[i]:=bytes[i-1];

          bytes[RexPrefixLocation]:=RexPrefix;

          if relativeAddressLocation<>-1 then inc(relativeAddressLocation);
        end;


        if relativeAddressLocation<>-1 then
        begin
          //adjust the specified address so it's relative (The outside of range check is already done in the modrm generation)
          if actualdisplacement>(address+length(bytes)) then
            v:=actualdisplacement-(address+length(bytes))
          else
            v:=(address+length(bytes))-actualdisplacement;

          if v>$7fffffff then
          begin
            setlength(bytes,0);
            //result:=HandleTooBigAddress(opcode,address, bytes, actualdisplacement);

            if skiprangecheck=false then  //for syntax checking
              raise exception.create(rsOffsetTooBig);
          end
          else
            pdword(@bytes[relativeAddressLocation])^:=actualdisplacement-(address+length(bytes));

        end;




      end;
    end;

    if needsAddressSwitchPrefix then //add it
    begin
      if canDoAddressSwitch then
      begin
        //put 0x67 in front
        setlength(bytes,length(bytes)+1);
        for i:=length(bytes)-1 downto 1 do
          bytes[i]:=bytes[i-1];

        bytes[0]:=$67;
      end
      else
        raise exception.create('Invalid address');
    end;
  end;
end;



//following routine is not finished and even when it is it's just useless
function TSingleLineAssembler.HandleTooBigAddress(opcode: string; address: ptrUint;var bytes: TAssemblerBytes; actualdisplacement: integer): boolean;
{
offset too big
rewrite this instruction
jmp +32
storage:
.....

push rax
mov rax,actualdisplacement
mov rax,[rax]
mov [rsp-8],rax
pop rax  //note that it will now be stored at rsp-10
mov [rsp-10],ecx  original instruction   :mov [181000010],rsp
push rax
push rbx
mov rax,[storage]
mov [actual],rax
pop rbx
pop rax


addressconfig:
dq displacement
}
var
  push1: TAssemblerBytes;
  movrax1: TAssemblerBytes;
  movrax2: TAssemblerBytes;
  movaddressconfig:TAssemblerBytes;
  pop1: TAssemblerBytes;
  modifiedoriginal: TAssemblerBytes;

  toreplace: string;
  i,j: integer;
begin
  i:=pos('[',opcode);
  j:=pos(']',opcode);
  toreplace:=copy(opcode,i+1,j-i-1);


  result:=assemble('push rax',address,push1);
  if result then result:=assemble('mov rax,'+toreplace,address,movrax1);
  if result then result:=assemble('mov rax,[rax]',address,movrax2);
  if result then result:=assemble('mov [rsp-8],rax',address,movaddressconfig);
  if result then result:=assemble('pop rax',address,pop1);

  if result then
  begin
    opcode:=stringreplace(opcode,toreplace,'rsp-10',[]);
    result:=assemble(opcode,address,modifiedoriginal);

    if result then
    begin
      //and
      setlength(bytes,length(push1)+length(movrax1)+length(movrax2)+length(movaddressconfig)+length(pop1)+length(modifiedoriginal));
      j:=0;

      for i:=0 to length(push1) do
      begin
        bytes[j]:=push1[i];
        inc(j);
      end;

      for i:=0 to length(movrax1) do
      begin
        bytes[j]:=movrax1[i];
        inc(j);
      end;

      for i:=0 to length(movrax2) do
      begin
        bytes[j]:=movrax2[i];
        inc(j);
      end;

      for i:=0 to length(movaddressconfig) do
      begin
        bytes[j]:=movaddressconfig[i];
        inc(j);
      end;

      for i:=0 to length(pop1) do
      begin
        bytes[j]:=pop1[i];
        inc(j);
      end;

      for i:=0 to length(modifiedoriginal) do
      begin
        bytes[j]:=modifiedoriginal[i];
        inc(j);
      end;

    end;
  end;
end;

var i,j,k: integer;
    lastentry: integer=1;
    lastindex: PIndexArray=nil;

initialization
//setup the index for the assembler

  for i:=0 to 25 do
  begin
    assemblerindex[i].startentry:=-1;
    assemblerindex[i].NextEntry:=-1;
    assemblerindex[i].SubIndex:=nil;
    for j:=lastentry to opcodecount do
    begin

      if ord(opcodes[j].mnemonic[1])=(ord('A')+i) then
      begin
        //found the first entry with this as first character
        if lastindex<>nil then
          lastindex[0].nextentry:=j;

        lastindex:=@assemblerindex[i];
        assemblerindex[i].startentry:=j;
        assemblerindex[i].SubIndex:=nil; //default initialization
        lastentry:=j;
        break;
      end;

      if ord(opcodes[j].mnemonic[1])>(ord('A')+i) then
        break; //passed it

    end;

  end;

  if assemblerindex[25].startentry<>-1 then
    assemblerindex[25].NextEntry:=opcodecount;

  //fill in the subindexes
  for i:=0 to 25 do
  begin
    if assemblerindex[i].startentry<>-1 then
    begin
      //initialize subindex
      getmem(assemblerindex[i].SubIndex,26*sizeof(tindex));
      for j:=0 to 25 do
      begin
        assemblerindex[i].SubIndex[j].startentry:=-1;
        assemblerindex[i].SubIndex[j].NextEntry:=-1;
        assemblerindex[i].SubIndex[j].SubIndex:=nil;
      end;

      lastindex:=nil;
      if (assemblerindex[i].NextEntry=-1) then //last one in the list didn't get a assignment
        assemblerindex[i].NextEntry:=opcodecount+1;

      for j:=0 to 25 do
      begin
        for k:=assemblerindex[i].startentry to assemblerindex[i].NextEntry-1 do
        begin
          if ord(opcodes[k].mnemonic[2])=(ord('A')+j) then
          begin
            if lastindex<>nil then
              lastindex[0].nextentry:=k;

            lastindex:=@assemblerindex[i].SubIndex[j];
            assemblerindex[i].SubIndex[j].startentry:=k;
            break;
          end;
        end;
      end;

    end;
  end;

  SingleLineAssembler:=TSingleLineassembler.create;

finalization
  if SingleLineAssembler<>nil then
    SingleLineAssembler.free;

end.
