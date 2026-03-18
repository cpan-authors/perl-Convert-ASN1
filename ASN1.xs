/* Copyright (c) 2000-2024 Graham Barr <gbarr@cpan.org>. All rights reserved.
 * This program is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 *
 * XS implementation of Convert::ASN1 helper functions.
 * Provides C implementations of the tag/length encoding and decoding
 * routines that are called on every encode/decode operation.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newSVpvn_flags
#include "ppport.h"

MODULE = Convert::ASN1    PACKAGE = Convert::ASN1

PROTOTYPES: DISABLE

# Return the number of bytes needed to encode an unsigned integer value.
# Equivalent to the pure-Perl num_length() function.

int
num_length(val)
    UV val
CODE:
    RETVAL = (val >> 24) ? 4 : (val >> 16) ? 3 : (val >> 8) ? 2 : 1;
OUTPUT:
    RETVAL


# Encode a length value into BER/DER length bytes.
# Returns a 1-byte string for lengths < 128, or a multi-byte string otherwise.

SV *
asn_encode_length(len)
    UV len
CODE:
    if (len >> 7) {
        /* Long-form length: 0x80|n followed by n big-endian bytes */
        int n = (len >> 24) ? 4 : (len >> 16) ? 3 : (len >> 8) ? 2 : 1;
        unsigned char buf[5];
        buf[0] = (unsigned char)(n | 0x80);
        switch (n) {
            case 4:
                buf[1] = (unsigned char)((len >> 24) & 0xff);
                buf[2] = (unsigned char)((len >> 16) & 0xff);
                buf[3] = (unsigned char)((len >>  8) & 0xff);
                buf[4] = (unsigned char)( len        & 0xff);
                break;
            case 3:
                buf[1] = (unsigned char)((len >> 16) & 0xff);
                buf[2] = (unsigned char)((len >>  8) & 0xff);
                buf[3] = (unsigned char)( len        & 0xff);
                break;
            case 2:
                buf[1] = (unsigned char)((len >>  8) & 0xff);
                buf[2] = (unsigned char)( len        & 0xff);
                break;
            default: /* case 1 */
                buf[1] = (unsigned char)( len        & 0xff);
                break;
        }
        RETVAL = newSVpvn((const char *)buf, (STRLEN)(n + 1));
    } else {
        /* Short-form length: single byte */
        unsigned char c = (unsigned char)(len & 0x7f);
        RETVAL = newSVpvn((const char *)&c, (STRLEN)1);
    }
OUTPUT:
    RETVAL


# Encode a tag integer into BER/DER tag bytes.
# The tag integer is stored in a packed little-endian format by asn_tag():
#   - tags 0-255:     single byte
#   - tags in 256-32767: two bytes little-endian (pack "v")
#   - tags with bit 15 set, bit 23 clear: three bytes little-endian
#   - tags with bit 23 set: four bytes little-endian (pack "V")

SV *
asn_encode_tag(tag)
    UV tag
CODE:
    if (tag >> 8) {
        unsigned char buf[4];
        STRLEN n;
        if (tag & 0x8000) {
            if (tag & 0x800000) {
                /* 4-byte little-endian tag */
                buf[0] = (unsigned char)( tag        & 0xff);
                buf[1] = (unsigned char)((tag >>  8) & 0xff);
                buf[2] = (unsigned char)((tag >> 16) & 0xff);
                buf[3] = (unsigned char)((tag >> 24) & 0xff);
                n = 4;
            } else {
                /* 3-byte little-endian tag */
                buf[0] = (unsigned char)( tag        & 0xff);
                buf[1] = (unsigned char)((tag >>  8) & 0xff);
                buf[2] = (unsigned char)((tag >> 16) & 0xff);
                n = 3;
            }
        } else {
            /* 2-byte little-endian tag */
            buf[0] = (unsigned char)( tag       & 0xff);
            buf[1] = (unsigned char)((tag >> 8) & 0xff);
            n = 2;
        }
        RETVAL = newSVpvn((const char *)buf, n);
    } else {
        /* 1-byte tag */
        unsigned char c = (unsigned char)(tag & 0xff);
        RETVAL = newSVpvn((const char *)&c, (STRLEN)1);
    }
OUTPUT:
    RETVAL


# Decode a BER/DER length field from the start of a string.
# Returns (bytes_consumed, length_value) or () on error.
# Returns (1, -1) for indefinite length encoding.

void
asn_decode_length(sv)
    SV *sv
PREINIT:
    STRLEN slen;
    const unsigned char *buf;
    UV first;
PPCODE:
    if (!SvOK(sv))
        XSRETURN_EMPTY;
    buf = (const unsigned char *)SvPV(sv, slen);
    if (slen == 0)
        XSRETURN_EMPTY;
    first = buf[0];
    if (first & 0x80) {
        UV n = first & 0x7f;
        if (n == 0) {
            /* Indefinite length */
            EXTEND(SP, 2);
            mPUSHu(1);
            mPUSHi(-1);
            XSRETURN(2);
        }
        if (n >= slen)
            XSRETURN_EMPTY;
        {
            UV val = 0;
            UV i;
            for (i = 0; i < n; i++)
                val = (val << 8) | buf[1 + i];
            EXTEND(SP, 2);
            mPUSHu(1 + n);
            mPUSHu(val);
            XSRETURN(2);
        }
    }
    EXTEND(SP, 2);
    mPUSHu(1);
    mPUSHu(first);
    XSRETURN(2);


# Decode a BER/DER tag field from the start of a string.
# Returns (bytes_consumed, tag_integer) or () on error.
# The tag integer uses the same packed little-endian format as asn_encode_tag.

void
asn_decode_tag(sv)
    SV *sv
PREINIT:
    STRLEN slen;
    const unsigned char *buf;
    UV tag, n;
PPCODE:
    if (!SvOK(sv))
        XSRETURN_EMPTY;
    buf = (const unsigned char *)SvPV(sv, slen);
    if (slen == 0)
        XSRETURN_EMPTY;
    tag = buf[0];
    n = 1;
    if ((tag & 0x1f) == 0x1f) {
        unsigned char b;
        do {
            if (n >= slen)
                XSRETURN_EMPTY;
            b = buf[n];
            tag |= ((UV)b) << (8 * n);
            n++;
        } while (b & 0x80);
    }
    EXTEND(SP, 2);
    mPUSHu(n);
    mPUSHu(tag);
    XSRETURN(2);


# Variant of asn_decode_tag that also returns the numeric tag value separately.
# Returns (bytes_consumed, raw_tag_byte, tag_number) or () on error.
# tag_number is the decoded tag number (without class/constructed bits).

void
asn_decode_tag2(sv)
    SV *sv
PREINIT:
    STRLEN slen;
    const unsigned char *buf;
    UV tag, num, len;
PPCODE:
    if (!SvOK(sv))
        XSRETURN_EMPTY;
    buf = (const unsigned char *)SvPV(sv, slen);
    if (slen == 0)
        XSRETURN_EMPTY;
    tag = buf[0];
    num = tag & 0x1f;
    len = 1;
    if (num == 0x1f) {
        unsigned char b;
        num = 0;
        do {
            if (len >= slen)
                XSRETURN_EMPTY;
            b = buf[len++];
            num = (num << 7) | (b & 0x7f);
        } while (b & 0x80);
    }
    EXTEND(SP, 3);
    mPUSHu(len);
    mPUSHu(tag);
    mPUSHu(num);
    XSRETURN(3);
