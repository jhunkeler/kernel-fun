#define VRAM 0x00b8000

extern void kmain(void);
extern void khalt(void);
extern unsigned short inb(unsigned short port);
extern unsigned short outb(unsigned short port, unsigned char data);
extern unsigned short kend;

unsigned short *scr = (unsigned short*) VRAM;
unsigned int cursor = 0;
unsigned char cursor_x;
unsigned char cursor_y;
unsigned char cursor_attrib;


unsigned char interrupt_handler(unsigned char intr)
{
    return intr;
}

void update_hw_cursor()
{
    unsigned char position = (cursor_y * 80) + cursor_x;
    cursor = position + VRAM;
    unsigned char x, y;
    x = (position >> 8);
    y = (position) & 0xff;
    outb(0x3D4, 14);
    outb(0x3D5, x);
    outb(0x3D4, 15);
    outb(0x3D5, y);
}

void cls(char attr)
{
    unsigned short i;
    unsigned short *sptr = (unsigned short*)scr;
    for(i = 0; i < 0x0780; ++i)
    {
        (*(sptr)) = ( 0x20 | attr << 8);
        sptr++;
    }
}

int putc(unsigned char ch)
{
    if (ch == 0x8)
    {
        if(cursor_x != 0)
            cursor_x--;
    }
    else if (ch == 0x9)
    {
        cursor_x = (cursor_x + 8) & ~(8 - 1);
    }
    else if (ch == '\r')
    {
        cursor_x = 0;
    }
    else if (ch == '\n')
    {
        cursor_x = 0;
        cursor_y++;
    }
    else if(ch >= 0x20)
    {
        (*(scr + cursor_y * 80 + cursor_x)) = (ch | cursor_attrib << 8);
        cursor_x++;
    }

    if(cursor_x > 79)
    {
        cursor_x = 0;
        cursor_y++;
    }

    scroll();
    update_hw_cursor();
    return ch;
}

void putnl()
{
    putc('\n');
}

unsigned int puts(const char *s)
{
    unsigned int i = 0;
    while(*s != 0)
    {
        putc(*s);
        i++;
        s++;
    }
    putnl();

    return i;
}

void *memset(void *s, int c, unsigned int n)
{
    unsigned int i;
    unsigned char *tmp = s;
    for(i = 0; i < n; ++i)
    {
        *tmp = c;
        tmp++;
    }
    return s;
}

void *memcpy(void *dest, void *src, unsigned int n)
{
    unsigned int i;
    unsigned short *dtmp = dest;
    unsigned short *stmp = src;

    for(i = 0; i < n; ++i)
    {
        (*(dtmp + i)) = (*(stmp + i));
    }
    return dest;
}

int strlen(const char *s)
{
    unsigned int i = 0;
    while(*s != 0)
    {
        i++;
        s++;
    }

    return i;
}

char *strchr(char *s, int c)
{
    while(*s != 0)
    {
        if(*s == c)
            break;
        s++;
    }

    return s;
}

char *strncat(char* dest, const char* src, int num)
{
    dest += strlen(dest);
    while(src != 0 && num != 0)
    {
        *dest = *src;
        src++;
        dest++;
        num--;
    }
    return dest;
}

char *strncpy(char* dest, const char* src, int num)
{
    while(src != 0 && num != 0)
    {
        *dest = *src;
        src++;
        dest++;
        num--;
    }
    return dest;
}

int strncmp(const char* str1, const char* str2, int num)
{
    while((*str1 == *str2) && (*str1 != 0) && num != 0)
    {
        str1++;
        str2++;
        num--;
    }
    return (*str1 - *str2);
}


void strrev(char *str)
{
    char temp;
    char *endp;

    if(str == 0 || !(*str))
    {
        return;
    }

    endp = str + strlen(str) - 1;
    while(endp > str)
    {
        temp = *str;
        *str = *endp;
        *endp = temp;
        str++;
        endp--;
    }

}

void putn(const char *type, long long int v)
{
    char buffer[128];
    memset(buffer, 0, 128);

    int bsize;
    int _is_signed = 0;
    int _is_hex = 0;
    int _is_int = 0;

    char r = 0;
    long int n = v;
    int i;

    for(i = 0; i <= strlen((char*)type); i++)
    {
        switch(type[i])
        {
            case 'u':
                _is_signed = 0;
                break;

            case 'x':
                _is_hex = 1;
                break;

            case 'i':
                _is_int = 1;
                break;
        }
    }

    if (n < 0)
    {
        n = ~n + 1;
        _is_signed = 1;
    }

    if(n == 0)
    {
        buffer[0] = '0';
    }
    else if(_is_int)
    {

        for(i = 0; n > 0; i++)
        {
            r = (n % 10);
            r += '0';
            buffer[i] = r;
            n /= 10;
        }
    }
    else if(_is_hex)
    {
        for(i = 0; v != 0; i++)
        {
            n = (v & 0x0f) + '0';
            if (n > '9')
            {
                n += 7;
            }
            buffer[i] = n;
            v >>= 4;
        }

    }
    else
    {
        puts("putn: invalid format specifier\n");
        return;
    }

    if(_is_hex)
    {
        buffer[strlen(buffer) + 1] = '0';
        buffer[strlen(buffer)] = 'x';
    }

    bsize = strlen(buffer);

    if(_is_signed)
        buffer[bsize] = '-';

    strrev(buffer);
    buffer[bsize+1] = 0;

    char *s = buffer;
    while(*s != 0)
    {
        putc(*s);
        i++;
        s++;
    }
}

unsigned char kbd_status(void)
{
    return inb(0x64);
}

unsigned char kbd_scancode(void)
{
    return inb(0x60);
}

void scroll(void)
{
    unsigned blank, temp;
    blank = 0x25 | (cursor_attrib << 8);
    if(cursor_y >= 25)
    {
        temp = cursor_y - 25 + 1;
        memcpy(scr, scr + temp * 80, (25 - temp) * 80 * 2);
        memcpy(scr + (25 - temp) * 80, (short*)blank, 80);
        cursor_y = 25 - 1;
    }
}

int ckmain()
{
    const char *banner =
"             _       __ _       ______   ___   ___ __ _ \n"
"    /|    //| |     // | |     //   ) )    / /    // | |\n"
"   //|   // | |    //__| |    //___/ /    / /    //__| |\n"
"  // |  //  | |   / ___  |   / ___ (     / /    / ___  |\n"
" //  | //   | |  //    | |  //   | |    / /    //    | |\n"
"//   |//    | | //     | | //    | | __/ /___ //     | |\n\n";

    const char *startup = "Kernel @ ";
    const char *startup2 = " ~ ";
    const char *msg_vram = "Video memory @ ";
    const char *shutdown = "Kernel shutting down...";

    char messages[256][10];
    memset(messages, 0, 256 * 10);
    strncpy(messages[0], "message1", 9);
    strncpy(messages[1], "message2", 9);
    strncpy(messages[2], "message3", 9);
    strncpy(messages[3], "message4", 9);

    cursor_x = 0;
    cursor_y = 1;
    cursor_attrib = 0x07;

    cls(cursor_attrib);

    /*
    for(int i = 0; i <= 79; ++i)
    {
        memset(scr-1, 0x07, 1);
        memset(scr+i, 0xB0, 1);
    }
    memcpy(scr + 1920, scr, 79);
    */

    puts(banner);
    puts(startup);
    putn("ux", (int)kmain);
    puts(startup2);

    putn("ux", (int)kend);
    putnl();

    puts(msg_vram);
    putn("ux", (int)scr);
    putnl();

    puts(shutdown);
    putn("ux", 0xDEADBEEF);
    putn("ui", 10);
    putn("x", 10);
    putn("si", -32768);
    putn("si", 32768);
    putn("x", (int)strchr((char*)shutdown, 'K'));
    putn("x", (int)strchr((char*)shutdown, '.'));

    puts((char*)messages[0]);
    puts((char*)messages[1]);
    puts((char*)messages[2]);
    puts((char*)messages[3]);

    char catme[20];
    strncpy(catme, "i like ", 8);
    strncat(catme, "cats\n", 5);
    puts((char*)catme);

    putn("i", strncmp(messages[1], messages[3], 9));

    unsigned char key, status;
    outb(0x20, 0x20);
    while(1)
    {
        status = kbd_status();
        if(status & 0x1)
        {
            key = kbd_scancode();

            putn("x", key);
            putc('\n');
        }

    }

    return 0xffffffff;
}
