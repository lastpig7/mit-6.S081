
user/_sysinfotest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <sinfo>:
#include "kernel/sysinfo.h"
#include "user/user.h"


void
sinfo(struct sysinfo *info) {
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
  if (sysinfo(info) < 0) {
   8:	00000097          	auipc	ra,0x0
   c:	662080e7          	jalr	1634(ra) # 66a <sysinfo>
  10:	00054663          	bltz	a0,1c <sinfo+0x1c>
    printf("FAIL: sysinfo failed");
    exit(1);
  }
}
  14:	60a2                	ld	ra,8(sp)
  16:	6402                	ld	s0,0(sp)
  18:	0141                	addi	sp,sp,16
  1a:	8082                	ret
    printf("FAIL: sysinfo failed");
  1c:	00001517          	auipc	a0,0x1
  20:	ad450513          	addi	a0,a0,-1324 # af0 <malloc+0xe8>
  24:	00001097          	auipc	ra,0x1
  28:	926080e7          	jalr	-1754(ra) # 94a <printf>
    exit(1);
  2c:	4505                	li	a0,1
  2e:	00000097          	auipc	ra,0x0
  32:	594080e7          	jalr	1428(ra) # 5c2 <exit>

0000000000000036 <countfree>:
//
// use sbrk() to count how many free physical memory pages there are.
//
int
countfree()
{
  36:	7139                	addi	sp,sp,-64
  38:	fc06                	sd	ra,56(sp)
  3a:	f822                	sd	s0,48(sp)
  3c:	f426                	sd	s1,40(sp)
  3e:	f04a                	sd	s2,32(sp)
  40:	ec4e                	sd	s3,24(sp)
  42:	e852                	sd	s4,16(sp)
  44:	0080                	addi	s0,sp,64
  uint64 sz0 = (uint64)sbrk(0);
  46:	4501                	li	a0,0
  48:	00000097          	auipc	ra,0x0
  4c:	602080e7          	jalr	1538(ra) # 64a <sbrk>
  50:	8a2a                	mv	s4,a0
  struct sysinfo info;
  int n = 0;
  52:	4481                	li	s1,0

  while(1){
    if((uint64)sbrk(PGSIZE) == 0xffffffffffffffff){
  54:	597d                	li	s2,-1
      break;
    }
    n += PGSIZE;
  56:	6985                	lui	s3,0x1
    if((uint64)sbrk(PGSIZE) == 0xffffffffffffffff){
  58:	6505                	lui	a0,0x1
  5a:	00000097          	auipc	ra,0x0
  5e:	5f0080e7          	jalr	1520(ra) # 64a <sbrk>
  62:	01250563          	beq	a0,s2,6c <countfree+0x36>
    n += PGSIZE;
  66:	009984bb          	addw	s1,s3,s1
    if((uint64)sbrk(PGSIZE) == 0xffffffffffffffff){
  6a:	b7fd                	j	58 <countfree+0x22>
  }
  sinfo(&info);
  6c:	fc040513          	addi	a0,s0,-64
  70:	00000097          	auipc	ra,0x0
  74:	f90080e7          	jalr	-112(ra) # 0 <sinfo>
  if (info.freemem != 0) {
  78:	fc043583          	ld	a1,-64(s0)
  7c:	e58d                	bnez	a1,a6 <countfree+0x70>
    printf("FAIL: there is no free mem, but sysinfo.freemem=%d\n",
      info.freemem);
    exit(1);
  }
  sbrk(-((uint64)sbrk(0) - sz0));
  7e:	4501                	li	a0,0
  80:	00000097          	auipc	ra,0x0
  84:	5ca080e7          	jalr	1482(ra) # 64a <sbrk>
  88:	40aa053b          	subw	a0,s4,a0
  8c:	00000097          	auipc	ra,0x0
  90:	5be080e7          	jalr	1470(ra) # 64a <sbrk>
  return n;
}
  94:	8526                	mv	a0,s1
  96:	70e2                	ld	ra,56(sp)
  98:	7442                	ld	s0,48(sp)
  9a:	74a2                	ld	s1,40(sp)
  9c:	7902                	ld	s2,32(sp)
  9e:	69e2                	ld	s3,24(sp)
  a0:	6a42                	ld	s4,16(sp)
  a2:	6121                	addi	sp,sp,64
  a4:	8082                	ret
    printf("FAIL: there is no free mem, but sysinfo.freemem=%d\n",
  a6:	00001517          	auipc	a0,0x1
  aa:	a6250513          	addi	a0,a0,-1438 # b08 <malloc+0x100>
  ae:	00001097          	auipc	ra,0x1
  b2:	89c080e7          	jalr	-1892(ra) # 94a <printf>
    exit(1);
  b6:	4505                	li	a0,1
  b8:	00000097          	auipc	ra,0x0
  bc:	50a080e7          	jalr	1290(ra) # 5c2 <exit>

00000000000000c0 <testmem>:

void
testmem() {
  c0:	7179                	addi	sp,sp,-48
  c2:	f406                	sd	ra,40(sp)
  c4:	f022                	sd	s0,32(sp)
  c6:	ec26                	sd	s1,24(sp)
  c8:	e84a                	sd	s2,16(sp)
  ca:	1800                	addi	s0,sp,48
  struct sysinfo info;
  uint64 n = countfree();
  cc:	00000097          	auipc	ra,0x0
  d0:	f6a080e7          	jalr	-150(ra) # 36 <countfree>
  d4:	84aa                	mv	s1,a0
  
  sinfo(&info);
  d6:	fd040513          	addi	a0,s0,-48
  da:	00000097          	auipc	ra,0x0
  de:	f26080e7          	jalr	-218(ra) # 0 <sinfo>
  printf("%d\n",&info);
  e2:	fd040593          	addi	a1,s0,-48
  e6:	00001517          	auipc	a0,0x1
  ea:	a5250513          	addi	a0,a0,-1454 # b38 <malloc+0x130>
  ee:	00001097          	auipc	ra,0x1
  f2:	85c080e7          	jalr	-1956(ra) # 94a <printf>
  if (info.freemem!= n) {
  f6:	fd043583          	ld	a1,-48(s0)
  fa:	04959e63          	bne	a1,s1,156 <testmem+0x96>
    printf("FAIL: free mem %d (bytes) instead of %d\n", info.freemem, n);
    exit(1);
  }
  
  if((uint64)sbrk(PGSIZE) == 0xffffffffffffffff){
  fe:	6505                	lui	a0,0x1
 100:	00000097          	auipc	ra,0x0
 104:	54a080e7          	jalr	1354(ra) # 64a <sbrk>
 108:	57fd                	li	a5,-1
 10a:	06f50463          	beq	a0,a5,172 <testmem+0xb2>
    printf("sbrk failed");
    exit(1);
  }

  sinfo(&info);
 10e:	fd040513          	addi	a0,s0,-48
 112:	00000097          	auipc	ra,0x0
 116:	eee080e7          	jalr	-274(ra) # 0 <sinfo>
    
  if (info.freemem != n-PGSIZE) {
 11a:	fd043603          	ld	a2,-48(s0)
 11e:	75fd                	lui	a1,0xfffff
 120:	95a6                	add	a1,a1,s1
 122:	06b61563          	bne	a2,a1,18c <testmem+0xcc>
    printf("FAIL: free mem %d (bytes) instead of %d\n", n-PGSIZE, info.freemem);
    exit(1);
  }
  
  if((uint64)sbrk(-PGSIZE) == 0xffffffffffffffff){
 126:	757d                	lui	a0,0xfffff
 128:	00000097          	auipc	ra,0x0
 12c:	522080e7          	jalr	1314(ra) # 64a <sbrk>
 130:	57fd                	li	a5,-1
 132:	06f50a63          	beq	a0,a5,1a6 <testmem+0xe6>
    printf("sbrk failed");
    exit(1);
  }

  sinfo(&info);
 136:	fd040513          	addi	a0,s0,-48
 13a:	00000097          	auipc	ra,0x0
 13e:	ec6080e7          	jalr	-314(ra) # 0 <sinfo>
    
  if (info.freemem != n) {
 142:	fd043603          	ld	a2,-48(s0)
 146:	06961d63          	bne	a2,s1,1c0 <testmem+0x100>
    printf("FAIL: free mem %d (bytes) instead of %d\n", n, info.freemem);
    exit(1);
  }
}
 14a:	70a2                	ld	ra,40(sp)
 14c:	7402                	ld	s0,32(sp)
 14e:	64e2                	ld	s1,24(sp)
 150:	6942                	ld	s2,16(sp)
 152:	6145                	addi	sp,sp,48
 154:	8082                	ret
    printf("FAIL: free mem %d (bytes) instead of %d\n", info.freemem, n);
 156:	8626                	mv	a2,s1
 158:	00001517          	auipc	a0,0x1
 15c:	9e850513          	addi	a0,a0,-1560 # b40 <malloc+0x138>
 160:	00000097          	auipc	ra,0x0
 164:	7ea080e7          	jalr	2026(ra) # 94a <printf>
    exit(1);
 168:	4505                	li	a0,1
 16a:	00000097          	auipc	ra,0x0
 16e:	458080e7          	jalr	1112(ra) # 5c2 <exit>
    printf("sbrk failed");
 172:	00001517          	auipc	a0,0x1
 176:	9fe50513          	addi	a0,a0,-1538 # b70 <malloc+0x168>
 17a:	00000097          	auipc	ra,0x0
 17e:	7d0080e7          	jalr	2000(ra) # 94a <printf>
    exit(1);
 182:	4505                	li	a0,1
 184:	00000097          	auipc	ra,0x0
 188:	43e080e7          	jalr	1086(ra) # 5c2 <exit>
    printf("FAIL: free mem %d (bytes) instead of %d\n", n-PGSIZE, info.freemem);
 18c:	00001517          	auipc	a0,0x1
 190:	9b450513          	addi	a0,a0,-1612 # b40 <malloc+0x138>
 194:	00000097          	auipc	ra,0x0
 198:	7b6080e7          	jalr	1974(ra) # 94a <printf>
    exit(1);
 19c:	4505                	li	a0,1
 19e:	00000097          	auipc	ra,0x0
 1a2:	424080e7          	jalr	1060(ra) # 5c2 <exit>
    printf("sbrk failed");
 1a6:	00001517          	auipc	a0,0x1
 1aa:	9ca50513          	addi	a0,a0,-1590 # b70 <malloc+0x168>
 1ae:	00000097          	auipc	ra,0x0
 1b2:	79c080e7          	jalr	1948(ra) # 94a <printf>
    exit(1);
 1b6:	4505                	li	a0,1
 1b8:	00000097          	auipc	ra,0x0
 1bc:	40a080e7          	jalr	1034(ra) # 5c2 <exit>
    printf("FAIL: free mem %d (bytes) instead of %d\n", n, info.freemem);
 1c0:	85a6                	mv	a1,s1
 1c2:	00001517          	auipc	a0,0x1
 1c6:	97e50513          	addi	a0,a0,-1666 # b40 <malloc+0x138>
 1ca:	00000097          	auipc	ra,0x0
 1ce:	780080e7          	jalr	1920(ra) # 94a <printf>
    exit(1);
 1d2:	4505                	li	a0,1
 1d4:	00000097          	auipc	ra,0x0
 1d8:	3ee080e7          	jalr	1006(ra) # 5c2 <exit>

00000000000001dc <testcall>:

void
testcall() {
 1dc:	1101                	addi	sp,sp,-32
 1de:	ec06                	sd	ra,24(sp)
 1e0:	e822                	sd	s0,16(sp)
 1e2:	1000                	addi	s0,sp,32
  struct sysinfo info;
  
  if (sysinfo(&info) < 0) {
 1e4:	fe040513          	addi	a0,s0,-32
 1e8:	00000097          	auipc	ra,0x0
 1ec:	482080e7          	jalr	1154(ra) # 66a <sysinfo>
 1f0:	02054163          	bltz	a0,212 <testcall+0x36>
    printf("FAIL: sysinfo failed\n");
    exit(1);
  }

  if (sysinfo((struct sysinfo *) 0xeaeb0b5b00002f5e) !=  0xffffffffffffffff) {
 1f4:	00001517          	auipc	a0,0x1
 1f8:	a7453503          	ld	a0,-1420(a0) # c68 <__SDATA_BEGIN__>
 1fc:	00000097          	auipc	ra,0x0
 200:	46e080e7          	jalr	1134(ra) # 66a <sysinfo>
 204:	57fd                	li	a5,-1
 206:	02f51363          	bne	a0,a5,22c <testcall+0x50>
    printf("FAIL: sysinfo succeeded with bad argument\n");
    exit(1);
  }
}
 20a:	60e2                	ld	ra,24(sp)
 20c:	6442                	ld	s0,16(sp)
 20e:	6105                	addi	sp,sp,32
 210:	8082                	ret
    printf("FAIL: sysinfo failed\n");
 212:	00001517          	auipc	a0,0x1
 216:	96e50513          	addi	a0,a0,-1682 # b80 <malloc+0x178>
 21a:	00000097          	auipc	ra,0x0
 21e:	730080e7          	jalr	1840(ra) # 94a <printf>
    exit(1);
 222:	4505                	li	a0,1
 224:	00000097          	auipc	ra,0x0
 228:	39e080e7          	jalr	926(ra) # 5c2 <exit>
    printf("FAIL: sysinfo succeeded with bad argument\n");
 22c:	00001517          	auipc	a0,0x1
 230:	96c50513          	addi	a0,a0,-1684 # b98 <malloc+0x190>
 234:	00000097          	auipc	ra,0x0
 238:	716080e7          	jalr	1814(ra) # 94a <printf>
    exit(1);
 23c:	4505                	li	a0,1
 23e:	00000097          	auipc	ra,0x0
 242:	384080e7          	jalr	900(ra) # 5c2 <exit>

0000000000000246 <testproc>:

void testproc() {
 246:	7139                	addi	sp,sp,-64
 248:	fc06                	sd	ra,56(sp)
 24a:	f822                	sd	s0,48(sp)
 24c:	f426                	sd	s1,40(sp)
 24e:	0080                	addi	s0,sp,64
  struct sysinfo info;
  uint64 nproc;
  int status;
  int pid;
  
  sinfo(&info);
 250:	fd040513          	addi	a0,s0,-48
 254:	00000097          	auipc	ra,0x0
 258:	dac080e7          	jalr	-596(ra) # 0 <sinfo>
  nproc = info.nproc;
 25c:	fd843483          	ld	s1,-40(s0)

  pid = fork();
 260:	00000097          	auipc	ra,0x0
 264:	35a080e7          	jalr	858(ra) # 5ba <fork>
  if(pid < 0){
 268:	02054c63          	bltz	a0,2a0 <testproc+0x5a>
    printf("sysinfotest: fork failed\n");
    exit(1);
  }
  if(pid == 0){
 26c:	ed21                	bnez	a0,2c4 <testproc+0x7e>
    sinfo(&info);
 26e:	fd040513          	addi	a0,s0,-48
 272:	00000097          	auipc	ra,0x0
 276:	d8e080e7          	jalr	-626(ra) # 0 <sinfo>
    if(info.nproc != nproc+1) {
 27a:	fd843583          	ld	a1,-40(s0)
 27e:	00148613          	addi	a2,s1,1
 282:	02c58c63          	beq	a1,a2,2ba <testproc+0x74>
      printf("sysinfotest: FAIL nproc is %d instead of %d\n", info.nproc, nproc+1);
 286:	00001517          	auipc	a0,0x1
 28a:	96250513          	addi	a0,a0,-1694 # be8 <malloc+0x1e0>
 28e:	00000097          	auipc	ra,0x0
 292:	6bc080e7          	jalr	1724(ra) # 94a <printf>
      exit(1);
 296:	4505                	li	a0,1
 298:	00000097          	auipc	ra,0x0
 29c:	32a080e7          	jalr	810(ra) # 5c2 <exit>
    printf("sysinfotest: fork failed\n");
 2a0:	00001517          	auipc	a0,0x1
 2a4:	92850513          	addi	a0,a0,-1752 # bc8 <malloc+0x1c0>
 2a8:	00000097          	auipc	ra,0x0
 2ac:	6a2080e7          	jalr	1698(ra) # 94a <printf>
    exit(1);
 2b0:	4505                	li	a0,1
 2b2:	00000097          	auipc	ra,0x0
 2b6:	310080e7          	jalr	784(ra) # 5c2 <exit>
    }
    exit(0);
 2ba:	4501                	li	a0,0
 2bc:	00000097          	auipc	ra,0x0
 2c0:	306080e7          	jalr	774(ra) # 5c2 <exit>
  }
  wait(&status);
 2c4:	fcc40513          	addi	a0,s0,-52
 2c8:	00000097          	auipc	ra,0x0
 2cc:	302080e7          	jalr	770(ra) # 5ca <wait>
  sinfo(&info);
 2d0:	fd040513          	addi	a0,s0,-48
 2d4:	00000097          	auipc	ra,0x0
 2d8:	d2c080e7          	jalr	-724(ra) # 0 <sinfo>
  if(info.nproc != nproc) {
 2dc:	fd843583          	ld	a1,-40(s0)
 2e0:	00959763          	bne	a1,s1,2ee <testproc+0xa8>
      printf("sysinfotest: FAIL nproc is %d instead of %d\n", info.nproc, nproc);
      exit(1);
  }
}
 2e4:	70e2                	ld	ra,56(sp)
 2e6:	7442                	ld	s0,48(sp)
 2e8:	74a2                	ld	s1,40(sp)
 2ea:	6121                	addi	sp,sp,64
 2ec:	8082                	ret
      printf("sysinfotest: FAIL nproc is %d instead of %d\n", info.nproc, nproc);
 2ee:	8626                	mv	a2,s1
 2f0:	00001517          	auipc	a0,0x1
 2f4:	8f850513          	addi	a0,a0,-1800 # be8 <malloc+0x1e0>
 2f8:	00000097          	auipc	ra,0x0
 2fc:	652080e7          	jalr	1618(ra) # 94a <printf>
      exit(1);
 300:	4505                	li	a0,1
 302:	00000097          	auipc	ra,0x0
 306:	2c0080e7          	jalr	704(ra) # 5c2 <exit>

000000000000030a <main>:

int
main(int argc, char *argv[])
{
 30a:	1141                	addi	sp,sp,-16
 30c:	e406                	sd	ra,8(sp)
 30e:	e022                	sd	s0,0(sp)
 310:	0800                	addi	s0,sp,16
  printf("sysinfotest: start\n");
 312:	00001517          	auipc	a0,0x1
 316:	90650513          	addi	a0,a0,-1786 # c18 <malloc+0x210>
 31a:	00000097          	auipc	ra,0x0
 31e:	630080e7          	jalr	1584(ra) # 94a <printf>
  //testcall();
  testmem();
 322:	00000097          	auipc	ra,0x0
 326:	d9e080e7          	jalr	-610(ra) # c0 <testmem>
  testproc();
 32a:	00000097          	auipc	ra,0x0
 32e:	f1c080e7          	jalr	-228(ra) # 246 <testproc>
  printf("sysinfotest: OK\n");
 332:	00001517          	auipc	a0,0x1
 336:	8fe50513          	addi	a0,a0,-1794 # c30 <malloc+0x228>
 33a:	00000097          	auipc	ra,0x0
 33e:	610080e7          	jalr	1552(ra) # 94a <printf>
  exit(0);
 342:	4501                	li	a0,0
 344:	00000097          	auipc	ra,0x0
 348:	27e080e7          	jalr	638(ra) # 5c2 <exit>

000000000000034c <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 34c:	1141                	addi	sp,sp,-16
 34e:	e422                	sd	s0,8(sp)
 350:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 352:	87aa                	mv	a5,a0
 354:	0585                	addi	a1,a1,1
 356:	0785                	addi	a5,a5,1
 358:	fff5c703          	lbu	a4,-1(a1) # ffffffffffffefff <__global_pointer$+0xffffffffffffdb9e>
 35c:	fee78fa3          	sb	a4,-1(a5)
 360:	fb75                	bnez	a4,354 <strcpy+0x8>
    ;
  return os;
}
 362:	6422                	ld	s0,8(sp)
 364:	0141                	addi	sp,sp,16
 366:	8082                	ret

0000000000000368 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 368:	1141                	addi	sp,sp,-16
 36a:	e422                	sd	s0,8(sp)
 36c:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 36e:	00054783          	lbu	a5,0(a0)
 372:	cb91                	beqz	a5,386 <strcmp+0x1e>
 374:	0005c703          	lbu	a4,0(a1)
 378:	00f71763          	bne	a4,a5,386 <strcmp+0x1e>
    p++, q++;
 37c:	0505                	addi	a0,a0,1
 37e:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 380:	00054783          	lbu	a5,0(a0)
 384:	fbe5                	bnez	a5,374 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 386:	0005c503          	lbu	a0,0(a1)
}
 38a:	40a7853b          	subw	a0,a5,a0
 38e:	6422                	ld	s0,8(sp)
 390:	0141                	addi	sp,sp,16
 392:	8082                	ret

0000000000000394 <strlen>:

uint
strlen(const char *s)
{
 394:	1141                	addi	sp,sp,-16
 396:	e422                	sd	s0,8(sp)
 398:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 39a:	00054783          	lbu	a5,0(a0)
 39e:	cf91                	beqz	a5,3ba <strlen+0x26>
 3a0:	0505                	addi	a0,a0,1
 3a2:	87aa                	mv	a5,a0
 3a4:	4685                	li	a3,1
 3a6:	9e89                	subw	a3,a3,a0
 3a8:	00f6853b          	addw	a0,a3,a5
 3ac:	0785                	addi	a5,a5,1
 3ae:	fff7c703          	lbu	a4,-1(a5)
 3b2:	fb7d                	bnez	a4,3a8 <strlen+0x14>
    ;
  return n;
}
 3b4:	6422                	ld	s0,8(sp)
 3b6:	0141                	addi	sp,sp,16
 3b8:	8082                	ret
  for(n = 0; s[n]; n++)
 3ba:	4501                	li	a0,0
 3bc:	bfe5                	j	3b4 <strlen+0x20>

00000000000003be <memset>:

void*
memset(void *dst, int c, uint n)
{
 3be:	1141                	addi	sp,sp,-16
 3c0:	e422                	sd	s0,8(sp)
 3c2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 3c4:	ce09                	beqz	a2,3de <memset+0x20>
 3c6:	87aa                	mv	a5,a0
 3c8:	fff6071b          	addiw	a4,a2,-1
 3cc:	1702                	slli	a4,a4,0x20
 3ce:	9301                	srli	a4,a4,0x20
 3d0:	0705                	addi	a4,a4,1
 3d2:	972a                	add	a4,a4,a0
    cdst[i] = c;
 3d4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 3d8:	0785                	addi	a5,a5,1
 3da:	fee79de3          	bne	a5,a4,3d4 <memset+0x16>
  }
  return dst;
}
 3de:	6422                	ld	s0,8(sp)
 3e0:	0141                	addi	sp,sp,16
 3e2:	8082                	ret

00000000000003e4 <strchr>:

char*
strchr(const char *s, char c)
{
 3e4:	1141                	addi	sp,sp,-16
 3e6:	e422                	sd	s0,8(sp)
 3e8:	0800                	addi	s0,sp,16
  for(; *s; s++)
 3ea:	00054783          	lbu	a5,0(a0)
 3ee:	cb99                	beqz	a5,404 <strchr+0x20>
    if(*s == c)
 3f0:	00f58763          	beq	a1,a5,3fe <strchr+0x1a>
  for(; *s; s++)
 3f4:	0505                	addi	a0,a0,1
 3f6:	00054783          	lbu	a5,0(a0)
 3fa:	fbfd                	bnez	a5,3f0 <strchr+0xc>
      return (char*)s;
  return 0;
 3fc:	4501                	li	a0,0
}
 3fe:	6422                	ld	s0,8(sp)
 400:	0141                	addi	sp,sp,16
 402:	8082                	ret
  return 0;
 404:	4501                	li	a0,0
 406:	bfe5                	j	3fe <strchr+0x1a>

0000000000000408 <gets>:

char*
gets(char *buf, int max)
{
 408:	711d                	addi	sp,sp,-96
 40a:	ec86                	sd	ra,88(sp)
 40c:	e8a2                	sd	s0,80(sp)
 40e:	e4a6                	sd	s1,72(sp)
 410:	e0ca                	sd	s2,64(sp)
 412:	fc4e                	sd	s3,56(sp)
 414:	f852                	sd	s4,48(sp)
 416:	f456                	sd	s5,40(sp)
 418:	f05a                	sd	s6,32(sp)
 41a:	ec5e                	sd	s7,24(sp)
 41c:	1080                	addi	s0,sp,96
 41e:	8baa                	mv	s7,a0
 420:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 422:	892a                	mv	s2,a0
 424:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 426:	4aa9                	li	s5,10
 428:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 42a:	89a6                	mv	s3,s1
 42c:	2485                	addiw	s1,s1,1
 42e:	0344d863          	bge	s1,s4,45e <gets+0x56>
    cc = read(0, &c, 1);
 432:	4605                	li	a2,1
 434:	faf40593          	addi	a1,s0,-81
 438:	4501                	li	a0,0
 43a:	00000097          	auipc	ra,0x0
 43e:	1a0080e7          	jalr	416(ra) # 5da <read>
    if(cc < 1)
 442:	00a05e63          	blez	a0,45e <gets+0x56>
    buf[i++] = c;
 446:	faf44783          	lbu	a5,-81(s0)
 44a:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 44e:	01578763          	beq	a5,s5,45c <gets+0x54>
 452:	0905                	addi	s2,s2,1
 454:	fd679be3          	bne	a5,s6,42a <gets+0x22>
  for(i=0; i+1 < max; ){
 458:	89a6                	mv	s3,s1
 45a:	a011                	j	45e <gets+0x56>
 45c:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 45e:	99de                	add	s3,s3,s7
 460:	00098023          	sb	zero,0(s3) # 1000 <__BSS_END__+0x378>
  return buf;
}
 464:	855e                	mv	a0,s7
 466:	60e6                	ld	ra,88(sp)
 468:	6446                	ld	s0,80(sp)
 46a:	64a6                	ld	s1,72(sp)
 46c:	6906                	ld	s2,64(sp)
 46e:	79e2                	ld	s3,56(sp)
 470:	7a42                	ld	s4,48(sp)
 472:	7aa2                	ld	s5,40(sp)
 474:	7b02                	ld	s6,32(sp)
 476:	6be2                	ld	s7,24(sp)
 478:	6125                	addi	sp,sp,96
 47a:	8082                	ret

000000000000047c <stat>:

int
stat(const char *n, struct stat *st)
{
 47c:	1101                	addi	sp,sp,-32
 47e:	ec06                	sd	ra,24(sp)
 480:	e822                	sd	s0,16(sp)
 482:	e426                	sd	s1,8(sp)
 484:	e04a                	sd	s2,0(sp)
 486:	1000                	addi	s0,sp,32
 488:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 48a:	4581                	li	a1,0
 48c:	00000097          	auipc	ra,0x0
 490:	176080e7          	jalr	374(ra) # 602 <open>
  if(fd < 0)
 494:	02054563          	bltz	a0,4be <stat+0x42>
 498:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 49a:	85ca                	mv	a1,s2
 49c:	00000097          	auipc	ra,0x0
 4a0:	17e080e7          	jalr	382(ra) # 61a <fstat>
 4a4:	892a                	mv	s2,a0
  close(fd);
 4a6:	8526                	mv	a0,s1
 4a8:	00000097          	auipc	ra,0x0
 4ac:	142080e7          	jalr	322(ra) # 5ea <close>
  return r;
}
 4b0:	854a                	mv	a0,s2
 4b2:	60e2                	ld	ra,24(sp)
 4b4:	6442                	ld	s0,16(sp)
 4b6:	64a2                	ld	s1,8(sp)
 4b8:	6902                	ld	s2,0(sp)
 4ba:	6105                	addi	sp,sp,32
 4bc:	8082                	ret
    return -1;
 4be:	597d                	li	s2,-1
 4c0:	bfc5                	j	4b0 <stat+0x34>

00000000000004c2 <atoi>:

int
atoi(const char *s)
{
 4c2:	1141                	addi	sp,sp,-16
 4c4:	e422                	sd	s0,8(sp)
 4c6:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 4c8:	00054603          	lbu	a2,0(a0)
 4cc:	fd06079b          	addiw	a5,a2,-48
 4d0:	0ff7f793          	andi	a5,a5,255
 4d4:	4725                	li	a4,9
 4d6:	02f76963          	bltu	a4,a5,508 <atoi+0x46>
 4da:	86aa                	mv	a3,a0
  n = 0;
 4dc:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 4de:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 4e0:	0685                	addi	a3,a3,1
 4e2:	0025179b          	slliw	a5,a0,0x2
 4e6:	9fa9                	addw	a5,a5,a0
 4e8:	0017979b          	slliw	a5,a5,0x1
 4ec:	9fb1                	addw	a5,a5,a2
 4ee:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 4f2:	0006c603          	lbu	a2,0(a3)
 4f6:	fd06071b          	addiw	a4,a2,-48
 4fa:	0ff77713          	andi	a4,a4,255
 4fe:	fee5f1e3          	bgeu	a1,a4,4e0 <atoi+0x1e>
  return n;
}
 502:	6422                	ld	s0,8(sp)
 504:	0141                	addi	sp,sp,16
 506:	8082                	ret
  n = 0;
 508:	4501                	li	a0,0
 50a:	bfe5                	j	502 <atoi+0x40>

000000000000050c <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 50c:	1141                	addi	sp,sp,-16
 50e:	e422                	sd	s0,8(sp)
 510:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 512:	02b57663          	bgeu	a0,a1,53e <memmove+0x32>
    while(n-- > 0)
 516:	02c05163          	blez	a2,538 <memmove+0x2c>
 51a:	fff6079b          	addiw	a5,a2,-1
 51e:	1782                	slli	a5,a5,0x20
 520:	9381                	srli	a5,a5,0x20
 522:	0785                	addi	a5,a5,1
 524:	97aa                	add	a5,a5,a0
  dst = vdst;
 526:	872a                	mv	a4,a0
      *dst++ = *src++;
 528:	0585                	addi	a1,a1,1
 52a:	0705                	addi	a4,a4,1
 52c:	fff5c683          	lbu	a3,-1(a1)
 530:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 534:	fee79ae3          	bne	a5,a4,528 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 538:	6422                	ld	s0,8(sp)
 53a:	0141                	addi	sp,sp,16
 53c:	8082                	ret
    dst += n;
 53e:	00c50733          	add	a4,a0,a2
    src += n;
 542:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 544:	fec05ae3          	blez	a2,538 <memmove+0x2c>
 548:	fff6079b          	addiw	a5,a2,-1
 54c:	1782                	slli	a5,a5,0x20
 54e:	9381                	srli	a5,a5,0x20
 550:	fff7c793          	not	a5,a5
 554:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 556:	15fd                	addi	a1,a1,-1
 558:	177d                	addi	a4,a4,-1
 55a:	0005c683          	lbu	a3,0(a1)
 55e:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 562:	fee79ae3          	bne	a5,a4,556 <memmove+0x4a>
 566:	bfc9                	j	538 <memmove+0x2c>

0000000000000568 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 568:	1141                	addi	sp,sp,-16
 56a:	e422                	sd	s0,8(sp)
 56c:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 56e:	ca05                	beqz	a2,59e <memcmp+0x36>
 570:	fff6069b          	addiw	a3,a2,-1
 574:	1682                	slli	a3,a3,0x20
 576:	9281                	srli	a3,a3,0x20
 578:	0685                	addi	a3,a3,1
 57a:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 57c:	00054783          	lbu	a5,0(a0)
 580:	0005c703          	lbu	a4,0(a1)
 584:	00e79863          	bne	a5,a4,594 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 588:	0505                	addi	a0,a0,1
    p2++;
 58a:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 58c:	fed518e3          	bne	a0,a3,57c <memcmp+0x14>
  }
  return 0;
 590:	4501                	li	a0,0
 592:	a019                	j	598 <memcmp+0x30>
      return *p1 - *p2;
 594:	40e7853b          	subw	a0,a5,a4
}
 598:	6422                	ld	s0,8(sp)
 59a:	0141                	addi	sp,sp,16
 59c:	8082                	ret
  return 0;
 59e:	4501                	li	a0,0
 5a0:	bfe5                	j	598 <memcmp+0x30>

00000000000005a2 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 5a2:	1141                	addi	sp,sp,-16
 5a4:	e406                	sd	ra,8(sp)
 5a6:	e022                	sd	s0,0(sp)
 5a8:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 5aa:	00000097          	auipc	ra,0x0
 5ae:	f62080e7          	jalr	-158(ra) # 50c <memmove>
}
 5b2:	60a2                	ld	ra,8(sp)
 5b4:	6402                	ld	s0,0(sp)
 5b6:	0141                	addi	sp,sp,16
 5b8:	8082                	ret

00000000000005ba <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 5ba:	4885                	li	a7,1
 ecall
 5bc:	00000073          	ecall
 ret
 5c0:	8082                	ret

00000000000005c2 <exit>:
.global exit
exit:
 li a7, SYS_exit
 5c2:	4889                	li	a7,2
 ecall
 5c4:	00000073          	ecall
 ret
 5c8:	8082                	ret

00000000000005ca <wait>:
.global wait
wait:
 li a7, SYS_wait
 5ca:	488d                	li	a7,3
 ecall
 5cc:	00000073          	ecall
 ret
 5d0:	8082                	ret

00000000000005d2 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 5d2:	4891                	li	a7,4
 ecall
 5d4:	00000073          	ecall
 ret
 5d8:	8082                	ret

00000000000005da <read>:
.global read
read:
 li a7, SYS_read
 5da:	4895                	li	a7,5
 ecall
 5dc:	00000073          	ecall
 ret
 5e0:	8082                	ret

00000000000005e2 <write>:
.global write
write:
 li a7, SYS_write
 5e2:	48c1                	li	a7,16
 ecall
 5e4:	00000073          	ecall
 ret
 5e8:	8082                	ret

00000000000005ea <close>:
.global close
close:
 li a7, SYS_close
 5ea:	48d5                	li	a7,21
 ecall
 5ec:	00000073          	ecall
 ret
 5f0:	8082                	ret

00000000000005f2 <kill>:
.global kill
kill:
 li a7, SYS_kill
 5f2:	4899                	li	a7,6
 ecall
 5f4:	00000073          	ecall
 ret
 5f8:	8082                	ret

00000000000005fa <exec>:
.global exec
exec:
 li a7, SYS_exec
 5fa:	489d                	li	a7,7
 ecall
 5fc:	00000073          	ecall
 ret
 600:	8082                	ret

0000000000000602 <open>:
.global open
open:
 li a7, SYS_open
 602:	48bd                	li	a7,15
 ecall
 604:	00000073          	ecall
 ret
 608:	8082                	ret

000000000000060a <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 60a:	48c5                	li	a7,17
 ecall
 60c:	00000073          	ecall
 ret
 610:	8082                	ret

0000000000000612 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 612:	48c9                	li	a7,18
 ecall
 614:	00000073          	ecall
 ret
 618:	8082                	ret

000000000000061a <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 61a:	48a1                	li	a7,8
 ecall
 61c:	00000073          	ecall
 ret
 620:	8082                	ret

0000000000000622 <link>:
.global link
link:
 li a7, SYS_link
 622:	48cd                	li	a7,19
 ecall
 624:	00000073          	ecall
 ret
 628:	8082                	ret

000000000000062a <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 62a:	48d1                	li	a7,20
 ecall
 62c:	00000073          	ecall
 ret
 630:	8082                	ret

0000000000000632 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 632:	48a5                	li	a7,9
 ecall
 634:	00000073          	ecall
 ret
 638:	8082                	ret

000000000000063a <dup>:
.global dup
dup:
 li a7, SYS_dup
 63a:	48a9                	li	a7,10
 ecall
 63c:	00000073          	ecall
 ret
 640:	8082                	ret

0000000000000642 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 642:	48ad                	li	a7,11
 ecall
 644:	00000073          	ecall
 ret
 648:	8082                	ret

000000000000064a <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 64a:	48b1                	li	a7,12
 ecall
 64c:	00000073          	ecall
 ret
 650:	8082                	ret

0000000000000652 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 652:	48b5                	li	a7,13
 ecall
 654:	00000073          	ecall
 ret
 658:	8082                	ret

000000000000065a <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 65a:	48b9                	li	a7,14
 ecall
 65c:	00000073          	ecall
 ret
 660:	8082                	ret

0000000000000662 <trace>:
.global trace
trace:
 li a7, SYS_trace
 662:	48d9                	li	a7,22
 ecall
 664:	00000073          	ecall
 ret
 668:	8082                	ret

000000000000066a <sysinfo>:
.global sysinfo
sysinfo:
 li a7, SYS_sysinfo
 66a:	48dd                	li	a7,23
 ecall
 66c:	00000073          	ecall
 ret
 670:	8082                	ret

0000000000000672 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 672:	1101                	addi	sp,sp,-32
 674:	ec06                	sd	ra,24(sp)
 676:	e822                	sd	s0,16(sp)
 678:	1000                	addi	s0,sp,32
 67a:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 67e:	4605                	li	a2,1
 680:	fef40593          	addi	a1,s0,-17
 684:	00000097          	auipc	ra,0x0
 688:	f5e080e7          	jalr	-162(ra) # 5e2 <write>
}
 68c:	60e2                	ld	ra,24(sp)
 68e:	6442                	ld	s0,16(sp)
 690:	6105                	addi	sp,sp,32
 692:	8082                	ret

0000000000000694 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 694:	7139                	addi	sp,sp,-64
 696:	fc06                	sd	ra,56(sp)
 698:	f822                	sd	s0,48(sp)
 69a:	f426                	sd	s1,40(sp)
 69c:	f04a                	sd	s2,32(sp)
 69e:	ec4e                	sd	s3,24(sp)
 6a0:	0080                	addi	s0,sp,64
 6a2:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 6a4:	c299                	beqz	a3,6aa <printint+0x16>
 6a6:	0805c863          	bltz	a1,736 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 6aa:	2581                	sext.w	a1,a1
  neg = 0;
 6ac:	4881                	li	a7,0
 6ae:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 6b2:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 6b4:	2601                	sext.w	a2,a2
 6b6:	00000517          	auipc	a0,0x0
 6ba:	59a50513          	addi	a0,a0,1434 # c50 <digits>
 6be:	883a                	mv	a6,a4
 6c0:	2705                	addiw	a4,a4,1
 6c2:	02c5f7bb          	remuw	a5,a1,a2
 6c6:	1782                	slli	a5,a5,0x20
 6c8:	9381                	srli	a5,a5,0x20
 6ca:	97aa                	add	a5,a5,a0
 6cc:	0007c783          	lbu	a5,0(a5)
 6d0:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 6d4:	0005879b          	sext.w	a5,a1
 6d8:	02c5d5bb          	divuw	a1,a1,a2
 6dc:	0685                	addi	a3,a3,1
 6de:	fec7f0e3          	bgeu	a5,a2,6be <printint+0x2a>
  if(neg)
 6e2:	00088b63          	beqz	a7,6f8 <printint+0x64>
    buf[i++] = '-';
 6e6:	fd040793          	addi	a5,s0,-48
 6ea:	973e                	add	a4,a4,a5
 6ec:	02d00793          	li	a5,45
 6f0:	fef70823          	sb	a5,-16(a4)
 6f4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 6f8:	02e05863          	blez	a4,728 <printint+0x94>
 6fc:	fc040793          	addi	a5,s0,-64
 700:	00e78933          	add	s2,a5,a4
 704:	fff78993          	addi	s3,a5,-1
 708:	99ba                	add	s3,s3,a4
 70a:	377d                	addiw	a4,a4,-1
 70c:	1702                	slli	a4,a4,0x20
 70e:	9301                	srli	a4,a4,0x20
 710:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 714:	fff94583          	lbu	a1,-1(s2)
 718:	8526                	mv	a0,s1
 71a:	00000097          	auipc	ra,0x0
 71e:	f58080e7          	jalr	-168(ra) # 672 <putc>
  while(--i >= 0)
 722:	197d                	addi	s2,s2,-1
 724:	ff3918e3          	bne	s2,s3,714 <printint+0x80>
}
 728:	70e2                	ld	ra,56(sp)
 72a:	7442                	ld	s0,48(sp)
 72c:	74a2                	ld	s1,40(sp)
 72e:	7902                	ld	s2,32(sp)
 730:	69e2                	ld	s3,24(sp)
 732:	6121                	addi	sp,sp,64
 734:	8082                	ret
    x = -xx;
 736:	40b005bb          	negw	a1,a1
    neg = 1;
 73a:	4885                	li	a7,1
    x = -xx;
 73c:	bf8d                	j	6ae <printint+0x1a>

000000000000073e <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 73e:	7119                	addi	sp,sp,-128
 740:	fc86                	sd	ra,120(sp)
 742:	f8a2                	sd	s0,112(sp)
 744:	f4a6                	sd	s1,104(sp)
 746:	f0ca                	sd	s2,96(sp)
 748:	ecce                	sd	s3,88(sp)
 74a:	e8d2                	sd	s4,80(sp)
 74c:	e4d6                	sd	s5,72(sp)
 74e:	e0da                	sd	s6,64(sp)
 750:	fc5e                	sd	s7,56(sp)
 752:	f862                	sd	s8,48(sp)
 754:	f466                	sd	s9,40(sp)
 756:	f06a                	sd	s10,32(sp)
 758:	ec6e                	sd	s11,24(sp)
 75a:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 75c:	0005c903          	lbu	s2,0(a1)
 760:	18090f63          	beqz	s2,8fe <vprintf+0x1c0>
 764:	8aaa                	mv	s5,a0
 766:	8b32                	mv	s6,a2
 768:	00158493          	addi	s1,a1,1
  state = 0;
 76c:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 76e:	02500a13          	li	s4,37
      if(c == 'd'){
 772:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 776:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 77a:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 77e:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 782:	00000b97          	auipc	s7,0x0
 786:	4ceb8b93          	addi	s7,s7,1230 # c50 <digits>
 78a:	a839                	j	7a8 <vprintf+0x6a>
        putc(fd, c);
 78c:	85ca                	mv	a1,s2
 78e:	8556                	mv	a0,s5
 790:	00000097          	auipc	ra,0x0
 794:	ee2080e7          	jalr	-286(ra) # 672 <putc>
 798:	a019                	j	79e <vprintf+0x60>
    } else if(state == '%'){
 79a:	01498f63          	beq	s3,s4,7b8 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 79e:	0485                	addi	s1,s1,1
 7a0:	fff4c903          	lbu	s2,-1(s1)
 7a4:	14090d63          	beqz	s2,8fe <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 7a8:	0009079b          	sext.w	a5,s2
    if(state == 0){
 7ac:	fe0997e3          	bnez	s3,79a <vprintf+0x5c>
      if(c == '%'){
 7b0:	fd479ee3          	bne	a5,s4,78c <vprintf+0x4e>
        state = '%';
 7b4:	89be                	mv	s3,a5
 7b6:	b7e5                	j	79e <vprintf+0x60>
      if(c == 'd'){
 7b8:	05878063          	beq	a5,s8,7f8 <vprintf+0xba>
      } else if(c == 'l') {
 7bc:	05978c63          	beq	a5,s9,814 <vprintf+0xd6>
      } else if(c == 'x') {
 7c0:	07a78863          	beq	a5,s10,830 <vprintf+0xf2>
      } else if(c == 'p') {
 7c4:	09b78463          	beq	a5,s11,84c <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 7c8:	07300713          	li	a4,115
 7cc:	0ce78663          	beq	a5,a4,898 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 7d0:	06300713          	li	a4,99
 7d4:	0ee78e63          	beq	a5,a4,8d0 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 7d8:	11478863          	beq	a5,s4,8e8 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 7dc:	85d2                	mv	a1,s4
 7de:	8556                	mv	a0,s5
 7e0:	00000097          	auipc	ra,0x0
 7e4:	e92080e7          	jalr	-366(ra) # 672 <putc>
        putc(fd, c);
 7e8:	85ca                	mv	a1,s2
 7ea:	8556                	mv	a0,s5
 7ec:	00000097          	auipc	ra,0x0
 7f0:	e86080e7          	jalr	-378(ra) # 672 <putc>
      }
      state = 0;
 7f4:	4981                	li	s3,0
 7f6:	b765                	j	79e <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 7f8:	008b0913          	addi	s2,s6,8
 7fc:	4685                	li	a3,1
 7fe:	4629                	li	a2,10
 800:	000b2583          	lw	a1,0(s6)
 804:	8556                	mv	a0,s5
 806:	00000097          	auipc	ra,0x0
 80a:	e8e080e7          	jalr	-370(ra) # 694 <printint>
 80e:	8b4a                	mv	s6,s2
      state = 0;
 810:	4981                	li	s3,0
 812:	b771                	j	79e <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 814:	008b0913          	addi	s2,s6,8
 818:	4681                	li	a3,0
 81a:	4629                	li	a2,10
 81c:	000b2583          	lw	a1,0(s6)
 820:	8556                	mv	a0,s5
 822:	00000097          	auipc	ra,0x0
 826:	e72080e7          	jalr	-398(ra) # 694 <printint>
 82a:	8b4a                	mv	s6,s2
      state = 0;
 82c:	4981                	li	s3,0
 82e:	bf85                	j	79e <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 830:	008b0913          	addi	s2,s6,8
 834:	4681                	li	a3,0
 836:	4641                	li	a2,16
 838:	000b2583          	lw	a1,0(s6)
 83c:	8556                	mv	a0,s5
 83e:	00000097          	auipc	ra,0x0
 842:	e56080e7          	jalr	-426(ra) # 694 <printint>
 846:	8b4a                	mv	s6,s2
      state = 0;
 848:	4981                	li	s3,0
 84a:	bf91                	j	79e <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 84c:	008b0793          	addi	a5,s6,8
 850:	f8f43423          	sd	a5,-120(s0)
 854:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 858:	03000593          	li	a1,48
 85c:	8556                	mv	a0,s5
 85e:	00000097          	auipc	ra,0x0
 862:	e14080e7          	jalr	-492(ra) # 672 <putc>
  putc(fd, 'x');
 866:	85ea                	mv	a1,s10
 868:	8556                	mv	a0,s5
 86a:	00000097          	auipc	ra,0x0
 86e:	e08080e7          	jalr	-504(ra) # 672 <putc>
 872:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 874:	03c9d793          	srli	a5,s3,0x3c
 878:	97de                	add	a5,a5,s7
 87a:	0007c583          	lbu	a1,0(a5)
 87e:	8556                	mv	a0,s5
 880:	00000097          	auipc	ra,0x0
 884:	df2080e7          	jalr	-526(ra) # 672 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 888:	0992                	slli	s3,s3,0x4
 88a:	397d                	addiw	s2,s2,-1
 88c:	fe0914e3          	bnez	s2,874 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 890:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 894:	4981                	li	s3,0
 896:	b721                	j	79e <vprintf+0x60>
        s = va_arg(ap, char*);
 898:	008b0993          	addi	s3,s6,8
 89c:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 8a0:	02090163          	beqz	s2,8c2 <vprintf+0x184>
        while(*s != 0){
 8a4:	00094583          	lbu	a1,0(s2)
 8a8:	c9a1                	beqz	a1,8f8 <vprintf+0x1ba>
          putc(fd, *s);
 8aa:	8556                	mv	a0,s5
 8ac:	00000097          	auipc	ra,0x0
 8b0:	dc6080e7          	jalr	-570(ra) # 672 <putc>
          s++;
 8b4:	0905                	addi	s2,s2,1
        while(*s != 0){
 8b6:	00094583          	lbu	a1,0(s2)
 8ba:	f9e5                	bnez	a1,8aa <vprintf+0x16c>
        s = va_arg(ap, char*);
 8bc:	8b4e                	mv	s6,s3
      state = 0;
 8be:	4981                	li	s3,0
 8c0:	bdf9                	j	79e <vprintf+0x60>
          s = "(null)";
 8c2:	00000917          	auipc	s2,0x0
 8c6:	38690913          	addi	s2,s2,902 # c48 <malloc+0x240>
        while(*s != 0){
 8ca:	02800593          	li	a1,40
 8ce:	bff1                	j	8aa <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 8d0:	008b0913          	addi	s2,s6,8
 8d4:	000b4583          	lbu	a1,0(s6)
 8d8:	8556                	mv	a0,s5
 8da:	00000097          	auipc	ra,0x0
 8de:	d98080e7          	jalr	-616(ra) # 672 <putc>
 8e2:	8b4a                	mv	s6,s2
      state = 0;
 8e4:	4981                	li	s3,0
 8e6:	bd65                	j	79e <vprintf+0x60>
        putc(fd, c);
 8e8:	85d2                	mv	a1,s4
 8ea:	8556                	mv	a0,s5
 8ec:	00000097          	auipc	ra,0x0
 8f0:	d86080e7          	jalr	-634(ra) # 672 <putc>
      state = 0;
 8f4:	4981                	li	s3,0
 8f6:	b565                	j	79e <vprintf+0x60>
        s = va_arg(ap, char*);
 8f8:	8b4e                	mv	s6,s3
      state = 0;
 8fa:	4981                	li	s3,0
 8fc:	b54d                	j	79e <vprintf+0x60>
    }
  }
}
 8fe:	70e6                	ld	ra,120(sp)
 900:	7446                	ld	s0,112(sp)
 902:	74a6                	ld	s1,104(sp)
 904:	7906                	ld	s2,96(sp)
 906:	69e6                	ld	s3,88(sp)
 908:	6a46                	ld	s4,80(sp)
 90a:	6aa6                	ld	s5,72(sp)
 90c:	6b06                	ld	s6,64(sp)
 90e:	7be2                	ld	s7,56(sp)
 910:	7c42                	ld	s8,48(sp)
 912:	7ca2                	ld	s9,40(sp)
 914:	7d02                	ld	s10,32(sp)
 916:	6de2                	ld	s11,24(sp)
 918:	6109                	addi	sp,sp,128
 91a:	8082                	ret

000000000000091c <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 91c:	715d                	addi	sp,sp,-80
 91e:	ec06                	sd	ra,24(sp)
 920:	e822                	sd	s0,16(sp)
 922:	1000                	addi	s0,sp,32
 924:	e010                	sd	a2,0(s0)
 926:	e414                	sd	a3,8(s0)
 928:	e818                	sd	a4,16(s0)
 92a:	ec1c                	sd	a5,24(s0)
 92c:	03043023          	sd	a6,32(s0)
 930:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 934:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 938:	8622                	mv	a2,s0
 93a:	00000097          	auipc	ra,0x0
 93e:	e04080e7          	jalr	-508(ra) # 73e <vprintf>
}
 942:	60e2                	ld	ra,24(sp)
 944:	6442                	ld	s0,16(sp)
 946:	6161                	addi	sp,sp,80
 948:	8082                	ret

000000000000094a <printf>:

void
printf(const char *fmt, ...)
{
 94a:	711d                	addi	sp,sp,-96
 94c:	ec06                	sd	ra,24(sp)
 94e:	e822                	sd	s0,16(sp)
 950:	1000                	addi	s0,sp,32
 952:	e40c                	sd	a1,8(s0)
 954:	e810                	sd	a2,16(s0)
 956:	ec14                	sd	a3,24(s0)
 958:	f018                	sd	a4,32(s0)
 95a:	f41c                	sd	a5,40(s0)
 95c:	03043823          	sd	a6,48(s0)
 960:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 964:	00840613          	addi	a2,s0,8
 968:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 96c:	85aa                	mv	a1,a0
 96e:	4505                	li	a0,1
 970:	00000097          	auipc	ra,0x0
 974:	dce080e7          	jalr	-562(ra) # 73e <vprintf>
}
 978:	60e2                	ld	ra,24(sp)
 97a:	6442                	ld	s0,16(sp)
 97c:	6125                	addi	sp,sp,96
 97e:	8082                	ret

0000000000000980 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 980:	1141                	addi	sp,sp,-16
 982:	e422                	sd	s0,8(sp)
 984:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 986:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 98a:	00000797          	auipc	a5,0x0
 98e:	2e67b783          	ld	a5,742(a5) # c70 <freep>
 992:	a805                	j	9c2 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 994:	4618                	lw	a4,8(a2)
 996:	9db9                	addw	a1,a1,a4
 998:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 99c:	6398                	ld	a4,0(a5)
 99e:	6318                	ld	a4,0(a4)
 9a0:	fee53823          	sd	a4,-16(a0)
 9a4:	a091                	j	9e8 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 9a6:	ff852703          	lw	a4,-8(a0)
 9aa:	9e39                	addw	a2,a2,a4
 9ac:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 9ae:	ff053703          	ld	a4,-16(a0)
 9b2:	e398                	sd	a4,0(a5)
 9b4:	a099                	j	9fa <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 9b6:	6398                	ld	a4,0(a5)
 9b8:	00e7e463          	bltu	a5,a4,9c0 <free+0x40>
 9bc:	00e6ea63          	bltu	a3,a4,9d0 <free+0x50>
{
 9c0:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 9c2:	fed7fae3          	bgeu	a5,a3,9b6 <free+0x36>
 9c6:	6398                	ld	a4,0(a5)
 9c8:	00e6e463          	bltu	a3,a4,9d0 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 9cc:	fee7eae3          	bltu	a5,a4,9c0 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 9d0:	ff852583          	lw	a1,-8(a0)
 9d4:	6390                	ld	a2,0(a5)
 9d6:	02059713          	slli	a4,a1,0x20
 9da:	9301                	srli	a4,a4,0x20
 9dc:	0712                	slli	a4,a4,0x4
 9de:	9736                	add	a4,a4,a3
 9e0:	fae60ae3          	beq	a2,a4,994 <free+0x14>
    bp->s.ptr = p->s.ptr;
 9e4:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 9e8:	4790                	lw	a2,8(a5)
 9ea:	02061713          	slli	a4,a2,0x20
 9ee:	9301                	srli	a4,a4,0x20
 9f0:	0712                	slli	a4,a4,0x4
 9f2:	973e                	add	a4,a4,a5
 9f4:	fae689e3          	beq	a3,a4,9a6 <free+0x26>
  } else
    p->s.ptr = bp;
 9f8:	e394                	sd	a3,0(a5)
  freep = p;
 9fa:	00000717          	auipc	a4,0x0
 9fe:	26f73b23          	sd	a5,630(a4) # c70 <freep>
}
 a02:	6422                	ld	s0,8(sp)
 a04:	0141                	addi	sp,sp,16
 a06:	8082                	ret

0000000000000a08 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 a08:	7139                	addi	sp,sp,-64
 a0a:	fc06                	sd	ra,56(sp)
 a0c:	f822                	sd	s0,48(sp)
 a0e:	f426                	sd	s1,40(sp)
 a10:	f04a                	sd	s2,32(sp)
 a12:	ec4e                	sd	s3,24(sp)
 a14:	e852                	sd	s4,16(sp)
 a16:	e456                	sd	s5,8(sp)
 a18:	e05a                	sd	s6,0(sp)
 a1a:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 a1c:	02051493          	slli	s1,a0,0x20
 a20:	9081                	srli	s1,s1,0x20
 a22:	04bd                	addi	s1,s1,15
 a24:	8091                	srli	s1,s1,0x4
 a26:	0014899b          	addiw	s3,s1,1
 a2a:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 a2c:	00000517          	auipc	a0,0x0
 a30:	24453503          	ld	a0,580(a0) # c70 <freep>
 a34:	c515                	beqz	a0,a60 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a36:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a38:	4798                	lw	a4,8(a5)
 a3a:	02977f63          	bgeu	a4,s1,a78 <malloc+0x70>
 a3e:	8a4e                	mv	s4,s3
 a40:	0009871b          	sext.w	a4,s3
 a44:	6685                	lui	a3,0x1
 a46:	00d77363          	bgeu	a4,a3,a4c <malloc+0x44>
 a4a:	6a05                	lui	s4,0x1
 a4c:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 a50:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 a54:	00000917          	auipc	s2,0x0
 a58:	21c90913          	addi	s2,s2,540 # c70 <freep>
  if(p == (char*)-1)
 a5c:	5afd                	li	s5,-1
 a5e:	a88d                	j	ad0 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 a60:	00000797          	auipc	a5,0x0
 a64:	21878793          	addi	a5,a5,536 # c78 <base>
 a68:	00000717          	auipc	a4,0x0
 a6c:	20f73423          	sd	a5,520(a4) # c70 <freep>
 a70:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 a72:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 a76:	b7e1                	j	a3e <malloc+0x36>
      if(p->s.size == nunits)
 a78:	02e48b63          	beq	s1,a4,aae <malloc+0xa6>
        p->s.size -= nunits;
 a7c:	4137073b          	subw	a4,a4,s3
 a80:	c798                	sw	a4,8(a5)
        p += p->s.size;
 a82:	1702                	slli	a4,a4,0x20
 a84:	9301                	srli	a4,a4,0x20
 a86:	0712                	slli	a4,a4,0x4
 a88:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 a8a:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 a8e:	00000717          	auipc	a4,0x0
 a92:	1ea73123          	sd	a0,482(a4) # c70 <freep>
      return (void*)(p + 1);
 a96:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 a9a:	70e2                	ld	ra,56(sp)
 a9c:	7442                	ld	s0,48(sp)
 a9e:	74a2                	ld	s1,40(sp)
 aa0:	7902                	ld	s2,32(sp)
 aa2:	69e2                	ld	s3,24(sp)
 aa4:	6a42                	ld	s4,16(sp)
 aa6:	6aa2                	ld	s5,8(sp)
 aa8:	6b02                	ld	s6,0(sp)
 aaa:	6121                	addi	sp,sp,64
 aac:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 aae:	6398                	ld	a4,0(a5)
 ab0:	e118                	sd	a4,0(a0)
 ab2:	bff1                	j	a8e <malloc+0x86>
  hp->s.size = nu;
 ab4:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 ab8:	0541                	addi	a0,a0,16
 aba:	00000097          	auipc	ra,0x0
 abe:	ec6080e7          	jalr	-314(ra) # 980 <free>
  return freep;
 ac2:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 ac6:	d971                	beqz	a0,a9a <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 ac8:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 aca:	4798                	lw	a4,8(a5)
 acc:	fa9776e3          	bgeu	a4,s1,a78 <malloc+0x70>
    if(p == freep)
 ad0:	00093703          	ld	a4,0(s2)
 ad4:	853e                	mv	a0,a5
 ad6:	fef719e3          	bne	a4,a5,ac8 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 ada:	8552                	mv	a0,s4
 adc:	00000097          	auipc	ra,0x0
 ae0:	b6e080e7          	jalr	-1170(ra) # 64a <sbrk>
  if(p == (char*)-1)
 ae4:	fd5518e3          	bne	a0,s5,ab4 <malloc+0xac>
        return 0;
 ae8:	4501                	li	a0,0
 aea:	bf45                	j	a9a <malloc+0x92>
