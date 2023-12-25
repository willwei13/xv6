
user/_mmaptest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <err>:

char *testname = "???";

void
err(char *why)
{
       0:	1101                	addi	sp,sp,-32
       2:	ec06                	sd	ra,24(sp)
       4:	e822                	sd	s0,16(sp)
       6:	e426                	sd	s1,8(sp)
       8:	e04a                	sd	s2,0(sp)
       a:	1000                	addi	s0,sp,32
       c:	84aa                	mv	s1,a0
  printf("mmaptest: %s failed: %s, pid=%d\n", testname, why, getpid());
       e:	00001917          	auipc	s2,0x1
      12:	5da93903          	ld	s2,1498(s2) # 15e8 <testname>
      16:	00001097          	auipc	ra,0x1
      1a:	c40080e7          	jalr	-960(ra) # c56 <getpid>
      1e:	86aa                	mv	a3,a0
      20:	8626                	mv	a2,s1
      22:	85ca                	mv	a1,s2
      24:	00001517          	auipc	a0,0x1
      28:	0dc50513          	addi	a0,a0,220 # 1100 <malloc+0xe4>
      2c:	00001097          	auipc	ra,0x1
      30:	f32080e7          	jalr	-206(ra) # f5e <printf>
  exit(1);
      34:	4505                	li	a0,1
      36:	00001097          	auipc	ra,0x1
      3a:	ba0080e7          	jalr	-1120(ra) # bd6 <exit>

000000000000003e <_v1>:
//
// check the content of the two mapped pages.
//
void
_v1(char *p)
{
      3e:	1141                	addi	sp,sp,-16
      40:	e406                	sd	ra,8(sp)
      42:	e022                	sd	s0,0(sp)
      44:	0800                	addi	s0,sp,16
      46:	4781                	li	a5,0
  int i;
  for (i = 0; i < PGSIZE*2; i++) {
    if (i < PGSIZE + (PGSIZE/2)) {
      48:	6685                	lui	a3,0x1
      4a:	7ff68693          	addi	a3,a3,2047 # 17ff <buf+0x207>
  for (i = 0; i < PGSIZE*2; i++) {
      4e:	6889                	lui	a7,0x2
      if (p[i] != 'A') {
      50:	04100813          	li	a6,65
      54:	a811                	j	68 <_v1+0x2a>
        printf("mismatch at %d, wanted 'A', got 0x%x\n", i, p[i]);
        err("v1 mismatch (1)");
      }
    } else {
      if (p[i] != 0) {
      56:	00f50633          	add	a2,a0,a5
      5a:	00064603          	lbu	a2,0(a2)
      5e:	e221                	bnez	a2,9e <_v1+0x60>
  for (i = 0; i < PGSIZE*2; i++) {
      60:	2705                	addiw	a4,a4,1
      62:	05175e63          	bge	a4,a7,be <_v1+0x80>
      66:	0785                	addi	a5,a5,1
      68:	0007871b          	sext.w	a4,a5
      6c:	85ba                	mv	a1,a4
    if (i < PGSIZE + (PGSIZE/2)) {
      6e:	fee6c4e3          	blt	a3,a4,56 <_v1+0x18>
      if (p[i] != 'A') {
      72:	00f50733          	add	a4,a0,a5
      76:	00074603          	lbu	a2,0(a4)
      7a:	ff0606e3          	beq	a2,a6,66 <_v1+0x28>
        printf("mismatch at %d, wanted 'A', got 0x%x\n", i, p[i]);
      7e:	00001517          	auipc	a0,0x1
      82:	0aa50513          	addi	a0,a0,170 # 1128 <malloc+0x10c>
      86:	00001097          	auipc	ra,0x1
      8a:	ed8080e7          	jalr	-296(ra) # f5e <printf>
        err("v1 mismatch (1)");
      8e:	00001517          	auipc	a0,0x1
      92:	0c250513          	addi	a0,a0,194 # 1150 <malloc+0x134>
      96:	00000097          	auipc	ra,0x0
      9a:	f6a080e7          	jalr	-150(ra) # 0 <err>
        printf("mismatch at %d, wanted zero, got 0x%x\n", i, p[i]);
      9e:	00001517          	auipc	a0,0x1
      a2:	0c250513          	addi	a0,a0,194 # 1160 <malloc+0x144>
      a6:	00001097          	auipc	ra,0x1
      aa:	eb8080e7          	jalr	-328(ra) # f5e <printf>
        err("v1 mismatch (2)");
      ae:	00001517          	auipc	a0,0x1
      b2:	0da50513          	addi	a0,a0,218 # 1188 <malloc+0x16c>
      b6:	00000097          	auipc	ra,0x0
      ba:	f4a080e7          	jalr	-182(ra) # 0 <err>
      }
    }
  }
}
      be:	60a2                	ld	ra,8(sp)
      c0:	6402                	ld	s0,0(sp)
      c2:	0141                	addi	sp,sp,16
      c4:	8082                	ret

00000000000000c6 <makefile>:
// create a file to be mapped, containing
// 1.5 pages of 'A' and half a page of zeros.
//
void
makefile(const char *f)
{
      c6:	7179                	addi	sp,sp,-48
      c8:	f406                	sd	ra,40(sp)
      ca:	f022                	sd	s0,32(sp)
      cc:	ec26                	sd	s1,24(sp)
      ce:	e84a                	sd	s2,16(sp)
      d0:	e44e                	sd	s3,8(sp)
      d2:	1800                	addi	s0,sp,48
      d4:	84aa                	mv	s1,a0
  int i;
  int n = PGSIZE/BSIZE;

  unlink(f);
      d6:	00001097          	auipc	ra,0x1
      da:	b50080e7          	jalr	-1200(ra) # c26 <unlink>
  int fd = open(f, O_WRONLY | O_CREATE);
      de:	20100593          	li	a1,513
      e2:	8526                	mv	a0,s1
      e4:	00001097          	auipc	ra,0x1
      e8:	b32080e7          	jalr	-1230(ra) # c16 <open>
  if (fd == -1)
      ec:	57fd                	li	a5,-1
      ee:	06f50163          	beq	a0,a5,150 <makefile+0x8a>
      f2:	892a                	mv	s2,a0
    err("open");
  memset(buf, 'A', BSIZE);
      f4:	40000613          	li	a2,1024
      f8:	04100593          	li	a1,65
      fc:	00001517          	auipc	a0,0x1
     100:	4fc50513          	addi	a0,a0,1276 # 15f8 <buf>
     104:	00001097          	auipc	ra,0x1
     108:	8ce080e7          	jalr	-1842(ra) # 9d2 <memset>
     10c:	4499                	li	s1,6
  // write 1.5 page
  for (i = 0; i < n + n/2; i++) {
    if (write(fd, buf, BSIZE) != BSIZE)
     10e:	00001997          	auipc	s3,0x1
     112:	4ea98993          	addi	s3,s3,1258 # 15f8 <buf>
     116:	40000613          	li	a2,1024
     11a:	85ce                	mv	a1,s3
     11c:	854a                	mv	a0,s2
     11e:	00001097          	auipc	ra,0x1
     122:	ad8080e7          	jalr	-1320(ra) # bf6 <write>
     126:	40000793          	li	a5,1024
     12a:	02f51b63          	bne	a0,a5,160 <makefile+0x9a>
  for (i = 0; i < n + n/2; i++) {
     12e:	34fd                	addiw	s1,s1,-1
     130:	f0fd                	bnez	s1,116 <makefile+0x50>
      err("write 0 makefile");
  }
  if (close(fd) == -1)
     132:	854a                	mv	a0,s2
     134:	00001097          	auipc	ra,0x1
     138:	aca080e7          	jalr	-1334(ra) # bfe <close>
     13c:	57fd                	li	a5,-1
     13e:	02f50963          	beq	a0,a5,170 <makefile+0xaa>
    err("close");
}
     142:	70a2                	ld	ra,40(sp)
     144:	7402                	ld	s0,32(sp)
     146:	64e2                	ld	s1,24(sp)
     148:	6942                	ld	s2,16(sp)
     14a:	69a2                	ld	s3,8(sp)
     14c:	6145                	addi	sp,sp,48
     14e:	8082                	ret
    err("open");
     150:	00001517          	auipc	a0,0x1
     154:	04850513          	addi	a0,a0,72 # 1198 <malloc+0x17c>
     158:	00000097          	auipc	ra,0x0
     15c:	ea8080e7          	jalr	-344(ra) # 0 <err>
      err("write 0 makefile");
     160:	00001517          	auipc	a0,0x1
     164:	04050513          	addi	a0,a0,64 # 11a0 <malloc+0x184>
     168:	00000097          	auipc	ra,0x0
     16c:	e98080e7          	jalr	-360(ra) # 0 <err>
    err("close");
     170:	00001517          	auipc	a0,0x1
     174:	04850513          	addi	a0,a0,72 # 11b8 <malloc+0x19c>
     178:	00000097          	auipc	ra,0x0
     17c:	e88080e7          	jalr	-376(ra) # 0 <err>

0000000000000180 <mmap_test>:

void
mmap_test(void)
{
     180:	7139                	addi	sp,sp,-64
     182:	fc06                	sd	ra,56(sp)
     184:	f822                	sd	s0,48(sp)
     186:	f426                	sd	s1,40(sp)
     188:	f04a                	sd	s2,32(sp)
     18a:	ec4e                	sd	s3,24(sp)
     18c:	e852                	sd	s4,16(sp)
     18e:	0080                	addi	s0,sp,64
  int fd;
  int i;
  const char * const f = "mmap.dur";
  printf("mmap_test starting\n");
     190:	00001517          	auipc	a0,0x1
     194:	03050513          	addi	a0,a0,48 # 11c0 <malloc+0x1a4>
     198:	00001097          	auipc	ra,0x1
     19c:	dc6080e7          	jalr	-570(ra) # f5e <printf>
  testname = "mmap_test";
     1a0:	00001797          	auipc	a5,0x1
     1a4:	03878793          	addi	a5,a5,56 # 11d8 <malloc+0x1bc>
     1a8:	00001717          	auipc	a4,0x1
     1ac:	44f73023          	sd	a5,1088(a4) # 15e8 <testname>
  //
  // create a file with known content, map it into memory, check that
  // the mapped memory has the same bytes as originally written to the
  // file.
  //
  makefile(f);
     1b0:	00001517          	auipc	a0,0x1
     1b4:	03850513          	addi	a0,a0,56 # 11e8 <malloc+0x1cc>
     1b8:	00000097          	auipc	ra,0x0
     1bc:	f0e080e7          	jalr	-242(ra) # c6 <makefile>
  if ((fd = open(f, O_RDONLY)) == -1)
     1c0:	4581                	li	a1,0
     1c2:	00001517          	auipc	a0,0x1
     1c6:	02650513          	addi	a0,a0,38 # 11e8 <malloc+0x1cc>
     1ca:	00001097          	auipc	ra,0x1
     1ce:	a4c080e7          	jalr	-1460(ra) # c16 <open>
     1d2:	57fd                	li	a5,-1
     1d4:	3ef50663          	beq	a0,a5,5c0 <mmap_test+0x440>
     1d8:	892a                	mv	s2,a0
    err("open");

  printf("test mmap f\n");
     1da:	00001517          	auipc	a0,0x1
     1de:	01e50513          	addi	a0,a0,30 # 11f8 <malloc+0x1dc>
     1e2:	00001097          	auipc	ra,0x1
     1e6:	d7c080e7          	jalr	-644(ra) # f5e <printf>
  // same file (of course in this case updates are prohibited
  // due to PROT_READ). the fifth argument is the file descriptor
  // of the file to be mapped. the last argument is the starting
  // offset in the file.
  //
  char *p = mmap(0, PGSIZE*2, PROT_READ, MAP_PRIVATE, fd, 0);
     1ea:	4781                	li	a5,0
     1ec:	874a                	mv	a4,s2
     1ee:	4689                	li	a3,2
     1f0:	4605                	li	a2,1
     1f2:	6589                	lui	a1,0x2
     1f4:	4501                	li	a0,0
     1f6:	00001097          	auipc	ra,0x1
     1fa:	a80080e7          	jalr	-1408(ra) # c76 <mmap>
     1fe:	84aa                	mv	s1,a0
  if (p == MAP_FAILED)
     200:	57fd                	li	a5,-1
     202:	3cf50763          	beq	a0,a5,5d0 <mmap_test+0x450>
    err("mmap (1)");
  _v1(p);
     206:	00000097          	auipc	ra,0x0
     20a:	e38080e7          	jalr	-456(ra) # 3e <_v1>
  if (munmap(p, PGSIZE*2) == -1)
     20e:	6589                	lui	a1,0x2
     210:	8526                	mv	a0,s1
     212:	00001097          	auipc	ra,0x1
     216:	a6c080e7          	jalr	-1428(ra) # c7e <munmap>
     21a:	57fd                	li	a5,-1
     21c:	3cf50263          	beq	a0,a5,5e0 <mmap_test+0x460>
    err("munmap (1)");

  printf("test mmap f: OK\n");
     220:	00001517          	auipc	a0,0x1
     224:	00850513          	addi	a0,a0,8 # 1228 <malloc+0x20c>
     228:	00001097          	auipc	ra,0x1
     22c:	d36080e7          	jalr	-714(ra) # f5e <printf>
    
  printf("test mmap private\n");
     230:	00001517          	auipc	a0,0x1
     234:	01050513          	addi	a0,a0,16 # 1240 <malloc+0x224>
     238:	00001097          	auipc	ra,0x1
     23c:	d26080e7          	jalr	-730(ra) # f5e <printf>
  // should be able to map file opened read-only with private writable
  // mapping
  p = mmap(0, PGSIZE*2, PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0);
     240:	4781                	li	a5,0
     242:	874a                	mv	a4,s2
     244:	4689                	li	a3,2
     246:	460d                	li	a2,3
     248:	6589                	lui	a1,0x2
     24a:	4501                	li	a0,0
     24c:	00001097          	auipc	ra,0x1
     250:	a2a080e7          	jalr	-1494(ra) # c76 <mmap>
     254:	84aa                	mv	s1,a0
  if (p == MAP_FAILED)
     256:	57fd                	li	a5,-1
     258:	38f50c63          	beq	a0,a5,5f0 <mmap_test+0x470>
    err("mmap (2)");
  if (close(fd) == -1)
     25c:	854a                	mv	a0,s2
     25e:	00001097          	auipc	ra,0x1
     262:	9a0080e7          	jalr	-1632(ra) # bfe <close>
     266:	57fd                	li	a5,-1
     268:	38f50c63          	beq	a0,a5,600 <mmap_test+0x480>
    err("close");
  _v1(p);
     26c:	8526                	mv	a0,s1
     26e:	00000097          	auipc	ra,0x0
     272:	dd0080e7          	jalr	-560(ra) # 3e <_v1>
  for (i = 0; i < PGSIZE*2; i++)
     276:	87a6                	mv	a5,s1
     278:	6709                	lui	a4,0x2
     27a:	9726                	add	a4,a4,s1
    p[i] = 'Z';
     27c:	05a00693          	li	a3,90
     280:	00d78023          	sb	a3,0(a5)
  for (i = 0; i < PGSIZE*2; i++)
     284:	0785                	addi	a5,a5,1
     286:	fef71de3          	bne	a4,a5,280 <mmap_test+0x100>
  if (munmap(p, PGSIZE*2) == -1)
     28a:	6589                	lui	a1,0x2
     28c:	8526                	mv	a0,s1
     28e:	00001097          	auipc	ra,0x1
     292:	9f0080e7          	jalr	-1552(ra) # c7e <munmap>
     296:	57fd                	li	a5,-1
     298:	36f50c63          	beq	a0,a5,610 <mmap_test+0x490>
    err("munmap (2)");

  printf("test mmap private: OK\n");
     29c:	00001517          	auipc	a0,0x1
     2a0:	fdc50513          	addi	a0,a0,-36 # 1278 <malloc+0x25c>
     2a4:	00001097          	auipc	ra,0x1
     2a8:	cba080e7          	jalr	-838(ra) # f5e <printf>
    
  printf("test mmap read-only\n");
     2ac:	00001517          	auipc	a0,0x1
     2b0:	fe450513          	addi	a0,a0,-28 # 1290 <malloc+0x274>
     2b4:	00001097          	auipc	ra,0x1
     2b8:	caa080e7          	jalr	-854(ra) # f5e <printf>
    
  // check that mmap doesn't allow read/write mapping of a
  // file opened read-only.
  if ((fd = open(f, O_RDONLY)) == -1)
     2bc:	4581                	li	a1,0
     2be:	00001517          	auipc	a0,0x1
     2c2:	f2a50513          	addi	a0,a0,-214 # 11e8 <malloc+0x1cc>
     2c6:	00001097          	auipc	ra,0x1
     2ca:	950080e7          	jalr	-1712(ra) # c16 <open>
     2ce:	84aa                	mv	s1,a0
     2d0:	57fd                	li	a5,-1
     2d2:	34f50763          	beq	a0,a5,620 <mmap_test+0x4a0>
    err("open");
  p = mmap(0, PGSIZE*3, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
     2d6:	4781                	li	a5,0
     2d8:	872a                	mv	a4,a0
     2da:	4685                	li	a3,1
     2dc:	460d                	li	a2,3
     2de:	658d                	lui	a1,0x3
     2e0:	4501                	li	a0,0
     2e2:	00001097          	auipc	ra,0x1
     2e6:	994080e7          	jalr	-1644(ra) # c76 <mmap>
  if (p != MAP_FAILED)
     2ea:	57fd                	li	a5,-1
     2ec:	34f51263          	bne	a0,a5,630 <mmap_test+0x4b0>
    err("mmap call should have failed");
  if (close(fd) == -1)
     2f0:	8526                	mv	a0,s1
     2f2:	00001097          	auipc	ra,0x1
     2f6:	90c080e7          	jalr	-1780(ra) # bfe <close>
     2fa:	57fd                	li	a5,-1
     2fc:	34f50263          	beq	a0,a5,640 <mmap_test+0x4c0>
    err("close");

  printf("test mmap read-only: OK\n");
     300:	00001517          	auipc	a0,0x1
     304:	fc850513          	addi	a0,a0,-56 # 12c8 <malloc+0x2ac>
     308:	00001097          	auipc	ra,0x1
     30c:	c56080e7          	jalr	-938(ra) # f5e <printf>
    
  printf("test mmap read/write\n");
     310:	00001517          	auipc	a0,0x1
     314:	fd850513          	addi	a0,a0,-40 # 12e8 <malloc+0x2cc>
     318:	00001097          	auipc	ra,0x1
     31c:	c46080e7          	jalr	-954(ra) # f5e <printf>
  
  // check that mmap does allow read/write mapping of a
  // file opened read/write.
  if ((fd = open(f, O_RDWR)) == -1)
     320:	4589                	li	a1,2
     322:	00001517          	auipc	a0,0x1
     326:	ec650513          	addi	a0,a0,-314 # 11e8 <malloc+0x1cc>
     32a:	00001097          	auipc	ra,0x1
     32e:	8ec080e7          	jalr	-1812(ra) # c16 <open>
     332:	84aa                	mv	s1,a0
     334:	57fd                	li	a5,-1
     336:	30f50d63          	beq	a0,a5,650 <mmap_test+0x4d0>
    err("open");
  p = mmap(0, PGSIZE*3, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
     33a:	4781                	li	a5,0
     33c:	872a                	mv	a4,a0
     33e:	4685                	li	a3,1
     340:	460d                	li	a2,3
     342:	658d                	lui	a1,0x3
     344:	4501                	li	a0,0
     346:	00001097          	auipc	ra,0x1
     34a:	930080e7          	jalr	-1744(ra) # c76 <mmap>
     34e:	89aa                	mv	s3,a0
  if (p == MAP_FAILED)
     350:	57fd                	li	a5,-1
     352:	30f50763          	beq	a0,a5,660 <mmap_test+0x4e0>
    err("mmap (3)");
  if (close(fd) == -1)
     356:	8526                	mv	a0,s1
     358:	00001097          	auipc	ra,0x1
     35c:	8a6080e7          	jalr	-1882(ra) # bfe <close>
     360:	57fd                	li	a5,-1
     362:	30f50763          	beq	a0,a5,670 <mmap_test+0x4f0>
    err("close");

  // check that the mapping still works after close(fd).
  _v1(p);
     366:	854e                	mv	a0,s3
     368:	00000097          	auipc	ra,0x0
     36c:	cd6080e7          	jalr	-810(ra) # 3e <_v1>

  // write the mapped memory.
  for (i = 0; i < PGSIZE*2; i++)
     370:	87ce                	mv	a5,s3
     372:	6709                	lui	a4,0x2
     374:	974e                	add	a4,a4,s3
    p[i] = 'Z';
     376:	05a00693          	li	a3,90
     37a:	00d78023          	sb	a3,0(a5)
  for (i = 0; i < PGSIZE*2; i++)
     37e:	0785                	addi	a5,a5,1
     380:	fee79de3          	bne	a5,a4,37a <mmap_test+0x1fa>

  // unmap just the first two of three pages of mapped memory.
  if (munmap(p, PGSIZE*2) == -1)
     384:	6589                	lui	a1,0x2
     386:	854e                	mv	a0,s3
     388:	00001097          	auipc	ra,0x1
     38c:	8f6080e7          	jalr	-1802(ra) # c7e <munmap>
     390:	57fd                	li	a5,-1
     392:	2ef50763          	beq	a0,a5,680 <mmap_test+0x500>
    err("munmap (3)");
  
  printf("test mmap read/write: OK\n");
     396:	00001517          	auipc	a0,0x1
     39a:	f8a50513          	addi	a0,a0,-118 # 1320 <malloc+0x304>
     39e:	00001097          	auipc	ra,0x1
     3a2:	bc0080e7          	jalr	-1088(ra) # f5e <printf>
  
  printf("test mmap dirty\n");
     3a6:	00001517          	auipc	a0,0x1
     3aa:	f9a50513          	addi	a0,a0,-102 # 1340 <malloc+0x324>
     3ae:	00001097          	auipc	ra,0x1
     3b2:	bb0080e7          	jalr	-1104(ra) # f5e <printf>
  
  // check that the writes to the mapped memory were
  // written to the file.
  if ((fd = open(f, O_RDWR)) == -1)
     3b6:	4589                	li	a1,2
     3b8:	00001517          	auipc	a0,0x1
     3bc:	e3050513          	addi	a0,a0,-464 # 11e8 <malloc+0x1cc>
     3c0:	00001097          	auipc	ra,0x1
     3c4:	856080e7          	jalr	-1962(ra) # c16 <open>
     3c8:	892a                	mv	s2,a0
     3ca:	57fd                	li	a5,-1
     3cc:	6489                	lui	s1,0x2
     3ce:	80048493          	addi	s1,s1,-2048 # 1800 <buf+0x208>
    err("open");
  for (i = 0; i < PGSIZE + (PGSIZE/2); i++){
    char b;
    if (read(fd, &b, 1) != 1)
      err("read (1)");
    if (b != 'Z')
     3d2:	05a00a13          	li	s4,90
  if ((fd = open(f, O_RDWR)) == -1)
     3d6:	2af50d63          	beq	a0,a5,690 <mmap_test+0x510>
    if (read(fd, &b, 1) != 1)
     3da:	4605                	li	a2,1
     3dc:	fcf40593          	addi	a1,s0,-49
     3e0:	854a                	mv	a0,s2
     3e2:	00001097          	auipc	ra,0x1
     3e6:	80c080e7          	jalr	-2036(ra) # bee <read>
     3ea:	4785                	li	a5,1
     3ec:	2af51a63          	bne	a0,a5,6a0 <mmap_test+0x520>
    if (b != 'Z')
     3f0:	fcf44783          	lbu	a5,-49(s0)
     3f4:	2b479e63          	bne	a5,s4,6b0 <mmap_test+0x530>
  for (i = 0; i < PGSIZE + (PGSIZE/2); i++){
     3f8:	34fd                	addiw	s1,s1,-1
     3fa:	f0e5                	bnez	s1,3da <mmap_test+0x25a>
      err("file does not contain modifications");
  }
  if (close(fd) == -1)
     3fc:	854a                	mv	a0,s2
     3fe:	00001097          	auipc	ra,0x1
     402:	800080e7          	jalr	-2048(ra) # bfe <close>
     406:	57fd                	li	a5,-1
     408:	2af50c63          	beq	a0,a5,6c0 <mmap_test+0x540>
    err("close");

  printf("test mmap dirty: OK\n");
     40c:	00001517          	auipc	a0,0x1
     410:	f8450513          	addi	a0,a0,-124 # 1390 <malloc+0x374>
     414:	00001097          	auipc	ra,0x1
     418:	b4a080e7          	jalr	-1206(ra) # f5e <printf>

  printf("test not-mapped unmap\n");
     41c:	00001517          	auipc	a0,0x1
     420:	f8c50513          	addi	a0,a0,-116 # 13a8 <malloc+0x38c>
     424:	00001097          	auipc	ra,0x1
     428:	b3a080e7          	jalr	-1222(ra) # f5e <printf>
  
  // unmap the rest of the mapped memory.
  if (munmap(p+PGSIZE*2, PGSIZE) == -1)
     42c:	6585                	lui	a1,0x1
     42e:	6509                	lui	a0,0x2
     430:	954e                	add	a0,a0,s3
     432:	00001097          	auipc	ra,0x1
     436:	84c080e7          	jalr	-1972(ra) # c7e <munmap>
     43a:	57fd                	li	a5,-1
     43c:	28f50a63          	beq	a0,a5,6d0 <mmap_test+0x550>
    err("munmap (4)");

  printf("test not-mapped unmap: OK\n");
     440:	00001517          	auipc	a0,0x1
     444:	f9050513          	addi	a0,a0,-112 # 13d0 <malloc+0x3b4>
     448:	00001097          	auipc	ra,0x1
     44c:	b16080e7          	jalr	-1258(ra) # f5e <printf>
    
  printf("test mmap two files\n");
     450:	00001517          	auipc	a0,0x1
     454:	fa050513          	addi	a0,a0,-96 # 13f0 <malloc+0x3d4>
     458:	00001097          	auipc	ra,0x1
     45c:	b06080e7          	jalr	-1274(ra) # f5e <printf>
  
  //
  // mmap two files at the same time.
  //
  int fd1;
  if((fd1 = open("mmap1", O_RDWR|O_CREATE)) < 0)
     460:	20200593          	li	a1,514
     464:	00001517          	auipc	a0,0x1
     468:	fa450513          	addi	a0,a0,-92 # 1408 <malloc+0x3ec>
     46c:	00000097          	auipc	ra,0x0
     470:	7aa080e7          	jalr	1962(ra) # c16 <open>
     474:	84aa                	mv	s1,a0
     476:	26054563          	bltz	a0,6e0 <mmap_test+0x560>
    err("open mmap1");
  if(write(fd1, "12345", 5) != 5)
     47a:	4615                	li	a2,5
     47c:	00001597          	auipc	a1,0x1
     480:	fa458593          	addi	a1,a1,-92 # 1420 <malloc+0x404>
     484:	00000097          	auipc	ra,0x0
     488:	772080e7          	jalr	1906(ra) # bf6 <write>
     48c:	4795                	li	a5,5
     48e:	26f51163          	bne	a0,a5,6f0 <mmap_test+0x570>
    err("write mmap1");
  char *p1 = mmap(0, PGSIZE, PROT_READ, MAP_PRIVATE, fd1, 0);
     492:	4781                	li	a5,0
     494:	8726                	mv	a4,s1
     496:	4689                	li	a3,2
     498:	4605                	li	a2,1
     49a:	6585                	lui	a1,0x1
     49c:	4501                	li	a0,0
     49e:	00000097          	auipc	ra,0x0
     4a2:	7d8080e7          	jalr	2008(ra) # c76 <mmap>
     4a6:	89aa                	mv	s3,a0
  if(p1 == MAP_FAILED)
     4a8:	57fd                	li	a5,-1
     4aa:	24f50b63          	beq	a0,a5,700 <mmap_test+0x580>
    err("mmap mmap1");
  close(fd1);
     4ae:	8526                	mv	a0,s1
     4b0:	00000097          	auipc	ra,0x0
     4b4:	74e080e7          	jalr	1870(ra) # bfe <close>
  unlink("mmap1");
     4b8:	00001517          	auipc	a0,0x1
     4bc:	f5050513          	addi	a0,a0,-176 # 1408 <malloc+0x3ec>
     4c0:	00000097          	auipc	ra,0x0
     4c4:	766080e7          	jalr	1894(ra) # c26 <unlink>

  int fd2;
  if((fd2 = open("mmap2", O_RDWR|O_CREATE)) < 0)
     4c8:	20200593          	li	a1,514
     4cc:	00001517          	auipc	a0,0x1
     4d0:	f7c50513          	addi	a0,a0,-132 # 1448 <malloc+0x42c>
     4d4:	00000097          	auipc	ra,0x0
     4d8:	742080e7          	jalr	1858(ra) # c16 <open>
     4dc:	892a                	mv	s2,a0
     4de:	22054963          	bltz	a0,710 <mmap_test+0x590>
    err("open mmap2");
  if(write(fd2, "67890", 5) != 5)
     4e2:	4615                	li	a2,5
     4e4:	00001597          	auipc	a1,0x1
     4e8:	f7c58593          	addi	a1,a1,-132 # 1460 <malloc+0x444>
     4ec:	00000097          	auipc	ra,0x0
     4f0:	70a080e7          	jalr	1802(ra) # bf6 <write>
     4f4:	4795                	li	a5,5
     4f6:	22f51563          	bne	a0,a5,720 <mmap_test+0x5a0>
    err("write mmap2");
  char *p2 = mmap(0, PGSIZE, PROT_READ, MAP_PRIVATE, fd2, 0);
     4fa:	4781                	li	a5,0
     4fc:	874a                	mv	a4,s2
     4fe:	4689                	li	a3,2
     500:	4605                	li	a2,1
     502:	6585                	lui	a1,0x1
     504:	4501                	li	a0,0
     506:	00000097          	auipc	ra,0x0
     50a:	770080e7          	jalr	1904(ra) # c76 <mmap>
     50e:	84aa                	mv	s1,a0
  if(p2 == MAP_FAILED)
     510:	57fd                	li	a5,-1
     512:	20f50f63          	beq	a0,a5,730 <mmap_test+0x5b0>
    err("mmap mmap2");
  close(fd2);
     516:	854a                	mv	a0,s2
     518:	00000097          	auipc	ra,0x0
     51c:	6e6080e7          	jalr	1766(ra) # bfe <close>
  unlink("mmap2");
     520:	00001517          	auipc	a0,0x1
     524:	f2850513          	addi	a0,a0,-216 # 1448 <malloc+0x42c>
     528:	00000097          	auipc	ra,0x0
     52c:	6fe080e7          	jalr	1790(ra) # c26 <unlink>

  if(memcmp(p1, "12345", 5) != 0)
     530:	4615                	li	a2,5
     532:	00001597          	auipc	a1,0x1
     536:	eee58593          	addi	a1,a1,-274 # 1420 <malloc+0x404>
     53a:	854e                	mv	a0,s3
     53c:	00000097          	auipc	ra,0x0
     540:	640080e7          	jalr	1600(ra) # b7c <memcmp>
     544:	1e051e63          	bnez	a0,740 <mmap_test+0x5c0>
    err("mmap1 mismatch");
  if(memcmp(p2, "67890", 5) != 0)
     548:	4615                	li	a2,5
     54a:	00001597          	auipc	a1,0x1
     54e:	f1658593          	addi	a1,a1,-234 # 1460 <malloc+0x444>
     552:	8526                	mv	a0,s1
     554:	00000097          	auipc	ra,0x0
     558:	628080e7          	jalr	1576(ra) # b7c <memcmp>
     55c:	1e051a63          	bnez	a0,750 <mmap_test+0x5d0>
    err("mmap2 mismatch");

  munmap(p1, PGSIZE);
     560:	6585                	lui	a1,0x1
     562:	854e                	mv	a0,s3
     564:	00000097          	auipc	ra,0x0
     568:	71a080e7          	jalr	1818(ra) # c7e <munmap>
  if(memcmp(p2, "67890", 5) != 0)
     56c:	4615                	li	a2,5
     56e:	00001597          	auipc	a1,0x1
     572:	ef258593          	addi	a1,a1,-270 # 1460 <malloc+0x444>
     576:	8526                	mv	a0,s1
     578:	00000097          	auipc	ra,0x0
     57c:	604080e7          	jalr	1540(ra) # b7c <memcmp>
     580:	1e051063          	bnez	a0,760 <mmap_test+0x5e0>
    err("mmap2 mismatch (2)");
  munmap(p2, PGSIZE);
     584:	6585                	lui	a1,0x1
     586:	8526                	mv	a0,s1
     588:	00000097          	auipc	ra,0x0
     58c:	6f6080e7          	jalr	1782(ra) # c7e <munmap>
  
  printf("test mmap two files: OK\n");
     590:	00001517          	auipc	a0,0x1
     594:	f3050513          	addi	a0,a0,-208 # 14c0 <malloc+0x4a4>
     598:	00001097          	auipc	ra,0x1
     59c:	9c6080e7          	jalr	-1594(ra) # f5e <printf>
  
  printf("mmap_test: ALL OK\n");
     5a0:	00001517          	auipc	a0,0x1
     5a4:	f4050513          	addi	a0,a0,-192 # 14e0 <malloc+0x4c4>
     5a8:	00001097          	auipc	ra,0x1
     5ac:	9b6080e7          	jalr	-1610(ra) # f5e <printf>
}
     5b0:	70e2                	ld	ra,56(sp)
     5b2:	7442                	ld	s0,48(sp)
     5b4:	74a2                	ld	s1,40(sp)
     5b6:	7902                	ld	s2,32(sp)
     5b8:	69e2                	ld	s3,24(sp)
     5ba:	6a42                	ld	s4,16(sp)
     5bc:	6121                	addi	sp,sp,64
     5be:	8082                	ret
    err("open");
     5c0:	00001517          	auipc	a0,0x1
     5c4:	bd850513          	addi	a0,a0,-1064 # 1198 <malloc+0x17c>
     5c8:	00000097          	auipc	ra,0x0
     5cc:	a38080e7          	jalr	-1480(ra) # 0 <err>
    err("mmap (1)");
     5d0:	00001517          	auipc	a0,0x1
     5d4:	c3850513          	addi	a0,a0,-968 # 1208 <malloc+0x1ec>
     5d8:	00000097          	auipc	ra,0x0
     5dc:	a28080e7          	jalr	-1496(ra) # 0 <err>
    err("munmap (1)");
     5e0:	00001517          	auipc	a0,0x1
     5e4:	c3850513          	addi	a0,a0,-968 # 1218 <malloc+0x1fc>
     5e8:	00000097          	auipc	ra,0x0
     5ec:	a18080e7          	jalr	-1512(ra) # 0 <err>
    err("mmap (2)");
     5f0:	00001517          	auipc	a0,0x1
     5f4:	c6850513          	addi	a0,a0,-920 # 1258 <malloc+0x23c>
     5f8:	00000097          	auipc	ra,0x0
     5fc:	a08080e7          	jalr	-1528(ra) # 0 <err>
    err("close");
     600:	00001517          	auipc	a0,0x1
     604:	bb850513          	addi	a0,a0,-1096 # 11b8 <malloc+0x19c>
     608:	00000097          	auipc	ra,0x0
     60c:	9f8080e7          	jalr	-1544(ra) # 0 <err>
    err("munmap (2)");
     610:	00001517          	auipc	a0,0x1
     614:	c5850513          	addi	a0,a0,-936 # 1268 <malloc+0x24c>
     618:	00000097          	auipc	ra,0x0
     61c:	9e8080e7          	jalr	-1560(ra) # 0 <err>
    err("open");
     620:	00001517          	auipc	a0,0x1
     624:	b7850513          	addi	a0,a0,-1160 # 1198 <malloc+0x17c>
     628:	00000097          	auipc	ra,0x0
     62c:	9d8080e7          	jalr	-1576(ra) # 0 <err>
    err("mmap call should have failed");
     630:	00001517          	auipc	a0,0x1
     634:	c7850513          	addi	a0,a0,-904 # 12a8 <malloc+0x28c>
     638:	00000097          	auipc	ra,0x0
     63c:	9c8080e7          	jalr	-1592(ra) # 0 <err>
    err("close");
     640:	00001517          	auipc	a0,0x1
     644:	b7850513          	addi	a0,a0,-1160 # 11b8 <malloc+0x19c>
     648:	00000097          	auipc	ra,0x0
     64c:	9b8080e7          	jalr	-1608(ra) # 0 <err>
    err("open");
     650:	00001517          	auipc	a0,0x1
     654:	b4850513          	addi	a0,a0,-1208 # 1198 <malloc+0x17c>
     658:	00000097          	auipc	ra,0x0
     65c:	9a8080e7          	jalr	-1624(ra) # 0 <err>
    err("mmap (3)");
     660:	00001517          	auipc	a0,0x1
     664:	ca050513          	addi	a0,a0,-864 # 1300 <malloc+0x2e4>
     668:	00000097          	auipc	ra,0x0
     66c:	998080e7          	jalr	-1640(ra) # 0 <err>
    err("close");
     670:	00001517          	auipc	a0,0x1
     674:	b4850513          	addi	a0,a0,-1208 # 11b8 <malloc+0x19c>
     678:	00000097          	auipc	ra,0x0
     67c:	988080e7          	jalr	-1656(ra) # 0 <err>
    err("munmap (3)");
     680:	00001517          	auipc	a0,0x1
     684:	c9050513          	addi	a0,a0,-880 # 1310 <malloc+0x2f4>
     688:	00000097          	auipc	ra,0x0
     68c:	978080e7          	jalr	-1672(ra) # 0 <err>
    err("open");
     690:	00001517          	auipc	a0,0x1
     694:	b0850513          	addi	a0,a0,-1272 # 1198 <malloc+0x17c>
     698:	00000097          	auipc	ra,0x0
     69c:	968080e7          	jalr	-1688(ra) # 0 <err>
      err("read (1)");
     6a0:	00001517          	auipc	a0,0x1
     6a4:	cb850513          	addi	a0,a0,-840 # 1358 <malloc+0x33c>
     6a8:	00000097          	auipc	ra,0x0
     6ac:	958080e7          	jalr	-1704(ra) # 0 <err>
      err("file does not contain modifications");
     6b0:	00001517          	auipc	a0,0x1
     6b4:	cb850513          	addi	a0,a0,-840 # 1368 <malloc+0x34c>
     6b8:	00000097          	auipc	ra,0x0
     6bc:	948080e7          	jalr	-1720(ra) # 0 <err>
    err("close");
     6c0:	00001517          	auipc	a0,0x1
     6c4:	af850513          	addi	a0,a0,-1288 # 11b8 <malloc+0x19c>
     6c8:	00000097          	auipc	ra,0x0
     6cc:	938080e7          	jalr	-1736(ra) # 0 <err>
    err("munmap (4)");
     6d0:	00001517          	auipc	a0,0x1
     6d4:	cf050513          	addi	a0,a0,-784 # 13c0 <malloc+0x3a4>
     6d8:	00000097          	auipc	ra,0x0
     6dc:	928080e7          	jalr	-1752(ra) # 0 <err>
    err("open mmap1");
     6e0:	00001517          	auipc	a0,0x1
     6e4:	d3050513          	addi	a0,a0,-720 # 1410 <malloc+0x3f4>
     6e8:	00000097          	auipc	ra,0x0
     6ec:	918080e7          	jalr	-1768(ra) # 0 <err>
    err("write mmap1");
     6f0:	00001517          	auipc	a0,0x1
     6f4:	d3850513          	addi	a0,a0,-712 # 1428 <malloc+0x40c>
     6f8:	00000097          	auipc	ra,0x0
     6fc:	908080e7          	jalr	-1784(ra) # 0 <err>
    err("mmap mmap1");
     700:	00001517          	auipc	a0,0x1
     704:	d3850513          	addi	a0,a0,-712 # 1438 <malloc+0x41c>
     708:	00000097          	auipc	ra,0x0
     70c:	8f8080e7          	jalr	-1800(ra) # 0 <err>
    err("open mmap2");
     710:	00001517          	auipc	a0,0x1
     714:	d4050513          	addi	a0,a0,-704 # 1450 <malloc+0x434>
     718:	00000097          	auipc	ra,0x0
     71c:	8e8080e7          	jalr	-1816(ra) # 0 <err>
    err("write mmap2");
     720:	00001517          	auipc	a0,0x1
     724:	d4850513          	addi	a0,a0,-696 # 1468 <malloc+0x44c>
     728:	00000097          	auipc	ra,0x0
     72c:	8d8080e7          	jalr	-1832(ra) # 0 <err>
    err("mmap mmap2");
     730:	00001517          	auipc	a0,0x1
     734:	d4850513          	addi	a0,a0,-696 # 1478 <malloc+0x45c>
     738:	00000097          	auipc	ra,0x0
     73c:	8c8080e7          	jalr	-1848(ra) # 0 <err>
    err("mmap1 mismatch");
     740:	00001517          	auipc	a0,0x1
     744:	d4850513          	addi	a0,a0,-696 # 1488 <malloc+0x46c>
     748:	00000097          	auipc	ra,0x0
     74c:	8b8080e7          	jalr	-1864(ra) # 0 <err>
    err("mmap2 mismatch");
     750:	00001517          	auipc	a0,0x1
     754:	d4850513          	addi	a0,a0,-696 # 1498 <malloc+0x47c>
     758:	00000097          	auipc	ra,0x0
     75c:	8a8080e7          	jalr	-1880(ra) # 0 <err>
    err("mmap2 mismatch (2)");
     760:	00001517          	auipc	a0,0x1
     764:	d4850513          	addi	a0,a0,-696 # 14a8 <malloc+0x48c>
     768:	00000097          	auipc	ra,0x0
     76c:	898080e7          	jalr	-1896(ra) # 0 <err>

0000000000000770 <fork_test>:
// mmap a file, then fork.
// check that the child sees the mapped file.
//
void
fork_test(void)
{
     770:	7179                	addi	sp,sp,-48
     772:	f406                	sd	ra,40(sp)
     774:	f022                	sd	s0,32(sp)
     776:	ec26                	sd	s1,24(sp)
     778:	e84a                	sd	s2,16(sp)
     77a:	1800                	addi	s0,sp,48
  int fd;
  int pid;
  const char * const f = "mmap.dur";
  
  printf("fork_test starting\n");
     77c:	00001517          	auipc	a0,0x1
     780:	d7c50513          	addi	a0,a0,-644 # 14f8 <malloc+0x4dc>
     784:	00000097          	auipc	ra,0x0
     788:	7da080e7          	jalr	2010(ra) # f5e <printf>
  testname = "fork_test";
     78c:	00001797          	auipc	a5,0x1
     790:	d8478793          	addi	a5,a5,-636 # 1510 <malloc+0x4f4>
     794:	00001717          	auipc	a4,0x1
     798:	e4f73a23          	sd	a5,-428(a4) # 15e8 <testname>
  
  // mmap the file twice.
  makefile(f);
     79c:	00001517          	auipc	a0,0x1
     7a0:	a4c50513          	addi	a0,a0,-1460 # 11e8 <malloc+0x1cc>
     7a4:	00000097          	auipc	ra,0x0
     7a8:	922080e7          	jalr	-1758(ra) # c6 <makefile>
  if ((fd = open(f, O_RDONLY)) == -1)
     7ac:	4581                	li	a1,0
     7ae:	00001517          	auipc	a0,0x1
     7b2:	a3a50513          	addi	a0,a0,-1478 # 11e8 <malloc+0x1cc>
     7b6:	00000097          	auipc	ra,0x0
     7ba:	460080e7          	jalr	1120(ra) # c16 <open>
     7be:	57fd                	li	a5,-1
     7c0:	0af50a63          	beq	a0,a5,874 <fork_test+0x104>
     7c4:	84aa                	mv	s1,a0
    err("open");
  unlink(f);
     7c6:	00001517          	auipc	a0,0x1
     7ca:	a2250513          	addi	a0,a0,-1502 # 11e8 <malloc+0x1cc>
     7ce:	00000097          	auipc	ra,0x0
     7d2:	458080e7          	jalr	1112(ra) # c26 <unlink>
  char *p1 = mmap(0, PGSIZE*2, PROT_READ, MAP_SHARED, fd, 0);
     7d6:	4781                	li	a5,0
     7d8:	8726                	mv	a4,s1
     7da:	4685                	li	a3,1
     7dc:	4605                	li	a2,1
     7de:	6589                	lui	a1,0x2
     7e0:	4501                	li	a0,0
     7e2:	00000097          	auipc	ra,0x0
     7e6:	494080e7          	jalr	1172(ra) # c76 <mmap>
     7ea:	892a                	mv	s2,a0
  if (p1 == MAP_FAILED)
     7ec:	57fd                	li	a5,-1
     7ee:	08f50b63          	beq	a0,a5,884 <fork_test+0x114>
    err("mmap (4)");
  char *p2 = mmap(0, PGSIZE*2, PROT_READ, MAP_SHARED, fd, 0);
     7f2:	4781                	li	a5,0
     7f4:	8726                	mv	a4,s1
     7f6:	4685                	li	a3,1
     7f8:	4605                	li	a2,1
     7fa:	6589                	lui	a1,0x2
     7fc:	4501                	li	a0,0
     7fe:	00000097          	auipc	ra,0x0
     802:	478080e7          	jalr	1144(ra) # c76 <mmap>
     806:	84aa                	mv	s1,a0
  if (p2 == MAP_FAILED)
     808:	57fd                	li	a5,-1
     80a:	08f50563          	beq	a0,a5,894 <fork_test+0x124>
    err("mmap (5)");

  // read just 2nd page.
  if(*(p1+PGSIZE) != 'A')
     80e:	6785                	lui	a5,0x1
     810:	97ca                	add	a5,a5,s2
     812:	0007c703          	lbu	a4,0(a5) # 1000 <free+0x6c>
     816:	04100793          	li	a5,65
     81a:	08f71563          	bne	a4,a5,8a4 <fork_test+0x134>
    err("fork mismatch (1)");

  if((pid = fork()) < 0)
     81e:	00000097          	auipc	ra,0x0
     822:	3b0080e7          	jalr	944(ra) # bce <fork>
     826:	08054763          	bltz	a0,8b4 <fork_test+0x144>
    err("fork");
  if (pid == 0) {
     82a:	cd49                	beqz	a0,8c4 <fork_test+0x154>
    munmap(p1, PGSIZE); // just the first page
    printf("2\n");
    exit(0); // tell the parent that the mapping looks OK.
  }

  int status = -1;
     82c:	57fd                	li	a5,-1
     82e:	fcf42e23          	sw	a5,-36(s0)
  wait(&status);
     832:	fdc40513          	addi	a0,s0,-36
     836:	00000097          	auipc	ra,0x0
     83a:	3a8080e7          	jalr	936(ra) # bde <wait>

  if(status != 0){
     83e:	fdc42783          	lw	a5,-36(s0)
     842:	ebe9                	bnez	a5,914 <fork_test+0x1a4>
    printf("fork_test failed\n");
    exit(1);
  }

  // check that the parent's mappings are still there.
  _v1(p1);
     844:	854a                	mv	a0,s2
     846:	fffff097          	auipc	ra,0xfffff
     84a:	7f8080e7          	jalr	2040(ra) # 3e <_v1>
  _v1(p2);
     84e:	8526                	mv	a0,s1
     850:	fffff097          	auipc	ra,0xfffff
     854:	7ee080e7          	jalr	2030(ra) # 3e <_v1>

  printf("fork_test OK\n");
     858:	00001517          	auipc	a0,0x1
     85c:	d3850513          	addi	a0,a0,-712 # 1590 <malloc+0x574>
     860:	00000097          	auipc	ra,0x0
     864:	6fe080e7          	jalr	1790(ra) # f5e <printf>
}
     868:	70a2                	ld	ra,40(sp)
     86a:	7402                	ld	s0,32(sp)
     86c:	64e2                	ld	s1,24(sp)
     86e:	6942                	ld	s2,16(sp)
     870:	6145                	addi	sp,sp,48
     872:	8082                	ret
    err("open");
     874:	00001517          	auipc	a0,0x1
     878:	92450513          	addi	a0,a0,-1756 # 1198 <malloc+0x17c>
     87c:	fffff097          	auipc	ra,0xfffff
     880:	784080e7          	jalr	1924(ra) # 0 <err>
    err("mmap (4)");
     884:	00001517          	auipc	a0,0x1
     888:	c9c50513          	addi	a0,a0,-868 # 1520 <malloc+0x504>
     88c:	fffff097          	auipc	ra,0xfffff
     890:	774080e7          	jalr	1908(ra) # 0 <err>
    err("mmap (5)");
     894:	00001517          	auipc	a0,0x1
     898:	c9c50513          	addi	a0,a0,-868 # 1530 <malloc+0x514>
     89c:	fffff097          	auipc	ra,0xfffff
     8a0:	764080e7          	jalr	1892(ra) # 0 <err>
    err("fork mismatch (1)");
     8a4:	00001517          	auipc	a0,0x1
     8a8:	c9c50513          	addi	a0,a0,-868 # 1540 <malloc+0x524>
     8ac:	fffff097          	auipc	ra,0xfffff
     8b0:	754080e7          	jalr	1876(ra) # 0 <err>
    err("fork");
     8b4:	00001517          	auipc	a0,0x1
     8b8:	ca450513          	addi	a0,a0,-860 # 1558 <malloc+0x53c>
     8bc:	fffff097          	auipc	ra,0xfffff
     8c0:	744080e7          	jalr	1860(ra) # 0 <err>
    printf("0\n");
     8c4:	00001517          	auipc	a0,0x1
     8c8:	c9c50513          	addi	a0,a0,-868 # 1560 <malloc+0x544>
     8cc:	00000097          	auipc	ra,0x0
     8d0:	692080e7          	jalr	1682(ra) # f5e <printf>
    _v1(p1);
     8d4:	854a                	mv	a0,s2
     8d6:	fffff097          	auipc	ra,0xfffff
     8da:	768080e7          	jalr	1896(ra) # 3e <_v1>
    printf("1\n");
     8de:	00001517          	auipc	a0,0x1
     8e2:	c8a50513          	addi	a0,a0,-886 # 1568 <malloc+0x54c>
     8e6:	00000097          	auipc	ra,0x0
     8ea:	678080e7          	jalr	1656(ra) # f5e <printf>
    munmap(p1, PGSIZE); // just the first page
     8ee:	6585                	lui	a1,0x1
     8f0:	854a                	mv	a0,s2
     8f2:	00000097          	auipc	ra,0x0
     8f6:	38c080e7          	jalr	908(ra) # c7e <munmap>
    printf("2\n");
     8fa:	00001517          	auipc	a0,0x1
     8fe:	c7650513          	addi	a0,a0,-906 # 1570 <malloc+0x554>
     902:	00000097          	auipc	ra,0x0
     906:	65c080e7          	jalr	1628(ra) # f5e <printf>
    exit(0); // tell the parent that the mapping looks OK.
     90a:	4501                	li	a0,0
     90c:	00000097          	auipc	ra,0x0
     910:	2ca080e7          	jalr	714(ra) # bd6 <exit>
    printf("fork_test failed\n");
     914:	00001517          	auipc	a0,0x1
     918:	c6450513          	addi	a0,a0,-924 # 1578 <malloc+0x55c>
     91c:	00000097          	auipc	ra,0x0
     920:	642080e7          	jalr	1602(ra) # f5e <printf>
    exit(1);
     924:	4505                	li	a0,1
     926:	00000097          	auipc	ra,0x0
     92a:	2b0080e7          	jalr	688(ra) # bd6 <exit>

000000000000092e <main>:
{
     92e:	1141                	addi	sp,sp,-16
     930:	e406                	sd	ra,8(sp)
     932:	e022                	sd	s0,0(sp)
     934:	0800                	addi	s0,sp,16
  mmap_test();
     936:	00000097          	auipc	ra,0x0
     93a:	84a080e7          	jalr	-1974(ra) # 180 <mmap_test>
  fork_test();
     93e:	00000097          	auipc	ra,0x0
     942:	e32080e7          	jalr	-462(ra) # 770 <fork_test>
  printf("mmaptest: all tests succeeded\n");
     946:	00001517          	auipc	a0,0x1
     94a:	c5a50513          	addi	a0,a0,-934 # 15a0 <malloc+0x584>
     94e:	00000097          	auipc	ra,0x0
     952:	610080e7          	jalr	1552(ra) # f5e <printf>
  exit(0);
     956:	4501                	li	a0,0
     958:	00000097          	auipc	ra,0x0
     95c:	27e080e7          	jalr	638(ra) # bd6 <exit>

0000000000000960 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
     960:	1141                	addi	sp,sp,-16
     962:	e422                	sd	s0,8(sp)
     964:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
     966:	87aa                	mv	a5,a0
     968:	0585                	addi	a1,a1,1
     96a:	0785                	addi	a5,a5,1
     96c:	fff5c703          	lbu	a4,-1(a1) # fff <free+0x6b>
     970:	fee78fa3          	sb	a4,-1(a5)
     974:	fb75                	bnez	a4,968 <strcpy+0x8>
    ;
  return os;
}
     976:	6422                	ld	s0,8(sp)
     978:	0141                	addi	sp,sp,16
     97a:	8082                	ret

000000000000097c <strcmp>:

int
strcmp(const char *p, const char *q)
{
     97c:	1141                	addi	sp,sp,-16
     97e:	e422                	sd	s0,8(sp)
     980:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
     982:	00054783          	lbu	a5,0(a0)
     986:	cb91                	beqz	a5,99a <strcmp+0x1e>
     988:	0005c703          	lbu	a4,0(a1)
     98c:	00f71763          	bne	a4,a5,99a <strcmp+0x1e>
    p++, q++;
     990:	0505                	addi	a0,a0,1
     992:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
     994:	00054783          	lbu	a5,0(a0)
     998:	fbe5                	bnez	a5,988 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
     99a:	0005c503          	lbu	a0,0(a1)
}
     99e:	40a7853b          	subw	a0,a5,a0
     9a2:	6422                	ld	s0,8(sp)
     9a4:	0141                	addi	sp,sp,16
     9a6:	8082                	ret

00000000000009a8 <strlen>:

uint
strlen(const char *s)
{
     9a8:	1141                	addi	sp,sp,-16
     9aa:	e422                	sd	s0,8(sp)
     9ac:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
     9ae:	00054783          	lbu	a5,0(a0)
     9b2:	cf91                	beqz	a5,9ce <strlen+0x26>
     9b4:	0505                	addi	a0,a0,1
     9b6:	87aa                	mv	a5,a0
     9b8:	4685                	li	a3,1
     9ba:	9e89                	subw	a3,a3,a0
     9bc:	00f6853b          	addw	a0,a3,a5
     9c0:	0785                	addi	a5,a5,1
     9c2:	fff7c703          	lbu	a4,-1(a5)
     9c6:	fb7d                	bnez	a4,9bc <strlen+0x14>
    ;
  return n;
}
     9c8:	6422                	ld	s0,8(sp)
     9ca:	0141                	addi	sp,sp,16
     9cc:	8082                	ret
  for(n = 0; s[n]; n++)
     9ce:	4501                	li	a0,0
     9d0:	bfe5                	j	9c8 <strlen+0x20>

00000000000009d2 <memset>:

void*
memset(void *dst, int c, uint n)
{
     9d2:	1141                	addi	sp,sp,-16
     9d4:	e422                	sd	s0,8(sp)
     9d6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
     9d8:	ce09                	beqz	a2,9f2 <memset+0x20>
     9da:	87aa                	mv	a5,a0
     9dc:	fff6071b          	addiw	a4,a2,-1
     9e0:	1702                	slli	a4,a4,0x20
     9e2:	9301                	srli	a4,a4,0x20
     9e4:	0705                	addi	a4,a4,1
     9e6:	972a                	add	a4,a4,a0
    cdst[i] = c;
     9e8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
     9ec:	0785                	addi	a5,a5,1
     9ee:	fee79de3          	bne	a5,a4,9e8 <memset+0x16>
  }
  return dst;
}
     9f2:	6422                	ld	s0,8(sp)
     9f4:	0141                	addi	sp,sp,16
     9f6:	8082                	ret

00000000000009f8 <strchr>:

char*
strchr(const char *s, char c)
{
     9f8:	1141                	addi	sp,sp,-16
     9fa:	e422                	sd	s0,8(sp)
     9fc:	0800                	addi	s0,sp,16
  for(; *s; s++)
     9fe:	00054783          	lbu	a5,0(a0)
     a02:	cb99                	beqz	a5,a18 <strchr+0x20>
    if(*s == c)
     a04:	00f58763          	beq	a1,a5,a12 <strchr+0x1a>
  for(; *s; s++)
     a08:	0505                	addi	a0,a0,1
     a0a:	00054783          	lbu	a5,0(a0)
     a0e:	fbfd                	bnez	a5,a04 <strchr+0xc>
      return (char*)s;
  return 0;
     a10:	4501                	li	a0,0
}
     a12:	6422                	ld	s0,8(sp)
     a14:	0141                	addi	sp,sp,16
     a16:	8082                	ret
  return 0;
     a18:	4501                	li	a0,0
     a1a:	bfe5                	j	a12 <strchr+0x1a>

0000000000000a1c <gets>:

char*
gets(char *buf, int max)
{
     a1c:	711d                	addi	sp,sp,-96
     a1e:	ec86                	sd	ra,88(sp)
     a20:	e8a2                	sd	s0,80(sp)
     a22:	e4a6                	sd	s1,72(sp)
     a24:	e0ca                	sd	s2,64(sp)
     a26:	fc4e                	sd	s3,56(sp)
     a28:	f852                	sd	s4,48(sp)
     a2a:	f456                	sd	s5,40(sp)
     a2c:	f05a                	sd	s6,32(sp)
     a2e:	ec5e                	sd	s7,24(sp)
     a30:	1080                	addi	s0,sp,96
     a32:	8baa                	mv	s7,a0
     a34:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
     a36:	892a                	mv	s2,a0
     a38:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
     a3a:	4aa9                	li	s5,10
     a3c:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
     a3e:	89a6                	mv	s3,s1
     a40:	2485                	addiw	s1,s1,1
     a42:	0344d863          	bge	s1,s4,a72 <gets+0x56>
    cc = read(0, &c, 1);
     a46:	4605                	li	a2,1
     a48:	faf40593          	addi	a1,s0,-81
     a4c:	4501                	li	a0,0
     a4e:	00000097          	auipc	ra,0x0
     a52:	1a0080e7          	jalr	416(ra) # bee <read>
    if(cc < 1)
     a56:	00a05e63          	blez	a0,a72 <gets+0x56>
    buf[i++] = c;
     a5a:	faf44783          	lbu	a5,-81(s0)
     a5e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
     a62:	01578763          	beq	a5,s5,a70 <gets+0x54>
     a66:	0905                	addi	s2,s2,1
     a68:	fd679be3          	bne	a5,s6,a3e <gets+0x22>
  for(i=0; i+1 < max; ){
     a6c:	89a6                	mv	s3,s1
     a6e:	a011                	j	a72 <gets+0x56>
     a70:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
     a72:	99de                	add	s3,s3,s7
     a74:	00098023          	sb	zero,0(s3)
  return buf;
}
     a78:	855e                	mv	a0,s7
     a7a:	60e6                	ld	ra,88(sp)
     a7c:	6446                	ld	s0,80(sp)
     a7e:	64a6                	ld	s1,72(sp)
     a80:	6906                	ld	s2,64(sp)
     a82:	79e2                	ld	s3,56(sp)
     a84:	7a42                	ld	s4,48(sp)
     a86:	7aa2                	ld	s5,40(sp)
     a88:	7b02                	ld	s6,32(sp)
     a8a:	6be2                	ld	s7,24(sp)
     a8c:	6125                	addi	sp,sp,96
     a8e:	8082                	ret

0000000000000a90 <stat>:

int
stat(const char *n, struct stat *st)
{
     a90:	1101                	addi	sp,sp,-32
     a92:	ec06                	sd	ra,24(sp)
     a94:	e822                	sd	s0,16(sp)
     a96:	e426                	sd	s1,8(sp)
     a98:	e04a                	sd	s2,0(sp)
     a9a:	1000                	addi	s0,sp,32
     a9c:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
     a9e:	4581                	li	a1,0
     aa0:	00000097          	auipc	ra,0x0
     aa4:	176080e7          	jalr	374(ra) # c16 <open>
  if(fd < 0)
     aa8:	02054563          	bltz	a0,ad2 <stat+0x42>
     aac:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
     aae:	85ca                	mv	a1,s2
     ab0:	00000097          	auipc	ra,0x0
     ab4:	17e080e7          	jalr	382(ra) # c2e <fstat>
     ab8:	892a                	mv	s2,a0
  close(fd);
     aba:	8526                	mv	a0,s1
     abc:	00000097          	auipc	ra,0x0
     ac0:	142080e7          	jalr	322(ra) # bfe <close>
  return r;
}
     ac4:	854a                	mv	a0,s2
     ac6:	60e2                	ld	ra,24(sp)
     ac8:	6442                	ld	s0,16(sp)
     aca:	64a2                	ld	s1,8(sp)
     acc:	6902                	ld	s2,0(sp)
     ace:	6105                	addi	sp,sp,32
     ad0:	8082                	ret
    return -1;
     ad2:	597d                	li	s2,-1
     ad4:	bfc5                	j	ac4 <stat+0x34>

0000000000000ad6 <atoi>:

int
atoi(const char *s)
{
     ad6:	1141                	addi	sp,sp,-16
     ad8:	e422                	sd	s0,8(sp)
     ada:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
     adc:	00054603          	lbu	a2,0(a0)
     ae0:	fd06079b          	addiw	a5,a2,-48
     ae4:	0ff7f793          	andi	a5,a5,255
     ae8:	4725                	li	a4,9
     aea:	02f76963          	bltu	a4,a5,b1c <atoi+0x46>
     aee:	86aa                	mv	a3,a0
  n = 0;
     af0:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
     af2:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
     af4:	0685                	addi	a3,a3,1
     af6:	0025179b          	slliw	a5,a0,0x2
     afa:	9fa9                	addw	a5,a5,a0
     afc:	0017979b          	slliw	a5,a5,0x1
     b00:	9fb1                	addw	a5,a5,a2
     b02:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
     b06:	0006c603          	lbu	a2,0(a3)
     b0a:	fd06071b          	addiw	a4,a2,-48
     b0e:	0ff77713          	andi	a4,a4,255
     b12:	fee5f1e3          	bgeu	a1,a4,af4 <atoi+0x1e>
  return n;
}
     b16:	6422                	ld	s0,8(sp)
     b18:	0141                	addi	sp,sp,16
     b1a:	8082                	ret
  n = 0;
     b1c:	4501                	li	a0,0
     b1e:	bfe5                	j	b16 <atoi+0x40>

0000000000000b20 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
     b20:	1141                	addi	sp,sp,-16
     b22:	e422                	sd	s0,8(sp)
     b24:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
     b26:	02b57663          	bgeu	a0,a1,b52 <memmove+0x32>
    while(n-- > 0)
     b2a:	02c05163          	blez	a2,b4c <memmove+0x2c>
     b2e:	fff6079b          	addiw	a5,a2,-1
     b32:	1782                	slli	a5,a5,0x20
     b34:	9381                	srli	a5,a5,0x20
     b36:	0785                	addi	a5,a5,1
     b38:	97aa                	add	a5,a5,a0
  dst = vdst;
     b3a:	872a                	mv	a4,a0
      *dst++ = *src++;
     b3c:	0585                	addi	a1,a1,1
     b3e:	0705                	addi	a4,a4,1
     b40:	fff5c683          	lbu	a3,-1(a1)
     b44:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
     b48:	fee79ae3          	bne	a5,a4,b3c <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
     b4c:	6422                	ld	s0,8(sp)
     b4e:	0141                	addi	sp,sp,16
     b50:	8082                	ret
    dst += n;
     b52:	00c50733          	add	a4,a0,a2
    src += n;
     b56:	95b2                	add	a1,a1,a2
    while(n-- > 0)
     b58:	fec05ae3          	blez	a2,b4c <memmove+0x2c>
     b5c:	fff6079b          	addiw	a5,a2,-1
     b60:	1782                	slli	a5,a5,0x20
     b62:	9381                	srli	a5,a5,0x20
     b64:	fff7c793          	not	a5,a5
     b68:	97ba                	add	a5,a5,a4
      *--dst = *--src;
     b6a:	15fd                	addi	a1,a1,-1
     b6c:	177d                	addi	a4,a4,-1
     b6e:	0005c683          	lbu	a3,0(a1)
     b72:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
     b76:	fee79ae3          	bne	a5,a4,b6a <memmove+0x4a>
     b7a:	bfc9                	j	b4c <memmove+0x2c>

0000000000000b7c <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
     b7c:	1141                	addi	sp,sp,-16
     b7e:	e422                	sd	s0,8(sp)
     b80:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
     b82:	ca05                	beqz	a2,bb2 <memcmp+0x36>
     b84:	fff6069b          	addiw	a3,a2,-1
     b88:	1682                	slli	a3,a3,0x20
     b8a:	9281                	srli	a3,a3,0x20
     b8c:	0685                	addi	a3,a3,1
     b8e:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
     b90:	00054783          	lbu	a5,0(a0)
     b94:	0005c703          	lbu	a4,0(a1)
     b98:	00e79863          	bne	a5,a4,ba8 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
     b9c:	0505                	addi	a0,a0,1
    p2++;
     b9e:	0585                	addi	a1,a1,1
  while (n-- > 0) {
     ba0:	fed518e3          	bne	a0,a3,b90 <memcmp+0x14>
  }
  return 0;
     ba4:	4501                	li	a0,0
     ba6:	a019                	j	bac <memcmp+0x30>
      return *p1 - *p2;
     ba8:	40e7853b          	subw	a0,a5,a4
}
     bac:	6422                	ld	s0,8(sp)
     bae:	0141                	addi	sp,sp,16
     bb0:	8082                	ret
  return 0;
     bb2:	4501                	li	a0,0
     bb4:	bfe5                	j	bac <memcmp+0x30>

0000000000000bb6 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
     bb6:	1141                	addi	sp,sp,-16
     bb8:	e406                	sd	ra,8(sp)
     bba:	e022                	sd	s0,0(sp)
     bbc:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
     bbe:	00000097          	auipc	ra,0x0
     bc2:	f62080e7          	jalr	-158(ra) # b20 <memmove>
}
     bc6:	60a2                	ld	ra,8(sp)
     bc8:	6402                	ld	s0,0(sp)
     bca:	0141                	addi	sp,sp,16
     bcc:	8082                	ret

0000000000000bce <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
     bce:	4885                	li	a7,1
 ecall
     bd0:	00000073          	ecall
 ret
     bd4:	8082                	ret

0000000000000bd6 <exit>:
.global exit
exit:
 li a7, SYS_exit
     bd6:	4889                	li	a7,2
 ecall
     bd8:	00000073          	ecall
 ret
     bdc:	8082                	ret

0000000000000bde <wait>:
.global wait
wait:
 li a7, SYS_wait
     bde:	488d                	li	a7,3
 ecall
     be0:	00000073          	ecall
 ret
     be4:	8082                	ret

0000000000000be6 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
     be6:	4891                	li	a7,4
 ecall
     be8:	00000073          	ecall
 ret
     bec:	8082                	ret

0000000000000bee <read>:
.global read
read:
 li a7, SYS_read
     bee:	4895                	li	a7,5
 ecall
     bf0:	00000073          	ecall
 ret
     bf4:	8082                	ret

0000000000000bf6 <write>:
.global write
write:
 li a7, SYS_write
     bf6:	48c1                	li	a7,16
 ecall
     bf8:	00000073          	ecall
 ret
     bfc:	8082                	ret

0000000000000bfe <close>:
.global close
close:
 li a7, SYS_close
     bfe:	48d5                	li	a7,21
 ecall
     c00:	00000073          	ecall
 ret
     c04:	8082                	ret

0000000000000c06 <kill>:
.global kill
kill:
 li a7, SYS_kill
     c06:	4899                	li	a7,6
 ecall
     c08:	00000073          	ecall
 ret
     c0c:	8082                	ret

0000000000000c0e <exec>:
.global exec
exec:
 li a7, SYS_exec
     c0e:	489d                	li	a7,7
 ecall
     c10:	00000073          	ecall
 ret
     c14:	8082                	ret

0000000000000c16 <open>:
.global open
open:
 li a7, SYS_open
     c16:	48bd                	li	a7,15
 ecall
     c18:	00000073          	ecall
 ret
     c1c:	8082                	ret

0000000000000c1e <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
     c1e:	48c5                	li	a7,17
 ecall
     c20:	00000073          	ecall
 ret
     c24:	8082                	ret

0000000000000c26 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
     c26:	48c9                	li	a7,18
 ecall
     c28:	00000073          	ecall
 ret
     c2c:	8082                	ret

0000000000000c2e <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
     c2e:	48a1                	li	a7,8
 ecall
     c30:	00000073          	ecall
 ret
     c34:	8082                	ret

0000000000000c36 <link>:
.global link
link:
 li a7, SYS_link
     c36:	48cd                	li	a7,19
 ecall
     c38:	00000073          	ecall
 ret
     c3c:	8082                	ret

0000000000000c3e <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
     c3e:	48d1                	li	a7,20
 ecall
     c40:	00000073          	ecall
 ret
     c44:	8082                	ret

0000000000000c46 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
     c46:	48a5                	li	a7,9
 ecall
     c48:	00000073          	ecall
 ret
     c4c:	8082                	ret

0000000000000c4e <dup>:
.global dup
dup:
 li a7, SYS_dup
     c4e:	48a9                	li	a7,10
 ecall
     c50:	00000073          	ecall
 ret
     c54:	8082                	ret

0000000000000c56 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
     c56:	48ad                	li	a7,11
 ecall
     c58:	00000073          	ecall
 ret
     c5c:	8082                	ret

0000000000000c5e <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
     c5e:	48b1                	li	a7,12
 ecall
     c60:	00000073          	ecall
 ret
     c64:	8082                	ret

0000000000000c66 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
     c66:	48b5                	li	a7,13
 ecall
     c68:	00000073          	ecall
 ret
     c6c:	8082                	ret

0000000000000c6e <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
     c6e:	48b9                	li	a7,14
 ecall
     c70:	00000073          	ecall
 ret
     c74:	8082                	ret

0000000000000c76 <mmap>:
.global mmap
mmap:
 li a7, SYS_mmap
     c76:	48d9                	li	a7,22
 ecall
     c78:	00000073          	ecall
 ret
     c7c:	8082                	ret

0000000000000c7e <munmap>:
.global munmap
munmap:
 li a7, SYS_munmap
     c7e:	48dd                	li	a7,23
 ecall
     c80:	00000073          	ecall
 ret
     c84:	8082                	ret

0000000000000c86 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
     c86:	1101                	addi	sp,sp,-32
     c88:	ec06                	sd	ra,24(sp)
     c8a:	e822                	sd	s0,16(sp)
     c8c:	1000                	addi	s0,sp,32
     c8e:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
     c92:	4605                	li	a2,1
     c94:	fef40593          	addi	a1,s0,-17
     c98:	00000097          	auipc	ra,0x0
     c9c:	f5e080e7          	jalr	-162(ra) # bf6 <write>
}
     ca0:	60e2                	ld	ra,24(sp)
     ca2:	6442                	ld	s0,16(sp)
     ca4:	6105                	addi	sp,sp,32
     ca6:	8082                	ret

0000000000000ca8 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
     ca8:	7139                	addi	sp,sp,-64
     caa:	fc06                	sd	ra,56(sp)
     cac:	f822                	sd	s0,48(sp)
     cae:	f426                	sd	s1,40(sp)
     cb0:	f04a                	sd	s2,32(sp)
     cb2:	ec4e                	sd	s3,24(sp)
     cb4:	0080                	addi	s0,sp,64
     cb6:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
     cb8:	c299                	beqz	a3,cbe <printint+0x16>
     cba:	0805c863          	bltz	a1,d4a <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
     cbe:	2581                	sext.w	a1,a1
  neg = 0;
     cc0:	4881                	li	a7,0
     cc2:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
     cc6:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
     cc8:	2601                	sext.w	a2,a2
     cca:	00001517          	auipc	a0,0x1
     cce:	90650513          	addi	a0,a0,-1786 # 15d0 <digits>
     cd2:	883a                	mv	a6,a4
     cd4:	2705                	addiw	a4,a4,1
     cd6:	02c5f7bb          	remuw	a5,a1,a2
     cda:	1782                	slli	a5,a5,0x20
     cdc:	9381                	srli	a5,a5,0x20
     cde:	97aa                	add	a5,a5,a0
     ce0:	0007c783          	lbu	a5,0(a5)
     ce4:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
     ce8:	0005879b          	sext.w	a5,a1
     cec:	02c5d5bb          	divuw	a1,a1,a2
     cf0:	0685                	addi	a3,a3,1
     cf2:	fec7f0e3          	bgeu	a5,a2,cd2 <printint+0x2a>
  if(neg)
     cf6:	00088b63          	beqz	a7,d0c <printint+0x64>
    buf[i++] = '-';
     cfa:	fd040793          	addi	a5,s0,-48
     cfe:	973e                	add	a4,a4,a5
     d00:	02d00793          	li	a5,45
     d04:	fef70823          	sb	a5,-16(a4)
     d08:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
     d0c:	02e05863          	blez	a4,d3c <printint+0x94>
     d10:	fc040793          	addi	a5,s0,-64
     d14:	00e78933          	add	s2,a5,a4
     d18:	fff78993          	addi	s3,a5,-1
     d1c:	99ba                	add	s3,s3,a4
     d1e:	377d                	addiw	a4,a4,-1
     d20:	1702                	slli	a4,a4,0x20
     d22:	9301                	srli	a4,a4,0x20
     d24:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
     d28:	fff94583          	lbu	a1,-1(s2)
     d2c:	8526                	mv	a0,s1
     d2e:	00000097          	auipc	ra,0x0
     d32:	f58080e7          	jalr	-168(ra) # c86 <putc>
  while(--i >= 0)
     d36:	197d                	addi	s2,s2,-1
     d38:	ff3918e3          	bne	s2,s3,d28 <printint+0x80>
}
     d3c:	70e2                	ld	ra,56(sp)
     d3e:	7442                	ld	s0,48(sp)
     d40:	74a2                	ld	s1,40(sp)
     d42:	7902                	ld	s2,32(sp)
     d44:	69e2                	ld	s3,24(sp)
     d46:	6121                	addi	sp,sp,64
     d48:	8082                	ret
    x = -xx;
     d4a:	40b005bb          	negw	a1,a1
    neg = 1;
     d4e:	4885                	li	a7,1
    x = -xx;
     d50:	bf8d                	j	cc2 <printint+0x1a>

0000000000000d52 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
     d52:	7119                	addi	sp,sp,-128
     d54:	fc86                	sd	ra,120(sp)
     d56:	f8a2                	sd	s0,112(sp)
     d58:	f4a6                	sd	s1,104(sp)
     d5a:	f0ca                	sd	s2,96(sp)
     d5c:	ecce                	sd	s3,88(sp)
     d5e:	e8d2                	sd	s4,80(sp)
     d60:	e4d6                	sd	s5,72(sp)
     d62:	e0da                	sd	s6,64(sp)
     d64:	fc5e                	sd	s7,56(sp)
     d66:	f862                	sd	s8,48(sp)
     d68:	f466                	sd	s9,40(sp)
     d6a:	f06a                	sd	s10,32(sp)
     d6c:	ec6e                	sd	s11,24(sp)
     d6e:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
     d70:	0005c903          	lbu	s2,0(a1)
     d74:	18090f63          	beqz	s2,f12 <vprintf+0x1c0>
     d78:	8aaa                	mv	s5,a0
     d7a:	8b32                	mv	s6,a2
     d7c:	00158493          	addi	s1,a1,1
  state = 0;
     d80:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
     d82:	02500a13          	li	s4,37
      if(c == 'd'){
     d86:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
     d8a:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
     d8e:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
     d92:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
     d96:	00001b97          	auipc	s7,0x1
     d9a:	83ab8b93          	addi	s7,s7,-1990 # 15d0 <digits>
     d9e:	a839                	j	dbc <vprintf+0x6a>
        putc(fd, c);
     da0:	85ca                	mv	a1,s2
     da2:	8556                	mv	a0,s5
     da4:	00000097          	auipc	ra,0x0
     da8:	ee2080e7          	jalr	-286(ra) # c86 <putc>
     dac:	a019                	j	db2 <vprintf+0x60>
    } else if(state == '%'){
     dae:	01498f63          	beq	s3,s4,dcc <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
     db2:	0485                	addi	s1,s1,1
     db4:	fff4c903          	lbu	s2,-1(s1)
     db8:	14090d63          	beqz	s2,f12 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
     dbc:	0009079b          	sext.w	a5,s2
    if(state == 0){
     dc0:	fe0997e3          	bnez	s3,dae <vprintf+0x5c>
      if(c == '%'){
     dc4:	fd479ee3          	bne	a5,s4,da0 <vprintf+0x4e>
        state = '%';
     dc8:	89be                	mv	s3,a5
     dca:	b7e5                	j	db2 <vprintf+0x60>
      if(c == 'd'){
     dcc:	05878063          	beq	a5,s8,e0c <vprintf+0xba>
      } else if(c == 'l') {
     dd0:	05978c63          	beq	a5,s9,e28 <vprintf+0xd6>
      } else if(c == 'x') {
     dd4:	07a78863          	beq	a5,s10,e44 <vprintf+0xf2>
      } else if(c == 'p') {
     dd8:	09b78463          	beq	a5,s11,e60 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
     ddc:	07300713          	li	a4,115
     de0:	0ce78663          	beq	a5,a4,eac <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
     de4:	06300713          	li	a4,99
     de8:	0ee78e63          	beq	a5,a4,ee4 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
     dec:	11478863          	beq	a5,s4,efc <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
     df0:	85d2                	mv	a1,s4
     df2:	8556                	mv	a0,s5
     df4:	00000097          	auipc	ra,0x0
     df8:	e92080e7          	jalr	-366(ra) # c86 <putc>
        putc(fd, c);
     dfc:	85ca                	mv	a1,s2
     dfe:	8556                	mv	a0,s5
     e00:	00000097          	auipc	ra,0x0
     e04:	e86080e7          	jalr	-378(ra) # c86 <putc>
      }
      state = 0;
     e08:	4981                	li	s3,0
     e0a:	b765                	j	db2 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
     e0c:	008b0913          	addi	s2,s6,8
     e10:	4685                	li	a3,1
     e12:	4629                	li	a2,10
     e14:	000b2583          	lw	a1,0(s6)
     e18:	8556                	mv	a0,s5
     e1a:	00000097          	auipc	ra,0x0
     e1e:	e8e080e7          	jalr	-370(ra) # ca8 <printint>
     e22:	8b4a                	mv	s6,s2
      state = 0;
     e24:	4981                	li	s3,0
     e26:	b771                	j	db2 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
     e28:	008b0913          	addi	s2,s6,8
     e2c:	4681                	li	a3,0
     e2e:	4629                	li	a2,10
     e30:	000b2583          	lw	a1,0(s6)
     e34:	8556                	mv	a0,s5
     e36:	00000097          	auipc	ra,0x0
     e3a:	e72080e7          	jalr	-398(ra) # ca8 <printint>
     e3e:	8b4a                	mv	s6,s2
      state = 0;
     e40:	4981                	li	s3,0
     e42:	bf85                	j	db2 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
     e44:	008b0913          	addi	s2,s6,8
     e48:	4681                	li	a3,0
     e4a:	4641                	li	a2,16
     e4c:	000b2583          	lw	a1,0(s6)
     e50:	8556                	mv	a0,s5
     e52:	00000097          	auipc	ra,0x0
     e56:	e56080e7          	jalr	-426(ra) # ca8 <printint>
     e5a:	8b4a                	mv	s6,s2
      state = 0;
     e5c:	4981                	li	s3,0
     e5e:	bf91                	j	db2 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
     e60:	008b0793          	addi	a5,s6,8
     e64:	f8f43423          	sd	a5,-120(s0)
     e68:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
     e6c:	03000593          	li	a1,48
     e70:	8556                	mv	a0,s5
     e72:	00000097          	auipc	ra,0x0
     e76:	e14080e7          	jalr	-492(ra) # c86 <putc>
  putc(fd, 'x');
     e7a:	85ea                	mv	a1,s10
     e7c:	8556                	mv	a0,s5
     e7e:	00000097          	auipc	ra,0x0
     e82:	e08080e7          	jalr	-504(ra) # c86 <putc>
     e86:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
     e88:	03c9d793          	srli	a5,s3,0x3c
     e8c:	97de                	add	a5,a5,s7
     e8e:	0007c583          	lbu	a1,0(a5)
     e92:	8556                	mv	a0,s5
     e94:	00000097          	auipc	ra,0x0
     e98:	df2080e7          	jalr	-526(ra) # c86 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
     e9c:	0992                	slli	s3,s3,0x4
     e9e:	397d                	addiw	s2,s2,-1
     ea0:	fe0914e3          	bnez	s2,e88 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
     ea4:	f8843b03          	ld	s6,-120(s0)
      state = 0;
     ea8:	4981                	li	s3,0
     eaa:	b721                	j	db2 <vprintf+0x60>
        s = va_arg(ap, char*);
     eac:	008b0993          	addi	s3,s6,8
     eb0:	000b3903          	ld	s2,0(s6)
        if(s == 0)
     eb4:	02090163          	beqz	s2,ed6 <vprintf+0x184>
        while(*s != 0){
     eb8:	00094583          	lbu	a1,0(s2)
     ebc:	c9a1                	beqz	a1,f0c <vprintf+0x1ba>
          putc(fd, *s);
     ebe:	8556                	mv	a0,s5
     ec0:	00000097          	auipc	ra,0x0
     ec4:	dc6080e7          	jalr	-570(ra) # c86 <putc>
          s++;
     ec8:	0905                	addi	s2,s2,1
        while(*s != 0){
     eca:	00094583          	lbu	a1,0(s2)
     ece:	f9e5                	bnez	a1,ebe <vprintf+0x16c>
        s = va_arg(ap, char*);
     ed0:	8b4e                	mv	s6,s3
      state = 0;
     ed2:	4981                	li	s3,0
     ed4:	bdf9                	j	db2 <vprintf+0x60>
          s = "(null)";
     ed6:	00000917          	auipc	s2,0x0
     eda:	6f290913          	addi	s2,s2,1778 # 15c8 <malloc+0x5ac>
        while(*s != 0){
     ede:	02800593          	li	a1,40
     ee2:	bff1                	j	ebe <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
     ee4:	008b0913          	addi	s2,s6,8
     ee8:	000b4583          	lbu	a1,0(s6)
     eec:	8556                	mv	a0,s5
     eee:	00000097          	auipc	ra,0x0
     ef2:	d98080e7          	jalr	-616(ra) # c86 <putc>
     ef6:	8b4a                	mv	s6,s2
      state = 0;
     ef8:	4981                	li	s3,0
     efa:	bd65                	j	db2 <vprintf+0x60>
        putc(fd, c);
     efc:	85d2                	mv	a1,s4
     efe:	8556                	mv	a0,s5
     f00:	00000097          	auipc	ra,0x0
     f04:	d86080e7          	jalr	-634(ra) # c86 <putc>
      state = 0;
     f08:	4981                	li	s3,0
     f0a:	b565                	j	db2 <vprintf+0x60>
        s = va_arg(ap, char*);
     f0c:	8b4e                	mv	s6,s3
      state = 0;
     f0e:	4981                	li	s3,0
     f10:	b54d                	j	db2 <vprintf+0x60>
    }
  }
}
     f12:	70e6                	ld	ra,120(sp)
     f14:	7446                	ld	s0,112(sp)
     f16:	74a6                	ld	s1,104(sp)
     f18:	7906                	ld	s2,96(sp)
     f1a:	69e6                	ld	s3,88(sp)
     f1c:	6a46                	ld	s4,80(sp)
     f1e:	6aa6                	ld	s5,72(sp)
     f20:	6b06                	ld	s6,64(sp)
     f22:	7be2                	ld	s7,56(sp)
     f24:	7c42                	ld	s8,48(sp)
     f26:	7ca2                	ld	s9,40(sp)
     f28:	7d02                	ld	s10,32(sp)
     f2a:	6de2                	ld	s11,24(sp)
     f2c:	6109                	addi	sp,sp,128
     f2e:	8082                	ret

0000000000000f30 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
     f30:	715d                	addi	sp,sp,-80
     f32:	ec06                	sd	ra,24(sp)
     f34:	e822                	sd	s0,16(sp)
     f36:	1000                	addi	s0,sp,32
     f38:	e010                	sd	a2,0(s0)
     f3a:	e414                	sd	a3,8(s0)
     f3c:	e818                	sd	a4,16(s0)
     f3e:	ec1c                	sd	a5,24(s0)
     f40:	03043023          	sd	a6,32(s0)
     f44:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
     f48:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
     f4c:	8622                	mv	a2,s0
     f4e:	00000097          	auipc	ra,0x0
     f52:	e04080e7          	jalr	-508(ra) # d52 <vprintf>
}
     f56:	60e2                	ld	ra,24(sp)
     f58:	6442                	ld	s0,16(sp)
     f5a:	6161                	addi	sp,sp,80
     f5c:	8082                	ret

0000000000000f5e <printf>:

void
printf(const char *fmt, ...)
{
     f5e:	711d                	addi	sp,sp,-96
     f60:	ec06                	sd	ra,24(sp)
     f62:	e822                	sd	s0,16(sp)
     f64:	1000                	addi	s0,sp,32
     f66:	e40c                	sd	a1,8(s0)
     f68:	e810                	sd	a2,16(s0)
     f6a:	ec14                	sd	a3,24(s0)
     f6c:	f018                	sd	a4,32(s0)
     f6e:	f41c                	sd	a5,40(s0)
     f70:	03043823          	sd	a6,48(s0)
     f74:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
     f78:	00840613          	addi	a2,s0,8
     f7c:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
     f80:	85aa                	mv	a1,a0
     f82:	4505                	li	a0,1
     f84:	00000097          	auipc	ra,0x0
     f88:	dce080e7          	jalr	-562(ra) # d52 <vprintf>
}
     f8c:	60e2                	ld	ra,24(sp)
     f8e:	6442                	ld	s0,16(sp)
     f90:	6125                	addi	sp,sp,96
     f92:	8082                	ret

0000000000000f94 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
     f94:	1141                	addi	sp,sp,-16
     f96:	e422                	sd	s0,8(sp)
     f98:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
     f9a:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
     f9e:	00000797          	auipc	a5,0x0
     fa2:	6527b783          	ld	a5,1618(a5) # 15f0 <freep>
     fa6:	a805                	j	fd6 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
     fa8:	4618                	lw	a4,8(a2)
     faa:	9db9                	addw	a1,a1,a4
     fac:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
     fb0:	6398                	ld	a4,0(a5)
     fb2:	6318                	ld	a4,0(a4)
     fb4:	fee53823          	sd	a4,-16(a0)
     fb8:	a091                	j	ffc <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
     fba:	ff852703          	lw	a4,-8(a0)
     fbe:	9e39                	addw	a2,a2,a4
     fc0:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
     fc2:	ff053703          	ld	a4,-16(a0)
     fc6:	e398                	sd	a4,0(a5)
     fc8:	a099                	j	100e <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
     fca:	6398                	ld	a4,0(a5)
     fcc:	00e7e463          	bltu	a5,a4,fd4 <free+0x40>
     fd0:	00e6ea63          	bltu	a3,a4,fe4 <free+0x50>
{
     fd4:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
     fd6:	fed7fae3          	bgeu	a5,a3,fca <free+0x36>
     fda:	6398                	ld	a4,0(a5)
     fdc:	00e6e463          	bltu	a3,a4,fe4 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
     fe0:	fee7eae3          	bltu	a5,a4,fd4 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
     fe4:	ff852583          	lw	a1,-8(a0)
     fe8:	6390                	ld	a2,0(a5)
     fea:	02059713          	slli	a4,a1,0x20
     fee:	9301                	srli	a4,a4,0x20
     ff0:	0712                	slli	a4,a4,0x4
     ff2:	9736                	add	a4,a4,a3
     ff4:	fae60ae3          	beq	a2,a4,fa8 <free+0x14>
    bp->s.ptr = p->s.ptr;
     ff8:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
     ffc:	4790                	lw	a2,8(a5)
     ffe:	02061713          	slli	a4,a2,0x20
    1002:	9301                	srli	a4,a4,0x20
    1004:	0712                	slli	a4,a4,0x4
    1006:	973e                	add	a4,a4,a5
    1008:	fae689e3          	beq	a3,a4,fba <free+0x26>
  } else
    p->s.ptr = bp;
    100c:	e394                	sd	a3,0(a5)
  freep = p;
    100e:	00000717          	auipc	a4,0x0
    1012:	5ef73123          	sd	a5,1506(a4) # 15f0 <freep>
}
    1016:	6422                	ld	s0,8(sp)
    1018:	0141                	addi	sp,sp,16
    101a:	8082                	ret

000000000000101c <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
    101c:	7139                	addi	sp,sp,-64
    101e:	fc06                	sd	ra,56(sp)
    1020:	f822                	sd	s0,48(sp)
    1022:	f426                	sd	s1,40(sp)
    1024:	f04a                	sd	s2,32(sp)
    1026:	ec4e                	sd	s3,24(sp)
    1028:	e852                	sd	s4,16(sp)
    102a:	e456                	sd	s5,8(sp)
    102c:	e05a                	sd	s6,0(sp)
    102e:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
    1030:	02051493          	slli	s1,a0,0x20
    1034:	9081                	srli	s1,s1,0x20
    1036:	04bd                	addi	s1,s1,15
    1038:	8091                	srli	s1,s1,0x4
    103a:	0014899b          	addiw	s3,s1,1
    103e:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
    1040:	00000517          	auipc	a0,0x0
    1044:	5b053503          	ld	a0,1456(a0) # 15f0 <freep>
    1048:	c515                	beqz	a0,1074 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    104a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    104c:	4798                	lw	a4,8(a5)
    104e:	02977f63          	bgeu	a4,s1,108c <malloc+0x70>
    1052:	8a4e                	mv	s4,s3
    1054:	0009871b          	sext.w	a4,s3
    1058:	6685                	lui	a3,0x1
    105a:	00d77363          	bgeu	a4,a3,1060 <malloc+0x44>
    105e:	6a05                	lui	s4,0x1
    1060:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
    1064:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
    1068:	00000917          	auipc	s2,0x0
    106c:	58890913          	addi	s2,s2,1416 # 15f0 <freep>
  if(p == (char*)-1)
    1070:	5afd                	li	s5,-1
    1072:	a88d                	j	10e4 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
    1074:	00001797          	auipc	a5,0x1
    1078:	98478793          	addi	a5,a5,-1660 # 19f8 <base>
    107c:	00000717          	auipc	a4,0x0
    1080:	56f73a23          	sd	a5,1396(a4) # 15f0 <freep>
    1084:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
    1086:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
    108a:	b7e1                	j	1052 <malloc+0x36>
      if(p->s.size == nunits)
    108c:	02e48b63          	beq	s1,a4,10c2 <malloc+0xa6>
        p->s.size -= nunits;
    1090:	4137073b          	subw	a4,a4,s3
    1094:	c798                	sw	a4,8(a5)
        p += p->s.size;
    1096:	1702                	slli	a4,a4,0x20
    1098:	9301                	srli	a4,a4,0x20
    109a:	0712                	slli	a4,a4,0x4
    109c:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
    109e:	0137a423          	sw	s3,8(a5)
      freep = prevp;
    10a2:	00000717          	auipc	a4,0x0
    10a6:	54a73723          	sd	a0,1358(a4) # 15f0 <freep>
      return (void*)(p + 1);
    10aa:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
    10ae:	70e2                	ld	ra,56(sp)
    10b0:	7442                	ld	s0,48(sp)
    10b2:	74a2                	ld	s1,40(sp)
    10b4:	7902                	ld	s2,32(sp)
    10b6:	69e2                	ld	s3,24(sp)
    10b8:	6a42                	ld	s4,16(sp)
    10ba:	6aa2                	ld	s5,8(sp)
    10bc:	6b02                	ld	s6,0(sp)
    10be:	6121                	addi	sp,sp,64
    10c0:	8082                	ret
        prevp->s.ptr = p->s.ptr;
    10c2:	6398                	ld	a4,0(a5)
    10c4:	e118                	sd	a4,0(a0)
    10c6:	bff1                	j	10a2 <malloc+0x86>
  hp->s.size = nu;
    10c8:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
    10cc:	0541                	addi	a0,a0,16
    10ce:	00000097          	auipc	ra,0x0
    10d2:	ec6080e7          	jalr	-314(ra) # f94 <free>
  return freep;
    10d6:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
    10da:	d971                	beqz	a0,10ae <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    10dc:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    10de:	4798                	lw	a4,8(a5)
    10e0:	fa9776e3          	bgeu	a4,s1,108c <malloc+0x70>
    if(p == freep)
    10e4:	00093703          	ld	a4,0(s2)
    10e8:	853e                	mv	a0,a5
    10ea:	fef719e3          	bne	a4,a5,10dc <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
    10ee:	8552                	mv	a0,s4
    10f0:	00000097          	auipc	ra,0x0
    10f4:	b6e080e7          	jalr	-1170(ra) # c5e <sbrk>
  if(p == (char*)-1)
    10f8:	fd5518e3          	bne	a0,s5,10c8 <malloc+0xac>
        return 0;
    10fc:	4501                	li	a0,0
    10fe:	bf45                	j	10ae <malloc+0x92>
