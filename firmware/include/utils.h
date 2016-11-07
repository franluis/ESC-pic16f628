#ifndef UTILS_H__
#define UTILS_H__

#define asc2byte(val, ch) (\
	((ch) >= '0' && (ch) <= '9') ? (val) = (ch) - '0' : (\
	((ch) >= 'A' && (ch) <= 'F') ? (val) = (ch) - ('A' - 10) : (\
	((ch) >= 'a' && (ch) <= 'f') ? (val) = (ch) - ('a' - 10) : \
	-1)))

// Convert an ascii string to a byte
#define str2byte(val, str, err) do { \
	char *st000 = str; \
	char c000 = *(st000+1); \
	char d000; \
	if(asc2byte(val, c000) < 0) { err = -1; break; } \
	c000 = *st000; \
	if(asc2byte(d000, c000) < 0) { err = -1; break; } \
	val |= d000 << 4; \
	err = 0; \
	} while (0)

#define byte2str(str, val) do { \
		byte *s = (byte *)str; \
		byte tmp = ((val & 0xFF) >> 4); \
		*s = (tmp < 0x0A) ? tmp + '0' : tmp + ('A' - 0x0A); \
		tmp = (val & 0x0F); \
		*(s+1) = (tmp < 0x0A) ? tmp + '0' : tmp + ('A' - 0x0A); \
	} while(0)

#define int2str(str, val) do{\
		byte *s = (byte *)str;\
		byte tmp = (val >> 12) & 0x0F; \
		*s = (tmp < 0x0A) ? tmp + '0' : tmp + ('A' - 0x0A); \
		tmp = (val >> 8) & 0x0F; \
		*(s+1) = (tmp < 0x0A) ? tmp + '0' : tmp + ('A' - 0x0A); \
		tmp = (val >> 4) & 0x0F; \
		*(s+2) = (tmp < 0x0A) ? tmp + '0' : tmp + ('A' - 0x0A); \
		tmp = (val) & 0x0F; \
		*(s+3) = (tmp < 0x0A) ? tmp + '0' : tmp + ('A' - 0x0A); \
	} while(0)

#endif
