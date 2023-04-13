
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	c8478793          	addi	a5,a5,-892 # 80005ce0 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
};
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e6a78793          	addi	a5,a5,-406 # 80000f10 <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	b56080e7          	jalr	-1194(ra) # 80000c62 <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	3d6080e7          	jalr	982(ra) # 800024fc <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	7aa080e7          	jalr	1962(ra) # 800008e0 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	bc8080e7          	jalr	-1080(ra) # 80000d16 <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7119                	addi	sp,sp,-128
    80000170:	fc86                	sd	ra,120(sp)
    80000172:	f8a2                	sd	s0,112(sp)
    80000174:	f4a6                	sd	s1,104(sp)
    80000176:	f0ca                	sd	s2,96(sp)
    80000178:	ecce                	sd	s3,88(sp)
    8000017a:	e8d2                	sd	s4,80(sp)
    8000017c:	e4d6                	sd	s5,72(sp)
    8000017e:	e0da                	sd	s6,64(sp)
    80000180:	fc5e                	sd	s7,56(sp)
    80000182:	f862                	sd	s8,48(sp)
    80000184:	f466                	sd	s9,40(sp)
    80000186:	f06a                	sd	s10,32(sp)
    80000188:	ec6e                	sd	s11,24(sp)
    8000018a:	0100                	addi	s0,sp,128
    8000018c:	8b2a                	mv	s6,a0
    8000018e:	8aae                	mv	s5,a1
    80000190:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000192:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    80000196:	00011517          	auipc	a0,0x11
    8000019a:	69a50513          	addi	a0,a0,1690 # 80011830 <cons>
    8000019e:	00001097          	auipc	ra,0x1
    800001a2:	ac4080e7          	jalr	-1340(ra) # 80000c62 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a6:	00011497          	auipc	s1,0x11
    800001aa:	68a48493          	addi	s1,s1,1674 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ae:	89a6                	mv	s3,s1
    800001b0:	00011917          	auipc	s2,0x11
    800001b4:	71890913          	addi	s2,s2,1816 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b8:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ba:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001bc:	4da9                	li	s11,10
  while(n > 0){
    800001be:	07405863          	blez	s4,8000022e <consoleread+0xc0>
    while(cons.r == cons.w){
    800001c2:	0984a783          	lw	a5,152(s1)
    800001c6:	09c4a703          	lw	a4,156(s1)
    800001ca:	02f71463          	bne	a4,a5,800001f2 <consoleread+0x84>
      if(myproc()->killed){
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	862080e7          	jalr	-1950(ra) # 80001a30 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	066080e7          	jalr	102(ra) # 80002244 <sleep>
    while(cons.r == cons.w){
    800001e6:	0984a783          	lw	a5,152(s1)
    800001ea:	09c4a703          	lw	a4,156(s1)
    800001ee:	fef700e3          	beq	a4,a5,800001ce <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f2:	0017871b          	addiw	a4,a5,1
    800001f6:	08e4ac23          	sw	a4,152(s1)
    800001fa:	07f7f713          	andi	a4,a5,127
    800001fe:	9726                	add	a4,a4,s1
    80000200:	01874703          	lbu	a4,24(a4)
    80000204:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000208:	079c0663          	beq	s8,s9,80000274 <consoleread+0x106>
    cbuf = c;
    8000020c:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	f8f40613          	addi	a2,s0,-113
    80000216:	85d6                	mv	a1,s5
    80000218:	855a                	mv	a0,s6
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	28c080e7          	jalr	652(ra) # 800024a6 <either_copyout>
    80000222:	01a50663          	beq	a0,s10,8000022e <consoleread+0xc0>
    dst++;
    80000226:	0a85                	addi	s5,s5,1
    --n;
    80000228:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000022a:	f9bc1ae3          	bne	s8,s11,800001be <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022e:	00011517          	auipc	a0,0x11
    80000232:	60250513          	addi	a0,a0,1538 # 80011830 <cons>
    80000236:	00001097          	auipc	ra,0x1
    8000023a:	ae0080e7          	jalr	-1312(ra) # 80000d16 <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	aca080e7          	jalr	-1334(ra) # 80000d16 <release>
        return -1;
    80000254:	557d                	li	a0,-1
}
    80000256:	70e6                	ld	ra,120(sp)
    80000258:	7446                	ld	s0,112(sp)
    8000025a:	74a6                	ld	s1,104(sp)
    8000025c:	7906                	ld	s2,96(sp)
    8000025e:	69e6                	ld	s3,88(sp)
    80000260:	6a46                	ld	s4,80(sp)
    80000262:	6aa6                	ld	s5,72(sp)
    80000264:	6b06                	ld	s6,64(sp)
    80000266:	7be2                	ld	s7,56(sp)
    80000268:	7c42                	ld	s8,48(sp)
    8000026a:	7ca2                	ld	s9,40(sp)
    8000026c:	7d02                	ld	s10,32(sp)
    8000026e:	6de2                	ld	s11,24(sp)
    80000270:	6109                	addi	sp,sp,128
    80000272:	8082                	ret
      if(n < target){
    80000274:	000a071b          	sext.w	a4,s4
    80000278:	fb777be3          	bgeu	a4,s7,8000022e <consoleread+0xc0>
        cons.r--;
    8000027c:	00011717          	auipc	a4,0x11
    80000280:	64f72623          	sw	a5,1612(a4) # 800118c8 <cons+0x98>
    80000284:	b76d                	j	8000022e <consoleread+0xc0>

0000000080000286 <consputc>:
{
    80000286:	1141                	addi	sp,sp,-16
    80000288:	e406                	sd	ra,8(sp)
    8000028a:	e022                	sd	s0,0(sp)
    8000028c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028e:	10000793          	li	a5,256
    80000292:	00f50a63          	beq	a0,a5,800002a6 <consputc+0x20>
    uartputc_sync(c);
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	564080e7          	jalr	1380(ra) # 800007fa <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	552080e7          	jalr	1362(ra) # 800007fa <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	546080e7          	jalr	1350(ra) # 800007fa <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	53c080e7          	jalr	1340(ra) # 800007fa <uartputc_sync>
    800002c6:	bfe1                	j	8000029e <consputc+0x18>

00000000800002c8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c8:	1101                	addi	sp,sp,-32
    800002ca:	ec06                	sd	ra,24(sp)
    800002cc:	e822                	sd	s0,16(sp)
    800002ce:	e426                	sd	s1,8(sp)
    800002d0:	e04a                	sd	s2,0(sp)
    800002d2:	1000                	addi	s0,sp,32
    800002d4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d6:	00011517          	auipc	a0,0x11
    800002da:	55a50513          	addi	a0,a0,1370 # 80011830 <cons>
    800002de:	00001097          	auipc	ra,0x1
    800002e2:	984080e7          	jalr	-1660(ra) # 80000c62 <acquire>

  switch(c){
    800002e6:	47d5                	li	a5,21
    800002e8:	0af48663          	beq	s1,a5,80000394 <consoleintr+0xcc>
    800002ec:	0297ca63          	blt	a5,s1,80000320 <consoleintr+0x58>
    800002f0:	47a1                	li	a5,8
    800002f2:	0ef48763          	beq	s1,a5,800003e0 <consoleintr+0x118>
    800002f6:	47c1                	li	a5,16
    800002f8:	10f49a63          	bne	s1,a5,8000040c <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fc:	00002097          	auipc	ra,0x2
    80000300:	256080e7          	jalr	598(ra) # 80002552 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	a0a080e7          	jalr	-1526(ra) # 80000d16 <release>
}
    80000314:	60e2                	ld	ra,24(sp)
    80000316:	6442                	ld	s0,16(sp)
    80000318:	64a2                	ld	s1,8(sp)
    8000031a:	6902                	ld	s2,0(sp)
    8000031c:	6105                	addi	sp,sp,32
    8000031e:	8082                	ret
  switch(c){
    80000320:	07f00793          	li	a5,127
    80000324:	0af48e63          	beq	s1,a5,800003e0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000328:	00011717          	auipc	a4,0x11
    8000032c:	50870713          	addi	a4,a4,1288 # 80011830 <cons>
    80000330:	0a072783          	lw	a5,160(a4)
    80000334:	09872703          	lw	a4,152(a4)
    80000338:	9f99                	subw	a5,a5,a4
    8000033a:	07f00713          	li	a4,127
    8000033e:	fcf763e3          	bltu	a4,a5,80000304 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000342:	47b5                	li	a5,13
    80000344:	0cf48763          	beq	s1,a5,80000412 <consoleintr+0x14a>
      consputc(c);
    80000348:	8526                	mv	a0,s1
    8000034a:	00000097          	auipc	ra,0x0
    8000034e:	f3c080e7          	jalr	-196(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000352:	00011797          	auipc	a5,0x11
    80000356:	4de78793          	addi	a5,a5,1246 # 80011830 <cons>
    8000035a:	0a07a703          	lw	a4,160(a5)
    8000035e:	0017069b          	addiw	a3,a4,1
    80000362:	0006861b          	sext.w	a2,a3
    80000366:	0ad7a023          	sw	a3,160(a5)
    8000036a:	07f77713          	andi	a4,a4,127
    8000036e:	97ba                	add	a5,a5,a4
    80000370:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000374:	47a9                	li	a5,10
    80000376:	0cf48563          	beq	s1,a5,80000440 <consoleintr+0x178>
    8000037a:	4791                	li	a5,4
    8000037c:	0cf48263          	beq	s1,a5,80000440 <consoleintr+0x178>
    80000380:	00011797          	auipc	a5,0x11
    80000384:	5487a783          	lw	a5,1352(a5) # 800118c8 <cons+0x98>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00011717          	auipc	a4,0x11
    80000398:	49c70713          	addi	a4,a4,1180 # 80011830 <cons>
    8000039c:	0a072783          	lw	a5,160(a4)
    800003a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	00011497          	auipc	s1,0x11
    800003a8:	48c48493          	addi	s1,s1,1164 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003ac:	4929                	li	s2,10
    800003ae:	f4f70be3          	beq	a4,a5,80000304 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b2:	37fd                	addiw	a5,a5,-1
    800003b4:	07f7f713          	andi	a4,a5,127
    800003b8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ba:	01874703          	lbu	a4,24(a4)
    800003be:	f52703e3          	beq	a4,s2,80000304 <consoleintr+0x3c>
      cons.e--;
    800003c2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c6:	10000513          	li	a0,256
    800003ca:	00000097          	auipc	ra,0x0
    800003ce:	ebc080e7          	jalr	-324(ra) # 80000286 <consputc>
    while(cons.e != cons.w &&
    800003d2:	0a04a783          	lw	a5,160(s1)
    800003d6:	09c4a703          	lw	a4,156(s1)
    800003da:	fcf71ce3          	bne	a4,a5,800003b2 <consoleintr+0xea>
    800003de:	b71d                	j	80000304 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e0:	00011717          	auipc	a4,0x11
    800003e4:	45070713          	addi	a4,a4,1104 # 80011830 <cons>
    800003e8:	0a072783          	lw	a5,160(a4)
    800003ec:	09c72703          	lw	a4,156(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00011717          	auipc	a4,0x11
    800003fa:	4cf72d23          	sw	a5,1242(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fe:	10000513          	li	a0,256
    80000402:	00000097          	auipc	ra,0x0
    80000406:	e84080e7          	jalr	-380(ra) # 80000286 <consputc>
    8000040a:	bded                	j	80000304 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040c:	ee048ce3          	beqz	s1,80000304 <consoleintr+0x3c>
    80000410:	bf21                	j	80000328 <consoleintr+0x60>
      consputc(c);
    80000412:	4529                	li	a0,10
    80000414:	00000097          	auipc	ra,0x0
    80000418:	e72080e7          	jalr	-398(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041c:	00011797          	auipc	a5,0x11
    80000420:	41478793          	addi	a5,a5,1044 # 80011830 <cons>
    80000424:	0a07a703          	lw	a4,160(a5)
    80000428:	0017069b          	addiw	a3,a4,1
    8000042c:	0006861b          	sext.w	a2,a3
    80000430:	0ad7a023          	sw	a3,160(a5)
    80000434:	07f77713          	andi	a4,a4,127
    80000438:	97ba                	add	a5,a5,a4
    8000043a:	4729                	li	a4,10
    8000043c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000440:	00011797          	auipc	a5,0x11
    80000444:	48c7a623          	sw	a2,1164(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000448:	00011517          	auipc	a0,0x11
    8000044c:	48050513          	addi	a0,a0,1152 # 800118c8 <cons+0x98>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	f7a080e7          	jalr	-134(ra) # 800023ca <wakeup>
    80000458:	b575                	j	80000304 <consoleintr+0x3c>

000000008000045a <consoleinit>:

void
consoleinit(void)
{
    8000045a:	1141                	addi	sp,sp,-16
    8000045c:	e406                	sd	ra,8(sp)
    8000045e:	e022                	sd	s0,0(sp)
    80000460:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000462:	00008597          	auipc	a1,0x8
    80000466:	bae58593          	addi	a1,a1,-1106 # 80008010 <etext+0x10>
    8000046a:	00011517          	auipc	a0,0x11
    8000046e:	3c650513          	addi	a0,a0,966 # 80011830 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	760080e7          	jalr	1888(ra) # 80000bd2 <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	330080e7          	jalr	816(ra) # 800007aa <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00021797          	auipc	a5,0x21
    80000486:	52e78793          	addi	a5,a5,1326 # 800219b0 <devsw>
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	ce470713          	addi	a4,a4,-796 # 8000016e <consoleread>
    80000492:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000494:	00000717          	auipc	a4,0x0
    80000498:	c5870713          	addi	a4,a4,-936 # 800000ec <consolewrite>
    8000049c:	ef98                	sd	a4,24(a5)
};
    8000049e:	60a2                	ld	ra,8(sp)
    800004a0:	6402                	ld	s0,0(sp)
    800004a2:	0141                	addi	sp,sp,16
    800004a4:	8082                	ret

00000000800004a6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a6:	7179                	addi	sp,sp,-48
    800004a8:	f406                	sd	ra,40(sp)
    800004aa:	f022                	sd	s0,32(sp)
    800004ac:	ec26                	sd	s1,24(sp)
    800004ae:	e84a                	sd	s2,16(sp)
    800004b0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b2:	c219                	beqz	a2,800004b8 <printint+0x12>
    800004b4:	08054663          	bltz	a0,80000540 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b8:	2501                	sext.w	a0,a0
    800004ba:	4881                	li	a7,0
    800004bc:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c2:	2581                	sext.w	a1,a1
    800004c4:	00008617          	auipc	a2,0x8
    800004c8:	b7c60613          	addi	a2,a2,-1156 # 80008040 <digits>
    800004cc:	883a                	mv	a6,a4
    800004ce:	2705                	addiw	a4,a4,1
    800004d0:	02b577bb          	remuw	a5,a0,a1
    800004d4:	1782                	slli	a5,a5,0x20
    800004d6:	9381                	srli	a5,a5,0x20
    800004d8:	97b2                	add	a5,a5,a2
    800004da:	0007c783          	lbu	a5,0(a5)
    800004de:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e2:	0005079b          	sext.w	a5,a0
    800004e6:	02b5553b          	divuw	a0,a0,a1
    800004ea:	0685                	addi	a3,a3,1
    800004ec:	feb7f0e3          	bgeu	a5,a1,800004cc <printint+0x26>

  if(sign)
    800004f0:	00088b63          	beqz	a7,80000506 <printint+0x60>
    buf[i++] = '-';
    800004f4:	fe040793          	addi	a5,s0,-32
    800004f8:	973e                	add	a4,a4,a5
    800004fa:	02d00793          	li	a5,45
    800004fe:	fef70823          	sb	a5,-16(a4)
    80000502:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000506:	02e05763          	blez	a4,80000534 <printint+0x8e>
    8000050a:	fd040793          	addi	a5,s0,-48
    8000050e:	00e784b3          	add	s1,a5,a4
    80000512:	fff78913          	addi	s2,a5,-1
    80000516:	993a                	add	s2,s2,a4
    80000518:	377d                	addiw	a4,a4,-1
    8000051a:	1702                	slli	a4,a4,0x20
    8000051c:	9301                	srli	a4,a4,0x20
    8000051e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000522:	fff4c503          	lbu	a0,-1(s1)
    80000526:	00000097          	auipc	ra,0x0
    8000052a:	d60080e7          	jalr	-672(ra) # 80000286 <consputc>
  while(--i >= 0)
    8000052e:	14fd                	addi	s1,s1,-1
    80000530:	ff2499e3          	bne	s1,s2,80000522 <printint+0x7c>
}
    80000534:	70a2                	ld	ra,40(sp)
    80000536:	7402                	ld	s0,32(sp)
    80000538:	64e2                	ld	s1,24(sp)
    8000053a:	6942                	ld	s2,16(sp)
    8000053c:	6145                	addi	sp,sp,48
    8000053e:	8082                	ret
    x = -xx;
    80000540:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000544:	4885                	li	a7,1
    x = -xx;
    80000546:	bf9d                	j	800004bc <printint+0x16>

0000000080000548 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
    80000552:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000554:	00011797          	auipc	a5,0x11
    80000558:	3807ae23          	sw	zero,924(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000055c:	00008517          	auipc	a0,0x8
    80000560:	abc50513          	addi	a0,a0,-1348 # 80008018 <etext+0x18>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	b5250513          	addi	a0,a0,-1198 # 800080c8 <digits+0x88>
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	014080e7          	jalr	20(ra) # 80000592 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000586:	4785                	li	a5,1
    80000588:	00009717          	auipc	a4,0x9
    8000058c:	a6f72c23          	sw	a5,-1416(a4) # 80009000 <panicked>
  for(;;)
    80000590:	a001                	j	80000590 <panic+0x48>

0000000080000592 <printf>:
{
    80000592:	7131                	addi	sp,sp,-192
    80000594:	fc86                	sd	ra,120(sp)
    80000596:	f8a2                	sd	s0,112(sp)
    80000598:	f4a6                	sd	s1,104(sp)
    8000059a:	f0ca                	sd	s2,96(sp)
    8000059c:	ecce                	sd	s3,88(sp)
    8000059e:	e8d2                	sd	s4,80(sp)
    800005a0:	e4d6                	sd	s5,72(sp)
    800005a2:	e0da                	sd	s6,64(sp)
    800005a4:	fc5e                	sd	s7,56(sp)
    800005a6:	f862                	sd	s8,48(sp)
    800005a8:	f466                	sd	s9,40(sp)
    800005aa:	f06a                	sd	s10,32(sp)
    800005ac:	ec6e                	sd	s11,24(sp)
    800005ae:	0100                	addi	s0,sp,128
    800005b0:	8a2a                	mv	s4,a0
    800005b2:	e40c                	sd	a1,8(s0)
    800005b4:	e810                	sd	a2,16(s0)
    800005b6:	ec14                	sd	a3,24(s0)
    800005b8:	f018                	sd	a4,32(s0)
    800005ba:	f41c                	sd	a5,40(s0)
    800005bc:	03043823          	sd	a6,48(s0)
    800005c0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c4:	00011d97          	auipc	s11,0x11
    800005c8:	32cdad83          	lw	s11,812(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005cc:	020d9b63          	bnez	s11,80000602 <printf+0x70>
  if (fmt == 0)
    800005d0:	040a0263          	beqz	s4,80000614 <printf+0x82>
  va_start(ap, fmt);
    800005d4:	00840793          	addi	a5,s0,8
    800005d8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005dc:	000a4503          	lbu	a0,0(s4)
    800005e0:	16050263          	beqz	a0,80000744 <printf+0x1b2>
    800005e4:	4481                	li	s1,0
    if(c != '%'){
    800005e6:	02500a93          	li	s5,37
    switch(c){
    800005ea:	07000b13          	li	s6,112
  consputc('x');
    800005ee:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f0:	00008b97          	auipc	s7,0x8
    800005f4:	a50b8b93          	addi	s7,s7,-1456 # 80008040 <digits>
    switch(c){
    800005f8:	07300c93          	li	s9,115
    800005fc:	06400c13          	li	s8,100
    80000600:	a82d                	j	8000063a <printf+0xa8>
    acquire(&pr.lock);
    80000602:	00011517          	auipc	a0,0x11
    80000606:	2d650513          	addi	a0,a0,726 # 800118d8 <pr>
    8000060a:	00000097          	auipc	ra,0x0
    8000060e:	658080e7          	jalr	1624(ra) # 80000c62 <acquire>
    80000612:	bf7d                	j	800005d0 <printf+0x3e>
    panic("null fmt");
    80000614:	00008517          	auipc	a0,0x8
    80000618:	a1450513          	addi	a0,a0,-1516 # 80008028 <etext+0x28>
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	f2c080e7          	jalr	-212(ra) # 80000548 <panic>
      consputc(c);
    80000624:	00000097          	auipc	ra,0x0
    80000628:	c62080e7          	jalr	-926(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062c:	2485                	addiw	s1,s1,1
    8000062e:	009a07b3          	add	a5,s4,s1
    80000632:	0007c503          	lbu	a0,0(a5)
    80000636:	10050763          	beqz	a0,80000744 <printf+0x1b2>
    if(c != '%'){
    8000063a:	ff5515e3          	bne	a0,s5,80000624 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063e:	2485                	addiw	s1,s1,1
    80000640:	009a07b3          	add	a5,s4,s1
    80000644:	0007c783          	lbu	a5,0(a5)
    80000648:	0007891b          	sext.w	s2,a5
    if(c == 0)
    8000064c:	cfe5                	beqz	a5,80000744 <printf+0x1b2>
    switch(c){
    8000064e:	05678a63          	beq	a5,s6,800006a2 <printf+0x110>
    80000652:	02fb7663          	bgeu	s6,a5,8000067e <printf+0xec>
    80000656:	09978963          	beq	a5,s9,800006e8 <printf+0x156>
    8000065a:	07800713          	li	a4,120
    8000065e:	0ce79863          	bne	a5,a4,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000662:	f8843783          	ld	a5,-120(s0)
    80000666:	00878713          	addi	a4,a5,8
    8000066a:	f8e43423          	sd	a4,-120(s0)
    8000066e:	4605                	li	a2,1
    80000670:	85ea                	mv	a1,s10
    80000672:	4388                	lw	a0,0(a5)
    80000674:	00000097          	auipc	ra,0x0
    80000678:	e32080e7          	jalr	-462(ra) # 800004a6 <printint>
      break;
    8000067c:	bf45                	j	8000062c <printf+0x9a>
    switch(c){
    8000067e:	0b578263          	beq	a5,s5,80000722 <printf+0x190>
    80000682:	0b879663          	bne	a5,s8,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000686:	f8843783          	ld	a5,-120(s0)
    8000068a:	00878713          	addi	a4,a5,8
    8000068e:	f8e43423          	sd	a4,-120(s0)
    80000692:	4605                	li	a2,1
    80000694:	45a9                	li	a1,10
    80000696:	4388                	lw	a0,0(a5)
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	e0e080e7          	jalr	-498(ra) # 800004a6 <printint>
      break;
    800006a0:	b771                	j	8000062c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a2:	f8843783          	ld	a5,-120(s0)
    800006a6:	00878713          	addi	a4,a5,8
    800006aa:	f8e43423          	sd	a4,-120(s0)
    800006ae:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006b2:	03000513          	li	a0,48
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bd0080e7          	jalr	-1072(ra) # 80000286 <consputc>
  consputc('x');
    800006be:	07800513          	li	a0,120
    800006c2:	00000097          	auipc	ra,0x0
    800006c6:	bc4080e7          	jalr	-1084(ra) # 80000286 <consputc>
    800006ca:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006cc:	03c9d793          	srli	a5,s3,0x3c
    800006d0:	97de                	add	a5,a5,s7
    800006d2:	0007c503          	lbu	a0,0(a5)
    800006d6:	00000097          	auipc	ra,0x0
    800006da:	bb0080e7          	jalr	-1104(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006de:	0992                	slli	s3,s3,0x4
    800006e0:	397d                	addiw	s2,s2,-1
    800006e2:	fe0915e3          	bnez	s2,800006cc <printf+0x13a>
    800006e6:	b799                	j	8000062c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	0007b903          	ld	s2,0(a5)
    800006f8:	00090e63          	beqz	s2,80000714 <printf+0x182>
      for(; *s; s++)
    800006fc:	00094503          	lbu	a0,0(s2)
    80000700:	d515                	beqz	a0,8000062c <printf+0x9a>
        consputc(*s);
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b84080e7          	jalr	-1148(ra) # 80000286 <consputc>
      for(; *s; s++)
    8000070a:	0905                	addi	s2,s2,1
    8000070c:	00094503          	lbu	a0,0(s2)
    80000710:	f96d                	bnez	a0,80000702 <printf+0x170>
    80000712:	bf29                	j	8000062c <printf+0x9a>
        s = "(null)";
    80000714:	00008917          	auipc	s2,0x8
    80000718:	90c90913          	addi	s2,s2,-1780 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000071c:	02800513          	li	a0,40
    80000720:	b7cd                	j	80000702 <printf+0x170>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b62080e7          	jalr	-1182(ra) # 80000286 <consputc>
      break;
    8000072c:	b701                	j	8000062c <printf+0x9a>
      consputc('%');
    8000072e:	8556                	mv	a0,s5
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b56080e7          	jalr	-1194(ra) # 80000286 <consputc>
      consputc(c);
    80000738:	854a                	mv	a0,s2
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	b4c080e7          	jalr	-1204(ra) # 80000286 <consputc>
      break;
    80000742:	b5ed                	j	8000062c <printf+0x9a>
  if(locking)
    80000744:	020d9163          	bnez	s11,80000766 <printf+0x1d4>
}
    80000748:	70e6                	ld	ra,120(sp)
    8000074a:	7446                	ld	s0,112(sp)
    8000074c:	74a6                	ld	s1,104(sp)
    8000074e:	7906                	ld	s2,96(sp)
    80000750:	69e6                	ld	s3,88(sp)
    80000752:	6a46                	ld	s4,80(sp)
    80000754:	6aa6                	ld	s5,72(sp)
    80000756:	6b06                	ld	s6,64(sp)
    80000758:	7be2                	ld	s7,56(sp)
    8000075a:	7c42                	ld	s8,48(sp)
    8000075c:	7ca2                	ld	s9,40(sp)
    8000075e:	7d02                	ld	s10,32(sp)
    80000760:	6de2                	ld	s11,24(sp)
    80000762:	6129                	addi	sp,sp,192
    80000764:	8082                	ret
    release(&pr.lock);
    80000766:	00011517          	auipc	a0,0x11
    8000076a:	17250513          	addi	a0,a0,370 # 800118d8 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	5a8080e7          	jalr	1448(ra) # 80000d16 <release>
}
    80000776:	bfc9                	j	80000748 <printf+0x1b6>

0000000080000778 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000778:	1101                	addi	sp,sp,-32
    8000077a:	ec06                	sd	ra,24(sp)
    8000077c:	e822                	sd	s0,16(sp)
    8000077e:	e426                	sd	s1,8(sp)
    80000780:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000782:	00011497          	auipc	s1,0x11
    80000786:	15648493          	addi	s1,s1,342 # 800118d8 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	8ae58593          	addi	a1,a1,-1874 # 80008038 <etext+0x38>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	43e080e7          	jalr	1086(ra) # 80000bd2 <initlock>
  pr.locking = 1;
    8000079c:	4785                	li	a5,1
    8000079e:	cc9c                	sw	a5,24(s1)
}
    800007a0:	60e2                	ld	ra,24(sp)
    800007a2:	6442                	ld	s0,16(sp)
    800007a4:	64a2                	ld	s1,8(sp)
    800007a6:	6105                	addi	sp,sp,32
    800007a8:	8082                	ret

00000000800007aa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007aa:	1141                	addi	sp,sp,-16
    800007ac:	e406                	sd	ra,8(sp)
    800007ae:	e022                	sd	s0,0(sp)
    800007b0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b2:	100007b7          	lui	a5,0x10000
    800007b6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ba:	f8000713          	li	a4,-128
    800007be:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c2:	470d                	li	a4,3
    800007c4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007cc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d0:	469d                	li	a3,7
    800007d2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007da:	00008597          	auipc	a1,0x8
    800007de:	87e58593          	addi	a1,a1,-1922 # 80008058 <digits+0x18>
    800007e2:	00011517          	auipc	a0,0x11
    800007e6:	11650513          	addi	a0,a0,278 # 800118f8 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	3e8080e7          	jalr	1000(ra) # 80000bd2 <initlock>
}
    800007f2:	60a2                	ld	ra,8(sp)
    800007f4:	6402                	ld	s0,0(sp)
    800007f6:	0141                	addi	sp,sp,16
    800007f8:	8082                	ret

00000000800007fa <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fa:	1101                	addi	sp,sp,-32
    800007fc:	ec06                	sd	ra,24(sp)
    800007fe:	e822                	sd	s0,16(sp)
    80000800:	e426                	sd	s1,8(sp)
    80000802:	1000                	addi	s0,sp,32
    80000804:	84aa                	mv	s1,a0
  push_off();
    80000806:	00000097          	auipc	ra,0x0
    8000080a:	410080e7          	jalr	1040(ra) # 80000c16 <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	7f27a783          	lw	a5,2034(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081a:	c391                	beqz	a5,8000081e <uartputc_sync+0x24>
    for(;;)
    8000081c:	a001                	j	8000081c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000822:	0ff7f793          	andi	a5,a5,255
    80000826:	0207f793          	andi	a5,a5,32
    8000082a:	dbf5                	beqz	a5,8000081e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000082c:	0ff4f793          	andi	a5,s1,255
    80000830:	10000737          	lui	a4,0x10000
    80000834:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000838:	00000097          	auipc	ra,0x0
    8000083c:	47e080e7          	jalr	1150(ra) # 80000cb6 <pop_off>
}
    80000840:	60e2                	ld	ra,24(sp)
    80000842:	6442                	ld	s0,16(sp)
    80000844:	64a2                	ld	s1,8(sp)
    80000846:	6105                	addi	sp,sp,32
    80000848:	8082                	ret

000000008000084a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000084a:	00008797          	auipc	a5,0x8
    8000084e:	7ba7a783          	lw	a5,1978(a5) # 80009004 <uart_tx_r>
    80000852:	00008717          	auipc	a4,0x8
    80000856:	7b672703          	lw	a4,1974(a4) # 80009008 <uart_tx_w>
    8000085a:	08f70263          	beq	a4,a5,800008de <uartstart+0x94>
{
    8000085e:	7139                	addi	sp,sp,-64
    80000860:	fc06                	sd	ra,56(sp)
    80000862:	f822                	sd	s0,48(sp)
    80000864:	f426                	sd	s1,40(sp)
    80000866:	f04a                	sd	s2,32(sp)
    80000868:	ec4e                	sd	s3,24(sp)
    8000086a:	e852                	sd	s4,16(sp)
    8000086c:	e456                	sd	s5,8(sp)
    8000086e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000870:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000874:	00011a17          	auipc	s4,0x11
    80000878:	084a0a13          	addi	s4,s4,132 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000087c:	00008497          	auipc	s1,0x8
    80000880:	78848493          	addi	s1,s1,1928 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000884:	00008997          	auipc	s3,0x8
    80000888:	78498993          	addi	s3,s3,1924 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000088c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000890:	0ff77713          	andi	a4,a4,255
    80000894:	02077713          	andi	a4,a4,32
    80000898:	cb15                	beqz	a4,800008cc <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    8000089a:	00fa0733          	add	a4,s4,a5
    8000089e:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008a2:	2785                	addiw	a5,a5,1
    800008a4:	41f7d71b          	sraiw	a4,a5,0x1f
    800008a8:	01b7571b          	srliw	a4,a4,0x1b
    800008ac:	9fb9                	addw	a5,a5,a4
    800008ae:	8bfd                	andi	a5,a5,31
    800008b0:	9f99                	subw	a5,a5,a4
    800008b2:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008b4:	8526                	mv	a0,s1
    800008b6:	00002097          	auipc	ra,0x2
    800008ba:	b14080e7          	jalr	-1260(ra) # 800023ca <wakeup>
    
    WriteReg(THR, c);
    800008be:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008c2:	409c                	lw	a5,0(s1)
    800008c4:	0009a703          	lw	a4,0(s3)
    800008c8:	fcf712e3          	bne	a4,a5,8000088c <uartstart+0x42>
  }
}
    800008cc:	70e2                	ld	ra,56(sp)
    800008ce:	7442                	ld	s0,48(sp)
    800008d0:	74a2                	ld	s1,40(sp)
    800008d2:	7902                	ld	s2,32(sp)
    800008d4:	69e2                	ld	s3,24(sp)
    800008d6:	6a42                	ld	s4,16(sp)
    800008d8:	6aa2                	ld	s5,8(sp)
    800008da:	6121                	addi	sp,sp,64
    800008dc:	8082                	ret
    800008de:	8082                	ret

00000000800008e0 <uartputc>:
{
    800008e0:	7179                	addi	sp,sp,-48
    800008e2:	f406                	sd	ra,40(sp)
    800008e4:	f022                	sd	s0,32(sp)
    800008e6:	ec26                	sd	s1,24(sp)
    800008e8:	e84a                	sd	s2,16(sp)
    800008ea:	e44e                	sd	s3,8(sp)
    800008ec:	e052                	sd	s4,0(sp)
    800008ee:	1800                	addi	s0,sp,48
    800008f0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008f2:	00011517          	auipc	a0,0x11
    800008f6:	00650513          	addi	a0,a0,6 # 800118f8 <uart_tx_lock>
    800008fa:	00000097          	auipc	ra,0x0
    800008fe:	368080e7          	jalr	872(ra) # 80000c62 <acquire>
  if(panicked){
    80000902:	00008797          	auipc	a5,0x8
    80000906:	6fe7a783          	lw	a5,1790(a5) # 80009000 <panicked>
    8000090a:	c391                	beqz	a5,8000090e <uartputc+0x2e>
    for(;;)
    8000090c:	a001                	j	8000090c <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000090e:	00008717          	auipc	a4,0x8
    80000912:	6fa72703          	lw	a4,1786(a4) # 80009008 <uart_tx_w>
    80000916:	0017079b          	addiw	a5,a4,1
    8000091a:	41f7d69b          	sraiw	a3,a5,0x1f
    8000091e:	01b6d69b          	srliw	a3,a3,0x1b
    80000922:	9fb5                	addw	a5,a5,a3
    80000924:	8bfd                	andi	a5,a5,31
    80000926:	9f95                	subw	a5,a5,a3
    80000928:	00008697          	auipc	a3,0x8
    8000092c:	6dc6a683          	lw	a3,1756(a3) # 80009004 <uart_tx_r>
    80000930:	04f69263          	bne	a3,a5,80000974 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000934:	00011a17          	auipc	s4,0x11
    80000938:	fc4a0a13          	addi	s4,s4,-60 # 800118f8 <uart_tx_lock>
    8000093c:	00008497          	auipc	s1,0x8
    80000940:	6c848493          	addi	s1,s1,1736 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	00008917          	auipc	s2,0x8
    80000948:	6c490913          	addi	s2,s2,1732 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000094c:	85d2                	mv	a1,s4
    8000094e:	8526                	mv	a0,s1
    80000950:	00002097          	auipc	ra,0x2
    80000954:	8f4080e7          	jalr	-1804(ra) # 80002244 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000958:	00092703          	lw	a4,0(s2)
    8000095c:	0017079b          	addiw	a5,a4,1
    80000960:	41f7d69b          	sraiw	a3,a5,0x1f
    80000964:	01b6d69b          	srliw	a3,a3,0x1b
    80000968:	9fb5                	addw	a5,a5,a3
    8000096a:	8bfd                	andi	a5,a5,31
    8000096c:	9f95                	subw	a5,a5,a3
    8000096e:	4094                	lw	a3,0(s1)
    80000970:	fcf68ee3          	beq	a3,a5,8000094c <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000974:	00011497          	auipc	s1,0x11
    80000978:	f8448493          	addi	s1,s1,-124 # 800118f8 <uart_tx_lock>
    8000097c:	9726                	add	a4,a4,s1
    8000097e:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000982:	00008717          	auipc	a4,0x8
    80000986:	68f72323          	sw	a5,1670(a4) # 80009008 <uart_tx_w>
      uartstart();
    8000098a:	00000097          	auipc	ra,0x0
    8000098e:	ec0080e7          	jalr	-320(ra) # 8000084a <uartstart>
      release(&uart_tx_lock);
    80000992:	8526                	mv	a0,s1
    80000994:	00000097          	auipc	ra,0x0
    80000998:	382080e7          	jalr	898(ra) # 80000d16 <release>
}
    8000099c:	70a2                	ld	ra,40(sp)
    8000099e:	7402                	ld	s0,32(sp)
    800009a0:	64e2                	ld	s1,24(sp)
    800009a2:	6942                	ld	s2,16(sp)
    800009a4:	69a2                	ld	s3,8(sp)
    800009a6:	6a02                	ld	s4,0(sp)
    800009a8:	6145                	addi	sp,sp,48
    800009aa:	8082                	ret

00000000800009ac <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009ac:	1141                	addi	sp,sp,-16
    800009ae:	e422                	sd	s0,8(sp)
    800009b0:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009b2:	100007b7          	lui	a5,0x10000
    800009b6:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009ba:	8b85                	andi	a5,a5,1
    800009bc:	cb91                	beqz	a5,800009d0 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009be:	100007b7          	lui	a5,0x10000
    800009c2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009c6:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009ca:	6422                	ld	s0,8(sp)
    800009cc:	0141                	addi	sp,sp,16
    800009ce:	8082                	ret
    return -1;
    800009d0:	557d                	li	a0,-1
    800009d2:	bfe5                	j	800009ca <uartgetc+0x1e>

00000000800009d4 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009d4:	1101                	addi	sp,sp,-32
    800009d6:	ec06                	sd	ra,24(sp)
    800009d8:	e822                	sd	s0,16(sp)
    800009da:	e426                	sd	s1,8(sp)
    800009dc:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009de:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e0:	00000097          	auipc	ra,0x0
    800009e4:	fcc080e7          	jalr	-52(ra) # 800009ac <uartgetc>
    if(c == -1)
    800009e8:	00950763          	beq	a0,s1,800009f6 <uartintr+0x22>
      break;
    consoleintr(c);
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	8dc080e7          	jalr	-1828(ra) # 800002c8 <consoleintr>
  while(1){
    800009f4:	b7f5                	j	800009e0 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009f6:	00011497          	auipc	s1,0x11
    800009fa:	f0248493          	addi	s1,s1,-254 # 800118f8 <uart_tx_lock>
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	262080e7          	jalr	610(ra) # 80000c62 <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	304080e7          	jalr	772(ra) # 80000d16 <release>
}
    80000a1a:	60e2                	ld	ra,24(sp)
    80000a1c:	6442                	ld	s0,16(sp)
    80000a1e:	64a2                	ld	s1,8(sp)
    80000a20:	6105                	addi	sp,sp,32
    80000a22:	8082                	ret

0000000080000a24 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a24:	1101                	addi	sp,sp,-32
    80000a26:	ec06                	sd	ra,24(sp)
    80000a28:	e822                	sd	s0,16(sp)
    80000a2a:	e426                	sd	s1,8(sp)
    80000a2c:	e04a                	sd	s2,0(sp)
    80000a2e:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a30:	03451793          	slli	a5,a0,0x34
    80000a34:	ebb9                	bnez	a5,80000a8a <kfree+0x66>
    80000a36:	84aa                	mv	s1,a0
    80000a38:	00025797          	auipc	a5,0x25
    80000a3c:	5c878793          	addi	a5,a5,1480 # 80026000 <end>
    80000a40:	04f56563          	bltu	a0,a5,80000a8a <kfree+0x66>
    80000a44:	47c5                	li	a5,17
    80000a46:	07ee                	slli	a5,a5,0x1b
    80000a48:	04f57163          	bgeu	a0,a5,80000a8a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a4c:	6605                	lui	a2,0x1
    80000a4e:	4585                	li	a1,1
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	30e080e7          	jalr	782(ra) # 80000d5e <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a58:	00011917          	auipc	s2,0x11
    80000a5c:	ed890913          	addi	s2,s2,-296 # 80011930 <kmem>
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	200080e7          	jalr	512(ra) # 80000c62 <acquire>
  r->next = kmem.freelist;
    80000a6a:	01893783          	ld	a5,24(s2)
    80000a6e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a70:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a74:	854a                	mv	a0,s2
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	2a0080e7          	jalr	672(ra) # 80000d16 <release>
}
    80000a7e:	60e2                	ld	ra,24(sp)
    80000a80:	6442                	ld	s0,16(sp)
    80000a82:	64a2                	ld	s1,8(sp)
    80000a84:	6902                	ld	s2,0(sp)
    80000a86:	6105                	addi	sp,sp,32
    80000a88:	8082                	ret
    panic("kfree");
    80000a8a:	00007517          	auipc	a0,0x7
    80000a8e:	5d650513          	addi	a0,a0,1494 # 80008060 <digits+0x20>
    80000a92:	00000097          	auipc	ra,0x0
    80000a96:	ab6080e7          	jalr	-1354(ra) # 80000548 <panic>

0000000080000a9a <freerange>:
{
    80000a9a:	7179                	addi	sp,sp,-48
    80000a9c:	f406                	sd	ra,40(sp)
    80000a9e:	f022                	sd	s0,32(sp)
    80000aa0:	ec26                	sd	s1,24(sp)
    80000aa2:	e84a                	sd	s2,16(sp)
    80000aa4:	e44e                	sd	s3,8(sp)
    80000aa6:	e052                	sd	s4,0(sp)
    80000aa8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aaa:	6785                	lui	a5,0x1
    80000aac:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ab0:	94aa                	add	s1,s1,a0
    80000ab2:	757d                	lui	a0,0xfffff
    80000ab4:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab6:	94be                	add	s1,s1,a5
    80000ab8:	0095ee63          	bltu	a1,s1,80000ad4 <freerange+0x3a>
    80000abc:	892e                	mv	s2,a1
    kfree(p);
    80000abe:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac0:	6985                	lui	s3,0x1
    kfree(p);
    80000ac2:	01448533          	add	a0,s1,s4
    80000ac6:	00000097          	auipc	ra,0x0
    80000aca:	f5e080e7          	jalr	-162(ra) # 80000a24 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ace:	94ce                	add	s1,s1,s3
    80000ad0:	fe9979e3          	bgeu	s2,s1,80000ac2 <freerange+0x28>
}
    80000ad4:	70a2                	ld	ra,40(sp)
    80000ad6:	7402                	ld	s0,32(sp)
    80000ad8:	64e2                	ld	s1,24(sp)
    80000ada:	6942                	ld	s2,16(sp)
    80000adc:	69a2                	ld	s3,8(sp)
    80000ade:	6a02                	ld	s4,0(sp)
    80000ae0:	6145                	addi	sp,sp,48
    80000ae2:	8082                	ret

0000000080000ae4 <kinit>:
{
    80000ae4:	1141                	addi	sp,sp,-16
    80000ae6:	e406                	sd	ra,8(sp)
    80000ae8:	e022                	sd	s0,0(sp)
    80000aea:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aec:	00007597          	auipc	a1,0x7
    80000af0:	57c58593          	addi	a1,a1,1404 # 80008068 <digits+0x28>
    80000af4:	00011517          	auipc	a0,0x11
    80000af8:	e3c50513          	addi	a0,a0,-452 # 80011930 <kmem>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	0d6080e7          	jalr	214(ra) # 80000bd2 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b04:	45c5                	li	a1,17
    80000b06:	05ee                	slli	a1,a1,0x1b
    80000b08:	00025517          	auipc	a0,0x25
    80000b0c:	4f850513          	addi	a0,a0,1272 # 80026000 <end>
    80000b10:	00000097          	auipc	ra,0x0
    80000b14:	f8a080e7          	jalr	-118(ra) # 80000a9a <freerange>
}
    80000b18:	60a2                	ld	ra,8(sp)
    80000b1a:	6402                	ld	s0,0(sp)
    80000b1c:	0141                	addi	sp,sp,16
    80000b1e:	8082                	ret

0000000080000b20 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b20:	1101                	addi	sp,sp,-32
    80000b22:	ec06                	sd	ra,24(sp)
    80000b24:	e822                	sd	s0,16(sp)
    80000b26:	e426                	sd	s1,8(sp)
    80000b28:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b2a:	00011497          	auipc	s1,0x11
    80000b2e:	e0648493          	addi	s1,s1,-506 # 80011930 <kmem>
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	12e080e7          	jalr	302(ra) # 80000c62 <acquire>
  r = kmem.freelist;
    80000b3c:	6c84                	ld	s1,24(s1)
  if(r)
    80000b3e:	c885                	beqz	s1,80000b6e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b40:	609c                	ld	a5,0(s1)
    80000b42:	00011517          	auipc	a0,0x11
    80000b46:	dee50513          	addi	a0,a0,-530 # 80011930 <kmem>
    80000b4a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	1ca080e7          	jalr	458(ra) # 80000d16 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b54:	6605                	lui	a2,0x1
    80000b56:	4595                	li	a1,5
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	204080e7          	jalr	516(ra) # 80000d5e <memset>
  return (void*)r;
}
    80000b62:	8526                	mv	a0,s1
    80000b64:	60e2                	ld	ra,24(sp)
    80000b66:	6442                	ld	s0,16(sp)
    80000b68:	64a2                	ld	s1,8(sp)
    80000b6a:	6105                	addi	sp,sp,32
    80000b6c:	8082                	ret
  release(&kmem.lock);
    80000b6e:	00011517          	auipc	a0,0x11
    80000b72:	dc250513          	addi	a0,a0,-574 # 80011930 <kmem>
    80000b76:	00000097          	auipc	ra,0x0
    80000b7a:	1a0080e7          	jalr	416(ra) # 80000d16 <release>
  if(r)
    80000b7e:	b7d5                	j	80000b62 <kalloc+0x42>

0000000080000b80 <freememory>:

//Collect the amount of free memory.
//Get the memory size in bytes.
void freememory(uint64 *bytes)
{
    80000b80:	1101                	addi	sp,sp,-32
    80000b82:	ec06                	sd	ra,24(sp)
    80000b84:	e822                	sd	s0,16(sp)
    80000b86:	e426                	sd	s1,8(sp)
    80000b88:	e04a                	sd	s2,0(sp)
    80000b8a:	1000                	addi	s0,sp,32
    80000b8c:	84aa                	mv	s1,a0
  struct run *r;
  (*bytes)=0;
    80000b8e:	00053023          	sd	zero,0(a0)
  acquire(&kmem.lock);
    80000b92:	00011917          	auipc	s2,0x11
    80000b96:	d9e90913          	addi	s2,s2,-610 # 80011930 <kmem>
    80000b9a:	854a                	mv	a0,s2
    80000b9c:	00000097          	auipc	ra,0x0
    80000ba0:	0c6080e7          	jalr	198(ra) # 80000c62 <acquire>
  r= kmem.freelist;
    80000ba4:	01893703          	ld	a4,24(s2)
  while(r>0)
    80000ba8:	c719                	beqz	a4,80000bb6 <freememory+0x36>
  {
    r = r->next;
 //   printf("freememory r:%d\n",r);
    (*bytes) += PGSIZE;
    80000baa:	6685                	lui	a3,0x1
    r = r->next;
    80000bac:	6318                	ld	a4,0(a4)
    (*bytes) += PGSIZE;
    80000bae:	609c                	ld	a5,0(s1)
    80000bb0:	97b6                	add	a5,a5,a3
    80000bb2:	e09c                	sd	a5,0(s1)
  while(r>0)
    80000bb4:	ff65                	bnez	a4,80000bac <freememory+0x2c>
  }
  release(&kmem.lock);
    80000bb6:	00011517          	auipc	a0,0x11
    80000bba:	d7a50513          	addi	a0,a0,-646 # 80011930 <kmem>
    80000bbe:	00000097          	auipc	ra,0x0
    80000bc2:	158080e7          	jalr	344(ra) # 80000d16 <release>
  return ;
    80000bc6:	60e2                	ld	ra,24(sp)
    80000bc8:	6442                	ld	s0,16(sp)
    80000bca:	64a2                	ld	s1,8(sp)
    80000bcc:	6902                	ld	s2,0(sp)
    80000bce:	6105                	addi	sp,sp,32
    80000bd0:	8082                	ret

0000000080000bd2 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bd2:	1141                	addi	sp,sp,-16
    80000bd4:	e422                	sd	s0,8(sp)
    80000bd6:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bd8:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bda:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bde:	00053823          	sd	zero,16(a0)
}
    80000be2:	6422                	ld	s0,8(sp)
    80000be4:	0141                	addi	sp,sp,16
    80000be6:	8082                	ret

0000000080000be8 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000be8:	411c                	lw	a5,0(a0)
    80000bea:	e399                	bnez	a5,80000bf0 <holding+0x8>
    80000bec:	4501                	li	a0,0
  return r;
}
    80000bee:	8082                	ret
{
    80000bf0:	1101                	addi	sp,sp,-32
    80000bf2:	ec06                	sd	ra,24(sp)
    80000bf4:	e822                	sd	s0,16(sp)
    80000bf6:	e426                	sd	s1,8(sp)
    80000bf8:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bfa:	6904                	ld	s1,16(a0)
    80000bfc:	00001097          	auipc	ra,0x1
    80000c00:	e18080e7          	jalr	-488(ra) # 80001a14 <mycpu>
    80000c04:	40a48533          	sub	a0,s1,a0
    80000c08:	00153513          	seqz	a0,a0
}
    80000c0c:	60e2                	ld	ra,24(sp)
    80000c0e:	6442                	ld	s0,16(sp)
    80000c10:	64a2                	ld	s1,8(sp)
    80000c12:	6105                	addi	sp,sp,32
    80000c14:	8082                	ret

0000000080000c16 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c16:	1101                	addi	sp,sp,-32
    80000c18:	ec06                	sd	ra,24(sp)
    80000c1a:	e822                	sd	s0,16(sp)
    80000c1c:	e426                	sd	s1,8(sp)
    80000c1e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c20:	100024f3          	csrr	s1,sstatus
    80000c24:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c28:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c2a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c2e:	00001097          	auipc	ra,0x1
    80000c32:	de6080e7          	jalr	-538(ra) # 80001a14 <mycpu>
    80000c36:	5d3c                	lw	a5,120(a0)
    80000c38:	cf89                	beqz	a5,80000c52 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c3a:	00001097          	auipc	ra,0x1
    80000c3e:	dda080e7          	jalr	-550(ra) # 80001a14 <mycpu>
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	2785                	addiw	a5,a5,1
    80000c46:	dd3c                	sw	a5,120(a0)
}
    80000c48:	60e2                	ld	ra,24(sp)
    80000c4a:	6442                	ld	s0,16(sp)
    80000c4c:	64a2                	ld	s1,8(sp)
    80000c4e:	6105                	addi	sp,sp,32
    80000c50:	8082                	ret
    mycpu()->intena = old;
    80000c52:	00001097          	auipc	ra,0x1
    80000c56:	dc2080e7          	jalr	-574(ra) # 80001a14 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c5a:	8085                	srli	s1,s1,0x1
    80000c5c:	8885                	andi	s1,s1,1
    80000c5e:	dd64                	sw	s1,124(a0)
    80000c60:	bfe9                	j	80000c3a <push_off+0x24>

0000000080000c62 <acquire>:
{
    80000c62:	1101                	addi	sp,sp,-32
    80000c64:	ec06                	sd	ra,24(sp)
    80000c66:	e822                	sd	s0,16(sp)
    80000c68:	e426                	sd	s1,8(sp)
    80000c6a:	1000                	addi	s0,sp,32
    80000c6c:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	fa8080e7          	jalr	-88(ra) # 80000c16 <push_off>
  if(holding(lk))
    80000c76:	8526                	mv	a0,s1
    80000c78:	00000097          	auipc	ra,0x0
    80000c7c:	f70080e7          	jalr	-144(ra) # 80000be8 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c80:	4705                	li	a4,1
  if(holding(lk))
    80000c82:	e115                	bnez	a0,80000ca6 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c84:	87ba                	mv	a5,a4
    80000c86:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c8a:	2781                	sext.w	a5,a5
    80000c8c:	ffe5                	bnez	a5,80000c84 <acquire+0x22>
  __sync_synchronize();
    80000c8e:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c92:	00001097          	auipc	ra,0x1
    80000c96:	d82080e7          	jalr	-638(ra) # 80001a14 <mycpu>
    80000c9a:	e888                	sd	a0,16(s1)
}
    80000c9c:	60e2                	ld	ra,24(sp)
    80000c9e:	6442                	ld	s0,16(sp)
    80000ca0:	64a2                	ld	s1,8(sp)
    80000ca2:	6105                	addi	sp,sp,32
    80000ca4:	8082                	ret
    panic("acquire");
    80000ca6:	00007517          	auipc	a0,0x7
    80000caa:	3ca50513          	addi	a0,a0,970 # 80008070 <digits+0x30>
    80000cae:	00000097          	auipc	ra,0x0
    80000cb2:	89a080e7          	jalr	-1894(ra) # 80000548 <panic>

0000000080000cb6 <pop_off>:

void
pop_off(void)
{
    80000cb6:	1141                	addi	sp,sp,-16
    80000cb8:	e406                	sd	ra,8(sp)
    80000cba:	e022                	sd	s0,0(sp)
    80000cbc:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cbe:	00001097          	auipc	ra,0x1
    80000cc2:	d56080e7          	jalr	-682(ra) # 80001a14 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cc6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cca:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000ccc:	e78d                	bnez	a5,80000cf6 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cce:	5d3c                	lw	a5,120(a0)
    80000cd0:	02f05b63          	blez	a5,80000d06 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000cd4:	37fd                	addiw	a5,a5,-1
    80000cd6:	0007871b          	sext.w	a4,a5
    80000cda:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cdc:	eb09                	bnez	a4,80000cee <pop_off+0x38>
    80000cde:	5d7c                	lw	a5,124(a0)
    80000ce0:	c799                	beqz	a5,80000cee <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ce2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000ce6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cea:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cee:	60a2                	ld	ra,8(sp)
    80000cf0:	6402                	ld	s0,0(sp)
    80000cf2:	0141                	addi	sp,sp,16
    80000cf4:	8082                	ret
    panic("pop_off - interruptible");
    80000cf6:	00007517          	auipc	a0,0x7
    80000cfa:	38250513          	addi	a0,a0,898 # 80008078 <digits+0x38>
    80000cfe:	00000097          	auipc	ra,0x0
    80000d02:	84a080e7          	jalr	-1974(ra) # 80000548 <panic>
    panic("pop_off");
    80000d06:	00007517          	auipc	a0,0x7
    80000d0a:	38a50513          	addi	a0,a0,906 # 80008090 <digits+0x50>
    80000d0e:	00000097          	auipc	ra,0x0
    80000d12:	83a080e7          	jalr	-1990(ra) # 80000548 <panic>

0000000080000d16 <release>:
{
    80000d16:	1101                	addi	sp,sp,-32
    80000d18:	ec06                	sd	ra,24(sp)
    80000d1a:	e822                	sd	s0,16(sp)
    80000d1c:	e426                	sd	s1,8(sp)
    80000d1e:	1000                	addi	s0,sp,32
    80000d20:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d22:	00000097          	auipc	ra,0x0
    80000d26:	ec6080e7          	jalr	-314(ra) # 80000be8 <holding>
    80000d2a:	c115                	beqz	a0,80000d4e <release+0x38>
  lk->cpu = 0;
    80000d2c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d30:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d34:	0f50000f          	fence	iorw,ow
    80000d38:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d3c:	00000097          	auipc	ra,0x0
    80000d40:	f7a080e7          	jalr	-134(ra) # 80000cb6 <pop_off>
}
    80000d44:	60e2                	ld	ra,24(sp)
    80000d46:	6442                	ld	s0,16(sp)
    80000d48:	64a2                	ld	s1,8(sp)
    80000d4a:	6105                	addi	sp,sp,32
    80000d4c:	8082                	ret
    panic("release");
    80000d4e:	00007517          	auipc	a0,0x7
    80000d52:	34a50513          	addi	a0,a0,842 # 80008098 <digits+0x58>
    80000d56:	fffff097          	auipc	ra,0xfffff
    80000d5a:	7f2080e7          	jalr	2034(ra) # 80000548 <panic>

0000000080000d5e <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d5e:	1141                	addi	sp,sp,-16
    80000d60:	e422                	sd	s0,8(sp)
    80000d62:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d64:	ce09                	beqz	a2,80000d7e <memset+0x20>
    80000d66:	87aa                	mv	a5,a0
    80000d68:	fff6071b          	addiw	a4,a2,-1
    80000d6c:	1702                	slli	a4,a4,0x20
    80000d6e:	9301                	srli	a4,a4,0x20
    80000d70:	0705                	addi	a4,a4,1
    80000d72:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d74:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d78:	0785                	addi	a5,a5,1
    80000d7a:	fee79de3          	bne	a5,a4,80000d74 <memset+0x16>
  }
  return dst;
}
    80000d7e:	6422                	ld	s0,8(sp)
    80000d80:	0141                	addi	sp,sp,16
    80000d82:	8082                	ret

0000000080000d84 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d84:	1141                	addi	sp,sp,-16
    80000d86:	e422                	sd	s0,8(sp)
    80000d88:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d8a:	ca05                	beqz	a2,80000dba <memcmp+0x36>
    80000d8c:	fff6069b          	addiw	a3,a2,-1
    80000d90:	1682                	slli	a3,a3,0x20
    80000d92:	9281                	srli	a3,a3,0x20
    80000d94:	0685                	addi	a3,a3,1
    80000d96:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d98:	00054783          	lbu	a5,0(a0)
    80000d9c:	0005c703          	lbu	a4,0(a1)
    80000da0:	00e79863          	bne	a5,a4,80000db0 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000da4:	0505                	addi	a0,a0,1
    80000da6:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000da8:	fed518e3          	bne	a0,a3,80000d98 <memcmp+0x14>
  }

  return 0;
    80000dac:	4501                	li	a0,0
    80000dae:	a019                	j	80000db4 <memcmp+0x30>
      return *s1 - *s2;
    80000db0:	40e7853b          	subw	a0,a5,a4
}
    80000db4:	6422                	ld	s0,8(sp)
    80000db6:	0141                	addi	sp,sp,16
    80000db8:	8082                	ret
  return 0;
    80000dba:	4501                	li	a0,0
    80000dbc:	bfe5                	j	80000db4 <memcmp+0x30>

0000000080000dbe <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000dbe:	1141                	addi	sp,sp,-16
    80000dc0:	e422                	sd	s0,8(sp)
    80000dc2:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dc4:	00a5f963          	bgeu	a1,a0,80000dd6 <memmove+0x18>
    80000dc8:	02061713          	slli	a4,a2,0x20
    80000dcc:	9301                	srli	a4,a4,0x20
    80000dce:	00e587b3          	add	a5,a1,a4
    80000dd2:	02f56563          	bltu	a0,a5,80000dfc <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000dd6:	fff6069b          	addiw	a3,a2,-1
    80000dda:	ce11                	beqz	a2,80000df6 <memmove+0x38>
    80000ddc:	1682                	slli	a3,a3,0x20
    80000dde:	9281                	srli	a3,a3,0x20
    80000de0:	0685                	addi	a3,a3,1
    80000de2:	96ae                	add	a3,a3,a1
    80000de4:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000de6:	0585                	addi	a1,a1,1
    80000de8:	0785                	addi	a5,a5,1
    80000dea:	fff5c703          	lbu	a4,-1(a1)
    80000dee:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000df2:	fed59ae3          	bne	a1,a3,80000de6 <memmove+0x28>

  return dst;
}
    80000df6:	6422                	ld	s0,8(sp)
    80000df8:	0141                	addi	sp,sp,16
    80000dfa:	8082                	ret
    d += n;
    80000dfc:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000dfe:	fff6069b          	addiw	a3,a2,-1
    80000e02:	da75                	beqz	a2,80000df6 <memmove+0x38>
    80000e04:	02069613          	slli	a2,a3,0x20
    80000e08:	9201                	srli	a2,a2,0x20
    80000e0a:	fff64613          	not	a2,a2
    80000e0e:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e10:	17fd                	addi	a5,a5,-1
    80000e12:	177d                	addi	a4,a4,-1
    80000e14:	0007c683          	lbu	a3,0(a5)
    80000e18:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000e1c:	fec79ae3          	bne	a5,a2,80000e10 <memmove+0x52>
    80000e20:	bfd9                	j	80000df6 <memmove+0x38>

0000000080000e22 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e22:	1141                	addi	sp,sp,-16
    80000e24:	e406                	sd	ra,8(sp)
    80000e26:	e022                	sd	s0,0(sp)
    80000e28:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e2a:	00000097          	auipc	ra,0x0
    80000e2e:	f94080e7          	jalr	-108(ra) # 80000dbe <memmove>
}
    80000e32:	60a2                	ld	ra,8(sp)
    80000e34:	6402                	ld	s0,0(sp)
    80000e36:	0141                	addi	sp,sp,16
    80000e38:	8082                	ret

0000000080000e3a <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e3a:	1141                	addi	sp,sp,-16
    80000e3c:	e422                	sd	s0,8(sp)
    80000e3e:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e40:	ce11                	beqz	a2,80000e5c <strncmp+0x22>
    80000e42:	00054783          	lbu	a5,0(a0)
    80000e46:	cf89                	beqz	a5,80000e60 <strncmp+0x26>
    80000e48:	0005c703          	lbu	a4,0(a1)
    80000e4c:	00f71a63          	bne	a4,a5,80000e60 <strncmp+0x26>
    n--, p++, q++;
    80000e50:	367d                	addiw	a2,a2,-1
    80000e52:	0505                	addi	a0,a0,1
    80000e54:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e56:	f675                	bnez	a2,80000e42 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e58:	4501                	li	a0,0
    80000e5a:	a809                	j	80000e6c <strncmp+0x32>
    80000e5c:	4501                	li	a0,0
    80000e5e:	a039                	j	80000e6c <strncmp+0x32>
  if(n == 0)
    80000e60:	ca09                	beqz	a2,80000e72 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e62:	00054503          	lbu	a0,0(a0)
    80000e66:	0005c783          	lbu	a5,0(a1)
    80000e6a:	9d1d                	subw	a0,a0,a5
}
    80000e6c:	6422                	ld	s0,8(sp)
    80000e6e:	0141                	addi	sp,sp,16
    80000e70:	8082                	ret
    return 0;
    80000e72:	4501                	li	a0,0
    80000e74:	bfe5                	j	80000e6c <strncmp+0x32>

0000000080000e76 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e76:	1141                	addi	sp,sp,-16
    80000e78:	e422                	sd	s0,8(sp)
    80000e7a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e7c:	872a                	mv	a4,a0
    80000e7e:	8832                	mv	a6,a2
    80000e80:	367d                	addiw	a2,a2,-1
    80000e82:	01005963          	blez	a6,80000e94 <strncpy+0x1e>
    80000e86:	0705                	addi	a4,a4,1
    80000e88:	0005c783          	lbu	a5,0(a1)
    80000e8c:	fef70fa3          	sb	a5,-1(a4)
    80000e90:	0585                	addi	a1,a1,1
    80000e92:	f7f5                	bnez	a5,80000e7e <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e94:	00c05d63          	blez	a2,80000eae <strncpy+0x38>
    80000e98:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e9a:	0685                	addi	a3,a3,1
    80000e9c:	fe068fa3          	sb	zero,-1(a3) # fff <_entry-0x7ffff001>
  while(n-- > 0)
    80000ea0:	fff6c793          	not	a5,a3
    80000ea4:	9fb9                	addw	a5,a5,a4
    80000ea6:	010787bb          	addw	a5,a5,a6
    80000eaa:	fef048e3          	bgtz	a5,80000e9a <strncpy+0x24>
  return os;
}
    80000eae:	6422                	ld	s0,8(sp)
    80000eb0:	0141                	addi	sp,sp,16
    80000eb2:	8082                	ret

0000000080000eb4 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000eb4:	1141                	addi	sp,sp,-16
    80000eb6:	e422                	sd	s0,8(sp)
    80000eb8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000eba:	02c05363          	blez	a2,80000ee0 <safestrcpy+0x2c>
    80000ebe:	fff6069b          	addiw	a3,a2,-1
    80000ec2:	1682                	slli	a3,a3,0x20
    80000ec4:	9281                	srli	a3,a3,0x20
    80000ec6:	96ae                	add	a3,a3,a1
    80000ec8:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000eca:	00d58963          	beq	a1,a3,80000edc <safestrcpy+0x28>
    80000ece:	0585                	addi	a1,a1,1
    80000ed0:	0785                	addi	a5,a5,1
    80000ed2:	fff5c703          	lbu	a4,-1(a1)
    80000ed6:	fee78fa3          	sb	a4,-1(a5)
    80000eda:	fb65                	bnez	a4,80000eca <safestrcpy+0x16>
    ;
  *s = 0;
    80000edc:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ee0:	6422                	ld	s0,8(sp)
    80000ee2:	0141                	addi	sp,sp,16
    80000ee4:	8082                	ret

0000000080000ee6 <strlen>:

int
strlen(const char *s)
{
    80000ee6:	1141                	addi	sp,sp,-16
    80000ee8:	e422                	sd	s0,8(sp)
    80000eea:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000eec:	00054783          	lbu	a5,0(a0)
    80000ef0:	cf91                	beqz	a5,80000f0c <strlen+0x26>
    80000ef2:	0505                	addi	a0,a0,1
    80000ef4:	87aa                	mv	a5,a0
    80000ef6:	4685                	li	a3,1
    80000ef8:	9e89                	subw	a3,a3,a0
    80000efa:	00f6853b          	addw	a0,a3,a5
    80000efe:	0785                	addi	a5,a5,1
    80000f00:	fff7c703          	lbu	a4,-1(a5)
    80000f04:	fb7d                	bnez	a4,80000efa <strlen+0x14>
    ;
  return n;
}
    80000f06:	6422                	ld	s0,8(sp)
    80000f08:	0141                	addi	sp,sp,16
    80000f0a:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f0c:	4501                	li	a0,0
    80000f0e:	bfe5                	j	80000f06 <strlen+0x20>

0000000080000f10 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f10:	1141                	addi	sp,sp,-16
    80000f12:	e406                	sd	ra,8(sp)
    80000f14:	e022                	sd	s0,0(sp)
    80000f16:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f18:	00001097          	auipc	ra,0x1
    80000f1c:	aec080e7          	jalr	-1300(ra) # 80001a04 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f20:	00008717          	auipc	a4,0x8
    80000f24:	0ec70713          	addi	a4,a4,236 # 8000900c <started>
  if(cpuid() == 0){
    80000f28:	c139                	beqz	a0,80000f6e <main+0x5e>
    while(started == 0)
    80000f2a:	431c                	lw	a5,0(a4)
    80000f2c:	2781                	sext.w	a5,a5
    80000f2e:	dff5                	beqz	a5,80000f2a <main+0x1a>
      ;
    __sync_synchronize();
    80000f30:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f34:	00001097          	auipc	ra,0x1
    80000f38:	ad0080e7          	jalr	-1328(ra) # 80001a04 <cpuid>
    80000f3c:	85aa                	mv	a1,a0
    80000f3e:	00007517          	auipc	a0,0x7
    80000f42:	17a50513          	addi	a0,a0,378 # 800080b8 <digits+0x78>
    80000f46:	fffff097          	auipc	ra,0xfffff
    80000f4a:	64c080e7          	jalr	1612(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000f4e:	00000097          	auipc	ra,0x0
    80000f52:	0d8080e7          	jalr	216(ra) # 80001026 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f56:	00001097          	auipc	ra,0x1
    80000f5a:	772080e7          	jalr	1906(ra) # 800026c8 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f5e:	00005097          	auipc	ra,0x5
    80000f62:	dc2080e7          	jalr	-574(ra) # 80005d20 <plicinithart>
  }

  scheduler();        
    80000f66:	00001097          	auipc	ra,0x1
    80000f6a:	002080e7          	jalr	2(ra) # 80001f68 <scheduler>
    consoleinit();
    80000f6e:	fffff097          	auipc	ra,0xfffff
    80000f72:	4ec080e7          	jalr	1260(ra) # 8000045a <consoleinit>
    printfinit();
    80000f76:	00000097          	auipc	ra,0x0
    80000f7a:	802080e7          	jalr	-2046(ra) # 80000778 <printfinit>
    printf("\n");
    80000f7e:	00007517          	auipc	a0,0x7
    80000f82:	14a50513          	addi	a0,a0,330 # 800080c8 <digits+0x88>
    80000f86:	fffff097          	auipc	ra,0xfffff
    80000f8a:	60c080e7          	jalr	1548(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f8e:	00007517          	auipc	a0,0x7
    80000f92:	11250513          	addi	a0,a0,274 # 800080a0 <digits+0x60>
    80000f96:	fffff097          	auipc	ra,0xfffff
    80000f9a:	5fc080e7          	jalr	1532(ra) # 80000592 <printf>
    printf("\n");
    80000f9e:	00007517          	auipc	a0,0x7
    80000fa2:	12a50513          	addi	a0,a0,298 # 800080c8 <digits+0x88>
    80000fa6:	fffff097          	auipc	ra,0xfffff
    80000faa:	5ec080e7          	jalr	1516(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000fae:	00000097          	auipc	ra,0x0
    80000fb2:	b36080e7          	jalr	-1226(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000fb6:	00000097          	auipc	ra,0x0
    80000fba:	2a0080e7          	jalr	672(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000fbe:	00000097          	auipc	ra,0x0
    80000fc2:	068080e7          	jalr	104(ra) # 80001026 <kvminithart>
    procinit();      // process table
    80000fc6:	00001097          	auipc	ra,0x1
    80000fca:	96e080e7          	jalr	-1682(ra) # 80001934 <procinit>
    trapinit();      // trap vectors
    80000fce:	00001097          	auipc	ra,0x1
    80000fd2:	6d2080e7          	jalr	1746(ra) # 800026a0 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fd6:	00001097          	auipc	ra,0x1
    80000fda:	6f2080e7          	jalr	1778(ra) # 800026c8 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fde:	00005097          	auipc	ra,0x5
    80000fe2:	d2c080e7          	jalr	-724(ra) # 80005d0a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fe6:	00005097          	auipc	ra,0x5
    80000fea:	d3a080e7          	jalr	-710(ra) # 80005d20 <plicinithart>
    binit();         // buffer cache
    80000fee:	00002097          	auipc	ra,0x2
    80000ff2:	ed4080e7          	jalr	-300(ra) # 80002ec2 <binit>
    iinit();         // inode cache
    80000ff6:	00002097          	auipc	ra,0x2
    80000ffa:	564080e7          	jalr	1380(ra) # 8000355a <iinit>
    fileinit();      // file table
    80000ffe:	00003097          	auipc	ra,0x3
    80001002:	4fe080e7          	jalr	1278(ra) # 800044fc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001006:	00005097          	auipc	ra,0x5
    8000100a:	e22080e7          	jalr	-478(ra) # 80005e28 <virtio_disk_init>
    userinit();      // first user process
    8000100e:	00001097          	auipc	ra,0x1
    80001012:	cec080e7          	jalr	-788(ra) # 80001cfa <userinit>
    __sync_synchronize();
    80001016:	0ff0000f          	fence
    started = 1;
    8000101a:	4785                	li	a5,1
    8000101c:	00008717          	auipc	a4,0x8
    80001020:	fef72823          	sw	a5,-16(a4) # 8000900c <started>
    80001024:	b789                	j	80000f66 <main+0x56>

0000000080001026 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001026:	1141                	addi	sp,sp,-16
    80001028:	e422                	sd	s0,8(sp)
    8000102a:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    8000102c:	00008797          	auipc	a5,0x8
    80001030:	fe47b783          	ld	a5,-28(a5) # 80009010 <kernel_pagetable>
    80001034:	83b1                	srli	a5,a5,0xc
    80001036:	577d                	li	a4,-1
    80001038:	177e                	slli	a4,a4,0x3f
    8000103a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000103c:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001040:	12000073          	sfence.vma
  sfence_vma();
}
    80001044:	6422                	ld	s0,8(sp)
    80001046:	0141                	addi	sp,sp,16
    80001048:	8082                	ret

000000008000104a <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000104a:	7139                	addi	sp,sp,-64
    8000104c:	fc06                	sd	ra,56(sp)
    8000104e:	f822                	sd	s0,48(sp)
    80001050:	f426                	sd	s1,40(sp)
    80001052:	f04a                	sd	s2,32(sp)
    80001054:	ec4e                	sd	s3,24(sp)
    80001056:	e852                	sd	s4,16(sp)
    80001058:	e456                	sd	s5,8(sp)
    8000105a:	e05a                	sd	s6,0(sp)
    8000105c:	0080                	addi	s0,sp,64
    8000105e:	84aa                	mv	s1,a0
    80001060:	89ae                	mv	s3,a1
    80001062:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001064:	57fd                	li	a5,-1
    80001066:	83e9                	srli	a5,a5,0x1a
    80001068:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000106a:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000106c:	04b7f263          	bgeu	a5,a1,800010b0 <walk+0x66>
    panic("walk");
    80001070:	00007517          	auipc	a0,0x7
    80001074:	06050513          	addi	a0,a0,96 # 800080d0 <digits+0x90>
    80001078:	fffff097          	auipc	ra,0xfffff
    8000107c:	4d0080e7          	jalr	1232(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001080:	060a8663          	beqz	s5,800010ec <walk+0xa2>
    80001084:	00000097          	auipc	ra,0x0
    80001088:	a9c080e7          	jalr	-1380(ra) # 80000b20 <kalloc>
    8000108c:	84aa                	mv	s1,a0
    8000108e:	c529                	beqz	a0,800010d8 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001090:	6605                	lui	a2,0x1
    80001092:	4581                	li	a1,0
    80001094:	00000097          	auipc	ra,0x0
    80001098:	cca080e7          	jalr	-822(ra) # 80000d5e <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000109c:	00c4d793          	srli	a5,s1,0xc
    800010a0:	07aa                	slli	a5,a5,0xa
    800010a2:	0017e793          	ori	a5,a5,1
    800010a6:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010aa:	3a5d                	addiw	s4,s4,-9
    800010ac:	036a0063          	beq	s4,s6,800010cc <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010b0:	0149d933          	srl	s2,s3,s4
    800010b4:	1ff97913          	andi	s2,s2,511
    800010b8:	090e                	slli	s2,s2,0x3
    800010ba:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010bc:	00093483          	ld	s1,0(s2)
    800010c0:	0014f793          	andi	a5,s1,1
    800010c4:	dfd5                	beqz	a5,80001080 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010c6:	80a9                	srli	s1,s1,0xa
    800010c8:	04b2                	slli	s1,s1,0xc
    800010ca:	b7c5                	j	800010aa <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010cc:	00c9d513          	srli	a0,s3,0xc
    800010d0:	1ff57513          	andi	a0,a0,511
    800010d4:	050e                	slli	a0,a0,0x3
    800010d6:	9526                	add	a0,a0,s1
}
    800010d8:	70e2                	ld	ra,56(sp)
    800010da:	7442                	ld	s0,48(sp)
    800010dc:	74a2                	ld	s1,40(sp)
    800010de:	7902                	ld	s2,32(sp)
    800010e0:	69e2                	ld	s3,24(sp)
    800010e2:	6a42                	ld	s4,16(sp)
    800010e4:	6aa2                	ld	s5,8(sp)
    800010e6:	6b02                	ld	s6,0(sp)
    800010e8:	6121                	addi	sp,sp,64
    800010ea:	8082                	ret
        return 0;
    800010ec:	4501                	li	a0,0
    800010ee:	b7ed                	j	800010d8 <walk+0x8e>

00000000800010f0 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010f0:	57fd                	li	a5,-1
    800010f2:	83e9                	srli	a5,a5,0x1a
    800010f4:	00b7f463          	bgeu	a5,a1,800010fc <walkaddr+0xc>
    return 0;
    800010f8:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010fa:	8082                	ret
{
    800010fc:	1141                	addi	sp,sp,-16
    800010fe:	e406                	sd	ra,8(sp)
    80001100:	e022                	sd	s0,0(sp)
    80001102:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001104:	4601                	li	a2,0
    80001106:	00000097          	auipc	ra,0x0
    8000110a:	f44080e7          	jalr	-188(ra) # 8000104a <walk>
  if(pte == 0)
    8000110e:	c105                	beqz	a0,8000112e <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001110:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001112:	0117f693          	andi	a3,a5,17
    80001116:	4745                	li	a4,17
    return 0;
    80001118:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000111a:	00e68663          	beq	a3,a4,80001126 <walkaddr+0x36>
}
    8000111e:	60a2                	ld	ra,8(sp)
    80001120:	6402                	ld	s0,0(sp)
    80001122:	0141                	addi	sp,sp,16
    80001124:	8082                	ret
  pa = PTE2PA(*pte);
    80001126:	00a7d513          	srli	a0,a5,0xa
    8000112a:	0532                	slli	a0,a0,0xc
  return pa;
    8000112c:	bfcd                	j	8000111e <walkaddr+0x2e>
    return 0;
    8000112e:	4501                	li	a0,0
    80001130:	b7fd                	j	8000111e <walkaddr+0x2e>

0000000080001132 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    80001132:	1101                	addi	sp,sp,-32
    80001134:	ec06                	sd	ra,24(sp)
    80001136:	e822                	sd	s0,16(sp)
    80001138:	e426                	sd	s1,8(sp)
    8000113a:	1000                	addi	s0,sp,32
    8000113c:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    8000113e:	1552                	slli	a0,a0,0x34
    80001140:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    80001144:	4601                	li	a2,0
    80001146:	00008517          	auipc	a0,0x8
    8000114a:	eca53503          	ld	a0,-310(a0) # 80009010 <kernel_pagetable>
    8000114e:	00000097          	auipc	ra,0x0
    80001152:	efc080e7          	jalr	-260(ra) # 8000104a <walk>
  if(pte == 0)
    80001156:	cd09                	beqz	a0,80001170 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001158:	6108                	ld	a0,0(a0)
    8000115a:	00157793          	andi	a5,a0,1
    8000115e:	c38d                	beqz	a5,80001180 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001160:	8129                	srli	a0,a0,0xa
    80001162:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001164:	9526                	add	a0,a0,s1
    80001166:	60e2                	ld	ra,24(sp)
    80001168:	6442                	ld	s0,16(sp)
    8000116a:	64a2                	ld	s1,8(sp)
    8000116c:	6105                	addi	sp,sp,32
    8000116e:	8082                	ret
    panic("kvmpa");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f6850513          	addi	a0,a0,-152 # 800080d8 <digits+0x98>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3d0080e7          	jalr	976(ra) # 80000548 <panic>
    panic("kvmpa");
    80001180:	00007517          	auipc	a0,0x7
    80001184:	f5850513          	addi	a0,a0,-168 # 800080d8 <digits+0x98>
    80001188:	fffff097          	auipc	ra,0xfffff
    8000118c:	3c0080e7          	jalr	960(ra) # 80000548 <panic>

0000000080001190 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001190:	715d                	addi	sp,sp,-80
    80001192:	e486                	sd	ra,72(sp)
    80001194:	e0a2                	sd	s0,64(sp)
    80001196:	fc26                	sd	s1,56(sp)
    80001198:	f84a                	sd	s2,48(sp)
    8000119a:	f44e                	sd	s3,40(sp)
    8000119c:	f052                	sd	s4,32(sp)
    8000119e:	ec56                	sd	s5,24(sp)
    800011a0:	e85a                	sd	s6,16(sp)
    800011a2:	e45e                	sd	s7,8(sp)
    800011a4:	0880                	addi	s0,sp,80
    800011a6:	8aaa                	mv	s5,a0
    800011a8:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011aa:	777d                	lui	a4,0xfffff
    800011ac:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011b0:	167d                	addi	a2,a2,-1
    800011b2:	00b609b3          	add	s3,a2,a1
    800011b6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011ba:	893e                	mv	s2,a5
    800011bc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011c0:	6b85                	lui	s7,0x1
    800011c2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011c6:	4605                	li	a2,1
    800011c8:	85ca                	mv	a1,s2
    800011ca:	8556                	mv	a0,s5
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	e7e080e7          	jalr	-386(ra) # 8000104a <walk>
    800011d4:	c51d                	beqz	a0,80001202 <mappages+0x72>
    if(*pte & PTE_V)
    800011d6:	611c                	ld	a5,0(a0)
    800011d8:	8b85                	andi	a5,a5,1
    800011da:	ef81                	bnez	a5,800011f2 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011dc:	80b1                	srli	s1,s1,0xc
    800011de:	04aa                	slli	s1,s1,0xa
    800011e0:	0164e4b3          	or	s1,s1,s6
    800011e4:	0014e493          	ori	s1,s1,1
    800011e8:	e104                	sd	s1,0(a0)
    if(a == last)
    800011ea:	03390863          	beq	s2,s3,8000121a <mappages+0x8a>
    a += PGSIZE;
    800011ee:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011f0:	bfc9                	j	800011c2 <mappages+0x32>
      panic("remap");
    800011f2:	00007517          	auipc	a0,0x7
    800011f6:	eee50513          	addi	a0,a0,-274 # 800080e0 <digits+0xa0>
    800011fa:	fffff097          	auipc	ra,0xfffff
    800011fe:	34e080e7          	jalr	846(ra) # 80000548 <panic>
      return -1;
    80001202:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001204:	60a6                	ld	ra,72(sp)
    80001206:	6406                	ld	s0,64(sp)
    80001208:	74e2                	ld	s1,56(sp)
    8000120a:	7942                	ld	s2,48(sp)
    8000120c:	79a2                	ld	s3,40(sp)
    8000120e:	7a02                	ld	s4,32(sp)
    80001210:	6ae2                	ld	s5,24(sp)
    80001212:	6b42                	ld	s6,16(sp)
    80001214:	6ba2                	ld	s7,8(sp)
    80001216:	6161                	addi	sp,sp,80
    80001218:	8082                	ret
  return 0;
    8000121a:	4501                	li	a0,0
    8000121c:	b7e5                	j	80001204 <mappages+0x74>

000000008000121e <kvmmap>:
{
    8000121e:	1141                	addi	sp,sp,-16
    80001220:	e406                	sd	ra,8(sp)
    80001222:	e022                	sd	s0,0(sp)
    80001224:	0800                	addi	s0,sp,16
    80001226:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001228:	86ae                	mv	a3,a1
    8000122a:	85aa                	mv	a1,a0
    8000122c:	00008517          	auipc	a0,0x8
    80001230:	de453503          	ld	a0,-540(a0) # 80009010 <kernel_pagetable>
    80001234:	00000097          	auipc	ra,0x0
    80001238:	f5c080e7          	jalr	-164(ra) # 80001190 <mappages>
    8000123c:	e509                	bnez	a0,80001246 <kvmmap+0x28>
}
    8000123e:	60a2                	ld	ra,8(sp)
    80001240:	6402                	ld	s0,0(sp)
    80001242:	0141                	addi	sp,sp,16
    80001244:	8082                	ret
    panic("kvmmap");
    80001246:	00007517          	auipc	a0,0x7
    8000124a:	ea250513          	addi	a0,a0,-350 # 800080e8 <digits+0xa8>
    8000124e:	fffff097          	auipc	ra,0xfffff
    80001252:	2fa080e7          	jalr	762(ra) # 80000548 <panic>

0000000080001256 <kvminit>:
{
    80001256:	1101                	addi	sp,sp,-32
    80001258:	ec06                	sd	ra,24(sp)
    8000125a:	e822                	sd	s0,16(sp)
    8000125c:	e426                	sd	s1,8(sp)
    8000125e:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001260:	00000097          	auipc	ra,0x0
    80001264:	8c0080e7          	jalr	-1856(ra) # 80000b20 <kalloc>
    80001268:	00008797          	auipc	a5,0x8
    8000126c:	daa7b423          	sd	a0,-600(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001270:	6605                	lui	a2,0x1
    80001272:	4581                	li	a1,0
    80001274:	00000097          	auipc	ra,0x0
    80001278:	aea080e7          	jalr	-1302(ra) # 80000d5e <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000127c:	4699                	li	a3,6
    8000127e:	6605                	lui	a2,0x1
    80001280:	100005b7          	lui	a1,0x10000
    80001284:	10000537          	lui	a0,0x10000
    80001288:	00000097          	auipc	ra,0x0
    8000128c:	f96080e7          	jalr	-106(ra) # 8000121e <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001290:	4699                	li	a3,6
    80001292:	6605                	lui	a2,0x1
    80001294:	100015b7          	lui	a1,0x10001
    80001298:	10001537          	lui	a0,0x10001
    8000129c:	00000097          	auipc	ra,0x0
    800012a0:	f82080e7          	jalr	-126(ra) # 8000121e <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800012a4:	4699                	li	a3,6
    800012a6:	6641                	lui	a2,0x10
    800012a8:	020005b7          	lui	a1,0x2000
    800012ac:	02000537          	lui	a0,0x2000
    800012b0:	00000097          	auipc	ra,0x0
    800012b4:	f6e080e7          	jalr	-146(ra) # 8000121e <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012b8:	4699                	li	a3,6
    800012ba:	00400637          	lui	a2,0x400
    800012be:	0c0005b7          	lui	a1,0xc000
    800012c2:	0c000537          	lui	a0,0xc000
    800012c6:	00000097          	auipc	ra,0x0
    800012ca:	f58080e7          	jalr	-168(ra) # 8000121e <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012ce:	00007497          	auipc	s1,0x7
    800012d2:	d3248493          	addi	s1,s1,-718 # 80008000 <etext>
    800012d6:	46a9                	li	a3,10
    800012d8:	80007617          	auipc	a2,0x80007
    800012dc:	d2860613          	addi	a2,a2,-728 # 8000 <_entry-0x7fff8000>
    800012e0:	4585                	li	a1,1
    800012e2:	05fe                	slli	a1,a1,0x1f
    800012e4:	852e                	mv	a0,a1
    800012e6:	00000097          	auipc	ra,0x0
    800012ea:	f38080e7          	jalr	-200(ra) # 8000121e <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012ee:	4699                	li	a3,6
    800012f0:	4645                	li	a2,17
    800012f2:	066e                	slli	a2,a2,0x1b
    800012f4:	8e05                	sub	a2,a2,s1
    800012f6:	85a6                	mv	a1,s1
    800012f8:	8526                	mv	a0,s1
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	f24080e7          	jalr	-220(ra) # 8000121e <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001302:	46a9                	li	a3,10
    80001304:	6605                	lui	a2,0x1
    80001306:	00006597          	auipc	a1,0x6
    8000130a:	cfa58593          	addi	a1,a1,-774 # 80007000 <_trampoline>
    8000130e:	04000537          	lui	a0,0x4000
    80001312:	157d                	addi	a0,a0,-1
    80001314:	0532                	slli	a0,a0,0xc
    80001316:	00000097          	auipc	ra,0x0
    8000131a:	f08080e7          	jalr	-248(ra) # 8000121e <kvmmap>
}
    8000131e:	60e2                	ld	ra,24(sp)
    80001320:	6442                	ld	s0,16(sp)
    80001322:	64a2                	ld	s1,8(sp)
    80001324:	6105                	addi	sp,sp,32
    80001326:	8082                	ret

0000000080001328 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001328:	715d                	addi	sp,sp,-80
    8000132a:	e486                	sd	ra,72(sp)
    8000132c:	e0a2                	sd	s0,64(sp)
    8000132e:	fc26                	sd	s1,56(sp)
    80001330:	f84a                	sd	s2,48(sp)
    80001332:	f44e                	sd	s3,40(sp)
    80001334:	f052                	sd	s4,32(sp)
    80001336:	ec56                	sd	s5,24(sp)
    80001338:	e85a                	sd	s6,16(sp)
    8000133a:	e45e                	sd	s7,8(sp)
    8000133c:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000133e:	03459793          	slli	a5,a1,0x34
    80001342:	e795                	bnez	a5,8000136e <uvmunmap+0x46>
    80001344:	8a2a                	mv	s4,a0
    80001346:	892e                	mv	s2,a1
    80001348:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000134a:	0632                	slli	a2,a2,0xc
    8000134c:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001350:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001352:	6b05                	lui	s6,0x1
    80001354:	0735e863          	bltu	a1,s3,800013c4 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001358:	60a6                	ld	ra,72(sp)
    8000135a:	6406                	ld	s0,64(sp)
    8000135c:	74e2                	ld	s1,56(sp)
    8000135e:	7942                	ld	s2,48(sp)
    80001360:	79a2                	ld	s3,40(sp)
    80001362:	7a02                	ld	s4,32(sp)
    80001364:	6ae2                	ld	s5,24(sp)
    80001366:	6b42                	ld	s6,16(sp)
    80001368:	6ba2                	ld	s7,8(sp)
    8000136a:	6161                	addi	sp,sp,80
    8000136c:	8082                	ret
    panic("uvmunmap: not aligned");
    8000136e:	00007517          	auipc	a0,0x7
    80001372:	d8250513          	addi	a0,a0,-638 # 800080f0 <digits+0xb0>
    80001376:	fffff097          	auipc	ra,0xfffff
    8000137a:	1d2080e7          	jalr	466(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    8000137e:	00007517          	auipc	a0,0x7
    80001382:	d8a50513          	addi	a0,a0,-630 # 80008108 <digits+0xc8>
    80001386:	fffff097          	auipc	ra,0xfffff
    8000138a:	1c2080e7          	jalr	450(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    8000138e:	00007517          	auipc	a0,0x7
    80001392:	d8a50513          	addi	a0,a0,-630 # 80008118 <digits+0xd8>
    80001396:	fffff097          	auipc	ra,0xfffff
    8000139a:	1b2080e7          	jalr	434(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    8000139e:	00007517          	auipc	a0,0x7
    800013a2:	d9250513          	addi	a0,a0,-622 # 80008130 <digits+0xf0>
    800013a6:	fffff097          	auipc	ra,0xfffff
    800013aa:	1a2080e7          	jalr	418(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    800013ae:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013b0:	0532                	slli	a0,a0,0xc
    800013b2:	fffff097          	auipc	ra,0xfffff
    800013b6:	672080e7          	jalr	1650(ra) # 80000a24 <kfree>
    *pte = 0;
    800013ba:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013be:	995a                	add	s2,s2,s6
    800013c0:	f9397ce3          	bgeu	s2,s3,80001358 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013c4:	4601                	li	a2,0
    800013c6:	85ca                	mv	a1,s2
    800013c8:	8552                	mv	a0,s4
    800013ca:	00000097          	auipc	ra,0x0
    800013ce:	c80080e7          	jalr	-896(ra) # 8000104a <walk>
    800013d2:	84aa                	mv	s1,a0
    800013d4:	d54d                	beqz	a0,8000137e <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013d6:	6108                	ld	a0,0(a0)
    800013d8:	00157793          	andi	a5,a0,1
    800013dc:	dbcd                	beqz	a5,8000138e <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013de:	3ff57793          	andi	a5,a0,1023
    800013e2:	fb778ee3          	beq	a5,s7,8000139e <uvmunmap+0x76>
    if(do_free){
    800013e6:	fc0a8ae3          	beqz	s5,800013ba <uvmunmap+0x92>
    800013ea:	b7d1                	j	800013ae <uvmunmap+0x86>

00000000800013ec <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013ec:	1101                	addi	sp,sp,-32
    800013ee:	ec06                	sd	ra,24(sp)
    800013f0:	e822                	sd	s0,16(sp)
    800013f2:	e426                	sd	s1,8(sp)
    800013f4:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013f6:	fffff097          	auipc	ra,0xfffff
    800013fa:	72a080e7          	jalr	1834(ra) # 80000b20 <kalloc>
    800013fe:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001400:	c519                	beqz	a0,8000140e <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001402:	6605                	lui	a2,0x1
    80001404:	4581                	li	a1,0
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	958080e7          	jalr	-1704(ra) # 80000d5e <memset>
  return pagetable;
}
    8000140e:	8526                	mv	a0,s1
    80001410:	60e2                	ld	ra,24(sp)
    80001412:	6442                	ld	s0,16(sp)
    80001414:	64a2                	ld	s1,8(sp)
    80001416:	6105                	addi	sp,sp,32
    80001418:	8082                	ret

000000008000141a <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000141a:	7179                	addi	sp,sp,-48
    8000141c:	f406                	sd	ra,40(sp)
    8000141e:	f022                	sd	s0,32(sp)
    80001420:	ec26                	sd	s1,24(sp)
    80001422:	e84a                	sd	s2,16(sp)
    80001424:	e44e                	sd	s3,8(sp)
    80001426:	e052                	sd	s4,0(sp)
    80001428:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000142a:	6785                	lui	a5,0x1
    8000142c:	04f67863          	bgeu	a2,a5,8000147c <uvminit+0x62>
    80001430:	8a2a                	mv	s4,a0
    80001432:	89ae                	mv	s3,a1
    80001434:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001436:	fffff097          	auipc	ra,0xfffff
    8000143a:	6ea080e7          	jalr	1770(ra) # 80000b20 <kalloc>
    8000143e:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001440:	6605                	lui	a2,0x1
    80001442:	4581                	li	a1,0
    80001444:	00000097          	auipc	ra,0x0
    80001448:	91a080e7          	jalr	-1766(ra) # 80000d5e <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000144c:	4779                	li	a4,30
    8000144e:	86ca                	mv	a3,s2
    80001450:	6605                	lui	a2,0x1
    80001452:	4581                	li	a1,0
    80001454:	8552                	mv	a0,s4
    80001456:	00000097          	auipc	ra,0x0
    8000145a:	d3a080e7          	jalr	-710(ra) # 80001190 <mappages>
  memmove(mem, src, sz);
    8000145e:	8626                	mv	a2,s1
    80001460:	85ce                	mv	a1,s3
    80001462:	854a                	mv	a0,s2
    80001464:	00000097          	auipc	ra,0x0
    80001468:	95a080e7          	jalr	-1702(ra) # 80000dbe <memmove>
}
    8000146c:	70a2                	ld	ra,40(sp)
    8000146e:	7402                	ld	s0,32(sp)
    80001470:	64e2                	ld	s1,24(sp)
    80001472:	6942                	ld	s2,16(sp)
    80001474:	69a2                	ld	s3,8(sp)
    80001476:	6a02                	ld	s4,0(sp)
    80001478:	6145                	addi	sp,sp,48
    8000147a:	8082                	ret
    panic("inituvm: more than a page");
    8000147c:	00007517          	auipc	a0,0x7
    80001480:	ccc50513          	addi	a0,a0,-820 # 80008148 <digits+0x108>
    80001484:	fffff097          	auipc	ra,0xfffff
    80001488:	0c4080e7          	jalr	196(ra) # 80000548 <panic>

000000008000148c <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000148c:	1101                	addi	sp,sp,-32
    8000148e:	ec06                	sd	ra,24(sp)
    80001490:	e822                	sd	s0,16(sp)
    80001492:	e426                	sd	s1,8(sp)
    80001494:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001496:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001498:	00b67d63          	bgeu	a2,a1,800014b2 <uvmdealloc+0x26>
    8000149c:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000149e:	6785                	lui	a5,0x1
    800014a0:	17fd                	addi	a5,a5,-1
    800014a2:	00f60733          	add	a4,a2,a5
    800014a6:	767d                	lui	a2,0xfffff
    800014a8:	8f71                	and	a4,a4,a2
    800014aa:	97ae                	add	a5,a5,a1
    800014ac:	8ff1                	and	a5,a5,a2
    800014ae:	00f76863          	bltu	a4,a5,800014be <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014b2:	8526                	mv	a0,s1
    800014b4:	60e2                	ld	ra,24(sp)
    800014b6:	6442                	ld	s0,16(sp)
    800014b8:	64a2                	ld	s1,8(sp)
    800014ba:	6105                	addi	sp,sp,32
    800014bc:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014be:	8f99                	sub	a5,a5,a4
    800014c0:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014c2:	4685                	li	a3,1
    800014c4:	0007861b          	sext.w	a2,a5
    800014c8:	85ba                	mv	a1,a4
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	e5e080e7          	jalr	-418(ra) # 80001328 <uvmunmap>
    800014d2:	b7c5                	j	800014b2 <uvmdealloc+0x26>

00000000800014d4 <uvmalloc>:
  if(newsz < oldsz)
    800014d4:	0ab66163          	bltu	a2,a1,80001576 <uvmalloc+0xa2>
{
    800014d8:	7139                	addi	sp,sp,-64
    800014da:	fc06                	sd	ra,56(sp)
    800014dc:	f822                	sd	s0,48(sp)
    800014de:	f426                	sd	s1,40(sp)
    800014e0:	f04a                	sd	s2,32(sp)
    800014e2:	ec4e                	sd	s3,24(sp)
    800014e4:	e852                	sd	s4,16(sp)
    800014e6:	e456                	sd	s5,8(sp)
    800014e8:	0080                	addi	s0,sp,64
    800014ea:	8aaa                	mv	s5,a0
    800014ec:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014ee:	6985                	lui	s3,0x1
    800014f0:	19fd                	addi	s3,s3,-1
    800014f2:	95ce                	add	a1,a1,s3
    800014f4:	79fd                	lui	s3,0xfffff
    800014f6:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014fa:	08c9f063          	bgeu	s3,a2,8000157a <uvmalloc+0xa6>
    800014fe:	894e                	mv	s2,s3
    mem = kalloc();
    80001500:	fffff097          	auipc	ra,0xfffff
    80001504:	620080e7          	jalr	1568(ra) # 80000b20 <kalloc>
    80001508:	84aa                	mv	s1,a0
    if(mem == 0){
    8000150a:	c51d                	beqz	a0,80001538 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000150c:	6605                	lui	a2,0x1
    8000150e:	4581                	li	a1,0
    80001510:	00000097          	auipc	ra,0x0
    80001514:	84e080e7          	jalr	-1970(ra) # 80000d5e <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001518:	4779                	li	a4,30
    8000151a:	86a6                	mv	a3,s1
    8000151c:	6605                	lui	a2,0x1
    8000151e:	85ca                	mv	a1,s2
    80001520:	8556                	mv	a0,s5
    80001522:	00000097          	auipc	ra,0x0
    80001526:	c6e080e7          	jalr	-914(ra) # 80001190 <mappages>
    8000152a:	e905                	bnez	a0,8000155a <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000152c:	6785                	lui	a5,0x1
    8000152e:	993e                	add	s2,s2,a5
    80001530:	fd4968e3          	bltu	s2,s4,80001500 <uvmalloc+0x2c>
  return newsz;
    80001534:	8552                	mv	a0,s4
    80001536:	a809                	j	80001548 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001538:	864e                	mv	a2,s3
    8000153a:	85ca                	mv	a1,s2
    8000153c:	8556                	mv	a0,s5
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f4e080e7          	jalr	-178(ra) # 8000148c <uvmdealloc>
      return 0;
    80001546:	4501                	li	a0,0
}
    80001548:	70e2                	ld	ra,56(sp)
    8000154a:	7442                	ld	s0,48(sp)
    8000154c:	74a2                	ld	s1,40(sp)
    8000154e:	7902                	ld	s2,32(sp)
    80001550:	69e2                	ld	s3,24(sp)
    80001552:	6a42                	ld	s4,16(sp)
    80001554:	6aa2                	ld	s5,8(sp)
    80001556:	6121                	addi	sp,sp,64
    80001558:	8082                	ret
      kfree(mem);
    8000155a:	8526                	mv	a0,s1
    8000155c:	fffff097          	auipc	ra,0xfffff
    80001560:	4c8080e7          	jalr	1224(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001564:	864e                	mv	a2,s3
    80001566:	85ca                	mv	a1,s2
    80001568:	8556                	mv	a0,s5
    8000156a:	00000097          	auipc	ra,0x0
    8000156e:	f22080e7          	jalr	-222(ra) # 8000148c <uvmdealloc>
      return 0;
    80001572:	4501                	li	a0,0
    80001574:	bfd1                	j	80001548 <uvmalloc+0x74>
    return oldsz;
    80001576:	852e                	mv	a0,a1
}
    80001578:	8082                	ret
  return newsz;
    8000157a:	8532                	mv	a0,a2
    8000157c:	b7f1                	j	80001548 <uvmalloc+0x74>

000000008000157e <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000157e:	7179                	addi	sp,sp,-48
    80001580:	f406                	sd	ra,40(sp)
    80001582:	f022                	sd	s0,32(sp)
    80001584:	ec26                	sd	s1,24(sp)
    80001586:	e84a                	sd	s2,16(sp)
    80001588:	e44e                	sd	s3,8(sp)
    8000158a:	e052                	sd	s4,0(sp)
    8000158c:	1800                	addi	s0,sp,48
    8000158e:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001590:	84aa                	mv	s1,a0
    80001592:	6905                	lui	s2,0x1
    80001594:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001596:	4985                	li	s3,1
    80001598:	a821                	j	800015b0 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000159a:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000159c:	0532                	slli	a0,a0,0xc
    8000159e:	00000097          	auipc	ra,0x0
    800015a2:	fe0080e7          	jalr	-32(ra) # 8000157e <freewalk>
      pagetable[i] = 0;
    800015a6:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015aa:	04a1                	addi	s1,s1,8
    800015ac:	03248163          	beq	s1,s2,800015ce <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015b0:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015b2:	00f57793          	andi	a5,a0,15
    800015b6:	ff3782e3          	beq	a5,s3,8000159a <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015ba:	8905                	andi	a0,a0,1
    800015bc:	d57d                	beqz	a0,800015aa <freewalk+0x2c>
      panic("freewalk: leaf");
    800015be:	00007517          	auipc	a0,0x7
    800015c2:	baa50513          	addi	a0,a0,-1110 # 80008168 <digits+0x128>
    800015c6:	fffff097          	auipc	ra,0xfffff
    800015ca:	f82080e7          	jalr	-126(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    800015ce:	8552                	mv	a0,s4
    800015d0:	fffff097          	auipc	ra,0xfffff
    800015d4:	454080e7          	jalr	1108(ra) # 80000a24 <kfree>
}
    800015d8:	70a2                	ld	ra,40(sp)
    800015da:	7402                	ld	s0,32(sp)
    800015dc:	64e2                	ld	s1,24(sp)
    800015de:	6942                	ld	s2,16(sp)
    800015e0:	69a2                	ld	s3,8(sp)
    800015e2:	6a02                	ld	s4,0(sp)
    800015e4:	6145                	addi	sp,sp,48
    800015e6:	8082                	ret

00000000800015e8 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015e8:	1101                	addi	sp,sp,-32
    800015ea:	ec06                	sd	ra,24(sp)
    800015ec:	e822                	sd	s0,16(sp)
    800015ee:	e426                	sd	s1,8(sp)
    800015f0:	1000                	addi	s0,sp,32
    800015f2:	84aa                	mv	s1,a0
  if(sz > 0)
    800015f4:	e999                	bnez	a1,8000160a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015f6:	8526                	mv	a0,s1
    800015f8:	00000097          	auipc	ra,0x0
    800015fc:	f86080e7          	jalr	-122(ra) # 8000157e <freewalk>
}
    80001600:	60e2                	ld	ra,24(sp)
    80001602:	6442                	ld	s0,16(sp)
    80001604:	64a2                	ld	s1,8(sp)
    80001606:	6105                	addi	sp,sp,32
    80001608:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000160a:	6605                	lui	a2,0x1
    8000160c:	167d                	addi	a2,a2,-1
    8000160e:	962e                	add	a2,a2,a1
    80001610:	4685                	li	a3,1
    80001612:	8231                	srli	a2,a2,0xc
    80001614:	4581                	li	a1,0
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	d12080e7          	jalr	-750(ra) # 80001328 <uvmunmap>
    8000161e:	bfe1                	j	800015f6 <uvmfree+0xe>

0000000080001620 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001620:	c679                	beqz	a2,800016ee <uvmcopy+0xce>
{
    80001622:	715d                	addi	sp,sp,-80
    80001624:	e486                	sd	ra,72(sp)
    80001626:	e0a2                	sd	s0,64(sp)
    80001628:	fc26                	sd	s1,56(sp)
    8000162a:	f84a                	sd	s2,48(sp)
    8000162c:	f44e                	sd	s3,40(sp)
    8000162e:	f052                	sd	s4,32(sp)
    80001630:	ec56                	sd	s5,24(sp)
    80001632:	e85a                	sd	s6,16(sp)
    80001634:	e45e                	sd	s7,8(sp)
    80001636:	0880                	addi	s0,sp,80
    80001638:	8b2a                	mv	s6,a0
    8000163a:	8aae                	mv	s5,a1
    8000163c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000163e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001640:	4601                	li	a2,0
    80001642:	85ce                	mv	a1,s3
    80001644:	855a                	mv	a0,s6
    80001646:	00000097          	auipc	ra,0x0
    8000164a:	a04080e7          	jalr	-1532(ra) # 8000104a <walk>
    8000164e:	c531                	beqz	a0,8000169a <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001650:	6118                	ld	a4,0(a0)
    80001652:	00177793          	andi	a5,a4,1
    80001656:	cbb1                	beqz	a5,800016aa <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001658:	00a75593          	srli	a1,a4,0xa
    8000165c:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001660:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	4bc080e7          	jalr	1212(ra) # 80000b20 <kalloc>
    8000166c:	892a                	mv	s2,a0
    8000166e:	c939                	beqz	a0,800016c4 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001670:	6605                	lui	a2,0x1
    80001672:	85de                	mv	a1,s7
    80001674:	fffff097          	auipc	ra,0xfffff
    80001678:	74a080e7          	jalr	1866(ra) # 80000dbe <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000167c:	8726                	mv	a4,s1
    8000167e:	86ca                	mv	a3,s2
    80001680:	6605                	lui	a2,0x1
    80001682:	85ce                	mv	a1,s3
    80001684:	8556                	mv	a0,s5
    80001686:	00000097          	auipc	ra,0x0
    8000168a:	b0a080e7          	jalr	-1270(ra) # 80001190 <mappages>
    8000168e:	e515                	bnez	a0,800016ba <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001690:	6785                	lui	a5,0x1
    80001692:	99be                	add	s3,s3,a5
    80001694:	fb49e6e3          	bltu	s3,s4,80001640 <uvmcopy+0x20>
    80001698:	a081                	j	800016d8 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000169a:	00007517          	auipc	a0,0x7
    8000169e:	ade50513          	addi	a0,a0,-1314 # 80008178 <digits+0x138>
    800016a2:	fffff097          	auipc	ra,0xfffff
    800016a6:	ea6080e7          	jalr	-346(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    800016aa:	00007517          	auipc	a0,0x7
    800016ae:	aee50513          	addi	a0,a0,-1298 # 80008198 <digits+0x158>
    800016b2:	fffff097          	auipc	ra,0xfffff
    800016b6:	e96080e7          	jalr	-362(ra) # 80000548 <panic>
      kfree(mem);
    800016ba:	854a                	mv	a0,s2
    800016bc:	fffff097          	auipc	ra,0xfffff
    800016c0:	368080e7          	jalr	872(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016c4:	4685                	li	a3,1
    800016c6:	00c9d613          	srli	a2,s3,0xc
    800016ca:	4581                	li	a1,0
    800016cc:	8556                	mv	a0,s5
    800016ce:	00000097          	auipc	ra,0x0
    800016d2:	c5a080e7          	jalr	-934(ra) # 80001328 <uvmunmap>
  return -1;
    800016d6:	557d                	li	a0,-1
}
    800016d8:	60a6                	ld	ra,72(sp)
    800016da:	6406                	ld	s0,64(sp)
    800016dc:	74e2                	ld	s1,56(sp)
    800016de:	7942                	ld	s2,48(sp)
    800016e0:	79a2                	ld	s3,40(sp)
    800016e2:	7a02                	ld	s4,32(sp)
    800016e4:	6ae2                	ld	s5,24(sp)
    800016e6:	6b42                	ld	s6,16(sp)
    800016e8:	6ba2                	ld	s7,8(sp)
    800016ea:	6161                	addi	sp,sp,80
    800016ec:	8082                	ret
  return 0;
    800016ee:	4501                	li	a0,0
}
    800016f0:	8082                	ret

00000000800016f2 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016f2:	1141                	addi	sp,sp,-16
    800016f4:	e406                	sd	ra,8(sp)
    800016f6:	e022                	sd	s0,0(sp)
    800016f8:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016fa:	4601                	li	a2,0
    800016fc:	00000097          	auipc	ra,0x0
    80001700:	94e080e7          	jalr	-1714(ra) # 8000104a <walk>
  if(pte == 0)
    80001704:	c901                	beqz	a0,80001714 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001706:	611c                	ld	a5,0(a0)
    80001708:	9bbd                	andi	a5,a5,-17
    8000170a:	e11c                	sd	a5,0(a0)
}
    8000170c:	60a2                	ld	ra,8(sp)
    8000170e:	6402                	ld	s0,0(sp)
    80001710:	0141                	addi	sp,sp,16
    80001712:	8082                	ret
    panic("uvmclear");
    80001714:	00007517          	auipc	a0,0x7
    80001718:	aa450513          	addi	a0,a0,-1372 # 800081b8 <digits+0x178>
    8000171c:	fffff097          	auipc	ra,0xfffff
    80001720:	e2c080e7          	jalr	-468(ra) # 80000548 <panic>

0000000080001724 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001724:	c6bd                	beqz	a3,80001792 <copyout+0x6e>
{
    80001726:	715d                	addi	sp,sp,-80
    80001728:	e486                	sd	ra,72(sp)
    8000172a:	e0a2                	sd	s0,64(sp)
    8000172c:	fc26                	sd	s1,56(sp)
    8000172e:	f84a                	sd	s2,48(sp)
    80001730:	f44e                	sd	s3,40(sp)
    80001732:	f052                	sd	s4,32(sp)
    80001734:	ec56                	sd	s5,24(sp)
    80001736:	e85a                	sd	s6,16(sp)
    80001738:	e45e                	sd	s7,8(sp)
    8000173a:	e062                	sd	s8,0(sp)
    8000173c:	0880                	addi	s0,sp,80
    8000173e:	8b2a                	mv	s6,a0
    80001740:	8c2e                	mv	s8,a1
    80001742:	8a32                	mv	s4,a2
    80001744:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001746:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001748:	6a85                	lui	s5,0x1
    8000174a:	a015                	j	8000176e <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000174c:	9562                	add	a0,a0,s8
    8000174e:	0004861b          	sext.w	a2,s1
    80001752:	85d2                	mv	a1,s4
    80001754:	41250533          	sub	a0,a0,s2
    80001758:	fffff097          	auipc	ra,0xfffff
    8000175c:	666080e7          	jalr	1638(ra) # 80000dbe <memmove>

    len -= n;
    80001760:	409989b3          	sub	s3,s3,s1
    src += n;
    80001764:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001766:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000176a:	02098263          	beqz	s3,8000178e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000176e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001772:	85ca                	mv	a1,s2
    80001774:	855a                	mv	a0,s6
    80001776:	00000097          	auipc	ra,0x0
    8000177a:	97a080e7          	jalr	-1670(ra) # 800010f0 <walkaddr>
    if(pa0 == 0)
    8000177e:	cd01                	beqz	a0,80001796 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001780:	418904b3          	sub	s1,s2,s8
    80001784:	94d6                	add	s1,s1,s5
    if(n > len)
    80001786:	fc99f3e3          	bgeu	s3,s1,8000174c <copyout+0x28>
    8000178a:	84ce                	mv	s1,s3
    8000178c:	b7c1                	j	8000174c <copyout+0x28>
  }
  return 0;
    8000178e:	4501                	li	a0,0
    80001790:	a021                	j	80001798 <copyout+0x74>
    80001792:	4501                	li	a0,0
}
    80001794:	8082                	ret
      return -1;
    80001796:	557d                	li	a0,-1
}
    80001798:	60a6                	ld	ra,72(sp)
    8000179a:	6406                	ld	s0,64(sp)
    8000179c:	74e2                	ld	s1,56(sp)
    8000179e:	7942                	ld	s2,48(sp)
    800017a0:	79a2                	ld	s3,40(sp)
    800017a2:	7a02                	ld	s4,32(sp)
    800017a4:	6ae2                	ld	s5,24(sp)
    800017a6:	6b42                	ld	s6,16(sp)
    800017a8:	6ba2                	ld	s7,8(sp)
    800017aa:	6c02                	ld	s8,0(sp)
    800017ac:	6161                	addi	sp,sp,80
    800017ae:	8082                	ret

00000000800017b0 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017b0:	c6bd                	beqz	a3,8000181e <copyin+0x6e>
{
    800017b2:	715d                	addi	sp,sp,-80
    800017b4:	e486                	sd	ra,72(sp)
    800017b6:	e0a2                	sd	s0,64(sp)
    800017b8:	fc26                	sd	s1,56(sp)
    800017ba:	f84a                	sd	s2,48(sp)
    800017bc:	f44e                	sd	s3,40(sp)
    800017be:	f052                	sd	s4,32(sp)
    800017c0:	ec56                	sd	s5,24(sp)
    800017c2:	e85a                	sd	s6,16(sp)
    800017c4:	e45e                	sd	s7,8(sp)
    800017c6:	e062                	sd	s8,0(sp)
    800017c8:	0880                	addi	s0,sp,80
    800017ca:	8b2a                	mv	s6,a0
    800017cc:	8a2e                	mv	s4,a1
    800017ce:	8c32                	mv	s8,a2
    800017d0:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017d2:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017d4:	6a85                	lui	s5,0x1
    800017d6:	a015                	j	800017fa <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017d8:	9562                	add	a0,a0,s8
    800017da:	0004861b          	sext.w	a2,s1
    800017de:	412505b3          	sub	a1,a0,s2
    800017e2:	8552                	mv	a0,s4
    800017e4:	fffff097          	auipc	ra,0xfffff
    800017e8:	5da080e7          	jalr	1498(ra) # 80000dbe <memmove>

    len -= n;
    800017ec:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017f0:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017f2:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017f6:	02098263          	beqz	s3,8000181a <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800017fa:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017fe:	85ca                	mv	a1,s2
    80001800:	855a                	mv	a0,s6
    80001802:	00000097          	auipc	ra,0x0
    80001806:	8ee080e7          	jalr	-1810(ra) # 800010f0 <walkaddr>
    if(pa0 == 0)
    8000180a:	cd01                	beqz	a0,80001822 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000180c:	418904b3          	sub	s1,s2,s8
    80001810:	94d6                	add	s1,s1,s5
    if(n > len)
    80001812:	fc99f3e3          	bgeu	s3,s1,800017d8 <copyin+0x28>
    80001816:	84ce                	mv	s1,s3
    80001818:	b7c1                	j	800017d8 <copyin+0x28>
  }
  return 0;
    8000181a:	4501                	li	a0,0
    8000181c:	a021                	j	80001824 <copyin+0x74>
    8000181e:	4501                	li	a0,0
}
    80001820:	8082                	ret
      return -1;
    80001822:	557d                	li	a0,-1
}
    80001824:	60a6                	ld	ra,72(sp)
    80001826:	6406                	ld	s0,64(sp)
    80001828:	74e2                	ld	s1,56(sp)
    8000182a:	7942                	ld	s2,48(sp)
    8000182c:	79a2                	ld	s3,40(sp)
    8000182e:	7a02                	ld	s4,32(sp)
    80001830:	6ae2                	ld	s5,24(sp)
    80001832:	6b42                	ld	s6,16(sp)
    80001834:	6ba2                	ld	s7,8(sp)
    80001836:	6c02                	ld	s8,0(sp)
    80001838:	6161                	addi	sp,sp,80
    8000183a:	8082                	ret

000000008000183c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000183c:	c6c5                	beqz	a3,800018e4 <copyinstr+0xa8>
{
    8000183e:	715d                	addi	sp,sp,-80
    80001840:	e486                	sd	ra,72(sp)
    80001842:	e0a2                	sd	s0,64(sp)
    80001844:	fc26                	sd	s1,56(sp)
    80001846:	f84a                	sd	s2,48(sp)
    80001848:	f44e                	sd	s3,40(sp)
    8000184a:	f052                	sd	s4,32(sp)
    8000184c:	ec56                	sd	s5,24(sp)
    8000184e:	e85a                	sd	s6,16(sp)
    80001850:	e45e                	sd	s7,8(sp)
    80001852:	0880                	addi	s0,sp,80
    80001854:	8a2a                	mv	s4,a0
    80001856:	8b2e                	mv	s6,a1
    80001858:	8bb2                	mv	s7,a2
    8000185a:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000185c:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000185e:	6985                	lui	s3,0x1
    80001860:	a035                	j	8000188c <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001862:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001866:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001868:	0017b793          	seqz	a5,a5
    8000186c:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001870:	60a6                	ld	ra,72(sp)
    80001872:	6406                	ld	s0,64(sp)
    80001874:	74e2                	ld	s1,56(sp)
    80001876:	7942                	ld	s2,48(sp)
    80001878:	79a2                	ld	s3,40(sp)
    8000187a:	7a02                	ld	s4,32(sp)
    8000187c:	6ae2                	ld	s5,24(sp)
    8000187e:	6b42                	ld	s6,16(sp)
    80001880:	6ba2                	ld	s7,8(sp)
    80001882:	6161                	addi	sp,sp,80
    80001884:	8082                	ret
    srcva = va0 + PGSIZE;
    80001886:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000188a:	c8a9                	beqz	s1,800018dc <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000188c:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001890:	85ca                	mv	a1,s2
    80001892:	8552                	mv	a0,s4
    80001894:	00000097          	auipc	ra,0x0
    80001898:	85c080e7          	jalr	-1956(ra) # 800010f0 <walkaddr>
    if(pa0 == 0)
    8000189c:	c131                	beqz	a0,800018e0 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000189e:	41790833          	sub	a6,s2,s7
    800018a2:	984e                	add	a6,a6,s3
    if(n > max)
    800018a4:	0104f363          	bgeu	s1,a6,800018aa <copyinstr+0x6e>
    800018a8:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018aa:	955e                	add	a0,a0,s7
    800018ac:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018b0:	fc080be3          	beqz	a6,80001886 <copyinstr+0x4a>
    800018b4:	985a                	add	a6,a6,s6
    800018b6:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018b8:	41650633          	sub	a2,a0,s6
    800018bc:	14fd                	addi	s1,s1,-1
    800018be:	9b26                	add	s6,s6,s1
    800018c0:	00f60733          	add	a4,a2,a5
    800018c4:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800018c8:	df49                	beqz	a4,80001862 <copyinstr+0x26>
        *dst = *p;
    800018ca:	00e78023          	sb	a4,0(a5)
      --max;
    800018ce:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018d2:	0785                	addi	a5,a5,1
    while(n > 0){
    800018d4:	ff0796e3          	bne	a5,a6,800018c0 <copyinstr+0x84>
      dst++;
    800018d8:	8b42                	mv	s6,a6
    800018da:	b775                	j	80001886 <copyinstr+0x4a>
    800018dc:	4781                	li	a5,0
    800018de:	b769                	j	80001868 <copyinstr+0x2c>
      return -1;
    800018e0:	557d                	li	a0,-1
    800018e2:	b779                	j	80001870 <copyinstr+0x34>
  int got_null = 0;
    800018e4:	4781                	li	a5,0
  if(got_null){
    800018e6:	0017b793          	seqz	a5,a5
    800018ea:	40f00533          	neg	a0,a5
}
    800018ee:	8082                	ret

00000000800018f0 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800018f0:	1101                	addi	sp,sp,-32
    800018f2:	ec06                	sd	ra,24(sp)
    800018f4:	e822                	sd	s0,16(sp)
    800018f6:	e426                	sd	s1,8(sp)
    800018f8:	1000                	addi	s0,sp,32
    800018fa:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800018fc:	fffff097          	auipc	ra,0xfffff
    80001900:	2ec080e7          	jalr	748(ra) # 80000be8 <holding>
    80001904:	c909                	beqz	a0,80001916 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001906:	749c                	ld	a5,40(s1)
    80001908:	00978f63          	beq	a5,s1,80001926 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    8000190c:	60e2                	ld	ra,24(sp)
    8000190e:	6442                	ld	s0,16(sp)
    80001910:	64a2                	ld	s1,8(sp)
    80001912:	6105                	addi	sp,sp,32
    80001914:	8082                	ret
    panic("wakeup1");
    80001916:	00007517          	auipc	a0,0x7
    8000191a:	8b250513          	addi	a0,a0,-1870 # 800081c8 <digits+0x188>
    8000191e:	fffff097          	auipc	ra,0xfffff
    80001922:	c2a080e7          	jalr	-982(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001926:	4c98                	lw	a4,24(s1)
    80001928:	4785                	li	a5,1
    8000192a:	fef711e3          	bne	a4,a5,8000190c <wakeup1+0x1c>
    p->state = RUNNABLE;
    8000192e:	4789                	li	a5,2
    80001930:	cc9c                	sw	a5,24(s1)
}
    80001932:	bfe9                	j	8000190c <wakeup1+0x1c>

0000000080001934 <procinit>:
{
    80001934:	715d                	addi	sp,sp,-80
    80001936:	e486                	sd	ra,72(sp)
    80001938:	e0a2                	sd	s0,64(sp)
    8000193a:	fc26                	sd	s1,56(sp)
    8000193c:	f84a                	sd	s2,48(sp)
    8000193e:	f44e                	sd	s3,40(sp)
    80001940:	f052                	sd	s4,32(sp)
    80001942:	ec56                	sd	s5,24(sp)
    80001944:	e85a                	sd	s6,16(sp)
    80001946:	e45e                	sd	s7,8(sp)
    80001948:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    8000194a:	00007597          	auipc	a1,0x7
    8000194e:	88658593          	addi	a1,a1,-1914 # 800081d0 <digits+0x190>
    80001952:	00010517          	auipc	a0,0x10
    80001956:	ffe50513          	addi	a0,a0,-2 # 80011950 <pid_lock>
    8000195a:	fffff097          	auipc	ra,0xfffff
    8000195e:	278080e7          	jalr	632(ra) # 80000bd2 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001962:	00010917          	auipc	s2,0x10
    80001966:	40690913          	addi	s2,s2,1030 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    8000196a:	00007b97          	auipc	s7,0x7
    8000196e:	86eb8b93          	addi	s7,s7,-1938 # 800081d8 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    80001972:	8b4a                	mv	s6,s2
    80001974:	00006a97          	auipc	s5,0x6
    80001978:	68ca8a93          	addi	s5,s5,1676 # 80008000 <etext>
    8000197c:	040009b7          	lui	s3,0x4000
    80001980:	19fd                	addi	s3,s3,-1
    80001982:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001984:	00016a17          	auipc	s4,0x16
    80001988:	de4a0a13          	addi	s4,s4,-540 # 80017768 <tickslock>
      initlock(&p->lock, "proc");
    8000198c:	85de                	mv	a1,s7
    8000198e:	854a                	mv	a0,s2
    80001990:	fffff097          	auipc	ra,0xfffff
    80001994:	242080e7          	jalr	578(ra) # 80000bd2 <initlock>
      char *pa = kalloc();
    80001998:	fffff097          	auipc	ra,0xfffff
    8000199c:	188080e7          	jalr	392(ra) # 80000b20 <kalloc>
    800019a0:	85aa                	mv	a1,a0
      if(pa == 0)
    800019a2:	c929                	beqz	a0,800019f4 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    800019a4:	416904b3          	sub	s1,s2,s6
    800019a8:	848d                	srai	s1,s1,0x3
    800019aa:	000ab783          	ld	a5,0(s5)
    800019ae:	02f484b3          	mul	s1,s1,a5
    800019b2:	2485                	addiw	s1,s1,1
    800019b4:	00d4949b          	slliw	s1,s1,0xd
    800019b8:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019bc:	4699                	li	a3,6
    800019be:	6605                	lui	a2,0x1
    800019c0:	8526                	mv	a0,s1
    800019c2:	00000097          	auipc	ra,0x0
    800019c6:	85c080e7          	jalr	-1956(ra) # 8000121e <kvmmap>
      p->kstack = va;
    800019ca:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ce:	16890913          	addi	s2,s2,360
    800019d2:	fb491de3          	bne	s2,s4,8000198c <procinit+0x58>
  kvminithart();
    800019d6:	fffff097          	auipc	ra,0xfffff
    800019da:	650080e7          	jalr	1616(ra) # 80001026 <kvminithart>
}
    800019de:	60a6                	ld	ra,72(sp)
    800019e0:	6406                	ld	s0,64(sp)
    800019e2:	74e2                	ld	s1,56(sp)
    800019e4:	7942                	ld	s2,48(sp)
    800019e6:	79a2                	ld	s3,40(sp)
    800019e8:	7a02                	ld	s4,32(sp)
    800019ea:	6ae2                	ld	s5,24(sp)
    800019ec:	6b42                	ld	s6,16(sp)
    800019ee:	6ba2                	ld	s7,8(sp)
    800019f0:	6161                	addi	sp,sp,80
    800019f2:	8082                	ret
        panic("kalloc");
    800019f4:	00006517          	auipc	a0,0x6
    800019f8:	7ec50513          	addi	a0,a0,2028 # 800081e0 <digits+0x1a0>
    800019fc:	fffff097          	auipc	ra,0xfffff
    80001a00:	b4c080e7          	jalr	-1204(ra) # 80000548 <panic>

0000000080001a04 <cpuid>:
{
    80001a04:	1141                	addi	sp,sp,-16
    80001a06:	e422                	sd	s0,8(sp)
    80001a08:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a0a:	8512                	mv	a0,tp
}
    80001a0c:	2501                	sext.w	a0,a0
    80001a0e:	6422                	ld	s0,8(sp)
    80001a10:	0141                	addi	sp,sp,16
    80001a12:	8082                	ret

0000000080001a14 <mycpu>:
mycpu(void) {
    80001a14:	1141                	addi	sp,sp,-16
    80001a16:	e422                	sd	s0,8(sp)
    80001a18:	0800                	addi	s0,sp,16
    80001a1a:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a1c:	2781                	sext.w	a5,a5
    80001a1e:	079e                	slli	a5,a5,0x7
}
    80001a20:	00010517          	auipc	a0,0x10
    80001a24:	f4850513          	addi	a0,a0,-184 # 80011968 <cpus>
    80001a28:	953e                	add	a0,a0,a5
    80001a2a:	6422                	ld	s0,8(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret

0000000080001a30 <myproc>:
myproc(void) {
    80001a30:	1101                	addi	sp,sp,-32
    80001a32:	ec06                	sd	ra,24(sp)
    80001a34:	e822                	sd	s0,16(sp)
    80001a36:	e426                	sd	s1,8(sp)
    80001a38:	1000                	addi	s0,sp,32
  push_off();
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	1dc080e7          	jalr	476(ra) # 80000c16 <push_off>
    80001a42:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a44:	2781                	sext.w	a5,a5
    80001a46:	079e                	slli	a5,a5,0x7
    80001a48:	00010717          	auipc	a4,0x10
    80001a4c:	f0870713          	addi	a4,a4,-248 # 80011950 <pid_lock>
    80001a50:	97ba                	add	a5,a5,a4
    80001a52:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	262080e7          	jalr	610(ra) # 80000cb6 <pop_off>
}
    80001a5c:	8526                	mv	a0,s1
    80001a5e:	60e2                	ld	ra,24(sp)
    80001a60:	6442                	ld	s0,16(sp)
    80001a62:	64a2                	ld	s1,8(sp)
    80001a64:	6105                	addi	sp,sp,32
    80001a66:	8082                	ret

0000000080001a68 <forkret>:
{
    80001a68:	1141                	addi	sp,sp,-16
    80001a6a:	e406                	sd	ra,8(sp)
    80001a6c:	e022                	sd	s0,0(sp)
    80001a6e:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a70:	00000097          	auipc	ra,0x0
    80001a74:	fc0080e7          	jalr	-64(ra) # 80001a30 <myproc>
    80001a78:	fffff097          	auipc	ra,0xfffff
    80001a7c:	29e080e7          	jalr	670(ra) # 80000d16 <release>
  if (first) {
    80001a80:	00007797          	auipc	a5,0x7
    80001a84:	f307a783          	lw	a5,-208(a5) # 800089b0 <first.1667>
    80001a88:	eb89                	bnez	a5,80001a9a <forkret+0x32>
  usertrapret();
    80001a8a:	00001097          	auipc	ra,0x1
    80001a8e:	c56080e7          	jalr	-938(ra) # 800026e0 <usertrapret>
}
    80001a92:	60a2                	ld	ra,8(sp)
    80001a94:	6402                	ld	s0,0(sp)
    80001a96:	0141                	addi	sp,sp,16
    80001a98:	8082                	ret
    first = 0;
    80001a9a:	00007797          	auipc	a5,0x7
    80001a9e:	f007ab23          	sw	zero,-234(a5) # 800089b0 <first.1667>
    fsinit(ROOTDEV);
    80001aa2:	4505                	li	a0,1
    80001aa4:	00002097          	auipc	ra,0x2
    80001aa8:	a36080e7          	jalr	-1482(ra) # 800034da <fsinit>
    80001aac:	bff9                	j	80001a8a <forkret+0x22>

0000000080001aae <allocpid>:
allocpid() {
    80001aae:	1101                	addi	sp,sp,-32
    80001ab0:	ec06                	sd	ra,24(sp)
    80001ab2:	e822                	sd	s0,16(sp)
    80001ab4:	e426                	sd	s1,8(sp)
    80001ab6:	e04a                	sd	s2,0(sp)
    80001ab8:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001aba:	00010917          	auipc	s2,0x10
    80001abe:	e9690913          	addi	s2,s2,-362 # 80011950 <pid_lock>
    80001ac2:	854a                	mv	a0,s2
    80001ac4:	fffff097          	auipc	ra,0xfffff
    80001ac8:	19e080e7          	jalr	414(ra) # 80000c62 <acquire>
  pid = nextpid;
    80001acc:	00007797          	auipc	a5,0x7
    80001ad0:	ee878793          	addi	a5,a5,-280 # 800089b4 <nextpid>
    80001ad4:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ad6:	0014871b          	addiw	a4,s1,1
    80001ada:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001adc:	854a                	mv	a0,s2
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	238080e7          	jalr	568(ra) # 80000d16 <release>
}
    80001ae6:	8526                	mv	a0,s1
    80001ae8:	60e2                	ld	ra,24(sp)
    80001aea:	6442                	ld	s0,16(sp)
    80001aec:	64a2                	ld	s1,8(sp)
    80001aee:	6902                	ld	s2,0(sp)
    80001af0:	6105                	addi	sp,sp,32
    80001af2:	8082                	ret

0000000080001af4 <proc_pagetable>:
{
    80001af4:	1101                	addi	sp,sp,-32
    80001af6:	ec06                	sd	ra,24(sp)
    80001af8:	e822                	sd	s0,16(sp)
    80001afa:	e426                	sd	s1,8(sp)
    80001afc:	e04a                	sd	s2,0(sp)
    80001afe:	1000                	addi	s0,sp,32
    80001b00:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b02:	00000097          	auipc	ra,0x0
    80001b06:	8ea080e7          	jalr	-1814(ra) # 800013ec <uvmcreate>
    80001b0a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b0c:	c121                	beqz	a0,80001b4c <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b0e:	4729                	li	a4,10
    80001b10:	00005697          	auipc	a3,0x5
    80001b14:	4f068693          	addi	a3,a3,1264 # 80007000 <_trampoline>
    80001b18:	6605                	lui	a2,0x1
    80001b1a:	040005b7          	lui	a1,0x4000
    80001b1e:	15fd                	addi	a1,a1,-1
    80001b20:	05b2                	slli	a1,a1,0xc
    80001b22:	fffff097          	auipc	ra,0xfffff
    80001b26:	66e080e7          	jalr	1646(ra) # 80001190 <mappages>
    80001b2a:	02054863          	bltz	a0,80001b5a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b2e:	4719                	li	a4,6
    80001b30:	05893683          	ld	a3,88(s2)
    80001b34:	6605                	lui	a2,0x1
    80001b36:	020005b7          	lui	a1,0x2000
    80001b3a:	15fd                	addi	a1,a1,-1
    80001b3c:	05b6                	slli	a1,a1,0xd
    80001b3e:	8526                	mv	a0,s1
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	650080e7          	jalr	1616(ra) # 80001190 <mappages>
    80001b48:	02054163          	bltz	a0,80001b6a <proc_pagetable+0x76>
}
    80001b4c:	8526                	mv	a0,s1
    80001b4e:	60e2                	ld	ra,24(sp)
    80001b50:	6442                	ld	s0,16(sp)
    80001b52:	64a2                	ld	s1,8(sp)
    80001b54:	6902                	ld	s2,0(sp)
    80001b56:	6105                	addi	sp,sp,32
    80001b58:	8082                	ret
    uvmfree(pagetable, 0);
    80001b5a:	4581                	li	a1,0
    80001b5c:	8526                	mv	a0,s1
    80001b5e:	00000097          	auipc	ra,0x0
    80001b62:	a8a080e7          	jalr	-1398(ra) # 800015e8 <uvmfree>
    return 0;
    80001b66:	4481                	li	s1,0
    80001b68:	b7d5                	j	80001b4c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b6a:	4681                	li	a3,0
    80001b6c:	4605                	li	a2,1
    80001b6e:	040005b7          	lui	a1,0x4000
    80001b72:	15fd                	addi	a1,a1,-1
    80001b74:	05b2                	slli	a1,a1,0xc
    80001b76:	8526                	mv	a0,s1
    80001b78:	fffff097          	auipc	ra,0xfffff
    80001b7c:	7b0080e7          	jalr	1968(ra) # 80001328 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b80:	4581                	li	a1,0
    80001b82:	8526                	mv	a0,s1
    80001b84:	00000097          	auipc	ra,0x0
    80001b88:	a64080e7          	jalr	-1436(ra) # 800015e8 <uvmfree>
    return 0;
    80001b8c:	4481                	li	s1,0
    80001b8e:	bf7d                	j	80001b4c <proc_pagetable+0x58>

0000000080001b90 <proc_freepagetable>:
{
    80001b90:	1101                	addi	sp,sp,-32
    80001b92:	ec06                	sd	ra,24(sp)
    80001b94:	e822                	sd	s0,16(sp)
    80001b96:	e426                	sd	s1,8(sp)
    80001b98:	e04a                	sd	s2,0(sp)
    80001b9a:	1000                	addi	s0,sp,32
    80001b9c:	84aa                	mv	s1,a0
    80001b9e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ba0:	4681                	li	a3,0
    80001ba2:	4605                	li	a2,1
    80001ba4:	040005b7          	lui	a1,0x4000
    80001ba8:	15fd                	addi	a1,a1,-1
    80001baa:	05b2                	slli	a1,a1,0xc
    80001bac:	fffff097          	auipc	ra,0xfffff
    80001bb0:	77c080e7          	jalr	1916(ra) # 80001328 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bb4:	4681                	li	a3,0
    80001bb6:	4605                	li	a2,1
    80001bb8:	020005b7          	lui	a1,0x2000
    80001bbc:	15fd                	addi	a1,a1,-1
    80001bbe:	05b6                	slli	a1,a1,0xd
    80001bc0:	8526                	mv	a0,s1
    80001bc2:	fffff097          	auipc	ra,0xfffff
    80001bc6:	766080e7          	jalr	1894(ra) # 80001328 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bca:	85ca                	mv	a1,s2
    80001bcc:	8526                	mv	a0,s1
    80001bce:	00000097          	auipc	ra,0x0
    80001bd2:	a1a080e7          	jalr	-1510(ra) # 800015e8 <uvmfree>
}
    80001bd6:	60e2                	ld	ra,24(sp)
    80001bd8:	6442                	ld	s0,16(sp)
    80001bda:	64a2                	ld	s1,8(sp)
    80001bdc:	6902                	ld	s2,0(sp)
    80001bde:	6105                	addi	sp,sp,32
    80001be0:	8082                	ret

0000000080001be2 <freeproc>:
{
    80001be2:	1101                	addi	sp,sp,-32
    80001be4:	ec06                	sd	ra,24(sp)
    80001be6:	e822                	sd	s0,16(sp)
    80001be8:	e426                	sd	s1,8(sp)
    80001bea:	1000                	addi	s0,sp,32
    80001bec:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bee:	6d28                	ld	a0,88(a0)
    80001bf0:	c509                	beqz	a0,80001bfa <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bf2:	fffff097          	auipc	ra,0xfffff
    80001bf6:	e32080e7          	jalr	-462(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001bfa:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bfe:	68a8                	ld	a0,80(s1)
    80001c00:	c511                	beqz	a0,80001c0c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c02:	64ac                	ld	a1,72(s1)
    80001c04:	00000097          	auipc	ra,0x0
    80001c08:	f8c080e7          	jalr	-116(ra) # 80001b90 <proc_freepagetable>
  p->pagetable = 0;
    80001c0c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c10:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c14:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c18:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c1c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c20:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c24:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c28:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c2c:	0004ac23          	sw	zero,24(s1)
}
    80001c30:	60e2                	ld	ra,24(sp)
    80001c32:	6442                	ld	s0,16(sp)
    80001c34:	64a2                	ld	s1,8(sp)
    80001c36:	6105                	addi	sp,sp,32
    80001c38:	8082                	ret

0000000080001c3a <allocproc>:
{
    80001c3a:	1101                	addi	sp,sp,-32
    80001c3c:	ec06                	sd	ra,24(sp)
    80001c3e:	e822                	sd	s0,16(sp)
    80001c40:	e426                	sd	s1,8(sp)
    80001c42:	e04a                	sd	s2,0(sp)
    80001c44:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c46:	00010497          	auipc	s1,0x10
    80001c4a:	12248493          	addi	s1,s1,290 # 80011d68 <proc>
    80001c4e:	00016917          	auipc	s2,0x16
    80001c52:	b1a90913          	addi	s2,s2,-1254 # 80017768 <tickslock>
    acquire(&p->lock);
    80001c56:	8526                	mv	a0,s1
    80001c58:	fffff097          	auipc	ra,0xfffff
    80001c5c:	00a080e7          	jalr	10(ra) # 80000c62 <acquire>
    if(p->state == UNUSED) {
    80001c60:	4c9c                	lw	a5,24(s1)
    80001c62:	cf81                	beqz	a5,80001c7a <allocproc+0x40>
      release(&p->lock);
    80001c64:	8526                	mv	a0,s1
    80001c66:	fffff097          	auipc	ra,0xfffff
    80001c6a:	0b0080e7          	jalr	176(ra) # 80000d16 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c6e:	16848493          	addi	s1,s1,360
    80001c72:	ff2492e3          	bne	s1,s2,80001c56 <allocproc+0x1c>
  return 0;
    80001c76:	4481                	li	s1,0
    80001c78:	a0b9                	j	80001cc6 <allocproc+0x8c>
  p->pid = allocpid();
    80001c7a:	00000097          	auipc	ra,0x0
    80001c7e:	e34080e7          	jalr	-460(ra) # 80001aae <allocpid>
    80001c82:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	e9c080e7          	jalr	-356(ra) # 80000b20 <kalloc>
    80001c8c:	892a                	mv	s2,a0
    80001c8e:	eca8                	sd	a0,88(s1)
    80001c90:	c131                	beqz	a0,80001cd4 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001c92:	8526                	mv	a0,s1
    80001c94:	00000097          	auipc	ra,0x0
    80001c98:	e60080e7          	jalr	-416(ra) # 80001af4 <proc_pagetable>
    80001c9c:	892a                	mv	s2,a0
    80001c9e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001ca0:	c129                	beqz	a0,80001ce2 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001ca2:	07000613          	li	a2,112
    80001ca6:	4581                	li	a1,0
    80001ca8:	06048513          	addi	a0,s1,96
    80001cac:	fffff097          	auipc	ra,0xfffff
    80001cb0:	0b2080e7          	jalr	178(ra) # 80000d5e <memset>
  p->context.ra = (uint64)forkret;
    80001cb4:	00000797          	auipc	a5,0x0
    80001cb8:	db478793          	addi	a5,a5,-588 # 80001a68 <forkret>
    80001cbc:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cbe:	60bc                	ld	a5,64(s1)
    80001cc0:	6705                	lui	a4,0x1
    80001cc2:	97ba                	add	a5,a5,a4
    80001cc4:	f4bc                	sd	a5,104(s1)
}
    80001cc6:	8526                	mv	a0,s1
    80001cc8:	60e2                	ld	ra,24(sp)
    80001cca:	6442                	ld	s0,16(sp)
    80001ccc:	64a2                	ld	s1,8(sp)
    80001cce:	6902                	ld	s2,0(sp)
    80001cd0:	6105                	addi	sp,sp,32
    80001cd2:	8082                	ret
    release(&p->lock);
    80001cd4:	8526                	mv	a0,s1
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	040080e7          	jalr	64(ra) # 80000d16 <release>
    return 0;
    80001cde:	84ca                	mv	s1,s2
    80001ce0:	b7dd                	j	80001cc6 <allocproc+0x8c>
    freeproc(p);
    80001ce2:	8526                	mv	a0,s1
    80001ce4:	00000097          	auipc	ra,0x0
    80001ce8:	efe080e7          	jalr	-258(ra) # 80001be2 <freeproc>
    release(&p->lock);
    80001cec:	8526                	mv	a0,s1
    80001cee:	fffff097          	auipc	ra,0xfffff
    80001cf2:	028080e7          	jalr	40(ra) # 80000d16 <release>
    return 0;
    80001cf6:	84ca                	mv	s1,s2
    80001cf8:	b7f9                	j	80001cc6 <allocproc+0x8c>

0000000080001cfa <userinit>:
{
    80001cfa:	1101                	addi	sp,sp,-32
    80001cfc:	ec06                	sd	ra,24(sp)
    80001cfe:	e822                	sd	s0,16(sp)
    80001d00:	e426                	sd	s1,8(sp)
    80001d02:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d04:	00000097          	auipc	ra,0x0
    80001d08:	f36080e7          	jalr	-202(ra) # 80001c3a <allocproc>
    80001d0c:	84aa                	mv	s1,a0
  initproc = p;
    80001d0e:	00007797          	auipc	a5,0x7
    80001d12:	30a7b523          	sd	a0,778(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d16:	03400613          	li	a2,52
    80001d1a:	00007597          	auipc	a1,0x7
    80001d1e:	ca658593          	addi	a1,a1,-858 # 800089c0 <initcode>
    80001d22:	6928                	ld	a0,80(a0)
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	6f6080e7          	jalr	1782(ra) # 8000141a <uvminit>
  p->sz = PGSIZE;
    80001d2c:	6785                	lui	a5,0x1
    80001d2e:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d30:	6cb8                	ld	a4,88(s1)
    80001d32:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d36:	6cb8                	ld	a4,88(s1)
    80001d38:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d3a:	4641                	li	a2,16
    80001d3c:	00006597          	auipc	a1,0x6
    80001d40:	4ac58593          	addi	a1,a1,1196 # 800081e8 <digits+0x1a8>
    80001d44:	15848513          	addi	a0,s1,344
    80001d48:	fffff097          	auipc	ra,0xfffff
    80001d4c:	16c080e7          	jalr	364(ra) # 80000eb4 <safestrcpy>
  p->cwd = namei("/");
    80001d50:	00006517          	auipc	a0,0x6
    80001d54:	4a850513          	addi	a0,a0,1192 # 800081f8 <digits+0x1b8>
    80001d58:	00002097          	auipc	ra,0x2
    80001d5c:	1aa080e7          	jalr	426(ra) # 80003f02 <namei>
    80001d60:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d64:	4789                	li	a5,2
    80001d66:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d68:	8526                	mv	a0,s1
    80001d6a:	fffff097          	auipc	ra,0xfffff
    80001d6e:	fac080e7          	jalr	-84(ra) # 80000d16 <release>
}
    80001d72:	60e2                	ld	ra,24(sp)
    80001d74:	6442                	ld	s0,16(sp)
    80001d76:	64a2                	ld	s1,8(sp)
    80001d78:	6105                	addi	sp,sp,32
    80001d7a:	8082                	ret

0000000080001d7c <growproc>:
{
    80001d7c:	1101                	addi	sp,sp,-32
    80001d7e:	ec06                	sd	ra,24(sp)
    80001d80:	e822                	sd	s0,16(sp)
    80001d82:	e426                	sd	s1,8(sp)
    80001d84:	e04a                	sd	s2,0(sp)
    80001d86:	1000                	addi	s0,sp,32
    80001d88:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d8a:	00000097          	auipc	ra,0x0
    80001d8e:	ca6080e7          	jalr	-858(ra) # 80001a30 <myproc>
    80001d92:	892a                	mv	s2,a0
  sz = p->sz;
    80001d94:	652c                	ld	a1,72(a0)
    80001d96:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d9a:	00904f63          	bgtz	s1,80001db8 <growproc+0x3c>
  } else if(n < 0){
    80001d9e:	0204cc63          	bltz	s1,80001dd6 <growproc+0x5a>
  p->sz = sz;
    80001da2:	1602                	slli	a2,a2,0x20
    80001da4:	9201                	srli	a2,a2,0x20
    80001da6:	04c93423          	sd	a2,72(s2)
  return 0;
    80001daa:	4501                	li	a0,0
}
    80001dac:	60e2                	ld	ra,24(sp)
    80001dae:	6442                	ld	s0,16(sp)
    80001db0:	64a2                	ld	s1,8(sp)
    80001db2:	6902                	ld	s2,0(sp)
    80001db4:	6105                	addi	sp,sp,32
    80001db6:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001db8:	9e25                	addw	a2,a2,s1
    80001dba:	1602                	slli	a2,a2,0x20
    80001dbc:	9201                	srli	a2,a2,0x20
    80001dbe:	1582                	slli	a1,a1,0x20
    80001dc0:	9181                	srli	a1,a1,0x20
    80001dc2:	6928                	ld	a0,80(a0)
    80001dc4:	fffff097          	auipc	ra,0xfffff
    80001dc8:	710080e7          	jalr	1808(ra) # 800014d4 <uvmalloc>
    80001dcc:	0005061b          	sext.w	a2,a0
    80001dd0:	fa69                	bnez	a2,80001da2 <growproc+0x26>
      return -1;
    80001dd2:	557d                	li	a0,-1
    80001dd4:	bfe1                	j	80001dac <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dd6:	9e25                	addw	a2,a2,s1
    80001dd8:	1602                	slli	a2,a2,0x20
    80001dda:	9201                	srli	a2,a2,0x20
    80001ddc:	1582                	slli	a1,a1,0x20
    80001dde:	9181                	srli	a1,a1,0x20
    80001de0:	6928                	ld	a0,80(a0)
    80001de2:	fffff097          	auipc	ra,0xfffff
    80001de6:	6aa080e7          	jalr	1706(ra) # 8000148c <uvmdealloc>
    80001dea:	0005061b          	sext.w	a2,a0
    80001dee:	bf55                	j	80001da2 <growproc+0x26>

0000000080001df0 <fork>:
{
    80001df0:	7179                	addi	sp,sp,-48
    80001df2:	f406                	sd	ra,40(sp)
    80001df4:	f022                	sd	s0,32(sp)
    80001df6:	ec26                	sd	s1,24(sp)
    80001df8:	e84a                	sd	s2,16(sp)
    80001dfa:	e44e                	sd	s3,8(sp)
    80001dfc:	e052                	sd	s4,0(sp)
    80001dfe:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e00:	00000097          	auipc	ra,0x0
    80001e04:	c30080e7          	jalr	-976(ra) # 80001a30 <myproc>
    80001e08:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e0a:	00000097          	auipc	ra,0x0
    80001e0e:	e30080e7          	jalr	-464(ra) # 80001c3a <allocproc>
    80001e12:	c575                	beqz	a0,80001efe <fork+0x10e>
    80001e14:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e16:	04893603          	ld	a2,72(s2)
    80001e1a:	692c                	ld	a1,80(a0)
    80001e1c:	05093503          	ld	a0,80(s2)
    80001e20:	00000097          	auipc	ra,0x0
    80001e24:	800080e7          	jalr	-2048(ra) # 80001620 <uvmcopy>
    80001e28:	04054863          	bltz	a0,80001e78 <fork+0x88>
  np->sz = p->sz;
    80001e2c:	04893783          	ld	a5,72(s2)
    80001e30:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001e34:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e38:	05893683          	ld	a3,88(s2)
    80001e3c:	87b6                	mv	a5,a3
    80001e3e:	0589b703          	ld	a4,88(s3)
    80001e42:	12068693          	addi	a3,a3,288
    80001e46:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e4a:	6788                	ld	a0,8(a5)
    80001e4c:	6b8c                	ld	a1,16(a5)
    80001e4e:	6f90                	ld	a2,24(a5)
    80001e50:	01073023          	sd	a6,0(a4)
    80001e54:	e708                	sd	a0,8(a4)
    80001e56:	eb0c                	sd	a1,16(a4)
    80001e58:	ef10                	sd	a2,24(a4)
    80001e5a:	02078793          	addi	a5,a5,32
    80001e5e:	02070713          	addi	a4,a4,32
    80001e62:	fed792e3          	bne	a5,a3,80001e46 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e66:	0589b783          	ld	a5,88(s3)
    80001e6a:	0607b823          	sd	zero,112(a5)
    80001e6e:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e72:	15000a13          	li	s4,336
    80001e76:	a03d                	j	80001ea4 <fork+0xb4>
    freeproc(np);
    80001e78:	854e                	mv	a0,s3
    80001e7a:	00000097          	auipc	ra,0x0
    80001e7e:	d68080e7          	jalr	-664(ra) # 80001be2 <freeproc>
    release(&np->lock);
    80001e82:	854e                	mv	a0,s3
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	e92080e7          	jalr	-366(ra) # 80000d16 <release>
    return -1;
    80001e8c:	54fd                	li	s1,-1
    80001e8e:	a8b9                	j	80001eec <fork+0xfc>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e90:	00002097          	auipc	ra,0x2
    80001e94:	6fe080e7          	jalr	1790(ra) # 8000458e <filedup>
    80001e98:	009987b3          	add	a5,s3,s1
    80001e9c:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e9e:	04a1                	addi	s1,s1,8
    80001ea0:	01448763          	beq	s1,s4,80001eae <fork+0xbe>
    if(p->ofile[i])
    80001ea4:	009907b3          	add	a5,s2,s1
    80001ea8:	6388                	ld	a0,0(a5)
    80001eaa:	f17d                	bnez	a0,80001e90 <fork+0xa0>
    80001eac:	bfcd                	j	80001e9e <fork+0xae>
  np->cwd = idup(p->cwd);
    80001eae:	15093503          	ld	a0,336(s2)
    80001eb2:	00002097          	auipc	ra,0x2
    80001eb6:	862080e7          	jalr	-1950(ra) # 80003714 <idup>
    80001eba:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ebe:	4641                	li	a2,16
    80001ec0:	15890593          	addi	a1,s2,344
    80001ec4:	15898513          	addi	a0,s3,344
    80001ec8:	fffff097          	auipc	ra,0xfffff
    80001ecc:	fec080e7          	jalr	-20(ra) # 80000eb4 <safestrcpy>
  pid = np->pid;
    80001ed0:	0389a483          	lw	s1,56(s3)
  np->tmask = p ->tmask;
    80001ed4:	03c92783          	lw	a5,60(s2)
    80001ed8:	02f9ae23          	sw	a5,60(s3)
  np->state = RUNNABLE;
    80001edc:	4789                	li	a5,2
    80001ede:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ee2:	854e                	mv	a0,s3
    80001ee4:	fffff097          	auipc	ra,0xfffff
    80001ee8:	e32080e7          	jalr	-462(ra) # 80000d16 <release>
}
    80001eec:	8526                	mv	a0,s1
    80001eee:	70a2                	ld	ra,40(sp)
    80001ef0:	7402                	ld	s0,32(sp)
    80001ef2:	64e2                	ld	s1,24(sp)
    80001ef4:	6942                	ld	s2,16(sp)
    80001ef6:	69a2                	ld	s3,8(sp)
    80001ef8:	6a02                	ld	s4,0(sp)
    80001efa:	6145                	addi	sp,sp,48
    80001efc:	8082                	ret
    return -1;
    80001efe:	54fd                	li	s1,-1
    80001f00:	b7f5                	j	80001eec <fork+0xfc>

0000000080001f02 <reparent>:
{
    80001f02:	7179                	addi	sp,sp,-48
    80001f04:	f406                	sd	ra,40(sp)
    80001f06:	f022                	sd	s0,32(sp)
    80001f08:	ec26                	sd	s1,24(sp)
    80001f0a:	e84a                	sd	s2,16(sp)
    80001f0c:	e44e                	sd	s3,8(sp)
    80001f0e:	e052                	sd	s4,0(sp)
    80001f10:	1800                	addi	s0,sp,48
    80001f12:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f14:	00010497          	auipc	s1,0x10
    80001f18:	e5448493          	addi	s1,s1,-428 # 80011d68 <proc>
      pp->parent = initproc;
    80001f1c:	00007a17          	auipc	s4,0x7
    80001f20:	0fca0a13          	addi	s4,s4,252 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f24:	00016997          	auipc	s3,0x16
    80001f28:	84498993          	addi	s3,s3,-1980 # 80017768 <tickslock>
    80001f2c:	a029                	j	80001f36 <reparent+0x34>
    80001f2e:	16848493          	addi	s1,s1,360
    80001f32:	03348363          	beq	s1,s3,80001f58 <reparent+0x56>
    if(pp->parent == p){
    80001f36:	709c                	ld	a5,32(s1)
    80001f38:	ff279be3          	bne	a5,s2,80001f2e <reparent+0x2c>
      acquire(&pp->lock);
    80001f3c:	8526                	mv	a0,s1
    80001f3e:	fffff097          	auipc	ra,0xfffff
    80001f42:	d24080e7          	jalr	-732(ra) # 80000c62 <acquire>
      pp->parent = initproc;
    80001f46:	000a3783          	ld	a5,0(s4)
    80001f4a:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f4c:	8526                	mv	a0,s1
    80001f4e:	fffff097          	auipc	ra,0xfffff
    80001f52:	dc8080e7          	jalr	-568(ra) # 80000d16 <release>
    80001f56:	bfe1                	j	80001f2e <reparent+0x2c>
}
    80001f58:	70a2                	ld	ra,40(sp)
    80001f5a:	7402                	ld	s0,32(sp)
    80001f5c:	64e2                	ld	s1,24(sp)
    80001f5e:	6942                	ld	s2,16(sp)
    80001f60:	69a2                	ld	s3,8(sp)
    80001f62:	6a02                	ld	s4,0(sp)
    80001f64:	6145                	addi	sp,sp,48
    80001f66:	8082                	ret

0000000080001f68 <scheduler>:
{
    80001f68:	715d                	addi	sp,sp,-80
    80001f6a:	e486                	sd	ra,72(sp)
    80001f6c:	e0a2                	sd	s0,64(sp)
    80001f6e:	fc26                	sd	s1,56(sp)
    80001f70:	f84a                	sd	s2,48(sp)
    80001f72:	f44e                	sd	s3,40(sp)
    80001f74:	f052                	sd	s4,32(sp)
    80001f76:	ec56                	sd	s5,24(sp)
    80001f78:	e85a                	sd	s6,16(sp)
    80001f7a:	e45e                	sd	s7,8(sp)
    80001f7c:	e062                	sd	s8,0(sp)
    80001f7e:	0880                	addi	s0,sp,80
    80001f80:	8792                	mv	a5,tp
  int id = r_tp();
    80001f82:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f84:	00779b13          	slli	s6,a5,0x7
    80001f88:	00010717          	auipc	a4,0x10
    80001f8c:	9c870713          	addi	a4,a4,-1592 # 80011950 <pid_lock>
    80001f90:	975a                	add	a4,a4,s6
    80001f92:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f96:	00010717          	auipc	a4,0x10
    80001f9a:	9da70713          	addi	a4,a4,-1574 # 80011970 <cpus+0x8>
    80001f9e:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001fa0:	4c0d                	li	s8,3
        c->proc = p;
    80001fa2:	079e                	slli	a5,a5,0x7
    80001fa4:	00010a17          	auipc	s4,0x10
    80001fa8:	9aca0a13          	addi	s4,s4,-1620 # 80011950 <pid_lock>
    80001fac:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fae:	00015997          	auipc	s3,0x15
    80001fb2:	7ba98993          	addi	s3,s3,1978 # 80017768 <tickslock>
        found = 1;
    80001fb6:	4b85                	li	s7,1
    80001fb8:	a899                	j	8000200e <scheduler+0xa6>
        p->state = RUNNING;
    80001fba:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001fbe:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001fc2:	06048593          	addi	a1,s1,96
    80001fc6:	855a                	mv	a0,s6
    80001fc8:	00000097          	auipc	ra,0x0
    80001fcc:	66e080e7          	jalr	1646(ra) # 80002636 <swtch>
        c->proc = 0;
    80001fd0:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001fd4:	8ade                	mv	s5,s7
      release(&p->lock);
    80001fd6:	8526                	mv	a0,s1
    80001fd8:	fffff097          	auipc	ra,0xfffff
    80001fdc:	d3e080e7          	jalr	-706(ra) # 80000d16 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fe0:	16848493          	addi	s1,s1,360
    80001fe4:	01348b63          	beq	s1,s3,80001ffa <scheduler+0x92>
      acquire(&p->lock);
    80001fe8:	8526                	mv	a0,s1
    80001fea:	fffff097          	auipc	ra,0xfffff
    80001fee:	c78080e7          	jalr	-904(ra) # 80000c62 <acquire>
      if(p->state == RUNNABLE) {
    80001ff2:	4c9c                	lw	a5,24(s1)
    80001ff4:	ff2791e3          	bne	a5,s2,80001fd6 <scheduler+0x6e>
    80001ff8:	b7c9                	j	80001fba <scheduler+0x52>
    if(found == 0) {
    80001ffa:	000a9a63          	bnez	s5,8000200e <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ffe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002002:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002006:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    8000200a:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000200e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002012:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002016:	10079073          	csrw	sstatus,a5
    int found = 0;
    8000201a:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    8000201c:	00010497          	auipc	s1,0x10
    80002020:	d4c48493          	addi	s1,s1,-692 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80002024:	4909                	li	s2,2
    80002026:	b7c9                	j	80001fe8 <scheduler+0x80>

0000000080002028 <sched>:
{
    80002028:	7179                	addi	sp,sp,-48
    8000202a:	f406                	sd	ra,40(sp)
    8000202c:	f022                	sd	s0,32(sp)
    8000202e:	ec26                	sd	s1,24(sp)
    80002030:	e84a                	sd	s2,16(sp)
    80002032:	e44e                	sd	s3,8(sp)
    80002034:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002036:	00000097          	auipc	ra,0x0
    8000203a:	9fa080e7          	jalr	-1542(ra) # 80001a30 <myproc>
    8000203e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002040:	fffff097          	auipc	ra,0xfffff
    80002044:	ba8080e7          	jalr	-1112(ra) # 80000be8 <holding>
    80002048:	c93d                	beqz	a0,800020be <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000204a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000204c:	2781                	sext.w	a5,a5
    8000204e:	079e                	slli	a5,a5,0x7
    80002050:	00010717          	auipc	a4,0x10
    80002054:	90070713          	addi	a4,a4,-1792 # 80011950 <pid_lock>
    80002058:	97ba                	add	a5,a5,a4
    8000205a:	0907a703          	lw	a4,144(a5)
    8000205e:	4785                	li	a5,1
    80002060:	06f71763          	bne	a4,a5,800020ce <sched+0xa6>
  if(p->state == RUNNING)
    80002064:	4c98                	lw	a4,24(s1)
    80002066:	478d                	li	a5,3
    80002068:	06f70b63          	beq	a4,a5,800020de <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000206c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002070:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002072:	efb5                	bnez	a5,800020ee <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002074:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002076:	00010917          	auipc	s2,0x10
    8000207a:	8da90913          	addi	s2,s2,-1830 # 80011950 <pid_lock>
    8000207e:	2781                	sext.w	a5,a5
    80002080:	079e                	slli	a5,a5,0x7
    80002082:	97ca                	add	a5,a5,s2
    80002084:	0947a983          	lw	s3,148(a5)
    80002088:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000208a:	2781                	sext.w	a5,a5
    8000208c:	079e                	slli	a5,a5,0x7
    8000208e:	00010597          	auipc	a1,0x10
    80002092:	8e258593          	addi	a1,a1,-1822 # 80011970 <cpus+0x8>
    80002096:	95be                	add	a1,a1,a5
    80002098:	06048513          	addi	a0,s1,96
    8000209c:	00000097          	auipc	ra,0x0
    800020a0:	59a080e7          	jalr	1434(ra) # 80002636 <swtch>
    800020a4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020a6:	2781                	sext.w	a5,a5
    800020a8:	079e                	slli	a5,a5,0x7
    800020aa:	97ca                	add	a5,a5,s2
    800020ac:	0937aa23          	sw	s3,148(a5)
}
    800020b0:	70a2                	ld	ra,40(sp)
    800020b2:	7402                	ld	s0,32(sp)
    800020b4:	64e2                	ld	s1,24(sp)
    800020b6:	6942                	ld	s2,16(sp)
    800020b8:	69a2                	ld	s3,8(sp)
    800020ba:	6145                	addi	sp,sp,48
    800020bc:	8082                	ret
    panic("sched p->lock");
    800020be:	00006517          	auipc	a0,0x6
    800020c2:	14250513          	addi	a0,a0,322 # 80008200 <digits+0x1c0>
    800020c6:	ffffe097          	auipc	ra,0xffffe
    800020ca:	482080e7          	jalr	1154(ra) # 80000548 <panic>
    panic("sched locks");
    800020ce:	00006517          	auipc	a0,0x6
    800020d2:	14250513          	addi	a0,a0,322 # 80008210 <digits+0x1d0>
    800020d6:	ffffe097          	auipc	ra,0xffffe
    800020da:	472080e7          	jalr	1138(ra) # 80000548 <panic>
    panic("sched running");
    800020de:	00006517          	auipc	a0,0x6
    800020e2:	14250513          	addi	a0,a0,322 # 80008220 <digits+0x1e0>
    800020e6:	ffffe097          	auipc	ra,0xffffe
    800020ea:	462080e7          	jalr	1122(ra) # 80000548 <panic>
    panic("sched interruptible");
    800020ee:	00006517          	auipc	a0,0x6
    800020f2:	14250513          	addi	a0,a0,322 # 80008230 <digits+0x1f0>
    800020f6:	ffffe097          	auipc	ra,0xffffe
    800020fa:	452080e7          	jalr	1106(ra) # 80000548 <panic>

00000000800020fe <exit>:
{
    800020fe:	7179                	addi	sp,sp,-48
    80002100:	f406                	sd	ra,40(sp)
    80002102:	f022                	sd	s0,32(sp)
    80002104:	ec26                	sd	s1,24(sp)
    80002106:	e84a                	sd	s2,16(sp)
    80002108:	e44e                	sd	s3,8(sp)
    8000210a:	e052                	sd	s4,0(sp)
    8000210c:	1800                	addi	s0,sp,48
    8000210e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002110:	00000097          	auipc	ra,0x0
    80002114:	920080e7          	jalr	-1760(ra) # 80001a30 <myproc>
    80002118:	89aa                	mv	s3,a0
  if(p == initproc)
    8000211a:	00007797          	auipc	a5,0x7
    8000211e:	efe7b783          	ld	a5,-258(a5) # 80009018 <initproc>
    80002122:	0d050493          	addi	s1,a0,208
    80002126:	15050913          	addi	s2,a0,336
    8000212a:	02a79363          	bne	a5,a0,80002150 <exit+0x52>
    panic("init exiting");
    8000212e:	00006517          	auipc	a0,0x6
    80002132:	11a50513          	addi	a0,a0,282 # 80008248 <digits+0x208>
    80002136:	ffffe097          	auipc	ra,0xffffe
    8000213a:	412080e7          	jalr	1042(ra) # 80000548 <panic>
      fileclose(f);
    8000213e:	00002097          	auipc	ra,0x2
    80002142:	4a2080e7          	jalr	1186(ra) # 800045e0 <fileclose>
      p->ofile[fd] = 0;
    80002146:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000214a:	04a1                	addi	s1,s1,8
    8000214c:	01248563          	beq	s1,s2,80002156 <exit+0x58>
    if(p->ofile[fd]){
    80002150:	6088                	ld	a0,0(s1)
    80002152:	f575                	bnez	a0,8000213e <exit+0x40>
    80002154:	bfdd                	j	8000214a <exit+0x4c>
  begin_op();
    80002156:	00002097          	auipc	ra,0x2
    8000215a:	fb8080e7          	jalr	-72(ra) # 8000410e <begin_op>
  iput(p->cwd);
    8000215e:	1509b503          	ld	a0,336(s3)
    80002162:	00001097          	auipc	ra,0x1
    80002166:	7aa080e7          	jalr	1962(ra) # 8000390c <iput>
  end_op();
    8000216a:	00002097          	auipc	ra,0x2
    8000216e:	024080e7          	jalr	36(ra) # 8000418e <end_op>
  p->cwd = 0;
    80002172:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002176:	00007497          	auipc	s1,0x7
    8000217a:	ea248493          	addi	s1,s1,-350 # 80009018 <initproc>
    8000217e:	6088                	ld	a0,0(s1)
    80002180:	fffff097          	auipc	ra,0xfffff
    80002184:	ae2080e7          	jalr	-1310(ra) # 80000c62 <acquire>
  wakeup1(initproc);
    80002188:	6088                	ld	a0,0(s1)
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	766080e7          	jalr	1894(ra) # 800018f0 <wakeup1>
  release(&initproc->lock);
    80002192:	6088                	ld	a0,0(s1)
    80002194:	fffff097          	auipc	ra,0xfffff
    80002198:	b82080e7          	jalr	-1150(ra) # 80000d16 <release>
  acquire(&p->lock);
    8000219c:	854e                	mv	a0,s3
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	ac4080e7          	jalr	-1340(ra) # 80000c62 <acquire>
  struct proc *original_parent = p->parent;
    800021a6:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800021aa:	854e                	mv	a0,s3
    800021ac:	fffff097          	auipc	ra,0xfffff
    800021b0:	b6a080e7          	jalr	-1174(ra) # 80000d16 <release>
  acquire(&original_parent->lock);
    800021b4:	8526                	mv	a0,s1
    800021b6:	fffff097          	auipc	ra,0xfffff
    800021ba:	aac080e7          	jalr	-1364(ra) # 80000c62 <acquire>
  acquire(&p->lock);
    800021be:	854e                	mv	a0,s3
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	aa2080e7          	jalr	-1374(ra) # 80000c62 <acquire>
  reparent(p);
    800021c8:	854e                	mv	a0,s3
    800021ca:	00000097          	auipc	ra,0x0
    800021ce:	d38080e7          	jalr	-712(ra) # 80001f02 <reparent>
  wakeup1(original_parent);
    800021d2:	8526                	mv	a0,s1
    800021d4:	fffff097          	auipc	ra,0xfffff
    800021d8:	71c080e7          	jalr	1820(ra) # 800018f0 <wakeup1>
  p->xstate = status;
    800021dc:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800021e0:	4791                	li	a5,4
    800021e2:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800021e6:	8526                	mv	a0,s1
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	b2e080e7          	jalr	-1234(ra) # 80000d16 <release>
  sched();
    800021f0:	00000097          	auipc	ra,0x0
    800021f4:	e38080e7          	jalr	-456(ra) # 80002028 <sched>
  panic("zombie exit");
    800021f8:	00006517          	auipc	a0,0x6
    800021fc:	06050513          	addi	a0,a0,96 # 80008258 <digits+0x218>
    80002200:	ffffe097          	auipc	ra,0xffffe
    80002204:	348080e7          	jalr	840(ra) # 80000548 <panic>

0000000080002208 <yield>:
{
    80002208:	1101                	addi	sp,sp,-32
    8000220a:	ec06                	sd	ra,24(sp)
    8000220c:	e822                	sd	s0,16(sp)
    8000220e:	e426                	sd	s1,8(sp)
    80002210:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002212:	00000097          	auipc	ra,0x0
    80002216:	81e080e7          	jalr	-2018(ra) # 80001a30 <myproc>
    8000221a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	a46080e7          	jalr	-1466(ra) # 80000c62 <acquire>
  p->state = RUNNABLE;
    80002224:	4789                	li	a5,2
    80002226:	cc9c                	sw	a5,24(s1)
  sched();
    80002228:	00000097          	auipc	ra,0x0
    8000222c:	e00080e7          	jalr	-512(ra) # 80002028 <sched>
  release(&p->lock);
    80002230:	8526                	mv	a0,s1
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	ae4080e7          	jalr	-1308(ra) # 80000d16 <release>
}
    8000223a:	60e2                	ld	ra,24(sp)
    8000223c:	6442                	ld	s0,16(sp)
    8000223e:	64a2                	ld	s1,8(sp)
    80002240:	6105                	addi	sp,sp,32
    80002242:	8082                	ret

0000000080002244 <sleep>:
{
    80002244:	7179                	addi	sp,sp,-48
    80002246:	f406                	sd	ra,40(sp)
    80002248:	f022                	sd	s0,32(sp)
    8000224a:	ec26                	sd	s1,24(sp)
    8000224c:	e84a                	sd	s2,16(sp)
    8000224e:	e44e                	sd	s3,8(sp)
    80002250:	1800                	addi	s0,sp,48
    80002252:	89aa                	mv	s3,a0
    80002254:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	7da080e7          	jalr	2010(ra) # 80001a30 <myproc>
    8000225e:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002260:	05250663          	beq	a0,s2,800022ac <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002264:	fffff097          	auipc	ra,0xfffff
    80002268:	9fe080e7          	jalr	-1538(ra) # 80000c62 <acquire>
    release(lk);
    8000226c:	854a                	mv	a0,s2
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	aa8080e7          	jalr	-1368(ra) # 80000d16 <release>
  p->chan = chan;
    80002276:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000227a:	4785                	li	a5,1
    8000227c:	cc9c                	sw	a5,24(s1)
  sched();
    8000227e:	00000097          	auipc	ra,0x0
    80002282:	daa080e7          	jalr	-598(ra) # 80002028 <sched>
  p->chan = 0;
    80002286:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000228a:	8526                	mv	a0,s1
    8000228c:	fffff097          	auipc	ra,0xfffff
    80002290:	a8a080e7          	jalr	-1398(ra) # 80000d16 <release>
    acquire(lk);
    80002294:	854a                	mv	a0,s2
    80002296:	fffff097          	auipc	ra,0xfffff
    8000229a:	9cc080e7          	jalr	-1588(ra) # 80000c62 <acquire>
}
    8000229e:	70a2                	ld	ra,40(sp)
    800022a0:	7402                	ld	s0,32(sp)
    800022a2:	64e2                	ld	s1,24(sp)
    800022a4:	6942                	ld	s2,16(sp)
    800022a6:	69a2                	ld	s3,8(sp)
    800022a8:	6145                	addi	sp,sp,48
    800022aa:	8082                	ret
  p->chan = chan;
    800022ac:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800022b0:	4785                	li	a5,1
    800022b2:	cd1c                	sw	a5,24(a0)
  sched();
    800022b4:	00000097          	auipc	ra,0x0
    800022b8:	d74080e7          	jalr	-652(ra) # 80002028 <sched>
  p->chan = 0;
    800022bc:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800022c0:	bff9                	j	8000229e <sleep+0x5a>

00000000800022c2 <wait>:
{
    800022c2:	715d                	addi	sp,sp,-80
    800022c4:	e486                	sd	ra,72(sp)
    800022c6:	e0a2                	sd	s0,64(sp)
    800022c8:	fc26                	sd	s1,56(sp)
    800022ca:	f84a                	sd	s2,48(sp)
    800022cc:	f44e                	sd	s3,40(sp)
    800022ce:	f052                	sd	s4,32(sp)
    800022d0:	ec56                	sd	s5,24(sp)
    800022d2:	e85a                	sd	s6,16(sp)
    800022d4:	e45e                	sd	s7,8(sp)
    800022d6:	e062                	sd	s8,0(sp)
    800022d8:	0880                	addi	s0,sp,80
    800022da:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	754080e7          	jalr	1876(ra) # 80001a30 <myproc>
    800022e4:	892a                	mv	s2,a0
  acquire(&p->lock);
    800022e6:	8c2a                	mv	s8,a0
    800022e8:	fffff097          	auipc	ra,0xfffff
    800022ec:	97a080e7          	jalr	-1670(ra) # 80000c62 <acquire>
    havekids = 0;
    800022f0:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022f2:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800022f4:	00015997          	auipc	s3,0x15
    800022f8:	47498993          	addi	s3,s3,1140 # 80017768 <tickslock>
        havekids = 1;
    800022fc:	4a85                	li	s5,1
    havekids = 0;
    800022fe:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002300:	00010497          	auipc	s1,0x10
    80002304:	a6848493          	addi	s1,s1,-1432 # 80011d68 <proc>
    80002308:	a08d                	j	8000236a <wait+0xa8>
          pid = np->pid;
    8000230a:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000230e:	000b0e63          	beqz	s6,8000232a <wait+0x68>
    80002312:	4691                	li	a3,4
    80002314:	03448613          	addi	a2,s1,52
    80002318:	85da                	mv	a1,s6
    8000231a:	05093503          	ld	a0,80(s2)
    8000231e:	fffff097          	auipc	ra,0xfffff
    80002322:	406080e7          	jalr	1030(ra) # 80001724 <copyout>
    80002326:	02054263          	bltz	a0,8000234a <wait+0x88>
          freeproc(np);
    8000232a:	8526                	mv	a0,s1
    8000232c:	00000097          	auipc	ra,0x0
    80002330:	8b6080e7          	jalr	-1866(ra) # 80001be2 <freeproc>
          release(&np->lock);
    80002334:	8526                	mv	a0,s1
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	9e0080e7          	jalr	-1568(ra) # 80000d16 <release>
          release(&p->lock);
    8000233e:	854a                	mv	a0,s2
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	9d6080e7          	jalr	-1578(ra) # 80000d16 <release>
          return pid;
    80002348:	a8a9                	j	800023a2 <wait+0xe0>
            release(&np->lock);
    8000234a:	8526                	mv	a0,s1
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	9ca080e7          	jalr	-1590(ra) # 80000d16 <release>
            release(&p->lock);
    80002354:	854a                	mv	a0,s2
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	9c0080e7          	jalr	-1600(ra) # 80000d16 <release>
            return -1;
    8000235e:	59fd                	li	s3,-1
    80002360:	a089                	j	800023a2 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002362:	16848493          	addi	s1,s1,360
    80002366:	03348463          	beq	s1,s3,8000238e <wait+0xcc>
      if(np->parent == p){
    8000236a:	709c                	ld	a5,32(s1)
    8000236c:	ff279be3          	bne	a5,s2,80002362 <wait+0xa0>
        acquire(&np->lock);
    80002370:	8526                	mv	a0,s1
    80002372:	fffff097          	auipc	ra,0xfffff
    80002376:	8f0080e7          	jalr	-1808(ra) # 80000c62 <acquire>
        if(np->state == ZOMBIE){
    8000237a:	4c9c                	lw	a5,24(s1)
    8000237c:	f94787e3          	beq	a5,s4,8000230a <wait+0x48>
        release(&np->lock);
    80002380:	8526                	mv	a0,s1
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	994080e7          	jalr	-1644(ra) # 80000d16 <release>
        havekids = 1;
    8000238a:	8756                	mv	a4,s5
    8000238c:	bfd9                	j	80002362 <wait+0xa0>
    if(!havekids || p->killed){
    8000238e:	c701                	beqz	a4,80002396 <wait+0xd4>
    80002390:	03092783          	lw	a5,48(s2)
    80002394:	c785                	beqz	a5,800023bc <wait+0xfa>
      release(&p->lock);
    80002396:	854a                	mv	a0,s2
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	97e080e7          	jalr	-1666(ra) # 80000d16 <release>
      return -1;
    800023a0:	59fd                	li	s3,-1
}
    800023a2:	854e                	mv	a0,s3
    800023a4:	60a6                	ld	ra,72(sp)
    800023a6:	6406                	ld	s0,64(sp)
    800023a8:	74e2                	ld	s1,56(sp)
    800023aa:	7942                	ld	s2,48(sp)
    800023ac:	79a2                	ld	s3,40(sp)
    800023ae:	7a02                	ld	s4,32(sp)
    800023b0:	6ae2                	ld	s5,24(sp)
    800023b2:	6b42                	ld	s6,16(sp)
    800023b4:	6ba2                	ld	s7,8(sp)
    800023b6:	6c02                	ld	s8,0(sp)
    800023b8:	6161                	addi	sp,sp,80
    800023ba:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800023bc:	85e2                	mv	a1,s8
    800023be:	854a                	mv	a0,s2
    800023c0:	00000097          	auipc	ra,0x0
    800023c4:	e84080e7          	jalr	-380(ra) # 80002244 <sleep>
    havekids = 0;
    800023c8:	bf1d                	j	800022fe <wait+0x3c>

00000000800023ca <wakeup>:
{
    800023ca:	7139                	addi	sp,sp,-64
    800023cc:	fc06                	sd	ra,56(sp)
    800023ce:	f822                	sd	s0,48(sp)
    800023d0:	f426                	sd	s1,40(sp)
    800023d2:	f04a                	sd	s2,32(sp)
    800023d4:	ec4e                	sd	s3,24(sp)
    800023d6:	e852                	sd	s4,16(sp)
    800023d8:	e456                	sd	s5,8(sp)
    800023da:	0080                	addi	s0,sp,64
    800023dc:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800023de:	00010497          	auipc	s1,0x10
    800023e2:	98a48493          	addi	s1,s1,-1654 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800023e6:	4985                	li	s3,1
      p->state = RUNNABLE;
    800023e8:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800023ea:	00015917          	auipc	s2,0x15
    800023ee:	37e90913          	addi	s2,s2,894 # 80017768 <tickslock>
    800023f2:	a821                	j	8000240a <wakeup+0x40>
      p->state = RUNNABLE;
    800023f4:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800023f8:	8526                	mv	a0,s1
    800023fa:	fffff097          	auipc	ra,0xfffff
    800023fe:	91c080e7          	jalr	-1764(ra) # 80000d16 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002402:	16848493          	addi	s1,s1,360
    80002406:	01248e63          	beq	s1,s2,80002422 <wakeup+0x58>
    acquire(&p->lock);
    8000240a:	8526                	mv	a0,s1
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	856080e7          	jalr	-1962(ra) # 80000c62 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002414:	4c9c                	lw	a5,24(s1)
    80002416:	ff3791e3          	bne	a5,s3,800023f8 <wakeup+0x2e>
    8000241a:	749c                	ld	a5,40(s1)
    8000241c:	fd479ee3          	bne	a5,s4,800023f8 <wakeup+0x2e>
    80002420:	bfd1                	j	800023f4 <wakeup+0x2a>
}
    80002422:	70e2                	ld	ra,56(sp)
    80002424:	7442                	ld	s0,48(sp)
    80002426:	74a2                	ld	s1,40(sp)
    80002428:	7902                	ld	s2,32(sp)
    8000242a:	69e2                	ld	s3,24(sp)
    8000242c:	6a42                	ld	s4,16(sp)
    8000242e:	6aa2                	ld	s5,8(sp)
    80002430:	6121                	addi	sp,sp,64
    80002432:	8082                	ret

0000000080002434 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002434:	7179                	addi	sp,sp,-48
    80002436:	f406                	sd	ra,40(sp)
    80002438:	f022                	sd	s0,32(sp)
    8000243a:	ec26                	sd	s1,24(sp)
    8000243c:	e84a                	sd	s2,16(sp)
    8000243e:	e44e                	sd	s3,8(sp)
    80002440:	1800                	addi	s0,sp,48
    80002442:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002444:	00010497          	auipc	s1,0x10
    80002448:	92448493          	addi	s1,s1,-1756 # 80011d68 <proc>
    8000244c:	00015997          	auipc	s3,0x15
    80002450:	31c98993          	addi	s3,s3,796 # 80017768 <tickslock>
    acquire(&p->lock);
    80002454:	8526                	mv	a0,s1
    80002456:	fffff097          	auipc	ra,0xfffff
    8000245a:	80c080e7          	jalr	-2036(ra) # 80000c62 <acquire>
    if(p->pid == pid){
    8000245e:	5c9c                	lw	a5,56(s1)
    80002460:	01278d63          	beq	a5,s2,8000247a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002464:	8526                	mv	a0,s1
    80002466:	fffff097          	auipc	ra,0xfffff
    8000246a:	8b0080e7          	jalr	-1872(ra) # 80000d16 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000246e:	16848493          	addi	s1,s1,360
    80002472:	ff3491e3          	bne	s1,s3,80002454 <kill+0x20>
  }
  return -1;
    80002476:	557d                	li	a0,-1
    80002478:	a829                	j	80002492 <kill+0x5e>
      p->killed = 1;
    8000247a:	4785                	li	a5,1
    8000247c:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    8000247e:	4c98                	lw	a4,24(s1)
    80002480:	4785                	li	a5,1
    80002482:	00f70f63          	beq	a4,a5,800024a0 <kill+0x6c>
      release(&p->lock);
    80002486:	8526                	mv	a0,s1
    80002488:	fffff097          	auipc	ra,0xfffff
    8000248c:	88e080e7          	jalr	-1906(ra) # 80000d16 <release>
      return 0;
    80002490:	4501                	li	a0,0
}
    80002492:	70a2                	ld	ra,40(sp)
    80002494:	7402                	ld	s0,32(sp)
    80002496:	64e2                	ld	s1,24(sp)
    80002498:	6942                	ld	s2,16(sp)
    8000249a:	69a2                	ld	s3,8(sp)
    8000249c:	6145                	addi	sp,sp,48
    8000249e:	8082                	ret
        p->state = RUNNABLE;
    800024a0:	4789                	li	a5,2
    800024a2:	cc9c                	sw	a5,24(s1)
    800024a4:	b7cd                	j	80002486 <kill+0x52>

00000000800024a6 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024a6:	7179                	addi	sp,sp,-48
    800024a8:	f406                	sd	ra,40(sp)
    800024aa:	f022                	sd	s0,32(sp)
    800024ac:	ec26                	sd	s1,24(sp)
    800024ae:	e84a                	sd	s2,16(sp)
    800024b0:	e44e                	sd	s3,8(sp)
    800024b2:	e052                	sd	s4,0(sp)
    800024b4:	1800                	addi	s0,sp,48
    800024b6:	84aa                	mv	s1,a0
    800024b8:	892e                	mv	s2,a1
    800024ba:	89b2                	mv	s3,a2
    800024bc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024be:	fffff097          	auipc	ra,0xfffff
    800024c2:	572080e7          	jalr	1394(ra) # 80001a30 <myproc>
  if(user_dst){
    800024c6:	c08d                	beqz	s1,800024e8 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024c8:	86d2                	mv	a3,s4
    800024ca:	864e                	mv	a2,s3
    800024cc:	85ca                	mv	a1,s2
    800024ce:	6928                	ld	a0,80(a0)
    800024d0:	fffff097          	auipc	ra,0xfffff
    800024d4:	254080e7          	jalr	596(ra) # 80001724 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024d8:	70a2                	ld	ra,40(sp)
    800024da:	7402                	ld	s0,32(sp)
    800024dc:	64e2                	ld	s1,24(sp)
    800024de:	6942                	ld	s2,16(sp)
    800024e0:	69a2                	ld	s3,8(sp)
    800024e2:	6a02                	ld	s4,0(sp)
    800024e4:	6145                	addi	sp,sp,48
    800024e6:	8082                	ret
    memmove((char *)dst, src, len);
    800024e8:	000a061b          	sext.w	a2,s4
    800024ec:	85ce                	mv	a1,s3
    800024ee:	854a                	mv	a0,s2
    800024f0:	fffff097          	auipc	ra,0xfffff
    800024f4:	8ce080e7          	jalr	-1842(ra) # 80000dbe <memmove>
    return 0;
    800024f8:	8526                	mv	a0,s1
    800024fa:	bff9                	j	800024d8 <either_copyout+0x32>

00000000800024fc <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024fc:	7179                	addi	sp,sp,-48
    800024fe:	f406                	sd	ra,40(sp)
    80002500:	f022                	sd	s0,32(sp)
    80002502:	ec26                	sd	s1,24(sp)
    80002504:	e84a                	sd	s2,16(sp)
    80002506:	e44e                	sd	s3,8(sp)
    80002508:	e052                	sd	s4,0(sp)
    8000250a:	1800                	addi	s0,sp,48
    8000250c:	892a                	mv	s2,a0
    8000250e:	84ae                	mv	s1,a1
    80002510:	89b2                	mv	s3,a2
    80002512:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002514:	fffff097          	auipc	ra,0xfffff
    80002518:	51c080e7          	jalr	1308(ra) # 80001a30 <myproc>
  if(user_src){
    8000251c:	c08d                	beqz	s1,8000253e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000251e:	86d2                	mv	a3,s4
    80002520:	864e                	mv	a2,s3
    80002522:	85ca                	mv	a1,s2
    80002524:	6928                	ld	a0,80(a0)
    80002526:	fffff097          	auipc	ra,0xfffff
    8000252a:	28a080e7          	jalr	650(ra) # 800017b0 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000252e:	70a2                	ld	ra,40(sp)
    80002530:	7402                	ld	s0,32(sp)
    80002532:	64e2                	ld	s1,24(sp)
    80002534:	6942                	ld	s2,16(sp)
    80002536:	69a2                	ld	s3,8(sp)
    80002538:	6a02                	ld	s4,0(sp)
    8000253a:	6145                	addi	sp,sp,48
    8000253c:	8082                	ret
    memmove(dst, (char*)src, len);
    8000253e:	000a061b          	sext.w	a2,s4
    80002542:	85ce                	mv	a1,s3
    80002544:	854a                	mv	a0,s2
    80002546:	fffff097          	auipc	ra,0xfffff
    8000254a:	878080e7          	jalr	-1928(ra) # 80000dbe <memmove>
    return 0;
    8000254e:	8526                	mv	a0,s1
    80002550:	bff9                	j	8000252e <either_copyin+0x32>

0000000080002552 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002552:	715d                	addi	sp,sp,-80
    80002554:	e486                	sd	ra,72(sp)
    80002556:	e0a2                	sd	s0,64(sp)
    80002558:	fc26                	sd	s1,56(sp)
    8000255a:	f84a                	sd	s2,48(sp)
    8000255c:	f44e                	sd	s3,40(sp)
    8000255e:	f052                	sd	s4,32(sp)
    80002560:	ec56                	sd	s5,24(sp)
    80002562:	e85a                	sd	s6,16(sp)
    80002564:	e45e                	sd	s7,8(sp)
    80002566:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002568:	00006517          	auipc	a0,0x6
    8000256c:	b6050513          	addi	a0,a0,-1184 # 800080c8 <digits+0x88>
    80002570:	ffffe097          	auipc	ra,0xffffe
    80002574:	022080e7          	jalr	34(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002578:	00010497          	auipc	s1,0x10
    8000257c:	94848493          	addi	s1,s1,-1720 # 80011ec0 <proc+0x158>
    80002580:	00015917          	auipc	s2,0x15
    80002584:	34090913          	addi	s2,s2,832 # 800178c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002588:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000258a:	00006997          	auipc	s3,0x6
    8000258e:	cde98993          	addi	s3,s3,-802 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    80002592:	00006a97          	auipc	s5,0x6
    80002596:	cdea8a93          	addi	s5,s5,-802 # 80008270 <digits+0x230>
    printf("\n");
    8000259a:	00006a17          	auipc	s4,0x6
    8000259e:	b2ea0a13          	addi	s4,s4,-1234 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025a2:	00006b97          	auipc	s7,0x6
    800025a6:	d06b8b93          	addi	s7,s7,-762 # 800082a8 <states.1707>
    800025aa:	a00d                	j	800025cc <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025ac:	ee06a583          	lw	a1,-288(a3)
    800025b0:	8556                	mv	a0,s5
    800025b2:	ffffe097          	auipc	ra,0xffffe
    800025b6:	fe0080e7          	jalr	-32(ra) # 80000592 <printf>
    printf("\n");
    800025ba:	8552                	mv	a0,s4
    800025bc:	ffffe097          	auipc	ra,0xffffe
    800025c0:	fd6080e7          	jalr	-42(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025c4:	16848493          	addi	s1,s1,360
    800025c8:	03248163          	beq	s1,s2,800025ea <procdump+0x98>
    if(p->state == UNUSED)
    800025cc:	86a6                	mv	a3,s1
    800025ce:	ec04a783          	lw	a5,-320(s1)
    800025d2:	dbed                	beqz	a5,800025c4 <procdump+0x72>
      state = "???";
    800025d4:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025d6:	fcfb6be3          	bltu	s6,a5,800025ac <procdump+0x5a>
    800025da:	1782                	slli	a5,a5,0x20
    800025dc:	9381                	srli	a5,a5,0x20
    800025de:	078e                	slli	a5,a5,0x3
    800025e0:	97de                	add	a5,a5,s7
    800025e2:	6390                	ld	a2,0(a5)
    800025e4:	f661                	bnez	a2,800025ac <procdump+0x5a>
      state = "???";
    800025e6:	864e                	mv	a2,s3
    800025e8:	b7d1                	j	800025ac <procdump+0x5a>
  }
}
    800025ea:	60a6                	ld	ra,72(sp)
    800025ec:	6406                	ld	s0,64(sp)
    800025ee:	74e2                	ld	s1,56(sp)
    800025f0:	7942                	ld	s2,48(sp)
    800025f2:	79a2                	ld	s3,40(sp)
    800025f4:	7a02                	ld	s4,32(sp)
    800025f6:	6ae2                	ld	s5,24(sp)
    800025f8:	6b42                	ld	s6,16(sp)
    800025fa:	6ba2                	ld	s7,8(sp)
    800025fc:	6161                	addi	sp,sp,80
    800025fe:	8082                	ret

0000000080002600 <procnum>:

void            
procnum(uint64* dst)
{
    80002600:	1141                	addi	sp,sp,-16
    80002602:	e422                	sd	s0,8(sp)
    80002604:	0800                	addi	s0,sp,16
  *(dst)=0;
    80002606:	00053023          	sd	zero,0(a0)
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++)
    8000260a:	0000f797          	auipc	a5,0xf
    8000260e:	75e78793          	addi	a5,a5,1886 # 80011d68 <proc>
    80002612:	00015697          	auipc	a3,0x15
    80002616:	15668693          	addi	a3,a3,342 # 80017768 <tickslock>
    8000261a:	a029                	j	80002624 <procnum+0x24>
    8000261c:	16878793          	addi	a5,a5,360
    80002620:	00d78863          	beq	a5,a3,80002630 <procnum+0x30>
  {
    if(p->state != UNUSED)
    80002624:	4f98                	lw	a4,24(a5)
    80002626:	db7d                	beqz	a4,8000261c <procnum+0x1c>
       *(dst)+=1; 
    80002628:	6118                	ld	a4,0(a0)
    8000262a:	0705                	addi	a4,a4,1
    8000262c:	e118                	sd	a4,0(a0)
    8000262e:	b7fd                	j	8000261c <procnum+0x1c>
  }
    80002630:	6422                	ld	s0,8(sp)
    80002632:	0141                	addi	sp,sp,16
    80002634:	8082                	ret

0000000080002636 <swtch>:
    80002636:	00153023          	sd	ra,0(a0)
    8000263a:	00253423          	sd	sp,8(a0)
    8000263e:	e900                	sd	s0,16(a0)
    80002640:	ed04                	sd	s1,24(a0)
    80002642:	03253023          	sd	s2,32(a0)
    80002646:	03353423          	sd	s3,40(a0)
    8000264a:	03453823          	sd	s4,48(a0)
    8000264e:	03553c23          	sd	s5,56(a0)
    80002652:	05653023          	sd	s6,64(a0)
    80002656:	05753423          	sd	s7,72(a0)
    8000265a:	05853823          	sd	s8,80(a0)
    8000265e:	05953c23          	sd	s9,88(a0)
    80002662:	07a53023          	sd	s10,96(a0)
    80002666:	07b53423          	sd	s11,104(a0)
    8000266a:	0005b083          	ld	ra,0(a1)
    8000266e:	0085b103          	ld	sp,8(a1)
    80002672:	6980                	ld	s0,16(a1)
    80002674:	6d84                	ld	s1,24(a1)
    80002676:	0205b903          	ld	s2,32(a1)
    8000267a:	0285b983          	ld	s3,40(a1)
    8000267e:	0305ba03          	ld	s4,48(a1)
    80002682:	0385ba83          	ld	s5,56(a1)
    80002686:	0405bb03          	ld	s6,64(a1)
    8000268a:	0485bb83          	ld	s7,72(a1)
    8000268e:	0505bc03          	ld	s8,80(a1)
    80002692:	0585bc83          	ld	s9,88(a1)
    80002696:	0605bd03          	ld	s10,96(a1)
    8000269a:	0685bd83          	ld	s11,104(a1)
    8000269e:	8082                	ret

00000000800026a0 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026a0:	1141                	addi	sp,sp,-16
    800026a2:	e406                	sd	ra,8(sp)
    800026a4:	e022                	sd	s0,0(sp)
    800026a6:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026a8:	00006597          	auipc	a1,0x6
    800026ac:	c2858593          	addi	a1,a1,-984 # 800082d0 <states.1707+0x28>
    800026b0:	00015517          	auipc	a0,0x15
    800026b4:	0b850513          	addi	a0,a0,184 # 80017768 <tickslock>
    800026b8:	ffffe097          	auipc	ra,0xffffe
    800026bc:	51a080e7          	jalr	1306(ra) # 80000bd2 <initlock>
}
    800026c0:	60a2                	ld	ra,8(sp)
    800026c2:	6402                	ld	s0,0(sp)
    800026c4:	0141                	addi	sp,sp,16
    800026c6:	8082                	ret

00000000800026c8 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026c8:	1141                	addi	sp,sp,-16
    800026ca:	e422                	sd	s0,8(sp)
    800026cc:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026ce:	00003797          	auipc	a5,0x3
    800026d2:	58278793          	addi	a5,a5,1410 # 80005c50 <kernelvec>
    800026d6:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026da:	6422                	ld	s0,8(sp)
    800026dc:	0141                	addi	sp,sp,16
    800026de:	8082                	ret

00000000800026e0 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026e0:	1141                	addi	sp,sp,-16
    800026e2:	e406                	sd	ra,8(sp)
    800026e4:	e022                	sd	s0,0(sp)
    800026e6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026e8:	fffff097          	auipc	ra,0xfffff
    800026ec:	348080e7          	jalr	840(ra) # 80001a30 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026f0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026f4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026f6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026fa:	00005617          	auipc	a2,0x5
    800026fe:	90660613          	addi	a2,a2,-1786 # 80007000 <_trampoline>
    80002702:	00005697          	auipc	a3,0x5
    80002706:	8fe68693          	addi	a3,a3,-1794 # 80007000 <_trampoline>
    8000270a:	8e91                	sub	a3,a3,a2
    8000270c:	040007b7          	lui	a5,0x4000
    80002710:	17fd                	addi	a5,a5,-1
    80002712:	07b2                	slli	a5,a5,0xc
    80002714:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002716:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000271a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000271c:	180026f3          	csrr	a3,satp
    80002720:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002722:	6d38                	ld	a4,88(a0)
    80002724:	6134                	ld	a3,64(a0)
    80002726:	6585                	lui	a1,0x1
    80002728:	96ae                	add	a3,a3,a1
    8000272a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000272c:	6d38                	ld	a4,88(a0)
    8000272e:	00000697          	auipc	a3,0x0
    80002732:	13868693          	addi	a3,a3,312 # 80002866 <usertrap>
    80002736:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002738:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000273a:	8692                	mv	a3,tp
    8000273c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000273e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002742:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002746:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000274a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000274e:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002750:	6f18                	ld	a4,24(a4)
    80002752:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002756:	692c                	ld	a1,80(a0)
    80002758:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000275a:	00005717          	auipc	a4,0x5
    8000275e:	93670713          	addi	a4,a4,-1738 # 80007090 <userret>
    80002762:	8f11                	sub	a4,a4,a2
    80002764:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002766:	577d                	li	a4,-1
    80002768:	177e                	slli	a4,a4,0x3f
    8000276a:	8dd9                	or	a1,a1,a4
    8000276c:	02000537          	lui	a0,0x2000
    80002770:	157d                	addi	a0,a0,-1
    80002772:	0536                	slli	a0,a0,0xd
    80002774:	9782                	jalr	a5
}
    80002776:	60a2                	ld	ra,8(sp)
    80002778:	6402                	ld	s0,0(sp)
    8000277a:	0141                	addi	sp,sp,16
    8000277c:	8082                	ret

000000008000277e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000277e:	1101                	addi	sp,sp,-32
    80002780:	ec06                	sd	ra,24(sp)
    80002782:	e822                	sd	s0,16(sp)
    80002784:	e426                	sd	s1,8(sp)
    80002786:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002788:	00015497          	auipc	s1,0x15
    8000278c:	fe048493          	addi	s1,s1,-32 # 80017768 <tickslock>
    80002790:	8526                	mv	a0,s1
    80002792:	ffffe097          	auipc	ra,0xffffe
    80002796:	4d0080e7          	jalr	1232(ra) # 80000c62 <acquire>
  ticks++;
    8000279a:	00007517          	auipc	a0,0x7
    8000279e:	88650513          	addi	a0,a0,-1914 # 80009020 <ticks>
    800027a2:	411c                	lw	a5,0(a0)
    800027a4:	2785                	addiw	a5,a5,1
    800027a6:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027a8:	00000097          	auipc	ra,0x0
    800027ac:	c22080e7          	jalr	-990(ra) # 800023ca <wakeup>
  release(&tickslock);
    800027b0:	8526                	mv	a0,s1
    800027b2:	ffffe097          	auipc	ra,0xffffe
    800027b6:	564080e7          	jalr	1380(ra) # 80000d16 <release>
}
    800027ba:	60e2                	ld	ra,24(sp)
    800027bc:	6442                	ld	s0,16(sp)
    800027be:	64a2                	ld	s1,8(sp)
    800027c0:	6105                	addi	sp,sp,32
    800027c2:	8082                	ret

00000000800027c4 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027c4:	1101                	addi	sp,sp,-32
    800027c6:	ec06                	sd	ra,24(sp)
    800027c8:	e822                	sd	s0,16(sp)
    800027ca:	e426                	sd	s1,8(sp)
    800027cc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027ce:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027d2:	00074d63          	bltz	a4,800027ec <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027d6:	57fd                	li	a5,-1
    800027d8:	17fe                	slli	a5,a5,0x3f
    800027da:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027dc:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027de:	06f70363          	beq	a4,a5,80002844 <devintr+0x80>
  }
}
    800027e2:	60e2                	ld	ra,24(sp)
    800027e4:	6442                	ld	s0,16(sp)
    800027e6:	64a2                	ld	s1,8(sp)
    800027e8:	6105                	addi	sp,sp,32
    800027ea:	8082                	ret
     (scause & 0xff) == 9){
    800027ec:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800027f0:	46a5                	li	a3,9
    800027f2:	fed792e3          	bne	a5,a3,800027d6 <devintr+0x12>
    int irq = plic_claim();
    800027f6:	00003097          	auipc	ra,0x3
    800027fa:	562080e7          	jalr	1378(ra) # 80005d58 <plic_claim>
    800027fe:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002800:	47a9                	li	a5,10
    80002802:	02f50763          	beq	a0,a5,80002830 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002806:	4785                	li	a5,1
    80002808:	02f50963          	beq	a0,a5,8000283a <devintr+0x76>
    return 1;
    8000280c:	4505                	li	a0,1
    } else if(irq){
    8000280e:	d8f1                	beqz	s1,800027e2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002810:	85a6                	mv	a1,s1
    80002812:	00006517          	auipc	a0,0x6
    80002816:	ac650513          	addi	a0,a0,-1338 # 800082d8 <states.1707+0x30>
    8000281a:	ffffe097          	auipc	ra,0xffffe
    8000281e:	d78080e7          	jalr	-648(ra) # 80000592 <printf>
      plic_complete(irq);
    80002822:	8526                	mv	a0,s1
    80002824:	00003097          	auipc	ra,0x3
    80002828:	558080e7          	jalr	1368(ra) # 80005d7c <plic_complete>
    return 1;
    8000282c:	4505                	li	a0,1
    8000282e:	bf55                	j	800027e2 <devintr+0x1e>
      uartintr();
    80002830:	ffffe097          	auipc	ra,0xffffe
    80002834:	1a4080e7          	jalr	420(ra) # 800009d4 <uartintr>
    80002838:	b7ed                	j	80002822 <devintr+0x5e>
      virtio_disk_intr();
    8000283a:	00004097          	auipc	ra,0x4
    8000283e:	9dc080e7          	jalr	-1572(ra) # 80006216 <virtio_disk_intr>
    80002842:	b7c5                	j	80002822 <devintr+0x5e>
    if(cpuid() == 0){
    80002844:	fffff097          	auipc	ra,0xfffff
    80002848:	1c0080e7          	jalr	448(ra) # 80001a04 <cpuid>
    8000284c:	c901                	beqz	a0,8000285c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000284e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002852:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002854:	14479073          	csrw	sip,a5
    return 2;
    80002858:	4509                	li	a0,2
    8000285a:	b761                	j	800027e2 <devintr+0x1e>
      clockintr();
    8000285c:	00000097          	auipc	ra,0x0
    80002860:	f22080e7          	jalr	-222(ra) # 8000277e <clockintr>
    80002864:	b7ed                	j	8000284e <devintr+0x8a>

0000000080002866 <usertrap>:
{
    80002866:	1101                	addi	sp,sp,-32
    80002868:	ec06                	sd	ra,24(sp)
    8000286a:	e822                	sd	s0,16(sp)
    8000286c:	e426                	sd	s1,8(sp)
    8000286e:	e04a                	sd	s2,0(sp)
    80002870:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002872:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002876:	1007f793          	andi	a5,a5,256
    8000287a:	e3ad                	bnez	a5,800028dc <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000287c:	00003797          	auipc	a5,0x3
    80002880:	3d478793          	addi	a5,a5,980 # 80005c50 <kernelvec>
    80002884:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002888:	fffff097          	auipc	ra,0xfffff
    8000288c:	1a8080e7          	jalr	424(ra) # 80001a30 <myproc>
    80002890:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002892:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002894:	14102773          	csrr	a4,sepc
    80002898:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000289a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000289e:	47a1                	li	a5,8
    800028a0:	04f71c63          	bne	a4,a5,800028f8 <usertrap+0x92>
    if(p->killed)
    800028a4:	591c                	lw	a5,48(a0)
    800028a6:	e3b9                	bnez	a5,800028ec <usertrap+0x86>
    p->trapframe->epc += 4;
    800028a8:	6cb8                	ld	a4,88(s1)
    800028aa:	6f1c                	ld	a5,24(a4)
    800028ac:	0791                	addi	a5,a5,4
    800028ae:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028b0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028b4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028b8:	10079073          	csrw	sstatus,a5
    syscall();
    800028bc:	00000097          	auipc	ra,0x0
    800028c0:	2e0080e7          	jalr	736(ra) # 80002b9c <syscall>
  if(p->killed)
    800028c4:	589c                	lw	a5,48(s1)
    800028c6:	ebc1                	bnez	a5,80002956 <usertrap+0xf0>
  usertrapret();
    800028c8:	00000097          	auipc	ra,0x0
    800028cc:	e18080e7          	jalr	-488(ra) # 800026e0 <usertrapret>
}
    800028d0:	60e2                	ld	ra,24(sp)
    800028d2:	6442                	ld	s0,16(sp)
    800028d4:	64a2                	ld	s1,8(sp)
    800028d6:	6902                	ld	s2,0(sp)
    800028d8:	6105                	addi	sp,sp,32
    800028da:	8082                	ret
    panic("usertrap: not from user mode");
    800028dc:	00006517          	auipc	a0,0x6
    800028e0:	a1c50513          	addi	a0,a0,-1508 # 800082f8 <states.1707+0x50>
    800028e4:	ffffe097          	auipc	ra,0xffffe
    800028e8:	c64080e7          	jalr	-924(ra) # 80000548 <panic>
      exit(-1);
    800028ec:	557d                	li	a0,-1
    800028ee:	00000097          	auipc	ra,0x0
    800028f2:	810080e7          	jalr	-2032(ra) # 800020fe <exit>
    800028f6:	bf4d                	j	800028a8 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800028f8:	00000097          	auipc	ra,0x0
    800028fc:	ecc080e7          	jalr	-308(ra) # 800027c4 <devintr>
    80002900:	892a                	mv	s2,a0
    80002902:	c501                	beqz	a0,8000290a <usertrap+0xa4>
  if(p->killed)
    80002904:	589c                	lw	a5,48(s1)
    80002906:	c3a1                	beqz	a5,80002946 <usertrap+0xe0>
    80002908:	a815                	j	8000293c <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000290a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000290e:	5c90                	lw	a2,56(s1)
    80002910:	00006517          	auipc	a0,0x6
    80002914:	a0850513          	addi	a0,a0,-1528 # 80008318 <states.1707+0x70>
    80002918:	ffffe097          	auipc	ra,0xffffe
    8000291c:	c7a080e7          	jalr	-902(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002920:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002924:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002928:	00006517          	auipc	a0,0x6
    8000292c:	a2050513          	addi	a0,a0,-1504 # 80008348 <states.1707+0xa0>
    80002930:	ffffe097          	auipc	ra,0xffffe
    80002934:	c62080e7          	jalr	-926(ra) # 80000592 <printf>
    p->killed = 1;
    80002938:	4785                	li	a5,1
    8000293a:	d89c                	sw	a5,48(s1)
    exit(-1);
    8000293c:	557d                	li	a0,-1
    8000293e:	fffff097          	auipc	ra,0xfffff
    80002942:	7c0080e7          	jalr	1984(ra) # 800020fe <exit>
  if(which_dev == 2)
    80002946:	4789                	li	a5,2
    80002948:	f8f910e3          	bne	s2,a5,800028c8 <usertrap+0x62>
    yield();
    8000294c:	00000097          	auipc	ra,0x0
    80002950:	8bc080e7          	jalr	-1860(ra) # 80002208 <yield>
    80002954:	bf95                	j	800028c8 <usertrap+0x62>
  int which_dev = 0;
    80002956:	4901                	li	s2,0
    80002958:	b7d5                	j	8000293c <usertrap+0xd6>

000000008000295a <kerneltrap>:
{
    8000295a:	7179                	addi	sp,sp,-48
    8000295c:	f406                	sd	ra,40(sp)
    8000295e:	f022                	sd	s0,32(sp)
    80002960:	ec26                	sd	s1,24(sp)
    80002962:	e84a                	sd	s2,16(sp)
    80002964:	e44e                	sd	s3,8(sp)
    80002966:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002968:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000296c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002970:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002974:	1004f793          	andi	a5,s1,256
    80002978:	cb85                	beqz	a5,800029a8 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000297a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000297e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002980:	ef85                	bnez	a5,800029b8 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002982:	00000097          	auipc	ra,0x0
    80002986:	e42080e7          	jalr	-446(ra) # 800027c4 <devintr>
    8000298a:	cd1d                	beqz	a0,800029c8 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000298c:	4789                	li	a5,2
    8000298e:	06f50a63          	beq	a0,a5,80002a02 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002992:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002996:	10049073          	csrw	sstatus,s1
}
    8000299a:	70a2                	ld	ra,40(sp)
    8000299c:	7402                	ld	s0,32(sp)
    8000299e:	64e2                	ld	s1,24(sp)
    800029a0:	6942                	ld	s2,16(sp)
    800029a2:	69a2                	ld	s3,8(sp)
    800029a4:	6145                	addi	sp,sp,48
    800029a6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029a8:	00006517          	auipc	a0,0x6
    800029ac:	9c050513          	addi	a0,a0,-1600 # 80008368 <states.1707+0xc0>
    800029b0:	ffffe097          	auipc	ra,0xffffe
    800029b4:	b98080e7          	jalr	-1128(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    800029b8:	00006517          	auipc	a0,0x6
    800029bc:	9d850513          	addi	a0,a0,-1576 # 80008390 <states.1707+0xe8>
    800029c0:	ffffe097          	auipc	ra,0xffffe
    800029c4:	b88080e7          	jalr	-1144(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    800029c8:	85ce                	mv	a1,s3
    800029ca:	00006517          	auipc	a0,0x6
    800029ce:	9e650513          	addi	a0,a0,-1562 # 800083b0 <states.1707+0x108>
    800029d2:	ffffe097          	auipc	ra,0xffffe
    800029d6:	bc0080e7          	jalr	-1088(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029da:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029de:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029e2:	00006517          	auipc	a0,0x6
    800029e6:	9de50513          	addi	a0,a0,-1570 # 800083c0 <states.1707+0x118>
    800029ea:	ffffe097          	auipc	ra,0xffffe
    800029ee:	ba8080e7          	jalr	-1112(ra) # 80000592 <printf>
    panic("kerneltrap");
    800029f2:	00006517          	auipc	a0,0x6
    800029f6:	9e650513          	addi	a0,a0,-1562 # 800083d8 <states.1707+0x130>
    800029fa:	ffffe097          	auipc	ra,0xffffe
    800029fe:	b4e080e7          	jalr	-1202(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a02:	fffff097          	auipc	ra,0xfffff
    80002a06:	02e080e7          	jalr	46(ra) # 80001a30 <myproc>
    80002a0a:	d541                	beqz	a0,80002992 <kerneltrap+0x38>
    80002a0c:	fffff097          	auipc	ra,0xfffff
    80002a10:	024080e7          	jalr	36(ra) # 80001a30 <myproc>
    80002a14:	4d18                	lw	a4,24(a0)
    80002a16:	478d                	li	a5,3
    80002a18:	f6f71de3          	bne	a4,a5,80002992 <kerneltrap+0x38>
    yield();
    80002a1c:	fffff097          	auipc	ra,0xfffff
    80002a20:	7ec080e7          	jalr	2028(ra) # 80002208 <yield>
    80002a24:	b7bd                	j	80002992 <kerneltrap+0x38>

0000000080002a26 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a26:	1101                	addi	sp,sp,-32
    80002a28:	ec06                	sd	ra,24(sp)
    80002a2a:	e822                	sd	s0,16(sp)
    80002a2c:	e426                	sd	s1,8(sp)
    80002a2e:	1000                	addi	s0,sp,32
    80002a30:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a32:	fffff097          	auipc	ra,0xfffff
    80002a36:	ffe080e7          	jalr	-2(ra) # 80001a30 <myproc>
  switch (n) {
    80002a3a:	4795                	li	a5,5
    80002a3c:	0497e163          	bltu	a5,s1,80002a7e <argraw+0x58>
    80002a40:	048a                	slli	s1,s1,0x2
    80002a42:	00006717          	auipc	a4,0x6
    80002a46:	a9e70713          	addi	a4,a4,-1378 # 800084e0 <states.1707+0x238>
    80002a4a:	94ba                	add	s1,s1,a4
    80002a4c:	409c                	lw	a5,0(s1)
    80002a4e:	97ba                	add	a5,a5,a4
    80002a50:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a52:	6d3c                	ld	a5,88(a0)
    80002a54:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a56:	60e2                	ld	ra,24(sp)
    80002a58:	6442                	ld	s0,16(sp)
    80002a5a:	64a2                	ld	s1,8(sp)
    80002a5c:	6105                	addi	sp,sp,32
    80002a5e:	8082                	ret
    return p->trapframe->a1;
    80002a60:	6d3c                	ld	a5,88(a0)
    80002a62:	7fa8                	ld	a0,120(a5)
    80002a64:	bfcd                	j	80002a56 <argraw+0x30>
    return p->trapframe->a2;
    80002a66:	6d3c                	ld	a5,88(a0)
    80002a68:	63c8                	ld	a0,128(a5)
    80002a6a:	b7f5                	j	80002a56 <argraw+0x30>
    return p->trapframe->a3;
    80002a6c:	6d3c                	ld	a5,88(a0)
    80002a6e:	67c8                	ld	a0,136(a5)
    80002a70:	b7dd                	j	80002a56 <argraw+0x30>
    return p->trapframe->a4;
    80002a72:	6d3c                	ld	a5,88(a0)
    80002a74:	6bc8                	ld	a0,144(a5)
    80002a76:	b7c5                	j	80002a56 <argraw+0x30>
    return p->trapframe->a5;
    80002a78:	6d3c                	ld	a5,88(a0)
    80002a7a:	6fc8                	ld	a0,152(a5)
    80002a7c:	bfe9                	j	80002a56 <argraw+0x30>
  panic("argraw");
    80002a7e:	00006517          	auipc	a0,0x6
    80002a82:	96a50513          	addi	a0,a0,-1686 # 800083e8 <states.1707+0x140>
    80002a86:	ffffe097          	auipc	ra,0xffffe
    80002a8a:	ac2080e7          	jalr	-1342(ra) # 80000548 <panic>

0000000080002a8e <fetchaddr>:
{
    80002a8e:	1101                	addi	sp,sp,-32
    80002a90:	ec06                	sd	ra,24(sp)
    80002a92:	e822                	sd	s0,16(sp)
    80002a94:	e426                	sd	s1,8(sp)
    80002a96:	e04a                	sd	s2,0(sp)
    80002a98:	1000                	addi	s0,sp,32
    80002a9a:	84aa                	mv	s1,a0
    80002a9c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a9e:	fffff097          	auipc	ra,0xfffff
    80002aa2:	f92080e7          	jalr	-110(ra) # 80001a30 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002aa6:	653c                	ld	a5,72(a0)
    80002aa8:	02f4f863          	bgeu	s1,a5,80002ad8 <fetchaddr+0x4a>
    80002aac:	00848713          	addi	a4,s1,8
    80002ab0:	02e7e663          	bltu	a5,a4,80002adc <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ab4:	46a1                	li	a3,8
    80002ab6:	8626                	mv	a2,s1
    80002ab8:	85ca                	mv	a1,s2
    80002aba:	6928                	ld	a0,80(a0)
    80002abc:	fffff097          	auipc	ra,0xfffff
    80002ac0:	cf4080e7          	jalr	-780(ra) # 800017b0 <copyin>
    80002ac4:	00a03533          	snez	a0,a0
    80002ac8:	40a00533          	neg	a0,a0
}
    80002acc:	60e2                	ld	ra,24(sp)
    80002ace:	6442                	ld	s0,16(sp)
    80002ad0:	64a2                	ld	s1,8(sp)
    80002ad2:	6902                	ld	s2,0(sp)
    80002ad4:	6105                	addi	sp,sp,32
    80002ad6:	8082                	ret
    return -1;
    80002ad8:	557d                	li	a0,-1
    80002ada:	bfcd                	j	80002acc <fetchaddr+0x3e>
    80002adc:	557d                	li	a0,-1
    80002ade:	b7fd                	j	80002acc <fetchaddr+0x3e>

0000000080002ae0 <fetchstr>:
{
    80002ae0:	7179                	addi	sp,sp,-48
    80002ae2:	f406                	sd	ra,40(sp)
    80002ae4:	f022                	sd	s0,32(sp)
    80002ae6:	ec26                	sd	s1,24(sp)
    80002ae8:	e84a                	sd	s2,16(sp)
    80002aea:	e44e                	sd	s3,8(sp)
    80002aec:	1800                	addi	s0,sp,48
    80002aee:	892a                	mv	s2,a0
    80002af0:	84ae                	mv	s1,a1
    80002af2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002af4:	fffff097          	auipc	ra,0xfffff
    80002af8:	f3c080e7          	jalr	-196(ra) # 80001a30 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002afc:	86ce                	mv	a3,s3
    80002afe:	864a                	mv	a2,s2
    80002b00:	85a6                	mv	a1,s1
    80002b02:	6928                	ld	a0,80(a0)
    80002b04:	fffff097          	auipc	ra,0xfffff
    80002b08:	d38080e7          	jalr	-712(ra) # 8000183c <copyinstr>
  if(err < 0)
    80002b0c:	00054763          	bltz	a0,80002b1a <fetchstr+0x3a>
  return strlen(buf);
    80002b10:	8526                	mv	a0,s1
    80002b12:	ffffe097          	auipc	ra,0xffffe
    80002b16:	3d4080e7          	jalr	980(ra) # 80000ee6 <strlen>
}
    80002b1a:	70a2                	ld	ra,40(sp)
    80002b1c:	7402                	ld	s0,32(sp)
    80002b1e:	64e2                	ld	s1,24(sp)
    80002b20:	6942                	ld	s2,16(sp)
    80002b22:	69a2                	ld	s3,8(sp)
    80002b24:	6145                	addi	sp,sp,48
    80002b26:	8082                	ret

0000000080002b28 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b28:	1101                	addi	sp,sp,-32
    80002b2a:	ec06                	sd	ra,24(sp)
    80002b2c:	e822                	sd	s0,16(sp)
    80002b2e:	e426                	sd	s1,8(sp)
    80002b30:	1000                	addi	s0,sp,32
    80002b32:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b34:	00000097          	auipc	ra,0x0
    80002b38:	ef2080e7          	jalr	-270(ra) # 80002a26 <argraw>
    80002b3c:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b3e:	4501                	li	a0,0
    80002b40:	60e2                	ld	ra,24(sp)
    80002b42:	6442                	ld	s0,16(sp)
    80002b44:	64a2                	ld	s1,8(sp)
    80002b46:	6105                	addi	sp,sp,32
    80002b48:	8082                	ret

0000000080002b4a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b4a:	1101                	addi	sp,sp,-32
    80002b4c:	ec06                	sd	ra,24(sp)
    80002b4e:	e822                	sd	s0,16(sp)
    80002b50:	e426                	sd	s1,8(sp)
    80002b52:	1000                	addi	s0,sp,32
    80002b54:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b56:	00000097          	auipc	ra,0x0
    80002b5a:	ed0080e7          	jalr	-304(ra) # 80002a26 <argraw>
    80002b5e:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b60:	4501                	li	a0,0
    80002b62:	60e2                	ld	ra,24(sp)
    80002b64:	6442                	ld	s0,16(sp)
    80002b66:	64a2                	ld	s1,8(sp)
    80002b68:	6105                	addi	sp,sp,32
    80002b6a:	8082                	ret

0000000080002b6c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b6c:	1101                	addi	sp,sp,-32
    80002b6e:	ec06                	sd	ra,24(sp)
    80002b70:	e822                	sd	s0,16(sp)
    80002b72:	e426                	sd	s1,8(sp)
    80002b74:	e04a                	sd	s2,0(sp)
    80002b76:	1000                	addi	s0,sp,32
    80002b78:	84ae                	mv	s1,a1
    80002b7a:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b7c:	00000097          	auipc	ra,0x0
    80002b80:	eaa080e7          	jalr	-342(ra) # 80002a26 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b84:	864a                	mv	a2,s2
    80002b86:	85a6                	mv	a1,s1
    80002b88:	00000097          	auipc	ra,0x0
    80002b8c:	f58080e7          	jalr	-168(ra) # 80002ae0 <fetchstr>
}
    80002b90:	60e2                	ld	ra,24(sp)
    80002b92:	6442                	ld	s0,16(sp)
    80002b94:	64a2                	ld	s1,8(sp)
    80002b96:	6902                	ld	s2,0(sp)
    80002b98:	6105                	addi	sp,sp,32
    80002b9a:	8082                	ret

0000000080002b9c <syscall>:
[SYS_sysinfo]  sys_sysinfo,
};

void
syscall(void)
{
    80002b9c:	7179                	addi	sp,sp,-48
    80002b9e:	f406                	sd	ra,40(sp)
    80002ba0:	f022                	sd	s0,32(sp)
    80002ba2:	ec26                	sd	s1,24(sp)
    80002ba4:	e84a                	sd	s2,16(sp)
    80002ba6:	e44e                	sd	s3,8(sp)
    80002ba8:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002baa:	fffff097          	auipc	ra,0xfffff
    80002bae:	e86080e7          	jalr	-378(ra) # 80001a30 <myproc>
    80002bb2:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bb4:	05853903          	ld	s2,88(a0)
    80002bb8:	0a893783          	ld	a5,168(s2)
    80002bbc:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) 
    80002bc0:	37fd                	addiw	a5,a5,-1
    80002bc2:	4759                	li	a4,22
    80002bc4:	04f76763          	bltu	a4,a5,80002c12 <syscall+0x76>
    80002bc8:	00399713          	slli	a4,s3,0x3
    80002bcc:	00006797          	auipc	a5,0x6
    80002bd0:	92c78793          	addi	a5,a5,-1748 # 800084f8 <syscalls>
    80002bd4:	97ba                	add	a5,a5,a4
    80002bd6:	639c                	ld	a5,0(a5)
    80002bd8:	cf8d                	beqz	a5,80002c12 <syscall+0x76>
  {
    p->trapframe->a0 = syscalls[num]();  
    80002bda:	9782                	jalr	a5
    80002bdc:	06a93823          	sd	a0,112(s2)
    if(1 << num & p->tmask)
    80002be0:	5cdc                	lw	a5,60(s1)
    80002be2:	4137d7bb          	sraw	a5,a5,s3
    80002be6:	8b85                	andi	a5,a5,1
    80002be8:	c7a1                	beqz	a5,80002c30 <syscall+0x94>
    {
      printf("%d: syscall %s -> %d \n",p->pid, 
    80002bea:	6cb8                	ld	a4,88(s1)
    80002bec:	098e                	slli	s3,s3,0x3
    80002bee:	00006797          	auipc	a5,0x6
    80002bf2:	90a78793          	addi	a5,a5,-1782 # 800084f8 <syscalls>
    80002bf6:	99be                	add	s3,s3,a5
    80002bf8:	7b34                	ld	a3,112(a4)
    80002bfa:	0c09b603          	ld	a2,192(s3)
    80002bfe:	5c8c                	lw	a1,56(s1)
    80002c00:	00005517          	auipc	a0,0x5
    80002c04:	7f050513          	addi	a0,a0,2032 # 800083f0 <states.1707+0x148>
    80002c08:	ffffe097          	auipc	ra,0xffffe
    80002c0c:	98a080e7          	jalr	-1654(ra) # 80000592 <printf>
    80002c10:	a005                	j	80002c30 <syscall+0x94>
              syscalls_name[num],p->trapframe->a0);
    }
  }
  else 
  {
    printf("%d %s: unknown sys call %d\n",
    80002c12:	86ce                	mv	a3,s3
    80002c14:	15848613          	addi	a2,s1,344
    80002c18:	5c8c                	lw	a1,56(s1)
    80002c1a:	00005517          	auipc	a0,0x5
    80002c1e:	7ee50513          	addi	a0,a0,2030 # 80008408 <states.1707+0x160>
    80002c22:	ffffe097          	auipc	ra,0xffffe
    80002c26:	970080e7          	jalr	-1680(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c2a:	6cbc                	ld	a5,88(s1)
    80002c2c:	577d                	li	a4,-1
    80002c2e:	fbb8                	sd	a4,112(a5)
  }
}
    80002c30:	70a2                	ld	ra,40(sp)
    80002c32:	7402                	ld	s0,32(sp)
    80002c34:	64e2                	ld	s1,24(sp)
    80002c36:	6942                	ld	s2,16(sp)
    80002c38:	69a2                	ld	s3,8(sp)
    80002c3a:	6145                	addi	sp,sp,48
    80002c3c:	8082                	ret

0000000080002c3e <sys_exit>:
#include "proc.h"
#include "sysinfo.h"

uint64
sys_exit(void)
{
    80002c3e:	1101                	addi	sp,sp,-32
    80002c40:	ec06                	sd	ra,24(sp)
    80002c42:	e822                	sd	s0,16(sp)
    80002c44:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c46:	fec40593          	addi	a1,s0,-20
    80002c4a:	4501                	li	a0,0
    80002c4c:	00000097          	auipc	ra,0x0
    80002c50:	edc080e7          	jalr	-292(ra) # 80002b28 <argint>
    return -1;
    80002c54:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c56:	00054963          	bltz	a0,80002c68 <sys_exit+0x2a>
  exit(n);
    80002c5a:	fec42503          	lw	a0,-20(s0)
    80002c5e:	fffff097          	auipc	ra,0xfffff
    80002c62:	4a0080e7          	jalr	1184(ra) # 800020fe <exit>
  return 0;  // not reached
    80002c66:	4781                	li	a5,0
}
    80002c68:	853e                	mv	a0,a5
    80002c6a:	60e2                	ld	ra,24(sp)
    80002c6c:	6442                	ld	s0,16(sp)
    80002c6e:	6105                	addi	sp,sp,32
    80002c70:	8082                	ret

0000000080002c72 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c72:	1141                	addi	sp,sp,-16
    80002c74:	e406                	sd	ra,8(sp)
    80002c76:	e022                	sd	s0,0(sp)
    80002c78:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c7a:	fffff097          	auipc	ra,0xfffff
    80002c7e:	db6080e7          	jalr	-586(ra) # 80001a30 <myproc>
}
    80002c82:	5d08                	lw	a0,56(a0)
    80002c84:	60a2                	ld	ra,8(sp)
    80002c86:	6402                	ld	s0,0(sp)
    80002c88:	0141                	addi	sp,sp,16
    80002c8a:	8082                	ret

0000000080002c8c <sys_fork>:

uint64
sys_fork(void)
{
    80002c8c:	1141                	addi	sp,sp,-16
    80002c8e:	e406                	sd	ra,8(sp)
    80002c90:	e022                	sd	s0,0(sp)
    80002c92:	0800                	addi	s0,sp,16
  return fork();
    80002c94:	fffff097          	auipc	ra,0xfffff
    80002c98:	15c080e7          	jalr	348(ra) # 80001df0 <fork>
}
    80002c9c:	60a2                	ld	ra,8(sp)
    80002c9e:	6402                	ld	s0,0(sp)
    80002ca0:	0141                	addi	sp,sp,16
    80002ca2:	8082                	ret

0000000080002ca4 <sys_wait>:


uint64
sys_wait(void)
{
    80002ca4:	1101                	addi	sp,sp,-32
    80002ca6:	ec06                	sd	ra,24(sp)
    80002ca8:	e822                	sd	s0,16(sp)
    80002caa:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cac:	fe840593          	addi	a1,s0,-24
    80002cb0:	4501                	li	a0,0
    80002cb2:	00000097          	auipc	ra,0x0
    80002cb6:	e98080e7          	jalr	-360(ra) # 80002b4a <argaddr>
    80002cba:	87aa                	mv	a5,a0
    return -1;
    80002cbc:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002cbe:	0007c863          	bltz	a5,80002cce <sys_wait+0x2a>
  return wait(p);
    80002cc2:	fe843503          	ld	a0,-24(s0)
    80002cc6:	fffff097          	auipc	ra,0xfffff
    80002cca:	5fc080e7          	jalr	1532(ra) # 800022c2 <wait>
}
    80002cce:	60e2                	ld	ra,24(sp)
    80002cd0:	6442                	ld	s0,16(sp)
    80002cd2:	6105                	addi	sp,sp,32
    80002cd4:	8082                	ret

0000000080002cd6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cd6:	7179                	addi	sp,sp,-48
    80002cd8:	f406                	sd	ra,40(sp)
    80002cda:	f022                	sd	s0,32(sp)
    80002cdc:	ec26                	sd	s1,24(sp)
    80002cde:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002ce0:	fdc40593          	addi	a1,s0,-36
    80002ce4:	4501                	li	a0,0
    80002ce6:	00000097          	auipc	ra,0x0
    80002cea:	e42080e7          	jalr	-446(ra) # 80002b28 <argint>
    80002cee:	87aa                	mv	a5,a0
    return -1;
    80002cf0:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002cf2:	0207c063          	bltz	a5,80002d12 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002cf6:	fffff097          	auipc	ra,0xfffff
    80002cfa:	d3a080e7          	jalr	-710(ra) # 80001a30 <myproc>
    80002cfe:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d00:	fdc42503          	lw	a0,-36(s0)
    80002d04:	fffff097          	auipc	ra,0xfffff
    80002d08:	078080e7          	jalr	120(ra) # 80001d7c <growproc>
    80002d0c:	00054863          	bltz	a0,80002d1c <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d10:	8526                	mv	a0,s1
}
    80002d12:	70a2                	ld	ra,40(sp)
    80002d14:	7402                	ld	s0,32(sp)
    80002d16:	64e2                	ld	s1,24(sp)
    80002d18:	6145                	addi	sp,sp,48
    80002d1a:	8082                	ret
    return -1;
    80002d1c:	557d                	li	a0,-1
    80002d1e:	bfd5                	j	80002d12 <sys_sbrk+0x3c>

0000000080002d20 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d20:	7139                	addi	sp,sp,-64
    80002d22:	fc06                	sd	ra,56(sp)
    80002d24:	f822                	sd	s0,48(sp)
    80002d26:	f426                	sd	s1,40(sp)
    80002d28:	f04a                	sd	s2,32(sp)
    80002d2a:	ec4e                	sd	s3,24(sp)
    80002d2c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d2e:	fcc40593          	addi	a1,s0,-52
    80002d32:	4501                	li	a0,0
    80002d34:	00000097          	auipc	ra,0x0
    80002d38:	df4080e7          	jalr	-524(ra) # 80002b28 <argint>
    return -1;
    80002d3c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d3e:	06054563          	bltz	a0,80002da8 <sys_sleep+0x88>
  acquire(&tickslock);
    80002d42:	00015517          	auipc	a0,0x15
    80002d46:	a2650513          	addi	a0,a0,-1498 # 80017768 <tickslock>
    80002d4a:	ffffe097          	auipc	ra,0xffffe
    80002d4e:	f18080e7          	jalr	-232(ra) # 80000c62 <acquire>
  ticks0 = ticks;
    80002d52:	00006917          	auipc	s2,0x6
    80002d56:	2ce92903          	lw	s2,718(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002d5a:	fcc42783          	lw	a5,-52(s0)
    80002d5e:	cf85                	beqz	a5,80002d96 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d60:	00015997          	auipc	s3,0x15
    80002d64:	a0898993          	addi	s3,s3,-1528 # 80017768 <tickslock>
    80002d68:	00006497          	auipc	s1,0x6
    80002d6c:	2b848493          	addi	s1,s1,696 # 80009020 <ticks>
    if(myproc()->killed){
    80002d70:	fffff097          	auipc	ra,0xfffff
    80002d74:	cc0080e7          	jalr	-832(ra) # 80001a30 <myproc>
    80002d78:	591c                	lw	a5,48(a0)
    80002d7a:	ef9d                	bnez	a5,80002db8 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d7c:	85ce                	mv	a1,s3
    80002d7e:	8526                	mv	a0,s1
    80002d80:	fffff097          	auipc	ra,0xfffff
    80002d84:	4c4080e7          	jalr	1220(ra) # 80002244 <sleep>
  while(ticks - ticks0 < n){
    80002d88:	409c                	lw	a5,0(s1)
    80002d8a:	412787bb          	subw	a5,a5,s2
    80002d8e:	fcc42703          	lw	a4,-52(s0)
    80002d92:	fce7efe3          	bltu	a5,a4,80002d70 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d96:	00015517          	auipc	a0,0x15
    80002d9a:	9d250513          	addi	a0,a0,-1582 # 80017768 <tickslock>
    80002d9e:	ffffe097          	auipc	ra,0xffffe
    80002da2:	f78080e7          	jalr	-136(ra) # 80000d16 <release>
  return 0;
    80002da6:	4781                	li	a5,0
}
    80002da8:	853e                	mv	a0,a5
    80002daa:	70e2                	ld	ra,56(sp)
    80002dac:	7442                	ld	s0,48(sp)
    80002dae:	74a2                	ld	s1,40(sp)
    80002db0:	7902                	ld	s2,32(sp)
    80002db2:	69e2                	ld	s3,24(sp)
    80002db4:	6121                	addi	sp,sp,64
    80002db6:	8082                	ret
      release(&tickslock);
    80002db8:	00015517          	auipc	a0,0x15
    80002dbc:	9b050513          	addi	a0,a0,-1616 # 80017768 <tickslock>
    80002dc0:	ffffe097          	auipc	ra,0xffffe
    80002dc4:	f56080e7          	jalr	-170(ra) # 80000d16 <release>
      return -1;
    80002dc8:	57fd                	li	a5,-1
    80002dca:	bff9                	j	80002da8 <sys_sleep+0x88>

0000000080002dcc <sys_kill>:

uint64
sys_kill(void)
{
    80002dcc:	1101                	addi	sp,sp,-32
    80002dce:	ec06                	sd	ra,24(sp)
    80002dd0:	e822                	sd	s0,16(sp)
    80002dd2:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002dd4:	fec40593          	addi	a1,s0,-20
    80002dd8:	4501                	li	a0,0
    80002dda:	00000097          	auipc	ra,0x0
    80002dde:	d4e080e7          	jalr	-690(ra) # 80002b28 <argint>
    80002de2:	87aa                	mv	a5,a0
    return -1;
    80002de4:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002de6:	0007c863          	bltz	a5,80002df6 <sys_kill+0x2a>
  return kill(pid);
    80002dea:	fec42503          	lw	a0,-20(s0)
    80002dee:	fffff097          	auipc	ra,0xfffff
    80002df2:	646080e7          	jalr	1606(ra) # 80002434 <kill>
}
    80002df6:	60e2                	ld	ra,24(sp)
    80002df8:	6442                	ld	s0,16(sp)
    80002dfa:	6105                	addi	sp,sp,32
    80002dfc:	8082                	ret

0000000080002dfe <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002dfe:	1101                	addi	sp,sp,-32
    80002e00:	ec06                	sd	ra,24(sp)
    80002e02:	e822                	sd	s0,16(sp)
    80002e04:	e426                	sd	s1,8(sp)
    80002e06:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e08:	00015517          	auipc	a0,0x15
    80002e0c:	96050513          	addi	a0,a0,-1696 # 80017768 <tickslock>
    80002e10:	ffffe097          	auipc	ra,0xffffe
    80002e14:	e52080e7          	jalr	-430(ra) # 80000c62 <acquire>
  xticks = ticks;
    80002e18:	00006497          	auipc	s1,0x6
    80002e1c:	2084a483          	lw	s1,520(s1) # 80009020 <ticks>
  release(&tickslock);
    80002e20:	00015517          	auipc	a0,0x15
    80002e24:	94850513          	addi	a0,a0,-1720 # 80017768 <tickslock>
    80002e28:	ffffe097          	auipc	ra,0xffffe
    80002e2c:	eee080e7          	jalr	-274(ra) # 80000d16 <release>
  return xticks;
}
    80002e30:	02049513          	slli	a0,s1,0x20
    80002e34:	9101                	srli	a0,a0,0x20
    80002e36:	60e2                	ld	ra,24(sp)
    80002e38:	6442                	ld	s0,16(sp)
    80002e3a:	64a2                	ld	s1,8(sp)
    80002e3c:	6105                	addi	sp,sp,32
    80002e3e:	8082                	ret

0000000080002e40 <sys_trace>:

uint64
sys_trace(void)
{
    80002e40:	1141                	addi	sp,sp,-16
    80002e42:	e406                	sd	ra,8(sp)
    80002e44:	e022                	sd	s0,0(sp)
    80002e46:	0800                	addi	s0,sp,16
  int * mask =&(myproc()->tmask);
    80002e48:	fffff097          	auipc	ra,0xfffff
    80002e4c:	be8080e7          	jalr	-1048(ra) # 80001a30 <myproc>
  argint(0, mask);
    80002e50:	03c50593          	addi	a1,a0,60
    80002e54:	4501                	li	a0,0
    80002e56:	00000097          	auipc	ra,0x0
    80002e5a:	cd2080e7          	jalr	-814(ra) # 80002b28 <argint>
  return 0;
}
    80002e5e:	4501                	li	a0,0
    80002e60:	60a2                	ld	ra,8(sp)
    80002e62:	6402                	ld	s0,0(sp)
    80002e64:	0141                	addi	sp,sp,16
    80002e66:	8082                	ret

0000000080002e68 <sys_sysinfo>:


// return a stuct
uint64
sys_sysinfo(void)
{
    80002e68:	7139                	addi	sp,sp,-64
    80002e6a:	fc06                	sd	ra,56(sp)
    80002e6c:	f822                	sd	s0,48(sp)
    80002e6e:	f426                	sd	s1,40(sp)
    80002e70:	0080                	addi	s0,sp,64
  uint64 addr;
  argaddr(0,&addr);
    80002e72:	fd840593          	addi	a1,s0,-40
    80002e76:	4501                	li	a0,0
    80002e78:	00000097          	auipc	ra,0x0
    80002e7c:	cd2080e7          	jalr	-814(ra) # 80002b4a <argaddr>
  struct proc *p = myproc();
    80002e80:	fffff097          	auipc	ra,0xfffff
    80002e84:	bb0080e7          	jalr	-1104(ra) # 80001a30 <myproc>
    80002e88:	84aa                	mv	s1,a0
  struct sysinfo info;
  procnum(&info.nproc);
    80002e8a:	fd040513          	addi	a0,s0,-48
    80002e8e:	fffff097          	auipc	ra,0xfffff
    80002e92:	772080e7          	jalr	1906(ra) # 80002600 <procnum>
  freememory(&info.freemem);
    80002e96:	fc840513          	addi	a0,s0,-56
    80002e9a:	ffffe097          	auipc	ra,0xffffe
    80002e9e:	ce6080e7          	jalr	-794(ra) # 80000b80 <freememory>
  // printf("sys_sysinfo procnum:%d\n",info.nproc);
  // printf("sys_sysinfo freememory:%d\n",info.freemem);
  if(copyout(p->pagetable, addr, (char *)&info, sizeof(info)) < 0)
    80002ea2:	46c1                	li	a3,16
    80002ea4:	fc840613          	addi	a2,s0,-56
    80002ea8:	fd843583          	ld	a1,-40(s0)
    80002eac:	68a8                	ld	a0,80(s1)
    80002eae:	fffff097          	auipc	ra,0xfffff
    80002eb2:	876080e7          	jalr	-1930(ra) # 80001724 <copyout>
  return -1;

  return 0;
}
    80002eb6:	957d                	srai	a0,a0,0x3f
    80002eb8:	70e2                	ld	ra,56(sp)
    80002eba:	7442                	ld	s0,48(sp)
    80002ebc:	74a2                	ld	s1,40(sp)
    80002ebe:	6121                	addi	sp,sp,64
    80002ec0:	8082                	ret

0000000080002ec2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ec2:	7179                	addi	sp,sp,-48
    80002ec4:	f406                	sd	ra,40(sp)
    80002ec6:	f022                	sd	s0,32(sp)
    80002ec8:	ec26                	sd	s1,24(sp)
    80002eca:	e84a                	sd	s2,16(sp)
    80002ecc:	e44e                	sd	s3,8(sp)
    80002ece:	e052                	sd	s4,0(sp)
    80002ed0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ed2:	00005597          	auipc	a1,0x5
    80002ed6:	7a658593          	addi	a1,a1,1958 # 80008678 <syscalls_name+0xc0>
    80002eda:	00015517          	auipc	a0,0x15
    80002ede:	8a650513          	addi	a0,a0,-1882 # 80017780 <bcache>
    80002ee2:	ffffe097          	auipc	ra,0xffffe
    80002ee6:	cf0080e7          	jalr	-784(ra) # 80000bd2 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002eea:	0001d797          	auipc	a5,0x1d
    80002eee:	89678793          	addi	a5,a5,-1898 # 8001f780 <bcache+0x8000>
    80002ef2:	0001d717          	auipc	a4,0x1d
    80002ef6:	af670713          	addi	a4,a4,-1290 # 8001f9e8 <bcache+0x8268>
    80002efa:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002efe:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f02:	00015497          	auipc	s1,0x15
    80002f06:	89648493          	addi	s1,s1,-1898 # 80017798 <bcache+0x18>
    b->next = bcache.head.next;
    80002f0a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f0c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f0e:	00005a17          	auipc	s4,0x5
    80002f12:	772a0a13          	addi	s4,s4,1906 # 80008680 <syscalls_name+0xc8>
    b->next = bcache.head.next;
    80002f16:	2b893783          	ld	a5,696(s2)
    80002f1a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f1c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f20:	85d2                	mv	a1,s4
    80002f22:	01048513          	addi	a0,s1,16
    80002f26:	00001097          	auipc	ra,0x1
    80002f2a:	4ac080e7          	jalr	1196(ra) # 800043d2 <initsleeplock>
    bcache.head.next->prev = b;
    80002f2e:	2b893783          	ld	a5,696(s2)
    80002f32:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f34:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f38:	45848493          	addi	s1,s1,1112
    80002f3c:	fd349de3          	bne	s1,s3,80002f16 <binit+0x54>
  }
}
    80002f40:	70a2                	ld	ra,40(sp)
    80002f42:	7402                	ld	s0,32(sp)
    80002f44:	64e2                	ld	s1,24(sp)
    80002f46:	6942                	ld	s2,16(sp)
    80002f48:	69a2                	ld	s3,8(sp)
    80002f4a:	6a02                	ld	s4,0(sp)
    80002f4c:	6145                	addi	sp,sp,48
    80002f4e:	8082                	ret

0000000080002f50 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f50:	7179                	addi	sp,sp,-48
    80002f52:	f406                	sd	ra,40(sp)
    80002f54:	f022                	sd	s0,32(sp)
    80002f56:	ec26                	sd	s1,24(sp)
    80002f58:	e84a                	sd	s2,16(sp)
    80002f5a:	e44e                	sd	s3,8(sp)
    80002f5c:	1800                	addi	s0,sp,48
    80002f5e:	89aa                	mv	s3,a0
    80002f60:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f62:	00015517          	auipc	a0,0x15
    80002f66:	81e50513          	addi	a0,a0,-2018 # 80017780 <bcache>
    80002f6a:	ffffe097          	auipc	ra,0xffffe
    80002f6e:	cf8080e7          	jalr	-776(ra) # 80000c62 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f72:	0001d497          	auipc	s1,0x1d
    80002f76:	ac64b483          	ld	s1,-1338(s1) # 8001fa38 <bcache+0x82b8>
    80002f7a:	0001d797          	auipc	a5,0x1d
    80002f7e:	a6e78793          	addi	a5,a5,-1426 # 8001f9e8 <bcache+0x8268>
    80002f82:	02f48f63          	beq	s1,a5,80002fc0 <bread+0x70>
    80002f86:	873e                	mv	a4,a5
    80002f88:	a021                	j	80002f90 <bread+0x40>
    80002f8a:	68a4                	ld	s1,80(s1)
    80002f8c:	02e48a63          	beq	s1,a4,80002fc0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f90:	449c                	lw	a5,8(s1)
    80002f92:	ff379ce3          	bne	a5,s3,80002f8a <bread+0x3a>
    80002f96:	44dc                	lw	a5,12(s1)
    80002f98:	ff2799e3          	bne	a5,s2,80002f8a <bread+0x3a>
      b->refcnt++;
    80002f9c:	40bc                	lw	a5,64(s1)
    80002f9e:	2785                	addiw	a5,a5,1
    80002fa0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fa2:	00014517          	auipc	a0,0x14
    80002fa6:	7de50513          	addi	a0,a0,2014 # 80017780 <bcache>
    80002faa:	ffffe097          	auipc	ra,0xffffe
    80002fae:	d6c080e7          	jalr	-660(ra) # 80000d16 <release>
      acquiresleep(&b->lock);
    80002fb2:	01048513          	addi	a0,s1,16
    80002fb6:	00001097          	auipc	ra,0x1
    80002fba:	456080e7          	jalr	1110(ra) # 8000440c <acquiresleep>
      return b;
    80002fbe:	a8b9                	j	8000301c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fc0:	0001d497          	auipc	s1,0x1d
    80002fc4:	a704b483          	ld	s1,-1424(s1) # 8001fa30 <bcache+0x82b0>
    80002fc8:	0001d797          	auipc	a5,0x1d
    80002fcc:	a2078793          	addi	a5,a5,-1504 # 8001f9e8 <bcache+0x8268>
    80002fd0:	00f48863          	beq	s1,a5,80002fe0 <bread+0x90>
    80002fd4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fd6:	40bc                	lw	a5,64(s1)
    80002fd8:	cf81                	beqz	a5,80002ff0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fda:	64a4                	ld	s1,72(s1)
    80002fdc:	fee49de3          	bne	s1,a4,80002fd6 <bread+0x86>
  panic("bget: no buffers");
    80002fe0:	00005517          	auipc	a0,0x5
    80002fe4:	6a850513          	addi	a0,a0,1704 # 80008688 <syscalls_name+0xd0>
    80002fe8:	ffffd097          	auipc	ra,0xffffd
    80002fec:	560080e7          	jalr	1376(ra) # 80000548 <panic>
      b->dev = dev;
    80002ff0:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002ff4:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002ff8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002ffc:	4785                	li	a5,1
    80002ffe:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003000:	00014517          	auipc	a0,0x14
    80003004:	78050513          	addi	a0,a0,1920 # 80017780 <bcache>
    80003008:	ffffe097          	auipc	ra,0xffffe
    8000300c:	d0e080e7          	jalr	-754(ra) # 80000d16 <release>
      acquiresleep(&b->lock);
    80003010:	01048513          	addi	a0,s1,16
    80003014:	00001097          	auipc	ra,0x1
    80003018:	3f8080e7          	jalr	1016(ra) # 8000440c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000301c:	409c                	lw	a5,0(s1)
    8000301e:	cb89                	beqz	a5,80003030 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003020:	8526                	mv	a0,s1
    80003022:	70a2                	ld	ra,40(sp)
    80003024:	7402                	ld	s0,32(sp)
    80003026:	64e2                	ld	s1,24(sp)
    80003028:	6942                	ld	s2,16(sp)
    8000302a:	69a2                	ld	s3,8(sp)
    8000302c:	6145                	addi	sp,sp,48
    8000302e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003030:	4581                	li	a1,0
    80003032:	8526                	mv	a0,s1
    80003034:	00003097          	auipc	ra,0x3
    80003038:	f38080e7          	jalr	-200(ra) # 80005f6c <virtio_disk_rw>
    b->valid = 1;
    8000303c:	4785                	li	a5,1
    8000303e:	c09c                	sw	a5,0(s1)
  return b;
    80003040:	b7c5                	j	80003020 <bread+0xd0>

0000000080003042 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003042:	1101                	addi	sp,sp,-32
    80003044:	ec06                	sd	ra,24(sp)
    80003046:	e822                	sd	s0,16(sp)
    80003048:	e426                	sd	s1,8(sp)
    8000304a:	1000                	addi	s0,sp,32
    8000304c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000304e:	0541                	addi	a0,a0,16
    80003050:	00001097          	auipc	ra,0x1
    80003054:	456080e7          	jalr	1110(ra) # 800044a6 <holdingsleep>
    80003058:	cd01                	beqz	a0,80003070 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000305a:	4585                	li	a1,1
    8000305c:	8526                	mv	a0,s1
    8000305e:	00003097          	auipc	ra,0x3
    80003062:	f0e080e7          	jalr	-242(ra) # 80005f6c <virtio_disk_rw>
}
    80003066:	60e2                	ld	ra,24(sp)
    80003068:	6442                	ld	s0,16(sp)
    8000306a:	64a2                	ld	s1,8(sp)
    8000306c:	6105                	addi	sp,sp,32
    8000306e:	8082                	ret
    panic("bwrite");
    80003070:	00005517          	auipc	a0,0x5
    80003074:	63050513          	addi	a0,a0,1584 # 800086a0 <syscalls_name+0xe8>
    80003078:	ffffd097          	auipc	ra,0xffffd
    8000307c:	4d0080e7          	jalr	1232(ra) # 80000548 <panic>

0000000080003080 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003080:	1101                	addi	sp,sp,-32
    80003082:	ec06                	sd	ra,24(sp)
    80003084:	e822                	sd	s0,16(sp)
    80003086:	e426                	sd	s1,8(sp)
    80003088:	e04a                	sd	s2,0(sp)
    8000308a:	1000                	addi	s0,sp,32
    8000308c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000308e:	01050913          	addi	s2,a0,16
    80003092:	854a                	mv	a0,s2
    80003094:	00001097          	auipc	ra,0x1
    80003098:	412080e7          	jalr	1042(ra) # 800044a6 <holdingsleep>
    8000309c:	c92d                	beqz	a0,8000310e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000309e:	854a                	mv	a0,s2
    800030a0:	00001097          	auipc	ra,0x1
    800030a4:	3c2080e7          	jalr	962(ra) # 80004462 <releasesleep>

  acquire(&bcache.lock);
    800030a8:	00014517          	auipc	a0,0x14
    800030ac:	6d850513          	addi	a0,a0,1752 # 80017780 <bcache>
    800030b0:	ffffe097          	auipc	ra,0xffffe
    800030b4:	bb2080e7          	jalr	-1102(ra) # 80000c62 <acquire>
  b->refcnt--;
    800030b8:	40bc                	lw	a5,64(s1)
    800030ba:	37fd                	addiw	a5,a5,-1
    800030bc:	0007871b          	sext.w	a4,a5
    800030c0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030c2:	eb05                	bnez	a4,800030f2 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030c4:	68bc                	ld	a5,80(s1)
    800030c6:	64b8                	ld	a4,72(s1)
    800030c8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030ca:	64bc                	ld	a5,72(s1)
    800030cc:	68b8                	ld	a4,80(s1)
    800030ce:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030d0:	0001c797          	auipc	a5,0x1c
    800030d4:	6b078793          	addi	a5,a5,1712 # 8001f780 <bcache+0x8000>
    800030d8:	2b87b703          	ld	a4,696(a5)
    800030dc:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030de:	0001d717          	auipc	a4,0x1d
    800030e2:	90a70713          	addi	a4,a4,-1782 # 8001f9e8 <bcache+0x8268>
    800030e6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030e8:	2b87b703          	ld	a4,696(a5)
    800030ec:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030ee:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030f2:	00014517          	auipc	a0,0x14
    800030f6:	68e50513          	addi	a0,a0,1678 # 80017780 <bcache>
    800030fa:	ffffe097          	auipc	ra,0xffffe
    800030fe:	c1c080e7          	jalr	-996(ra) # 80000d16 <release>
}
    80003102:	60e2                	ld	ra,24(sp)
    80003104:	6442                	ld	s0,16(sp)
    80003106:	64a2                	ld	s1,8(sp)
    80003108:	6902                	ld	s2,0(sp)
    8000310a:	6105                	addi	sp,sp,32
    8000310c:	8082                	ret
    panic("brelse");
    8000310e:	00005517          	auipc	a0,0x5
    80003112:	59a50513          	addi	a0,a0,1434 # 800086a8 <syscalls_name+0xf0>
    80003116:	ffffd097          	auipc	ra,0xffffd
    8000311a:	432080e7          	jalr	1074(ra) # 80000548 <panic>

000000008000311e <bpin>:

void
bpin(struct buf *b) {
    8000311e:	1101                	addi	sp,sp,-32
    80003120:	ec06                	sd	ra,24(sp)
    80003122:	e822                	sd	s0,16(sp)
    80003124:	e426                	sd	s1,8(sp)
    80003126:	1000                	addi	s0,sp,32
    80003128:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000312a:	00014517          	auipc	a0,0x14
    8000312e:	65650513          	addi	a0,a0,1622 # 80017780 <bcache>
    80003132:	ffffe097          	auipc	ra,0xffffe
    80003136:	b30080e7          	jalr	-1232(ra) # 80000c62 <acquire>
  b->refcnt++;
    8000313a:	40bc                	lw	a5,64(s1)
    8000313c:	2785                	addiw	a5,a5,1
    8000313e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003140:	00014517          	auipc	a0,0x14
    80003144:	64050513          	addi	a0,a0,1600 # 80017780 <bcache>
    80003148:	ffffe097          	auipc	ra,0xffffe
    8000314c:	bce080e7          	jalr	-1074(ra) # 80000d16 <release>
}
    80003150:	60e2                	ld	ra,24(sp)
    80003152:	6442                	ld	s0,16(sp)
    80003154:	64a2                	ld	s1,8(sp)
    80003156:	6105                	addi	sp,sp,32
    80003158:	8082                	ret

000000008000315a <bunpin>:

void
bunpin(struct buf *b) {
    8000315a:	1101                	addi	sp,sp,-32
    8000315c:	ec06                	sd	ra,24(sp)
    8000315e:	e822                	sd	s0,16(sp)
    80003160:	e426                	sd	s1,8(sp)
    80003162:	1000                	addi	s0,sp,32
    80003164:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003166:	00014517          	auipc	a0,0x14
    8000316a:	61a50513          	addi	a0,a0,1562 # 80017780 <bcache>
    8000316e:	ffffe097          	auipc	ra,0xffffe
    80003172:	af4080e7          	jalr	-1292(ra) # 80000c62 <acquire>
  b->refcnt--;
    80003176:	40bc                	lw	a5,64(s1)
    80003178:	37fd                	addiw	a5,a5,-1
    8000317a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000317c:	00014517          	auipc	a0,0x14
    80003180:	60450513          	addi	a0,a0,1540 # 80017780 <bcache>
    80003184:	ffffe097          	auipc	ra,0xffffe
    80003188:	b92080e7          	jalr	-1134(ra) # 80000d16 <release>
}
    8000318c:	60e2                	ld	ra,24(sp)
    8000318e:	6442                	ld	s0,16(sp)
    80003190:	64a2                	ld	s1,8(sp)
    80003192:	6105                	addi	sp,sp,32
    80003194:	8082                	ret

0000000080003196 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003196:	1101                	addi	sp,sp,-32
    80003198:	ec06                	sd	ra,24(sp)
    8000319a:	e822                	sd	s0,16(sp)
    8000319c:	e426                	sd	s1,8(sp)
    8000319e:	e04a                	sd	s2,0(sp)
    800031a0:	1000                	addi	s0,sp,32
    800031a2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031a4:	00d5d59b          	srliw	a1,a1,0xd
    800031a8:	0001d797          	auipc	a5,0x1d
    800031ac:	cb47a783          	lw	a5,-844(a5) # 8001fe5c <sb+0x1c>
    800031b0:	9dbd                	addw	a1,a1,a5
    800031b2:	00000097          	auipc	ra,0x0
    800031b6:	d9e080e7          	jalr	-610(ra) # 80002f50 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031ba:	0074f713          	andi	a4,s1,7
    800031be:	4785                	li	a5,1
    800031c0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031c4:	14ce                	slli	s1,s1,0x33
    800031c6:	90d9                	srli	s1,s1,0x36
    800031c8:	00950733          	add	a4,a0,s1
    800031cc:	05874703          	lbu	a4,88(a4)
    800031d0:	00e7f6b3          	and	a3,a5,a4
    800031d4:	c69d                	beqz	a3,80003202 <bfree+0x6c>
    800031d6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031d8:	94aa                	add	s1,s1,a0
    800031da:	fff7c793          	not	a5,a5
    800031de:	8ff9                	and	a5,a5,a4
    800031e0:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800031e4:	00001097          	auipc	ra,0x1
    800031e8:	100080e7          	jalr	256(ra) # 800042e4 <log_write>
  brelse(bp);
    800031ec:	854a                	mv	a0,s2
    800031ee:	00000097          	auipc	ra,0x0
    800031f2:	e92080e7          	jalr	-366(ra) # 80003080 <brelse>
}
    800031f6:	60e2                	ld	ra,24(sp)
    800031f8:	6442                	ld	s0,16(sp)
    800031fa:	64a2                	ld	s1,8(sp)
    800031fc:	6902                	ld	s2,0(sp)
    800031fe:	6105                	addi	sp,sp,32
    80003200:	8082                	ret
    panic("freeing free block");
    80003202:	00005517          	auipc	a0,0x5
    80003206:	4ae50513          	addi	a0,a0,1198 # 800086b0 <syscalls_name+0xf8>
    8000320a:	ffffd097          	auipc	ra,0xffffd
    8000320e:	33e080e7          	jalr	830(ra) # 80000548 <panic>

0000000080003212 <balloc>:
{
    80003212:	711d                	addi	sp,sp,-96
    80003214:	ec86                	sd	ra,88(sp)
    80003216:	e8a2                	sd	s0,80(sp)
    80003218:	e4a6                	sd	s1,72(sp)
    8000321a:	e0ca                	sd	s2,64(sp)
    8000321c:	fc4e                	sd	s3,56(sp)
    8000321e:	f852                	sd	s4,48(sp)
    80003220:	f456                	sd	s5,40(sp)
    80003222:	f05a                	sd	s6,32(sp)
    80003224:	ec5e                	sd	s7,24(sp)
    80003226:	e862                	sd	s8,16(sp)
    80003228:	e466                	sd	s9,8(sp)
    8000322a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000322c:	0001d797          	auipc	a5,0x1d
    80003230:	c187a783          	lw	a5,-1000(a5) # 8001fe44 <sb+0x4>
    80003234:	cbd1                	beqz	a5,800032c8 <balloc+0xb6>
    80003236:	8baa                	mv	s7,a0
    80003238:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000323a:	0001db17          	auipc	s6,0x1d
    8000323e:	c06b0b13          	addi	s6,s6,-1018 # 8001fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003242:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003244:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003246:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003248:	6c89                	lui	s9,0x2
    8000324a:	a831                	j	80003266 <balloc+0x54>
    brelse(bp);
    8000324c:	854a                	mv	a0,s2
    8000324e:	00000097          	auipc	ra,0x0
    80003252:	e32080e7          	jalr	-462(ra) # 80003080 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003256:	015c87bb          	addw	a5,s9,s5
    8000325a:	00078a9b          	sext.w	s5,a5
    8000325e:	004b2703          	lw	a4,4(s6)
    80003262:	06eaf363          	bgeu	s5,a4,800032c8 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003266:	41fad79b          	sraiw	a5,s5,0x1f
    8000326a:	0137d79b          	srliw	a5,a5,0x13
    8000326e:	015787bb          	addw	a5,a5,s5
    80003272:	40d7d79b          	sraiw	a5,a5,0xd
    80003276:	01cb2583          	lw	a1,28(s6)
    8000327a:	9dbd                	addw	a1,a1,a5
    8000327c:	855e                	mv	a0,s7
    8000327e:	00000097          	auipc	ra,0x0
    80003282:	cd2080e7          	jalr	-814(ra) # 80002f50 <bread>
    80003286:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003288:	004b2503          	lw	a0,4(s6)
    8000328c:	000a849b          	sext.w	s1,s5
    80003290:	8662                	mv	a2,s8
    80003292:	faa4fde3          	bgeu	s1,a0,8000324c <balloc+0x3a>
      m = 1 << (bi % 8);
    80003296:	41f6579b          	sraiw	a5,a2,0x1f
    8000329a:	01d7d69b          	srliw	a3,a5,0x1d
    8000329e:	00c6873b          	addw	a4,a3,a2
    800032a2:	00777793          	andi	a5,a4,7
    800032a6:	9f95                	subw	a5,a5,a3
    800032a8:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032ac:	4037571b          	sraiw	a4,a4,0x3
    800032b0:	00e906b3          	add	a3,s2,a4
    800032b4:	0586c683          	lbu	a3,88(a3)
    800032b8:	00d7f5b3          	and	a1,a5,a3
    800032bc:	cd91                	beqz	a1,800032d8 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032be:	2605                	addiw	a2,a2,1
    800032c0:	2485                	addiw	s1,s1,1
    800032c2:	fd4618e3          	bne	a2,s4,80003292 <balloc+0x80>
    800032c6:	b759                	j	8000324c <balloc+0x3a>
  panic("balloc: out of blocks");
    800032c8:	00005517          	auipc	a0,0x5
    800032cc:	40050513          	addi	a0,a0,1024 # 800086c8 <syscalls_name+0x110>
    800032d0:	ffffd097          	auipc	ra,0xffffd
    800032d4:	278080e7          	jalr	632(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032d8:	974a                	add	a4,a4,s2
    800032da:	8fd5                	or	a5,a5,a3
    800032dc:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032e0:	854a                	mv	a0,s2
    800032e2:	00001097          	auipc	ra,0x1
    800032e6:	002080e7          	jalr	2(ra) # 800042e4 <log_write>
        brelse(bp);
    800032ea:	854a                	mv	a0,s2
    800032ec:	00000097          	auipc	ra,0x0
    800032f0:	d94080e7          	jalr	-620(ra) # 80003080 <brelse>
  bp = bread(dev, bno);
    800032f4:	85a6                	mv	a1,s1
    800032f6:	855e                	mv	a0,s7
    800032f8:	00000097          	auipc	ra,0x0
    800032fc:	c58080e7          	jalr	-936(ra) # 80002f50 <bread>
    80003300:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003302:	40000613          	li	a2,1024
    80003306:	4581                	li	a1,0
    80003308:	05850513          	addi	a0,a0,88
    8000330c:	ffffe097          	auipc	ra,0xffffe
    80003310:	a52080e7          	jalr	-1454(ra) # 80000d5e <memset>
  log_write(bp);
    80003314:	854a                	mv	a0,s2
    80003316:	00001097          	auipc	ra,0x1
    8000331a:	fce080e7          	jalr	-50(ra) # 800042e4 <log_write>
  brelse(bp);
    8000331e:	854a                	mv	a0,s2
    80003320:	00000097          	auipc	ra,0x0
    80003324:	d60080e7          	jalr	-672(ra) # 80003080 <brelse>
}
    80003328:	8526                	mv	a0,s1
    8000332a:	60e6                	ld	ra,88(sp)
    8000332c:	6446                	ld	s0,80(sp)
    8000332e:	64a6                	ld	s1,72(sp)
    80003330:	6906                	ld	s2,64(sp)
    80003332:	79e2                	ld	s3,56(sp)
    80003334:	7a42                	ld	s4,48(sp)
    80003336:	7aa2                	ld	s5,40(sp)
    80003338:	7b02                	ld	s6,32(sp)
    8000333a:	6be2                	ld	s7,24(sp)
    8000333c:	6c42                	ld	s8,16(sp)
    8000333e:	6ca2                	ld	s9,8(sp)
    80003340:	6125                	addi	sp,sp,96
    80003342:	8082                	ret

0000000080003344 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003344:	7179                	addi	sp,sp,-48
    80003346:	f406                	sd	ra,40(sp)
    80003348:	f022                	sd	s0,32(sp)
    8000334a:	ec26                	sd	s1,24(sp)
    8000334c:	e84a                	sd	s2,16(sp)
    8000334e:	e44e                	sd	s3,8(sp)
    80003350:	e052                	sd	s4,0(sp)
    80003352:	1800                	addi	s0,sp,48
    80003354:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003356:	47ad                	li	a5,11
    80003358:	04b7fe63          	bgeu	a5,a1,800033b4 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000335c:	ff45849b          	addiw	s1,a1,-12
    80003360:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003364:	0ff00793          	li	a5,255
    80003368:	0ae7e363          	bltu	a5,a4,8000340e <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000336c:	08052583          	lw	a1,128(a0)
    80003370:	c5ad                	beqz	a1,800033da <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003372:	00092503          	lw	a0,0(s2)
    80003376:	00000097          	auipc	ra,0x0
    8000337a:	bda080e7          	jalr	-1062(ra) # 80002f50 <bread>
    8000337e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003380:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003384:	02049593          	slli	a1,s1,0x20
    80003388:	9181                	srli	a1,a1,0x20
    8000338a:	058a                	slli	a1,a1,0x2
    8000338c:	00b784b3          	add	s1,a5,a1
    80003390:	0004a983          	lw	s3,0(s1)
    80003394:	04098d63          	beqz	s3,800033ee <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003398:	8552                	mv	a0,s4
    8000339a:	00000097          	auipc	ra,0x0
    8000339e:	ce6080e7          	jalr	-794(ra) # 80003080 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033a2:	854e                	mv	a0,s3
    800033a4:	70a2                	ld	ra,40(sp)
    800033a6:	7402                	ld	s0,32(sp)
    800033a8:	64e2                	ld	s1,24(sp)
    800033aa:	6942                	ld	s2,16(sp)
    800033ac:	69a2                	ld	s3,8(sp)
    800033ae:	6a02                	ld	s4,0(sp)
    800033b0:	6145                	addi	sp,sp,48
    800033b2:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800033b4:	02059493          	slli	s1,a1,0x20
    800033b8:	9081                	srli	s1,s1,0x20
    800033ba:	048a                	slli	s1,s1,0x2
    800033bc:	94aa                	add	s1,s1,a0
    800033be:	0504a983          	lw	s3,80(s1)
    800033c2:	fe0990e3          	bnez	s3,800033a2 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800033c6:	4108                	lw	a0,0(a0)
    800033c8:	00000097          	auipc	ra,0x0
    800033cc:	e4a080e7          	jalr	-438(ra) # 80003212 <balloc>
    800033d0:	0005099b          	sext.w	s3,a0
    800033d4:	0534a823          	sw	s3,80(s1)
    800033d8:	b7e9                	j	800033a2 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800033da:	4108                	lw	a0,0(a0)
    800033dc:	00000097          	auipc	ra,0x0
    800033e0:	e36080e7          	jalr	-458(ra) # 80003212 <balloc>
    800033e4:	0005059b          	sext.w	a1,a0
    800033e8:	08b92023          	sw	a1,128(s2)
    800033ec:	b759                	j	80003372 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800033ee:	00092503          	lw	a0,0(s2)
    800033f2:	00000097          	auipc	ra,0x0
    800033f6:	e20080e7          	jalr	-480(ra) # 80003212 <balloc>
    800033fa:	0005099b          	sext.w	s3,a0
    800033fe:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003402:	8552                	mv	a0,s4
    80003404:	00001097          	auipc	ra,0x1
    80003408:	ee0080e7          	jalr	-288(ra) # 800042e4 <log_write>
    8000340c:	b771                	j	80003398 <bmap+0x54>
  panic("bmap: out of range");
    8000340e:	00005517          	auipc	a0,0x5
    80003412:	2d250513          	addi	a0,a0,722 # 800086e0 <syscalls_name+0x128>
    80003416:	ffffd097          	auipc	ra,0xffffd
    8000341a:	132080e7          	jalr	306(ra) # 80000548 <panic>

000000008000341e <iget>:
{
    8000341e:	7179                	addi	sp,sp,-48
    80003420:	f406                	sd	ra,40(sp)
    80003422:	f022                	sd	s0,32(sp)
    80003424:	ec26                	sd	s1,24(sp)
    80003426:	e84a                	sd	s2,16(sp)
    80003428:	e44e                	sd	s3,8(sp)
    8000342a:	e052                	sd	s4,0(sp)
    8000342c:	1800                	addi	s0,sp,48
    8000342e:	89aa                	mv	s3,a0
    80003430:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003432:	0001d517          	auipc	a0,0x1d
    80003436:	a2e50513          	addi	a0,a0,-1490 # 8001fe60 <icache>
    8000343a:	ffffe097          	auipc	ra,0xffffe
    8000343e:	828080e7          	jalr	-2008(ra) # 80000c62 <acquire>
  empty = 0;
    80003442:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003444:	0001d497          	auipc	s1,0x1d
    80003448:	a3448493          	addi	s1,s1,-1484 # 8001fe78 <icache+0x18>
    8000344c:	0001e697          	auipc	a3,0x1e
    80003450:	4bc68693          	addi	a3,a3,1212 # 80021908 <log>
    80003454:	a039                	j	80003462 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003456:	02090b63          	beqz	s2,8000348c <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000345a:	08848493          	addi	s1,s1,136
    8000345e:	02d48a63          	beq	s1,a3,80003492 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003462:	449c                	lw	a5,8(s1)
    80003464:	fef059e3          	blez	a5,80003456 <iget+0x38>
    80003468:	4098                	lw	a4,0(s1)
    8000346a:	ff3716e3          	bne	a4,s3,80003456 <iget+0x38>
    8000346e:	40d8                	lw	a4,4(s1)
    80003470:	ff4713e3          	bne	a4,s4,80003456 <iget+0x38>
      ip->ref++;
    80003474:	2785                	addiw	a5,a5,1
    80003476:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003478:	0001d517          	auipc	a0,0x1d
    8000347c:	9e850513          	addi	a0,a0,-1560 # 8001fe60 <icache>
    80003480:	ffffe097          	auipc	ra,0xffffe
    80003484:	896080e7          	jalr	-1898(ra) # 80000d16 <release>
      return ip;
    80003488:	8926                	mv	s2,s1
    8000348a:	a03d                	j	800034b8 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000348c:	f7f9                	bnez	a5,8000345a <iget+0x3c>
    8000348e:	8926                	mv	s2,s1
    80003490:	b7e9                	j	8000345a <iget+0x3c>
  if(empty == 0)
    80003492:	02090c63          	beqz	s2,800034ca <iget+0xac>
  ip->dev = dev;
    80003496:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000349a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000349e:	4785                	li	a5,1
    800034a0:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034a4:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800034a8:	0001d517          	auipc	a0,0x1d
    800034ac:	9b850513          	addi	a0,a0,-1608 # 8001fe60 <icache>
    800034b0:	ffffe097          	auipc	ra,0xffffe
    800034b4:	866080e7          	jalr	-1946(ra) # 80000d16 <release>
}
    800034b8:	854a                	mv	a0,s2
    800034ba:	70a2                	ld	ra,40(sp)
    800034bc:	7402                	ld	s0,32(sp)
    800034be:	64e2                	ld	s1,24(sp)
    800034c0:	6942                	ld	s2,16(sp)
    800034c2:	69a2                	ld	s3,8(sp)
    800034c4:	6a02                	ld	s4,0(sp)
    800034c6:	6145                	addi	sp,sp,48
    800034c8:	8082                	ret
    panic("iget: no inodes");
    800034ca:	00005517          	auipc	a0,0x5
    800034ce:	22e50513          	addi	a0,a0,558 # 800086f8 <syscalls_name+0x140>
    800034d2:	ffffd097          	auipc	ra,0xffffd
    800034d6:	076080e7          	jalr	118(ra) # 80000548 <panic>

00000000800034da <fsinit>:
fsinit(int dev) {
    800034da:	7179                	addi	sp,sp,-48
    800034dc:	f406                	sd	ra,40(sp)
    800034de:	f022                	sd	s0,32(sp)
    800034e0:	ec26                	sd	s1,24(sp)
    800034e2:	e84a                	sd	s2,16(sp)
    800034e4:	e44e                	sd	s3,8(sp)
    800034e6:	1800                	addi	s0,sp,48
    800034e8:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034ea:	4585                	li	a1,1
    800034ec:	00000097          	auipc	ra,0x0
    800034f0:	a64080e7          	jalr	-1436(ra) # 80002f50 <bread>
    800034f4:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034f6:	0001d997          	auipc	s3,0x1d
    800034fa:	94a98993          	addi	s3,s3,-1718 # 8001fe40 <sb>
    800034fe:	02000613          	li	a2,32
    80003502:	05850593          	addi	a1,a0,88
    80003506:	854e                	mv	a0,s3
    80003508:	ffffe097          	auipc	ra,0xffffe
    8000350c:	8b6080e7          	jalr	-1866(ra) # 80000dbe <memmove>
  brelse(bp);
    80003510:	8526                	mv	a0,s1
    80003512:	00000097          	auipc	ra,0x0
    80003516:	b6e080e7          	jalr	-1170(ra) # 80003080 <brelse>
  if(sb.magic != FSMAGIC)
    8000351a:	0009a703          	lw	a4,0(s3)
    8000351e:	102037b7          	lui	a5,0x10203
    80003522:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003526:	02f71263          	bne	a4,a5,8000354a <fsinit+0x70>
  initlog(dev, &sb);
    8000352a:	0001d597          	auipc	a1,0x1d
    8000352e:	91658593          	addi	a1,a1,-1770 # 8001fe40 <sb>
    80003532:	854a                	mv	a0,s2
    80003534:	00001097          	auipc	ra,0x1
    80003538:	b38080e7          	jalr	-1224(ra) # 8000406c <initlog>
}
    8000353c:	70a2                	ld	ra,40(sp)
    8000353e:	7402                	ld	s0,32(sp)
    80003540:	64e2                	ld	s1,24(sp)
    80003542:	6942                	ld	s2,16(sp)
    80003544:	69a2                	ld	s3,8(sp)
    80003546:	6145                	addi	sp,sp,48
    80003548:	8082                	ret
    panic("invalid file system");
    8000354a:	00005517          	auipc	a0,0x5
    8000354e:	1be50513          	addi	a0,a0,446 # 80008708 <syscalls_name+0x150>
    80003552:	ffffd097          	auipc	ra,0xffffd
    80003556:	ff6080e7          	jalr	-10(ra) # 80000548 <panic>

000000008000355a <iinit>:
{
    8000355a:	7179                	addi	sp,sp,-48
    8000355c:	f406                	sd	ra,40(sp)
    8000355e:	f022                	sd	s0,32(sp)
    80003560:	ec26                	sd	s1,24(sp)
    80003562:	e84a                	sd	s2,16(sp)
    80003564:	e44e                	sd	s3,8(sp)
    80003566:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003568:	00005597          	auipc	a1,0x5
    8000356c:	1b858593          	addi	a1,a1,440 # 80008720 <syscalls_name+0x168>
    80003570:	0001d517          	auipc	a0,0x1d
    80003574:	8f050513          	addi	a0,a0,-1808 # 8001fe60 <icache>
    80003578:	ffffd097          	auipc	ra,0xffffd
    8000357c:	65a080e7          	jalr	1626(ra) # 80000bd2 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003580:	0001d497          	auipc	s1,0x1d
    80003584:	90848493          	addi	s1,s1,-1784 # 8001fe88 <icache+0x28>
    80003588:	0001e997          	auipc	s3,0x1e
    8000358c:	39098993          	addi	s3,s3,912 # 80021918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003590:	00005917          	auipc	s2,0x5
    80003594:	19890913          	addi	s2,s2,408 # 80008728 <syscalls_name+0x170>
    80003598:	85ca                	mv	a1,s2
    8000359a:	8526                	mv	a0,s1
    8000359c:	00001097          	auipc	ra,0x1
    800035a0:	e36080e7          	jalr	-458(ra) # 800043d2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035a4:	08848493          	addi	s1,s1,136
    800035a8:	ff3498e3          	bne	s1,s3,80003598 <iinit+0x3e>
}
    800035ac:	70a2                	ld	ra,40(sp)
    800035ae:	7402                	ld	s0,32(sp)
    800035b0:	64e2                	ld	s1,24(sp)
    800035b2:	6942                	ld	s2,16(sp)
    800035b4:	69a2                	ld	s3,8(sp)
    800035b6:	6145                	addi	sp,sp,48
    800035b8:	8082                	ret

00000000800035ba <ialloc>:
{
    800035ba:	715d                	addi	sp,sp,-80
    800035bc:	e486                	sd	ra,72(sp)
    800035be:	e0a2                	sd	s0,64(sp)
    800035c0:	fc26                	sd	s1,56(sp)
    800035c2:	f84a                	sd	s2,48(sp)
    800035c4:	f44e                	sd	s3,40(sp)
    800035c6:	f052                	sd	s4,32(sp)
    800035c8:	ec56                	sd	s5,24(sp)
    800035ca:	e85a                	sd	s6,16(sp)
    800035cc:	e45e                	sd	s7,8(sp)
    800035ce:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035d0:	0001d717          	auipc	a4,0x1d
    800035d4:	87c72703          	lw	a4,-1924(a4) # 8001fe4c <sb+0xc>
    800035d8:	4785                	li	a5,1
    800035da:	04e7fa63          	bgeu	a5,a4,8000362e <ialloc+0x74>
    800035de:	8aaa                	mv	s5,a0
    800035e0:	8bae                	mv	s7,a1
    800035e2:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035e4:	0001da17          	auipc	s4,0x1d
    800035e8:	85ca0a13          	addi	s4,s4,-1956 # 8001fe40 <sb>
    800035ec:	00048b1b          	sext.w	s6,s1
    800035f0:	0044d593          	srli	a1,s1,0x4
    800035f4:	018a2783          	lw	a5,24(s4)
    800035f8:	9dbd                	addw	a1,a1,a5
    800035fa:	8556                	mv	a0,s5
    800035fc:	00000097          	auipc	ra,0x0
    80003600:	954080e7          	jalr	-1708(ra) # 80002f50 <bread>
    80003604:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003606:	05850993          	addi	s3,a0,88
    8000360a:	00f4f793          	andi	a5,s1,15
    8000360e:	079a                	slli	a5,a5,0x6
    80003610:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003612:	00099783          	lh	a5,0(s3)
    80003616:	c785                	beqz	a5,8000363e <ialloc+0x84>
    brelse(bp);
    80003618:	00000097          	auipc	ra,0x0
    8000361c:	a68080e7          	jalr	-1432(ra) # 80003080 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003620:	0485                	addi	s1,s1,1
    80003622:	00ca2703          	lw	a4,12(s4)
    80003626:	0004879b          	sext.w	a5,s1
    8000362a:	fce7e1e3          	bltu	a5,a4,800035ec <ialloc+0x32>
  panic("ialloc: no inodes");
    8000362e:	00005517          	auipc	a0,0x5
    80003632:	10250513          	addi	a0,a0,258 # 80008730 <syscalls_name+0x178>
    80003636:	ffffd097          	auipc	ra,0xffffd
    8000363a:	f12080e7          	jalr	-238(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    8000363e:	04000613          	li	a2,64
    80003642:	4581                	li	a1,0
    80003644:	854e                	mv	a0,s3
    80003646:	ffffd097          	auipc	ra,0xffffd
    8000364a:	718080e7          	jalr	1816(ra) # 80000d5e <memset>
      dip->type = type;
    8000364e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003652:	854a                	mv	a0,s2
    80003654:	00001097          	auipc	ra,0x1
    80003658:	c90080e7          	jalr	-880(ra) # 800042e4 <log_write>
      brelse(bp);
    8000365c:	854a                	mv	a0,s2
    8000365e:	00000097          	auipc	ra,0x0
    80003662:	a22080e7          	jalr	-1502(ra) # 80003080 <brelse>
      return iget(dev, inum);
    80003666:	85da                	mv	a1,s6
    80003668:	8556                	mv	a0,s5
    8000366a:	00000097          	auipc	ra,0x0
    8000366e:	db4080e7          	jalr	-588(ra) # 8000341e <iget>
}
    80003672:	60a6                	ld	ra,72(sp)
    80003674:	6406                	ld	s0,64(sp)
    80003676:	74e2                	ld	s1,56(sp)
    80003678:	7942                	ld	s2,48(sp)
    8000367a:	79a2                	ld	s3,40(sp)
    8000367c:	7a02                	ld	s4,32(sp)
    8000367e:	6ae2                	ld	s5,24(sp)
    80003680:	6b42                	ld	s6,16(sp)
    80003682:	6ba2                	ld	s7,8(sp)
    80003684:	6161                	addi	sp,sp,80
    80003686:	8082                	ret

0000000080003688 <iupdate>:
{
    80003688:	1101                	addi	sp,sp,-32
    8000368a:	ec06                	sd	ra,24(sp)
    8000368c:	e822                	sd	s0,16(sp)
    8000368e:	e426                	sd	s1,8(sp)
    80003690:	e04a                	sd	s2,0(sp)
    80003692:	1000                	addi	s0,sp,32
    80003694:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003696:	415c                	lw	a5,4(a0)
    80003698:	0047d79b          	srliw	a5,a5,0x4
    8000369c:	0001c597          	auipc	a1,0x1c
    800036a0:	7bc5a583          	lw	a1,1980(a1) # 8001fe58 <sb+0x18>
    800036a4:	9dbd                	addw	a1,a1,a5
    800036a6:	4108                	lw	a0,0(a0)
    800036a8:	00000097          	auipc	ra,0x0
    800036ac:	8a8080e7          	jalr	-1880(ra) # 80002f50 <bread>
    800036b0:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036b2:	05850793          	addi	a5,a0,88
    800036b6:	40c8                	lw	a0,4(s1)
    800036b8:	893d                	andi	a0,a0,15
    800036ba:	051a                	slli	a0,a0,0x6
    800036bc:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036be:	04449703          	lh	a4,68(s1)
    800036c2:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800036c6:	04649703          	lh	a4,70(s1)
    800036ca:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800036ce:	04849703          	lh	a4,72(s1)
    800036d2:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800036d6:	04a49703          	lh	a4,74(s1)
    800036da:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800036de:	44f8                	lw	a4,76(s1)
    800036e0:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036e2:	03400613          	li	a2,52
    800036e6:	05048593          	addi	a1,s1,80
    800036ea:	0531                	addi	a0,a0,12
    800036ec:	ffffd097          	auipc	ra,0xffffd
    800036f0:	6d2080e7          	jalr	1746(ra) # 80000dbe <memmove>
  log_write(bp);
    800036f4:	854a                	mv	a0,s2
    800036f6:	00001097          	auipc	ra,0x1
    800036fa:	bee080e7          	jalr	-1042(ra) # 800042e4 <log_write>
  brelse(bp);
    800036fe:	854a                	mv	a0,s2
    80003700:	00000097          	auipc	ra,0x0
    80003704:	980080e7          	jalr	-1664(ra) # 80003080 <brelse>
}
    80003708:	60e2                	ld	ra,24(sp)
    8000370a:	6442                	ld	s0,16(sp)
    8000370c:	64a2                	ld	s1,8(sp)
    8000370e:	6902                	ld	s2,0(sp)
    80003710:	6105                	addi	sp,sp,32
    80003712:	8082                	ret

0000000080003714 <idup>:
{
    80003714:	1101                	addi	sp,sp,-32
    80003716:	ec06                	sd	ra,24(sp)
    80003718:	e822                	sd	s0,16(sp)
    8000371a:	e426                	sd	s1,8(sp)
    8000371c:	1000                	addi	s0,sp,32
    8000371e:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003720:	0001c517          	auipc	a0,0x1c
    80003724:	74050513          	addi	a0,a0,1856 # 8001fe60 <icache>
    80003728:	ffffd097          	auipc	ra,0xffffd
    8000372c:	53a080e7          	jalr	1338(ra) # 80000c62 <acquire>
  ip->ref++;
    80003730:	449c                	lw	a5,8(s1)
    80003732:	2785                	addiw	a5,a5,1
    80003734:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003736:	0001c517          	auipc	a0,0x1c
    8000373a:	72a50513          	addi	a0,a0,1834 # 8001fe60 <icache>
    8000373e:	ffffd097          	auipc	ra,0xffffd
    80003742:	5d8080e7          	jalr	1496(ra) # 80000d16 <release>
}
    80003746:	8526                	mv	a0,s1
    80003748:	60e2                	ld	ra,24(sp)
    8000374a:	6442                	ld	s0,16(sp)
    8000374c:	64a2                	ld	s1,8(sp)
    8000374e:	6105                	addi	sp,sp,32
    80003750:	8082                	ret

0000000080003752 <ilock>:
{
    80003752:	1101                	addi	sp,sp,-32
    80003754:	ec06                	sd	ra,24(sp)
    80003756:	e822                	sd	s0,16(sp)
    80003758:	e426                	sd	s1,8(sp)
    8000375a:	e04a                	sd	s2,0(sp)
    8000375c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000375e:	c115                	beqz	a0,80003782 <ilock+0x30>
    80003760:	84aa                	mv	s1,a0
    80003762:	451c                	lw	a5,8(a0)
    80003764:	00f05f63          	blez	a5,80003782 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003768:	0541                	addi	a0,a0,16
    8000376a:	00001097          	auipc	ra,0x1
    8000376e:	ca2080e7          	jalr	-862(ra) # 8000440c <acquiresleep>
  if(ip->valid == 0){
    80003772:	40bc                	lw	a5,64(s1)
    80003774:	cf99                	beqz	a5,80003792 <ilock+0x40>
}
    80003776:	60e2                	ld	ra,24(sp)
    80003778:	6442                	ld	s0,16(sp)
    8000377a:	64a2                	ld	s1,8(sp)
    8000377c:	6902                	ld	s2,0(sp)
    8000377e:	6105                	addi	sp,sp,32
    80003780:	8082                	ret
    panic("ilock");
    80003782:	00005517          	auipc	a0,0x5
    80003786:	fc650513          	addi	a0,a0,-58 # 80008748 <syscalls_name+0x190>
    8000378a:	ffffd097          	auipc	ra,0xffffd
    8000378e:	dbe080e7          	jalr	-578(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003792:	40dc                	lw	a5,4(s1)
    80003794:	0047d79b          	srliw	a5,a5,0x4
    80003798:	0001c597          	auipc	a1,0x1c
    8000379c:	6c05a583          	lw	a1,1728(a1) # 8001fe58 <sb+0x18>
    800037a0:	9dbd                	addw	a1,a1,a5
    800037a2:	4088                	lw	a0,0(s1)
    800037a4:	fffff097          	auipc	ra,0xfffff
    800037a8:	7ac080e7          	jalr	1964(ra) # 80002f50 <bread>
    800037ac:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037ae:	05850593          	addi	a1,a0,88
    800037b2:	40dc                	lw	a5,4(s1)
    800037b4:	8bbd                	andi	a5,a5,15
    800037b6:	079a                	slli	a5,a5,0x6
    800037b8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037ba:	00059783          	lh	a5,0(a1)
    800037be:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037c2:	00259783          	lh	a5,2(a1)
    800037c6:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037ca:	00459783          	lh	a5,4(a1)
    800037ce:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037d2:	00659783          	lh	a5,6(a1)
    800037d6:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037da:	459c                	lw	a5,8(a1)
    800037dc:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037de:	03400613          	li	a2,52
    800037e2:	05b1                	addi	a1,a1,12
    800037e4:	05048513          	addi	a0,s1,80
    800037e8:	ffffd097          	auipc	ra,0xffffd
    800037ec:	5d6080e7          	jalr	1494(ra) # 80000dbe <memmove>
    brelse(bp);
    800037f0:	854a                	mv	a0,s2
    800037f2:	00000097          	auipc	ra,0x0
    800037f6:	88e080e7          	jalr	-1906(ra) # 80003080 <brelse>
    ip->valid = 1;
    800037fa:	4785                	li	a5,1
    800037fc:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037fe:	04449783          	lh	a5,68(s1)
    80003802:	fbb5                	bnez	a5,80003776 <ilock+0x24>
      panic("ilock: no type");
    80003804:	00005517          	auipc	a0,0x5
    80003808:	f4c50513          	addi	a0,a0,-180 # 80008750 <syscalls_name+0x198>
    8000380c:	ffffd097          	auipc	ra,0xffffd
    80003810:	d3c080e7          	jalr	-708(ra) # 80000548 <panic>

0000000080003814 <iunlock>:
{
    80003814:	1101                	addi	sp,sp,-32
    80003816:	ec06                	sd	ra,24(sp)
    80003818:	e822                	sd	s0,16(sp)
    8000381a:	e426                	sd	s1,8(sp)
    8000381c:	e04a                	sd	s2,0(sp)
    8000381e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003820:	c905                	beqz	a0,80003850 <iunlock+0x3c>
    80003822:	84aa                	mv	s1,a0
    80003824:	01050913          	addi	s2,a0,16
    80003828:	854a                	mv	a0,s2
    8000382a:	00001097          	auipc	ra,0x1
    8000382e:	c7c080e7          	jalr	-900(ra) # 800044a6 <holdingsleep>
    80003832:	cd19                	beqz	a0,80003850 <iunlock+0x3c>
    80003834:	449c                	lw	a5,8(s1)
    80003836:	00f05d63          	blez	a5,80003850 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000383a:	854a                	mv	a0,s2
    8000383c:	00001097          	auipc	ra,0x1
    80003840:	c26080e7          	jalr	-986(ra) # 80004462 <releasesleep>
}
    80003844:	60e2                	ld	ra,24(sp)
    80003846:	6442                	ld	s0,16(sp)
    80003848:	64a2                	ld	s1,8(sp)
    8000384a:	6902                	ld	s2,0(sp)
    8000384c:	6105                	addi	sp,sp,32
    8000384e:	8082                	ret
    panic("iunlock");
    80003850:	00005517          	auipc	a0,0x5
    80003854:	f1050513          	addi	a0,a0,-240 # 80008760 <syscalls_name+0x1a8>
    80003858:	ffffd097          	auipc	ra,0xffffd
    8000385c:	cf0080e7          	jalr	-784(ra) # 80000548 <panic>

0000000080003860 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003860:	7179                	addi	sp,sp,-48
    80003862:	f406                	sd	ra,40(sp)
    80003864:	f022                	sd	s0,32(sp)
    80003866:	ec26                	sd	s1,24(sp)
    80003868:	e84a                	sd	s2,16(sp)
    8000386a:	e44e                	sd	s3,8(sp)
    8000386c:	e052                	sd	s4,0(sp)
    8000386e:	1800                	addi	s0,sp,48
    80003870:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003872:	05050493          	addi	s1,a0,80
    80003876:	08050913          	addi	s2,a0,128
    8000387a:	a021                	j	80003882 <itrunc+0x22>
    8000387c:	0491                	addi	s1,s1,4
    8000387e:	01248d63          	beq	s1,s2,80003898 <itrunc+0x38>
    if(ip->addrs[i]){
    80003882:	408c                	lw	a1,0(s1)
    80003884:	dde5                	beqz	a1,8000387c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003886:	0009a503          	lw	a0,0(s3)
    8000388a:	00000097          	auipc	ra,0x0
    8000388e:	90c080e7          	jalr	-1780(ra) # 80003196 <bfree>
      ip->addrs[i] = 0;
    80003892:	0004a023          	sw	zero,0(s1)
    80003896:	b7dd                	j	8000387c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003898:	0809a583          	lw	a1,128(s3)
    8000389c:	e185                	bnez	a1,800038bc <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000389e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038a2:	854e                	mv	a0,s3
    800038a4:	00000097          	auipc	ra,0x0
    800038a8:	de4080e7          	jalr	-540(ra) # 80003688 <iupdate>
}
    800038ac:	70a2                	ld	ra,40(sp)
    800038ae:	7402                	ld	s0,32(sp)
    800038b0:	64e2                	ld	s1,24(sp)
    800038b2:	6942                	ld	s2,16(sp)
    800038b4:	69a2                	ld	s3,8(sp)
    800038b6:	6a02                	ld	s4,0(sp)
    800038b8:	6145                	addi	sp,sp,48
    800038ba:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038bc:	0009a503          	lw	a0,0(s3)
    800038c0:	fffff097          	auipc	ra,0xfffff
    800038c4:	690080e7          	jalr	1680(ra) # 80002f50 <bread>
    800038c8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038ca:	05850493          	addi	s1,a0,88
    800038ce:	45850913          	addi	s2,a0,1112
    800038d2:	a811                	j	800038e6 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800038d4:	0009a503          	lw	a0,0(s3)
    800038d8:	00000097          	auipc	ra,0x0
    800038dc:	8be080e7          	jalr	-1858(ra) # 80003196 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800038e0:	0491                	addi	s1,s1,4
    800038e2:	01248563          	beq	s1,s2,800038ec <itrunc+0x8c>
      if(a[j])
    800038e6:	408c                	lw	a1,0(s1)
    800038e8:	dde5                	beqz	a1,800038e0 <itrunc+0x80>
    800038ea:	b7ed                	j	800038d4 <itrunc+0x74>
    brelse(bp);
    800038ec:	8552                	mv	a0,s4
    800038ee:	fffff097          	auipc	ra,0xfffff
    800038f2:	792080e7          	jalr	1938(ra) # 80003080 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038f6:	0809a583          	lw	a1,128(s3)
    800038fa:	0009a503          	lw	a0,0(s3)
    800038fe:	00000097          	auipc	ra,0x0
    80003902:	898080e7          	jalr	-1896(ra) # 80003196 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003906:	0809a023          	sw	zero,128(s3)
    8000390a:	bf51                	j	8000389e <itrunc+0x3e>

000000008000390c <iput>:
{
    8000390c:	1101                	addi	sp,sp,-32
    8000390e:	ec06                	sd	ra,24(sp)
    80003910:	e822                	sd	s0,16(sp)
    80003912:	e426                	sd	s1,8(sp)
    80003914:	e04a                	sd	s2,0(sp)
    80003916:	1000                	addi	s0,sp,32
    80003918:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000391a:	0001c517          	auipc	a0,0x1c
    8000391e:	54650513          	addi	a0,a0,1350 # 8001fe60 <icache>
    80003922:	ffffd097          	auipc	ra,0xffffd
    80003926:	340080e7          	jalr	832(ra) # 80000c62 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000392a:	4498                	lw	a4,8(s1)
    8000392c:	4785                	li	a5,1
    8000392e:	02f70363          	beq	a4,a5,80003954 <iput+0x48>
  ip->ref--;
    80003932:	449c                	lw	a5,8(s1)
    80003934:	37fd                	addiw	a5,a5,-1
    80003936:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003938:	0001c517          	auipc	a0,0x1c
    8000393c:	52850513          	addi	a0,a0,1320 # 8001fe60 <icache>
    80003940:	ffffd097          	auipc	ra,0xffffd
    80003944:	3d6080e7          	jalr	982(ra) # 80000d16 <release>
}
    80003948:	60e2                	ld	ra,24(sp)
    8000394a:	6442                	ld	s0,16(sp)
    8000394c:	64a2                	ld	s1,8(sp)
    8000394e:	6902                	ld	s2,0(sp)
    80003950:	6105                	addi	sp,sp,32
    80003952:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003954:	40bc                	lw	a5,64(s1)
    80003956:	dff1                	beqz	a5,80003932 <iput+0x26>
    80003958:	04a49783          	lh	a5,74(s1)
    8000395c:	fbf9                	bnez	a5,80003932 <iput+0x26>
    acquiresleep(&ip->lock);
    8000395e:	01048913          	addi	s2,s1,16
    80003962:	854a                	mv	a0,s2
    80003964:	00001097          	auipc	ra,0x1
    80003968:	aa8080e7          	jalr	-1368(ra) # 8000440c <acquiresleep>
    release(&icache.lock);
    8000396c:	0001c517          	auipc	a0,0x1c
    80003970:	4f450513          	addi	a0,a0,1268 # 8001fe60 <icache>
    80003974:	ffffd097          	auipc	ra,0xffffd
    80003978:	3a2080e7          	jalr	930(ra) # 80000d16 <release>
    itrunc(ip);
    8000397c:	8526                	mv	a0,s1
    8000397e:	00000097          	auipc	ra,0x0
    80003982:	ee2080e7          	jalr	-286(ra) # 80003860 <itrunc>
    ip->type = 0;
    80003986:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000398a:	8526                	mv	a0,s1
    8000398c:	00000097          	auipc	ra,0x0
    80003990:	cfc080e7          	jalr	-772(ra) # 80003688 <iupdate>
    ip->valid = 0;
    80003994:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003998:	854a                	mv	a0,s2
    8000399a:	00001097          	auipc	ra,0x1
    8000399e:	ac8080e7          	jalr	-1336(ra) # 80004462 <releasesleep>
    acquire(&icache.lock);
    800039a2:	0001c517          	auipc	a0,0x1c
    800039a6:	4be50513          	addi	a0,a0,1214 # 8001fe60 <icache>
    800039aa:	ffffd097          	auipc	ra,0xffffd
    800039ae:	2b8080e7          	jalr	696(ra) # 80000c62 <acquire>
    800039b2:	b741                	j	80003932 <iput+0x26>

00000000800039b4 <iunlockput>:
{
    800039b4:	1101                	addi	sp,sp,-32
    800039b6:	ec06                	sd	ra,24(sp)
    800039b8:	e822                	sd	s0,16(sp)
    800039ba:	e426                	sd	s1,8(sp)
    800039bc:	1000                	addi	s0,sp,32
    800039be:	84aa                	mv	s1,a0
  iunlock(ip);
    800039c0:	00000097          	auipc	ra,0x0
    800039c4:	e54080e7          	jalr	-428(ra) # 80003814 <iunlock>
  iput(ip);
    800039c8:	8526                	mv	a0,s1
    800039ca:	00000097          	auipc	ra,0x0
    800039ce:	f42080e7          	jalr	-190(ra) # 8000390c <iput>
}
    800039d2:	60e2                	ld	ra,24(sp)
    800039d4:	6442                	ld	s0,16(sp)
    800039d6:	64a2                	ld	s1,8(sp)
    800039d8:	6105                	addi	sp,sp,32
    800039da:	8082                	ret

00000000800039dc <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039dc:	1141                	addi	sp,sp,-16
    800039de:	e422                	sd	s0,8(sp)
    800039e0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039e2:	411c                	lw	a5,0(a0)
    800039e4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039e6:	415c                	lw	a5,4(a0)
    800039e8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039ea:	04451783          	lh	a5,68(a0)
    800039ee:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039f2:	04a51783          	lh	a5,74(a0)
    800039f6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039fa:	04c56783          	lwu	a5,76(a0)
    800039fe:	e99c                	sd	a5,16(a1)
}
    80003a00:	6422                	ld	s0,8(sp)
    80003a02:	0141                	addi	sp,sp,16
    80003a04:	8082                	ret

0000000080003a06 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a06:	457c                	lw	a5,76(a0)
    80003a08:	0ed7e863          	bltu	a5,a3,80003af8 <readi+0xf2>
{
    80003a0c:	7159                	addi	sp,sp,-112
    80003a0e:	f486                	sd	ra,104(sp)
    80003a10:	f0a2                	sd	s0,96(sp)
    80003a12:	eca6                	sd	s1,88(sp)
    80003a14:	e8ca                	sd	s2,80(sp)
    80003a16:	e4ce                	sd	s3,72(sp)
    80003a18:	e0d2                	sd	s4,64(sp)
    80003a1a:	fc56                	sd	s5,56(sp)
    80003a1c:	f85a                	sd	s6,48(sp)
    80003a1e:	f45e                	sd	s7,40(sp)
    80003a20:	f062                	sd	s8,32(sp)
    80003a22:	ec66                	sd	s9,24(sp)
    80003a24:	e86a                	sd	s10,16(sp)
    80003a26:	e46e                	sd	s11,8(sp)
    80003a28:	1880                	addi	s0,sp,112
    80003a2a:	8baa                	mv	s7,a0
    80003a2c:	8c2e                	mv	s8,a1
    80003a2e:	8ab2                	mv	s5,a2
    80003a30:	84b6                	mv	s1,a3
    80003a32:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a34:	9f35                	addw	a4,a4,a3
    return 0;
    80003a36:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a38:	08d76f63          	bltu	a4,a3,80003ad6 <readi+0xd0>
  if(off + n > ip->size)
    80003a3c:	00e7f463          	bgeu	a5,a4,80003a44 <readi+0x3e>
    n = ip->size - off;
    80003a40:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a44:	0a0b0863          	beqz	s6,80003af4 <readi+0xee>
    80003a48:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a4a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a4e:	5cfd                	li	s9,-1
    80003a50:	a82d                	j	80003a8a <readi+0x84>
    80003a52:	020a1d93          	slli	s11,s4,0x20
    80003a56:	020ddd93          	srli	s11,s11,0x20
    80003a5a:	05890613          	addi	a2,s2,88
    80003a5e:	86ee                	mv	a3,s11
    80003a60:	963a                	add	a2,a2,a4
    80003a62:	85d6                	mv	a1,s5
    80003a64:	8562                	mv	a0,s8
    80003a66:	fffff097          	auipc	ra,0xfffff
    80003a6a:	a40080e7          	jalr	-1472(ra) # 800024a6 <either_copyout>
    80003a6e:	05950d63          	beq	a0,s9,80003ac8 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003a72:	854a                	mv	a0,s2
    80003a74:	fffff097          	auipc	ra,0xfffff
    80003a78:	60c080e7          	jalr	1548(ra) # 80003080 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a7c:	013a09bb          	addw	s3,s4,s3
    80003a80:	009a04bb          	addw	s1,s4,s1
    80003a84:	9aee                	add	s5,s5,s11
    80003a86:	0569f663          	bgeu	s3,s6,80003ad2 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a8a:	000ba903          	lw	s2,0(s7)
    80003a8e:	00a4d59b          	srliw	a1,s1,0xa
    80003a92:	855e                	mv	a0,s7
    80003a94:	00000097          	auipc	ra,0x0
    80003a98:	8b0080e7          	jalr	-1872(ra) # 80003344 <bmap>
    80003a9c:	0005059b          	sext.w	a1,a0
    80003aa0:	854a                	mv	a0,s2
    80003aa2:	fffff097          	auipc	ra,0xfffff
    80003aa6:	4ae080e7          	jalr	1198(ra) # 80002f50 <bread>
    80003aaa:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aac:	3ff4f713          	andi	a4,s1,1023
    80003ab0:	40ed07bb          	subw	a5,s10,a4
    80003ab4:	413b06bb          	subw	a3,s6,s3
    80003ab8:	8a3e                	mv	s4,a5
    80003aba:	2781                	sext.w	a5,a5
    80003abc:	0006861b          	sext.w	a2,a3
    80003ac0:	f8f679e3          	bgeu	a2,a5,80003a52 <readi+0x4c>
    80003ac4:	8a36                	mv	s4,a3
    80003ac6:	b771                	j	80003a52 <readi+0x4c>
      brelse(bp);
    80003ac8:	854a                	mv	a0,s2
    80003aca:	fffff097          	auipc	ra,0xfffff
    80003ace:	5b6080e7          	jalr	1462(ra) # 80003080 <brelse>
  }
  return tot;
    80003ad2:	0009851b          	sext.w	a0,s3
}
    80003ad6:	70a6                	ld	ra,104(sp)
    80003ad8:	7406                	ld	s0,96(sp)
    80003ada:	64e6                	ld	s1,88(sp)
    80003adc:	6946                	ld	s2,80(sp)
    80003ade:	69a6                	ld	s3,72(sp)
    80003ae0:	6a06                	ld	s4,64(sp)
    80003ae2:	7ae2                	ld	s5,56(sp)
    80003ae4:	7b42                	ld	s6,48(sp)
    80003ae6:	7ba2                	ld	s7,40(sp)
    80003ae8:	7c02                	ld	s8,32(sp)
    80003aea:	6ce2                	ld	s9,24(sp)
    80003aec:	6d42                	ld	s10,16(sp)
    80003aee:	6da2                	ld	s11,8(sp)
    80003af0:	6165                	addi	sp,sp,112
    80003af2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003af4:	89da                	mv	s3,s6
    80003af6:	bff1                	j	80003ad2 <readi+0xcc>
    return 0;
    80003af8:	4501                	li	a0,0
}
    80003afa:	8082                	ret

0000000080003afc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003afc:	457c                	lw	a5,76(a0)
    80003afe:	10d7e663          	bltu	a5,a3,80003c0a <writei+0x10e>
{
    80003b02:	7159                	addi	sp,sp,-112
    80003b04:	f486                	sd	ra,104(sp)
    80003b06:	f0a2                	sd	s0,96(sp)
    80003b08:	eca6                	sd	s1,88(sp)
    80003b0a:	e8ca                	sd	s2,80(sp)
    80003b0c:	e4ce                	sd	s3,72(sp)
    80003b0e:	e0d2                	sd	s4,64(sp)
    80003b10:	fc56                	sd	s5,56(sp)
    80003b12:	f85a                	sd	s6,48(sp)
    80003b14:	f45e                	sd	s7,40(sp)
    80003b16:	f062                	sd	s8,32(sp)
    80003b18:	ec66                	sd	s9,24(sp)
    80003b1a:	e86a                	sd	s10,16(sp)
    80003b1c:	e46e                	sd	s11,8(sp)
    80003b1e:	1880                	addi	s0,sp,112
    80003b20:	8baa                	mv	s7,a0
    80003b22:	8c2e                	mv	s8,a1
    80003b24:	8ab2                	mv	s5,a2
    80003b26:	8936                	mv	s2,a3
    80003b28:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b2a:	00e687bb          	addw	a5,a3,a4
    80003b2e:	0ed7e063          	bltu	a5,a3,80003c0e <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b32:	00043737          	lui	a4,0x43
    80003b36:	0cf76e63          	bltu	a4,a5,80003c12 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b3a:	0a0b0763          	beqz	s6,80003be8 <writei+0xec>
    80003b3e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b40:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b44:	5cfd                	li	s9,-1
    80003b46:	a091                	j	80003b8a <writei+0x8e>
    80003b48:	02099d93          	slli	s11,s3,0x20
    80003b4c:	020ddd93          	srli	s11,s11,0x20
    80003b50:	05848513          	addi	a0,s1,88
    80003b54:	86ee                	mv	a3,s11
    80003b56:	8656                	mv	a2,s5
    80003b58:	85e2                	mv	a1,s8
    80003b5a:	953a                	add	a0,a0,a4
    80003b5c:	fffff097          	auipc	ra,0xfffff
    80003b60:	9a0080e7          	jalr	-1632(ra) # 800024fc <either_copyin>
    80003b64:	07950263          	beq	a0,s9,80003bc8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b68:	8526                	mv	a0,s1
    80003b6a:	00000097          	auipc	ra,0x0
    80003b6e:	77a080e7          	jalr	1914(ra) # 800042e4 <log_write>
    brelse(bp);
    80003b72:	8526                	mv	a0,s1
    80003b74:	fffff097          	auipc	ra,0xfffff
    80003b78:	50c080e7          	jalr	1292(ra) # 80003080 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b7c:	01498a3b          	addw	s4,s3,s4
    80003b80:	0129893b          	addw	s2,s3,s2
    80003b84:	9aee                	add	s5,s5,s11
    80003b86:	056a7663          	bgeu	s4,s6,80003bd2 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b8a:	000ba483          	lw	s1,0(s7)
    80003b8e:	00a9559b          	srliw	a1,s2,0xa
    80003b92:	855e                	mv	a0,s7
    80003b94:	fffff097          	auipc	ra,0xfffff
    80003b98:	7b0080e7          	jalr	1968(ra) # 80003344 <bmap>
    80003b9c:	0005059b          	sext.w	a1,a0
    80003ba0:	8526                	mv	a0,s1
    80003ba2:	fffff097          	auipc	ra,0xfffff
    80003ba6:	3ae080e7          	jalr	942(ra) # 80002f50 <bread>
    80003baa:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bac:	3ff97713          	andi	a4,s2,1023
    80003bb0:	40ed07bb          	subw	a5,s10,a4
    80003bb4:	414b06bb          	subw	a3,s6,s4
    80003bb8:	89be                	mv	s3,a5
    80003bba:	2781                	sext.w	a5,a5
    80003bbc:	0006861b          	sext.w	a2,a3
    80003bc0:	f8f674e3          	bgeu	a2,a5,80003b48 <writei+0x4c>
    80003bc4:	89b6                	mv	s3,a3
    80003bc6:	b749                	j	80003b48 <writei+0x4c>
      brelse(bp);
    80003bc8:	8526                	mv	a0,s1
    80003bca:	fffff097          	auipc	ra,0xfffff
    80003bce:	4b6080e7          	jalr	1206(ra) # 80003080 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003bd2:	04cba783          	lw	a5,76(s7)
    80003bd6:	0127f463          	bgeu	a5,s2,80003bde <writei+0xe2>
      ip->size = off;
    80003bda:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003bde:	855e                	mv	a0,s7
    80003be0:	00000097          	auipc	ra,0x0
    80003be4:	aa8080e7          	jalr	-1368(ra) # 80003688 <iupdate>
  }

  return n;
    80003be8:	000b051b          	sext.w	a0,s6
}
    80003bec:	70a6                	ld	ra,104(sp)
    80003bee:	7406                	ld	s0,96(sp)
    80003bf0:	64e6                	ld	s1,88(sp)
    80003bf2:	6946                	ld	s2,80(sp)
    80003bf4:	69a6                	ld	s3,72(sp)
    80003bf6:	6a06                	ld	s4,64(sp)
    80003bf8:	7ae2                	ld	s5,56(sp)
    80003bfa:	7b42                	ld	s6,48(sp)
    80003bfc:	7ba2                	ld	s7,40(sp)
    80003bfe:	7c02                	ld	s8,32(sp)
    80003c00:	6ce2                	ld	s9,24(sp)
    80003c02:	6d42                	ld	s10,16(sp)
    80003c04:	6da2                	ld	s11,8(sp)
    80003c06:	6165                	addi	sp,sp,112
    80003c08:	8082                	ret
    return -1;
    80003c0a:	557d                	li	a0,-1
}
    80003c0c:	8082                	ret
    return -1;
    80003c0e:	557d                	li	a0,-1
    80003c10:	bff1                	j	80003bec <writei+0xf0>
    return -1;
    80003c12:	557d                	li	a0,-1
    80003c14:	bfe1                	j	80003bec <writei+0xf0>

0000000080003c16 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c16:	1141                	addi	sp,sp,-16
    80003c18:	e406                	sd	ra,8(sp)
    80003c1a:	e022                	sd	s0,0(sp)
    80003c1c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c1e:	4639                	li	a2,14
    80003c20:	ffffd097          	auipc	ra,0xffffd
    80003c24:	21a080e7          	jalr	538(ra) # 80000e3a <strncmp>
}
    80003c28:	60a2                	ld	ra,8(sp)
    80003c2a:	6402                	ld	s0,0(sp)
    80003c2c:	0141                	addi	sp,sp,16
    80003c2e:	8082                	ret

0000000080003c30 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c30:	7139                	addi	sp,sp,-64
    80003c32:	fc06                	sd	ra,56(sp)
    80003c34:	f822                	sd	s0,48(sp)
    80003c36:	f426                	sd	s1,40(sp)
    80003c38:	f04a                	sd	s2,32(sp)
    80003c3a:	ec4e                	sd	s3,24(sp)
    80003c3c:	e852                	sd	s4,16(sp)
    80003c3e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c40:	04451703          	lh	a4,68(a0)
    80003c44:	4785                	li	a5,1
    80003c46:	00f71a63          	bne	a4,a5,80003c5a <dirlookup+0x2a>
    80003c4a:	892a                	mv	s2,a0
    80003c4c:	89ae                	mv	s3,a1
    80003c4e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c50:	457c                	lw	a5,76(a0)
    80003c52:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c54:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c56:	e79d                	bnez	a5,80003c84 <dirlookup+0x54>
    80003c58:	a8a5                	j	80003cd0 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c5a:	00005517          	auipc	a0,0x5
    80003c5e:	b0e50513          	addi	a0,a0,-1266 # 80008768 <syscalls_name+0x1b0>
    80003c62:	ffffd097          	auipc	ra,0xffffd
    80003c66:	8e6080e7          	jalr	-1818(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003c6a:	00005517          	auipc	a0,0x5
    80003c6e:	b1650513          	addi	a0,a0,-1258 # 80008780 <syscalls_name+0x1c8>
    80003c72:	ffffd097          	auipc	ra,0xffffd
    80003c76:	8d6080e7          	jalr	-1834(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c7a:	24c1                	addiw	s1,s1,16
    80003c7c:	04c92783          	lw	a5,76(s2)
    80003c80:	04f4f763          	bgeu	s1,a5,80003cce <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c84:	4741                	li	a4,16
    80003c86:	86a6                	mv	a3,s1
    80003c88:	fc040613          	addi	a2,s0,-64
    80003c8c:	4581                	li	a1,0
    80003c8e:	854a                	mv	a0,s2
    80003c90:	00000097          	auipc	ra,0x0
    80003c94:	d76080e7          	jalr	-650(ra) # 80003a06 <readi>
    80003c98:	47c1                	li	a5,16
    80003c9a:	fcf518e3          	bne	a0,a5,80003c6a <dirlookup+0x3a>
    if(de.inum == 0)
    80003c9e:	fc045783          	lhu	a5,-64(s0)
    80003ca2:	dfe1                	beqz	a5,80003c7a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ca4:	fc240593          	addi	a1,s0,-62
    80003ca8:	854e                	mv	a0,s3
    80003caa:	00000097          	auipc	ra,0x0
    80003cae:	f6c080e7          	jalr	-148(ra) # 80003c16 <namecmp>
    80003cb2:	f561                	bnez	a0,80003c7a <dirlookup+0x4a>
      if(poff)
    80003cb4:	000a0463          	beqz	s4,80003cbc <dirlookup+0x8c>
        *poff = off;
    80003cb8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003cbc:	fc045583          	lhu	a1,-64(s0)
    80003cc0:	00092503          	lw	a0,0(s2)
    80003cc4:	fffff097          	auipc	ra,0xfffff
    80003cc8:	75a080e7          	jalr	1882(ra) # 8000341e <iget>
    80003ccc:	a011                	j	80003cd0 <dirlookup+0xa0>
  return 0;
    80003cce:	4501                	li	a0,0
}
    80003cd0:	70e2                	ld	ra,56(sp)
    80003cd2:	7442                	ld	s0,48(sp)
    80003cd4:	74a2                	ld	s1,40(sp)
    80003cd6:	7902                	ld	s2,32(sp)
    80003cd8:	69e2                	ld	s3,24(sp)
    80003cda:	6a42                	ld	s4,16(sp)
    80003cdc:	6121                	addi	sp,sp,64
    80003cde:	8082                	ret

0000000080003ce0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ce0:	711d                	addi	sp,sp,-96
    80003ce2:	ec86                	sd	ra,88(sp)
    80003ce4:	e8a2                	sd	s0,80(sp)
    80003ce6:	e4a6                	sd	s1,72(sp)
    80003ce8:	e0ca                	sd	s2,64(sp)
    80003cea:	fc4e                	sd	s3,56(sp)
    80003cec:	f852                	sd	s4,48(sp)
    80003cee:	f456                	sd	s5,40(sp)
    80003cf0:	f05a                	sd	s6,32(sp)
    80003cf2:	ec5e                	sd	s7,24(sp)
    80003cf4:	e862                	sd	s8,16(sp)
    80003cf6:	e466                	sd	s9,8(sp)
    80003cf8:	1080                	addi	s0,sp,96
    80003cfa:	84aa                	mv	s1,a0
    80003cfc:	8b2e                	mv	s6,a1
    80003cfe:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d00:	00054703          	lbu	a4,0(a0)
    80003d04:	02f00793          	li	a5,47
    80003d08:	02f70363          	beq	a4,a5,80003d2e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d0c:	ffffe097          	auipc	ra,0xffffe
    80003d10:	d24080e7          	jalr	-732(ra) # 80001a30 <myproc>
    80003d14:	15053503          	ld	a0,336(a0)
    80003d18:	00000097          	auipc	ra,0x0
    80003d1c:	9fc080e7          	jalr	-1540(ra) # 80003714 <idup>
    80003d20:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d22:	02f00913          	li	s2,47
  len = path - s;
    80003d26:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d28:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d2a:	4c05                	li	s8,1
    80003d2c:	a865                	j	80003de4 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d2e:	4585                	li	a1,1
    80003d30:	4505                	li	a0,1
    80003d32:	fffff097          	auipc	ra,0xfffff
    80003d36:	6ec080e7          	jalr	1772(ra) # 8000341e <iget>
    80003d3a:	89aa                	mv	s3,a0
    80003d3c:	b7dd                	j	80003d22 <namex+0x42>
      iunlockput(ip);
    80003d3e:	854e                	mv	a0,s3
    80003d40:	00000097          	auipc	ra,0x0
    80003d44:	c74080e7          	jalr	-908(ra) # 800039b4 <iunlockput>
      return 0;
    80003d48:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d4a:	854e                	mv	a0,s3
    80003d4c:	60e6                	ld	ra,88(sp)
    80003d4e:	6446                	ld	s0,80(sp)
    80003d50:	64a6                	ld	s1,72(sp)
    80003d52:	6906                	ld	s2,64(sp)
    80003d54:	79e2                	ld	s3,56(sp)
    80003d56:	7a42                	ld	s4,48(sp)
    80003d58:	7aa2                	ld	s5,40(sp)
    80003d5a:	7b02                	ld	s6,32(sp)
    80003d5c:	6be2                	ld	s7,24(sp)
    80003d5e:	6c42                	ld	s8,16(sp)
    80003d60:	6ca2                	ld	s9,8(sp)
    80003d62:	6125                	addi	sp,sp,96
    80003d64:	8082                	ret
      iunlock(ip);
    80003d66:	854e                	mv	a0,s3
    80003d68:	00000097          	auipc	ra,0x0
    80003d6c:	aac080e7          	jalr	-1364(ra) # 80003814 <iunlock>
      return ip;
    80003d70:	bfe9                	j	80003d4a <namex+0x6a>
      iunlockput(ip);
    80003d72:	854e                	mv	a0,s3
    80003d74:	00000097          	auipc	ra,0x0
    80003d78:	c40080e7          	jalr	-960(ra) # 800039b4 <iunlockput>
      return 0;
    80003d7c:	89d2                	mv	s3,s4
    80003d7e:	b7f1                	j	80003d4a <namex+0x6a>
  len = path - s;
    80003d80:	40b48633          	sub	a2,s1,a1
    80003d84:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d88:	094cd463          	bge	s9,s4,80003e10 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d8c:	4639                	li	a2,14
    80003d8e:	8556                	mv	a0,s5
    80003d90:	ffffd097          	auipc	ra,0xffffd
    80003d94:	02e080e7          	jalr	46(ra) # 80000dbe <memmove>
  while(*path == '/')
    80003d98:	0004c783          	lbu	a5,0(s1)
    80003d9c:	01279763          	bne	a5,s2,80003daa <namex+0xca>
    path++;
    80003da0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003da2:	0004c783          	lbu	a5,0(s1)
    80003da6:	ff278de3          	beq	a5,s2,80003da0 <namex+0xc0>
    ilock(ip);
    80003daa:	854e                	mv	a0,s3
    80003dac:	00000097          	auipc	ra,0x0
    80003db0:	9a6080e7          	jalr	-1626(ra) # 80003752 <ilock>
    if(ip->type != T_DIR){
    80003db4:	04499783          	lh	a5,68(s3)
    80003db8:	f98793e3          	bne	a5,s8,80003d3e <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003dbc:	000b0563          	beqz	s6,80003dc6 <namex+0xe6>
    80003dc0:	0004c783          	lbu	a5,0(s1)
    80003dc4:	d3cd                	beqz	a5,80003d66 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003dc6:	865e                	mv	a2,s7
    80003dc8:	85d6                	mv	a1,s5
    80003dca:	854e                	mv	a0,s3
    80003dcc:	00000097          	auipc	ra,0x0
    80003dd0:	e64080e7          	jalr	-412(ra) # 80003c30 <dirlookup>
    80003dd4:	8a2a                	mv	s4,a0
    80003dd6:	dd51                	beqz	a0,80003d72 <namex+0x92>
    iunlockput(ip);
    80003dd8:	854e                	mv	a0,s3
    80003dda:	00000097          	auipc	ra,0x0
    80003dde:	bda080e7          	jalr	-1062(ra) # 800039b4 <iunlockput>
    ip = next;
    80003de2:	89d2                	mv	s3,s4
  while(*path == '/')
    80003de4:	0004c783          	lbu	a5,0(s1)
    80003de8:	05279763          	bne	a5,s2,80003e36 <namex+0x156>
    path++;
    80003dec:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dee:	0004c783          	lbu	a5,0(s1)
    80003df2:	ff278de3          	beq	a5,s2,80003dec <namex+0x10c>
  if(*path == 0)
    80003df6:	c79d                	beqz	a5,80003e24 <namex+0x144>
    path++;
    80003df8:	85a6                	mv	a1,s1
  len = path - s;
    80003dfa:	8a5e                	mv	s4,s7
    80003dfc:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003dfe:	01278963          	beq	a5,s2,80003e10 <namex+0x130>
    80003e02:	dfbd                	beqz	a5,80003d80 <namex+0xa0>
    path++;
    80003e04:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e06:	0004c783          	lbu	a5,0(s1)
    80003e0a:	ff279ce3          	bne	a5,s2,80003e02 <namex+0x122>
    80003e0e:	bf8d                	j	80003d80 <namex+0xa0>
    memmove(name, s, len);
    80003e10:	2601                	sext.w	a2,a2
    80003e12:	8556                	mv	a0,s5
    80003e14:	ffffd097          	auipc	ra,0xffffd
    80003e18:	faa080e7          	jalr	-86(ra) # 80000dbe <memmove>
    name[len] = 0;
    80003e1c:	9a56                	add	s4,s4,s5
    80003e1e:	000a0023          	sb	zero,0(s4)
    80003e22:	bf9d                	j	80003d98 <namex+0xb8>
  if(nameiparent){
    80003e24:	f20b03e3          	beqz	s6,80003d4a <namex+0x6a>
    iput(ip);
    80003e28:	854e                	mv	a0,s3
    80003e2a:	00000097          	auipc	ra,0x0
    80003e2e:	ae2080e7          	jalr	-1310(ra) # 8000390c <iput>
    return 0;
    80003e32:	4981                	li	s3,0
    80003e34:	bf19                	j	80003d4a <namex+0x6a>
  if(*path == 0)
    80003e36:	d7fd                	beqz	a5,80003e24 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e38:	0004c783          	lbu	a5,0(s1)
    80003e3c:	85a6                	mv	a1,s1
    80003e3e:	b7d1                	j	80003e02 <namex+0x122>

0000000080003e40 <dirlink>:
{
    80003e40:	7139                	addi	sp,sp,-64
    80003e42:	fc06                	sd	ra,56(sp)
    80003e44:	f822                	sd	s0,48(sp)
    80003e46:	f426                	sd	s1,40(sp)
    80003e48:	f04a                	sd	s2,32(sp)
    80003e4a:	ec4e                	sd	s3,24(sp)
    80003e4c:	e852                	sd	s4,16(sp)
    80003e4e:	0080                	addi	s0,sp,64
    80003e50:	892a                	mv	s2,a0
    80003e52:	8a2e                	mv	s4,a1
    80003e54:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e56:	4601                	li	a2,0
    80003e58:	00000097          	auipc	ra,0x0
    80003e5c:	dd8080e7          	jalr	-552(ra) # 80003c30 <dirlookup>
    80003e60:	e93d                	bnez	a0,80003ed6 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e62:	04c92483          	lw	s1,76(s2)
    80003e66:	c49d                	beqz	s1,80003e94 <dirlink+0x54>
    80003e68:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e6a:	4741                	li	a4,16
    80003e6c:	86a6                	mv	a3,s1
    80003e6e:	fc040613          	addi	a2,s0,-64
    80003e72:	4581                	li	a1,0
    80003e74:	854a                	mv	a0,s2
    80003e76:	00000097          	auipc	ra,0x0
    80003e7a:	b90080e7          	jalr	-1136(ra) # 80003a06 <readi>
    80003e7e:	47c1                	li	a5,16
    80003e80:	06f51163          	bne	a0,a5,80003ee2 <dirlink+0xa2>
    if(de.inum == 0)
    80003e84:	fc045783          	lhu	a5,-64(s0)
    80003e88:	c791                	beqz	a5,80003e94 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e8a:	24c1                	addiw	s1,s1,16
    80003e8c:	04c92783          	lw	a5,76(s2)
    80003e90:	fcf4ede3          	bltu	s1,a5,80003e6a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e94:	4639                	li	a2,14
    80003e96:	85d2                	mv	a1,s4
    80003e98:	fc240513          	addi	a0,s0,-62
    80003e9c:	ffffd097          	auipc	ra,0xffffd
    80003ea0:	fda080e7          	jalr	-38(ra) # 80000e76 <strncpy>
  de.inum = inum;
    80003ea4:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ea8:	4741                	li	a4,16
    80003eaa:	86a6                	mv	a3,s1
    80003eac:	fc040613          	addi	a2,s0,-64
    80003eb0:	4581                	li	a1,0
    80003eb2:	854a                	mv	a0,s2
    80003eb4:	00000097          	auipc	ra,0x0
    80003eb8:	c48080e7          	jalr	-952(ra) # 80003afc <writei>
    80003ebc:	872a                	mv	a4,a0
    80003ebe:	47c1                	li	a5,16
  return 0;
    80003ec0:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ec2:	02f71863          	bne	a4,a5,80003ef2 <dirlink+0xb2>
}
    80003ec6:	70e2                	ld	ra,56(sp)
    80003ec8:	7442                	ld	s0,48(sp)
    80003eca:	74a2                	ld	s1,40(sp)
    80003ecc:	7902                	ld	s2,32(sp)
    80003ece:	69e2                	ld	s3,24(sp)
    80003ed0:	6a42                	ld	s4,16(sp)
    80003ed2:	6121                	addi	sp,sp,64
    80003ed4:	8082                	ret
    iput(ip);
    80003ed6:	00000097          	auipc	ra,0x0
    80003eda:	a36080e7          	jalr	-1482(ra) # 8000390c <iput>
    return -1;
    80003ede:	557d                	li	a0,-1
    80003ee0:	b7dd                	j	80003ec6 <dirlink+0x86>
      panic("dirlink read");
    80003ee2:	00005517          	auipc	a0,0x5
    80003ee6:	8ae50513          	addi	a0,a0,-1874 # 80008790 <syscalls_name+0x1d8>
    80003eea:	ffffc097          	auipc	ra,0xffffc
    80003eee:	65e080e7          	jalr	1630(ra) # 80000548 <panic>
    panic("dirlink");
    80003ef2:	00005517          	auipc	a0,0x5
    80003ef6:	9b650513          	addi	a0,a0,-1610 # 800088a8 <syscalls_name+0x2f0>
    80003efa:	ffffc097          	auipc	ra,0xffffc
    80003efe:	64e080e7          	jalr	1614(ra) # 80000548 <panic>

0000000080003f02 <namei>:

struct inode*
namei(char *path)
{
    80003f02:	1101                	addi	sp,sp,-32
    80003f04:	ec06                	sd	ra,24(sp)
    80003f06:	e822                	sd	s0,16(sp)
    80003f08:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f0a:	fe040613          	addi	a2,s0,-32
    80003f0e:	4581                	li	a1,0
    80003f10:	00000097          	auipc	ra,0x0
    80003f14:	dd0080e7          	jalr	-560(ra) # 80003ce0 <namex>
}
    80003f18:	60e2                	ld	ra,24(sp)
    80003f1a:	6442                	ld	s0,16(sp)
    80003f1c:	6105                	addi	sp,sp,32
    80003f1e:	8082                	ret

0000000080003f20 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f20:	1141                	addi	sp,sp,-16
    80003f22:	e406                	sd	ra,8(sp)
    80003f24:	e022                	sd	s0,0(sp)
    80003f26:	0800                	addi	s0,sp,16
    80003f28:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f2a:	4585                	li	a1,1
    80003f2c:	00000097          	auipc	ra,0x0
    80003f30:	db4080e7          	jalr	-588(ra) # 80003ce0 <namex>
}
    80003f34:	60a2                	ld	ra,8(sp)
    80003f36:	6402                	ld	s0,0(sp)
    80003f38:	0141                	addi	sp,sp,16
    80003f3a:	8082                	ret

0000000080003f3c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f3c:	1101                	addi	sp,sp,-32
    80003f3e:	ec06                	sd	ra,24(sp)
    80003f40:	e822                	sd	s0,16(sp)
    80003f42:	e426                	sd	s1,8(sp)
    80003f44:	e04a                	sd	s2,0(sp)
    80003f46:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f48:	0001e917          	auipc	s2,0x1e
    80003f4c:	9c090913          	addi	s2,s2,-1600 # 80021908 <log>
    80003f50:	01892583          	lw	a1,24(s2)
    80003f54:	02892503          	lw	a0,40(s2)
    80003f58:	fffff097          	auipc	ra,0xfffff
    80003f5c:	ff8080e7          	jalr	-8(ra) # 80002f50 <bread>
    80003f60:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f62:	02c92683          	lw	a3,44(s2)
    80003f66:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f68:	02d05763          	blez	a3,80003f96 <write_head+0x5a>
    80003f6c:	0001e797          	auipc	a5,0x1e
    80003f70:	9cc78793          	addi	a5,a5,-1588 # 80021938 <log+0x30>
    80003f74:	05c50713          	addi	a4,a0,92
    80003f78:	36fd                	addiw	a3,a3,-1
    80003f7a:	1682                	slli	a3,a3,0x20
    80003f7c:	9281                	srli	a3,a3,0x20
    80003f7e:	068a                	slli	a3,a3,0x2
    80003f80:	0001e617          	auipc	a2,0x1e
    80003f84:	9bc60613          	addi	a2,a2,-1604 # 8002193c <log+0x34>
    80003f88:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f8a:	4390                	lw	a2,0(a5)
    80003f8c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f8e:	0791                	addi	a5,a5,4
    80003f90:	0711                	addi	a4,a4,4
    80003f92:	fed79ce3          	bne	a5,a3,80003f8a <write_head+0x4e>
  }
  bwrite(buf);
    80003f96:	8526                	mv	a0,s1
    80003f98:	fffff097          	auipc	ra,0xfffff
    80003f9c:	0aa080e7          	jalr	170(ra) # 80003042 <bwrite>
  brelse(buf);
    80003fa0:	8526                	mv	a0,s1
    80003fa2:	fffff097          	auipc	ra,0xfffff
    80003fa6:	0de080e7          	jalr	222(ra) # 80003080 <brelse>
}
    80003faa:	60e2                	ld	ra,24(sp)
    80003fac:	6442                	ld	s0,16(sp)
    80003fae:	64a2                	ld	s1,8(sp)
    80003fb0:	6902                	ld	s2,0(sp)
    80003fb2:	6105                	addi	sp,sp,32
    80003fb4:	8082                	ret

0000000080003fb6 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fb6:	0001e797          	auipc	a5,0x1e
    80003fba:	97e7a783          	lw	a5,-1666(a5) # 80021934 <log+0x2c>
    80003fbe:	0af05663          	blez	a5,8000406a <install_trans+0xb4>
{
    80003fc2:	7139                	addi	sp,sp,-64
    80003fc4:	fc06                	sd	ra,56(sp)
    80003fc6:	f822                	sd	s0,48(sp)
    80003fc8:	f426                	sd	s1,40(sp)
    80003fca:	f04a                	sd	s2,32(sp)
    80003fcc:	ec4e                	sd	s3,24(sp)
    80003fce:	e852                	sd	s4,16(sp)
    80003fd0:	e456                	sd	s5,8(sp)
    80003fd2:	0080                	addi	s0,sp,64
    80003fd4:	0001ea97          	auipc	s5,0x1e
    80003fd8:	964a8a93          	addi	s5,s5,-1692 # 80021938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fdc:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fde:	0001e997          	auipc	s3,0x1e
    80003fe2:	92a98993          	addi	s3,s3,-1750 # 80021908 <log>
    80003fe6:	0189a583          	lw	a1,24(s3)
    80003fea:	014585bb          	addw	a1,a1,s4
    80003fee:	2585                	addiw	a1,a1,1
    80003ff0:	0289a503          	lw	a0,40(s3)
    80003ff4:	fffff097          	auipc	ra,0xfffff
    80003ff8:	f5c080e7          	jalr	-164(ra) # 80002f50 <bread>
    80003ffc:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003ffe:	000aa583          	lw	a1,0(s5)
    80004002:	0289a503          	lw	a0,40(s3)
    80004006:	fffff097          	auipc	ra,0xfffff
    8000400a:	f4a080e7          	jalr	-182(ra) # 80002f50 <bread>
    8000400e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004010:	40000613          	li	a2,1024
    80004014:	05890593          	addi	a1,s2,88
    80004018:	05850513          	addi	a0,a0,88
    8000401c:	ffffd097          	auipc	ra,0xffffd
    80004020:	da2080e7          	jalr	-606(ra) # 80000dbe <memmove>
    bwrite(dbuf);  // write dst to disk
    80004024:	8526                	mv	a0,s1
    80004026:	fffff097          	auipc	ra,0xfffff
    8000402a:	01c080e7          	jalr	28(ra) # 80003042 <bwrite>
    bunpin(dbuf);
    8000402e:	8526                	mv	a0,s1
    80004030:	fffff097          	auipc	ra,0xfffff
    80004034:	12a080e7          	jalr	298(ra) # 8000315a <bunpin>
    brelse(lbuf);
    80004038:	854a                	mv	a0,s2
    8000403a:	fffff097          	auipc	ra,0xfffff
    8000403e:	046080e7          	jalr	70(ra) # 80003080 <brelse>
    brelse(dbuf);
    80004042:	8526                	mv	a0,s1
    80004044:	fffff097          	auipc	ra,0xfffff
    80004048:	03c080e7          	jalr	60(ra) # 80003080 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000404c:	2a05                	addiw	s4,s4,1
    8000404e:	0a91                	addi	s5,s5,4
    80004050:	02c9a783          	lw	a5,44(s3)
    80004054:	f8fa49e3          	blt	s4,a5,80003fe6 <install_trans+0x30>
}
    80004058:	70e2                	ld	ra,56(sp)
    8000405a:	7442                	ld	s0,48(sp)
    8000405c:	74a2                	ld	s1,40(sp)
    8000405e:	7902                	ld	s2,32(sp)
    80004060:	69e2                	ld	s3,24(sp)
    80004062:	6a42                	ld	s4,16(sp)
    80004064:	6aa2                	ld	s5,8(sp)
    80004066:	6121                	addi	sp,sp,64
    80004068:	8082                	ret
    8000406a:	8082                	ret

000000008000406c <initlog>:
{
    8000406c:	7179                	addi	sp,sp,-48
    8000406e:	f406                	sd	ra,40(sp)
    80004070:	f022                	sd	s0,32(sp)
    80004072:	ec26                	sd	s1,24(sp)
    80004074:	e84a                	sd	s2,16(sp)
    80004076:	e44e                	sd	s3,8(sp)
    80004078:	1800                	addi	s0,sp,48
    8000407a:	892a                	mv	s2,a0
    8000407c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000407e:	0001e497          	auipc	s1,0x1e
    80004082:	88a48493          	addi	s1,s1,-1910 # 80021908 <log>
    80004086:	00004597          	auipc	a1,0x4
    8000408a:	71a58593          	addi	a1,a1,1818 # 800087a0 <syscalls_name+0x1e8>
    8000408e:	8526                	mv	a0,s1
    80004090:	ffffd097          	auipc	ra,0xffffd
    80004094:	b42080e7          	jalr	-1214(ra) # 80000bd2 <initlock>
  log.start = sb->logstart;
    80004098:	0149a583          	lw	a1,20(s3)
    8000409c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000409e:	0109a783          	lw	a5,16(s3)
    800040a2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040a4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040a8:	854a                	mv	a0,s2
    800040aa:	fffff097          	auipc	ra,0xfffff
    800040ae:	ea6080e7          	jalr	-346(ra) # 80002f50 <bread>
  log.lh.n = lh->n;
    800040b2:	4d3c                	lw	a5,88(a0)
    800040b4:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040b6:	02f05563          	blez	a5,800040e0 <initlog+0x74>
    800040ba:	05c50713          	addi	a4,a0,92
    800040be:	0001e697          	auipc	a3,0x1e
    800040c2:	87a68693          	addi	a3,a3,-1926 # 80021938 <log+0x30>
    800040c6:	37fd                	addiw	a5,a5,-1
    800040c8:	1782                	slli	a5,a5,0x20
    800040ca:	9381                	srli	a5,a5,0x20
    800040cc:	078a                	slli	a5,a5,0x2
    800040ce:	06050613          	addi	a2,a0,96
    800040d2:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800040d4:	4310                	lw	a2,0(a4)
    800040d6:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800040d8:	0711                	addi	a4,a4,4
    800040da:	0691                	addi	a3,a3,4
    800040dc:	fef71ce3          	bne	a4,a5,800040d4 <initlog+0x68>
  brelse(buf);
    800040e0:	fffff097          	auipc	ra,0xfffff
    800040e4:	fa0080e7          	jalr	-96(ra) # 80003080 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800040e8:	00000097          	auipc	ra,0x0
    800040ec:	ece080e7          	jalr	-306(ra) # 80003fb6 <install_trans>
  log.lh.n = 0;
    800040f0:	0001e797          	auipc	a5,0x1e
    800040f4:	8407a223          	sw	zero,-1980(a5) # 80021934 <log+0x2c>
  write_head(); // clear the log
    800040f8:	00000097          	auipc	ra,0x0
    800040fc:	e44080e7          	jalr	-444(ra) # 80003f3c <write_head>
}
    80004100:	70a2                	ld	ra,40(sp)
    80004102:	7402                	ld	s0,32(sp)
    80004104:	64e2                	ld	s1,24(sp)
    80004106:	6942                	ld	s2,16(sp)
    80004108:	69a2                	ld	s3,8(sp)
    8000410a:	6145                	addi	sp,sp,48
    8000410c:	8082                	ret

000000008000410e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000410e:	1101                	addi	sp,sp,-32
    80004110:	ec06                	sd	ra,24(sp)
    80004112:	e822                	sd	s0,16(sp)
    80004114:	e426                	sd	s1,8(sp)
    80004116:	e04a                	sd	s2,0(sp)
    80004118:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000411a:	0001d517          	auipc	a0,0x1d
    8000411e:	7ee50513          	addi	a0,a0,2030 # 80021908 <log>
    80004122:	ffffd097          	auipc	ra,0xffffd
    80004126:	b40080e7          	jalr	-1216(ra) # 80000c62 <acquire>
  while(1){
    if(log.committing){
    8000412a:	0001d497          	auipc	s1,0x1d
    8000412e:	7de48493          	addi	s1,s1,2014 # 80021908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004132:	4979                	li	s2,30
    80004134:	a039                	j	80004142 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004136:	85a6                	mv	a1,s1
    80004138:	8526                	mv	a0,s1
    8000413a:	ffffe097          	auipc	ra,0xffffe
    8000413e:	10a080e7          	jalr	266(ra) # 80002244 <sleep>
    if(log.committing){
    80004142:	50dc                	lw	a5,36(s1)
    80004144:	fbed                	bnez	a5,80004136 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004146:	509c                	lw	a5,32(s1)
    80004148:	0017871b          	addiw	a4,a5,1
    8000414c:	0007069b          	sext.w	a3,a4
    80004150:	0027179b          	slliw	a5,a4,0x2
    80004154:	9fb9                	addw	a5,a5,a4
    80004156:	0017979b          	slliw	a5,a5,0x1
    8000415a:	54d8                	lw	a4,44(s1)
    8000415c:	9fb9                	addw	a5,a5,a4
    8000415e:	00f95963          	bge	s2,a5,80004170 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004162:	85a6                	mv	a1,s1
    80004164:	8526                	mv	a0,s1
    80004166:	ffffe097          	auipc	ra,0xffffe
    8000416a:	0de080e7          	jalr	222(ra) # 80002244 <sleep>
    8000416e:	bfd1                	j	80004142 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004170:	0001d517          	auipc	a0,0x1d
    80004174:	79850513          	addi	a0,a0,1944 # 80021908 <log>
    80004178:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000417a:	ffffd097          	auipc	ra,0xffffd
    8000417e:	b9c080e7          	jalr	-1124(ra) # 80000d16 <release>
      break;
    }
  }
}
    80004182:	60e2                	ld	ra,24(sp)
    80004184:	6442                	ld	s0,16(sp)
    80004186:	64a2                	ld	s1,8(sp)
    80004188:	6902                	ld	s2,0(sp)
    8000418a:	6105                	addi	sp,sp,32
    8000418c:	8082                	ret

000000008000418e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000418e:	7139                	addi	sp,sp,-64
    80004190:	fc06                	sd	ra,56(sp)
    80004192:	f822                	sd	s0,48(sp)
    80004194:	f426                	sd	s1,40(sp)
    80004196:	f04a                	sd	s2,32(sp)
    80004198:	ec4e                	sd	s3,24(sp)
    8000419a:	e852                	sd	s4,16(sp)
    8000419c:	e456                	sd	s5,8(sp)
    8000419e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041a0:	0001d497          	auipc	s1,0x1d
    800041a4:	76848493          	addi	s1,s1,1896 # 80021908 <log>
    800041a8:	8526                	mv	a0,s1
    800041aa:	ffffd097          	auipc	ra,0xffffd
    800041ae:	ab8080e7          	jalr	-1352(ra) # 80000c62 <acquire>
  log.outstanding -= 1;
    800041b2:	509c                	lw	a5,32(s1)
    800041b4:	37fd                	addiw	a5,a5,-1
    800041b6:	0007891b          	sext.w	s2,a5
    800041ba:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041bc:	50dc                	lw	a5,36(s1)
    800041be:	efb9                	bnez	a5,8000421c <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041c0:	06091663          	bnez	s2,8000422c <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800041c4:	0001d497          	auipc	s1,0x1d
    800041c8:	74448493          	addi	s1,s1,1860 # 80021908 <log>
    800041cc:	4785                	li	a5,1
    800041ce:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041d0:	8526                	mv	a0,s1
    800041d2:	ffffd097          	auipc	ra,0xffffd
    800041d6:	b44080e7          	jalr	-1212(ra) # 80000d16 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041da:	54dc                	lw	a5,44(s1)
    800041dc:	06f04763          	bgtz	a5,8000424a <end_op+0xbc>
    acquire(&log.lock);
    800041e0:	0001d497          	auipc	s1,0x1d
    800041e4:	72848493          	addi	s1,s1,1832 # 80021908 <log>
    800041e8:	8526                	mv	a0,s1
    800041ea:	ffffd097          	auipc	ra,0xffffd
    800041ee:	a78080e7          	jalr	-1416(ra) # 80000c62 <acquire>
    log.committing = 0;
    800041f2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041f6:	8526                	mv	a0,s1
    800041f8:	ffffe097          	auipc	ra,0xffffe
    800041fc:	1d2080e7          	jalr	466(ra) # 800023ca <wakeup>
    release(&log.lock);
    80004200:	8526                	mv	a0,s1
    80004202:	ffffd097          	auipc	ra,0xffffd
    80004206:	b14080e7          	jalr	-1260(ra) # 80000d16 <release>
}
    8000420a:	70e2                	ld	ra,56(sp)
    8000420c:	7442                	ld	s0,48(sp)
    8000420e:	74a2                	ld	s1,40(sp)
    80004210:	7902                	ld	s2,32(sp)
    80004212:	69e2                	ld	s3,24(sp)
    80004214:	6a42                	ld	s4,16(sp)
    80004216:	6aa2                	ld	s5,8(sp)
    80004218:	6121                	addi	sp,sp,64
    8000421a:	8082                	ret
    panic("log.committing");
    8000421c:	00004517          	auipc	a0,0x4
    80004220:	58c50513          	addi	a0,a0,1420 # 800087a8 <syscalls_name+0x1f0>
    80004224:	ffffc097          	auipc	ra,0xffffc
    80004228:	324080e7          	jalr	804(ra) # 80000548 <panic>
    wakeup(&log);
    8000422c:	0001d497          	auipc	s1,0x1d
    80004230:	6dc48493          	addi	s1,s1,1756 # 80021908 <log>
    80004234:	8526                	mv	a0,s1
    80004236:	ffffe097          	auipc	ra,0xffffe
    8000423a:	194080e7          	jalr	404(ra) # 800023ca <wakeup>
  release(&log.lock);
    8000423e:	8526                	mv	a0,s1
    80004240:	ffffd097          	auipc	ra,0xffffd
    80004244:	ad6080e7          	jalr	-1322(ra) # 80000d16 <release>
  if(do_commit){
    80004248:	b7c9                	j	8000420a <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000424a:	0001da97          	auipc	s5,0x1d
    8000424e:	6eea8a93          	addi	s5,s5,1774 # 80021938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004252:	0001da17          	auipc	s4,0x1d
    80004256:	6b6a0a13          	addi	s4,s4,1718 # 80021908 <log>
    8000425a:	018a2583          	lw	a1,24(s4)
    8000425e:	012585bb          	addw	a1,a1,s2
    80004262:	2585                	addiw	a1,a1,1
    80004264:	028a2503          	lw	a0,40(s4)
    80004268:	fffff097          	auipc	ra,0xfffff
    8000426c:	ce8080e7          	jalr	-792(ra) # 80002f50 <bread>
    80004270:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004272:	000aa583          	lw	a1,0(s5)
    80004276:	028a2503          	lw	a0,40(s4)
    8000427a:	fffff097          	auipc	ra,0xfffff
    8000427e:	cd6080e7          	jalr	-810(ra) # 80002f50 <bread>
    80004282:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004284:	40000613          	li	a2,1024
    80004288:	05850593          	addi	a1,a0,88
    8000428c:	05848513          	addi	a0,s1,88
    80004290:	ffffd097          	auipc	ra,0xffffd
    80004294:	b2e080e7          	jalr	-1234(ra) # 80000dbe <memmove>
    bwrite(to);  // write the log
    80004298:	8526                	mv	a0,s1
    8000429a:	fffff097          	auipc	ra,0xfffff
    8000429e:	da8080e7          	jalr	-600(ra) # 80003042 <bwrite>
    brelse(from);
    800042a2:	854e                	mv	a0,s3
    800042a4:	fffff097          	auipc	ra,0xfffff
    800042a8:	ddc080e7          	jalr	-548(ra) # 80003080 <brelse>
    brelse(to);
    800042ac:	8526                	mv	a0,s1
    800042ae:	fffff097          	auipc	ra,0xfffff
    800042b2:	dd2080e7          	jalr	-558(ra) # 80003080 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042b6:	2905                	addiw	s2,s2,1
    800042b8:	0a91                	addi	s5,s5,4
    800042ba:	02ca2783          	lw	a5,44(s4)
    800042be:	f8f94ee3          	blt	s2,a5,8000425a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042c2:	00000097          	auipc	ra,0x0
    800042c6:	c7a080e7          	jalr	-902(ra) # 80003f3c <write_head>
    install_trans(); // Now install writes to home locations
    800042ca:	00000097          	auipc	ra,0x0
    800042ce:	cec080e7          	jalr	-788(ra) # 80003fb6 <install_trans>
    log.lh.n = 0;
    800042d2:	0001d797          	auipc	a5,0x1d
    800042d6:	6607a123          	sw	zero,1634(a5) # 80021934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042da:	00000097          	auipc	ra,0x0
    800042de:	c62080e7          	jalr	-926(ra) # 80003f3c <write_head>
    800042e2:	bdfd                	j	800041e0 <end_op+0x52>

00000000800042e4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042e4:	1101                	addi	sp,sp,-32
    800042e6:	ec06                	sd	ra,24(sp)
    800042e8:	e822                	sd	s0,16(sp)
    800042ea:	e426                	sd	s1,8(sp)
    800042ec:	e04a                	sd	s2,0(sp)
    800042ee:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042f0:	0001d717          	auipc	a4,0x1d
    800042f4:	64472703          	lw	a4,1604(a4) # 80021934 <log+0x2c>
    800042f8:	47f5                	li	a5,29
    800042fa:	08e7c063          	blt	a5,a4,8000437a <log_write+0x96>
    800042fe:	84aa                	mv	s1,a0
    80004300:	0001d797          	auipc	a5,0x1d
    80004304:	6247a783          	lw	a5,1572(a5) # 80021924 <log+0x1c>
    80004308:	37fd                	addiw	a5,a5,-1
    8000430a:	06f75863          	bge	a4,a5,8000437a <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000430e:	0001d797          	auipc	a5,0x1d
    80004312:	61a7a783          	lw	a5,1562(a5) # 80021928 <log+0x20>
    80004316:	06f05a63          	blez	a5,8000438a <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    8000431a:	0001d917          	auipc	s2,0x1d
    8000431e:	5ee90913          	addi	s2,s2,1518 # 80021908 <log>
    80004322:	854a                	mv	a0,s2
    80004324:	ffffd097          	auipc	ra,0xffffd
    80004328:	93e080e7          	jalr	-1730(ra) # 80000c62 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    8000432c:	02c92603          	lw	a2,44(s2)
    80004330:	06c05563          	blez	a2,8000439a <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004334:	44cc                	lw	a1,12(s1)
    80004336:	0001d717          	auipc	a4,0x1d
    8000433a:	60270713          	addi	a4,a4,1538 # 80021938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000433e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004340:	4314                	lw	a3,0(a4)
    80004342:	04b68d63          	beq	a3,a1,8000439c <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004346:	2785                	addiw	a5,a5,1
    80004348:	0711                	addi	a4,a4,4
    8000434a:	fec79be3          	bne	a5,a2,80004340 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000434e:	0621                	addi	a2,a2,8
    80004350:	060a                	slli	a2,a2,0x2
    80004352:	0001d797          	auipc	a5,0x1d
    80004356:	5b678793          	addi	a5,a5,1462 # 80021908 <log>
    8000435a:	963e                	add	a2,a2,a5
    8000435c:	44dc                	lw	a5,12(s1)
    8000435e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004360:	8526                	mv	a0,s1
    80004362:	fffff097          	auipc	ra,0xfffff
    80004366:	dbc080e7          	jalr	-580(ra) # 8000311e <bpin>
    log.lh.n++;
    8000436a:	0001d717          	auipc	a4,0x1d
    8000436e:	59e70713          	addi	a4,a4,1438 # 80021908 <log>
    80004372:	575c                	lw	a5,44(a4)
    80004374:	2785                	addiw	a5,a5,1
    80004376:	d75c                	sw	a5,44(a4)
    80004378:	a83d                	j	800043b6 <log_write+0xd2>
    panic("too big a transaction");
    8000437a:	00004517          	auipc	a0,0x4
    8000437e:	43e50513          	addi	a0,a0,1086 # 800087b8 <syscalls_name+0x200>
    80004382:	ffffc097          	auipc	ra,0xffffc
    80004386:	1c6080e7          	jalr	454(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    8000438a:	00004517          	auipc	a0,0x4
    8000438e:	44650513          	addi	a0,a0,1094 # 800087d0 <syscalls_name+0x218>
    80004392:	ffffc097          	auipc	ra,0xffffc
    80004396:	1b6080e7          	jalr	438(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    8000439a:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000439c:	00878713          	addi	a4,a5,8
    800043a0:	00271693          	slli	a3,a4,0x2
    800043a4:	0001d717          	auipc	a4,0x1d
    800043a8:	56470713          	addi	a4,a4,1380 # 80021908 <log>
    800043ac:	9736                	add	a4,a4,a3
    800043ae:	44d4                	lw	a3,12(s1)
    800043b0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043b2:	faf607e3          	beq	a2,a5,80004360 <log_write+0x7c>
  }
  release(&log.lock);
    800043b6:	0001d517          	auipc	a0,0x1d
    800043ba:	55250513          	addi	a0,a0,1362 # 80021908 <log>
    800043be:	ffffd097          	auipc	ra,0xffffd
    800043c2:	958080e7          	jalr	-1704(ra) # 80000d16 <release>
}
    800043c6:	60e2                	ld	ra,24(sp)
    800043c8:	6442                	ld	s0,16(sp)
    800043ca:	64a2                	ld	s1,8(sp)
    800043cc:	6902                	ld	s2,0(sp)
    800043ce:	6105                	addi	sp,sp,32
    800043d0:	8082                	ret

00000000800043d2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043d2:	1101                	addi	sp,sp,-32
    800043d4:	ec06                	sd	ra,24(sp)
    800043d6:	e822                	sd	s0,16(sp)
    800043d8:	e426                	sd	s1,8(sp)
    800043da:	e04a                	sd	s2,0(sp)
    800043dc:	1000                	addi	s0,sp,32
    800043de:	84aa                	mv	s1,a0
    800043e0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043e2:	00004597          	auipc	a1,0x4
    800043e6:	40e58593          	addi	a1,a1,1038 # 800087f0 <syscalls_name+0x238>
    800043ea:	0521                	addi	a0,a0,8
    800043ec:	ffffc097          	auipc	ra,0xffffc
    800043f0:	7e6080e7          	jalr	2022(ra) # 80000bd2 <initlock>
  lk->name = name;
    800043f4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043f8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043fc:	0204a423          	sw	zero,40(s1)
}
    80004400:	60e2                	ld	ra,24(sp)
    80004402:	6442                	ld	s0,16(sp)
    80004404:	64a2                	ld	s1,8(sp)
    80004406:	6902                	ld	s2,0(sp)
    80004408:	6105                	addi	sp,sp,32
    8000440a:	8082                	ret

000000008000440c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000440c:	1101                	addi	sp,sp,-32
    8000440e:	ec06                	sd	ra,24(sp)
    80004410:	e822                	sd	s0,16(sp)
    80004412:	e426                	sd	s1,8(sp)
    80004414:	e04a                	sd	s2,0(sp)
    80004416:	1000                	addi	s0,sp,32
    80004418:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000441a:	00850913          	addi	s2,a0,8
    8000441e:	854a                	mv	a0,s2
    80004420:	ffffd097          	auipc	ra,0xffffd
    80004424:	842080e7          	jalr	-1982(ra) # 80000c62 <acquire>
  while (lk->locked) {
    80004428:	409c                	lw	a5,0(s1)
    8000442a:	cb89                	beqz	a5,8000443c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000442c:	85ca                	mv	a1,s2
    8000442e:	8526                	mv	a0,s1
    80004430:	ffffe097          	auipc	ra,0xffffe
    80004434:	e14080e7          	jalr	-492(ra) # 80002244 <sleep>
  while (lk->locked) {
    80004438:	409c                	lw	a5,0(s1)
    8000443a:	fbed                	bnez	a5,8000442c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000443c:	4785                	li	a5,1
    8000443e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004440:	ffffd097          	auipc	ra,0xffffd
    80004444:	5f0080e7          	jalr	1520(ra) # 80001a30 <myproc>
    80004448:	5d1c                	lw	a5,56(a0)
    8000444a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000444c:	854a                	mv	a0,s2
    8000444e:	ffffd097          	auipc	ra,0xffffd
    80004452:	8c8080e7          	jalr	-1848(ra) # 80000d16 <release>
}
    80004456:	60e2                	ld	ra,24(sp)
    80004458:	6442                	ld	s0,16(sp)
    8000445a:	64a2                	ld	s1,8(sp)
    8000445c:	6902                	ld	s2,0(sp)
    8000445e:	6105                	addi	sp,sp,32
    80004460:	8082                	ret

0000000080004462 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004462:	1101                	addi	sp,sp,-32
    80004464:	ec06                	sd	ra,24(sp)
    80004466:	e822                	sd	s0,16(sp)
    80004468:	e426                	sd	s1,8(sp)
    8000446a:	e04a                	sd	s2,0(sp)
    8000446c:	1000                	addi	s0,sp,32
    8000446e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004470:	00850913          	addi	s2,a0,8
    80004474:	854a                	mv	a0,s2
    80004476:	ffffc097          	auipc	ra,0xffffc
    8000447a:	7ec080e7          	jalr	2028(ra) # 80000c62 <acquire>
  lk->locked = 0;
    8000447e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004482:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004486:	8526                	mv	a0,s1
    80004488:	ffffe097          	auipc	ra,0xffffe
    8000448c:	f42080e7          	jalr	-190(ra) # 800023ca <wakeup>
  release(&lk->lk);
    80004490:	854a                	mv	a0,s2
    80004492:	ffffd097          	auipc	ra,0xffffd
    80004496:	884080e7          	jalr	-1916(ra) # 80000d16 <release>
}
    8000449a:	60e2                	ld	ra,24(sp)
    8000449c:	6442                	ld	s0,16(sp)
    8000449e:	64a2                	ld	s1,8(sp)
    800044a0:	6902                	ld	s2,0(sp)
    800044a2:	6105                	addi	sp,sp,32
    800044a4:	8082                	ret

00000000800044a6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044a6:	7179                	addi	sp,sp,-48
    800044a8:	f406                	sd	ra,40(sp)
    800044aa:	f022                	sd	s0,32(sp)
    800044ac:	ec26                	sd	s1,24(sp)
    800044ae:	e84a                	sd	s2,16(sp)
    800044b0:	e44e                	sd	s3,8(sp)
    800044b2:	1800                	addi	s0,sp,48
    800044b4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044b6:	00850913          	addi	s2,a0,8
    800044ba:	854a                	mv	a0,s2
    800044bc:	ffffc097          	auipc	ra,0xffffc
    800044c0:	7a6080e7          	jalr	1958(ra) # 80000c62 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044c4:	409c                	lw	a5,0(s1)
    800044c6:	ef99                	bnez	a5,800044e4 <holdingsleep+0x3e>
    800044c8:	4481                	li	s1,0
  release(&lk->lk);
    800044ca:	854a                	mv	a0,s2
    800044cc:	ffffd097          	auipc	ra,0xffffd
    800044d0:	84a080e7          	jalr	-1974(ra) # 80000d16 <release>
  return r;
}
    800044d4:	8526                	mv	a0,s1
    800044d6:	70a2                	ld	ra,40(sp)
    800044d8:	7402                	ld	s0,32(sp)
    800044da:	64e2                	ld	s1,24(sp)
    800044dc:	6942                	ld	s2,16(sp)
    800044de:	69a2                	ld	s3,8(sp)
    800044e0:	6145                	addi	sp,sp,48
    800044e2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044e4:	0284a983          	lw	s3,40(s1)
    800044e8:	ffffd097          	auipc	ra,0xffffd
    800044ec:	548080e7          	jalr	1352(ra) # 80001a30 <myproc>
    800044f0:	5d04                	lw	s1,56(a0)
    800044f2:	413484b3          	sub	s1,s1,s3
    800044f6:	0014b493          	seqz	s1,s1
    800044fa:	bfc1                	j	800044ca <holdingsleep+0x24>

00000000800044fc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044fc:	1141                	addi	sp,sp,-16
    800044fe:	e406                	sd	ra,8(sp)
    80004500:	e022                	sd	s0,0(sp)
    80004502:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004504:	00004597          	auipc	a1,0x4
    80004508:	2fc58593          	addi	a1,a1,764 # 80008800 <syscalls_name+0x248>
    8000450c:	0001d517          	auipc	a0,0x1d
    80004510:	54450513          	addi	a0,a0,1348 # 80021a50 <ftable>
    80004514:	ffffc097          	auipc	ra,0xffffc
    80004518:	6be080e7          	jalr	1726(ra) # 80000bd2 <initlock>
}
    8000451c:	60a2                	ld	ra,8(sp)
    8000451e:	6402                	ld	s0,0(sp)
    80004520:	0141                	addi	sp,sp,16
    80004522:	8082                	ret

0000000080004524 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004524:	1101                	addi	sp,sp,-32
    80004526:	ec06                	sd	ra,24(sp)
    80004528:	e822                	sd	s0,16(sp)
    8000452a:	e426                	sd	s1,8(sp)
    8000452c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000452e:	0001d517          	auipc	a0,0x1d
    80004532:	52250513          	addi	a0,a0,1314 # 80021a50 <ftable>
    80004536:	ffffc097          	auipc	ra,0xffffc
    8000453a:	72c080e7          	jalr	1836(ra) # 80000c62 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000453e:	0001d497          	auipc	s1,0x1d
    80004542:	52a48493          	addi	s1,s1,1322 # 80021a68 <ftable+0x18>
    80004546:	0001e717          	auipc	a4,0x1e
    8000454a:	4c270713          	addi	a4,a4,1218 # 80022a08 <ftable+0xfb8>
    if(f->ref == 0){
    8000454e:	40dc                	lw	a5,4(s1)
    80004550:	cf99                	beqz	a5,8000456e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004552:	02848493          	addi	s1,s1,40
    80004556:	fee49ce3          	bne	s1,a4,8000454e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000455a:	0001d517          	auipc	a0,0x1d
    8000455e:	4f650513          	addi	a0,a0,1270 # 80021a50 <ftable>
    80004562:	ffffc097          	auipc	ra,0xffffc
    80004566:	7b4080e7          	jalr	1972(ra) # 80000d16 <release>
  return 0;
    8000456a:	4481                	li	s1,0
    8000456c:	a819                	j	80004582 <filealloc+0x5e>
      f->ref = 1;
    8000456e:	4785                	li	a5,1
    80004570:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004572:	0001d517          	auipc	a0,0x1d
    80004576:	4de50513          	addi	a0,a0,1246 # 80021a50 <ftable>
    8000457a:	ffffc097          	auipc	ra,0xffffc
    8000457e:	79c080e7          	jalr	1948(ra) # 80000d16 <release>
}
    80004582:	8526                	mv	a0,s1
    80004584:	60e2                	ld	ra,24(sp)
    80004586:	6442                	ld	s0,16(sp)
    80004588:	64a2                	ld	s1,8(sp)
    8000458a:	6105                	addi	sp,sp,32
    8000458c:	8082                	ret

000000008000458e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000458e:	1101                	addi	sp,sp,-32
    80004590:	ec06                	sd	ra,24(sp)
    80004592:	e822                	sd	s0,16(sp)
    80004594:	e426                	sd	s1,8(sp)
    80004596:	1000                	addi	s0,sp,32
    80004598:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000459a:	0001d517          	auipc	a0,0x1d
    8000459e:	4b650513          	addi	a0,a0,1206 # 80021a50 <ftable>
    800045a2:	ffffc097          	auipc	ra,0xffffc
    800045a6:	6c0080e7          	jalr	1728(ra) # 80000c62 <acquire>
  if(f->ref < 1)
    800045aa:	40dc                	lw	a5,4(s1)
    800045ac:	02f05263          	blez	a5,800045d0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045b0:	2785                	addiw	a5,a5,1
    800045b2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045b4:	0001d517          	auipc	a0,0x1d
    800045b8:	49c50513          	addi	a0,a0,1180 # 80021a50 <ftable>
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	75a080e7          	jalr	1882(ra) # 80000d16 <release>
  return f;
}
    800045c4:	8526                	mv	a0,s1
    800045c6:	60e2                	ld	ra,24(sp)
    800045c8:	6442                	ld	s0,16(sp)
    800045ca:	64a2                	ld	s1,8(sp)
    800045cc:	6105                	addi	sp,sp,32
    800045ce:	8082                	ret
    panic("filedup");
    800045d0:	00004517          	auipc	a0,0x4
    800045d4:	23850513          	addi	a0,a0,568 # 80008808 <syscalls_name+0x250>
    800045d8:	ffffc097          	auipc	ra,0xffffc
    800045dc:	f70080e7          	jalr	-144(ra) # 80000548 <panic>

00000000800045e0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045e0:	7139                	addi	sp,sp,-64
    800045e2:	fc06                	sd	ra,56(sp)
    800045e4:	f822                	sd	s0,48(sp)
    800045e6:	f426                	sd	s1,40(sp)
    800045e8:	f04a                	sd	s2,32(sp)
    800045ea:	ec4e                	sd	s3,24(sp)
    800045ec:	e852                	sd	s4,16(sp)
    800045ee:	e456                	sd	s5,8(sp)
    800045f0:	0080                	addi	s0,sp,64
    800045f2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045f4:	0001d517          	auipc	a0,0x1d
    800045f8:	45c50513          	addi	a0,a0,1116 # 80021a50 <ftable>
    800045fc:	ffffc097          	auipc	ra,0xffffc
    80004600:	666080e7          	jalr	1638(ra) # 80000c62 <acquire>
  if(f->ref < 1)
    80004604:	40dc                	lw	a5,4(s1)
    80004606:	06f05163          	blez	a5,80004668 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000460a:	37fd                	addiw	a5,a5,-1
    8000460c:	0007871b          	sext.w	a4,a5
    80004610:	c0dc                	sw	a5,4(s1)
    80004612:	06e04363          	bgtz	a4,80004678 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004616:	0004a903          	lw	s2,0(s1)
    8000461a:	0094ca83          	lbu	s5,9(s1)
    8000461e:	0104ba03          	ld	s4,16(s1)
    80004622:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004626:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000462a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000462e:	0001d517          	auipc	a0,0x1d
    80004632:	42250513          	addi	a0,a0,1058 # 80021a50 <ftable>
    80004636:	ffffc097          	auipc	ra,0xffffc
    8000463a:	6e0080e7          	jalr	1760(ra) # 80000d16 <release>

  if(ff.type == FD_PIPE){
    8000463e:	4785                	li	a5,1
    80004640:	04f90d63          	beq	s2,a5,8000469a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004644:	3979                	addiw	s2,s2,-2
    80004646:	4785                	li	a5,1
    80004648:	0527e063          	bltu	a5,s2,80004688 <fileclose+0xa8>
    begin_op();
    8000464c:	00000097          	auipc	ra,0x0
    80004650:	ac2080e7          	jalr	-1342(ra) # 8000410e <begin_op>
    iput(ff.ip);
    80004654:	854e                	mv	a0,s3
    80004656:	fffff097          	auipc	ra,0xfffff
    8000465a:	2b6080e7          	jalr	694(ra) # 8000390c <iput>
    end_op();
    8000465e:	00000097          	auipc	ra,0x0
    80004662:	b30080e7          	jalr	-1232(ra) # 8000418e <end_op>
    80004666:	a00d                	j	80004688 <fileclose+0xa8>
    panic("fileclose");
    80004668:	00004517          	auipc	a0,0x4
    8000466c:	1a850513          	addi	a0,a0,424 # 80008810 <syscalls_name+0x258>
    80004670:	ffffc097          	auipc	ra,0xffffc
    80004674:	ed8080e7          	jalr	-296(ra) # 80000548 <panic>
    release(&ftable.lock);
    80004678:	0001d517          	auipc	a0,0x1d
    8000467c:	3d850513          	addi	a0,a0,984 # 80021a50 <ftable>
    80004680:	ffffc097          	auipc	ra,0xffffc
    80004684:	696080e7          	jalr	1686(ra) # 80000d16 <release>
  }
}
    80004688:	70e2                	ld	ra,56(sp)
    8000468a:	7442                	ld	s0,48(sp)
    8000468c:	74a2                	ld	s1,40(sp)
    8000468e:	7902                	ld	s2,32(sp)
    80004690:	69e2                	ld	s3,24(sp)
    80004692:	6a42                	ld	s4,16(sp)
    80004694:	6aa2                	ld	s5,8(sp)
    80004696:	6121                	addi	sp,sp,64
    80004698:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000469a:	85d6                	mv	a1,s5
    8000469c:	8552                	mv	a0,s4
    8000469e:	00000097          	auipc	ra,0x0
    800046a2:	372080e7          	jalr	882(ra) # 80004a10 <pipeclose>
    800046a6:	b7cd                	j	80004688 <fileclose+0xa8>

00000000800046a8 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046a8:	715d                	addi	sp,sp,-80
    800046aa:	e486                	sd	ra,72(sp)
    800046ac:	e0a2                	sd	s0,64(sp)
    800046ae:	fc26                	sd	s1,56(sp)
    800046b0:	f84a                	sd	s2,48(sp)
    800046b2:	f44e                	sd	s3,40(sp)
    800046b4:	0880                	addi	s0,sp,80
    800046b6:	84aa                	mv	s1,a0
    800046b8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046ba:	ffffd097          	auipc	ra,0xffffd
    800046be:	376080e7          	jalr	886(ra) # 80001a30 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046c2:	409c                	lw	a5,0(s1)
    800046c4:	37f9                	addiw	a5,a5,-2
    800046c6:	4705                	li	a4,1
    800046c8:	04f76763          	bltu	a4,a5,80004716 <filestat+0x6e>
    800046cc:	892a                	mv	s2,a0
    ilock(f->ip);
    800046ce:	6c88                	ld	a0,24(s1)
    800046d0:	fffff097          	auipc	ra,0xfffff
    800046d4:	082080e7          	jalr	130(ra) # 80003752 <ilock>
    stati(f->ip, &st);
    800046d8:	fb840593          	addi	a1,s0,-72
    800046dc:	6c88                	ld	a0,24(s1)
    800046de:	fffff097          	auipc	ra,0xfffff
    800046e2:	2fe080e7          	jalr	766(ra) # 800039dc <stati>
    iunlock(f->ip);
    800046e6:	6c88                	ld	a0,24(s1)
    800046e8:	fffff097          	auipc	ra,0xfffff
    800046ec:	12c080e7          	jalr	300(ra) # 80003814 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046f0:	46e1                	li	a3,24
    800046f2:	fb840613          	addi	a2,s0,-72
    800046f6:	85ce                	mv	a1,s3
    800046f8:	05093503          	ld	a0,80(s2)
    800046fc:	ffffd097          	auipc	ra,0xffffd
    80004700:	028080e7          	jalr	40(ra) # 80001724 <copyout>
    80004704:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004708:	60a6                	ld	ra,72(sp)
    8000470a:	6406                	ld	s0,64(sp)
    8000470c:	74e2                	ld	s1,56(sp)
    8000470e:	7942                	ld	s2,48(sp)
    80004710:	79a2                	ld	s3,40(sp)
    80004712:	6161                	addi	sp,sp,80
    80004714:	8082                	ret
  return -1;
    80004716:	557d                	li	a0,-1
    80004718:	bfc5                	j	80004708 <filestat+0x60>

000000008000471a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000471a:	7179                	addi	sp,sp,-48
    8000471c:	f406                	sd	ra,40(sp)
    8000471e:	f022                	sd	s0,32(sp)
    80004720:	ec26                	sd	s1,24(sp)
    80004722:	e84a                	sd	s2,16(sp)
    80004724:	e44e                	sd	s3,8(sp)
    80004726:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004728:	00854783          	lbu	a5,8(a0)
    8000472c:	c3d5                	beqz	a5,800047d0 <fileread+0xb6>
    8000472e:	84aa                	mv	s1,a0
    80004730:	89ae                	mv	s3,a1
    80004732:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004734:	411c                	lw	a5,0(a0)
    80004736:	4705                	li	a4,1
    80004738:	04e78963          	beq	a5,a4,8000478a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000473c:	470d                	li	a4,3
    8000473e:	04e78d63          	beq	a5,a4,80004798 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004742:	4709                	li	a4,2
    80004744:	06e79e63          	bne	a5,a4,800047c0 <fileread+0xa6>
    ilock(f->ip);
    80004748:	6d08                	ld	a0,24(a0)
    8000474a:	fffff097          	auipc	ra,0xfffff
    8000474e:	008080e7          	jalr	8(ra) # 80003752 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004752:	874a                	mv	a4,s2
    80004754:	5094                	lw	a3,32(s1)
    80004756:	864e                	mv	a2,s3
    80004758:	4585                	li	a1,1
    8000475a:	6c88                	ld	a0,24(s1)
    8000475c:	fffff097          	auipc	ra,0xfffff
    80004760:	2aa080e7          	jalr	682(ra) # 80003a06 <readi>
    80004764:	892a                	mv	s2,a0
    80004766:	00a05563          	blez	a0,80004770 <fileread+0x56>
      f->off += r;
    8000476a:	509c                	lw	a5,32(s1)
    8000476c:	9fa9                	addw	a5,a5,a0
    8000476e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004770:	6c88                	ld	a0,24(s1)
    80004772:	fffff097          	auipc	ra,0xfffff
    80004776:	0a2080e7          	jalr	162(ra) # 80003814 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000477a:	854a                	mv	a0,s2
    8000477c:	70a2                	ld	ra,40(sp)
    8000477e:	7402                	ld	s0,32(sp)
    80004780:	64e2                	ld	s1,24(sp)
    80004782:	6942                	ld	s2,16(sp)
    80004784:	69a2                	ld	s3,8(sp)
    80004786:	6145                	addi	sp,sp,48
    80004788:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000478a:	6908                	ld	a0,16(a0)
    8000478c:	00000097          	auipc	ra,0x0
    80004790:	418080e7          	jalr	1048(ra) # 80004ba4 <piperead>
    80004794:	892a                	mv	s2,a0
    80004796:	b7d5                	j	8000477a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004798:	02451783          	lh	a5,36(a0)
    8000479c:	03079693          	slli	a3,a5,0x30
    800047a0:	92c1                	srli	a3,a3,0x30
    800047a2:	4725                	li	a4,9
    800047a4:	02d76863          	bltu	a4,a3,800047d4 <fileread+0xba>
    800047a8:	0792                	slli	a5,a5,0x4
    800047aa:	0001d717          	auipc	a4,0x1d
    800047ae:	20670713          	addi	a4,a4,518 # 800219b0 <devsw>
    800047b2:	97ba                	add	a5,a5,a4
    800047b4:	639c                	ld	a5,0(a5)
    800047b6:	c38d                	beqz	a5,800047d8 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047b8:	4505                	li	a0,1
    800047ba:	9782                	jalr	a5
    800047bc:	892a                	mv	s2,a0
    800047be:	bf75                	j	8000477a <fileread+0x60>
    panic("fileread");
    800047c0:	00004517          	auipc	a0,0x4
    800047c4:	06050513          	addi	a0,a0,96 # 80008820 <syscalls_name+0x268>
    800047c8:	ffffc097          	auipc	ra,0xffffc
    800047cc:	d80080e7          	jalr	-640(ra) # 80000548 <panic>
    return -1;
    800047d0:	597d                	li	s2,-1
    800047d2:	b765                	j	8000477a <fileread+0x60>
      return -1;
    800047d4:	597d                	li	s2,-1
    800047d6:	b755                	j	8000477a <fileread+0x60>
    800047d8:	597d                	li	s2,-1
    800047da:	b745                	j	8000477a <fileread+0x60>

00000000800047dc <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800047dc:	00954783          	lbu	a5,9(a0)
    800047e0:	14078563          	beqz	a5,8000492a <filewrite+0x14e>
{
    800047e4:	715d                	addi	sp,sp,-80
    800047e6:	e486                	sd	ra,72(sp)
    800047e8:	e0a2                	sd	s0,64(sp)
    800047ea:	fc26                	sd	s1,56(sp)
    800047ec:	f84a                	sd	s2,48(sp)
    800047ee:	f44e                	sd	s3,40(sp)
    800047f0:	f052                	sd	s4,32(sp)
    800047f2:	ec56                	sd	s5,24(sp)
    800047f4:	e85a                	sd	s6,16(sp)
    800047f6:	e45e                	sd	s7,8(sp)
    800047f8:	e062                	sd	s8,0(sp)
    800047fa:	0880                	addi	s0,sp,80
    800047fc:	892a                	mv	s2,a0
    800047fe:	8aae                	mv	s5,a1
    80004800:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004802:	411c                	lw	a5,0(a0)
    80004804:	4705                	li	a4,1
    80004806:	02e78263          	beq	a5,a4,8000482a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000480a:	470d                	li	a4,3
    8000480c:	02e78563          	beq	a5,a4,80004836 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004810:	4709                	li	a4,2
    80004812:	10e79463          	bne	a5,a4,8000491a <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004816:	0ec05e63          	blez	a2,80004912 <filewrite+0x136>
    int i = 0;
    8000481a:	4981                	li	s3,0
    8000481c:	6b05                	lui	s6,0x1
    8000481e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004822:	6b85                	lui	s7,0x1
    80004824:	c00b8b9b          	addiw	s7,s7,-1024
    80004828:	a851                	j	800048bc <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    8000482a:	6908                	ld	a0,16(a0)
    8000482c:	00000097          	auipc	ra,0x0
    80004830:	254080e7          	jalr	596(ra) # 80004a80 <pipewrite>
    80004834:	a85d                	j	800048ea <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004836:	02451783          	lh	a5,36(a0)
    8000483a:	03079693          	slli	a3,a5,0x30
    8000483e:	92c1                	srli	a3,a3,0x30
    80004840:	4725                	li	a4,9
    80004842:	0ed76663          	bltu	a4,a3,8000492e <filewrite+0x152>
    80004846:	0792                	slli	a5,a5,0x4
    80004848:	0001d717          	auipc	a4,0x1d
    8000484c:	16870713          	addi	a4,a4,360 # 800219b0 <devsw>
    80004850:	97ba                	add	a5,a5,a4
    80004852:	679c                	ld	a5,8(a5)
    80004854:	cff9                	beqz	a5,80004932 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004856:	4505                	li	a0,1
    80004858:	9782                	jalr	a5
    8000485a:	a841                	j	800048ea <filewrite+0x10e>
    8000485c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004860:	00000097          	auipc	ra,0x0
    80004864:	8ae080e7          	jalr	-1874(ra) # 8000410e <begin_op>
      ilock(f->ip);
    80004868:	01893503          	ld	a0,24(s2)
    8000486c:	fffff097          	auipc	ra,0xfffff
    80004870:	ee6080e7          	jalr	-282(ra) # 80003752 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004874:	8762                	mv	a4,s8
    80004876:	02092683          	lw	a3,32(s2)
    8000487a:	01598633          	add	a2,s3,s5
    8000487e:	4585                	li	a1,1
    80004880:	01893503          	ld	a0,24(s2)
    80004884:	fffff097          	auipc	ra,0xfffff
    80004888:	278080e7          	jalr	632(ra) # 80003afc <writei>
    8000488c:	84aa                	mv	s1,a0
    8000488e:	02a05f63          	blez	a0,800048cc <filewrite+0xf0>
        f->off += r;
    80004892:	02092783          	lw	a5,32(s2)
    80004896:	9fa9                	addw	a5,a5,a0
    80004898:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000489c:	01893503          	ld	a0,24(s2)
    800048a0:	fffff097          	auipc	ra,0xfffff
    800048a4:	f74080e7          	jalr	-140(ra) # 80003814 <iunlock>
      end_op();
    800048a8:	00000097          	auipc	ra,0x0
    800048ac:	8e6080e7          	jalr	-1818(ra) # 8000418e <end_op>

      if(r < 0)
        break;
      if(r != n1)
    800048b0:	049c1963          	bne	s8,s1,80004902 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    800048b4:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048b8:	0349d663          	bge	s3,s4,800048e4 <filewrite+0x108>
      int n1 = n - i;
    800048bc:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048c0:	84be                	mv	s1,a5
    800048c2:	2781                	sext.w	a5,a5
    800048c4:	f8fb5ce3          	bge	s6,a5,8000485c <filewrite+0x80>
    800048c8:	84de                	mv	s1,s7
    800048ca:	bf49                	j	8000485c <filewrite+0x80>
      iunlock(f->ip);
    800048cc:	01893503          	ld	a0,24(s2)
    800048d0:	fffff097          	auipc	ra,0xfffff
    800048d4:	f44080e7          	jalr	-188(ra) # 80003814 <iunlock>
      end_op();
    800048d8:	00000097          	auipc	ra,0x0
    800048dc:	8b6080e7          	jalr	-1866(ra) # 8000418e <end_op>
      if(r < 0)
    800048e0:	fc04d8e3          	bgez	s1,800048b0 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    800048e4:	8552                	mv	a0,s4
    800048e6:	033a1863          	bne	s4,s3,80004916 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048ea:	60a6                	ld	ra,72(sp)
    800048ec:	6406                	ld	s0,64(sp)
    800048ee:	74e2                	ld	s1,56(sp)
    800048f0:	7942                	ld	s2,48(sp)
    800048f2:	79a2                	ld	s3,40(sp)
    800048f4:	7a02                	ld	s4,32(sp)
    800048f6:	6ae2                	ld	s5,24(sp)
    800048f8:	6b42                	ld	s6,16(sp)
    800048fa:	6ba2                	ld	s7,8(sp)
    800048fc:	6c02                	ld	s8,0(sp)
    800048fe:	6161                	addi	sp,sp,80
    80004900:	8082                	ret
        panic("short filewrite");
    80004902:	00004517          	auipc	a0,0x4
    80004906:	f2e50513          	addi	a0,a0,-210 # 80008830 <syscalls_name+0x278>
    8000490a:	ffffc097          	auipc	ra,0xffffc
    8000490e:	c3e080e7          	jalr	-962(ra) # 80000548 <panic>
    int i = 0;
    80004912:	4981                	li	s3,0
    80004914:	bfc1                	j	800048e4 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004916:	557d                	li	a0,-1
    80004918:	bfc9                	j	800048ea <filewrite+0x10e>
    panic("filewrite");
    8000491a:	00004517          	auipc	a0,0x4
    8000491e:	f2650513          	addi	a0,a0,-218 # 80008840 <syscalls_name+0x288>
    80004922:	ffffc097          	auipc	ra,0xffffc
    80004926:	c26080e7          	jalr	-986(ra) # 80000548 <panic>
    return -1;
    8000492a:	557d                	li	a0,-1
}
    8000492c:	8082                	ret
      return -1;
    8000492e:	557d                	li	a0,-1
    80004930:	bf6d                	j	800048ea <filewrite+0x10e>
    80004932:	557d                	li	a0,-1
    80004934:	bf5d                	j	800048ea <filewrite+0x10e>

0000000080004936 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004936:	7179                	addi	sp,sp,-48
    80004938:	f406                	sd	ra,40(sp)
    8000493a:	f022                	sd	s0,32(sp)
    8000493c:	ec26                	sd	s1,24(sp)
    8000493e:	e84a                	sd	s2,16(sp)
    80004940:	e44e                	sd	s3,8(sp)
    80004942:	e052                	sd	s4,0(sp)
    80004944:	1800                	addi	s0,sp,48
    80004946:	84aa                	mv	s1,a0
    80004948:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000494a:	0005b023          	sd	zero,0(a1)
    8000494e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004952:	00000097          	auipc	ra,0x0
    80004956:	bd2080e7          	jalr	-1070(ra) # 80004524 <filealloc>
    8000495a:	e088                	sd	a0,0(s1)
    8000495c:	c551                	beqz	a0,800049e8 <pipealloc+0xb2>
    8000495e:	00000097          	auipc	ra,0x0
    80004962:	bc6080e7          	jalr	-1082(ra) # 80004524 <filealloc>
    80004966:	00aa3023          	sd	a0,0(s4)
    8000496a:	c92d                	beqz	a0,800049dc <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000496c:	ffffc097          	auipc	ra,0xffffc
    80004970:	1b4080e7          	jalr	436(ra) # 80000b20 <kalloc>
    80004974:	892a                	mv	s2,a0
    80004976:	c125                	beqz	a0,800049d6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004978:	4985                	li	s3,1
    8000497a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000497e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004982:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004986:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000498a:	00004597          	auipc	a1,0x4
    8000498e:	ab658593          	addi	a1,a1,-1354 # 80008440 <states.1707+0x198>
    80004992:	ffffc097          	auipc	ra,0xffffc
    80004996:	240080e7          	jalr	576(ra) # 80000bd2 <initlock>
  (*f0)->type = FD_PIPE;
    8000499a:	609c                	ld	a5,0(s1)
    8000499c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049a0:	609c                	ld	a5,0(s1)
    800049a2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049a6:	609c                	ld	a5,0(s1)
    800049a8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049ac:	609c                	ld	a5,0(s1)
    800049ae:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049b2:	000a3783          	ld	a5,0(s4)
    800049b6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049ba:	000a3783          	ld	a5,0(s4)
    800049be:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049c2:	000a3783          	ld	a5,0(s4)
    800049c6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049ca:	000a3783          	ld	a5,0(s4)
    800049ce:	0127b823          	sd	s2,16(a5)
  return 0;
    800049d2:	4501                	li	a0,0
    800049d4:	a025                	j	800049fc <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049d6:	6088                	ld	a0,0(s1)
    800049d8:	e501                	bnez	a0,800049e0 <pipealloc+0xaa>
    800049da:	a039                	j	800049e8 <pipealloc+0xb2>
    800049dc:	6088                	ld	a0,0(s1)
    800049de:	c51d                	beqz	a0,80004a0c <pipealloc+0xd6>
    fileclose(*f0);
    800049e0:	00000097          	auipc	ra,0x0
    800049e4:	c00080e7          	jalr	-1024(ra) # 800045e0 <fileclose>
  if(*f1)
    800049e8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049ec:	557d                	li	a0,-1
  if(*f1)
    800049ee:	c799                	beqz	a5,800049fc <pipealloc+0xc6>
    fileclose(*f1);
    800049f0:	853e                	mv	a0,a5
    800049f2:	00000097          	auipc	ra,0x0
    800049f6:	bee080e7          	jalr	-1042(ra) # 800045e0 <fileclose>
  return -1;
    800049fa:	557d                	li	a0,-1
}
    800049fc:	70a2                	ld	ra,40(sp)
    800049fe:	7402                	ld	s0,32(sp)
    80004a00:	64e2                	ld	s1,24(sp)
    80004a02:	6942                	ld	s2,16(sp)
    80004a04:	69a2                	ld	s3,8(sp)
    80004a06:	6a02                	ld	s4,0(sp)
    80004a08:	6145                	addi	sp,sp,48
    80004a0a:	8082                	ret
  return -1;
    80004a0c:	557d                	li	a0,-1
    80004a0e:	b7fd                	j	800049fc <pipealloc+0xc6>

0000000080004a10 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a10:	1101                	addi	sp,sp,-32
    80004a12:	ec06                	sd	ra,24(sp)
    80004a14:	e822                	sd	s0,16(sp)
    80004a16:	e426                	sd	s1,8(sp)
    80004a18:	e04a                	sd	s2,0(sp)
    80004a1a:	1000                	addi	s0,sp,32
    80004a1c:	84aa                	mv	s1,a0
    80004a1e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a20:	ffffc097          	auipc	ra,0xffffc
    80004a24:	242080e7          	jalr	578(ra) # 80000c62 <acquire>
  if(writable){
    80004a28:	02090d63          	beqz	s2,80004a62 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a2c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a30:	21848513          	addi	a0,s1,536
    80004a34:	ffffe097          	auipc	ra,0xffffe
    80004a38:	996080e7          	jalr	-1642(ra) # 800023ca <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a3c:	2204b783          	ld	a5,544(s1)
    80004a40:	eb95                	bnez	a5,80004a74 <pipeclose+0x64>
    release(&pi->lock);
    80004a42:	8526                	mv	a0,s1
    80004a44:	ffffc097          	auipc	ra,0xffffc
    80004a48:	2d2080e7          	jalr	722(ra) # 80000d16 <release>
    kfree((char*)pi);
    80004a4c:	8526                	mv	a0,s1
    80004a4e:	ffffc097          	auipc	ra,0xffffc
    80004a52:	fd6080e7          	jalr	-42(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004a56:	60e2                	ld	ra,24(sp)
    80004a58:	6442                	ld	s0,16(sp)
    80004a5a:	64a2                	ld	s1,8(sp)
    80004a5c:	6902                	ld	s2,0(sp)
    80004a5e:	6105                	addi	sp,sp,32
    80004a60:	8082                	ret
    pi->readopen = 0;
    80004a62:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a66:	21c48513          	addi	a0,s1,540
    80004a6a:	ffffe097          	auipc	ra,0xffffe
    80004a6e:	960080e7          	jalr	-1696(ra) # 800023ca <wakeup>
    80004a72:	b7e9                	j	80004a3c <pipeclose+0x2c>
    release(&pi->lock);
    80004a74:	8526                	mv	a0,s1
    80004a76:	ffffc097          	auipc	ra,0xffffc
    80004a7a:	2a0080e7          	jalr	672(ra) # 80000d16 <release>
}
    80004a7e:	bfe1                	j	80004a56 <pipeclose+0x46>

0000000080004a80 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a80:	7119                	addi	sp,sp,-128
    80004a82:	fc86                	sd	ra,120(sp)
    80004a84:	f8a2                	sd	s0,112(sp)
    80004a86:	f4a6                	sd	s1,104(sp)
    80004a88:	f0ca                	sd	s2,96(sp)
    80004a8a:	ecce                	sd	s3,88(sp)
    80004a8c:	e8d2                	sd	s4,80(sp)
    80004a8e:	e4d6                	sd	s5,72(sp)
    80004a90:	e0da                	sd	s6,64(sp)
    80004a92:	fc5e                	sd	s7,56(sp)
    80004a94:	f862                	sd	s8,48(sp)
    80004a96:	f466                	sd	s9,40(sp)
    80004a98:	f06a                	sd	s10,32(sp)
    80004a9a:	ec6e                	sd	s11,24(sp)
    80004a9c:	0100                	addi	s0,sp,128
    80004a9e:	84aa                	mv	s1,a0
    80004aa0:	8cae                	mv	s9,a1
    80004aa2:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004aa4:	ffffd097          	auipc	ra,0xffffd
    80004aa8:	f8c080e7          	jalr	-116(ra) # 80001a30 <myproc>
    80004aac:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004aae:	8526                	mv	a0,s1
    80004ab0:	ffffc097          	auipc	ra,0xffffc
    80004ab4:	1b2080e7          	jalr	434(ra) # 80000c62 <acquire>
  for(i = 0; i < n; i++){
    80004ab8:	0d605963          	blez	s6,80004b8a <pipewrite+0x10a>
    80004abc:	89a6                	mv	s3,s1
    80004abe:	3b7d                	addiw	s6,s6,-1
    80004ac0:	1b02                	slli	s6,s6,0x20
    80004ac2:	020b5b13          	srli	s6,s6,0x20
    80004ac6:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004ac8:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004acc:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ad0:	5dfd                	li	s11,-1
    80004ad2:	000b8d1b          	sext.w	s10,s7
    80004ad6:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004ad8:	2184a783          	lw	a5,536(s1)
    80004adc:	21c4a703          	lw	a4,540(s1)
    80004ae0:	2007879b          	addiw	a5,a5,512
    80004ae4:	02f71b63          	bne	a4,a5,80004b1a <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004ae8:	2204a783          	lw	a5,544(s1)
    80004aec:	cbad                	beqz	a5,80004b5e <pipewrite+0xde>
    80004aee:	03092783          	lw	a5,48(s2)
    80004af2:	e7b5                	bnez	a5,80004b5e <pipewrite+0xde>
      wakeup(&pi->nread);
    80004af4:	8556                	mv	a0,s5
    80004af6:	ffffe097          	auipc	ra,0xffffe
    80004afa:	8d4080e7          	jalr	-1836(ra) # 800023ca <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004afe:	85ce                	mv	a1,s3
    80004b00:	8552                	mv	a0,s4
    80004b02:	ffffd097          	auipc	ra,0xffffd
    80004b06:	742080e7          	jalr	1858(ra) # 80002244 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b0a:	2184a783          	lw	a5,536(s1)
    80004b0e:	21c4a703          	lw	a4,540(s1)
    80004b12:	2007879b          	addiw	a5,a5,512
    80004b16:	fcf709e3          	beq	a4,a5,80004ae8 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b1a:	4685                	li	a3,1
    80004b1c:	019b8633          	add	a2,s7,s9
    80004b20:	f8f40593          	addi	a1,s0,-113
    80004b24:	05093503          	ld	a0,80(s2)
    80004b28:	ffffd097          	auipc	ra,0xffffd
    80004b2c:	c88080e7          	jalr	-888(ra) # 800017b0 <copyin>
    80004b30:	05b50e63          	beq	a0,s11,80004b8c <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b34:	21c4a783          	lw	a5,540(s1)
    80004b38:	0017871b          	addiw	a4,a5,1
    80004b3c:	20e4ae23          	sw	a4,540(s1)
    80004b40:	1ff7f793          	andi	a5,a5,511
    80004b44:	97a6                	add	a5,a5,s1
    80004b46:	f8f44703          	lbu	a4,-113(s0)
    80004b4a:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004b4e:	001d0c1b          	addiw	s8,s10,1
    80004b52:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004b56:	036b8b63          	beq	s7,s6,80004b8c <pipewrite+0x10c>
    80004b5a:	8bbe                	mv	s7,a5
    80004b5c:	bf9d                	j	80004ad2 <pipewrite+0x52>
        release(&pi->lock);
    80004b5e:	8526                	mv	a0,s1
    80004b60:	ffffc097          	auipc	ra,0xffffc
    80004b64:	1b6080e7          	jalr	438(ra) # 80000d16 <release>
        return -1;
    80004b68:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004b6a:	8562                	mv	a0,s8
    80004b6c:	70e6                	ld	ra,120(sp)
    80004b6e:	7446                	ld	s0,112(sp)
    80004b70:	74a6                	ld	s1,104(sp)
    80004b72:	7906                	ld	s2,96(sp)
    80004b74:	69e6                	ld	s3,88(sp)
    80004b76:	6a46                	ld	s4,80(sp)
    80004b78:	6aa6                	ld	s5,72(sp)
    80004b7a:	6b06                	ld	s6,64(sp)
    80004b7c:	7be2                	ld	s7,56(sp)
    80004b7e:	7c42                	ld	s8,48(sp)
    80004b80:	7ca2                	ld	s9,40(sp)
    80004b82:	7d02                	ld	s10,32(sp)
    80004b84:	6de2                	ld	s11,24(sp)
    80004b86:	6109                	addi	sp,sp,128
    80004b88:	8082                	ret
  for(i = 0; i < n; i++){
    80004b8a:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004b8c:	21848513          	addi	a0,s1,536
    80004b90:	ffffe097          	auipc	ra,0xffffe
    80004b94:	83a080e7          	jalr	-1990(ra) # 800023ca <wakeup>
  release(&pi->lock);
    80004b98:	8526                	mv	a0,s1
    80004b9a:	ffffc097          	auipc	ra,0xffffc
    80004b9e:	17c080e7          	jalr	380(ra) # 80000d16 <release>
  return i;
    80004ba2:	b7e1                	j	80004b6a <pipewrite+0xea>

0000000080004ba4 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ba4:	715d                	addi	sp,sp,-80
    80004ba6:	e486                	sd	ra,72(sp)
    80004ba8:	e0a2                	sd	s0,64(sp)
    80004baa:	fc26                	sd	s1,56(sp)
    80004bac:	f84a                	sd	s2,48(sp)
    80004bae:	f44e                	sd	s3,40(sp)
    80004bb0:	f052                	sd	s4,32(sp)
    80004bb2:	ec56                	sd	s5,24(sp)
    80004bb4:	e85a                	sd	s6,16(sp)
    80004bb6:	0880                	addi	s0,sp,80
    80004bb8:	84aa                	mv	s1,a0
    80004bba:	892e                	mv	s2,a1
    80004bbc:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bbe:	ffffd097          	auipc	ra,0xffffd
    80004bc2:	e72080e7          	jalr	-398(ra) # 80001a30 <myproc>
    80004bc6:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bc8:	8b26                	mv	s6,s1
    80004bca:	8526                	mv	a0,s1
    80004bcc:	ffffc097          	auipc	ra,0xffffc
    80004bd0:	096080e7          	jalr	150(ra) # 80000c62 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bd4:	2184a703          	lw	a4,536(s1)
    80004bd8:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bdc:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004be0:	02f71463          	bne	a4,a5,80004c08 <piperead+0x64>
    80004be4:	2244a783          	lw	a5,548(s1)
    80004be8:	c385                	beqz	a5,80004c08 <piperead+0x64>
    if(pr->killed){
    80004bea:	030a2783          	lw	a5,48(s4)
    80004bee:	ebc1                	bnez	a5,80004c7e <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bf0:	85da                	mv	a1,s6
    80004bf2:	854e                	mv	a0,s3
    80004bf4:	ffffd097          	auipc	ra,0xffffd
    80004bf8:	650080e7          	jalr	1616(ra) # 80002244 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bfc:	2184a703          	lw	a4,536(s1)
    80004c00:	21c4a783          	lw	a5,540(s1)
    80004c04:	fef700e3          	beq	a4,a5,80004be4 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c08:	09505263          	blez	s5,80004c8c <piperead+0xe8>
    80004c0c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c0e:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c10:	2184a783          	lw	a5,536(s1)
    80004c14:	21c4a703          	lw	a4,540(s1)
    80004c18:	02f70d63          	beq	a4,a5,80004c52 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c1c:	0017871b          	addiw	a4,a5,1
    80004c20:	20e4ac23          	sw	a4,536(s1)
    80004c24:	1ff7f793          	andi	a5,a5,511
    80004c28:	97a6                	add	a5,a5,s1
    80004c2a:	0187c783          	lbu	a5,24(a5)
    80004c2e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c32:	4685                	li	a3,1
    80004c34:	fbf40613          	addi	a2,s0,-65
    80004c38:	85ca                	mv	a1,s2
    80004c3a:	050a3503          	ld	a0,80(s4)
    80004c3e:	ffffd097          	auipc	ra,0xffffd
    80004c42:	ae6080e7          	jalr	-1306(ra) # 80001724 <copyout>
    80004c46:	01650663          	beq	a0,s6,80004c52 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c4a:	2985                	addiw	s3,s3,1
    80004c4c:	0905                	addi	s2,s2,1
    80004c4e:	fd3a91e3          	bne	s5,s3,80004c10 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c52:	21c48513          	addi	a0,s1,540
    80004c56:	ffffd097          	auipc	ra,0xffffd
    80004c5a:	774080e7          	jalr	1908(ra) # 800023ca <wakeup>
  release(&pi->lock);
    80004c5e:	8526                	mv	a0,s1
    80004c60:	ffffc097          	auipc	ra,0xffffc
    80004c64:	0b6080e7          	jalr	182(ra) # 80000d16 <release>
  return i;
}
    80004c68:	854e                	mv	a0,s3
    80004c6a:	60a6                	ld	ra,72(sp)
    80004c6c:	6406                	ld	s0,64(sp)
    80004c6e:	74e2                	ld	s1,56(sp)
    80004c70:	7942                	ld	s2,48(sp)
    80004c72:	79a2                	ld	s3,40(sp)
    80004c74:	7a02                	ld	s4,32(sp)
    80004c76:	6ae2                	ld	s5,24(sp)
    80004c78:	6b42                	ld	s6,16(sp)
    80004c7a:	6161                	addi	sp,sp,80
    80004c7c:	8082                	ret
      release(&pi->lock);
    80004c7e:	8526                	mv	a0,s1
    80004c80:	ffffc097          	auipc	ra,0xffffc
    80004c84:	096080e7          	jalr	150(ra) # 80000d16 <release>
      return -1;
    80004c88:	59fd                	li	s3,-1
    80004c8a:	bff9                	j	80004c68 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c8c:	4981                	li	s3,0
    80004c8e:	b7d1                	j	80004c52 <piperead+0xae>

0000000080004c90 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c90:	df010113          	addi	sp,sp,-528
    80004c94:	20113423          	sd	ra,520(sp)
    80004c98:	20813023          	sd	s0,512(sp)
    80004c9c:	ffa6                	sd	s1,504(sp)
    80004c9e:	fbca                	sd	s2,496(sp)
    80004ca0:	f7ce                	sd	s3,488(sp)
    80004ca2:	f3d2                	sd	s4,480(sp)
    80004ca4:	efd6                	sd	s5,472(sp)
    80004ca6:	ebda                	sd	s6,464(sp)
    80004ca8:	e7de                	sd	s7,456(sp)
    80004caa:	e3e2                	sd	s8,448(sp)
    80004cac:	ff66                	sd	s9,440(sp)
    80004cae:	fb6a                	sd	s10,432(sp)
    80004cb0:	f76e                	sd	s11,424(sp)
    80004cb2:	0c00                	addi	s0,sp,528
    80004cb4:	84aa                	mv	s1,a0
    80004cb6:	dea43c23          	sd	a0,-520(s0)
    80004cba:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cbe:	ffffd097          	auipc	ra,0xffffd
    80004cc2:	d72080e7          	jalr	-654(ra) # 80001a30 <myproc>
    80004cc6:	892a                	mv	s2,a0

  begin_op();
    80004cc8:	fffff097          	auipc	ra,0xfffff
    80004ccc:	446080e7          	jalr	1094(ra) # 8000410e <begin_op>

  if((ip = namei(path)) == 0){
    80004cd0:	8526                	mv	a0,s1
    80004cd2:	fffff097          	auipc	ra,0xfffff
    80004cd6:	230080e7          	jalr	560(ra) # 80003f02 <namei>
    80004cda:	c92d                	beqz	a0,80004d4c <exec+0xbc>
    80004cdc:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cde:	fffff097          	auipc	ra,0xfffff
    80004ce2:	a74080e7          	jalr	-1420(ra) # 80003752 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ce6:	04000713          	li	a4,64
    80004cea:	4681                	li	a3,0
    80004cec:	e4840613          	addi	a2,s0,-440
    80004cf0:	4581                	li	a1,0
    80004cf2:	8526                	mv	a0,s1
    80004cf4:	fffff097          	auipc	ra,0xfffff
    80004cf8:	d12080e7          	jalr	-750(ra) # 80003a06 <readi>
    80004cfc:	04000793          	li	a5,64
    80004d00:	00f51a63          	bne	a0,a5,80004d14 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d04:	e4842703          	lw	a4,-440(s0)
    80004d08:	464c47b7          	lui	a5,0x464c4
    80004d0c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d10:	04f70463          	beq	a4,a5,80004d58 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d14:	8526                	mv	a0,s1
    80004d16:	fffff097          	auipc	ra,0xfffff
    80004d1a:	c9e080e7          	jalr	-866(ra) # 800039b4 <iunlockput>
    end_op();
    80004d1e:	fffff097          	auipc	ra,0xfffff
    80004d22:	470080e7          	jalr	1136(ra) # 8000418e <end_op>
  }
  return -1;
    80004d26:	557d                	li	a0,-1
}
    80004d28:	20813083          	ld	ra,520(sp)
    80004d2c:	20013403          	ld	s0,512(sp)
    80004d30:	74fe                	ld	s1,504(sp)
    80004d32:	795e                	ld	s2,496(sp)
    80004d34:	79be                	ld	s3,488(sp)
    80004d36:	7a1e                	ld	s4,480(sp)
    80004d38:	6afe                	ld	s5,472(sp)
    80004d3a:	6b5e                	ld	s6,464(sp)
    80004d3c:	6bbe                	ld	s7,456(sp)
    80004d3e:	6c1e                	ld	s8,448(sp)
    80004d40:	7cfa                	ld	s9,440(sp)
    80004d42:	7d5a                	ld	s10,432(sp)
    80004d44:	7dba                	ld	s11,424(sp)
    80004d46:	21010113          	addi	sp,sp,528
    80004d4a:	8082                	ret
    end_op();
    80004d4c:	fffff097          	auipc	ra,0xfffff
    80004d50:	442080e7          	jalr	1090(ra) # 8000418e <end_op>
    return -1;
    80004d54:	557d                	li	a0,-1
    80004d56:	bfc9                	j	80004d28 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d58:	854a                	mv	a0,s2
    80004d5a:	ffffd097          	auipc	ra,0xffffd
    80004d5e:	d9a080e7          	jalr	-614(ra) # 80001af4 <proc_pagetable>
    80004d62:	8baa                	mv	s7,a0
    80004d64:	d945                	beqz	a0,80004d14 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d66:	e6842983          	lw	s3,-408(s0)
    80004d6a:	e8045783          	lhu	a5,-384(s0)
    80004d6e:	c7ad                	beqz	a5,80004dd8 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d70:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d72:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004d74:	6c85                	lui	s9,0x1
    80004d76:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d7a:	def43823          	sd	a5,-528(s0)
    80004d7e:	a42d                	j	80004fa8 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d80:	00004517          	auipc	a0,0x4
    80004d84:	ad050513          	addi	a0,a0,-1328 # 80008850 <syscalls_name+0x298>
    80004d88:	ffffb097          	auipc	ra,0xffffb
    80004d8c:	7c0080e7          	jalr	1984(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d90:	8756                	mv	a4,s5
    80004d92:	012d86bb          	addw	a3,s11,s2
    80004d96:	4581                	li	a1,0
    80004d98:	8526                	mv	a0,s1
    80004d9a:	fffff097          	auipc	ra,0xfffff
    80004d9e:	c6c080e7          	jalr	-916(ra) # 80003a06 <readi>
    80004da2:	2501                	sext.w	a0,a0
    80004da4:	1aaa9963          	bne	s5,a0,80004f56 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004da8:	6785                	lui	a5,0x1
    80004daa:	0127893b          	addw	s2,a5,s2
    80004dae:	77fd                	lui	a5,0xfffff
    80004db0:	01478a3b          	addw	s4,a5,s4
    80004db4:	1f897163          	bgeu	s2,s8,80004f96 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004db8:	02091593          	slli	a1,s2,0x20
    80004dbc:	9181                	srli	a1,a1,0x20
    80004dbe:	95ea                	add	a1,a1,s10
    80004dc0:	855e                	mv	a0,s7
    80004dc2:	ffffc097          	auipc	ra,0xffffc
    80004dc6:	32e080e7          	jalr	814(ra) # 800010f0 <walkaddr>
    80004dca:	862a                	mv	a2,a0
    if(pa == 0)
    80004dcc:	d955                	beqz	a0,80004d80 <exec+0xf0>
      n = PGSIZE;
    80004dce:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004dd0:	fd9a70e3          	bgeu	s4,s9,80004d90 <exec+0x100>
      n = sz - i;
    80004dd4:	8ad2                	mv	s5,s4
    80004dd6:	bf6d                	j	80004d90 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004dd8:	4901                	li	s2,0
  iunlockput(ip);
    80004dda:	8526                	mv	a0,s1
    80004ddc:	fffff097          	auipc	ra,0xfffff
    80004de0:	bd8080e7          	jalr	-1064(ra) # 800039b4 <iunlockput>
  end_op();
    80004de4:	fffff097          	auipc	ra,0xfffff
    80004de8:	3aa080e7          	jalr	938(ra) # 8000418e <end_op>
  p = myproc();
    80004dec:	ffffd097          	auipc	ra,0xffffd
    80004df0:	c44080e7          	jalr	-956(ra) # 80001a30 <myproc>
    80004df4:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004df6:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004dfa:	6785                	lui	a5,0x1
    80004dfc:	17fd                	addi	a5,a5,-1
    80004dfe:	993e                	add	s2,s2,a5
    80004e00:	757d                	lui	a0,0xfffff
    80004e02:	00a977b3          	and	a5,s2,a0
    80004e06:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e0a:	6609                	lui	a2,0x2
    80004e0c:	963e                	add	a2,a2,a5
    80004e0e:	85be                	mv	a1,a5
    80004e10:	855e                	mv	a0,s7
    80004e12:	ffffc097          	auipc	ra,0xffffc
    80004e16:	6c2080e7          	jalr	1730(ra) # 800014d4 <uvmalloc>
    80004e1a:	8b2a                	mv	s6,a0
  ip = 0;
    80004e1c:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e1e:	12050c63          	beqz	a0,80004f56 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e22:	75f9                	lui	a1,0xffffe
    80004e24:	95aa                	add	a1,a1,a0
    80004e26:	855e                	mv	a0,s7
    80004e28:	ffffd097          	auipc	ra,0xffffd
    80004e2c:	8ca080e7          	jalr	-1846(ra) # 800016f2 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e30:	7c7d                	lui	s8,0xfffff
    80004e32:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e34:	e0043783          	ld	a5,-512(s0)
    80004e38:	6388                	ld	a0,0(a5)
    80004e3a:	c535                	beqz	a0,80004ea6 <exec+0x216>
    80004e3c:	e8840993          	addi	s3,s0,-376
    80004e40:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004e44:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e46:	ffffc097          	auipc	ra,0xffffc
    80004e4a:	0a0080e7          	jalr	160(ra) # 80000ee6 <strlen>
    80004e4e:	2505                	addiw	a0,a0,1
    80004e50:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e54:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e58:	13896363          	bltu	s2,s8,80004f7e <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e5c:	e0043d83          	ld	s11,-512(s0)
    80004e60:	000dba03          	ld	s4,0(s11)
    80004e64:	8552                	mv	a0,s4
    80004e66:	ffffc097          	auipc	ra,0xffffc
    80004e6a:	080080e7          	jalr	128(ra) # 80000ee6 <strlen>
    80004e6e:	0015069b          	addiw	a3,a0,1
    80004e72:	8652                	mv	a2,s4
    80004e74:	85ca                	mv	a1,s2
    80004e76:	855e                	mv	a0,s7
    80004e78:	ffffd097          	auipc	ra,0xffffd
    80004e7c:	8ac080e7          	jalr	-1876(ra) # 80001724 <copyout>
    80004e80:	10054363          	bltz	a0,80004f86 <exec+0x2f6>
    ustack[argc] = sp;
    80004e84:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e88:	0485                	addi	s1,s1,1
    80004e8a:	008d8793          	addi	a5,s11,8
    80004e8e:	e0f43023          	sd	a5,-512(s0)
    80004e92:	008db503          	ld	a0,8(s11)
    80004e96:	c911                	beqz	a0,80004eaa <exec+0x21a>
    if(argc >= MAXARG)
    80004e98:	09a1                	addi	s3,s3,8
    80004e9a:	fb3c96e3          	bne	s9,s3,80004e46 <exec+0x1b6>
  sz = sz1;
    80004e9e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ea2:	4481                	li	s1,0
    80004ea4:	a84d                	j	80004f56 <exec+0x2c6>
  sp = sz;
    80004ea6:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ea8:	4481                	li	s1,0
  ustack[argc] = 0;
    80004eaa:	00349793          	slli	a5,s1,0x3
    80004eae:	f9040713          	addi	a4,s0,-112
    80004eb2:	97ba                	add	a5,a5,a4
    80004eb4:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004eb8:	00148693          	addi	a3,s1,1
    80004ebc:	068e                	slli	a3,a3,0x3
    80004ebe:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ec2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ec6:	01897663          	bgeu	s2,s8,80004ed2 <exec+0x242>
  sz = sz1;
    80004eca:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ece:	4481                	li	s1,0
    80004ed0:	a059                	j	80004f56 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ed2:	e8840613          	addi	a2,s0,-376
    80004ed6:	85ca                	mv	a1,s2
    80004ed8:	855e                	mv	a0,s7
    80004eda:	ffffd097          	auipc	ra,0xffffd
    80004ede:	84a080e7          	jalr	-1974(ra) # 80001724 <copyout>
    80004ee2:	0a054663          	bltz	a0,80004f8e <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004ee6:	058ab783          	ld	a5,88(s5)
    80004eea:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004eee:	df843783          	ld	a5,-520(s0)
    80004ef2:	0007c703          	lbu	a4,0(a5)
    80004ef6:	cf11                	beqz	a4,80004f12 <exec+0x282>
    80004ef8:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004efa:	02f00693          	li	a3,47
    80004efe:	a029                	j	80004f08 <exec+0x278>
  for(last=s=path; *s; s++)
    80004f00:	0785                	addi	a5,a5,1
    80004f02:	fff7c703          	lbu	a4,-1(a5)
    80004f06:	c711                	beqz	a4,80004f12 <exec+0x282>
    if(*s == '/')
    80004f08:	fed71ce3          	bne	a4,a3,80004f00 <exec+0x270>
      last = s+1;
    80004f0c:	def43c23          	sd	a5,-520(s0)
    80004f10:	bfc5                	j	80004f00 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f12:	4641                	li	a2,16
    80004f14:	df843583          	ld	a1,-520(s0)
    80004f18:	158a8513          	addi	a0,s5,344
    80004f1c:	ffffc097          	auipc	ra,0xffffc
    80004f20:	f98080e7          	jalr	-104(ra) # 80000eb4 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f24:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f28:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f2c:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f30:	058ab783          	ld	a5,88(s5)
    80004f34:	e6043703          	ld	a4,-416(s0)
    80004f38:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f3a:	058ab783          	ld	a5,88(s5)
    80004f3e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f42:	85ea                	mv	a1,s10
    80004f44:	ffffd097          	auipc	ra,0xffffd
    80004f48:	c4c080e7          	jalr	-948(ra) # 80001b90 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f4c:	0004851b          	sext.w	a0,s1
    80004f50:	bbe1                	j	80004d28 <exec+0x98>
    80004f52:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f56:	e0843583          	ld	a1,-504(s0)
    80004f5a:	855e                	mv	a0,s7
    80004f5c:	ffffd097          	auipc	ra,0xffffd
    80004f60:	c34080e7          	jalr	-972(ra) # 80001b90 <proc_freepagetable>
  if(ip){
    80004f64:	da0498e3          	bnez	s1,80004d14 <exec+0x84>
  return -1;
    80004f68:	557d                	li	a0,-1
    80004f6a:	bb7d                	j	80004d28 <exec+0x98>
    80004f6c:	e1243423          	sd	s2,-504(s0)
    80004f70:	b7dd                	j	80004f56 <exec+0x2c6>
    80004f72:	e1243423          	sd	s2,-504(s0)
    80004f76:	b7c5                	j	80004f56 <exec+0x2c6>
    80004f78:	e1243423          	sd	s2,-504(s0)
    80004f7c:	bfe9                	j	80004f56 <exec+0x2c6>
  sz = sz1;
    80004f7e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f82:	4481                	li	s1,0
    80004f84:	bfc9                	j	80004f56 <exec+0x2c6>
  sz = sz1;
    80004f86:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f8a:	4481                	li	s1,0
    80004f8c:	b7e9                	j	80004f56 <exec+0x2c6>
  sz = sz1;
    80004f8e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f92:	4481                	li	s1,0
    80004f94:	b7c9                	j	80004f56 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f96:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f9a:	2b05                	addiw	s6,s6,1
    80004f9c:	0389899b          	addiw	s3,s3,56
    80004fa0:	e8045783          	lhu	a5,-384(s0)
    80004fa4:	e2fb5be3          	bge	s6,a5,80004dda <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fa8:	2981                	sext.w	s3,s3
    80004faa:	03800713          	li	a4,56
    80004fae:	86ce                	mv	a3,s3
    80004fb0:	e1040613          	addi	a2,s0,-496
    80004fb4:	4581                	li	a1,0
    80004fb6:	8526                	mv	a0,s1
    80004fb8:	fffff097          	auipc	ra,0xfffff
    80004fbc:	a4e080e7          	jalr	-1458(ra) # 80003a06 <readi>
    80004fc0:	03800793          	li	a5,56
    80004fc4:	f8f517e3          	bne	a0,a5,80004f52 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004fc8:	e1042783          	lw	a5,-496(s0)
    80004fcc:	4705                	li	a4,1
    80004fce:	fce796e3          	bne	a5,a4,80004f9a <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004fd2:	e3843603          	ld	a2,-456(s0)
    80004fd6:	e3043783          	ld	a5,-464(s0)
    80004fda:	f8f669e3          	bltu	a2,a5,80004f6c <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fde:	e2043783          	ld	a5,-480(s0)
    80004fe2:	963e                	add	a2,a2,a5
    80004fe4:	f8f667e3          	bltu	a2,a5,80004f72 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fe8:	85ca                	mv	a1,s2
    80004fea:	855e                	mv	a0,s7
    80004fec:	ffffc097          	auipc	ra,0xffffc
    80004ff0:	4e8080e7          	jalr	1256(ra) # 800014d4 <uvmalloc>
    80004ff4:	e0a43423          	sd	a0,-504(s0)
    80004ff8:	d141                	beqz	a0,80004f78 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80004ffa:	e2043d03          	ld	s10,-480(s0)
    80004ffe:	df043783          	ld	a5,-528(s0)
    80005002:	00fd77b3          	and	a5,s10,a5
    80005006:	fba1                	bnez	a5,80004f56 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005008:	e1842d83          	lw	s11,-488(s0)
    8000500c:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005010:	f80c03e3          	beqz	s8,80004f96 <exec+0x306>
    80005014:	8a62                	mv	s4,s8
    80005016:	4901                	li	s2,0
    80005018:	b345                	j	80004db8 <exec+0x128>

000000008000501a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000501a:	7179                	addi	sp,sp,-48
    8000501c:	f406                	sd	ra,40(sp)
    8000501e:	f022                	sd	s0,32(sp)
    80005020:	ec26                	sd	s1,24(sp)
    80005022:	e84a                	sd	s2,16(sp)
    80005024:	1800                	addi	s0,sp,48
    80005026:	892e                	mv	s2,a1
    80005028:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000502a:	fdc40593          	addi	a1,s0,-36
    8000502e:	ffffe097          	auipc	ra,0xffffe
    80005032:	afa080e7          	jalr	-1286(ra) # 80002b28 <argint>
    80005036:	04054063          	bltz	a0,80005076 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000503a:	fdc42703          	lw	a4,-36(s0)
    8000503e:	47bd                	li	a5,15
    80005040:	02e7ed63          	bltu	a5,a4,8000507a <argfd+0x60>
    80005044:	ffffd097          	auipc	ra,0xffffd
    80005048:	9ec080e7          	jalr	-1556(ra) # 80001a30 <myproc>
    8000504c:	fdc42703          	lw	a4,-36(s0)
    80005050:	01a70793          	addi	a5,a4,26
    80005054:	078e                	slli	a5,a5,0x3
    80005056:	953e                	add	a0,a0,a5
    80005058:	611c                	ld	a5,0(a0)
    8000505a:	c395                	beqz	a5,8000507e <argfd+0x64>
    return -1;
  if(pfd)
    8000505c:	00090463          	beqz	s2,80005064 <argfd+0x4a>
    *pfd = fd;
    80005060:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005064:	4501                	li	a0,0
  if(pf)
    80005066:	c091                	beqz	s1,8000506a <argfd+0x50>
    *pf = f;
    80005068:	e09c                	sd	a5,0(s1)
}
    8000506a:	70a2                	ld	ra,40(sp)
    8000506c:	7402                	ld	s0,32(sp)
    8000506e:	64e2                	ld	s1,24(sp)
    80005070:	6942                	ld	s2,16(sp)
    80005072:	6145                	addi	sp,sp,48
    80005074:	8082                	ret
    return -1;
    80005076:	557d                	li	a0,-1
    80005078:	bfcd                	j	8000506a <argfd+0x50>
    return -1;
    8000507a:	557d                	li	a0,-1
    8000507c:	b7fd                	j	8000506a <argfd+0x50>
    8000507e:	557d                	li	a0,-1
    80005080:	b7ed                	j	8000506a <argfd+0x50>

0000000080005082 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005082:	1101                	addi	sp,sp,-32
    80005084:	ec06                	sd	ra,24(sp)
    80005086:	e822                	sd	s0,16(sp)
    80005088:	e426                	sd	s1,8(sp)
    8000508a:	1000                	addi	s0,sp,32
    8000508c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000508e:	ffffd097          	auipc	ra,0xffffd
    80005092:	9a2080e7          	jalr	-1630(ra) # 80001a30 <myproc>
    80005096:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005098:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    8000509c:	4501                	li	a0,0
    8000509e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050a0:	6398                	ld	a4,0(a5)
    800050a2:	cb19                	beqz	a4,800050b8 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050a4:	2505                	addiw	a0,a0,1
    800050a6:	07a1                	addi	a5,a5,8
    800050a8:	fed51ce3          	bne	a0,a3,800050a0 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050ac:	557d                	li	a0,-1
}
    800050ae:	60e2                	ld	ra,24(sp)
    800050b0:	6442                	ld	s0,16(sp)
    800050b2:	64a2                	ld	s1,8(sp)
    800050b4:	6105                	addi	sp,sp,32
    800050b6:	8082                	ret
      p->ofile[fd] = f;
    800050b8:	01a50793          	addi	a5,a0,26
    800050bc:	078e                	slli	a5,a5,0x3
    800050be:	963e                	add	a2,a2,a5
    800050c0:	e204                	sd	s1,0(a2)
      return fd;
    800050c2:	b7f5                	j	800050ae <fdalloc+0x2c>

00000000800050c4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050c4:	715d                	addi	sp,sp,-80
    800050c6:	e486                	sd	ra,72(sp)
    800050c8:	e0a2                	sd	s0,64(sp)
    800050ca:	fc26                	sd	s1,56(sp)
    800050cc:	f84a                	sd	s2,48(sp)
    800050ce:	f44e                	sd	s3,40(sp)
    800050d0:	f052                	sd	s4,32(sp)
    800050d2:	ec56                	sd	s5,24(sp)
    800050d4:	0880                	addi	s0,sp,80
    800050d6:	89ae                	mv	s3,a1
    800050d8:	8ab2                	mv	s5,a2
    800050da:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050dc:	fb040593          	addi	a1,s0,-80
    800050e0:	fffff097          	auipc	ra,0xfffff
    800050e4:	e40080e7          	jalr	-448(ra) # 80003f20 <nameiparent>
    800050e8:	892a                	mv	s2,a0
    800050ea:	12050f63          	beqz	a0,80005228 <create+0x164>
    return 0;

  ilock(dp);
    800050ee:	ffffe097          	auipc	ra,0xffffe
    800050f2:	664080e7          	jalr	1636(ra) # 80003752 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050f6:	4601                	li	a2,0
    800050f8:	fb040593          	addi	a1,s0,-80
    800050fc:	854a                	mv	a0,s2
    800050fe:	fffff097          	auipc	ra,0xfffff
    80005102:	b32080e7          	jalr	-1230(ra) # 80003c30 <dirlookup>
    80005106:	84aa                	mv	s1,a0
    80005108:	c921                	beqz	a0,80005158 <create+0x94>
    iunlockput(dp);
    8000510a:	854a                	mv	a0,s2
    8000510c:	fffff097          	auipc	ra,0xfffff
    80005110:	8a8080e7          	jalr	-1880(ra) # 800039b4 <iunlockput>
    ilock(ip);
    80005114:	8526                	mv	a0,s1
    80005116:	ffffe097          	auipc	ra,0xffffe
    8000511a:	63c080e7          	jalr	1596(ra) # 80003752 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000511e:	2981                	sext.w	s3,s3
    80005120:	4789                	li	a5,2
    80005122:	02f99463          	bne	s3,a5,8000514a <create+0x86>
    80005126:	0444d783          	lhu	a5,68(s1)
    8000512a:	37f9                	addiw	a5,a5,-2
    8000512c:	17c2                	slli	a5,a5,0x30
    8000512e:	93c1                	srli	a5,a5,0x30
    80005130:	4705                	li	a4,1
    80005132:	00f76c63          	bltu	a4,a5,8000514a <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005136:	8526                	mv	a0,s1
    80005138:	60a6                	ld	ra,72(sp)
    8000513a:	6406                	ld	s0,64(sp)
    8000513c:	74e2                	ld	s1,56(sp)
    8000513e:	7942                	ld	s2,48(sp)
    80005140:	79a2                	ld	s3,40(sp)
    80005142:	7a02                	ld	s4,32(sp)
    80005144:	6ae2                	ld	s5,24(sp)
    80005146:	6161                	addi	sp,sp,80
    80005148:	8082                	ret
    iunlockput(ip);
    8000514a:	8526                	mv	a0,s1
    8000514c:	fffff097          	auipc	ra,0xfffff
    80005150:	868080e7          	jalr	-1944(ra) # 800039b4 <iunlockput>
    return 0;
    80005154:	4481                	li	s1,0
    80005156:	b7c5                	j	80005136 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005158:	85ce                	mv	a1,s3
    8000515a:	00092503          	lw	a0,0(s2)
    8000515e:	ffffe097          	auipc	ra,0xffffe
    80005162:	45c080e7          	jalr	1116(ra) # 800035ba <ialloc>
    80005166:	84aa                	mv	s1,a0
    80005168:	c529                	beqz	a0,800051b2 <create+0xee>
  ilock(ip);
    8000516a:	ffffe097          	auipc	ra,0xffffe
    8000516e:	5e8080e7          	jalr	1512(ra) # 80003752 <ilock>
  ip->major = major;
    80005172:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005176:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000517a:	4785                	li	a5,1
    8000517c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005180:	8526                	mv	a0,s1
    80005182:	ffffe097          	auipc	ra,0xffffe
    80005186:	506080e7          	jalr	1286(ra) # 80003688 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000518a:	2981                	sext.w	s3,s3
    8000518c:	4785                	li	a5,1
    8000518e:	02f98a63          	beq	s3,a5,800051c2 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005192:	40d0                	lw	a2,4(s1)
    80005194:	fb040593          	addi	a1,s0,-80
    80005198:	854a                	mv	a0,s2
    8000519a:	fffff097          	auipc	ra,0xfffff
    8000519e:	ca6080e7          	jalr	-858(ra) # 80003e40 <dirlink>
    800051a2:	06054b63          	bltz	a0,80005218 <create+0x154>
  iunlockput(dp);
    800051a6:	854a                	mv	a0,s2
    800051a8:	fffff097          	auipc	ra,0xfffff
    800051ac:	80c080e7          	jalr	-2036(ra) # 800039b4 <iunlockput>
  return ip;
    800051b0:	b759                	j	80005136 <create+0x72>
    panic("create: ialloc");
    800051b2:	00003517          	auipc	a0,0x3
    800051b6:	6be50513          	addi	a0,a0,1726 # 80008870 <syscalls_name+0x2b8>
    800051ba:	ffffb097          	auipc	ra,0xffffb
    800051be:	38e080e7          	jalr	910(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    800051c2:	04a95783          	lhu	a5,74(s2)
    800051c6:	2785                	addiw	a5,a5,1
    800051c8:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051cc:	854a                	mv	a0,s2
    800051ce:	ffffe097          	auipc	ra,0xffffe
    800051d2:	4ba080e7          	jalr	1210(ra) # 80003688 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051d6:	40d0                	lw	a2,4(s1)
    800051d8:	00003597          	auipc	a1,0x3
    800051dc:	6a858593          	addi	a1,a1,1704 # 80008880 <syscalls_name+0x2c8>
    800051e0:	8526                	mv	a0,s1
    800051e2:	fffff097          	auipc	ra,0xfffff
    800051e6:	c5e080e7          	jalr	-930(ra) # 80003e40 <dirlink>
    800051ea:	00054f63          	bltz	a0,80005208 <create+0x144>
    800051ee:	00492603          	lw	a2,4(s2)
    800051f2:	00003597          	auipc	a1,0x3
    800051f6:	69658593          	addi	a1,a1,1686 # 80008888 <syscalls_name+0x2d0>
    800051fa:	8526                	mv	a0,s1
    800051fc:	fffff097          	auipc	ra,0xfffff
    80005200:	c44080e7          	jalr	-956(ra) # 80003e40 <dirlink>
    80005204:	f80557e3          	bgez	a0,80005192 <create+0xce>
      panic("create dots");
    80005208:	00003517          	auipc	a0,0x3
    8000520c:	68850513          	addi	a0,a0,1672 # 80008890 <syscalls_name+0x2d8>
    80005210:	ffffb097          	auipc	ra,0xffffb
    80005214:	338080e7          	jalr	824(ra) # 80000548 <panic>
    panic("create: dirlink");
    80005218:	00003517          	auipc	a0,0x3
    8000521c:	68850513          	addi	a0,a0,1672 # 800088a0 <syscalls_name+0x2e8>
    80005220:	ffffb097          	auipc	ra,0xffffb
    80005224:	328080e7          	jalr	808(ra) # 80000548 <panic>
    return 0;
    80005228:	84aa                	mv	s1,a0
    8000522a:	b731                	j	80005136 <create+0x72>

000000008000522c <sys_dup>:
{
    8000522c:	7179                	addi	sp,sp,-48
    8000522e:	f406                	sd	ra,40(sp)
    80005230:	f022                	sd	s0,32(sp)
    80005232:	ec26                	sd	s1,24(sp)
    80005234:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005236:	fd840613          	addi	a2,s0,-40
    8000523a:	4581                	li	a1,0
    8000523c:	4501                	li	a0,0
    8000523e:	00000097          	auipc	ra,0x0
    80005242:	ddc080e7          	jalr	-548(ra) # 8000501a <argfd>
    return -1;
    80005246:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005248:	02054363          	bltz	a0,8000526e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000524c:	fd843503          	ld	a0,-40(s0)
    80005250:	00000097          	auipc	ra,0x0
    80005254:	e32080e7          	jalr	-462(ra) # 80005082 <fdalloc>
    80005258:	84aa                	mv	s1,a0
    return -1;
    8000525a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000525c:	00054963          	bltz	a0,8000526e <sys_dup+0x42>
  filedup(f);
    80005260:	fd843503          	ld	a0,-40(s0)
    80005264:	fffff097          	auipc	ra,0xfffff
    80005268:	32a080e7          	jalr	810(ra) # 8000458e <filedup>
  return fd;
    8000526c:	87a6                	mv	a5,s1
}
    8000526e:	853e                	mv	a0,a5
    80005270:	70a2                	ld	ra,40(sp)
    80005272:	7402                	ld	s0,32(sp)
    80005274:	64e2                	ld	s1,24(sp)
    80005276:	6145                	addi	sp,sp,48
    80005278:	8082                	ret

000000008000527a <sys_read>:
{
    8000527a:	7179                	addi	sp,sp,-48
    8000527c:	f406                	sd	ra,40(sp)
    8000527e:	f022                	sd	s0,32(sp)
    80005280:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005282:	fe840613          	addi	a2,s0,-24
    80005286:	4581                	li	a1,0
    80005288:	4501                	li	a0,0
    8000528a:	00000097          	auipc	ra,0x0
    8000528e:	d90080e7          	jalr	-624(ra) # 8000501a <argfd>
    return -1;
    80005292:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005294:	04054163          	bltz	a0,800052d6 <sys_read+0x5c>
    80005298:	fe440593          	addi	a1,s0,-28
    8000529c:	4509                	li	a0,2
    8000529e:	ffffe097          	auipc	ra,0xffffe
    800052a2:	88a080e7          	jalr	-1910(ra) # 80002b28 <argint>
    return -1;
    800052a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052a8:	02054763          	bltz	a0,800052d6 <sys_read+0x5c>
    800052ac:	fd840593          	addi	a1,s0,-40
    800052b0:	4505                	li	a0,1
    800052b2:	ffffe097          	auipc	ra,0xffffe
    800052b6:	898080e7          	jalr	-1896(ra) # 80002b4a <argaddr>
    return -1;
    800052ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052bc:	00054d63          	bltz	a0,800052d6 <sys_read+0x5c>
  return fileread(f, p, n);
    800052c0:	fe442603          	lw	a2,-28(s0)
    800052c4:	fd843583          	ld	a1,-40(s0)
    800052c8:	fe843503          	ld	a0,-24(s0)
    800052cc:	fffff097          	auipc	ra,0xfffff
    800052d0:	44e080e7          	jalr	1102(ra) # 8000471a <fileread>
    800052d4:	87aa                	mv	a5,a0
}
    800052d6:	853e                	mv	a0,a5
    800052d8:	70a2                	ld	ra,40(sp)
    800052da:	7402                	ld	s0,32(sp)
    800052dc:	6145                	addi	sp,sp,48
    800052de:	8082                	ret

00000000800052e0 <sys_write>:
{
    800052e0:	7179                	addi	sp,sp,-48
    800052e2:	f406                	sd	ra,40(sp)
    800052e4:	f022                	sd	s0,32(sp)
    800052e6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e8:	fe840613          	addi	a2,s0,-24
    800052ec:	4581                	li	a1,0
    800052ee:	4501                	li	a0,0
    800052f0:	00000097          	auipc	ra,0x0
    800052f4:	d2a080e7          	jalr	-726(ra) # 8000501a <argfd>
    return -1;
    800052f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052fa:	04054163          	bltz	a0,8000533c <sys_write+0x5c>
    800052fe:	fe440593          	addi	a1,s0,-28
    80005302:	4509                	li	a0,2
    80005304:	ffffe097          	auipc	ra,0xffffe
    80005308:	824080e7          	jalr	-2012(ra) # 80002b28 <argint>
    return -1;
    8000530c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000530e:	02054763          	bltz	a0,8000533c <sys_write+0x5c>
    80005312:	fd840593          	addi	a1,s0,-40
    80005316:	4505                	li	a0,1
    80005318:	ffffe097          	auipc	ra,0xffffe
    8000531c:	832080e7          	jalr	-1998(ra) # 80002b4a <argaddr>
    return -1;
    80005320:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005322:	00054d63          	bltz	a0,8000533c <sys_write+0x5c>
  return filewrite(f, p, n);
    80005326:	fe442603          	lw	a2,-28(s0)
    8000532a:	fd843583          	ld	a1,-40(s0)
    8000532e:	fe843503          	ld	a0,-24(s0)
    80005332:	fffff097          	auipc	ra,0xfffff
    80005336:	4aa080e7          	jalr	1194(ra) # 800047dc <filewrite>
    8000533a:	87aa                	mv	a5,a0
}
    8000533c:	853e                	mv	a0,a5
    8000533e:	70a2                	ld	ra,40(sp)
    80005340:	7402                	ld	s0,32(sp)
    80005342:	6145                	addi	sp,sp,48
    80005344:	8082                	ret

0000000080005346 <sys_close>:
{
    80005346:	1101                	addi	sp,sp,-32
    80005348:	ec06                	sd	ra,24(sp)
    8000534a:	e822                	sd	s0,16(sp)
    8000534c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000534e:	fe040613          	addi	a2,s0,-32
    80005352:	fec40593          	addi	a1,s0,-20
    80005356:	4501                	li	a0,0
    80005358:	00000097          	auipc	ra,0x0
    8000535c:	cc2080e7          	jalr	-830(ra) # 8000501a <argfd>
    return -1;
    80005360:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005362:	02054463          	bltz	a0,8000538a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005366:	ffffc097          	auipc	ra,0xffffc
    8000536a:	6ca080e7          	jalr	1738(ra) # 80001a30 <myproc>
    8000536e:	fec42783          	lw	a5,-20(s0)
    80005372:	07e9                	addi	a5,a5,26
    80005374:	078e                	slli	a5,a5,0x3
    80005376:	97aa                	add	a5,a5,a0
    80005378:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000537c:	fe043503          	ld	a0,-32(s0)
    80005380:	fffff097          	auipc	ra,0xfffff
    80005384:	260080e7          	jalr	608(ra) # 800045e0 <fileclose>
  return 0;
    80005388:	4781                	li	a5,0
}
    8000538a:	853e                	mv	a0,a5
    8000538c:	60e2                	ld	ra,24(sp)
    8000538e:	6442                	ld	s0,16(sp)
    80005390:	6105                	addi	sp,sp,32
    80005392:	8082                	ret

0000000080005394 <sys_fstat>:
{
    80005394:	1101                	addi	sp,sp,-32
    80005396:	ec06                	sd	ra,24(sp)
    80005398:	e822                	sd	s0,16(sp)
    8000539a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000539c:	fe840613          	addi	a2,s0,-24
    800053a0:	4581                	li	a1,0
    800053a2:	4501                	li	a0,0
    800053a4:	00000097          	auipc	ra,0x0
    800053a8:	c76080e7          	jalr	-906(ra) # 8000501a <argfd>
    return -1;
    800053ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053ae:	02054563          	bltz	a0,800053d8 <sys_fstat+0x44>
    800053b2:	fe040593          	addi	a1,s0,-32
    800053b6:	4505                	li	a0,1
    800053b8:	ffffd097          	auipc	ra,0xffffd
    800053bc:	792080e7          	jalr	1938(ra) # 80002b4a <argaddr>
    return -1;
    800053c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053c2:	00054b63          	bltz	a0,800053d8 <sys_fstat+0x44>
  return filestat(f, st);
    800053c6:	fe043583          	ld	a1,-32(s0)
    800053ca:	fe843503          	ld	a0,-24(s0)
    800053ce:	fffff097          	auipc	ra,0xfffff
    800053d2:	2da080e7          	jalr	730(ra) # 800046a8 <filestat>
    800053d6:	87aa                	mv	a5,a0
}
    800053d8:	853e                	mv	a0,a5
    800053da:	60e2                	ld	ra,24(sp)
    800053dc:	6442                	ld	s0,16(sp)
    800053de:	6105                	addi	sp,sp,32
    800053e0:	8082                	ret

00000000800053e2 <sys_link>:
{
    800053e2:	7169                	addi	sp,sp,-304
    800053e4:	f606                	sd	ra,296(sp)
    800053e6:	f222                	sd	s0,288(sp)
    800053e8:	ee26                	sd	s1,280(sp)
    800053ea:	ea4a                	sd	s2,272(sp)
    800053ec:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053ee:	08000613          	li	a2,128
    800053f2:	ed040593          	addi	a1,s0,-304
    800053f6:	4501                	li	a0,0
    800053f8:	ffffd097          	auipc	ra,0xffffd
    800053fc:	774080e7          	jalr	1908(ra) # 80002b6c <argstr>
    return -1;
    80005400:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005402:	10054e63          	bltz	a0,8000551e <sys_link+0x13c>
    80005406:	08000613          	li	a2,128
    8000540a:	f5040593          	addi	a1,s0,-176
    8000540e:	4505                	li	a0,1
    80005410:	ffffd097          	auipc	ra,0xffffd
    80005414:	75c080e7          	jalr	1884(ra) # 80002b6c <argstr>
    return -1;
    80005418:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000541a:	10054263          	bltz	a0,8000551e <sys_link+0x13c>
  begin_op();
    8000541e:	fffff097          	auipc	ra,0xfffff
    80005422:	cf0080e7          	jalr	-784(ra) # 8000410e <begin_op>
  if((ip = namei(old)) == 0){
    80005426:	ed040513          	addi	a0,s0,-304
    8000542a:	fffff097          	auipc	ra,0xfffff
    8000542e:	ad8080e7          	jalr	-1320(ra) # 80003f02 <namei>
    80005432:	84aa                	mv	s1,a0
    80005434:	c551                	beqz	a0,800054c0 <sys_link+0xde>
  ilock(ip);
    80005436:	ffffe097          	auipc	ra,0xffffe
    8000543a:	31c080e7          	jalr	796(ra) # 80003752 <ilock>
  if(ip->type == T_DIR){
    8000543e:	04449703          	lh	a4,68(s1)
    80005442:	4785                	li	a5,1
    80005444:	08f70463          	beq	a4,a5,800054cc <sys_link+0xea>
  ip->nlink++;
    80005448:	04a4d783          	lhu	a5,74(s1)
    8000544c:	2785                	addiw	a5,a5,1
    8000544e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005452:	8526                	mv	a0,s1
    80005454:	ffffe097          	auipc	ra,0xffffe
    80005458:	234080e7          	jalr	564(ra) # 80003688 <iupdate>
  iunlock(ip);
    8000545c:	8526                	mv	a0,s1
    8000545e:	ffffe097          	auipc	ra,0xffffe
    80005462:	3b6080e7          	jalr	950(ra) # 80003814 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005466:	fd040593          	addi	a1,s0,-48
    8000546a:	f5040513          	addi	a0,s0,-176
    8000546e:	fffff097          	auipc	ra,0xfffff
    80005472:	ab2080e7          	jalr	-1358(ra) # 80003f20 <nameiparent>
    80005476:	892a                	mv	s2,a0
    80005478:	c935                	beqz	a0,800054ec <sys_link+0x10a>
  ilock(dp);
    8000547a:	ffffe097          	auipc	ra,0xffffe
    8000547e:	2d8080e7          	jalr	728(ra) # 80003752 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005482:	00092703          	lw	a4,0(s2)
    80005486:	409c                	lw	a5,0(s1)
    80005488:	04f71d63          	bne	a4,a5,800054e2 <sys_link+0x100>
    8000548c:	40d0                	lw	a2,4(s1)
    8000548e:	fd040593          	addi	a1,s0,-48
    80005492:	854a                	mv	a0,s2
    80005494:	fffff097          	auipc	ra,0xfffff
    80005498:	9ac080e7          	jalr	-1620(ra) # 80003e40 <dirlink>
    8000549c:	04054363          	bltz	a0,800054e2 <sys_link+0x100>
  iunlockput(dp);
    800054a0:	854a                	mv	a0,s2
    800054a2:	ffffe097          	auipc	ra,0xffffe
    800054a6:	512080e7          	jalr	1298(ra) # 800039b4 <iunlockput>
  iput(ip);
    800054aa:	8526                	mv	a0,s1
    800054ac:	ffffe097          	auipc	ra,0xffffe
    800054b0:	460080e7          	jalr	1120(ra) # 8000390c <iput>
  end_op();
    800054b4:	fffff097          	auipc	ra,0xfffff
    800054b8:	cda080e7          	jalr	-806(ra) # 8000418e <end_op>
  return 0;
    800054bc:	4781                	li	a5,0
    800054be:	a085                	j	8000551e <sys_link+0x13c>
    end_op();
    800054c0:	fffff097          	auipc	ra,0xfffff
    800054c4:	cce080e7          	jalr	-818(ra) # 8000418e <end_op>
    return -1;
    800054c8:	57fd                	li	a5,-1
    800054ca:	a891                	j	8000551e <sys_link+0x13c>
    iunlockput(ip);
    800054cc:	8526                	mv	a0,s1
    800054ce:	ffffe097          	auipc	ra,0xffffe
    800054d2:	4e6080e7          	jalr	1254(ra) # 800039b4 <iunlockput>
    end_op();
    800054d6:	fffff097          	auipc	ra,0xfffff
    800054da:	cb8080e7          	jalr	-840(ra) # 8000418e <end_op>
    return -1;
    800054de:	57fd                	li	a5,-1
    800054e0:	a83d                	j	8000551e <sys_link+0x13c>
    iunlockput(dp);
    800054e2:	854a                	mv	a0,s2
    800054e4:	ffffe097          	auipc	ra,0xffffe
    800054e8:	4d0080e7          	jalr	1232(ra) # 800039b4 <iunlockput>
  ilock(ip);
    800054ec:	8526                	mv	a0,s1
    800054ee:	ffffe097          	auipc	ra,0xffffe
    800054f2:	264080e7          	jalr	612(ra) # 80003752 <ilock>
  ip->nlink--;
    800054f6:	04a4d783          	lhu	a5,74(s1)
    800054fa:	37fd                	addiw	a5,a5,-1
    800054fc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005500:	8526                	mv	a0,s1
    80005502:	ffffe097          	auipc	ra,0xffffe
    80005506:	186080e7          	jalr	390(ra) # 80003688 <iupdate>
  iunlockput(ip);
    8000550a:	8526                	mv	a0,s1
    8000550c:	ffffe097          	auipc	ra,0xffffe
    80005510:	4a8080e7          	jalr	1192(ra) # 800039b4 <iunlockput>
  end_op();
    80005514:	fffff097          	auipc	ra,0xfffff
    80005518:	c7a080e7          	jalr	-902(ra) # 8000418e <end_op>
  return -1;
    8000551c:	57fd                	li	a5,-1
}
    8000551e:	853e                	mv	a0,a5
    80005520:	70b2                	ld	ra,296(sp)
    80005522:	7412                	ld	s0,288(sp)
    80005524:	64f2                	ld	s1,280(sp)
    80005526:	6952                	ld	s2,272(sp)
    80005528:	6155                	addi	sp,sp,304
    8000552a:	8082                	ret

000000008000552c <sys_unlink>:
{
    8000552c:	7151                	addi	sp,sp,-240
    8000552e:	f586                	sd	ra,232(sp)
    80005530:	f1a2                	sd	s0,224(sp)
    80005532:	eda6                	sd	s1,216(sp)
    80005534:	e9ca                	sd	s2,208(sp)
    80005536:	e5ce                	sd	s3,200(sp)
    80005538:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000553a:	08000613          	li	a2,128
    8000553e:	f3040593          	addi	a1,s0,-208
    80005542:	4501                	li	a0,0
    80005544:	ffffd097          	auipc	ra,0xffffd
    80005548:	628080e7          	jalr	1576(ra) # 80002b6c <argstr>
    8000554c:	18054163          	bltz	a0,800056ce <sys_unlink+0x1a2>
  begin_op();
    80005550:	fffff097          	auipc	ra,0xfffff
    80005554:	bbe080e7          	jalr	-1090(ra) # 8000410e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005558:	fb040593          	addi	a1,s0,-80
    8000555c:	f3040513          	addi	a0,s0,-208
    80005560:	fffff097          	auipc	ra,0xfffff
    80005564:	9c0080e7          	jalr	-1600(ra) # 80003f20 <nameiparent>
    80005568:	84aa                	mv	s1,a0
    8000556a:	c979                	beqz	a0,80005640 <sys_unlink+0x114>
  ilock(dp);
    8000556c:	ffffe097          	auipc	ra,0xffffe
    80005570:	1e6080e7          	jalr	486(ra) # 80003752 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005574:	00003597          	auipc	a1,0x3
    80005578:	30c58593          	addi	a1,a1,780 # 80008880 <syscalls_name+0x2c8>
    8000557c:	fb040513          	addi	a0,s0,-80
    80005580:	ffffe097          	auipc	ra,0xffffe
    80005584:	696080e7          	jalr	1686(ra) # 80003c16 <namecmp>
    80005588:	14050a63          	beqz	a0,800056dc <sys_unlink+0x1b0>
    8000558c:	00003597          	auipc	a1,0x3
    80005590:	2fc58593          	addi	a1,a1,764 # 80008888 <syscalls_name+0x2d0>
    80005594:	fb040513          	addi	a0,s0,-80
    80005598:	ffffe097          	auipc	ra,0xffffe
    8000559c:	67e080e7          	jalr	1662(ra) # 80003c16 <namecmp>
    800055a0:	12050e63          	beqz	a0,800056dc <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055a4:	f2c40613          	addi	a2,s0,-212
    800055a8:	fb040593          	addi	a1,s0,-80
    800055ac:	8526                	mv	a0,s1
    800055ae:	ffffe097          	auipc	ra,0xffffe
    800055b2:	682080e7          	jalr	1666(ra) # 80003c30 <dirlookup>
    800055b6:	892a                	mv	s2,a0
    800055b8:	12050263          	beqz	a0,800056dc <sys_unlink+0x1b0>
  ilock(ip);
    800055bc:	ffffe097          	auipc	ra,0xffffe
    800055c0:	196080e7          	jalr	406(ra) # 80003752 <ilock>
  if(ip->nlink < 1)
    800055c4:	04a91783          	lh	a5,74(s2)
    800055c8:	08f05263          	blez	a5,8000564c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055cc:	04491703          	lh	a4,68(s2)
    800055d0:	4785                	li	a5,1
    800055d2:	08f70563          	beq	a4,a5,8000565c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055d6:	4641                	li	a2,16
    800055d8:	4581                	li	a1,0
    800055da:	fc040513          	addi	a0,s0,-64
    800055de:	ffffb097          	auipc	ra,0xffffb
    800055e2:	780080e7          	jalr	1920(ra) # 80000d5e <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055e6:	4741                	li	a4,16
    800055e8:	f2c42683          	lw	a3,-212(s0)
    800055ec:	fc040613          	addi	a2,s0,-64
    800055f0:	4581                	li	a1,0
    800055f2:	8526                	mv	a0,s1
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	508080e7          	jalr	1288(ra) # 80003afc <writei>
    800055fc:	47c1                	li	a5,16
    800055fe:	0af51563          	bne	a0,a5,800056a8 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005602:	04491703          	lh	a4,68(s2)
    80005606:	4785                	li	a5,1
    80005608:	0af70863          	beq	a4,a5,800056b8 <sys_unlink+0x18c>
  iunlockput(dp);
    8000560c:	8526                	mv	a0,s1
    8000560e:	ffffe097          	auipc	ra,0xffffe
    80005612:	3a6080e7          	jalr	934(ra) # 800039b4 <iunlockput>
  ip->nlink--;
    80005616:	04a95783          	lhu	a5,74(s2)
    8000561a:	37fd                	addiw	a5,a5,-1
    8000561c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005620:	854a                	mv	a0,s2
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	066080e7          	jalr	102(ra) # 80003688 <iupdate>
  iunlockput(ip);
    8000562a:	854a                	mv	a0,s2
    8000562c:	ffffe097          	auipc	ra,0xffffe
    80005630:	388080e7          	jalr	904(ra) # 800039b4 <iunlockput>
  end_op();
    80005634:	fffff097          	auipc	ra,0xfffff
    80005638:	b5a080e7          	jalr	-1190(ra) # 8000418e <end_op>
  return 0;
    8000563c:	4501                	li	a0,0
    8000563e:	a84d                	j	800056f0 <sys_unlink+0x1c4>
    end_op();
    80005640:	fffff097          	auipc	ra,0xfffff
    80005644:	b4e080e7          	jalr	-1202(ra) # 8000418e <end_op>
    return -1;
    80005648:	557d                	li	a0,-1
    8000564a:	a05d                	j	800056f0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000564c:	00003517          	auipc	a0,0x3
    80005650:	26450513          	addi	a0,a0,612 # 800088b0 <syscalls_name+0x2f8>
    80005654:	ffffb097          	auipc	ra,0xffffb
    80005658:	ef4080e7          	jalr	-268(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000565c:	04c92703          	lw	a4,76(s2)
    80005660:	02000793          	li	a5,32
    80005664:	f6e7f9e3          	bgeu	a5,a4,800055d6 <sys_unlink+0xaa>
    80005668:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000566c:	4741                	li	a4,16
    8000566e:	86ce                	mv	a3,s3
    80005670:	f1840613          	addi	a2,s0,-232
    80005674:	4581                	li	a1,0
    80005676:	854a                	mv	a0,s2
    80005678:	ffffe097          	auipc	ra,0xffffe
    8000567c:	38e080e7          	jalr	910(ra) # 80003a06 <readi>
    80005680:	47c1                	li	a5,16
    80005682:	00f51b63          	bne	a0,a5,80005698 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005686:	f1845783          	lhu	a5,-232(s0)
    8000568a:	e7a1                	bnez	a5,800056d2 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000568c:	29c1                	addiw	s3,s3,16
    8000568e:	04c92783          	lw	a5,76(s2)
    80005692:	fcf9ede3          	bltu	s3,a5,8000566c <sys_unlink+0x140>
    80005696:	b781                	j	800055d6 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005698:	00003517          	auipc	a0,0x3
    8000569c:	23050513          	addi	a0,a0,560 # 800088c8 <syscalls_name+0x310>
    800056a0:	ffffb097          	auipc	ra,0xffffb
    800056a4:	ea8080e7          	jalr	-344(ra) # 80000548 <panic>
    panic("unlink: writei");
    800056a8:	00003517          	auipc	a0,0x3
    800056ac:	23850513          	addi	a0,a0,568 # 800088e0 <syscalls_name+0x328>
    800056b0:	ffffb097          	auipc	ra,0xffffb
    800056b4:	e98080e7          	jalr	-360(ra) # 80000548 <panic>
    dp->nlink--;
    800056b8:	04a4d783          	lhu	a5,74(s1)
    800056bc:	37fd                	addiw	a5,a5,-1
    800056be:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056c2:	8526                	mv	a0,s1
    800056c4:	ffffe097          	auipc	ra,0xffffe
    800056c8:	fc4080e7          	jalr	-60(ra) # 80003688 <iupdate>
    800056cc:	b781                	j	8000560c <sys_unlink+0xe0>
    return -1;
    800056ce:	557d                	li	a0,-1
    800056d0:	a005                	j	800056f0 <sys_unlink+0x1c4>
    iunlockput(ip);
    800056d2:	854a                	mv	a0,s2
    800056d4:	ffffe097          	auipc	ra,0xffffe
    800056d8:	2e0080e7          	jalr	736(ra) # 800039b4 <iunlockput>
  iunlockput(dp);
    800056dc:	8526                	mv	a0,s1
    800056de:	ffffe097          	auipc	ra,0xffffe
    800056e2:	2d6080e7          	jalr	726(ra) # 800039b4 <iunlockput>
  end_op();
    800056e6:	fffff097          	auipc	ra,0xfffff
    800056ea:	aa8080e7          	jalr	-1368(ra) # 8000418e <end_op>
  return -1;
    800056ee:	557d                	li	a0,-1
}
    800056f0:	70ae                	ld	ra,232(sp)
    800056f2:	740e                	ld	s0,224(sp)
    800056f4:	64ee                	ld	s1,216(sp)
    800056f6:	694e                	ld	s2,208(sp)
    800056f8:	69ae                	ld	s3,200(sp)
    800056fa:	616d                	addi	sp,sp,240
    800056fc:	8082                	ret

00000000800056fe <sys_open>:

uint64
sys_open(void)
{
    800056fe:	7131                	addi	sp,sp,-192
    80005700:	fd06                	sd	ra,184(sp)
    80005702:	f922                	sd	s0,176(sp)
    80005704:	f526                	sd	s1,168(sp)
    80005706:	f14a                	sd	s2,160(sp)
    80005708:	ed4e                	sd	s3,152(sp)
    8000570a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000570c:	08000613          	li	a2,128
    80005710:	f5040593          	addi	a1,s0,-176
    80005714:	4501                	li	a0,0
    80005716:	ffffd097          	auipc	ra,0xffffd
    8000571a:	456080e7          	jalr	1110(ra) # 80002b6c <argstr>
    return -1;
    8000571e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005720:	0c054163          	bltz	a0,800057e2 <sys_open+0xe4>
    80005724:	f4c40593          	addi	a1,s0,-180
    80005728:	4505                	li	a0,1
    8000572a:	ffffd097          	auipc	ra,0xffffd
    8000572e:	3fe080e7          	jalr	1022(ra) # 80002b28 <argint>
    80005732:	0a054863          	bltz	a0,800057e2 <sys_open+0xe4>

  begin_op();
    80005736:	fffff097          	auipc	ra,0xfffff
    8000573a:	9d8080e7          	jalr	-1576(ra) # 8000410e <begin_op>

  if(omode & O_CREATE){
    8000573e:	f4c42783          	lw	a5,-180(s0)
    80005742:	2007f793          	andi	a5,a5,512
    80005746:	cbdd                	beqz	a5,800057fc <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005748:	4681                	li	a3,0
    8000574a:	4601                	li	a2,0
    8000574c:	4589                	li	a1,2
    8000574e:	f5040513          	addi	a0,s0,-176
    80005752:	00000097          	auipc	ra,0x0
    80005756:	972080e7          	jalr	-1678(ra) # 800050c4 <create>
    8000575a:	892a                	mv	s2,a0
    if(ip == 0){
    8000575c:	c959                	beqz	a0,800057f2 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000575e:	04491703          	lh	a4,68(s2)
    80005762:	478d                	li	a5,3
    80005764:	00f71763          	bne	a4,a5,80005772 <sys_open+0x74>
    80005768:	04695703          	lhu	a4,70(s2)
    8000576c:	47a5                	li	a5,9
    8000576e:	0ce7ec63          	bltu	a5,a4,80005846 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005772:	fffff097          	auipc	ra,0xfffff
    80005776:	db2080e7          	jalr	-590(ra) # 80004524 <filealloc>
    8000577a:	89aa                	mv	s3,a0
    8000577c:	10050263          	beqz	a0,80005880 <sys_open+0x182>
    80005780:	00000097          	auipc	ra,0x0
    80005784:	902080e7          	jalr	-1790(ra) # 80005082 <fdalloc>
    80005788:	84aa                	mv	s1,a0
    8000578a:	0e054663          	bltz	a0,80005876 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000578e:	04491703          	lh	a4,68(s2)
    80005792:	478d                	li	a5,3
    80005794:	0cf70463          	beq	a4,a5,8000585c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005798:	4789                	li	a5,2
    8000579a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000579e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057a2:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057a6:	f4c42783          	lw	a5,-180(s0)
    800057aa:	0017c713          	xori	a4,a5,1
    800057ae:	8b05                	andi	a4,a4,1
    800057b0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057b4:	0037f713          	andi	a4,a5,3
    800057b8:	00e03733          	snez	a4,a4
    800057bc:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057c0:	4007f793          	andi	a5,a5,1024
    800057c4:	c791                	beqz	a5,800057d0 <sys_open+0xd2>
    800057c6:	04491703          	lh	a4,68(s2)
    800057ca:	4789                	li	a5,2
    800057cc:	08f70f63          	beq	a4,a5,8000586a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057d0:	854a                	mv	a0,s2
    800057d2:	ffffe097          	auipc	ra,0xffffe
    800057d6:	042080e7          	jalr	66(ra) # 80003814 <iunlock>
  end_op();
    800057da:	fffff097          	auipc	ra,0xfffff
    800057de:	9b4080e7          	jalr	-1612(ra) # 8000418e <end_op>

  return fd;
}
    800057e2:	8526                	mv	a0,s1
    800057e4:	70ea                	ld	ra,184(sp)
    800057e6:	744a                	ld	s0,176(sp)
    800057e8:	74aa                	ld	s1,168(sp)
    800057ea:	790a                	ld	s2,160(sp)
    800057ec:	69ea                	ld	s3,152(sp)
    800057ee:	6129                	addi	sp,sp,192
    800057f0:	8082                	ret
      end_op();
    800057f2:	fffff097          	auipc	ra,0xfffff
    800057f6:	99c080e7          	jalr	-1636(ra) # 8000418e <end_op>
      return -1;
    800057fa:	b7e5                	j	800057e2 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800057fc:	f5040513          	addi	a0,s0,-176
    80005800:	ffffe097          	auipc	ra,0xffffe
    80005804:	702080e7          	jalr	1794(ra) # 80003f02 <namei>
    80005808:	892a                	mv	s2,a0
    8000580a:	c905                	beqz	a0,8000583a <sys_open+0x13c>
    ilock(ip);
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	f46080e7          	jalr	-186(ra) # 80003752 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005814:	04491703          	lh	a4,68(s2)
    80005818:	4785                	li	a5,1
    8000581a:	f4f712e3          	bne	a4,a5,8000575e <sys_open+0x60>
    8000581e:	f4c42783          	lw	a5,-180(s0)
    80005822:	dba1                	beqz	a5,80005772 <sys_open+0x74>
      iunlockput(ip);
    80005824:	854a                	mv	a0,s2
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	18e080e7          	jalr	398(ra) # 800039b4 <iunlockput>
      end_op();
    8000582e:	fffff097          	auipc	ra,0xfffff
    80005832:	960080e7          	jalr	-1696(ra) # 8000418e <end_op>
      return -1;
    80005836:	54fd                	li	s1,-1
    80005838:	b76d                	j	800057e2 <sys_open+0xe4>
      end_op();
    8000583a:	fffff097          	auipc	ra,0xfffff
    8000583e:	954080e7          	jalr	-1708(ra) # 8000418e <end_op>
      return -1;
    80005842:	54fd                	li	s1,-1
    80005844:	bf79                	j	800057e2 <sys_open+0xe4>
    iunlockput(ip);
    80005846:	854a                	mv	a0,s2
    80005848:	ffffe097          	auipc	ra,0xffffe
    8000584c:	16c080e7          	jalr	364(ra) # 800039b4 <iunlockput>
    end_op();
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	93e080e7          	jalr	-1730(ra) # 8000418e <end_op>
    return -1;
    80005858:	54fd                	li	s1,-1
    8000585a:	b761                	j	800057e2 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000585c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005860:	04691783          	lh	a5,70(s2)
    80005864:	02f99223          	sh	a5,36(s3)
    80005868:	bf2d                	j	800057a2 <sys_open+0xa4>
    itrunc(ip);
    8000586a:	854a                	mv	a0,s2
    8000586c:	ffffe097          	auipc	ra,0xffffe
    80005870:	ff4080e7          	jalr	-12(ra) # 80003860 <itrunc>
    80005874:	bfb1                	j	800057d0 <sys_open+0xd2>
      fileclose(f);
    80005876:	854e                	mv	a0,s3
    80005878:	fffff097          	auipc	ra,0xfffff
    8000587c:	d68080e7          	jalr	-664(ra) # 800045e0 <fileclose>
    iunlockput(ip);
    80005880:	854a                	mv	a0,s2
    80005882:	ffffe097          	auipc	ra,0xffffe
    80005886:	132080e7          	jalr	306(ra) # 800039b4 <iunlockput>
    end_op();
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	904080e7          	jalr	-1788(ra) # 8000418e <end_op>
    return -1;
    80005892:	54fd                	li	s1,-1
    80005894:	b7b9                	j	800057e2 <sys_open+0xe4>

0000000080005896 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005896:	7175                	addi	sp,sp,-144
    80005898:	e506                	sd	ra,136(sp)
    8000589a:	e122                	sd	s0,128(sp)
    8000589c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	870080e7          	jalr	-1936(ra) # 8000410e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058a6:	08000613          	li	a2,128
    800058aa:	f7040593          	addi	a1,s0,-144
    800058ae:	4501                	li	a0,0
    800058b0:	ffffd097          	auipc	ra,0xffffd
    800058b4:	2bc080e7          	jalr	700(ra) # 80002b6c <argstr>
    800058b8:	02054963          	bltz	a0,800058ea <sys_mkdir+0x54>
    800058bc:	4681                	li	a3,0
    800058be:	4601                	li	a2,0
    800058c0:	4585                	li	a1,1
    800058c2:	f7040513          	addi	a0,s0,-144
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	7fe080e7          	jalr	2046(ra) # 800050c4 <create>
    800058ce:	cd11                	beqz	a0,800058ea <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058d0:	ffffe097          	auipc	ra,0xffffe
    800058d4:	0e4080e7          	jalr	228(ra) # 800039b4 <iunlockput>
  end_op();
    800058d8:	fffff097          	auipc	ra,0xfffff
    800058dc:	8b6080e7          	jalr	-1866(ra) # 8000418e <end_op>
  return 0;
    800058e0:	4501                	li	a0,0
}
    800058e2:	60aa                	ld	ra,136(sp)
    800058e4:	640a                	ld	s0,128(sp)
    800058e6:	6149                	addi	sp,sp,144
    800058e8:	8082                	ret
    end_op();
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	8a4080e7          	jalr	-1884(ra) # 8000418e <end_op>
    return -1;
    800058f2:	557d                	li	a0,-1
    800058f4:	b7fd                	j	800058e2 <sys_mkdir+0x4c>

00000000800058f6 <sys_mknod>:

uint64
sys_mknod(void)
{
    800058f6:	7135                	addi	sp,sp,-160
    800058f8:	ed06                	sd	ra,152(sp)
    800058fa:	e922                	sd	s0,144(sp)
    800058fc:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058fe:	fffff097          	auipc	ra,0xfffff
    80005902:	810080e7          	jalr	-2032(ra) # 8000410e <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005906:	08000613          	li	a2,128
    8000590a:	f7040593          	addi	a1,s0,-144
    8000590e:	4501                	li	a0,0
    80005910:	ffffd097          	auipc	ra,0xffffd
    80005914:	25c080e7          	jalr	604(ra) # 80002b6c <argstr>
    80005918:	04054a63          	bltz	a0,8000596c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000591c:	f6c40593          	addi	a1,s0,-148
    80005920:	4505                	li	a0,1
    80005922:	ffffd097          	auipc	ra,0xffffd
    80005926:	206080e7          	jalr	518(ra) # 80002b28 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000592a:	04054163          	bltz	a0,8000596c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000592e:	f6840593          	addi	a1,s0,-152
    80005932:	4509                	li	a0,2
    80005934:	ffffd097          	auipc	ra,0xffffd
    80005938:	1f4080e7          	jalr	500(ra) # 80002b28 <argint>
     argint(1, &major) < 0 ||
    8000593c:	02054863          	bltz	a0,8000596c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005940:	f6841683          	lh	a3,-152(s0)
    80005944:	f6c41603          	lh	a2,-148(s0)
    80005948:	458d                	li	a1,3
    8000594a:	f7040513          	addi	a0,s0,-144
    8000594e:	fffff097          	auipc	ra,0xfffff
    80005952:	776080e7          	jalr	1910(ra) # 800050c4 <create>
     argint(2, &minor) < 0 ||
    80005956:	c919                	beqz	a0,8000596c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005958:	ffffe097          	auipc	ra,0xffffe
    8000595c:	05c080e7          	jalr	92(ra) # 800039b4 <iunlockput>
  end_op();
    80005960:	fffff097          	auipc	ra,0xfffff
    80005964:	82e080e7          	jalr	-2002(ra) # 8000418e <end_op>
  return 0;
    80005968:	4501                	li	a0,0
    8000596a:	a031                	j	80005976 <sys_mknod+0x80>
    end_op();
    8000596c:	fffff097          	auipc	ra,0xfffff
    80005970:	822080e7          	jalr	-2014(ra) # 8000418e <end_op>
    return -1;
    80005974:	557d                	li	a0,-1
}
    80005976:	60ea                	ld	ra,152(sp)
    80005978:	644a                	ld	s0,144(sp)
    8000597a:	610d                	addi	sp,sp,160
    8000597c:	8082                	ret

000000008000597e <sys_chdir>:

uint64
sys_chdir(void)
{
    8000597e:	7135                	addi	sp,sp,-160
    80005980:	ed06                	sd	ra,152(sp)
    80005982:	e922                	sd	s0,144(sp)
    80005984:	e526                	sd	s1,136(sp)
    80005986:	e14a                	sd	s2,128(sp)
    80005988:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000598a:	ffffc097          	auipc	ra,0xffffc
    8000598e:	0a6080e7          	jalr	166(ra) # 80001a30 <myproc>
    80005992:	892a                	mv	s2,a0
  
  begin_op();
    80005994:	ffffe097          	auipc	ra,0xffffe
    80005998:	77a080e7          	jalr	1914(ra) # 8000410e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000599c:	08000613          	li	a2,128
    800059a0:	f6040593          	addi	a1,s0,-160
    800059a4:	4501                	li	a0,0
    800059a6:	ffffd097          	auipc	ra,0xffffd
    800059aa:	1c6080e7          	jalr	454(ra) # 80002b6c <argstr>
    800059ae:	04054b63          	bltz	a0,80005a04 <sys_chdir+0x86>
    800059b2:	f6040513          	addi	a0,s0,-160
    800059b6:	ffffe097          	auipc	ra,0xffffe
    800059ba:	54c080e7          	jalr	1356(ra) # 80003f02 <namei>
    800059be:	84aa                	mv	s1,a0
    800059c0:	c131                	beqz	a0,80005a04 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	d90080e7          	jalr	-624(ra) # 80003752 <ilock>
  if(ip->type != T_DIR){
    800059ca:	04449703          	lh	a4,68(s1)
    800059ce:	4785                	li	a5,1
    800059d0:	04f71063          	bne	a4,a5,80005a10 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059d4:	8526                	mv	a0,s1
    800059d6:	ffffe097          	auipc	ra,0xffffe
    800059da:	e3e080e7          	jalr	-450(ra) # 80003814 <iunlock>
  iput(p->cwd);
    800059de:	15093503          	ld	a0,336(s2)
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	f2a080e7          	jalr	-214(ra) # 8000390c <iput>
  end_op();
    800059ea:	ffffe097          	auipc	ra,0xffffe
    800059ee:	7a4080e7          	jalr	1956(ra) # 8000418e <end_op>
  p->cwd = ip;
    800059f2:	14993823          	sd	s1,336(s2)
  return 0;
    800059f6:	4501                	li	a0,0
}
    800059f8:	60ea                	ld	ra,152(sp)
    800059fa:	644a                	ld	s0,144(sp)
    800059fc:	64aa                	ld	s1,136(sp)
    800059fe:	690a                	ld	s2,128(sp)
    80005a00:	610d                	addi	sp,sp,160
    80005a02:	8082                	ret
    end_op();
    80005a04:	ffffe097          	auipc	ra,0xffffe
    80005a08:	78a080e7          	jalr	1930(ra) # 8000418e <end_op>
    return -1;
    80005a0c:	557d                	li	a0,-1
    80005a0e:	b7ed                	j	800059f8 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a10:	8526                	mv	a0,s1
    80005a12:	ffffe097          	auipc	ra,0xffffe
    80005a16:	fa2080e7          	jalr	-94(ra) # 800039b4 <iunlockput>
    end_op();
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	774080e7          	jalr	1908(ra) # 8000418e <end_op>
    return -1;
    80005a22:	557d                	li	a0,-1
    80005a24:	bfd1                	j	800059f8 <sys_chdir+0x7a>

0000000080005a26 <sys_exec>:

uint64
sys_exec(void)
{
    80005a26:	7145                	addi	sp,sp,-464
    80005a28:	e786                	sd	ra,456(sp)
    80005a2a:	e3a2                	sd	s0,448(sp)
    80005a2c:	ff26                	sd	s1,440(sp)
    80005a2e:	fb4a                	sd	s2,432(sp)
    80005a30:	f74e                	sd	s3,424(sp)
    80005a32:	f352                	sd	s4,416(sp)
    80005a34:	ef56                	sd	s5,408(sp)
    80005a36:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a38:	08000613          	li	a2,128
    80005a3c:	f4040593          	addi	a1,s0,-192
    80005a40:	4501                	li	a0,0
    80005a42:	ffffd097          	auipc	ra,0xffffd
    80005a46:	12a080e7          	jalr	298(ra) # 80002b6c <argstr>
    return -1;
    80005a4a:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a4c:	0c054a63          	bltz	a0,80005b20 <sys_exec+0xfa>
    80005a50:	e3840593          	addi	a1,s0,-456
    80005a54:	4505                	li	a0,1
    80005a56:	ffffd097          	auipc	ra,0xffffd
    80005a5a:	0f4080e7          	jalr	244(ra) # 80002b4a <argaddr>
    80005a5e:	0c054163          	bltz	a0,80005b20 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a62:	10000613          	li	a2,256
    80005a66:	4581                	li	a1,0
    80005a68:	e4040513          	addi	a0,s0,-448
    80005a6c:	ffffb097          	auipc	ra,0xffffb
    80005a70:	2f2080e7          	jalr	754(ra) # 80000d5e <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a74:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a78:	89a6                	mv	s3,s1
    80005a7a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a7c:	02000a13          	li	s4,32
    80005a80:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a84:	00391513          	slli	a0,s2,0x3
    80005a88:	e3040593          	addi	a1,s0,-464
    80005a8c:	e3843783          	ld	a5,-456(s0)
    80005a90:	953e                	add	a0,a0,a5
    80005a92:	ffffd097          	auipc	ra,0xffffd
    80005a96:	ffc080e7          	jalr	-4(ra) # 80002a8e <fetchaddr>
    80005a9a:	02054a63          	bltz	a0,80005ace <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a9e:	e3043783          	ld	a5,-464(s0)
    80005aa2:	c3b9                	beqz	a5,80005ae8 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005aa4:	ffffb097          	auipc	ra,0xffffb
    80005aa8:	07c080e7          	jalr	124(ra) # 80000b20 <kalloc>
    80005aac:	85aa                	mv	a1,a0
    80005aae:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ab2:	cd11                	beqz	a0,80005ace <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ab4:	6605                	lui	a2,0x1
    80005ab6:	e3043503          	ld	a0,-464(s0)
    80005aba:	ffffd097          	auipc	ra,0xffffd
    80005abe:	026080e7          	jalr	38(ra) # 80002ae0 <fetchstr>
    80005ac2:	00054663          	bltz	a0,80005ace <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ac6:	0905                	addi	s2,s2,1
    80005ac8:	09a1                	addi	s3,s3,8
    80005aca:	fb491be3          	bne	s2,s4,80005a80 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ace:	10048913          	addi	s2,s1,256
    80005ad2:	6088                	ld	a0,0(s1)
    80005ad4:	c529                	beqz	a0,80005b1e <sys_exec+0xf8>
    kfree(argv[i]);
    80005ad6:	ffffb097          	auipc	ra,0xffffb
    80005ada:	f4e080e7          	jalr	-178(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ade:	04a1                	addi	s1,s1,8
    80005ae0:	ff2499e3          	bne	s1,s2,80005ad2 <sys_exec+0xac>
  return -1;
    80005ae4:	597d                	li	s2,-1
    80005ae6:	a82d                	j	80005b20 <sys_exec+0xfa>
      argv[i] = 0;
    80005ae8:	0a8e                	slli	s5,s5,0x3
    80005aea:	fc040793          	addi	a5,s0,-64
    80005aee:	9abe                	add	s5,s5,a5
    80005af0:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005af4:	e4040593          	addi	a1,s0,-448
    80005af8:	f4040513          	addi	a0,s0,-192
    80005afc:	fffff097          	auipc	ra,0xfffff
    80005b00:	194080e7          	jalr	404(ra) # 80004c90 <exec>
    80005b04:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b06:	10048993          	addi	s3,s1,256
    80005b0a:	6088                	ld	a0,0(s1)
    80005b0c:	c911                	beqz	a0,80005b20 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b0e:	ffffb097          	auipc	ra,0xffffb
    80005b12:	f16080e7          	jalr	-234(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b16:	04a1                	addi	s1,s1,8
    80005b18:	ff3499e3          	bne	s1,s3,80005b0a <sys_exec+0xe4>
    80005b1c:	a011                	j	80005b20 <sys_exec+0xfa>
  return -1;
    80005b1e:	597d                	li	s2,-1
}
    80005b20:	854a                	mv	a0,s2
    80005b22:	60be                	ld	ra,456(sp)
    80005b24:	641e                	ld	s0,448(sp)
    80005b26:	74fa                	ld	s1,440(sp)
    80005b28:	795a                	ld	s2,432(sp)
    80005b2a:	79ba                	ld	s3,424(sp)
    80005b2c:	7a1a                	ld	s4,416(sp)
    80005b2e:	6afa                	ld	s5,408(sp)
    80005b30:	6179                	addi	sp,sp,464
    80005b32:	8082                	ret

0000000080005b34 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b34:	7139                	addi	sp,sp,-64
    80005b36:	fc06                	sd	ra,56(sp)
    80005b38:	f822                	sd	s0,48(sp)
    80005b3a:	f426                	sd	s1,40(sp)
    80005b3c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b3e:	ffffc097          	auipc	ra,0xffffc
    80005b42:	ef2080e7          	jalr	-270(ra) # 80001a30 <myproc>
    80005b46:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b48:	fd840593          	addi	a1,s0,-40
    80005b4c:	4501                	li	a0,0
    80005b4e:	ffffd097          	auipc	ra,0xffffd
    80005b52:	ffc080e7          	jalr	-4(ra) # 80002b4a <argaddr>
    return -1;
    80005b56:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b58:	0e054063          	bltz	a0,80005c38 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b5c:	fc840593          	addi	a1,s0,-56
    80005b60:	fd040513          	addi	a0,s0,-48
    80005b64:	fffff097          	auipc	ra,0xfffff
    80005b68:	dd2080e7          	jalr	-558(ra) # 80004936 <pipealloc>
    return -1;
    80005b6c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b6e:	0c054563          	bltz	a0,80005c38 <sys_pipe+0x104>
  fd0 = -1;
    80005b72:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b76:	fd043503          	ld	a0,-48(s0)
    80005b7a:	fffff097          	auipc	ra,0xfffff
    80005b7e:	508080e7          	jalr	1288(ra) # 80005082 <fdalloc>
    80005b82:	fca42223          	sw	a0,-60(s0)
    80005b86:	08054c63          	bltz	a0,80005c1e <sys_pipe+0xea>
    80005b8a:	fc843503          	ld	a0,-56(s0)
    80005b8e:	fffff097          	auipc	ra,0xfffff
    80005b92:	4f4080e7          	jalr	1268(ra) # 80005082 <fdalloc>
    80005b96:	fca42023          	sw	a0,-64(s0)
    80005b9a:	06054863          	bltz	a0,80005c0a <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b9e:	4691                	li	a3,4
    80005ba0:	fc440613          	addi	a2,s0,-60
    80005ba4:	fd843583          	ld	a1,-40(s0)
    80005ba8:	68a8                	ld	a0,80(s1)
    80005baa:	ffffc097          	auipc	ra,0xffffc
    80005bae:	b7a080e7          	jalr	-1158(ra) # 80001724 <copyout>
    80005bb2:	02054063          	bltz	a0,80005bd2 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bb6:	4691                	li	a3,4
    80005bb8:	fc040613          	addi	a2,s0,-64
    80005bbc:	fd843583          	ld	a1,-40(s0)
    80005bc0:	0591                	addi	a1,a1,4
    80005bc2:	68a8                	ld	a0,80(s1)
    80005bc4:	ffffc097          	auipc	ra,0xffffc
    80005bc8:	b60080e7          	jalr	-1184(ra) # 80001724 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bcc:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bce:	06055563          	bgez	a0,80005c38 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005bd2:	fc442783          	lw	a5,-60(s0)
    80005bd6:	07e9                	addi	a5,a5,26
    80005bd8:	078e                	slli	a5,a5,0x3
    80005bda:	97a6                	add	a5,a5,s1
    80005bdc:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005be0:	fc042503          	lw	a0,-64(s0)
    80005be4:	0569                	addi	a0,a0,26
    80005be6:	050e                	slli	a0,a0,0x3
    80005be8:	9526                	add	a0,a0,s1
    80005bea:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005bee:	fd043503          	ld	a0,-48(s0)
    80005bf2:	fffff097          	auipc	ra,0xfffff
    80005bf6:	9ee080e7          	jalr	-1554(ra) # 800045e0 <fileclose>
    fileclose(wf);
    80005bfa:	fc843503          	ld	a0,-56(s0)
    80005bfe:	fffff097          	auipc	ra,0xfffff
    80005c02:	9e2080e7          	jalr	-1566(ra) # 800045e0 <fileclose>
    return -1;
    80005c06:	57fd                	li	a5,-1
    80005c08:	a805                	j	80005c38 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c0a:	fc442783          	lw	a5,-60(s0)
    80005c0e:	0007c863          	bltz	a5,80005c1e <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c12:	01a78513          	addi	a0,a5,26
    80005c16:	050e                	slli	a0,a0,0x3
    80005c18:	9526                	add	a0,a0,s1
    80005c1a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c1e:	fd043503          	ld	a0,-48(s0)
    80005c22:	fffff097          	auipc	ra,0xfffff
    80005c26:	9be080e7          	jalr	-1602(ra) # 800045e0 <fileclose>
    fileclose(wf);
    80005c2a:	fc843503          	ld	a0,-56(s0)
    80005c2e:	fffff097          	auipc	ra,0xfffff
    80005c32:	9b2080e7          	jalr	-1614(ra) # 800045e0 <fileclose>
    return -1;
    80005c36:	57fd                	li	a5,-1
}
    80005c38:	853e                	mv	a0,a5
    80005c3a:	70e2                	ld	ra,56(sp)
    80005c3c:	7442                	ld	s0,48(sp)
    80005c3e:	74a2                	ld	s1,40(sp)
    80005c40:	6121                	addi	sp,sp,64
    80005c42:	8082                	ret
	...

0000000080005c50 <kernelvec>:
    80005c50:	7111                	addi	sp,sp,-256
    80005c52:	e006                	sd	ra,0(sp)
    80005c54:	e40a                	sd	sp,8(sp)
    80005c56:	e80e                	sd	gp,16(sp)
    80005c58:	ec12                	sd	tp,24(sp)
    80005c5a:	f016                	sd	t0,32(sp)
    80005c5c:	f41a                	sd	t1,40(sp)
    80005c5e:	f81e                	sd	t2,48(sp)
    80005c60:	fc22                	sd	s0,56(sp)
    80005c62:	e0a6                	sd	s1,64(sp)
    80005c64:	e4aa                	sd	a0,72(sp)
    80005c66:	e8ae                	sd	a1,80(sp)
    80005c68:	ecb2                	sd	a2,88(sp)
    80005c6a:	f0b6                	sd	a3,96(sp)
    80005c6c:	f4ba                	sd	a4,104(sp)
    80005c6e:	f8be                	sd	a5,112(sp)
    80005c70:	fcc2                	sd	a6,120(sp)
    80005c72:	e146                	sd	a7,128(sp)
    80005c74:	e54a                	sd	s2,136(sp)
    80005c76:	e94e                	sd	s3,144(sp)
    80005c78:	ed52                	sd	s4,152(sp)
    80005c7a:	f156                	sd	s5,160(sp)
    80005c7c:	f55a                	sd	s6,168(sp)
    80005c7e:	f95e                	sd	s7,176(sp)
    80005c80:	fd62                	sd	s8,184(sp)
    80005c82:	e1e6                	sd	s9,192(sp)
    80005c84:	e5ea                	sd	s10,200(sp)
    80005c86:	e9ee                	sd	s11,208(sp)
    80005c88:	edf2                	sd	t3,216(sp)
    80005c8a:	f1f6                	sd	t4,224(sp)
    80005c8c:	f5fa                	sd	t5,232(sp)
    80005c8e:	f9fe                	sd	t6,240(sp)
    80005c90:	ccbfc0ef          	jal	ra,8000295a <kerneltrap>
    80005c94:	6082                	ld	ra,0(sp)
    80005c96:	6122                	ld	sp,8(sp)
    80005c98:	61c2                	ld	gp,16(sp)
    80005c9a:	7282                	ld	t0,32(sp)
    80005c9c:	7322                	ld	t1,40(sp)
    80005c9e:	73c2                	ld	t2,48(sp)
    80005ca0:	7462                	ld	s0,56(sp)
    80005ca2:	6486                	ld	s1,64(sp)
    80005ca4:	6526                	ld	a0,72(sp)
    80005ca6:	65c6                	ld	a1,80(sp)
    80005ca8:	6666                	ld	a2,88(sp)
    80005caa:	7686                	ld	a3,96(sp)
    80005cac:	7726                	ld	a4,104(sp)
    80005cae:	77c6                	ld	a5,112(sp)
    80005cb0:	7866                	ld	a6,120(sp)
    80005cb2:	688a                	ld	a7,128(sp)
    80005cb4:	692a                	ld	s2,136(sp)
    80005cb6:	69ca                	ld	s3,144(sp)
    80005cb8:	6a6a                	ld	s4,152(sp)
    80005cba:	7a8a                	ld	s5,160(sp)
    80005cbc:	7b2a                	ld	s6,168(sp)
    80005cbe:	7bca                	ld	s7,176(sp)
    80005cc0:	7c6a                	ld	s8,184(sp)
    80005cc2:	6c8e                	ld	s9,192(sp)
    80005cc4:	6d2e                	ld	s10,200(sp)
    80005cc6:	6dce                	ld	s11,208(sp)
    80005cc8:	6e6e                	ld	t3,216(sp)
    80005cca:	7e8e                	ld	t4,224(sp)
    80005ccc:	7f2e                	ld	t5,232(sp)
    80005cce:	7fce                	ld	t6,240(sp)
    80005cd0:	6111                	addi	sp,sp,256
    80005cd2:	10200073          	sret
    80005cd6:	00000013          	nop
    80005cda:	00000013          	nop
    80005cde:	0001                	nop

0000000080005ce0 <timervec>:
    80005ce0:	34051573          	csrrw	a0,mscratch,a0
    80005ce4:	e10c                	sd	a1,0(a0)
    80005ce6:	e510                	sd	a2,8(a0)
    80005ce8:	e914                	sd	a3,16(a0)
    80005cea:	710c                	ld	a1,32(a0)
    80005cec:	7510                	ld	a2,40(a0)
    80005cee:	6194                	ld	a3,0(a1)
    80005cf0:	96b2                	add	a3,a3,a2
    80005cf2:	e194                	sd	a3,0(a1)
    80005cf4:	4589                	li	a1,2
    80005cf6:	14459073          	csrw	sip,a1
    80005cfa:	6914                	ld	a3,16(a0)
    80005cfc:	6510                	ld	a2,8(a0)
    80005cfe:	610c                	ld	a1,0(a0)
    80005d00:	34051573          	csrrw	a0,mscratch,a0
    80005d04:	30200073          	mret
	...

0000000080005d0a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d0a:	1141                	addi	sp,sp,-16
    80005d0c:	e422                	sd	s0,8(sp)
    80005d0e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d10:	0c0007b7          	lui	a5,0xc000
    80005d14:	4705                	li	a4,1
    80005d16:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d18:	c3d8                	sw	a4,4(a5)
}
    80005d1a:	6422                	ld	s0,8(sp)
    80005d1c:	0141                	addi	sp,sp,16
    80005d1e:	8082                	ret

0000000080005d20 <plicinithart>:

void
plicinithart(void)
{
    80005d20:	1141                	addi	sp,sp,-16
    80005d22:	e406                	sd	ra,8(sp)
    80005d24:	e022                	sd	s0,0(sp)
    80005d26:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d28:	ffffc097          	auipc	ra,0xffffc
    80005d2c:	cdc080e7          	jalr	-804(ra) # 80001a04 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d30:	0085171b          	slliw	a4,a0,0x8
    80005d34:	0c0027b7          	lui	a5,0xc002
    80005d38:	97ba                	add	a5,a5,a4
    80005d3a:	40200713          	li	a4,1026
    80005d3e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d42:	00d5151b          	slliw	a0,a0,0xd
    80005d46:	0c2017b7          	lui	a5,0xc201
    80005d4a:	953e                	add	a0,a0,a5
    80005d4c:	00052023          	sw	zero,0(a0)
}
    80005d50:	60a2                	ld	ra,8(sp)
    80005d52:	6402                	ld	s0,0(sp)
    80005d54:	0141                	addi	sp,sp,16
    80005d56:	8082                	ret

0000000080005d58 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d58:	1141                	addi	sp,sp,-16
    80005d5a:	e406                	sd	ra,8(sp)
    80005d5c:	e022                	sd	s0,0(sp)
    80005d5e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d60:	ffffc097          	auipc	ra,0xffffc
    80005d64:	ca4080e7          	jalr	-860(ra) # 80001a04 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d68:	00d5179b          	slliw	a5,a0,0xd
    80005d6c:	0c201537          	lui	a0,0xc201
    80005d70:	953e                	add	a0,a0,a5
  return irq;
}
    80005d72:	4148                	lw	a0,4(a0)
    80005d74:	60a2                	ld	ra,8(sp)
    80005d76:	6402                	ld	s0,0(sp)
    80005d78:	0141                	addi	sp,sp,16
    80005d7a:	8082                	ret

0000000080005d7c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d7c:	1101                	addi	sp,sp,-32
    80005d7e:	ec06                	sd	ra,24(sp)
    80005d80:	e822                	sd	s0,16(sp)
    80005d82:	e426                	sd	s1,8(sp)
    80005d84:	1000                	addi	s0,sp,32
    80005d86:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d88:	ffffc097          	auipc	ra,0xffffc
    80005d8c:	c7c080e7          	jalr	-900(ra) # 80001a04 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d90:	00d5151b          	slliw	a0,a0,0xd
    80005d94:	0c2017b7          	lui	a5,0xc201
    80005d98:	97aa                	add	a5,a5,a0
    80005d9a:	c3c4                	sw	s1,4(a5)
}
    80005d9c:	60e2                	ld	ra,24(sp)
    80005d9e:	6442                	ld	s0,16(sp)
    80005da0:	64a2                	ld	s1,8(sp)
    80005da2:	6105                	addi	sp,sp,32
    80005da4:	8082                	ret

0000000080005da6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005da6:	1141                	addi	sp,sp,-16
    80005da8:	e406                	sd	ra,8(sp)
    80005daa:	e022                	sd	s0,0(sp)
    80005dac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dae:	479d                	li	a5,7
    80005db0:	04a7cc63          	blt	a5,a0,80005e08 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005db4:	0001d797          	auipc	a5,0x1d
    80005db8:	24c78793          	addi	a5,a5,588 # 80023000 <disk>
    80005dbc:	00a78733          	add	a4,a5,a0
    80005dc0:	6789                	lui	a5,0x2
    80005dc2:	97ba                	add	a5,a5,a4
    80005dc4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005dc8:	eba1                	bnez	a5,80005e18 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005dca:	00451713          	slli	a4,a0,0x4
    80005dce:	0001f797          	auipc	a5,0x1f
    80005dd2:	2327b783          	ld	a5,562(a5) # 80025000 <disk+0x2000>
    80005dd6:	97ba                	add	a5,a5,a4
    80005dd8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005ddc:	0001d797          	auipc	a5,0x1d
    80005de0:	22478793          	addi	a5,a5,548 # 80023000 <disk>
    80005de4:	97aa                	add	a5,a5,a0
    80005de6:	6509                	lui	a0,0x2
    80005de8:	953e                	add	a0,a0,a5
    80005dea:	4785                	li	a5,1
    80005dec:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005df0:	0001f517          	auipc	a0,0x1f
    80005df4:	22850513          	addi	a0,a0,552 # 80025018 <disk+0x2018>
    80005df8:	ffffc097          	auipc	ra,0xffffc
    80005dfc:	5d2080e7          	jalr	1490(ra) # 800023ca <wakeup>
}
    80005e00:	60a2                	ld	ra,8(sp)
    80005e02:	6402                	ld	s0,0(sp)
    80005e04:	0141                	addi	sp,sp,16
    80005e06:	8082                	ret
    panic("virtio_disk_intr 1");
    80005e08:	00003517          	auipc	a0,0x3
    80005e0c:	ae850513          	addi	a0,a0,-1304 # 800088f0 <syscalls_name+0x338>
    80005e10:	ffffa097          	auipc	ra,0xffffa
    80005e14:	738080e7          	jalr	1848(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005e18:	00003517          	auipc	a0,0x3
    80005e1c:	af050513          	addi	a0,a0,-1296 # 80008908 <syscalls_name+0x350>
    80005e20:	ffffa097          	auipc	ra,0xffffa
    80005e24:	728080e7          	jalr	1832(ra) # 80000548 <panic>

0000000080005e28 <virtio_disk_init>:
{
    80005e28:	1101                	addi	sp,sp,-32
    80005e2a:	ec06                	sd	ra,24(sp)
    80005e2c:	e822                	sd	s0,16(sp)
    80005e2e:	e426                	sd	s1,8(sp)
    80005e30:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e32:	00003597          	auipc	a1,0x3
    80005e36:	aee58593          	addi	a1,a1,-1298 # 80008920 <syscalls_name+0x368>
    80005e3a:	0001f517          	auipc	a0,0x1f
    80005e3e:	26e50513          	addi	a0,a0,622 # 800250a8 <disk+0x20a8>
    80005e42:	ffffb097          	auipc	ra,0xffffb
    80005e46:	d90080e7          	jalr	-624(ra) # 80000bd2 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e4a:	100017b7          	lui	a5,0x10001
    80005e4e:	4398                	lw	a4,0(a5)
    80005e50:	2701                	sext.w	a4,a4
    80005e52:	747277b7          	lui	a5,0x74727
    80005e56:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e5a:	0ef71163          	bne	a4,a5,80005f3c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e5e:	100017b7          	lui	a5,0x10001
    80005e62:	43dc                	lw	a5,4(a5)
    80005e64:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e66:	4705                	li	a4,1
    80005e68:	0ce79a63          	bne	a5,a4,80005f3c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e6c:	100017b7          	lui	a5,0x10001
    80005e70:	479c                	lw	a5,8(a5)
    80005e72:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e74:	4709                	li	a4,2
    80005e76:	0ce79363          	bne	a5,a4,80005f3c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e7a:	100017b7          	lui	a5,0x10001
    80005e7e:	47d8                	lw	a4,12(a5)
    80005e80:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e82:	554d47b7          	lui	a5,0x554d4
    80005e86:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e8a:	0af71963          	bne	a4,a5,80005f3c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e8e:	100017b7          	lui	a5,0x10001
    80005e92:	4705                	li	a4,1
    80005e94:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e96:	470d                	li	a4,3
    80005e98:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e9a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e9c:	c7ffe737          	lui	a4,0xc7ffe
    80005ea0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005ea4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ea6:	2701                	sext.w	a4,a4
    80005ea8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eaa:	472d                	li	a4,11
    80005eac:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eae:	473d                	li	a4,15
    80005eb0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005eb2:	6705                	lui	a4,0x1
    80005eb4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005eb6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005eba:	5bdc                	lw	a5,52(a5)
    80005ebc:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ebe:	c7d9                	beqz	a5,80005f4c <virtio_disk_init+0x124>
  if(max < NUM)
    80005ec0:	471d                	li	a4,7
    80005ec2:	08f77d63          	bgeu	a4,a5,80005f5c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ec6:	100014b7          	lui	s1,0x10001
    80005eca:	47a1                	li	a5,8
    80005ecc:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005ece:	6609                	lui	a2,0x2
    80005ed0:	4581                	li	a1,0
    80005ed2:	0001d517          	auipc	a0,0x1d
    80005ed6:	12e50513          	addi	a0,a0,302 # 80023000 <disk>
    80005eda:	ffffb097          	auipc	ra,0xffffb
    80005ede:	e84080e7          	jalr	-380(ra) # 80000d5e <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005ee2:	0001d717          	auipc	a4,0x1d
    80005ee6:	11e70713          	addi	a4,a4,286 # 80023000 <disk>
    80005eea:	00c75793          	srli	a5,a4,0xc
    80005eee:	2781                	sext.w	a5,a5
    80005ef0:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005ef2:	0001f797          	auipc	a5,0x1f
    80005ef6:	10e78793          	addi	a5,a5,270 # 80025000 <disk+0x2000>
    80005efa:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005efc:	0001d717          	auipc	a4,0x1d
    80005f00:	18470713          	addi	a4,a4,388 # 80023080 <disk+0x80>
    80005f04:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005f06:	0001e717          	auipc	a4,0x1e
    80005f0a:	0fa70713          	addi	a4,a4,250 # 80024000 <disk+0x1000>
    80005f0e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f10:	4705                	li	a4,1
    80005f12:	00e78c23          	sb	a4,24(a5)
    80005f16:	00e78ca3          	sb	a4,25(a5)
    80005f1a:	00e78d23          	sb	a4,26(a5)
    80005f1e:	00e78da3          	sb	a4,27(a5)
    80005f22:	00e78e23          	sb	a4,28(a5)
    80005f26:	00e78ea3          	sb	a4,29(a5)
    80005f2a:	00e78f23          	sb	a4,30(a5)
    80005f2e:	00e78fa3          	sb	a4,31(a5)
}
    80005f32:	60e2                	ld	ra,24(sp)
    80005f34:	6442                	ld	s0,16(sp)
    80005f36:	64a2                	ld	s1,8(sp)
    80005f38:	6105                	addi	sp,sp,32
    80005f3a:	8082                	ret
    panic("could not find virtio disk");
    80005f3c:	00003517          	auipc	a0,0x3
    80005f40:	9f450513          	addi	a0,a0,-1548 # 80008930 <syscalls_name+0x378>
    80005f44:	ffffa097          	auipc	ra,0xffffa
    80005f48:	604080e7          	jalr	1540(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    80005f4c:	00003517          	auipc	a0,0x3
    80005f50:	a0450513          	addi	a0,a0,-1532 # 80008950 <syscalls_name+0x398>
    80005f54:	ffffa097          	auipc	ra,0xffffa
    80005f58:	5f4080e7          	jalr	1524(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    80005f5c:	00003517          	auipc	a0,0x3
    80005f60:	a1450513          	addi	a0,a0,-1516 # 80008970 <syscalls_name+0x3b8>
    80005f64:	ffffa097          	auipc	ra,0xffffa
    80005f68:	5e4080e7          	jalr	1508(ra) # 80000548 <panic>

0000000080005f6c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f6c:	7119                	addi	sp,sp,-128
    80005f6e:	fc86                	sd	ra,120(sp)
    80005f70:	f8a2                	sd	s0,112(sp)
    80005f72:	f4a6                	sd	s1,104(sp)
    80005f74:	f0ca                	sd	s2,96(sp)
    80005f76:	ecce                	sd	s3,88(sp)
    80005f78:	e8d2                	sd	s4,80(sp)
    80005f7a:	e4d6                	sd	s5,72(sp)
    80005f7c:	e0da                	sd	s6,64(sp)
    80005f7e:	fc5e                	sd	s7,56(sp)
    80005f80:	f862                	sd	s8,48(sp)
    80005f82:	f466                	sd	s9,40(sp)
    80005f84:	f06a                	sd	s10,32(sp)
    80005f86:	0100                	addi	s0,sp,128
    80005f88:	892a                	mv	s2,a0
    80005f8a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f8c:	00c52c83          	lw	s9,12(a0)
    80005f90:	001c9c9b          	slliw	s9,s9,0x1
    80005f94:	1c82                	slli	s9,s9,0x20
    80005f96:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f9a:	0001f517          	auipc	a0,0x1f
    80005f9e:	10e50513          	addi	a0,a0,270 # 800250a8 <disk+0x20a8>
    80005fa2:	ffffb097          	auipc	ra,0xffffb
    80005fa6:	cc0080e7          	jalr	-832(ra) # 80000c62 <acquire>
  for(int i = 0; i < 3; i++){
    80005faa:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005fac:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005fae:	0001db97          	auipc	s7,0x1d
    80005fb2:	052b8b93          	addi	s7,s7,82 # 80023000 <disk>
    80005fb6:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005fb8:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005fba:	8a4e                	mv	s4,s3
    80005fbc:	a051                	j	80006040 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005fbe:	00fb86b3          	add	a3,s7,a5
    80005fc2:	96da                	add	a3,a3,s6
    80005fc4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005fc8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005fca:	0207c563          	bltz	a5,80005ff4 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005fce:	2485                	addiw	s1,s1,1
    80005fd0:	0711                	addi	a4,a4,4
    80005fd2:	23548d63          	beq	s1,s5,8000620c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80005fd6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005fd8:	0001f697          	auipc	a3,0x1f
    80005fdc:	04068693          	addi	a3,a3,64 # 80025018 <disk+0x2018>
    80005fe0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005fe2:	0006c583          	lbu	a1,0(a3)
    80005fe6:	fde1                	bnez	a1,80005fbe <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005fe8:	2785                	addiw	a5,a5,1
    80005fea:	0685                	addi	a3,a3,1
    80005fec:	ff879be3          	bne	a5,s8,80005fe2 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005ff0:	57fd                	li	a5,-1
    80005ff2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005ff4:	02905a63          	blez	s1,80006028 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ff8:	f9042503          	lw	a0,-112(s0)
    80005ffc:	00000097          	auipc	ra,0x0
    80006000:	daa080e7          	jalr	-598(ra) # 80005da6 <free_desc>
      for(int j = 0; j < i; j++)
    80006004:	4785                	li	a5,1
    80006006:	0297d163          	bge	a5,s1,80006028 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000600a:	f9442503          	lw	a0,-108(s0)
    8000600e:	00000097          	auipc	ra,0x0
    80006012:	d98080e7          	jalr	-616(ra) # 80005da6 <free_desc>
      for(int j = 0; j < i; j++)
    80006016:	4789                	li	a5,2
    80006018:	0097d863          	bge	a5,s1,80006028 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000601c:	f9842503          	lw	a0,-104(s0)
    80006020:	00000097          	auipc	ra,0x0
    80006024:	d86080e7          	jalr	-634(ra) # 80005da6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006028:	0001f597          	auipc	a1,0x1f
    8000602c:	08058593          	addi	a1,a1,128 # 800250a8 <disk+0x20a8>
    80006030:	0001f517          	auipc	a0,0x1f
    80006034:	fe850513          	addi	a0,a0,-24 # 80025018 <disk+0x2018>
    80006038:	ffffc097          	auipc	ra,0xffffc
    8000603c:	20c080e7          	jalr	524(ra) # 80002244 <sleep>
  for(int i = 0; i < 3; i++){
    80006040:	f9040713          	addi	a4,s0,-112
    80006044:	84ce                	mv	s1,s3
    80006046:	bf41                	j	80005fd6 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006048:	4785                	li	a5,1
    8000604a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000604e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006052:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006056:	f9042983          	lw	s3,-112(s0)
    8000605a:	00499493          	slli	s1,s3,0x4
    8000605e:	0001fa17          	auipc	s4,0x1f
    80006062:	fa2a0a13          	addi	s4,s4,-94 # 80025000 <disk+0x2000>
    80006066:	000a3a83          	ld	s5,0(s4)
    8000606a:	9aa6                	add	s5,s5,s1
    8000606c:	f8040513          	addi	a0,s0,-128
    80006070:	ffffb097          	auipc	ra,0xffffb
    80006074:	0c2080e7          	jalr	194(ra) # 80001132 <kvmpa>
    80006078:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000607c:	000a3783          	ld	a5,0(s4)
    80006080:	97a6                	add	a5,a5,s1
    80006082:	4741                	li	a4,16
    80006084:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006086:	000a3783          	ld	a5,0(s4)
    8000608a:	97a6                	add	a5,a5,s1
    8000608c:	4705                	li	a4,1
    8000608e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006092:	f9442703          	lw	a4,-108(s0)
    80006096:	000a3783          	ld	a5,0(s4)
    8000609a:	97a6                	add	a5,a5,s1
    8000609c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800060a0:	0712                	slli	a4,a4,0x4
    800060a2:	000a3783          	ld	a5,0(s4)
    800060a6:	97ba                	add	a5,a5,a4
    800060a8:	05890693          	addi	a3,s2,88
    800060ac:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    800060ae:	000a3783          	ld	a5,0(s4)
    800060b2:	97ba                	add	a5,a5,a4
    800060b4:	40000693          	li	a3,1024
    800060b8:	c794                	sw	a3,8(a5)
  if(write)
    800060ba:	100d0a63          	beqz	s10,800061ce <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800060be:	0001f797          	auipc	a5,0x1f
    800060c2:	f427b783          	ld	a5,-190(a5) # 80025000 <disk+0x2000>
    800060c6:	97ba                	add	a5,a5,a4
    800060c8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060cc:	0001d517          	auipc	a0,0x1d
    800060d0:	f3450513          	addi	a0,a0,-204 # 80023000 <disk>
    800060d4:	0001f797          	auipc	a5,0x1f
    800060d8:	f2c78793          	addi	a5,a5,-212 # 80025000 <disk+0x2000>
    800060dc:	6394                	ld	a3,0(a5)
    800060de:	96ba                	add	a3,a3,a4
    800060e0:	00c6d603          	lhu	a2,12(a3)
    800060e4:	00166613          	ori	a2,a2,1
    800060e8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800060ec:	f9842683          	lw	a3,-104(s0)
    800060f0:	6390                	ld	a2,0(a5)
    800060f2:	9732                	add	a4,a4,a2
    800060f4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    800060f8:	20098613          	addi	a2,s3,512
    800060fc:	0612                	slli	a2,a2,0x4
    800060fe:	962a                	add	a2,a2,a0
    80006100:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006104:	00469713          	slli	a4,a3,0x4
    80006108:	6394                	ld	a3,0(a5)
    8000610a:	96ba                	add	a3,a3,a4
    8000610c:	6589                	lui	a1,0x2
    8000610e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006112:	94ae                	add	s1,s1,a1
    80006114:	94aa                	add	s1,s1,a0
    80006116:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006118:	6394                	ld	a3,0(a5)
    8000611a:	96ba                	add	a3,a3,a4
    8000611c:	4585                	li	a1,1
    8000611e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006120:	6394                	ld	a3,0(a5)
    80006122:	96ba                	add	a3,a3,a4
    80006124:	4509                	li	a0,2
    80006126:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000612a:	6394                	ld	a3,0(a5)
    8000612c:	9736                	add	a4,a4,a3
    8000612e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006132:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006136:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000613a:	6794                	ld	a3,8(a5)
    8000613c:	0026d703          	lhu	a4,2(a3)
    80006140:	8b1d                	andi	a4,a4,7
    80006142:	2709                	addiw	a4,a4,2
    80006144:	0706                	slli	a4,a4,0x1
    80006146:	9736                	add	a4,a4,a3
    80006148:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000614c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006150:	6798                	ld	a4,8(a5)
    80006152:	00275783          	lhu	a5,2(a4)
    80006156:	2785                	addiw	a5,a5,1
    80006158:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000615c:	100017b7          	lui	a5,0x10001
    80006160:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006164:	00492703          	lw	a4,4(s2)
    80006168:	4785                	li	a5,1
    8000616a:	02f71163          	bne	a4,a5,8000618c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000616e:	0001f997          	auipc	s3,0x1f
    80006172:	f3a98993          	addi	s3,s3,-198 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006176:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006178:	85ce                	mv	a1,s3
    8000617a:	854a                	mv	a0,s2
    8000617c:	ffffc097          	auipc	ra,0xffffc
    80006180:	0c8080e7          	jalr	200(ra) # 80002244 <sleep>
  while(b->disk == 1) {
    80006184:	00492783          	lw	a5,4(s2)
    80006188:	fe9788e3          	beq	a5,s1,80006178 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000618c:	f9042483          	lw	s1,-112(s0)
    80006190:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006194:	00479713          	slli	a4,a5,0x4
    80006198:	0001d797          	auipc	a5,0x1d
    8000619c:	e6878793          	addi	a5,a5,-408 # 80023000 <disk>
    800061a0:	97ba                	add	a5,a5,a4
    800061a2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800061a6:	0001f917          	auipc	s2,0x1f
    800061aa:	e5a90913          	addi	s2,s2,-422 # 80025000 <disk+0x2000>
    free_desc(i);
    800061ae:	8526                	mv	a0,s1
    800061b0:	00000097          	auipc	ra,0x0
    800061b4:	bf6080e7          	jalr	-1034(ra) # 80005da6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800061b8:	0492                	slli	s1,s1,0x4
    800061ba:	00093783          	ld	a5,0(s2)
    800061be:	94be                	add	s1,s1,a5
    800061c0:	00c4d783          	lhu	a5,12(s1)
    800061c4:	8b85                	andi	a5,a5,1
    800061c6:	cf89                	beqz	a5,800061e0 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    800061c8:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800061cc:	b7cd                	j	800061ae <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800061ce:	0001f797          	auipc	a5,0x1f
    800061d2:	e327b783          	ld	a5,-462(a5) # 80025000 <disk+0x2000>
    800061d6:	97ba                	add	a5,a5,a4
    800061d8:	4689                	li	a3,2
    800061da:	00d79623          	sh	a3,12(a5)
    800061de:	b5fd                	j	800060cc <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061e0:	0001f517          	auipc	a0,0x1f
    800061e4:	ec850513          	addi	a0,a0,-312 # 800250a8 <disk+0x20a8>
    800061e8:	ffffb097          	auipc	ra,0xffffb
    800061ec:	b2e080e7          	jalr	-1234(ra) # 80000d16 <release>
}
    800061f0:	70e6                	ld	ra,120(sp)
    800061f2:	7446                	ld	s0,112(sp)
    800061f4:	74a6                	ld	s1,104(sp)
    800061f6:	7906                	ld	s2,96(sp)
    800061f8:	69e6                	ld	s3,88(sp)
    800061fa:	6a46                	ld	s4,80(sp)
    800061fc:	6aa6                	ld	s5,72(sp)
    800061fe:	6b06                	ld	s6,64(sp)
    80006200:	7be2                	ld	s7,56(sp)
    80006202:	7c42                	ld	s8,48(sp)
    80006204:	7ca2                	ld	s9,40(sp)
    80006206:	7d02                	ld	s10,32(sp)
    80006208:	6109                	addi	sp,sp,128
    8000620a:	8082                	ret
  if(write)
    8000620c:	e20d1ee3          	bnez	s10,80006048 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006210:	f8042023          	sw	zero,-128(s0)
    80006214:	bd2d                	j	8000604e <virtio_disk_rw+0xe2>

0000000080006216 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006216:	1101                	addi	sp,sp,-32
    80006218:	ec06                	sd	ra,24(sp)
    8000621a:	e822                	sd	s0,16(sp)
    8000621c:	e426                	sd	s1,8(sp)
    8000621e:	e04a                	sd	s2,0(sp)
    80006220:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006222:	0001f517          	auipc	a0,0x1f
    80006226:	e8650513          	addi	a0,a0,-378 # 800250a8 <disk+0x20a8>
    8000622a:	ffffb097          	auipc	ra,0xffffb
    8000622e:	a38080e7          	jalr	-1480(ra) # 80000c62 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006232:	0001f717          	auipc	a4,0x1f
    80006236:	dce70713          	addi	a4,a4,-562 # 80025000 <disk+0x2000>
    8000623a:	02075783          	lhu	a5,32(a4)
    8000623e:	6b18                	ld	a4,16(a4)
    80006240:	00275683          	lhu	a3,2(a4)
    80006244:	8ebd                	xor	a3,a3,a5
    80006246:	8a9d                	andi	a3,a3,7
    80006248:	cab9                	beqz	a3,8000629e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000624a:	0001d917          	auipc	s2,0x1d
    8000624e:	db690913          	addi	s2,s2,-586 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006252:	0001f497          	auipc	s1,0x1f
    80006256:	dae48493          	addi	s1,s1,-594 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000625a:	078e                	slli	a5,a5,0x3
    8000625c:	97ba                	add	a5,a5,a4
    8000625e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006260:	20078713          	addi	a4,a5,512
    80006264:	0712                	slli	a4,a4,0x4
    80006266:	974a                	add	a4,a4,s2
    80006268:	03074703          	lbu	a4,48(a4)
    8000626c:	ef21                	bnez	a4,800062c4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000626e:	20078793          	addi	a5,a5,512
    80006272:	0792                	slli	a5,a5,0x4
    80006274:	97ca                	add	a5,a5,s2
    80006276:	7798                	ld	a4,40(a5)
    80006278:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000627c:	7788                	ld	a0,40(a5)
    8000627e:	ffffc097          	auipc	ra,0xffffc
    80006282:	14c080e7          	jalr	332(ra) # 800023ca <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006286:	0204d783          	lhu	a5,32(s1)
    8000628a:	2785                	addiw	a5,a5,1
    8000628c:	8b9d                	andi	a5,a5,7
    8000628e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006292:	6898                	ld	a4,16(s1)
    80006294:	00275683          	lhu	a3,2(a4)
    80006298:	8a9d                	andi	a3,a3,7
    8000629a:	fcf690e3          	bne	a3,a5,8000625a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000629e:	10001737          	lui	a4,0x10001
    800062a2:	533c                	lw	a5,96(a4)
    800062a4:	8b8d                	andi	a5,a5,3
    800062a6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800062a8:	0001f517          	auipc	a0,0x1f
    800062ac:	e0050513          	addi	a0,a0,-512 # 800250a8 <disk+0x20a8>
    800062b0:	ffffb097          	auipc	ra,0xffffb
    800062b4:	a66080e7          	jalr	-1434(ra) # 80000d16 <release>
}
    800062b8:	60e2                	ld	ra,24(sp)
    800062ba:	6442                	ld	s0,16(sp)
    800062bc:	64a2                	ld	s1,8(sp)
    800062be:	6902                	ld	s2,0(sp)
    800062c0:	6105                	addi	sp,sp,32
    800062c2:	8082                	ret
      panic("virtio_disk_intr status");
    800062c4:	00002517          	auipc	a0,0x2
    800062c8:	6cc50513          	addi	a0,a0,1740 # 80008990 <syscalls_name+0x3d8>
    800062cc:	ffffa097          	auipc	ra,0xffffa
    800062d0:	27c080e7          	jalr	636(ra) # 80000548 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
