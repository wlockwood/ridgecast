"""Validate the TIFF metadata and storage ranges RidgeCast's WorldPop reader needs.

Uses Python's standard library; reads metadata only, without loading country
rasters into memory. This does not authenticate dataset provenance or decode
every compressed pixel block.
"""
import argparse
import json
import math
import struct
from pathlib import Path

FORMATS = {1: "B", 3: "H", 4: "I", 6: "b", 8: "h", 9: "i", 11: "f", 12: "d", 16: "Q", 17: "q", 18: "Q"}
NEEDED = {256, 257, 258, 259, 262, 273, 277, 278, 279, 284, 317, 322, 323, 324, 325, 339, 33550, 33922, 34264, 34735}
MAX_TAG_BYTES = 16 * 1024 * 1024


def validate(path):
    path = Path(path)
    with path.open("rb") as stream:
        size = path.stat().st_size

        def read_at(offset, length):
            if offset < 0 or length < 0 or offset + length > size:
                raise ValueError("TIFF data range is outside the file (truncated download)")
            stream.seek(offset)
            data = stream.read(length)
            if len(data) != length:
                raise ValueError("TIFF changed or was truncated while being checked")
            return data

        marker = read_at(0, 2)
        if marker not in (b"II", b"MM"):
            raise ValueError("Not a TIFF file: expected II or MM byte-order marker")
        endian = "<" if marker == b"II" else ">"

        def unpack(offset, fmt):
            return struct.unpack(endian + fmt, read_at(offset, struct.calcsize(endian + fmt)))

        magic = unpack(2, "H")[0]
        if magic == 42:
            slot, entry_size, count_size, header_size = 4, 12, 2, 8
            pointer_format, entry_format, count_format = "I", "HHI", "H"
            directory = unpack(4, "I")[0]
        elif magic == 43:
            if unpack(4, "HH") != (8, 0):
                raise ValueError("Unsupported BigTIFF offset format")
            slot, entry_size, count_size, header_size = 8, 20, 8, 16
            pointer_format, entry_format, count_format = "Q", "HHQ", "Q"
            directory = unpack(8, "Q")[0]
        else:
            raise ValueError("Invalid TIFF magic number")
        if directory < header_size:
            raise ValueError("Invalid TIFF image directory range")
        count = unpack(directory, count_format)[0]
        if not 1 <= count <= 4096:
            raise ValueError("Invalid TIFF image directory entry count")
        read_at(directory, count_size + count * entry_size + slot)
        tags = {}
        for index in range(count):
            entry = directory + count_size + index * entry_size
            tag, kind, length = unpack(entry, entry_format)
            if tag not in NEEDED:
                continue
            if tag in tags or kind not in FORMATS:
                raise ValueError(f"Duplicate or unsupported TIFF tag {tag}")
            allowed_kinds = (12,) if tag in (33550, 33922, 34264) else (3,) if tag == 34735 else (1, 3, 4, 16, 18)
            if kind not in allowed_kinds:
                raise ValueError(f"Invalid numeric type for TIFF tag {tag}")
            fmt = FORMATS[kind]
            byte_count = struct.calcsize(fmt) * length
            if not 1 <= byte_count <= MAX_TAG_BYTES:
                raise ValueError(f"Invalid or excessive TIFF tag {tag} size")
            value_slot = entry + entry_size - slot
            offset = value_slot if byte_count <= slot else unpack(value_slot, pointer_format)[0]
            tags[tag] = struct.unpack(endian + str(length) + fmt, read_at(offset, byte_count))

        def scalar(tag, default=None):
            values = tags.get(tag, (default,))
            if len(values) != 1 or values[0] is None:
                raise ValueError(f"Missing or invalid TIFF tag {tag}")
            return values[0]

        width, height = scalar(256), scalar(257)
        if not (0 < width <= 0xFFFFFFFF and 0 < height <= 0xFFFFFFFF):
            raise ValueError("TIFF dimensions must be positive")
        if scalar(277, 1) != 1 or scalar(258) != 32 or scalar(339, 1) != 3:
            raise ValueError("WorldPop tiles must contain one float32 population band")
        if scalar(262) != 1 or scalar(284, 1) != 1:
            raise ValueError("WorldPop tiles must use a single grayscale band")
        # Lossless formats enabled in RidgeCast's tiff 0.11 decoder. JPEG,
        # bilevel fax, ZSTD and WebP are unsuitable for this float32 dataset.
        compression = scalar(259, 1)
        if compression not in (1, 5, 8, 32946, 32773):
            raise ValueError("TIFF compression is incompatible with RidgeCast's WorldPop reader")
        if scalar(317, 1) not in (1, 2, 3):
            raise ValueError("Unsupported TIFF predictor")
        scale, tie = tags.get(33550, ()), tags.get(33922, ())
        if 34264 in tags or len(scale) != 3 or len(tie) != 6:
            raise ValueError("Missing or unsupported north-up TIFF georeference tags")
        if not all(math.isfinite(x) for x in (*scale, *tie)) or min(scale[:2]) <= 0:
            raise ValueError("Invalid TIFF georeference values")
        if not all(math.isclose(x, 1 / 1200, rel_tol=1e-6) for x in scale[:2]):
            raise ValueError("WorldPop tiles must have approximately 100 m (3 arc-second) resolution")
        keys = tags.get(34735, ())
        if len(keys) < 4 or keys[:3] != (1, 1, 0) or len(keys) != 4 + 4 * keys[3]:
            raise ValueError("Invalid GeoTIFF key directory; WGS 84 is required")
        geo = {}
        for index in range(4, len(keys), 4):
            key, location, length, value = keys[index:index + 4]
            if key in geo:
                raise ValueError("Duplicate GeoTIFF coordinate key")
            geo[key] = (location, length, value)
        if geo.get(1024) != (0, 1, 2) or geo.get(2048) != (0, 1, 4326):
            raise ValueError("WorldPop tiles must use geographic WGS 84 (EPSG:4326)")
        if geo.get(1025, (0, 1, 1)) != (0, 1, 1):
            raise ValueError("WorldPop georeference must use PixelIsArea")
        west, north = tie[3] - tie[0] * scale[0], tie[4] + tie[1] * scale[1]
        east, south = west + width * scale[0], north - height * scale[1]
        tiled = any(tag in tags for tag in (322, 323, 324, 325))
        if tiled and any(tag in tags for tag in (273, 278, 279)):
            raise ValueError("Cannot mix TIFF tile and strip storage")
        if tiled:
            chunk_width, chunk_height = scalar(322), scalar(323)
            offsets, lengths = tags.get(324, ()), tags.get(325, ())
        else:
            chunk_width, chunk_height = width, scalar(278, height)
            offsets, lengths = tags.get(273, ()), tags.get(279, ())
        if chunk_width <= 0 or chunk_height <= 0 or chunk_width * chunk_height * 4 > 4 * 1024**3:
            raise ValueError("Invalid TIFF chunk dimensions or decoding buffer exceeds 4 GiB")
        # Source COGs pad edge grids to block boundaries; USA and Russia extend
        # slightly past 180 degrees. Permit one storage block of edge padding.
        longitude_padding = chunk_width * scale[0] if tiled else scale[0]
        latitude_padding = chunk_height * scale[1] if tiled else scale[1]
        if not (-180.00001 <= west < 180 and -90 < north <= 90.00001 and
                east <= 180 + longitude_padding and south >= -90 - latitude_padding):
            raise ValueError(f"TIFF georeference lies outside longitude/latitude bounds: {west}, {south}, {east}, {north}")
        expected = ((width + chunk_width - 1) // chunk_width) * ((height + chunk_height - 1) // chunk_height)
        if len(offsets) != expected or len(lengths) != expected:
            raise ValueError("TIFF pixel block offsets/counts do not match image dimensions")
        for index, (offset, length) in enumerate(zip(offsets, lengths)):
            if offset < header_size or length <= 0 or offset + length > size:
                raise ValueError("TIFF pixel data range is invalid or truncated")
            if compression == 1:
                stored_rows = chunk_height if tiled else min(chunk_height, height - index * chunk_height)
                if length != chunk_width * stored_rows * 4:
                    raise ValueError("Invalid uncompressed TIFF pixel block byte count")
        return {"file": path.name, "width": width, "height": height,
                "blocks": expected, "bytes": size, "bigtiff": magic == 43}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("file", type=Path)
    args = parser.parse_args()
    try:
        print(json.dumps(validate(args.file)))
    except (OSError, ValueError, struct.error) as error:
        parser.exit(1, f"{args.file}: {error}\n")


if __name__ == "__main__":
    main()
