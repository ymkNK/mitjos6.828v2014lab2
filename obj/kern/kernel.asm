
obj/kern/kernel：     文件格式 elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 1c             	sub    $0x1c,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 79 11 f0       	mov    $0xf0117970,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 73 11 f0       	push   $0xf0117300
f0100058:	e8 f5 32 00 00       	call   f0103352 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 c4 04 00 00       	call   f0100526 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 00 38 10 f0       	push   $0xf0103800
f010006f:	e8 2e 27 00 00       	call   f01027a2 <cprintf>
    {
        int x = 1, y = 3, z = 4;
    Lab1_exercise8_3:
        cprintf("x %d, y %x, z %d\n", x, y, z);
f0100074:	6a 04                	push   $0x4
f0100076:	6a 03                	push   $0x3
f0100078:	6a 01                	push   $0x1
f010007a:	68 1b 38 10 f0       	push   $0xf010381b
f010007f:	e8 1e 27 00 00       	call   f01027a2 <cprintf>
    Lab1_exercise8_5:
        cprintf("x=%d y=%d", 3);
f0100084:	83 c4 18             	add    $0x18,%esp
f0100087:	6a 03                	push   $0x3
f0100089:	68 2d 38 10 f0       	push   $0xf010382d
f010008e:	e8 0f 27 00 00       	call   f01027a2 <cprintf>
    }
    {
        unsigned int i = 0x000a646c;
f0100093:	c7 45 f4 6c 64 0a 00 	movl   $0xa646c,-0xc(%ebp)
    Lab1_exercise8_4:
        cprintf("H%x Wor%s", 57616, &i);
f010009a:	83 c4 0c             	add    $0xc,%esp
f010009d:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01000a0:	50                   	push   %eax
f01000a1:	68 10 e1 00 00       	push   $0xe110
f01000a6:	68 37 38 10 f0       	push   $0xf0103837
f01000ab:	e8 f2 26 00 00       	call   f01027a2 <cprintf>
    }

	// Lab 2 memory management initialization functions
	mem_init();
f01000b0:	e8 e6 0f 00 00       	call   f010109b <mem_init>
f01000b5:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000b8:	83 ec 0c             	sub    $0xc,%esp
f01000bb:	6a 00                	push   $0x0
f01000bd:	e8 05 07 00 00       	call   f01007c7 <monitor>
f01000c2:	83 c4 10             	add    $0x10,%esp
f01000c5:	eb f1                	jmp    f01000b8 <i386_init+0x78>

f01000c7 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000c7:	55                   	push   %ebp
f01000c8:	89 e5                	mov    %esp,%ebp
f01000ca:	56                   	push   %esi
f01000cb:	53                   	push   %ebx
f01000cc:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000cf:	83 3d 60 79 11 f0 00 	cmpl   $0x0,0xf0117960
f01000d6:	75 37                	jne    f010010f <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000d8:	89 35 60 79 11 f0    	mov    %esi,0xf0117960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000de:	fa                   	cli    
f01000df:	fc                   	cld    

	va_start(ap, fmt);
f01000e0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000e3:	83 ec 04             	sub    $0x4,%esp
f01000e6:	ff 75 0c             	pushl  0xc(%ebp)
f01000e9:	ff 75 08             	pushl  0x8(%ebp)
f01000ec:	68 41 38 10 f0       	push   $0xf0103841
f01000f1:	e8 ac 26 00 00       	call   f01027a2 <cprintf>
	vcprintf(fmt, ap);
f01000f6:	83 c4 08             	add    $0x8,%esp
f01000f9:	53                   	push   %ebx
f01000fa:	56                   	push   %esi
f01000fb:	e8 7c 26 00 00       	call   f010277c <vcprintf>
	cprintf("\n");
f0100100:	c7 04 24 7d 47 10 f0 	movl   $0xf010477d,(%esp)
f0100107:	e8 96 26 00 00       	call   f01027a2 <cprintf>
	va_end(ap);
f010010c:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010010f:	83 ec 0c             	sub    $0xc,%esp
f0100112:	6a 00                	push   $0x0
f0100114:	e8 ae 06 00 00       	call   f01007c7 <monitor>
f0100119:	83 c4 10             	add    $0x10,%esp
f010011c:	eb f1                	jmp    f010010f <_panic+0x48>

f010011e <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010011e:	55                   	push   %ebp
f010011f:	89 e5                	mov    %esp,%ebp
f0100121:	53                   	push   %ebx
f0100122:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100125:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100128:	ff 75 0c             	pushl  0xc(%ebp)
f010012b:	ff 75 08             	pushl  0x8(%ebp)
f010012e:	68 59 38 10 f0       	push   $0xf0103859
f0100133:	e8 6a 26 00 00       	call   f01027a2 <cprintf>
	vcprintf(fmt, ap);
f0100138:	83 c4 08             	add    $0x8,%esp
f010013b:	53                   	push   %ebx
f010013c:	ff 75 10             	pushl  0x10(%ebp)
f010013f:	e8 38 26 00 00       	call   f010277c <vcprintf>
	cprintf("\n");
f0100144:	c7 04 24 7d 47 10 f0 	movl   $0xf010477d,(%esp)
f010014b:	e8 52 26 00 00       	call   f01027a2 <cprintf>
	va_end(ap);
}
f0100150:	83 c4 10             	add    $0x10,%esp
f0100153:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100156:	c9                   	leave  
f0100157:	c3                   	ret    

f0100158 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100158:	55                   	push   %ebp
f0100159:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010015b:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100160:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100161:	a8 01                	test   $0x1,%al
f0100163:	74 0b                	je     f0100170 <serial_proc_data+0x18>
f0100165:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010016a:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010016b:	0f b6 c0             	movzbl %al,%eax
f010016e:	eb 05                	jmp    f0100175 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100170:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100175:	5d                   	pop    %ebp
f0100176:	c3                   	ret    

f0100177 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100177:	55                   	push   %ebp
f0100178:	89 e5                	mov    %esp,%ebp
f010017a:	53                   	push   %ebx
f010017b:	83 ec 04             	sub    $0x4,%esp
f010017e:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100180:	eb 2b                	jmp    f01001ad <cons_intr+0x36>
		if (c == 0)
f0100182:	85 c0                	test   %eax,%eax
f0100184:	74 27                	je     f01001ad <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f0100186:	8b 0d 24 75 11 f0    	mov    0xf0117524,%ecx
f010018c:	8d 51 01             	lea    0x1(%ecx),%edx
f010018f:	89 15 24 75 11 f0    	mov    %edx,0xf0117524
f0100195:	88 81 20 73 11 f0    	mov    %al,-0xfee8ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010019b:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001a1:	75 0a                	jne    f01001ad <cons_intr+0x36>
			cons.wpos = 0;
f01001a3:	c7 05 24 75 11 f0 00 	movl   $0x0,0xf0117524
f01001aa:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001ad:	ff d3                	call   *%ebx
f01001af:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001b2:	75 ce                	jne    f0100182 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001b4:	83 c4 04             	add    $0x4,%esp
f01001b7:	5b                   	pop    %ebx
f01001b8:	5d                   	pop    %ebp
f01001b9:	c3                   	ret    

f01001ba <kbd_proc_data>:
f01001ba:	ba 64 00 00 00       	mov    $0x64,%edx
f01001bf:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001c0:	a8 01                	test   $0x1,%al
f01001c2:	0f 84 f0 00 00 00    	je     f01002b8 <kbd_proc_data+0xfe>
f01001c8:	ba 60 00 00 00       	mov    $0x60,%edx
f01001cd:	ec                   	in     (%dx),%al
f01001ce:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001d0:	3c e0                	cmp    $0xe0,%al
f01001d2:	75 0d                	jne    f01001e1 <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f01001d4:	83 0d 00 73 11 f0 40 	orl    $0x40,0xf0117300
		return 0;
f01001db:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001e0:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001e1:	55                   	push   %ebp
f01001e2:	89 e5                	mov    %esp,%ebp
f01001e4:	53                   	push   %ebx
f01001e5:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001e8:	84 c0                	test   %al,%al
f01001ea:	79 36                	jns    f0100222 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001ec:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001f2:	89 cb                	mov    %ecx,%ebx
f01001f4:	83 e3 40             	and    $0x40,%ebx
f01001f7:	83 e0 7f             	and    $0x7f,%eax
f01001fa:	85 db                	test   %ebx,%ebx
f01001fc:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001ff:	0f b6 d2             	movzbl %dl,%edx
f0100202:	0f b6 82 c0 39 10 f0 	movzbl -0xfefc640(%edx),%eax
f0100209:	83 c8 40             	or     $0x40,%eax
f010020c:	0f b6 c0             	movzbl %al,%eax
f010020f:	f7 d0                	not    %eax
f0100211:	21 c8                	and    %ecx,%eax
f0100213:	a3 00 73 11 f0       	mov    %eax,0xf0117300
		return 0;
f0100218:	b8 00 00 00 00       	mov    $0x0,%eax
f010021d:	e9 9e 00 00 00       	jmp    f01002c0 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f0100222:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f0100228:	f6 c1 40             	test   $0x40,%cl
f010022b:	74 0e                	je     f010023b <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010022d:	83 c8 80             	or     $0xffffff80,%eax
f0100230:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100232:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100235:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
	}

	shift |= shiftcode[data];
f010023b:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010023e:	0f b6 82 c0 39 10 f0 	movzbl -0xfefc640(%edx),%eax
f0100245:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
f010024b:	0f b6 8a c0 38 10 f0 	movzbl -0xfefc740(%edx),%ecx
f0100252:	31 c8                	xor    %ecx,%eax
f0100254:	a3 00 73 11 f0       	mov    %eax,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100259:	89 c1                	mov    %eax,%ecx
f010025b:	83 e1 03             	and    $0x3,%ecx
f010025e:	8b 0c 8d a0 38 10 f0 	mov    -0xfefc760(,%ecx,4),%ecx
f0100265:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100269:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010026c:	a8 08                	test   $0x8,%al
f010026e:	74 1b                	je     f010028b <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f0100270:	89 da                	mov    %ebx,%edx
f0100272:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100275:	83 f9 19             	cmp    $0x19,%ecx
f0100278:	77 05                	ja     f010027f <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f010027a:	83 eb 20             	sub    $0x20,%ebx
f010027d:	eb 0c                	jmp    f010028b <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f010027f:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100282:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100285:	83 fa 19             	cmp    $0x19,%edx
f0100288:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010028b:	f7 d0                	not    %eax
f010028d:	a8 06                	test   $0x6,%al
f010028f:	75 2d                	jne    f01002be <kbd_proc_data+0x104>
f0100291:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100297:	75 25                	jne    f01002be <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f0100299:	83 ec 0c             	sub    $0xc,%esp
f010029c:	68 73 38 10 f0       	push   $0xf0103873
f01002a1:	e8 fc 24 00 00       	call   f01027a2 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002a6:	ba 92 00 00 00       	mov    $0x92,%edx
f01002ab:	b8 03 00 00 00       	mov    $0x3,%eax
f01002b0:	ee                   	out    %al,(%dx)
f01002b1:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002b4:	89 d8                	mov    %ebx,%eax
f01002b6:	eb 08                	jmp    f01002c0 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002b8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002bd:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002be:	89 d8                	mov    %ebx,%eax
}
f01002c0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002c3:	c9                   	leave  
f01002c4:	c3                   	ret    

f01002c5 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002c5:	55                   	push   %ebp
f01002c6:	89 e5                	mov    %esp,%ebp
f01002c8:	57                   	push   %edi
f01002c9:	56                   	push   %esi
f01002ca:	53                   	push   %ebx
f01002cb:	83 ec 1c             	sub    $0x1c,%esp
f01002ce:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002d0:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002d5:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002da:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002df:	eb 09                	jmp    f01002ea <cons_putc+0x25>
f01002e1:	89 ca                	mov    %ecx,%edx
f01002e3:	ec                   	in     (%dx),%al
f01002e4:	ec                   	in     (%dx),%al
f01002e5:	ec                   	in     (%dx),%al
f01002e6:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002e7:	83 c3 01             	add    $0x1,%ebx
f01002ea:	89 f2                	mov    %esi,%edx
f01002ec:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002ed:	a8 20                	test   $0x20,%al
f01002ef:	75 08                	jne    f01002f9 <cons_putc+0x34>
f01002f1:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002f7:	7e e8                	jle    f01002e1 <cons_putc+0x1c>
f01002f9:	89 f8                	mov    %edi,%eax
f01002fb:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002fe:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100303:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100304:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100309:	be 79 03 00 00       	mov    $0x379,%esi
f010030e:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100313:	eb 09                	jmp    f010031e <cons_putc+0x59>
f0100315:	89 ca                	mov    %ecx,%edx
f0100317:	ec                   	in     (%dx),%al
f0100318:	ec                   	in     (%dx),%al
f0100319:	ec                   	in     (%dx),%al
f010031a:	ec                   	in     (%dx),%al
f010031b:	83 c3 01             	add    $0x1,%ebx
f010031e:	89 f2                	mov    %esi,%edx
f0100320:	ec                   	in     (%dx),%al
f0100321:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100327:	7f 04                	jg     f010032d <cons_putc+0x68>
f0100329:	84 c0                	test   %al,%al
f010032b:	79 e8                	jns    f0100315 <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010032d:	ba 78 03 00 00       	mov    $0x378,%edx
f0100332:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100336:	ee                   	out    %al,(%dx)
f0100337:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010033c:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100341:	ee                   	out    %al,(%dx)
f0100342:	b8 08 00 00 00       	mov    $0x8,%eax
f0100347:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100348:	89 fa                	mov    %edi,%edx
f010034a:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100350:	89 f8                	mov    %edi,%eax
f0100352:	80 cc 07             	or     $0x7,%ah
f0100355:	85 d2                	test   %edx,%edx
f0100357:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010035a:	89 f8                	mov    %edi,%eax
f010035c:	0f b6 c0             	movzbl %al,%eax
f010035f:	83 f8 09             	cmp    $0x9,%eax
f0100362:	74 74                	je     f01003d8 <cons_putc+0x113>
f0100364:	83 f8 09             	cmp    $0x9,%eax
f0100367:	7f 0a                	jg     f0100373 <cons_putc+0xae>
f0100369:	83 f8 08             	cmp    $0x8,%eax
f010036c:	74 14                	je     f0100382 <cons_putc+0xbd>
f010036e:	e9 99 00 00 00       	jmp    f010040c <cons_putc+0x147>
f0100373:	83 f8 0a             	cmp    $0xa,%eax
f0100376:	74 3a                	je     f01003b2 <cons_putc+0xed>
f0100378:	83 f8 0d             	cmp    $0xd,%eax
f010037b:	74 3d                	je     f01003ba <cons_putc+0xf5>
f010037d:	e9 8a 00 00 00       	jmp    f010040c <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100382:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f0100389:	66 85 c0             	test   %ax,%ax
f010038c:	0f 84 e6 00 00 00    	je     f0100478 <cons_putc+0x1b3>
			crt_pos--;
f0100392:	83 e8 01             	sub    $0x1,%eax
f0100395:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010039b:	0f b7 c0             	movzwl %ax,%eax
f010039e:	66 81 e7 00 ff       	and    $0xff00,%di
f01003a3:	83 cf 20             	or     $0x20,%edi
f01003a6:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f01003ac:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003b0:	eb 78                	jmp    f010042a <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003b2:	66 83 05 28 75 11 f0 	addw   $0x50,0xf0117528
f01003b9:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003ba:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003c1:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003c7:	c1 e8 16             	shr    $0x16,%eax
f01003ca:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003cd:	c1 e0 04             	shl    $0x4,%eax
f01003d0:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
f01003d6:	eb 52                	jmp    f010042a <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003d8:	b8 20 00 00 00       	mov    $0x20,%eax
f01003dd:	e8 e3 fe ff ff       	call   f01002c5 <cons_putc>
		cons_putc(' ');
f01003e2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e7:	e8 d9 fe ff ff       	call   f01002c5 <cons_putc>
		cons_putc(' ');
f01003ec:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f1:	e8 cf fe ff ff       	call   f01002c5 <cons_putc>
		cons_putc(' ');
f01003f6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003fb:	e8 c5 fe ff ff       	call   f01002c5 <cons_putc>
		cons_putc(' ');
f0100400:	b8 20 00 00 00       	mov    $0x20,%eax
f0100405:	e8 bb fe ff ff       	call   f01002c5 <cons_putc>
f010040a:	eb 1e                	jmp    f010042a <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010040c:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f0100413:	8d 50 01             	lea    0x1(%eax),%edx
f0100416:	66 89 15 28 75 11 f0 	mov    %dx,0xf0117528
f010041d:	0f b7 c0             	movzwl %ax,%eax
f0100420:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100426:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010042a:	66 81 3d 28 75 11 f0 	cmpw   $0x7cf,0xf0117528
f0100431:	cf 07 
f0100433:	76 43                	jbe    f0100478 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100435:	a1 2c 75 11 f0       	mov    0xf011752c,%eax
f010043a:	83 ec 04             	sub    $0x4,%esp
f010043d:	68 00 0f 00 00       	push   $0xf00
f0100442:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100448:	52                   	push   %edx
f0100449:	50                   	push   %eax
f010044a:	e8 50 2f 00 00       	call   f010339f <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010044f:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100455:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010045b:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100461:	83 c4 10             	add    $0x10,%esp
f0100464:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100469:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010046c:	39 d0                	cmp    %edx,%eax
f010046e:	75 f4                	jne    f0100464 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100470:	66 83 2d 28 75 11 f0 	subw   $0x50,0xf0117528
f0100477:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100478:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f010047e:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100483:	89 ca                	mov    %ecx,%edx
f0100485:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100486:	0f b7 1d 28 75 11 f0 	movzwl 0xf0117528,%ebx
f010048d:	8d 71 01             	lea    0x1(%ecx),%esi
f0100490:	89 d8                	mov    %ebx,%eax
f0100492:	66 c1 e8 08          	shr    $0x8,%ax
f0100496:	89 f2                	mov    %esi,%edx
f0100498:	ee                   	out    %al,(%dx)
f0100499:	b8 0f 00 00 00       	mov    $0xf,%eax
f010049e:	89 ca                	mov    %ecx,%edx
f01004a0:	ee                   	out    %al,(%dx)
f01004a1:	89 d8                	mov    %ebx,%eax
f01004a3:	89 f2                	mov    %esi,%edx
f01004a5:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004a6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004a9:	5b                   	pop    %ebx
f01004aa:	5e                   	pop    %esi
f01004ab:	5f                   	pop    %edi
f01004ac:	5d                   	pop    %ebp
f01004ad:	c3                   	ret    

f01004ae <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004ae:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
f01004b5:	74 11                	je     f01004c8 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004b7:	55                   	push   %ebp
f01004b8:	89 e5                	mov    %esp,%ebp
f01004ba:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004bd:	b8 58 01 10 f0       	mov    $0xf0100158,%eax
f01004c2:	e8 b0 fc ff ff       	call   f0100177 <cons_intr>
}
f01004c7:	c9                   	leave  
f01004c8:	f3 c3                	repz ret 

f01004ca <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004ca:	55                   	push   %ebp
f01004cb:	89 e5                	mov    %esp,%ebp
f01004cd:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004d0:	b8 ba 01 10 f0       	mov    $0xf01001ba,%eax
f01004d5:	e8 9d fc ff ff       	call   f0100177 <cons_intr>
}
f01004da:	c9                   	leave  
f01004db:	c3                   	ret    

f01004dc <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004dc:	55                   	push   %ebp
f01004dd:	89 e5                	mov    %esp,%ebp
f01004df:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004e2:	e8 c7 ff ff ff       	call   f01004ae <serial_intr>
	kbd_intr();
f01004e7:	e8 de ff ff ff       	call   f01004ca <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004ec:	a1 20 75 11 f0       	mov    0xf0117520,%eax
f01004f1:	3b 05 24 75 11 f0    	cmp    0xf0117524,%eax
f01004f7:	74 26                	je     f010051f <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004f9:	8d 50 01             	lea    0x1(%eax),%edx
f01004fc:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
f0100502:	0f b6 88 20 73 11 f0 	movzbl -0xfee8ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100509:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f010050b:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100511:	75 11                	jne    f0100524 <cons_getc+0x48>
			cons.rpos = 0;
f0100513:	c7 05 20 75 11 f0 00 	movl   $0x0,0xf0117520
f010051a:	00 00 00 
f010051d:	eb 05                	jmp    f0100524 <cons_getc+0x48>
		return c;
	}
	return 0;
f010051f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100524:	c9                   	leave  
f0100525:	c3                   	ret    

f0100526 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100526:	55                   	push   %ebp
f0100527:	89 e5                	mov    %esp,%ebp
f0100529:	57                   	push   %edi
f010052a:	56                   	push   %esi
f010052b:	53                   	push   %ebx
f010052c:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010052f:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100536:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010053d:	5a a5 
	if (*cp != 0xA55A) {
f010053f:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100546:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010054a:	74 11                	je     f010055d <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010054c:	c7 05 30 75 11 f0 b4 	movl   $0x3b4,0xf0117530
f0100553:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100556:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010055b:	eb 16                	jmp    f0100573 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010055d:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100564:	c7 05 30 75 11 f0 d4 	movl   $0x3d4,0xf0117530
f010056b:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010056e:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100573:	8b 3d 30 75 11 f0    	mov    0xf0117530,%edi
f0100579:	b8 0e 00 00 00       	mov    $0xe,%eax
f010057e:	89 fa                	mov    %edi,%edx
f0100580:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100581:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100584:	89 da                	mov    %ebx,%edx
f0100586:	ec                   	in     (%dx),%al
f0100587:	0f b6 c8             	movzbl %al,%ecx
f010058a:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010058d:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100592:	89 fa                	mov    %edi,%edx
f0100594:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100595:	89 da                	mov    %ebx,%edx
f0100597:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100598:	89 35 2c 75 11 f0    	mov    %esi,0xf011752c
	crt_pos = pos;
f010059e:	0f b6 c0             	movzbl %al,%eax
f01005a1:	09 c8                	or     %ecx,%eax
f01005a3:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005a9:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005ae:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b3:	89 f2                	mov    %esi,%edx
f01005b5:	ee                   	out    %al,(%dx)
f01005b6:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005bb:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005c0:	ee                   	out    %al,(%dx)
f01005c1:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005c6:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005cb:	89 da                	mov    %ebx,%edx
f01005cd:	ee                   	out    %al,(%dx)
f01005ce:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005d3:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d8:	ee                   	out    %al,(%dx)
f01005d9:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005de:	b8 03 00 00 00       	mov    $0x3,%eax
f01005e3:	ee                   	out    %al,(%dx)
f01005e4:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005e9:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ee:	ee                   	out    %al,(%dx)
f01005ef:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005f4:	b8 01 00 00 00       	mov    $0x1,%eax
f01005f9:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005fa:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005ff:	ec                   	in     (%dx),%al
f0100600:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100602:	3c ff                	cmp    $0xff,%al
f0100604:	0f 95 05 34 75 11 f0 	setne  0xf0117534
f010060b:	89 f2                	mov    %esi,%edx
f010060d:	ec                   	in     (%dx),%al
f010060e:	89 da                	mov    %ebx,%edx
f0100610:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100611:	80 f9 ff             	cmp    $0xff,%cl
f0100614:	75 10                	jne    f0100626 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f0100616:	83 ec 0c             	sub    $0xc,%esp
f0100619:	68 7f 38 10 f0       	push   $0xf010387f
f010061e:	e8 7f 21 00 00       	call   f01027a2 <cprintf>
f0100623:	83 c4 10             	add    $0x10,%esp
}
f0100626:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100629:	5b                   	pop    %ebx
f010062a:	5e                   	pop    %esi
f010062b:	5f                   	pop    %edi
f010062c:	5d                   	pop    %ebp
f010062d:	c3                   	ret    

f010062e <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010062e:	55                   	push   %ebp
f010062f:	89 e5                	mov    %esp,%ebp
f0100631:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100634:	8b 45 08             	mov    0x8(%ebp),%eax
f0100637:	e8 89 fc ff ff       	call   f01002c5 <cons_putc>
}
f010063c:	c9                   	leave  
f010063d:	c3                   	ret    

f010063e <getchar>:

int
getchar(void)
{
f010063e:	55                   	push   %ebp
f010063f:	89 e5                	mov    %esp,%ebp
f0100641:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100644:	e8 93 fe ff ff       	call   f01004dc <cons_getc>
f0100649:	85 c0                	test   %eax,%eax
f010064b:	74 f7                	je     f0100644 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010064d:	c9                   	leave  
f010064e:	c3                   	ret    

f010064f <iscons>:

int
iscons(int fdnum)
{
f010064f:	55                   	push   %ebp
f0100650:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100652:	b8 01 00 00 00       	mov    $0x1,%eax
f0100657:	5d                   	pop    %ebp
f0100658:	c3                   	ret    

f0100659 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100659:	55                   	push   %ebp
f010065a:	89 e5                	mov    %esp,%ebp
f010065c:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010065f:	68 c0 3a 10 f0       	push   $0xf0103ac0
f0100664:	68 de 3a 10 f0       	push   $0xf0103ade
f0100669:	68 e3 3a 10 f0       	push   $0xf0103ae3
f010066e:	e8 2f 21 00 00       	call   f01027a2 <cprintf>
f0100673:	83 c4 0c             	add    $0xc,%esp
f0100676:	68 7c 3b 10 f0       	push   $0xf0103b7c
f010067b:	68 ec 3a 10 f0       	push   $0xf0103aec
f0100680:	68 e3 3a 10 f0       	push   $0xf0103ae3
f0100685:	e8 18 21 00 00       	call   f01027a2 <cprintf>
f010068a:	83 c4 0c             	add    $0xc,%esp
f010068d:	68 f5 3a 10 f0       	push   $0xf0103af5
f0100692:	68 0c 3b 10 f0       	push   $0xf0103b0c
f0100697:	68 e3 3a 10 f0       	push   $0xf0103ae3
f010069c:	e8 01 21 00 00       	call   f01027a2 <cprintf>
	return 0;
}
f01006a1:	b8 00 00 00 00       	mov    $0x0,%eax
f01006a6:	c9                   	leave  
f01006a7:	c3                   	ret    

f01006a8 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006a8:	55                   	push   %ebp
f01006a9:	89 e5                	mov    %esp,%ebp
f01006ab:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006ae:	68 16 3b 10 f0       	push   $0xf0103b16
f01006b3:	e8 ea 20 00 00       	call   f01027a2 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006b8:	83 c4 08             	add    $0x8,%esp
f01006bb:	68 0c 00 10 00       	push   $0x10000c
f01006c0:	68 a4 3b 10 f0       	push   $0xf0103ba4
f01006c5:	e8 d8 20 00 00       	call   f01027a2 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006ca:	83 c4 0c             	add    $0xc,%esp
f01006cd:	68 0c 00 10 00       	push   $0x10000c
f01006d2:	68 0c 00 10 f0       	push   $0xf010000c
f01006d7:	68 cc 3b 10 f0       	push   $0xf0103bcc
f01006dc:	e8 c1 20 00 00       	call   f01027a2 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006e1:	83 c4 0c             	add    $0xc,%esp
f01006e4:	68 e1 37 10 00       	push   $0x1037e1
f01006e9:	68 e1 37 10 f0       	push   $0xf01037e1
f01006ee:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01006f3:	e8 aa 20 00 00       	call   f01027a2 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006f8:	83 c4 0c             	add    $0xc,%esp
f01006fb:	68 00 73 11 00       	push   $0x117300
f0100700:	68 00 73 11 f0       	push   $0xf0117300
f0100705:	68 14 3c 10 f0       	push   $0xf0103c14
f010070a:	e8 93 20 00 00       	call   f01027a2 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010070f:	83 c4 0c             	add    $0xc,%esp
f0100712:	68 70 79 11 00       	push   $0x117970
f0100717:	68 70 79 11 f0       	push   $0xf0117970
f010071c:	68 38 3c 10 f0       	push   $0xf0103c38
f0100721:	e8 7c 20 00 00       	call   f01027a2 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100726:	b8 6f 7d 11 f0       	mov    $0xf0117d6f,%eax
f010072b:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100730:	83 c4 08             	add    $0x8,%esp
f0100733:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100738:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010073e:	85 c0                	test   %eax,%eax
f0100740:	0f 48 c2             	cmovs  %edx,%eax
f0100743:	c1 f8 0a             	sar    $0xa,%eax
f0100746:	50                   	push   %eax
f0100747:	68 5c 3c 10 f0       	push   $0xf0103c5c
f010074c:	e8 51 20 00 00       	call   f01027a2 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100751:	b8 00 00 00 00       	mov    $0x0,%eax
f0100756:	c9                   	leave  
f0100757:	c3                   	ret    

f0100758 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100758:	55                   	push   %ebp
f0100759:	89 e5                	mov    %esp,%ebp
f010075b:	57                   	push   %edi
f010075c:	56                   	push   %esi
f010075d:	53                   	push   %ebx
f010075e:	83 ec 2c             	sub    $0x2c,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100761:	89 e8                	mov    %ebp,%eax
    while (ebp != 0)
    {
        p = (uint32_t *) ebp;
        eip = p[1];
        cprintf("ebp %x eip %x args %08x %08x %08x %08x %08x\n", ebp, eip, p[2], p[3], p[4], p[5], p[6]);
        if (debuginfo_eip(eip, &info) == 0)
f0100763:	8d 7d d0             	lea    -0x30(%ebp),%edi
{
    uint32_t ebp, eip, *p;
    struct Eipdebuginfo info;

    ebp = read_ebp();
    while (ebp != 0)
f0100766:	eb 53                	jmp    f01007bb <mon_backtrace+0x63>
    {
        p = (uint32_t *) ebp;
f0100768:	89 c6                	mov    %eax,%esi
        eip = p[1];
f010076a:	8b 58 04             	mov    0x4(%eax),%ebx
        cprintf("ebp %x eip %x args %08x %08x %08x %08x %08x\n", ebp, eip, p[2], p[3], p[4], p[5], p[6]);
f010076d:	ff 70 18             	pushl  0x18(%eax)
f0100770:	ff 70 14             	pushl  0x14(%eax)
f0100773:	ff 70 10             	pushl  0x10(%eax)
f0100776:	ff 70 0c             	pushl  0xc(%eax)
f0100779:	ff 70 08             	pushl  0x8(%eax)
f010077c:	53                   	push   %ebx
f010077d:	50                   	push   %eax
f010077e:	68 88 3c 10 f0       	push   $0xf0103c88
f0100783:	e8 1a 20 00 00       	call   f01027a2 <cprintf>
        if (debuginfo_eip(eip, &info) == 0)
f0100788:	83 c4 18             	add    $0x18,%esp
f010078b:	57                   	push   %edi
f010078c:	53                   	push   %ebx
f010078d:	e8 1a 21 00 00       	call   f01028ac <debuginfo_eip>
f0100792:	83 c4 10             	add    $0x10,%esp
f0100795:	85 c0                	test   %eax,%eax
f0100797:	75 20                	jne    f01007b9 <mon_backtrace+0x61>
        {
            int fn_offset = eip - info.eip_fn_addr;

            cprintf("%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, fn_offset);
f0100799:	83 ec 08             	sub    $0x8,%esp
f010079c:	2b 5d e0             	sub    -0x20(%ebp),%ebx
f010079f:	53                   	push   %ebx
f01007a0:	ff 75 d8             	pushl  -0x28(%ebp)
f01007a3:	ff 75 dc             	pushl  -0x24(%ebp)
f01007a6:	ff 75 d4             	pushl  -0x2c(%ebp)
f01007a9:	ff 75 d0             	pushl  -0x30(%ebp)
f01007ac:	68 2f 3b 10 f0       	push   $0xf0103b2f
f01007b1:	e8 ec 1f 00 00       	call   f01027a2 <cprintf>
f01007b6:	83 c4 20             	add    $0x20,%esp
        }
        ebp = p[0];
f01007b9:	8b 06                	mov    (%esi),%eax
{
    uint32_t ebp, eip, *p;
    struct Eipdebuginfo info;

    ebp = read_ebp();
    while (ebp != 0)
f01007bb:	85 c0                	test   %eax,%eax
f01007bd:	75 a9                	jne    f0100768 <mon_backtrace+0x10>
        }
        ebp = p[0];
    }
    
	return 0;
}
f01007bf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007c2:	5b                   	pop    %ebx
f01007c3:	5e                   	pop    %esi
f01007c4:	5f                   	pop    %edi
f01007c5:	5d                   	pop    %ebp
f01007c6:	c3                   	ret    

f01007c7 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007c7:	55                   	push   %ebp
f01007c8:	89 e5                	mov    %esp,%ebp
f01007ca:	57                   	push   %edi
f01007cb:	56                   	push   %esi
f01007cc:	53                   	push   %ebx
f01007cd:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007d0:	68 b8 3c 10 f0       	push   $0xf0103cb8
f01007d5:	e8 c8 1f 00 00       	call   f01027a2 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007da:	c7 04 24 dc 3c 10 f0 	movl   $0xf0103cdc,(%esp)
f01007e1:	e8 bc 1f 00 00       	call   f01027a2 <cprintf>
f01007e6:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007e9:	83 ec 0c             	sub    $0xc,%esp
f01007ec:	68 3f 3b 10 f0       	push   $0xf0103b3f
f01007f1:	e8 05 29 00 00       	call   f01030fb <readline>
f01007f6:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007f8:	83 c4 10             	add    $0x10,%esp
f01007fb:	85 c0                	test   %eax,%eax
f01007fd:	74 ea                	je     f01007e9 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007ff:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100806:	be 00 00 00 00       	mov    $0x0,%esi
f010080b:	eb 0a                	jmp    f0100817 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010080d:	c6 03 00             	movb   $0x0,(%ebx)
f0100810:	89 f7                	mov    %esi,%edi
f0100812:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100815:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100817:	0f b6 03             	movzbl (%ebx),%eax
f010081a:	84 c0                	test   %al,%al
f010081c:	74 63                	je     f0100881 <monitor+0xba>
f010081e:	83 ec 08             	sub    $0x8,%esp
f0100821:	0f be c0             	movsbl %al,%eax
f0100824:	50                   	push   %eax
f0100825:	68 43 3b 10 f0       	push   $0xf0103b43
f010082a:	e8 e6 2a 00 00       	call   f0103315 <strchr>
f010082f:	83 c4 10             	add    $0x10,%esp
f0100832:	85 c0                	test   %eax,%eax
f0100834:	75 d7                	jne    f010080d <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100836:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100839:	74 46                	je     f0100881 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010083b:	83 fe 0f             	cmp    $0xf,%esi
f010083e:	75 14                	jne    f0100854 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100840:	83 ec 08             	sub    $0x8,%esp
f0100843:	6a 10                	push   $0x10
f0100845:	68 48 3b 10 f0       	push   $0xf0103b48
f010084a:	e8 53 1f 00 00       	call   f01027a2 <cprintf>
f010084f:	83 c4 10             	add    $0x10,%esp
f0100852:	eb 95                	jmp    f01007e9 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f0100854:	8d 7e 01             	lea    0x1(%esi),%edi
f0100857:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010085b:	eb 03                	jmp    f0100860 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010085d:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100860:	0f b6 03             	movzbl (%ebx),%eax
f0100863:	84 c0                	test   %al,%al
f0100865:	74 ae                	je     f0100815 <monitor+0x4e>
f0100867:	83 ec 08             	sub    $0x8,%esp
f010086a:	0f be c0             	movsbl %al,%eax
f010086d:	50                   	push   %eax
f010086e:	68 43 3b 10 f0       	push   $0xf0103b43
f0100873:	e8 9d 2a 00 00       	call   f0103315 <strchr>
f0100878:	83 c4 10             	add    $0x10,%esp
f010087b:	85 c0                	test   %eax,%eax
f010087d:	74 de                	je     f010085d <monitor+0x96>
f010087f:	eb 94                	jmp    f0100815 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f0100881:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100888:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100889:	85 f6                	test   %esi,%esi
f010088b:	0f 84 58 ff ff ff    	je     f01007e9 <monitor+0x22>
f0100891:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100896:	83 ec 08             	sub    $0x8,%esp
f0100899:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010089c:	ff 34 85 20 3d 10 f0 	pushl  -0xfefc2e0(,%eax,4)
f01008a3:	ff 75 a8             	pushl  -0x58(%ebp)
f01008a6:	e8 0c 2a 00 00       	call   f01032b7 <strcmp>
f01008ab:	83 c4 10             	add    $0x10,%esp
f01008ae:	85 c0                	test   %eax,%eax
f01008b0:	75 21                	jne    f01008d3 <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f01008b2:	83 ec 04             	sub    $0x4,%esp
f01008b5:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008b8:	ff 75 08             	pushl  0x8(%ebp)
f01008bb:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008be:	52                   	push   %edx
f01008bf:	56                   	push   %esi
f01008c0:	ff 14 85 28 3d 10 f0 	call   *-0xfefc2d8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008c7:	83 c4 10             	add    $0x10,%esp
f01008ca:	85 c0                	test   %eax,%eax
f01008cc:	78 25                	js     f01008f3 <monitor+0x12c>
f01008ce:	e9 16 ff ff ff       	jmp    f01007e9 <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008d3:	83 c3 01             	add    $0x1,%ebx
f01008d6:	83 fb 03             	cmp    $0x3,%ebx
f01008d9:	75 bb                	jne    f0100896 <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008db:	83 ec 08             	sub    $0x8,%esp
f01008de:	ff 75 a8             	pushl  -0x58(%ebp)
f01008e1:	68 65 3b 10 f0       	push   $0xf0103b65
f01008e6:	e8 b7 1e 00 00       	call   f01027a2 <cprintf>
f01008eb:	83 c4 10             	add    $0x10,%esp
f01008ee:	e9 f6 fe ff ff       	jmp    f01007e9 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008f3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008f6:	5b                   	pop    %ebx
f01008f7:	5e                   	pop    %esi
f01008f8:	5f                   	pop    %edi
f01008f9:	5d                   	pop    %ebp
f01008fa:	c3                   	ret    

f01008fb <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01008fb:	55                   	push   %ebp
f01008fc:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01008fe:	83 3d 38 75 11 f0 00 	cmpl   $0x0,0xf0117538
f0100905:	75 11                	jne    f0100918 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100907:	ba 6f 89 11 f0       	mov    $0xf011896f,%edx
f010090c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100912:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
    result = nextfree;
f0100918:	8b 0d 38 75 11 f0    	mov    0xf0117538,%ecx
    nextfree = ROUNDUP(nextfree + n, PGSIZE);
f010091e:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f0100925:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010092b:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
    
	return result;
}
f0100931:	89 c8                	mov    %ecx,%eax
f0100933:	5d                   	pop    %ebp
f0100934:	c3                   	ret    

f0100935 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100935:	89 d1                	mov    %edx,%ecx
f0100937:	c1 e9 16             	shr    $0x16,%ecx
f010093a:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f010093d:	a8 01                	test   $0x1,%al
f010093f:	74 52                	je     f0100993 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100941:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100946:	89 c1                	mov    %eax,%ecx
f0100948:	c1 e9 0c             	shr    $0xc,%ecx
f010094b:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0100951:	72 1b                	jb     f010096e <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100953:	55                   	push   %ebp
f0100954:	89 e5                	mov    %esp,%ebp
f0100956:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100959:	50                   	push   %eax
f010095a:	68 44 3d 10 f0       	push   $0xf0103d44
f010095f:	68 25 03 00 00       	push   $0x325
f0100964:	68 cc 44 10 f0       	push   $0xf01044cc
f0100969:	e8 59 f7 ff ff       	call   f01000c7 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f010096e:	c1 ea 0c             	shr    $0xc,%edx
f0100971:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100977:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f010097e:	89 c2                	mov    %eax,%edx
f0100980:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100983:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100988:	85 d2                	test   %edx,%edx
f010098a:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f010098f:	0f 44 c2             	cmove  %edx,%eax
f0100992:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100993:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100998:	c3                   	ret    

f0100999 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100999:	55                   	push   %ebp
f010099a:	89 e5                	mov    %esp,%ebp
f010099c:	57                   	push   %edi
f010099d:	56                   	push   %esi
f010099e:	53                   	push   %ebx
f010099f:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009a2:	84 c0                	test   %al,%al
f01009a4:	0f 85 72 02 00 00    	jne    f0100c1c <check_page_free_list+0x283>
f01009aa:	e9 7f 02 00 00       	jmp    f0100c2e <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01009af:	83 ec 04             	sub    $0x4,%esp
f01009b2:	68 68 3d 10 f0       	push   $0xf0103d68
f01009b7:	68 68 02 00 00       	push   $0x268
f01009bc:	68 cc 44 10 f0       	push   $0xf01044cc
f01009c1:	e8 01 f7 ff ff       	call   f01000c7 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f01009c6:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01009c9:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01009cc:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01009cf:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f01009d2:	89 c2                	mov    %eax,%edx
f01009d4:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01009da:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f01009e0:	0f 95 c2             	setne  %dl
f01009e3:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f01009e6:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f01009ea:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f01009ec:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f01009f0:	8b 00                	mov    (%eax),%eax
f01009f2:	85 c0                	test   %eax,%eax
f01009f4:	75 dc                	jne    f01009d2 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f01009f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009f9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f01009ff:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a02:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a05:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a07:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a0a:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a0f:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a14:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100a1a:	eb 53                	jmp    f0100a6f <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a1c:	89 d8                	mov    %ebx,%eax
f0100a1e:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100a24:	c1 f8 03             	sar    $0x3,%eax
f0100a27:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a2a:	89 c2                	mov    %eax,%edx
f0100a2c:	c1 ea 16             	shr    $0x16,%edx
f0100a2f:	39 f2                	cmp    %esi,%edx
f0100a31:	73 3a                	jae    f0100a6d <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a33:	89 c2                	mov    %eax,%edx
f0100a35:	c1 ea 0c             	shr    $0xc,%edx
f0100a38:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100a3e:	72 12                	jb     f0100a52 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a40:	50                   	push   %eax
f0100a41:	68 44 3d 10 f0       	push   $0xf0103d44
f0100a46:	6a 52                	push   $0x52
f0100a48:	68 d8 44 10 f0       	push   $0xf01044d8
f0100a4d:	e8 75 f6 ff ff       	call   f01000c7 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a52:	83 ec 04             	sub    $0x4,%esp
f0100a55:	68 80 00 00 00       	push   $0x80
f0100a5a:	68 97 00 00 00       	push   $0x97
f0100a5f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a64:	50                   	push   %eax
f0100a65:	e8 e8 28 00 00       	call   f0103352 <memset>
f0100a6a:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a6d:	8b 1b                	mov    (%ebx),%ebx
f0100a6f:	85 db                	test   %ebx,%ebx
f0100a71:	75 a9                	jne    f0100a1c <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100a73:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a78:	e8 7e fe ff ff       	call   f01008fb <boot_alloc>
f0100a7d:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a80:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a86:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
		assert(pp < pages + npages);
f0100a8c:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0100a91:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100a94:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a97:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100a9a:	be 00 00 00 00       	mov    $0x0,%esi
f0100a9f:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100aa2:	e9 30 01 00 00       	jmp    f0100bd7 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100aa7:	39 ca                	cmp    %ecx,%edx
f0100aa9:	73 19                	jae    f0100ac4 <check_page_free_list+0x12b>
f0100aab:	68 e6 44 10 f0       	push   $0xf01044e6
f0100ab0:	68 f2 44 10 f0       	push   $0xf01044f2
f0100ab5:	68 82 02 00 00       	push   $0x282
f0100aba:	68 cc 44 10 f0       	push   $0xf01044cc
f0100abf:	e8 03 f6 ff ff       	call   f01000c7 <_panic>
		assert(pp < pages + npages);
f0100ac4:	39 fa                	cmp    %edi,%edx
f0100ac6:	72 19                	jb     f0100ae1 <check_page_free_list+0x148>
f0100ac8:	68 07 45 10 f0       	push   $0xf0104507
f0100acd:	68 f2 44 10 f0       	push   $0xf01044f2
f0100ad2:	68 83 02 00 00       	push   $0x283
f0100ad7:	68 cc 44 10 f0       	push   $0xf01044cc
f0100adc:	e8 e6 f5 ff ff       	call   f01000c7 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ae1:	89 d0                	mov    %edx,%eax
f0100ae3:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100ae6:	a8 07                	test   $0x7,%al
f0100ae8:	74 19                	je     f0100b03 <check_page_free_list+0x16a>
f0100aea:	68 8c 3d 10 f0       	push   $0xf0103d8c
f0100aef:	68 f2 44 10 f0       	push   $0xf01044f2
f0100af4:	68 84 02 00 00       	push   $0x284
f0100af9:	68 cc 44 10 f0       	push   $0xf01044cc
f0100afe:	e8 c4 f5 ff ff       	call   f01000c7 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b03:	c1 f8 03             	sar    $0x3,%eax
f0100b06:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b09:	85 c0                	test   %eax,%eax
f0100b0b:	75 19                	jne    f0100b26 <check_page_free_list+0x18d>
f0100b0d:	68 1b 45 10 f0       	push   $0xf010451b
f0100b12:	68 f2 44 10 f0       	push   $0xf01044f2
f0100b17:	68 87 02 00 00       	push   $0x287
f0100b1c:	68 cc 44 10 f0       	push   $0xf01044cc
f0100b21:	e8 a1 f5 ff ff       	call   f01000c7 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b26:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b2b:	75 19                	jne    f0100b46 <check_page_free_list+0x1ad>
f0100b2d:	68 2c 45 10 f0       	push   $0xf010452c
f0100b32:	68 f2 44 10 f0       	push   $0xf01044f2
f0100b37:	68 88 02 00 00       	push   $0x288
f0100b3c:	68 cc 44 10 f0       	push   $0xf01044cc
f0100b41:	e8 81 f5 ff ff       	call   f01000c7 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b46:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b4b:	75 19                	jne    f0100b66 <check_page_free_list+0x1cd>
f0100b4d:	68 c0 3d 10 f0       	push   $0xf0103dc0
f0100b52:	68 f2 44 10 f0       	push   $0xf01044f2
f0100b57:	68 89 02 00 00       	push   $0x289
f0100b5c:	68 cc 44 10 f0       	push   $0xf01044cc
f0100b61:	e8 61 f5 ff ff       	call   f01000c7 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b66:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b6b:	75 19                	jne    f0100b86 <check_page_free_list+0x1ed>
f0100b6d:	68 45 45 10 f0       	push   $0xf0104545
f0100b72:	68 f2 44 10 f0       	push   $0xf01044f2
f0100b77:	68 8a 02 00 00       	push   $0x28a
f0100b7c:	68 cc 44 10 f0       	push   $0xf01044cc
f0100b81:	e8 41 f5 ff ff       	call   f01000c7 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100b86:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100b8b:	76 3f                	jbe    f0100bcc <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b8d:	89 c3                	mov    %eax,%ebx
f0100b8f:	c1 eb 0c             	shr    $0xc,%ebx
f0100b92:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100b95:	77 12                	ja     f0100ba9 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b97:	50                   	push   %eax
f0100b98:	68 44 3d 10 f0       	push   $0xf0103d44
f0100b9d:	6a 52                	push   $0x52
f0100b9f:	68 d8 44 10 f0       	push   $0xf01044d8
f0100ba4:	e8 1e f5 ff ff       	call   f01000c7 <_panic>
f0100ba9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bae:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100bb1:	76 1e                	jbe    f0100bd1 <check_page_free_list+0x238>
f0100bb3:	68 e4 3d 10 f0       	push   $0xf0103de4
f0100bb8:	68 f2 44 10 f0       	push   $0xf01044f2
f0100bbd:	68 8b 02 00 00       	push   $0x28b
f0100bc2:	68 cc 44 10 f0       	push   $0xf01044cc
f0100bc7:	e8 fb f4 ff ff       	call   f01000c7 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100bcc:	83 c6 01             	add    $0x1,%esi
f0100bcf:	eb 04                	jmp    f0100bd5 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100bd1:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bd5:	8b 12                	mov    (%edx),%edx
f0100bd7:	85 d2                	test   %edx,%edx
f0100bd9:	0f 85 c8 fe ff ff    	jne    f0100aa7 <check_page_free_list+0x10e>
f0100bdf:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100be2:	85 f6                	test   %esi,%esi
f0100be4:	7f 19                	jg     f0100bff <check_page_free_list+0x266>
f0100be6:	68 5f 45 10 f0       	push   $0xf010455f
f0100beb:	68 f2 44 10 f0       	push   $0xf01044f2
f0100bf0:	68 93 02 00 00       	push   $0x293
f0100bf5:	68 cc 44 10 f0       	push   $0xf01044cc
f0100bfa:	e8 c8 f4 ff ff       	call   f01000c7 <_panic>
	assert(nfree_extmem > 0);
f0100bff:	85 db                	test   %ebx,%ebx
f0100c01:	7f 42                	jg     f0100c45 <check_page_free_list+0x2ac>
f0100c03:	68 71 45 10 f0       	push   $0xf0104571
f0100c08:	68 f2 44 10 f0       	push   $0xf01044f2
f0100c0d:	68 94 02 00 00       	push   $0x294
f0100c12:	68 cc 44 10 f0       	push   $0xf01044cc
f0100c17:	e8 ab f4 ff ff       	call   f01000c7 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c1c:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100c21:	85 c0                	test   %eax,%eax
f0100c23:	0f 85 9d fd ff ff    	jne    f01009c6 <check_page_free_list+0x2d>
f0100c29:	e9 81 fd ff ff       	jmp    f01009af <check_page_free_list+0x16>
f0100c2e:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f0100c35:	0f 84 74 fd ff ff    	je     f01009af <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c3b:	be 00 04 00 00       	mov    $0x400,%esi
f0100c40:	e9 cf fd ff ff       	jmp    f0100a14 <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100c45:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c48:	5b                   	pop    %ebx
f0100c49:	5e                   	pop    %esi
f0100c4a:	5f                   	pop    %edi
f0100c4b:	5d                   	pop    %ebp
f0100c4c:	c3                   	ret    

f0100c4d <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100c4d:	55                   	push   %ebp
f0100c4e:	89 e5                	mov    %esp,%ebp
f0100c50:	56                   	push   %esi
f0100c51:	53                   	push   %ebx
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}*/

    // Mark page 0 as in use
    pages[0].pp_ref = 1;
f0100c52:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0100c57:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)

    // Mark base memory as free
	for (i = 1; i < npages_basemem; i++)
f0100c5d:	8b 35 40 75 11 f0    	mov    0xf0117540,%esi
f0100c63:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100c69:	ba 00 00 00 00       	mov    $0x0,%edx
f0100c6e:	b8 01 00 00 00       	mov    $0x1,%eax
f0100c73:	eb 27                	jmp    f0100c9c <page_init+0x4f>
	{
	    pages[i].pp_ref = 0;
f0100c75:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100c7c:	89 d1                	mov    %edx,%ecx
f0100c7e:	03 0d 6c 79 11 f0    	add    0xf011796c,%ecx
f0100c84:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
	    pages[i].pp_link = page_free_list;
f0100c8a:	89 19                	mov    %ebx,(%ecx)

    // Mark page 0 as in use
    pages[0].pp_ref = 1;

    // Mark base memory as free
	for (i = 1; i < npages_basemem; i++)
f0100c8c:	83 c0 01             	add    $0x1,%eax
	{
	    pages[i].pp_ref = 0;
	    pages[i].pp_link = page_free_list;
	    page_free_list = &pages[i];
f0100c8f:	89 d3                	mov    %edx,%ebx
f0100c91:	03 1d 6c 79 11 f0    	add    0xf011796c,%ebx
f0100c97:	ba 01 00 00 00       	mov    $0x1,%edx

    // Mark page 0 as in use
    pages[0].pp_ref = 1;

    // Mark base memory as free
	for (i = 1; i < npages_basemem; i++)
f0100c9c:	39 f0                	cmp    %esi,%eax
f0100c9e:	72 d5                	jb     f0100c75 <page_init+0x28>
f0100ca0:	84 d2                	test   %dl,%dl
f0100ca2:	74 06                	je     f0100caa <page_init+0x5d>
f0100ca4:	89 1d 3c 75 11 f0    	mov    %ebx,0xf011753c
	
	// IOPHYSMEM/PGSIZE == npages_basemem
	// Mark IO hole
	for (i = IOPHYSMEM/PGSIZE; i < EXTPHYSMEM/PGSIZE; i++)
	{
	    pages[i].pp_ref = 1;
f0100caa:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
f0100cb0:	8d 82 04 05 00 00    	lea    0x504(%edx),%eax
f0100cb6:	81 c2 04 08 00 00    	add    $0x804,%edx
f0100cbc:	66 c7 00 01 00       	movw   $0x1,(%eax)
f0100cc1:	83 c0 08             	add    $0x8,%eax
	    page_free_list = &pages[i];
	}
	
	// IOPHYSMEM/PGSIZE == npages_basemem
	// Mark IO hole
	for (i = IOPHYSMEM/PGSIZE; i < EXTPHYSMEM/PGSIZE; i++)
f0100cc4:	39 d0                	cmp    %edx,%eax
f0100cc6:	75 f4                	jne    f0100cbc <page_init+0x6f>
    // kernel is loaded in physical memory 0x100000, the beginning of extended memory
    // page directory entry, and npages of PageInfo structure ares allocated by 
    // boot_alloc in mem_init(). next free byte is 


    first_free_byte = PADDR(boot_alloc(0));
f0100cc8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ccd:	e8 29 fc ff ff       	call   f01008fb <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100cd2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100cd7:	77 15                	ja     f0100cee <page_init+0xa1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100cd9:	50                   	push   %eax
f0100cda:	68 2c 3e 10 f0       	push   $0xf0103e2c
f0100cdf:	68 30 01 00 00       	push   $0x130
f0100ce4:	68 cc 44 10 f0       	push   $0xf01044cc
f0100ce9:	e8 d9 f3 ff ff       	call   f01000c7 <_panic>
    first_free_page = first_free_byte/PGSIZE;
f0100cee:	05 00 00 00 10       	add    $0x10000000,%eax
f0100cf3:	c1 e8 0c             	shr    $0xc,%eax

    // mark kernel and page directory, PageInfo list as in use
    for (i = EXTPHYSMEM/PGSIZE; i < first_free_page; i++)
    {
        pages[i].pp_ref = 1;
f0100cf6:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx

    first_free_byte = PADDR(boot_alloc(0));
    first_free_page = first_free_byte/PGSIZE;

    // mark kernel and page directory, PageInfo list as in use
    for (i = EXTPHYSMEM/PGSIZE; i < first_free_page; i++)
f0100cfc:	ba 00 01 00 00       	mov    $0x100,%edx
f0100d01:	eb 0a                	jmp    f0100d0d <page_init+0xc0>
    {
        pages[i].pp_ref = 1;
f0100d03:	66 c7 44 d1 04 01 00 	movw   $0x1,0x4(%ecx,%edx,8)

    first_free_byte = PADDR(boot_alloc(0));
    first_free_page = first_free_byte/PGSIZE;

    // mark kernel and page directory, PageInfo list as in use
    for (i = EXTPHYSMEM/PGSIZE; i < first_free_page; i++)
f0100d0a:	83 c2 01             	add    $0x1,%edx
f0100d0d:	39 c2                	cmp    %eax,%edx
f0100d0f:	72 f2                	jb     f0100d03 <page_init+0xb6>
f0100d11:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100d17:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100d1e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d23:	eb 23                	jmp    f0100d48 <page_init+0xfb>
        pages[i].pp_ref = 1;
    }
    // mark others as free
    for (i = first_free_page; i < npages; i++)
    {
        pages[i].pp_ref = 0;
f0100d25:	89 d1                	mov    %edx,%ecx
f0100d27:	03 0d 6c 79 11 f0    	add    0xf011796c,%ecx
f0100d2d:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
        pages[i].pp_link = page_free_list;
f0100d33:	89 19                	mov    %ebx,(%ecx)
	    page_free_list = &pages[i];
f0100d35:	89 d3                	mov    %edx,%ebx
f0100d37:	03 1d 6c 79 11 f0    	add    0xf011796c,%ebx
    for (i = EXTPHYSMEM/PGSIZE; i < first_free_page; i++)
    {
        pages[i].pp_ref = 1;
    }
    // mark others as free
    for (i = first_free_page; i < npages; i++)
f0100d3d:	83 c0 01             	add    $0x1,%eax
f0100d40:	83 c2 08             	add    $0x8,%edx
f0100d43:	b9 01 00 00 00       	mov    $0x1,%ecx
f0100d48:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0100d4e:	72 d5                	jb     f0100d25 <page_init+0xd8>
f0100d50:	84 c9                	test   %cl,%cl
f0100d52:	74 06                	je     f0100d5a <page_init+0x10d>
f0100d54:	89 1d 3c 75 11 f0    	mov    %ebx,0xf011753c
    {
        pages[i].pp_ref = 0;
        pages[i].pp_link = page_free_list;
	    page_free_list = &pages[i];
    }
}
f0100d5a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100d5d:	5b                   	pop    %ebx
f0100d5e:	5e                   	pop    %esi
f0100d5f:	5d                   	pop    %ebp
f0100d60:	c3                   	ret    

f0100d61 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d61:	55                   	push   %ebp
f0100d62:	89 e5                	mov    %esp,%ebp
f0100d64:	53                   	push   %ebx
f0100d65:	83 ec 04             	sub    $0x4,%esp
    struct PageInfo *pp;
    char *kva;

    if (!page_free_list)
f0100d68:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100d6e:	85 db                	test   %ebx,%ebx
f0100d70:	74 58                	je     f0100dca <page_alloc+0x69>
    {
        return NULL;
    }
    pp = page_free_list;
    page_free_list = page_free_list->pp_link;
f0100d72:	8b 03                	mov    (%ebx),%eax
f0100d74:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
    pp->pp_link = NULL;
f0100d79:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
    if (alloc_flags & ALLOC_ZERO)
f0100d7f:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d83:	74 45                	je     f0100dca <page_alloc+0x69>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d85:	89 d8                	mov    %ebx,%eax
f0100d87:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100d8d:	c1 f8 03             	sar    $0x3,%eax
f0100d90:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d93:	89 c2                	mov    %eax,%edx
f0100d95:	c1 ea 0c             	shr    $0xc,%edx
f0100d98:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100d9e:	72 12                	jb     f0100db2 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100da0:	50                   	push   %eax
f0100da1:	68 44 3d 10 f0       	push   $0xf0103d44
f0100da6:	6a 52                	push   $0x52
f0100da8:	68 d8 44 10 f0       	push   $0xf01044d8
f0100dad:	e8 15 f3 ff ff       	call   f01000c7 <_panic>
    {
        kva = page2kva(pp);
        memset(kva, '\0', PGSIZE);
f0100db2:	83 ec 04             	sub    $0x4,%esp
f0100db5:	68 00 10 00 00       	push   $0x1000
f0100dba:	6a 00                	push   $0x0
f0100dbc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100dc1:	50                   	push   %eax
f0100dc2:	e8 8b 25 00 00       	call   f0103352 <memset>
f0100dc7:	83 c4 10             	add    $0x10,%esp
    }

	// Fill this function in
	return pp;
}
f0100dca:	89 d8                	mov    %ebx,%eax
f0100dcc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100dcf:	c9                   	leave  
f0100dd0:	c3                   	ret    

f0100dd1 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100dd1:	55                   	push   %ebp
f0100dd2:	89 e5                	mov    %esp,%ebp
f0100dd4:	83 ec 08             	sub    $0x8,%esp
f0100dd7:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if (pp->pp_ref != 0 || pp->pp_link != NULL)
f0100dda:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100ddf:	75 05                	jne    f0100de6 <page_free+0x15>
f0100de1:	83 38 00             	cmpl   $0x0,(%eax)
f0100de4:	74 17                	je     f0100dfd <page_free+0x2c>
	{
	    panic("can't free page in use, or page in the free list");
f0100de6:	83 ec 04             	sub    $0x4,%esp
f0100de9:	68 50 3e 10 f0       	push   $0xf0103e50
f0100dee:	68 70 01 00 00       	push   $0x170
f0100df3:	68 cc 44 10 f0       	push   $0xf01044cc
f0100df8:	e8 ca f2 ff ff       	call   f01000c7 <_panic>
	}
	pp->pp_link = page_free_list;
f0100dfd:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100e03:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100e05:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
}
f0100e0a:	c9                   	leave  
f0100e0b:	c3                   	ret    

f0100e0c <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e0c:	55                   	push   %ebp
f0100e0d:	89 e5                	mov    %esp,%ebp
f0100e0f:	83 ec 08             	sub    $0x8,%esp
f0100e12:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e15:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e19:	83 e8 01             	sub    $0x1,%eax
f0100e1c:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e20:	66 85 c0             	test   %ax,%ax
f0100e23:	75 0c                	jne    f0100e31 <page_decref+0x25>
		page_free(pp);
f0100e25:	83 ec 0c             	sub    $0xc,%esp
f0100e28:	52                   	push   %edx
f0100e29:	e8 a3 ff ff ff       	call   f0100dd1 <page_free>
f0100e2e:	83 c4 10             	add    $0x10,%esp
}
f0100e31:	c9                   	leave  
f0100e32:	c3                   	ret    

f0100e33 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e33:	55                   	push   %ebp
f0100e34:	89 e5                	mov    %esp,%ebp
f0100e36:	57                   	push   %edi
f0100e37:	56                   	push   %esi
f0100e38:	53                   	push   %ebx
f0100e39:	83 ec 0c             	sub    $0xc,%esp
f0100e3c:	8b 45 0c             	mov    0xc(%ebp),%eax

    uint32_t pdx = PDX(va);
    uint32_t ptx = PTX(va);
f0100e3f:	89 c6                	mov    %eax,%esi
f0100e41:	c1 ee 0c             	shr    $0xc,%esi
f0100e44:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
    pde_t * pde;
    pte_t * pte;
    struct PageInfo *pp;

    pde = &pgdir[pdx];
f0100e4a:	c1 e8 16             	shr    $0x16,%eax
f0100e4d:	8d 1c 85 00 00 00 00 	lea    0x0(,%eax,4),%ebx
f0100e54:	03 5d 08             	add    0x8(%ebp),%ebx
    if(*pde & PTE_P)
f0100e57:	8b 03                	mov    (%ebx),%eax
f0100e59:	a8 01                	test   $0x1,%al
f0100e5b:	74 2f                	je     f0100e8c <pgdir_walk+0x59>
    { 
        pte = (KADDR(PTE_ADDR(*pde)));
f0100e5d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e62:	89 c2                	mov    %eax,%edx
f0100e64:	c1 ea 0c             	shr    $0xc,%edx
f0100e67:	39 15 64 79 11 f0    	cmp    %edx,0xf0117964
f0100e6d:	77 15                	ja     f0100e84 <pgdir_walk+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e6f:	50                   	push   %eax
f0100e70:	68 44 3d 10 f0       	push   $0xf0103d44
f0100e75:	68 a4 01 00 00       	push   $0x1a4
f0100e7a:	68 cc 44 10 f0       	push   $0xf01044cc
f0100e7f:	e8 43 f2 ff ff       	call   f01000c7 <_panic>
	return (void *)(pa + KERNBASE);
f0100e84:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
f0100e8a:	eb 73                	jmp    f0100eff <pgdir_walk+0xcc>
    }
    else
    {
        if (!create)
f0100e8c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100e90:	74 72                	je     f0100f04 <pgdir_walk+0xd1>
        {
            return NULL;
        }
        if(!(pp = page_alloc(ALLOC_ZERO)))
f0100e92:	83 ec 0c             	sub    $0xc,%esp
f0100e95:	6a 01                	push   $0x1
f0100e97:	e8 c5 fe ff ff       	call   f0100d61 <page_alloc>
f0100e9c:	83 c4 10             	add    $0x10,%esp
f0100e9f:	85 c0                	test   %eax,%eax
f0100ea1:	74 68                	je     f0100f0b <pgdir_walk+0xd8>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ea3:	89 c1                	mov    %eax,%ecx
f0100ea5:	2b 0d 6c 79 11 f0    	sub    0xf011796c,%ecx
f0100eab:	c1 f9 03             	sar    $0x3,%ecx
f0100eae:	c1 e1 0c             	shl    $0xc,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100eb1:	89 ca                	mov    %ecx,%edx
f0100eb3:	c1 ea 0c             	shr    $0xc,%edx
f0100eb6:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100ebc:	72 12                	jb     f0100ed0 <pgdir_walk+0x9d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ebe:	51                   	push   %ecx
f0100ebf:	68 44 3d 10 f0       	push   $0xf0103d44
f0100ec4:	6a 52                	push   $0x52
f0100ec6:	68 d8 44 10 f0       	push   $0xf01044d8
f0100ecb:	e8 f7 f1 ff ff       	call   f01000c7 <_panic>
	return (void *)(pa + KERNBASE);
f0100ed0:	8d b9 00 00 00 f0    	lea    -0x10000000(%ecx),%edi
f0100ed6:	89 fa                	mov    %edi,%edx
        {
            return NULL;
        }

        pte = (pte_t *)page2kva(pp);
        pp->pp_ref++;
f0100ed8:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100edd:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f0100ee3:	77 15                	ja     f0100efa <pgdir_walk+0xc7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100ee5:	57                   	push   %edi
f0100ee6:	68 2c 3e 10 f0       	push   $0xf0103e2c
f0100eeb:	68 b3 01 00 00       	push   $0x1b3
f0100ef0:	68 cc 44 10 f0       	push   $0xf01044cc
f0100ef5:	e8 cd f1 ff ff       	call   f01000c7 <_panic>
        *pde = PADDR(pte) | PTE_P | PTE_W | PTE_U;
f0100efa:	83 c9 07             	or     $0x7,%ecx
f0100efd:	89 0b                	mov    %ecx,(%ebx)
    }   

    return &pte[ptx];
f0100eff:	8d 04 b2             	lea    (%edx,%esi,4),%eax
f0100f02:	eb 0c                	jmp    f0100f10 <pgdir_walk+0xdd>
    }
    else
    {
        if (!create)
        {
            return NULL;
f0100f04:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f09:	eb 05                	jmp    f0100f10 <pgdir_walk+0xdd>
        }
        if(!(pp = page_alloc(ALLOC_ZERO)))
        {
            return NULL;
f0100f0b:	b8 00 00 00 00       	mov    $0x0,%eax
        pp->pp_ref++;
        *pde = PADDR(pte) | PTE_P | PTE_W | PTE_U;
    }   

    return &pte[ptx];
}
f0100f10:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f13:	5b                   	pop    %ebx
f0100f14:	5e                   	pop    %esi
f0100f15:	5f                   	pop    %edi
f0100f16:	5d                   	pop    %ebp
f0100f17:	c3                   	ret    

f0100f18 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100f18:	55                   	push   %ebp
f0100f19:	89 e5                	mov    %esp,%ebp
f0100f1b:	57                   	push   %edi
f0100f1c:	56                   	push   %esi
f0100f1d:	53                   	push   %ebx
f0100f1e:	83 ec 1c             	sub    $0x1c,%esp
f0100f21:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f24:	8b 45 08             	mov    0x8(%ebp),%eax
    uintptr_t pva = va;
    physaddr_t ppa = pa;
    pte_t *pte;
    size_t i, np;

    np = size/PGSIZE;
f0100f27:	c1 e9 0c             	shr    $0xc,%ecx
f0100f2a:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
    uintptr_t pva = va;
    physaddr_t ppa = pa;
f0100f2d:	89 c3                	mov    %eax,%ebx
    pte_t *pte;
    size_t i, np;

    np = size/PGSIZE;
    // can't use va+size as upper bound, may overflow    
    for (i = 0; i < np; i++)
f0100f2f:	be 00 00 00 00       	mov    $0x0,%esi
    {
        pte = pgdir_walk(pgdir, (void *)pva, 1);
f0100f34:	89 d7                	mov    %edx,%edi
f0100f36:	29 c7                	sub    %eax,%edi
    pte_t *pte;
    size_t i, np;

    np = size/PGSIZE;
    // can't use va+size as upper bound, may overflow    
    for (i = 0; i < np; i++)
f0100f38:	eb 2e                	jmp    f0100f68 <boot_map_region+0x50>
    {
        pte = pgdir_walk(pgdir, (void *)pva, 1);
f0100f3a:	83 ec 04             	sub    $0x4,%esp
f0100f3d:	6a 01                	push   $0x1
f0100f3f:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f0100f42:	50                   	push   %eax
f0100f43:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f46:	e8 e8 fe ff ff       	call   f0100e33 <pgdir_walk>
        if (!pte)
f0100f4b:	83 c4 10             	add    $0x10,%esp
f0100f4e:	85 c0                	test   %eax,%eax
f0100f50:	74 1b                	je     f0100f6d <boot_map_region+0x55>
        {
            return;
        }
        *pte = PTE_ADDR(ppa) | perm;
f0100f52:	89 da                	mov    %ebx,%edx
f0100f54:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100f5a:	0b 55 0c             	or     0xc(%ebp),%edx
f0100f5d:	89 10                	mov    %edx,(%eax)
        pva+=PGSIZE;
        ppa+=PGSIZE;
f0100f5f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pte_t *pte;
    size_t i, np;

    np = size/PGSIZE;
    // can't use va+size as upper bound, may overflow    
    for (i = 0; i < np; i++)
f0100f65:	83 c6 01             	add    $0x1,%esi
f0100f68:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100f6b:	75 cd                	jne    f0100f3a <boot_map_region+0x22>
        }
        *pte = PTE_ADDR(ppa) | perm;
        pva+=PGSIZE;
        ppa+=PGSIZE;
    }
}
f0100f6d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f70:	5b                   	pop    %ebx
f0100f71:	5e                   	pop    %esi
f0100f72:	5f                   	pop    %edi
f0100f73:	5d                   	pop    %ebp
f0100f74:	c3                   	ret    

f0100f75 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100f75:	55                   	push   %ebp
f0100f76:	89 e5                	mov    %esp,%ebp
f0100f78:	53                   	push   %ebx
f0100f79:	83 ec 08             	sub    $0x8,%esp
f0100f7c:	8b 5d 10             	mov    0x10(%ebp),%ebx
    pte_t * pte = pgdir_walk(pgdir, va, 0);
f0100f7f:	6a 00                	push   $0x0
f0100f81:	ff 75 0c             	pushl  0xc(%ebp)
f0100f84:	ff 75 08             	pushl  0x8(%ebp)
f0100f87:	e8 a7 fe ff ff       	call   f0100e33 <pgdir_walk>

    if (!pte)
f0100f8c:	83 c4 10             	add    $0x10,%esp
f0100f8f:	85 c0                	test   %eax,%eax
f0100f91:	74 32                	je     f0100fc5 <page_lookup+0x50>
    {
        return NULL;
    }

    if (pte_store)
f0100f93:	85 db                	test   %ebx,%ebx
f0100f95:	74 02                	je     f0100f99 <page_lookup+0x24>
    {
        *pte_store = pte;
f0100f97:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f99:	8b 00                	mov    (%eax),%eax
f0100f9b:	c1 e8 0c             	shr    $0xc,%eax
f0100f9e:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0100fa4:	72 14                	jb     f0100fba <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0100fa6:	83 ec 04             	sub    $0x4,%esp
f0100fa9:	68 84 3e 10 f0       	push   $0xf0103e84
f0100fae:	6a 4b                	push   $0x4b
f0100fb0:	68 d8 44 10 f0       	push   $0xf01044d8
f0100fb5:	e8 0d f1 ff ff       	call   f01000c7 <_panic>
	return &pages[PGNUM(pa)];
f0100fba:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
f0100fc0:	8d 04 c2             	lea    (%edx,%eax,8),%eax
    }

    return pa2page(PTE_ADDR(*pte));
f0100fc3:	eb 05                	jmp    f0100fca <page_lookup+0x55>
{
    pte_t * pte = pgdir_walk(pgdir, va, 0);

    if (!pte)
    {
        return NULL;
f0100fc5:	b8 00 00 00 00       	mov    $0x0,%eax
    {
        *pte_store = pte;
    }

    return pa2page(PTE_ADDR(*pte));
}
f0100fca:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fcd:	c9                   	leave  
f0100fce:	c3                   	ret    

f0100fcf <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100fcf:	55                   	push   %ebp
f0100fd0:	89 e5                	mov    %esp,%ebp
f0100fd2:	53                   	push   %ebx
f0100fd3:	83 ec 18             	sub    $0x18,%esp
f0100fd6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
    pte_t *pte;
    pte_t **pte_store = &pte;
    struct PageInfo *pp = page_lookup(pgdir, va, pte_store);
f0100fd9:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100fdc:	50                   	push   %eax
f0100fdd:	53                   	push   %ebx
f0100fde:	ff 75 08             	pushl  0x8(%ebp)
f0100fe1:	e8 8f ff ff ff       	call   f0100f75 <page_lookup>
    if(!pp)
f0100fe6:	83 c4 10             	add    $0x10,%esp
f0100fe9:	85 c0                	test   %eax,%eax
f0100feb:	74 18                	je     f0101005 <page_remove+0x36>
        return;

    page_decref(pp);
f0100fed:	83 ec 0c             	sub    $0xc,%esp
f0100ff0:	50                   	push   %eax
f0100ff1:	e8 16 fe ff ff       	call   f0100e0c <page_decref>

    **pte_store = 0;
f0100ff6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100ff9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100fff:	0f 01 3b             	invlpg (%ebx)
f0101002:	83 c4 10             	add    $0x10,%esp
    tlb_invalidate(pgdir, va);
}
f0101005:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101008:	c9                   	leave  
f0101009:	c3                   	ret    

f010100a <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010100a:	55                   	push   %ebp
f010100b:	89 e5                	mov    %esp,%ebp
f010100d:	57                   	push   %edi
f010100e:	56                   	push   %esi
f010100f:	53                   	push   %ebx
f0101010:	83 ec 10             	sub    $0x10,%esp
f0101013:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101016:	8b 7d 10             	mov    0x10(%ebp),%edi
    pte_t *pte = pgdir_walk(pgdir, va, 1);
f0101019:	6a 01                	push   $0x1
f010101b:	57                   	push   %edi
f010101c:	ff 75 08             	pushl  0x8(%ebp)
f010101f:	e8 0f fe ff ff       	call   f0100e33 <pgdir_walk>
    if (!pte)
f0101024:	83 c4 10             	add    $0x10,%esp
f0101027:	85 c0                	test   %eax,%eax
f0101029:	74 63                	je     f010108e <page_insert+0x84>
f010102b:	89 c3                	mov    %eax,%ebx
    {
        return -E_NO_MEM;
    }
    if (*pte & PTE_P)
f010102d:	8b 00                	mov    (%eax),%eax
f010102f:	a8 01                	test   $0x1,%al
f0101031:	74 37                	je     f010106a <page_insert+0x60>
    {
        // reinsert same page to same va
        if (PTE_ADDR(*pte) == page2pa(pp))
f0101033:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101038:	89 f2                	mov    %esi,%edx
f010103a:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101040:	c1 fa 03             	sar    $0x3,%edx
f0101043:	c1 e2 0c             	shl    $0xc,%edx
f0101046:	39 d0                	cmp    %edx,%eax
f0101048:	75 11                	jne    f010105b <page_insert+0x51>
        {
            *pte = page2pa(pp) | (perm|PTE_P);
f010104a:	8b 55 14             	mov    0x14(%ebp),%edx
f010104d:	83 ca 01             	or     $0x1,%edx
f0101050:	09 d0                	or     %edx,%eax
f0101052:	89 03                	mov    %eax,(%ebx)
            return 0;
f0101054:	b8 00 00 00 00       	mov    $0x0,%eax
f0101059:	eb 38                	jmp    f0101093 <page_insert+0x89>
        }
        else
        {
            page_remove(pgdir, va);
f010105b:	83 ec 08             	sub    $0x8,%esp
f010105e:	57                   	push   %edi
f010105f:	ff 75 08             	pushl  0x8(%ebp)
f0101062:	e8 68 ff ff ff       	call   f0100fcf <page_remove>
f0101067:	83 c4 10             	add    $0x10,%esp
        }
    }
    *pte = page2pa(pp) | perm | PTE_P;
f010106a:	89 f0                	mov    %esi,%eax
f010106c:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101072:	c1 f8 03             	sar    $0x3,%eax
f0101075:	c1 e0 0c             	shl    $0xc,%eax
f0101078:	8b 55 14             	mov    0x14(%ebp),%edx
f010107b:	83 ca 01             	or     $0x1,%edx
f010107e:	09 d0                	or     %edx,%eax
f0101080:	89 03                	mov    %eax,(%ebx)
    pp->pp_ref++;
f0101082:	66 83 46 04 01       	addw   $0x1,0x4(%esi)

    return 0;
f0101087:	b8 00 00 00 00       	mov    $0x0,%eax
f010108c:	eb 05                	jmp    f0101093 <page_insert+0x89>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
    pte_t *pte = pgdir_walk(pgdir, va, 1);
    if (!pte)
    {
        return -E_NO_MEM;
f010108e:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    }
    *pte = page2pa(pp) | perm | PTE_P;
    pp->pp_ref++;

    return 0;
}
f0101093:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101096:	5b                   	pop    %ebx
f0101097:	5e                   	pop    %esi
f0101098:	5f                   	pop    %edi
f0101099:	5d                   	pop    %ebp
f010109a:	c3                   	ret    

f010109b <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010109b:	55                   	push   %ebp
f010109c:	89 e5                	mov    %esp,%ebp
f010109e:	57                   	push   %edi
f010109f:	56                   	push   %esi
f01010a0:	53                   	push   %ebx
f01010a1:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01010a4:	6a 15                	push   $0x15
f01010a6:	e8 90 16 00 00       	call   f010273b <mc146818_read>
f01010ab:	89 c3                	mov    %eax,%ebx
f01010ad:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f01010b4:	e8 82 16 00 00       	call   f010273b <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01010b9:	c1 e0 08             	shl    $0x8,%eax
f01010bc:	09 d8                	or     %ebx,%eax
f01010be:	c1 e0 0a             	shl    $0xa,%eax
f01010c1:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01010c7:	85 c0                	test   %eax,%eax
f01010c9:	0f 48 c2             	cmovs  %edx,%eax
f01010cc:	c1 f8 0c             	sar    $0xc,%eax
f01010cf:	a3 40 75 11 f0       	mov    %eax,0xf0117540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01010d4:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f01010db:	e8 5b 16 00 00       	call   f010273b <mc146818_read>
f01010e0:	89 c3                	mov    %eax,%ebx
f01010e2:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01010e9:	e8 4d 16 00 00       	call   f010273b <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01010ee:	c1 e0 08             	shl    $0x8,%eax
f01010f1:	09 d8                	or     %ebx,%eax
f01010f3:	c1 e0 0a             	shl    $0xa,%eax
f01010f6:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01010fc:	83 c4 10             	add    $0x10,%esp
f01010ff:	85 c0                	test   %eax,%eax
f0101101:	0f 48 c2             	cmovs  %edx,%eax
f0101104:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101107:	85 c0                	test   %eax,%eax
f0101109:	74 0e                	je     f0101119 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010110b:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101111:	89 15 64 79 11 f0    	mov    %edx,0xf0117964
f0101117:	eb 0c                	jmp    f0101125 <mem_init+0x8a>
	else
		npages = npages_basemem;
f0101119:	8b 15 40 75 11 f0    	mov    0xf0117540,%edx
f010111f:	89 15 64 79 11 f0    	mov    %edx,0xf0117964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101125:	c1 e0 0c             	shl    $0xc,%eax
f0101128:	c1 e8 0a             	shr    $0xa,%eax
f010112b:	50                   	push   %eax
f010112c:	a1 40 75 11 f0       	mov    0xf0117540,%eax
f0101131:	c1 e0 0c             	shl    $0xc,%eax
f0101134:	c1 e8 0a             	shr    $0xa,%eax
f0101137:	50                   	push   %eax
f0101138:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f010113d:	c1 e0 0c             	shl    $0xc,%eax
f0101140:	c1 e8 0a             	shr    $0xa,%eax
f0101143:	50                   	push   %eax
f0101144:	68 a4 3e 10 f0       	push   $0xf0103ea4
f0101149:	e8 54 16 00 00       	call   f01027a2 <cprintf>
	// Remove this line when you're ready to test this function.
	// panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010114e:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101153:	e8 a3 f7 ff ff       	call   f01008fb <boot_alloc>
f0101158:	a3 68 79 11 f0       	mov    %eax,0xf0117968
	memset(kern_pgdir, 0, PGSIZE);
f010115d:	83 c4 0c             	add    $0xc,%esp
f0101160:	68 00 10 00 00       	push   $0x1000
f0101165:	6a 00                	push   $0x0
f0101167:	50                   	push   %eax
f0101168:	e8 e5 21 00 00       	call   f0103352 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010116d:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101172:	83 c4 10             	add    $0x10,%esp
f0101175:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010117a:	77 15                	ja     f0101191 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010117c:	50                   	push   %eax
f010117d:	68 2c 3e 10 f0       	push   $0xf0103e2c
f0101182:	68 8e 00 00 00       	push   $0x8e
f0101187:	68 cc 44 10 f0       	push   $0xf01044cc
f010118c:	e8 36 ef ff ff       	call   f01000c7 <_panic>
f0101191:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101197:	83 ca 05             	or     $0x5,%edx
f010119a:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:

    pages = (struct PageInfo*)boot_alloc(sizeof(struct PageInfo)*npages);
f01011a0:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f01011a5:	c1 e0 03             	shl    $0x3,%eax
f01011a8:	e8 4e f7 ff ff       	call   f01008fb <boot_alloc>
f01011ad:	a3 6c 79 11 f0       	mov    %eax,0xf011796c
    memset(pages, 0, sizeof(struct PageInfo)*npages);
f01011b2:	83 ec 04             	sub    $0x4,%esp
f01011b5:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f01011bb:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01011c2:	52                   	push   %edx
f01011c3:	6a 00                	push   $0x0
f01011c5:	50                   	push   %eax
f01011c6:	e8 87 21 00 00       	call   f0103352 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01011cb:	e8 7d fa ff ff       	call   f0100c4d <page_init>

	check_page_free_list(1);
f01011d0:	b8 01 00 00 00       	mov    $0x1,%eax
f01011d5:	e8 bf f7 ff ff       	call   f0100999 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01011da:	83 c4 10             	add    $0x10,%esp
f01011dd:	83 3d 6c 79 11 f0 00 	cmpl   $0x0,0xf011796c
f01011e4:	75 17                	jne    f01011fd <mem_init+0x162>
		panic("'pages' is a null pointer!");
f01011e6:	83 ec 04             	sub    $0x4,%esp
f01011e9:	68 82 45 10 f0       	push   $0xf0104582
f01011ee:	68 a5 02 00 00       	push   $0x2a5
f01011f3:	68 cc 44 10 f0       	push   $0xf01044cc
f01011f8:	e8 ca ee ff ff       	call   f01000c7 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011fd:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101202:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101207:	eb 05                	jmp    f010120e <mem_init+0x173>
		++nfree;
f0101209:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010120c:	8b 00                	mov    (%eax),%eax
f010120e:	85 c0                	test   %eax,%eax
f0101210:	75 f7                	jne    f0101209 <mem_init+0x16e>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101212:	83 ec 0c             	sub    $0xc,%esp
f0101215:	6a 00                	push   $0x0
f0101217:	e8 45 fb ff ff       	call   f0100d61 <page_alloc>
f010121c:	89 c7                	mov    %eax,%edi
f010121e:	83 c4 10             	add    $0x10,%esp
f0101221:	85 c0                	test   %eax,%eax
f0101223:	75 19                	jne    f010123e <mem_init+0x1a3>
f0101225:	68 9d 45 10 f0       	push   $0xf010459d
f010122a:	68 f2 44 10 f0       	push   $0xf01044f2
f010122f:	68 ad 02 00 00       	push   $0x2ad
f0101234:	68 cc 44 10 f0       	push   $0xf01044cc
f0101239:	e8 89 ee ff ff       	call   f01000c7 <_panic>
	assert((pp1 = page_alloc(0)));
f010123e:	83 ec 0c             	sub    $0xc,%esp
f0101241:	6a 00                	push   $0x0
f0101243:	e8 19 fb ff ff       	call   f0100d61 <page_alloc>
f0101248:	89 c6                	mov    %eax,%esi
f010124a:	83 c4 10             	add    $0x10,%esp
f010124d:	85 c0                	test   %eax,%eax
f010124f:	75 19                	jne    f010126a <mem_init+0x1cf>
f0101251:	68 b3 45 10 f0       	push   $0xf01045b3
f0101256:	68 f2 44 10 f0       	push   $0xf01044f2
f010125b:	68 ae 02 00 00       	push   $0x2ae
f0101260:	68 cc 44 10 f0       	push   $0xf01044cc
f0101265:	e8 5d ee ff ff       	call   f01000c7 <_panic>
	assert((pp2 = page_alloc(0)));
f010126a:	83 ec 0c             	sub    $0xc,%esp
f010126d:	6a 00                	push   $0x0
f010126f:	e8 ed fa ff ff       	call   f0100d61 <page_alloc>
f0101274:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101277:	83 c4 10             	add    $0x10,%esp
f010127a:	85 c0                	test   %eax,%eax
f010127c:	75 19                	jne    f0101297 <mem_init+0x1fc>
f010127e:	68 c9 45 10 f0       	push   $0xf01045c9
f0101283:	68 f2 44 10 f0       	push   $0xf01044f2
f0101288:	68 af 02 00 00       	push   $0x2af
f010128d:	68 cc 44 10 f0       	push   $0xf01044cc
f0101292:	e8 30 ee ff ff       	call   f01000c7 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101297:	39 f7                	cmp    %esi,%edi
f0101299:	75 19                	jne    f01012b4 <mem_init+0x219>
f010129b:	68 df 45 10 f0       	push   $0xf01045df
f01012a0:	68 f2 44 10 f0       	push   $0xf01044f2
f01012a5:	68 b2 02 00 00       	push   $0x2b2
f01012aa:	68 cc 44 10 f0       	push   $0xf01044cc
f01012af:	e8 13 ee ff ff       	call   f01000c7 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01012b4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012b7:	39 c6                	cmp    %eax,%esi
f01012b9:	74 04                	je     f01012bf <mem_init+0x224>
f01012bb:	39 c7                	cmp    %eax,%edi
f01012bd:	75 19                	jne    f01012d8 <mem_init+0x23d>
f01012bf:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01012c4:	68 f2 44 10 f0       	push   $0xf01044f2
f01012c9:	68 b3 02 00 00       	push   $0x2b3
f01012ce:	68 cc 44 10 f0       	push   $0xf01044cc
f01012d3:	e8 ef ed ff ff       	call   f01000c7 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012d8:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01012de:	8b 15 64 79 11 f0    	mov    0xf0117964,%edx
f01012e4:	c1 e2 0c             	shl    $0xc,%edx
f01012e7:	89 f8                	mov    %edi,%eax
f01012e9:	29 c8                	sub    %ecx,%eax
f01012eb:	c1 f8 03             	sar    $0x3,%eax
f01012ee:	c1 e0 0c             	shl    $0xc,%eax
f01012f1:	39 d0                	cmp    %edx,%eax
f01012f3:	72 19                	jb     f010130e <mem_init+0x273>
f01012f5:	68 f1 45 10 f0       	push   $0xf01045f1
f01012fa:	68 f2 44 10 f0       	push   $0xf01044f2
f01012ff:	68 b4 02 00 00       	push   $0x2b4
f0101304:	68 cc 44 10 f0       	push   $0xf01044cc
f0101309:	e8 b9 ed ff ff       	call   f01000c7 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010130e:	89 f0                	mov    %esi,%eax
f0101310:	29 c8                	sub    %ecx,%eax
f0101312:	c1 f8 03             	sar    $0x3,%eax
f0101315:	c1 e0 0c             	shl    $0xc,%eax
f0101318:	39 c2                	cmp    %eax,%edx
f010131a:	77 19                	ja     f0101335 <mem_init+0x29a>
f010131c:	68 0e 46 10 f0       	push   $0xf010460e
f0101321:	68 f2 44 10 f0       	push   $0xf01044f2
f0101326:	68 b5 02 00 00       	push   $0x2b5
f010132b:	68 cc 44 10 f0       	push   $0xf01044cc
f0101330:	e8 92 ed ff ff       	call   f01000c7 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101335:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101338:	29 c8                	sub    %ecx,%eax
f010133a:	c1 f8 03             	sar    $0x3,%eax
f010133d:	c1 e0 0c             	shl    $0xc,%eax
f0101340:	39 c2                	cmp    %eax,%edx
f0101342:	77 19                	ja     f010135d <mem_init+0x2c2>
f0101344:	68 2b 46 10 f0       	push   $0xf010462b
f0101349:	68 f2 44 10 f0       	push   $0xf01044f2
f010134e:	68 b6 02 00 00       	push   $0x2b6
f0101353:	68 cc 44 10 f0       	push   $0xf01044cc
f0101358:	e8 6a ed ff ff       	call   f01000c7 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010135d:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101362:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101365:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f010136c:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010136f:	83 ec 0c             	sub    $0xc,%esp
f0101372:	6a 00                	push   $0x0
f0101374:	e8 e8 f9 ff ff       	call   f0100d61 <page_alloc>
f0101379:	83 c4 10             	add    $0x10,%esp
f010137c:	85 c0                	test   %eax,%eax
f010137e:	74 19                	je     f0101399 <mem_init+0x2fe>
f0101380:	68 48 46 10 f0       	push   $0xf0104648
f0101385:	68 f2 44 10 f0       	push   $0xf01044f2
f010138a:	68 bd 02 00 00       	push   $0x2bd
f010138f:	68 cc 44 10 f0       	push   $0xf01044cc
f0101394:	e8 2e ed ff ff       	call   f01000c7 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101399:	83 ec 0c             	sub    $0xc,%esp
f010139c:	57                   	push   %edi
f010139d:	e8 2f fa ff ff       	call   f0100dd1 <page_free>
	page_free(pp1);
f01013a2:	89 34 24             	mov    %esi,(%esp)
f01013a5:	e8 27 fa ff ff       	call   f0100dd1 <page_free>
	page_free(pp2);
f01013aa:	83 c4 04             	add    $0x4,%esp
f01013ad:	ff 75 d4             	pushl  -0x2c(%ebp)
f01013b0:	e8 1c fa ff ff       	call   f0100dd1 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013b5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013bc:	e8 a0 f9 ff ff       	call   f0100d61 <page_alloc>
f01013c1:	89 c6                	mov    %eax,%esi
f01013c3:	83 c4 10             	add    $0x10,%esp
f01013c6:	85 c0                	test   %eax,%eax
f01013c8:	75 19                	jne    f01013e3 <mem_init+0x348>
f01013ca:	68 9d 45 10 f0       	push   $0xf010459d
f01013cf:	68 f2 44 10 f0       	push   $0xf01044f2
f01013d4:	68 c4 02 00 00       	push   $0x2c4
f01013d9:	68 cc 44 10 f0       	push   $0xf01044cc
f01013de:	e8 e4 ec ff ff       	call   f01000c7 <_panic>
	assert((pp1 = page_alloc(0)));
f01013e3:	83 ec 0c             	sub    $0xc,%esp
f01013e6:	6a 00                	push   $0x0
f01013e8:	e8 74 f9 ff ff       	call   f0100d61 <page_alloc>
f01013ed:	89 c7                	mov    %eax,%edi
f01013ef:	83 c4 10             	add    $0x10,%esp
f01013f2:	85 c0                	test   %eax,%eax
f01013f4:	75 19                	jne    f010140f <mem_init+0x374>
f01013f6:	68 b3 45 10 f0       	push   $0xf01045b3
f01013fb:	68 f2 44 10 f0       	push   $0xf01044f2
f0101400:	68 c5 02 00 00       	push   $0x2c5
f0101405:	68 cc 44 10 f0       	push   $0xf01044cc
f010140a:	e8 b8 ec ff ff       	call   f01000c7 <_panic>
	assert((pp2 = page_alloc(0)));
f010140f:	83 ec 0c             	sub    $0xc,%esp
f0101412:	6a 00                	push   $0x0
f0101414:	e8 48 f9 ff ff       	call   f0100d61 <page_alloc>
f0101419:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010141c:	83 c4 10             	add    $0x10,%esp
f010141f:	85 c0                	test   %eax,%eax
f0101421:	75 19                	jne    f010143c <mem_init+0x3a1>
f0101423:	68 c9 45 10 f0       	push   $0xf01045c9
f0101428:	68 f2 44 10 f0       	push   $0xf01044f2
f010142d:	68 c6 02 00 00       	push   $0x2c6
f0101432:	68 cc 44 10 f0       	push   $0xf01044cc
f0101437:	e8 8b ec ff ff       	call   f01000c7 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010143c:	39 fe                	cmp    %edi,%esi
f010143e:	75 19                	jne    f0101459 <mem_init+0x3be>
f0101440:	68 df 45 10 f0       	push   $0xf01045df
f0101445:	68 f2 44 10 f0       	push   $0xf01044f2
f010144a:	68 c8 02 00 00       	push   $0x2c8
f010144f:	68 cc 44 10 f0       	push   $0xf01044cc
f0101454:	e8 6e ec ff ff       	call   f01000c7 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101459:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010145c:	39 c7                	cmp    %eax,%edi
f010145e:	74 04                	je     f0101464 <mem_init+0x3c9>
f0101460:	39 c6                	cmp    %eax,%esi
f0101462:	75 19                	jne    f010147d <mem_init+0x3e2>
f0101464:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101469:	68 f2 44 10 f0       	push   $0xf01044f2
f010146e:	68 c9 02 00 00       	push   $0x2c9
f0101473:	68 cc 44 10 f0       	push   $0xf01044cc
f0101478:	e8 4a ec ff ff       	call   f01000c7 <_panic>
	assert(!page_alloc(0));
f010147d:	83 ec 0c             	sub    $0xc,%esp
f0101480:	6a 00                	push   $0x0
f0101482:	e8 da f8 ff ff       	call   f0100d61 <page_alloc>
f0101487:	83 c4 10             	add    $0x10,%esp
f010148a:	85 c0                	test   %eax,%eax
f010148c:	74 19                	je     f01014a7 <mem_init+0x40c>
f010148e:	68 48 46 10 f0       	push   $0xf0104648
f0101493:	68 f2 44 10 f0       	push   $0xf01044f2
f0101498:	68 ca 02 00 00       	push   $0x2ca
f010149d:	68 cc 44 10 f0       	push   $0xf01044cc
f01014a2:	e8 20 ec ff ff       	call   f01000c7 <_panic>
f01014a7:	89 f0                	mov    %esi,%eax
f01014a9:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01014af:	c1 f8 03             	sar    $0x3,%eax
f01014b2:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014b5:	89 c2                	mov    %eax,%edx
f01014b7:	c1 ea 0c             	shr    $0xc,%edx
f01014ba:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01014c0:	72 12                	jb     f01014d4 <mem_init+0x439>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014c2:	50                   	push   %eax
f01014c3:	68 44 3d 10 f0       	push   $0xf0103d44
f01014c8:	6a 52                	push   $0x52
f01014ca:	68 d8 44 10 f0       	push   $0xf01044d8
f01014cf:	e8 f3 eb ff ff       	call   f01000c7 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01014d4:	83 ec 04             	sub    $0x4,%esp
f01014d7:	68 00 10 00 00       	push   $0x1000
f01014dc:	6a 01                	push   $0x1
f01014de:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01014e3:	50                   	push   %eax
f01014e4:	e8 69 1e 00 00       	call   f0103352 <memset>
	page_free(pp0);
f01014e9:	89 34 24             	mov    %esi,(%esp)
f01014ec:	e8 e0 f8 ff ff       	call   f0100dd1 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01014f1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01014f8:	e8 64 f8 ff ff       	call   f0100d61 <page_alloc>
f01014fd:	83 c4 10             	add    $0x10,%esp
f0101500:	85 c0                	test   %eax,%eax
f0101502:	75 19                	jne    f010151d <mem_init+0x482>
f0101504:	68 57 46 10 f0       	push   $0xf0104657
f0101509:	68 f2 44 10 f0       	push   $0xf01044f2
f010150e:	68 cf 02 00 00       	push   $0x2cf
f0101513:	68 cc 44 10 f0       	push   $0xf01044cc
f0101518:	e8 aa eb ff ff       	call   f01000c7 <_panic>
	assert(pp && pp0 == pp);
f010151d:	39 c6                	cmp    %eax,%esi
f010151f:	74 19                	je     f010153a <mem_init+0x49f>
f0101521:	68 75 46 10 f0       	push   $0xf0104675
f0101526:	68 f2 44 10 f0       	push   $0xf01044f2
f010152b:	68 d0 02 00 00       	push   $0x2d0
f0101530:	68 cc 44 10 f0       	push   $0xf01044cc
f0101535:	e8 8d eb ff ff       	call   f01000c7 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010153a:	89 f0                	mov    %esi,%eax
f010153c:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101542:	c1 f8 03             	sar    $0x3,%eax
f0101545:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101548:	89 c2                	mov    %eax,%edx
f010154a:	c1 ea 0c             	shr    $0xc,%edx
f010154d:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0101553:	72 12                	jb     f0101567 <mem_init+0x4cc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101555:	50                   	push   %eax
f0101556:	68 44 3d 10 f0       	push   $0xf0103d44
f010155b:	6a 52                	push   $0x52
f010155d:	68 d8 44 10 f0       	push   $0xf01044d8
f0101562:	e8 60 eb ff ff       	call   f01000c7 <_panic>
f0101567:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010156d:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101573:	80 38 00             	cmpb   $0x0,(%eax)
f0101576:	74 19                	je     f0101591 <mem_init+0x4f6>
f0101578:	68 85 46 10 f0       	push   $0xf0104685
f010157d:	68 f2 44 10 f0       	push   $0xf01044f2
f0101582:	68 d3 02 00 00       	push   $0x2d3
f0101587:	68 cc 44 10 f0       	push   $0xf01044cc
f010158c:	e8 36 eb ff ff       	call   f01000c7 <_panic>
f0101591:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101594:	39 d0                	cmp    %edx,%eax
f0101596:	75 db                	jne    f0101573 <mem_init+0x4d8>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101598:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010159b:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f01015a0:	83 ec 0c             	sub    $0xc,%esp
f01015a3:	56                   	push   %esi
f01015a4:	e8 28 f8 ff ff       	call   f0100dd1 <page_free>
	page_free(pp1);
f01015a9:	89 3c 24             	mov    %edi,(%esp)
f01015ac:	e8 20 f8 ff ff       	call   f0100dd1 <page_free>
	page_free(pp2);
f01015b1:	83 c4 04             	add    $0x4,%esp
f01015b4:	ff 75 d4             	pushl  -0x2c(%ebp)
f01015b7:	e8 15 f8 ff ff       	call   f0100dd1 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015bc:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01015c1:	83 c4 10             	add    $0x10,%esp
f01015c4:	eb 05                	jmp    f01015cb <mem_init+0x530>
		--nfree;
f01015c6:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015c9:	8b 00                	mov    (%eax),%eax
f01015cb:	85 c0                	test   %eax,%eax
f01015cd:	75 f7                	jne    f01015c6 <mem_init+0x52b>
		--nfree;
	assert(nfree == 0);
f01015cf:	85 db                	test   %ebx,%ebx
f01015d1:	74 19                	je     f01015ec <mem_init+0x551>
f01015d3:	68 8f 46 10 f0       	push   $0xf010468f
f01015d8:	68 f2 44 10 f0       	push   $0xf01044f2
f01015dd:	68 e0 02 00 00       	push   $0x2e0
f01015e2:	68 cc 44 10 f0       	push   $0xf01044cc
f01015e7:	e8 db ea ff ff       	call   f01000c7 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01015ec:	83 ec 0c             	sub    $0xc,%esp
f01015ef:	68 00 3f 10 f0       	push   $0xf0103f00
f01015f4:	e8 a9 11 00 00       	call   f01027a2 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015f9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101600:	e8 5c f7 ff ff       	call   f0100d61 <page_alloc>
f0101605:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101608:	83 c4 10             	add    $0x10,%esp
f010160b:	85 c0                	test   %eax,%eax
f010160d:	75 19                	jne    f0101628 <mem_init+0x58d>
f010160f:	68 9d 45 10 f0       	push   $0xf010459d
f0101614:	68 f2 44 10 f0       	push   $0xf01044f2
f0101619:	68 39 03 00 00       	push   $0x339
f010161e:	68 cc 44 10 f0       	push   $0xf01044cc
f0101623:	e8 9f ea ff ff       	call   f01000c7 <_panic>
	assert((pp1 = page_alloc(0)));
f0101628:	83 ec 0c             	sub    $0xc,%esp
f010162b:	6a 00                	push   $0x0
f010162d:	e8 2f f7 ff ff       	call   f0100d61 <page_alloc>
f0101632:	89 c3                	mov    %eax,%ebx
f0101634:	83 c4 10             	add    $0x10,%esp
f0101637:	85 c0                	test   %eax,%eax
f0101639:	75 19                	jne    f0101654 <mem_init+0x5b9>
f010163b:	68 b3 45 10 f0       	push   $0xf01045b3
f0101640:	68 f2 44 10 f0       	push   $0xf01044f2
f0101645:	68 3a 03 00 00       	push   $0x33a
f010164a:	68 cc 44 10 f0       	push   $0xf01044cc
f010164f:	e8 73 ea ff ff       	call   f01000c7 <_panic>
	assert((pp2 = page_alloc(0)));
f0101654:	83 ec 0c             	sub    $0xc,%esp
f0101657:	6a 00                	push   $0x0
f0101659:	e8 03 f7 ff ff       	call   f0100d61 <page_alloc>
f010165e:	89 c6                	mov    %eax,%esi
f0101660:	83 c4 10             	add    $0x10,%esp
f0101663:	85 c0                	test   %eax,%eax
f0101665:	75 19                	jne    f0101680 <mem_init+0x5e5>
f0101667:	68 c9 45 10 f0       	push   $0xf01045c9
f010166c:	68 f2 44 10 f0       	push   $0xf01044f2
f0101671:	68 3b 03 00 00       	push   $0x33b
f0101676:	68 cc 44 10 f0       	push   $0xf01044cc
f010167b:	e8 47 ea ff ff       	call   f01000c7 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101680:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101683:	75 19                	jne    f010169e <mem_init+0x603>
f0101685:	68 df 45 10 f0       	push   $0xf01045df
f010168a:	68 f2 44 10 f0       	push   $0xf01044f2
f010168f:	68 3e 03 00 00       	push   $0x33e
f0101694:	68 cc 44 10 f0       	push   $0xf01044cc
f0101699:	e8 29 ea ff ff       	call   f01000c7 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010169e:	39 c3                	cmp    %eax,%ebx
f01016a0:	74 05                	je     f01016a7 <mem_init+0x60c>
f01016a2:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01016a5:	75 19                	jne    f01016c0 <mem_init+0x625>
f01016a7:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01016ac:	68 f2 44 10 f0       	push   $0xf01044f2
f01016b1:	68 3f 03 00 00       	push   $0x33f
f01016b6:	68 cc 44 10 f0       	push   $0xf01044cc
f01016bb:	e8 07 ea ff ff       	call   f01000c7 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01016c0:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01016c5:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01016c8:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f01016cf:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01016d2:	83 ec 0c             	sub    $0xc,%esp
f01016d5:	6a 00                	push   $0x0
f01016d7:	e8 85 f6 ff ff       	call   f0100d61 <page_alloc>
f01016dc:	83 c4 10             	add    $0x10,%esp
f01016df:	85 c0                	test   %eax,%eax
f01016e1:	74 19                	je     f01016fc <mem_init+0x661>
f01016e3:	68 48 46 10 f0       	push   $0xf0104648
f01016e8:	68 f2 44 10 f0       	push   $0xf01044f2
f01016ed:	68 46 03 00 00       	push   $0x346
f01016f2:	68 cc 44 10 f0       	push   $0xf01044cc
f01016f7:	e8 cb e9 ff ff       	call   f01000c7 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01016fc:	83 ec 04             	sub    $0x4,%esp
f01016ff:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101702:	50                   	push   %eax
f0101703:	6a 00                	push   $0x0
f0101705:	ff 35 68 79 11 f0    	pushl  0xf0117968
f010170b:	e8 65 f8 ff ff       	call   f0100f75 <page_lookup>
f0101710:	83 c4 10             	add    $0x10,%esp
f0101713:	85 c0                	test   %eax,%eax
f0101715:	74 19                	je     f0101730 <mem_init+0x695>
f0101717:	68 20 3f 10 f0       	push   $0xf0103f20
f010171c:	68 f2 44 10 f0       	push   $0xf01044f2
f0101721:	68 49 03 00 00       	push   $0x349
f0101726:	68 cc 44 10 f0       	push   $0xf01044cc
f010172b:	e8 97 e9 ff ff       	call   f01000c7 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101730:	6a 02                	push   $0x2
f0101732:	6a 00                	push   $0x0
f0101734:	53                   	push   %ebx
f0101735:	ff 35 68 79 11 f0    	pushl  0xf0117968
f010173b:	e8 ca f8 ff ff       	call   f010100a <page_insert>
f0101740:	83 c4 10             	add    $0x10,%esp
f0101743:	85 c0                	test   %eax,%eax
f0101745:	78 19                	js     f0101760 <mem_init+0x6c5>
f0101747:	68 58 3f 10 f0       	push   $0xf0103f58
f010174c:	68 f2 44 10 f0       	push   $0xf01044f2
f0101751:	68 4c 03 00 00       	push   $0x34c
f0101756:	68 cc 44 10 f0       	push   $0xf01044cc
f010175b:	e8 67 e9 ff ff       	call   f01000c7 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101760:	83 ec 0c             	sub    $0xc,%esp
f0101763:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101766:	e8 66 f6 ff ff       	call   f0100dd1 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010176b:	6a 02                	push   $0x2
f010176d:	6a 00                	push   $0x0
f010176f:	53                   	push   %ebx
f0101770:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101776:	e8 8f f8 ff ff       	call   f010100a <page_insert>
f010177b:	83 c4 20             	add    $0x20,%esp
f010177e:	85 c0                	test   %eax,%eax
f0101780:	74 19                	je     f010179b <mem_init+0x700>
f0101782:	68 88 3f 10 f0       	push   $0xf0103f88
f0101787:	68 f2 44 10 f0       	push   $0xf01044f2
f010178c:	68 50 03 00 00       	push   $0x350
f0101791:	68 cc 44 10 f0       	push   $0xf01044cc
f0101796:	e8 2c e9 ff ff       	call   f01000c7 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010179b:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01017a1:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f01017a6:	89 c1                	mov    %eax,%ecx
f01017a8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01017ab:	8b 17                	mov    (%edi),%edx
f01017ad:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01017b3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017b6:	29 c8                	sub    %ecx,%eax
f01017b8:	c1 f8 03             	sar    $0x3,%eax
f01017bb:	c1 e0 0c             	shl    $0xc,%eax
f01017be:	39 c2                	cmp    %eax,%edx
f01017c0:	74 19                	je     f01017db <mem_init+0x740>
f01017c2:	68 b8 3f 10 f0       	push   $0xf0103fb8
f01017c7:	68 f2 44 10 f0       	push   $0xf01044f2
f01017cc:	68 51 03 00 00       	push   $0x351
f01017d1:	68 cc 44 10 f0       	push   $0xf01044cc
f01017d6:	e8 ec e8 ff ff       	call   f01000c7 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01017db:	ba 00 00 00 00       	mov    $0x0,%edx
f01017e0:	89 f8                	mov    %edi,%eax
f01017e2:	e8 4e f1 ff ff       	call   f0100935 <check_va2pa>
f01017e7:	89 da                	mov    %ebx,%edx
f01017e9:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01017ec:	c1 fa 03             	sar    $0x3,%edx
f01017ef:	c1 e2 0c             	shl    $0xc,%edx
f01017f2:	39 d0                	cmp    %edx,%eax
f01017f4:	74 19                	je     f010180f <mem_init+0x774>
f01017f6:	68 e0 3f 10 f0       	push   $0xf0103fe0
f01017fb:	68 f2 44 10 f0       	push   $0xf01044f2
f0101800:	68 52 03 00 00       	push   $0x352
f0101805:	68 cc 44 10 f0       	push   $0xf01044cc
f010180a:	e8 b8 e8 ff ff       	call   f01000c7 <_panic>
	assert(pp1->pp_ref == 1);
f010180f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101814:	74 19                	je     f010182f <mem_init+0x794>
f0101816:	68 9a 46 10 f0       	push   $0xf010469a
f010181b:	68 f2 44 10 f0       	push   $0xf01044f2
f0101820:	68 53 03 00 00       	push   $0x353
f0101825:	68 cc 44 10 f0       	push   $0xf01044cc
f010182a:	e8 98 e8 ff ff       	call   f01000c7 <_panic>
	assert(pp0->pp_ref == 1);
f010182f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101832:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101837:	74 19                	je     f0101852 <mem_init+0x7b7>
f0101839:	68 ab 46 10 f0       	push   $0xf01046ab
f010183e:	68 f2 44 10 f0       	push   $0xf01044f2
f0101843:	68 54 03 00 00       	push   $0x354
f0101848:	68 cc 44 10 f0       	push   $0xf01044cc
f010184d:	e8 75 e8 ff ff       	call   f01000c7 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101852:	6a 02                	push   $0x2
f0101854:	68 00 10 00 00       	push   $0x1000
f0101859:	56                   	push   %esi
f010185a:	57                   	push   %edi
f010185b:	e8 aa f7 ff ff       	call   f010100a <page_insert>
f0101860:	83 c4 10             	add    $0x10,%esp
f0101863:	85 c0                	test   %eax,%eax
f0101865:	74 19                	je     f0101880 <mem_init+0x7e5>
f0101867:	68 10 40 10 f0       	push   $0xf0104010
f010186c:	68 f2 44 10 f0       	push   $0xf01044f2
f0101871:	68 57 03 00 00       	push   $0x357
f0101876:	68 cc 44 10 f0       	push   $0xf01044cc
f010187b:	e8 47 e8 ff ff       	call   f01000c7 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101880:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101885:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010188a:	e8 a6 f0 ff ff       	call   f0100935 <check_va2pa>
f010188f:	89 f2                	mov    %esi,%edx
f0101891:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101897:	c1 fa 03             	sar    $0x3,%edx
f010189a:	c1 e2 0c             	shl    $0xc,%edx
f010189d:	39 d0                	cmp    %edx,%eax
f010189f:	74 19                	je     f01018ba <mem_init+0x81f>
f01018a1:	68 4c 40 10 f0       	push   $0xf010404c
f01018a6:	68 f2 44 10 f0       	push   $0xf01044f2
f01018ab:	68 58 03 00 00       	push   $0x358
f01018b0:	68 cc 44 10 f0       	push   $0xf01044cc
f01018b5:	e8 0d e8 ff ff       	call   f01000c7 <_panic>
	assert(pp2->pp_ref == 1);
f01018ba:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018bf:	74 19                	je     f01018da <mem_init+0x83f>
f01018c1:	68 bc 46 10 f0       	push   $0xf01046bc
f01018c6:	68 f2 44 10 f0       	push   $0xf01044f2
f01018cb:	68 59 03 00 00       	push   $0x359
f01018d0:	68 cc 44 10 f0       	push   $0xf01044cc
f01018d5:	e8 ed e7 ff ff       	call   f01000c7 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01018da:	83 ec 0c             	sub    $0xc,%esp
f01018dd:	6a 00                	push   $0x0
f01018df:	e8 7d f4 ff ff       	call   f0100d61 <page_alloc>
f01018e4:	83 c4 10             	add    $0x10,%esp
f01018e7:	85 c0                	test   %eax,%eax
f01018e9:	74 19                	je     f0101904 <mem_init+0x869>
f01018eb:	68 48 46 10 f0       	push   $0xf0104648
f01018f0:	68 f2 44 10 f0       	push   $0xf01044f2
f01018f5:	68 5c 03 00 00       	push   $0x35c
f01018fa:	68 cc 44 10 f0       	push   $0xf01044cc
f01018ff:	e8 c3 e7 ff ff       	call   f01000c7 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101904:	6a 02                	push   $0x2
f0101906:	68 00 10 00 00       	push   $0x1000
f010190b:	56                   	push   %esi
f010190c:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101912:	e8 f3 f6 ff ff       	call   f010100a <page_insert>
f0101917:	83 c4 10             	add    $0x10,%esp
f010191a:	85 c0                	test   %eax,%eax
f010191c:	74 19                	je     f0101937 <mem_init+0x89c>
f010191e:	68 10 40 10 f0       	push   $0xf0104010
f0101923:	68 f2 44 10 f0       	push   $0xf01044f2
f0101928:	68 5f 03 00 00       	push   $0x35f
f010192d:	68 cc 44 10 f0       	push   $0xf01044cc
f0101932:	e8 90 e7 ff ff       	call   f01000c7 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101937:	ba 00 10 00 00       	mov    $0x1000,%edx
f010193c:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101941:	e8 ef ef ff ff       	call   f0100935 <check_va2pa>
f0101946:	89 f2                	mov    %esi,%edx
f0101948:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f010194e:	c1 fa 03             	sar    $0x3,%edx
f0101951:	c1 e2 0c             	shl    $0xc,%edx
f0101954:	39 d0                	cmp    %edx,%eax
f0101956:	74 19                	je     f0101971 <mem_init+0x8d6>
f0101958:	68 4c 40 10 f0       	push   $0xf010404c
f010195d:	68 f2 44 10 f0       	push   $0xf01044f2
f0101962:	68 60 03 00 00       	push   $0x360
f0101967:	68 cc 44 10 f0       	push   $0xf01044cc
f010196c:	e8 56 e7 ff ff       	call   f01000c7 <_panic>
	assert(pp2->pp_ref == 1);
f0101971:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101976:	74 19                	je     f0101991 <mem_init+0x8f6>
f0101978:	68 bc 46 10 f0       	push   $0xf01046bc
f010197d:	68 f2 44 10 f0       	push   $0xf01044f2
f0101982:	68 61 03 00 00       	push   $0x361
f0101987:	68 cc 44 10 f0       	push   $0xf01044cc
f010198c:	e8 36 e7 ff ff       	call   f01000c7 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101991:	83 ec 0c             	sub    $0xc,%esp
f0101994:	6a 00                	push   $0x0
f0101996:	e8 c6 f3 ff ff       	call   f0100d61 <page_alloc>
f010199b:	83 c4 10             	add    $0x10,%esp
f010199e:	85 c0                	test   %eax,%eax
f01019a0:	74 19                	je     f01019bb <mem_init+0x920>
f01019a2:	68 48 46 10 f0       	push   $0xf0104648
f01019a7:	68 f2 44 10 f0       	push   $0xf01044f2
f01019ac:	68 65 03 00 00       	push   $0x365
f01019b1:	68 cc 44 10 f0       	push   $0xf01044cc
f01019b6:	e8 0c e7 ff ff       	call   f01000c7 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01019bb:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f01019c1:	8b 02                	mov    (%edx),%eax
f01019c3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01019c8:	89 c1                	mov    %eax,%ecx
f01019ca:	c1 e9 0c             	shr    $0xc,%ecx
f01019cd:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f01019d3:	72 15                	jb     f01019ea <mem_init+0x94f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01019d5:	50                   	push   %eax
f01019d6:	68 44 3d 10 f0       	push   $0xf0103d44
f01019db:	68 68 03 00 00       	push   $0x368
f01019e0:	68 cc 44 10 f0       	push   $0xf01044cc
f01019e5:	e8 dd e6 ff ff       	call   f01000c7 <_panic>
f01019ea:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01019ef:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01019f2:	83 ec 04             	sub    $0x4,%esp
f01019f5:	6a 00                	push   $0x0
f01019f7:	68 00 10 00 00       	push   $0x1000
f01019fc:	52                   	push   %edx
f01019fd:	e8 31 f4 ff ff       	call   f0100e33 <pgdir_walk>
f0101a02:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101a05:	8d 51 04             	lea    0x4(%ecx),%edx
f0101a08:	83 c4 10             	add    $0x10,%esp
f0101a0b:	39 d0                	cmp    %edx,%eax
f0101a0d:	74 19                	je     f0101a28 <mem_init+0x98d>
f0101a0f:	68 7c 40 10 f0       	push   $0xf010407c
f0101a14:	68 f2 44 10 f0       	push   $0xf01044f2
f0101a19:	68 69 03 00 00       	push   $0x369
f0101a1e:	68 cc 44 10 f0       	push   $0xf01044cc
f0101a23:	e8 9f e6 ff ff       	call   f01000c7 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101a28:	6a 06                	push   $0x6
f0101a2a:	68 00 10 00 00       	push   $0x1000
f0101a2f:	56                   	push   %esi
f0101a30:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101a36:	e8 cf f5 ff ff       	call   f010100a <page_insert>
f0101a3b:	83 c4 10             	add    $0x10,%esp
f0101a3e:	85 c0                	test   %eax,%eax
f0101a40:	74 19                	je     f0101a5b <mem_init+0x9c0>
f0101a42:	68 bc 40 10 f0       	push   $0xf01040bc
f0101a47:	68 f2 44 10 f0       	push   $0xf01044f2
f0101a4c:	68 6c 03 00 00       	push   $0x36c
f0101a51:	68 cc 44 10 f0       	push   $0xf01044cc
f0101a56:	e8 6c e6 ff ff       	call   f01000c7 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a5b:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101a61:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a66:	89 f8                	mov    %edi,%eax
f0101a68:	e8 c8 ee ff ff       	call   f0100935 <check_va2pa>
f0101a6d:	89 f2                	mov    %esi,%edx
f0101a6f:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101a75:	c1 fa 03             	sar    $0x3,%edx
f0101a78:	c1 e2 0c             	shl    $0xc,%edx
f0101a7b:	39 d0                	cmp    %edx,%eax
f0101a7d:	74 19                	je     f0101a98 <mem_init+0x9fd>
f0101a7f:	68 4c 40 10 f0       	push   $0xf010404c
f0101a84:	68 f2 44 10 f0       	push   $0xf01044f2
f0101a89:	68 6d 03 00 00       	push   $0x36d
f0101a8e:	68 cc 44 10 f0       	push   $0xf01044cc
f0101a93:	e8 2f e6 ff ff       	call   f01000c7 <_panic>
	assert(pp2->pp_ref == 1);
f0101a98:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a9d:	74 19                	je     f0101ab8 <mem_init+0xa1d>
f0101a9f:	68 bc 46 10 f0       	push   $0xf01046bc
f0101aa4:	68 f2 44 10 f0       	push   $0xf01044f2
f0101aa9:	68 6e 03 00 00       	push   $0x36e
f0101aae:	68 cc 44 10 f0       	push   $0xf01044cc
f0101ab3:	e8 0f e6 ff ff       	call   f01000c7 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101ab8:	83 ec 04             	sub    $0x4,%esp
f0101abb:	6a 00                	push   $0x0
f0101abd:	68 00 10 00 00       	push   $0x1000
f0101ac2:	57                   	push   %edi
f0101ac3:	e8 6b f3 ff ff       	call   f0100e33 <pgdir_walk>
f0101ac8:	83 c4 10             	add    $0x10,%esp
f0101acb:	f6 00 04             	testb  $0x4,(%eax)
f0101ace:	75 19                	jne    f0101ae9 <mem_init+0xa4e>
f0101ad0:	68 fc 40 10 f0       	push   $0xf01040fc
f0101ad5:	68 f2 44 10 f0       	push   $0xf01044f2
f0101ada:	68 6f 03 00 00       	push   $0x36f
f0101adf:	68 cc 44 10 f0       	push   $0xf01044cc
f0101ae4:	e8 de e5 ff ff       	call   f01000c7 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101ae9:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101aee:	f6 00 04             	testb  $0x4,(%eax)
f0101af1:	75 19                	jne    f0101b0c <mem_init+0xa71>
f0101af3:	68 cd 46 10 f0       	push   $0xf01046cd
f0101af8:	68 f2 44 10 f0       	push   $0xf01044f2
f0101afd:	68 70 03 00 00       	push   $0x370
f0101b02:	68 cc 44 10 f0       	push   $0xf01044cc
f0101b07:	e8 bb e5 ff ff       	call   f01000c7 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b0c:	6a 02                	push   $0x2
f0101b0e:	68 00 10 00 00       	push   $0x1000
f0101b13:	56                   	push   %esi
f0101b14:	50                   	push   %eax
f0101b15:	e8 f0 f4 ff ff       	call   f010100a <page_insert>
f0101b1a:	83 c4 10             	add    $0x10,%esp
f0101b1d:	85 c0                	test   %eax,%eax
f0101b1f:	74 19                	je     f0101b3a <mem_init+0xa9f>
f0101b21:	68 10 40 10 f0       	push   $0xf0104010
f0101b26:	68 f2 44 10 f0       	push   $0xf01044f2
f0101b2b:	68 73 03 00 00       	push   $0x373
f0101b30:	68 cc 44 10 f0       	push   $0xf01044cc
f0101b35:	e8 8d e5 ff ff       	call   f01000c7 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101b3a:	83 ec 04             	sub    $0x4,%esp
f0101b3d:	6a 00                	push   $0x0
f0101b3f:	68 00 10 00 00       	push   $0x1000
f0101b44:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101b4a:	e8 e4 f2 ff ff       	call   f0100e33 <pgdir_walk>
f0101b4f:	83 c4 10             	add    $0x10,%esp
f0101b52:	f6 00 02             	testb  $0x2,(%eax)
f0101b55:	75 19                	jne    f0101b70 <mem_init+0xad5>
f0101b57:	68 30 41 10 f0       	push   $0xf0104130
f0101b5c:	68 f2 44 10 f0       	push   $0xf01044f2
f0101b61:	68 74 03 00 00       	push   $0x374
f0101b66:	68 cc 44 10 f0       	push   $0xf01044cc
f0101b6b:	e8 57 e5 ff ff       	call   f01000c7 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b70:	83 ec 04             	sub    $0x4,%esp
f0101b73:	6a 00                	push   $0x0
f0101b75:	68 00 10 00 00       	push   $0x1000
f0101b7a:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101b80:	e8 ae f2 ff ff       	call   f0100e33 <pgdir_walk>
f0101b85:	83 c4 10             	add    $0x10,%esp
f0101b88:	f6 00 04             	testb  $0x4,(%eax)
f0101b8b:	74 19                	je     f0101ba6 <mem_init+0xb0b>
f0101b8d:	68 64 41 10 f0       	push   $0xf0104164
f0101b92:	68 f2 44 10 f0       	push   $0xf01044f2
f0101b97:	68 75 03 00 00       	push   $0x375
f0101b9c:	68 cc 44 10 f0       	push   $0xf01044cc
f0101ba1:	e8 21 e5 ff ff       	call   f01000c7 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101ba6:	6a 02                	push   $0x2
f0101ba8:	68 00 00 40 00       	push   $0x400000
f0101bad:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101bb0:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101bb6:	e8 4f f4 ff ff       	call   f010100a <page_insert>
f0101bbb:	83 c4 10             	add    $0x10,%esp
f0101bbe:	85 c0                	test   %eax,%eax
f0101bc0:	78 19                	js     f0101bdb <mem_init+0xb40>
f0101bc2:	68 9c 41 10 f0       	push   $0xf010419c
f0101bc7:	68 f2 44 10 f0       	push   $0xf01044f2
f0101bcc:	68 78 03 00 00       	push   $0x378
f0101bd1:	68 cc 44 10 f0       	push   $0xf01044cc
f0101bd6:	e8 ec e4 ff ff       	call   f01000c7 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101bdb:	6a 02                	push   $0x2
f0101bdd:	68 00 10 00 00       	push   $0x1000
f0101be2:	53                   	push   %ebx
f0101be3:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101be9:	e8 1c f4 ff ff       	call   f010100a <page_insert>
f0101bee:	83 c4 10             	add    $0x10,%esp
f0101bf1:	85 c0                	test   %eax,%eax
f0101bf3:	74 19                	je     f0101c0e <mem_init+0xb73>
f0101bf5:	68 d4 41 10 f0       	push   $0xf01041d4
f0101bfa:	68 f2 44 10 f0       	push   $0xf01044f2
f0101bff:	68 7b 03 00 00       	push   $0x37b
f0101c04:	68 cc 44 10 f0       	push   $0xf01044cc
f0101c09:	e8 b9 e4 ff ff       	call   f01000c7 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c0e:	83 ec 04             	sub    $0x4,%esp
f0101c11:	6a 00                	push   $0x0
f0101c13:	68 00 10 00 00       	push   $0x1000
f0101c18:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101c1e:	e8 10 f2 ff ff       	call   f0100e33 <pgdir_walk>
f0101c23:	83 c4 10             	add    $0x10,%esp
f0101c26:	f6 00 04             	testb  $0x4,(%eax)
f0101c29:	74 19                	je     f0101c44 <mem_init+0xba9>
f0101c2b:	68 64 41 10 f0       	push   $0xf0104164
f0101c30:	68 f2 44 10 f0       	push   $0xf01044f2
f0101c35:	68 7c 03 00 00       	push   $0x37c
f0101c3a:	68 cc 44 10 f0       	push   $0xf01044cc
f0101c3f:	e8 83 e4 ff ff       	call   f01000c7 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c44:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101c4a:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c4f:	89 f8                	mov    %edi,%eax
f0101c51:	e8 df ec ff ff       	call   f0100935 <check_va2pa>
f0101c56:	89 c1                	mov    %eax,%ecx
f0101c58:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c5b:	89 d8                	mov    %ebx,%eax
f0101c5d:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101c63:	c1 f8 03             	sar    $0x3,%eax
f0101c66:	c1 e0 0c             	shl    $0xc,%eax
f0101c69:	39 c1                	cmp    %eax,%ecx
f0101c6b:	74 19                	je     f0101c86 <mem_init+0xbeb>
f0101c6d:	68 10 42 10 f0       	push   $0xf0104210
f0101c72:	68 f2 44 10 f0       	push   $0xf01044f2
f0101c77:	68 7f 03 00 00       	push   $0x37f
f0101c7c:	68 cc 44 10 f0       	push   $0xf01044cc
f0101c81:	e8 41 e4 ff ff       	call   f01000c7 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c86:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c8b:	89 f8                	mov    %edi,%eax
f0101c8d:	e8 a3 ec ff ff       	call   f0100935 <check_va2pa>
f0101c92:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101c95:	74 19                	je     f0101cb0 <mem_init+0xc15>
f0101c97:	68 3c 42 10 f0       	push   $0xf010423c
f0101c9c:	68 f2 44 10 f0       	push   $0xf01044f2
f0101ca1:	68 80 03 00 00       	push   $0x380
f0101ca6:	68 cc 44 10 f0       	push   $0xf01044cc
f0101cab:	e8 17 e4 ff ff       	call   f01000c7 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101cb0:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101cb5:	74 19                	je     f0101cd0 <mem_init+0xc35>
f0101cb7:	68 e3 46 10 f0       	push   $0xf01046e3
f0101cbc:	68 f2 44 10 f0       	push   $0xf01044f2
f0101cc1:	68 82 03 00 00       	push   $0x382
f0101cc6:	68 cc 44 10 f0       	push   $0xf01044cc
f0101ccb:	e8 f7 e3 ff ff       	call   f01000c7 <_panic>
	assert(pp2->pp_ref == 0);
f0101cd0:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101cd5:	74 19                	je     f0101cf0 <mem_init+0xc55>
f0101cd7:	68 f4 46 10 f0       	push   $0xf01046f4
f0101cdc:	68 f2 44 10 f0       	push   $0xf01044f2
f0101ce1:	68 83 03 00 00       	push   $0x383
f0101ce6:	68 cc 44 10 f0       	push   $0xf01044cc
f0101ceb:	e8 d7 e3 ff ff       	call   f01000c7 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101cf0:	83 ec 0c             	sub    $0xc,%esp
f0101cf3:	6a 00                	push   $0x0
f0101cf5:	e8 67 f0 ff ff       	call   f0100d61 <page_alloc>
f0101cfa:	83 c4 10             	add    $0x10,%esp
f0101cfd:	85 c0                	test   %eax,%eax
f0101cff:	74 04                	je     f0101d05 <mem_init+0xc6a>
f0101d01:	39 c6                	cmp    %eax,%esi
f0101d03:	74 19                	je     f0101d1e <mem_init+0xc83>
f0101d05:	68 6c 42 10 f0       	push   $0xf010426c
f0101d0a:	68 f2 44 10 f0       	push   $0xf01044f2
f0101d0f:	68 86 03 00 00       	push   $0x386
f0101d14:	68 cc 44 10 f0       	push   $0xf01044cc
f0101d19:	e8 a9 e3 ff ff       	call   f01000c7 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101d1e:	83 ec 08             	sub    $0x8,%esp
f0101d21:	6a 00                	push   $0x0
f0101d23:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101d29:	e8 a1 f2 ff ff       	call   f0100fcf <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d2e:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101d34:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d39:	89 f8                	mov    %edi,%eax
f0101d3b:	e8 f5 eb ff ff       	call   f0100935 <check_va2pa>
f0101d40:	83 c4 10             	add    $0x10,%esp
f0101d43:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d46:	74 19                	je     f0101d61 <mem_init+0xcc6>
f0101d48:	68 90 42 10 f0       	push   $0xf0104290
f0101d4d:	68 f2 44 10 f0       	push   $0xf01044f2
f0101d52:	68 8a 03 00 00       	push   $0x38a
f0101d57:	68 cc 44 10 f0       	push   $0xf01044cc
f0101d5c:	e8 66 e3 ff ff       	call   f01000c7 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d61:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d66:	89 f8                	mov    %edi,%eax
f0101d68:	e8 c8 eb ff ff       	call   f0100935 <check_va2pa>
f0101d6d:	89 da                	mov    %ebx,%edx
f0101d6f:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101d75:	c1 fa 03             	sar    $0x3,%edx
f0101d78:	c1 e2 0c             	shl    $0xc,%edx
f0101d7b:	39 d0                	cmp    %edx,%eax
f0101d7d:	74 19                	je     f0101d98 <mem_init+0xcfd>
f0101d7f:	68 3c 42 10 f0       	push   $0xf010423c
f0101d84:	68 f2 44 10 f0       	push   $0xf01044f2
f0101d89:	68 8b 03 00 00       	push   $0x38b
f0101d8e:	68 cc 44 10 f0       	push   $0xf01044cc
f0101d93:	e8 2f e3 ff ff       	call   f01000c7 <_panic>
	assert(pp1->pp_ref == 1);
f0101d98:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d9d:	74 19                	je     f0101db8 <mem_init+0xd1d>
f0101d9f:	68 9a 46 10 f0       	push   $0xf010469a
f0101da4:	68 f2 44 10 f0       	push   $0xf01044f2
f0101da9:	68 8c 03 00 00       	push   $0x38c
f0101dae:	68 cc 44 10 f0       	push   $0xf01044cc
f0101db3:	e8 0f e3 ff ff       	call   f01000c7 <_panic>
	assert(pp2->pp_ref == 0);
f0101db8:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101dbd:	74 19                	je     f0101dd8 <mem_init+0xd3d>
f0101dbf:	68 f4 46 10 f0       	push   $0xf01046f4
f0101dc4:	68 f2 44 10 f0       	push   $0xf01044f2
f0101dc9:	68 8d 03 00 00       	push   $0x38d
f0101dce:	68 cc 44 10 f0       	push   $0xf01044cc
f0101dd3:	e8 ef e2 ff ff       	call   f01000c7 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101dd8:	6a 00                	push   $0x0
f0101dda:	68 00 10 00 00       	push   $0x1000
f0101ddf:	53                   	push   %ebx
f0101de0:	57                   	push   %edi
f0101de1:	e8 24 f2 ff ff       	call   f010100a <page_insert>
f0101de6:	83 c4 10             	add    $0x10,%esp
f0101de9:	85 c0                	test   %eax,%eax
f0101deb:	74 19                	je     f0101e06 <mem_init+0xd6b>
f0101ded:	68 b4 42 10 f0       	push   $0xf01042b4
f0101df2:	68 f2 44 10 f0       	push   $0xf01044f2
f0101df7:	68 90 03 00 00       	push   $0x390
f0101dfc:	68 cc 44 10 f0       	push   $0xf01044cc
f0101e01:	e8 c1 e2 ff ff       	call   f01000c7 <_panic>
	assert(pp1->pp_ref);
f0101e06:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e0b:	75 19                	jne    f0101e26 <mem_init+0xd8b>
f0101e0d:	68 05 47 10 f0       	push   $0xf0104705
f0101e12:	68 f2 44 10 f0       	push   $0xf01044f2
f0101e17:	68 91 03 00 00       	push   $0x391
f0101e1c:	68 cc 44 10 f0       	push   $0xf01044cc
f0101e21:	e8 a1 e2 ff ff       	call   f01000c7 <_panic>
	assert(pp1->pp_link == NULL);
f0101e26:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101e29:	74 19                	je     f0101e44 <mem_init+0xda9>
f0101e2b:	68 11 47 10 f0       	push   $0xf0104711
f0101e30:	68 f2 44 10 f0       	push   $0xf01044f2
f0101e35:	68 92 03 00 00       	push   $0x392
f0101e3a:	68 cc 44 10 f0       	push   $0xf01044cc
f0101e3f:	e8 83 e2 ff ff       	call   f01000c7 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e44:	83 ec 08             	sub    $0x8,%esp
f0101e47:	68 00 10 00 00       	push   $0x1000
f0101e4c:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101e52:	e8 78 f1 ff ff       	call   f0100fcf <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e57:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101e5d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e62:	89 f8                	mov    %edi,%eax
f0101e64:	e8 cc ea ff ff       	call   f0100935 <check_va2pa>
f0101e69:	83 c4 10             	add    $0x10,%esp
f0101e6c:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e6f:	74 19                	je     f0101e8a <mem_init+0xdef>
f0101e71:	68 90 42 10 f0       	push   $0xf0104290
f0101e76:	68 f2 44 10 f0       	push   $0xf01044f2
f0101e7b:	68 96 03 00 00       	push   $0x396
f0101e80:	68 cc 44 10 f0       	push   $0xf01044cc
f0101e85:	e8 3d e2 ff ff       	call   f01000c7 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e8a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e8f:	89 f8                	mov    %edi,%eax
f0101e91:	e8 9f ea ff ff       	call   f0100935 <check_va2pa>
f0101e96:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e99:	74 19                	je     f0101eb4 <mem_init+0xe19>
f0101e9b:	68 ec 42 10 f0       	push   $0xf01042ec
f0101ea0:	68 f2 44 10 f0       	push   $0xf01044f2
f0101ea5:	68 97 03 00 00       	push   $0x397
f0101eaa:	68 cc 44 10 f0       	push   $0xf01044cc
f0101eaf:	e8 13 e2 ff ff       	call   f01000c7 <_panic>
	assert(pp1->pp_ref == 0);
f0101eb4:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101eb9:	74 19                	je     f0101ed4 <mem_init+0xe39>
f0101ebb:	68 26 47 10 f0       	push   $0xf0104726
f0101ec0:	68 f2 44 10 f0       	push   $0xf01044f2
f0101ec5:	68 98 03 00 00       	push   $0x398
f0101eca:	68 cc 44 10 f0       	push   $0xf01044cc
f0101ecf:	e8 f3 e1 ff ff       	call   f01000c7 <_panic>
	assert(pp2->pp_ref == 0);
f0101ed4:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ed9:	74 19                	je     f0101ef4 <mem_init+0xe59>
f0101edb:	68 f4 46 10 f0       	push   $0xf01046f4
f0101ee0:	68 f2 44 10 f0       	push   $0xf01044f2
f0101ee5:	68 99 03 00 00       	push   $0x399
f0101eea:	68 cc 44 10 f0       	push   $0xf01044cc
f0101eef:	e8 d3 e1 ff ff       	call   f01000c7 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101ef4:	83 ec 0c             	sub    $0xc,%esp
f0101ef7:	6a 00                	push   $0x0
f0101ef9:	e8 63 ee ff ff       	call   f0100d61 <page_alloc>
f0101efe:	83 c4 10             	add    $0x10,%esp
f0101f01:	39 c3                	cmp    %eax,%ebx
f0101f03:	75 04                	jne    f0101f09 <mem_init+0xe6e>
f0101f05:	85 c0                	test   %eax,%eax
f0101f07:	75 19                	jne    f0101f22 <mem_init+0xe87>
f0101f09:	68 14 43 10 f0       	push   $0xf0104314
f0101f0e:	68 f2 44 10 f0       	push   $0xf01044f2
f0101f13:	68 9c 03 00 00       	push   $0x39c
f0101f18:	68 cc 44 10 f0       	push   $0xf01044cc
f0101f1d:	e8 a5 e1 ff ff       	call   f01000c7 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101f22:	83 ec 0c             	sub    $0xc,%esp
f0101f25:	6a 00                	push   $0x0
f0101f27:	e8 35 ee ff ff       	call   f0100d61 <page_alloc>
f0101f2c:	83 c4 10             	add    $0x10,%esp
f0101f2f:	85 c0                	test   %eax,%eax
f0101f31:	74 19                	je     f0101f4c <mem_init+0xeb1>
f0101f33:	68 48 46 10 f0       	push   $0xf0104648
f0101f38:	68 f2 44 10 f0       	push   $0xf01044f2
f0101f3d:	68 9f 03 00 00       	push   $0x39f
f0101f42:	68 cc 44 10 f0       	push   $0xf01044cc
f0101f47:	e8 7b e1 ff ff       	call   f01000c7 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f4c:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f0101f52:	8b 11                	mov    (%ecx),%edx
f0101f54:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f5a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f5d:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101f63:	c1 f8 03             	sar    $0x3,%eax
f0101f66:	c1 e0 0c             	shl    $0xc,%eax
f0101f69:	39 c2                	cmp    %eax,%edx
f0101f6b:	74 19                	je     f0101f86 <mem_init+0xeeb>
f0101f6d:	68 b8 3f 10 f0       	push   $0xf0103fb8
f0101f72:	68 f2 44 10 f0       	push   $0xf01044f2
f0101f77:	68 a2 03 00 00       	push   $0x3a2
f0101f7c:	68 cc 44 10 f0       	push   $0xf01044cc
f0101f81:	e8 41 e1 ff ff       	call   f01000c7 <_panic>
	kern_pgdir[0] = 0;
f0101f86:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f8c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f8f:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f94:	74 19                	je     f0101faf <mem_init+0xf14>
f0101f96:	68 ab 46 10 f0       	push   $0xf01046ab
f0101f9b:	68 f2 44 10 f0       	push   $0xf01044f2
f0101fa0:	68 a4 03 00 00       	push   $0x3a4
f0101fa5:	68 cc 44 10 f0       	push   $0xf01044cc
f0101faa:	e8 18 e1 ff ff       	call   f01000c7 <_panic>
	pp0->pp_ref = 0;
f0101faf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fb2:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101fb8:	83 ec 0c             	sub    $0xc,%esp
f0101fbb:	50                   	push   %eax
f0101fbc:	e8 10 ee ff ff       	call   f0100dd1 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101fc1:	83 c4 0c             	add    $0xc,%esp
f0101fc4:	6a 01                	push   $0x1
f0101fc6:	68 00 10 40 00       	push   $0x401000
f0101fcb:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101fd1:	e8 5d ee ff ff       	call   f0100e33 <pgdir_walk>
f0101fd6:	89 c7                	mov    %eax,%edi
f0101fd8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101fdb:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101fe0:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101fe3:	8b 40 04             	mov    0x4(%eax),%eax
f0101fe6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101feb:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f0101ff1:	89 c2                	mov    %eax,%edx
f0101ff3:	c1 ea 0c             	shr    $0xc,%edx
f0101ff6:	83 c4 10             	add    $0x10,%esp
f0101ff9:	39 ca                	cmp    %ecx,%edx
f0101ffb:	72 15                	jb     f0102012 <mem_init+0xf77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ffd:	50                   	push   %eax
f0101ffe:	68 44 3d 10 f0       	push   $0xf0103d44
f0102003:	68 ab 03 00 00       	push   $0x3ab
f0102008:	68 cc 44 10 f0       	push   $0xf01044cc
f010200d:	e8 b5 e0 ff ff       	call   f01000c7 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102012:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0102017:	39 c7                	cmp    %eax,%edi
f0102019:	74 19                	je     f0102034 <mem_init+0xf99>
f010201b:	68 37 47 10 f0       	push   $0xf0104737
f0102020:	68 f2 44 10 f0       	push   $0xf01044f2
f0102025:	68 ac 03 00 00       	push   $0x3ac
f010202a:	68 cc 44 10 f0       	push   $0xf01044cc
f010202f:	e8 93 e0 ff ff       	call   f01000c7 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102034:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102037:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f010203e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102041:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102047:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f010204d:	c1 f8 03             	sar    $0x3,%eax
f0102050:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102053:	89 c2                	mov    %eax,%edx
f0102055:	c1 ea 0c             	shr    $0xc,%edx
f0102058:	39 d1                	cmp    %edx,%ecx
f010205a:	77 12                	ja     f010206e <mem_init+0xfd3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010205c:	50                   	push   %eax
f010205d:	68 44 3d 10 f0       	push   $0xf0103d44
f0102062:	6a 52                	push   $0x52
f0102064:	68 d8 44 10 f0       	push   $0xf01044d8
f0102069:	e8 59 e0 ff ff       	call   f01000c7 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010206e:	83 ec 04             	sub    $0x4,%esp
f0102071:	68 00 10 00 00       	push   $0x1000
f0102076:	68 ff 00 00 00       	push   $0xff
f010207b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102080:	50                   	push   %eax
f0102081:	e8 cc 12 00 00       	call   f0103352 <memset>
	page_free(pp0);
f0102086:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102089:	89 3c 24             	mov    %edi,(%esp)
f010208c:	e8 40 ed ff ff       	call   f0100dd1 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102091:	83 c4 0c             	add    $0xc,%esp
f0102094:	6a 01                	push   $0x1
f0102096:	6a 00                	push   $0x0
f0102098:	ff 35 68 79 11 f0    	pushl  0xf0117968
f010209e:	e8 90 ed ff ff       	call   f0100e33 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01020a3:	89 fa                	mov    %edi,%edx
f01020a5:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01020ab:	c1 fa 03             	sar    $0x3,%edx
f01020ae:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01020b1:	89 d0                	mov    %edx,%eax
f01020b3:	c1 e8 0c             	shr    $0xc,%eax
f01020b6:	83 c4 10             	add    $0x10,%esp
f01020b9:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f01020bf:	72 12                	jb     f01020d3 <mem_init+0x1038>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01020c1:	52                   	push   %edx
f01020c2:	68 44 3d 10 f0       	push   $0xf0103d44
f01020c7:	6a 52                	push   $0x52
f01020c9:	68 d8 44 10 f0       	push   $0xf01044d8
f01020ce:	e8 f4 df ff ff       	call   f01000c7 <_panic>
	return (void *)(pa + KERNBASE);
f01020d3:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01020d9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01020dc:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01020e2:	f6 00 01             	testb  $0x1,(%eax)
f01020e5:	74 19                	je     f0102100 <mem_init+0x1065>
f01020e7:	68 4f 47 10 f0       	push   $0xf010474f
f01020ec:	68 f2 44 10 f0       	push   $0xf01044f2
f01020f1:	68 b6 03 00 00       	push   $0x3b6
f01020f6:	68 cc 44 10 f0       	push   $0xf01044cc
f01020fb:	e8 c7 df ff ff       	call   f01000c7 <_panic>
f0102100:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102103:	39 d0                	cmp    %edx,%eax
f0102105:	75 db                	jne    f01020e2 <mem_init+0x1047>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102107:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010210c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102112:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102115:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010211b:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010211e:	89 0d 3c 75 11 f0    	mov    %ecx,0xf011753c

	// free the pages we took
	page_free(pp0);
f0102124:	83 ec 0c             	sub    $0xc,%esp
f0102127:	50                   	push   %eax
f0102128:	e8 a4 ec ff ff       	call   f0100dd1 <page_free>
	page_free(pp1);
f010212d:	89 1c 24             	mov    %ebx,(%esp)
f0102130:	e8 9c ec ff ff       	call   f0100dd1 <page_free>
	page_free(pp2);
f0102135:	89 34 24             	mov    %esi,(%esp)
f0102138:	e8 94 ec ff ff       	call   f0100dd1 <page_free>

	cprintf("check_page() succeeded!\n");
f010213d:	c7 04 24 66 47 10 f0 	movl   $0xf0104766,(%esp)
f0102144:	e8 59 06 00 00       	call   f01027a2 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	
   boot_map_region(kern_pgdir, 
f0102149:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010214e:	83 c4 10             	add    $0x10,%esp
f0102151:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102156:	77 15                	ja     f010216d <mem_init+0x10d2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102158:	50                   	push   %eax
f0102159:	68 2c 3e 10 f0       	push   $0xf0103e2c
f010215e:	68 b5 00 00 00       	push   $0xb5
f0102163:	68 cc 44 10 f0       	push   $0xf01044cc
f0102168:	e8 5a df ff ff       	call   f01000c7 <_panic>
                    UPAGES, 
                    ROUNDUP((sizeof(struct PageInfo)*npages), PGSIZE),
f010216d:	8b 15 64 79 11 f0    	mov    0xf0117964,%edx
f0102173:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	
   boot_map_region(kern_pgdir, 
f010217a:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102180:	83 ec 08             	sub    $0x8,%esp
f0102183:	6a 05                	push   $0x5
f0102185:	05 00 00 00 10       	add    $0x10000000,%eax
f010218a:	50                   	push   %eax
f010218b:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102190:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102195:	e8 7e ed ff ff       	call   f0100f18 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010219a:	83 c4 10             	add    $0x10,%esp
f010219d:	b8 00 d0 10 f0       	mov    $0xf010d000,%eax
f01021a2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01021a7:	77 15                	ja     f01021be <mem_init+0x1123>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021a9:	50                   	push   %eax
f01021aa:	68 2c 3e 10 f0       	push   $0xf0103e2c
f01021af:	68 c6 00 00 00       	push   $0xc6
f01021b4:	68 cc 44 10 f0       	push   $0xf01044cc
f01021b9:	e8 09 df ff ff       	call   f01000c7 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
    boot_map_region(kern_pgdir, 
f01021be:	83 ec 08             	sub    $0x8,%esp
f01021c1:	6a 03                	push   $0x3
f01021c3:	68 00 d0 10 00       	push   $0x10d000
f01021c8:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01021cd:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01021d2:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01021d7:	e8 3c ed ff ff       	call   f0100f18 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
    boot_map_region(kern_pgdir, 
f01021dc:	83 c4 08             	add    $0x8,%esp
f01021df:	6a 03                	push   $0x3
f01021e1:	6a 00                	push   $0x0
f01021e3:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01021e8:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021ed:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01021f2:	e8 21 ed ff ff       	call   f0100f18 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01021f7:	8b 35 68 79 11 f0    	mov    0xf0117968,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021fd:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0102202:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102205:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010220c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102211:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102214:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010221a:	89 7d d0             	mov    %edi,-0x30(%ebp)
f010221d:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102220:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102225:	eb 55                	jmp    f010227c <mem_init+0x11e1>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102227:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f010222d:	89 f0                	mov    %esi,%eax
f010222f:	e8 01 e7 ff ff       	call   f0100935 <check_va2pa>
f0102234:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f010223b:	77 15                	ja     f0102252 <mem_init+0x11b7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010223d:	57                   	push   %edi
f010223e:	68 2c 3e 10 f0       	push   $0xf0103e2c
f0102243:	68 f8 02 00 00       	push   $0x2f8
f0102248:	68 cc 44 10 f0       	push   $0xf01044cc
f010224d:	e8 75 de ff ff       	call   f01000c7 <_panic>
f0102252:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f0102259:	39 c2                	cmp    %eax,%edx
f010225b:	74 19                	je     f0102276 <mem_init+0x11db>
f010225d:	68 38 43 10 f0       	push   $0xf0104338
f0102262:	68 f2 44 10 f0       	push   $0xf01044f2
f0102267:	68 f8 02 00 00       	push   $0x2f8
f010226c:	68 cc 44 10 f0       	push   $0xf01044cc
f0102271:	e8 51 de ff ff       	call   f01000c7 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102276:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010227c:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010227f:	77 a6                	ja     f0102227 <mem_init+0x118c>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102281:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102284:	c1 e7 0c             	shl    $0xc,%edi
f0102287:	bb 00 00 00 00       	mov    $0x0,%ebx
f010228c:	eb 30                	jmp    f01022be <mem_init+0x1223>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010228e:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102294:	89 f0                	mov    %esi,%eax
f0102296:	e8 9a e6 ff ff       	call   f0100935 <check_va2pa>
f010229b:	39 c3                	cmp    %eax,%ebx
f010229d:	74 19                	je     f01022b8 <mem_init+0x121d>
f010229f:	68 6c 43 10 f0       	push   $0xf010436c
f01022a4:	68 f2 44 10 f0       	push   $0xf01044f2
f01022a9:	68 fd 02 00 00       	push   $0x2fd
f01022ae:	68 cc 44 10 f0       	push   $0xf01044cc
f01022b3:	e8 0f de ff ff       	call   f01000c7 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01022b8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01022be:	39 fb                	cmp    %edi,%ebx
f01022c0:	72 cc                	jb     f010228e <mem_init+0x11f3>
f01022c2:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01022c7:	89 da                	mov    %ebx,%edx
f01022c9:	89 f0                	mov    %esi,%eax
f01022cb:	e8 65 e6 ff ff       	call   f0100935 <check_va2pa>
f01022d0:	8d 93 00 50 11 10    	lea    0x10115000(%ebx),%edx
f01022d6:	39 c2                	cmp    %eax,%edx
f01022d8:	74 19                	je     f01022f3 <mem_init+0x1258>
f01022da:	68 94 43 10 f0       	push   $0xf0104394
f01022df:	68 f2 44 10 f0       	push   $0xf01044f2
f01022e4:	68 01 03 00 00       	push   $0x301
f01022e9:	68 cc 44 10 f0       	push   $0xf01044cc
f01022ee:	e8 d4 dd ff ff       	call   f01000c7 <_panic>
f01022f3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01022f9:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f01022ff:	75 c6                	jne    f01022c7 <mem_init+0x122c>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102301:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102306:	89 f0                	mov    %esi,%eax
f0102308:	e8 28 e6 ff ff       	call   f0100935 <check_va2pa>
f010230d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102310:	74 51                	je     f0102363 <mem_init+0x12c8>
f0102312:	68 dc 43 10 f0       	push   $0xf01043dc
f0102317:	68 f2 44 10 f0       	push   $0xf01044f2
f010231c:	68 02 03 00 00       	push   $0x302
f0102321:	68 cc 44 10 f0       	push   $0xf01044cc
f0102326:	e8 9c dd ff ff       	call   f01000c7 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010232b:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102330:	72 36                	jb     f0102368 <mem_init+0x12cd>
f0102332:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102337:	76 07                	jbe    f0102340 <mem_init+0x12a5>
f0102339:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010233e:	75 28                	jne    f0102368 <mem_init+0x12cd>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102340:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102344:	0f 85 83 00 00 00    	jne    f01023cd <mem_init+0x1332>
f010234a:	68 7f 47 10 f0       	push   $0xf010477f
f010234f:	68 f2 44 10 f0       	push   $0xf01044f2
f0102354:	68 0a 03 00 00       	push   $0x30a
f0102359:	68 cc 44 10 f0       	push   $0xf01044cc
f010235e:	e8 64 dd ff ff       	call   f01000c7 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102363:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102368:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010236d:	76 3f                	jbe    f01023ae <mem_init+0x1313>
				assert(pgdir[i] & PTE_P);
f010236f:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102372:	f6 c2 01             	test   $0x1,%dl
f0102375:	75 19                	jne    f0102390 <mem_init+0x12f5>
f0102377:	68 7f 47 10 f0       	push   $0xf010477f
f010237c:	68 f2 44 10 f0       	push   $0xf01044f2
f0102381:	68 0e 03 00 00       	push   $0x30e
f0102386:	68 cc 44 10 f0       	push   $0xf01044cc
f010238b:	e8 37 dd ff ff       	call   f01000c7 <_panic>
				assert(pgdir[i] & PTE_W);
f0102390:	f6 c2 02             	test   $0x2,%dl
f0102393:	75 38                	jne    f01023cd <mem_init+0x1332>
f0102395:	68 90 47 10 f0       	push   $0xf0104790
f010239a:	68 f2 44 10 f0       	push   $0xf01044f2
f010239f:	68 0f 03 00 00       	push   $0x30f
f01023a4:	68 cc 44 10 f0       	push   $0xf01044cc
f01023a9:	e8 19 dd ff ff       	call   f01000c7 <_panic>
			} else
				assert(pgdir[i] == 0);
f01023ae:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f01023b2:	74 19                	je     f01023cd <mem_init+0x1332>
f01023b4:	68 a1 47 10 f0       	push   $0xf01047a1
f01023b9:	68 f2 44 10 f0       	push   $0xf01044f2
f01023be:	68 11 03 00 00       	push   $0x311
f01023c3:	68 cc 44 10 f0       	push   $0xf01044cc
f01023c8:	e8 fa dc ff ff       	call   f01000c7 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01023cd:	83 c0 01             	add    $0x1,%eax
f01023d0:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01023d5:	0f 86 50 ff ff ff    	jbe    f010232b <mem_init+0x1290>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01023db:	83 ec 0c             	sub    $0xc,%esp
f01023de:	68 0c 44 10 f0       	push   $0xf010440c
f01023e3:	e8 ba 03 00 00       	call   f01027a2 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01023e8:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01023ed:	83 c4 10             	add    $0x10,%esp
f01023f0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01023f5:	77 15                	ja     f010240c <mem_init+0x1371>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01023f7:	50                   	push   %eax
f01023f8:	68 2c 3e 10 f0       	push   $0xf0103e2c
f01023fd:	68 e1 00 00 00       	push   $0xe1
f0102402:	68 cc 44 10 f0       	push   $0xf01044cc
f0102407:	e8 bb dc ff ff       	call   f01000c7 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010240c:	05 00 00 00 10       	add    $0x10000000,%eax
f0102411:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102414:	b8 00 00 00 00       	mov    $0x0,%eax
f0102419:	e8 7b e5 ff ff       	call   f0100999 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f010241e:	0f 20 c0             	mov    %cr0,%eax
f0102421:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102424:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102429:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010242c:	83 ec 0c             	sub    $0xc,%esp
f010242f:	6a 00                	push   $0x0
f0102431:	e8 2b e9 ff ff       	call   f0100d61 <page_alloc>
f0102436:	89 c3                	mov    %eax,%ebx
f0102438:	83 c4 10             	add    $0x10,%esp
f010243b:	85 c0                	test   %eax,%eax
f010243d:	75 19                	jne    f0102458 <mem_init+0x13bd>
f010243f:	68 9d 45 10 f0       	push   $0xf010459d
f0102444:	68 f2 44 10 f0       	push   $0xf01044f2
f0102449:	68 d1 03 00 00       	push   $0x3d1
f010244e:	68 cc 44 10 f0       	push   $0xf01044cc
f0102453:	e8 6f dc ff ff       	call   f01000c7 <_panic>
	assert((pp1 = page_alloc(0)));
f0102458:	83 ec 0c             	sub    $0xc,%esp
f010245b:	6a 00                	push   $0x0
f010245d:	e8 ff e8 ff ff       	call   f0100d61 <page_alloc>
f0102462:	89 c7                	mov    %eax,%edi
f0102464:	83 c4 10             	add    $0x10,%esp
f0102467:	85 c0                	test   %eax,%eax
f0102469:	75 19                	jne    f0102484 <mem_init+0x13e9>
f010246b:	68 b3 45 10 f0       	push   $0xf01045b3
f0102470:	68 f2 44 10 f0       	push   $0xf01044f2
f0102475:	68 d2 03 00 00       	push   $0x3d2
f010247a:	68 cc 44 10 f0       	push   $0xf01044cc
f010247f:	e8 43 dc ff ff       	call   f01000c7 <_panic>
	assert((pp2 = page_alloc(0)));
f0102484:	83 ec 0c             	sub    $0xc,%esp
f0102487:	6a 00                	push   $0x0
f0102489:	e8 d3 e8 ff ff       	call   f0100d61 <page_alloc>
f010248e:	89 c6                	mov    %eax,%esi
f0102490:	83 c4 10             	add    $0x10,%esp
f0102493:	85 c0                	test   %eax,%eax
f0102495:	75 19                	jne    f01024b0 <mem_init+0x1415>
f0102497:	68 c9 45 10 f0       	push   $0xf01045c9
f010249c:	68 f2 44 10 f0       	push   $0xf01044f2
f01024a1:	68 d3 03 00 00       	push   $0x3d3
f01024a6:	68 cc 44 10 f0       	push   $0xf01044cc
f01024ab:	e8 17 dc ff ff       	call   f01000c7 <_panic>
	page_free(pp0);
f01024b0:	83 ec 0c             	sub    $0xc,%esp
f01024b3:	53                   	push   %ebx
f01024b4:	e8 18 e9 ff ff       	call   f0100dd1 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024b9:	89 f8                	mov    %edi,%eax
f01024bb:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01024c1:	c1 f8 03             	sar    $0x3,%eax
f01024c4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024c7:	89 c2                	mov    %eax,%edx
f01024c9:	c1 ea 0c             	shr    $0xc,%edx
f01024cc:	83 c4 10             	add    $0x10,%esp
f01024cf:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01024d5:	72 12                	jb     f01024e9 <mem_init+0x144e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024d7:	50                   	push   %eax
f01024d8:	68 44 3d 10 f0       	push   $0xf0103d44
f01024dd:	6a 52                	push   $0x52
f01024df:	68 d8 44 10 f0       	push   $0xf01044d8
f01024e4:	e8 de db ff ff       	call   f01000c7 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01024e9:	83 ec 04             	sub    $0x4,%esp
f01024ec:	68 00 10 00 00       	push   $0x1000
f01024f1:	6a 01                	push   $0x1
f01024f3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024f8:	50                   	push   %eax
f01024f9:	e8 54 0e 00 00       	call   f0103352 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024fe:	89 f0                	mov    %esi,%eax
f0102500:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102506:	c1 f8 03             	sar    $0x3,%eax
f0102509:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010250c:	89 c2                	mov    %eax,%edx
f010250e:	c1 ea 0c             	shr    $0xc,%edx
f0102511:	83 c4 10             	add    $0x10,%esp
f0102514:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f010251a:	72 12                	jb     f010252e <mem_init+0x1493>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010251c:	50                   	push   %eax
f010251d:	68 44 3d 10 f0       	push   $0xf0103d44
f0102522:	6a 52                	push   $0x52
f0102524:	68 d8 44 10 f0       	push   $0xf01044d8
f0102529:	e8 99 db ff ff       	call   f01000c7 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f010252e:	83 ec 04             	sub    $0x4,%esp
f0102531:	68 00 10 00 00       	push   $0x1000
f0102536:	6a 02                	push   $0x2
f0102538:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010253d:	50                   	push   %eax
f010253e:	e8 0f 0e 00 00       	call   f0103352 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102543:	6a 02                	push   $0x2
f0102545:	68 00 10 00 00       	push   $0x1000
f010254a:	57                   	push   %edi
f010254b:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102551:	e8 b4 ea ff ff       	call   f010100a <page_insert>
	assert(pp1->pp_ref == 1);
f0102556:	83 c4 20             	add    $0x20,%esp
f0102559:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f010255e:	74 19                	je     f0102579 <mem_init+0x14de>
f0102560:	68 9a 46 10 f0       	push   $0xf010469a
f0102565:	68 f2 44 10 f0       	push   $0xf01044f2
f010256a:	68 d8 03 00 00       	push   $0x3d8
f010256f:	68 cc 44 10 f0       	push   $0xf01044cc
f0102574:	e8 4e db ff ff       	call   f01000c7 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102579:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102580:	01 01 01 
f0102583:	74 19                	je     f010259e <mem_init+0x1503>
f0102585:	68 2c 44 10 f0       	push   $0xf010442c
f010258a:	68 f2 44 10 f0       	push   $0xf01044f2
f010258f:	68 d9 03 00 00       	push   $0x3d9
f0102594:	68 cc 44 10 f0       	push   $0xf01044cc
f0102599:	e8 29 db ff ff       	call   f01000c7 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f010259e:	6a 02                	push   $0x2
f01025a0:	68 00 10 00 00       	push   $0x1000
f01025a5:	56                   	push   %esi
f01025a6:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01025ac:	e8 59 ea ff ff       	call   f010100a <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01025b1:	83 c4 10             	add    $0x10,%esp
f01025b4:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f01025bb:	02 02 02 
f01025be:	74 19                	je     f01025d9 <mem_init+0x153e>
f01025c0:	68 50 44 10 f0       	push   $0xf0104450
f01025c5:	68 f2 44 10 f0       	push   $0xf01044f2
f01025ca:	68 db 03 00 00       	push   $0x3db
f01025cf:	68 cc 44 10 f0       	push   $0xf01044cc
f01025d4:	e8 ee da ff ff       	call   f01000c7 <_panic>
	assert(pp2->pp_ref == 1);
f01025d9:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01025de:	74 19                	je     f01025f9 <mem_init+0x155e>
f01025e0:	68 bc 46 10 f0       	push   $0xf01046bc
f01025e5:	68 f2 44 10 f0       	push   $0xf01044f2
f01025ea:	68 dc 03 00 00       	push   $0x3dc
f01025ef:	68 cc 44 10 f0       	push   $0xf01044cc
f01025f4:	e8 ce da ff ff       	call   f01000c7 <_panic>
	assert(pp1->pp_ref == 0);
f01025f9:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01025fe:	74 19                	je     f0102619 <mem_init+0x157e>
f0102600:	68 26 47 10 f0       	push   $0xf0104726
f0102605:	68 f2 44 10 f0       	push   $0xf01044f2
f010260a:	68 dd 03 00 00       	push   $0x3dd
f010260f:	68 cc 44 10 f0       	push   $0xf01044cc
f0102614:	e8 ae da ff ff       	call   f01000c7 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102619:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102620:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102623:	89 f0                	mov    %esi,%eax
f0102625:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f010262b:	c1 f8 03             	sar    $0x3,%eax
f010262e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102631:	89 c2                	mov    %eax,%edx
f0102633:	c1 ea 0c             	shr    $0xc,%edx
f0102636:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f010263c:	72 12                	jb     f0102650 <mem_init+0x15b5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010263e:	50                   	push   %eax
f010263f:	68 44 3d 10 f0       	push   $0xf0103d44
f0102644:	6a 52                	push   $0x52
f0102646:	68 d8 44 10 f0       	push   $0xf01044d8
f010264b:	e8 77 da ff ff       	call   f01000c7 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102650:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102657:	03 03 03 
f010265a:	74 19                	je     f0102675 <mem_init+0x15da>
f010265c:	68 74 44 10 f0       	push   $0xf0104474
f0102661:	68 f2 44 10 f0       	push   $0xf01044f2
f0102666:	68 df 03 00 00       	push   $0x3df
f010266b:	68 cc 44 10 f0       	push   $0xf01044cc
f0102670:	e8 52 da ff ff       	call   f01000c7 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102675:	83 ec 08             	sub    $0x8,%esp
f0102678:	68 00 10 00 00       	push   $0x1000
f010267d:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102683:	e8 47 e9 ff ff       	call   f0100fcf <page_remove>
	assert(pp2->pp_ref == 0);
f0102688:	83 c4 10             	add    $0x10,%esp
f010268b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102690:	74 19                	je     f01026ab <mem_init+0x1610>
f0102692:	68 f4 46 10 f0       	push   $0xf01046f4
f0102697:	68 f2 44 10 f0       	push   $0xf01044f2
f010269c:	68 e1 03 00 00       	push   $0x3e1
f01026a1:	68 cc 44 10 f0       	push   $0xf01044cc
f01026a6:	e8 1c da ff ff       	call   f01000c7 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01026ab:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f01026b1:	8b 11                	mov    (%ecx),%edx
f01026b3:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01026b9:	89 d8                	mov    %ebx,%eax
f01026bb:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01026c1:	c1 f8 03             	sar    $0x3,%eax
f01026c4:	c1 e0 0c             	shl    $0xc,%eax
f01026c7:	39 c2                	cmp    %eax,%edx
f01026c9:	74 19                	je     f01026e4 <mem_init+0x1649>
f01026cb:	68 b8 3f 10 f0       	push   $0xf0103fb8
f01026d0:	68 f2 44 10 f0       	push   $0xf01044f2
f01026d5:	68 e4 03 00 00       	push   $0x3e4
f01026da:	68 cc 44 10 f0       	push   $0xf01044cc
f01026df:	e8 e3 d9 ff ff       	call   f01000c7 <_panic>
	kern_pgdir[0] = 0;
f01026e4:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01026ea:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01026ef:	74 19                	je     f010270a <mem_init+0x166f>
f01026f1:	68 ab 46 10 f0       	push   $0xf01046ab
f01026f6:	68 f2 44 10 f0       	push   $0xf01044f2
f01026fb:	68 e6 03 00 00       	push   $0x3e6
f0102700:	68 cc 44 10 f0       	push   $0xf01044cc
f0102705:	e8 bd d9 ff ff       	call   f01000c7 <_panic>
	pp0->pp_ref = 0;
f010270a:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102710:	83 ec 0c             	sub    $0xc,%esp
f0102713:	53                   	push   %ebx
f0102714:	e8 b8 e6 ff ff       	call   f0100dd1 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102719:	c7 04 24 a0 44 10 f0 	movl   $0xf01044a0,(%esp)
f0102720:	e8 7d 00 00 00       	call   f01027a2 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102725:	83 c4 10             	add    $0x10,%esp
f0102728:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010272b:	5b                   	pop    %ebx
f010272c:	5e                   	pop    %esi
f010272d:	5f                   	pop    %edi
f010272e:	5d                   	pop    %ebp
f010272f:	c3                   	ret    

f0102730 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102730:	55                   	push   %ebp
f0102731:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102733:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102736:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102739:	5d                   	pop    %ebp
f010273a:	c3                   	ret    

f010273b <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010273b:	55                   	push   %ebp
f010273c:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010273e:	ba 70 00 00 00       	mov    $0x70,%edx
f0102743:	8b 45 08             	mov    0x8(%ebp),%eax
f0102746:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102747:	ba 71 00 00 00       	mov    $0x71,%edx
f010274c:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f010274d:	0f b6 c0             	movzbl %al,%eax
}
f0102750:	5d                   	pop    %ebp
f0102751:	c3                   	ret    

f0102752 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102752:	55                   	push   %ebp
f0102753:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102755:	ba 70 00 00 00       	mov    $0x70,%edx
f010275a:	8b 45 08             	mov    0x8(%ebp),%eax
f010275d:	ee                   	out    %al,(%dx)
f010275e:	ba 71 00 00 00       	mov    $0x71,%edx
f0102763:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102766:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102767:	5d                   	pop    %ebp
f0102768:	c3                   	ret    

f0102769 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102769:	55                   	push   %ebp
f010276a:	89 e5                	mov    %esp,%ebp
f010276c:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010276f:	ff 75 08             	pushl  0x8(%ebp)
f0102772:	e8 b7 de ff ff       	call   f010062e <cputchar>
	*cnt++;
}
f0102777:	83 c4 10             	add    $0x10,%esp
f010277a:	c9                   	leave  
f010277b:	c3                   	ret    

f010277c <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010277c:	55                   	push   %ebp
f010277d:	89 e5                	mov    %esp,%ebp
f010277f:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102782:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102789:	ff 75 0c             	pushl  0xc(%ebp)
f010278c:	ff 75 08             	pushl  0x8(%ebp)
f010278f:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102792:	50                   	push   %eax
f0102793:	68 69 27 10 f0       	push   $0xf0102769
f0102798:	e8 29 04 00 00       	call   f0102bc6 <vprintfmt>
	return cnt;
}
f010279d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01027a0:	c9                   	leave  
f01027a1:	c3                   	ret    

f01027a2 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01027a2:	55                   	push   %ebp
f01027a3:	89 e5                	mov    %esp,%ebp
f01027a5:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01027a8:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01027ab:	50                   	push   %eax
f01027ac:	ff 75 08             	pushl  0x8(%ebp)
f01027af:	e8 c8 ff ff ff       	call   f010277c <vcprintf>
	va_end(ap);

	return cnt;
}
f01027b4:	c9                   	leave  
f01027b5:	c3                   	ret    

f01027b6 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01027b6:	55                   	push   %ebp
f01027b7:	89 e5                	mov    %esp,%ebp
f01027b9:	57                   	push   %edi
f01027ba:	56                   	push   %esi
f01027bb:	53                   	push   %ebx
f01027bc:	83 ec 14             	sub    $0x14,%esp
f01027bf:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01027c2:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01027c5:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01027c8:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01027cb:	8b 1a                	mov    (%edx),%ebx
f01027cd:	8b 01                	mov    (%ecx),%eax
f01027cf:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01027d2:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01027d9:	eb 7f                	jmp    f010285a <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01027db:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01027de:	01 d8                	add    %ebx,%eax
f01027e0:	89 c6                	mov    %eax,%esi
f01027e2:	c1 ee 1f             	shr    $0x1f,%esi
f01027e5:	01 c6                	add    %eax,%esi
f01027e7:	d1 fe                	sar    %esi
f01027e9:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01027ec:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01027ef:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01027f2:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01027f4:	eb 03                	jmp    f01027f9 <stab_binsearch+0x43>
			m--;
f01027f6:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01027f9:	39 c3                	cmp    %eax,%ebx
f01027fb:	7f 0d                	jg     f010280a <stab_binsearch+0x54>
f01027fd:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102801:	83 ea 0c             	sub    $0xc,%edx
f0102804:	39 f9                	cmp    %edi,%ecx
f0102806:	75 ee                	jne    f01027f6 <stab_binsearch+0x40>
f0102808:	eb 05                	jmp    f010280f <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010280a:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f010280d:	eb 4b                	jmp    f010285a <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010280f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102812:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102815:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102819:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010281c:	76 11                	jbe    f010282f <stab_binsearch+0x79>
			*region_left = m;
f010281e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0102821:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0102823:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102826:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010282d:	eb 2b                	jmp    f010285a <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010282f:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102832:	73 14                	jae    f0102848 <stab_binsearch+0x92>
			*region_right = m - 1;
f0102834:	83 e8 01             	sub    $0x1,%eax
f0102837:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010283a:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010283d:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010283f:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102846:	eb 12                	jmp    f010285a <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102848:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010284b:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f010284d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0102851:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102853:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010285a:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010285d:	0f 8e 78 ff ff ff    	jle    f01027db <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102863:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0102867:	75 0f                	jne    f0102878 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0102869:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010286c:	8b 00                	mov    (%eax),%eax
f010286e:	83 e8 01             	sub    $0x1,%eax
f0102871:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102874:	89 06                	mov    %eax,(%esi)
f0102876:	eb 2c                	jmp    f01028a4 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102878:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010287b:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010287d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102880:	8b 0e                	mov    (%esi),%ecx
f0102882:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102885:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0102888:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010288b:	eb 03                	jmp    f0102890 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010288d:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102890:	39 c8                	cmp    %ecx,%eax
f0102892:	7e 0b                	jle    f010289f <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0102894:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0102898:	83 ea 0c             	sub    $0xc,%edx
f010289b:	39 df                	cmp    %ebx,%edi
f010289d:	75 ee                	jne    f010288d <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f010289f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01028a2:	89 06                	mov    %eax,(%esi)
	}
}
f01028a4:	83 c4 14             	add    $0x14,%esp
f01028a7:	5b                   	pop    %ebx
f01028a8:	5e                   	pop    %esi
f01028a9:	5f                   	pop    %edi
f01028aa:	5d                   	pop    %ebp
f01028ab:	c3                   	ret    

f01028ac <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01028ac:	55                   	push   %ebp
f01028ad:	89 e5                	mov    %esp,%ebp
f01028af:	57                   	push   %edi
f01028b0:	56                   	push   %esi
f01028b1:	53                   	push   %ebx
f01028b2:	83 ec 3c             	sub    $0x3c,%esp
f01028b5:	8b 75 08             	mov    0x8(%ebp),%esi
f01028b8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01028bb:	c7 03 af 47 10 f0    	movl   $0xf01047af,(%ebx)
	info->eip_line = 0;
f01028c1:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01028c8:	c7 43 08 af 47 10 f0 	movl   $0xf01047af,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01028cf:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01028d6:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01028d9:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01028e0:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01028e6:	76 11                	jbe    f01028f9 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01028e8:	b8 d9 c1 10 f0       	mov    $0xf010c1d9,%eax
f01028ed:	3d 35 a4 10 f0       	cmp    $0xf010a435,%eax
f01028f2:	77 19                	ja     f010290d <debuginfo_eip+0x61>
f01028f4:	e9 c2 01 00 00       	jmp    f0102abb <debuginfo_eip+0x20f>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01028f9:	83 ec 04             	sub    $0x4,%esp
f01028fc:	68 b9 47 10 f0       	push   $0xf01047b9
f0102901:	6a 7f                	push   $0x7f
f0102903:	68 c6 47 10 f0       	push   $0xf01047c6
f0102908:	e8 ba d7 ff ff       	call   f01000c7 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010290d:	80 3d d8 c1 10 f0 00 	cmpb   $0x0,0xf010c1d8
f0102914:	0f 85 a8 01 00 00    	jne    f0102ac2 <debuginfo_eip+0x216>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010291a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102921:	b8 34 a4 10 f0       	mov    $0xf010a434,%eax
f0102926:	2d 10 4a 10 f0       	sub    $0xf0104a10,%eax
f010292b:	c1 f8 02             	sar    $0x2,%eax
f010292e:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102934:	83 e8 01             	sub    $0x1,%eax
f0102937:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010293a:	83 ec 08             	sub    $0x8,%esp
f010293d:	56                   	push   %esi
f010293e:	6a 64                	push   $0x64
f0102940:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102943:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102946:	b8 10 4a 10 f0       	mov    $0xf0104a10,%eax
f010294b:	e8 66 fe ff ff       	call   f01027b6 <stab_binsearch>
	if (lfile == 0)
f0102950:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102953:	83 c4 10             	add    $0x10,%esp
f0102956:	85 c0                	test   %eax,%eax
f0102958:	0f 84 6b 01 00 00    	je     f0102ac9 <debuginfo_eip+0x21d>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010295e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102961:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102964:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102967:	83 ec 08             	sub    $0x8,%esp
f010296a:	56                   	push   %esi
f010296b:	6a 24                	push   $0x24
f010296d:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102970:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102973:	b8 10 4a 10 f0       	mov    $0xf0104a10,%eax
f0102978:	e8 39 fe ff ff       	call   f01027b6 <stab_binsearch>

	if (lfun <= rfun) {
f010297d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102980:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102983:	83 c4 10             	add    $0x10,%esp
f0102986:	39 d0                	cmp    %edx,%eax
f0102988:	7f 40                	jg     f01029ca <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010298a:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f010298d:	c1 e1 02             	shl    $0x2,%ecx
f0102990:	8d b9 10 4a 10 f0    	lea    -0xfefb5f0(%ecx),%edi
f0102996:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0102999:	8b b9 10 4a 10 f0    	mov    -0xfefb5f0(%ecx),%edi
f010299f:	b9 d9 c1 10 f0       	mov    $0xf010c1d9,%ecx
f01029a4:	81 e9 35 a4 10 f0    	sub    $0xf010a435,%ecx
f01029aa:	39 cf                	cmp    %ecx,%edi
f01029ac:	73 09                	jae    f01029b7 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01029ae:	81 c7 35 a4 10 f0    	add    $0xf010a435,%edi
f01029b4:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01029b7:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01029ba:	8b 4f 08             	mov    0x8(%edi),%ecx
f01029bd:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01029c0:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01029c2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01029c5:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01029c8:	eb 0f                	jmp    f01029d9 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01029ca:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01029cd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01029d0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01029d3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01029d6:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01029d9:	83 ec 08             	sub    $0x8,%esp
f01029dc:	6a 3a                	push   $0x3a
f01029de:	ff 73 08             	pushl  0x8(%ebx)
f01029e1:	e8 50 09 00 00       	call   f0103336 <strfind>
f01029e6:	2b 43 08             	sub    0x8(%ebx),%eax
f01029e9:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

    stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01029ec:	83 c4 08             	add    $0x8,%esp
f01029ef:	56                   	push   %esi
f01029f0:	6a 44                	push   $0x44
f01029f2:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01029f5:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01029f8:	b8 10 4a 10 f0       	mov    $0xf0104a10,%eax
f01029fd:	e8 b4 fd ff ff       	call   f01027b6 <stab_binsearch>
    if (lline <= rline) {
f0102a02:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a05:	83 c4 10             	add    $0x10,%esp
f0102a08:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0102a0b:	7f 10                	jg     f0102a1d <debuginfo_eip+0x171>
        info->eip_line = stabs[lline].n_desc;
f0102a0d:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102a10:	0f b7 04 85 16 4a 10 	movzwl -0xfefb5ea(,%eax,4),%eax
f0102a17:	f0 
f0102a18:	89 43 04             	mov    %eax,0x4(%ebx)
f0102a1b:	eb 10                	jmp    f0102a2d <debuginfo_eip+0x181>
    }
    else {
        cprintf("line not find\n");
f0102a1d:	83 ec 0c             	sub    $0xc,%esp
f0102a20:	68 d4 47 10 f0       	push   $0xf01047d4
f0102a25:	e8 78 fd ff ff       	call   f01027a2 <cprintf>
f0102a2a:	83 c4 10             	add    $0x10,%esp
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102a2d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102a30:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102a33:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102a36:	8d 04 85 10 4a 10 f0 	lea    -0xfefb5f0(,%eax,4),%eax
f0102a3d:	eb 06                	jmp    f0102a45 <debuginfo_eip+0x199>
f0102a3f:	83 ea 01             	sub    $0x1,%edx
f0102a42:	83 e8 0c             	sub    $0xc,%eax
f0102a45:	39 d7                	cmp    %edx,%edi
f0102a47:	7f 34                	jg     f0102a7d <debuginfo_eip+0x1d1>
	       && stabs[lline].n_type != N_SOL
f0102a49:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0102a4d:	80 f9 84             	cmp    $0x84,%cl
f0102a50:	74 0b                	je     f0102a5d <debuginfo_eip+0x1b1>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102a52:	80 f9 64             	cmp    $0x64,%cl
f0102a55:	75 e8                	jne    f0102a3f <debuginfo_eip+0x193>
f0102a57:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102a5b:	74 e2                	je     f0102a3f <debuginfo_eip+0x193>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102a5d:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102a60:	8b 14 85 10 4a 10 f0 	mov    -0xfefb5f0(,%eax,4),%edx
f0102a67:	b8 d9 c1 10 f0       	mov    $0xf010c1d9,%eax
f0102a6c:	2d 35 a4 10 f0       	sub    $0xf010a435,%eax
f0102a71:	39 c2                	cmp    %eax,%edx
f0102a73:	73 08                	jae    f0102a7d <debuginfo_eip+0x1d1>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102a75:	81 c2 35 a4 10 f0    	add    $0xf010a435,%edx
f0102a7b:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102a7d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102a80:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a83:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102a88:	39 f2                	cmp    %esi,%edx
f0102a8a:	7d 49                	jge    f0102ad5 <debuginfo_eip+0x229>
		for (lline = lfun + 1;
f0102a8c:	83 c2 01             	add    $0x1,%edx
f0102a8f:	89 d0                	mov    %edx,%eax
f0102a91:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102a94:	8d 14 95 10 4a 10 f0 	lea    -0xfefb5f0(,%edx,4),%edx
f0102a9b:	eb 04                	jmp    f0102aa1 <debuginfo_eip+0x1f5>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102a9d:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102aa1:	39 c6                	cmp    %eax,%esi
f0102aa3:	7e 2b                	jle    f0102ad0 <debuginfo_eip+0x224>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102aa5:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102aa9:	83 c0 01             	add    $0x1,%eax
f0102aac:	83 c2 0c             	add    $0xc,%edx
f0102aaf:	80 f9 a0             	cmp    $0xa0,%cl
f0102ab2:	74 e9                	je     f0102a9d <debuginfo_eip+0x1f1>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102ab4:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ab9:	eb 1a                	jmp    f0102ad5 <debuginfo_eip+0x229>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102abb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102ac0:	eb 13                	jmp    f0102ad5 <debuginfo_eip+0x229>
f0102ac2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102ac7:	eb 0c                	jmp    f0102ad5 <debuginfo_eip+0x229>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102ac9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102ace:	eb 05                	jmp    f0102ad5 <debuginfo_eip+0x229>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102ad0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102ad5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ad8:	5b                   	pop    %ebx
f0102ad9:	5e                   	pop    %esi
f0102ada:	5f                   	pop    %edi
f0102adb:	5d                   	pop    %ebp
f0102adc:	c3                   	ret    

f0102add <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102add:	55                   	push   %ebp
f0102ade:	89 e5                	mov    %esp,%ebp
f0102ae0:	57                   	push   %edi
f0102ae1:	56                   	push   %esi
f0102ae2:	53                   	push   %ebx
f0102ae3:	83 ec 1c             	sub    $0x1c,%esp
f0102ae6:	89 c7                	mov    %eax,%edi
f0102ae8:	89 d6                	mov    %edx,%esi
f0102aea:	8b 45 08             	mov    0x8(%ebp),%eax
f0102aed:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102af0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102af3:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102af6:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102af9:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102afe:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102b01:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102b04:	39 d3                	cmp    %edx,%ebx
f0102b06:	72 05                	jb     f0102b0d <printnum+0x30>
f0102b08:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102b0b:	77 45                	ja     f0102b52 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102b0d:	83 ec 0c             	sub    $0xc,%esp
f0102b10:	ff 75 18             	pushl  0x18(%ebp)
f0102b13:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b16:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102b19:	53                   	push   %ebx
f0102b1a:	ff 75 10             	pushl  0x10(%ebp)
f0102b1d:	83 ec 08             	sub    $0x8,%esp
f0102b20:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102b23:	ff 75 e0             	pushl  -0x20(%ebp)
f0102b26:	ff 75 dc             	pushl  -0x24(%ebp)
f0102b29:	ff 75 d8             	pushl  -0x28(%ebp)
f0102b2c:	e8 2f 0a 00 00       	call   f0103560 <__udivdi3>
f0102b31:	83 c4 18             	add    $0x18,%esp
f0102b34:	52                   	push   %edx
f0102b35:	50                   	push   %eax
f0102b36:	89 f2                	mov    %esi,%edx
f0102b38:	89 f8                	mov    %edi,%eax
f0102b3a:	e8 9e ff ff ff       	call   f0102add <printnum>
f0102b3f:	83 c4 20             	add    $0x20,%esp
f0102b42:	eb 18                	jmp    f0102b5c <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102b44:	83 ec 08             	sub    $0x8,%esp
f0102b47:	56                   	push   %esi
f0102b48:	ff 75 18             	pushl  0x18(%ebp)
f0102b4b:	ff d7                	call   *%edi
f0102b4d:	83 c4 10             	add    $0x10,%esp
f0102b50:	eb 03                	jmp    f0102b55 <printnum+0x78>
f0102b52:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102b55:	83 eb 01             	sub    $0x1,%ebx
f0102b58:	85 db                	test   %ebx,%ebx
f0102b5a:	7f e8                	jg     f0102b44 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102b5c:	83 ec 08             	sub    $0x8,%esp
f0102b5f:	56                   	push   %esi
f0102b60:	83 ec 04             	sub    $0x4,%esp
f0102b63:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102b66:	ff 75 e0             	pushl  -0x20(%ebp)
f0102b69:	ff 75 dc             	pushl  -0x24(%ebp)
f0102b6c:	ff 75 d8             	pushl  -0x28(%ebp)
f0102b6f:	e8 1c 0b 00 00       	call   f0103690 <__umoddi3>
f0102b74:	83 c4 14             	add    $0x14,%esp
f0102b77:	0f be 80 e3 47 10 f0 	movsbl -0xfefb81d(%eax),%eax
f0102b7e:	50                   	push   %eax
f0102b7f:	ff d7                	call   *%edi
}
f0102b81:	83 c4 10             	add    $0x10,%esp
f0102b84:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b87:	5b                   	pop    %ebx
f0102b88:	5e                   	pop    %esi
f0102b89:	5f                   	pop    %edi
f0102b8a:	5d                   	pop    %ebp
f0102b8b:	c3                   	ret    

f0102b8c <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102b8c:	55                   	push   %ebp
f0102b8d:	89 e5                	mov    %esp,%ebp
f0102b8f:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102b92:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102b96:	8b 10                	mov    (%eax),%edx
f0102b98:	3b 50 04             	cmp    0x4(%eax),%edx
f0102b9b:	73 0a                	jae    f0102ba7 <sprintputch+0x1b>
		*b->buf++ = ch;
f0102b9d:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102ba0:	89 08                	mov    %ecx,(%eax)
f0102ba2:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ba5:	88 02                	mov    %al,(%edx)
}
f0102ba7:	5d                   	pop    %ebp
f0102ba8:	c3                   	ret    

f0102ba9 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102ba9:	55                   	push   %ebp
f0102baa:	89 e5                	mov    %esp,%ebp
f0102bac:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102baf:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102bb2:	50                   	push   %eax
f0102bb3:	ff 75 10             	pushl  0x10(%ebp)
f0102bb6:	ff 75 0c             	pushl  0xc(%ebp)
f0102bb9:	ff 75 08             	pushl  0x8(%ebp)
f0102bbc:	e8 05 00 00 00       	call   f0102bc6 <vprintfmt>
	va_end(ap);
}
f0102bc1:	83 c4 10             	add    $0x10,%esp
f0102bc4:	c9                   	leave  
f0102bc5:	c3                   	ret    

f0102bc6 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102bc6:	55                   	push   %ebp
f0102bc7:	89 e5                	mov    %esp,%ebp
f0102bc9:	57                   	push   %edi
f0102bca:	56                   	push   %esi
f0102bcb:	53                   	push   %ebx
f0102bcc:	83 ec 2c             	sub    $0x2c,%esp
f0102bcf:	8b 75 08             	mov    0x8(%ebp),%esi
f0102bd2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102bd5:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102bd8:	eb 12                	jmp    f0102bec <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102bda:	85 c0                	test   %eax,%eax
f0102bdc:	0f 84 a9 04 00 00    	je     f010308b <vprintfmt+0x4c5>
				return;
			putch(ch, putdat);
f0102be2:	83 ec 08             	sub    $0x8,%esp
f0102be5:	53                   	push   %ebx
f0102be6:	50                   	push   %eax
f0102be7:	ff d6                	call   *%esi
f0102be9:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102bec:	83 c7 01             	add    $0x1,%edi
f0102bef:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102bf3:	83 f8 25             	cmp    $0x25,%eax
f0102bf6:	75 e2                	jne    f0102bda <vprintfmt+0x14>
f0102bf8:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102bfc:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102c03:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102c0a:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102c11:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102c16:	eb 07                	jmp    f0102c1f <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c18:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102c1b:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c1f:	8d 47 01             	lea    0x1(%edi),%eax
f0102c22:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102c25:	0f b6 07             	movzbl (%edi),%eax
f0102c28:	0f b6 d0             	movzbl %al,%edx
f0102c2b:	83 e8 23             	sub    $0x23,%eax
f0102c2e:	3c 55                	cmp    $0x55,%al
f0102c30:	0f 87 3a 04 00 00    	ja     f0103070 <vprintfmt+0x4aa>
f0102c36:	0f b6 c0             	movzbl %al,%eax
f0102c39:	ff 24 85 80 48 10 f0 	jmp    *-0xfefb780(,%eax,4)
f0102c40:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102c43:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102c47:	eb d6                	jmp    f0102c1f <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c49:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c4c:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c51:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102c54:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102c57:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0102c5b:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0102c5e:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0102c61:	83 f9 09             	cmp    $0x9,%ecx
f0102c64:	77 3f                	ja     f0102ca5 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102c66:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102c69:	eb e9                	jmp    f0102c54 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102c6b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c6e:	8b 00                	mov    (%eax),%eax
f0102c70:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102c73:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c76:	8d 40 04             	lea    0x4(%eax),%eax
f0102c79:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c7c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102c7f:	eb 2a                	jmp    f0102cab <vprintfmt+0xe5>
f0102c81:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102c84:	85 c0                	test   %eax,%eax
f0102c86:	ba 00 00 00 00       	mov    $0x0,%edx
f0102c8b:	0f 49 d0             	cmovns %eax,%edx
f0102c8e:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c91:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c94:	eb 89                	jmp    f0102c1f <vprintfmt+0x59>
f0102c96:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102c99:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102ca0:	e9 7a ff ff ff       	jmp    f0102c1f <vprintfmt+0x59>
f0102ca5:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102ca8:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102cab:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102caf:	0f 89 6a ff ff ff    	jns    f0102c1f <vprintfmt+0x59>
				width = precision, precision = -1;
f0102cb5:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102cb8:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102cbb:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102cc2:	e9 58 ff ff ff       	jmp    f0102c1f <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102cc7:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cca:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102ccd:	e9 4d ff ff ff       	jmp    f0102c1f <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102cd2:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cd5:	8d 78 04             	lea    0x4(%eax),%edi
f0102cd8:	83 ec 08             	sub    $0x8,%esp
f0102cdb:	53                   	push   %ebx
f0102cdc:	ff 30                	pushl  (%eax)
f0102cde:	ff d6                	call   *%esi
			break;
f0102ce0:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102ce3:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ce6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102ce9:	e9 fe fe ff ff       	jmp    f0102bec <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102cee:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cf1:	8d 78 04             	lea    0x4(%eax),%edi
f0102cf4:	8b 00                	mov    (%eax),%eax
f0102cf6:	99                   	cltd   
f0102cf7:	31 d0                	xor    %edx,%eax
f0102cf9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102cfb:	83 f8 07             	cmp    $0x7,%eax
f0102cfe:	7f 0b                	jg     f0102d0b <vprintfmt+0x145>
f0102d00:	8b 14 85 e0 49 10 f0 	mov    -0xfefb620(,%eax,4),%edx
f0102d07:	85 d2                	test   %edx,%edx
f0102d09:	75 1b                	jne    f0102d26 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0102d0b:	50                   	push   %eax
f0102d0c:	68 fb 47 10 f0       	push   $0xf01047fb
f0102d11:	53                   	push   %ebx
f0102d12:	56                   	push   %esi
f0102d13:	e8 91 fe ff ff       	call   f0102ba9 <printfmt>
f0102d18:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102d1b:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d1e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102d21:	e9 c6 fe ff ff       	jmp    f0102bec <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102d26:	52                   	push   %edx
f0102d27:	68 04 45 10 f0       	push   $0xf0104504
f0102d2c:	53                   	push   %ebx
f0102d2d:	56                   	push   %esi
f0102d2e:	e8 76 fe ff ff       	call   f0102ba9 <printfmt>
f0102d33:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102d36:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d39:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102d3c:	e9 ab fe ff ff       	jmp    f0102bec <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102d41:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d44:	83 c0 04             	add    $0x4,%eax
f0102d47:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102d4a:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d4d:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102d4f:	85 ff                	test   %edi,%edi
f0102d51:	b8 f4 47 10 f0       	mov    $0xf01047f4,%eax
f0102d56:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102d59:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102d5d:	0f 8e 94 00 00 00    	jle    f0102df7 <vprintfmt+0x231>
f0102d63:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102d67:	0f 84 98 00 00 00    	je     f0102e05 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d6d:	83 ec 08             	sub    $0x8,%esp
f0102d70:	ff 75 d0             	pushl  -0x30(%ebp)
f0102d73:	57                   	push   %edi
f0102d74:	e8 73 04 00 00       	call   f01031ec <strnlen>
f0102d79:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102d7c:	29 c1                	sub    %eax,%ecx
f0102d7e:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0102d81:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102d84:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102d88:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102d8b:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102d8e:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d90:	eb 0f                	jmp    f0102da1 <vprintfmt+0x1db>
					putch(padc, putdat);
f0102d92:	83 ec 08             	sub    $0x8,%esp
f0102d95:	53                   	push   %ebx
f0102d96:	ff 75 e0             	pushl  -0x20(%ebp)
f0102d99:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d9b:	83 ef 01             	sub    $0x1,%edi
f0102d9e:	83 c4 10             	add    $0x10,%esp
f0102da1:	85 ff                	test   %edi,%edi
f0102da3:	7f ed                	jg     f0102d92 <vprintfmt+0x1cc>
f0102da5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102da8:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102dab:	85 c9                	test   %ecx,%ecx
f0102dad:	b8 00 00 00 00       	mov    $0x0,%eax
f0102db2:	0f 49 c1             	cmovns %ecx,%eax
f0102db5:	29 c1                	sub    %eax,%ecx
f0102db7:	89 75 08             	mov    %esi,0x8(%ebp)
f0102dba:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102dbd:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102dc0:	89 cb                	mov    %ecx,%ebx
f0102dc2:	eb 4d                	jmp    f0102e11 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102dc4:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102dc8:	74 1b                	je     f0102de5 <vprintfmt+0x21f>
f0102dca:	0f be c0             	movsbl %al,%eax
f0102dcd:	83 e8 20             	sub    $0x20,%eax
f0102dd0:	83 f8 5e             	cmp    $0x5e,%eax
f0102dd3:	76 10                	jbe    f0102de5 <vprintfmt+0x21f>
					putch('?', putdat);
f0102dd5:	83 ec 08             	sub    $0x8,%esp
f0102dd8:	ff 75 0c             	pushl  0xc(%ebp)
f0102ddb:	6a 3f                	push   $0x3f
f0102ddd:	ff 55 08             	call   *0x8(%ebp)
f0102de0:	83 c4 10             	add    $0x10,%esp
f0102de3:	eb 0d                	jmp    f0102df2 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0102de5:	83 ec 08             	sub    $0x8,%esp
f0102de8:	ff 75 0c             	pushl  0xc(%ebp)
f0102deb:	52                   	push   %edx
f0102dec:	ff 55 08             	call   *0x8(%ebp)
f0102def:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102df2:	83 eb 01             	sub    $0x1,%ebx
f0102df5:	eb 1a                	jmp    f0102e11 <vprintfmt+0x24b>
f0102df7:	89 75 08             	mov    %esi,0x8(%ebp)
f0102dfa:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102dfd:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102e00:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102e03:	eb 0c                	jmp    f0102e11 <vprintfmt+0x24b>
f0102e05:	89 75 08             	mov    %esi,0x8(%ebp)
f0102e08:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102e0b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102e0e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102e11:	83 c7 01             	add    $0x1,%edi
f0102e14:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102e18:	0f be d0             	movsbl %al,%edx
f0102e1b:	85 d2                	test   %edx,%edx
f0102e1d:	74 23                	je     f0102e42 <vprintfmt+0x27c>
f0102e1f:	85 f6                	test   %esi,%esi
f0102e21:	78 a1                	js     f0102dc4 <vprintfmt+0x1fe>
f0102e23:	83 ee 01             	sub    $0x1,%esi
f0102e26:	79 9c                	jns    f0102dc4 <vprintfmt+0x1fe>
f0102e28:	89 df                	mov    %ebx,%edi
f0102e2a:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e2d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102e30:	eb 18                	jmp    f0102e4a <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102e32:	83 ec 08             	sub    $0x8,%esp
f0102e35:	53                   	push   %ebx
f0102e36:	6a 20                	push   $0x20
f0102e38:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102e3a:	83 ef 01             	sub    $0x1,%edi
f0102e3d:	83 c4 10             	add    $0x10,%esp
f0102e40:	eb 08                	jmp    f0102e4a <vprintfmt+0x284>
f0102e42:	89 df                	mov    %ebx,%edi
f0102e44:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e47:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102e4a:	85 ff                	test   %edi,%edi
f0102e4c:	7f e4                	jg     f0102e32 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102e4e:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102e51:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e54:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102e57:	e9 90 fd ff ff       	jmp    f0102bec <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102e5c:	83 f9 01             	cmp    $0x1,%ecx
f0102e5f:	7e 19                	jle    f0102e7a <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0102e61:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e64:	8b 50 04             	mov    0x4(%eax),%edx
f0102e67:	8b 00                	mov    (%eax),%eax
f0102e69:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e6c:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102e6f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e72:	8d 40 08             	lea    0x8(%eax),%eax
f0102e75:	89 45 14             	mov    %eax,0x14(%ebp)
f0102e78:	eb 38                	jmp    f0102eb2 <vprintfmt+0x2ec>
	else if (lflag)
f0102e7a:	85 c9                	test   %ecx,%ecx
f0102e7c:	74 1b                	je     f0102e99 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0102e7e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e81:	8b 00                	mov    (%eax),%eax
f0102e83:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e86:	89 c1                	mov    %eax,%ecx
f0102e88:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e8b:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102e8e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e91:	8d 40 04             	lea    0x4(%eax),%eax
f0102e94:	89 45 14             	mov    %eax,0x14(%ebp)
f0102e97:	eb 19                	jmp    f0102eb2 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0102e99:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e9c:	8b 00                	mov    (%eax),%eax
f0102e9e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102ea1:	89 c1                	mov    %eax,%ecx
f0102ea3:	c1 f9 1f             	sar    $0x1f,%ecx
f0102ea6:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102ea9:	8b 45 14             	mov    0x14(%ebp),%eax
f0102eac:	8d 40 04             	lea    0x4(%eax),%eax
f0102eaf:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102eb2:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102eb5:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102eb8:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102ebd:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102ec1:	0f 89 75 01 00 00    	jns    f010303c <vprintfmt+0x476>
				putch('-', putdat);
f0102ec7:	83 ec 08             	sub    $0x8,%esp
f0102eca:	53                   	push   %ebx
f0102ecb:	6a 2d                	push   $0x2d
f0102ecd:	ff d6                	call   *%esi
				num = -(long long) num;
f0102ecf:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102ed2:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102ed5:	f7 da                	neg    %edx
f0102ed7:	83 d1 00             	adc    $0x0,%ecx
f0102eda:	f7 d9                	neg    %ecx
f0102edc:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102edf:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102ee4:	e9 53 01 00 00       	jmp    f010303c <vprintfmt+0x476>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102ee9:	83 f9 01             	cmp    $0x1,%ecx
f0102eec:	7e 18                	jle    f0102f06 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0102eee:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ef1:	8b 10                	mov    (%eax),%edx
f0102ef3:	8b 48 04             	mov    0x4(%eax),%ecx
f0102ef6:	8d 40 08             	lea    0x8(%eax),%eax
f0102ef9:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102efc:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102f01:	e9 36 01 00 00       	jmp    f010303c <vprintfmt+0x476>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102f06:	85 c9                	test   %ecx,%ecx
f0102f08:	74 1a                	je     f0102f24 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0102f0a:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f0d:	8b 10                	mov    (%eax),%edx
f0102f0f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102f14:	8d 40 04             	lea    0x4(%eax),%eax
f0102f17:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102f1a:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102f1f:	e9 18 01 00 00       	jmp    f010303c <vprintfmt+0x476>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102f24:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f27:	8b 10                	mov    (%eax),%edx
f0102f29:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102f2e:	8d 40 04             	lea    0x4(%eax),%eax
f0102f31:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102f34:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102f39:	e9 fe 00 00 00       	jmp    f010303c <vprintfmt+0x476>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102f3e:	83 f9 01             	cmp    $0x1,%ecx
f0102f41:	7e 19                	jle    f0102f5c <vprintfmt+0x396>
		return va_arg(*ap, long long);
f0102f43:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f46:	8b 50 04             	mov    0x4(%eax),%edx
f0102f49:	8b 00                	mov    (%eax),%eax
f0102f4b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102f4e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102f51:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f54:	8d 40 08             	lea    0x8(%eax),%eax
f0102f57:	89 45 14             	mov    %eax,0x14(%ebp)
f0102f5a:	eb 38                	jmp    f0102f94 <vprintfmt+0x3ce>
	else if (lflag)
f0102f5c:	85 c9                	test   %ecx,%ecx
f0102f5e:	74 1b                	je     f0102f7b <vprintfmt+0x3b5>
		return va_arg(*ap, long);
f0102f60:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f63:	8b 00                	mov    (%eax),%eax
f0102f65:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102f68:	89 c1                	mov    %eax,%ecx
f0102f6a:	c1 f9 1f             	sar    $0x1f,%ecx
f0102f6d:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102f70:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f73:	8d 40 04             	lea    0x4(%eax),%eax
f0102f76:	89 45 14             	mov    %eax,0x14(%ebp)
f0102f79:	eb 19                	jmp    f0102f94 <vprintfmt+0x3ce>
	else
		return va_arg(*ap, int);
f0102f7b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f7e:	8b 00                	mov    (%eax),%eax
f0102f80:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102f83:	89 c1                	mov    %eax,%ecx
f0102f85:	c1 f9 1f             	sar    $0x1f,%ecx
f0102f88:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102f8b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f8e:	8d 40 04             	lea    0x4(%eax),%eax
f0102f91:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
			goto number;

		// (unsigned) octal
		case 'o':
			num = getint(&ap, lflag);
f0102f94:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102f97:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 8;
f0102f9a:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;

		// (unsigned) octal
		case 'o':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102f9f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102fa3:	0f 89 93 00 00 00    	jns    f010303c <vprintfmt+0x476>
				putch('-', putdat);
f0102fa9:	83 ec 08             	sub    $0x8,%esp
f0102fac:	53                   	push   %ebx
f0102fad:	6a 2d                	push   $0x2d
f0102faf:	ff d6                	call   *%esi
				num = -(long long) num;
f0102fb1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102fb4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102fb7:	f7 da                	neg    %edx
f0102fb9:	83 d1 00             	adc    $0x0,%ecx
f0102fbc:	f7 d9                	neg    %ecx
f0102fbe:	83 c4 10             	add    $0x10,%esp
			}
			base = 8;
f0102fc1:	b8 08 00 00 00       	mov    $0x8,%eax
f0102fc6:	eb 74                	jmp    f010303c <vprintfmt+0x476>
			goto number;

		// pointer
		case 'p':
			putch('0', putdat);
f0102fc8:	83 ec 08             	sub    $0x8,%esp
f0102fcb:	53                   	push   %ebx
f0102fcc:	6a 30                	push   $0x30
f0102fce:	ff d6                	call   *%esi
			putch('x', putdat);
f0102fd0:	83 c4 08             	add    $0x8,%esp
f0102fd3:	53                   	push   %ebx
f0102fd4:	6a 78                	push   $0x78
f0102fd6:	ff d6                	call   *%esi
			num = (unsigned long long)
f0102fd8:	8b 45 14             	mov    0x14(%ebp),%eax
f0102fdb:	8b 10                	mov    (%eax),%edx
f0102fdd:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102fe2:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102fe5:	8d 40 04             	lea    0x4(%eax),%eax
f0102fe8:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0102feb:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0102ff0:	eb 4a                	jmp    f010303c <vprintfmt+0x476>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102ff2:	83 f9 01             	cmp    $0x1,%ecx
f0102ff5:	7e 15                	jle    f010300c <vprintfmt+0x446>
		return va_arg(*ap, unsigned long long);
f0102ff7:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ffa:	8b 10                	mov    (%eax),%edx
f0102ffc:	8b 48 04             	mov    0x4(%eax),%ecx
f0102fff:	8d 40 08             	lea    0x8(%eax),%eax
f0103002:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103005:	b8 10 00 00 00       	mov    $0x10,%eax
f010300a:	eb 30                	jmp    f010303c <vprintfmt+0x476>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f010300c:	85 c9                	test   %ecx,%ecx
f010300e:	74 17                	je     f0103027 <vprintfmt+0x461>
		return va_arg(*ap, unsigned long);
f0103010:	8b 45 14             	mov    0x14(%ebp),%eax
f0103013:	8b 10                	mov    (%eax),%edx
f0103015:	b9 00 00 00 00       	mov    $0x0,%ecx
f010301a:	8d 40 04             	lea    0x4(%eax),%eax
f010301d:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103020:	b8 10 00 00 00       	mov    $0x10,%eax
f0103025:	eb 15                	jmp    f010303c <vprintfmt+0x476>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0103027:	8b 45 14             	mov    0x14(%ebp),%eax
f010302a:	8b 10                	mov    (%eax),%edx
f010302c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103031:	8d 40 04             	lea    0x4(%eax),%eax
f0103034:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103037:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f010303c:	83 ec 0c             	sub    $0xc,%esp
f010303f:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103043:	57                   	push   %edi
f0103044:	ff 75 e0             	pushl  -0x20(%ebp)
f0103047:	50                   	push   %eax
f0103048:	51                   	push   %ecx
f0103049:	52                   	push   %edx
f010304a:	89 da                	mov    %ebx,%edx
f010304c:	89 f0                	mov    %esi,%eax
f010304e:	e8 8a fa ff ff       	call   f0102add <printnum>
			break;
f0103053:	83 c4 20             	add    $0x20,%esp
f0103056:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103059:	e9 8e fb ff ff       	jmp    f0102bec <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010305e:	83 ec 08             	sub    $0x8,%esp
f0103061:	53                   	push   %ebx
f0103062:	52                   	push   %edx
f0103063:	ff d6                	call   *%esi
			break;
f0103065:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103068:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010306b:	e9 7c fb ff ff       	jmp    f0102bec <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103070:	83 ec 08             	sub    $0x8,%esp
f0103073:	53                   	push   %ebx
f0103074:	6a 25                	push   $0x25
f0103076:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103078:	83 c4 10             	add    $0x10,%esp
f010307b:	eb 03                	jmp    f0103080 <vprintfmt+0x4ba>
f010307d:	83 ef 01             	sub    $0x1,%edi
f0103080:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103084:	75 f7                	jne    f010307d <vprintfmt+0x4b7>
f0103086:	e9 61 fb ff ff       	jmp    f0102bec <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f010308b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010308e:	5b                   	pop    %ebx
f010308f:	5e                   	pop    %esi
f0103090:	5f                   	pop    %edi
f0103091:	5d                   	pop    %ebp
f0103092:	c3                   	ret    

f0103093 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103093:	55                   	push   %ebp
f0103094:	89 e5                	mov    %esp,%ebp
f0103096:	83 ec 18             	sub    $0x18,%esp
f0103099:	8b 45 08             	mov    0x8(%ebp),%eax
f010309c:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010309f:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01030a2:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01030a6:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01030a9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01030b0:	85 c0                	test   %eax,%eax
f01030b2:	74 26                	je     f01030da <vsnprintf+0x47>
f01030b4:	85 d2                	test   %edx,%edx
f01030b6:	7e 22                	jle    f01030da <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01030b8:	ff 75 14             	pushl  0x14(%ebp)
f01030bb:	ff 75 10             	pushl  0x10(%ebp)
f01030be:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01030c1:	50                   	push   %eax
f01030c2:	68 8c 2b 10 f0       	push   $0xf0102b8c
f01030c7:	e8 fa fa ff ff       	call   f0102bc6 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01030cc:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01030cf:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01030d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01030d5:	83 c4 10             	add    $0x10,%esp
f01030d8:	eb 05                	jmp    f01030df <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01030da:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01030df:	c9                   	leave  
f01030e0:	c3                   	ret    

f01030e1 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01030e1:	55                   	push   %ebp
f01030e2:	89 e5                	mov    %esp,%ebp
f01030e4:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01030e7:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01030ea:	50                   	push   %eax
f01030eb:	ff 75 10             	pushl  0x10(%ebp)
f01030ee:	ff 75 0c             	pushl  0xc(%ebp)
f01030f1:	ff 75 08             	pushl  0x8(%ebp)
f01030f4:	e8 9a ff ff ff       	call   f0103093 <vsnprintf>
	va_end(ap);

	return rc;
}
f01030f9:	c9                   	leave  
f01030fa:	c3                   	ret    

f01030fb <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01030fb:	55                   	push   %ebp
f01030fc:	89 e5                	mov    %esp,%ebp
f01030fe:	57                   	push   %edi
f01030ff:	56                   	push   %esi
f0103100:	53                   	push   %ebx
f0103101:	83 ec 0c             	sub    $0xc,%esp
f0103104:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103107:	85 c0                	test   %eax,%eax
f0103109:	74 11                	je     f010311c <readline+0x21>
		cprintf("%s", prompt);
f010310b:	83 ec 08             	sub    $0x8,%esp
f010310e:	50                   	push   %eax
f010310f:	68 04 45 10 f0       	push   $0xf0104504
f0103114:	e8 89 f6 ff ff       	call   f01027a2 <cprintf>
f0103119:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010311c:	83 ec 0c             	sub    $0xc,%esp
f010311f:	6a 00                	push   $0x0
f0103121:	e8 29 d5 ff ff       	call   f010064f <iscons>
f0103126:	89 c7                	mov    %eax,%edi
f0103128:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010312b:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103130:	e8 09 d5 ff ff       	call   f010063e <getchar>
f0103135:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103137:	85 c0                	test   %eax,%eax
f0103139:	79 18                	jns    f0103153 <readline+0x58>
			cprintf("read error: %e\n", c);
f010313b:	83 ec 08             	sub    $0x8,%esp
f010313e:	50                   	push   %eax
f010313f:	68 00 4a 10 f0       	push   $0xf0104a00
f0103144:	e8 59 f6 ff ff       	call   f01027a2 <cprintf>
			return NULL;
f0103149:	83 c4 10             	add    $0x10,%esp
f010314c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103151:	eb 79                	jmp    f01031cc <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103153:	83 f8 08             	cmp    $0x8,%eax
f0103156:	0f 94 c2             	sete   %dl
f0103159:	83 f8 7f             	cmp    $0x7f,%eax
f010315c:	0f 94 c0             	sete   %al
f010315f:	08 c2                	or     %al,%dl
f0103161:	74 1a                	je     f010317d <readline+0x82>
f0103163:	85 f6                	test   %esi,%esi
f0103165:	7e 16                	jle    f010317d <readline+0x82>
			if (echoing)
f0103167:	85 ff                	test   %edi,%edi
f0103169:	74 0d                	je     f0103178 <readline+0x7d>
				cputchar('\b');
f010316b:	83 ec 0c             	sub    $0xc,%esp
f010316e:	6a 08                	push   $0x8
f0103170:	e8 b9 d4 ff ff       	call   f010062e <cputchar>
f0103175:	83 c4 10             	add    $0x10,%esp
			i--;
f0103178:	83 ee 01             	sub    $0x1,%esi
f010317b:	eb b3                	jmp    f0103130 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010317d:	83 fb 1f             	cmp    $0x1f,%ebx
f0103180:	7e 23                	jle    f01031a5 <readline+0xaa>
f0103182:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103188:	7f 1b                	jg     f01031a5 <readline+0xaa>
			if (echoing)
f010318a:	85 ff                	test   %edi,%edi
f010318c:	74 0c                	je     f010319a <readline+0x9f>
				cputchar(c);
f010318e:	83 ec 0c             	sub    $0xc,%esp
f0103191:	53                   	push   %ebx
f0103192:	e8 97 d4 ff ff       	call   f010062e <cputchar>
f0103197:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010319a:	88 9e 60 75 11 f0    	mov    %bl,-0xfee8aa0(%esi)
f01031a0:	8d 76 01             	lea    0x1(%esi),%esi
f01031a3:	eb 8b                	jmp    f0103130 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01031a5:	83 fb 0a             	cmp    $0xa,%ebx
f01031a8:	74 05                	je     f01031af <readline+0xb4>
f01031aa:	83 fb 0d             	cmp    $0xd,%ebx
f01031ad:	75 81                	jne    f0103130 <readline+0x35>
			if (echoing)
f01031af:	85 ff                	test   %edi,%edi
f01031b1:	74 0d                	je     f01031c0 <readline+0xc5>
				cputchar('\n');
f01031b3:	83 ec 0c             	sub    $0xc,%esp
f01031b6:	6a 0a                	push   $0xa
f01031b8:	e8 71 d4 ff ff       	call   f010062e <cputchar>
f01031bd:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01031c0:	c6 86 60 75 11 f0 00 	movb   $0x0,-0xfee8aa0(%esi)
			return buf;
f01031c7:	b8 60 75 11 f0       	mov    $0xf0117560,%eax
		}
	}
}
f01031cc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01031cf:	5b                   	pop    %ebx
f01031d0:	5e                   	pop    %esi
f01031d1:	5f                   	pop    %edi
f01031d2:	5d                   	pop    %ebp
f01031d3:	c3                   	ret    

f01031d4 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01031d4:	55                   	push   %ebp
f01031d5:	89 e5                	mov    %esp,%ebp
f01031d7:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01031da:	b8 00 00 00 00       	mov    $0x0,%eax
f01031df:	eb 03                	jmp    f01031e4 <strlen+0x10>
		n++;
f01031e1:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01031e4:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01031e8:	75 f7                	jne    f01031e1 <strlen+0xd>
		n++;
	return n;
}
f01031ea:	5d                   	pop    %ebp
f01031eb:	c3                   	ret    

f01031ec <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01031ec:	55                   	push   %ebp
f01031ed:	89 e5                	mov    %esp,%ebp
f01031ef:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01031f2:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01031f5:	ba 00 00 00 00       	mov    $0x0,%edx
f01031fa:	eb 03                	jmp    f01031ff <strnlen+0x13>
		n++;
f01031fc:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01031ff:	39 c2                	cmp    %eax,%edx
f0103201:	74 08                	je     f010320b <strnlen+0x1f>
f0103203:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103207:	75 f3                	jne    f01031fc <strnlen+0x10>
f0103209:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010320b:	5d                   	pop    %ebp
f010320c:	c3                   	ret    

f010320d <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010320d:	55                   	push   %ebp
f010320e:	89 e5                	mov    %esp,%ebp
f0103210:	53                   	push   %ebx
f0103211:	8b 45 08             	mov    0x8(%ebp),%eax
f0103214:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103217:	89 c2                	mov    %eax,%edx
f0103219:	83 c2 01             	add    $0x1,%edx
f010321c:	83 c1 01             	add    $0x1,%ecx
f010321f:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103223:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103226:	84 db                	test   %bl,%bl
f0103228:	75 ef                	jne    f0103219 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010322a:	5b                   	pop    %ebx
f010322b:	5d                   	pop    %ebp
f010322c:	c3                   	ret    

f010322d <strcat>:

char *
strcat(char *dst, const char *src)
{
f010322d:	55                   	push   %ebp
f010322e:	89 e5                	mov    %esp,%ebp
f0103230:	53                   	push   %ebx
f0103231:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103234:	53                   	push   %ebx
f0103235:	e8 9a ff ff ff       	call   f01031d4 <strlen>
f010323a:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010323d:	ff 75 0c             	pushl  0xc(%ebp)
f0103240:	01 d8                	add    %ebx,%eax
f0103242:	50                   	push   %eax
f0103243:	e8 c5 ff ff ff       	call   f010320d <strcpy>
	return dst;
}
f0103248:	89 d8                	mov    %ebx,%eax
f010324a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010324d:	c9                   	leave  
f010324e:	c3                   	ret    

f010324f <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010324f:	55                   	push   %ebp
f0103250:	89 e5                	mov    %esp,%ebp
f0103252:	56                   	push   %esi
f0103253:	53                   	push   %ebx
f0103254:	8b 75 08             	mov    0x8(%ebp),%esi
f0103257:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010325a:	89 f3                	mov    %esi,%ebx
f010325c:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010325f:	89 f2                	mov    %esi,%edx
f0103261:	eb 0f                	jmp    f0103272 <strncpy+0x23>
		*dst++ = *src;
f0103263:	83 c2 01             	add    $0x1,%edx
f0103266:	0f b6 01             	movzbl (%ecx),%eax
f0103269:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010326c:	80 39 01             	cmpb   $0x1,(%ecx)
f010326f:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103272:	39 da                	cmp    %ebx,%edx
f0103274:	75 ed                	jne    f0103263 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103276:	89 f0                	mov    %esi,%eax
f0103278:	5b                   	pop    %ebx
f0103279:	5e                   	pop    %esi
f010327a:	5d                   	pop    %ebp
f010327b:	c3                   	ret    

f010327c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010327c:	55                   	push   %ebp
f010327d:	89 e5                	mov    %esp,%ebp
f010327f:	56                   	push   %esi
f0103280:	53                   	push   %ebx
f0103281:	8b 75 08             	mov    0x8(%ebp),%esi
f0103284:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103287:	8b 55 10             	mov    0x10(%ebp),%edx
f010328a:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010328c:	85 d2                	test   %edx,%edx
f010328e:	74 21                	je     f01032b1 <strlcpy+0x35>
f0103290:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103294:	89 f2                	mov    %esi,%edx
f0103296:	eb 09                	jmp    f01032a1 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103298:	83 c2 01             	add    $0x1,%edx
f010329b:	83 c1 01             	add    $0x1,%ecx
f010329e:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01032a1:	39 c2                	cmp    %eax,%edx
f01032a3:	74 09                	je     f01032ae <strlcpy+0x32>
f01032a5:	0f b6 19             	movzbl (%ecx),%ebx
f01032a8:	84 db                	test   %bl,%bl
f01032aa:	75 ec                	jne    f0103298 <strlcpy+0x1c>
f01032ac:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01032ae:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01032b1:	29 f0                	sub    %esi,%eax
}
f01032b3:	5b                   	pop    %ebx
f01032b4:	5e                   	pop    %esi
f01032b5:	5d                   	pop    %ebp
f01032b6:	c3                   	ret    

f01032b7 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01032b7:	55                   	push   %ebp
f01032b8:	89 e5                	mov    %esp,%ebp
f01032ba:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01032bd:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01032c0:	eb 06                	jmp    f01032c8 <strcmp+0x11>
		p++, q++;
f01032c2:	83 c1 01             	add    $0x1,%ecx
f01032c5:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01032c8:	0f b6 01             	movzbl (%ecx),%eax
f01032cb:	84 c0                	test   %al,%al
f01032cd:	74 04                	je     f01032d3 <strcmp+0x1c>
f01032cf:	3a 02                	cmp    (%edx),%al
f01032d1:	74 ef                	je     f01032c2 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01032d3:	0f b6 c0             	movzbl %al,%eax
f01032d6:	0f b6 12             	movzbl (%edx),%edx
f01032d9:	29 d0                	sub    %edx,%eax
}
f01032db:	5d                   	pop    %ebp
f01032dc:	c3                   	ret    

f01032dd <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01032dd:	55                   	push   %ebp
f01032de:	89 e5                	mov    %esp,%ebp
f01032e0:	53                   	push   %ebx
f01032e1:	8b 45 08             	mov    0x8(%ebp),%eax
f01032e4:	8b 55 0c             	mov    0xc(%ebp),%edx
f01032e7:	89 c3                	mov    %eax,%ebx
f01032e9:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01032ec:	eb 06                	jmp    f01032f4 <strncmp+0x17>
		n--, p++, q++;
f01032ee:	83 c0 01             	add    $0x1,%eax
f01032f1:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01032f4:	39 d8                	cmp    %ebx,%eax
f01032f6:	74 15                	je     f010330d <strncmp+0x30>
f01032f8:	0f b6 08             	movzbl (%eax),%ecx
f01032fb:	84 c9                	test   %cl,%cl
f01032fd:	74 04                	je     f0103303 <strncmp+0x26>
f01032ff:	3a 0a                	cmp    (%edx),%cl
f0103301:	74 eb                	je     f01032ee <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103303:	0f b6 00             	movzbl (%eax),%eax
f0103306:	0f b6 12             	movzbl (%edx),%edx
f0103309:	29 d0                	sub    %edx,%eax
f010330b:	eb 05                	jmp    f0103312 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010330d:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103312:	5b                   	pop    %ebx
f0103313:	5d                   	pop    %ebp
f0103314:	c3                   	ret    

f0103315 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103315:	55                   	push   %ebp
f0103316:	89 e5                	mov    %esp,%ebp
f0103318:	8b 45 08             	mov    0x8(%ebp),%eax
f010331b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010331f:	eb 07                	jmp    f0103328 <strchr+0x13>
		if (*s == c)
f0103321:	38 ca                	cmp    %cl,%dl
f0103323:	74 0f                	je     f0103334 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103325:	83 c0 01             	add    $0x1,%eax
f0103328:	0f b6 10             	movzbl (%eax),%edx
f010332b:	84 d2                	test   %dl,%dl
f010332d:	75 f2                	jne    f0103321 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010332f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103334:	5d                   	pop    %ebp
f0103335:	c3                   	ret    

f0103336 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103336:	55                   	push   %ebp
f0103337:	89 e5                	mov    %esp,%ebp
f0103339:	8b 45 08             	mov    0x8(%ebp),%eax
f010333c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103340:	eb 03                	jmp    f0103345 <strfind+0xf>
f0103342:	83 c0 01             	add    $0x1,%eax
f0103345:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103348:	38 ca                	cmp    %cl,%dl
f010334a:	74 04                	je     f0103350 <strfind+0x1a>
f010334c:	84 d2                	test   %dl,%dl
f010334e:	75 f2                	jne    f0103342 <strfind+0xc>
			break;
	return (char *) s;
}
f0103350:	5d                   	pop    %ebp
f0103351:	c3                   	ret    

f0103352 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103352:	55                   	push   %ebp
f0103353:	89 e5                	mov    %esp,%ebp
f0103355:	57                   	push   %edi
f0103356:	56                   	push   %esi
f0103357:	53                   	push   %ebx
f0103358:	8b 7d 08             	mov    0x8(%ebp),%edi
f010335b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010335e:	85 c9                	test   %ecx,%ecx
f0103360:	74 36                	je     f0103398 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103362:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103368:	75 28                	jne    f0103392 <memset+0x40>
f010336a:	f6 c1 03             	test   $0x3,%cl
f010336d:	75 23                	jne    f0103392 <memset+0x40>
		c &= 0xFF;
f010336f:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103373:	89 d3                	mov    %edx,%ebx
f0103375:	c1 e3 08             	shl    $0x8,%ebx
f0103378:	89 d6                	mov    %edx,%esi
f010337a:	c1 e6 18             	shl    $0x18,%esi
f010337d:	89 d0                	mov    %edx,%eax
f010337f:	c1 e0 10             	shl    $0x10,%eax
f0103382:	09 f0                	or     %esi,%eax
f0103384:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103386:	89 d8                	mov    %ebx,%eax
f0103388:	09 d0                	or     %edx,%eax
f010338a:	c1 e9 02             	shr    $0x2,%ecx
f010338d:	fc                   	cld    
f010338e:	f3 ab                	rep stos %eax,%es:(%edi)
f0103390:	eb 06                	jmp    f0103398 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103392:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103395:	fc                   	cld    
f0103396:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103398:	89 f8                	mov    %edi,%eax
f010339a:	5b                   	pop    %ebx
f010339b:	5e                   	pop    %esi
f010339c:	5f                   	pop    %edi
f010339d:	5d                   	pop    %ebp
f010339e:	c3                   	ret    

f010339f <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010339f:	55                   	push   %ebp
f01033a0:	89 e5                	mov    %esp,%ebp
f01033a2:	57                   	push   %edi
f01033a3:	56                   	push   %esi
f01033a4:	8b 45 08             	mov    0x8(%ebp),%eax
f01033a7:	8b 75 0c             	mov    0xc(%ebp),%esi
f01033aa:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01033ad:	39 c6                	cmp    %eax,%esi
f01033af:	73 35                	jae    f01033e6 <memmove+0x47>
f01033b1:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01033b4:	39 d0                	cmp    %edx,%eax
f01033b6:	73 2e                	jae    f01033e6 <memmove+0x47>
		s += n;
		d += n;
f01033b8:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01033bb:	89 d6                	mov    %edx,%esi
f01033bd:	09 fe                	or     %edi,%esi
f01033bf:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01033c5:	75 13                	jne    f01033da <memmove+0x3b>
f01033c7:	f6 c1 03             	test   $0x3,%cl
f01033ca:	75 0e                	jne    f01033da <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01033cc:	83 ef 04             	sub    $0x4,%edi
f01033cf:	8d 72 fc             	lea    -0x4(%edx),%esi
f01033d2:	c1 e9 02             	shr    $0x2,%ecx
f01033d5:	fd                   	std    
f01033d6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01033d8:	eb 09                	jmp    f01033e3 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01033da:	83 ef 01             	sub    $0x1,%edi
f01033dd:	8d 72 ff             	lea    -0x1(%edx),%esi
f01033e0:	fd                   	std    
f01033e1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01033e3:	fc                   	cld    
f01033e4:	eb 1d                	jmp    f0103403 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01033e6:	89 f2                	mov    %esi,%edx
f01033e8:	09 c2                	or     %eax,%edx
f01033ea:	f6 c2 03             	test   $0x3,%dl
f01033ed:	75 0f                	jne    f01033fe <memmove+0x5f>
f01033ef:	f6 c1 03             	test   $0x3,%cl
f01033f2:	75 0a                	jne    f01033fe <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01033f4:	c1 e9 02             	shr    $0x2,%ecx
f01033f7:	89 c7                	mov    %eax,%edi
f01033f9:	fc                   	cld    
f01033fa:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01033fc:	eb 05                	jmp    f0103403 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01033fe:	89 c7                	mov    %eax,%edi
f0103400:	fc                   	cld    
f0103401:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103403:	5e                   	pop    %esi
f0103404:	5f                   	pop    %edi
f0103405:	5d                   	pop    %ebp
f0103406:	c3                   	ret    

f0103407 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103407:	55                   	push   %ebp
f0103408:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010340a:	ff 75 10             	pushl  0x10(%ebp)
f010340d:	ff 75 0c             	pushl  0xc(%ebp)
f0103410:	ff 75 08             	pushl  0x8(%ebp)
f0103413:	e8 87 ff ff ff       	call   f010339f <memmove>
}
f0103418:	c9                   	leave  
f0103419:	c3                   	ret    

f010341a <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010341a:	55                   	push   %ebp
f010341b:	89 e5                	mov    %esp,%ebp
f010341d:	56                   	push   %esi
f010341e:	53                   	push   %ebx
f010341f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103422:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103425:	89 c6                	mov    %eax,%esi
f0103427:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010342a:	eb 1a                	jmp    f0103446 <memcmp+0x2c>
		if (*s1 != *s2)
f010342c:	0f b6 08             	movzbl (%eax),%ecx
f010342f:	0f b6 1a             	movzbl (%edx),%ebx
f0103432:	38 d9                	cmp    %bl,%cl
f0103434:	74 0a                	je     f0103440 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103436:	0f b6 c1             	movzbl %cl,%eax
f0103439:	0f b6 db             	movzbl %bl,%ebx
f010343c:	29 d8                	sub    %ebx,%eax
f010343e:	eb 0f                	jmp    f010344f <memcmp+0x35>
		s1++, s2++;
f0103440:	83 c0 01             	add    $0x1,%eax
f0103443:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103446:	39 f0                	cmp    %esi,%eax
f0103448:	75 e2                	jne    f010342c <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010344a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010344f:	5b                   	pop    %ebx
f0103450:	5e                   	pop    %esi
f0103451:	5d                   	pop    %ebp
f0103452:	c3                   	ret    

f0103453 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103453:	55                   	push   %ebp
f0103454:	89 e5                	mov    %esp,%ebp
f0103456:	53                   	push   %ebx
f0103457:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010345a:	89 c1                	mov    %eax,%ecx
f010345c:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f010345f:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103463:	eb 0a                	jmp    f010346f <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103465:	0f b6 10             	movzbl (%eax),%edx
f0103468:	39 da                	cmp    %ebx,%edx
f010346a:	74 07                	je     f0103473 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010346c:	83 c0 01             	add    $0x1,%eax
f010346f:	39 c8                	cmp    %ecx,%eax
f0103471:	72 f2                	jb     f0103465 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103473:	5b                   	pop    %ebx
f0103474:	5d                   	pop    %ebp
f0103475:	c3                   	ret    

f0103476 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103476:	55                   	push   %ebp
f0103477:	89 e5                	mov    %esp,%ebp
f0103479:	57                   	push   %edi
f010347a:	56                   	push   %esi
f010347b:	53                   	push   %ebx
f010347c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010347f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103482:	eb 03                	jmp    f0103487 <strtol+0x11>
		s++;
f0103484:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103487:	0f b6 01             	movzbl (%ecx),%eax
f010348a:	3c 20                	cmp    $0x20,%al
f010348c:	74 f6                	je     f0103484 <strtol+0xe>
f010348e:	3c 09                	cmp    $0x9,%al
f0103490:	74 f2                	je     f0103484 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103492:	3c 2b                	cmp    $0x2b,%al
f0103494:	75 0a                	jne    f01034a0 <strtol+0x2a>
		s++;
f0103496:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103499:	bf 00 00 00 00       	mov    $0x0,%edi
f010349e:	eb 11                	jmp    f01034b1 <strtol+0x3b>
f01034a0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01034a5:	3c 2d                	cmp    $0x2d,%al
f01034a7:	75 08                	jne    f01034b1 <strtol+0x3b>
		s++, neg = 1;
f01034a9:	83 c1 01             	add    $0x1,%ecx
f01034ac:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01034b1:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01034b7:	75 15                	jne    f01034ce <strtol+0x58>
f01034b9:	80 39 30             	cmpb   $0x30,(%ecx)
f01034bc:	75 10                	jne    f01034ce <strtol+0x58>
f01034be:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01034c2:	75 7c                	jne    f0103540 <strtol+0xca>
		s += 2, base = 16;
f01034c4:	83 c1 02             	add    $0x2,%ecx
f01034c7:	bb 10 00 00 00       	mov    $0x10,%ebx
f01034cc:	eb 16                	jmp    f01034e4 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01034ce:	85 db                	test   %ebx,%ebx
f01034d0:	75 12                	jne    f01034e4 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01034d2:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01034d7:	80 39 30             	cmpb   $0x30,(%ecx)
f01034da:	75 08                	jne    f01034e4 <strtol+0x6e>
		s++, base = 8;
f01034dc:	83 c1 01             	add    $0x1,%ecx
f01034df:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01034e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01034e9:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01034ec:	0f b6 11             	movzbl (%ecx),%edx
f01034ef:	8d 72 d0             	lea    -0x30(%edx),%esi
f01034f2:	89 f3                	mov    %esi,%ebx
f01034f4:	80 fb 09             	cmp    $0x9,%bl
f01034f7:	77 08                	ja     f0103501 <strtol+0x8b>
			dig = *s - '0';
f01034f9:	0f be d2             	movsbl %dl,%edx
f01034fc:	83 ea 30             	sub    $0x30,%edx
f01034ff:	eb 22                	jmp    f0103523 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103501:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103504:	89 f3                	mov    %esi,%ebx
f0103506:	80 fb 19             	cmp    $0x19,%bl
f0103509:	77 08                	ja     f0103513 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010350b:	0f be d2             	movsbl %dl,%edx
f010350e:	83 ea 57             	sub    $0x57,%edx
f0103511:	eb 10                	jmp    f0103523 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103513:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103516:	89 f3                	mov    %esi,%ebx
f0103518:	80 fb 19             	cmp    $0x19,%bl
f010351b:	77 16                	ja     f0103533 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010351d:	0f be d2             	movsbl %dl,%edx
f0103520:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103523:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103526:	7d 0b                	jge    f0103533 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103528:	83 c1 01             	add    $0x1,%ecx
f010352b:	0f af 45 10          	imul   0x10(%ebp),%eax
f010352f:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103531:	eb b9                	jmp    f01034ec <strtol+0x76>

	if (endptr)
f0103533:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103537:	74 0d                	je     f0103546 <strtol+0xd0>
		*endptr = (char *) s;
f0103539:	8b 75 0c             	mov    0xc(%ebp),%esi
f010353c:	89 0e                	mov    %ecx,(%esi)
f010353e:	eb 06                	jmp    f0103546 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103540:	85 db                	test   %ebx,%ebx
f0103542:	74 98                	je     f01034dc <strtol+0x66>
f0103544:	eb 9e                	jmp    f01034e4 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103546:	89 c2                	mov    %eax,%edx
f0103548:	f7 da                	neg    %edx
f010354a:	85 ff                	test   %edi,%edi
f010354c:	0f 45 c2             	cmovne %edx,%eax
}
f010354f:	5b                   	pop    %ebx
f0103550:	5e                   	pop    %esi
f0103551:	5f                   	pop    %edi
f0103552:	5d                   	pop    %ebp
f0103553:	c3                   	ret    
f0103554:	66 90                	xchg   %ax,%ax
f0103556:	66 90                	xchg   %ax,%ax
f0103558:	66 90                	xchg   %ax,%ax
f010355a:	66 90                	xchg   %ax,%ax
f010355c:	66 90                	xchg   %ax,%ax
f010355e:	66 90                	xchg   %ax,%ax

f0103560 <__udivdi3>:
f0103560:	55                   	push   %ebp
f0103561:	57                   	push   %edi
f0103562:	56                   	push   %esi
f0103563:	53                   	push   %ebx
f0103564:	83 ec 1c             	sub    $0x1c,%esp
f0103567:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010356b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010356f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103573:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103577:	85 f6                	test   %esi,%esi
f0103579:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010357d:	89 ca                	mov    %ecx,%edx
f010357f:	89 f8                	mov    %edi,%eax
f0103581:	75 3d                	jne    f01035c0 <__udivdi3+0x60>
f0103583:	39 cf                	cmp    %ecx,%edi
f0103585:	0f 87 c5 00 00 00    	ja     f0103650 <__udivdi3+0xf0>
f010358b:	85 ff                	test   %edi,%edi
f010358d:	89 fd                	mov    %edi,%ebp
f010358f:	75 0b                	jne    f010359c <__udivdi3+0x3c>
f0103591:	b8 01 00 00 00       	mov    $0x1,%eax
f0103596:	31 d2                	xor    %edx,%edx
f0103598:	f7 f7                	div    %edi
f010359a:	89 c5                	mov    %eax,%ebp
f010359c:	89 c8                	mov    %ecx,%eax
f010359e:	31 d2                	xor    %edx,%edx
f01035a0:	f7 f5                	div    %ebp
f01035a2:	89 c1                	mov    %eax,%ecx
f01035a4:	89 d8                	mov    %ebx,%eax
f01035a6:	89 cf                	mov    %ecx,%edi
f01035a8:	f7 f5                	div    %ebp
f01035aa:	89 c3                	mov    %eax,%ebx
f01035ac:	89 d8                	mov    %ebx,%eax
f01035ae:	89 fa                	mov    %edi,%edx
f01035b0:	83 c4 1c             	add    $0x1c,%esp
f01035b3:	5b                   	pop    %ebx
f01035b4:	5e                   	pop    %esi
f01035b5:	5f                   	pop    %edi
f01035b6:	5d                   	pop    %ebp
f01035b7:	c3                   	ret    
f01035b8:	90                   	nop
f01035b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01035c0:	39 ce                	cmp    %ecx,%esi
f01035c2:	77 74                	ja     f0103638 <__udivdi3+0xd8>
f01035c4:	0f bd fe             	bsr    %esi,%edi
f01035c7:	83 f7 1f             	xor    $0x1f,%edi
f01035ca:	0f 84 98 00 00 00    	je     f0103668 <__udivdi3+0x108>
f01035d0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01035d5:	89 f9                	mov    %edi,%ecx
f01035d7:	89 c5                	mov    %eax,%ebp
f01035d9:	29 fb                	sub    %edi,%ebx
f01035db:	d3 e6                	shl    %cl,%esi
f01035dd:	89 d9                	mov    %ebx,%ecx
f01035df:	d3 ed                	shr    %cl,%ebp
f01035e1:	89 f9                	mov    %edi,%ecx
f01035e3:	d3 e0                	shl    %cl,%eax
f01035e5:	09 ee                	or     %ebp,%esi
f01035e7:	89 d9                	mov    %ebx,%ecx
f01035e9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01035ed:	89 d5                	mov    %edx,%ebp
f01035ef:	8b 44 24 08          	mov    0x8(%esp),%eax
f01035f3:	d3 ed                	shr    %cl,%ebp
f01035f5:	89 f9                	mov    %edi,%ecx
f01035f7:	d3 e2                	shl    %cl,%edx
f01035f9:	89 d9                	mov    %ebx,%ecx
f01035fb:	d3 e8                	shr    %cl,%eax
f01035fd:	09 c2                	or     %eax,%edx
f01035ff:	89 d0                	mov    %edx,%eax
f0103601:	89 ea                	mov    %ebp,%edx
f0103603:	f7 f6                	div    %esi
f0103605:	89 d5                	mov    %edx,%ebp
f0103607:	89 c3                	mov    %eax,%ebx
f0103609:	f7 64 24 0c          	mull   0xc(%esp)
f010360d:	39 d5                	cmp    %edx,%ebp
f010360f:	72 10                	jb     f0103621 <__udivdi3+0xc1>
f0103611:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103615:	89 f9                	mov    %edi,%ecx
f0103617:	d3 e6                	shl    %cl,%esi
f0103619:	39 c6                	cmp    %eax,%esi
f010361b:	73 07                	jae    f0103624 <__udivdi3+0xc4>
f010361d:	39 d5                	cmp    %edx,%ebp
f010361f:	75 03                	jne    f0103624 <__udivdi3+0xc4>
f0103621:	83 eb 01             	sub    $0x1,%ebx
f0103624:	31 ff                	xor    %edi,%edi
f0103626:	89 d8                	mov    %ebx,%eax
f0103628:	89 fa                	mov    %edi,%edx
f010362a:	83 c4 1c             	add    $0x1c,%esp
f010362d:	5b                   	pop    %ebx
f010362e:	5e                   	pop    %esi
f010362f:	5f                   	pop    %edi
f0103630:	5d                   	pop    %ebp
f0103631:	c3                   	ret    
f0103632:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103638:	31 ff                	xor    %edi,%edi
f010363a:	31 db                	xor    %ebx,%ebx
f010363c:	89 d8                	mov    %ebx,%eax
f010363e:	89 fa                	mov    %edi,%edx
f0103640:	83 c4 1c             	add    $0x1c,%esp
f0103643:	5b                   	pop    %ebx
f0103644:	5e                   	pop    %esi
f0103645:	5f                   	pop    %edi
f0103646:	5d                   	pop    %ebp
f0103647:	c3                   	ret    
f0103648:	90                   	nop
f0103649:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103650:	89 d8                	mov    %ebx,%eax
f0103652:	f7 f7                	div    %edi
f0103654:	31 ff                	xor    %edi,%edi
f0103656:	89 c3                	mov    %eax,%ebx
f0103658:	89 d8                	mov    %ebx,%eax
f010365a:	89 fa                	mov    %edi,%edx
f010365c:	83 c4 1c             	add    $0x1c,%esp
f010365f:	5b                   	pop    %ebx
f0103660:	5e                   	pop    %esi
f0103661:	5f                   	pop    %edi
f0103662:	5d                   	pop    %ebp
f0103663:	c3                   	ret    
f0103664:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103668:	39 ce                	cmp    %ecx,%esi
f010366a:	72 0c                	jb     f0103678 <__udivdi3+0x118>
f010366c:	31 db                	xor    %ebx,%ebx
f010366e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103672:	0f 87 34 ff ff ff    	ja     f01035ac <__udivdi3+0x4c>
f0103678:	bb 01 00 00 00       	mov    $0x1,%ebx
f010367d:	e9 2a ff ff ff       	jmp    f01035ac <__udivdi3+0x4c>
f0103682:	66 90                	xchg   %ax,%ax
f0103684:	66 90                	xchg   %ax,%ax
f0103686:	66 90                	xchg   %ax,%ax
f0103688:	66 90                	xchg   %ax,%ax
f010368a:	66 90                	xchg   %ax,%ax
f010368c:	66 90                	xchg   %ax,%ax
f010368e:	66 90                	xchg   %ax,%ax

f0103690 <__umoddi3>:
f0103690:	55                   	push   %ebp
f0103691:	57                   	push   %edi
f0103692:	56                   	push   %esi
f0103693:	53                   	push   %ebx
f0103694:	83 ec 1c             	sub    $0x1c,%esp
f0103697:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010369b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010369f:	8b 74 24 34          	mov    0x34(%esp),%esi
f01036a3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01036a7:	85 d2                	test   %edx,%edx
f01036a9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01036ad:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01036b1:	89 f3                	mov    %esi,%ebx
f01036b3:	89 3c 24             	mov    %edi,(%esp)
f01036b6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01036ba:	75 1c                	jne    f01036d8 <__umoddi3+0x48>
f01036bc:	39 f7                	cmp    %esi,%edi
f01036be:	76 50                	jbe    f0103710 <__umoddi3+0x80>
f01036c0:	89 c8                	mov    %ecx,%eax
f01036c2:	89 f2                	mov    %esi,%edx
f01036c4:	f7 f7                	div    %edi
f01036c6:	89 d0                	mov    %edx,%eax
f01036c8:	31 d2                	xor    %edx,%edx
f01036ca:	83 c4 1c             	add    $0x1c,%esp
f01036cd:	5b                   	pop    %ebx
f01036ce:	5e                   	pop    %esi
f01036cf:	5f                   	pop    %edi
f01036d0:	5d                   	pop    %ebp
f01036d1:	c3                   	ret    
f01036d2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01036d8:	39 f2                	cmp    %esi,%edx
f01036da:	89 d0                	mov    %edx,%eax
f01036dc:	77 52                	ja     f0103730 <__umoddi3+0xa0>
f01036de:	0f bd ea             	bsr    %edx,%ebp
f01036e1:	83 f5 1f             	xor    $0x1f,%ebp
f01036e4:	75 5a                	jne    f0103740 <__umoddi3+0xb0>
f01036e6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01036ea:	0f 82 e0 00 00 00    	jb     f01037d0 <__umoddi3+0x140>
f01036f0:	39 0c 24             	cmp    %ecx,(%esp)
f01036f3:	0f 86 d7 00 00 00    	jbe    f01037d0 <__umoddi3+0x140>
f01036f9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01036fd:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103701:	83 c4 1c             	add    $0x1c,%esp
f0103704:	5b                   	pop    %ebx
f0103705:	5e                   	pop    %esi
f0103706:	5f                   	pop    %edi
f0103707:	5d                   	pop    %ebp
f0103708:	c3                   	ret    
f0103709:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103710:	85 ff                	test   %edi,%edi
f0103712:	89 fd                	mov    %edi,%ebp
f0103714:	75 0b                	jne    f0103721 <__umoddi3+0x91>
f0103716:	b8 01 00 00 00       	mov    $0x1,%eax
f010371b:	31 d2                	xor    %edx,%edx
f010371d:	f7 f7                	div    %edi
f010371f:	89 c5                	mov    %eax,%ebp
f0103721:	89 f0                	mov    %esi,%eax
f0103723:	31 d2                	xor    %edx,%edx
f0103725:	f7 f5                	div    %ebp
f0103727:	89 c8                	mov    %ecx,%eax
f0103729:	f7 f5                	div    %ebp
f010372b:	89 d0                	mov    %edx,%eax
f010372d:	eb 99                	jmp    f01036c8 <__umoddi3+0x38>
f010372f:	90                   	nop
f0103730:	89 c8                	mov    %ecx,%eax
f0103732:	89 f2                	mov    %esi,%edx
f0103734:	83 c4 1c             	add    $0x1c,%esp
f0103737:	5b                   	pop    %ebx
f0103738:	5e                   	pop    %esi
f0103739:	5f                   	pop    %edi
f010373a:	5d                   	pop    %ebp
f010373b:	c3                   	ret    
f010373c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103740:	8b 34 24             	mov    (%esp),%esi
f0103743:	bf 20 00 00 00       	mov    $0x20,%edi
f0103748:	89 e9                	mov    %ebp,%ecx
f010374a:	29 ef                	sub    %ebp,%edi
f010374c:	d3 e0                	shl    %cl,%eax
f010374e:	89 f9                	mov    %edi,%ecx
f0103750:	89 f2                	mov    %esi,%edx
f0103752:	d3 ea                	shr    %cl,%edx
f0103754:	89 e9                	mov    %ebp,%ecx
f0103756:	09 c2                	or     %eax,%edx
f0103758:	89 d8                	mov    %ebx,%eax
f010375a:	89 14 24             	mov    %edx,(%esp)
f010375d:	89 f2                	mov    %esi,%edx
f010375f:	d3 e2                	shl    %cl,%edx
f0103761:	89 f9                	mov    %edi,%ecx
f0103763:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103767:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010376b:	d3 e8                	shr    %cl,%eax
f010376d:	89 e9                	mov    %ebp,%ecx
f010376f:	89 c6                	mov    %eax,%esi
f0103771:	d3 e3                	shl    %cl,%ebx
f0103773:	89 f9                	mov    %edi,%ecx
f0103775:	89 d0                	mov    %edx,%eax
f0103777:	d3 e8                	shr    %cl,%eax
f0103779:	89 e9                	mov    %ebp,%ecx
f010377b:	09 d8                	or     %ebx,%eax
f010377d:	89 d3                	mov    %edx,%ebx
f010377f:	89 f2                	mov    %esi,%edx
f0103781:	f7 34 24             	divl   (%esp)
f0103784:	89 d6                	mov    %edx,%esi
f0103786:	d3 e3                	shl    %cl,%ebx
f0103788:	f7 64 24 04          	mull   0x4(%esp)
f010378c:	39 d6                	cmp    %edx,%esi
f010378e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103792:	89 d1                	mov    %edx,%ecx
f0103794:	89 c3                	mov    %eax,%ebx
f0103796:	72 08                	jb     f01037a0 <__umoddi3+0x110>
f0103798:	75 11                	jne    f01037ab <__umoddi3+0x11b>
f010379a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010379e:	73 0b                	jae    f01037ab <__umoddi3+0x11b>
f01037a0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01037a4:	1b 14 24             	sbb    (%esp),%edx
f01037a7:	89 d1                	mov    %edx,%ecx
f01037a9:	89 c3                	mov    %eax,%ebx
f01037ab:	8b 54 24 08          	mov    0x8(%esp),%edx
f01037af:	29 da                	sub    %ebx,%edx
f01037b1:	19 ce                	sbb    %ecx,%esi
f01037b3:	89 f9                	mov    %edi,%ecx
f01037b5:	89 f0                	mov    %esi,%eax
f01037b7:	d3 e0                	shl    %cl,%eax
f01037b9:	89 e9                	mov    %ebp,%ecx
f01037bb:	d3 ea                	shr    %cl,%edx
f01037bd:	89 e9                	mov    %ebp,%ecx
f01037bf:	d3 ee                	shr    %cl,%esi
f01037c1:	09 d0                	or     %edx,%eax
f01037c3:	89 f2                	mov    %esi,%edx
f01037c5:	83 c4 1c             	add    $0x1c,%esp
f01037c8:	5b                   	pop    %ebx
f01037c9:	5e                   	pop    %esi
f01037ca:	5f                   	pop    %edi
f01037cb:	5d                   	pop    %ebp
f01037cc:	c3                   	ret    
f01037cd:	8d 76 00             	lea    0x0(%esi),%esi
f01037d0:	29 f9                	sub    %edi,%ecx
f01037d2:	19 d6                	sbb    %edx,%esi
f01037d4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01037d8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01037dc:	e9 18 ff ff ff       	jmp    f01036f9 <__umoddi3+0x69>
