"""Minimal general WDC5 (DB2) reader.

Returns, per section, rows of inline field values in storage order plus the
non-inline ID (id list / copy table) and the relationship-map foreign key.
Field meaning comes from WoWDBDefs; this file only decodes storage.
"""
import struct


def _bits(rec, off, size):
    v = int.from_bytes(rec, "little")
    return (v >> off) & ((1 << size) - 1)


def read(d):
    assert d[:4] == b"WDC5", d[:4]
    rc, fc, rs, sts, th, lh, mn, mx, loc = struct.unpack_from("<9I", d, 136)
    flags, id_index = struct.unpack_from("<HH", d, 172)
    tfc, bpo, lcc, fsis, cds, pds, sc = struct.unpack_from("<7I", d, 176)
    pos = 204
    secs = []
    for _ in range(sc):
        tkh, fo, src, sst, ore, ils, rds, omc, ctc = struct.unpack_from("<QIIIIIIII", d, pos)
        secs.append(dict(tkh=tkh, fo=fo, rc=src, sts=sst, ore=ore, ils=ils, rds=rds, omc=omc, ctc=ctc))
        pos += 40
    pos += 4 * fc  # field_structure
    info = []
    for _ in range(fsis // 24):
        fob, fsb, ads, st, v1, v2, v3 = struct.unpack_from("<HHIIIII", d, pos)
        info.append(dict(off=fob, size=fsb, ads=ads, type=st, v1=v1, v2=v2, v3=v3))
        pos += 24
    # pallet data then common data, each split by additional_data_size
    pallet, common = [], []
    p = pos
    for f in info:
        if f["type"] in (3, 4):
            n = f["ads"] // 4
            pallet.append(struct.unpack_from("<%dI" % n, d, p))
            p += f["ads"]
        else:
            pallet.append(None)
    for f in info:
        if f["type"] == 2:
            n = f["ads"] // 8
            vals = struct.unpack_from("<%dI" % (2 * n), d, p)
            common.append({vals[2 * i]: vals[2 * i + 1] for i in range(n)})
            p += f["ads"]
        else:
            common.append(None)
    assert not (flags & 1), "sparse tables not supported"

    rows = []
    for s in secs:
        if s["tkh"] and not s["rc"]:
            continue
        p = s["fo"]
        recs = [d[p + i * rs:p + (i + 1) * rs] for i in range(s["rc"])]
        p += s["rc"] * rs + s["sts"]
        ids = list(struct.unpack_from("<%dI" % (s["ils"] // 4), d, p)) if s["ils"] else None
        p += s["ils"]
        copies = [struct.unpack_from("<II", d, p + 8 * j) for j in range(s["ctc"])]
        p += 8 * s["ctc"]
        p += 6 * s["omc"]
        rel = {}
        if s["rds"]:
            n, _mn, _mx = struct.unpack_from("<III", d, p)
            for j in range(n):
                fk, idx = struct.unpack_from("<II", d, p + 12 + 8 * j)
                rel[idx] = fk
            p += s["rds"]
        sec_rows = []
        for i, r in enumerate(recs):
            if s["tkh"] and not any(r):
                continue  # encrypted section we could not decrypt
            vals = []
            for fi, f in enumerate(info):
                t = f["type"]
                if t == 0:
                    nbytes = f["size"] // 8
                    vals.append(r[f["off"] // 8:f["off"] // 8 + nbytes])
                elif t in (1, 5):
                    v = _bits(r, f["off"], f["v2"])
                    if t == 5 and v & (1 << (f["v2"] - 1)):
                        v -= 1 << f["v2"]
                    vals.append(v)
                elif t == 2:
                    vals.append(None)  # resolved after id known
                elif t == 3:
                    vals.append(pallet[fi][_bits(r, f["off"], f["v2"])])
                elif t == 4:
                    k = _bits(r, f["off"], f["v2"])
                    n = f["v3"]
                    vals.append(list(pallet[fi][k * n:(k + 1) * n]))
            sec_rows.append([ids[i] if ids else None, rel.get(i), vals])
        by_id = {}
        for row in sec_rows:
            by_id[row[0]] = row
        for new, old in copies:
            if old in by_id:
                src = by_id[old]
                sec_rows.append([new, src[1], list(src[2])])
        rows.extend(sec_rows)
    # common-data fields
    for row in rows:
        for fi, f in enumerate(info):
            if f["type"] == 2:
                row[2][fi] = common[fi].get(row[0], f["v1"])
    return dict(info=info, rows=rows, id_index=id_index, flags=flags)


def u32s(b):
    """Raw bytes (type 0 field) -> list of uint32."""
    if isinstance(b, int):
        return [b]
    return list(struct.unpack("<%dI" % (len(b) // 4), b))
