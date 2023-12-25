
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8e013103          	ld	sp,-1824(sp) # 800088e0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	16c78793          	addi	a5,a5,364 # 800061d0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dd678793          	addi	a5,a5,-554 # 80000e84 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000106:	04c05663          	blez	a2,80000152 <consolewrite+0x5e>
    8000010a:	8a2a                	mv	s4,a0
    8000010c:	84ae                	mv	s1,a1
    8000010e:	89b2                	mv	s3,a2
    80000110:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000112:	5afd                	li	s5,-1
    80000114:	4685                	li	a3,1
    80000116:	8626                	mv	a2,s1
    80000118:	85d2                	mv	a1,s4
    8000011a:	fbf40513          	addi	a0,s0,-65
    8000011e:	00002097          	auipc	ra,0x2
    80000122:	4aa080e7          	jalr	1194(ra) # 800025c8 <either_copyin>
    80000126:	01550c63          	beq	a0,s5,8000013e <consolewrite+0x4a>
      break;
    uartputc(c);
    8000012a:	fbf44503          	lbu	a0,-65(s0)
    8000012e:	00000097          	auipc	ra,0x0
    80000132:	78e080e7          	jalr	1934(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000136:	2905                	addiw	s2,s2,1
    80000138:	0485                	addi	s1,s1,1
    8000013a:	fd299de3          	bne	s3,s2,80000114 <consolewrite+0x20>
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4a>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000156:	7119                	addi	sp,sp,-128
    80000158:	fc86                	sd	ra,120(sp)
    8000015a:	f8a2                	sd	s0,112(sp)
    8000015c:	f4a6                	sd	s1,104(sp)
    8000015e:	f0ca                	sd	s2,96(sp)
    80000160:	ecce                	sd	s3,88(sp)
    80000162:	e8d2                	sd	s4,80(sp)
    80000164:	e4d6                	sd	s5,72(sp)
    80000166:	e0da                	sd	s6,64(sp)
    80000168:	fc5e                	sd	s7,56(sp)
    8000016a:	f862                	sd	s8,48(sp)
    8000016c:	f466                	sd	s9,40(sp)
    8000016e:	f06a                	sd	s10,32(sp)
    80000170:	ec6e                	sd	s11,24(sp)
    80000172:	0100                	addi	s0,sp,128
    80000174:	8b2a                	mv	s6,a0
    80000176:	8aae                	mv	s5,a1
    80000178:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000017a:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000017e:	00011517          	auipc	a0,0x11
    80000182:	00250513          	addi	a0,a0,2 # 80011180 <cons>
    80000186:	00001097          	auipc	ra,0x1
    8000018a:	a50080e7          	jalr	-1456(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018e:	00011497          	auipc	s1,0x11
    80000192:	ff248493          	addi	s1,s1,-14 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000196:	89a6                	mv	s3,s1
    80000198:	00011917          	auipc	s2,0x11
    8000019c:	08090913          	addi	s2,s2,128 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001a0:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001a2:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a4:	4da9                	li	s11,10
  while(n > 0){
    800001a6:	07405863          	blez	s4,80000216 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001aa:	0984a783          	lw	a5,152(s1)
    800001ae:	09c4a703          	lw	a4,156(s1)
    800001b2:	02f71463          	bne	a4,a5,800001da <consoleread+0x84>
      if(myproc()->killed){
    800001b6:	00002097          	auipc	ra,0x2
    800001ba:	9f0080e7          	jalr	-1552(ra) # 80001ba6 <myproc>
    800001be:	591c                	lw	a5,48(a0)
    800001c0:	e7b5                	bnez	a5,8000022c <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001c2:	85ce                	mv	a1,s3
    800001c4:	854a                	mv	a0,s2
    800001c6:	00002097          	auipc	ra,0x2
    800001ca:	14a080e7          	jalr	330(ra) # 80002310 <sleep>
    while(cons.r == cons.w){
    800001ce:	0984a783          	lw	a5,152(s1)
    800001d2:	09c4a703          	lw	a4,156(s1)
    800001d6:	fef700e3          	beq	a4,a5,800001b6 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001da:	0017871b          	addiw	a4,a5,1
    800001de:	08e4ac23          	sw	a4,152(s1)
    800001e2:	07f7f713          	andi	a4,a5,127
    800001e6:	9726                	add	a4,a4,s1
    800001e8:	01874703          	lbu	a4,24(a4)
    800001ec:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001f0:	079c0663          	beq	s8,s9,8000025c <consoleread+0x106>
    cbuf = c;
    800001f4:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f8:	4685                	li	a3,1
    800001fa:	f8f40613          	addi	a2,s0,-113
    800001fe:	85d6                	mv	a1,s5
    80000200:	855a                	mv	a0,s6
    80000202:	00002097          	auipc	ra,0x2
    80000206:	370080e7          	jalr	880(ra) # 80002572 <either_copyout>
    8000020a:	01a50663          	beq	a0,s10,80000216 <consoleread+0xc0>
    dst++;
    8000020e:	0a85                	addi	s5,s5,1
    --n;
    80000210:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000212:	f9bc1ae3          	bne	s8,s11,800001a6 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000216:	00011517          	auipc	a0,0x11
    8000021a:	f6a50513          	addi	a0,a0,-150 # 80011180 <cons>
    8000021e:	00001097          	auipc	ra,0x1
    80000222:	a6c080e7          	jalr	-1428(ra) # 80000c8a <release>

  return target - n;
    80000226:	414b853b          	subw	a0,s7,s4
    8000022a:	a811                	j	8000023e <consoleread+0xe8>
        release(&cons.lock);
    8000022c:	00011517          	auipc	a0,0x11
    80000230:	f5450513          	addi	a0,a0,-172 # 80011180 <cons>
    80000234:	00001097          	auipc	ra,0x1
    80000238:	a56080e7          	jalr	-1450(ra) # 80000c8a <release>
        return -1;
    8000023c:	557d                	li	a0,-1
}
    8000023e:	70e6                	ld	ra,120(sp)
    80000240:	7446                	ld	s0,112(sp)
    80000242:	74a6                	ld	s1,104(sp)
    80000244:	7906                	ld	s2,96(sp)
    80000246:	69e6                	ld	s3,88(sp)
    80000248:	6a46                	ld	s4,80(sp)
    8000024a:	6aa6                	ld	s5,72(sp)
    8000024c:	6b06                	ld	s6,64(sp)
    8000024e:	7be2                	ld	s7,56(sp)
    80000250:	7c42                	ld	s8,48(sp)
    80000252:	7ca2                	ld	s9,40(sp)
    80000254:	7d02                	ld	s10,32(sp)
    80000256:	6de2                	ld	s11,24(sp)
    80000258:	6109                	addi	sp,sp,128
    8000025a:	8082                	ret
      if(n < target){
    8000025c:	000a071b          	sext.w	a4,s4
    80000260:	fb777be3          	bgeu	a4,s7,80000216 <consoleread+0xc0>
        cons.r--;
    80000264:	00011717          	auipc	a4,0x11
    80000268:	faf72a23          	sw	a5,-76(a4) # 80011218 <cons+0x98>
    8000026c:	b76d                	j	80000216 <consoleread+0xc0>

000000008000026e <consputc>:
{
    8000026e:	1141                	addi	sp,sp,-16
    80000270:	e406                	sd	ra,8(sp)
    80000272:	e022                	sd	s0,0(sp)
    80000274:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000276:	10000793          	li	a5,256
    8000027a:	00f50a63          	beq	a0,a5,8000028e <consputc+0x20>
    uartputc_sync(c);
    8000027e:	00000097          	auipc	ra,0x0
    80000282:	564080e7          	jalr	1380(ra) # 800007e2 <uartputc_sync>
}
    80000286:	60a2                	ld	ra,8(sp)
    80000288:	6402                	ld	s0,0(sp)
    8000028a:	0141                	addi	sp,sp,16
    8000028c:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000028e:	4521                	li	a0,8
    80000290:	00000097          	auipc	ra,0x0
    80000294:	552080e7          	jalr	1362(ra) # 800007e2 <uartputc_sync>
    80000298:	02000513          	li	a0,32
    8000029c:	00000097          	auipc	ra,0x0
    800002a0:	546080e7          	jalr	1350(ra) # 800007e2 <uartputc_sync>
    800002a4:	4521                	li	a0,8
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	53c080e7          	jalr	1340(ra) # 800007e2 <uartputc_sync>
    800002ae:	bfe1                	j	80000286 <consputc+0x18>

00000000800002b0 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b0:	1101                	addi	sp,sp,-32
    800002b2:	ec06                	sd	ra,24(sp)
    800002b4:	e822                	sd	s0,16(sp)
    800002b6:	e426                	sd	s1,8(sp)
    800002b8:	e04a                	sd	s2,0(sp)
    800002ba:	1000                	addi	s0,sp,32
    800002bc:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002be:	00011517          	auipc	a0,0x11
    800002c2:	ec250513          	addi	a0,a0,-318 # 80011180 <cons>
    800002c6:	00001097          	auipc	ra,0x1
    800002ca:	910080e7          	jalr	-1776(ra) # 80000bd6 <acquire>

  switch(c){
    800002ce:	47d5                	li	a5,21
    800002d0:	0af48663          	beq	s1,a5,8000037c <consoleintr+0xcc>
    800002d4:	0297ca63          	blt	a5,s1,80000308 <consoleintr+0x58>
    800002d8:	47a1                	li	a5,8
    800002da:	0ef48763          	beq	s1,a5,800003c8 <consoleintr+0x118>
    800002de:	47c1                	li	a5,16
    800002e0:	10f49a63          	bne	s1,a5,800003f4 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002e4:	00002097          	auipc	ra,0x2
    800002e8:	33a080e7          	jalr	826(ra) # 8000261e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002ec:	00011517          	auipc	a0,0x11
    800002f0:	e9450513          	addi	a0,a0,-364 # 80011180 <cons>
    800002f4:	00001097          	auipc	ra,0x1
    800002f8:	996080e7          	jalr	-1642(ra) # 80000c8a <release>
}
    800002fc:	60e2                	ld	ra,24(sp)
    800002fe:	6442                	ld	s0,16(sp)
    80000300:	64a2                	ld	s1,8(sp)
    80000302:	6902                	ld	s2,0(sp)
    80000304:	6105                	addi	sp,sp,32
    80000306:	8082                	ret
  switch(c){
    80000308:	07f00793          	li	a5,127
    8000030c:	0af48e63          	beq	s1,a5,800003c8 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000310:	00011717          	auipc	a4,0x11
    80000314:	e7070713          	addi	a4,a4,-400 # 80011180 <cons>
    80000318:	0a072783          	lw	a5,160(a4)
    8000031c:	09872703          	lw	a4,152(a4)
    80000320:	9f99                	subw	a5,a5,a4
    80000322:	07f00713          	li	a4,127
    80000326:	fcf763e3          	bltu	a4,a5,800002ec <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000032a:	47b5                	li	a5,13
    8000032c:	0cf48763          	beq	s1,a5,800003fa <consoleintr+0x14a>
      consputc(c);
    80000330:	8526                	mv	a0,s1
    80000332:	00000097          	auipc	ra,0x0
    80000336:	f3c080e7          	jalr	-196(ra) # 8000026e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000033a:	00011797          	auipc	a5,0x11
    8000033e:	e4678793          	addi	a5,a5,-442 # 80011180 <cons>
    80000342:	0a07a703          	lw	a4,160(a5)
    80000346:	0017069b          	addiw	a3,a4,1
    8000034a:	0006861b          	sext.w	a2,a3
    8000034e:	0ad7a023          	sw	a3,160(a5)
    80000352:	07f77713          	andi	a4,a4,127
    80000356:	97ba                	add	a5,a5,a4
    80000358:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000035c:	47a9                	li	a5,10
    8000035e:	0cf48563          	beq	s1,a5,80000428 <consoleintr+0x178>
    80000362:	4791                	li	a5,4
    80000364:	0cf48263          	beq	s1,a5,80000428 <consoleintr+0x178>
    80000368:	00011797          	auipc	a5,0x11
    8000036c:	eb07a783          	lw	a5,-336(a5) # 80011218 <cons+0x98>
    80000370:	0807879b          	addiw	a5,a5,128
    80000374:	f6f61ce3          	bne	a2,a5,800002ec <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000378:	863e                	mv	a2,a5
    8000037a:	a07d                	j	80000428 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000037c:	00011717          	auipc	a4,0x11
    80000380:	e0470713          	addi	a4,a4,-508 # 80011180 <cons>
    80000384:	0a072783          	lw	a5,160(a4)
    80000388:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000038c:	00011497          	auipc	s1,0x11
    80000390:	df448493          	addi	s1,s1,-524 # 80011180 <cons>
    while(cons.e != cons.w &&
    80000394:	4929                	li	s2,10
    80000396:	f4f70be3          	beq	a4,a5,800002ec <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	37fd                	addiw	a5,a5,-1
    8000039c:	07f7f713          	andi	a4,a5,127
    800003a0:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003a2:	01874703          	lbu	a4,24(a4)
    800003a6:	f52703e3          	beq	a4,s2,800002ec <consoleintr+0x3c>
      cons.e--;
    800003aa:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003ae:	10000513          	li	a0,256
    800003b2:	00000097          	auipc	ra,0x0
    800003b6:	ebc080e7          	jalr	-324(ra) # 8000026e <consputc>
    while(cons.e != cons.w &&
    800003ba:	0a04a783          	lw	a5,160(s1)
    800003be:	09c4a703          	lw	a4,156(s1)
    800003c2:	fcf71ce3          	bne	a4,a5,8000039a <consoleintr+0xea>
    800003c6:	b71d                	j	800002ec <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c8:	00011717          	auipc	a4,0x11
    800003cc:	db870713          	addi	a4,a4,-584 # 80011180 <cons>
    800003d0:	0a072783          	lw	a5,160(a4)
    800003d4:	09c72703          	lw	a4,156(a4)
    800003d8:	f0f70ae3          	beq	a4,a5,800002ec <consoleintr+0x3c>
      cons.e--;
    800003dc:	37fd                	addiw	a5,a5,-1
    800003de:	00011717          	auipc	a4,0x11
    800003e2:	e4f72123          	sw	a5,-446(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e6:	10000513          	li	a0,256
    800003ea:	00000097          	auipc	ra,0x0
    800003ee:	e84080e7          	jalr	-380(ra) # 8000026e <consputc>
    800003f2:	bded                	j	800002ec <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003f4:	ee048ce3          	beqz	s1,800002ec <consoleintr+0x3c>
    800003f8:	bf21                	j	80000310 <consoleintr+0x60>
      consputc(c);
    800003fa:	4529                	li	a0,10
    800003fc:	00000097          	auipc	ra,0x0
    80000400:	e72080e7          	jalr	-398(ra) # 8000026e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000404:	00011797          	auipc	a5,0x11
    80000408:	d7c78793          	addi	a5,a5,-644 # 80011180 <cons>
    8000040c:	0a07a703          	lw	a4,160(a5)
    80000410:	0017069b          	addiw	a3,a4,1
    80000414:	0006861b          	sext.w	a2,a3
    80000418:	0ad7a023          	sw	a3,160(a5)
    8000041c:	07f77713          	andi	a4,a4,127
    80000420:	97ba                	add	a5,a5,a4
    80000422:	4729                	li	a4,10
    80000424:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000428:	00011797          	auipc	a5,0x11
    8000042c:	dec7aa23          	sw	a2,-524(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000430:	00011517          	auipc	a0,0x11
    80000434:	de850513          	addi	a0,a0,-536 # 80011218 <cons+0x98>
    80000438:	00002097          	auipc	ra,0x2
    8000043c:	05e080e7          	jalr	94(ra) # 80002496 <wakeup>
    80000440:	b575                	j	800002ec <consoleintr+0x3c>

0000000080000442 <consoleinit>:

void
consoleinit(void)
{
    80000442:	1141                	addi	sp,sp,-16
    80000444:	e406                	sd	ra,8(sp)
    80000446:	e022                	sd	s0,0(sp)
    80000448:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000044a:	00008597          	auipc	a1,0x8
    8000044e:	bc658593          	addi	a1,a1,-1082 # 80008010 <etext+0x10>
    80000452:	00011517          	auipc	a0,0x11
    80000456:	d2e50513          	addi	a0,a0,-722 # 80011180 <cons>
    8000045a:	00000097          	auipc	ra,0x0
    8000045e:	6ec080e7          	jalr	1772(ra) # 80000b46 <initlock>

  uartinit();
    80000462:	00000097          	auipc	ra,0x0
    80000466:	330080e7          	jalr	816(ra) # 80000792 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000046a:	00021797          	auipc	a5,0x21
    8000046e:	59678793          	addi	a5,a5,1430 # 80021a00 <devsw>
    80000472:	00000717          	auipc	a4,0x0
    80000476:	ce470713          	addi	a4,a4,-796 # 80000156 <consoleread>
    8000047a:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	c7870713          	addi	a4,a4,-904 # 800000f4 <consolewrite>
    80000484:	ef98                	sd	a4,24(a5)
}
    80000486:	60a2                	ld	ra,8(sp)
    80000488:	6402                	ld	s0,0(sp)
    8000048a:	0141                	addi	sp,sp,16
    8000048c:	8082                	ret

000000008000048e <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000048e:	7179                	addi	sp,sp,-48
    80000490:	f406                	sd	ra,40(sp)
    80000492:	f022                	sd	s0,32(sp)
    80000494:	ec26                	sd	s1,24(sp)
    80000496:	e84a                	sd	s2,16(sp)
    80000498:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    8000049a:	c219                	beqz	a2,800004a0 <printint+0x12>
    8000049c:	08054663          	bltz	a0,80000528 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004a0:	2501                	sext.w	a0,a0
    800004a2:	4881                	li	a7,0
    800004a4:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004aa:	2581                	sext.w	a1,a1
    800004ac:	00008617          	auipc	a2,0x8
    800004b0:	b9460613          	addi	a2,a2,-1132 # 80008040 <digits>
    800004b4:	883a                	mv	a6,a4
    800004b6:	2705                	addiw	a4,a4,1
    800004b8:	02b577bb          	remuw	a5,a0,a1
    800004bc:	1782                	slli	a5,a5,0x20
    800004be:	9381                	srli	a5,a5,0x20
    800004c0:	97b2                	add	a5,a5,a2
    800004c2:	0007c783          	lbu	a5,0(a5)
    800004c6:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004ca:	0005079b          	sext.w	a5,a0
    800004ce:	02b5553b          	divuw	a0,a0,a1
    800004d2:	0685                	addi	a3,a3,1
    800004d4:	feb7f0e3          	bgeu	a5,a1,800004b4 <printint+0x26>

  if(sign)
    800004d8:	00088b63          	beqz	a7,800004ee <printint+0x60>
    buf[i++] = '-';
    800004dc:	fe040793          	addi	a5,s0,-32
    800004e0:	973e                	add	a4,a4,a5
    800004e2:	02d00793          	li	a5,45
    800004e6:	fef70823          	sb	a5,-16(a4)
    800004ea:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004ee:	02e05763          	blez	a4,8000051c <printint+0x8e>
    800004f2:	fd040793          	addi	a5,s0,-48
    800004f6:	00e784b3          	add	s1,a5,a4
    800004fa:	fff78913          	addi	s2,a5,-1
    800004fe:	993a                	add	s2,s2,a4
    80000500:	377d                	addiw	a4,a4,-1
    80000502:	1702                	slli	a4,a4,0x20
    80000504:	9301                	srli	a4,a4,0x20
    80000506:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000050a:	fff4c503          	lbu	a0,-1(s1)
    8000050e:	00000097          	auipc	ra,0x0
    80000512:	d60080e7          	jalr	-672(ra) # 8000026e <consputc>
  while(--i >= 0)
    80000516:	14fd                	addi	s1,s1,-1
    80000518:	ff2499e3          	bne	s1,s2,8000050a <printint+0x7c>
}
    8000051c:	70a2                	ld	ra,40(sp)
    8000051e:	7402                	ld	s0,32(sp)
    80000520:	64e2                	ld	s1,24(sp)
    80000522:	6942                	ld	s2,16(sp)
    80000524:	6145                	addi	sp,sp,48
    80000526:	8082                	ret
    x = -xx;
    80000528:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000052c:	4885                	li	a7,1
    x = -xx;
    8000052e:	bf9d                	j	800004a4 <printint+0x16>

0000000080000530 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000530:	1101                	addi	sp,sp,-32
    80000532:	ec06                	sd	ra,24(sp)
    80000534:	e822                	sd	s0,16(sp)
    80000536:	e426                	sd	s1,8(sp)
    80000538:	1000                	addi	s0,sp,32
    8000053a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000053c:	00011797          	auipc	a5,0x11
    80000540:	d007a223          	sw	zero,-764(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000544:	00008517          	auipc	a0,0x8
    80000548:	ad450513          	addi	a0,a0,-1324 # 80008018 <etext+0x18>
    8000054c:	00000097          	auipc	ra,0x0
    80000550:	02e080e7          	jalr	46(ra) # 8000057a <printf>
  printf(s);
    80000554:	8526                	mv	a0,s1
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	024080e7          	jalr	36(ra) # 8000057a <printf>
  printf("\n");
    8000055e:	00008517          	auipc	a0,0x8
    80000562:	c6a50513          	addi	a0,a0,-918 # 800081c8 <digits+0x188>
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	014080e7          	jalr	20(ra) # 8000057a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000056e:	4785                	li	a5,1
    80000570:	00009717          	auipc	a4,0x9
    80000574:	a8f72823          	sw	a5,-1392(a4) # 80009000 <panicked>
  for(;;)
    80000578:	a001                	j	80000578 <panic+0x48>

000000008000057a <printf>:
{
    8000057a:	7131                	addi	sp,sp,-192
    8000057c:	fc86                	sd	ra,120(sp)
    8000057e:	f8a2                	sd	s0,112(sp)
    80000580:	f4a6                	sd	s1,104(sp)
    80000582:	f0ca                	sd	s2,96(sp)
    80000584:	ecce                	sd	s3,88(sp)
    80000586:	e8d2                	sd	s4,80(sp)
    80000588:	e4d6                	sd	s5,72(sp)
    8000058a:	e0da                	sd	s6,64(sp)
    8000058c:	fc5e                	sd	s7,56(sp)
    8000058e:	f862                	sd	s8,48(sp)
    80000590:	f466                	sd	s9,40(sp)
    80000592:	f06a                	sd	s10,32(sp)
    80000594:	ec6e                	sd	s11,24(sp)
    80000596:	0100                	addi	s0,sp,128
    80000598:	8a2a                	mv	s4,a0
    8000059a:	e40c                	sd	a1,8(s0)
    8000059c:	e810                	sd	a2,16(s0)
    8000059e:	ec14                	sd	a3,24(s0)
    800005a0:	f018                	sd	a4,32(s0)
    800005a2:	f41c                	sd	a5,40(s0)
    800005a4:	03043823          	sd	a6,48(s0)
    800005a8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ac:	00011d97          	auipc	s11,0x11
    800005b0:	c94dad83          	lw	s11,-876(s11) # 80011240 <pr+0x18>
  if(locking)
    800005b4:	020d9b63          	bnez	s11,800005ea <printf+0x70>
  if (fmt == 0)
    800005b8:	040a0263          	beqz	s4,800005fc <printf+0x82>
  va_start(ap, fmt);
    800005bc:	00840793          	addi	a5,s0,8
    800005c0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005c4:	000a4503          	lbu	a0,0(s4)
    800005c8:	16050263          	beqz	a0,8000072c <printf+0x1b2>
    800005cc:	4481                	li	s1,0
    if(c != '%'){
    800005ce:	02500a93          	li	s5,37
    switch(c){
    800005d2:	07000b13          	li	s6,112
  consputc('x');
    800005d6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d8:	00008b97          	auipc	s7,0x8
    800005dc:	a68b8b93          	addi	s7,s7,-1432 # 80008040 <digits>
    switch(c){
    800005e0:	07300c93          	li	s9,115
    800005e4:	06400c13          	li	s8,100
    800005e8:	a82d                	j	80000622 <printf+0xa8>
    acquire(&pr.lock);
    800005ea:	00011517          	auipc	a0,0x11
    800005ee:	c3e50513          	addi	a0,a0,-962 # 80011228 <pr>
    800005f2:	00000097          	auipc	ra,0x0
    800005f6:	5e4080e7          	jalr	1508(ra) # 80000bd6 <acquire>
    800005fa:	bf7d                	j	800005b8 <printf+0x3e>
    panic("null fmt");
    800005fc:	00008517          	auipc	a0,0x8
    80000600:	a2c50513          	addi	a0,a0,-1492 # 80008028 <etext+0x28>
    80000604:	00000097          	auipc	ra,0x0
    80000608:	f2c080e7          	jalr	-212(ra) # 80000530 <panic>
      consputc(c);
    8000060c:	00000097          	auipc	ra,0x0
    80000610:	c62080e7          	jalr	-926(ra) # 8000026e <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000614:	2485                	addiw	s1,s1,1
    80000616:	009a07b3          	add	a5,s4,s1
    8000061a:	0007c503          	lbu	a0,0(a5)
    8000061e:	10050763          	beqz	a0,8000072c <printf+0x1b2>
    if(c != '%'){
    80000622:	ff5515e3          	bne	a0,s5,8000060c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000626:	2485                	addiw	s1,s1,1
    80000628:	009a07b3          	add	a5,s4,s1
    8000062c:	0007c783          	lbu	a5,0(a5)
    80000630:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000634:	cfe5                	beqz	a5,8000072c <printf+0x1b2>
    switch(c){
    80000636:	05678a63          	beq	a5,s6,8000068a <printf+0x110>
    8000063a:	02fb7663          	bgeu	s6,a5,80000666 <printf+0xec>
    8000063e:	09978963          	beq	a5,s9,800006d0 <printf+0x156>
    80000642:	07800713          	li	a4,120
    80000646:	0ce79863          	bne	a5,a4,80000716 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000064a:	f8843783          	ld	a5,-120(s0)
    8000064e:	00878713          	addi	a4,a5,8
    80000652:	f8e43423          	sd	a4,-120(s0)
    80000656:	4605                	li	a2,1
    80000658:	85ea                	mv	a1,s10
    8000065a:	4388                	lw	a0,0(a5)
    8000065c:	00000097          	auipc	ra,0x0
    80000660:	e32080e7          	jalr	-462(ra) # 8000048e <printint>
      break;
    80000664:	bf45                	j	80000614 <printf+0x9a>
    switch(c){
    80000666:	0b578263          	beq	a5,s5,8000070a <printf+0x190>
    8000066a:	0b879663          	bne	a5,s8,80000716 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000066e:	f8843783          	ld	a5,-120(s0)
    80000672:	00878713          	addi	a4,a5,8
    80000676:	f8e43423          	sd	a4,-120(s0)
    8000067a:	4605                	li	a2,1
    8000067c:	45a9                	li	a1,10
    8000067e:	4388                	lw	a0,0(a5)
    80000680:	00000097          	auipc	ra,0x0
    80000684:	e0e080e7          	jalr	-498(ra) # 8000048e <printint>
      break;
    80000688:	b771                	j	80000614 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000068a:	f8843783          	ld	a5,-120(s0)
    8000068e:	00878713          	addi	a4,a5,8
    80000692:	f8e43423          	sd	a4,-120(s0)
    80000696:	0007b983          	ld	s3,0(a5)
  consputc('0');
    8000069a:	03000513          	li	a0,48
    8000069e:	00000097          	auipc	ra,0x0
    800006a2:	bd0080e7          	jalr	-1072(ra) # 8000026e <consputc>
  consputc('x');
    800006a6:	07800513          	li	a0,120
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	bc4080e7          	jalr	-1084(ra) # 8000026e <consputc>
    800006b2:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006b4:	03c9d793          	srli	a5,s3,0x3c
    800006b8:	97de                	add	a5,a5,s7
    800006ba:	0007c503          	lbu	a0,0(a5)
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bb0080e7          	jalr	-1104(ra) # 8000026e <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c6:	0992                	slli	s3,s3,0x4
    800006c8:	397d                	addiw	s2,s2,-1
    800006ca:	fe0915e3          	bnez	s2,800006b4 <printf+0x13a>
    800006ce:	b799                	j	80000614 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d0:	f8843783          	ld	a5,-120(s0)
    800006d4:	00878713          	addi	a4,a5,8
    800006d8:	f8e43423          	sd	a4,-120(s0)
    800006dc:	0007b903          	ld	s2,0(a5)
    800006e0:	00090e63          	beqz	s2,800006fc <printf+0x182>
      for(; *s; s++)
    800006e4:	00094503          	lbu	a0,0(s2)
    800006e8:	d515                	beqz	a0,80000614 <printf+0x9a>
        consputc(*s);
    800006ea:	00000097          	auipc	ra,0x0
    800006ee:	b84080e7          	jalr	-1148(ra) # 8000026e <consputc>
      for(; *s; s++)
    800006f2:	0905                	addi	s2,s2,1
    800006f4:	00094503          	lbu	a0,0(s2)
    800006f8:	f96d                	bnez	a0,800006ea <printf+0x170>
    800006fa:	bf29                	j	80000614 <printf+0x9a>
        s = "(null)";
    800006fc:	00008917          	auipc	s2,0x8
    80000700:	92490913          	addi	s2,s2,-1756 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000704:	02800513          	li	a0,40
    80000708:	b7cd                	j	800006ea <printf+0x170>
      consputc('%');
    8000070a:	8556                	mv	a0,s5
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	b62080e7          	jalr	-1182(ra) # 8000026e <consputc>
      break;
    80000714:	b701                	j	80000614 <printf+0x9a>
      consputc('%');
    80000716:	8556                	mv	a0,s5
    80000718:	00000097          	auipc	ra,0x0
    8000071c:	b56080e7          	jalr	-1194(ra) # 8000026e <consputc>
      consputc(c);
    80000720:	854a                	mv	a0,s2
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b4c080e7          	jalr	-1204(ra) # 8000026e <consputc>
      break;
    8000072a:	b5ed                	j	80000614 <printf+0x9a>
  if(locking)
    8000072c:	020d9163          	bnez	s11,8000074e <printf+0x1d4>
}
    80000730:	70e6                	ld	ra,120(sp)
    80000732:	7446                	ld	s0,112(sp)
    80000734:	74a6                	ld	s1,104(sp)
    80000736:	7906                	ld	s2,96(sp)
    80000738:	69e6                	ld	s3,88(sp)
    8000073a:	6a46                	ld	s4,80(sp)
    8000073c:	6aa6                	ld	s5,72(sp)
    8000073e:	6b06                	ld	s6,64(sp)
    80000740:	7be2                	ld	s7,56(sp)
    80000742:	7c42                	ld	s8,48(sp)
    80000744:	7ca2                	ld	s9,40(sp)
    80000746:	7d02                	ld	s10,32(sp)
    80000748:	6de2                	ld	s11,24(sp)
    8000074a:	6129                	addi	sp,sp,192
    8000074c:	8082                	ret
    release(&pr.lock);
    8000074e:	00011517          	auipc	a0,0x11
    80000752:	ada50513          	addi	a0,a0,-1318 # 80011228 <pr>
    80000756:	00000097          	auipc	ra,0x0
    8000075a:	534080e7          	jalr	1332(ra) # 80000c8a <release>
}
    8000075e:	bfc9                	j	80000730 <printf+0x1b6>

0000000080000760 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000760:	1101                	addi	sp,sp,-32
    80000762:	ec06                	sd	ra,24(sp)
    80000764:	e822                	sd	s0,16(sp)
    80000766:	e426                	sd	s1,8(sp)
    80000768:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076a:	00011497          	auipc	s1,0x11
    8000076e:	abe48493          	addi	s1,s1,-1346 # 80011228 <pr>
    80000772:	00008597          	auipc	a1,0x8
    80000776:	8c658593          	addi	a1,a1,-1850 # 80008038 <etext+0x38>
    8000077a:	8526                	mv	a0,s1
    8000077c:	00000097          	auipc	ra,0x0
    80000780:	3ca080e7          	jalr	970(ra) # 80000b46 <initlock>
  pr.locking = 1;
    80000784:	4785                	li	a5,1
    80000786:	cc9c                	sw	a5,24(s1)
}
    80000788:	60e2                	ld	ra,24(sp)
    8000078a:	6442                	ld	s0,16(sp)
    8000078c:	64a2                	ld	s1,8(sp)
    8000078e:	6105                	addi	sp,sp,32
    80000790:	8082                	ret

0000000080000792 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000792:	1141                	addi	sp,sp,-16
    80000794:	e406                	sd	ra,8(sp)
    80000796:	e022                	sd	s0,0(sp)
    80000798:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079a:	100007b7          	lui	a5,0x10000
    8000079e:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a2:	f8000713          	li	a4,-128
    800007a6:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007aa:	470d                	li	a4,3
    800007ac:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b0:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b4:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007b8:	469d                	li	a3,7
    800007ba:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007be:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c2:	00008597          	auipc	a1,0x8
    800007c6:	89658593          	addi	a1,a1,-1898 # 80008058 <digits+0x18>
    800007ca:	00011517          	auipc	a0,0x11
    800007ce:	a7e50513          	addi	a0,a0,-1410 # 80011248 <uart_tx_lock>
    800007d2:	00000097          	auipc	ra,0x0
    800007d6:	374080e7          	jalr	884(ra) # 80000b46 <initlock>
}
    800007da:	60a2                	ld	ra,8(sp)
    800007dc:	6402                	ld	s0,0(sp)
    800007de:	0141                	addi	sp,sp,16
    800007e0:	8082                	ret

00000000800007e2 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e2:	1101                	addi	sp,sp,-32
    800007e4:	ec06                	sd	ra,24(sp)
    800007e6:	e822                	sd	s0,16(sp)
    800007e8:	e426                	sd	s1,8(sp)
    800007ea:	1000                	addi	s0,sp,32
    800007ec:	84aa                	mv	s1,a0
  push_off();
    800007ee:	00000097          	auipc	ra,0x0
    800007f2:	39c080e7          	jalr	924(ra) # 80000b8a <push_off>

  if(panicked){
    800007f6:	00009797          	auipc	a5,0x9
    800007fa:	80a7a783          	lw	a5,-2038(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fe:	10000737          	lui	a4,0x10000
  if(panicked){
    80000802:	c391                	beqz	a5,80000806 <uartputc_sync+0x24>
    for(;;)
    80000804:	a001                	j	80000804 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080a:	0ff7f793          	andi	a5,a5,255
    8000080e:	0207f793          	andi	a5,a5,32
    80000812:	dbf5                	beqz	a5,80000806 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000814:	0ff4f793          	andi	a5,s1,255
    80000818:	10000737          	lui	a4,0x10000
    8000081c:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000820:	00000097          	auipc	ra,0x0
    80000824:	40a080e7          	jalr	1034(ra) # 80000c2a <pop_off>
}
    80000828:	60e2                	ld	ra,24(sp)
    8000082a:	6442                	ld	s0,16(sp)
    8000082c:	64a2                	ld	s1,8(sp)
    8000082e:	6105                	addi	sp,sp,32
    80000830:	8082                	ret

0000000080000832 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000832:	00008717          	auipc	a4,0x8
    80000836:	7d673703          	ld	a4,2006(a4) # 80009008 <uart_tx_r>
    8000083a:	00008797          	auipc	a5,0x8
    8000083e:	7d67b783          	ld	a5,2006(a5) # 80009010 <uart_tx_w>
    80000842:	06e78c63          	beq	a5,a4,800008ba <uartstart+0x88>
{
    80000846:	7139                	addi	sp,sp,-64
    80000848:	fc06                	sd	ra,56(sp)
    8000084a:	f822                	sd	s0,48(sp)
    8000084c:	f426                	sd	s1,40(sp)
    8000084e:	f04a                	sd	s2,32(sp)
    80000850:	ec4e                	sd	s3,24(sp)
    80000852:	e852                	sd	s4,16(sp)
    80000854:	e456                	sd	s5,8(sp)
    80000856:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000858:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085c:	00011a17          	auipc	s4,0x11
    80000860:	9eca0a13          	addi	s4,s4,-1556 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000864:	00008497          	auipc	s1,0x8
    80000868:	7a448493          	addi	s1,s1,1956 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086c:	00008997          	auipc	s3,0x8
    80000870:	7a498993          	addi	s3,s3,1956 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000874:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000878:	0ff7f793          	andi	a5,a5,255
    8000087c:	0207f793          	andi	a5,a5,32
    80000880:	c785                	beqz	a5,800008a8 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f77793          	andi	a5,a4,31
    80000886:	97d2                	add	a5,a5,s4
    80000888:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000088c:	0705                	addi	a4,a4,1
    8000088e:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	c04080e7          	jalr	-1020(ra) # 80002496 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	6098                	ld	a4,0(s1)
    800008a0:	0009b783          	ld	a5,0(s3)
    800008a4:	fce798e3          	bne	a5,a4,80000874 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008ce:	00011517          	auipc	a0,0x11
    800008d2:	97a50513          	addi	a0,a0,-1670 # 80011248 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	7227a783          	lw	a5,1826(a5) # 80009000 <panicked>
    800008e6:	c391                	beqz	a5,800008ea <uartputc+0x2e>
    for(;;)
    800008e8:	a001                	j	800008e8 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008797          	auipc	a5,0x8
    800008ee:	7267b783          	ld	a5,1830(a5) # 80009010 <uart_tx_w>
    800008f2:	00008717          	auipc	a4,0x8
    800008f6:	71673703          	ld	a4,1814(a4) # 80009008 <uart_tx_r>
    800008fa:	02070713          	addi	a4,a4,32
    800008fe:	02f71b63          	bne	a4,a5,80000934 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000902:	00011a17          	auipc	s4,0x11
    80000906:	946a0a13          	addi	s4,s4,-1722 # 80011248 <uart_tx_lock>
    8000090a:	00008497          	auipc	s1,0x8
    8000090e:	6fe48493          	addi	s1,s1,1790 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00008917          	auipc	s2,0x8
    80000916:	6fe90913          	addi	s2,s2,1790 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85d2                	mv	a1,s4
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	9f2080e7          	jalr	-1550(ra) # 80002310 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093783          	ld	a5,0(s2)
    8000092a:	6098                	ld	a4,0(s1)
    8000092c:	02070713          	addi	a4,a4,32
    80000930:	fef705e3          	beq	a4,a5,8000091a <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00011497          	auipc	s1,0x11
    80000938:	91448493          	addi	s1,s1,-1772 # 80011248 <uart_tx_lock>
    8000093c:	01f7f713          	andi	a4,a5,31
    80000940:	9726                	add	a4,a4,s1
    80000942:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000946:	0785                	addi	a5,a5,1
    80000948:	00008717          	auipc	a4,0x8
    8000094c:	6cf73423          	sd	a5,1736(a4) # 80009010 <uart_tx_w>
      uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee2080e7          	jalr	-286(ra) # 80000832 <uartstart>
      release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    int c = uartgetc();
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	fcc080e7          	jalr	-52(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009ae:	00950763          	beq	a0,s1,800009bc <uartintr+0x22>
      break;
    consoleintr(c);
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	8fe080e7          	jalr	-1794(ra) # 800002b0 <consoleintr>
  while(1){
    800009ba:	b7f5                	j	800009a6 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00011497          	auipc	s1,0x11
    800009c0:	88c48493          	addi	s1,s1,-1908 # 80011248 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e64080e7          	jalr	-412(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00025797          	auipc	a5,0x25
    80000a02:	60278793          	addi	a5,a5,1538 # 80026000 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00011917          	auipc	s2,0x11
    80000a22:	86290913          	addi	s2,s2,-1950 # 80011280 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ad8080e7          	jalr	-1320(ra) # 80000530 <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	7c650513          	addi	a0,a0,1990 # 80011280 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00025517          	auipc	a0,0x25
    80000ad2:	53250513          	addi	a0,a0,1330 # 80026000 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	79048493          	addi	s1,s1,1936 # 80011280 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	77850513          	addi	a0,a0,1912 # 80011280 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	74c50513          	addi	a0,a0,1868 # 80011280 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	01a080e7          	jalr	26(ra) # 80001b8a <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	fe8080e7          	jalr	-24(ra) # 80001b8a <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	fdc080e7          	jalr	-36(ra) # 80001b8a <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	fc4080e7          	jalr	-60(ra) # 80001b8a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	f84080e7          	jalr	-124(ra) # 80001b8a <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	90e080e7          	jalr	-1778(ra) # 80000530 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	f58080e7          	jalr	-168(ra) # 80001b8a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8be080e7          	jalr	-1858(ra) # 80000530 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8ae080e7          	jalr	-1874(ra) # 80000530 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	866080e7          	jalr	-1946(ra) # 80000530 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ce09                	beqz	a2,80000cf2 <memset+0x20>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	fff6071b          	addiw	a4,a2,-1
    80000ce0:	1702                	slli	a4,a4,0x20
    80000ce2:	9301                	srli	a4,a4,0x20
    80000ce4:	0705                	addi	a4,a4,1
    80000ce6:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000ce8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cec:	0785                	addi	a5,a5,1
    80000cee:	fee79de3          	bne	a5,a4,80000ce8 <memset+0x16>
  }
  return dst;
}
    80000cf2:	6422                	ld	s0,8(sp)
    80000cf4:	0141                	addi	sp,sp,16
    80000cf6:	8082                	ret

0000000080000cf8 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf8:	1141                	addi	sp,sp,-16
    80000cfa:	e422                	sd	s0,8(sp)
    80000cfc:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfe:	ca05                	beqz	a2,80000d2e <memcmp+0x36>
    80000d00:	fff6069b          	addiw	a3,a2,-1
    80000d04:	1682                	slli	a3,a3,0x20
    80000d06:	9281                	srli	a3,a3,0x20
    80000d08:	0685                	addi	a3,a3,1
    80000d0a:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d0c:	00054783          	lbu	a5,0(a0)
    80000d10:	0005c703          	lbu	a4,0(a1)
    80000d14:	00e79863          	bne	a5,a4,80000d24 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d18:	0505                	addi	a0,a0,1
    80000d1a:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d1c:	fed518e3          	bne	a0,a3,80000d0c <memcmp+0x14>
  }

  return 0;
    80000d20:	4501                	li	a0,0
    80000d22:	a019                	j	80000d28 <memcmp+0x30>
      return *s1 - *s2;
    80000d24:	40e7853b          	subw	a0,a5,a4
}
    80000d28:	6422                	ld	s0,8(sp)
    80000d2a:	0141                	addi	sp,sp,16
    80000d2c:	8082                	ret
  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	bfe5                	j	80000d28 <memcmp+0x30>

0000000080000d32 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e422                	sd	s0,8(sp)
    80000d36:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d38:	00a5f963          	bgeu	a1,a0,80000d4a <memmove+0x18>
    80000d3c:	02061713          	slli	a4,a2,0x20
    80000d40:	9301                	srli	a4,a4,0x20
    80000d42:	00e587b3          	add	a5,a1,a4
    80000d46:	02f56563          	bltu	a0,a5,80000d70 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d4a:	fff6069b          	addiw	a3,a2,-1
    80000d4e:	ce11                	beqz	a2,80000d6a <memmove+0x38>
    80000d50:	1682                	slli	a3,a3,0x20
    80000d52:	9281                	srli	a3,a3,0x20
    80000d54:	0685                	addi	a3,a3,1
    80000d56:	96ae                	add	a3,a3,a1
    80000d58:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d5a:	0585                	addi	a1,a1,1
    80000d5c:	0785                	addi	a5,a5,1
    80000d5e:	fff5c703          	lbu	a4,-1(a1)
    80000d62:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d66:	fed59ae3          	bne	a1,a3,80000d5a <memmove+0x28>

  return dst;
}
    80000d6a:	6422                	ld	s0,8(sp)
    80000d6c:	0141                	addi	sp,sp,16
    80000d6e:	8082                	ret
    d += n;
    80000d70:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d72:	fff6069b          	addiw	a3,a2,-1
    80000d76:	da75                	beqz	a2,80000d6a <memmove+0x38>
    80000d78:	02069613          	slli	a2,a3,0x20
    80000d7c:	9201                	srli	a2,a2,0x20
    80000d7e:	fff64613          	not	a2,a2
    80000d82:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d84:	17fd                	addi	a5,a5,-1
    80000d86:	177d                	addi	a4,a4,-1
    80000d88:	0007c683          	lbu	a3,0(a5)
    80000d8c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d90:	fec79ae3          	bne	a5,a2,80000d84 <memmove+0x52>
    80000d94:	bfd9                	j	80000d6a <memmove+0x38>

0000000080000d96 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e406                	sd	ra,8(sp)
    80000d9a:	e022                	sd	s0,0(sp)
    80000d9c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d9e:	00000097          	auipc	ra,0x0
    80000da2:	f94080e7          	jalr	-108(ra) # 80000d32 <memmove>
}
    80000da6:	60a2                	ld	ra,8(sp)
    80000da8:	6402                	ld	s0,0(sp)
    80000daa:	0141                	addi	sp,sp,16
    80000dac:	8082                	ret

0000000080000dae <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dae:	1141                	addi	sp,sp,-16
    80000db0:	e422                	sd	s0,8(sp)
    80000db2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000db4:	ce11                	beqz	a2,80000dd0 <strncmp+0x22>
    80000db6:	00054783          	lbu	a5,0(a0)
    80000dba:	cf89                	beqz	a5,80000dd4 <strncmp+0x26>
    80000dbc:	0005c703          	lbu	a4,0(a1)
    80000dc0:	00f71a63          	bne	a4,a5,80000dd4 <strncmp+0x26>
    n--, p++, q++;
    80000dc4:	367d                	addiw	a2,a2,-1
    80000dc6:	0505                	addi	a0,a0,1
    80000dc8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dca:	f675                	bnez	a2,80000db6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dcc:	4501                	li	a0,0
    80000dce:	a809                	j	80000de0 <strncmp+0x32>
    80000dd0:	4501                	li	a0,0
    80000dd2:	a039                	j	80000de0 <strncmp+0x32>
  if(n == 0)
    80000dd4:	ca09                	beqz	a2,80000de6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dd6:	00054503          	lbu	a0,0(a0)
    80000dda:	0005c783          	lbu	a5,0(a1)
    80000dde:	9d1d                	subw	a0,a0,a5
}
    80000de0:	6422                	ld	s0,8(sp)
    80000de2:	0141                	addi	sp,sp,16
    80000de4:	8082                	ret
    return 0;
    80000de6:	4501                	li	a0,0
    80000de8:	bfe5                	j	80000de0 <strncmp+0x32>

0000000080000dea <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dea:	1141                	addi	sp,sp,-16
    80000dec:	e422                	sd	s0,8(sp)
    80000dee:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000df0:	872a                	mv	a4,a0
    80000df2:	8832                	mv	a6,a2
    80000df4:	367d                	addiw	a2,a2,-1
    80000df6:	01005963          	blez	a6,80000e08 <strncpy+0x1e>
    80000dfa:	0705                	addi	a4,a4,1
    80000dfc:	0005c783          	lbu	a5,0(a1)
    80000e00:	fef70fa3          	sb	a5,-1(a4)
    80000e04:	0585                	addi	a1,a1,1
    80000e06:	f7f5                	bnez	a5,80000df2 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e08:	00c05d63          	blez	a2,80000e22 <strncpy+0x38>
    80000e0c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e0e:	0685                	addi	a3,a3,1
    80000e10:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e14:	fff6c793          	not	a5,a3
    80000e18:	9fb9                	addw	a5,a5,a4
    80000e1a:	010787bb          	addw	a5,a5,a6
    80000e1e:	fef048e3          	bgtz	a5,80000e0e <strncpy+0x24>
  return os;
}
    80000e22:	6422                	ld	s0,8(sp)
    80000e24:	0141                	addi	sp,sp,16
    80000e26:	8082                	ret

0000000080000e28 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e28:	1141                	addi	sp,sp,-16
    80000e2a:	e422                	sd	s0,8(sp)
    80000e2c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e2e:	02c05363          	blez	a2,80000e54 <safestrcpy+0x2c>
    80000e32:	fff6069b          	addiw	a3,a2,-1
    80000e36:	1682                	slli	a3,a3,0x20
    80000e38:	9281                	srli	a3,a3,0x20
    80000e3a:	96ae                	add	a3,a3,a1
    80000e3c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e3e:	00d58963          	beq	a1,a3,80000e50 <safestrcpy+0x28>
    80000e42:	0585                	addi	a1,a1,1
    80000e44:	0785                	addi	a5,a5,1
    80000e46:	fff5c703          	lbu	a4,-1(a1)
    80000e4a:	fee78fa3          	sb	a4,-1(a5)
    80000e4e:	fb65                	bnez	a4,80000e3e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e50:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e54:	6422                	ld	s0,8(sp)
    80000e56:	0141                	addi	sp,sp,16
    80000e58:	8082                	ret

0000000080000e5a <strlen>:

int
strlen(const char *s)
{
    80000e5a:	1141                	addi	sp,sp,-16
    80000e5c:	e422                	sd	s0,8(sp)
    80000e5e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e60:	00054783          	lbu	a5,0(a0)
    80000e64:	cf91                	beqz	a5,80000e80 <strlen+0x26>
    80000e66:	0505                	addi	a0,a0,1
    80000e68:	87aa                	mv	a5,a0
    80000e6a:	4685                	li	a3,1
    80000e6c:	9e89                	subw	a3,a3,a0
    80000e6e:	00f6853b          	addw	a0,a3,a5
    80000e72:	0785                	addi	a5,a5,1
    80000e74:	fff7c703          	lbu	a4,-1(a5)
    80000e78:	fb7d                	bnez	a4,80000e6e <strlen+0x14>
    ;
  return n;
}
    80000e7a:	6422                	ld	s0,8(sp)
    80000e7c:	0141                	addi	sp,sp,16
    80000e7e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e80:	4501                	li	a0,0
    80000e82:	bfe5                	j	80000e7a <strlen+0x20>

0000000080000e84 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e84:	1141                	addi	sp,sp,-16
    80000e86:	e406                	sd	ra,8(sp)
    80000e88:	e022                	sd	s0,0(sp)
    80000e8a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e8c:	00001097          	auipc	ra,0x1
    80000e90:	cee080e7          	jalr	-786(ra) # 80001b7a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e94:	00008717          	auipc	a4,0x8
    80000e98:	18470713          	addi	a4,a4,388 # 80009018 <started>
  if(cpuid() == 0){
    80000e9c:	c139                	beqz	a0,80000ee2 <main+0x5e>
    while(started == 0)
    80000e9e:	431c                	lw	a5,0(a4)
    80000ea0:	2781                	sext.w	a5,a5
    80000ea2:	dff5                	beqz	a5,80000e9e <main+0x1a>
      ;
    __sync_synchronize();
    80000ea4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ea8:	00001097          	auipc	ra,0x1
    80000eac:	cd2080e7          	jalr	-814(ra) # 80001b7a <cpuid>
    80000eb0:	85aa                	mv	a1,a0
    80000eb2:	00007517          	auipc	a0,0x7
    80000eb6:	20650513          	addi	a0,a0,518 # 800080b8 <digits+0x78>
    80000eba:	fffff097          	auipc	ra,0xfffff
    80000ebe:	6c0080e7          	jalr	1728(ra) # 8000057a <printf>
    kvminithart();    // turn on paging
    80000ec2:	00000097          	auipc	ra,0x0
    80000ec6:	0d8080e7          	jalr	216(ra) # 80000f9a <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eca:	00002097          	auipc	ra,0x2
    80000ece:	a86080e7          	jalr	-1402(ra) # 80002950 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ed2:	00005097          	auipc	ra,0x5
    80000ed6:	33e080e7          	jalr	830(ra) # 80006210 <plicinithart>
  }

  scheduler();        
    80000eda:	00001097          	auipc	ra,0x1
    80000ede:	0f2080e7          	jalr	242(ra) # 80001fcc <scheduler>
    consoleinit();
    80000ee2:	fffff097          	auipc	ra,0xfffff
    80000ee6:	560080e7          	jalr	1376(ra) # 80000442 <consoleinit>
    printfinit();
    80000eea:	00000097          	auipc	ra,0x0
    80000eee:	876080e7          	jalr	-1930(ra) # 80000760 <printfinit>
    printf("\n");
    80000ef2:	00007517          	auipc	a0,0x7
    80000ef6:	2d650513          	addi	a0,a0,726 # 800081c8 <digits+0x188>
    80000efa:	fffff097          	auipc	ra,0xfffff
    80000efe:	680080e7          	jalr	1664(ra) # 8000057a <printf>
    printf("xv6 kernel is booting\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	19e50513          	addi	a0,a0,414 # 800080a0 <digits+0x60>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	670080e7          	jalr	1648(ra) # 8000057a <printf>
    printf("\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	2b650513          	addi	a0,a0,694 # 800081c8 <digits+0x188>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	660080e7          	jalr	1632(ra) # 8000057a <printf>
    kinit();         // physical page allocator
    80000f22:	00000097          	auipc	ra,0x0
    80000f26:	b88080e7          	jalr	-1144(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f2a:	00000097          	auipc	ra,0x0
    80000f2e:	310080e7          	jalr	784(ra) # 8000123a <kvminit>
    kvminithart();   // turn on paging
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	068080e7          	jalr	104(ra) # 80000f9a <kvminithart>
    procinit();      // process table
    80000f3a:	00001097          	auipc	ra,0x1
    80000f3e:	ba8080e7          	jalr	-1112(ra) # 80001ae2 <procinit>
    trapinit();      // trap vectors
    80000f42:	00002097          	auipc	ra,0x2
    80000f46:	9e6080e7          	jalr	-1562(ra) # 80002928 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	a06080e7          	jalr	-1530(ra) # 80002950 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f52:	00005097          	auipc	ra,0x5
    80000f56:	2a8080e7          	jalr	680(ra) # 800061fa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f5a:	00005097          	auipc	ra,0x5
    80000f5e:	2b6080e7          	jalr	694(ra) # 80006210 <plicinithart>
    binit();         // buffer cache
    80000f62:	00002097          	auipc	ra,0x2
    80000f66:	170080e7          	jalr	368(ra) # 800030d2 <binit>
    iinit();         // inode cache
    80000f6a:	00003097          	auipc	ra,0x3
    80000f6e:	800080e7          	jalr	-2048(ra) # 8000376a <iinit>
    fileinit();      // file table
    80000f72:	00003097          	auipc	ra,0x3
    80000f76:	7b2080e7          	jalr	1970(ra) # 80004724 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f7a:	00005097          	auipc	ra,0x5
    80000f7e:	3b8080e7          	jalr	952(ra) # 80006332 <virtio_disk_init>
    userinit();      // first user process
    80000f82:	00001097          	auipc	ra,0x1
    80000f86:	eee080e7          	jalr	-274(ra) # 80001e70 <userinit>
    __sync_synchronize();
    80000f8a:	0ff0000f          	fence
    started = 1;
    80000f8e:	4785                	li	a5,1
    80000f90:	00008717          	auipc	a4,0x8
    80000f94:	08f72423          	sw	a5,136(a4) # 80009018 <started>
    80000f98:	b789                	j	80000eda <main+0x56>

0000000080000f9a <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f9a:	1141                	addi	sp,sp,-16
    80000f9c:	e422                	sd	s0,8(sp)
    80000f9e:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fa0:	00008797          	auipc	a5,0x8
    80000fa4:	0807b783          	ld	a5,128(a5) # 80009020 <kernel_pagetable>
    80000fa8:	83b1                	srli	a5,a5,0xc
    80000faa:	577d                	li	a4,-1
    80000fac:	177e                	slli	a4,a4,0x3f
    80000fae:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fb0:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb4:	12000073          	sfence.vma
  sfence_vma();
}
    80000fb8:	6422                	ld	s0,8(sp)
    80000fba:	0141                	addi	sp,sp,16
    80000fbc:	8082                	ret

0000000080000fbe <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fbe:	7139                	addi	sp,sp,-64
    80000fc0:	fc06                	sd	ra,56(sp)
    80000fc2:	f822                	sd	s0,48(sp)
    80000fc4:	f426                	sd	s1,40(sp)
    80000fc6:	f04a                	sd	s2,32(sp)
    80000fc8:	ec4e                	sd	s3,24(sp)
    80000fca:	e852                	sd	s4,16(sp)
    80000fcc:	e456                	sd	s5,8(sp)
    80000fce:	e05a                	sd	s6,0(sp)
    80000fd0:	0080                	addi	s0,sp,64
    80000fd2:	84aa                	mv	s1,a0
    80000fd4:	89ae                	mv	s3,a1
    80000fd6:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd8:	57fd                	li	a5,-1
    80000fda:	83e9                	srli	a5,a5,0x1a
    80000fdc:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fde:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fe0:	04b7f263          	bgeu	a5,a1,80001024 <walk+0x66>
    panic("walk");
    80000fe4:	00007517          	auipc	a0,0x7
    80000fe8:	0ec50513          	addi	a0,a0,236 # 800080d0 <digits+0x90>
    80000fec:	fffff097          	auipc	ra,0xfffff
    80000ff0:	544080e7          	jalr	1348(ra) # 80000530 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ff4:	060a8663          	beqz	s5,80001060 <walk+0xa2>
    80000ff8:	00000097          	auipc	ra,0x0
    80000ffc:	aee080e7          	jalr	-1298(ra) # 80000ae6 <kalloc>
    80001000:	84aa                	mv	s1,a0
    80001002:	c529                	beqz	a0,8000104c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001004:	6605                	lui	a2,0x1
    80001006:	4581                	li	a1,0
    80001008:	00000097          	auipc	ra,0x0
    8000100c:	cca080e7          	jalr	-822(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001010:	00c4d793          	srli	a5,s1,0xc
    80001014:	07aa                	slli	a5,a5,0xa
    80001016:	0017e793          	ori	a5,a5,1
    8000101a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000101e:	3a5d                	addiw	s4,s4,-9
    80001020:	036a0063          	beq	s4,s6,80001040 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001024:	0149d933          	srl	s2,s3,s4
    80001028:	1ff97913          	andi	s2,s2,511
    8000102c:	090e                	slli	s2,s2,0x3
    8000102e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001030:	00093483          	ld	s1,0(s2)
    80001034:	0014f793          	andi	a5,s1,1
    80001038:	dfd5                	beqz	a5,80000ff4 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000103a:	80a9                	srli	s1,s1,0xa
    8000103c:	04b2                	slli	s1,s1,0xc
    8000103e:	b7c5                	j	8000101e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001040:	00c9d513          	srli	a0,s3,0xc
    80001044:	1ff57513          	andi	a0,a0,511
    80001048:	050e                	slli	a0,a0,0x3
    8000104a:	9526                	add	a0,a0,s1
}
    8000104c:	70e2                	ld	ra,56(sp)
    8000104e:	7442                	ld	s0,48(sp)
    80001050:	74a2                	ld	s1,40(sp)
    80001052:	7902                	ld	s2,32(sp)
    80001054:	69e2                	ld	s3,24(sp)
    80001056:	6a42                	ld	s4,16(sp)
    80001058:	6aa2                	ld	s5,8(sp)
    8000105a:	6b02                	ld	s6,0(sp)
    8000105c:	6121                	addi	sp,sp,64
    8000105e:	8082                	ret
        return 0;
    80001060:	4501                	li	a0,0
    80001062:	b7ed                	j	8000104c <walk+0x8e>

0000000080001064 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001064:	57fd                	li	a5,-1
    80001066:	83e9                	srli	a5,a5,0x1a
    80001068:	00b7f463          	bgeu	a5,a1,80001070 <walkaddr+0xc>
    return 0;
    8000106c:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000106e:	8082                	ret
{
    80001070:	1141                	addi	sp,sp,-16
    80001072:	e406                	sd	ra,8(sp)
    80001074:	e022                	sd	s0,0(sp)
    80001076:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001078:	4601                	li	a2,0
    8000107a:	00000097          	auipc	ra,0x0
    8000107e:	f44080e7          	jalr	-188(ra) # 80000fbe <walk>
  if(pte == 0)
    80001082:	c105                	beqz	a0,800010a2 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001084:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001086:	0117f693          	andi	a3,a5,17
    8000108a:	4745                	li	a4,17
    return 0;
    8000108c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000108e:	00e68663          	beq	a3,a4,8000109a <walkaddr+0x36>
}
    80001092:	60a2                	ld	ra,8(sp)
    80001094:	6402                	ld	s0,0(sp)
    80001096:	0141                	addi	sp,sp,16
    80001098:	8082                	ret
  pa = PTE2PA(*pte);
    8000109a:	00a7d513          	srli	a0,a5,0xa
    8000109e:	0532                	slli	a0,a0,0xc
  return pa;
    800010a0:	bfcd                	j	80001092 <walkaddr+0x2e>
    return 0;
    800010a2:	4501                	li	a0,0
    800010a4:	b7fd                	j	80001092 <walkaddr+0x2e>

00000000800010a6 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010a6:	715d                	addi	sp,sp,-80
    800010a8:	e486                	sd	ra,72(sp)
    800010aa:	e0a2                	sd	s0,64(sp)
    800010ac:	fc26                	sd	s1,56(sp)
    800010ae:	f84a                	sd	s2,48(sp)
    800010b0:	f44e                	sd	s3,40(sp)
    800010b2:	f052                	sd	s4,32(sp)
    800010b4:	ec56                	sd	s5,24(sp)
    800010b6:	e85a                	sd	s6,16(sp)
    800010b8:	e45e                	sd	s7,8(sp)
    800010ba:	0880                	addi	s0,sp,80
    800010bc:	8aaa                	mv	s5,a0
    800010be:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010c0:	777d                	lui	a4,0xfffff
    800010c2:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c6:	167d                	addi	a2,a2,-1
    800010c8:	00b609b3          	add	s3,a2,a1
    800010cc:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010d0:	893e                	mv	s2,a5
    800010d2:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d6:	6b85                	lui	s7,0x1
    800010d8:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010dc:	4605                	li	a2,1
    800010de:	85ca                	mv	a1,s2
    800010e0:	8556                	mv	a0,s5
    800010e2:	00000097          	auipc	ra,0x0
    800010e6:	edc080e7          	jalr	-292(ra) # 80000fbe <walk>
    800010ea:	c51d                	beqz	a0,80001118 <mappages+0x72>
    if(*pte & PTE_V)
    800010ec:	611c                	ld	a5,0(a0)
    800010ee:	8b85                	andi	a5,a5,1
    800010f0:	ef81                	bnez	a5,80001108 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010f2:	80b1                	srli	s1,s1,0xc
    800010f4:	04aa                	slli	s1,s1,0xa
    800010f6:	0164e4b3          	or	s1,s1,s6
    800010fa:	0014e493          	ori	s1,s1,1
    800010fe:	e104                	sd	s1,0(a0)
    if(a == last)
    80001100:	03390863          	beq	s2,s3,80001130 <mappages+0x8a>
    a += PGSIZE;
    80001104:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001106:	bfc9                	j	800010d8 <mappages+0x32>
      panic("remap");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fd050513          	addi	a0,a0,-48 # 800080d8 <digits+0x98>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	420080e7          	jalr	1056(ra) # 80000530 <panic>
      return -1;
    80001118:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111a:	60a6                	ld	ra,72(sp)
    8000111c:	6406                	ld	s0,64(sp)
    8000111e:	74e2                	ld	s1,56(sp)
    80001120:	7942                	ld	s2,48(sp)
    80001122:	79a2                	ld	s3,40(sp)
    80001124:	7a02                	ld	s4,32(sp)
    80001126:	6ae2                	ld	s5,24(sp)
    80001128:	6b42                	ld	s6,16(sp)
    8000112a:	6ba2                	ld	s7,8(sp)
    8000112c:	6161                	addi	sp,sp,80
    8000112e:	8082                	ret
  return 0;
    80001130:	4501                	li	a0,0
    80001132:	b7e5                	j	8000111a <mappages+0x74>

0000000080001134 <kvmmap>:
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e406                	sd	ra,8(sp)
    80001138:	e022                	sd	s0,0(sp)
    8000113a:	0800                	addi	s0,sp,16
    8000113c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000113e:	86b2                	mv	a3,a2
    80001140:	863e                	mv	a2,a5
    80001142:	00000097          	auipc	ra,0x0
    80001146:	f64080e7          	jalr	-156(ra) # 800010a6 <mappages>
    8000114a:	e509                	bnez	a0,80001154 <kvmmap+0x20>
}
    8000114c:	60a2                	ld	ra,8(sp)
    8000114e:	6402                	ld	s0,0(sp)
    80001150:	0141                	addi	sp,sp,16
    80001152:	8082                	ret
    panic("kvmmap");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	f8c50513          	addi	a0,a0,-116 # 800080e0 <digits+0xa0>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3d4080e7          	jalr	980(ra) # 80000530 <panic>

0000000080001164 <kvmmake>:
{
    80001164:	1101                	addi	sp,sp,-32
    80001166:	ec06                	sd	ra,24(sp)
    80001168:	e822                	sd	s0,16(sp)
    8000116a:	e426                	sd	s1,8(sp)
    8000116c:	e04a                	sd	s2,0(sp)
    8000116e:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001170:	00000097          	auipc	ra,0x0
    80001174:	976080e7          	jalr	-1674(ra) # 80000ae6 <kalloc>
    80001178:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117a:	6605                	lui	a2,0x1
    8000117c:	4581                	li	a1,0
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	b54080e7          	jalr	-1196(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001186:	4719                	li	a4,6
    80001188:	6685                	lui	a3,0x1
    8000118a:	10000637          	lui	a2,0x10000
    8000118e:	100005b7          	lui	a1,0x10000
    80001192:	8526                	mv	a0,s1
    80001194:	00000097          	auipc	ra,0x0
    80001198:	fa0080e7          	jalr	-96(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000119c:	4719                	li	a4,6
    8000119e:	6685                	lui	a3,0x1
    800011a0:	10001637          	lui	a2,0x10001
    800011a4:	100015b7          	lui	a1,0x10001
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f8a080e7          	jalr	-118(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	004006b7          	lui	a3,0x400
    800011b8:	0c000637          	lui	a2,0xc000
    800011bc:	0c0005b7          	lui	a1,0xc000
    800011c0:	8526                	mv	a0,s1
    800011c2:	00000097          	auipc	ra,0x0
    800011c6:	f72080e7          	jalr	-142(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ca:	00007917          	auipc	s2,0x7
    800011ce:	e3690913          	addi	s2,s2,-458 # 80008000 <etext>
    800011d2:	4729                	li	a4,10
    800011d4:	80007697          	auipc	a3,0x80007
    800011d8:	e2c68693          	addi	a3,a3,-468 # 8000 <_entry-0x7fff8000>
    800011dc:	4605                	li	a2,1
    800011de:	067e                	slli	a2,a2,0x1f
    800011e0:	85b2                	mv	a1,a2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f50080e7          	jalr	-176(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011ec:	4719                	li	a4,6
    800011ee:	46c5                	li	a3,17
    800011f0:	06ee                	slli	a3,a3,0x1b
    800011f2:	412686b3          	sub	a3,a3,s2
    800011f6:	864a                	mv	a2,s2
    800011f8:	85ca                	mv	a1,s2
    800011fa:	8526                	mv	a0,s1
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f38080e7          	jalr	-200(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001204:	4729                	li	a4,10
    80001206:	6685                	lui	a3,0x1
    80001208:	00006617          	auipc	a2,0x6
    8000120c:	df860613          	addi	a2,a2,-520 # 80007000 <_trampoline>
    80001210:	040005b7          	lui	a1,0x4000
    80001214:	15fd                	addi	a1,a1,-1
    80001216:	05b2                	slli	a1,a1,0xc
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f1a080e7          	jalr	-230(ra) # 80001134 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001222:	8526                	mv	a0,s1
    80001224:	00001097          	auipc	ra,0x1
    80001228:	828080e7          	jalr	-2008(ra) # 80001a4c <proc_mapstacks>
}
    8000122c:	8526                	mv	a0,s1
    8000122e:	60e2                	ld	ra,24(sp)
    80001230:	6442                	ld	s0,16(sp)
    80001232:	64a2                	ld	s1,8(sp)
    80001234:	6902                	ld	s2,0(sp)
    80001236:	6105                	addi	sp,sp,32
    80001238:	8082                	ret

000000008000123a <kvminit>:
{
    8000123a:	1141                	addi	sp,sp,-16
    8000123c:	e406                	sd	ra,8(sp)
    8000123e:	e022                	sd	s0,0(sp)
    80001240:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001242:	00000097          	auipc	ra,0x0
    80001246:	f22080e7          	jalr	-222(ra) # 80001164 <kvmmake>
    8000124a:	00008797          	auipc	a5,0x8
    8000124e:	dca7bb23          	sd	a0,-554(a5) # 80009020 <kernel_pagetable>
}
    80001252:	60a2                	ld	ra,8(sp)
    80001254:	6402                	ld	s0,0(sp)
    80001256:	0141                	addi	sp,sp,16
    80001258:	8082                	ret

000000008000125a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125a:	715d                	addi	sp,sp,-80
    8000125c:	e486                	sd	ra,72(sp)
    8000125e:	e0a2                	sd	s0,64(sp)
    80001260:	fc26                	sd	s1,56(sp)
    80001262:	f84a                	sd	s2,48(sp)
    80001264:	f44e                	sd	s3,40(sp)
    80001266:	f052                	sd	s4,32(sp)
    80001268:	ec56                	sd	s5,24(sp)
    8000126a:	e85a                	sd	s6,16(sp)
    8000126c:	e45e                	sd	s7,8(sp)
    8000126e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001270:	03459793          	slli	a5,a1,0x34
    80001274:	e795                	bnez	a5,800012a0 <uvmunmap+0x46>
    80001276:	8a2a                	mv	s4,a0
    80001278:	892e                	mv	s2,a1
    8000127a:	8b36                	mv	s6,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	0632                	slli	a2,a2,0xc
    8000127e:	00b609b3          	add	s3,a2,a1
      continue;
      //panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      continue;
      //panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001282:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001284:	6a85                	lui	s5,0x1
    80001286:	0535e963          	bltu	a1,s3,800012d8 <uvmunmap+0x7e>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128a:	60a6                	ld	ra,72(sp)
    8000128c:	6406                	ld	s0,64(sp)
    8000128e:	74e2                	ld	s1,56(sp)
    80001290:	7942                	ld	s2,48(sp)
    80001292:	79a2                	ld	s3,40(sp)
    80001294:	7a02                	ld	s4,32(sp)
    80001296:	6ae2                	ld	s5,24(sp)
    80001298:	6b42                	ld	s6,16(sp)
    8000129a:	6ba2                	ld	s7,8(sp)
    8000129c:	6161                	addi	sp,sp,80
    8000129e:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e4850513          	addi	a0,a0,-440 # 800080e8 <digits+0xa8>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	288080e7          	jalr	648(ra) # 80000530 <panic>
      panic("uvmunmap: not a leaf");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e5050513          	addi	a0,a0,-432 # 80008100 <digits+0xc0>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	278080e7          	jalr	632(ra) # 80000530 <panic>
      uint64 pa = PTE2PA(*pte);
    800012c0:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    800012c2:	00c79513          	slli	a0,a5,0xc
    800012c6:	fffff097          	auipc	ra,0xfffff
    800012ca:	724080e7          	jalr	1828(ra) # 800009ea <kfree>
    *pte = 0;
    800012ce:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d2:	9956                	add	s2,s2,s5
    800012d4:	fb397be3          	bgeu	s2,s3,8000128a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012d8:	4601                	li	a2,0
    800012da:	85ca                	mv	a1,s2
    800012dc:	8552                	mv	a0,s4
    800012de:	00000097          	auipc	ra,0x0
    800012e2:	ce0080e7          	jalr	-800(ra) # 80000fbe <walk>
    800012e6:	84aa                	mv	s1,a0
    800012e8:	d56d                	beqz	a0,800012d2 <uvmunmap+0x78>
    if((*pte & PTE_V) == 0)
    800012ea:	611c                	ld	a5,0(a0)
    800012ec:	0017f713          	andi	a4,a5,1
    800012f0:	d36d                	beqz	a4,800012d2 <uvmunmap+0x78>
    if(PTE_FLAGS(*pte) == PTE_V)
    800012f2:	3ff7f713          	andi	a4,a5,1023
    800012f6:	fb770de3          	beq	a4,s7,800012b0 <uvmunmap+0x56>
    if(do_free){
    800012fa:	fc0b0ae3          	beqz	s6,800012ce <uvmunmap+0x74>
    800012fe:	b7c9                	j	800012c0 <uvmunmap+0x66>

0000000080001300 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001300:	1101                	addi	sp,sp,-32
    80001302:	ec06                	sd	ra,24(sp)
    80001304:	e822                	sd	s0,16(sp)
    80001306:	e426                	sd	s1,8(sp)
    80001308:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000130a:	fffff097          	auipc	ra,0xfffff
    8000130e:	7dc080e7          	jalr	2012(ra) # 80000ae6 <kalloc>
    80001312:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001314:	c519                	beqz	a0,80001322 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001316:	6605                	lui	a2,0x1
    80001318:	4581                	li	a1,0
    8000131a:	00000097          	auipc	ra,0x0
    8000131e:	9b8080e7          	jalr	-1608(ra) # 80000cd2 <memset>
  return pagetable;
}
    80001322:	8526                	mv	a0,s1
    80001324:	60e2                	ld	ra,24(sp)
    80001326:	6442                	ld	s0,16(sp)
    80001328:	64a2                	ld	s1,8(sp)
    8000132a:	6105                	addi	sp,sp,32
    8000132c:	8082                	ret

000000008000132e <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000132e:	7179                	addi	sp,sp,-48
    80001330:	f406                	sd	ra,40(sp)
    80001332:	f022                	sd	s0,32(sp)
    80001334:	ec26                	sd	s1,24(sp)
    80001336:	e84a                	sd	s2,16(sp)
    80001338:	e44e                	sd	s3,8(sp)
    8000133a:	e052                	sd	s4,0(sp)
    8000133c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000133e:	6785                	lui	a5,0x1
    80001340:	04f67863          	bgeu	a2,a5,80001390 <uvminit+0x62>
    80001344:	8a2a                	mv	s4,a0
    80001346:	89ae                	mv	s3,a1
    80001348:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000134a:	fffff097          	auipc	ra,0xfffff
    8000134e:	79c080e7          	jalr	1948(ra) # 80000ae6 <kalloc>
    80001352:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001354:	6605                	lui	a2,0x1
    80001356:	4581                	li	a1,0
    80001358:	00000097          	auipc	ra,0x0
    8000135c:	97a080e7          	jalr	-1670(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001360:	4779                	li	a4,30
    80001362:	86ca                	mv	a3,s2
    80001364:	6605                	lui	a2,0x1
    80001366:	4581                	li	a1,0
    80001368:	8552                	mv	a0,s4
    8000136a:	00000097          	auipc	ra,0x0
    8000136e:	d3c080e7          	jalr	-708(ra) # 800010a6 <mappages>
  memmove(mem, src, sz);
    80001372:	8626                	mv	a2,s1
    80001374:	85ce                	mv	a1,s3
    80001376:	854a                	mv	a0,s2
    80001378:	00000097          	auipc	ra,0x0
    8000137c:	9ba080e7          	jalr	-1606(ra) # 80000d32 <memmove>
}
    80001380:	70a2                	ld	ra,40(sp)
    80001382:	7402                	ld	s0,32(sp)
    80001384:	64e2                	ld	s1,24(sp)
    80001386:	6942                	ld	s2,16(sp)
    80001388:	69a2                	ld	s3,8(sp)
    8000138a:	6a02                	ld	s4,0(sp)
    8000138c:	6145                	addi	sp,sp,48
    8000138e:	8082                	ret
    panic("inituvm: more than a page");
    80001390:	00007517          	auipc	a0,0x7
    80001394:	d8850513          	addi	a0,a0,-632 # 80008118 <digits+0xd8>
    80001398:	fffff097          	auipc	ra,0xfffff
    8000139c:	198080e7          	jalr	408(ra) # 80000530 <panic>

00000000800013a0 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013a0:	1101                	addi	sp,sp,-32
    800013a2:	ec06                	sd	ra,24(sp)
    800013a4:	e822                	sd	s0,16(sp)
    800013a6:	e426                	sd	s1,8(sp)
    800013a8:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013aa:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ac:	00b67d63          	bgeu	a2,a1,800013c6 <uvmdealloc+0x26>
    800013b0:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013b2:	6785                	lui	a5,0x1
    800013b4:	17fd                	addi	a5,a5,-1
    800013b6:	00f60733          	add	a4,a2,a5
    800013ba:	767d                	lui	a2,0xfffff
    800013bc:	8f71                	and	a4,a4,a2
    800013be:	97ae                	add	a5,a5,a1
    800013c0:	8ff1                	and	a5,a5,a2
    800013c2:	00f76863          	bltu	a4,a5,800013d2 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013c6:	8526                	mv	a0,s1
    800013c8:	60e2                	ld	ra,24(sp)
    800013ca:	6442                	ld	s0,16(sp)
    800013cc:	64a2                	ld	s1,8(sp)
    800013ce:	6105                	addi	sp,sp,32
    800013d0:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013d2:	8f99                	sub	a5,a5,a4
    800013d4:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013d6:	4685                	li	a3,1
    800013d8:	0007861b          	sext.w	a2,a5
    800013dc:	85ba                	mv	a1,a4
    800013de:	00000097          	auipc	ra,0x0
    800013e2:	e7c080e7          	jalr	-388(ra) # 8000125a <uvmunmap>
    800013e6:	b7c5                	j	800013c6 <uvmdealloc+0x26>

00000000800013e8 <uvmalloc>:
  if(newsz < oldsz)
    800013e8:	0ab66163          	bltu	a2,a1,8000148a <uvmalloc+0xa2>
{
    800013ec:	7139                	addi	sp,sp,-64
    800013ee:	fc06                	sd	ra,56(sp)
    800013f0:	f822                	sd	s0,48(sp)
    800013f2:	f426                	sd	s1,40(sp)
    800013f4:	f04a                	sd	s2,32(sp)
    800013f6:	ec4e                	sd	s3,24(sp)
    800013f8:	e852                	sd	s4,16(sp)
    800013fa:	e456                	sd	s5,8(sp)
    800013fc:	0080                	addi	s0,sp,64
    800013fe:	8aaa                	mv	s5,a0
    80001400:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001402:	6985                	lui	s3,0x1
    80001404:	19fd                	addi	s3,s3,-1
    80001406:	95ce                	add	a1,a1,s3
    80001408:	79fd                	lui	s3,0xfffff
    8000140a:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000140e:	08c9f063          	bgeu	s3,a2,8000148e <uvmalloc+0xa6>
    80001412:	894e                	mv	s2,s3
    mem = kalloc();
    80001414:	fffff097          	auipc	ra,0xfffff
    80001418:	6d2080e7          	jalr	1746(ra) # 80000ae6 <kalloc>
    8000141c:	84aa                	mv	s1,a0
    if(mem == 0){
    8000141e:	c51d                	beqz	a0,8000144c <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001420:	6605                	lui	a2,0x1
    80001422:	4581                	li	a1,0
    80001424:	00000097          	auipc	ra,0x0
    80001428:	8ae080e7          	jalr	-1874(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000142c:	4779                	li	a4,30
    8000142e:	86a6                	mv	a3,s1
    80001430:	6605                	lui	a2,0x1
    80001432:	85ca                	mv	a1,s2
    80001434:	8556                	mv	a0,s5
    80001436:	00000097          	auipc	ra,0x0
    8000143a:	c70080e7          	jalr	-912(ra) # 800010a6 <mappages>
    8000143e:	e905                	bnez	a0,8000146e <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001440:	6785                	lui	a5,0x1
    80001442:	993e                	add	s2,s2,a5
    80001444:	fd4968e3          	bltu	s2,s4,80001414 <uvmalloc+0x2c>
  return newsz;
    80001448:	8552                	mv	a0,s4
    8000144a:	a809                	j	8000145c <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000144c:	864e                	mv	a2,s3
    8000144e:	85ca                	mv	a1,s2
    80001450:	8556                	mv	a0,s5
    80001452:	00000097          	auipc	ra,0x0
    80001456:	f4e080e7          	jalr	-178(ra) # 800013a0 <uvmdealloc>
      return 0;
    8000145a:	4501                	li	a0,0
}
    8000145c:	70e2                	ld	ra,56(sp)
    8000145e:	7442                	ld	s0,48(sp)
    80001460:	74a2                	ld	s1,40(sp)
    80001462:	7902                	ld	s2,32(sp)
    80001464:	69e2                	ld	s3,24(sp)
    80001466:	6a42                	ld	s4,16(sp)
    80001468:	6aa2                	ld	s5,8(sp)
    8000146a:	6121                	addi	sp,sp,64
    8000146c:	8082                	ret
      kfree(mem);
    8000146e:	8526                	mv	a0,s1
    80001470:	fffff097          	auipc	ra,0xfffff
    80001474:	57a080e7          	jalr	1402(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001478:	864e                	mv	a2,s3
    8000147a:	85ca                	mv	a1,s2
    8000147c:	8556                	mv	a0,s5
    8000147e:	00000097          	auipc	ra,0x0
    80001482:	f22080e7          	jalr	-222(ra) # 800013a0 <uvmdealloc>
      return 0;
    80001486:	4501                	li	a0,0
    80001488:	bfd1                	j	8000145c <uvmalloc+0x74>
    return oldsz;
    8000148a:	852e                	mv	a0,a1
}
    8000148c:	8082                	ret
  return newsz;
    8000148e:	8532                	mv	a0,a2
    80001490:	b7f1                	j	8000145c <uvmalloc+0x74>

0000000080001492 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001492:	7179                	addi	sp,sp,-48
    80001494:	f406                	sd	ra,40(sp)
    80001496:	f022                	sd	s0,32(sp)
    80001498:	ec26                	sd	s1,24(sp)
    8000149a:	e84a                	sd	s2,16(sp)
    8000149c:	e44e                	sd	s3,8(sp)
    8000149e:	e052                	sd	s4,0(sp)
    800014a0:	1800                	addi	s0,sp,48
    800014a2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014a4:	84aa                	mv	s1,a0
    800014a6:	6905                	lui	s2,0x1
    800014a8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014aa:	4985                	li	s3,1
    800014ac:	a821                	j	800014c4 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014ae:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014b0:	0532                	slli	a0,a0,0xc
    800014b2:	00000097          	auipc	ra,0x0
    800014b6:	fe0080e7          	jalr	-32(ra) # 80001492 <freewalk>
      pagetable[i] = 0;
    800014ba:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014be:	04a1                	addi	s1,s1,8
    800014c0:	01248863          	beq	s1,s2,800014d0 <freewalk+0x3e>
    pte_t pte = pagetable[i];
    800014c4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014c6:	00f57793          	andi	a5,a0,15
    800014ca:	ff379ae3          	bne	a5,s3,800014be <freewalk+0x2c>
    800014ce:	b7c5                	j	800014ae <freewalk+0x1c>
    } else if(pte & PTE_V){
      // panic("freewalk: leaf");
    }
  }
  kfree((void*)pagetable);
    800014d0:	8552                	mv	a0,s4
    800014d2:	fffff097          	auipc	ra,0xfffff
    800014d6:	518080e7          	jalr	1304(ra) # 800009ea <kfree>
}
    800014da:	70a2                	ld	ra,40(sp)
    800014dc:	7402                	ld	s0,32(sp)
    800014de:	64e2                	ld	s1,24(sp)
    800014e0:	6942                	ld	s2,16(sp)
    800014e2:	69a2                	ld	s3,8(sp)
    800014e4:	6a02                	ld	s4,0(sp)
    800014e6:	6145                	addi	sp,sp,48
    800014e8:	8082                	ret

00000000800014ea <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800014ea:	1101                	addi	sp,sp,-32
    800014ec:	ec06                	sd	ra,24(sp)
    800014ee:	e822                	sd	s0,16(sp)
    800014f0:	e426                	sd	s1,8(sp)
    800014f2:	1000                	addi	s0,sp,32
    800014f4:	84aa                	mv	s1,a0
  if(sz > 0)
    800014f6:	e999                	bnez	a1,8000150c <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800014f8:	8526                	mv	a0,s1
    800014fa:	00000097          	auipc	ra,0x0
    800014fe:	f98080e7          	jalr	-104(ra) # 80001492 <freewalk>
}
    80001502:	60e2                	ld	ra,24(sp)
    80001504:	6442                	ld	s0,16(sp)
    80001506:	64a2                	ld	s1,8(sp)
    80001508:	6105                	addi	sp,sp,32
    8000150a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000150c:	6605                	lui	a2,0x1
    8000150e:	167d                	addi	a2,a2,-1
    80001510:	962e                	add	a2,a2,a1
    80001512:	4685                	li	a3,1
    80001514:	8231                	srli	a2,a2,0xc
    80001516:	4581                	li	a1,0
    80001518:	00000097          	auipc	ra,0x0
    8000151c:	d42080e7          	jalr	-702(ra) # 8000125a <uvmunmap>
    80001520:	bfe1                	j	800014f8 <uvmfree+0xe>

0000000080001522 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001522:	c679                	beqz	a2,800015f0 <uvmcopy+0xce>
{
    80001524:	715d                	addi	sp,sp,-80
    80001526:	e486                	sd	ra,72(sp)
    80001528:	e0a2                	sd	s0,64(sp)
    8000152a:	fc26                	sd	s1,56(sp)
    8000152c:	f84a                	sd	s2,48(sp)
    8000152e:	f44e                	sd	s3,40(sp)
    80001530:	f052                	sd	s4,32(sp)
    80001532:	ec56                	sd	s5,24(sp)
    80001534:	e85a                	sd	s6,16(sp)
    80001536:	e45e                	sd	s7,8(sp)
    80001538:	0880                	addi	s0,sp,80
    8000153a:	8b2a                	mv	s6,a0
    8000153c:	8aae                	mv	s5,a1
    8000153e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001540:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001542:	4601                	li	a2,0
    80001544:	85ce                	mv	a1,s3
    80001546:	855a                	mv	a0,s6
    80001548:	00000097          	auipc	ra,0x0
    8000154c:	a76080e7          	jalr	-1418(ra) # 80000fbe <walk>
    80001550:	c531                	beqz	a0,8000159c <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001552:	6118                	ld	a4,0(a0)
    80001554:	00177793          	andi	a5,a4,1
    80001558:	cbb1                	beqz	a5,800015ac <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000155a:	00a75593          	srli	a1,a4,0xa
    8000155e:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001562:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001566:	fffff097          	auipc	ra,0xfffff
    8000156a:	580080e7          	jalr	1408(ra) # 80000ae6 <kalloc>
    8000156e:	892a                	mv	s2,a0
    80001570:	c939                	beqz	a0,800015c6 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001572:	6605                	lui	a2,0x1
    80001574:	85de                	mv	a1,s7
    80001576:	fffff097          	auipc	ra,0xfffff
    8000157a:	7bc080e7          	jalr	1980(ra) # 80000d32 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000157e:	8726                	mv	a4,s1
    80001580:	86ca                	mv	a3,s2
    80001582:	6605                	lui	a2,0x1
    80001584:	85ce                	mv	a1,s3
    80001586:	8556                	mv	a0,s5
    80001588:	00000097          	auipc	ra,0x0
    8000158c:	b1e080e7          	jalr	-1250(ra) # 800010a6 <mappages>
    80001590:	e515                	bnez	a0,800015bc <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001592:	6785                	lui	a5,0x1
    80001594:	99be                	add	s3,s3,a5
    80001596:	fb49e6e3          	bltu	s3,s4,80001542 <uvmcopy+0x20>
    8000159a:	a081                	j	800015da <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000159c:	00007517          	auipc	a0,0x7
    800015a0:	b9c50513          	addi	a0,a0,-1124 # 80008138 <digits+0xf8>
    800015a4:	fffff097          	auipc	ra,0xfffff
    800015a8:	f8c080e7          	jalr	-116(ra) # 80000530 <panic>
      panic("uvmcopy: page not present");
    800015ac:	00007517          	auipc	a0,0x7
    800015b0:	bac50513          	addi	a0,a0,-1108 # 80008158 <digits+0x118>
    800015b4:	fffff097          	auipc	ra,0xfffff
    800015b8:	f7c080e7          	jalr	-132(ra) # 80000530 <panic>
      kfree(mem);
    800015bc:	854a                	mv	a0,s2
    800015be:	fffff097          	auipc	ra,0xfffff
    800015c2:	42c080e7          	jalr	1068(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015c6:	4685                	li	a3,1
    800015c8:	00c9d613          	srli	a2,s3,0xc
    800015cc:	4581                	li	a1,0
    800015ce:	8556                	mv	a0,s5
    800015d0:	00000097          	auipc	ra,0x0
    800015d4:	c8a080e7          	jalr	-886(ra) # 8000125a <uvmunmap>
  return -1;
    800015d8:	557d                	li	a0,-1
}
    800015da:	60a6                	ld	ra,72(sp)
    800015dc:	6406                	ld	s0,64(sp)
    800015de:	74e2                	ld	s1,56(sp)
    800015e0:	7942                	ld	s2,48(sp)
    800015e2:	79a2                	ld	s3,40(sp)
    800015e4:	7a02                	ld	s4,32(sp)
    800015e6:	6ae2                	ld	s5,24(sp)
    800015e8:	6b42                	ld	s6,16(sp)
    800015ea:	6ba2                	ld	s7,8(sp)
    800015ec:	6161                	addi	sp,sp,80
    800015ee:	8082                	ret
  return 0;
    800015f0:	4501                	li	a0,0
}
    800015f2:	8082                	ret

00000000800015f4 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800015f4:	1141                	addi	sp,sp,-16
    800015f6:	e406                	sd	ra,8(sp)
    800015f8:	e022                	sd	s0,0(sp)
    800015fa:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800015fc:	4601                	li	a2,0
    800015fe:	00000097          	auipc	ra,0x0
    80001602:	9c0080e7          	jalr	-1600(ra) # 80000fbe <walk>
  if(pte == 0)
    80001606:	c901                	beqz	a0,80001616 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001608:	611c                	ld	a5,0(a0)
    8000160a:	9bbd                	andi	a5,a5,-17
    8000160c:	e11c                	sd	a5,0(a0)
}
    8000160e:	60a2                	ld	ra,8(sp)
    80001610:	6402                	ld	s0,0(sp)
    80001612:	0141                	addi	sp,sp,16
    80001614:	8082                	ret
    panic("uvmclear");
    80001616:	00007517          	auipc	a0,0x7
    8000161a:	b6250513          	addi	a0,a0,-1182 # 80008178 <digits+0x138>
    8000161e:	fffff097          	auipc	ra,0xfffff
    80001622:	f12080e7          	jalr	-238(ra) # 80000530 <panic>

0000000080001626 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001626:	c6bd                	beqz	a3,80001694 <copyout+0x6e>
{
    80001628:	715d                	addi	sp,sp,-80
    8000162a:	e486                	sd	ra,72(sp)
    8000162c:	e0a2                	sd	s0,64(sp)
    8000162e:	fc26                	sd	s1,56(sp)
    80001630:	f84a                	sd	s2,48(sp)
    80001632:	f44e                	sd	s3,40(sp)
    80001634:	f052                	sd	s4,32(sp)
    80001636:	ec56                	sd	s5,24(sp)
    80001638:	e85a                	sd	s6,16(sp)
    8000163a:	e45e                	sd	s7,8(sp)
    8000163c:	e062                	sd	s8,0(sp)
    8000163e:	0880                	addi	s0,sp,80
    80001640:	8b2a                	mv	s6,a0
    80001642:	8c2e                	mv	s8,a1
    80001644:	8a32                	mv	s4,a2
    80001646:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001648:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000164a:	6a85                	lui	s5,0x1
    8000164c:	a015                	j	80001670 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000164e:	9562                	add	a0,a0,s8
    80001650:	0004861b          	sext.w	a2,s1
    80001654:	85d2                	mv	a1,s4
    80001656:	41250533          	sub	a0,a0,s2
    8000165a:	fffff097          	auipc	ra,0xfffff
    8000165e:	6d8080e7          	jalr	1752(ra) # 80000d32 <memmove>

    len -= n;
    80001662:	409989b3          	sub	s3,s3,s1
    src += n;
    80001666:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001668:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000166c:	02098263          	beqz	s3,80001690 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001670:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001674:	85ca                	mv	a1,s2
    80001676:	855a                	mv	a0,s6
    80001678:	00000097          	auipc	ra,0x0
    8000167c:	9ec080e7          	jalr	-1556(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    80001680:	cd01                	beqz	a0,80001698 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001682:	418904b3          	sub	s1,s2,s8
    80001686:	94d6                	add	s1,s1,s5
    if(n > len)
    80001688:	fc99f3e3          	bgeu	s3,s1,8000164e <copyout+0x28>
    8000168c:	84ce                	mv	s1,s3
    8000168e:	b7c1                	j	8000164e <copyout+0x28>
  }
  return 0;
    80001690:	4501                	li	a0,0
    80001692:	a021                	j	8000169a <copyout+0x74>
    80001694:	4501                	li	a0,0
}
    80001696:	8082                	ret
      return -1;
    80001698:	557d                	li	a0,-1
}
    8000169a:	60a6                	ld	ra,72(sp)
    8000169c:	6406                	ld	s0,64(sp)
    8000169e:	74e2                	ld	s1,56(sp)
    800016a0:	7942                	ld	s2,48(sp)
    800016a2:	79a2                	ld	s3,40(sp)
    800016a4:	7a02                	ld	s4,32(sp)
    800016a6:	6ae2                	ld	s5,24(sp)
    800016a8:	6b42                	ld	s6,16(sp)
    800016aa:	6ba2                	ld	s7,8(sp)
    800016ac:	6c02                	ld	s8,0(sp)
    800016ae:	6161                	addi	sp,sp,80
    800016b0:	8082                	ret

00000000800016b2 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016b2:	c6bd                	beqz	a3,80001720 <copyin+0x6e>
{
    800016b4:	715d                	addi	sp,sp,-80
    800016b6:	e486                	sd	ra,72(sp)
    800016b8:	e0a2                	sd	s0,64(sp)
    800016ba:	fc26                	sd	s1,56(sp)
    800016bc:	f84a                	sd	s2,48(sp)
    800016be:	f44e                	sd	s3,40(sp)
    800016c0:	f052                	sd	s4,32(sp)
    800016c2:	ec56                	sd	s5,24(sp)
    800016c4:	e85a                	sd	s6,16(sp)
    800016c6:	e45e                	sd	s7,8(sp)
    800016c8:	e062                	sd	s8,0(sp)
    800016ca:	0880                	addi	s0,sp,80
    800016cc:	8b2a                	mv	s6,a0
    800016ce:	8a2e                	mv	s4,a1
    800016d0:	8c32                	mv	s8,a2
    800016d2:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800016d4:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800016d6:	6a85                	lui	s5,0x1
    800016d8:	a015                	j	800016fc <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800016da:	9562                	add	a0,a0,s8
    800016dc:	0004861b          	sext.w	a2,s1
    800016e0:	412505b3          	sub	a1,a0,s2
    800016e4:	8552                	mv	a0,s4
    800016e6:	fffff097          	auipc	ra,0xfffff
    800016ea:	64c080e7          	jalr	1612(ra) # 80000d32 <memmove>

    len -= n;
    800016ee:	409989b3          	sub	s3,s3,s1
    dst += n;
    800016f2:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800016f4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016f8:	02098263          	beqz	s3,8000171c <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800016fc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001700:	85ca                	mv	a1,s2
    80001702:	855a                	mv	a0,s6
    80001704:	00000097          	auipc	ra,0x0
    80001708:	960080e7          	jalr	-1696(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    8000170c:	cd01                	beqz	a0,80001724 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000170e:	418904b3          	sub	s1,s2,s8
    80001712:	94d6                	add	s1,s1,s5
    if(n > len)
    80001714:	fc99f3e3          	bgeu	s3,s1,800016da <copyin+0x28>
    80001718:	84ce                	mv	s1,s3
    8000171a:	b7c1                	j	800016da <copyin+0x28>
  }
  return 0;
    8000171c:	4501                	li	a0,0
    8000171e:	a021                	j	80001726 <copyin+0x74>
    80001720:	4501                	li	a0,0
}
    80001722:	8082                	ret
      return -1;
    80001724:	557d                	li	a0,-1
}
    80001726:	60a6                	ld	ra,72(sp)
    80001728:	6406                	ld	s0,64(sp)
    8000172a:	74e2                	ld	s1,56(sp)
    8000172c:	7942                	ld	s2,48(sp)
    8000172e:	79a2                	ld	s3,40(sp)
    80001730:	7a02                	ld	s4,32(sp)
    80001732:	6ae2                	ld	s5,24(sp)
    80001734:	6b42                	ld	s6,16(sp)
    80001736:	6ba2                	ld	s7,8(sp)
    80001738:	6c02                	ld	s8,0(sp)
    8000173a:	6161                	addi	sp,sp,80
    8000173c:	8082                	ret

000000008000173e <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000173e:	c6c5                	beqz	a3,800017e6 <copyinstr+0xa8>
{
    80001740:	715d                	addi	sp,sp,-80
    80001742:	e486                	sd	ra,72(sp)
    80001744:	e0a2                	sd	s0,64(sp)
    80001746:	fc26                	sd	s1,56(sp)
    80001748:	f84a                	sd	s2,48(sp)
    8000174a:	f44e                	sd	s3,40(sp)
    8000174c:	f052                	sd	s4,32(sp)
    8000174e:	ec56                	sd	s5,24(sp)
    80001750:	e85a                	sd	s6,16(sp)
    80001752:	e45e                	sd	s7,8(sp)
    80001754:	0880                	addi	s0,sp,80
    80001756:	8a2a                	mv	s4,a0
    80001758:	8b2e                	mv	s6,a1
    8000175a:	8bb2                	mv	s7,a2
    8000175c:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000175e:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001760:	6985                	lui	s3,0x1
    80001762:	a035                	j	8000178e <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001764:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001768:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000176a:	0017b793          	seqz	a5,a5
    8000176e:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6161                	addi	sp,sp,80
    80001786:	8082                	ret
    srcva = va0 + PGSIZE;
    80001788:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000178c:	c8a9                	beqz	s1,800017de <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000178e:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001792:	85ca                	mv	a1,s2
    80001794:	8552                	mv	a0,s4
    80001796:	00000097          	auipc	ra,0x0
    8000179a:	8ce080e7          	jalr	-1842(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    8000179e:	c131                	beqz	a0,800017e2 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017a0:	41790833          	sub	a6,s2,s7
    800017a4:	984e                	add	a6,a6,s3
    if(n > max)
    800017a6:	0104f363          	bgeu	s1,a6,800017ac <copyinstr+0x6e>
    800017aa:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017ac:	955e                	add	a0,a0,s7
    800017ae:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017b2:	fc080be3          	beqz	a6,80001788 <copyinstr+0x4a>
    800017b6:	985a                	add	a6,a6,s6
    800017b8:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017ba:	41650633          	sub	a2,a0,s6
    800017be:	14fd                	addi	s1,s1,-1
    800017c0:	9b26                	add	s6,s6,s1
    800017c2:	00f60733          	add	a4,a2,a5
    800017c6:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800017ca:	df49                	beqz	a4,80001764 <copyinstr+0x26>
        *dst = *p;
    800017cc:	00e78023          	sb	a4,0(a5)
      --max;
    800017d0:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800017d4:	0785                	addi	a5,a5,1
    while(n > 0){
    800017d6:	ff0796e3          	bne	a5,a6,800017c2 <copyinstr+0x84>
      dst++;
    800017da:	8b42                	mv	s6,a6
    800017dc:	b775                	j	80001788 <copyinstr+0x4a>
    800017de:	4781                	li	a5,0
    800017e0:	b769                	j	8000176a <copyinstr+0x2c>
      return -1;
    800017e2:	557d                	li	a0,-1
    800017e4:	b779                	j	80001772 <copyinstr+0x34>
  int got_null = 0;
    800017e6:	4781                	li	a5,0
  if(got_null){
    800017e8:	0017b793          	seqz	a5,a5
    800017ec:	40f00533          	neg	a0,a5
}
    800017f0:	8082                	ret

00000000800017f2 <mmap_handler>:

int
mmap_handler(uint64 va, int scause)
{
    800017f2:	7139                	addi	sp,sp,-64
    800017f4:	fc06                	sd	ra,56(sp)
    800017f6:	f822                	sd	s0,48(sp)
    800017f8:	f426                	sd	s1,40(sp)
    800017fa:	f04a                	sd	s2,32(sp)
    800017fc:	ec4e                	sd	s3,24(sp)
    800017fe:	e852                	sd	s4,16(sp)
    80001800:	e456                	sd	s5,8(sp)
    80001802:	0080                	addi	s0,sp,64
    80001804:	892a                	mv	s2,a0
    80001806:	8a2e                	mv	s4,a1
  struct proc *p = myproc();
    80001808:	00000097          	auipc	ra,0x0
    8000180c:	39e080e7          	jalr	926(ra) # 80001ba6 <myproc>
    80001810:	89aa                	mv	s3,a0
  struct vma* v = p->vma;
    80001812:	15853483          	ld	s1,344(a0)
  while(v != 0){
    80001816:	e489                	bnez	s1,80001820 <mmap_handler+0x2e>
    }
    //printf("%p\n", v);
    v = v->next;
  }

  if(v == 0) return -1; // not mmap addr
    80001818:	59fd                	li	s3,-1
    8000181a:	a851                	j	800018ae <mmap_handler+0xbc>
    v = v->next;
    8000181c:	7884                	ld	s1,48(s1)
  while(v != 0){
    8000181e:	c0d5                	beqz	s1,800018c2 <mmap_handler+0xd0>
    if(va >= v->start && va < v->end){
    80001820:	609c                	ld	a5,0(s1)
    80001822:	fef96de3          	bltu	s2,a5,8000181c <mmap_handler+0x2a>
    80001826:	649c                	ld	a5,8(s1)
    80001828:	fef97ae3          	bgeu	s2,a5,8000181c <mmap_handler+0x2a>
  if(scause == 13 && !(v->permission & PTE_R)) return -2; // unreadable vma
    8000182c:	47b5                	li	a5,13
    8000182e:	08fa0c63          	beq	s4,a5,800018c6 <mmap_handler+0xd4>
  if(scause == 15 && !(v->permission & PTE_W)) return -3; // unwritable vma
    80001832:	47bd                	li	a5,15
    80001834:	00fa1563          	bne	s4,a5,8000183e <mmap_handler+0x4c>
    80001838:	509c                	lw	a5,32(s1)
    8000183a:	8b91                	andi	a5,a5,4
    8000183c:	c3cd                	beqz	a5,800018de <mmap_handler+0xec>

  // load page from file
  va = PGROUNDDOWN(va);
    8000183e:	7a7d                	lui	s4,0xfffff
    80001840:	01497a33          	and	s4,s2,s4
  char* mem = kalloc();
    80001844:	fffff097          	auipc	ra,0xfffff
    80001848:	2a2080e7          	jalr	674(ra) # 80000ae6 <kalloc>
    8000184c:	892a                	mv	s2,a0
  if (mem == 0) return -4; // kalloc failed
    8000184e:	c951                	beqz	a0,800018e2 <mmap_handler+0xf0>
  
  memset(mem, 0, PGSIZE);
    80001850:	6605                	lui	a2,0x1
    80001852:	4581                	li	a1,0
    80001854:	fffff097          	auipc	ra,0xfffff
    80001858:	47e080e7          	jalr	1150(ra) # 80000cd2 <memset>

  if(mappages(p->pagetable, va, PGSIZE, (uint64)mem, v->permission) != 0){
    8000185c:	5098                	lw	a4,32(s1)
    8000185e:	86ca                	mv	a3,s2
    80001860:	6605                	lui	a2,0x1
    80001862:	85d2                	mv	a1,s4
    80001864:	0509b503          	ld	a0,80(s3) # 1050 <_entry-0x7fffefb0>
    80001868:	00000097          	auipc	ra,0x0
    8000186c:	83e080e7          	jalr	-1986(ra) # 800010a6 <mappages>
    80001870:	89aa                	mv	s3,a0
    80001872:	ed39                	bnez	a0,800018d0 <mmap_handler+0xde>
    kfree(mem);
    return -5; // map page failed
  }

  struct file *f = v->file;
    80001874:	0284ba83          	ld	s5,40(s1)
  ilock(f->ip);
    80001878:	018ab503          	ld	a0,24(s5) # fffffffffffff018 <end+0xffffffff7ffd9018>
    8000187c:	00002097          	auipc	ra,0x2
    80001880:	0e6080e7          	jalr	230(ra) # 80003962 <ilock>
  readi(f->ip, 0, (uint64)mem, v->off + va - v->start, PGSIZE);
    80001884:	6c94                	ld	a3,24(s1)
    80001886:	01468a3b          	addw	s4,a3,s4
    8000188a:	6094                	ld	a3,0(s1)
    8000188c:	6705                	lui	a4,0x1
    8000188e:	40da06bb          	subw	a3,s4,a3
    80001892:	864a                	mv	a2,s2
    80001894:	4581                	li	a1,0
    80001896:	018ab503          	ld	a0,24(s5)
    8000189a:	00002097          	auipc	ra,0x2
    8000189e:	37c080e7          	jalr	892(ra) # 80003c16 <readi>
  iunlock(f->ip);
    800018a2:	018ab503          	ld	a0,24(s5)
    800018a6:	00002097          	auipc	ra,0x2
    800018aa:	17e080e7          	jalr	382(ra) # 80003a24 <iunlock>
  return 0;
}
    800018ae:	854e                	mv	a0,s3
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6121                	addi	sp,sp,64
    800018c0:	8082                	ret
  if(v == 0) return -1; // not mmap addr
    800018c2:	59fd                	li	s3,-1
    800018c4:	b7ed                	j	800018ae <mmap_handler+0xbc>
  if(scause == 13 && !(v->permission & PTE_R)) return -2; // unreadable vma
    800018c6:	509c                	lw	a5,32(s1)
    800018c8:	8b89                	andi	a5,a5,2
    800018ca:	fbb5                	bnez	a5,8000183e <mmap_handler+0x4c>
    800018cc:	59f9                	li	s3,-2
    800018ce:	b7c5                	j	800018ae <mmap_handler+0xbc>
    kfree(mem);
    800018d0:	854a                	mv	a0,s2
    800018d2:	fffff097          	auipc	ra,0xfffff
    800018d6:	118080e7          	jalr	280(ra) # 800009ea <kfree>
    return -5; // map page failed
    800018da:	59ed                	li	s3,-5
    800018dc:	bfc9                	j	800018ae <mmap_handler+0xbc>
  if(scause == 15 && !(v->permission & PTE_W)) return -3; // unwritable vma
    800018de:	59f5                	li	s3,-3
    800018e0:	b7f9                	j	800018ae <mmap_handler+0xbc>
  if (mem == 0) return -4; // kalloc failed
    800018e2:	59f1                	li	s3,-4
    800018e4:	b7e9                	j	800018ae <mmap_handler+0xbc>

00000000800018e6 <writeback>:

void
writeback(struct vma* v, uint64 addr, int n)
{
  if(!(v->permission & PTE_W) || (v->flags & MAP_PRIVATE)) // no need to writeback
    800018e6:	511c                	lw	a5,32(a0)
    800018e8:	8b91                	andi	a5,a5,4
    800018ea:	10078e63          	beqz	a5,80001a06 <writeback+0x120>
{
    800018ee:	7159                	addi	sp,sp,-112
    800018f0:	f486                	sd	ra,104(sp)
    800018f2:	f0a2                	sd	s0,96(sp)
    800018f4:	eca6                	sd	s1,88(sp)
    800018f6:	e8ca                	sd	s2,80(sp)
    800018f8:	e4ce                	sd	s3,72(sp)
    800018fa:	e0d2                	sd	s4,64(sp)
    800018fc:	fc56                	sd	s5,56(sp)
    800018fe:	f85a                	sd	s6,48(sp)
    80001900:	f45e                	sd	s7,40(sp)
    80001902:	f062                	sd	s8,32(sp)
    80001904:	ec66                	sd	s9,24(sp)
    80001906:	e86a                	sd	s10,16(sp)
    80001908:	e46e                	sd	s11,8(sp)
    8000190a:	1880                	addi	s0,sp,112
    8000190c:	892a                	mv	s2,a0
    8000190e:	89ae                	mv	s3,a1
    80001910:	8b32                	mv	s6,a2
  if(!(v->permission & PTE_W) || (v->flags & MAP_PRIVATE)) // no need to writeback
    80001912:	515c                	lw	a5,36(a0)
    80001914:	8b89                	andi	a5,a5,2
    80001916:	0007849b          	sext.w	s1,a5
    8000191a:	e7f9                	bnez	a5,800019e8 <writeback+0x102>
    return;

  if((addr % PGSIZE) != 0)
    8000191c:	03459793          	slli	a5,a1,0x34
    80001920:	eb85                	bnez	a5,80001950 <writeback+0x6a>
    panic("unmap: not aligned");

  printf("starting writeback: %p %d\n", addr, n);
    80001922:	00007517          	auipc	a0,0x7
    80001926:	87e50513          	addi	a0,a0,-1922 # 800081a0 <digits+0x160>
    8000192a:	fffff097          	auipc	ra,0xfffff
    8000192e:	c50080e7          	jalr	-944(ra) # 8000057a <printf>

  struct file* f = v->file;
    80001932:	02893a83          	ld	s5,40(s2) # 1028 <_entry-0x7fffefd8>

  int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
  int i = 0;
  while(i < n){
    80001936:	0b605963          	blez	s6,800019e8 <writeback+0x102>
    8000193a:	6c05                	lui	s8,0x1
    8000193c:	c00c0c13          	addi	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80001940:	6d05                	lui	s10,0x1
    80001942:	c00d0d1b          	addiw	s10,s10,-1024
    if(n1 > max)
      n1 = max;

    begin_op();
    ilock(f->ip);
    printf("%p %d %d\n",addr + i, v->off + v->start - addr, n1);
    80001946:	00007c97          	auipc	s9,0x7
    8000194a:	87ac8c93          	addi	s9,s9,-1926 # 800081c0 <digits+0x180>
    8000194e:	a069                	j	800019d8 <writeback+0xf2>
    panic("unmap: not aligned");
    80001950:	00007517          	auipc	a0,0x7
    80001954:	83850513          	addi	a0,a0,-1992 # 80008188 <digits+0x148>
    80001958:	fffff097          	auipc	ra,0xfffff
    8000195c:	bd8080e7          	jalr	-1064(ra) # 80000530 <panic>
    80001960:	000a0d9b          	sext.w	s11,s4
    begin_op();
    80001964:	00003097          	auipc	ra,0x3
    80001968:	9d0080e7          	jalr	-1584(ra) # 80004334 <begin_op>
    ilock(f->ip);
    8000196c:	018ab503          	ld	a0,24(s5)
    80001970:	00002097          	auipc	ra,0x2
    80001974:	ff2080e7          	jalr	-14(ra) # 80003962 <ilock>
    printf("%p %d %d\n",addr + i, v->off + v->start - addr, n1);
    80001978:	01348bb3          	add	s7,s1,s3
    8000197c:	01893603          	ld	a2,24(s2)
    80001980:	00093783          	ld	a5,0(s2)
    80001984:	963e                	add	a2,a2,a5
    80001986:	86ee                	mv	a3,s11
    80001988:	41360633          	sub	a2,a2,s3
    8000198c:	85de                	mv	a1,s7
    8000198e:	8566                	mv	a0,s9
    80001990:	fffff097          	auipc	ra,0xfffff
    80001994:	bea080e7          	jalr	-1046(ra) # 8000057a <printf>
    int r = writei(f->ip, 1, addr + i, v->off + v->start - addr + i, n1);
    80001998:	01893683          	ld	a3,24(s2)
    8000199c:	00093783          	ld	a5,0(s2)
    800019a0:	9ebd                	addw	a3,a3,a5
    800019a2:	413686bb          	subw	a3,a3,s3
    800019a6:	876e                	mv	a4,s11
    800019a8:	9ea5                	addw	a3,a3,s1
    800019aa:	865e                	mv	a2,s7
    800019ac:	4585                	li	a1,1
    800019ae:	018ab503          	ld	a0,24(s5)
    800019b2:	00002097          	auipc	ra,0x2
    800019b6:	35c080e7          	jalr	860(ra) # 80003d0e <writei>
    800019ba:	8a2a                	mv	s4,a0
    iunlock(f->ip);
    800019bc:	018ab503          	ld	a0,24(s5)
    800019c0:	00002097          	auipc	ra,0x2
    800019c4:	064080e7          	jalr	100(ra) # 80003a24 <iunlock>
    end_op();
    800019c8:	00003097          	auipc	ra,0x3
    800019cc:	9ec080e7          	jalr	-1556(ra) # 800043b4 <end_op>
    i += r;
    800019d0:	009a04bb          	addw	s1,s4,s1
  while(i < n){
    800019d4:	0164da63          	bge	s1,s6,800019e8 <writeback+0x102>
    int n1 = n - i;
    800019d8:	409b07bb          	subw	a5,s6,s1
    if(n1 > max)
    800019dc:	8a3e                	mv	s4,a5
    800019de:	2781                	sext.w	a5,a5
    800019e0:	f8fc50e3          	bge	s8,a5,80001960 <writeback+0x7a>
    800019e4:	8a6a                	mv	s4,s10
    800019e6:	bfad                	j	80001960 <writeback+0x7a>
  }
}
    800019e8:	70a6                	ld	ra,104(sp)
    800019ea:	7406                	ld	s0,96(sp)
    800019ec:	64e6                	ld	s1,88(sp)
    800019ee:	6946                	ld	s2,80(sp)
    800019f0:	69a6                	ld	s3,72(sp)
    800019f2:	6a06                	ld	s4,64(sp)
    800019f4:	7ae2                	ld	s5,56(sp)
    800019f6:	7b42                	ld	s6,48(sp)
    800019f8:	7ba2                	ld	s7,40(sp)
    800019fa:	7c02                	ld	s8,32(sp)
    800019fc:	6ce2                	ld	s9,24(sp)
    800019fe:	6d42                	ld	s10,16(sp)
    80001a00:	6da2                	ld	s11,8(sp)
    80001a02:	6165                	addi	sp,sp,112
    80001a04:	8082                	ret
    80001a06:	8082                	ret

0000000080001a08 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001a08:	1101                	addi	sp,sp,-32
    80001a0a:	ec06                	sd	ra,24(sp)
    80001a0c:	e822                	sd	s0,16(sp)
    80001a0e:	e426                	sd	s1,8(sp)
    80001a10:	1000                	addi	s0,sp,32
    80001a12:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001a14:	fffff097          	auipc	ra,0xfffff
    80001a18:	148080e7          	jalr	328(ra) # 80000b5c <holding>
    80001a1c:	c909                	beqz	a0,80001a2e <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001a1e:	749c                	ld	a5,40(s1)
    80001a20:	00978f63          	beq	a5,s1,80001a3e <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001a24:	60e2                	ld	ra,24(sp)
    80001a26:	6442                	ld	s0,16(sp)
    80001a28:	64a2                	ld	s1,8(sp)
    80001a2a:	6105                	addi	sp,sp,32
    80001a2c:	8082                	ret
    panic("wakeup1");
    80001a2e:	00006517          	auipc	a0,0x6
    80001a32:	7a250513          	addi	a0,a0,1954 # 800081d0 <digits+0x190>
    80001a36:	fffff097          	auipc	ra,0xfffff
    80001a3a:	afa080e7          	jalr	-1286(ra) # 80000530 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001a3e:	4c98                	lw	a4,24(s1)
    80001a40:	4785                	li	a5,1
    80001a42:	fef711e3          	bne	a4,a5,80001a24 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001a46:	4789                	li	a5,2
    80001a48:	cc9c                	sw	a5,24(s1)
}
    80001a4a:	bfe9                	j	80001a24 <wakeup1+0x1c>

0000000080001a4c <proc_mapstacks>:
proc_mapstacks(pagetable_t kpgtbl) {
    80001a4c:	7139                	addi	sp,sp,-64
    80001a4e:	fc06                	sd	ra,56(sp)
    80001a50:	f822                	sd	s0,48(sp)
    80001a52:	f426                	sd	s1,40(sp)
    80001a54:	f04a                	sd	s2,32(sp)
    80001a56:	ec4e                	sd	s3,24(sp)
    80001a58:	e852                	sd	s4,16(sp)
    80001a5a:	e456                	sd	s5,8(sp)
    80001a5c:	e05a                	sd	s6,0(sp)
    80001a5e:	0080                	addi	s0,sp,64
    80001a60:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a62:	00010497          	auipc	s1,0x10
    80001a66:	15648493          	addi	s1,s1,342 # 80011bb8 <proc>
    uint64 va = KSTACK((int) (p - proc));
    80001a6a:	8b26                	mv	s6,s1
    80001a6c:	00006a97          	auipc	s5,0x6
    80001a70:	594a8a93          	addi	s5,s5,1428 # 80008000 <etext>
    80001a74:	04000937          	lui	s2,0x4000
    80001a78:	197d                	addi	s2,s2,-1
    80001a7a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a7c:	00016a17          	auipc	s4,0x16
    80001a80:	d3ca0a13          	addi	s4,s4,-708 # 800177b8 <tickslock>
    char *pa = kalloc();
    80001a84:	fffff097          	auipc	ra,0xfffff
    80001a88:	062080e7          	jalr	98(ra) # 80000ae6 <kalloc>
    80001a8c:	862a                	mv	a2,a0
    if(pa == 0)
    80001a8e:	c131                	beqz	a0,80001ad2 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001a90:	416485b3          	sub	a1,s1,s6
    80001a94:	8591                	srai	a1,a1,0x4
    80001a96:	000ab783          	ld	a5,0(s5)
    80001a9a:	02f585b3          	mul	a1,a1,a5
    80001a9e:	2585                	addiw	a1,a1,1
    80001aa0:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001aa4:	4719                	li	a4,6
    80001aa6:	6685                	lui	a3,0x1
    80001aa8:	40b905b3          	sub	a1,s2,a1
    80001aac:	854e                	mv	a0,s3
    80001aae:	fffff097          	auipc	ra,0xfffff
    80001ab2:	686080e7          	jalr	1670(ra) # 80001134 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ab6:	17048493          	addi	s1,s1,368
    80001aba:	fd4495e3          	bne	s1,s4,80001a84 <proc_mapstacks+0x38>
}
    80001abe:	70e2                	ld	ra,56(sp)
    80001ac0:	7442                	ld	s0,48(sp)
    80001ac2:	74a2                	ld	s1,40(sp)
    80001ac4:	7902                	ld	s2,32(sp)
    80001ac6:	69e2                	ld	s3,24(sp)
    80001ac8:	6a42                	ld	s4,16(sp)
    80001aca:	6aa2                	ld	s5,8(sp)
    80001acc:	6b02                	ld	s6,0(sp)
    80001ace:	6121                	addi	sp,sp,64
    80001ad0:	8082                	ret
      panic("kalloc");
    80001ad2:	00006517          	auipc	a0,0x6
    80001ad6:	70650513          	addi	a0,a0,1798 # 800081d8 <digits+0x198>
    80001ada:	fffff097          	auipc	ra,0xfffff
    80001ade:	a56080e7          	jalr	-1450(ra) # 80000530 <panic>

0000000080001ae2 <procinit>:
{
    80001ae2:	7139                	addi	sp,sp,-64
    80001ae4:	fc06                	sd	ra,56(sp)
    80001ae6:	f822                	sd	s0,48(sp)
    80001ae8:	f426                	sd	s1,40(sp)
    80001aea:	f04a                	sd	s2,32(sp)
    80001aec:	ec4e                	sd	s3,24(sp)
    80001aee:	e852                	sd	s4,16(sp)
    80001af0:	e456                	sd	s5,8(sp)
    80001af2:	e05a                	sd	s6,0(sp)
    80001af4:	0080                	addi	s0,sp,64
  initlock(&pid_lock, "nextpid");
    80001af6:	00006597          	auipc	a1,0x6
    80001afa:	6ea58593          	addi	a1,a1,1770 # 800081e0 <digits+0x1a0>
    80001afe:	0000f517          	auipc	a0,0xf
    80001b02:	7a250513          	addi	a0,a0,1954 # 800112a0 <pid_lock>
    80001b06:	fffff097          	auipc	ra,0xfffff
    80001b0a:	040080e7          	jalr	64(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b0e:	00010497          	auipc	s1,0x10
    80001b12:	0aa48493          	addi	s1,s1,170 # 80011bb8 <proc>
      initlock(&p->lock, "proc");
    80001b16:	00006b17          	auipc	s6,0x6
    80001b1a:	6d2b0b13          	addi	s6,s6,1746 # 800081e8 <digits+0x1a8>
      p->kstack = KSTACK((int) (p - proc));
    80001b1e:	8aa6                	mv	s5,s1
    80001b20:	00006a17          	auipc	s4,0x6
    80001b24:	4e0a0a13          	addi	s4,s4,1248 # 80008000 <etext>
    80001b28:	04000937          	lui	s2,0x4000
    80001b2c:	197d                	addi	s2,s2,-1
    80001b2e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b30:	00016997          	auipc	s3,0x16
    80001b34:	c8898993          	addi	s3,s3,-888 # 800177b8 <tickslock>
      initlock(&p->lock, "proc");
    80001b38:	85da                	mv	a1,s6
    80001b3a:	8526                	mv	a0,s1
    80001b3c:	fffff097          	auipc	ra,0xfffff
    80001b40:	00a080e7          	jalr	10(ra) # 80000b46 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001b44:	415487b3          	sub	a5,s1,s5
    80001b48:	8791                	srai	a5,a5,0x4
    80001b4a:	000a3703          	ld	a4,0(s4)
    80001b4e:	02e787b3          	mul	a5,a5,a4
    80001b52:	2785                	addiw	a5,a5,1
    80001b54:	00d7979b          	slliw	a5,a5,0xd
    80001b58:	40f907b3          	sub	a5,s2,a5
    80001b5c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b5e:	17048493          	addi	s1,s1,368
    80001b62:	fd349be3          	bne	s1,s3,80001b38 <procinit+0x56>
}
    80001b66:	70e2                	ld	ra,56(sp)
    80001b68:	7442                	ld	s0,48(sp)
    80001b6a:	74a2                	ld	s1,40(sp)
    80001b6c:	7902                	ld	s2,32(sp)
    80001b6e:	69e2                	ld	s3,24(sp)
    80001b70:	6a42                	ld	s4,16(sp)
    80001b72:	6aa2                	ld	s5,8(sp)
    80001b74:	6b02                	ld	s6,0(sp)
    80001b76:	6121                	addi	sp,sp,64
    80001b78:	8082                	ret

0000000080001b7a <cpuid>:
{
    80001b7a:	1141                	addi	sp,sp,-16
    80001b7c:	e422                	sd	s0,8(sp)
    80001b7e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b80:	8512                	mv	a0,tp
}
    80001b82:	2501                	sext.w	a0,a0
    80001b84:	6422                	ld	s0,8(sp)
    80001b86:	0141                	addi	sp,sp,16
    80001b88:	8082                	ret

0000000080001b8a <mycpu>:
mycpu(void) {
    80001b8a:	1141                	addi	sp,sp,-16
    80001b8c:	e422                	sd	s0,8(sp)
    80001b8e:	0800                	addi	s0,sp,16
    80001b90:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001b92:	2781                	sext.w	a5,a5
    80001b94:	079e                	slli	a5,a5,0x7
}
    80001b96:	0000f517          	auipc	a0,0xf
    80001b9a:	72250513          	addi	a0,a0,1826 # 800112b8 <cpus>
    80001b9e:	953e                	add	a0,a0,a5
    80001ba0:	6422                	ld	s0,8(sp)
    80001ba2:	0141                	addi	sp,sp,16
    80001ba4:	8082                	ret

0000000080001ba6 <myproc>:
myproc(void) {
    80001ba6:	1101                	addi	sp,sp,-32
    80001ba8:	ec06                	sd	ra,24(sp)
    80001baa:	e822                	sd	s0,16(sp)
    80001bac:	e426                	sd	s1,8(sp)
    80001bae:	1000                	addi	s0,sp,32
  push_off();
    80001bb0:	fffff097          	auipc	ra,0xfffff
    80001bb4:	fda080e7          	jalr	-38(ra) # 80000b8a <push_off>
    80001bb8:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001bba:	2781                	sext.w	a5,a5
    80001bbc:	079e                	slli	a5,a5,0x7
    80001bbe:	0000f717          	auipc	a4,0xf
    80001bc2:	6e270713          	addi	a4,a4,1762 # 800112a0 <pid_lock>
    80001bc6:	97ba                	add	a5,a5,a4
    80001bc8:	6f84                	ld	s1,24(a5)
  pop_off();
    80001bca:	fffff097          	auipc	ra,0xfffff
    80001bce:	060080e7          	jalr	96(ra) # 80000c2a <pop_off>
}
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	60e2                	ld	ra,24(sp)
    80001bd6:	6442                	ld	s0,16(sp)
    80001bd8:	64a2                	ld	s1,8(sp)
    80001bda:	6105                	addi	sp,sp,32
    80001bdc:	8082                	ret

0000000080001bde <forkret>:
{
    80001bde:	1141                	addi	sp,sp,-16
    80001be0:	e406                	sd	ra,8(sp)
    80001be2:	e022                	sd	s0,0(sp)
    80001be4:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001be6:	00000097          	auipc	ra,0x0
    80001bea:	fc0080e7          	jalr	-64(ra) # 80001ba6 <myproc>
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	09c080e7          	jalr	156(ra) # 80000c8a <release>
  if (first) {
    80001bf6:	00007797          	auipc	a5,0x7
    80001bfa:	c9a7a783          	lw	a5,-870(a5) # 80008890 <first.1700>
    80001bfe:	eb89                	bnez	a5,80001c10 <forkret+0x32>
  usertrapret();
    80001c00:	00001097          	auipc	ra,0x1
    80001c04:	d68080e7          	jalr	-664(ra) # 80002968 <usertrapret>
}
    80001c08:	60a2                	ld	ra,8(sp)
    80001c0a:	6402                	ld	s0,0(sp)
    80001c0c:	0141                	addi	sp,sp,16
    80001c0e:	8082                	ret
    first = 0;
    80001c10:	00007797          	auipc	a5,0x7
    80001c14:	c807a023          	sw	zero,-896(a5) # 80008890 <first.1700>
    fsinit(ROOTDEV);
    80001c18:	4505                	li	a0,1
    80001c1a:	00002097          	auipc	ra,0x2
    80001c1e:	ad0080e7          	jalr	-1328(ra) # 800036ea <fsinit>
    80001c22:	bff9                	j	80001c00 <forkret+0x22>

0000000080001c24 <allocpid>:
allocpid() {
    80001c24:	1101                	addi	sp,sp,-32
    80001c26:	ec06                	sd	ra,24(sp)
    80001c28:	e822                	sd	s0,16(sp)
    80001c2a:	e426                	sd	s1,8(sp)
    80001c2c:	e04a                	sd	s2,0(sp)
    80001c2e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c30:	0000f917          	auipc	s2,0xf
    80001c34:	67090913          	addi	s2,s2,1648 # 800112a0 <pid_lock>
    80001c38:	854a                	mv	a0,s2
    80001c3a:	fffff097          	auipc	ra,0xfffff
    80001c3e:	f9c080e7          	jalr	-100(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001c42:	00007797          	auipc	a5,0x7
    80001c46:	c5278793          	addi	a5,a5,-942 # 80008894 <nextpid>
    80001c4a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c4c:	0014871b          	addiw	a4,s1,1
    80001c50:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c52:	854a                	mv	a0,s2
    80001c54:	fffff097          	auipc	ra,0xfffff
    80001c58:	036080e7          	jalr	54(ra) # 80000c8a <release>
}
    80001c5c:	8526                	mv	a0,s1
    80001c5e:	60e2                	ld	ra,24(sp)
    80001c60:	6442                	ld	s0,16(sp)
    80001c62:	64a2                	ld	s1,8(sp)
    80001c64:	6902                	ld	s2,0(sp)
    80001c66:	6105                	addi	sp,sp,32
    80001c68:	8082                	ret

0000000080001c6a <proc_pagetable>:
{
    80001c6a:	1101                	addi	sp,sp,-32
    80001c6c:	ec06                	sd	ra,24(sp)
    80001c6e:	e822                	sd	s0,16(sp)
    80001c70:	e426                	sd	s1,8(sp)
    80001c72:	e04a                	sd	s2,0(sp)
    80001c74:	1000                	addi	s0,sp,32
    80001c76:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	688080e7          	jalr	1672(ra) # 80001300 <uvmcreate>
    80001c80:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c82:	c121                	beqz	a0,80001cc2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c84:	4729                	li	a4,10
    80001c86:	00005697          	auipc	a3,0x5
    80001c8a:	37a68693          	addi	a3,a3,890 # 80007000 <_trampoline>
    80001c8e:	6605                	lui	a2,0x1
    80001c90:	040005b7          	lui	a1,0x4000
    80001c94:	15fd                	addi	a1,a1,-1
    80001c96:	05b2                	slli	a1,a1,0xc
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	40e080e7          	jalr	1038(ra) # 800010a6 <mappages>
    80001ca0:	02054863          	bltz	a0,80001cd0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ca4:	4719                	li	a4,6
    80001ca6:	05893683          	ld	a3,88(s2)
    80001caa:	6605                	lui	a2,0x1
    80001cac:	020005b7          	lui	a1,0x2000
    80001cb0:	15fd                	addi	a1,a1,-1
    80001cb2:	05b6                	slli	a1,a1,0xd
    80001cb4:	8526                	mv	a0,s1
    80001cb6:	fffff097          	auipc	ra,0xfffff
    80001cba:	3f0080e7          	jalr	1008(ra) # 800010a6 <mappages>
    80001cbe:	02054163          	bltz	a0,80001ce0 <proc_pagetable+0x76>
}
    80001cc2:	8526                	mv	a0,s1
    80001cc4:	60e2                	ld	ra,24(sp)
    80001cc6:	6442                	ld	s0,16(sp)
    80001cc8:	64a2                	ld	s1,8(sp)
    80001cca:	6902                	ld	s2,0(sp)
    80001ccc:	6105                	addi	sp,sp,32
    80001cce:	8082                	ret
    uvmfree(pagetable, 0);
    80001cd0:	4581                	li	a1,0
    80001cd2:	8526                	mv	a0,s1
    80001cd4:	00000097          	auipc	ra,0x0
    80001cd8:	816080e7          	jalr	-2026(ra) # 800014ea <uvmfree>
    return 0;
    80001cdc:	4481                	li	s1,0
    80001cde:	b7d5                	j	80001cc2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ce0:	4681                	li	a3,0
    80001ce2:	4605                	li	a2,1
    80001ce4:	040005b7          	lui	a1,0x4000
    80001ce8:	15fd                	addi	a1,a1,-1
    80001cea:	05b2                	slli	a1,a1,0xc
    80001cec:	8526                	mv	a0,s1
    80001cee:	fffff097          	auipc	ra,0xfffff
    80001cf2:	56c080e7          	jalr	1388(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001cf6:	4581                	li	a1,0
    80001cf8:	8526                	mv	a0,s1
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	7f0080e7          	jalr	2032(ra) # 800014ea <uvmfree>
    return 0;
    80001d02:	4481                	li	s1,0
    80001d04:	bf7d                	j	80001cc2 <proc_pagetable+0x58>

0000000080001d06 <proc_freepagetable>:
{
    80001d06:	1101                	addi	sp,sp,-32
    80001d08:	ec06                	sd	ra,24(sp)
    80001d0a:	e822                	sd	s0,16(sp)
    80001d0c:	e426                	sd	s1,8(sp)
    80001d0e:	e04a                	sd	s2,0(sp)
    80001d10:	1000                	addi	s0,sp,32
    80001d12:	84aa                	mv	s1,a0
    80001d14:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d16:	4681                	li	a3,0
    80001d18:	4605                	li	a2,1
    80001d1a:	040005b7          	lui	a1,0x4000
    80001d1e:	15fd                	addi	a1,a1,-1
    80001d20:	05b2                	slli	a1,a1,0xc
    80001d22:	fffff097          	auipc	ra,0xfffff
    80001d26:	538080e7          	jalr	1336(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d2a:	4681                	li	a3,0
    80001d2c:	4605                	li	a2,1
    80001d2e:	020005b7          	lui	a1,0x2000
    80001d32:	15fd                	addi	a1,a1,-1
    80001d34:	05b6                	slli	a1,a1,0xd
    80001d36:	8526                	mv	a0,s1
    80001d38:	fffff097          	auipc	ra,0xfffff
    80001d3c:	522080e7          	jalr	1314(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001d40:	85ca                	mv	a1,s2
    80001d42:	8526                	mv	a0,s1
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	7a6080e7          	jalr	1958(ra) # 800014ea <uvmfree>
}
    80001d4c:	60e2                	ld	ra,24(sp)
    80001d4e:	6442                	ld	s0,16(sp)
    80001d50:	64a2                	ld	s1,8(sp)
    80001d52:	6902                	ld	s2,0(sp)
    80001d54:	6105                	addi	sp,sp,32
    80001d56:	8082                	ret

0000000080001d58 <freeproc>:
{
    80001d58:	1101                	addi	sp,sp,-32
    80001d5a:	ec06                	sd	ra,24(sp)
    80001d5c:	e822                	sd	s0,16(sp)
    80001d5e:	e426                	sd	s1,8(sp)
    80001d60:	1000                	addi	s0,sp,32
    80001d62:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001d64:	6d28                	ld	a0,88(a0)
    80001d66:	c509                	beqz	a0,80001d70 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001d68:	fffff097          	auipc	ra,0xfffff
    80001d6c:	c82080e7          	jalr	-894(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001d70:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001d74:	68a8                	ld	a0,80(s1)
    80001d76:	c511                	beqz	a0,80001d82 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d78:	64ac                	ld	a1,72(s1)
    80001d7a:	00000097          	auipc	ra,0x0
    80001d7e:	f8c080e7          	jalr	-116(ra) # 80001d06 <proc_freepagetable>
  p->pagetable = 0;
    80001d82:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d86:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d8a:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001d8e:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001d92:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001d96:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001d9a:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001d9e:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001da2:	0004ac23          	sw	zero,24(s1)
}
    80001da6:	60e2                	ld	ra,24(sp)
    80001da8:	6442                	ld	s0,16(sp)
    80001daa:	64a2                	ld	s1,8(sp)
    80001dac:	6105                	addi	sp,sp,32
    80001dae:	8082                	ret

0000000080001db0 <allocproc>:
{
    80001db0:	1101                	addi	sp,sp,-32
    80001db2:	ec06                	sd	ra,24(sp)
    80001db4:	e822                	sd	s0,16(sp)
    80001db6:	e426                	sd	s1,8(sp)
    80001db8:	e04a                	sd	s2,0(sp)
    80001dba:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001dbc:	00010497          	auipc	s1,0x10
    80001dc0:	dfc48493          	addi	s1,s1,-516 # 80011bb8 <proc>
    80001dc4:	00016917          	auipc	s2,0x16
    80001dc8:	9f490913          	addi	s2,s2,-1548 # 800177b8 <tickslock>
    acquire(&p->lock);
    80001dcc:	8526                	mv	a0,s1
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	e08080e7          	jalr	-504(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001dd6:	4c9c                	lw	a5,24(s1)
    80001dd8:	cf81                	beqz	a5,80001df0 <allocproc+0x40>
      release(&p->lock);
    80001dda:	8526                	mv	a0,s1
    80001ddc:	fffff097          	auipc	ra,0xfffff
    80001de0:	eae080e7          	jalr	-338(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001de4:	17048493          	addi	s1,s1,368
    80001de8:	ff2492e3          	bne	s1,s2,80001dcc <allocproc+0x1c>
  return 0;
    80001dec:	4481                	li	s1,0
    80001dee:	a0b9                	j	80001e3c <allocproc+0x8c>
  p->pid = allocpid();
    80001df0:	00000097          	auipc	ra,0x0
    80001df4:	e34080e7          	jalr	-460(ra) # 80001c24 <allocpid>
    80001df8:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	cec080e7          	jalr	-788(ra) # 80000ae6 <kalloc>
    80001e02:	892a                	mv	s2,a0
    80001e04:	eca8                	sd	a0,88(s1)
    80001e06:	c131                	beqz	a0,80001e4a <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001e08:	8526                	mv	a0,s1
    80001e0a:	00000097          	auipc	ra,0x0
    80001e0e:	e60080e7          	jalr	-416(ra) # 80001c6a <proc_pagetable>
    80001e12:	892a                	mv	s2,a0
    80001e14:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001e16:	c129                	beqz	a0,80001e58 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001e18:	07000613          	li	a2,112
    80001e1c:	4581                	li	a1,0
    80001e1e:	06048513          	addi	a0,s1,96
    80001e22:	fffff097          	auipc	ra,0xfffff
    80001e26:	eb0080e7          	jalr	-336(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001e2a:	00000797          	auipc	a5,0x0
    80001e2e:	db478793          	addi	a5,a5,-588 # 80001bde <forkret>
    80001e32:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e34:	60bc                	ld	a5,64(s1)
    80001e36:	6705                	lui	a4,0x1
    80001e38:	97ba                	add	a5,a5,a4
    80001e3a:	f4bc                	sd	a5,104(s1)
}
    80001e3c:	8526                	mv	a0,s1
    80001e3e:	60e2                	ld	ra,24(sp)
    80001e40:	6442                	ld	s0,16(sp)
    80001e42:	64a2                	ld	s1,8(sp)
    80001e44:	6902                	ld	s2,0(sp)
    80001e46:	6105                	addi	sp,sp,32
    80001e48:	8082                	ret
    release(&p->lock);
    80001e4a:	8526                	mv	a0,s1
    80001e4c:	fffff097          	auipc	ra,0xfffff
    80001e50:	e3e080e7          	jalr	-450(ra) # 80000c8a <release>
    return 0;
    80001e54:	84ca                	mv	s1,s2
    80001e56:	b7dd                	j	80001e3c <allocproc+0x8c>
    freeproc(p);
    80001e58:	8526                	mv	a0,s1
    80001e5a:	00000097          	auipc	ra,0x0
    80001e5e:	efe080e7          	jalr	-258(ra) # 80001d58 <freeproc>
    release(&p->lock);
    80001e62:	8526                	mv	a0,s1
    80001e64:	fffff097          	auipc	ra,0xfffff
    80001e68:	e26080e7          	jalr	-474(ra) # 80000c8a <release>
    return 0;
    80001e6c:	84ca                	mv	s1,s2
    80001e6e:	b7f9                	j	80001e3c <allocproc+0x8c>

0000000080001e70 <userinit>:
{
    80001e70:	1101                	addi	sp,sp,-32
    80001e72:	ec06                	sd	ra,24(sp)
    80001e74:	e822                	sd	s0,16(sp)
    80001e76:	e426                	sd	s1,8(sp)
    80001e78:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e7a:	00000097          	auipc	ra,0x0
    80001e7e:	f36080e7          	jalr	-202(ra) # 80001db0 <allocproc>
    80001e82:	84aa                	mv	s1,a0
  initproc = p;
    80001e84:	00007797          	auipc	a5,0x7
    80001e88:	1aa7b223          	sd	a0,420(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e8c:	03400613          	li	a2,52
    80001e90:	00007597          	auipc	a1,0x7
    80001e94:	a1058593          	addi	a1,a1,-1520 # 800088a0 <initcode>
    80001e98:	6928                	ld	a0,80(a0)
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	494080e7          	jalr	1172(ra) # 8000132e <uvminit>
  p->sz = PGSIZE;
    80001ea2:	6785                	lui	a5,0x1
    80001ea4:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ea6:	6cb8                	ld	a4,88(s1)
    80001ea8:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001eac:	6cb8                	ld	a4,88(s1)
    80001eae:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001eb0:	4641                	li	a2,16
    80001eb2:	00006597          	auipc	a1,0x6
    80001eb6:	33e58593          	addi	a1,a1,830 # 800081f0 <digits+0x1b0>
    80001eba:	16048513          	addi	a0,s1,352
    80001ebe:	fffff097          	auipc	ra,0xfffff
    80001ec2:	f6a080e7          	jalr	-150(ra) # 80000e28 <safestrcpy>
  p->cwd = namei("/");
    80001ec6:	00006517          	auipc	a0,0x6
    80001eca:	33a50513          	addi	a0,a0,826 # 80008200 <digits+0x1c0>
    80001ece:	00002097          	auipc	ra,0x2
    80001ed2:	24a080e7          	jalr	586(ra) # 80004118 <namei>
    80001ed6:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001eda:	4789                	li	a5,2
    80001edc:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001ede:	8526                	mv	a0,s1
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	daa080e7          	jalr	-598(ra) # 80000c8a <release>
}
    80001ee8:	60e2                	ld	ra,24(sp)
    80001eea:	6442                	ld	s0,16(sp)
    80001eec:	64a2                	ld	s1,8(sp)
    80001eee:	6105                	addi	sp,sp,32
    80001ef0:	8082                	ret

0000000080001ef2 <growproc>:
{
    80001ef2:	1101                	addi	sp,sp,-32
    80001ef4:	ec06                	sd	ra,24(sp)
    80001ef6:	e822                	sd	s0,16(sp)
    80001ef8:	e426                	sd	s1,8(sp)
    80001efa:	e04a                	sd	s2,0(sp)
    80001efc:	1000                	addi	s0,sp,32
    80001efe:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001f00:	00000097          	auipc	ra,0x0
    80001f04:	ca6080e7          	jalr	-858(ra) # 80001ba6 <myproc>
    80001f08:	892a                	mv	s2,a0
  sz = p->sz;
    80001f0a:	652c                	ld	a1,72(a0)
    80001f0c:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001f10:	00904f63          	bgtz	s1,80001f2e <growproc+0x3c>
  } else if(n < 0){
    80001f14:	0204cc63          	bltz	s1,80001f4c <growproc+0x5a>
  p->sz = sz;
    80001f18:	1602                	slli	a2,a2,0x20
    80001f1a:	9201                	srli	a2,a2,0x20
    80001f1c:	04c93423          	sd	a2,72(s2)
  return 0;
    80001f20:	4501                	li	a0,0
}
    80001f22:	60e2                	ld	ra,24(sp)
    80001f24:	6442                	ld	s0,16(sp)
    80001f26:	64a2                	ld	s1,8(sp)
    80001f28:	6902                	ld	s2,0(sp)
    80001f2a:	6105                	addi	sp,sp,32
    80001f2c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001f2e:	9e25                	addw	a2,a2,s1
    80001f30:	1602                	slli	a2,a2,0x20
    80001f32:	9201                	srli	a2,a2,0x20
    80001f34:	1582                	slli	a1,a1,0x20
    80001f36:	9181                	srli	a1,a1,0x20
    80001f38:	6928                	ld	a0,80(a0)
    80001f3a:	fffff097          	auipc	ra,0xfffff
    80001f3e:	4ae080e7          	jalr	1198(ra) # 800013e8 <uvmalloc>
    80001f42:	0005061b          	sext.w	a2,a0
    80001f46:	fa69                	bnez	a2,80001f18 <growproc+0x26>
      return -1;
    80001f48:	557d                	li	a0,-1
    80001f4a:	bfe1                	j	80001f22 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f4c:	9e25                	addw	a2,a2,s1
    80001f4e:	1602                	slli	a2,a2,0x20
    80001f50:	9201                	srli	a2,a2,0x20
    80001f52:	1582                	slli	a1,a1,0x20
    80001f54:	9181                	srli	a1,a1,0x20
    80001f56:	6928                	ld	a0,80(a0)
    80001f58:	fffff097          	auipc	ra,0xfffff
    80001f5c:	448080e7          	jalr	1096(ra) # 800013a0 <uvmdealloc>
    80001f60:	0005061b          	sext.w	a2,a0
    80001f64:	bf55                	j	80001f18 <growproc+0x26>

0000000080001f66 <reparent>:
{
    80001f66:	7179                	addi	sp,sp,-48
    80001f68:	f406                	sd	ra,40(sp)
    80001f6a:	f022                	sd	s0,32(sp)
    80001f6c:	ec26                	sd	s1,24(sp)
    80001f6e:	e84a                	sd	s2,16(sp)
    80001f70:	e44e                	sd	s3,8(sp)
    80001f72:	e052                	sd	s4,0(sp)
    80001f74:	1800                	addi	s0,sp,48
    80001f76:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f78:	00010497          	auipc	s1,0x10
    80001f7c:	c4048493          	addi	s1,s1,-960 # 80011bb8 <proc>
      pp->parent = initproc;
    80001f80:	00007a17          	auipc	s4,0x7
    80001f84:	0a8a0a13          	addi	s4,s4,168 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f88:	00016997          	auipc	s3,0x16
    80001f8c:	83098993          	addi	s3,s3,-2000 # 800177b8 <tickslock>
    80001f90:	a029                	j	80001f9a <reparent+0x34>
    80001f92:	17048493          	addi	s1,s1,368
    80001f96:	03348363          	beq	s1,s3,80001fbc <reparent+0x56>
    if(pp->parent == p){
    80001f9a:	709c                	ld	a5,32(s1)
    80001f9c:	ff279be3          	bne	a5,s2,80001f92 <reparent+0x2c>
      acquire(&pp->lock);
    80001fa0:	8526                	mv	a0,s1
    80001fa2:	fffff097          	auipc	ra,0xfffff
    80001fa6:	c34080e7          	jalr	-972(ra) # 80000bd6 <acquire>
      pp->parent = initproc;
    80001faa:	000a3783          	ld	a5,0(s4)
    80001fae:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001fb0:	8526                	mv	a0,s1
    80001fb2:	fffff097          	auipc	ra,0xfffff
    80001fb6:	cd8080e7          	jalr	-808(ra) # 80000c8a <release>
    80001fba:	bfe1                	j	80001f92 <reparent+0x2c>
}
    80001fbc:	70a2                	ld	ra,40(sp)
    80001fbe:	7402                	ld	s0,32(sp)
    80001fc0:	64e2                	ld	s1,24(sp)
    80001fc2:	6942                	ld	s2,16(sp)
    80001fc4:	69a2                	ld	s3,8(sp)
    80001fc6:	6a02                	ld	s4,0(sp)
    80001fc8:	6145                	addi	sp,sp,48
    80001fca:	8082                	ret

0000000080001fcc <scheduler>:
{
    80001fcc:	711d                	addi	sp,sp,-96
    80001fce:	ec86                	sd	ra,88(sp)
    80001fd0:	e8a2                	sd	s0,80(sp)
    80001fd2:	e4a6                	sd	s1,72(sp)
    80001fd4:	e0ca                	sd	s2,64(sp)
    80001fd6:	fc4e                	sd	s3,56(sp)
    80001fd8:	f852                	sd	s4,48(sp)
    80001fda:	f456                	sd	s5,40(sp)
    80001fdc:	f05a                	sd	s6,32(sp)
    80001fde:	ec5e                	sd	s7,24(sp)
    80001fe0:	e862                	sd	s8,16(sp)
    80001fe2:	e466                	sd	s9,8(sp)
    80001fe4:	1080                	addi	s0,sp,96
    80001fe6:	8792                	mv	a5,tp
  int id = r_tp();
    80001fe8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fea:	00779c13          	slli	s8,a5,0x7
    80001fee:	0000f717          	auipc	a4,0xf
    80001ff2:	2b270713          	addi	a4,a4,690 # 800112a0 <pid_lock>
    80001ff6:	9762                	add	a4,a4,s8
    80001ff8:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001ffc:	0000f717          	auipc	a4,0xf
    80002000:	2c470713          	addi	a4,a4,708 # 800112c0 <cpus+0x8>
    80002004:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    80002006:	4a89                	li	s5,2
        c->proc = p;
    80002008:	079e                	slli	a5,a5,0x7
    8000200a:	0000fb17          	auipc	s6,0xf
    8000200e:	296b0b13          	addi	s6,s6,662 # 800112a0 <pid_lock>
    80002012:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002014:	00015a17          	auipc	s4,0x15
    80002018:	7a4a0a13          	addi	s4,s4,1956 # 800177b8 <tickslock>
    int nproc = 0;
    8000201c:	4c81                	li	s9,0
    8000201e:	a8a1                	j	80002076 <scheduler+0xaa>
        p->state = RUNNING;
    80002020:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80002024:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    80002028:	06048593          	addi	a1,s1,96
    8000202c:	8562                	mv	a0,s8
    8000202e:	00001097          	auipc	ra,0x1
    80002032:	890080e7          	jalr	-1904(ra) # 800028be <swtch>
        c->proc = 0;
    80002036:	000b3c23          	sd	zero,24(s6)
      release(&p->lock);
    8000203a:	8526                	mv	a0,s1
    8000203c:	fffff097          	auipc	ra,0xfffff
    80002040:	c4e080e7          	jalr	-946(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002044:	17048493          	addi	s1,s1,368
    80002048:	01448d63          	beq	s1,s4,80002062 <scheduler+0x96>
      acquire(&p->lock);
    8000204c:	8526                	mv	a0,s1
    8000204e:	fffff097          	auipc	ra,0xfffff
    80002052:	b88080e7          	jalr	-1144(ra) # 80000bd6 <acquire>
      if(p->state != UNUSED) {
    80002056:	4c9c                	lw	a5,24(s1)
    80002058:	d3ed                	beqz	a5,8000203a <scheduler+0x6e>
        nproc++;
    8000205a:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    8000205c:	fd579fe3          	bne	a5,s5,8000203a <scheduler+0x6e>
    80002060:	b7c1                	j	80002020 <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80002062:	013aca63          	blt	s5,s3,80002076 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002066:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000206a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000206e:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002072:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002076:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000207a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000207e:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    80002082:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    80002084:	00010497          	auipc	s1,0x10
    80002088:	b3448493          	addi	s1,s1,-1228 # 80011bb8 <proc>
        p->state = RUNNING;
    8000208c:	4b8d                	li	s7,3
    8000208e:	bf7d                	j	8000204c <scheduler+0x80>

0000000080002090 <sched>:
{
    80002090:	7179                	addi	sp,sp,-48
    80002092:	f406                	sd	ra,40(sp)
    80002094:	f022                	sd	s0,32(sp)
    80002096:	ec26                	sd	s1,24(sp)
    80002098:	e84a                	sd	s2,16(sp)
    8000209a:	e44e                	sd	s3,8(sp)
    8000209c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000209e:	00000097          	auipc	ra,0x0
    800020a2:	b08080e7          	jalr	-1272(ra) # 80001ba6 <myproc>
    800020a6:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800020a8:	fffff097          	auipc	ra,0xfffff
    800020ac:	ab4080e7          	jalr	-1356(ra) # 80000b5c <holding>
    800020b0:	c93d                	beqz	a0,80002126 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020b2:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020b4:	2781                	sext.w	a5,a5
    800020b6:	079e                	slli	a5,a5,0x7
    800020b8:	0000f717          	auipc	a4,0xf
    800020bc:	1e870713          	addi	a4,a4,488 # 800112a0 <pid_lock>
    800020c0:	97ba                	add	a5,a5,a4
    800020c2:	0907a703          	lw	a4,144(a5) # 1090 <_entry-0x7fffef70>
    800020c6:	4785                	li	a5,1
    800020c8:	06f71763          	bne	a4,a5,80002136 <sched+0xa6>
  if(p->state == RUNNING)
    800020cc:	4c98                	lw	a4,24(s1)
    800020ce:	478d                	li	a5,3
    800020d0:	06f70b63          	beq	a4,a5,80002146 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020d4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020d8:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020da:	efb5                	bnez	a5,80002156 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020dc:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020de:	0000f917          	auipc	s2,0xf
    800020e2:	1c290913          	addi	s2,s2,450 # 800112a0 <pid_lock>
    800020e6:	2781                	sext.w	a5,a5
    800020e8:	079e                	slli	a5,a5,0x7
    800020ea:	97ca                	add	a5,a5,s2
    800020ec:	0947a983          	lw	s3,148(a5)
    800020f0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020f2:	2781                	sext.w	a5,a5
    800020f4:	079e                	slli	a5,a5,0x7
    800020f6:	0000f597          	auipc	a1,0xf
    800020fa:	1ca58593          	addi	a1,a1,458 # 800112c0 <cpus+0x8>
    800020fe:	95be                	add	a1,a1,a5
    80002100:	06048513          	addi	a0,s1,96
    80002104:	00000097          	auipc	ra,0x0
    80002108:	7ba080e7          	jalr	1978(ra) # 800028be <swtch>
    8000210c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000210e:	2781                	sext.w	a5,a5
    80002110:	079e                	slli	a5,a5,0x7
    80002112:	97ca                	add	a5,a5,s2
    80002114:	0937aa23          	sw	s3,148(a5)
}
    80002118:	70a2                	ld	ra,40(sp)
    8000211a:	7402                	ld	s0,32(sp)
    8000211c:	64e2                	ld	s1,24(sp)
    8000211e:	6942                	ld	s2,16(sp)
    80002120:	69a2                	ld	s3,8(sp)
    80002122:	6145                	addi	sp,sp,48
    80002124:	8082                	ret
    panic("sched p->lock");
    80002126:	00006517          	auipc	a0,0x6
    8000212a:	0e250513          	addi	a0,a0,226 # 80008208 <digits+0x1c8>
    8000212e:	ffffe097          	auipc	ra,0xffffe
    80002132:	402080e7          	jalr	1026(ra) # 80000530 <panic>
    panic("sched locks");
    80002136:	00006517          	auipc	a0,0x6
    8000213a:	0e250513          	addi	a0,a0,226 # 80008218 <digits+0x1d8>
    8000213e:	ffffe097          	auipc	ra,0xffffe
    80002142:	3f2080e7          	jalr	1010(ra) # 80000530 <panic>
    panic("sched running");
    80002146:	00006517          	auipc	a0,0x6
    8000214a:	0e250513          	addi	a0,a0,226 # 80008228 <digits+0x1e8>
    8000214e:	ffffe097          	auipc	ra,0xffffe
    80002152:	3e2080e7          	jalr	994(ra) # 80000530 <panic>
    panic("sched interruptible");
    80002156:	00006517          	auipc	a0,0x6
    8000215a:	0e250513          	addi	a0,a0,226 # 80008238 <digits+0x1f8>
    8000215e:	ffffe097          	auipc	ra,0xffffe
    80002162:	3d2080e7          	jalr	978(ra) # 80000530 <panic>

0000000080002166 <exit>:
{
    80002166:	7139                	addi	sp,sp,-64
    80002168:	fc06                	sd	ra,56(sp)
    8000216a:	f822                	sd	s0,48(sp)
    8000216c:	f426                	sd	s1,40(sp)
    8000216e:	f04a                	sd	s2,32(sp)
    80002170:	ec4e                	sd	s3,24(sp)
    80002172:	e852                	sd	s4,16(sp)
    80002174:	e456                	sd	s5,8(sp)
    80002176:	e05a                	sd	s6,0(sp)
    80002178:	0080                	addi	s0,sp,64
    8000217a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000217c:	00000097          	auipc	ra,0x0
    80002180:	a2a080e7          	jalr	-1494(ra) # 80001ba6 <myproc>
  if(p == initproc)
    80002184:	00007797          	auipc	a5,0x7
    80002188:	ea47b783          	ld	a5,-348(a5) # 80009028 <initproc>
    8000218c:	06a78763          	beq	a5,a0,800021fa <exit+0x94>
    80002190:	89aa                	mv	s3,a0
  struct vma* v = p->vma;
    80002192:	15853483          	ld	s1,344(a0)
  while(v){
    80002196:	cca9                	beqz	s1,800021f0 <exit+0x8a>
    uvmunmap(p->pagetable, v->start, PGROUNDUP(v->length) / PGSIZE, 1);
    80002198:	6a85                	lui	s5,0x1
    8000219a:	1afd                	addi	s5,s5,-1
    writeback(v, v->start, v->length);
    8000219c:	4890                	lw	a2,16(s1)
    8000219e:	608c                	ld	a1,0(s1)
    800021a0:	8526                	mv	a0,s1
    800021a2:	fffff097          	auipc	ra,0xfffff
    800021a6:	744080e7          	jalr	1860(ra) # 800018e6 <writeback>
    uvmunmap(p->pagetable, v->start, PGROUNDUP(v->length) / PGSIZE, 1);
    800021aa:	6890                	ld	a2,16(s1)
    800021ac:	9656                	add	a2,a2,s5
    800021ae:	4685                	li	a3,1
    800021b0:	8231                	srli	a2,a2,0xc
    800021b2:	608c                	ld	a1,0(s1)
    800021b4:	0509b503          	ld	a0,80(s3)
    800021b8:	fffff097          	auipc	ra,0xfffff
    800021bc:	0a2080e7          	jalr	162(ra) # 8000125a <uvmunmap>
    fileclose(v->file);
    800021c0:	7488                	ld	a0,40(s1)
    800021c2:	00002097          	auipc	ra,0x2
    800021c6:	646080e7          	jalr	1606(ra) # 80004808 <fileclose>
    pv = v->next;
    800021ca:	8926                	mv	s2,s1
    800021cc:	7884                	ld	s1,48(s1)
    acquire(&v->lock);
    800021ce:	03890a13          	addi	s4,s2,56
    800021d2:	8552                	mv	a0,s4
    800021d4:	fffff097          	auipc	ra,0xfffff
    800021d8:	a02080e7          	jalr	-1534(ra) # 80000bd6 <acquire>
    v->next = 0;
    800021dc:	02093823          	sd	zero,48(s2)
    v->length = 0;
    800021e0:	00093823          	sd	zero,16(s2)
    release(&v->lock);
    800021e4:	8552                	mv	a0,s4
    800021e6:	fffff097          	auipc	ra,0xfffff
    800021ea:	aa4080e7          	jalr	-1372(ra) # 80000c8a <release>
  while(v){
    800021ee:	f4dd                	bnez	s1,8000219c <exit+0x36>
  for(int fd = 0; fd < NOFILE; fd++){
    800021f0:	0d098493          	addi	s1,s3,208
    800021f4:	15098913          	addi	s2,s3,336
    800021f8:	a015                	j	8000221c <exit+0xb6>
    panic("init exiting");
    800021fa:	00006517          	auipc	a0,0x6
    800021fe:	05650513          	addi	a0,a0,86 # 80008250 <digits+0x210>
    80002202:	ffffe097          	auipc	ra,0xffffe
    80002206:	32e080e7          	jalr	814(ra) # 80000530 <panic>
      fileclose(f);
    8000220a:	00002097          	auipc	ra,0x2
    8000220e:	5fe080e7          	jalr	1534(ra) # 80004808 <fileclose>
      p->ofile[fd] = 0;
    80002212:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002216:	04a1                	addi	s1,s1,8
    80002218:	01248563          	beq	s1,s2,80002222 <exit+0xbc>
    if(p->ofile[fd]){
    8000221c:	6088                	ld	a0,0(s1)
    8000221e:	f575                	bnez	a0,8000220a <exit+0xa4>
    80002220:	bfdd                	j	80002216 <exit+0xb0>
  begin_op();
    80002222:	00002097          	auipc	ra,0x2
    80002226:	112080e7          	jalr	274(ra) # 80004334 <begin_op>
  iput(p->cwd);
    8000222a:	1509b503          	ld	a0,336(s3)
    8000222e:	00002097          	auipc	ra,0x2
    80002232:	8ee080e7          	jalr	-1810(ra) # 80003b1c <iput>
  end_op();
    80002236:	00002097          	auipc	ra,0x2
    8000223a:	17e080e7          	jalr	382(ra) # 800043b4 <end_op>
  p->cwd = 0;
    8000223e:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002242:	00007497          	auipc	s1,0x7
    80002246:	de648493          	addi	s1,s1,-538 # 80009028 <initproc>
    8000224a:	6088                	ld	a0,0(s1)
    8000224c:	fffff097          	auipc	ra,0xfffff
    80002250:	98a080e7          	jalr	-1654(ra) # 80000bd6 <acquire>
  wakeup1(initproc);
    80002254:	6088                	ld	a0,0(s1)
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	7b2080e7          	jalr	1970(ra) # 80001a08 <wakeup1>
  release(&initproc->lock);
    8000225e:	6088                	ld	a0,0(s1)
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	a2a080e7          	jalr	-1494(ra) # 80000c8a <release>
  acquire(&p->lock);
    80002268:	854e                	mv	a0,s3
    8000226a:	fffff097          	auipc	ra,0xfffff
    8000226e:	96c080e7          	jalr	-1684(ra) # 80000bd6 <acquire>
  struct proc *original_parent = p->parent;
    80002272:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002276:	854e                	mv	a0,s3
    80002278:	fffff097          	auipc	ra,0xfffff
    8000227c:	a12080e7          	jalr	-1518(ra) # 80000c8a <release>
  acquire(&original_parent->lock);
    80002280:	8526                	mv	a0,s1
    80002282:	fffff097          	auipc	ra,0xfffff
    80002286:	954080e7          	jalr	-1708(ra) # 80000bd6 <acquire>
  acquire(&p->lock);
    8000228a:	854e                	mv	a0,s3
    8000228c:	fffff097          	auipc	ra,0xfffff
    80002290:	94a080e7          	jalr	-1718(ra) # 80000bd6 <acquire>
  reparent(p);
    80002294:	854e                	mv	a0,s3
    80002296:	00000097          	auipc	ra,0x0
    8000229a:	cd0080e7          	jalr	-816(ra) # 80001f66 <reparent>
  wakeup1(original_parent);
    8000229e:	8526                	mv	a0,s1
    800022a0:	fffff097          	auipc	ra,0xfffff
    800022a4:	768080e7          	jalr	1896(ra) # 80001a08 <wakeup1>
  p->xstate = status;
    800022a8:	0369aa23          	sw	s6,52(s3)
  p->state = ZOMBIE;
    800022ac:	4791                	li	a5,4
    800022ae:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800022b2:	8526                	mv	a0,s1
    800022b4:	fffff097          	auipc	ra,0xfffff
    800022b8:	9d6080e7          	jalr	-1578(ra) # 80000c8a <release>
  sched();
    800022bc:	00000097          	auipc	ra,0x0
    800022c0:	dd4080e7          	jalr	-556(ra) # 80002090 <sched>
  panic("zombie exit");
    800022c4:	00006517          	auipc	a0,0x6
    800022c8:	f9c50513          	addi	a0,a0,-100 # 80008260 <digits+0x220>
    800022cc:	ffffe097          	auipc	ra,0xffffe
    800022d0:	264080e7          	jalr	612(ra) # 80000530 <panic>

00000000800022d4 <yield>:
{
    800022d4:	1101                	addi	sp,sp,-32
    800022d6:	ec06                	sd	ra,24(sp)
    800022d8:	e822                	sd	s0,16(sp)
    800022da:	e426                	sd	s1,8(sp)
    800022dc:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800022de:	00000097          	auipc	ra,0x0
    800022e2:	8c8080e7          	jalr	-1848(ra) # 80001ba6 <myproc>
    800022e6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022e8:	fffff097          	auipc	ra,0xfffff
    800022ec:	8ee080e7          	jalr	-1810(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    800022f0:	4789                	li	a5,2
    800022f2:	cc9c                	sw	a5,24(s1)
  sched();
    800022f4:	00000097          	auipc	ra,0x0
    800022f8:	d9c080e7          	jalr	-612(ra) # 80002090 <sched>
  release(&p->lock);
    800022fc:	8526                	mv	a0,s1
    800022fe:	fffff097          	auipc	ra,0xfffff
    80002302:	98c080e7          	jalr	-1652(ra) # 80000c8a <release>
}
    80002306:	60e2                	ld	ra,24(sp)
    80002308:	6442                	ld	s0,16(sp)
    8000230a:	64a2                	ld	s1,8(sp)
    8000230c:	6105                	addi	sp,sp,32
    8000230e:	8082                	ret

0000000080002310 <sleep>:
{
    80002310:	7179                	addi	sp,sp,-48
    80002312:	f406                	sd	ra,40(sp)
    80002314:	f022                	sd	s0,32(sp)
    80002316:	ec26                	sd	s1,24(sp)
    80002318:	e84a                	sd	s2,16(sp)
    8000231a:	e44e                	sd	s3,8(sp)
    8000231c:	1800                	addi	s0,sp,48
    8000231e:	89aa                	mv	s3,a0
    80002320:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002322:	00000097          	auipc	ra,0x0
    80002326:	884080e7          	jalr	-1916(ra) # 80001ba6 <myproc>
    8000232a:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000232c:	05250663          	beq	a0,s2,80002378 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	8a6080e7          	jalr	-1882(ra) # 80000bd6 <acquire>
    release(lk);
    80002338:	854a                	mv	a0,s2
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	950080e7          	jalr	-1712(ra) # 80000c8a <release>
  p->chan = chan;
    80002342:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002346:	4785                	li	a5,1
    80002348:	cc9c                	sw	a5,24(s1)
  sched();
    8000234a:	00000097          	auipc	ra,0x0
    8000234e:	d46080e7          	jalr	-698(ra) # 80002090 <sched>
  p->chan = 0;
    80002352:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002356:	8526                	mv	a0,s1
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	932080e7          	jalr	-1742(ra) # 80000c8a <release>
    acquire(lk);
    80002360:	854a                	mv	a0,s2
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	874080e7          	jalr	-1932(ra) # 80000bd6 <acquire>
}
    8000236a:	70a2                	ld	ra,40(sp)
    8000236c:	7402                	ld	s0,32(sp)
    8000236e:	64e2                	ld	s1,24(sp)
    80002370:	6942                	ld	s2,16(sp)
    80002372:	69a2                	ld	s3,8(sp)
    80002374:	6145                	addi	sp,sp,48
    80002376:	8082                	ret
  p->chan = chan;
    80002378:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000237c:	4785                	li	a5,1
    8000237e:	cd1c                	sw	a5,24(a0)
  sched();
    80002380:	00000097          	auipc	ra,0x0
    80002384:	d10080e7          	jalr	-752(ra) # 80002090 <sched>
  p->chan = 0;
    80002388:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    8000238c:	bff9                	j	8000236a <sleep+0x5a>

000000008000238e <wait>:
{
    8000238e:	715d                	addi	sp,sp,-80
    80002390:	e486                	sd	ra,72(sp)
    80002392:	e0a2                	sd	s0,64(sp)
    80002394:	fc26                	sd	s1,56(sp)
    80002396:	f84a                	sd	s2,48(sp)
    80002398:	f44e                	sd	s3,40(sp)
    8000239a:	f052                	sd	s4,32(sp)
    8000239c:	ec56                	sd	s5,24(sp)
    8000239e:	e85a                	sd	s6,16(sp)
    800023a0:	e45e                	sd	s7,8(sp)
    800023a2:	e062                	sd	s8,0(sp)
    800023a4:	0880                	addi	s0,sp,80
    800023a6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	7fe080e7          	jalr	2046(ra) # 80001ba6 <myproc>
    800023b0:	892a                	mv	s2,a0
  acquire(&p->lock);
    800023b2:	8c2a                	mv	s8,a0
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	822080e7          	jalr	-2014(ra) # 80000bd6 <acquire>
    havekids = 0;
    800023bc:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800023be:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800023c0:	00015997          	auipc	s3,0x15
    800023c4:	3f898993          	addi	s3,s3,1016 # 800177b8 <tickslock>
        havekids = 1;
    800023c8:	4a85                	li	s5,1
    havekids = 0;
    800023ca:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800023cc:	0000f497          	auipc	s1,0xf
    800023d0:	7ec48493          	addi	s1,s1,2028 # 80011bb8 <proc>
    800023d4:	a08d                	j	80002436 <wait+0xa8>
          pid = np->pid;
    800023d6:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800023da:	000b0e63          	beqz	s6,800023f6 <wait+0x68>
    800023de:	4691                	li	a3,4
    800023e0:	03448613          	addi	a2,s1,52
    800023e4:	85da                	mv	a1,s6
    800023e6:	05093503          	ld	a0,80(s2)
    800023ea:	fffff097          	auipc	ra,0xfffff
    800023ee:	23c080e7          	jalr	572(ra) # 80001626 <copyout>
    800023f2:	02054263          	bltz	a0,80002416 <wait+0x88>
          freeproc(np);
    800023f6:	8526                	mv	a0,s1
    800023f8:	00000097          	auipc	ra,0x0
    800023fc:	960080e7          	jalr	-1696(ra) # 80001d58 <freeproc>
          release(&np->lock);
    80002400:	8526                	mv	a0,s1
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	888080e7          	jalr	-1912(ra) # 80000c8a <release>
          release(&p->lock);
    8000240a:	854a                	mv	a0,s2
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	87e080e7          	jalr	-1922(ra) # 80000c8a <release>
          return pid;
    80002414:	a8a9                	j	8000246e <wait+0xe0>
            release(&np->lock);
    80002416:	8526                	mv	a0,s1
    80002418:	fffff097          	auipc	ra,0xfffff
    8000241c:	872080e7          	jalr	-1934(ra) # 80000c8a <release>
            release(&p->lock);
    80002420:	854a                	mv	a0,s2
    80002422:	fffff097          	auipc	ra,0xfffff
    80002426:	868080e7          	jalr	-1944(ra) # 80000c8a <release>
            return -1;
    8000242a:	59fd                	li	s3,-1
    8000242c:	a089                	j	8000246e <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    8000242e:	17048493          	addi	s1,s1,368
    80002432:	03348463          	beq	s1,s3,8000245a <wait+0xcc>
      if(np->parent == p){
    80002436:	709c                	ld	a5,32(s1)
    80002438:	ff279be3          	bne	a5,s2,8000242e <wait+0xa0>
        acquire(&np->lock);
    8000243c:	8526                	mv	a0,s1
    8000243e:	ffffe097          	auipc	ra,0xffffe
    80002442:	798080e7          	jalr	1944(ra) # 80000bd6 <acquire>
        if(np->state == ZOMBIE){
    80002446:	4c9c                	lw	a5,24(s1)
    80002448:	f94787e3          	beq	a5,s4,800023d6 <wait+0x48>
        release(&np->lock);
    8000244c:	8526                	mv	a0,s1
    8000244e:	fffff097          	auipc	ra,0xfffff
    80002452:	83c080e7          	jalr	-1988(ra) # 80000c8a <release>
        havekids = 1;
    80002456:	8756                	mv	a4,s5
    80002458:	bfd9                	j	8000242e <wait+0xa0>
    if(!havekids || p->killed){
    8000245a:	c701                	beqz	a4,80002462 <wait+0xd4>
    8000245c:	03092783          	lw	a5,48(s2)
    80002460:	c785                	beqz	a5,80002488 <wait+0xfa>
      release(&p->lock);
    80002462:	854a                	mv	a0,s2
    80002464:	fffff097          	auipc	ra,0xfffff
    80002468:	826080e7          	jalr	-2010(ra) # 80000c8a <release>
      return -1;
    8000246c:	59fd                	li	s3,-1
}
    8000246e:	854e                	mv	a0,s3
    80002470:	60a6                	ld	ra,72(sp)
    80002472:	6406                	ld	s0,64(sp)
    80002474:	74e2                	ld	s1,56(sp)
    80002476:	7942                	ld	s2,48(sp)
    80002478:	79a2                	ld	s3,40(sp)
    8000247a:	7a02                	ld	s4,32(sp)
    8000247c:	6ae2                	ld	s5,24(sp)
    8000247e:	6b42                	ld	s6,16(sp)
    80002480:	6ba2                	ld	s7,8(sp)
    80002482:	6c02                	ld	s8,0(sp)
    80002484:	6161                	addi	sp,sp,80
    80002486:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002488:	85e2                	mv	a1,s8
    8000248a:	854a                	mv	a0,s2
    8000248c:	00000097          	auipc	ra,0x0
    80002490:	e84080e7          	jalr	-380(ra) # 80002310 <sleep>
    havekids = 0;
    80002494:	bf1d                	j	800023ca <wait+0x3c>

0000000080002496 <wakeup>:
{
    80002496:	7139                	addi	sp,sp,-64
    80002498:	fc06                	sd	ra,56(sp)
    8000249a:	f822                	sd	s0,48(sp)
    8000249c:	f426                	sd	s1,40(sp)
    8000249e:	f04a                	sd	s2,32(sp)
    800024a0:	ec4e                	sd	s3,24(sp)
    800024a2:	e852                	sd	s4,16(sp)
    800024a4:	e456                	sd	s5,8(sp)
    800024a6:	0080                	addi	s0,sp,64
    800024a8:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800024aa:	0000f497          	auipc	s1,0xf
    800024ae:	70e48493          	addi	s1,s1,1806 # 80011bb8 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800024b2:	4985                	li	s3,1
      p->state = RUNNABLE;
    800024b4:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800024b6:	00015917          	auipc	s2,0x15
    800024ba:	30290913          	addi	s2,s2,770 # 800177b8 <tickslock>
    800024be:	a821                	j	800024d6 <wakeup+0x40>
      p->state = RUNNABLE;
    800024c0:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800024c4:	8526                	mv	a0,s1
    800024c6:	ffffe097          	auipc	ra,0xffffe
    800024ca:	7c4080e7          	jalr	1988(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800024ce:	17048493          	addi	s1,s1,368
    800024d2:	01248e63          	beq	s1,s2,800024ee <wakeup+0x58>
    acquire(&p->lock);
    800024d6:	8526                	mv	a0,s1
    800024d8:	ffffe097          	auipc	ra,0xffffe
    800024dc:	6fe080e7          	jalr	1790(ra) # 80000bd6 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800024e0:	4c9c                	lw	a5,24(s1)
    800024e2:	ff3791e3          	bne	a5,s3,800024c4 <wakeup+0x2e>
    800024e6:	749c                	ld	a5,40(s1)
    800024e8:	fd479ee3          	bne	a5,s4,800024c4 <wakeup+0x2e>
    800024ec:	bfd1                	j	800024c0 <wakeup+0x2a>
}
    800024ee:	70e2                	ld	ra,56(sp)
    800024f0:	7442                	ld	s0,48(sp)
    800024f2:	74a2                	ld	s1,40(sp)
    800024f4:	7902                	ld	s2,32(sp)
    800024f6:	69e2                	ld	s3,24(sp)
    800024f8:	6a42                	ld	s4,16(sp)
    800024fa:	6aa2                	ld	s5,8(sp)
    800024fc:	6121                	addi	sp,sp,64
    800024fe:	8082                	ret

0000000080002500 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002500:	7179                	addi	sp,sp,-48
    80002502:	f406                	sd	ra,40(sp)
    80002504:	f022                	sd	s0,32(sp)
    80002506:	ec26                	sd	s1,24(sp)
    80002508:	e84a                	sd	s2,16(sp)
    8000250a:	e44e                	sd	s3,8(sp)
    8000250c:	1800                	addi	s0,sp,48
    8000250e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002510:	0000f497          	auipc	s1,0xf
    80002514:	6a848493          	addi	s1,s1,1704 # 80011bb8 <proc>
    80002518:	00015997          	auipc	s3,0x15
    8000251c:	2a098993          	addi	s3,s3,672 # 800177b8 <tickslock>
    acquire(&p->lock);
    80002520:	8526                	mv	a0,s1
    80002522:	ffffe097          	auipc	ra,0xffffe
    80002526:	6b4080e7          	jalr	1716(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    8000252a:	5c9c                	lw	a5,56(s1)
    8000252c:	01278d63          	beq	a5,s2,80002546 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002530:	8526                	mv	a0,s1
    80002532:	ffffe097          	auipc	ra,0xffffe
    80002536:	758080e7          	jalr	1880(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000253a:	17048493          	addi	s1,s1,368
    8000253e:	ff3491e3          	bne	s1,s3,80002520 <kill+0x20>
  }
  return -1;
    80002542:	557d                	li	a0,-1
    80002544:	a829                	j	8000255e <kill+0x5e>
      p->killed = 1;
    80002546:	4785                	li	a5,1
    80002548:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    8000254a:	4c98                	lw	a4,24(s1)
    8000254c:	4785                	li	a5,1
    8000254e:	00f70f63          	beq	a4,a5,8000256c <kill+0x6c>
      release(&p->lock);
    80002552:	8526                	mv	a0,s1
    80002554:	ffffe097          	auipc	ra,0xffffe
    80002558:	736080e7          	jalr	1846(ra) # 80000c8a <release>
      return 0;
    8000255c:	4501                	li	a0,0
}
    8000255e:	70a2                	ld	ra,40(sp)
    80002560:	7402                	ld	s0,32(sp)
    80002562:	64e2                	ld	s1,24(sp)
    80002564:	6942                	ld	s2,16(sp)
    80002566:	69a2                	ld	s3,8(sp)
    80002568:	6145                	addi	sp,sp,48
    8000256a:	8082                	ret
        p->state = RUNNABLE;
    8000256c:	4789                	li	a5,2
    8000256e:	cc9c                	sw	a5,24(s1)
    80002570:	b7cd                	j	80002552 <kill+0x52>

0000000080002572 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002572:	7179                	addi	sp,sp,-48
    80002574:	f406                	sd	ra,40(sp)
    80002576:	f022                	sd	s0,32(sp)
    80002578:	ec26                	sd	s1,24(sp)
    8000257a:	e84a                	sd	s2,16(sp)
    8000257c:	e44e                	sd	s3,8(sp)
    8000257e:	e052                	sd	s4,0(sp)
    80002580:	1800                	addi	s0,sp,48
    80002582:	84aa                	mv	s1,a0
    80002584:	892e                	mv	s2,a1
    80002586:	89b2                	mv	s3,a2
    80002588:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000258a:	fffff097          	auipc	ra,0xfffff
    8000258e:	61c080e7          	jalr	1564(ra) # 80001ba6 <myproc>
  if(user_dst){
    80002592:	c08d                	beqz	s1,800025b4 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002594:	86d2                	mv	a3,s4
    80002596:	864e                	mv	a2,s3
    80002598:	85ca                	mv	a1,s2
    8000259a:	6928                	ld	a0,80(a0)
    8000259c:	fffff097          	auipc	ra,0xfffff
    800025a0:	08a080e7          	jalr	138(ra) # 80001626 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800025a4:	70a2                	ld	ra,40(sp)
    800025a6:	7402                	ld	s0,32(sp)
    800025a8:	64e2                	ld	s1,24(sp)
    800025aa:	6942                	ld	s2,16(sp)
    800025ac:	69a2                	ld	s3,8(sp)
    800025ae:	6a02                	ld	s4,0(sp)
    800025b0:	6145                	addi	sp,sp,48
    800025b2:	8082                	ret
    memmove((char *)dst, src, len);
    800025b4:	000a061b          	sext.w	a2,s4
    800025b8:	85ce                	mv	a1,s3
    800025ba:	854a                	mv	a0,s2
    800025bc:	ffffe097          	auipc	ra,0xffffe
    800025c0:	776080e7          	jalr	1910(ra) # 80000d32 <memmove>
    return 0;
    800025c4:	8526                	mv	a0,s1
    800025c6:	bff9                	j	800025a4 <either_copyout+0x32>

00000000800025c8 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800025c8:	7179                	addi	sp,sp,-48
    800025ca:	f406                	sd	ra,40(sp)
    800025cc:	f022                	sd	s0,32(sp)
    800025ce:	ec26                	sd	s1,24(sp)
    800025d0:	e84a                	sd	s2,16(sp)
    800025d2:	e44e                	sd	s3,8(sp)
    800025d4:	e052                	sd	s4,0(sp)
    800025d6:	1800                	addi	s0,sp,48
    800025d8:	892a                	mv	s2,a0
    800025da:	84ae                	mv	s1,a1
    800025dc:	89b2                	mv	s3,a2
    800025de:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025e0:	fffff097          	auipc	ra,0xfffff
    800025e4:	5c6080e7          	jalr	1478(ra) # 80001ba6 <myproc>
  if(user_src){
    800025e8:	c08d                	beqz	s1,8000260a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025ea:	86d2                	mv	a3,s4
    800025ec:	864e                	mv	a2,s3
    800025ee:	85ca                	mv	a1,s2
    800025f0:	6928                	ld	a0,80(a0)
    800025f2:	fffff097          	auipc	ra,0xfffff
    800025f6:	0c0080e7          	jalr	192(ra) # 800016b2 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025fa:	70a2                	ld	ra,40(sp)
    800025fc:	7402                	ld	s0,32(sp)
    800025fe:	64e2                	ld	s1,24(sp)
    80002600:	6942                	ld	s2,16(sp)
    80002602:	69a2                	ld	s3,8(sp)
    80002604:	6a02                	ld	s4,0(sp)
    80002606:	6145                	addi	sp,sp,48
    80002608:	8082                	ret
    memmove(dst, (char*)src, len);
    8000260a:	000a061b          	sext.w	a2,s4
    8000260e:	85ce                	mv	a1,s3
    80002610:	854a                	mv	a0,s2
    80002612:	ffffe097          	auipc	ra,0xffffe
    80002616:	720080e7          	jalr	1824(ra) # 80000d32 <memmove>
    return 0;
    8000261a:	8526                	mv	a0,s1
    8000261c:	bff9                	j	800025fa <either_copyin+0x32>

000000008000261e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000261e:	715d                	addi	sp,sp,-80
    80002620:	e486                	sd	ra,72(sp)
    80002622:	e0a2                	sd	s0,64(sp)
    80002624:	fc26                	sd	s1,56(sp)
    80002626:	f84a                	sd	s2,48(sp)
    80002628:	f44e                	sd	s3,40(sp)
    8000262a:	f052                	sd	s4,32(sp)
    8000262c:	ec56                	sd	s5,24(sp)
    8000262e:	e85a                	sd	s6,16(sp)
    80002630:	e45e                	sd	s7,8(sp)
    80002632:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002634:	00006517          	auipc	a0,0x6
    80002638:	b9450513          	addi	a0,a0,-1132 # 800081c8 <digits+0x188>
    8000263c:	ffffe097          	auipc	ra,0xffffe
    80002640:	f3e080e7          	jalr	-194(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002644:	0000f497          	auipc	s1,0xf
    80002648:	6d448493          	addi	s1,s1,1748 # 80011d18 <proc+0x160>
    8000264c:	00015917          	auipc	s2,0x15
    80002650:	2cc90913          	addi	s2,s2,716 # 80017918 <bcache+0x148>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002654:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002656:	00006997          	auipc	s3,0x6
    8000265a:	c1a98993          	addi	s3,s3,-998 # 80008270 <digits+0x230>
    printf("%d %s %s", p->pid, state, p->name);
    8000265e:	00006a97          	auipc	s5,0x6
    80002662:	c1aa8a93          	addi	s5,s5,-998 # 80008278 <digits+0x238>
    printf("\n");
    80002666:	00006a17          	auipc	s4,0x6
    8000266a:	b62a0a13          	addi	s4,s4,-1182 # 800081c8 <digits+0x188>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000266e:	00006b97          	auipc	s7,0x6
    80002672:	c52b8b93          	addi	s7,s7,-942 # 800082c0 <states.1740>
    80002676:	a00d                	j	80002698 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002678:	ed86a583          	lw	a1,-296(a3)
    8000267c:	8556                	mv	a0,s5
    8000267e:	ffffe097          	auipc	ra,0xffffe
    80002682:	efc080e7          	jalr	-260(ra) # 8000057a <printf>
    printf("\n");
    80002686:	8552                	mv	a0,s4
    80002688:	ffffe097          	auipc	ra,0xffffe
    8000268c:	ef2080e7          	jalr	-270(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002690:	17048493          	addi	s1,s1,368
    80002694:	03248163          	beq	s1,s2,800026b6 <procdump+0x98>
    if(p->state == UNUSED)
    80002698:	86a6                	mv	a3,s1
    8000269a:	eb84a783          	lw	a5,-328(s1)
    8000269e:	dbed                	beqz	a5,80002690 <procdump+0x72>
      state = "???";
    800026a0:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026a2:	fcfb6be3          	bltu	s6,a5,80002678 <procdump+0x5a>
    800026a6:	1782                	slli	a5,a5,0x20
    800026a8:	9381                	srli	a5,a5,0x20
    800026aa:	078e                	slli	a5,a5,0x3
    800026ac:	97de                	add	a5,a5,s7
    800026ae:	6390                	ld	a2,0(a5)
    800026b0:	f661                	bnez	a2,80002678 <procdump+0x5a>
      state = "???";
    800026b2:	864e                	mv	a2,s3
    800026b4:	b7d1                	j	80002678 <procdump+0x5a>
  }
}
    800026b6:	60a6                	ld	ra,72(sp)
    800026b8:	6406                	ld	s0,64(sp)
    800026ba:	74e2                	ld	s1,56(sp)
    800026bc:	7942                	ld	s2,48(sp)
    800026be:	79a2                	ld	s3,40(sp)
    800026c0:	7a02                	ld	s4,32(sp)
    800026c2:	6ae2                	ld	s5,24(sp)
    800026c4:	6b42                	ld	s6,16(sp)
    800026c6:	6ba2                	ld	s7,8(sp)
    800026c8:	6161                	addi	sp,sp,80
    800026ca:	8082                	ret

00000000800026cc <vma_alloc>:

struct vma vma_list[NVMA];

struct vma* vma_alloc(){
    800026cc:	7179                	addi	sp,sp,-48
    800026ce:	f406                	sd	ra,40(sp)
    800026d0:	f022                	sd	s0,32(sp)
    800026d2:	ec26                	sd	s1,24(sp)
    800026d4:	e84a                	sd	s2,16(sp)
    800026d6:	e44e                	sd	s3,8(sp)
    800026d8:	1800                	addi	s0,sp,48
  for(int i = 0; i < NVMA; i++){
    800026da:	0000f497          	auipc	s1,0xf
    800026de:	01648493          	addi	s1,s1,22 # 800116f0 <vma_list+0x38>
    800026e2:	4901                	li	s2,0
    800026e4:	49c1                	li	s3,16
    acquire(&vma_list[i].lock);
    800026e6:	8526                	mv	a0,s1
    800026e8:	ffffe097          	auipc	ra,0xffffe
    800026ec:	4ee080e7          	jalr	1262(ra) # 80000bd6 <acquire>
    if(vma_list[i].length == 0){
    800026f0:	fd84b783          	ld	a5,-40(s1)
    800026f4:	c39d                	beqz	a5,8000271a <vma_alloc+0x4e>
      return &vma_list[i];
    }else{
      release(&vma_list[i].lock);
    800026f6:	8526                	mv	a0,s1
    800026f8:	ffffe097          	auipc	ra,0xffffe
    800026fc:	592080e7          	jalr	1426(ra) # 80000c8a <release>
  for(int i = 0; i < NVMA; i++){
    80002700:	2905                	addiw	s2,s2,1
    80002702:	05048493          	addi	s1,s1,80
    80002706:	ff3910e3          	bne	s2,s3,800026e6 <vma_alloc+0x1a>
    }
  }
  panic("no enough vma");
    8000270a:	00006517          	auipc	a0,0x6
    8000270e:	b7e50513          	addi	a0,a0,-1154 # 80008288 <digits+0x248>
    80002712:	ffffe097          	auipc	ra,0xffffe
    80002716:	e1e080e7          	jalr	-482(ra) # 80000530 <panic>
      return &vma_list[i];
    8000271a:	00291513          	slli	a0,s2,0x2
    8000271e:	954a                	add	a0,a0,s2
    80002720:	0512                	slli	a0,a0,0x4
    80002722:	0000f797          	auipc	a5,0xf
    80002726:	f9678793          	addi	a5,a5,-106 # 800116b8 <vma_list>
    8000272a:	953e                	add	a0,a0,a5
}
    8000272c:	70a2                	ld	ra,40(sp)
    8000272e:	7402                	ld	s0,32(sp)
    80002730:	64e2                	ld	s1,24(sp)
    80002732:	6942                	ld	s2,16(sp)
    80002734:	69a2                	ld	s3,8(sp)
    80002736:	6145                	addi	sp,sp,48
    80002738:	8082                	ret

000000008000273a <fork>:
{
    8000273a:	7139                	addi	sp,sp,-64
    8000273c:	fc06                	sd	ra,56(sp)
    8000273e:	f822                	sd	s0,48(sp)
    80002740:	f426                	sd	s1,40(sp)
    80002742:	f04a                	sd	s2,32(sp)
    80002744:	ec4e                	sd	s3,24(sp)
    80002746:	e852                	sd	s4,16(sp)
    80002748:	e456                	sd	s5,8(sp)
    8000274a:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    8000274c:	fffff097          	auipc	ra,0xfffff
    80002750:	45a080e7          	jalr	1114(ra) # 80001ba6 <myproc>
    80002754:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002756:	fffff097          	auipc	ra,0xfffff
    8000275a:	65a080e7          	jalr	1626(ra) # 80001db0 <allocproc>
    8000275e:	14050e63          	beqz	a0,800028ba <fork+0x180>
    80002762:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002764:	04893603          	ld	a2,72(s2)
    80002768:	692c                	ld	a1,80(a0)
    8000276a:	05093503          	ld	a0,80(s2)
    8000276e:	fffff097          	auipc	ra,0xfffff
    80002772:	db4080e7          	jalr	-588(ra) # 80001522 <uvmcopy>
    80002776:	04054863          	bltz	a0,800027c6 <fork+0x8c>
  np->sz = p->sz;
    8000277a:	04893783          	ld	a5,72(s2)
    8000277e:	04f9b423          	sd	a5,72(s3)
  np->parent = p;
    80002782:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80002786:	05893683          	ld	a3,88(s2)
    8000278a:	87b6                	mv	a5,a3
    8000278c:	0589b703          	ld	a4,88(s3)
    80002790:	12068693          	addi	a3,a3,288
    80002794:	0007b803          	ld	a6,0(a5)
    80002798:	6788                	ld	a0,8(a5)
    8000279a:	6b8c                	ld	a1,16(a5)
    8000279c:	6f90                	ld	a2,24(a5)
    8000279e:	01073023          	sd	a6,0(a4)
    800027a2:	e708                	sd	a0,8(a4)
    800027a4:	eb0c                	sd	a1,16(a4)
    800027a6:	ef10                	sd	a2,24(a4)
    800027a8:	02078793          	addi	a5,a5,32
    800027ac:	02070713          	addi	a4,a4,32
    800027b0:	fed792e3          	bne	a5,a3,80002794 <fork+0x5a>
  np->trapframe->a0 = 0;
    800027b4:	0589b783          	ld	a5,88(s3)
    800027b8:	0607b823          	sd	zero,112(a5)
    800027bc:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    800027c0:	15000a13          	li	s4,336
    800027c4:	a03d                	j	800027f2 <fork+0xb8>
    freeproc(np);
    800027c6:	854e                	mv	a0,s3
    800027c8:	fffff097          	auipc	ra,0xfffff
    800027cc:	590080e7          	jalr	1424(ra) # 80001d58 <freeproc>
    release(&np->lock);
    800027d0:	854e                	mv	a0,s3
    800027d2:	ffffe097          	auipc	ra,0xffffe
    800027d6:	4b8080e7          	jalr	1208(ra) # 80000c8a <release>
    return -1;
    800027da:	5afd                	li	s5,-1
    800027dc:	a0e9                	j	800028a6 <fork+0x16c>
      np->ofile[i] = filedup(p->ofile[i]);
    800027de:	00002097          	auipc	ra,0x2
    800027e2:	fd8080e7          	jalr	-40(ra) # 800047b6 <filedup>
    800027e6:	009987b3          	add	a5,s3,s1
    800027ea:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800027ec:	04a1                	addi	s1,s1,8
    800027ee:	01448763          	beq	s1,s4,800027fc <fork+0xc2>
    if(p->ofile[i])
    800027f2:	009907b3          	add	a5,s2,s1
    800027f6:	6388                	ld	a0,0(a5)
    800027f8:	f17d                	bnez	a0,800027de <fork+0xa4>
    800027fa:	bfcd                	j	800027ec <fork+0xb2>
  np->cwd = idup(p->cwd);
    800027fc:	15093503          	ld	a0,336(s2)
    80002800:	00001097          	auipc	ra,0x1
    80002804:	124080e7          	jalr	292(ra) # 80003924 <idup>
    80002808:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000280c:	4641                	li	a2,16
    8000280e:	16090593          	addi	a1,s2,352
    80002812:	16098513          	addi	a0,s3,352
    80002816:	ffffe097          	auipc	ra,0xffffe
    8000281a:	612080e7          	jalr	1554(ra) # 80000e28 <safestrcpy>
  pid = np->pid;
    8000281e:	0389aa83          	lw	s5,56(s3)
  np->state = RUNNABLE;
    80002822:	4789                	li	a5,2
    80002824:	00f9ac23          	sw	a5,24(s3)
  np->vma = 0;
    80002828:	1409bc23          	sd	zero,344(s3)
  struct vma *pv = p->vma;
    8000282c:	15893903          	ld	s2,344(s2)
  while(pv){
    80002830:	06090663          	beqz	s2,8000289c <fork+0x162>
  struct vma *pre = 0;
    80002834:	4481                	li	s1,0
    80002836:	a829                	j	80002850 <fork+0x116>
      np->vma = vma;
    80002838:	1499bc23          	sd	s1,344(s3)
    release(&vma->lock);
    8000283c:	03848513          	addi	a0,s1,56
    80002840:	ffffe097          	auipc	ra,0xffffe
    80002844:	44a080e7          	jalr	1098(ra) # 80000c8a <release>
    pv = pv->next;
    80002848:	03093903          	ld	s2,48(s2)
  while(pv){
    8000284c:	04090863          	beqz	s2,8000289c <fork+0x162>
    struct vma *vma = vma_alloc();
    80002850:	8a26                	mv	s4,s1
    80002852:	00000097          	auipc	ra,0x0
    80002856:	e7a080e7          	jalr	-390(ra) # 800026cc <vma_alloc>
    8000285a:	84aa                	mv	s1,a0
    vma->start = pv->start;
    8000285c:	00093783          	ld	a5,0(s2)
    80002860:	e11c                	sd	a5,0(a0)
    vma->end = pv->end;
    80002862:	00893783          	ld	a5,8(s2)
    80002866:	e51c                	sd	a5,8(a0)
    vma->off = pv->off;
    80002868:	01893783          	ld	a5,24(s2)
    8000286c:	ed1c                	sd	a5,24(a0)
    vma->length = pv->length;
    8000286e:	01093783          	ld	a5,16(s2)
    80002872:	e91c                	sd	a5,16(a0)
    vma->permission = pv->permission;
    80002874:	02092783          	lw	a5,32(s2)
    80002878:	d11c                	sw	a5,32(a0)
    vma->flags = pv->flags;
    8000287a:	02492783          	lw	a5,36(s2)
    8000287e:	d15c                	sw	a5,36(a0)
    vma->file = pv->file;
    80002880:	02893503          	ld	a0,40(s2)
    80002884:	f488                	sd	a0,40(s1)
    filedup(vma->file);
    80002886:	00002097          	auipc	ra,0x2
    8000288a:	f30080e7          	jalr	-208(ra) # 800047b6 <filedup>
    vma->next = 0;
    8000288e:	0204b823          	sd	zero,48(s1)
    if(pre == 0){
    80002892:	fa0a03e3          	beqz	s4,80002838 <fork+0xfe>
      pre->next = vma;
    80002896:	029a3823          	sd	s1,48(s4)
    8000289a:	b74d                	j	8000283c <fork+0x102>
  release(&np->lock);
    8000289c:	854e                	mv	a0,s3
    8000289e:	ffffe097          	auipc	ra,0xffffe
    800028a2:	3ec080e7          	jalr	1004(ra) # 80000c8a <release>
}
    800028a6:	8556                	mv	a0,s5
    800028a8:	70e2                	ld	ra,56(sp)
    800028aa:	7442                	ld	s0,48(sp)
    800028ac:	74a2                	ld	s1,40(sp)
    800028ae:	7902                	ld	s2,32(sp)
    800028b0:	69e2                	ld	s3,24(sp)
    800028b2:	6a42                	ld	s4,16(sp)
    800028b4:	6aa2                	ld	s5,8(sp)
    800028b6:	6121                	addi	sp,sp,64
    800028b8:	8082                	ret
    return -1;
    800028ba:	5afd                	li	s5,-1
    800028bc:	b7ed                	j	800028a6 <fork+0x16c>

00000000800028be <swtch>:
    800028be:	00153023          	sd	ra,0(a0)
    800028c2:	00253423          	sd	sp,8(a0)
    800028c6:	e900                	sd	s0,16(a0)
    800028c8:	ed04                	sd	s1,24(a0)
    800028ca:	03253023          	sd	s2,32(a0)
    800028ce:	03353423          	sd	s3,40(a0)
    800028d2:	03453823          	sd	s4,48(a0)
    800028d6:	03553c23          	sd	s5,56(a0)
    800028da:	05653023          	sd	s6,64(a0)
    800028de:	05753423          	sd	s7,72(a0)
    800028e2:	05853823          	sd	s8,80(a0)
    800028e6:	05953c23          	sd	s9,88(a0)
    800028ea:	07a53023          	sd	s10,96(a0)
    800028ee:	07b53423          	sd	s11,104(a0)
    800028f2:	0005b083          	ld	ra,0(a1)
    800028f6:	0085b103          	ld	sp,8(a1)
    800028fa:	6980                	ld	s0,16(a1)
    800028fc:	6d84                	ld	s1,24(a1)
    800028fe:	0205b903          	ld	s2,32(a1)
    80002902:	0285b983          	ld	s3,40(a1)
    80002906:	0305ba03          	ld	s4,48(a1)
    8000290a:	0385ba83          	ld	s5,56(a1)
    8000290e:	0405bb03          	ld	s6,64(a1)
    80002912:	0485bb83          	ld	s7,72(a1)
    80002916:	0505bc03          	ld	s8,80(a1)
    8000291a:	0585bc83          	ld	s9,88(a1)
    8000291e:	0605bd03          	ld	s10,96(a1)
    80002922:	0685bd83          	ld	s11,104(a1)
    80002926:	8082                	ret

0000000080002928 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002928:	1141                	addi	sp,sp,-16
    8000292a:	e406                	sd	ra,8(sp)
    8000292c:	e022                	sd	s0,0(sp)
    8000292e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002930:	00006597          	auipc	a1,0x6
    80002934:	9b858593          	addi	a1,a1,-1608 # 800082e8 <states.1740+0x28>
    80002938:	00015517          	auipc	a0,0x15
    8000293c:	e8050513          	addi	a0,a0,-384 # 800177b8 <tickslock>
    80002940:	ffffe097          	auipc	ra,0xffffe
    80002944:	206080e7          	jalr	518(ra) # 80000b46 <initlock>
}
    80002948:	60a2                	ld	ra,8(sp)
    8000294a:	6402                	ld	s0,0(sp)
    8000294c:	0141                	addi	sp,sp,16
    8000294e:	8082                	ret

0000000080002950 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002950:	1141                	addi	sp,sp,-16
    80002952:	e422                	sd	s0,8(sp)
    80002954:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002956:	00003797          	auipc	a5,0x3
    8000295a:	7ea78793          	addi	a5,a5,2026 # 80006140 <kernelvec>
    8000295e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002962:	6422                	ld	s0,8(sp)
    80002964:	0141                	addi	sp,sp,16
    80002966:	8082                	ret

0000000080002968 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002968:	1141                	addi	sp,sp,-16
    8000296a:	e406                	sd	ra,8(sp)
    8000296c:	e022                	sd	s0,0(sp)
    8000296e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002970:	fffff097          	auipc	ra,0xfffff
    80002974:	236080e7          	jalr	566(ra) # 80001ba6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002978:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000297c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000297e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002982:	00004617          	auipc	a2,0x4
    80002986:	67e60613          	addi	a2,a2,1662 # 80007000 <_trampoline>
    8000298a:	00004697          	auipc	a3,0x4
    8000298e:	67668693          	addi	a3,a3,1654 # 80007000 <_trampoline>
    80002992:	8e91                	sub	a3,a3,a2
    80002994:	040007b7          	lui	a5,0x4000
    80002998:	17fd                	addi	a5,a5,-1
    8000299a:	07b2                	slli	a5,a5,0xc
    8000299c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000299e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029a2:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029a4:	180026f3          	csrr	a3,satp
    800029a8:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029aa:	6d38                	ld	a4,88(a0)
    800029ac:	6134                	ld	a3,64(a0)
    800029ae:	6585                	lui	a1,0x1
    800029b0:	96ae                	add	a3,a3,a1
    800029b2:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029b4:	6d38                	ld	a4,88(a0)
    800029b6:	00000697          	auipc	a3,0x0
    800029ba:	13868693          	addi	a3,a3,312 # 80002aee <usertrap>
    800029be:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029c0:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029c2:	8692                	mv	a3,tp
    800029c4:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c6:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029ca:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029ce:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029d2:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029d6:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029d8:	6f18                	ld	a4,24(a4)
    800029da:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029de:	692c                	ld	a1,80(a0)
    800029e0:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800029e2:	00004717          	auipc	a4,0x4
    800029e6:	6ae70713          	addi	a4,a4,1710 # 80007090 <userret>
    800029ea:	8f11                	sub	a4,a4,a2
    800029ec:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800029ee:	577d                	li	a4,-1
    800029f0:	177e                	slli	a4,a4,0x3f
    800029f2:	8dd9                	or	a1,a1,a4
    800029f4:	02000537          	lui	a0,0x2000
    800029f8:	157d                	addi	a0,a0,-1
    800029fa:	0536                	slli	a0,a0,0xd
    800029fc:	9782                	jalr	a5
}
    800029fe:	60a2                	ld	ra,8(sp)
    80002a00:	6402                	ld	s0,0(sp)
    80002a02:	0141                	addi	sp,sp,16
    80002a04:	8082                	ret

0000000080002a06 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a06:	1101                	addi	sp,sp,-32
    80002a08:	ec06                	sd	ra,24(sp)
    80002a0a:	e822                	sd	s0,16(sp)
    80002a0c:	e426                	sd	s1,8(sp)
    80002a0e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a10:	00015497          	auipc	s1,0x15
    80002a14:	da848493          	addi	s1,s1,-600 # 800177b8 <tickslock>
    80002a18:	8526                	mv	a0,s1
    80002a1a:	ffffe097          	auipc	ra,0xffffe
    80002a1e:	1bc080e7          	jalr	444(ra) # 80000bd6 <acquire>
  ticks++;
    80002a22:	00006517          	auipc	a0,0x6
    80002a26:	60e50513          	addi	a0,a0,1550 # 80009030 <ticks>
    80002a2a:	411c                	lw	a5,0(a0)
    80002a2c:	2785                	addiw	a5,a5,1
    80002a2e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a30:	00000097          	auipc	ra,0x0
    80002a34:	a66080e7          	jalr	-1434(ra) # 80002496 <wakeup>
  release(&tickslock);
    80002a38:	8526                	mv	a0,s1
    80002a3a:	ffffe097          	auipc	ra,0xffffe
    80002a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80002a42:	60e2                	ld	ra,24(sp)
    80002a44:	6442                	ld	s0,16(sp)
    80002a46:	64a2                	ld	s1,8(sp)
    80002a48:	6105                	addi	sp,sp,32
    80002a4a:	8082                	ret

0000000080002a4c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a4c:	1101                	addi	sp,sp,-32
    80002a4e:	ec06                	sd	ra,24(sp)
    80002a50:	e822                	sd	s0,16(sp)
    80002a52:	e426                	sd	s1,8(sp)
    80002a54:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a56:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a5a:	00074d63          	bltz	a4,80002a74 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a5e:	57fd                	li	a5,-1
    80002a60:	17fe                	slli	a5,a5,0x3f
    80002a62:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a64:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a66:	06f70363          	beq	a4,a5,80002acc <devintr+0x80>
  }
}
    80002a6a:	60e2                	ld	ra,24(sp)
    80002a6c:	6442                	ld	s0,16(sp)
    80002a6e:	64a2                	ld	s1,8(sp)
    80002a70:	6105                	addi	sp,sp,32
    80002a72:	8082                	ret
     (scause & 0xff) == 9){
    80002a74:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a78:	46a5                	li	a3,9
    80002a7a:	fed792e3          	bne	a5,a3,80002a5e <devintr+0x12>
    int irq = plic_claim();
    80002a7e:	00003097          	auipc	ra,0x3
    80002a82:	7ca080e7          	jalr	1994(ra) # 80006248 <plic_claim>
    80002a86:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a88:	47a9                	li	a5,10
    80002a8a:	02f50763          	beq	a0,a5,80002ab8 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a8e:	4785                	li	a5,1
    80002a90:	02f50963          	beq	a0,a5,80002ac2 <devintr+0x76>
    return 1;
    80002a94:	4505                	li	a0,1
    } else if(irq){
    80002a96:	d8f1                	beqz	s1,80002a6a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a98:	85a6                	mv	a1,s1
    80002a9a:	00006517          	auipc	a0,0x6
    80002a9e:	85650513          	addi	a0,a0,-1962 # 800082f0 <states.1740+0x30>
    80002aa2:	ffffe097          	auipc	ra,0xffffe
    80002aa6:	ad8080e7          	jalr	-1320(ra) # 8000057a <printf>
      plic_complete(irq);
    80002aaa:	8526                	mv	a0,s1
    80002aac:	00003097          	auipc	ra,0x3
    80002ab0:	7c0080e7          	jalr	1984(ra) # 8000626c <plic_complete>
    return 1;
    80002ab4:	4505                	li	a0,1
    80002ab6:	bf55                	j	80002a6a <devintr+0x1e>
      uartintr();
    80002ab8:	ffffe097          	auipc	ra,0xffffe
    80002abc:	ee2080e7          	jalr	-286(ra) # 8000099a <uartintr>
    80002ac0:	b7ed                	j	80002aaa <devintr+0x5e>
      virtio_disk_intr();
    80002ac2:	00004097          	auipc	ra,0x4
    80002ac6:	c8a080e7          	jalr	-886(ra) # 8000674c <virtio_disk_intr>
    80002aca:	b7c5                	j	80002aaa <devintr+0x5e>
    if(cpuid() == 0){
    80002acc:	fffff097          	auipc	ra,0xfffff
    80002ad0:	0ae080e7          	jalr	174(ra) # 80001b7a <cpuid>
    80002ad4:	c901                	beqz	a0,80002ae4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ad6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ada:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002adc:	14479073          	csrw	sip,a5
    return 2;
    80002ae0:	4509                	li	a0,2
    80002ae2:	b761                	j	80002a6a <devintr+0x1e>
      clockintr();
    80002ae4:	00000097          	auipc	ra,0x0
    80002ae8:	f22080e7          	jalr	-222(ra) # 80002a06 <clockintr>
    80002aec:	b7ed                	j	80002ad6 <devintr+0x8a>

0000000080002aee <usertrap>:
{
    80002aee:	1101                	addi	sp,sp,-32
    80002af0:	ec06                	sd	ra,24(sp)
    80002af2:	e822                	sd	s0,16(sp)
    80002af4:	e426                	sd	s1,8(sp)
    80002af6:	e04a                	sd	s2,0(sp)
    80002af8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002afa:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002afe:	1007f793          	andi	a5,a5,256
    80002b02:	e3c9                	bnez	a5,80002b84 <usertrap+0x96>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b04:	00003797          	auipc	a5,0x3
    80002b08:	63c78793          	addi	a5,a5,1596 # 80006140 <kernelvec>
    80002b0c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b10:	fffff097          	auipc	ra,0xfffff
    80002b14:	096080e7          	jalr	150(ra) # 80001ba6 <myproc>
    80002b18:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b1a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b1c:	14102773          	csrr	a4,sepc
    80002b20:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b22:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b26:	47a1                	li	a5,8
    80002b28:	06f70663          	beq	a4,a5,80002b94 <usertrap+0xa6>
    80002b2c:	14202773          	csrr	a4,scause
  } else if(r_scause() == 15 || r_scause() == 13){
    80002b30:	47bd                	li	a5,15
    80002b32:	00f70763          	beq	a4,a5,80002b40 <usertrap+0x52>
    80002b36:	14202773          	csrr	a4,scause
    80002b3a:	47b5                	li	a5,13
    80002b3c:	08f71e63          	bne	a4,a5,80002bd8 <usertrap+0xea>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b40:	14302573          	csrr	a0,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b44:	142025f3          	csrr	a1,scause
    if(mmap_handler(r_stval(), r_scause()) != 0){
    80002b48:	2581                	sext.w	a1,a1
    80002b4a:	fffff097          	auipc	ra,0xfffff
    80002b4e:	ca8080e7          	jalr	-856(ra) # 800017f2 <mmap_handler>
    80002b52:	c12d                	beqz	a0,80002bb4 <usertrap+0xc6>
      printf("page fault\n");
    80002b54:	00005517          	auipc	a0,0x5
    80002b58:	7dc50513          	addi	a0,a0,2012 # 80008330 <states.1740+0x70>
    80002b5c:	ffffe097          	auipc	ra,0xffffe
    80002b60:	a1e080e7          	jalr	-1506(ra) # 8000057a <printf>
      p->killed = 1;
    80002b64:	4785                	li	a5,1
    80002b66:	d89c                	sw	a5,48(s1)
{
    80002b68:	4901                	li	s2,0
    exit(-1);
    80002b6a:	557d                	li	a0,-1
    80002b6c:	fffff097          	auipc	ra,0xfffff
    80002b70:	5fa080e7          	jalr	1530(ra) # 80002166 <exit>
  if(which_dev == 2)
    80002b74:	4789                	li	a5,2
    80002b76:	04f91163          	bne	s2,a5,80002bb8 <usertrap+0xca>
    yield();
    80002b7a:	fffff097          	auipc	ra,0xfffff
    80002b7e:	75a080e7          	jalr	1882(ra) # 800022d4 <yield>
    80002b82:	a81d                	j	80002bb8 <usertrap+0xca>
    panic("usertrap: not from user mode");
    80002b84:	00005517          	auipc	a0,0x5
    80002b88:	78c50513          	addi	a0,a0,1932 # 80008310 <states.1740+0x50>
    80002b8c:	ffffe097          	auipc	ra,0xffffe
    80002b90:	9a4080e7          	jalr	-1628(ra) # 80000530 <panic>
    if(p->killed)
    80002b94:	591c                	lw	a5,48(a0)
    80002b96:	eb9d                	bnez	a5,80002bcc <usertrap+0xde>
    p->trapframe->epc += 4;
    80002b98:	6cb8                	ld	a4,88(s1)
    80002b9a:	6f1c                	ld	a5,24(a4)
    80002b9c:	0791                	addi	a5,a5,4
    80002b9e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ba0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ba4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ba8:	10079073          	csrw	sstatus,a5
    syscall();
    80002bac:	00000097          	auipc	ra,0x0
    80002bb0:	2b8080e7          	jalr	696(ra) # 80002e64 <syscall>
  if(p->killed)
    80002bb4:	589c                	lw	a5,48(s1)
    80002bb6:	e7a5                	bnez	a5,80002c1e <usertrap+0x130>
  usertrapret();
    80002bb8:	00000097          	auipc	ra,0x0
    80002bbc:	db0080e7          	jalr	-592(ra) # 80002968 <usertrapret>
}
    80002bc0:	60e2                	ld	ra,24(sp)
    80002bc2:	6442                	ld	s0,16(sp)
    80002bc4:	64a2                	ld	s1,8(sp)
    80002bc6:	6902                	ld	s2,0(sp)
    80002bc8:	6105                	addi	sp,sp,32
    80002bca:	8082                	ret
      exit(-1);
    80002bcc:	557d                	li	a0,-1
    80002bce:	fffff097          	auipc	ra,0xfffff
    80002bd2:	598080e7          	jalr	1432(ra) # 80002166 <exit>
    80002bd6:	b7c9                	j	80002b98 <usertrap+0xaa>
  } else if((which_dev = devintr()) != 0){
    80002bd8:	00000097          	auipc	ra,0x0
    80002bdc:	e74080e7          	jalr	-396(ra) # 80002a4c <devintr>
    80002be0:	892a                	mv	s2,a0
    80002be2:	c501                	beqz	a0,80002bea <usertrap+0xfc>
  if(p->killed)
    80002be4:	589c                	lw	a5,48(s1)
    80002be6:	d7d9                	beqz	a5,80002b74 <usertrap+0x86>
    80002be8:	b749                	j	80002b6a <usertrap+0x7c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bea:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bee:	5c90                	lw	a2,56(s1)
    80002bf0:	00005517          	auipc	a0,0x5
    80002bf4:	75050513          	addi	a0,a0,1872 # 80008340 <states.1740+0x80>
    80002bf8:	ffffe097          	auipc	ra,0xffffe
    80002bfc:	982080e7          	jalr	-1662(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c00:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c04:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c08:	00005517          	auipc	a0,0x5
    80002c0c:	76850513          	addi	a0,a0,1896 # 80008370 <states.1740+0xb0>
    80002c10:	ffffe097          	auipc	ra,0xffffe
    80002c14:	96a080e7          	jalr	-1686(ra) # 8000057a <printf>
    p->killed = 1;
    80002c18:	4785                	li	a5,1
    80002c1a:	d89c                	sw	a5,48(s1)
    80002c1c:	b7b1                	j	80002b68 <usertrap+0x7a>
  if(p->killed)
    80002c1e:	4901                	li	s2,0
    80002c20:	b7a9                	j	80002b6a <usertrap+0x7c>

0000000080002c22 <kerneltrap>:
{
    80002c22:	7179                	addi	sp,sp,-48
    80002c24:	f406                	sd	ra,40(sp)
    80002c26:	f022                	sd	s0,32(sp)
    80002c28:	ec26                	sd	s1,24(sp)
    80002c2a:	e84a                	sd	s2,16(sp)
    80002c2c:	e44e                	sd	s3,8(sp)
    80002c2e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c30:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c34:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c38:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c3c:	1004f793          	andi	a5,s1,256
    80002c40:	cb85                	beqz	a5,80002c70 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c42:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c46:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c48:	ef85                	bnez	a5,80002c80 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c4a:	00000097          	auipc	ra,0x0
    80002c4e:	e02080e7          	jalr	-510(ra) # 80002a4c <devintr>
    80002c52:	cd1d                	beqz	a0,80002c90 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c54:	4789                	li	a5,2
    80002c56:	06f50a63          	beq	a0,a5,80002cca <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c5a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c5e:	10049073          	csrw	sstatus,s1
}
    80002c62:	70a2                	ld	ra,40(sp)
    80002c64:	7402                	ld	s0,32(sp)
    80002c66:	64e2                	ld	s1,24(sp)
    80002c68:	6942                	ld	s2,16(sp)
    80002c6a:	69a2                	ld	s3,8(sp)
    80002c6c:	6145                	addi	sp,sp,48
    80002c6e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c70:	00005517          	auipc	a0,0x5
    80002c74:	72050513          	addi	a0,a0,1824 # 80008390 <states.1740+0xd0>
    80002c78:	ffffe097          	auipc	ra,0xffffe
    80002c7c:	8b8080e7          	jalr	-1864(ra) # 80000530 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c80:	00005517          	auipc	a0,0x5
    80002c84:	73850513          	addi	a0,a0,1848 # 800083b8 <states.1740+0xf8>
    80002c88:	ffffe097          	auipc	ra,0xffffe
    80002c8c:	8a8080e7          	jalr	-1880(ra) # 80000530 <panic>
    printf("scause %p\n", scause);
    80002c90:	85ce                	mv	a1,s3
    80002c92:	00005517          	auipc	a0,0x5
    80002c96:	74650513          	addi	a0,a0,1862 # 800083d8 <states.1740+0x118>
    80002c9a:	ffffe097          	auipc	ra,0xffffe
    80002c9e:	8e0080e7          	jalr	-1824(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ca2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ca6:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002caa:	00005517          	auipc	a0,0x5
    80002cae:	73e50513          	addi	a0,a0,1854 # 800083e8 <states.1740+0x128>
    80002cb2:	ffffe097          	auipc	ra,0xffffe
    80002cb6:	8c8080e7          	jalr	-1848(ra) # 8000057a <printf>
    panic("kerneltrap");
    80002cba:	00005517          	auipc	a0,0x5
    80002cbe:	74650513          	addi	a0,a0,1862 # 80008400 <states.1740+0x140>
    80002cc2:	ffffe097          	auipc	ra,0xffffe
    80002cc6:	86e080e7          	jalr	-1938(ra) # 80000530 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cca:	fffff097          	auipc	ra,0xfffff
    80002cce:	edc080e7          	jalr	-292(ra) # 80001ba6 <myproc>
    80002cd2:	d541                	beqz	a0,80002c5a <kerneltrap+0x38>
    80002cd4:	fffff097          	auipc	ra,0xfffff
    80002cd8:	ed2080e7          	jalr	-302(ra) # 80001ba6 <myproc>
    80002cdc:	4d18                	lw	a4,24(a0)
    80002cde:	478d                	li	a5,3
    80002ce0:	f6f71de3          	bne	a4,a5,80002c5a <kerneltrap+0x38>
    yield();
    80002ce4:	fffff097          	auipc	ra,0xfffff
    80002ce8:	5f0080e7          	jalr	1520(ra) # 800022d4 <yield>
    80002cec:	b7bd                	j	80002c5a <kerneltrap+0x38>

0000000080002cee <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cee:	1101                	addi	sp,sp,-32
    80002cf0:	ec06                	sd	ra,24(sp)
    80002cf2:	e822                	sd	s0,16(sp)
    80002cf4:	e426                	sd	s1,8(sp)
    80002cf6:	1000                	addi	s0,sp,32
    80002cf8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002cfa:	fffff097          	auipc	ra,0xfffff
    80002cfe:	eac080e7          	jalr	-340(ra) # 80001ba6 <myproc>
  switch (n) {
    80002d02:	4795                	li	a5,5
    80002d04:	0497e163          	bltu	a5,s1,80002d46 <argraw+0x58>
    80002d08:	048a                	slli	s1,s1,0x2
    80002d0a:	00005717          	auipc	a4,0x5
    80002d0e:	72e70713          	addi	a4,a4,1838 # 80008438 <states.1740+0x178>
    80002d12:	94ba                	add	s1,s1,a4
    80002d14:	409c                	lw	a5,0(s1)
    80002d16:	97ba                	add	a5,a5,a4
    80002d18:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d1a:	6d3c                	ld	a5,88(a0)
    80002d1c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d1e:	60e2                	ld	ra,24(sp)
    80002d20:	6442                	ld	s0,16(sp)
    80002d22:	64a2                	ld	s1,8(sp)
    80002d24:	6105                	addi	sp,sp,32
    80002d26:	8082                	ret
    return p->trapframe->a1;
    80002d28:	6d3c                	ld	a5,88(a0)
    80002d2a:	7fa8                	ld	a0,120(a5)
    80002d2c:	bfcd                	j	80002d1e <argraw+0x30>
    return p->trapframe->a2;
    80002d2e:	6d3c                	ld	a5,88(a0)
    80002d30:	63c8                	ld	a0,128(a5)
    80002d32:	b7f5                	j	80002d1e <argraw+0x30>
    return p->trapframe->a3;
    80002d34:	6d3c                	ld	a5,88(a0)
    80002d36:	67c8                	ld	a0,136(a5)
    80002d38:	b7dd                	j	80002d1e <argraw+0x30>
    return p->trapframe->a4;
    80002d3a:	6d3c                	ld	a5,88(a0)
    80002d3c:	6bc8                	ld	a0,144(a5)
    80002d3e:	b7c5                	j	80002d1e <argraw+0x30>
    return p->trapframe->a5;
    80002d40:	6d3c                	ld	a5,88(a0)
    80002d42:	6fc8                	ld	a0,152(a5)
    80002d44:	bfe9                	j	80002d1e <argraw+0x30>
  panic("argraw");
    80002d46:	00005517          	auipc	a0,0x5
    80002d4a:	6ca50513          	addi	a0,a0,1738 # 80008410 <states.1740+0x150>
    80002d4e:	ffffd097          	auipc	ra,0xffffd
    80002d52:	7e2080e7          	jalr	2018(ra) # 80000530 <panic>

0000000080002d56 <fetchaddr>:
{
    80002d56:	1101                	addi	sp,sp,-32
    80002d58:	ec06                	sd	ra,24(sp)
    80002d5a:	e822                	sd	s0,16(sp)
    80002d5c:	e426                	sd	s1,8(sp)
    80002d5e:	e04a                	sd	s2,0(sp)
    80002d60:	1000                	addi	s0,sp,32
    80002d62:	84aa                	mv	s1,a0
    80002d64:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d66:	fffff097          	auipc	ra,0xfffff
    80002d6a:	e40080e7          	jalr	-448(ra) # 80001ba6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d6e:	653c                	ld	a5,72(a0)
    80002d70:	02f4f863          	bgeu	s1,a5,80002da0 <fetchaddr+0x4a>
    80002d74:	00848713          	addi	a4,s1,8
    80002d78:	02e7e663          	bltu	a5,a4,80002da4 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d7c:	46a1                	li	a3,8
    80002d7e:	8626                	mv	a2,s1
    80002d80:	85ca                	mv	a1,s2
    80002d82:	6928                	ld	a0,80(a0)
    80002d84:	fffff097          	auipc	ra,0xfffff
    80002d88:	92e080e7          	jalr	-1746(ra) # 800016b2 <copyin>
    80002d8c:	00a03533          	snez	a0,a0
    80002d90:	40a00533          	neg	a0,a0
}
    80002d94:	60e2                	ld	ra,24(sp)
    80002d96:	6442                	ld	s0,16(sp)
    80002d98:	64a2                	ld	s1,8(sp)
    80002d9a:	6902                	ld	s2,0(sp)
    80002d9c:	6105                	addi	sp,sp,32
    80002d9e:	8082                	ret
    return -1;
    80002da0:	557d                	li	a0,-1
    80002da2:	bfcd                	j	80002d94 <fetchaddr+0x3e>
    80002da4:	557d                	li	a0,-1
    80002da6:	b7fd                	j	80002d94 <fetchaddr+0x3e>

0000000080002da8 <fetchstr>:
{
    80002da8:	7179                	addi	sp,sp,-48
    80002daa:	f406                	sd	ra,40(sp)
    80002dac:	f022                	sd	s0,32(sp)
    80002dae:	ec26                	sd	s1,24(sp)
    80002db0:	e84a                	sd	s2,16(sp)
    80002db2:	e44e                	sd	s3,8(sp)
    80002db4:	1800                	addi	s0,sp,48
    80002db6:	892a                	mv	s2,a0
    80002db8:	84ae                	mv	s1,a1
    80002dba:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002dbc:	fffff097          	auipc	ra,0xfffff
    80002dc0:	dea080e7          	jalr	-534(ra) # 80001ba6 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002dc4:	86ce                	mv	a3,s3
    80002dc6:	864a                	mv	a2,s2
    80002dc8:	85a6                	mv	a1,s1
    80002dca:	6928                	ld	a0,80(a0)
    80002dcc:	fffff097          	auipc	ra,0xfffff
    80002dd0:	972080e7          	jalr	-1678(ra) # 8000173e <copyinstr>
  if(err < 0)
    80002dd4:	00054763          	bltz	a0,80002de2 <fetchstr+0x3a>
  return strlen(buf);
    80002dd8:	8526                	mv	a0,s1
    80002dda:	ffffe097          	auipc	ra,0xffffe
    80002dde:	080080e7          	jalr	128(ra) # 80000e5a <strlen>
}
    80002de2:	70a2                	ld	ra,40(sp)
    80002de4:	7402                	ld	s0,32(sp)
    80002de6:	64e2                	ld	s1,24(sp)
    80002de8:	6942                	ld	s2,16(sp)
    80002dea:	69a2                	ld	s3,8(sp)
    80002dec:	6145                	addi	sp,sp,48
    80002dee:	8082                	ret

0000000080002df0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002df0:	1101                	addi	sp,sp,-32
    80002df2:	ec06                	sd	ra,24(sp)
    80002df4:	e822                	sd	s0,16(sp)
    80002df6:	e426                	sd	s1,8(sp)
    80002df8:	1000                	addi	s0,sp,32
    80002dfa:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dfc:	00000097          	auipc	ra,0x0
    80002e00:	ef2080e7          	jalr	-270(ra) # 80002cee <argraw>
    80002e04:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e06:	4501                	li	a0,0
    80002e08:	60e2                	ld	ra,24(sp)
    80002e0a:	6442                	ld	s0,16(sp)
    80002e0c:	64a2                	ld	s1,8(sp)
    80002e0e:	6105                	addi	sp,sp,32
    80002e10:	8082                	ret

0000000080002e12 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e12:	1101                	addi	sp,sp,-32
    80002e14:	ec06                	sd	ra,24(sp)
    80002e16:	e822                	sd	s0,16(sp)
    80002e18:	e426                	sd	s1,8(sp)
    80002e1a:	1000                	addi	s0,sp,32
    80002e1c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e1e:	00000097          	auipc	ra,0x0
    80002e22:	ed0080e7          	jalr	-304(ra) # 80002cee <argraw>
    80002e26:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e28:	4501                	li	a0,0
    80002e2a:	60e2                	ld	ra,24(sp)
    80002e2c:	6442                	ld	s0,16(sp)
    80002e2e:	64a2                	ld	s1,8(sp)
    80002e30:	6105                	addi	sp,sp,32
    80002e32:	8082                	ret

0000000080002e34 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e34:	1101                	addi	sp,sp,-32
    80002e36:	ec06                	sd	ra,24(sp)
    80002e38:	e822                	sd	s0,16(sp)
    80002e3a:	e426                	sd	s1,8(sp)
    80002e3c:	e04a                	sd	s2,0(sp)
    80002e3e:	1000                	addi	s0,sp,32
    80002e40:	84ae                	mv	s1,a1
    80002e42:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e44:	00000097          	auipc	ra,0x0
    80002e48:	eaa080e7          	jalr	-342(ra) # 80002cee <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e4c:	864a                	mv	a2,s2
    80002e4e:	85a6                	mv	a1,s1
    80002e50:	00000097          	auipc	ra,0x0
    80002e54:	f58080e7          	jalr	-168(ra) # 80002da8 <fetchstr>
}
    80002e58:	60e2                	ld	ra,24(sp)
    80002e5a:	6442                	ld	s0,16(sp)
    80002e5c:	64a2                	ld	s1,8(sp)
    80002e5e:	6902                	ld	s2,0(sp)
    80002e60:	6105                	addi	sp,sp,32
    80002e62:	8082                	ret

0000000080002e64 <syscall>:
[SYS_munmap]  sys_munmap,
};

void
syscall(void)
{
    80002e64:	1101                	addi	sp,sp,-32
    80002e66:	ec06                	sd	ra,24(sp)
    80002e68:	e822                	sd	s0,16(sp)
    80002e6a:	e426                	sd	s1,8(sp)
    80002e6c:	e04a                	sd	s2,0(sp)
    80002e6e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e70:	fffff097          	auipc	ra,0xfffff
    80002e74:	d36080e7          	jalr	-714(ra) # 80001ba6 <myproc>
    80002e78:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e7a:	05853903          	ld	s2,88(a0)
    80002e7e:	0a893783          	ld	a5,168(s2)
    80002e82:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e86:	37fd                	addiw	a5,a5,-1
    80002e88:	4759                	li	a4,22
    80002e8a:	00f76f63          	bltu	a4,a5,80002ea8 <syscall+0x44>
    80002e8e:	00369713          	slli	a4,a3,0x3
    80002e92:	00005797          	auipc	a5,0x5
    80002e96:	5be78793          	addi	a5,a5,1470 # 80008450 <syscalls>
    80002e9a:	97ba                	add	a5,a5,a4
    80002e9c:	639c                	ld	a5,0(a5)
    80002e9e:	c789                	beqz	a5,80002ea8 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002ea0:	9782                	jalr	a5
    80002ea2:	06a93823          	sd	a0,112(s2)
    80002ea6:	a839                	j	80002ec4 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ea8:	16048613          	addi	a2,s1,352
    80002eac:	5c8c                	lw	a1,56(s1)
    80002eae:	00005517          	auipc	a0,0x5
    80002eb2:	56a50513          	addi	a0,a0,1386 # 80008418 <states.1740+0x158>
    80002eb6:	ffffd097          	auipc	ra,0xffffd
    80002eba:	6c4080e7          	jalr	1732(ra) # 8000057a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ebe:	6cbc                	ld	a5,88(s1)
    80002ec0:	577d                	li	a4,-1
    80002ec2:	fbb8                	sd	a4,112(a5)
  }
}
    80002ec4:	60e2                	ld	ra,24(sp)
    80002ec6:	6442                	ld	s0,16(sp)
    80002ec8:	64a2                	ld	s1,8(sp)
    80002eca:	6902                	ld	s2,0(sp)
    80002ecc:	6105                	addi	sp,sp,32
    80002ece:	8082                	ret

0000000080002ed0 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ed0:	1101                	addi	sp,sp,-32
    80002ed2:	ec06                	sd	ra,24(sp)
    80002ed4:	e822                	sd	s0,16(sp)
    80002ed6:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002ed8:	fec40593          	addi	a1,s0,-20
    80002edc:	4501                	li	a0,0
    80002ede:	00000097          	auipc	ra,0x0
    80002ee2:	f12080e7          	jalr	-238(ra) # 80002df0 <argint>
    return -1;
    80002ee6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ee8:	00054963          	bltz	a0,80002efa <sys_exit+0x2a>
  exit(n);
    80002eec:	fec42503          	lw	a0,-20(s0)
    80002ef0:	fffff097          	auipc	ra,0xfffff
    80002ef4:	276080e7          	jalr	630(ra) # 80002166 <exit>
  return 0;  // not reached
    80002ef8:	4781                	li	a5,0
}
    80002efa:	853e                	mv	a0,a5
    80002efc:	60e2                	ld	ra,24(sp)
    80002efe:	6442                	ld	s0,16(sp)
    80002f00:	6105                	addi	sp,sp,32
    80002f02:	8082                	ret

0000000080002f04 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f04:	1141                	addi	sp,sp,-16
    80002f06:	e406                	sd	ra,8(sp)
    80002f08:	e022                	sd	s0,0(sp)
    80002f0a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f0c:	fffff097          	auipc	ra,0xfffff
    80002f10:	c9a080e7          	jalr	-870(ra) # 80001ba6 <myproc>
}
    80002f14:	5d08                	lw	a0,56(a0)
    80002f16:	60a2                	ld	ra,8(sp)
    80002f18:	6402                	ld	s0,0(sp)
    80002f1a:	0141                	addi	sp,sp,16
    80002f1c:	8082                	ret

0000000080002f1e <sys_fork>:

uint64
sys_fork(void)
{
    80002f1e:	1141                	addi	sp,sp,-16
    80002f20:	e406                	sd	ra,8(sp)
    80002f22:	e022                	sd	s0,0(sp)
    80002f24:	0800                	addi	s0,sp,16
  return fork();
    80002f26:	00000097          	auipc	ra,0x0
    80002f2a:	814080e7          	jalr	-2028(ra) # 8000273a <fork>
}
    80002f2e:	60a2                	ld	ra,8(sp)
    80002f30:	6402                	ld	s0,0(sp)
    80002f32:	0141                	addi	sp,sp,16
    80002f34:	8082                	ret

0000000080002f36 <sys_wait>:

uint64
sys_wait(void)
{
    80002f36:	1101                	addi	sp,sp,-32
    80002f38:	ec06                	sd	ra,24(sp)
    80002f3a:	e822                	sd	s0,16(sp)
    80002f3c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f3e:	fe840593          	addi	a1,s0,-24
    80002f42:	4501                	li	a0,0
    80002f44:	00000097          	auipc	ra,0x0
    80002f48:	ece080e7          	jalr	-306(ra) # 80002e12 <argaddr>
    80002f4c:	87aa                	mv	a5,a0
    return -1;
    80002f4e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f50:	0007c863          	bltz	a5,80002f60 <sys_wait+0x2a>
  return wait(p);
    80002f54:	fe843503          	ld	a0,-24(s0)
    80002f58:	fffff097          	auipc	ra,0xfffff
    80002f5c:	436080e7          	jalr	1078(ra) # 8000238e <wait>
}
    80002f60:	60e2                	ld	ra,24(sp)
    80002f62:	6442                	ld	s0,16(sp)
    80002f64:	6105                	addi	sp,sp,32
    80002f66:	8082                	ret

0000000080002f68 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f68:	7179                	addi	sp,sp,-48
    80002f6a:	f406                	sd	ra,40(sp)
    80002f6c:	f022                	sd	s0,32(sp)
    80002f6e:	ec26                	sd	s1,24(sp)
    80002f70:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f72:	fdc40593          	addi	a1,s0,-36
    80002f76:	4501                	li	a0,0
    80002f78:	00000097          	auipc	ra,0x0
    80002f7c:	e78080e7          	jalr	-392(ra) # 80002df0 <argint>
    80002f80:	87aa                	mv	a5,a0
    return -1;
    80002f82:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f84:	0207c063          	bltz	a5,80002fa4 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f88:	fffff097          	auipc	ra,0xfffff
    80002f8c:	c1e080e7          	jalr	-994(ra) # 80001ba6 <myproc>
    80002f90:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002f92:	fdc42503          	lw	a0,-36(s0)
    80002f96:	fffff097          	auipc	ra,0xfffff
    80002f9a:	f5c080e7          	jalr	-164(ra) # 80001ef2 <growproc>
    80002f9e:	00054863          	bltz	a0,80002fae <sys_sbrk+0x46>
    return -1;
  return addr;
    80002fa2:	8526                	mv	a0,s1
}
    80002fa4:	70a2                	ld	ra,40(sp)
    80002fa6:	7402                	ld	s0,32(sp)
    80002fa8:	64e2                	ld	s1,24(sp)
    80002faa:	6145                	addi	sp,sp,48
    80002fac:	8082                	ret
    return -1;
    80002fae:	557d                	li	a0,-1
    80002fb0:	bfd5                	j	80002fa4 <sys_sbrk+0x3c>

0000000080002fb2 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fb2:	7139                	addi	sp,sp,-64
    80002fb4:	fc06                	sd	ra,56(sp)
    80002fb6:	f822                	sd	s0,48(sp)
    80002fb8:	f426                	sd	s1,40(sp)
    80002fba:	f04a                	sd	s2,32(sp)
    80002fbc:	ec4e                	sd	s3,24(sp)
    80002fbe:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002fc0:	fcc40593          	addi	a1,s0,-52
    80002fc4:	4501                	li	a0,0
    80002fc6:	00000097          	auipc	ra,0x0
    80002fca:	e2a080e7          	jalr	-470(ra) # 80002df0 <argint>
    return -1;
    80002fce:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fd0:	06054563          	bltz	a0,8000303a <sys_sleep+0x88>
  acquire(&tickslock);
    80002fd4:	00014517          	auipc	a0,0x14
    80002fd8:	7e450513          	addi	a0,a0,2020 # 800177b8 <tickslock>
    80002fdc:	ffffe097          	auipc	ra,0xffffe
    80002fe0:	bfa080e7          	jalr	-1030(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002fe4:	00006917          	auipc	s2,0x6
    80002fe8:	04c92903          	lw	s2,76(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002fec:	fcc42783          	lw	a5,-52(s0)
    80002ff0:	cf85                	beqz	a5,80003028 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ff2:	00014997          	auipc	s3,0x14
    80002ff6:	7c698993          	addi	s3,s3,1990 # 800177b8 <tickslock>
    80002ffa:	00006497          	auipc	s1,0x6
    80002ffe:	03648493          	addi	s1,s1,54 # 80009030 <ticks>
    if(myproc()->killed){
    80003002:	fffff097          	auipc	ra,0xfffff
    80003006:	ba4080e7          	jalr	-1116(ra) # 80001ba6 <myproc>
    8000300a:	591c                	lw	a5,48(a0)
    8000300c:	ef9d                	bnez	a5,8000304a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000300e:	85ce                	mv	a1,s3
    80003010:	8526                	mv	a0,s1
    80003012:	fffff097          	auipc	ra,0xfffff
    80003016:	2fe080e7          	jalr	766(ra) # 80002310 <sleep>
  while(ticks - ticks0 < n){
    8000301a:	409c                	lw	a5,0(s1)
    8000301c:	412787bb          	subw	a5,a5,s2
    80003020:	fcc42703          	lw	a4,-52(s0)
    80003024:	fce7efe3          	bltu	a5,a4,80003002 <sys_sleep+0x50>
  }
  release(&tickslock);
    80003028:	00014517          	auipc	a0,0x14
    8000302c:	79050513          	addi	a0,a0,1936 # 800177b8 <tickslock>
    80003030:	ffffe097          	auipc	ra,0xffffe
    80003034:	c5a080e7          	jalr	-934(ra) # 80000c8a <release>
  return 0;
    80003038:	4781                	li	a5,0
}
    8000303a:	853e                	mv	a0,a5
    8000303c:	70e2                	ld	ra,56(sp)
    8000303e:	7442                	ld	s0,48(sp)
    80003040:	74a2                	ld	s1,40(sp)
    80003042:	7902                	ld	s2,32(sp)
    80003044:	69e2                	ld	s3,24(sp)
    80003046:	6121                	addi	sp,sp,64
    80003048:	8082                	ret
      release(&tickslock);
    8000304a:	00014517          	auipc	a0,0x14
    8000304e:	76e50513          	addi	a0,a0,1902 # 800177b8 <tickslock>
    80003052:	ffffe097          	auipc	ra,0xffffe
    80003056:	c38080e7          	jalr	-968(ra) # 80000c8a <release>
      return -1;
    8000305a:	57fd                	li	a5,-1
    8000305c:	bff9                	j	8000303a <sys_sleep+0x88>

000000008000305e <sys_kill>:

uint64
sys_kill(void)
{
    8000305e:	1101                	addi	sp,sp,-32
    80003060:	ec06                	sd	ra,24(sp)
    80003062:	e822                	sd	s0,16(sp)
    80003064:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003066:	fec40593          	addi	a1,s0,-20
    8000306a:	4501                	li	a0,0
    8000306c:	00000097          	auipc	ra,0x0
    80003070:	d84080e7          	jalr	-636(ra) # 80002df0 <argint>
    80003074:	87aa                	mv	a5,a0
    return -1;
    80003076:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003078:	0007c863          	bltz	a5,80003088 <sys_kill+0x2a>
  return kill(pid);
    8000307c:	fec42503          	lw	a0,-20(s0)
    80003080:	fffff097          	auipc	ra,0xfffff
    80003084:	480080e7          	jalr	1152(ra) # 80002500 <kill>
}
    80003088:	60e2                	ld	ra,24(sp)
    8000308a:	6442                	ld	s0,16(sp)
    8000308c:	6105                	addi	sp,sp,32
    8000308e:	8082                	ret

0000000080003090 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003090:	1101                	addi	sp,sp,-32
    80003092:	ec06                	sd	ra,24(sp)
    80003094:	e822                	sd	s0,16(sp)
    80003096:	e426                	sd	s1,8(sp)
    80003098:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000309a:	00014517          	auipc	a0,0x14
    8000309e:	71e50513          	addi	a0,a0,1822 # 800177b8 <tickslock>
    800030a2:	ffffe097          	auipc	ra,0xffffe
    800030a6:	b34080e7          	jalr	-1228(ra) # 80000bd6 <acquire>
  xticks = ticks;
    800030aa:	00006497          	auipc	s1,0x6
    800030ae:	f864a483          	lw	s1,-122(s1) # 80009030 <ticks>
  release(&tickslock);
    800030b2:	00014517          	auipc	a0,0x14
    800030b6:	70650513          	addi	a0,a0,1798 # 800177b8 <tickslock>
    800030ba:	ffffe097          	auipc	ra,0xffffe
    800030be:	bd0080e7          	jalr	-1072(ra) # 80000c8a <release>
  return xticks;
}
    800030c2:	02049513          	slli	a0,s1,0x20
    800030c6:	9101                	srli	a0,a0,0x20
    800030c8:	60e2                	ld	ra,24(sp)
    800030ca:	6442                	ld	s0,16(sp)
    800030cc:	64a2                	ld	s1,8(sp)
    800030ce:	6105                	addi	sp,sp,32
    800030d0:	8082                	ret

00000000800030d2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030d2:	7179                	addi	sp,sp,-48
    800030d4:	f406                	sd	ra,40(sp)
    800030d6:	f022                	sd	s0,32(sp)
    800030d8:	ec26                	sd	s1,24(sp)
    800030da:	e84a                	sd	s2,16(sp)
    800030dc:	e44e                	sd	s3,8(sp)
    800030de:	e052                	sd	s4,0(sp)
    800030e0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030e2:	00005597          	auipc	a1,0x5
    800030e6:	42e58593          	addi	a1,a1,1070 # 80008510 <syscalls+0xc0>
    800030ea:	00014517          	auipc	a0,0x14
    800030ee:	6e650513          	addi	a0,a0,1766 # 800177d0 <bcache>
    800030f2:	ffffe097          	auipc	ra,0xffffe
    800030f6:	a54080e7          	jalr	-1452(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800030fa:	0001c797          	auipc	a5,0x1c
    800030fe:	6d678793          	addi	a5,a5,1750 # 8001f7d0 <bcache+0x8000>
    80003102:	0001d717          	auipc	a4,0x1d
    80003106:	93670713          	addi	a4,a4,-1738 # 8001fa38 <bcache+0x8268>
    8000310a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000310e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003112:	00014497          	auipc	s1,0x14
    80003116:	6d648493          	addi	s1,s1,1750 # 800177e8 <bcache+0x18>
    b->next = bcache.head.next;
    8000311a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000311c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000311e:	00005a17          	auipc	s4,0x5
    80003122:	3faa0a13          	addi	s4,s4,1018 # 80008518 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003126:	2b893783          	ld	a5,696(s2)
    8000312a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000312c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003130:	85d2                	mv	a1,s4
    80003132:	01048513          	addi	a0,s1,16
    80003136:	00001097          	auipc	ra,0x1
    8000313a:	4c4080e7          	jalr	1220(ra) # 800045fa <initsleeplock>
    bcache.head.next->prev = b;
    8000313e:	2b893783          	ld	a5,696(s2)
    80003142:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003144:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003148:	45848493          	addi	s1,s1,1112
    8000314c:	fd349de3          	bne	s1,s3,80003126 <binit+0x54>
  }
}
    80003150:	70a2                	ld	ra,40(sp)
    80003152:	7402                	ld	s0,32(sp)
    80003154:	64e2                	ld	s1,24(sp)
    80003156:	6942                	ld	s2,16(sp)
    80003158:	69a2                	ld	s3,8(sp)
    8000315a:	6a02                	ld	s4,0(sp)
    8000315c:	6145                	addi	sp,sp,48
    8000315e:	8082                	ret

0000000080003160 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003160:	7179                	addi	sp,sp,-48
    80003162:	f406                	sd	ra,40(sp)
    80003164:	f022                	sd	s0,32(sp)
    80003166:	ec26                	sd	s1,24(sp)
    80003168:	e84a                	sd	s2,16(sp)
    8000316a:	e44e                	sd	s3,8(sp)
    8000316c:	1800                	addi	s0,sp,48
    8000316e:	89aa                	mv	s3,a0
    80003170:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003172:	00014517          	auipc	a0,0x14
    80003176:	65e50513          	addi	a0,a0,1630 # 800177d0 <bcache>
    8000317a:	ffffe097          	auipc	ra,0xffffe
    8000317e:	a5c080e7          	jalr	-1444(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003182:	0001d497          	auipc	s1,0x1d
    80003186:	9064b483          	ld	s1,-1786(s1) # 8001fa88 <bcache+0x82b8>
    8000318a:	0001d797          	auipc	a5,0x1d
    8000318e:	8ae78793          	addi	a5,a5,-1874 # 8001fa38 <bcache+0x8268>
    80003192:	02f48f63          	beq	s1,a5,800031d0 <bread+0x70>
    80003196:	873e                	mv	a4,a5
    80003198:	a021                	j	800031a0 <bread+0x40>
    8000319a:	68a4                	ld	s1,80(s1)
    8000319c:	02e48a63          	beq	s1,a4,800031d0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031a0:	449c                	lw	a5,8(s1)
    800031a2:	ff379ce3          	bne	a5,s3,8000319a <bread+0x3a>
    800031a6:	44dc                	lw	a5,12(s1)
    800031a8:	ff2799e3          	bne	a5,s2,8000319a <bread+0x3a>
      b->refcnt++;
    800031ac:	40bc                	lw	a5,64(s1)
    800031ae:	2785                	addiw	a5,a5,1
    800031b0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031b2:	00014517          	auipc	a0,0x14
    800031b6:	61e50513          	addi	a0,a0,1566 # 800177d0 <bcache>
    800031ba:	ffffe097          	auipc	ra,0xffffe
    800031be:	ad0080e7          	jalr	-1328(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800031c2:	01048513          	addi	a0,s1,16
    800031c6:	00001097          	auipc	ra,0x1
    800031ca:	46e080e7          	jalr	1134(ra) # 80004634 <acquiresleep>
      return b;
    800031ce:	a8b9                	j	8000322c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031d0:	0001d497          	auipc	s1,0x1d
    800031d4:	8b04b483          	ld	s1,-1872(s1) # 8001fa80 <bcache+0x82b0>
    800031d8:	0001d797          	auipc	a5,0x1d
    800031dc:	86078793          	addi	a5,a5,-1952 # 8001fa38 <bcache+0x8268>
    800031e0:	00f48863          	beq	s1,a5,800031f0 <bread+0x90>
    800031e4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031e6:	40bc                	lw	a5,64(s1)
    800031e8:	cf81                	beqz	a5,80003200 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031ea:	64a4                	ld	s1,72(s1)
    800031ec:	fee49de3          	bne	s1,a4,800031e6 <bread+0x86>
  panic("bget: no buffers");
    800031f0:	00005517          	auipc	a0,0x5
    800031f4:	33050513          	addi	a0,a0,816 # 80008520 <syscalls+0xd0>
    800031f8:	ffffd097          	auipc	ra,0xffffd
    800031fc:	338080e7          	jalr	824(ra) # 80000530 <panic>
      b->dev = dev;
    80003200:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003204:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003208:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000320c:	4785                	li	a5,1
    8000320e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003210:	00014517          	auipc	a0,0x14
    80003214:	5c050513          	addi	a0,a0,1472 # 800177d0 <bcache>
    80003218:	ffffe097          	auipc	ra,0xffffe
    8000321c:	a72080e7          	jalr	-1422(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003220:	01048513          	addi	a0,s1,16
    80003224:	00001097          	auipc	ra,0x1
    80003228:	410080e7          	jalr	1040(ra) # 80004634 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000322c:	409c                	lw	a5,0(s1)
    8000322e:	cb89                	beqz	a5,80003240 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003230:	8526                	mv	a0,s1
    80003232:	70a2                	ld	ra,40(sp)
    80003234:	7402                	ld	s0,32(sp)
    80003236:	64e2                	ld	s1,24(sp)
    80003238:	6942                	ld	s2,16(sp)
    8000323a:	69a2                	ld	s3,8(sp)
    8000323c:	6145                	addi	sp,sp,48
    8000323e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003240:	4581                	li	a1,0
    80003242:	8526                	mv	a0,s1
    80003244:	00003097          	auipc	ra,0x3
    80003248:	232080e7          	jalr	562(ra) # 80006476 <virtio_disk_rw>
    b->valid = 1;
    8000324c:	4785                	li	a5,1
    8000324e:	c09c                	sw	a5,0(s1)
  return b;
    80003250:	b7c5                	j	80003230 <bread+0xd0>

0000000080003252 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003252:	1101                	addi	sp,sp,-32
    80003254:	ec06                	sd	ra,24(sp)
    80003256:	e822                	sd	s0,16(sp)
    80003258:	e426                	sd	s1,8(sp)
    8000325a:	1000                	addi	s0,sp,32
    8000325c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000325e:	0541                	addi	a0,a0,16
    80003260:	00001097          	auipc	ra,0x1
    80003264:	46e080e7          	jalr	1134(ra) # 800046ce <holdingsleep>
    80003268:	cd01                	beqz	a0,80003280 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000326a:	4585                	li	a1,1
    8000326c:	8526                	mv	a0,s1
    8000326e:	00003097          	auipc	ra,0x3
    80003272:	208080e7          	jalr	520(ra) # 80006476 <virtio_disk_rw>
}
    80003276:	60e2                	ld	ra,24(sp)
    80003278:	6442                	ld	s0,16(sp)
    8000327a:	64a2                	ld	s1,8(sp)
    8000327c:	6105                	addi	sp,sp,32
    8000327e:	8082                	ret
    panic("bwrite");
    80003280:	00005517          	auipc	a0,0x5
    80003284:	2b850513          	addi	a0,a0,696 # 80008538 <syscalls+0xe8>
    80003288:	ffffd097          	auipc	ra,0xffffd
    8000328c:	2a8080e7          	jalr	680(ra) # 80000530 <panic>

0000000080003290 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003290:	1101                	addi	sp,sp,-32
    80003292:	ec06                	sd	ra,24(sp)
    80003294:	e822                	sd	s0,16(sp)
    80003296:	e426                	sd	s1,8(sp)
    80003298:	e04a                	sd	s2,0(sp)
    8000329a:	1000                	addi	s0,sp,32
    8000329c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000329e:	01050913          	addi	s2,a0,16
    800032a2:	854a                	mv	a0,s2
    800032a4:	00001097          	auipc	ra,0x1
    800032a8:	42a080e7          	jalr	1066(ra) # 800046ce <holdingsleep>
    800032ac:	c92d                	beqz	a0,8000331e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032ae:	854a                	mv	a0,s2
    800032b0:	00001097          	auipc	ra,0x1
    800032b4:	3da080e7          	jalr	986(ra) # 8000468a <releasesleep>

  acquire(&bcache.lock);
    800032b8:	00014517          	auipc	a0,0x14
    800032bc:	51850513          	addi	a0,a0,1304 # 800177d0 <bcache>
    800032c0:	ffffe097          	auipc	ra,0xffffe
    800032c4:	916080e7          	jalr	-1770(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800032c8:	40bc                	lw	a5,64(s1)
    800032ca:	37fd                	addiw	a5,a5,-1
    800032cc:	0007871b          	sext.w	a4,a5
    800032d0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032d2:	eb05                	bnez	a4,80003302 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032d4:	68bc                	ld	a5,80(s1)
    800032d6:	64b8                	ld	a4,72(s1)
    800032d8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032da:	64bc                	ld	a5,72(s1)
    800032dc:	68b8                	ld	a4,80(s1)
    800032de:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032e0:	0001c797          	auipc	a5,0x1c
    800032e4:	4f078793          	addi	a5,a5,1264 # 8001f7d0 <bcache+0x8000>
    800032e8:	2b87b703          	ld	a4,696(a5)
    800032ec:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032ee:	0001c717          	auipc	a4,0x1c
    800032f2:	74a70713          	addi	a4,a4,1866 # 8001fa38 <bcache+0x8268>
    800032f6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800032f8:	2b87b703          	ld	a4,696(a5)
    800032fc:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800032fe:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003302:	00014517          	auipc	a0,0x14
    80003306:	4ce50513          	addi	a0,a0,1230 # 800177d0 <bcache>
    8000330a:	ffffe097          	auipc	ra,0xffffe
    8000330e:	980080e7          	jalr	-1664(ra) # 80000c8a <release>
}
    80003312:	60e2                	ld	ra,24(sp)
    80003314:	6442                	ld	s0,16(sp)
    80003316:	64a2                	ld	s1,8(sp)
    80003318:	6902                	ld	s2,0(sp)
    8000331a:	6105                	addi	sp,sp,32
    8000331c:	8082                	ret
    panic("brelse");
    8000331e:	00005517          	auipc	a0,0x5
    80003322:	22250513          	addi	a0,a0,546 # 80008540 <syscalls+0xf0>
    80003326:	ffffd097          	auipc	ra,0xffffd
    8000332a:	20a080e7          	jalr	522(ra) # 80000530 <panic>

000000008000332e <bpin>:

void
bpin(struct buf *b) {
    8000332e:	1101                	addi	sp,sp,-32
    80003330:	ec06                	sd	ra,24(sp)
    80003332:	e822                	sd	s0,16(sp)
    80003334:	e426                	sd	s1,8(sp)
    80003336:	1000                	addi	s0,sp,32
    80003338:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000333a:	00014517          	auipc	a0,0x14
    8000333e:	49650513          	addi	a0,a0,1174 # 800177d0 <bcache>
    80003342:	ffffe097          	auipc	ra,0xffffe
    80003346:	894080e7          	jalr	-1900(ra) # 80000bd6 <acquire>
  b->refcnt++;
    8000334a:	40bc                	lw	a5,64(s1)
    8000334c:	2785                	addiw	a5,a5,1
    8000334e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003350:	00014517          	auipc	a0,0x14
    80003354:	48050513          	addi	a0,a0,1152 # 800177d0 <bcache>
    80003358:	ffffe097          	auipc	ra,0xffffe
    8000335c:	932080e7          	jalr	-1742(ra) # 80000c8a <release>
}
    80003360:	60e2                	ld	ra,24(sp)
    80003362:	6442                	ld	s0,16(sp)
    80003364:	64a2                	ld	s1,8(sp)
    80003366:	6105                	addi	sp,sp,32
    80003368:	8082                	ret

000000008000336a <bunpin>:

void
bunpin(struct buf *b) {
    8000336a:	1101                	addi	sp,sp,-32
    8000336c:	ec06                	sd	ra,24(sp)
    8000336e:	e822                	sd	s0,16(sp)
    80003370:	e426                	sd	s1,8(sp)
    80003372:	1000                	addi	s0,sp,32
    80003374:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003376:	00014517          	auipc	a0,0x14
    8000337a:	45a50513          	addi	a0,a0,1114 # 800177d0 <bcache>
    8000337e:	ffffe097          	auipc	ra,0xffffe
    80003382:	858080e7          	jalr	-1960(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003386:	40bc                	lw	a5,64(s1)
    80003388:	37fd                	addiw	a5,a5,-1
    8000338a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000338c:	00014517          	auipc	a0,0x14
    80003390:	44450513          	addi	a0,a0,1092 # 800177d0 <bcache>
    80003394:	ffffe097          	auipc	ra,0xffffe
    80003398:	8f6080e7          	jalr	-1802(ra) # 80000c8a <release>
}
    8000339c:	60e2                	ld	ra,24(sp)
    8000339e:	6442                	ld	s0,16(sp)
    800033a0:	64a2                	ld	s1,8(sp)
    800033a2:	6105                	addi	sp,sp,32
    800033a4:	8082                	ret

00000000800033a6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033a6:	1101                	addi	sp,sp,-32
    800033a8:	ec06                	sd	ra,24(sp)
    800033aa:	e822                	sd	s0,16(sp)
    800033ac:	e426                	sd	s1,8(sp)
    800033ae:	e04a                	sd	s2,0(sp)
    800033b0:	1000                	addi	s0,sp,32
    800033b2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033b4:	00d5d59b          	srliw	a1,a1,0xd
    800033b8:	0001d797          	auipc	a5,0x1d
    800033bc:	af47a783          	lw	a5,-1292(a5) # 8001feac <sb+0x1c>
    800033c0:	9dbd                	addw	a1,a1,a5
    800033c2:	00000097          	auipc	ra,0x0
    800033c6:	d9e080e7          	jalr	-610(ra) # 80003160 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033ca:	0074f713          	andi	a4,s1,7
    800033ce:	4785                	li	a5,1
    800033d0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033d4:	14ce                	slli	s1,s1,0x33
    800033d6:	90d9                	srli	s1,s1,0x36
    800033d8:	00950733          	add	a4,a0,s1
    800033dc:	05874703          	lbu	a4,88(a4)
    800033e0:	00e7f6b3          	and	a3,a5,a4
    800033e4:	c69d                	beqz	a3,80003412 <bfree+0x6c>
    800033e6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033e8:	94aa                	add	s1,s1,a0
    800033ea:	fff7c793          	not	a5,a5
    800033ee:	8ff9                	and	a5,a5,a4
    800033f0:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800033f4:	00001097          	auipc	ra,0x1
    800033f8:	118080e7          	jalr	280(ra) # 8000450c <log_write>
  brelse(bp);
    800033fc:	854a                	mv	a0,s2
    800033fe:	00000097          	auipc	ra,0x0
    80003402:	e92080e7          	jalr	-366(ra) # 80003290 <brelse>
}
    80003406:	60e2                	ld	ra,24(sp)
    80003408:	6442                	ld	s0,16(sp)
    8000340a:	64a2                	ld	s1,8(sp)
    8000340c:	6902                	ld	s2,0(sp)
    8000340e:	6105                	addi	sp,sp,32
    80003410:	8082                	ret
    panic("freeing free block");
    80003412:	00005517          	auipc	a0,0x5
    80003416:	13650513          	addi	a0,a0,310 # 80008548 <syscalls+0xf8>
    8000341a:	ffffd097          	auipc	ra,0xffffd
    8000341e:	116080e7          	jalr	278(ra) # 80000530 <panic>

0000000080003422 <balloc>:
{
    80003422:	711d                	addi	sp,sp,-96
    80003424:	ec86                	sd	ra,88(sp)
    80003426:	e8a2                	sd	s0,80(sp)
    80003428:	e4a6                	sd	s1,72(sp)
    8000342a:	e0ca                	sd	s2,64(sp)
    8000342c:	fc4e                	sd	s3,56(sp)
    8000342e:	f852                	sd	s4,48(sp)
    80003430:	f456                	sd	s5,40(sp)
    80003432:	f05a                	sd	s6,32(sp)
    80003434:	ec5e                	sd	s7,24(sp)
    80003436:	e862                	sd	s8,16(sp)
    80003438:	e466                	sd	s9,8(sp)
    8000343a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000343c:	0001d797          	auipc	a5,0x1d
    80003440:	a587a783          	lw	a5,-1448(a5) # 8001fe94 <sb+0x4>
    80003444:	cbd1                	beqz	a5,800034d8 <balloc+0xb6>
    80003446:	8baa                	mv	s7,a0
    80003448:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000344a:	0001db17          	auipc	s6,0x1d
    8000344e:	a46b0b13          	addi	s6,s6,-1466 # 8001fe90 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003452:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003454:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003456:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003458:	6c89                	lui	s9,0x2
    8000345a:	a831                	j	80003476 <balloc+0x54>
    brelse(bp);
    8000345c:	854a                	mv	a0,s2
    8000345e:	00000097          	auipc	ra,0x0
    80003462:	e32080e7          	jalr	-462(ra) # 80003290 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003466:	015c87bb          	addw	a5,s9,s5
    8000346a:	00078a9b          	sext.w	s5,a5
    8000346e:	004b2703          	lw	a4,4(s6)
    80003472:	06eaf363          	bgeu	s5,a4,800034d8 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003476:	41fad79b          	sraiw	a5,s5,0x1f
    8000347a:	0137d79b          	srliw	a5,a5,0x13
    8000347e:	015787bb          	addw	a5,a5,s5
    80003482:	40d7d79b          	sraiw	a5,a5,0xd
    80003486:	01cb2583          	lw	a1,28(s6)
    8000348a:	9dbd                	addw	a1,a1,a5
    8000348c:	855e                	mv	a0,s7
    8000348e:	00000097          	auipc	ra,0x0
    80003492:	cd2080e7          	jalr	-814(ra) # 80003160 <bread>
    80003496:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003498:	004b2503          	lw	a0,4(s6)
    8000349c:	000a849b          	sext.w	s1,s5
    800034a0:	8662                	mv	a2,s8
    800034a2:	faa4fde3          	bgeu	s1,a0,8000345c <balloc+0x3a>
      m = 1 << (bi % 8);
    800034a6:	41f6579b          	sraiw	a5,a2,0x1f
    800034aa:	01d7d69b          	srliw	a3,a5,0x1d
    800034ae:	00c6873b          	addw	a4,a3,a2
    800034b2:	00777793          	andi	a5,a4,7
    800034b6:	9f95                	subw	a5,a5,a3
    800034b8:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034bc:	4037571b          	sraiw	a4,a4,0x3
    800034c0:	00e906b3          	add	a3,s2,a4
    800034c4:	0586c683          	lbu	a3,88(a3)
    800034c8:	00d7f5b3          	and	a1,a5,a3
    800034cc:	cd91                	beqz	a1,800034e8 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034ce:	2605                	addiw	a2,a2,1
    800034d0:	2485                	addiw	s1,s1,1
    800034d2:	fd4618e3          	bne	a2,s4,800034a2 <balloc+0x80>
    800034d6:	b759                	j	8000345c <balloc+0x3a>
  panic("balloc: out of blocks");
    800034d8:	00005517          	auipc	a0,0x5
    800034dc:	08850513          	addi	a0,a0,136 # 80008560 <syscalls+0x110>
    800034e0:	ffffd097          	auipc	ra,0xffffd
    800034e4:	050080e7          	jalr	80(ra) # 80000530 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034e8:	974a                	add	a4,a4,s2
    800034ea:	8fd5                	or	a5,a5,a3
    800034ec:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800034f0:	854a                	mv	a0,s2
    800034f2:	00001097          	auipc	ra,0x1
    800034f6:	01a080e7          	jalr	26(ra) # 8000450c <log_write>
        brelse(bp);
    800034fa:	854a                	mv	a0,s2
    800034fc:	00000097          	auipc	ra,0x0
    80003500:	d94080e7          	jalr	-620(ra) # 80003290 <brelse>
  bp = bread(dev, bno);
    80003504:	85a6                	mv	a1,s1
    80003506:	855e                	mv	a0,s7
    80003508:	00000097          	auipc	ra,0x0
    8000350c:	c58080e7          	jalr	-936(ra) # 80003160 <bread>
    80003510:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003512:	40000613          	li	a2,1024
    80003516:	4581                	li	a1,0
    80003518:	05850513          	addi	a0,a0,88
    8000351c:	ffffd097          	auipc	ra,0xffffd
    80003520:	7b6080e7          	jalr	1974(ra) # 80000cd2 <memset>
  log_write(bp);
    80003524:	854a                	mv	a0,s2
    80003526:	00001097          	auipc	ra,0x1
    8000352a:	fe6080e7          	jalr	-26(ra) # 8000450c <log_write>
  brelse(bp);
    8000352e:	854a                	mv	a0,s2
    80003530:	00000097          	auipc	ra,0x0
    80003534:	d60080e7          	jalr	-672(ra) # 80003290 <brelse>
}
    80003538:	8526                	mv	a0,s1
    8000353a:	60e6                	ld	ra,88(sp)
    8000353c:	6446                	ld	s0,80(sp)
    8000353e:	64a6                	ld	s1,72(sp)
    80003540:	6906                	ld	s2,64(sp)
    80003542:	79e2                	ld	s3,56(sp)
    80003544:	7a42                	ld	s4,48(sp)
    80003546:	7aa2                	ld	s5,40(sp)
    80003548:	7b02                	ld	s6,32(sp)
    8000354a:	6be2                	ld	s7,24(sp)
    8000354c:	6c42                	ld	s8,16(sp)
    8000354e:	6ca2                	ld	s9,8(sp)
    80003550:	6125                	addi	sp,sp,96
    80003552:	8082                	ret

0000000080003554 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003554:	7179                	addi	sp,sp,-48
    80003556:	f406                	sd	ra,40(sp)
    80003558:	f022                	sd	s0,32(sp)
    8000355a:	ec26                	sd	s1,24(sp)
    8000355c:	e84a                	sd	s2,16(sp)
    8000355e:	e44e                	sd	s3,8(sp)
    80003560:	e052                	sd	s4,0(sp)
    80003562:	1800                	addi	s0,sp,48
    80003564:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003566:	47ad                	li	a5,11
    80003568:	04b7fe63          	bgeu	a5,a1,800035c4 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000356c:	ff45849b          	addiw	s1,a1,-12
    80003570:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003574:	0ff00793          	li	a5,255
    80003578:	0ae7e363          	bltu	a5,a4,8000361e <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000357c:	08052583          	lw	a1,128(a0)
    80003580:	c5ad                	beqz	a1,800035ea <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003582:	00092503          	lw	a0,0(s2)
    80003586:	00000097          	auipc	ra,0x0
    8000358a:	bda080e7          	jalr	-1062(ra) # 80003160 <bread>
    8000358e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003590:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003594:	02049593          	slli	a1,s1,0x20
    80003598:	9181                	srli	a1,a1,0x20
    8000359a:	058a                	slli	a1,a1,0x2
    8000359c:	00b784b3          	add	s1,a5,a1
    800035a0:	0004a983          	lw	s3,0(s1)
    800035a4:	04098d63          	beqz	s3,800035fe <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035a8:	8552                	mv	a0,s4
    800035aa:	00000097          	auipc	ra,0x0
    800035ae:	ce6080e7          	jalr	-794(ra) # 80003290 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035b2:	854e                	mv	a0,s3
    800035b4:	70a2                	ld	ra,40(sp)
    800035b6:	7402                	ld	s0,32(sp)
    800035b8:	64e2                	ld	s1,24(sp)
    800035ba:	6942                	ld	s2,16(sp)
    800035bc:	69a2                	ld	s3,8(sp)
    800035be:	6a02                	ld	s4,0(sp)
    800035c0:	6145                	addi	sp,sp,48
    800035c2:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035c4:	02059493          	slli	s1,a1,0x20
    800035c8:	9081                	srli	s1,s1,0x20
    800035ca:	048a                	slli	s1,s1,0x2
    800035cc:	94aa                	add	s1,s1,a0
    800035ce:	0504a983          	lw	s3,80(s1)
    800035d2:	fe0990e3          	bnez	s3,800035b2 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035d6:	4108                	lw	a0,0(a0)
    800035d8:	00000097          	auipc	ra,0x0
    800035dc:	e4a080e7          	jalr	-438(ra) # 80003422 <balloc>
    800035e0:	0005099b          	sext.w	s3,a0
    800035e4:	0534a823          	sw	s3,80(s1)
    800035e8:	b7e9                	j	800035b2 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800035ea:	4108                	lw	a0,0(a0)
    800035ec:	00000097          	auipc	ra,0x0
    800035f0:	e36080e7          	jalr	-458(ra) # 80003422 <balloc>
    800035f4:	0005059b          	sext.w	a1,a0
    800035f8:	08b92023          	sw	a1,128(s2)
    800035fc:	b759                	j	80003582 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800035fe:	00092503          	lw	a0,0(s2)
    80003602:	00000097          	auipc	ra,0x0
    80003606:	e20080e7          	jalr	-480(ra) # 80003422 <balloc>
    8000360a:	0005099b          	sext.w	s3,a0
    8000360e:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003612:	8552                	mv	a0,s4
    80003614:	00001097          	auipc	ra,0x1
    80003618:	ef8080e7          	jalr	-264(ra) # 8000450c <log_write>
    8000361c:	b771                	j	800035a8 <bmap+0x54>
  panic("bmap: out of range");
    8000361e:	00005517          	auipc	a0,0x5
    80003622:	f5a50513          	addi	a0,a0,-166 # 80008578 <syscalls+0x128>
    80003626:	ffffd097          	auipc	ra,0xffffd
    8000362a:	f0a080e7          	jalr	-246(ra) # 80000530 <panic>

000000008000362e <iget>:
{
    8000362e:	7179                	addi	sp,sp,-48
    80003630:	f406                	sd	ra,40(sp)
    80003632:	f022                	sd	s0,32(sp)
    80003634:	ec26                	sd	s1,24(sp)
    80003636:	e84a                	sd	s2,16(sp)
    80003638:	e44e                	sd	s3,8(sp)
    8000363a:	e052                	sd	s4,0(sp)
    8000363c:	1800                	addi	s0,sp,48
    8000363e:	89aa                	mv	s3,a0
    80003640:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003642:	0001d517          	auipc	a0,0x1d
    80003646:	86e50513          	addi	a0,a0,-1938 # 8001feb0 <icache>
    8000364a:	ffffd097          	auipc	ra,0xffffd
    8000364e:	58c080e7          	jalr	1420(ra) # 80000bd6 <acquire>
  empty = 0;
    80003652:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003654:	0001d497          	auipc	s1,0x1d
    80003658:	87448493          	addi	s1,s1,-1932 # 8001fec8 <icache+0x18>
    8000365c:	0001e697          	auipc	a3,0x1e
    80003660:	2fc68693          	addi	a3,a3,764 # 80021958 <log>
    80003664:	a039                	j	80003672 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003666:	02090b63          	beqz	s2,8000369c <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000366a:	08848493          	addi	s1,s1,136
    8000366e:	02d48a63          	beq	s1,a3,800036a2 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003672:	449c                	lw	a5,8(s1)
    80003674:	fef059e3          	blez	a5,80003666 <iget+0x38>
    80003678:	4098                	lw	a4,0(s1)
    8000367a:	ff3716e3          	bne	a4,s3,80003666 <iget+0x38>
    8000367e:	40d8                	lw	a4,4(s1)
    80003680:	ff4713e3          	bne	a4,s4,80003666 <iget+0x38>
      ip->ref++;
    80003684:	2785                	addiw	a5,a5,1
    80003686:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003688:	0001d517          	auipc	a0,0x1d
    8000368c:	82850513          	addi	a0,a0,-2008 # 8001feb0 <icache>
    80003690:	ffffd097          	auipc	ra,0xffffd
    80003694:	5fa080e7          	jalr	1530(ra) # 80000c8a <release>
      return ip;
    80003698:	8926                	mv	s2,s1
    8000369a:	a03d                	j	800036c8 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000369c:	f7f9                	bnez	a5,8000366a <iget+0x3c>
    8000369e:	8926                	mv	s2,s1
    800036a0:	b7e9                	j	8000366a <iget+0x3c>
  if(empty == 0)
    800036a2:	02090c63          	beqz	s2,800036da <iget+0xac>
  ip->dev = dev;
    800036a6:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036aa:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036ae:	4785                	li	a5,1
    800036b0:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036b4:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800036b8:	0001c517          	auipc	a0,0x1c
    800036bc:	7f850513          	addi	a0,a0,2040 # 8001feb0 <icache>
    800036c0:	ffffd097          	auipc	ra,0xffffd
    800036c4:	5ca080e7          	jalr	1482(ra) # 80000c8a <release>
}
    800036c8:	854a                	mv	a0,s2
    800036ca:	70a2                	ld	ra,40(sp)
    800036cc:	7402                	ld	s0,32(sp)
    800036ce:	64e2                	ld	s1,24(sp)
    800036d0:	6942                	ld	s2,16(sp)
    800036d2:	69a2                	ld	s3,8(sp)
    800036d4:	6a02                	ld	s4,0(sp)
    800036d6:	6145                	addi	sp,sp,48
    800036d8:	8082                	ret
    panic("iget: no inodes");
    800036da:	00005517          	auipc	a0,0x5
    800036de:	eb650513          	addi	a0,a0,-330 # 80008590 <syscalls+0x140>
    800036e2:	ffffd097          	auipc	ra,0xffffd
    800036e6:	e4e080e7          	jalr	-434(ra) # 80000530 <panic>

00000000800036ea <fsinit>:
fsinit(int dev) {
    800036ea:	7179                	addi	sp,sp,-48
    800036ec:	f406                	sd	ra,40(sp)
    800036ee:	f022                	sd	s0,32(sp)
    800036f0:	ec26                	sd	s1,24(sp)
    800036f2:	e84a                	sd	s2,16(sp)
    800036f4:	e44e                	sd	s3,8(sp)
    800036f6:	1800                	addi	s0,sp,48
    800036f8:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800036fa:	4585                	li	a1,1
    800036fc:	00000097          	auipc	ra,0x0
    80003700:	a64080e7          	jalr	-1436(ra) # 80003160 <bread>
    80003704:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003706:	0001c997          	auipc	s3,0x1c
    8000370a:	78a98993          	addi	s3,s3,1930 # 8001fe90 <sb>
    8000370e:	02000613          	li	a2,32
    80003712:	05850593          	addi	a1,a0,88
    80003716:	854e                	mv	a0,s3
    80003718:	ffffd097          	auipc	ra,0xffffd
    8000371c:	61a080e7          	jalr	1562(ra) # 80000d32 <memmove>
  brelse(bp);
    80003720:	8526                	mv	a0,s1
    80003722:	00000097          	auipc	ra,0x0
    80003726:	b6e080e7          	jalr	-1170(ra) # 80003290 <brelse>
  if(sb.magic != FSMAGIC)
    8000372a:	0009a703          	lw	a4,0(s3)
    8000372e:	102037b7          	lui	a5,0x10203
    80003732:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003736:	02f71263          	bne	a4,a5,8000375a <fsinit+0x70>
  initlog(dev, &sb);
    8000373a:	0001c597          	auipc	a1,0x1c
    8000373e:	75658593          	addi	a1,a1,1878 # 8001fe90 <sb>
    80003742:	854a                	mv	a0,s2
    80003744:	00001097          	auipc	ra,0x1
    80003748:	b4c080e7          	jalr	-1204(ra) # 80004290 <initlog>
}
    8000374c:	70a2                	ld	ra,40(sp)
    8000374e:	7402                	ld	s0,32(sp)
    80003750:	64e2                	ld	s1,24(sp)
    80003752:	6942                	ld	s2,16(sp)
    80003754:	69a2                	ld	s3,8(sp)
    80003756:	6145                	addi	sp,sp,48
    80003758:	8082                	ret
    panic("invalid file system");
    8000375a:	00005517          	auipc	a0,0x5
    8000375e:	e4650513          	addi	a0,a0,-442 # 800085a0 <syscalls+0x150>
    80003762:	ffffd097          	auipc	ra,0xffffd
    80003766:	dce080e7          	jalr	-562(ra) # 80000530 <panic>

000000008000376a <iinit>:
{
    8000376a:	7179                	addi	sp,sp,-48
    8000376c:	f406                	sd	ra,40(sp)
    8000376e:	f022                	sd	s0,32(sp)
    80003770:	ec26                	sd	s1,24(sp)
    80003772:	e84a                	sd	s2,16(sp)
    80003774:	e44e                	sd	s3,8(sp)
    80003776:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003778:	00005597          	auipc	a1,0x5
    8000377c:	e4058593          	addi	a1,a1,-448 # 800085b8 <syscalls+0x168>
    80003780:	0001c517          	auipc	a0,0x1c
    80003784:	73050513          	addi	a0,a0,1840 # 8001feb0 <icache>
    80003788:	ffffd097          	auipc	ra,0xffffd
    8000378c:	3be080e7          	jalr	958(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003790:	0001c497          	auipc	s1,0x1c
    80003794:	74848493          	addi	s1,s1,1864 # 8001fed8 <icache+0x28>
    80003798:	0001e997          	auipc	s3,0x1e
    8000379c:	1d098993          	addi	s3,s3,464 # 80021968 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800037a0:	00005917          	auipc	s2,0x5
    800037a4:	e2090913          	addi	s2,s2,-480 # 800085c0 <syscalls+0x170>
    800037a8:	85ca                	mv	a1,s2
    800037aa:	8526                	mv	a0,s1
    800037ac:	00001097          	auipc	ra,0x1
    800037b0:	e4e080e7          	jalr	-434(ra) # 800045fa <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037b4:	08848493          	addi	s1,s1,136
    800037b8:	ff3498e3          	bne	s1,s3,800037a8 <iinit+0x3e>
}
    800037bc:	70a2                	ld	ra,40(sp)
    800037be:	7402                	ld	s0,32(sp)
    800037c0:	64e2                	ld	s1,24(sp)
    800037c2:	6942                	ld	s2,16(sp)
    800037c4:	69a2                	ld	s3,8(sp)
    800037c6:	6145                	addi	sp,sp,48
    800037c8:	8082                	ret

00000000800037ca <ialloc>:
{
    800037ca:	715d                	addi	sp,sp,-80
    800037cc:	e486                	sd	ra,72(sp)
    800037ce:	e0a2                	sd	s0,64(sp)
    800037d0:	fc26                	sd	s1,56(sp)
    800037d2:	f84a                	sd	s2,48(sp)
    800037d4:	f44e                	sd	s3,40(sp)
    800037d6:	f052                	sd	s4,32(sp)
    800037d8:	ec56                	sd	s5,24(sp)
    800037da:	e85a                	sd	s6,16(sp)
    800037dc:	e45e                	sd	s7,8(sp)
    800037de:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037e0:	0001c717          	auipc	a4,0x1c
    800037e4:	6bc72703          	lw	a4,1724(a4) # 8001fe9c <sb+0xc>
    800037e8:	4785                	li	a5,1
    800037ea:	04e7fa63          	bgeu	a5,a4,8000383e <ialloc+0x74>
    800037ee:	8aaa                	mv	s5,a0
    800037f0:	8bae                	mv	s7,a1
    800037f2:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037f4:	0001ca17          	auipc	s4,0x1c
    800037f8:	69ca0a13          	addi	s4,s4,1692 # 8001fe90 <sb>
    800037fc:	00048b1b          	sext.w	s6,s1
    80003800:	0044d593          	srli	a1,s1,0x4
    80003804:	018a2783          	lw	a5,24(s4)
    80003808:	9dbd                	addw	a1,a1,a5
    8000380a:	8556                	mv	a0,s5
    8000380c:	00000097          	auipc	ra,0x0
    80003810:	954080e7          	jalr	-1708(ra) # 80003160 <bread>
    80003814:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003816:	05850993          	addi	s3,a0,88
    8000381a:	00f4f793          	andi	a5,s1,15
    8000381e:	079a                	slli	a5,a5,0x6
    80003820:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003822:	00099783          	lh	a5,0(s3)
    80003826:	c785                	beqz	a5,8000384e <ialloc+0x84>
    brelse(bp);
    80003828:	00000097          	auipc	ra,0x0
    8000382c:	a68080e7          	jalr	-1432(ra) # 80003290 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003830:	0485                	addi	s1,s1,1
    80003832:	00ca2703          	lw	a4,12(s4)
    80003836:	0004879b          	sext.w	a5,s1
    8000383a:	fce7e1e3          	bltu	a5,a4,800037fc <ialloc+0x32>
  panic("ialloc: no inodes");
    8000383e:	00005517          	auipc	a0,0x5
    80003842:	d8a50513          	addi	a0,a0,-630 # 800085c8 <syscalls+0x178>
    80003846:	ffffd097          	auipc	ra,0xffffd
    8000384a:	cea080e7          	jalr	-790(ra) # 80000530 <panic>
      memset(dip, 0, sizeof(*dip));
    8000384e:	04000613          	li	a2,64
    80003852:	4581                	li	a1,0
    80003854:	854e                	mv	a0,s3
    80003856:	ffffd097          	auipc	ra,0xffffd
    8000385a:	47c080e7          	jalr	1148(ra) # 80000cd2 <memset>
      dip->type = type;
    8000385e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003862:	854a                	mv	a0,s2
    80003864:	00001097          	auipc	ra,0x1
    80003868:	ca8080e7          	jalr	-856(ra) # 8000450c <log_write>
      brelse(bp);
    8000386c:	854a                	mv	a0,s2
    8000386e:	00000097          	auipc	ra,0x0
    80003872:	a22080e7          	jalr	-1502(ra) # 80003290 <brelse>
      return iget(dev, inum);
    80003876:	85da                	mv	a1,s6
    80003878:	8556                	mv	a0,s5
    8000387a:	00000097          	auipc	ra,0x0
    8000387e:	db4080e7          	jalr	-588(ra) # 8000362e <iget>
}
    80003882:	60a6                	ld	ra,72(sp)
    80003884:	6406                	ld	s0,64(sp)
    80003886:	74e2                	ld	s1,56(sp)
    80003888:	7942                	ld	s2,48(sp)
    8000388a:	79a2                	ld	s3,40(sp)
    8000388c:	7a02                	ld	s4,32(sp)
    8000388e:	6ae2                	ld	s5,24(sp)
    80003890:	6b42                	ld	s6,16(sp)
    80003892:	6ba2                	ld	s7,8(sp)
    80003894:	6161                	addi	sp,sp,80
    80003896:	8082                	ret

0000000080003898 <iupdate>:
{
    80003898:	1101                	addi	sp,sp,-32
    8000389a:	ec06                	sd	ra,24(sp)
    8000389c:	e822                	sd	s0,16(sp)
    8000389e:	e426                	sd	s1,8(sp)
    800038a0:	e04a                	sd	s2,0(sp)
    800038a2:	1000                	addi	s0,sp,32
    800038a4:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038a6:	415c                	lw	a5,4(a0)
    800038a8:	0047d79b          	srliw	a5,a5,0x4
    800038ac:	0001c597          	auipc	a1,0x1c
    800038b0:	5fc5a583          	lw	a1,1532(a1) # 8001fea8 <sb+0x18>
    800038b4:	9dbd                	addw	a1,a1,a5
    800038b6:	4108                	lw	a0,0(a0)
    800038b8:	00000097          	auipc	ra,0x0
    800038bc:	8a8080e7          	jalr	-1880(ra) # 80003160 <bread>
    800038c0:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038c2:	05850793          	addi	a5,a0,88
    800038c6:	40c8                	lw	a0,4(s1)
    800038c8:	893d                	andi	a0,a0,15
    800038ca:	051a                	slli	a0,a0,0x6
    800038cc:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038ce:	04449703          	lh	a4,68(s1)
    800038d2:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038d6:	04649703          	lh	a4,70(s1)
    800038da:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038de:	04849703          	lh	a4,72(s1)
    800038e2:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800038e6:	04a49703          	lh	a4,74(s1)
    800038ea:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800038ee:	44f8                	lw	a4,76(s1)
    800038f0:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038f2:	03400613          	li	a2,52
    800038f6:	05048593          	addi	a1,s1,80
    800038fa:	0531                	addi	a0,a0,12
    800038fc:	ffffd097          	auipc	ra,0xffffd
    80003900:	436080e7          	jalr	1078(ra) # 80000d32 <memmove>
  log_write(bp);
    80003904:	854a                	mv	a0,s2
    80003906:	00001097          	auipc	ra,0x1
    8000390a:	c06080e7          	jalr	-1018(ra) # 8000450c <log_write>
  brelse(bp);
    8000390e:	854a                	mv	a0,s2
    80003910:	00000097          	auipc	ra,0x0
    80003914:	980080e7          	jalr	-1664(ra) # 80003290 <brelse>
}
    80003918:	60e2                	ld	ra,24(sp)
    8000391a:	6442                	ld	s0,16(sp)
    8000391c:	64a2                	ld	s1,8(sp)
    8000391e:	6902                	ld	s2,0(sp)
    80003920:	6105                	addi	sp,sp,32
    80003922:	8082                	ret

0000000080003924 <idup>:
{
    80003924:	1101                	addi	sp,sp,-32
    80003926:	ec06                	sd	ra,24(sp)
    80003928:	e822                	sd	s0,16(sp)
    8000392a:	e426                	sd	s1,8(sp)
    8000392c:	1000                	addi	s0,sp,32
    8000392e:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003930:	0001c517          	auipc	a0,0x1c
    80003934:	58050513          	addi	a0,a0,1408 # 8001feb0 <icache>
    80003938:	ffffd097          	auipc	ra,0xffffd
    8000393c:	29e080e7          	jalr	670(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003940:	449c                	lw	a5,8(s1)
    80003942:	2785                	addiw	a5,a5,1
    80003944:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003946:	0001c517          	auipc	a0,0x1c
    8000394a:	56a50513          	addi	a0,a0,1386 # 8001feb0 <icache>
    8000394e:	ffffd097          	auipc	ra,0xffffd
    80003952:	33c080e7          	jalr	828(ra) # 80000c8a <release>
}
    80003956:	8526                	mv	a0,s1
    80003958:	60e2                	ld	ra,24(sp)
    8000395a:	6442                	ld	s0,16(sp)
    8000395c:	64a2                	ld	s1,8(sp)
    8000395e:	6105                	addi	sp,sp,32
    80003960:	8082                	ret

0000000080003962 <ilock>:
{
    80003962:	1101                	addi	sp,sp,-32
    80003964:	ec06                	sd	ra,24(sp)
    80003966:	e822                	sd	s0,16(sp)
    80003968:	e426                	sd	s1,8(sp)
    8000396a:	e04a                	sd	s2,0(sp)
    8000396c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000396e:	c115                	beqz	a0,80003992 <ilock+0x30>
    80003970:	84aa                	mv	s1,a0
    80003972:	451c                	lw	a5,8(a0)
    80003974:	00f05f63          	blez	a5,80003992 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003978:	0541                	addi	a0,a0,16
    8000397a:	00001097          	auipc	ra,0x1
    8000397e:	cba080e7          	jalr	-838(ra) # 80004634 <acquiresleep>
  if(ip->valid == 0){
    80003982:	40bc                	lw	a5,64(s1)
    80003984:	cf99                	beqz	a5,800039a2 <ilock+0x40>
}
    80003986:	60e2                	ld	ra,24(sp)
    80003988:	6442                	ld	s0,16(sp)
    8000398a:	64a2                	ld	s1,8(sp)
    8000398c:	6902                	ld	s2,0(sp)
    8000398e:	6105                	addi	sp,sp,32
    80003990:	8082                	ret
    panic("ilock");
    80003992:	00005517          	auipc	a0,0x5
    80003996:	c4e50513          	addi	a0,a0,-946 # 800085e0 <syscalls+0x190>
    8000399a:	ffffd097          	auipc	ra,0xffffd
    8000399e:	b96080e7          	jalr	-1130(ra) # 80000530 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039a2:	40dc                	lw	a5,4(s1)
    800039a4:	0047d79b          	srliw	a5,a5,0x4
    800039a8:	0001c597          	auipc	a1,0x1c
    800039ac:	5005a583          	lw	a1,1280(a1) # 8001fea8 <sb+0x18>
    800039b0:	9dbd                	addw	a1,a1,a5
    800039b2:	4088                	lw	a0,0(s1)
    800039b4:	fffff097          	auipc	ra,0xfffff
    800039b8:	7ac080e7          	jalr	1964(ra) # 80003160 <bread>
    800039bc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039be:	05850593          	addi	a1,a0,88
    800039c2:	40dc                	lw	a5,4(s1)
    800039c4:	8bbd                	andi	a5,a5,15
    800039c6:	079a                	slli	a5,a5,0x6
    800039c8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039ca:	00059783          	lh	a5,0(a1)
    800039ce:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039d2:	00259783          	lh	a5,2(a1)
    800039d6:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039da:	00459783          	lh	a5,4(a1)
    800039de:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039e2:	00659783          	lh	a5,6(a1)
    800039e6:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800039ea:	459c                	lw	a5,8(a1)
    800039ec:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039ee:	03400613          	li	a2,52
    800039f2:	05b1                	addi	a1,a1,12
    800039f4:	05048513          	addi	a0,s1,80
    800039f8:	ffffd097          	auipc	ra,0xffffd
    800039fc:	33a080e7          	jalr	826(ra) # 80000d32 <memmove>
    brelse(bp);
    80003a00:	854a                	mv	a0,s2
    80003a02:	00000097          	auipc	ra,0x0
    80003a06:	88e080e7          	jalr	-1906(ra) # 80003290 <brelse>
    ip->valid = 1;
    80003a0a:	4785                	li	a5,1
    80003a0c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a0e:	04449783          	lh	a5,68(s1)
    80003a12:	fbb5                	bnez	a5,80003986 <ilock+0x24>
      panic("ilock: no type");
    80003a14:	00005517          	auipc	a0,0x5
    80003a18:	bd450513          	addi	a0,a0,-1068 # 800085e8 <syscalls+0x198>
    80003a1c:	ffffd097          	auipc	ra,0xffffd
    80003a20:	b14080e7          	jalr	-1260(ra) # 80000530 <panic>

0000000080003a24 <iunlock>:
{
    80003a24:	1101                	addi	sp,sp,-32
    80003a26:	ec06                	sd	ra,24(sp)
    80003a28:	e822                	sd	s0,16(sp)
    80003a2a:	e426                	sd	s1,8(sp)
    80003a2c:	e04a                	sd	s2,0(sp)
    80003a2e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a30:	c905                	beqz	a0,80003a60 <iunlock+0x3c>
    80003a32:	84aa                	mv	s1,a0
    80003a34:	01050913          	addi	s2,a0,16
    80003a38:	854a                	mv	a0,s2
    80003a3a:	00001097          	auipc	ra,0x1
    80003a3e:	c94080e7          	jalr	-876(ra) # 800046ce <holdingsleep>
    80003a42:	cd19                	beqz	a0,80003a60 <iunlock+0x3c>
    80003a44:	449c                	lw	a5,8(s1)
    80003a46:	00f05d63          	blez	a5,80003a60 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a4a:	854a                	mv	a0,s2
    80003a4c:	00001097          	auipc	ra,0x1
    80003a50:	c3e080e7          	jalr	-962(ra) # 8000468a <releasesleep>
}
    80003a54:	60e2                	ld	ra,24(sp)
    80003a56:	6442                	ld	s0,16(sp)
    80003a58:	64a2                	ld	s1,8(sp)
    80003a5a:	6902                	ld	s2,0(sp)
    80003a5c:	6105                	addi	sp,sp,32
    80003a5e:	8082                	ret
    panic("iunlock");
    80003a60:	00005517          	auipc	a0,0x5
    80003a64:	b9850513          	addi	a0,a0,-1128 # 800085f8 <syscalls+0x1a8>
    80003a68:	ffffd097          	auipc	ra,0xffffd
    80003a6c:	ac8080e7          	jalr	-1336(ra) # 80000530 <panic>

0000000080003a70 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a70:	7179                	addi	sp,sp,-48
    80003a72:	f406                	sd	ra,40(sp)
    80003a74:	f022                	sd	s0,32(sp)
    80003a76:	ec26                	sd	s1,24(sp)
    80003a78:	e84a                	sd	s2,16(sp)
    80003a7a:	e44e                	sd	s3,8(sp)
    80003a7c:	e052                	sd	s4,0(sp)
    80003a7e:	1800                	addi	s0,sp,48
    80003a80:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a82:	05050493          	addi	s1,a0,80
    80003a86:	08050913          	addi	s2,a0,128
    80003a8a:	a021                	j	80003a92 <itrunc+0x22>
    80003a8c:	0491                	addi	s1,s1,4
    80003a8e:	01248d63          	beq	s1,s2,80003aa8 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a92:	408c                	lw	a1,0(s1)
    80003a94:	dde5                	beqz	a1,80003a8c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a96:	0009a503          	lw	a0,0(s3)
    80003a9a:	00000097          	auipc	ra,0x0
    80003a9e:	90c080e7          	jalr	-1780(ra) # 800033a6 <bfree>
      ip->addrs[i] = 0;
    80003aa2:	0004a023          	sw	zero,0(s1)
    80003aa6:	b7dd                	j	80003a8c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003aa8:	0809a583          	lw	a1,128(s3)
    80003aac:	e185                	bnez	a1,80003acc <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003aae:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ab2:	854e                	mv	a0,s3
    80003ab4:	00000097          	auipc	ra,0x0
    80003ab8:	de4080e7          	jalr	-540(ra) # 80003898 <iupdate>
}
    80003abc:	70a2                	ld	ra,40(sp)
    80003abe:	7402                	ld	s0,32(sp)
    80003ac0:	64e2                	ld	s1,24(sp)
    80003ac2:	6942                	ld	s2,16(sp)
    80003ac4:	69a2                	ld	s3,8(sp)
    80003ac6:	6a02                	ld	s4,0(sp)
    80003ac8:	6145                	addi	sp,sp,48
    80003aca:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003acc:	0009a503          	lw	a0,0(s3)
    80003ad0:	fffff097          	auipc	ra,0xfffff
    80003ad4:	690080e7          	jalr	1680(ra) # 80003160 <bread>
    80003ad8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ada:	05850493          	addi	s1,a0,88
    80003ade:	45850913          	addi	s2,a0,1112
    80003ae2:	a811                	j	80003af6 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003ae4:	0009a503          	lw	a0,0(s3)
    80003ae8:	00000097          	auipc	ra,0x0
    80003aec:	8be080e7          	jalr	-1858(ra) # 800033a6 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003af0:	0491                	addi	s1,s1,4
    80003af2:	01248563          	beq	s1,s2,80003afc <itrunc+0x8c>
      if(a[j])
    80003af6:	408c                	lw	a1,0(s1)
    80003af8:	dde5                	beqz	a1,80003af0 <itrunc+0x80>
    80003afa:	b7ed                	j	80003ae4 <itrunc+0x74>
    brelse(bp);
    80003afc:	8552                	mv	a0,s4
    80003afe:	fffff097          	auipc	ra,0xfffff
    80003b02:	792080e7          	jalr	1938(ra) # 80003290 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b06:	0809a583          	lw	a1,128(s3)
    80003b0a:	0009a503          	lw	a0,0(s3)
    80003b0e:	00000097          	auipc	ra,0x0
    80003b12:	898080e7          	jalr	-1896(ra) # 800033a6 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b16:	0809a023          	sw	zero,128(s3)
    80003b1a:	bf51                	j	80003aae <itrunc+0x3e>

0000000080003b1c <iput>:
{
    80003b1c:	1101                	addi	sp,sp,-32
    80003b1e:	ec06                	sd	ra,24(sp)
    80003b20:	e822                	sd	s0,16(sp)
    80003b22:	e426                	sd	s1,8(sp)
    80003b24:	e04a                	sd	s2,0(sp)
    80003b26:	1000                	addi	s0,sp,32
    80003b28:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003b2a:	0001c517          	auipc	a0,0x1c
    80003b2e:	38650513          	addi	a0,a0,902 # 8001feb0 <icache>
    80003b32:	ffffd097          	auipc	ra,0xffffd
    80003b36:	0a4080e7          	jalr	164(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b3a:	4498                	lw	a4,8(s1)
    80003b3c:	4785                	li	a5,1
    80003b3e:	02f70363          	beq	a4,a5,80003b64 <iput+0x48>
  ip->ref--;
    80003b42:	449c                	lw	a5,8(s1)
    80003b44:	37fd                	addiw	a5,a5,-1
    80003b46:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b48:	0001c517          	auipc	a0,0x1c
    80003b4c:	36850513          	addi	a0,a0,872 # 8001feb0 <icache>
    80003b50:	ffffd097          	auipc	ra,0xffffd
    80003b54:	13a080e7          	jalr	314(ra) # 80000c8a <release>
}
    80003b58:	60e2                	ld	ra,24(sp)
    80003b5a:	6442                	ld	s0,16(sp)
    80003b5c:	64a2                	ld	s1,8(sp)
    80003b5e:	6902                	ld	s2,0(sp)
    80003b60:	6105                	addi	sp,sp,32
    80003b62:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b64:	40bc                	lw	a5,64(s1)
    80003b66:	dff1                	beqz	a5,80003b42 <iput+0x26>
    80003b68:	04a49783          	lh	a5,74(s1)
    80003b6c:	fbf9                	bnez	a5,80003b42 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b6e:	01048913          	addi	s2,s1,16
    80003b72:	854a                	mv	a0,s2
    80003b74:	00001097          	auipc	ra,0x1
    80003b78:	ac0080e7          	jalr	-1344(ra) # 80004634 <acquiresleep>
    release(&icache.lock);
    80003b7c:	0001c517          	auipc	a0,0x1c
    80003b80:	33450513          	addi	a0,a0,820 # 8001feb0 <icache>
    80003b84:	ffffd097          	auipc	ra,0xffffd
    80003b88:	106080e7          	jalr	262(ra) # 80000c8a <release>
    itrunc(ip);
    80003b8c:	8526                	mv	a0,s1
    80003b8e:	00000097          	auipc	ra,0x0
    80003b92:	ee2080e7          	jalr	-286(ra) # 80003a70 <itrunc>
    ip->type = 0;
    80003b96:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b9a:	8526                	mv	a0,s1
    80003b9c:	00000097          	auipc	ra,0x0
    80003ba0:	cfc080e7          	jalr	-772(ra) # 80003898 <iupdate>
    ip->valid = 0;
    80003ba4:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ba8:	854a                	mv	a0,s2
    80003baa:	00001097          	auipc	ra,0x1
    80003bae:	ae0080e7          	jalr	-1312(ra) # 8000468a <releasesleep>
    acquire(&icache.lock);
    80003bb2:	0001c517          	auipc	a0,0x1c
    80003bb6:	2fe50513          	addi	a0,a0,766 # 8001feb0 <icache>
    80003bba:	ffffd097          	auipc	ra,0xffffd
    80003bbe:	01c080e7          	jalr	28(ra) # 80000bd6 <acquire>
    80003bc2:	b741                	j	80003b42 <iput+0x26>

0000000080003bc4 <iunlockput>:
{
    80003bc4:	1101                	addi	sp,sp,-32
    80003bc6:	ec06                	sd	ra,24(sp)
    80003bc8:	e822                	sd	s0,16(sp)
    80003bca:	e426                	sd	s1,8(sp)
    80003bcc:	1000                	addi	s0,sp,32
    80003bce:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bd0:	00000097          	auipc	ra,0x0
    80003bd4:	e54080e7          	jalr	-428(ra) # 80003a24 <iunlock>
  iput(ip);
    80003bd8:	8526                	mv	a0,s1
    80003bda:	00000097          	auipc	ra,0x0
    80003bde:	f42080e7          	jalr	-190(ra) # 80003b1c <iput>
}
    80003be2:	60e2                	ld	ra,24(sp)
    80003be4:	6442                	ld	s0,16(sp)
    80003be6:	64a2                	ld	s1,8(sp)
    80003be8:	6105                	addi	sp,sp,32
    80003bea:	8082                	ret

0000000080003bec <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003bec:	1141                	addi	sp,sp,-16
    80003bee:	e422                	sd	s0,8(sp)
    80003bf0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003bf2:	411c                	lw	a5,0(a0)
    80003bf4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003bf6:	415c                	lw	a5,4(a0)
    80003bf8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003bfa:	04451783          	lh	a5,68(a0)
    80003bfe:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c02:	04a51783          	lh	a5,74(a0)
    80003c06:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c0a:	04c56783          	lwu	a5,76(a0)
    80003c0e:	e99c                	sd	a5,16(a1)
}
    80003c10:	6422                	ld	s0,8(sp)
    80003c12:	0141                	addi	sp,sp,16
    80003c14:	8082                	ret

0000000080003c16 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c16:	457c                	lw	a5,76(a0)
    80003c18:	0ed7e963          	bltu	a5,a3,80003d0a <readi+0xf4>
{
    80003c1c:	7159                	addi	sp,sp,-112
    80003c1e:	f486                	sd	ra,104(sp)
    80003c20:	f0a2                	sd	s0,96(sp)
    80003c22:	eca6                	sd	s1,88(sp)
    80003c24:	e8ca                	sd	s2,80(sp)
    80003c26:	e4ce                	sd	s3,72(sp)
    80003c28:	e0d2                	sd	s4,64(sp)
    80003c2a:	fc56                	sd	s5,56(sp)
    80003c2c:	f85a                	sd	s6,48(sp)
    80003c2e:	f45e                	sd	s7,40(sp)
    80003c30:	f062                	sd	s8,32(sp)
    80003c32:	ec66                	sd	s9,24(sp)
    80003c34:	e86a                	sd	s10,16(sp)
    80003c36:	e46e                	sd	s11,8(sp)
    80003c38:	1880                	addi	s0,sp,112
    80003c3a:	8baa                	mv	s7,a0
    80003c3c:	8c2e                	mv	s8,a1
    80003c3e:	8ab2                	mv	s5,a2
    80003c40:	84b6                	mv	s1,a3
    80003c42:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c44:	9f35                	addw	a4,a4,a3
    return 0;
    80003c46:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c48:	0ad76063          	bltu	a4,a3,80003ce8 <readi+0xd2>
  if(off + n > ip->size)
    80003c4c:	00e7f463          	bgeu	a5,a4,80003c54 <readi+0x3e>
    n = ip->size - off;
    80003c50:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c54:	0a0b0963          	beqz	s6,80003d06 <readi+0xf0>
    80003c58:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c5a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c5e:	5cfd                	li	s9,-1
    80003c60:	a82d                	j	80003c9a <readi+0x84>
    80003c62:	020a1d93          	slli	s11,s4,0x20
    80003c66:	020ddd93          	srli	s11,s11,0x20
    80003c6a:	05890613          	addi	a2,s2,88
    80003c6e:	86ee                	mv	a3,s11
    80003c70:	963a                	add	a2,a2,a4
    80003c72:	85d6                	mv	a1,s5
    80003c74:	8562                	mv	a0,s8
    80003c76:	fffff097          	auipc	ra,0xfffff
    80003c7a:	8fc080e7          	jalr	-1796(ra) # 80002572 <either_copyout>
    80003c7e:	05950d63          	beq	a0,s9,80003cd8 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c82:	854a                	mv	a0,s2
    80003c84:	fffff097          	auipc	ra,0xfffff
    80003c88:	60c080e7          	jalr	1548(ra) # 80003290 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c8c:	013a09bb          	addw	s3,s4,s3
    80003c90:	009a04bb          	addw	s1,s4,s1
    80003c94:	9aee                	add	s5,s5,s11
    80003c96:	0569f763          	bgeu	s3,s6,80003ce4 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c9a:	000ba903          	lw	s2,0(s7)
    80003c9e:	00a4d59b          	srliw	a1,s1,0xa
    80003ca2:	855e                	mv	a0,s7
    80003ca4:	00000097          	auipc	ra,0x0
    80003ca8:	8b0080e7          	jalr	-1872(ra) # 80003554 <bmap>
    80003cac:	0005059b          	sext.w	a1,a0
    80003cb0:	854a                	mv	a0,s2
    80003cb2:	fffff097          	auipc	ra,0xfffff
    80003cb6:	4ae080e7          	jalr	1198(ra) # 80003160 <bread>
    80003cba:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cbc:	3ff4f713          	andi	a4,s1,1023
    80003cc0:	40ed07bb          	subw	a5,s10,a4
    80003cc4:	413b06bb          	subw	a3,s6,s3
    80003cc8:	8a3e                	mv	s4,a5
    80003cca:	2781                	sext.w	a5,a5
    80003ccc:	0006861b          	sext.w	a2,a3
    80003cd0:	f8f679e3          	bgeu	a2,a5,80003c62 <readi+0x4c>
    80003cd4:	8a36                	mv	s4,a3
    80003cd6:	b771                	j	80003c62 <readi+0x4c>
      brelse(bp);
    80003cd8:	854a                	mv	a0,s2
    80003cda:	fffff097          	auipc	ra,0xfffff
    80003cde:	5b6080e7          	jalr	1462(ra) # 80003290 <brelse>
      tot = -1;
    80003ce2:	59fd                	li	s3,-1
  }
  return tot;
    80003ce4:	0009851b          	sext.w	a0,s3
}
    80003ce8:	70a6                	ld	ra,104(sp)
    80003cea:	7406                	ld	s0,96(sp)
    80003cec:	64e6                	ld	s1,88(sp)
    80003cee:	6946                	ld	s2,80(sp)
    80003cf0:	69a6                	ld	s3,72(sp)
    80003cf2:	6a06                	ld	s4,64(sp)
    80003cf4:	7ae2                	ld	s5,56(sp)
    80003cf6:	7b42                	ld	s6,48(sp)
    80003cf8:	7ba2                	ld	s7,40(sp)
    80003cfa:	7c02                	ld	s8,32(sp)
    80003cfc:	6ce2                	ld	s9,24(sp)
    80003cfe:	6d42                	ld	s10,16(sp)
    80003d00:	6da2                	ld	s11,8(sp)
    80003d02:	6165                	addi	sp,sp,112
    80003d04:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d06:	89da                	mv	s3,s6
    80003d08:	bff1                	j	80003ce4 <readi+0xce>
    return 0;
    80003d0a:	4501                	li	a0,0
}
    80003d0c:	8082                	ret

0000000080003d0e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d0e:	457c                	lw	a5,76(a0)
    80003d10:	10d7e863          	bltu	a5,a3,80003e20 <writei+0x112>
{
    80003d14:	7159                	addi	sp,sp,-112
    80003d16:	f486                	sd	ra,104(sp)
    80003d18:	f0a2                	sd	s0,96(sp)
    80003d1a:	eca6                	sd	s1,88(sp)
    80003d1c:	e8ca                	sd	s2,80(sp)
    80003d1e:	e4ce                	sd	s3,72(sp)
    80003d20:	e0d2                	sd	s4,64(sp)
    80003d22:	fc56                	sd	s5,56(sp)
    80003d24:	f85a                	sd	s6,48(sp)
    80003d26:	f45e                	sd	s7,40(sp)
    80003d28:	f062                	sd	s8,32(sp)
    80003d2a:	ec66                	sd	s9,24(sp)
    80003d2c:	e86a                	sd	s10,16(sp)
    80003d2e:	e46e                	sd	s11,8(sp)
    80003d30:	1880                	addi	s0,sp,112
    80003d32:	8b2a                	mv	s6,a0
    80003d34:	8c2e                	mv	s8,a1
    80003d36:	8ab2                	mv	s5,a2
    80003d38:	8936                	mv	s2,a3
    80003d3a:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003d3c:	00e687bb          	addw	a5,a3,a4
    80003d40:	0ed7e263          	bltu	a5,a3,80003e24 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d44:	00043737          	lui	a4,0x43
    80003d48:	0ef76063          	bltu	a4,a5,80003e28 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d4c:	0c0b8863          	beqz	s7,80003e1c <writei+0x10e>
    80003d50:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d52:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d56:	5cfd                	li	s9,-1
    80003d58:	a091                	j	80003d9c <writei+0x8e>
    80003d5a:	02099d93          	slli	s11,s3,0x20
    80003d5e:	020ddd93          	srli	s11,s11,0x20
    80003d62:	05848513          	addi	a0,s1,88
    80003d66:	86ee                	mv	a3,s11
    80003d68:	8656                	mv	a2,s5
    80003d6a:	85e2                	mv	a1,s8
    80003d6c:	953a                	add	a0,a0,a4
    80003d6e:	fffff097          	auipc	ra,0xfffff
    80003d72:	85a080e7          	jalr	-1958(ra) # 800025c8 <either_copyin>
    80003d76:	07950263          	beq	a0,s9,80003dda <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d7a:	8526                	mv	a0,s1
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	790080e7          	jalr	1936(ra) # 8000450c <log_write>
    brelse(bp);
    80003d84:	8526                	mv	a0,s1
    80003d86:	fffff097          	auipc	ra,0xfffff
    80003d8a:	50a080e7          	jalr	1290(ra) # 80003290 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d8e:	01498a3b          	addw	s4,s3,s4
    80003d92:	0129893b          	addw	s2,s3,s2
    80003d96:	9aee                	add	s5,s5,s11
    80003d98:	057a7663          	bgeu	s4,s7,80003de4 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d9c:	000b2483          	lw	s1,0(s6)
    80003da0:	00a9559b          	srliw	a1,s2,0xa
    80003da4:	855a                	mv	a0,s6
    80003da6:	fffff097          	auipc	ra,0xfffff
    80003daa:	7ae080e7          	jalr	1966(ra) # 80003554 <bmap>
    80003dae:	0005059b          	sext.w	a1,a0
    80003db2:	8526                	mv	a0,s1
    80003db4:	fffff097          	auipc	ra,0xfffff
    80003db8:	3ac080e7          	jalr	940(ra) # 80003160 <bread>
    80003dbc:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dbe:	3ff97713          	andi	a4,s2,1023
    80003dc2:	40ed07bb          	subw	a5,s10,a4
    80003dc6:	414b86bb          	subw	a3,s7,s4
    80003dca:	89be                	mv	s3,a5
    80003dcc:	2781                	sext.w	a5,a5
    80003dce:	0006861b          	sext.w	a2,a3
    80003dd2:	f8f674e3          	bgeu	a2,a5,80003d5a <writei+0x4c>
    80003dd6:	89b6                	mv	s3,a3
    80003dd8:	b749                	j	80003d5a <writei+0x4c>
      brelse(bp);
    80003dda:	8526                	mv	a0,s1
    80003ddc:	fffff097          	auipc	ra,0xfffff
    80003de0:	4b4080e7          	jalr	1204(ra) # 80003290 <brelse>
  }

  if(off > ip->size)
    80003de4:	04cb2783          	lw	a5,76(s6)
    80003de8:	0127f463          	bgeu	a5,s2,80003df0 <writei+0xe2>
    ip->size = off;
    80003dec:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003df0:	855a                	mv	a0,s6
    80003df2:	00000097          	auipc	ra,0x0
    80003df6:	aa6080e7          	jalr	-1370(ra) # 80003898 <iupdate>

  return tot;
    80003dfa:	000a051b          	sext.w	a0,s4
}
    80003dfe:	70a6                	ld	ra,104(sp)
    80003e00:	7406                	ld	s0,96(sp)
    80003e02:	64e6                	ld	s1,88(sp)
    80003e04:	6946                	ld	s2,80(sp)
    80003e06:	69a6                	ld	s3,72(sp)
    80003e08:	6a06                	ld	s4,64(sp)
    80003e0a:	7ae2                	ld	s5,56(sp)
    80003e0c:	7b42                	ld	s6,48(sp)
    80003e0e:	7ba2                	ld	s7,40(sp)
    80003e10:	7c02                	ld	s8,32(sp)
    80003e12:	6ce2                	ld	s9,24(sp)
    80003e14:	6d42                	ld	s10,16(sp)
    80003e16:	6da2                	ld	s11,8(sp)
    80003e18:	6165                	addi	sp,sp,112
    80003e1a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e1c:	8a5e                	mv	s4,s7
    80003e1e:	bfc9                	j	80003df0 <writei+0xe2>
    return -1;
    80003e20:	557d                	li	a0,-1
}
    80003e22:	8082                	ret
    return -1;
    80003e24:	557d                	li	a0,-1
    80003e26:	bfe1                	j	80003dfe <writei+0xf0>
    return -1;
    80003e28:	557d                	li	a0,-1
    80003e2a:	bfd1                	j	80003dfe <writei+0xf0>

0000000080003e2c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e2c:	1141                	addi	sp,sp,-16
    80003e2e:	e406                	sd	ra,8(sp)
    80003e30:	e022                	sd	s0,0(sp)
    80003e32:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e34:	4639                	li	a2,14
    80003e36:	ffffd097          	auipc	ra,0xffffd
    80003e3a:	f78080e7          	jalr	-136(ra) # 80000dae <strncmp>
}
    80003e3e:	60a2                	ld	ra,8(sp)
    80003e40:	6402                	ld	s0,0(sp)
    80003e42:	0141                	addi	sp,sp,16
    80003e44:	8082                	ret

0000000080003e46 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e46:	7139                	addi	sp,sp,-64
    80003e48:	fc06                	sd	ra,56(sp)
    80003e4a:	f822                	sd	s0,48(sp)
    80003e4c:	f426                	sd	s1,40(sp)
    80003e4e:	f04a                	sd	s2,32(sp)
    80003e50:	ec4e                	sd	s3,24(sp)
    80003e52:	e852                	sd	s4,16(sp)
    80003e54:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e56:	04451703          	lh	a4,68(a0)
    80003e5a:	4785                	li	a5,1
    80003e5c:	00f71a63          	bne	a4,a5,80003e70 <dirlookup+0x2a>
    80003e60:	892a                	mv	s2,a0
    80003e62:	89ae                	mv	s3,a1
    80003e64:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e66:	457c                	lw	a5,76(a0)
    80003e68:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e6a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e6c:	e79d                	bnez	a5,80003e9a <dirlookup+0x54>
    80003e6e:	a8a5                	j	80003ee6 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e70:	00004517          	auipc	a0,0x4
    80003e74:	79050513          	addi	a0,a0,1936 # 80008600 <syscalls+0x1b0>
    80003e78:	ffffc097          	auipc	ra,0xffffc
    80003e7c:	6b8080e7          	jalr	1720(ra) # 80000530 <panic>
      panic("dirlookup read");
    80003e80:	00004517          	auipc	a0,0x4
    80003e84:	79850513          	addi	a0,a0,1944 # 80008618 <syscalls+0x1c8>
    80003e88:	ffffc097          	auipc	ra,0xffffc
    80003e8c:	6a8080e7          	jalr	1704(ra) # 80000530 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e90:	24c1                	addiw	s1,s1,16
    80003e92:	04c92783          	lw	a5,76(s2)
    80003e96:	04f4f763          	bgeu	s1,a5,80003ee4 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e9a:	4741                	li	a4,16
    80003e9c:	86a6                	mv	a3,s1
    80003e9e:	fc040613          	addi	a2,s0,-64
    80003ea2:	4581                	li	a1,0
    80003ea4:	854a                	mv	a0,s2
    80003ea6:	00000097          	auipc	ra,0x0
    80003eaa:	d70080e7          	jalr	-656(ra) # 80003c16 <readi>
    80003eae:	47c1                	li	a5,16
    80003eb0:	fcf518e3          	bne	a0,a5,80003e80 <dirlookup+0x3a>
    if(de.inum == 0)
    80003eb4:	fc045783          	lhu	a5,-64(s0)
    80003eb8:	dfe1                	beqz	a5,80003e90 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003eba:	fc240593          	addi	a1,s0,-62
    80003ebe:	854e                	mv	a0,s3
    80003ec0:	00000097          	auipc	ra,0x0
    80003ec4:	f6c080e7          	jalr	-148(ra) # 80003e2c <namecmp>
    80003ec8:	f561                	bnez	a0,80003e90 <dirlookup+0x4a>
      if(poff)
    80003eca:	000a0463          	beqz	s4,80003ed2 <dirlookup+0x8c>
        *poff = off;
    80003ece:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ed2:	fc045583          	lhu	a1,-64(s0)
    80003ed6:	00092503          	lw	a0,0(s2)
    80003eda:	fffff097          	auipc	ra,0xfffff
    80003ede:	754080e7          	jalr	1876(ra) # 8000362e <iget>
    80003ee2:	a011                	j	80003ee6 <dirlookup+0xa0>
  return 0;
    80003ee4:	4501                	li	a0,0
}
    80003ee6:	70e2                	ld	ra,56(sp)
    80003ee8:	7442                	ld	s0,48(sp)
    80003eea:	74a2                	ld	s1,40(sp)
    80003eec:	7902                	ld	s2,32(sp)
    80003eee:	69e2                	ld	s3,24(sp)
    80003ef0:	6a42                	ld	s4,16(sp)
    80003ef2:	6121                	addi	sp,sp,64
    80003ef4:	8082                	ret

0000000080003ef6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ef6:	711d                	addi	sp,sp,-96
    80003ef8:	ec86                	sd	ra,88(sp)
    80003efa:	e8a2                	sd	s0,80(sp)
    80003efc:	e4a6                	sd	s1,72(sp)
    80003efe:	e0ca                	sd	s2,64(sp)
    80003f00:	fc4e                	sd	s3,56(sp)
    80003f02:	f852                	sd	s4,48(sp)
    80003f04:	f456                	sd	s5,40(sp)
    80003f06:	f05a                	sd	s6,32(sp)
    80003f08:	ec5e                	sd	s7,24(sp)
    80003f0a:	e862                	sd	s8,16(sp)
    80003f0c:	e466                	sd	s9,8(sp)
    80003f0e:	1080                	addi	s0,sp,96
    80003f10:	84aa                	mv	s1,a0
    80003f12:	8b2e                	mv	s6,a1
    80003f14:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f16:	00054703          	lbu	a4,0(a0)
    80003f1a:	02f00793          	li	a5,47
    80003f1e:	02f70363          	beq	a4,a5,80003f44 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f22:	ffffe097          	auipc	ra,0xffffe
    80003f26:	c84080e7          	jalr	-892(ra) # 80001ba6 <myproc>
    80003f2a:	15053503          	ld	a0,336(a0)
    80003f2e:	00000097          	auipc	ra,0x0
    80003f32:	9f6080e7          	jalr	-1546(ra) # 80003924 <idup>
    80003f36:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f38:	02f00913          	li	s2,47
  len = path - s;
    80003f3c:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f3e:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f40:	4c05                	li	s8,1
    80003f42:	a865                	j	80003ffa <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f44:	4585                	li	a1,1
    80003f46:	4505                	li	a0,1
    80003f48:	fffff097          	auipc	ra,0xfffff
    80003f4c:	6e6080e7          	jalr	1766(ra) # 8000362e <iget>
    80003f50:	89aa                	mv	s3,a0
    80003f52:	b7dd                	j	80003f38 <namex+0x42>
      iunlockput(ip);
    80003f54:	854e                	mv	a0,s3
    80003f56:	00000097          	auipc	ra,0x0
    80003f5a:	c6e080e7          	jalr	-914(ra) # 80003bc4 <iunlockput>
      return 0;
    80003f5e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f60:	854e                	mv	a0,s3
    80003f62:	60e6                	ld	ra,88(sp)
    80003f64:	6446                	ld	s0,80(sp)
    80003f66:	64a6                	ld	s1,72(sp)
    80003f68:	6906                	ld	s2,64(sp)
    80003f6a:	79e2                	ld	s3,56(sp)
    80003f6c:	7a42                	ld	s4,48(sp)
    80003f6e:	7aa2                	ld	s5,40(sp)
    80003f70:	7b02                	ld	s6,32(sp)
    80003f72:	6be2                	ld	s7,24(sp)
    80003f74:	6c42                	ld	s8,16(sp)
    80003f76:	6ca2                	ld	s9,8(sp)
    80003f78:	6125                	addi	sp,sp,96
    80003f7a:	8082                	ret
      iunlock(ip);
    80003f7c:	854e                	mv	a0,s3
    80003f7e:	00000097          	auipc	ra,0x0
    80003f82:	aa6080e7          	jalr	-1370(ra) # 80003a24 <iunlock>
      return ip;
    80003f86:	bfe9                	j	80003f60 <namex+0x6a>
      iunlockput(ip);
    80003f88:	854e                	mv	a0,s3
    80003f8a:	00000097          	auipc	ra,0x0
    80003f8e:	c3a080e7          	jalr	-966(ra) # 80003bc4 <iunlockput>
      return 0;
    80003f92:	89d2                	mv	s3,s4
    80003f94:	b7f1                	j	80003f60 <namex+0x6a>
  len = path - s;
    80003f96:	40b48633          	sub	a2,s1,a1
    80003f9a:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003f9e:	094cd463          	bge	s9,s4,80004026 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003fa2:	4639                	li	a2,14
    80003fa4:	8556                	mv	a0,s5
    80003fa6:	ffffd097          	auipc	ra,0xffffd
    80003faa:	d8c080e7          	jalr	-628(ra) # 80000d32 <memmove>
  while(*path == '/')
    80003fae:	0004c783          	lbu	a5,0(s1)
    80003fb2:	01279763          	bne	a5,s2,80003fc0 <namex+0xca>
    path++;
    80003fb6:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fb8:	0004c783          	lbu	a5,0(s1)
    80003fbc:	ff278de3          	beq	a5,s2,80003fb6 <namex+0xc0>
    ilock(ip);
    80003fc0:	854e                	mv	a0,s3
    80003fc2:	00000097          	auipc	ra,0x0
    80003fc6:	9a0080e7          	jalr	-1632(ra) # 80003962 <ilock>
    if(ip->type != T_DIR){
    80003fca:	04499783          	lh	a5,68(s3)
    80003fce:	f98793e3          	bne	a5,s8,80003f54 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003fd2:	000b0563          	beqz	s6,80003fdc <namex+0xe6>
    80003fd6:	0004c783          	lbu	a5,0(s1)
    80003fda:	d3cd                	beqz	a5,80003f7c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003fdc:	865e                	mv	a2,s7
    80003fde:	85d6                	mv	a1,s5
    80003fe0:	854e                	mv	a0,s3
    80003fe2:	00000097          	auipc	ra,0x0
    80003fe6:	e64080e7          	jalr	-412(ra) # 80003e46 <dirlookup>
    80003fea:	8a2a                	mv	s4,a0
    80003fec:	dd51                	beqz	a0,80003f88 <namex+0x92>
    iunlockput(ip);
    80003fee:	854e                	mv	a0,s3
    80003ff0:	00000097          	auipc	ra,0x0
    80003ff4:	bd4080e7          	jalr	-1068(ra) # 80003bc4 <iunlockput>
    ip = next;
    80003ff8:	89d2                	mv	s3,s4
  while(*path == '/')
    80003ffa:	0004c783          	lbu	a5,0(s1)
    80003ffe:	05279763          	bne	a5,s2,8000404c <namex+0x156>
    path++;
    80004002:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004004:	0004c783          	lbu	a5,0(s1)
    80004008:	ff278de3          	beq	a5,s2,80004002 <namex+0x10c>
  if(*path == 0)
    8000400c:	c79d                	beqz	a5,8000403a <namex+0x144>
    path++;
    8000400e:	85a6                	mv	a1,s1
  len = path - s;
    80004010:	8a5e                	mv	s4,s7
    80004012:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004014:	01278963          	beq	a5,s2,80004026 <namex+0x130>
    80004018:	dfbd                	beqz	a5,80003f96 <namex+0xa0>
    path++;
    8000401a:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000401c:	0004c783          	lbu	a5,0(s1)
    80004020:	ff279ce3          	bne	a5,s2,80004018 <namex+0x122>
    80004024:	bf8d                	j	80003f96 <namex+0xa0>
    memmove(name, s, len);
    80004026:	2601                	sext.w	a2,a2
    80004028:	8556                	mv	a0,s5
    8000402a:	ffffd097          	auipc	ra,0xffffd
    8000402e:	d08080e7          	jalr	-760(ra) # 80000d32 <memmove>
    name[len] = 0;
    80004032:	9a56                	add	s4,s4,s5
    80004034:	000a0023          	sb	zero,0(s4)
    80004038:	bf9d                	j	80003fae <namex+0xb8>
  if(nameiparent){
    8000403a:	f20b03e3          	beqz	s6,80003f60 <namex+0x6a>
    iput(ip);
    8000403e:	854e                	mv	a0,s3
    80004040:	00000097          	auipc	ra,0x0
    80004044:	adc080e7          	jalr	-1316(ra) # 80003b1c <iput>
    return 0;
    80004048:	4981                	li	s3,0
    8000404a:	bf19                	j	80003f60 <namex+0x6a>
  if(*path == 0)
    8000404c:	d7fd                	beqz	a5,8000403a <namex+0x144>
  while(*path != '/' && *path != 0)
    8000404e:	0004c783          	lbu	a5,0(s1)
    80004052:	85a6                	mv	a1,s1
    80004054:	b7d1                	j	80004018 <namex+0x122>

0000000080004056 <dirlink>:
{
    80004056:	7139                	addi	sp,sp,-64
    80004058:	fc06                	sd	ra,56(sp)
    8000405a:	f822                	sd	s0,48(sp)
    8000405c:	f426                	sd	s1,40(sp)
    8000405e:	f04a                	sd	s2,32(sp)
    80004060:	ec4e                	sd	s3,24(sp)
    80004062:	e852                	sd	s4,16(sp)
    80004064:	0080                	addi	s0,sp,64
    80004066:	892a                	mv	s2,a0
    80004068:	8a2e                	mv	s4,a1
    8000406a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000406c:	4601                	li	a2,0
    8000406e:	00000097          	auipc	ra,0x0
    80004072:	dd8080e7          	jalr	-552(ra) # 80003e46 <dirlookup>
    80004076:	e93d                	bnez	a0,800040ec <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004078:	04c92483          	lw	s1,76(s2)
    8000407c:	c49d                	beqz	s1,800040aa <dirlink+0x54>
    8000407e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004080:	4741                	li	a4,16
    80004082:	86a6                	mv	a3,s1
    80004084:	fc040613          	addi	a2,s0,-64
    80004088:	4581                	li	a1,0
    8000408a:	854a                	mv	a0,s2
    8000408c:	00000097          	auipc	ra,0x0
    80004090:	b8a080e7          	jalr	-1142(ra) # 80003c16 <readi>
    80004094:	47c1                	li	a5,16
    80004096:	06f51163          	bne	a0,a5,800040f8 <dirlink+0xa2>
    if(de.inum == 0)
    8000409a:	fc045783          	lhu	a5,-64(s0)
    8000409e:	c791                	beqz	a5,800040aa <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040a0:	24c1                	addiw	s1,s1,16
    800040a2:	04c92783          	lw	a5,76(s2)
    800040a6:	fcf4ede3          	bltu	s1,a5,80004080 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040aa:	4639                	li	a2,14
    800040ac:	85d2                	mv	a1,s4
    800040ae:	fc240513          	addi	a0,s0,-62
    800040b2:	ffffd097          	auipc	ra,0xffffd
    800040b6:	d38080e7          	jalr	-712(ra) # 80000dea <strncpy>
  de.inum = inum;
    800040ba:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040be:	4741                	li	a4,16
    800040c0:	86a6                	mv	a3,s1
    800040c2:	fc040613          	addi	a2,s0,-64
    800040c6:	4581                	li	a1,0
    800040c8:	854a                	mv	a0,s2
    800040ca:	00000097          	auipc	ra,0x0
    800040ce:	c44080e7          	jalr	-956(ra) # 80003d0e <writei>
    800040d2:	872a                	mv	a4,a0
    800040d4:	47c1                	li	a5,16
  return 0;
    800040d6:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040d8:	02f71863          	bne	a4,a5,80004108 <dirlink+0xb2>
}
    800040dc:	70e2                	ld	ra,56(sp)
    800040de:	7442                	ld	s0,48(sp)
    800040e0:	74a2                	ld	s1,40(sp)
    800040e2:	7902                	ld	s2,32(sp)
    800040e4:	69e2                	ld	s3,24(sp)
    800040e6:	6a42                	ld	s4,16(sp)
    800040e8:	6121                	addi	sp,sp,64
    800040ea:	8082                	ret
    iput(ip);
    800040ec:	00000097          	auipc	ra,0x0
    800040f0:	a30080e7          	jalr	-1488(ra) # 80003b1c <iput>
    return -1;
    800040f4:	557d                	li	a0,-1
    800040f6:	b7dd                	j	800040dc <dirlink+0x86>
      panic("dirlink read");
    800040f8:	00004517          	auipc	a0,0x4
    800040fc:	53050513          	addi	a0,a0,1328 # 80008628 <syscalls+0x1d8>
    80004100:	ffffc097          	auipc	ra,0xffffc
    80004104:	430080e7          	jalr	1072(ra) # 80000530 <panic>
    panic("dirlink");
    80004108:	00004517          	auipc	a0,0x4
    8000410c:	63050513          	addi	a0,a0,1584 # 80008738 <syscalls+0x2e8>
    80004110:	ffffc097          	auipc	ra,0xffffc
    80004114:	420080e7          	jalr	1056(ra) # 80000530 <panic>

0000000080004118 <namei>:

struct inode*
namei(char *path)
{
    80004118:	1101                	addi	sp,sp,-32
    8000411a:	ec06                	sd	ra,24(sp)
    8000411c:	e822                	sd	s0,16(sp)
    8000411e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004120:	fe040613          	addi	a2,s0,-32
    80004124:	4581                	li	a1,0
    80004126:	00000097          	auipc	ra,0x0
    8000412a:	dd0080e7          	jalr	-560(ra) # 80003ef6 <namex>
}
    8000412e:	60e2                	ld	ra,24(sp)
    80004130:	6442                	ld	s0,16(sp)
    80004132:	6105                	addi	sp,sp,32
    80004134:	8082                	ret

0000000080004136 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004136:	1141                	addi	sp,sp,-16
    80004138:	e406                	sd	ra,8(sp)
    8000413a:	e022                	sd	s0,0(sp)
    8000413c:	0800                	addi	s0,sp,16
    8000413e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004140:	4585                	li	a1,1
    80004142:	00000097          	auipc	ra,0x0
    80004146:	db4080e7          	jalr	-588(ra) # 80003ef6 <namex>
}
    8000414a:	60a2                	ld	ra,8(sp)
    8000414c:	6402                	ld	s0,0(sp)
    8000414e:	0141                	addi	sp,sp,16
    80004150:	8082                	ret

0000000080004152 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004152:	1101                	addi	sp,sp,-32
    80004154:	ec06                	sd	ra,24(sp)
    80004156:	e822                	sd	s0,16(sp)
    80004158:	e426                	sd	s1,8(sp)
    8000415a:	e04a                	sd	s2,0(sp)
    8000415c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000415e:	0001d917          	auipc	s2,0x1d
    80004162:	7fa90913          	addi	s2,s2,2042 # 80021958 <log>
    80004166:	01892583          	lw	a1,24(s2)
    8000416a:	02892503          	lw	a0,40(s2)
    8000416e:	fffff097          	auipc	ra,0xfffff
    80004172:	ff2080e7          	jalr	-14(ra) # 80003160 <bread>
    80004176:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004178:	02c92683          	lw	a3,44(s2)
    8000417c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000417e:	02d05763          	blez	a3,800041ac <write_head+0x5a>
    80004182:	0001e797          	auipc	a5,0x1e
    80004186:	80678793          	addi	a5,a5,-2042 # 80021988 <log+0x30>
    8000418a:	05c50713          	addi	a4,a0,92
    8000418e:	36fd                	addiw	a3,a3,-1
    80004190:	1682                	slli	a3,a3,0x20
    80004192:	9281                	srli	a3,a3,0x20
    80004194:	068a                	slli	a3,a3,0x2
    80004196:	0001d617          	auipc	a2,0x1d
    8000419a:	7f660613          	addi	a2,a2,2038 # 8002198c <log+0x34>
    8000419e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041a0:	4390                	lw	a2,0(a5)
    800041a2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041a4:	0791                	addi	a5,a5,4
    800041a6:	0711                	addi	a4,a4,4
    800041a8:	fed79ce3          	bne	a5,a3,800041a0 <write_head+0x4e>
  }
  bwrite(buf);
    800041ac:	8526                	mv	a0,s1
    800041ae:	fffff097          	auipc	ra,0xfffff
    800041b2:	0a4080e7          	jalr	164(ra) # 80003252 <bwrite>
  brelse(buf);
    800041b6:	8526                	mv	a0,s1
    800041b8:	fffff097          	auipc	ra,0xfffff
    800041bc:	0d8080e7          	jalr	216(ra) # 80003290 <brelse>
}
    800041c0:	60e2                	ld	ra,24(sp)
    800041c2:	6442                	ld	s0,16(sp)
    800041c4:	64a2                	ld	s1,8(sp)
    800041c6:	6902                	ld	s2,0(sp)
    800041c8:	6105                	addi	sp,sp,32
    800041ca:	8082                	ret

00000000800041cc <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041cc:	0001d797          	auipc	a5,0x1d
    800041d0:	7b87a783          	lw	a5,1976(a5) # 80021984 <log+0x2c>
    800041d4:	0af05d63          	blez	a5,8000428e <install_trans+0xc2>
{
    800041d8:	7139                	addi	sp,sp,-64
    800041da:	fc06                	sd	ra,56(sp)
    800041dc:	f822                	sd	s0,48(sp)
    800041de:	f426                	sd	s1,40(sp)
    800041e0:	f04a                	sd	s2,32(sp)
    800041e2:	ec4e                	sd	s3,24(sp)
    800041e4:	e852                	sd	s4,16(sp)
    800041e6:	e456                	sd	s5,8(sp)
    800041e8:	e05a                	sd	s6,0(sp)
    800041ea:	0080                	addi	s0,sp,64
    800041ec:	8b2a                	mv	s6,a0
    800041ee:	0001da97          	auipc	s5,0x1d
    800041f2:	79aa8a93          	addi	s5,s5,1946 # 80021988 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041f6:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041f8:	0001d997          	auipc	s3,0x1d
    800041fc:	76098993          	addi	s3,s3,1888 # 80021958 <log>
    80004200:	a035                	j	8000422c <install_trans+0x60>
      bunpin(dbuf);
    80004202:	8526                	mv	a0,s1
    80004204:	fffff097          	auipc	ra,0xfffff
    80004208:	166080e7          	jalr	358(ra) # 8000336a <bunpin>
    brelse(lbuf);
    8000420c:	854a                	mv	a0,s2
    8000420e:	fffff097          	auipc	ra,0xfffff
    80004212:	082080e7          	jalr	130(ra) # 80003290 <brelse>
    brelse(dbuf);
    80004216:	8526                	mv	a0,s1
    80004218:	fffff097          	auipc	ra,0xfffff
    8000421c:	078080e7          	jalr	120(ra) # 80003290 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004220:	2a05                	addiw	s4,s4,1
    80004222:	0a91                	addi	s5,s5,4
    80004224:	02c9a783          	lw	a5,44(s3)
    80004228:	04fa5963          	bge	s4,a5,8000427a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000422c:	0189a583          	lw	a1,24(s3)
    80004230:	014585bb          	addw	a1,a1,s4
    80004234:	2585                	addiw	a1,a1,1
    80004236:	0289a503          	lw	a0,40(s3)
    8000423a:	fffff097          	auipc	ra,0xfffff
    8000423e:	f26080e7          	jalr	-218(ra) # 80003160 <bread>
    80004242:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004244:	000aa583          	lw	a1,0(s5)
    80004248:	0289a503          	lw	a0,40(s3)
    8000424c:	fffff097          	auipc	ra,0xfffff
    80004250:	f14080e7          	jalr	-236(ra) # 80003160 <bread>
    80004254:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004256:	40000613          	li	a2,1024
    8000425a:	05890593          	addi	a1,s2,88
    8000425e:	05850513          	addi	a0,a0,88
    80004262:	ffffd097          	auipc	ra,0xffffd
    80004266:	ad0080e7          	jalr	-1328(ra) # 80000d32 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000426a:	8526                	mv	a0,s1
    8000426c:	fffff097          	auipc	ra,0xfffff
    80004270:	fe6080e7          	jalr	-26(ra) # 80003252 <bwrite>
    if(recovering == 0)
    80004274:	f80b1ce3          	bnez	s6,8000420c <install_trans+0x40>
    80004278:	b769                	j	80004202 <install_trans+0x36>
}
    8000427a:	70e2                	ld	ra,56(sp)
    8000427c:	7442                	ld	s0,48(sp)
    8000427e:	74a2                	ld	s1,40(sp)
    80004280:	7902                	ld	s2,32(sp)
    80004282:	69e2                	ld	s3,24(sp)
    80004284:	6a42                	ld	s4,16(sp)
    80004286:	6aa2                	ld	s5,8(sp)
    80004288:	6b02                	ld	s6,0(sp)
    8000428a:	6121                	addi	sp,sp,64
    8000428c:	8082                	ret
    8000428e:	8082                	ret

0000000080004290 <initlog>:
{
    80004290:	7179                	addi	sp,sp,-48
    80004292:	f406                	sd	ra,40(sp)
    80004294:	f022                	sd	s0,32(sp)
    80004296:	ec26                	sd	s1,24(sp)
    80004298:	e84a                	sd	s2,16(sp)
    8000429a:	e44e                	sd	s3,8(sp)
    8000429c:	1800                	addi	s0,sp,48
    8000429e:	892a                	mv	s2,a0
    800042a0:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042a2:	0001d497          	auipc	s1,0x1d
    800042a6:	6b648493          	addi	s1,s1,1718 # 80021958 <log>
    800042aa:	00004597          	auipc	a1,0x4
    800042ae:	38e58593          	addi	a1,a1,910 # 80008638 <syscalls+0x1e8>
    800042b2:	8526                	mv	a0,s1
    800042b4:	ffffd097          	auipc	ra,0xffffd
    800042b8:	892080e7          	jalr	-1902(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    800042bc:	0149a583          	lw	a1,20(s3)
    800042c0:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042c2:	0109a783          	lw	a5,16(s3)
    800042c6:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042c8:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042cc:	854a                	mv	a0,s2
    800042ce:	fffff097          	auipc	ra,0xfffff
    800042d2:	e92080e7          	jalr	-366(ra) # 80003160 <bread>
  log.lh.n = lh->n;
    800042d6:	4d3c                	lw	a5,88(a0)
    800042d8:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042da:	02f05563          	blez	a5,80004304 <initlog+0x74>
    800042de:	05c50713          	addi	a4,a0,92
    800042e2:	0001d697          	auipc	a3,0x1d
    800042e6:	6a668693          	addi	a3,a3,1702 # 80021988 <log+0x30>
    800042ea:	37fd                	addiw	a5,a5,-1
    800042ec:	1782                	slli	a5,a5,0x20
    800042ee:	9381                	srli	a5,a5,0x20
    800042f0:	078a                	slli	a5,a5,0x2
    800042f2:	06050613          	addi	a2,a0,96
    800042f6:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800042f8:	4310                	lw	a2,0(a4)
    800042fa:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800042fc:	0711                	addi	a4,a4,4
    800042fe:	0691                	addi	a3,a3,4
    80004300:	fef71ce3          	bne	a4,a5,800042f8 <initlog+0x68>
  brelse(buf);
    80004304:	fffff097          	auipc	ra,0xfffff
    80004308:	f8c080e7          	jalr	-116(ra) # 80003290 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000430c:	4505                	li	a0,1
    8000430e:	00000097          	auipc	ra,0x0
    80004312:	ebe080e7          	jalr	-322(ra) # 800041cc <install_trans>
  log.lh.n = 0;
    80004316:	0001d797          	auipc	a5,0x1d
    8000431a:	6607a723          	sw	zero,1646(a5) # 80021984 <log+0x2c>
  write_head(); // clear the log
    8000431e:	00000097          	auipc	ra,0x0
    80004322:	e34080e7          	jalr	-460(ra) # 80004152 <write_head>
}
    80004326:	70a2                	ld	ra,40(sp)
    80004328:	7402                	ld	s0,32(sp)
    8000432a:	64e2                	ld	s1,24(sp)
    8000432c:	6942                	ld	s2,16(sp)
    8000432e:	69a2                	ld	s3,8(sp)
    80004330:	6145                	addi	sp,sp,48
    80004332:	8082                	ret

0000000080004334 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004334:	1101                	addi	sp,sp,-32
    80004336:	ec06                	sd	ra,24(sp)
    80004338:	e822                	sd	s0,16(sp)
    8000433a:	e426                	sd	s1,8(sp)
    8000433c:	e04a                	sd	s2,0(sp)
    8000433e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004340:	0001d517          	auipc	a0,0x1d
    80004344:	61850513          	addi	a0,a0,1560 # 80021958 <log>
    80004348:	ffffd097          	auipc	ra,0xffffd
    8000434c:	88e080e7          	jalr	-1906(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004350:	0001d497          	auipc	s1,0x1d
    80004354:	60848493          	addi	s1,s1,1544 # 80021958 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004358:	4979                	li	s2,30
    8000435a:	a039                	j	80004368 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000435c:	85a6                	mv	a1,s1
    8000435e:	8526                	mv	a0,s1
    80004360:	ffffe097          	auipc	ra,0xffffe
    80004364:	fb0080e7          	jalr	-80(ra) # 80002310 <sleep>
    if(log.committing){
    80004368:	50dc                	lw	a5,36(s1)
    8000436a:	fbed                	bnez	a5,8000435c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000436c:	509c                	lw	a5,32(s1)
    8000436e:	0017871b          	addiw	a4,a5,1
    80004372:	0007069b          	sext.w	a3,a4
    80004376:	0027179b          	slliw	a5,a4,0x2
    8000437a:	9fb9                	addw	a5,a5,a4
    8000437c:	0017979b          	slliw	a5,a5,0x1
    80004380:	54d8                	lw	a4,44(s1)
    80004382:	9fb9                	addw	a5,a5,a4
    80004384:	00f95963          	bge	s2,a5,80004396 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004388:	85a6                	mv	a1,s1
    8000438a:	8526                	mv	a0,s1
    8000438c:	ffffe097          	auipc	ra,0xffffe
    80004390:	f84080e7          	jalr	-124(ra) # 80002310 <sleep>
    80004394:	bfd1                	j	80004368 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004396:	0001d517          	auipc	a0,0x1d
    8000439a:	5c250513          	addi	a0,a0,1474 # 80021958 <log>
    8000439e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800043a0:	ffffd097          	auipc	ra,0xffffd
    800043a4:	8ea080e7          	jalr	-1814(ra) # 80000c8a <release>
      break;
    }
  }
}
    800043a8:	60e2                	ld	ra,24(sp)
    800043aa:	6442                	ld	s0,16(sp)
    800043ac:	64a2                	ld	s1,8(sp)
    800043ae:	6902                	ld	s2,0(sp)
    800043b0:	6105                	addi	sp,sp,32
    800043b2:	8082                	ret

00000000800043b4 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043b4:	7139                	addi	sp,sp,-64
    800043b6:	fc06                	sd	ra,56(sp)
    800043b8:	f822                	sd	s0,48(sp)
    800043ba:	f426                	sd	s1,40(sp)
    800043bc:	f04a                	sd	s2,32(sp)
    800043be:	ec4e                	sd	s3,24(sp)
    800043c0:	e852                	sd	s4,16(sp)
    800043c2:	e456                	sd	s5,8(sp)
    800043c4:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043c6:	0001d497          	auipc	s1,0x1d
    800043ca:	59248493          	addi	s1,s1,1426 # 80021958 <log>
    800043ce:	8526                	mv	a0,s1
    800043d0:	ffffd097          	auipc	ra,0xffffd
    800043d4:	806080e7          	jalr	-2042(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800043d8:	509c                	lw	a5,32(s1)
    800043da:	37fd                	addiw	a5,a5,-1
    800043dc:	0007891b          	sext.w	s2,a5
    800043e0:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043e2:	50dc                	lw	a5,36(s1)
    800043e4:	efb9                	bnez	a5,80004442 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043e6:	06091663          	bnez	s2,80004452 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800043ea:	0001d497          	auipc	s1,0x1d
    800043ee:	56e48493          	addi	s1,s1,1390 # 80021958 <log>
    800043f2:	4785                	li	a5,1
    800043f4:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043f6:	8526                	mv	a0,s1
    800043f8:	ffffd097          	auipc	ra,0xffffd
    800043fc:	892080e7          	jalr	-1902(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004400:	54dc                	lw	a5,44(s1)
    80004402:	06f04763          	bgtz	a5,80004470 <end_op+0xbc>
    acquire(&log.lock);
    80004406:	0001d497          	auipc	s1,0x1d
    8000440a:	55248493          	addi	s1,s1,1362 # 80021958 <log>
    8000440e:	8526                	mv	a0,s1
    80004410:	ffffc097          	auipc	ra,0xffffc
    80004414:	7c6080e7          	jalr	1990(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004418:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000441c:	8526                	mv	a0,s1
    8000441e:	ffffe097          	auipc	ra,0xffffe
    80004422:	078080e7          	jalr	120(ra) # 80002496 <wakeup>
    release(&log.lock);
    80004426:	8526                	mv	a0,s1
    80004428:	ffffd097          	auipc	ra,0xffffd
    8000442c:	862080e7          	jalr	-1950(ra) # 80000c8a <release>
}
    80004430:	70e2                	ld	ra,56(sp)
    80004432:	7442                	ld	s0,48(sp)
    80004434:	74a2                	ld	s1,40(sp)
    80004436:	7902                	ld	s2,32(sp)
    80004438:	69e2                	ld	s3,24(sp)
    8000443a:	6a42                	ld	s4,16(sp)
    8000443c:	6aa2                	ld	s5,8(sp)
    8000443e:	6121                	addi	sp,sp,64
    80004440:	8082                	ret
    panic("log.committing");
    80004442:	00004517          	auipc	a0,0x4
    80004446:	1fe50513          	addi	a0,a0,510 # 80008640 <syscalls+0x1f0>
    8000444a:	ffffc097          	auipc	ra,0xffffc
    8000444e:	0e6080e7          	jalr	230(ra) # 80000530 <panic>
    wakeup(&log);
    80004452:	0001d497          	auipc	s1,0x1d
    80004456:	50648493          	addi	s1,s1,1286 # 80021958 <log>
    8000445a:	8526                	mv	a0,s1
    8000445c:	ffffe097          	auipc	ra,0xffffe
    80004460:	03a080e7          	jalr	58(ra) # 80002496 <wakeup>
  release(&log.lock);
    80004464:	8526                	mv	a0,s1
    80004466:	ffffd097          	auipc	ra,0xffffd
    8000446a:	824080e7          	jalr	-2012(ra) # 80000c8a <release>
  if(do_commit){
    8000446e:	b7c9                	j	80004430 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004470:	0001da97          	auipc	s5,0x1d
    80004474:	518a8a93          	addi	s5,s5,1304 # 80021988 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004478:	0001da17          	auipc	s4,0x1d
    8000447c:	4e0a0a13          	addi	s4,s4,1248 # 80021958 <log>
    80004480:	018a2583          	lw	a1,24(s4)
    80004484:	012585bb          	addw	a1,a1,s2
    80004488:	2585                	addiw	a1,a1,1
    8000448a:	028a2503          	lw	a0,40(s4)
    8000448e:	fffff097          	auipc	ra,0xfffff
    80004492:	cd2080e7          	jalr	-814(ra) # 80003160 <bread>
    80004496:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004498:	000aa583          	lw	a1,0(s5)
    8000449c:	028a2503          	lw	a0,40(s4)
    800044a0:	fffff097          	auipc	ra,0xfffff
    800044a4:	cc0080e7          	jalr	-832(ra) # 80003160 <bread>
    800044a8:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044aa:	40000613          	li	a2,1024
    800044ae:	05850593          	addi	a1,a0,88
    800044b2:	05848513          	addi	a0,s1,88
    800044b6:	ffffd097          	auipc	ra,0xffffd
    800044ba:	87c080e7          	jalr	-1924(ra) # 80000d32 <memmove>
    bwrite(to);  // write the log
    800044be:	8526                	mv	a0,s1
    800044c0:	fffff097          	auipc	ra,0xfffff
    800044c4:	d92080e7          	jalr	-622(ra) # 80003252 <bwrite>
    brelse(from);
    800044c8:	854e                	mv	a0,s3
    800044ca:	fffff097          	auipc	ra,0xfffff
    800044ce:	dc6080e7          	jalr	-570(ra) # 80003290 <brelse>
    brelse(to);
    800044d2:	8526                	mv	a0,s1
    800044d4:	fffff097          	auipc	ra,0xfffff
    800044d8:	dbc080e7          	jalr	-580(ra) # 80003290 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044dc:	2905                	addiw	s2,s2,1
    800044de:	0a91                	addi	s5,s5,4
    800044e0:	02ca2783          	lw	a5,44(s4)
    800044e4:	f8f94ee3          	blt	s2,a5,80004480 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044e8:	00000097          	auipc	ra,0x0
    800044ec:	c6a080e7          	jalr	-918(ra) # 80004152 <write_head>
    install_trans(0); // Now install writes to home locations
    800044f0:	4501                	li	a0,0
    800044f2:	00000097          	auipc	ra,0x0
    800044f6:	cda080e7          	jalr	-806(ra) # 800041cc <install_trans>
    log.lh.n = 0;
    800044fa:	0001d797          	auipc	a5,0x1d
    800044fe:	4807a523          	sw	zero,1162(a5) # 80021984 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004502:	00000097          	auipc	ra,0x0
    80004506:	c50080e7          	jalr	-944(ra) # 80004152 <write_head>
    8000450a:	bdf5                	j	80004406 <end_op+0x52>

000000008000450c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000450c:	1101                	addi	sp,sp,-32
    8000450e:	ec06                	sd	ra,24(sp)
    80004510:	e822                	sd	s0,16(sp)
    80004512:	e426                	sd	s1,8(sp)
    80004514:	e04a                	sd	s2,0(sp)
    80004516:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004518:	0001d717          	auipc	a4,0x1d
    8000451c:	46c72703          	lw	a4,1132(a4) # 80021984 <log+0x2c>
    80004520:	47f5                	li	a5,29
    80004522:	08e7c063          	blt	a5,a4,800045a2 <log_write+0x96>
    80004526:	84aa                	mv	s1,a0
    80004528:	0001d797          	auipc	a5,0x1d
    8000452c:	44c7a783          	lw	a5,1100(a5) # 80021974 <log+0x1c>
    80004530:	37fd                	addiw	a5,a5,-1
    80004532:	06f75863          	bge	a4,a5,800045a2 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004536:	0001d797          	auipc	a5,0x1d
    8000453a:	4427a783          	lw	a5,1090(a5) # 80021978 <log+0x20>
    8000453e:	06f05a63          	blez	a5,800045b2 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004542:	0001d917          	auipc	s2,0x1d
    80004546:	41690913          	addi	s2,s2,1046 # 80021958 <log>
    8000454a:	854a                	mv	a0,s2
    8000454c:	ffffc097          	auipc	ra,0xffffc
    80004550:	68a080e7          	jalr	1674(ra) # 80000bd6 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004554:	02c92603          	lw	a2,44(s2)
    80004558:	06c05563          	blez	a2,800045c2 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000455c:	44cc                	lw	a1,12(s1)
    8000455e:	0001d717          	auipc	a4,0x1d
    80004562:	42a70713          	addi	a4,a4,1066 # 80021988 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004566:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004568:	4314                	lw	a3,0(a4)
    8000456a:	04b68d63          	beq	a3,a1,800045c4 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000456e:	2785                	addiw	a5,a5,1
    80004570:	0711                	addi	a4,a4,4
    80004572:	fec79be3          	bne	a5,a2,80004568 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004576:	0621                	addi	a2,a2,8
    80004578:	060a                	slli	a2,a2,0x2
    8000457a:	0001d797          	auipc	a5,0x1d
    8000457e:	3de78793          	addi	a5,a5,990 # 80021958 <log>
    80004582:	963e                	add	a2,a2,a5
    80004584:	44dc                	lw	a5,12(s1)
    80004586:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004588:	8526                	mv	a0,s1
    8000458a:	fffff097          	auipc	ra,0xfffff
    8000458e:	da4080e7          	jalr	-604(ra) # 8000332e <bpin>
    log.lh.n++;
    80004592:	0001d717          	auipc	a4,0x1d
    80004596:	3c670713          	addi	a4,a4,966 # 80021958 <log>
    8000459a:	575c                	lw	a5,44(a4)
    8000459c:	2785                	addiw	a5,a5,1
    8000459e:	d75c                	sw	a5,44(a4)
    800045a0:	a83d                	j	800045de <log_write+0xd2>
    panic("too big a transaction");
    800045a2:	00004517          	auipc	a0,0x4
    800045a6:	0ae50513          	addi	a0,a0,174 # 80008650 <syscalls+0x200>
    800045aa:	ffffc097          	auipc	ra,0xffffc
    800045ae:	f86080e7          	jalr	-122(ra) # 80000530 <panic>
    panic("log_write outside of trans");
    800045b2:	00004517          	auipc	a0,0x4
    800045b6:	0b650513          	addi	a0,a0,182 # 80008668 <syscalls+0x218>
    800045ba:	ffffc097          	auipc	ra,0xffffc
    800045be:	f76080e7          	jalr	-138(ra) # 80000530 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800045c2:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800045c4:	00878713          	addi	a4,a5,8
    800045c8:	00271693          	slli	a3,a4,0x2
    800045cc:	0001d717          	auipc	a4,0x1d
    800045d0:	38c70713          	addi	a4,a4,908 # 80021958 <log>
    800045d4:	9736                	add	a4,a4,a3
    800045d6:	44d4                	lw	a3,12(s1)
    800045d8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045da:	faf607e3          	beq	a2,a5,80004588 <log_write+0x7c>
  }
  release(&log.lock);
    800045de:	0001d517          	auipc	a0,0x1d
    800045e2:	37a50513          	addi	a0,a0,890 # 80021958 <log>
    800045e6:	ffffc097          	auipc	ra,0xffffc
    800045ea:	6a4080e7          	jalr	1700(ra) # 80000c8a <release>
}
    800045ee:	60e2                	ld	ra,24(sp)
    800045f0:	6442                	ld	s0,16(sp)
    800045f2:	64a2                	ld	s1,8(sp)
    800045f4:	6902                	ld	s2,0(sp)
    800045f6:	6105                	addi	sp,sp,32
    800045f8:	8082                	ret

00000000800045fa <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045fa:	1101                	addi	sp,sp,-32
    800045fc:	ec06                	sd	ra,24(sp)
    800045fe:	e822                	sd	s0,16(sp)
    80004600:	e426                	sd	s1,8(sp)
    80004602:	e04a                	sd	s2,0(sp)
    80004604:	1000                	addi	s0,sp,32
    80004606:	84aa                	mv	s1,a0
    80004608:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000460a:	00004597          	auipc	a1,0x4
    8000460e:	07e58593          	addi	a1,a1,126 # 80008688 <syscalls+0x238>
    80004612:	0521                	addi	a0,a0,8
    80004614:	ffffc097          	auipc	ra,0xffffc
    80004618:	532080e7          	jalr	1330(ra) # 80000b46 <initlock>
  lk->name = name;
    8000461c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004620:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004624:	0204a423          	sw	zero,40(s1)
}
    80004628:	60e2                	ld	ra,24(sp)
    8000462a:	6442                	ld	s0,16(sp)
    8000462c:	64a2                	ld	s1,8(sp)
    8000462e:	6902                	ld	s2,0(sp)
    80004630:	6105                	addi	sp,sp,32
    80004632:	8082                	ret

0000000080004634 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004634:	1101                	addi	sp,sp,-32
    80004636:	ec06                	sd	ra,24(sp)
    80004638:	e822                	sd	s0,16(sp)
    8000463a:	e426                	sd	s1,8(sp)
    8000463c:	e04a                	sd	s2,0(sp)
    8000463e:	1000                	addi	s0,sp,32
    80004640:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004642:	00850913          	addi	s2,a0,8
    80004646:	854a                	mv	a0,s2
    80004648:	ffffc097          	auipc	ra,0xffffc
    8000464c:	58e080e7          	jalr	1422(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004650:	409c                	lw	a5,0(s1)
    80004652:	cb89                	beqz	a5,80004664 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004654:	85ca                	mv	a1,s2
    80004656:	8526                	mv	a0,s1
    80004658:	ffffe097          	auipc	ra,0xffffe
    8000465c:	cb8080e7          	jalr	-840(ra) # 80002310 <sleep>
  while (lk->locked) {
    80004660:	409c                	lw	a5,0(s1)
    80004662:	fbed                	bnez	a5,80004654 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004664:	4785                	li	a5,1
    80004666:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004668:	ffffd097          	auipc	ra,0xffffd
    8000466c:	53e080e7          	jalr	1342(ra) # 80001ba6 <myproc>
    80004670:	5d1c                	lw	a5,56(a0)
    80004672:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004674:	854a                	mv	a0,s2
    80004676:	ffffc097          	auipc	ra,0xffffc
    8000467a:	614080e7          	jalr	1556(ra) # 80000c8a <release>
}
    8000467e:	60e2                	ld	ra,24(sp)
    80004680:	6442                	ld	s0,16(sp)
    80004682:	64a2                	ld	s1,8(sp)
    80004684:	6902                	ld	s2,0(sp)
    80004686:	6105                	addi	sp,sp,32
    80004688:	8082                	ret

000000008000468a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000468a:	1101                	addi	sp,sp,-32
    8000468c:	ec06                	sd	ra,24(sp)
    8000468e:	e822                	sd	s0,16(sp)
    80004690:	e426                	sd	s1,8(sp)
    80004692:	e04a                	sd	s2,0(sp)
    80004694:	1000                	addi	s0,sp,32
    80004696:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004698:	00850913          	addi	s2,a0,8
    8000469c:	854a                	mv	a0,s2
    8000469e:	ffffc097          	auipc	ra,0xffffc
    800046a2:	538080e7          	jalr	1336(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800046a6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046aa:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046ae:	8526                	mv	a0,s1
    800046b0:	ffffe097          	auipc	ra,0xffffe
    800046b4:	de6080e7          	jalr	-538(ra) # 80002496 <wakeup>
  release(&lk->lk);
    800046b8:	854a                	mv	a0,s2
    800046ba:	ffffc097          	auipc	ra,0xffffc
    800046be:	5d0080e7          	jalr	1488(ra) # 80000c8a <release>
}
    800046c2:	60e2                	ld	ra,24(sp)
    800046c4:	6442                	ld	s0,16(sp)
    800046c6:	64a2                	ld	s1,8(sp)
    800046c8:	6902                	ld	s2,0(sp)
    800046ca:	6105                	addi	sp,sp,32
    800046cc:	8082                	ret

00000000800046ce <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046ce:	7179                	addi	sp,sp,-48
    800046d0:	f406                	sd	ra,40(sp)
    800046d2:	f022                	sd	s0,32(sp)
    800046d4:	ec26                	sd	s1,24(sp)
    800046d6:	e84a                	sd	s2,16(sp)
    800046d8:	e44e                	sd	s3,8(sp)
    800046da:	1800                	addi	s0,sp,48
    800046dc:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046de:	00850913          	addi	s2,a0,8
    800046e2:	854a                	mv	a0,s2
    800046e4:	ffffc097          	auipc	ra,0xffffc
    800046e8:	4f2080e7          	jalr	1266(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046ec:	409c                	lw	a5,0(s1)
    800046ee:	ef99                	bnez	a5,8000470c <holdingsleep+0x3e>
    800046f0:	4481                	li	s1,0
  release(&lk->lk);
    800046f2:	854a                	mv	a0,s2
    800046f4:	ffffc097          	auipc	ra,0xffffc
    800046f8:	596080e7          	jalr	1430(ra) # 80000c8a <release>
  return r;
}
    800046fc:	8526                	mv	a0,s1
    800046fe:	70a2                	ld	ra,40(sp)
    80004700:	7402                	ld	s0,32(sp)
    80004702:	64e2                	ld	s1,24(sp)
    80004704:	6942                	ld	s2,16(sp)
    80004706:	69a2                	ld	s3,8(sp)
    80004708:	6145                	addi	sp,sp,48
    8000470a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000470c:	0284a983          	lw	s3,40(s1)
    80004710:	ffffd097          	auipc	ra,0xffffd
    80004714:	496080e7          	jalr	1174(ra) # 80001ba6 <myproc>
    80004718:	5d04                	lw	s1,56(a0)
    8000471a:	413484b3          	sub	s1,s1,s3
    8000471e:	0014b493          	seqz	s1,s1
    80004722:	bfc1                	j	800046f2 <holdingsleep+0x24>

0000000080004724 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004724:	1141                	addi	sp,sp,-16
    80004726:	e406                	sd	ra,8(sp)
    80004728:	e022                	sd	s0,0(sp)
    8000472a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000472c:	00004597          	auipc	a1,0x4
    80004730:	f6c58593          	addi	a1,a1,-148 # 80008698 <syscalls+0x248>
    80004734:	0001d517          	auipc	a0,0x1d
    80004738:	36c50513          	addi	a0,a0,876 # 80021aa0 <ftable>
    8000473c:	ffffc097          	auipc	ra,0xffffc
    80004740:	40a080e7          	jalr	1034(ra) # 80000b46 <initlock>
}
    80004744:	60a2                	ld	ra,8(sp)
    80004746:	6402                	ld	s0,0(sp)
    80004748:	0141                	addi	sp,sp,16
    8000474a:	8082                	ret

000000008000474c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000474c:	1101                	addi	sp,sp,-32
    8000474e:	ec06                	sd	ra,24(sp)
    80004750:	e822                	sd	s0,16(sp)
    80004752:	e426                	sd	s1,8(sp)
    80004754:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004756:	0001d517          	auipc	a0,0x1d
    8000475a:	34a50513          	addi	a0,a0,842 # 80021aa0 <ftable>
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	478080e7          	jalr	1144(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004766:	0001d497          	auipc	s1,0x1d
    8000476a:	35248493          	addi	s1,s1,850 # 80021ab8 <ftable+0x18>
    8000476e:	0001e717          	auipc	a4,0x1e
    80004772:	2ea70713          	addi	a4,a4,746 # 80022a58 <ftable+0xfb8>
    if(f->ref == 0){
    80004776:	40dc                	lw	a5,4(s1)
    80004778:	cf99                	beqz	a5,80004796 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000477a:	02848493          	addi	s1,s1,40
    8000477e:	fee49ce3          	bne	s1,a4,80004776 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004782:	0001d517          	auipc	a0,0x1d
    80004786:	31e50513          	addi	a0,a0,798 # 80021aa0 <ftable>
    8000478a:	ffffc097          	auipc	ra,0xffffc
    8000478e:	500080e7          	jalr	1280(ra) # 80000c8a <release>
  return 0;
    80004792:	4481                	li	s1,0
    80004794:	a819                	j	800047aa <filealloc+0x5e>
      f->ref = 1;
    80004796:	4785                	li	a5,1
    80004798:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000479a:	0001d517          	auipc	a0,0x1d
    8000479e:	30650513          	addi	a0,a0,774 # 80021aa0 <ftable>
    800047a2:	ffffc097          	auipc	ra,0xffffc
    800047a6:	4e8080e7          	jalr	1256(ra) # 80000c8a <release>
}
    800047aa:	8526                	mv	a0,s1
    800047ac:	60e2                	ld	ra,24(sp)
    800047ae:	6442                	ld	s0,16(sp)
    800047b0:	64a2                	ld	s1,8(sp)
    800047b2:	6105                	addi	sp,sp,32
    800047b4:	8082                	ret

00000000800047b6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047b6:	1101                	addi	sp,sp,-32
    800047b8:	ec06                	sd	ra,24(sp)
    800047ba:	e822                	sd	s0,16(sp)
    800047bc:	e426                	sd	s1,8(sp)
    800047be:	1000                	addi	s0,sp,32
    800047c0:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047c2:	0001d517          	auipc	a0,0x1d
    800047c6:	2de50513          	addi	a0,a0,734 # 80021aa0 <ftable>
    800047ca:	ffffc097          	auipc	ra,0xffffc
    800047ce:	40c080e7          	jalr	1036(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800047d2:	40dc                	lw	a5,4(s1)
    800047d4:	02f05263          	blez	a5,800047f8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047d8:	2785                	addiw	a5,a5,1
    800047da:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047dc:	0001d517          	auipc	a0,0x1d
    800047e0:	2c450513          	addi	a0,a0,708 # 80021aa0 <ftable>
    800047e4:	ffffc097          	auipc	ra,0xffffc
    800047e8:	4a6080e7          	jalr	1190(ra) # 80000c8a <release>
  return f;
}
    800047ec:	8526                	mv	a0,s1
    800047ee:	60e2                	ld	ra,24(sp)
    800047f0:	6442                	ld	s0,16(sp)
    800047f2:	64a2                	ld	s1,8(sp)
    800047f4:	6105                	addi	sp,sp,32
    800047f6:	8082                	ret
    panic("filedup");
    800047f8:	00004517          	auipc	a0,0x4
    800047fc:	ea850513          	addi	a0,a0,-344 # 800086a0 <syscalls+0x250>
    80004800:	ffffc097          	auipc	ra,0xffffc
    80004804:	d30080e7          	jalr	-720(ra) # 80000530 <panic>

0000000080004808 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004808:	7139                	addi	sp,sp,-64
    8000480a:	fc06                	sd	ra,56(sp)
    8000480c:	f822                	sd	s0,48(sp)
    8000480e:	f426                	sd	s1,40(sp)
    80004810:	f04a                	sd	s2,32(sp)
    80004812:	ec4e                	sd	s3,24(sp)
    80004814:	e852                	sd	s4,16(sp)
    80004816:	e456                	sd	s5,8(sp)
    80004818:	0080                	addi	s0,sp,64
    8000481a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000481c:	0001d517          	auipc	a0,0x1d
    80004820:	28450513          	addi	a0,a0,644 # 80021aa0 <ftable>
    80004824:	ffffc097          	auipc	ra,0xffffc
    80004828:	3b2080e7          	jalr	946(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000482c:	40dc                	lw	a5,4(s1)
    8000482e:	06f05163          	blez	a5,80004890 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004832:	37fd                	addiw	a5,a5,-1
    80004834:	0007871b          	sext.w	a4,a5
    80004838:	c0dc                	sw	a5,4(s1)
    8000483a:	06e04363          	bgtz	a4,800048a0 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000483e:	0004a903          	lw	s2,0(s1)
    80004842:	0094ca83          	lbu	s5,9(s1)
    80004846:	0104ba03          	ld	s4,16(s1)
    8000484a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000484e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004852:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004856:	0001d517          	auipc	a0,0x1d
    8000485a:	24a50513          	addi	a0,a0,586 # 80021aa0 <ftable>
    8000485e:	ffffc097          	auipc	ra,0xffffc
    80004862:	42c080e7          	jalr	1068(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004866:	4785                	li	a5,1
    80004868:	04f90d63          	beq	s2,a5,800048c2 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000486c:	3979                	addiw	s2,s2,-2
    8000486e:	4785                	li	a5,1
    80004870:	0527e063          	bltu	a5,s2,800048b0 <fileclose+0xa8>
    begin_op();
    80004874:	00000097          	auipc	ra,0x0
    80004878:	ac0080e7          	jalr	-1344(ra) # 80004334 <begin_op>
    iput(ff.ip);
    8000487c:	854e                	mv	a0,s3
    8000487e:	fffff097          	auipc	ra,0xfffff
    80004882:	29e080e7          	jalr	670(ra) # 80003b1c <iput>
    end_op();
    80004886:	00000097          	auipc	ra,0x0
    8000488a:	b2e080e7          	jalr	-1234(ra) # 800043b4 <end_op>
    8000488e:	a00d                	j	800048b0 <fileclose+0xa8>
    panic("fileclose");
    80004890:	00004517          	auipc	a0,0x4
    80004894:	e1850513          	addi	a0,a0,-488 # 800086a8 <syscalls+0x258>
    80004898:	ffffc097          	auipc	ra,0xffffc
    8000489c:	c98080e7          	jalr	-872(ra) # 80000530 <panic>
    release(&ftable.lock);
    800048a0:	0001d517          	auipc	a0,0x1d
    800048a4:	20050513          	addi	a0,a0,512 # 80021aa0 <ftable>
    800048a8:	ffffc097          	auipc	ra,0xffffc
    800048ac:	3e2080e7          	jalr	994(ra) # 80000c8a <release>
  }
}
    800048b0:	70e2                	ld	ra,56(sp)
    800048b2:	7442                	ld	s0,48(sp)
    800048b4:	74a2                	ld	s1,40(sp)
    800048b6:	7902                	ld	s2,32(sp)
    800048b8:	69e2                	ld	s3,24(sp)
    800048ba:	6a42                	ld	s4,16(sp)
    800048bc:	6aa2                	ld	s5,8(sp)
    800048be:	6121                	addi	sp,sp,64
    800048c0:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048c2:	85d6                	mv	a1,s5
    800048c4:	8552                	mv	a0,s4
    800048c6:	00000097          	auipc	ra,0x0
    800048ca:	34c080e7          	jalr	844(ra) # 80004c12 <pipeclose>
    800048ce:	b7cd                	j	800048b0 <fileclose+0xa8>

00000000800048d0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048d0:	715d                	addi	sp,sp,-80
    800048d2:	e486                	sd	ra,72(sp)
    800048d4:	e0a2                	sd	s0,64(sp)
    800048d6:	fc26                	sd	s1,56(sp)
    800048d8:	f84a                	sd	s2,48(sp)
    800048da:	f44e                	sd	s3,40(sp)
    800048dc:	0880                	addi	s0,sp,80
    800048de:	84aa                	mv	s1,a0
    800048e0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048e2:	ffffd097          	auipc	ra,0xffffd
    800048e6:	2c4080e7          	jalr	708(ra) # 80001ba6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048ea:	409c                	lw	a5,0(s1)
    800048ec:	37f9                	addiw	a5,a5,-2
    800048ee:	4705                	li	a4,1
    800048f0:	04f76763          	bltu	a4,a5,8000493e <filestat+0x6e>
    800048f4:	892a                	mv	s2,a0
    ilock(f->ip);
    800048f6:	6c88                	ld	a0,24(s1)
    800048f8:	fffff097          	auipc	ra,0xfffff
    800048fc:	06a080e7          	jalr	106(ra) # 80003962 <ilock>
    stati(f->ip, &st);
    80004900:	fb840593          	addi	a1,s0,-72
    80004904:	6c88                	ld	a0,24(s1)
    80004906:	fffff097          	auipc	ra,0xfffff
    8000490a:	2e6080e7          	jalr	742(ra) # 80003bec <stati>
    iunlock(f->ip);
    8000490e:	6c88                	ld	a0,24(s1)
    80004910:	fffff097          	auipc	ra,0xfffff
    80004914:	114080e7          	jalr	276(ra) # 80003a24 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004918:	46e1                	li	a3,24
    8000491a:	fb840613          	addi	a2,s0,-72
    8000491e:	85ce                	mv	a1,s3
    80004920:	05093503          	ld	a0,80(s2)
    80004924:	ffffd097          	auipc	ra,0xffffd
    80004928:	d02080e7          	jalr	-766(ra) # 80001626 <copyout>
    8000492c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004930:	60a6                	ld	ra,72(sp)
    80004932:	6406                	ld	s0,64(sp)
    80004934:	74e2                	ld	s1,56(sp)
    80004936:	7942                	ld	s2,48(sp)
    80004938:	79a2                	ld	s3,40(sp)
    8000493a:	6161                	addi	sp,sp,80
    8000493c:	8082                	ret
  return -1;
    8000493e:	557d                	li	a0,-1
    80004940:	bfc5                	j	80004930 <filestat+0x60>

0000000080004942 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004942:	7179                	addi	sp,sp,-48
    80004944:	f406                	sd	ra,40(sp)
    80004946:	f022                	sd	s0,32(sp)
    80004948:	ec26                	sd	s1,24(sp)
    8000494a:	e84a                	sd	s2,16(sp)
    8000494c:	e44e                	sd	s3,8(sp)
    8000494e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004950:	00854783          	lbu	a5,8(a0)
    80004954:	c3d5                	beqz	a5,800049f8 <fileread+0xb6>
    80004956:	84aa                	mv	s1,a0
    80004958:	89ae                	mv	s3,a1
    8000495a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000495c:	411c                	lw	a5,0(a0)
    8000495e:	4705                	li	a4,1
    80004960:	04e78963          	beq	a5,a4,800049b2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004964:	470d                	li	a4,3
    80004966:	04e78d63          	beq	a5,a4,800049c0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000496a:	4709                	li	a4,2
    8000496c:	06e79e63          	bne	a5,a4,800049e8 <fileread+0xa6>
    ilock(f->ip);
    80004970:	6d08                	ld	a0,24(a0)
    80004972:	fffff097          	auipc	ra,0xfffff
    80004976:	ff0080e7          	jalr	-16(ra) # 80003962 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000497a:	874a                	mv	a4,s2
    8000497c:	5094                	lw	a3,32(s1)
    8000497e:	864e                	mv	a2,s3
    80004980:	4585                	li	a1,1
    80004982:	6c88                	ld	a0,24(s1)
    80004984:	fffff097          	auipc	ra,0xfffff
    80004988:	292080e7          	jalr	658(ra) # 80003c16 <readi>
    8000498c:	892a                	mv	s2,a0
    8000498e:	00a05563          	blez	a0,80004998 <fileread+0x56>
      f->off += r;
    80004992:	509c                	lw	a5,32(s1)
    80004994:	9fa9                	addw	a5,a5,a0
    80004996:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004998:	6c88                	ld	a0,24(s1)
    8000499a:	fffff097          	auipc	ra,0xfffff
    8000499e:	08a080e7          	jalr	138(ra) # 80003a24 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049a2:	854a                	mv	a0,s2
    800049a4:	70a2                	ld	ra,40(sp)
    800049a6:	7402                	ld	s0,32(sp)
    800049a8:	64e2                	ld	s1,24(sp)
    800049aa:	6942                	ld	s2,16(sp)
    800049ac:	69a2                	ld	s3,8(sp)
    800049ae:	6145                	addi	sp,sp,48
    800049b0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049b2:	6908                	ld	a0,16(a0)
    800049b4:	00000097          	auipc	ra,0x0
    800049b8:	3c8080e7          	jalr	968(ra) # 80004d7c <piperead>
    800049bc:	892a                	mv	s2,a0
    800049be:	b7d5                	j	800049a2 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049c0:	02451783          	lh	a5,36(a0)
    800049c4:	03079693          	slli	a3,a5,0x30
    800049c8:	92c1                	srli	a3,a3,0x30
    800049ca:	4725                	li	a4,9
    800049cc:	02d76863          	bltu	a4,a3,800049fc <fileread+0xba>
    800049d0:	0792                	slli	a5,a5,0x4
    800049d2:	0001d717          	auipc	a4,0x1d
    800049d6:	02e70713          	addi	a4,a4,46 # 80021a00 <devsw>
    800049da:	97ba                	add	a5,a5,a4
    800049dc:	639c                	ld	a5,0(a5)
    800049de:	c38d                	beqz	a5,80004a00 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049e0:	4505                	li	a0,1
    800049e2:	9782                	jalr	a5
    800049e4:	892a                	mv	s2,a0
    800049e6:	bf75                	j	800049a2 <fileread+0x60>
    panic("fileread");
    800049e8:	00004517          	auipc	a0,0x4
    800049ec:	cd050513          	addi	a0,a0,-816 # 800086b8 <syscalls+0x268>
    800049f0:	ffffc097          	auipc	ra,0xffffc
    800049f4:	b40080e7          	jalr	-1216(ra) # 80000530 <panic>
    return -1;
    800049f8:	597d                	li	s2,-1
    800049fa:	b765                	j	800049a2 <fileread+0x60>
      return -1;
    800049fc:	597d                	li	s2,-1
    800049fe:	b755                	j	800049a2 <fileread+0x60>
    80004a00:	597d                	li	s2,-1
    80004a02:	b745                	j	800049a2 <fileread+0x60>

0000000080004a04 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a04:	715d                	addi	sp,sp,-80
    80004a06:	e486                	sd	ra,72(sp)
    80004a08:	e0a2                	sd	s0,64(sp)
    80004a0a:	fc26                	sd	s1,56(sp)
    80004a0c:	f84a                	sd	s2,48(sp)
    80004a0e:	f44e                	sd	s3,40(sp)
    80004a10:	f052                	sd	s4,32(sp)
    80004a12:	ec56                	sd	s5,24(sp)
    80004a14:	e85a                	sd	s6,16(sp)
    80004a16:	e45e                	sd	s7,8(sp)
    80004a18:	e062                	sd	s8,0(sp)
    80004a1a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a1c:	00954783          	lbu	a5,9(a0)
    80004a20:	10078663          	beqz	a5,80004b2c <filewrite+0x128>
    80004a24:	892a                	mv	s2,a0
    80004a26:	8aae                	mv	s5,a1
    80004a28:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a2a:	411c                	lw	a5,0(a0)
    80004a2c:	4705                	li	a4,1
    80004a2e:	02e78263          	beq	a5,a4,80004a52 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a32:	470d                	li	a4,3
    80004a34:	02e78663          	beq	a5,a4,80004a60 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a38:	4709                	li	a4,2
    80004a3a:	0ee79163          	bne	a5,a4,80004b1c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a3e:	0ac05d63          	blez	a2,80004af8 <filewrite+0xf4>
    int i = 0;
    80004a42:	4981                	li	s3,0
    80004a44:	6b05                	lui	s6,0x1
    80004a46:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a4a:	6b85                	lui	s7,0x1
    80004a4c:	c00b8b9b          	addiw	s7,s7,-1024
    80004a50:	a861                	j	80004ae8 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a52:	6908                	ld	a0,16(a0)
    80004a54:	00000097          	auipc	ra,0x0
    80004a58:	22e080e7          	jalr	558(ra) # 80004c82 <pipewrite>
    80004a5c:	8a2a                	mv	s4,a0
    80004a5e:	a045                	j	80004afe <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a60:	02451783          	lh	a5,36(a0)
    80004a64:	03079693          	slli	a3,a5,0x30
    80004a68:	92c1                	srli	a3,a3,0x30
    80004a6a:	4725                	li	a4,9
    80004a6c:	0cd76263          	bltu	a4,a3,80004b30 <filewrite+0x12c>
    80004a70:	0792                	slli	a5,a5,0x4
    80004a72:	0001d717          	auipc	a4,0x1d
    80004a76:	f8e70713          	addi	a4,a4,-114 # 80021a00 <devsw>
    80004a7a:	97ba                	add	a5,a5,a4
    80004a7c:	679c                	ld	a5,8(a5)
    80004a7e:	cbdd                	beqz	a5,80004b34 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a80:	4505                	li	a0,1
    80004a82:	9782                	jalr	a5
    80004a84:	8a2a                	mv	s4,a0
    80004a86:	a8a5                	j	80004afe <filewrite+0xfa>
    80004a88:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a8c:	00000097          	auipc	ra,0x0
    80004a90:	8a8080e7          	jalr	-1880(ra) # 80004334 <begin_op>
      ilock(f->ip);
    80004a94:	01893503          	ld	a0,24(s2)
    80004a98:	fffff097          	auipc	ra,0xfffff
    80004a9c:	eca080e7          	jalr	-310(ra) # 80003962 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004aa0:	8762                	mv	a4,s8
    80004aa2:	02092683          	lw	a3,32(s2)
    80004aa6:	01598633          	add	a2,s3,s5
    80004aaa:	4585                	li	a1,1
    80004aac:	01893503          	ld	a0,24(s2)
    80004ab0:	fffff097          	auipc	ra,0xfffff
    80004ab4:	25e080e7          	jalr	606(ra) # 80003d0e <writei>
    80004ab8:	84aa                	mv	s1,a0
    80004aba:	00a05763          	blez	a0,80004ac8 <filewrite+0xc4>
        f->off += r;
    80004abe:	02092783          	lw	a5,32(s2)
    80004ac2:	9fa9                	addw	a5,a5,a0
    80004ac4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ac8:	01893503          	ld	a0,24(s2)
    80004acc:	fffff097          	auipc	ra,0xfffff
    80004ad0:	f58080e7          	jalr	-168(ra) # 80003a24 <iunlock>
      end_op();
    80004ad4:	00000097          	auipc	ra,0x0
    80004ad8:	8e0080e7          	jalr	-1824(ra) # 800043b4 <end_op>

      if(r != n1){
    80004adc:	009c1f63          	bne	s8,s1,80004afa <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004ae0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ae4:	0149db63          	bge	s3,s4,80004afa <filewrite+0xf6>
      int n1 = n - i;
    80004ae8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004aec:	84be                	mv	s1,a5
    80004aee:	2781                	sext.w	a5,a5
    80004af0:	f8fb5ce3          	bge	s6,a5,80004a88 <filewrite+0x84>
    80004af4:	84de                	mv	s1,s7
    80004af6:	bf49                	j	80004a88 <filewrite+0x84>
    int i = 0;
    80004af8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004afa:	013a1f63          	bne	s4,s3,80004b18 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004afe:	8552                	mv	a0,s4
    80004b00:	60a6                	ld	ra,72(sp)
    80004b02:	6406                	ld	s0,64(sp)
    80004b04:	74e2                	ld	s1,56(sp)
    80004b06:	7942                	ld	s2,48(sp)
    80004b08:	79a2                	ld	s3,40(sp)
    80004b0a:	7a02                	ld	s4,32(sp)
    80004b0c:	6ae2                	ld	s5,24(sp)
    80004b0e:	6b42                	ld	s6,16(sp)
    80004b10:	6ba2                	ld	s7,8(sp)
    80004b12:	6c02                	ld	s8,0(sp)
    80004b14:	6161                	addi	sp,sp,80
    80004b16:	8082                	ret
    ret = (i == n ? n : -1);
    80004b18:	5a7d                	li	s4,-1
    80004b1a:	b7d5                	j	80004afe <filewrite+0xfa>
    panic("filewrite");
    80004b1c:	00004517          	auipc	a0,0x4
    80004b20:	bac50513          	addi	a0,a0,-1108 # 800086c8 <syscalls+0x278>
    80004b24:	ffffc097          	auipc	ra,0xffffc
    80004b28:	a0c080e7          	jalr	-1524(ra) # 80000530 <panic>
    return -1;
    80004b2c:	5a7d                	li	s4,-1
    80004b2e:	bfc1                	j	80004afe <filewrite+0xfa>
      return -1;
    80004b30:	5a7d                	li	s4,-1
    80004b32:	b7f1                	j	80004afe <filewrite+0xfa>
    80004b34:	5a7d                	li	s4,-1
    80004b36:	b7e1                	j	80004afe <filewrite+0xfa>

0000000080004b38 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b38:	7179                	addi	sp,sp,-48
    80004b3a:	f406                	sd	ra,40(sp)
    80004b3c:	f022                	sd	s0,32(sp)
    80004b3e:	ec26                	sd	s1,24(sp)
    80004b40:	e84a                	sd	s2,16(sp)
    80004b42:	e44e                	sd	s3,8(sp)
    80004b44:	e052                	sd	s4,0(sp)
    80004b46:	1800                	addi	s0,sp,48
    80004b48:	84aa                	mv	s1,a0
    80004b4a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b4c:	0005b023          	sd	zero,0(a1)
    80004b50:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b54:	00000097          	auipc	ra,0x0
    80004b58:	bf8080e7          	jalr	-1032(ra) # 8000474c <filealloc>
    80004b5c:	e088                	sd	a0,0(s1)
    80004b5e:	c551                	beqz	a0,80004bea <pipealloc+0xb2>
    80004b60:	00000097          	auipc	ra,0x0
    80004b64:	bec080e7          	jalr	-1044(ra) # 8000474c <filealloc>
    80004b68:	00aa3023          	sd	a0,0(s4)
    80004b6c:	c92d                	beqz	a0,80004bde <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b6e:	ffffc097          	auipc	ra,0xffffc
    80004b72:	f78080e7          	jalr	-136(ra) # 80000ae6 <kalloc>
    80004b76:	892a                	mv	s2,a0
    80004b78:	c125                	beqz	a0,80004bd8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b7a:	4985                	li	s3,1
    80004b7c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b80:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b84:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b88:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b8c:	00004597          	auipc	a1,0x4
    80004b90:	b4c58593          	addi	a1,a1,-1204 # 800086d8 <syscalls+0x288>
    80004b94:	ffffc097          	auipc	ra,0xffffc
    80004b98:	fb2080e7          	jalr	-78(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004b9c:	609c                	ld	a5,0(s1)
    80004b9e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ba2:	609c                	ld	a5,0(s1)
    80004ba4:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ba8:	609c                	ld	a5,0(s1)
    80004baa:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004bae:	609c                	ld	a5,0(s1)
    80004bb0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004bb4:	000a3783          	ld	a5,0(s4)
    80004bb8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004bbc:	000a3783          	ld	a5,0(s4)
    80004bc0:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bc4:	000a3783          	ld	a5,0(s4)
    80004bc8:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004bcc:	000a3783          	ld	a5,0(s4)
    80004bd0:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bd4:	4501                	li	a0,0
    80004bd6:	a025                	j	80004bfe <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004bd8:	6088                	ld	a0,0(s1)
    80004bda:	e501                	bnez	a0,80004be2 <pipealloc+0xaa>
    80004bdc:	a039                	j	80004bea <pipealloc+0xb2>
    80004bde:	6088                	ld	a0,0(s1)
    80004be0:	c51d                	beqz	a0,80004c0e <pipealloc+0xd6>
    fileclose(*f0);
    80004be2:	00000097          	auipc	ra,0x0
    80004be6:	c26080e7          	jalr	-986(ra) # 80004808 <fileclose>
  if(*f1)
    80004bea:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004bee:	557d                	li	a0,-1
  if(*f1)
    80004bf0:	c799                	beqz	a5,80004bfe <pipealloc+0xc6>
    fileclose(*f1);
    80004bf2:	853e                	mv	a0,a5
    80004bf4:	00000097          	auipc	ra,0x0
    80004bf8:	c14080e7          	jalr	-1004(ra) # 80004808 <fileclose>
  return -1;
    80004bfc:	557d                	li	a0,-1
}
    80004bfe:	70a2                	ld	ra,40(sp)
    80004c00:	7402                	ld	s0,32(sp)
    80004c02:	64e2                	ld	s1,24(sp)
    80004c04:	6942                	ld	s2,16(sp)
    80004c06:	69a2                	ld	s3,8(sp)
    80004c08:	6a02                	ld	s4,0(sp)
    80004c0a:	6145                	addi	sp,sp,48
    80004c0c:	8082                	ret
  return -1;
    80004c0e:	557d                	li	a0,-1
    80004c10:	b7fd                	j	80004bfe <pipealloc+0xc6>

0000000080004c12 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c12:	1101                	addi	sp,sp,-32
    80004c14:	ec06                	sd	ra,24(sp)
    80004c16:	e822                	sd	s0,16(sp)
    80004c18:	e426                	sd	s1,8(sp)
    80004c1a:	e04a                	sd	s2,0(sp)
    80004c1c:	1000                	addi	s0,sp,32
    80004c1e:	84aa                	mv	s1,a0
    80004c20:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c22:	ffffc097          	auipc	ra,0xffffc
    80004c26:	fb4080e7          	jalr	-76(ra) # 80000bd6 <acquire>
  if(writable){
    80004c2a:	02090d63          	beqz	s2,80004c64 <pipeclose+0x52>
    pi->writeopen = 0;
    80004c2e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c32:	21848513          	addi	a0,s1,536
    80004c36:	ffffe097          	auipc	ra,0xffffe
    80004c3a:	860080e7          	jalr	-1952(ra) # 80002496 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c3e:	2204b783          	ld	a5,544(s1)
    80004c42:	eb95                	bnez	a5,80004c76 <pipeclose+0x64>
    release(&pi->lock);
    80004c44:	8526                	mv	a0,s1
    80004c46:	ffffc097          	auipc	ra,0xffffc
    80004c4a:	044080e7          	jalr	68(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004c4e:	8526                	mv	a0,s1
    80004c50:	ffffc097          	auipc	ra,0xffffc
    80004c54:	d9a080e7          	jalr	-614(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004c58:	60e2                	ld	ra,24(sp)
    80004c5a:	6442                	ld	s0,16(sp)
    80004c5c:	64a2                	ld	s1,8(sp)
    80004c5e:	6902                	ld	s2,0(sp)
    80004c60:	6105                	addi	sp,sp,32
    80004c62:	8082                	ret
    pi->readopen = 0;
    80004c64:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c68:	21c48513          	addi	a0,s1,540
    80004c6c:	ffffe097          	auipc	ra,0xffffe
    80004c70:	82a080e7          	jalr	-2006(ra) # 80002496 <wakeup>
    80004c74:	b7e9                	j	80004c3e <pipeclose+0x2c>
    release(&pi->lock);
    80004c76:	8526                	mv	a0,s1
    80004c78:	ffffc097          	auipc	ra,0xffffc
    80004c7c:	012080e7          	jalr	18(ra) # 80000c8a <release>
}
    80004c80:	bfe1                	j	80004c58 <pipeclose+0x46>

0000000080004c82 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c82:	7159                	addi	sp,sp,-112
    80004c84:	f486                	sd	ra,104(sp)
    80004c86:	f0a2                	sd	s0,96(sp)
    80004c88:	eca6                	sd	s1,88(sp)
    80004c8a:	e8ca                	sd	s2,80(sp)
    80004c8c:	e4ce                	sd	s3,72(sp)
    80004c8e:	e0d2                	sd	s4,64(sp)
    80004c90:	fc56                	sd	s5,56(sp)
    80004c92:	f85a                	sd	s6,48(sp)
    80004c94:	f45e                	sd	s7,40(sp)
    80004c96:	f062                	sd	s8,32(sp)
    80004c98:	ec66                	sd	s9,24(sp)
    80004c9a:	1880                	addi	s0,sp,112
    80004c9c:	84aa                	mv	s1,a0
    80004c9e:	8aae                	mv	s5,a1
    80004ca0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ca2:	ffffd097          	auipc	ra,0xffffd
    80004ca6:	f04080e7          	jalr	-252(ra) # 80001ba6 <myproc>
    80004caa:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004cac:	8526                	mv	a0,s1
    80004cae:	ffffc097          	auipc	ra,0xffffc
    80004cb2:	f28080e7          	jalr	-216(ra) # 80000bd6 <acquire>
  while(i < n){
    80004cb6:	0d405163          	blez	s4,80004d78 <pipewrite+0xf6>
    80004cba:	8ba6                	mv	s7,s1
  int i = 0;
    80004cbc:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cbe:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004cc0:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004cc4:	21c48c13          	addi	s8,s1,540
    80004cc8:	a08d                	j	80004d2a <pipewrite+0xa8>
      release(&pi->lock);
    80004cca:	8526                	mv	a0,s1
    80004ccc:	ffffc097          	auipc	ra,0xffffc
    80004cd0:	fbe080e7          	jalr	-66(ra) # 80000c8a <release>
      return -1;
    80004cd4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004cd6:	854a                	mv	a0,s2
    80004cd8:	70a6                	ld	ra,104(sp)
    80004cda:	7406                	ld	s0,96(sp)
    80004cdc:	64e6                	ld	s1,88(sp)
    80004cde:	6946                	ld	s2,80(sp)
    80004ce0:	69a6                	ld	s3,72(sp)
    80004ce2:	6a06                	ld	s4,64(sp)
    80004ce4:	7ae2                	ld	s5,56(sp)
    80004ce6:	7b42                	ld	s6,48(sp)
    80004ce8:	7ba2                	ld	s7,40(sp)
    80004cea:	7c02                	ld	s8,32(sp)
    80004cec:	6ce2                	ld	s9,24(sp)
    80004cee:	6165                	addi	sp,sp,112
    80004cf0:	8082                	ret
      wakeup(&pi->nread);
    80004cf2:	8566                	mv	a0,s9
    80004cf4:	ffffd097          	auipc	ra,0xffffd
    80004cf8:	7a2080e7          	jalr	1954(ra) # 80002496 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004cfc:	85de                	mv	a1,s7
    80004cfe:	8562                	mv	a0,s8
    80004d00:	ffffd097          	auipc	ra,0xffffd
    80004d04:	610080e7          	jalr	1552(ra) # 80002310 <sleep>
    80004d08:	a839                	j	80004d26 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d0a:	21c4a783          	lw	a5,540(s1)
    80004d0e:	0017871b          	addiw	a4,a5,1
    80004d12:	20e4ae23          	sw	a4,540(s1)
    80004d16:	1ff7f793          	andi	a5,a5,511
    80004d1a:	97a6                	add	a5,a5,s1
    80004d1c:	f9f44703          	lbu	a4,-97(s0)
    80004d20:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d24:	2905                	addiw	s2,s2,1
  while(i < n){
    80004d26:	03495d63          	bge	s2,s4,80004d60 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004d2a:	2204a783          	lw	a5,544(s1)
    80004d2e:	dfd1                	beqz	a5,80004cca <pipewrite+0x48>
    80004d30:	0309a783          	lw	a5,48(s3)
    80004d34:	fbd9                	bnez	a5,80004cca <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d36:	2184a783          	lw	a5,536(s1)
    80004d3a:	21c4a703          	lw	a4,540(s1)
    80004d3e:	2007879b          	addiw	a5,a5,512
    80004d42:	faf708e3          	beq	a4,a5,80004cf2 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d46:	4685                	li	a3,1
    80004d48:	01590633          	add	a2,s2,s5
    80004d4c:	f9f40593          	addi	a1,s0,-97
    80004d50:	0509b503          	ld	a0,80(s3)
    80004d54:	ffffd097          	auipc	ra,0xffffd
    80004d58:	95e080e7          	jalr	-1698(ra) # 800016b2 <copyin>
    80004d5c:	fb6517e3          	bne	a0,s6,80004d0a <pipewrite+0x88>
  wakeup(&pi->nread);
    80004d60:	21848513          	addi	a0,s1,536
    80004d64:	ffffd097          	auipc	ra,0xffffd
    80004d68:	732080e7          	jalr	1842(ra) # 80002496 <wakeup>
  release(&pi->lock);
    80004d6c:	8526                	mv	a0,s1
    80004d6e:	ffffc097          	auipc	ra,0xffffc
    80004d72:	f1c080e7          	jalr	-228(ra) # 80000c8a <release>
  return i;
    80004d76:	b785                	j	80004cd6 <pipewrite+0x54>
  int i = 0;
    80004d78:	4901                	li	s2,0
    80004d7a:	b7dd                	j	80004d60 <pipewrite+0xde>

0000000080004d7c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d7c:	715d                	addi	sp,sp,-80
    80004d7e:	e486                	sd	ra,72(sp)
    80004d80:	e0a2                	sd	s0,64(sp)
    80004d82:	fc26                	sd	s1,56(sp)
    80004d84:	f84a                	sd	s2,48(sp)
    80004d86:	f44e                	sd	s3,40(sp)
    80004d88:	f052                	sd	s4,32(sp)
    80004d8a:	ec56                	sd	s5,24(sp)
    80004d8c:	e85a                	sd	s6,16(sp)
    80004d8e:	0880                	addi	s0,sp,80
    80004d90:	84aa                	mv	s1,a0
    80004d92:	892e                	mv	s2,a1
    80004d94:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d96:	ffffd097          	auipc	ra,0xffffd
    80004d9a:	e10080e7          	jalr	-496(ra) # 80001ba6 <myproc>
    80004d9e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004da0:	8b26                	mv	s6,s1
    80004da2:	8526                	mv	a0,s1
    80004da4:	ffffc097          	auipc	ra,0xffffc
    80004da8:	e32080e7          	jalr	-462(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dac:	2184a703          	lw	a4,536(s1)
    80004db0:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004db4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004db8:	02f71463          	bne	a4,a5,80004de0 <piperead+0x64>
    80004dbc:	2244a783          	lw	a5,548(s1)
    80004dc0:	c385                	beqz	a5,80004de0 <piperead+0x64>
    if(pr->killed){
    80004dc2:	030a2783          	lw	a5,48(s4)
    80004dc6:	ebc1                	bnez	a5,80004e56 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dc8:	85da                	mv	a1,s6
    80004dca:	854e                	mv	a0,s3
    80004dcc:	ffffd097          	auipc	ra,0xffffd
    80004dd0:	544080e7          	jalr	1348(ra) # 80002310 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dd4:	2184a703          	lw	a4,536(s1)
    80004dd8:	21c4a783          	lw	a5,540(s1)
    80004ddc:	fef700e3          	beq	a4,a5,80004dbc <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004de0:	09505263          	blez	s5,80004e64 <piperead+0xe8>
    80004de4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004de6:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004de8:	2184a783          	lw	a5,536(s1)
    80004dec:	21c4a703          	lw	a4,540(s1)
    80004df0:	02f70d63          	beq	a4,a5,80004e2a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004df4:	0017871b          	addiw	a4,a5,1
    80004df8:	20e4ac23          	sw	a4,536(s1)
    80004dfc:	1ff7f793          	andi	a5,a5,511
    80004e00:	97a6                	add	a5,a5,s1
    80004e02:	0187c783          	lbu	a5,24(a5)
    80004e06:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e0a:	4685                	li	a3,1
    80004e0c:	fbf40613          	addi	a2,s0,-65
    80004e10:	85ca                	mv	a1,s2
    80004e12:	050a3503          	ld	a0,80(s4)
    80004e16:	ffffd097          	auipc	ra,0xffffd
    80004e1a:	810080e7          	jalr	-2032(ra) # 80001626 <copyout>
    80004e1e:	01650663          	beq	a0,s6,80004e2a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e22:	2985                	addiw	s3,s3,1
    80004e24:	0905                	addi	s2,s2,1
    80004e26:	fd3a91e3          	bne	s5,s3,80004de8 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e2a:	21c48513          	addi	a0,s1,540
    80004e2e:	ffffd097          	auipc	ra,0xffffd
    80004e32:	668080e7          	jalr	1640(ra) # 80002496 <wakeup>
  release(&pi->lock);
    80004e36:	8526                	mv	a0,s1
    80004e38:	ffffc097          	auipc	ra,0xffffc
    80004e3c:	e52080e7          	jalr	-430(ra) # 80000c8a <release>
  return i;
}
    80004e40:	854e                	mv	a0,s3
    80004e42:	60a6                	ld	ra,72(sp)
    80004e44:	6406                	ld	s0,64(sp)
    80004e46:	74e2                	ld	s1,56(sp)
    80004e48:	7942                	ld	s2,48(sp)
    80004e4a:	79a2                	ld	s3,40(sp)
    80004e4c:	7a02                	ld	s4,32(sp)
    80004e4e:	6ae2                	ld	s5,24(sp)
    80004e50:	6b42                	ld	s6,16(sp)
    80004e52:	6161                	addi	sp,sp,80
    80004e54:	8082                	ret
      release(&pi->lock);
    80004e56:	8526                	mv	a0,s1
    80004e58:	ffffc097          	auipc	ra,0xffffc
    80004e5c:	e32080e7          	jalr	-462(ra) # 80000c8a <release>
      return -1;
    80004e60:	59fd                	li	s3,-1
    80004e62:	bff9                	j	80004e40 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e64:	4981                	li	s3,0
    80004e66:	b7d1                	j	80004e2a <piperead+0xae>

0000000080004e68 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e68:	df010113          	addi	sp,sp,-528
    80004e6c:	20113423          	sd	ra,520(sp)
    80004e70:	20813023          	sd	s0,512(sp)
    80004e74:	ffa6                	sd	s1,504(sp)
    80004e76:	fbca                	sd	s2,496(sp)
    80004e78:	f7ce                	sd	s3,488(sp)
    80004e7a:	f3d2                	sd	s4,480(sp)
    80004e7c:	efd6                	sd	s5,472(sp)
    80004e7e:	ebda                	sd	s6,464(sp)
    80004e80:	e7de                	sd	s7,456(sp)
    80004e82:	e3e2                	sd	s8,448(sp)
    80004e84:	ff66                	sd	s9,440(sp)
    80004e86:	fb6a                	sd	s10,432(sp)
    80004e88:	f76e                	sd	s11,424(sp)
    80004e8a:	0c00                	addi	s0,sp,528
    80004e8c:	84aa                	mv	s1,a0
    80004e8e:	dea43c23          	sd	a0,-520(s0)
    80004e92:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e96:	ffffd097          	auipc	ra,0xffffd
    80004e9a:	d10080e7          	jalr	-752(ra) # 80001ba6 <myproc>
    80004e9e:	892a                	mv	s2,a0

  begin_op();
    80004ea0:	fffff097          	auipc	ra,0xfffff
    80004ea4:	494080e7          	jalr	1172(ra) # 80004334 <begin_op>

  if((ip = namei(path)) == 0){
    80004ea8:	8526                	mv	a0,s1
    80004eaa:	fffff097          	auipc	ra,0xfffff
    80004eae:	26e080e7          	jalr	622(ra) # 80004118 <namei>
    80004eb2:	c92d                	beqz	a0,80004f24 <exec+0xbc>
    80004eb4:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004eb6:	fffff097          	auipc	ra,0xfffff
    80004eba:	aac080e7          	jalr	-1364(ra) # 80003962 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ebe:	04000713          	li	a4,64
    80004ec2:	4681                	li	a3,0
    80004ec4:	e4840613          	addi	a2,s0,-440
    80004ec8:	4581                	li	a1,0
    80004eca:	8526                	mv	a0,s1
    80004ecc:	fffff097          	auipc	ra,0xfffff
    80004ed0:	d4a080e7          	jalr	-694(ra) # 80003c16 <readi>
    80004ed4:	04000793          	li	a5,64
    80004ed8:	00f51a63          	bne	a0,a5,80004eec <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004edc:	e4842703          	lw	a4,-440(s0)
    80004ee0:	464c47b7          	lui	a5,0x464c4
    80004ee4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ee8:	04f70463          	beq	a4,a5,80004f30 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004eec:	8526                	mv	a0,s1
    80004eee:	fffff097          	auipc	ra,0xfffff
    80004ef2:	cd6080e7          	jalr	-810(ra) # 80003bc4 <iunlockput>
    end_op();
    80004ef6:	fffff097          	auipc	ra,0xfffff
    80004efa:	4be080e7          	jalr	1214(ra) # 800043b4 <end_op>
  }
  return -1;
    80004efe:	557d                	li	a0,-1
}
    80004f00:	20813083          	ld	ra,520(sp)
    80004f04:	20013403          	ld	s0,512(sp)
    80004f08:	74fe                	ld	s1,504(sp)
    80004f0a:	795e                	ld	s2,496(sp)
    80004f0c:	79be                	ld	s3,488(sp)
    80004f0e:	7a1e                	ld	s4,480(sp)
    80004f10:	6afe                	ld	s5,472(sp)
    80004f12:	6b5e                	ld	s6,464(sp)
    80004f14:	6bbe                	ld	s7,456(sp)
    80004f16:	6c1e                	ld	s8,448(sp)
    80004f18:	7cfa                	ld	s9,440(sp)
    80004f1a:	7d5a                	ld	s10,432(sp)
    80004f1c:	7dba                	ld	s11,424(sp)
    80004f1e:	21010113          	addi	sp,sp,528
    80004f22:	8082                	ret
    end_op();
    80004f24:	fffff097          	auipc	ra,0xfffff
    80004f28:	490080e7          	jalr	1168(ra) # 800043b4 <end_op>
    return -1;
    80004f2c:	557d                	li	a0,-1
    80004f2e:	bfc9                	j	80004f00 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f30:	854a                	mv	a0,s2
    80004f32:	ffffd097          	auipc	ra,0xffffd
    80004f36:	d38080e7          	jalr	-712(ra) # 80001c6a <proc_pagetable>
    80004f3a:	8baa                	mv	s7,a0
    80004f3c:	d945                	beqz	a0,80004eec <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f3e:	e6842983          	lw	s3,-408(s0)
    80004f42:	e8045783          	lhu	a5,-384(s0)
    80004f46:	c7ad                	beqz	a5,80004fb0 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f48:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f4a:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004f4c:	6c85                	lui	s9,0x1
    80004f4e:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f52:	def43823          	sd	a5,-528(s0)
    80004f56:	a42d                	j	80005180 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f58:	00003517          	auipc	a0,0x3
    80004f5c:	78850513          	addi	a0,a0,1928 # 800086e0 <syscalls+0x290>
    80004f60:	ffffb097          	auipc	ra,0xffffb
    80004f64:	5d0080e7          	jalr	1488(ra) # 80000530 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f68:	8756                	mv	a4,s5
    80004f6a:	012d86bb          	addw	a3,s11,s2
    80004f6e:	4581                	li	a1,0
    80004f70:	8526                	mv	a0,s1
    80004f72:	fffff097          	auipc	ra,0xfffff
    80004f76:	ca4080e7          	jalr	-860(ra) # 80003c16 <readi>
    80004f7a:	2501                	sext.w	a0,a0
    80004f7c:	1aaa9963          	bne	s5,a0,8000512e <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004f80:	6785                	lui	a5,0x1
    80004f82:	0127893b          	addw	s2,a5,s2
    80004f86:	77fd                	lui	a5,0xfffff
    80004f88:	01478a3b          	addw	s4,a5,s4
    80004f8c:	1f897163          	bgeu	s2,s8,8000516e <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004f90:	02091593          	slli	a1,s2,0x20
    80004f94:	9181                	srli	a1,a1,0x20
    80004f96:	95ea                	add	a1,a1,s10
    80004f98:	855e                	mv	a0,s7
    80004f9a:	ffffc097          	auipc	ra,0xffffc
    80004f9e:	0ca080e7          	jalr	202(ra) # 80001064 <walkaddr>
    80004fa2:	862a                	mv	a2,a0
    if(pa == 0)
    80004fa4:	d955                	beqz	a0,80004f58 <exec+0xf0>
      n = PGSIZE;
    80004fa6:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004fa8:	fd9a70e3          	bgeu	s4,s9,80004f68 <exec+0x100>
      n = sz - i;
    80004fac:	8ad2                	mv	s5,s4
    80004fae:	bf6d                	j	80004f68 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004fb0:	4901                	li	s2,0
  iunlockput(ip);
    80004fb2:	8526                	mv	a0,s1
    80004fb4:	fffff097          	auipc	ra,0xfffff
    80004fb8:	c10080e7          	jalr	-1008(ra) # 80003bc4 <iunlockput>
  end_op();
    80004fbc:	fffff097          	auipc	ra,0xfffff
    80004fc0:	3f8080e7          	jalr	1016(ra) # 800043b4 <end_op>
  p = myproc();
    80004fc4:	ffffd097          	auipc	ra,0xffffd
    80004fc8:	be2080e7          	jalr	-1054(ra) # 80001ba6 <myproc>
    80004fcc:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004fce:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004fd2:	6785                	lui	a5,0x1
    80004fd4:	17fd                	addi	a5,a5,-1
    80004fd6:	993e                	add	s2,s2,a5
    80004fd8:	757d                	lui	a0,0xfffff
    80004fda:	00a977b3          	and	a5,s2,a0
    80004fde:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fe2:	6609                	lui	a2,0x2
    80004fe4:	963e                	add	a2,a2,a5
    80004fe6:	85be                	mv	a1,a5
    80004fe8:	855e                	mv	a0,s7
    80004fea:	ffffc097          	auipc	ra,0xffffc
    80004fee:	3fe080e7          	jalr	1022(ra) # 800013e8 <uvmalloc>
    80004ff2:	8b2a                	mv	s6,a0
  ip = 0;
    80004ff4:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ff6:	12050c63          	beqz	a0,8000512e <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ffa:	75f9                	lui	a1,0xffffe
    80004ffc:	95aa                	add	a1,a1,a0
    80004ffe:	855e                	mv	a0,s7
    80005000:	ffffc097          	auipc	ra,0xffffc
    80005004:	5f4080e7          	jalr	1524(ra) # 800015f4 <uvmclear>
  stackbase = sp - PGSIZE;
    80005008:	7c7d                	lui	s8,0xfffff
    8000500a:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000500c:	e0043783          	ld	a5,-512(s0)
    80005010:	6388                	ld	a0,0(a5)
    80005012:	c535                	beqz	a0,8000507e <exec+0x216>
    80005014:	e8840993          	addi	s3,s0,-376
    80005018:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    8000501c:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000501e:	ffffc097          	auipc	ra,0xffffc
    80005022:	e3c080e7          	jalr	-452(ra) # 80000e5a <strlen>
    80005026:	2505                	addiw	a0,a0,1
    80005028:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000502c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005030:	13896363          	bltu	s2,s8,80005156 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005034:	e0043d83          	ld	s11,-512(s0)
    80005038:	000dba03          	ld	s4,0(s11)
    8000503c:	8552                	mv	a0,s4
    8000503e:	ffffc097          	auipc	ra,0xffffc
    80005042:	e1c080e7          	jalr	-484(ra) # 80000e5a <strlen>
    80005046:	0015069b          	addiw	a3,a0,1
    8000504a:	8652                	mv	a2,s4
    8000504c:	85ca                	mv	a1,s2
    8000504e:	855e                	mv	a0,s7
    80005050:	ffffc097          	auipc	ra,0xffffc
    80005054:	5d6080e7          	jalr	1494(ra) # 80001626 <copyout>
    80005058:	10054363          	bltz	a0,8000515e <exec+0x2f6>
    ustack[argc] = sp;
    8000505c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005060:	0485                	addi	s1,s1,1
    80005062:	008d8793          	addi	a5,s11,8
    80005066:	e0f43023          	sd	a5,-512(s0)
    8000506a:	008db503          	ld	a0,8(s11)
    8000506e:	c911                	beqz	a0,80005082 <exec+0x21a>
    if(argc >= MAXARG)
    80005070:	09a1                	addi	s3,s3,8
    80005072:	fb3c96e3          	bne	s9,s3,8000501e <exec+0x1b6>
  sz = sz1;
    80005076:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000507a:	4481                	li	s1,0
    8000507c:	a84d                	j	8000512e <exec+0x2c6>
  sp = sz;
    8000507e:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005080:	4481                	li	s1,0
  ustack[argc] = 0;
    80005082:	00349793          	slli	a5,s1,0x3
    80005086:	f9040713          	addi	a4,s0,-112
    8000508a:	97ba                	add	a5,a5,a4
    8000508c:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80005090:	00148693          	addi	a3,s1,1
    80005094:	068e                	slli	a3,a3,0x3
    80005096:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000509a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000509e:	01897663          	bgeu	s2,s8,800050aa <exec+0x242>
  sz = sz1;
    800050a2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050a6:	4481                	li	s1,0
    800050a8:	a059                	j	8000512e <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050aa:	e8840613          	addi	a2,s0,-376
    800050ae:	85ca                	mv	a1,s2
    800050b0:	855e                	mv	a0,s7
    800050b2:	ffffc097          	auipc	ra,0xffffc
    800050b6:	574080e7          	jalr	1396(ra) # 80001626 <copyout>
    800050ba:	0a054663          	bltz	a0,80005166 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800050be:	058ab783          	ld	a5,88(s5)
    800050c2:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050c6:	df843783          	ld	a5,-520(s0)
    800050ca:	0007c703          	lbu	a4,0(a5)
    800050ce:	cf11                	beqz	a4,800050ea <exec+0x282>
    800050d0:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050d2:	02f00693          	li	a3,47
    800050d6:	a029                	j	800050e0 <exec+0x278>
  for(last=s=path; *s; s++)
    800050d8:	0785                	addi	a5,a5,1
    800050da:	fff7c703          	lbu	a4,-1(a5)
    800050de:	c711                	beqz	a4,800050ea <exec+0x282>
    if(*s == '/')
    800050e0:	fed71ce3          	bne	a4,a3,800050d8 <exec+0x270>
      last = s+1;
    800050e4:	def43c23          	sd	a5,-520(s0)
    800050e8:	bfc5                	j	800050d8 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800050ea:	4641                	li	a2,16
    800050ec:	df843583          	ld	a1,-520(s0)
    800050f0:	160a8513          	addi	a0,s5,352
    800050f4:	ffffc097          	auipc	ra,0xffffc
    800050f8:	d34080e7          	jalr	-716(ra) # 80000e28 <safestrcpy>
  oldpagetable = p->pagetable;
    800050fc:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005100:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005104:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005108:	058ab783          	ld	a5,88(s5)
    8000510c:	e6043703          	ld	a4,-416(s0)
    80005110:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005112:	058ab783          	ld	a5,88(s5)
    80005116:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000511a:	85ea                	mv	a1,s10
    8000511c:	ffffd097          	auipc	ra,0xffffd
    80005120:	bea080e7          	jalr	-1046(ra) # 80001d06 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005124:	0004851b          	sext.w	a0,s1
    80005128:	bbe1                	j	80004f00 <exec+0x98>
    8000512a:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000512e:	e0843583          	ld	a1,-504(s0)
    80005132:	855e                	mv	a0,s7
    80005134:	ffffd097          	auipc	ra,0xffffd
    80005138:	bd2080e7          	jalr	-1070(ra) # 80001d06 <proc_freepagetable>
  if(ip){
    8000513c:	da0498e3          	bnez	s1,80004eec <exec+0x84>
  return -1;
    80005140:	557d                	li	a0,-1
    80005142:	bb7d                	j	80004f00 <exec+0x98>
    80005144:	e1243423          	sd	s2,-504(s0)
    80005148:	b7dd                	j	8000512e <exec+0x2c6>
    8000514a:	e1243423          	sd	s2,-504(s0)
    8000514e:	b7c5                	j	8000512e <exec+0x2c6>
    80005150:	e1243423          	sd	s2,-504(s0)
    80005154:	bfe9                	j	8000512e <exec+0x2c6>
  sz = sz1;
    80005156:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000515a:	4481                	li	s1,0
    8000515c:	bfc9                	j	8000512e <exec+0x2c6>
  sz = sz1;
    8000515e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005162:	4481                	li	s1,0
    80005164:	b7e9                	j	8000512e <exec+0x2c6>
  sz = sz1;
    80005166:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000516a:	4481                	li	s1,0
    8000516c:	b7c9                	j	8000512e <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000516e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005172:	2b05                	addiw	s6,s6,1
    80005174:	0389899b          	addiw	s3,s3,56
    80005178:	e8045783          	lhu	a5,-384(s0)
    8000517c:	e2fb5be3          	bge	s6,a5,80004fb2 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005180:	2981                	sext.w	s3,s3
    80005182:	03800713          	li	a4,56
    80005186:	86ce                	mv	a3,s3
    80005188:	e1040613          	addi	a2,s0,-496
    8000518c:	4581                	li	a1,0
    8000518e:	8526                	mv	a0,s1
    80005190:	fffff097          	auipc	ra,0xfffff
    80005194:	a86080e7          	jalr	-1402(ra) # 80003c16 <readi>
    80005198:	03800793          	li	a5,56
    8000519c:	f8f517e3          	bne	a0,a5,8000512a <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800051a0:	e1042783          	lw	a5,-496(s0)
    800051a4:	4705                	li	a4,1
    800051a6:	fce796e3          	bne	a5,a4,80005172 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800051aa:	e3843603          	ld	a2,-456(s0)
    800051ae:	e3043783          	ld	a5,-464(s0)
    800051b2:	f8f669e3          	bltu	a2,a5,80005144 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051b6:	e2043783          	ld	a5,-480(s0)
    800051ba:	963e                	add	a2,a2,a5
    800051bc:	f8f667e3          	bltu	a2,a5,8000514a <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051c0:	85ca                	mv	a1,s2
    800051c2:	855e                	mv	a0,s7
    800051c4:	ffffc097          	auipc	ra,0xffffc
    800051c8:	224080e7          	jalr	548(ra) # 800013e8 <uvmalloc>
    800051cc:	e0a43423          	sd	a0,-504(s0)
    800051d0:	d141                	beqz	a0,80005150 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    800051d2:	e2043d03          	ld	s10,-480(s0)
    800051d6:	df043783          	ld	a5,-528(s0)
    800051da:	00fd77b3          	and	a5,s10,a5
    800051de:	fba1                	bnez	a5,8000512e <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051e0:	e1842d83          	lw	s11,-488(s0)
    800051e4:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051e8:	f80c03e3          	beqz	s8,8000516e <exec+0x306>
    800051ec:	8a62                	mv	s4,s8
    800051ee:	4901                	li	s2,0
    800051f0:	b345                	j	80004f90 <exec+0x128>

00000000800051f2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051f2:	7179                	addi	sp,sp,-48
    800051f4:	f406                	sd	ra,40(sp)
    800051f6:	f022                	sd	s0,32(sp)
    800051f8:	ec26                	sd	s1,24(sp)
    800051fa:	e84a                	sd	s2,16(sp)
    800051fc:	1800                	addi	s0,sp,48
    800051fe:	892e                	mv	s2,a1
    80005200:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005202:	fdc40593          	addi	a1,s0,-36
    80005206:	ffffe097          	auipc	ra,0xffffe
    8000520a:	bea080e7          	jalr	-1046(ra) # 80002df0 <argint>
    8000520e:	04054063          	bltz	a0,8000524e <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005212:	fdc42703          	lw	a4,-36(s0)
    80005216:	47bd                	li	a5,15
    80005218:	02e7ed63          	bltu	a5,a4,80005252 <argfd+0x60>
    8000521c:	ffffd097          	auipc	ra,0xffffd
    80005220:	98a080e7          	jalr	-1654(ra) # 80001ba6 <myproc>
    80005224:	fdc42703          	lw	a4,-36(s0)
    80005228:	01a70793          	addi	a5,a4,26
    8000522c:	078e                	slli	a5,a5,0x3
    8000522e:	953e                	add	a0,a0,a5
    80005230:	611c                	ld	a5,0(a0)
    80005232:	c395                	beqz	a5,80005256 <argfd+0x64>
    return -1;
  if(pfd)
    80005234:	00090463          	beqz	s2,8000523c <argfd+0x4a>
    *pfd = fd;
    80005238:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000523c:	4501                	li	a0,0
  if(pf)
    8000523e:	c091                	beqz	s1,80005242 <argfd+0x50>
    *pf = f;
    80005240:	e09c                	sd	a5,0(s1)
}
    80005242:	70a2                	ld	ra,40(sp)
    80005244:	7402                	ld	s0,32(sp)
    80005246:	64e2                	ld	s1,24(sp)
    80005248:	6942                	ld	s2,16(sp)
    8000524a:	6145                	addi	sp,sp,48
    8000524c:	8082                	ret
    return -1;
    8000524e:	557d                	li	a0,-1
    80005250:	bfcd                	j	80005242 <argfd+0x50>
    return -1;
    80005252:	557d                	li	a0,-1
    80005254:	b7fd                	j	80005242 <argfd+0x50>
    80005256:	557d                	li	a0,-1
    80005258:	b7ed                	j	80005242 <argfd+0x50>

000000008000525a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000525a:	1101                	addi	sp,sp,-32
    8000525c:	ec06                	sd	ra,24(sp)
    8000525e:	e822                	sd	s0,16(sp)
    80005260:	e426                	sd	s1,8(sp)
    80005262:	1000                	addi	s0,sp,32
    80005264:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005266:	ffffd097          	auipc	ra,0xffffd
    8000526a:	940080e7          	jalr	-1728(ra) # 80001ba6 <myproc>
    8000526e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005270:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005274:	4501                	li	a0,0
    80005276:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005278:	6398                	ld	a4,0(a5)
    8000527a:	cb19                	beqz	a4,80005290 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000527c:	2505                	addiw	a0,a0,1
    8000527e:	07a1                	addi	a5,a5,8
    80005280:	fed51ce3          	bne	a0,a3,80005278 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005284:	557d                	li	a0,-1
}
    80005286:	60e2                	ld	ra,24(sp)
    80005288:	6442                	ld	s0,16(sp)
    8000528a:	64a2                	ld	s1,8(sp)
    8000528c:	6105                	addi	sp,sp,32
    8000528e:	8082                	ret
      p->ofile[fd] = f;
    80005290:	01a50793          	addi	a5,a0,26
    80005294:	078e                	slli	a5,a5,0x3
    80005296:	963e                	add	a2,a2,a5
    80005298:	e204                	sd	s1,0(a2)
      return fd;
    8000529a:	b7f5                	j	80005286 <fdalloc+0x2c>

000000008000529c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000529c:	715d                	addi	sp,sp,-80
    8000529e:	e486                	sd	ra,72(sp)
    800052a0:	e0a2                	sd	s0,64(sp)
    800052a2:	fc26                	sd	s1,56(sp)
    800052a4:	f84a                	sd	s2,48(sp)
    800052a6:	f44e                	sd	s3,40(sp)
    800052a8:	f052                	sd	s4,32(sp)
    800052aa:	ec56                	sd	s5,24(sp)
    800052ac:	0880                	addi	s0,sp,80
    800052ae:	89ae                	mv	s3,a1
    800052b0:	8ab2                	mv	s5,a2
    800052b2:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052b4:	fb040593          	addi	a1,s0,-80
    800052b8:	fffff097          	auipc	ra,0xfffff
    800052bc:	e7e080e7          	jalr	-386(ra) # 80004136 <nameiparent>
    800052c0:	892a                	mv	s2,a0
    800052c2:	12050f63          	beqz	a0,80005400 <create+0x164>
    return 0;

  ilock(dp);
    800052c6:	ffffe097          	auipc	ra,0xffffe
    800052ca:	69c080e7          	jalr	1692(ra) # 80003962 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052ce:	4601                	li	a2,0
    800052d0:	fb040593          	addi	a1,s0,-80
    800052d4:	854a                	mv	a0,s2
    800052d6:	fffff097          	auipc	ra,0xfffff
    800052da:	b70080e7          	jalr	-1168(ra) # 80003e46 <dirlookup>
    800052de:	84aa                	mv	s1,a0
    800052e0:	c921                	beqz	a0,80005330 <create+0x94>
    iunlockput(dp);
    800052e2:	854a                	mv	a0,s2
    800052e4:	fffff097          	auipc	ra,0xfffff
    800052e8:	8e0080e7          	jalr	-1824(ra) # 80003bc4 <iunlockput>
    ilock(ip);
    800052ec:	8526                	mv	a0,s1
    800052ee:	ffffe097          	auipc	ra,0xffffe
    800052f2:	674080e7          	jalr	1652(ra) # 80003962 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052f6:	2981                	sext.w	s3,s3
    800052f8:	4789                	li	a5,2
    800052fa:	02f99463          	bne	s3,a5,80005322 <create+0x86>
    800052fe:	0444d783          	lhu	a5,68(s1)
    80005302:	37f9                	addiw	a5,a5,-2
    80005304:	17c2                	slli	a5,a5,0x30
    80005306:	93c1                	srli	a5,a5,0x30
    80005308:	4705                	li	a4,1
    8000530a:	00f76c63          	bltu	a4,a5,80005322 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000530e:	8526                	mv	a0,s1
    80005310:	60a6                	ld	ra,72(sp)
    80005312:	6406                	ld	s0,64(sp)
    80005314:	74e2                	ld	s1,56(sp)
    80005316:	7942                	ld	s2,48(sp)
    80005318:	79a2                	ld	s3,40(sp)
    8000531a:	7a02                	ld	s4,32(sp)
    8000531c:	6ae2                	ld	s5,24(sp)
    8000531e:	6161                	addi	sp,sp,80
    80005320:	8082                	ret
    iunlockput(ip);
    80005322:	8526                	mv	a0,s1
    80005324:	fffff097          	auipc	ra,0xfffff
    80005328:	8a0080e7          	jalr	-1888(ra) # 80003bc4 <iunlockput>
    return 0;
    8000532c:	4481                	li	s1,0
    8000532e:	b7c5                	j	8000530e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005330:	85ce                	mv	a1,s3
    80005332:	00092503          	lw	a0,0(s2)
    80005336:	ffffe097          	auipc	ra,0xffffe
    8000533a:	494080e7          	jalr	1172(ra) # 800037ca <ialloc>
    8000533e:	84aa                	mv	s1,a0
    80005340:	c529                	beqz	a0,8000538a <create+0xee>
  ilock(ip);
    80005342:	ffffe097          	auipc	ra,0xffffe
    80005346:	620080e7          	jalr	1568(ra) # 80003962 <ilock>
  ip->major = major;
    8000534a:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000534e:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005352:	4785                	li	a5,1
    80005354:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005358:	8526                	mv	a0,s1
    8000535a:	ffffe097          	auipc	ra,0xffffe
    8000535e:	53e080e7          	jalr	1342(ra) # 80003898 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005362:	2981                	sext.w	s3,s3
    80005364:	4785                	li	a5,1
    80005366:	02f98a63          	beq	s3,a5,8000539a <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000536a:	40d0                	lw	a2,4(s1)
    8000536c:	fb040593          	addi	a1,s0,-80
    80005370:	854a                	mv	a0,s2
    80005372:	fffff097          	auipc	ra,0xfffff
    80005376:	ce4080e7          	jalr	-796(ra) # 80004056 <dirlink>
    8000537a:	06054b63          	bltz	a0,800053f0 <create+0x154>
  iunlockput(dp);
    8000537e:	854a                	mv	a0,s2
    80005380:	fffff097          	auipc	ra,0xfffff
    80005384:	844080e7          	jalr	-1980(ra) # 80003bc4 <iunlockput>
  return ip;
    80005388:	b759                	j	8000530e <create+0x72>
    panic("create: ialloc");
    8000538a:	00003517          	auipc	a0,0x3
    8000538e:	37650513          	addi	a0,a0,886 # 80008700 <syscalls+0x2b0>
    80005392:	ffffb097          	auipc	ra,0xffffb
    80005396:	19e080e7          	jalr	414(ra) # 80000530 <panic>
    dp->nlink++;  // for ".."
    8000539a:	04a95783          	lhu	a5,74(s2)
    8000539e:	2785                	addiw	a5,a5,1
    800053a0:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800053a4:	854a                	mv	a0,s2
    800053a6:	ffffe097          	auipc	ra,0xffffe
    800053aa:	4f2080e7          	jalr	1266(ra) # 80003898 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053ae:	40d0                	lw	a2,4(s1)
    800053b0:	00003597          	auipc	a1,0x3
    800053b4:	36058593          	addi	a1,a1,864 # 80008710 <syscalls+0x2c0>
    800053b8:	8526                	mv	a0,s1
    800053ba:	fffff097          	auipc	ra,0xfffff
    800053be:	c9c080e7          	jalr	-868(ra) # 80004056 <dirlink>
    800053c2:	00054f63          	bltz	a0,800053e0 <create+0x144>
    800053c6:	00492603          	lw	a2,4(s2)
    800053ca:	00003597          	auipc	a1,0x3
    800053ce:	34e58593          	addi	a1,a1,846 # 80008718 <syscalls+0x2c8>
    800053d2:	8526                	mv	a0,s1
    800053d4:	fffff097          	auipc	ra,0xfffff
    800053d8:	c82080e7          	jalr	-894(ra) # 80004056 <dirlink>
    800053dc:	f80557e3          	bgez	a0,8000536a <create+0xce>
      panic("create dots");
    800053e0:	00003517          	auipc	a0,0x3
    800053e4:	34050513          	addi	a0,a0,832 # 80008720 <syscalls+0x2d0>
    800053e8:	ffffb097          	auipc	ra,0xffffb
    800053ec:	148080e7          	jalr	328(ra) # 80000530 <panic>
    panic("create: dirlink");
    800053f0:	00003517          	auipc	a0,0x3
    800053f4:	34050513          	addi	a0,a0,832 # 80008730 <syscalls+0x2e0>
    800053f8:	ffffb097          	auipc	ra,0xffffb
    800053fc:	138080e7          	jalr	312(ra) # 80000530 <panic>
    return 0;
    80005400:	84aa                	mv	s1,a0
    80005402:	b731                	j	8000530e <create+0x72>

0000000080005404 <sys_dup>:
{
    80005404:	7179                	addi	sp,sp,-48
    80005406:	f406                	sd	ra,40(sp)
    80005408:	f022                	sd	s0,32(sp)
    8000540a:	ec26                	sd	s1,24(sp)
    8000540c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000540e:	fd840613          	addi	a2,s0,-40
    80005412:	4581                	li	a1,0
    80005414:	4501                	li	a0,0
    80005416:	00000097          	auipc	ra,0x0
    8000541a:	ddc080e7          	jalr	-548(ra) # 800051f2 <argfd>
    return -1;
    8000541e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005420:	02054363          	bltz	a0,80005446 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005424:	fd843503          	ld	a0,-40(s0)
    80005428:	00000097          	auipc	ra,0x0
    8000542c:	e32080e7          	jalr	-462(ra) # 8000525a <fdalloc>
    80005430:	84aa                	mv	s1,a0
    return -1;
    80005432:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005434:	00054963          	bltz	a0,80005446 <sys_dup+0x42>
  filedup(f);
    80005438:	fd843503          	ld	a0,-40(s0)
    8000543c:	fffff097          	auipc	ra,0xfffff
    80005440:	37a080e7          	jalr	890(ra) # 800047b6 <filedup>
  return fd;
    80005444:	87a6                	mv	a5,s1
}
    80005446:	853e                	mv	a0,a5
    80005448:	70a2                	ld	ra,40(sp)
    8000544a:	7402                	ld	s0,32(sp)
    8000544c:	64e2                	ld	s1,24(sp)
    8000544e:	6145                	addi	sp,sp,48
    80005450:	8082                	ret

0000000080005452 <sys_read>:
{
    80005452:	7179                	addi	sp,sp,-48
    80005454:	f406                	sd	ra,40(sp)
    80005456:	f022                	sd	s0,32(sp)
    80005458:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000545a:	fe840613          	addi	a2,s0,-24
    8000545e:	4581                	li	a1,0
    80005460:	4501                	li	a0,0
    80005462:	00000097          	auipc	ra,0x0
    80005466:	d90080e7          	jalr	-624(ra) # 800051f2 <argfd>
    return -1;
    8000546a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000546c:	04054163          	bltz	a0,800054ae <sys_read+0x5c>
    80005470:	fe440593          	addi	a1,s0,-28
    80005474:	4509                	li	a0,2
    80005476:	ffffe097          	auipc	ra,0xffffe
    8000547a:	97a080e7          	jalr	-1670(ra) # 80002df0 <argint>
    return -1;
    8000547e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005480:	02054763          	bltz	a0,800054ae <sys_read+0x5c>
    80005484:	fd840593          	addi	a1,s0,-40
    80005488:	4505                	li	a0,1
    8000548a:	ffffe097          	auipc	ra,0xffffe
    8000548e:	988080e7          	jalr	-1656(ra) # 80002e12 <argaddr>
    return -1;
    80005492:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005494:	00054d63          	bltz	a0,800054ae <sys_read+0x5c>
  return fileread(f, p, n);
    80005498:	fe442603          	lw	a2,-28(s0)
    8000549c:	fd843583          	ld	a1,-40(s0)
    800054a0:	fe843503          	ld	a0,-24(s0)
    800054a4:	fffff097          	auipc	ra,0xfffff
    800054a8:	49e080e7          	jalr	1182(ra) # 80004942 <fileread>
    800054ac:	87aa                	mv	a5,a0
}
    800054ae:	853e                	mv	a0,a5
    800054b0:	70a2                	ld	ra,40(sp)
    800054b2:	7402                	ld	s0,32(sp)
    800054b4:	6145                	addi	sp,sp,48
    800054b6:	8082                	ret

00000000800054b8 <sys_write>:
{
    800054b8:	7179                	addi	sp,sp,-48
    800054ba:	f406                	sd	ra,40(sp)
    800054bc:	f022                	sd	s0,32(sp)
    800054be:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054c0:	fe840613          	addi	a2,s0,-24
    800054c4:	4581                	li	a1,0
    800054c6:	4501                	li	a0,0
    800054c8:	00000097          	auipc	ra,0x0
    800054cc:	d2a080e7          	jalr	-726(ra) # 800051f2 <argfd>
    return -1;
    800054d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054d2:	04054163          	bltz	a0,80005514 <sys_write+0x5c>
    800054d6:	fe440593          	addi	a1,s0,-28
    800054da:	4509                	li	a0,2
    800054dc:	ffffe097          	auipc	ra,0xffffe
    800054e0:	914080e7          	jalr	-1772(ra) # 80002df0 <argint>
    return -1;
    800054e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054e6:	02054763          	bltz	a0,80005514 <sys_write+0x5c>
    800054ea:	fd840593          	addi	a1,s0,-40
    800054ee:	4505                	li	a0,1
    800054f0:	ffffe097          	auipc	ra,0xffffe
    800054f4:	922080e7          	jalr	-1758(ra) # 80002e12 <argaddr>
    return -1;
    800054f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054fa:	00054d63          	bltz	a0,80005514 <sys_write+0x5c>
  return filewrite(f, p, n);
    800054fe:	fe442603          	lw	a2,-28(s0)
    80005502:	fd843583          	ld	a1,-40(s0)
    80005506:	fe843503          	ld	a0,-24(s0)
    8000550a:	fffff097          	auipc	ra,0xfffff
    8000550e:	4fa080e7          	jalr	1274(ra) # 80004a04 <filewrite>
    80005512:	87aa                	mv	a5,a0
}
    80005514:	853e                	mv	a0,a5
    80005516:	70a2                	ld	ra,40(sp)
    80005518:	7402                	ld	s0,32(sp)
    8000551a:	6145                	addi	sp,sp,48
    8000551c:	8082                	ret

000000008000551e <sys_close>:
{
    8000551e:	1101                	addi	sp,sp,-32
    80005520:	ec06                	sd	ra,24(sp)
    80005522:	e822                	sd	s0,16(sp)
    80005524:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005526:	fe040613          	addi	a2,s0,-32
    8000552a:	fec40593          	addi	a1,s0,-20
    8000552e:	4501                	li	a0,0
    80005530:	00000097          	auipc	ra,0x0
    80005534:	cc2080e7          	jalr	-830(ra) # 800051f2 <argfd>
    return -1;
    80005538:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000553a:	02054463          	bltz	a0,80005562 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000553e:	ffffc097          	auipc	ra,0xffffc
    80005542:	668080e7          	jalr	1640(ra) # 80001ba6 <myproc>
    80005546:	fec42783          	lw	a5,-20(s0)
    8000554a:	07e9                	addi	a5,a5,26
    8000554c:	078e                	slli	a5,a5,0x3
    8000554e:	97aa                	add	a5,a5,a0
    80005550:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005554:	fe043503          	ld	a0,-32(s0)
    80005558:	fffff097          	auipc	ra,0xfffff
    8000555c:	2b0080e7          	jalr	688(ra) # 80004808 <fileclose>
  return 0;
    80005560:	4781                	li	a5,0
}
    80005562:	853e                	mv	a0,a5
    80005564:	60e2                	ld	ra,24(sp)
    80005566:	6442                	ld	s0,16(sp)
    80005568:	6105                	addi	sp,sp,32
    8000556a:	8082                	ret

000000008000556c <sys_fstat>:
{
    8000556c:	1101                	addi	sp,sp,-32
    8000556e:	ec06                	sd	ra,24(sp)
    80005570:	e822                	sd	s0,16(sp)
    80005572:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005574:	fe840613          	addi	a2,s0,-24
    80005578:	4581                	li	a1,0
    8000557a:	4501                	li	a0,0
    8000557c:	00000097          	auipc	ra,0x0
    80005580:	c76080e7          	jalr	-906(ra) # 800051f2 <argfd>
    return -1;
    80005584:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005586:	02054563          	bltz	a0,800055b0 <sys_fstat+0x44>
    8000558a:	fe040593          	addi	a1,s0,-32
    8000558e:	4505                	li	a0,1
    80005590:	ffffe097          	auipc	ra,0xffffe
    80005594:	882080e7          	jalr	-1918(ra) # 80002e12 <argaddr>
    return -1;
    80005598:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000559a:	00054b63          	bltz	a0,800055b0 <sys_fstat+0x44>
  return filestat(f, st);
    8000559e:	fe043583          	ld	a1,-32(s0)
    800055a2:	fe843503          	ld	a0,-24(s0)
    800055a6:	fffff097          	auipc	ra,0xfffff
    800055aa:	32a080e7          	jalr	810(ra) # 800048d0 <filestat>
    800055ae:	87aa                	mv	a5,a0
}
    800055b0:	853e                	mv	a0,a5
    800055b2:	60e2                	ld	ra,24(sp)
    800055b4:	6442                	ld	s0,16(sp)
    800055b6:	6105                	addi	sp,sp,32
    800055b8:	8082                	ret

00000000800055ba <sys_link>:
{
    800055ba:	7169                	addi	sp,sp,-304
    800055bc:	f606                	sd	ra,296(sp)
    800055be:	f222                	sd	s0,288(sp)
    800055c0:	ee26                	sd	s1,280(sp)
    800055c2:	ea4a                	sd	s2,272(sp)
    800055c4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055c6:	08000613          	li	a2,128
    800055ca:	ed040593          	addi	a1,s0,-304
    800055ce:	4501                	li	a0,0
    800055d0:	ffffe097          	auipc	ra,0xffffe
    800055d4:	864080e7          	jalr	-1948(ra) # 80002e34 <argstr>
    return -1;
    800055d8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055da:	10054e63          	bltz	a0,800056f6 <sys_link+0x13c>
    800055de:	08000613          	li	a2,128
    800055e2:	f5040593          	addi	a1,s0,-176
    800055e6:	4505                	li	a0,1
    800055e8:	ffffe097          	auipc	ra,0xffffe
    800055ec:	84c080e7          	jalr	-1972(ra) # 80002e34 <argstr>
    return -1;
    800055f0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055f2:	10054263          	bltz	a0,800056f6 <sys_link+0x13c>
  begin_op();
    800055f6:	fffff097          	auipc	ra,0xfffff
    800055fa:	d3e080e7          	jalr	-706(ra) # 80004334 <begin_op>
  if((ip = namei(old)) == 0){
    800055fe:	ed040513          	addi	a0,s0,-304
    80005602:	fffff097          	auipc	ra,0xfffff
    80005606:	b16080e7          	jalr	-1258(ra) # 80004118 <namei>
    8000560a:	84aa                	mv	s1,a0
    8000560c:	c551                	beqz	a0,80005698 <sys_link+0xde>
  ilock(ip);
    8000560e:	ffffe097          	auipc	ra,0xffffe
    80005612:	354080e7          	jalr	852(ra) # 80003962 <ilock>
  if(ip->type == T_DIR){
    80005616:	04449703          	lh	a4,68(s1)
    8000561a:	4785                	li	a5,1
    8000561c:	08f70463          	beq	a4,a5,800056a4 <sys_link+0xea>
  ip->nlink++;
    80005620:	04a4d783          	lhu	a5,74(s1)
    80005624:	2785                	addiw	a5,a5,1
    80005626:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000562a:	8526                	mv	a0,s1
    8000562c:	ffffe097          	auipc	ra,0xffffe
    80005630:	26c080e7          	jalr	620(ra) # 80003898 <iupdate>
  iunlock(ip);
    80005634:	8526                	mv	a0,s1
    80005636:	ffffe097          	auipc	ra,0xffffe
    8000563a:	3ee080e7          	jalr	1006(ra) # 80003a24 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000563e:	fd040593          	addi	a1,s0,-48
    80005642:	f5040513          	addi	a0,s0,-176
    80005646:	fffff097          	auipc	ra,0xfffff
    8000564a:	af0080e7          	jalr	-1296(ra) # 80004136 <nameiparent>
    8000564e:	892a                	mv	s2,a0
    80005650:	c935                	beqz	a0,800056c4 <sys_link+0x10a>
  ilock(dp);
    80005652:	ffffe097          	auipc	ra,0xffffe
    80005656:	310080e7          	jalr	784(ra) # 80003962 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000565a:	00092703          	lw	a4,0(s2)
    8000565e:	409c                	lw	a5,0(s1)
    80005660:	04f71d63          	bne	a4,a5,800056ba <sys_link+0x100>
    80005664:	40d0                	lw	a2,4(s1)
    80005666:	fd040593          	addi	a1,s0,-48
    8000566a:	854a                	mv	a0,s2
    8000566c:	fffff097          	auipc	ra,0xfffff
    80005670:	9ea080e7          	jalr	-1558(ra) # 80004056 <dirlink>
    80005674:	04054363          	bltz	a0,800056ba <sys_link+0x100>
  iunlockput(dp);
    80005678:	854a                	mv	a0,s2
    8000567a:	ffffe097          	auipc	ra,0xffffe
    8000567e:	54a080e7          	jalr	1354(ra) # 80003bc4 <iunlockput>
  iput(ip);
    80005682:	8526                	mv	a0,s1
    80005684:	ffffe097          	auipc	ra,0xffffe
    80005688:	498080e7          	jalr	1176(ra) # 80003b1c <iput>
  end_op();
    8000568c:	fffff097          	auipc	ra,0xfffff
    80005690:	d28080e7          	jalr	-728(ra) # 800043b4 <end_op>
  return 0;
    80005694:	4781                	li	a5,0
    80005696:	a085                	j	800056f6 <sys_link+0x13c>
    end_op();
    80005698:	fffff097          	auipc	ra,0xfffff
    8000569c:	d1c080e7          	jalr	-740(ra) # 800043b4 <end_op>
    return -1;
    800056a0:	57fd                	li	a5,-1
    800056a2:	a891                	j	800056f6 <sys_link+0x13c>
    iunlockput(ip);
    800056a4:	8526                	mv	a0,s1
    800056a6:	ffffe097          	auipc	ra,0xffffe
    800056aa:	51e080e7          	jalr	1310(ra) # 80003bc4 <iunlockput>
    end_op();
    800056ae:	fffff097          	auipc	ra,0xfffff
    800056b2:	d06080e7          	jalr	-762(ra) # 800043b4 <end_op>
    return -1;
    800056b6:	57fd                	li	a5,-1
    800056b8:	a83d                	j	800056f6 <sys_link+0x13c>
    iunlockput(dp);
    800056ba:	854a                	mv	a0,s2
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	508080e7          	jalr	1288(ra) # 80003bc4 <iunlockput>
  ilock(ip);
    800056c4:	8526                	mv	a0,s1
    800056c6:	ffffe097          	auipc	ra,0xffffe
    800056ca:	29c080e7          	jalr	668(ra) # 80003962 <ilock>
  ip->nlink--;
    800056ce:	04a4d783          	lhu	a5,74(s1)
    800056d2:	37fd                	addiw	a5,a5,-1
    800056d4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056d8:	8526                	mv	a0,s1
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	1be080e7          	jalr	446(ra) # 80003898 <iupdate>
  iunlockput(ip);
    800056e2:	8526                	mv	a0,s1
    800056e4:	ffffe097          	auipc	ra,0xffffe
    800056e8:	4e0080e7          	jalr	1248(ra) # 80003bc4 <iunlockput>
  end_op();
    800056ec:	fffff097          	auipc	ra,0xfffff
    800056f0:	cc8080e7          	jalr	-824(ra) # 800043b4 <end_op>
  return -1;
    800056f4:	57fd                	li	a5,-1
}
    800056f6:	853e                	mv	a0,a5
    800056f8:	70b2                	ld	ra,296(sp)
    800056fa:	7412                	ld	s0,288(sp)
    800056fc:	64f2                	ld	s1,280(sp)
    800056fe:	6952                	ld	s2,272(sp)
    80005700:	6155                	addi	sp,sp,304
    80005702:	8082                	ret

0000000080005704 <sys_unlink>:
{
    80005704:	7151                	addi	sp,sp,-240
    80005706:	f586                	sd	ra,232(sp)
    80005708:	f1a2                	sd	s0,224(sp)
    8000570a:	eda6                	sd	s1,216(sp)
    8000570c:	e9ca                	sd	s2,208(sp)
    8000570e:	e5ce                	sd	s3,200(sp)
    80005710:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005712:	08000613          	li	a2,128
    80005716:	f3040593          	addi	a1,s0,-208
    8000571a:	4501                	li	a0,0
    8000571c:	ffffd097          	auipc	ra,0xffffd
    80005720:	718080e7          	jalr	1816(ra) # 80002e34 <argstr>
    80005724:	18054163          	bltz	a0,800058a6 <sys_unlink+0x1a2>
  begin_op();
    80005728:	fffff097          	auipc	ra,0xfffff
    8000572c:	c0c080e7          	jalr	-1012(ra) # 80004334 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005730:	fb040593          	addi	a1,s0,-80
    80005734:	f3040513          	addi	a0,s0,-208
    80005738:	fffff097          	auipc	ra,0xfffff
    8000573c:	9fe080e7          	jalr	-1538(ra) # 80004136 <nameiparent>
    80005740:	84aa                	mv	s1,a0
    80005742:	c979                	beqz	a0,80005818 <sys_unlink+0x114>
  ilock(dp);
    80005744:	ffffe097          	auipc	ra,0xffffe
    80005748:	21e080e7          	jalr	542(ra) # 80003962 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000574c:	00003597          	auipc	a1,0x3
    80005750:	fc458593          	addi	a1,a1,-60 # 80008710 <syscalls+0x2c0>
    80005754:	fb040513          	addi	a0,s0,-80
    80005758:	ffffe097          	auipc	ra,0xffffe
    8000575c:	6d4080e7          	jalr	1748(ra) # 80003e2c <namecmp>
    80005760:	14050a63          	beqz	a0,800058b4 <sys_unlink+0x1b0>
    80005764:	00003597          	auipc	a1,0x3
    80005768:	fb458593          	addi	a1,a1,-76 # 80008718 <syscalls+0x2c8>
    8000576c:	fb040513          	addi	a0,s0,-80
    80005770:	ffffe097          	auipc	ra,0xffffe
    80005774:	6bc080e7          	jalr	1724(ra) # 80003e2c <namecmp>
    80005778:	12050e63          	beqz	a0,800058b4 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000577c:	f2c40613          	addi	a2,s0,-212
    80005780:	fb040593          	addi	a1,s0,-80
    80005784:	8526                	mv	a0,s1
    80005786:	ffffe097          	auipc	ra,0xffffe
    8000578a:	6c0080e7          	jalr	1728(ra) # 80003e46 <dirlookup>
    8000578e:	892a                	mv	s2,a0
    80005790:	12050263          	beqz	a0,800058b4 <sys_unlink+0x1b0>
  ilock(ip);
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	1ce080e7          	jalr	462(ra) # 80003962 <ilock>
  if(ip->nlink < 1)
    8000579c:	04a91783          	lh	a5,74(s2)
    800057a0:	08f05263          	blez	a5,80005824 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057a4:	04491703          	lh	a4,68(s2)
    800057a8:	4785                	li	a5,1
    800057aa:	08f70563          	beq	a4,a5,80005834 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057ae:	4641                	li	a2,16
    800057b0:	4581                	li	a1,0
    800057b2:	fc040513          	addi	a0,s0,-64
    800057b6:	ffffb097          	auipc	ra,0xffffb
    800057ba:	51c080e7          	jalr	1308(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057be:	4741                	li	a4,16
    800057c0:	f2c42683          	lw	a3,-212(s0)
    800057c4:	fc040613          	addi	a2,s0,-64
    800057c8:	4581                	li	a1,0
    800057ca:	8526                	mv	a0,s1
    800057cc:	ffffe097          	auipc	ra,0xffffe
    800057d0:	542080e7          	jalr	1346(ra) # 80003d0e <writei>
    800057d4:	47c1                	li	a5,16
    800057d6:	0af51563          	bne	a0,a5,80005880 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057da:	04491703          	lh	a4,68(s2)
    800057de:	4785                	li	a5,1
    800057e0:	0af70863          	beq	a4,a5,80005890 <sys_unlink+0x18c>
  iunlockput(dp);
    800057e4:	8526                	mv	a0,s1
    800057e6:	ffffe097          	auipc	ra,0xffffe
    800057ea:	3de080e7          	jalr	990(ra) # 80003bc4 <iunlockput>
  ip->nlink--;
    800057ee:	04a95783          	lhu	a5,74(s2)
    800057f2:	37fd                	addiw	a5,a5,-1
    800057f4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057f8:	854a                	mv	a0,s2
    800057fa:	ffffe097          	auipc	ra,0xffffe
    800057fe:	09e080e7          	jalr	158(ra) # 80003898 <iupdate>
  iunlockput(ip);
    80005802:	854a                	mv	a0,s2
    80005804:	ffffe097          	auipc	ra,0xffffe
    80005808:	3c0080e7          	jalr	960(ra) # 80003bc4 <iunlockput>
  end_op();
    8000580c:	fffff097          	auipc	ra,0xfffff
    80005810:	ba8080e7          	jalr	-1112(ra) # 800043b4 <end_op>
  return 0;
    80005814:	4501                	li	a0,0
    80005816:	a84d                	j	800058c8 <sys_unlink+0x1c4>
    end_op();
    80005818:	fffff097          	auipc	ra,0xfffff
    8000581c:	b9c080e7          	jalr	-1124(ra) # 800043b4 <end_op>
    return -1;
    80005820:	557d                	li	a0,-1
    80005822:	a05d                	j	800058c8 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005824:	00003517          	auipc	a0,0x3
    80005828:	f1c50513          	addi	a0,a0,-228 # 80008740 <syscalls+0x2f0>
    8000582c:	ffffb097          	auipc	ra,0xffffb
    80005830:	d04080e7          	jalr	-764(ra) # 80000530 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005834:	04c92703          	lw	a4,76(s2)
    80005838:	02000793          	li	a5,32
    8000583c:	f6e7f9e3          	bgeu	a5,a4,800057ae <sys_unlink+0xaa>
    80005840:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005844:	4741                	li	a4,16
    80005846:	86ce                	mv	a3,s3
    80005848:	f1840613          	addi	a2,s0,-232
    8000584c:	4581                	li	a1,0
    8000584e:	854a                	mv	a0,s2
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	3c6080e7          	jalr	966(ra) # 80003c16 <readi>
    80005858:	47c1                	li	a5,16
    8000585a:	00f51b63          	bne	a0,a5,80005870 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000585e:	f1845783          	lhu	a5,-232(s0)
    80005862:	e7a1                	bnez	a5,800058aa <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005864:	29c1                	addiw	s3,s3,16
    80005866:	04c92783          	lw	a5,76(s2)
    8000586a:	fcf9ede3          	bltu	s3,a5,80005844 <sys_unlink+0x140>
    8000586e:	b781                	j	800057ae <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005870:	00003517          	auipc	a0,0x3
    80005874:	ee850513          	addi	a0,a0,-280 # 80008758 <syscalls+0x308>
    80005878:	ffffb097          	auipc	ra,0xffffb
    8000587c:	cb8080e7          	jalr	-840(ra) # 80000530 <panic>
    panic("unlink: writei");
    80005880:	00003517          	auipc	a0,0x3
    80005884:	ef050513          	addi	a0,a0,-272 # 80008770 <syscalls+0x320>
    80005888:	ffffb097          	auipc	ra,0xffffb
    8000588c:	ca8080e7          	jalr	-856(ra) # 80000530 <panic>
    dp->nlink--;
    80005890:	04a4d783          	lhu	a5,74(s1)
    80005894:	37fd                	addiw	a5,a5,-1
    80005896:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000589a:	8526                	mv	a0,s1
    8000589c:	ffffe097          	auipc	ra,0xffffe
    800058a0:	ffc080e7          	jalr	-4(ra) # 80003898 <iupdate>
    800058a4:	b781                	j	800057e4 <sys_unlink+0xe0>
    return -1;
    800058a6:	557d                	li	a0,-1
    800058a8:	a005                	j	800058c8 <sys_unlink+0x1c4>
    iunlockput(ip);
    800058aa:	854a                	mv	a0,s2
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	318080e7          	jalr	792(ra) # 80003bc4 <iunlockput>
  iunlockput(dp);
    800058b4:	8526                	mv	a0,s1
    800058b6:	ffffe097          	auipc	ra,0xffffe
    800058ba:	30e080e7          	jalr	782(ra) # 80003bc4 <iunlockput>
  end_op();
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	af6080e7          	jalr	-1290(ra) # 800043b4 <end_op>
  return -1;
    800058c6:	557d                	li	a0,-1
}
    800058c8:	70ae                	ld	ra,232(sp)
    800058ca:	740e                	ld	s0,224(sp)
    800058cc:	64ee                	ld	s1,216(sp)
    800058ce:	694e                	ld	s2,208(sp)
    800058d0:	69ae                	ld	s3,200(sp)
    800058d2:	616d                	addi	sp,sp,240
    800058d4:	8082                	ret

00000000800058d6 <sys_open>:

uint64
sys_open(void)
{
    800058d6:	7131                	addi	sp,sp,-192
    800058d8:	fd06                	sd	ra,184(sp)
    800058da:	f922                	sd	s0,176(sp)
    800058dc:	f526                	sd	s1,168(sp)
    800058de:	f14a                	sd	s2,160(sp)
    800058e0:	ed4e                	sd	s3,152(sp)
    800058e2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058e4:	08000613          	li	a2,128
    800058e8:	f5040593          	addi	a1,s0,-176
    800058ec:	4501                	li	a0,0
    800058ee:	ffffd097          	auipc	ra,0xffffd
    800058f2:	546080e7          	jalr	1350(ra) # 80002e34 <argstr>
    return -1;
    800058f6:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058f8:	0c054163          	bltz	a0,800059ba <sys_open+0xe4>
    800058fc:	f4c40593          	addi	a1,s0,-180
    80005900:	4505                	li	a0,1
    80005902:	ffffd097          	auipc	ra,0xffffd
    80005906:	4ee080e7          	jalr	1262(ra) # 80002df0 <argint>
    8000590a:	0a054863          	bltz	a0,800059ba <sys_open+0xe4>

  begin_op();
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	a26080e7          	jalr	-1498(ra) # 80004334 <begin_op>

  if(omode & O_CREATE){
    80005916:	f4c42783          	lw	a5,-180(s0)
    8000591a:	2007f793          	andi	a5,a5,512
    8000591e:	cbdd                	beqz	a5,800059d4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005920:	4681                	li	a3,0
    80005922:	4601                	li	a2,0
    80005924:	4589                	li	a1,2
    80005926:	f5040513          	addi	a0,s0,-176
    8000592a:	00000097          	auipc	ra,0x0
    8000592e:	972080e7          	jalr	-1678(ra) # 8000529c <create>
    80005932:	892a                	mv	s2,a0
    if(ip == 0){
    80005934:	c959                	beqz	a0,800059ca <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005936:	04491703          	lh	a4,68(s2)
    8000593a:	478d                	li	a5,3
    8000593c:	00f71763          	bne	a4,a5,8000594a <sys_open+0x74>
    80005940:	04695703          	lhu	a4,70(s2)
    80005944:	47a5                	li	a5,9
    80005946:	0ce7ec63          	bltu	a5,a4,80005a1e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000594a:	fffff097          	auipc	ra,0xfffff
    8000594e:	e02080e7          	jalr	-510(ra) # 8000474c <filealloc>
    80005952:	89aa                	mv	s3,a0
    80005954:	10050263          	beqz	a0,80005a58 <sys_open+0x182>
    80005958:	00000097          	auipc	ra,0x0
    8000595c:	902080e7          	jalr	-1790(ra) # 8000525a <fdalloc>
    80005960:	84aa                	mv	s1,a0
    80005962:	0e054663          	bltz	a0,80005a4e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005966:	04491703          	lh	a4,68(s2)
    8000596a:	478d                	li	a5,3
    8000596c:	0cf70463          	beq	a4,a5,80005a34 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005970:	4789                	li	a5,2
    80005972:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005976:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000597a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000597e:	f4c42783          	lw	a5,-180(s0)
    80005982:	0017c713          	xori	a4,a5,1
    80005986:	8b05                	andi	a4,a4,1
    80005988:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000598c:	0037f713          	andi	a4,a5,3
    80005990:	00e03733          	snez	a4,a4
    80005994:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005998:	4007f793          	andi	a5,a5,1024
    8000599c:	c791                	beqz	a5,800059a8 <sys_open+0xd2>
    8000599e:	04491703          	lh	a4,68(s2)
    800059a2:	4789                	li	a5,2
    800059a4:	08f70f63          	beq	a4,a5,80005a42 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059a8:	854a                	mv	a0,s2
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	07a080e7          	jalr	122(ra) # 80003a24 <iunlock>
  end_op();
    800059b2:	fffff097          	auipc	ra,0xfffff
    800059b6:	a02080e7          	jalr	-1534(ra) # 800043b4 <end_op>

  return fd;
}
    800059ba:	8526                	mv	a0,s1
    800059bc:	70ea                	ld	ra,184(sp)
    800059be:	744a                	ld	s0,176(sp)
    800059c0:	74aa                	ld	s1,168(sp)
    800059c2:	790a                	ld	s2,160(sp)
    800059c4:	69ea                	ld	s3,152(sp)
    800059c6:	6129                	addi	sp,sp,192
    800059c8:	8082                	ret
      end_op();
    800059ca:	fffff097          	auipc	ra,0xfffff
    800059ce:	9ea080e7          	jalr	-1558(ra) # 800043b4 <end_op>
      return -1;
    800059d2:	b7e5                	j	800059ba <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059d4:	f5040513          	addi	a0,s0,-176
    800059d8:	ffffe097          	auipc	ra,0xffffe
    800059dc:	740080e7          	jalr	1856(ra) # 80004118 <namei>
    800059e0:	892a                	mv	s2,a0
    800059e2:	c905                	beqz	a0,80005a12 <sys_open+0x13c>
    ilock(ip);
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	f7e080e7          	jalr	-130(ra) # 80003962 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059ec:	04491703          	lh	a4,68(s2)
    800059f0:	4785                	li	a5,1
    800059f2:	f4f712e3          	bne	a4,a5,80005936 <sys_open+0x60>
    800059f6:	f4c42783          	lw	a5,-180(s0)
    800059fa:	dba1                	beqz	a5,8000594a <sys_open+0x74>
      iunlockput(ip);
    800059fc:	854a                	mv	a0,s2
    800059fe:	ffffe097          	auipc	ra,0xffffe
    80005a02:	1c6080e7          	jalr	454(ra) # 80003bc4 <iunlockput>
      end_op();
    80005a06:	fffff097          	auipc	ra,0xfffff
    80005a0a:	9ae080e7          	jalr	-1618(ra) # 800043b4 <end_op>
      return -1;
    80005a0e:	54fd                	li	s1,-1
    80005a10:	b76d                	j	800059ba <sys_open+0xe4>
      end_op();
    80005a12:	fffff097          	auipc	ra,0xfffff
    80005a16:	9a2080e7          	jalr	-1630(ra) # 800043b4 <end_op>
      return -1;
    80005a1a:	54fd                	li	s1,-1
    80005a1c:	bf79                	j	800059ba <sys_open+0xe4>
    iunlockput(ip);
    80005a1e:	854a                	mv	a0,s2
    80005a20:	ffffe097          	auipc	ra,0xffffe
    80005a24:	1a4080e7          	jalr	420(ra) # 80003bc4 <iunlockput>
    end_op();
    80005a28:	fffff097          	auipc	ra,0xfffff
    80005a2c:	98c080e7          	jalr	-1652(ra) # 800043b4 <end_op>
    return -1;
    80005a30:	54fd                	li	s1,-1
    80005a32:	b761                	j	800059ba <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a34:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a38:	04691783          	lh	a5,70(s2)
    80005a3c:	02f99223          	sh	a5,36(s3)
    80005a40:	bf2d                	j	8000597a <sys_open+0xa4>
    itrunc(ip);
    80005a42:	854a                	mv	a0,s2
    80005a44:	ffffe097          	auipc	ra,0xffffe
    80005a48:	02c080e7          	jalr	44(ra) # 80003a70 <itrunc>
    80005a4c:	bfb1                	j	800059a8 <sys_open+0xd2>
      fileclose(f);
    80005a4e:	854e                	mv	a0,s3
    80005a50:	fffff097          	auipc	ra,0xfffff
    80005a54:	db8080e7          	jalr	-584(ra) # 80004808 <fileclose>
    iunlockput(ip);
    80005a58:	854a                	mv	a0,s2
    80005a5a:	ffffe097          	auipc	ra,0xffffe
    80005a5e:	16a080e7          	jalr	362(ra) # 80003bc4 <iunlockput>
    end_op();
    80005a62:	fffff097          	auipc	ra,0xfffff
    80005a66:	952080e7          	jalr	-1710(ra) # 800043b4 <end_op>
    return -1;
    80005a6a:	54fd                	li	s1,-1
    80005a6c:	b7b9                	j	800059ba <sys_open+0xe4>

0000000080005a6e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a6e:	7175                	addi	sp,sp,-144
    80005a70:	e506                	sd	ra,136(sp)
    80005a72:	e122                	sd	s0,128(sp)
    80005a74:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a76:	fffff097          	auipc	ra,0xfffff
    80005a7a:	8be080e7          	jalr	-1858(ra) # 80004334 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a7e:	08000613          	li	a2,128
    80005a82:	f7040593          	addi	a1,s0,-144
    80005a86:	4501                	li	a0,0
    80005a88:	ffffd097          	auipc	ra,0xffffd
    80005a8c:	3ac080e7          	jalr	940(ra) # 80002e34 <argstr>
    80005a90:	02054963          	bltz	a0,80005ac2 <sys_mkdir+0x54>
    80005a94:	4681                	li	a3,0
    80005a96:	4601                	li	a2,0
    80005a98:	4585                	li	a1,1
    80005a9a:	f7040513          	addi	a0,s0,-144
    80005a9e:	fffff097          	auipc	ra,0xfffff
    80005aa2:	7fe080e7          	jalr	2046(ra) # 8000529c <create>
    80005aa6:	cd11                	beqz	a0,80005ac2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	11c080e7          	jalr	284(ra) # 80003bc4 <iunlockput>
  end_op();
    80005ab0:	fffff097          	auipc	ra,0xfffff
    80005ab4:	904080e7          	jalr	-1788(ra) # 800043b4 <end_op>
  return 0;
    80005ab8:	4501                	li	a0,0
}
    80005aba:	60aa                	ld	ra,136(sp)
    80005abc:	640a                	ld	s0,128(sp)
    80005abe:	6149                	addi	sp,sp,144
    80005ac0:	8082                	ret
    end_op();
    80005ac2:	fffff097          	auipc	ra,0xfffff
    80005ac6:	8f2080e7          	jalr	-1806(ra) # 800043b4 <end_op>
    return -1;
    80005aca:	557d                	li	a0,-1
    80005acc:	b7fd                	j	80005aba <sys_mkdir+0x4c>

0000000080005ace <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ace:	7135                	addi	sp,sp,-160
    80005ad0:	ed06                	sd	ra,152(sp)
    80005ad2:	e922                	sd	s0,144(sp)
    80005ad4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ad6:	fffff097          	auipc	ra,0xfffff
    80005ada:	85e080e7          	jalr	-1954(ra) # 80004334 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ade:	08000613          	li	a2,128
    80005ae2:	f7040593          	addi	a1,s0,-144
    80005ae6:	4501                	li	a0,0
    80005ae8:	ffffd097          	auipc	ra,0xffffd
    80005aec:	34c080e7          	jalr	844(ra) # 80002e34 <argstr>
    80005af0:	04054a63          	bltz	a0,80005b44 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005af4:	f6c40593          	addi	a1,s0,-148
    80005af8:	4505                	li	a0,1
    80005afa:	ffffd097          	auipc	ra,0xffffd
    80005afe:	2f6080e7          	jalr	758(ra) # 80002df0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b02:	04054163          	bltz	a0,80005b44 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b06:	f6840593          	addi	a1,s0,-152
    80005b0a:	4509                	li	a0,2
    80005b0c:	ffffd097          	auipc	ra,0xffffd
    80005b10:	2e4080e7          	jalr	740(ra) # 80002df0 <argint>
     argint(1, &major) < 0 ||
    80005b14:	02054863          	bltz	a0,80005b44 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b18:	f6841683          	lh	a3,-152(s0)
    80005b1c:	f6c41603          	lh	a2,-148(s0)
    80005b20:	458d                	li	a1,3
    80005b22:	f7040513          	addi	a0,s0,-144
    80005b26:	fffff097          	auipc	ra,0xfffff
    80005b2a:	776080e7          	jalr	1910(ra) # 8000529c <create>
     argint(2, &minor) < 0 ||
    80005b2e:	c919                	beqz	a0,80005b44 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b30:	ffffe097          	auipc	ra,0xffffe
    80005b34:	094080e7          	jalr	148(ra) # 80003bc4 <iunlockput>
  end_op();
    80005b38:	fffff097          	auipc	ra,0xfffff
    80005b3c:	87c080e7          	jalr	-1924(ra) # 800043b4 <end_op>
  return 0;
    80005b40:	4501                	li	a0,0
    80005b42:	a031                	j	80005b4e <sys_mknod+0x80>
    end_op();
    80005b44:	fffff097          	auipc	ra,0xfffff
    80005b48:	870080e7          	jalr	-1936(ra) # 800043b4 <end_op>
    return -1;
    80005b4c:	557d                	li	a0,-1
}
    80005b4e:	60ea                	ld	ra,152(sp)
    80005b50:	644a                	ld	s0,144(sp)
    80005b52:	610d                	addi	sp,sp,160
    80005b54:	8082                	ret

0000000080005b56 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b56:	7135                	addi	sp,sp,-160
    80005b58:	ed06                	sd	ra,152(sp)
    80005b5a:	e922                	sd	s0,144(sp)
    80005b5c:	e526                	sd	s1,136(sp)
    80005b5e:	e14a                	sd	s2,128(sp)
    80005b60:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b62:	ffffc097          	auipc	ra,0xffffc
    80005b66:	044080e7          	jalr	68(ra) # 80001ba6 <myproc>
    80005b6a:	892a                	mv	s2,a0
  
  begin_op();
    80005b6c:	ffffe097          	auipc	ra,0xffffe
    80005b70:	7c8080e7          	jalr	1992(ra) # 80004334 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b74:	08000613          	li	a2,128
    80005b78:	f6040593          	addi	a1,s0,-160
    80005b7c:	4501                	li	a0,0
    80005b7e:	ffffd097          	auipc	ra,0xffffd
    80005b82:	2b6080e7          	jalr	694(ra) # 80002e34 <argstr>
    80005b86:	04054b63          	bltz	a0,80005bdc <sys_chdir+0x86>
    80005b8a:	f6040513          	addi	a0,s0,-160
    80005b8e:	ffffe097          	auipc	ra,0xffffe
    80005b92:	58a080e7          	jalr	1418(ra) # 80004118 <namei>
    80005b96:	84aa                	mv	s1,a0
    80005b98:	c131                	beqz	a0,80005bdc <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b9a:	ffffe097          	auipc	ra,0xffffe
    80005b9e:	dc8080e7          	jalr	-568(ra) # 80003962 <ilock>
  if(ip->type != T_DIR){
    80005ba2:	04449703          	lh	a4,68(s1)
    80005ba6:	4785                	li	a5,1
    80005ba8:	04f71063          	bne	a4,a5,80005be8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005bac:	8526                	mv	a0,s1
    80005bae:	ffffe097          	auipc	ra,0xffffe
    80005bb2:	e76080e7          	jalr	-394(ra) # 80003a24 <iunlock>
  iput(p->cwd);
    80005bb6:	15093503          	ld	a0,336(s2)
    80005bba:	ffffe097          	auipc	ra,0xffffe
    80005bbe:	f62080e7          	jalr	-158(ra) # 80003b1c <iput>
  end_op();
    80005bc2:	ffffe097          	auipc	ra,0xffffe
    80005bc6:	7f2080e7          	jalr	2034(ra) # 800043b4 <end_op>
  p->cwd = ip;
    80005bca:	14993823          	sd	s1,336(s2)
  return 0;
    80005bce:	4501                	li	a0,0
}
    80005bd0:	60ea                	ld	ra,152(sp)
    80005bd2:	644a                	ld	s0,144(sp)
    80005bd4:	64aa                	ld	s1,136(sp)
    80005bd6:	690a                	ld	s2,128(sp)
    80005bd8:	610d                	addi	sp,sp,160
    80005bda:	8082                	ret
    end_op();
    80005bdc:	ffffe097          	auipc	ra,0xffffe
    80005be0:	7d8080e7          	jalr	2008(ra) # 800043b4 <end_op>
    return -1;
    80005be4:	557d                	li	a0,-1
    80005be6:	b7ed                	j	80005bd0 <sys_chdir+0x7a>
    iunlockput(ip);
    80005be8:	8526                	mv	a0,s1
    80005bea:	ffffe097          	auipc	ra,0xffffe
    80005bee:	fda080e7          	jalr	-38(ra) # 80003bc4 <iunlockput>
    end_op();
    80005bf2:	ffffe097          	auipc	ra,0xffffe
    80005bf6:	7c2080e7          	jalr	1986(ra) # 800043b4 <end_op>
    return -1;
    80005bfa:	557d                	li	a0,-1
    80005bfc:	bfd1                	j	80005bd0 <sys_chdir+0x7a>

0000000080005bfe <sys_exec>:

uint64
sys_exec(void)
{
    80005bfe:	7145                	addi	sp,sp,-464
    80005c00:	e786                	sd	ra,456(sp)
    80005c02:	e3a2                	sd	s0,448(sp)
    80005c04:	ff26                	sd	s1,440(sp)
    80005c06:	fb4a                	sd	s2,432(sp)
    80005c08:	f74e                	sd	s3,424(sp)
    80005c0a:	f352                	sd	s4,416(sp)
    80005c0c:	ef56                	sd	s5,408(sp)
    80005c0e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c10:	08000613          	li	a2,128
    80005c14:	f4040593          	addi	a1,s0,-192
    80005c18:	4501                	li	a0,0
    80005c1a:	ffffd097          	auipc	ra,0xffffd
    80005c1e:	21a080e7          	jalr	538(ra) # 80002e34 <argstr>
    return -1;
    80005c22:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c24:	0c054a63          	bltz	a0,80005cf8 <sys_exec+0xfa>
    80005c28:	e3840593          	addi	a1,s0,-456
    80005c2c:	4505                	li	a0,1
    80005c2e:	ffffd097          	auipc	ra,0xffffd
    80005c32:	1e4080e7          	jalr	484(ra) # 80002e12 <argaddr>
    80005c36:	0c054163          	bltz	a0,80005cf8 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c3a:	10000613          	li	a2,256
    80005c3e:	4581                	li	a1,0
    80005c40:	e4040513          	addi	a0,s0,-448
    80005c44:	ffffb097          	auipc	ra,0xffffb
    80005c48:	08e080e7          	jalr	142(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c4c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c50:	89a6                	mv	s3,s1
    80005c52:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c54:	02000a13          	li	s4,32
    80005c58:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c5c:	00391513          	slli	a0,s2,0x3
    80005c60:	e3040593          	addi	a1,s0,-464
    80005c64:	e3843783          	ld	a5,-456(s0)
    80005c68:	953e                	add	a0,a0,a5
    80005c6a:	ffffd097          	auipc	ra,0xffffd
    80005c6e:	0ec080e7          	jalr	236(ra) # 80002d56 <fetchaddr>
    80005c72:	02054a63          	bltz	a0,80005ca6 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c76:	e3043783          	ld	a5,-464(s0)
    80005c7a:	c3b9                	beqz	a5,80005cc0 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c7c:	ffffb097          	auipc	ra,0xffffb
    80005c80:	e6a080e7          	jalr	-406(ra) # 80000ae6 <kalloc>
    80005c84:	85aa                	mv	a1,a0
    80005c86:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c8a:	cd11                	beqz	a0,80005ca6 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c8c:	6605                	lui	a2,0x1
    80005c8e:	e3043503          	ld	a0,-464(s0)
    80005c92:	ffffd097          	auipc	ra,0xffffd
    80005c96:	116080e7          	jalr	278(ra) # 80002da8 <fetchstr>
    80005c9a:	00054663          	bltz	a0,80005ca6 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c9e:	0905                	addi	s2,s2,1
    80005ca0:	09a1                	addi	s3,s3,8
    80005ca2:	fb491be3          	bne	s2,s4,80005c58 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ca6:	10048913          	addi	s2,s1,256
    80005caa:	6088                	ld	a0,0(s1)
    80005cac:	c529                	beqz	a0,80005cf6 <sys_exec+0xf8>
    kfree(argv[i]);
    80005cae:	ffffb097          	auipc	ra,0xffffb
    80005cb2:	d3c080e7          	jalr	-708(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cb6:	04a1                	addi	s1,s1,8
    80005cb8:	ff2499e3          	bne	s1,s2,80005caa <sys_exec+0xac>
  return -1;
    80005cbc:	597d                	li	s2,-1
    80005cbe:	a82d                	j	80005cf8 <sys_exec+0xfa>
      argv[i] = 0;
    80005cc0:	0a8e                	slli	s5,s5,0x3
    80005cc2:	fc040793          	addi	a5,s0,-64
    80005cc6:	9abe                	add	s5,s5,a5
    80005cc8:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ccc:	e4040593          	addi	a1,s0,-448
    80005cd0:	f4040513          	addi	a0,s0,-192
    80005cd4:	fffff097          	auipc	ra,0xfffff
    80005cd8:	194080e7          	jalr	404(ra) # 80004e68 <exec>
    80005cdc:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cde:	10048993          	addi	s3,s1,256
    80005ce2:	6088                	ld	a0,0(s1)
    80005ce4:	c911                	beqz	a0,80005cf8 <sys_exec+0xfa>
    kfree(argv[i]);
    80005ce6:	ffffb097          	auipc	ra,0xffffb
    80005cea:	d04080e7          	jalr	-764(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cee:	04a1                	addi	s1,s1,8
    80005cf0:	ff3499e3          	bne	s1,s3,80005ce2 <sys_exec+0xe4>
    80005cf4:	a011                	j	80005cf8 <sys_exec+0xfa>
  return -1;
    80005cf6:	597d                	li	s2,-1
}
    80005cf8:	854a                	mv	a0,s2
    80005cfa:	60be                	ld	ra,456(sp)
    80005cfc:	641e                	ld	s0,448(sp)
    80005cfe:	74fa                	ld	s1,440(sp)
    80005d00:	795a                	ld	s2,432(sp)
    80005d02:	79ba                	ld	s3,424(sp)
    80005d04:	7a1a                	ld	s4,416(sp)
    80005d06:	6afa                	ld	s5,408(sp)
    80005d08:	6179                	addi	sp,sp,464
    80005d0a:	8082                	ret

0000000080005d0c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d0c:	7139                	addi	sp,sp,-64
    80005d0e:	fc06                	sd	ra,56(sp)
    80005d10:	f822                	sd	s0,48(sp)
    80005d12:	f426                	sd	s1,40(sp)
    80005d14:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d16:	ffffc097          	auipc	ra,0xffffc
    80005d1a:	e90080e7          	jalr	-368(ra) # 80001ba6 <myproc>
    80005d1e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d20:	fd840593          	addi	a1,s0,-40
    80005d24:	4501                	li	a0,0
    80005d26:	ffffd097          	auipc	ra,0xffffd
    80005d2a:	0ec080e7          	jalr	236(ra) # 80002e12 <argaddr>
    return -1;
    80005d2e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d30:	0e054063          	bltz	a0,80005e10 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d34:	fc840593          	addi	a1,s0,-56
    80005d38:	fd040513          	addi	a0,s0,-48
    80005d3c:	fffff097          	auipc	ra,0xfffff
    80005d40:	dfc080e7          	jalr	-516(ra) # 80004b38 <pipealloc>
    return -1;
    80005d44:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d46:	0c054563          	bltz	a0,80005e10 <sys_pipe+0x104>
  fd0 = -1;
    80005d4a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d4e:	fd043503          	ld	a0,-48(s0)
    80005d52:	fffff097          	auipc	ra,0xfffff
    80005d56:	508080e7          	jalr	1288(ra) # 8000525a <fdalloc>
    80005d5a:	fca42223          	sw	a0,-60(s0)
    80005d5e:	08054c63          	bltz	a0,80005df6 <sys_pipe+0xea>
    80005d62:	fc843503          	ld	a0,-56(s0)
    80005d66:	fffff097          	auipc	ra,0xfffff
    80005d6a:	4f4080e7          	jalr	1268(ra) # 8000525a <fdalloc>
    80005d6e:	fca42023          	sw	a0,-64(s0)
    80005d72:	06054863          	bltz	a0,80005de2 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d76:	4691                	li	a3,4
    80005d78:	fc440613          	addi	a2,s0,-60
    80005d7c:	fd843583          	ld	a1,-40(s0)
    80005d80:	68a8                	ld	a0,80(s1)
    80005d82:	ffffc097          	auipc	ra,0xffffc
    80005d86:	8a4080e7          	jalr	-1884(ra) # 80001626 <copyout>
    80005d8a:	02054063          	bltz	a0,80005daa <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d8e:	4691                	li	a3,4
    80005d90:	fc040613          	addi	a2,s0,-64
    80005d94:	fd843583          	ld	a1,-40(s0)
    80005d98:	0591                	addi	a1,a1,4
    80005d9a:	68a8                	ld	a0,80(s1)
    80005d9c:	ffffc097          	auipc	ra,0xffffc
    80005da0:	88a080e7          	jalr	-1910(ra) # 80001626 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005da4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005da6:	06055563          	bgez	a0,80005e10 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005daa:	fc442783          	lw	a5,-60(s0)
    80005dae:	07e9                	addi	a5,a5,26
    80005db0:	078e                	slli	a5,a5,0x3
    80005db2:	97a6                	add	a5,a5,s1
    80005db4:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005db8:	fc042503          	lw	a0,-64(s0)
    80005dbc:	0569                	addi	a0,a0,26
    80005dbe:	050e                	slli	a0,a0,0x3
    80005dc0:	9526                	add	a0,a0,s1
    80005dc2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005dc6:	fd043503          	ld	a0,-48(s0)
    80005dca:	fffff097          	auipc	ra,0xfffff
    80005dce:	a3e080e7          	jalr	-1474(ra) # 80004808 <fileclose>
    fileclose(wf);
    80005dd2:	fc843503          	ld	a0,-56(s0)
    80005dd6:	fffff097          	auipc	ra,0xfffff
    80005dda:	a32080e7          	jalr	-1486(ra) # 80004808 <fileclose>
    return -1;
    80005dde:	57fd                	li	a5,-1
    80005de0:	a805                	j	80005e10 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005de2:	fc442783          	lw	a5,-60(s0)
    80005de6:	0007c863          	bltz	a5,80005df6 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005dea:	01a78513          	addi	a0,a5,26
    80005dee:	050e                	slli	a0,a0,0x3
    80005df0:	9526                	add	a0,a0,s1
    80005df2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005df6:	fd043503          	ld	a0,-48(s0)
    80005dfa:	fffff097          	auipc	ra,0xfffff
    80005dfe:	a0e080e7          	jalr	-1522(ra) # 80004808 <fileclose>
    fileclose(wf);
    80005e02:	fc843503          	ld	a0,-56(s0)
    80005e06:	fffff097          	auipc	ra,0xfffff
    80005e0a:	a02080e7          	jalr	-1534(ra) # 80004808 <fileclose>
    return -1;
    80005e0e:	57fd                	li	a5,-1
}
    80005e10:	853e                	mv	a0,a5
    80005e12:	70e2                	ld	ra,56(sp)
    80005e14:	7442                	ld	s0,48(sp)
    80005e16:	74a2                	ld	s1,40(sp)
    80005e18:	6121                	addi	sp,sp,64
    80005e1a:	8082                	ret

0000000080005e1c <sys_mmap>:

uint64
sys_mmap(void)
{
    80005e1c:	715d                	addi	sp,sp,-80
    80005e1e:	e486                	sd	ra,72(sp)
    80005e20:	e0a2                	sd	s0,64(sp)
    80005e22:	fc26                	sd	s1,56(sp)
    80005e24:	f84a                	sd	s2,48(sp)
    80005e26:	f44e                	sd	s3,40(sp)
    80005e28:	f052                	sd	s4,32(sp)
    80005e2a:	0880                	addi	s0,sp,80
  uint64 addr;
  int length, prot, flags, fd, offset;
  if(argaddr(0, &addr) < 0 || argint(1, &length) < 0 || argint(2, &prot) < 0 || argint(3, &flags) < 0 || argint(4, &fd) < 0 || argint(5, &offset) < 0){
    80005e2c:	fc840593          	addi	a1,s0,-56
    80005e30:	4501                	li	a0,0
    80005e32:	ffffd097          	auipc	ra,0xffffd
    80005e36:	fe0080e7          	jalr	-32(ra) # 80002e12 <argaddr>
    80005e3a:	16054e63          	bltz	a0,80005fb6 <sys_mmap+0x19a>
    80005e3e:	fc440593          	addi	a1,s0,-60
    80005e42:	4505                	li	a0,1
    80005e44:	ffffd097          	auipc	ra,0xffffd
    80005e48:	fac080e7          	jalr	-84(ra) # 80002df0 <argint>
    80005e4c:	16054e63          	bltz	a0,80005fc8 <sys_mmap+0x1ac>
    80005e50:	fc040593          	addi	a1,s0,-64
    80005e54:	4509                	li	a0,2
    80005e56:	ffffd097          	auipc	ra,0xffffd
    80005e5a:	f9a080e7          	jalr	-102(ra) # 80002df0 <argint>
    80005e5e:	16054763          	bltz	a0,80005fcc <sys_mmap+0x1b0>
    80005e62:	fbc40593          	addi	a1,s0,-68
    80005e66:	450d                	li	a0,3
    80005e68:	ffffd097          	auipc	ra,0xffffd
    80005e6c:	f88080e7          	jalr	-120(ra) # 80002df0 <argint>
    80005e70:	16054063          	bltz	a0,80005fd0 <sys_mmap+0x1b4>
    80005e74:	fb840593          	addi	a1,s0,-72
    80005e78:	4511                	li	a0,4
    80005e7a:	ffffd097          	auipc	ra,0xffffd
    80005e7e:	f76080e7          	jalr	-138(ra) # 80002df0 <argint>
    80005e82:	14054963          	bltz	a0,80005fd4 <sys_mmap+0x1b8>
    80005e86:	fb440593          	addi	a1,s0,-76
    80005e8a:	4515                	li	a0,5
    80005e8c:	ffffd097          	auipc	ra,0xffffd
    80005e90:	f64080e7          	jalr	-156(ra) # 80002df0 <argint>
    80005e94:	14054263          	bltz	a0,80005fd8 <sys_mmap+0x1bc>
    return -1;
  }

  if(addr != 0)
    80005e98:	fc843783          	ld	a5,-56(s0)
    80005e9c:	ef9d                	bnez	a5,80005eda <sys_mmap+0xbe>
    panic("mmap: addr not 0");
  if(offset != 0)
    80005e9e:	fb442783          	lw	a5,-76(s0)
    80005ea2:	e7a1                	bnez	a5,80005eea <sys_mmap+0xce>
    panic("mmap: offset not 0");

  struct proc *p = myproc();
    80005ea4:	ffffc097          	auipc	ra,0xffffc
    80005ea8:	d02080e7          	jalr	-766(ra) # 80001ba6 <myproc>
    80005eac:	892a                	mv	s2,a0
  struct file* f = p->ofile[fd];
    80005eae:	fb842783          	lw	a5,-72(s0)
    80005eb2:	07e9                	addi	a5,a5,26
    80005eb4:	078e                	slli	a5,a5,0x3
    80005eb6:	97aa                	add	a5,a5,a0
    80005eb8:	0007b983          	ld	s3,0(a5)

  int pte_flag = PTE_U;
  if (prot & PROT_WRITE) {
    80005ebc:	fc042783          	lw	a5,-64(s0)
    80005ec0:	0027f713          	andi	a4,a5,2
    80005ec4:	cb1d                	beqz	a4,80005efa <sys_mmap+0xde>
    if(!f->writable && !(flags & MAP_PRIVATE)) return -1; // map to a unwritable file with PROT_WRITE
    80005ec6:	0099c703          	lbu	a4,9(s3)
    80005eca:	eb71                	bnez	a4,80005f9e <sys_mmap+0x182>
    80005ecc:	fbc42703          	lw	a4,-68(s0)
    80005ed0:	8b09                	andi	a4,a4,2
    80005ed2:	557d                	li	a0,-1
    pte_flag |= PTE_W;
    80005ed4:	4a51                	li	s4,20
    if(!f->writable && !(flags & MAP_PRIVATE)) return -1; // map to a unwritable file with PROT_WRITE
    80005ed6:	e31d                	bnez	a4,80005efc <sys_mmap+0xe0>
    80005ed8:	a0c5                	j	80005fb8 <sys_mmap+0x19c>
    panic("mmap: addr not 0");
    80005eda:	00003517          	auipc	a0,0x3
    80005ede:	8a650513          	addi	a0,a0,-1882 # 80008780 <syscalls+0x330>
    80005ee2:	ffffa097          	auipc	ra,0xffffa
    80005ee6:	64e080e7          	jalr	1614(ra) # 80000530 <panic>
    panic("mmap: offset not 0");
    80005eea:	00003517          	auipc	a0,0x3
    80005eee:	8ae50513          	addi	a0,a0,-1874 # 80008798 <syscalls+0x348>
    80005ef2:	ffffa097          	auipc	ra,0xffffa
    80005ef6:	63e080e7          	jalr	1598(ra) # 80000530 <panic>
  int pte_flag = PTE_U;
    80005efa:	4a41                	li	s4,16
  }
  if (prot & PROT_READ) {
    80005efc:	8b85                	andi	a5,a5,1
    80005efe:	c799                	beqz	a5,80005f0c <sys_mmap+0xf0>
    if(!f->readable) return -1; // map to a unreadable file with PROT_READ
    80005f00:	0089c783          	lbu	a5,8(s3)
    80005f04:	557d                	li	a0,-1
    80005f06:	cbcd                	beqz	a5,80005fb8 <sys_mmap+0x19c>
    pte_flag |= PTE_R;
    80005f08:	002a6a13          	ori	s4,s4,2
  }

  struct vma* v = vma_alloc();
    80005f0c:	ffffc097          	auipc	ra,0xffffc
    80005f10:	7c0080e7          	jalr	1984(ra) # 800026cc <vma_alloc>
    80005f14:	84aa                	mv	s1,a0
  v->permission = pte_flag;
    80005f16:	03452023          	sw	s4,32(a0)
  v->length = length;
    80005f1a:	fc442783          	lw	a5,-60(s0)
    80005f1e:	e91c                	sd	a5,16(a0)
  v->off = offset;
    80005f20:	fb442783          	lw	a5,-76(s0)
    80005f24:	ed1c                	sd	a5,24(a0)
  v->file = myproc()->ofile[fd];
    80005f26:	ffffc097          	auipc	ra,0xffffc
    80005f2a:	c80080e7          	jalr	-896(ra) # 80001ba6 <myproc>
    80005f2e:	fb842783          	lw	a5,-72(s0)
    80005f32:	07e9                	addi	a5,a5,26
    80005f34:	078e                	slli	a5,a5,0x3
    80005f36:	97aa                	add	a5,a5,a0
    80005f38:	639c                	ld	a5,0(a5)
    80005f3a:	f49c                	sd	a5,40(s1)
  v->flags = flags;
    80005f3c:	fbc42783          	lw	a5,-68(s0)
    80005f40:	d0dc                	sw	a5,36(s1)
  filedup(f);
    80005f42:	854e                	mv	a0,s3
    80005f44:	fffff097          	auipc	ra,0xfffff
    80005f48:	872080e7          	jalr	-1934(ra) # 800047b6 <filedup>
  struct vma* pv = p->vma;
    80005f4c:	15893783          	ld	a5,344(s2)
  if(pv == 0){
    80005f50:	cba9                	beqz	a5,80005fa2 <sys_mmap+0x186>
    v->start = VMA_START;
    v->end = v->start + length;
    p->vma = v;
  }else{
    while(pv->next) pv = pv->next;
    80005f52:	873e                	mv	a4,a5
    80005f54:	7b9c                	ld	a5,48(a5)
    80005f56:	fff5                	bnez	a5,80005f52 <sys_mmap+0x136>
    v->start = PGROUNDUP(pv->end);
    80005f58:	671c                	ld	a5,8(a4)
    80005f5a:	6685                	lui	a3,0x1
    80005f5c:	16fd                	addi	a3,a3,-1
    80005f5e:	97b6                	add	a5,a5,a3
    80005f60:	76fd                	lui	a3,0xfffff
    80005f62:	8ff5                	and	a5,a5,a3
    80005f64:	e09c                	sd	a5,0(s1)
    v->end = v->start + length;
    80005f66:	fc442683          	lw	a3,-60(s0)
    80005f6a:	97b6                	add	a5,a5,a3
    80005f6c:	e49c                	sd	a5,8(s1)
    pv->next = v;
    80005f6e:	fb04                	sd	s1,48(a4)
    v->next = 0;
    80005f70:	0204b823          	sd	zero,48(s1)
  }
  addr = v->start;
    80005f74:	608c                	ld	a1,0(s1)
    80005f76:	fcb43423          	sd	a1,-56(s0)
  printf("mmap: [%p, %p)\n", addr, v->end);
    80005f7a:	6490                	ld	a2,8(s1)
    80005f7c:	00003517          	auipc	a0,0x3
    80005f80:	83450513          	addi	a0,a0,-1996 # 800087b0 <syscalls+0x360>
    80005f84:	ffffa097          	auipc	ra,0xffffa
    80005f88:	5f6080e7          	jalr	1526(ra) # 8000057a <printf>

  release(&v->lock);
    80005f8c:	03848513          	addi	a0,s1,56
    80005f90:	ffffb097          	auipc	ra,0xffffb
    80005f94:	cfa080e7          	jalr	-774(ra) # 80000c8a <release>
  return addr;
    80005f98:	fc843503          	ld	a0,-56(s0)
    80005f9c:	a831                	j	80005fb8 <sys_mmap+0x19c>
    pte_flag |= PTE_W;
    80005f9e:	4a51                	li	s4,20
    80005fa0:	bfb1                	j	80005efc <sys_mmap+0xe0>
    v->start = VMA_START;
    80005fa2:	4785                	li	a5,1
    80005fa4:	1796                	slli	a5,a5,0x25
    80005fa6:	e09c                	sd	a5,0(s1)
    v->end = v->start + length;
    80005fa8:	fc442703          	lw	a4,-60(s0)
    80005fac:	97ba                	add	a5,a5,a4
    80005fae:	e49c                	sd	a5,8(s1)
    p->vma = v;
    80005fb0:	14993c23          	sd	s1,344(s2)
    80005fb4:	b7c1                	j	80005f74 <sys_mmap+0x158>
    return -1;
    80005fb6:	557d                	li	a0,-1
}
    80005fb8:	60a6                	ld	ra,72(sp)
    80005fba:	6406                	ld	s0,64(sp)
    80005fbc:	74e2                	ld	s1,56(sp)
    80005fbe:	7942                	ld	s2,48(sp)
    80005fc0:	79a2                	ld	s3,40(sp)
    80005fc2:	7a02                	ld	s4,32(sp)
    80005fc4:	6161                	addi	sp,sp,80
    80005fc6:	8082                	ret
    return -1;
    80005fc8:	557d                	li	a0,-1
    80005fca:	b7fd                	j	80005fb8 <sys_mmap+0x19c>
    80005fcc:	557d                	li	a0,-1
    80005fce:	b7ed                	j	80005fb8 <sys_mmap+0x19c>
    80005fd0:	557d                	li	a0,-1
    80005fd2:	b7dd                	j	80005fb8 <sys_mmap+0x19c>
    80005fd4:	557d                	li	a0,-1
    80005fd6:	b7cd                	j	80005fb8 <sys_mmap+0x19c>
    80005fd8:	557d                	li	a0,-1
    80005fda:	bff9                	j	80005fb8 <sys_mmap+0x19c>

0000000080005fdc <sys_munmap>:

uint64
sys_munmap(void)
{
    80005fdc:	7139                	addi	sp,sp,-64
    80005fde:	fc06                	sd	ra,56(sp)
    80005fe0:	f822                	sd	s0,48(sp)
    80005fe2:	f426                	sd	s1,40(sp)
    80005fe4:	f04a                	sd	s2,32(sp)
    80005fe6:	ec4e                	sd	s3,24(sp)
    80005fe8:	0080                	addi	s0,sp,64
  uint64 addr;
  int length;
  if(argaddr(0, &addr) < 0 || argint(1, &length) < 0){
    80005fea:	fc840593          	addi	a1,s0,-56
    80005fee:	4501                	li	a0,0
    80005ff0:	ffffd097          	auipc	ra,0xffffd
    80005ff4:	e22080e7          	jalr	-478(ra) # 80002e12 <argaddr>
    80005ff8:	12054863          	bltz	a0,80006128 <sys_munmap+0x14c>
    80005ffc:	fc440593          	addi	a1,s0,-60
    80006000:	4505                	li	a0,1
    80006002:	ffffd097          	auipc	ra,0xffffd
    80006006:	dee080e7          	jalr	-530(ra) # 80002df0 <argint>
    8000600a:	12054163          	bltz	a0,8000612c <sys_munmap+0x150>
    return -1;
  }

  struct proc *p = myproc();
    8000600e:	ffffc097          	auipc	ra,0xffffc
    80006012:	b98080e7          	jalr	-1128(ra) # 80001ba6 <myproc>
    80006016:	89aa                	mv	s3,a0
  struct vma *v = p->vma;
    80006018:	15853483          	ld	s1,344(a0)
  struct vma *pre = 0;
  while(v != 0){
    8000601c:	10048a63          	beqz	s1,80006130 <sys_munmap+0x154>
    if(addr >= v->start && addr < v->end) break; // found
    80006020:	fc843583          	ld	a1,-56(s0)
  struct vma *pre = 0;
    80006024:	4901                	li	s2,0
    80006026:	a029                	j	80006030 <sys_munmap+0x54>
    pre = v;
    v = v->next;
    80006028:	789c                	ld	a5,48(s1)
  while(v != 0){
    8000602a:	8926                	mv	s2,s1
    8000602c:	cbb1                	beqz	a5,80006080 <sys_munmap+0xa4>
    v = v->next;
    8000602e:	84be                	mv	s1,a5
    if(addr >= v->start && addr < v->end) break; // found
    80006030:	609c                	ld	a5,0(s1)
    80006032:	fef5ebe3          	bltu	a1,a5,80006028 <sys_munmap+0x4c>
    80006036:	649c                	ld	a5,8(s1)
    80006038:	fef5f8e3          	bgeu	a1,a5,80006028 <sys_munmap+0x4c>
  }

  if(v == 0) return -1; // not mapped
  printf("munmap: %p %d\n", addr, length);
    8000603c:	fc442603          	lw	a2,-60(s0)
    80006040:	00002517          	auipc	a0,0x2
    80006044:	79850513          	addi	a0,a0,1944 # 800087d8 <syscalls+0x388>
    80006048:	ffffa097          	auipc	ra,0xffffa
    8000604c:	532080e7          	jalr	1330(ra) # 8000057a <printf>
  if(addr != v->start && addr + length != v->end) panic("munmap middle of vma");
    80006050:	fc843583          	ld	a1,-56(s0)
    80006054:	609c                	ld	a5,0(s1)
    80006056:	02b78f63          	beq	a5,a1,80006094 <sys_munmap+0xb8>
    8000605a:	fc442683          	lw	a3,-60(s0)
    8000605e:	649c                	ld	a5,8(s1)
    80006060:	95b6                	add	a1,a1,a3
    80006062:	02f59163          	bne	a1,a5,80006084 <sys_munmap+0xa8>
      v->off += length;
      v->length -= length;
    }
  }else{
    // free tail
    v->length -= length;
    80006066:	6898                	ld	a4,16(s1)
    80006068:	8f15                	sub	a4,a4,a3
    8000606a:	e898                	sd	a4,16(s1)
    v->end -= length;
    8000606c:	8f95                	sub	a5,a5,a3
    8000606e:	e49c                	sd	a5,8(s1)
  }
  return 0;
    80006070:	4501                	li	a0,0
}
    80006072:	70e2                	ld	ra,56(sp)
    80006074:	7442                	ld	s0,48(sp)
    80006076:	74a2                	ld	s1,40(sp)
    80006078:	7902                	ld	s2,32(sp)
    8000607a:	69e2                	ld	s3,24(sp)
    8000607c:	6121                	addi	sp,sp,64
    8000607e:	8082                	ret
  if(v == 0) return -1; // not mapped
    80006080:	557d                	li	a0,-1
    80006082:	bfc5                	j	80006072 <sys_munmap+0x96>
  if(addr != v->start && addr + length != v->end) panic("munmap middle of vma");
    80006084:	00002517          	auipc	a0,0x2
    80006088:	73c50513          	addi	a0,a0,1852 # 800087c0 <syscalls+0x370>
    8000608c:	ffffa097          	auipc	ra,0xffffa
    80006090:	4a4080e7          	jalr	1188(ra) # 80000530 <panic>
    writeback(v, addr, length);
    80006094:	fc442603          	lw	a2,-60(s0)
    80006098:	8526                	mv	a0,s1
    8000609a:	ffffc097          	auipc	ra,0xffffc
    8000609e:	84c080e7          	jalr	-1972(ra) # 800018e6 <writeback>
    uvmunmap(p->pagetable, addr, length / PGSIZE, 1);
    800060a2:	fc442783          	lw	a5,-60(s0)
    800060a6:	41f7d61b          	sraiw	a2,a5,0x1f
    800060aa:	0146561b          	srliw	a2,a2,0x14
    800060ae:	9e3d                	addw	a2,a2,a5
    800060b0:	4685                	li	a3,1
    800060b2:	40c6561b          	sraiw	a2,a2,0xc
    800060b6:	fc843583          	ld	a1,-56(s0)
    800060ba:	0509b503          	ld	a0,80(s3)
    800060be:	ffffb097          	auipc	ra,0xffffb
    800060c2:	19c080e7          	jalr	412(ra) # 8000125a <uvmunmap>
    if(length == v->length){
    800060c6:	fc442683          	lw	a3,-60(s0)
    800060ca:	689c                	ld	a5,16(s1)
    800060cc:	00f68e63          	beq	a3,a5,800060e8 <sys_munmap+0x10c>
      v->start -= length;
    800060d0:	6098                	ld	a4,0(s1)
    800060d2:	8f15                	sub	a4,a4,a3
    800060d4:	e098                	sd	a4,0(s1)
      v->off += length;
    800060d6:	fc442683          	lw	a3,-60(s0)
    800060da:	6c98                	ld	a4,24(s1)
    800060dc:	9736                	add	a4,a4,a3
    800060de:	ec98                	sd	a4,24(s1)
      v->length -= length;
    800060e0:	8f95                	sub	a5,a5,a3
    800060e2:	e89c                	sd	a5,16(s1)
  return 0;
    800060e4:	4501                	li	a0,0
    800060e6:	b771                	j	80006072 <sys_munmap+0x96>
      fileclose(v->file);
    800060e8:	7488                	ld	a0,40(s1)
    800060ea:	ffffe097          	auipc	ra,0xffffe
    800060ee:	71e080e7          	jalr	1822(ra) # 80004808 <fileclose>
      if(pre == 0){
    800060f2:	02090763          	beqz	s2,80006120 <sys_munmap+0x144>
        pre->next = v->next;
    800060f6:	789c                	ld	a5,48(s1)
    800060f8:	02f93823          	sd	a5,48(s2)
        v->next = 0;
    800060fc:	0204b823          	sd	zero,48(s1)
      acquire(&v->lock);
    80006100:	03848913          	addi	s2,s1,56
    80006104:	854a                	mv	a0,s2
    80006106:	ffffb097          	auipc	ra,0xffffb
    8000610a:	ad0080e7          	jalr	-1328(ra) # 80000bd6 <acquire>
      v->length = 0;
    8000610e:	0004b823          	sd	zero,16(s1)
      release(&v->lock);
    80006112:	854a                	mv	a0,s2
    80006114:	ffffb097          	auipc	ra,0xffffb
    80006118:	b76080e7          	jalr	-1162(ra) # 80000c8a <release>
  return 0;
    8000611c:	4501                	li	a0,0
    8000611e:	bf91                	j	80006072 <sys_munmap+0x96>
        p->vma = v->next; // head
    80006120:	789c                	ld	a5,48(s1)
    80006122:	14f9bc23          	sd	a5,344(s3)
    80006126:	bfe9                	j	80006100 <sys_munmap+0x124>
    return -1;
    80006128:	557d                	li	a0,-1
    8000612a:	b7a1                	j	80006072 <sys_munmap+0x96>
    8000612c:	557d                	li	a0,-1
    8000612e:	b791                	j	80006072 <sys_munmap+0x96>
  if(v == 0) return -1; // not mapped
    80006130:	557d                	li	a0,-1
    80006132:	b781                	j	80006072 <sys_munmap+0x96>
	...

0000000080006140 <kernelvec>:
    80006140:	7111                	addi	sp,sp,-256
    80006142:	e006                	sd	ra,0(sp)
    80006144:	e40a                	sd	sp,8(sp)
    80006146:	e80e                	sd	gp,16(sp)
    80006148:	ec12                	sd	tp,24(sp)
    8000614a:	f016                	sd	t0,32(sp)
    8000614c:	f41a                	sd	t1,40(sp)
    8000614e:	f81e                	sd	t2,48(sp)
    80006150:	fc22                	sd	s0,56(sp)
    80006152:	e0a6                	sd	s1,64(sp)
    80006154:	e4aa                	sd	a0,72(sp)
    80006156:	e8ae                	sd	a1,80(sp)
    80006158:	ecb2                	sd	a2,88(sp)
    8000615a:	f0b6                	sd	a3,96(sp)
    8000615c:	f4ba                	sd	a4,104(sp)
    8000615e:	f8be                	sd	a5,112(sp)
    80006160:	fcc2                	sd	a6,120(sp)
    80006162:	e146                	sd	a7,128(sp)
    80006164:	e54a                	sd	s2,136(sp)
    80006166:	e94e                	sd	s3,144(sp)
    80006168:	ed52                	sd	s4,152(sp)
    8000616a:	f156                	sd	s5,160(sp)
    8000616c:	f55a                	sd	s6,168(sp)
    8000616e:	f95e                	sd	s7,176(sp)
    80006170:	fd62                	sd	s8,184(sp)
    80006172:	e1e6                	sd	s9,192(sp)
    80006174:	e5ea                	sd	s10,200(sp)
    80006176:	e9ee                	sd	s11,208(sp)
    80006178:	edf2                	sd	t3,216(sp)
    8000617a:	f1f6                	sd	t4,224(sp)
    8000617c:	f5fa                	sd	t5,232(sp)
    8000617e:	f9fe                	sd	t6,240(sp)
    80006180:	aa3fc0ef          	jal	ra,80002c22 <kerneltrap>
    80006184:	6082                	ld	ra,0(sp)
    80006186:	6122                	ld	sp,8(sp)
    80006188:	61c2                	ld	gp,16(sp)
    8000618a:	7282                	ld	t0,32(sp)
    8000618c:	7322                	ld	t1,40(sp)
    8000618e:	73c2                	ld	t2,48(sp)
    80006190:	7462                	ld	s0,56(sp)
    80006192:	6486                	ld	s1,64(sp)
    80006194:	6526                	ld	a0,72(sp)
    80006196:	65c6                	ld	a1,80(sp)
    80006198:	6666                	ld	a2,88(sp)
    8000619a:	7686                	ld	a3,96(sp)
    8000619c:	7726                	ld	a4,104(sp)
    8000619e:	77c6                	ld	a5,112(sp)
    800061a0:	7866                	ld	a6,120(sp)
    800061a2:	688a                	ld	a7,128(sp)
    800061a4:	692a                	ld	s2,136(sp)
    800061a6:	69ca                	ld	s3,144(sp)
    800061a8:	6a6a                	ld	s4,152(sp)
    800061aa:	7a8a                	ld	s5,160(sp)
    800061ac:	7b2a                	ld	s6,168(sp)
    800061ae:	7bca                	ld	s7,176(sp)
    800061b0:	7c6a                	ld	s8,184(sp)
    800061b2:	6c8e                	ld	s9,192(sp)
    800061b4:	6d2e                	ld	s10,200(sp)
    800061b6:	6dce                	ld	s11,208(sp)
    800061b8:	6e6e                	ld	t3,216(sp)
    800061ba:	7e8e                	ld	t4,224(sp)
    800061bc:	7f2e                	ld	t5,232(sp)
    800061be:	7fce                	ld	t6,240(sp)
    800061c0:	6111                	addi	sp,sp,256
    800061c2:	10200073          	sret
    800061c6:	00000013          	nop
    800061ca:	00000013          	nop
    800061ce:	0001                	nop

00000000800061d0 <timervec>:
    800061d0:	34051573          	csrrw	a0,mscratch,a0
    800061d4:	e10c                	sd	a1,0(a0)
    800061d6:	e510                	sd	a2,8(a0)
    800061d8:	e914                	sd	a3,16(a0)
    800061da:	6d0c                	ld	a1,24(a0)
    800061dc:	7110                	ld	a2,32(a0)
    800061de:	6194                	ld	a3,0(a1)
    800061e0:	96b2                	add	a3,a3,a2
    800061e2:	e194                	sd	a3,0(a1)
    800061e4:	4589                	li	a1,2
    800061e6:	14459073          	csrw	sip,a1
    800061ea:	6914                	ld	a3,16(a0)
    800061ec:	6510                	ld	a2,8(a0)
    800061ee:	610c                	ld	a1,0(a0)
    800061f0:	34051573          	csrrw	a0,mscratch,a0
    800061f4:	30200073          	mret
	...

00000000800061fa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800061fa:	1141                	addi	sp,sp,-16
    800061fc:	e422                	sd	s0,8(sp)
    800061fe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006200:	0c0007b7          	lui	a5,0xc000
    80006204:	4705                	li	a4,1
    80006206:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006208:	c3d8                	sw	a4,4(a5)
}
    8000620a:	6422                	ld	s0,8(sp)
    8000620c:	0141                	addi	sp,sp,16
    8000620e:	8082                	ret

0000000080006210 <plicinithart>:

void
plicinithart(void)
{
    80006210:	1141                	addi	sp,sp,-16
    80006212:	e406                	sd	ra,8(sp)
    80006214:	e022                	sd	s0,0(sp)
    80006216:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006218:	ffffc097          	auipc	ra,0xffffc
    8000621c:	962080e7          	jalr	-1694(ra) # 80001b7a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006220:	0085171b          	slliw	a4,a0,0x8
    80006224:	0c0027b7          	lui	a5,0xc002
    80006228:	97ba                	add	a5,a5,a4
    8000622a:	40200713          	li	a4,1026
    8000622e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006232:	00d5151b          	slliw	a0,a0,0xd
    80006236:	0c2017b7          	lui	a5,0xc201
    8000623a:	953e                	add	a0,a0,a5
    8000623c:	00052023          	sw	zero,0(a0)
}
    80006240:	60a2                	ld	ra,8(sp)
    80006242:	6402                	ld	s0,0(sp)
    80006244:	0141                	addi	sp,sp,16
    80006246:	8082                	ret

0000000080006248 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006248:	1141                	addi	sp,sp,-16
    8000624a:	e406                	sd	ra,8(sp)
    8000624c:	e022                	sd	s0,0(sp)
    8000624e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006250:	ffffc097          	auipc	ra,0xffffc
    80006254:	92a080e7          	jalr	-1750(ra) # 80001b7a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006258:	00d5179b          	slliw	a5,a0,0xd
    8000625c:	0c201537          	lui	a0,0xc201
    80006260:	953e                	add	a0,a0,a5
  return irq;
}
    80006262:	4148                	lw	a0,4(a0)
    80006264:	60a2                	ld	ra,8(sp)
    80006266:	6402                	ld	s0,0(sp)
    80006268:	0141                	addi	sp,sp,16
    8000626a:	8082                	ret

000000008000626c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000626c:	1101                	addi	sp,sp,-32
    8000626e:	ec06                	sd	ra,24(sp)
    80006270:	e822                	sd	s0,16(sp)
    80006272:	e426                	sd	s1,8(sp)
    80006274:	1000                	addi	s0,sp,32
    80006276:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006278:	ffffc097          	auipc	ra,0xffffc
    8000627c:	902080e7          	jalr	-1790(ra) # 80001b7a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006280:	00d5151b          	slliw	a0,a0,0xd
    80006284:	0c2017b7          	lui	a5,0xc201
    80006288:	97aa                	add	a5,a5,a0
    8000628a:	c3c4                	sw	s1,4(a5)
}
    8000628c:	60e2                	ld	ra,24(sp)
    8000628e:	6442                	ld	s0,16(sp)
    80006290:	64a2                	ld	s1,8(sp)
    80006292:	6105                	addi	sp,sp,32
    80006294:	8082                	ret

0000000080006296 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006296:	1141                	addi	sp,sp,-16
    80006298:	e406                	sd	ra,8(sp)
    8000629a:	e022                	sd	s0,0(sp)
    8000629c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000629e:	479d                	li	a5,7
    800062a0:	06a7c963          	blt	a5,a0,80006312 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800062a4:	0001d797          	auipc	a5,0x1d
    800062a8:	d5c78793          	addi	a5,a5,-676 # 80023000 <disk>
    800062ac:	00a78733          	add	a4,a5,a0
    800062b0:	6789                	lui	a5,0x2
    800062b2:	97ba                	add	a5,a5,a4
    800062b4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800062b8:	e7ad                	bnez	a5,80006322 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800062ba:	00451793          	slli	a5,a0,0x4
    800062be:	0001f717          	auipc	a4,0x1f
    800062c2:	d4270713          	addi	a4,a4,-702 # 80025000 <disk+0x2000>
    800062c6:	6314                	ld	a3,0(a4)
    800062c8:	96be                	add	a3,a3,a5
    800062ca:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7ffd9000>
  disk.desc[i].len = 0;
    800062ce:	6314                	ld	a3,0(a4)
    800062d0:	96be                	add	a3,a3,a5
    800062d2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800062d6:	6314                	ld	a3,0(a4)
    800062d8:	96be                	add	a3,a3,a5
    800062da:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800062de:	6318                	ld	a4,0(a4)
    800062e0:	97ba                	add	a5,a5,a4
    800062e2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800062e6:	0001d797          	auipc	a5,0x1d
    800062ea:	d1a78793          	addi	a5,a5,-742 # 80023000 <disk>
    800062ee:	97aa                	add	a5,a5,a0
    800062f0:	6509                	lui	a0,0x2
    800062f2:	953e                	add	a0,a0,a5
    800062f4:	4785                	li	a5,1
    800062f6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800062fa:	0001f517          	auipc	a0,0x1f
    800062fe:	d1e50513          	addi	a0,a0,-738 # 80025018 <disk+0x2018>
    80006302:	ffffc097          	auipc	ra,0xffffc
    80006306:	194080e7          	jalr	404(ra) # 80002496 <wakeup>
}
    8000630a:	60a2                	ld	ra,8(sp)
    8000630c:	6402                	ld	s0,0(sp)
    8000630e:	0141                	addi	sp,sp,16
    80006310:	8082                	ret
    panic("free_desc 1");
    80006312:	00002517          	auipc	a0,0x2
    80006316:	4d650513          	addi	a0,a0,1238 # 800087e8 <syscalls+0x398>
    8000631a:	ffffa097          	auipc	ra,0xffffa
    8000631e:	216080e7          	jalr	534(ra) # 80000530 <panic>
    panic("free_desc 2");
    80006322:	00002517          	auipc	a0,0x2
    80006326:	4d650513          	addi	a0,a0,1238 # 800087f8 <syscalls+0x3a8>
    8000632a:	ffffa097          	auipc	ra,0xffffa
    8000632e:	206080e7          	jalr	518(ra) # 80000530 <panic>

0000000080006332 <virtio_disk_init>:
{
    80006332:	1101                	addi	sp,sp,-32
    80006334:	ec06                	sd	ra,24(sp)
    80006336:	e822                	sd	s0,16(sp)
    80006338:	e426                	sd	s1,8(sp)
    8000633a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000633c:	00002597          	auipc	a1,0x2
    80006340:	4cc58593          	addi	a1,a1,1228 # 80008808 <syscalls+0x3b8>
    80006344:	0001f517          	auipc	a0,0x1f
    80006348:	de450513          	addi	a0,a0,-540 # 80025128 <disk+0x2128>
    8000634c:	ffffa097          	auipc	ra,0xffffa
    80006350:	7fa080e7          	jalr	2042(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006354:	100017b7          	lui	a5,0x10001
    80006358:	4398                	lw	a4,0(a5)
    8000635a:	2701                	sext.w	a4,a4
    8000635c:	747277b7          	lui	a5,0x74727
    80006360:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006364:	0ef71163          	bne	a4,a5,80006446 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006368:	100017b7          	lui	a5,0x10001
    8000636c:	43dc                	lw	a5,4(a5)
    8000636e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006370:	4705                	li	a4,1
    80006372:	0ce79a63          	bne	a5,a4,80006446 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006376:	100017b7          	lui	a5,0x10001
    8000637a:	479c                	lw	a5,8(a5)
    8000637c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000637e:	4709                	li	a4,2
    80006380:	0ce79363          	bne	a5,a4,80006446 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006384:	100017b7          	lui	a5,0x10001
    80006388:	47d8                	lw	a4,12(a5)
    8000638a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000638c:	554d47b7          	lui	a5,0x554d4
    80006390:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006394:	0af71963          	bne	a4,a5,80006446 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006398:	100017b7          	lui	a5,0x10001
    8000639c:	4705                	li	a4,1
    8000639e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063a0:	470d                	li	a4,3
    800063a2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800063a4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800063a6:	c7ffe737          	lui	a4,0xc7ffe
    800063aa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800063ae:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800063b0:	2701                	sext.w	a4,a4
    800063b2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063b4:	472d                	li	a4,11
    800063b6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063b8:	473d                	li	a4,15
    800063ba:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800063bc:	6705                	lui	a4,0x1
    800063be:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800063c0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800063c4:	5bdc                	lw	a5,52(a5)
    800063c6:	2781                	sext.w	a5,a5
  if(max == 0)
    800063c8:	c7d9                	beqz	a5,80006456 <virtio_disk_init+0x124>
  if(max < NUM)
    800063ca:	471d                	li	a4,7
    800063cc:	08f77d63          	bgeu	a4,a5,80006466 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800063d0:	100014b7          	lui	s1,0x10001
    800063d4:	47a1                	li	a5,8
    800063d6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800063d8:	6609                	lui	a2,0x2
    800063da:	4581                	li	a1,0
    800063dc:	0001d517          	auipc	a0,0x1d
    800063e0:	c2450513          	addi	a0,a0,-988 # 80023000 <disk>
    800063e4:	ffffb097          	auipc	ra,0xffffb
    800063e8:	8ee080e7          	jalr	-1810(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800063ec:	0001d717          	auipc	a4,0x1d
    800063f0:	c1470713          	addi	a4,a4,-1004 # 80023000 <disk>
    800063f4:	00c75793          	srli	a5,a4,0xc
    800063f8:	2781                	sext.w	a5,a5
    800063fa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800063fc:	0001f797          	auipc	a5,0x1f
    80006400:	c0478793          	addi	a5,a5,-1020 # 80025000 <disk+0x2000>
    80006404:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006406:	0001d717          	auipc	a4,0x1d
    8000640a:	c7a70713          	addi	a4,a4,-902 # 80023080 <disk+0x80>
    8000640e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006410:	0001e717          	auipc	a4,0x1e
    80006414:	bf070713          	addi	a4,a4,-1040 # 80024000 <disk+0x1000>
    80006418:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000641a:	4705                	li	a4,1
    8000641c:	00e78c23          	sb	a4,24(a5)
    80006420:	00e78ca3          	sb	a4,25(a5)
    80006424:	00e78d23          	sb	a4,26(a5)
    80006428:	00e78da3          	sb	a4,27(a5)
    8000642c:	00e78e23          	sb	a4,28(a5)
    80006430:	00e78ea3          	sb	a4,29(a5)
    80006434:	00e78f23          	sb	a4,30(a5)
    80006438:	00e78fa3          	sb	a4,31(a5)
}
    8000643c:	60e2                	ld	ra,24(sp)
    8000643e:	6442                	ld	s0,16(sp)
    80006440:	64a2                	ld	s1,8(sp)
    80006442:	6105                	addi	sp,sp,32
    80006444:	8082                	ret
    panic("could not find virtio disk");
    80006446:	00002517          	auipc	a0,0x2
    8000644a:	3d250513          	addi	a0,a0,978 # 80008818 <syscalls+0x3c8>
    8000644e:	ffffa097          	auipc	ra,0xffffa
    80006452:	0e2080e7          	jalr	226(ra) # 80000530 <panic>
    panic("virtio disk has no queue 0");
    80006456:	00002517          	auipc	a0,0x2
    8000645a:	3e250513          	addi	a0,a0,994 # 80008838 <syscalls+0x3e8>
    8000645e:	ffffa097          	auipc	ra,0xffffa
    80006462:	0d2080e7          	jalr	210(ra) # 80000530 <panic>
    panic("virtio disk max queue too short");
    80006466:	00002517          	auipc	a0,0x2
    8000646a:	3f250513          	addi	a0,a0,1010 # 80008858 <syscalls+0x408>
    8000646e:	ffffa097          	auipc	ra,0xffffa
    80006472:	0c2080e7          	jalr	194(ra) # 80000530 <panic>

0000000080006476 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006476:	7159                	addi	sp,sp,-112
    80006478:	f486                	sd	ra,104(sp)
    8000647a:	f0a2                	sd	s0,96(sp)
    8000647c:	eca6                	sd	s1,88(sp)
    8000647e:	e8ca                	sd	s2,80(sp)
    80006480:	e4ce                	sd	s3,72(sp)
    80006482:	e0d2                	sd	s4,64(sp)
    80006484:	fc56                	sd	s5,56(sp)
    80006486:	f85a                	sd	s6,48(sp)
    80006488:	f45e                	sd	s7,40(sp)
    8000648a:	f062                	sd	s8,32(sp)
    8000648c:	ec66                	sd	s9,24(sp)
    8000648e:	e86a                	sd	s10,16(sp)
    80006490:	1880                	addi	s0,sp,112
    80006492:	892a                	mv	s2,a0
    80006494:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006496:	00c52c83          	lw	s9,12(a0)
    8000649a:	001c9c9b          	slliw	s9,s9,0x1
    8000649e:	1c82                	slli	s9,s9,0x20
    800064a0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800064a4:	0001f517          	auipc	a0,0x1f
    800064a8:	c8450513          	addi	a0,a0,-892 # 80025128 <disk+0x2128>
    800064ac:	ffffa097          	auipc	ra,0xffffa
    800064b0:	72a080e7          	jalr	1834(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800064b4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800064b6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800064b8:	0001db97          	auipc	s7,0x1d
    800064bc:	b48b8b93          	addi	s7,s7,-1208 # 80023000 <disk>
    800064c0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800064c2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800064c4:	8a4e                	mv	s4,s3
    800064c6:	a051                	j	8000654a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800064c8:	00fb86b3          	add	a3,s7,a5
    800064cc:	96da                	add	a3,a3,s6
    800064ce:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800064d2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800064d4:	0207c563          	bltz	a5,800064fe <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800064d8:	2485                	addiw	s1,s1,1
    800064da:	0711                	addi	a4,a4,4
    800064dc:	25548063          	beq	s1,s5,8000671c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800064e0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800064e2:	0001f697          	auipc	a3,0x1f
    800064e6:	b3668693          	addi	a3,a3,-1226 # 80025018 <disk+0x2018>
    800064ea:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800064ec:	0006c583          	lbu	a1,0(a3)
    800064f0:	fde1                	bnez	a1,800064c8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800064f2:	2785                	addiw	a5,a5,1
    800064f4:	0685                	addi	a3,a3,1
    800064f6:	ff879be3          	bne	a5,s8,800064ec <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800064fa:	57fd                	li	a5,-1
    800064fc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800064fe:	02905a63          	blez	s1,80006532 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006502:	f9042503          	lw	a0,-112(s0)
    80006506:	00000097          	auipc	ra,0x0
    8000650a:	d90080e7          	jalr	-624(ra) # 80006296 <free_desc>
      for(int j = 0; j < i; j++)
    8000650e:	4785                	li	a5,1
    80006510:	0297d163          	bge	a5,s1,80006532 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006514:	f9442503          	lw	a0,-108(s0)
    80006518:	00000097          	auipc	ra,0x0
    8000651c:	d7e080e7          	jalr	-642(ra) # 80006296 <free_desc>
      for(int j = 0; j < i; j++)
    80006520:	4789                	li	a5,2
    80006522:	0097d863          	bge	a5,s1,80006532 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006526:	f9842503          	lw	a0,-104(s0)
    8000652a:	00000097          	auipc	ra,0x0
    8000652e:	d6c080e7          	jalr	-660(ra) # 80006296 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006532:	0001f597          	auipc	a1,0x1f
    80006536:	bf658593          	addi	a1,a1,-1034 # 80025128 <disk+0x2128>
    8000653a:	0001f517          	auipc	a0,0x1f
    8000653e:	ade50513          	addi	a0,a0,-1314 # 80025018 <disk+0x2018>
    80006542:	ffffc097          	auipc	ra,0xffffc
    80006546:	dce080e7          	jalr	-562(ra) # 80002310 <sleep>
  for(int i = 0; i < 3; i++){
    8000654a:	f9040713          	addi	a4,s0,-112
    8000654e:	84ce                	mv	s1,s3
    80006550:	bf41                	j	800064e0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006552:	20058713          	addi	a4,a1,512
    80006556:	00471693          	slli	a3,a4,0x4
    8000655a:	0001d717          	auipc	a4,0x1d
    8000655e:	aa670713          	addi	a4,a4,-1370 # 80023000 <disk>
    80006562:	9736                	add	a4,a4,a3
    80006564:	4685                	li	a3,1
    80006566:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000656a:	20058713          	addi	a4,a1,512
    8000656e:	00471693          	slli	a3,a4,0x4
    80006572:	0001d717          	auipc	a4,0x1d
    80006576:	a8e70713          	addi	a4,a4,-1394 # 80023000 <disk>
    8000657a:	9736                	add	a4,a4,a3
    8000657c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006580:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006584:	7679                	lui	a2,0xffffe
    80006586:	963e                	add	a2,a2,a5
    80006588:	0001f697          	auipc	a3,0x1f
    8000658c:	a7868693          	addi	a3,a3,-1416 # 80025000 <disk+0x2000>
    80006590:	6298                	ld	a4,0(a3)
    80006592:	9732                	add	a4,a4,a2
    80006594:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006596:	6298                	ld	a4,0(a3)
    80006598:	9732                	add	a4,a4,a2
    8000659a:	4541                	li	a0,16
    8000659c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000659e:	6298                	ld	a4,0(a3)
    800065a0:	9732                	add	a4,a4,a2
    800065a2:	4505                	li	a0,1
    800065a4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800065a8:	f9442703          	lw	a4,-108(s0)
    800065ac:	6288                	ld	a0,0(a3)
    800065ae:	962a                	add	a2,a2,a0
    800065b0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800065b4:	0712                	slli	a4,a4,0x4
    800065b6:	6290                	ld	a2,0(a3)
    800065b8:	963a                	add	a2,a2,a4
    800065ba:	05890513          	addi	a0,s2,88
    800065be:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800065c0:	6294                	ld	a3,0(a3)
    800065c2:	96ba                	add	a3,a3,a4
    800065c4:	40000613          	li	a2,1024
    800065c8:	c690                	sw	a2,8(a3)
  if(write)
    800065ca:	140d0063          	beqz	s10,8000670a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800065ce:	0001f697          	auipc	a3,0x1f
    800065d2:	a326b683          	ld	a3,-1486(a3) # 80025000 <disk+0x2000>
    800065d6:	96ba                	add	a3,a3,a4
    800065d8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800065dc:	0001d817          	auipc	a6,0x1d
    800065e0:	a2480813          	addi	a6,a6,-1500 # 80023000 <disk>
    800065e4:	0001f517          	auipc	a0,0x1f
    800065e8:	a1c50513          	addi	a0,a0,-1508 # 80025000 <disk+0x2000>
    800065ec:	6114                	ld	a3,0(a0)
    800065ee:	96ba                	add	a3,a3,a4
    800065f0:	00c6d603          	lhu	a2,12(a3)
    800065f4:	00166613          	ori	a2,a2,1
    800065f8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800065fc:	f9842683          	lw	a3,-104(s0)
    80006600:	6110                	ld	a2,0(a0)
    80006602:	9732                	add	a4,a4,a2
    80006604:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006608:	20058613          	addi	a2,a1,512
    8000660c:	0612                	slli	a2,a2,0x4
    8000660e:	9642                	add	a2,a2,a6
    80006610:	577d                	li	a4,-1
    80006612:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006616:	00469713          	slli	a4,a3,0x4
    8000661a:	6114                	ld	a3,0(a0)
    8000661c:	96ba                	add	a3,a3,a4
    8000661e:	03078793          	addi	a5,a5,48
    80006622:	97c2                	add	a5,a5,a6
    80006624:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006626:	611c                	ld	a5,0(a0)
    80006628:	97ba                	add	a5,a5,a4
    8000662a:	4685                	li	a3,1
    8000662c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000662e:	611c                	ld	a5,0(a0)
    80006630:	97ba                	add	a5,a5,a4
    80006632:	4809                	li	a6,2
    80006634:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006638:	611c                	ld	a5,0(a0)
    8000663a:	973e                	add	a4,a4,a5
    8000663c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006640:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006644:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006648:	6518                	ld	a4,8(a0)
    8000664a:	00275783          	lhu	a5,2(a4)
    8000664e:	8b9d                	andi	a5,a5,7
    80006650:	0786                	slli	a5,a5,0x1
    80006652:	97ba                	add	a5,a5,a4
    80006654:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006658:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000665c:	6518                	ld	a4,8(a0)
    8000665e:	00275783          	lhu	a5,2(a4)
    80006662:	2785                	addiw	a5,a5,1
    80006664:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006668:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000666c:	100017b7          	lui	a5,0x10001
    80006670:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006674:	00492703          	lw	a4,4(s2)
    80006678:	4785                	li	a5,1
    8000667a:	02f71163          	bne	a4,a5,8000669c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000667e:	0001f997          	auipc	s3,0x1f
    80006682:	aaa98993          	addi	s3,s3,-1366 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006686:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006688:	85ce                	mv	a1,s3
    8000668a:	854a                	mv	a0,s2
    8000668c:	ffffc097          	auipc	ra,0xffffc
    80006690:	c84080e7          	jalr	-892(ra) # 80002310 <sleep>
  while(b->disk == 1) {
    80006694:	00492783          	lw	a5,4(s2)
    80006698:	fe9788e3          	beq	a5,s1,80006688 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000669c:	f9042903          	lw	s2,-112(s0)
    800066a0:	20090793          	addi	a5,s2,512
    800066a4:	00479713          	slli	a4,a5,0x4
    800066a8:	0001d797          	auipc	a5,0x1d
    800066ac:	95878793          	addi	a5,a5,-1704 # 80023000 <disk>
    800066b0:	97ba                	add	a5,a5,a4
    800066b2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800066b6:	0001f997          	auipc	s3,0x1f
    800066ba:	94a98993          	addi	s3,s3,-1718 # 80025000 <disk+0x2000>
    800066be:	00491713          	slli	a4,s2,0x4
    800066c2:	0009b783          	ld	a5,0(s3)
    800066c6:	97ba                	add	a5,a5,a4
    800066c8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800066cc:	854a                	mv	a0,s2
    800066ce:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800066d2:	00000097          	auipc	ra,0x0
    800066d6:	bc4080e7          	jalr	-1084(ra) # 80006296 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800066da:	8885                	andi	s1,s1,1
    800066dc:	f0ed                	bnez	s1,800066be <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800066de:	0001f517          	auipc	a0,0x1f
    800066e2:	a4a50513          	addi	a0,a0,-1462 # 80025128 <disk+0x2128>
    800066e6:	ffffa097          	auipc	ra,0xffffa
    800066ea:	5a4080e7          	jalr	1444(ra) # 80000c8a <release>
}
    800066ee:	70a6                	ld	ra,104(sp)
    800066f0:	7406                	ld	s0,96(sp)
    800066f2:	64e6                	ld	s1,88(sp)
    800066f4:	6946                	ld	s2,80(sp)
    800066f6:	69a6                	ld	s3,72(sp)
    800066f8:	6a06                	ld	s4,64(sp)
    800066fa:	7ae2                	ld	s5,56(sp)
    800066fc:	7b42                	ld	s6,48(sp)
    800066fe:	7ba2                	ld	s7,40(sp)
    80006700:	7c02                	ld	s8,32(sp)
    80006702:	6ce2                	ld	s9,24(sp)
    80006704:	6d42                	ld	s10,16(sp)
    80006706:	6165                	addi	sp,sp,112
    80006708:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000670a:	0001f697          	auipc	a3,0x1f
    8000670e:	8f66b683          	ld	a3,-1802(a3) # 80025000 <disk+0x2000>
    80006712:	96ba                	add	a3,a3,a4
    80006714:	4609                	li	a2,2
    80006716:	00c69623          	sh	a2,12(a3)
    8000671a:	b5c9                	j	800065dc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000671c:	f9042583          	lw	a1,-112(s0)
    80006720:	20058793          	addi	a5,a1,512
    80006724:	0792                	slli	a5,a5,0x4
    80006726:	0001d517          	auipc	a0,0x1d
    8000672a:	98250513          	addi	a0,a0,-1662 # 800230a8 <disk+0xa8>
    8000672e:	953e                	add	a0,a0,a5
  if(write)
    80006730:	e20d11e3          	bnez	s10,80006552 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006734:	20058713          	addi	a4,a1,512
    80006738:	00471693          	slli	a3,a4,0x4
    8000673c:	0001d717          	auipc	a4,0x1d
    80006740:	8c470713          	addi	a4,a4,-1852 # 80023000 <disk>
    80006744:	9736                	add	a4,a4,a3
    80006746:	0a072423          	sw	zero,168(a4)
    8000674a:	b505                	j	8000656a <virtio_disk_rw+0xf4>

000000008000674c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000674c:	1101                	addi	sp,sp,-32
    8000674e:	ec06                	sd	ra,24(sp)
    80006750:	e822                	sd	s0,16(sp)
    80006752:	e426                	sd	s1,8(sp)
    80006754:	e04a                	sd	s2,0(sp)
    80006756:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006758:	0001f517          	auipc	a0,0x1f
    8000675c:	9d050513          	addi	a0,a0,-1584 # 80025128 <disk+0x2128>
    80006760:	ffffa097          	auipc	ra,0xffffa
    80006764:	476080e7          	jalr	1142(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006768:	10001737          	lui	a4,0x10001
    8000676c:	533c                	lw	a5,96(a4)
    8000676e:	8b8d                	andi	a5,a5,3
    80006770:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006772:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006776:	0001f797          	auipc	a5,0x1f
    8000677a:	88a78793          	addi	a5,a5,-1910 # 80025000 <disk+0x2000>
    8000677e:	6b94                	ld	a3,16(a5)
    80006780:	0207d703          	lhu	a4,32(a5)
    80006784:	0026d783          	lhu	a5,2(a3)
    80006788:	06f70163          	beq	a4,a5,800067ea <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000678c:	0001d917          	auipc	s2,0x1d
    80006790:	87490913          	addi	s2,s2,-1932 # 80023000 <disk>
    80006794:	0001f497          	auipc	s1,0x1f
    80006798:	86c48493          	addi	s1,s1,-1940 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000679c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800067a0:	6898                	ld	a4,16(s1)
    800067a2:	0204d783          	lhu	a5,32(s1)
    800067a6:	8b9d                	andi	a5,a5,7
    800067a8:	078e                	slli	a5,a5,0x3
    800067aa:	97ba                	add	a5,a5,a4
    800067ac:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800067ae:	20078713          	addi	a4,a5,512
    800067b2:	0712                	slli	a4,a4,0x4
    800067b4:	974a                	add	a4,a4,s2
    800067b6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800067ba:	e731                	bnez	a4,80006806 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800067bc:	20078793          	addi	a5,a5,512
    800067c0:	0792                	slli	a5,a5,0x4
    800067c2:	97ca                	add	a5,a5,s2
    800067c4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800067c6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800067ca:	ffffc097          	auipc	ra,0xffffc
    800067ce:	ccc080e7          	jalr	-820(ra) # 80002496 <wakeup>

    disk.used_idx += 1;
    800067d2:	0204d783          	lhu	a5,32(s1)
    800067d6:	2785                	addiw	a5,a5,1
    800067d8:	17c2                	slli	a5,a5,0x30
    800067da:	93c1                	srli	a5,a5,0x30
    800067dc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800067e0:	6898                	ld	a4,16(s1)
    800067e2:	00275703          	lhu	a4,2(a4)
    800067e6:	faf71be3          	bne	a4,a5,8000679c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800067ea:	0001f517          	auipc	a0,0x1f
    800067ee:	93e50513          	addi	a0,a0,-1730 # 80025128 <disk+0x2128>
    800067f2:	ffffa097          	auipc	ra,0xffffa
    800067f6:	498080e7          	jalr	1176(ra) # 80000c8a <release>
}
    800067fa:	60e2                	ld	ra,24(sp)
    800067fc:	6442                	ld	s0,16(sp)
    800067fe:	64a2                	ld	s1,8(sp)
    80006800:	6902                	ld	s2,0(sp)
    80006802:	6105                	addi	sp,sp,32
    80006804:	8082                	ret
      panic("virtio_disk_intr status");
    80006806:	00002517          	auipc	a0,0x2
    8000680a:	07250513          	addi	a0,a0,114 # 80008878 <syscalls+0x428>
    8000680e:	ffffa097          	auipc	ra,0xffffa
    80006812:	d22080e7          	jalr	-734(ra) # 80000530 <panic>
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
