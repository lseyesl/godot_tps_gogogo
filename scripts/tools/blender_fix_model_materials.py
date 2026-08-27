import re
import struct
import sys
from pathlib import Path

def script_arguments():
    separator = sys.argv.index("--") if "--" in sys.argv else len(sys.argv)
    arguments = sys.argv[separator + 1 :]
    if len(arguments) != 2:
        raise SystemExit("usage: blender --background --python blender_fix_model_materials.py -- INPUT_DIR OUTPUT_DIR")
    return Path(arguments[0]).resolve(), Path(arguments[1]).resolve()


JSON_CHUNK = 0x4E4F534A
GLB_MAGIC = 0x46546C67
METALLIC_PATTERN = re.compile(rb'("metallicFactor"\s*:\s*)(1(?:\.0+)?)')
PBR_START_PATTERN = re.compile(rb'("pbrMetallicRoughness"\s*:\s*\{)')


def process_model(input_path, output_path):
    source = input_path.read_bytes()
    magic, version, declared_length = struct.unpack_from("<III", source, 0)
    if magic != GLB_MAGIC or version != 2 or declared_length != len(source):
        raise RuntimeError(f"{input_path.name}: invalid GLB 2 header")
    chunks = []
    offset = 12
    changed = 0
    binary_chunks_before = []
    while offset < len(source):
        chunk_length, chunk_type = struct.unpack_from("<II", source, offset)
        data_start = offset + 8
        data = source[data_start : data_start + chunk_length]
        if chunk_type == JSON_CHUNK:
            updated, replacements = METALLIC_PATTERN.subn(
                lambda match: match.group(1) + b"0" + match.group(2)[1:], data
            )
            changed += replacements
            if replacements == 0:
                updated, insertions = PBR_START_PATTERN.subn(rb'\1"metallicFactor":0,', updated)
                changed += insertions
            updated = updated.rstrip(b" \x00")
            updated += b" " * ((4 - len(updated) % 4) % 4)
            data = updated
        else:
            binary_chunks_before.append(data)
        chunks.append((chunk_type, data))
        offset = data_start + chunk_length
    if changed == 0:
        raise RuntimeError(f"{input_path.name}: no pbrMetallicRoughness block was changed")
    payload = bytearray()
    for chunk_type, data in chunks:
        payload.extend(struct.pack("<II", len(data), chunk_type))
        payload.extend(data)
    result = struct.pack("<III", GLB_MAGIC, 2, 12 + len(payload)) + bytes(payload)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(result)
    print(
        f"FIXED {input_path.name} metallic_materials={changed} "
        f"size={len(source)}->{len(result)} binary_chunks_preserved={len(binary_chunks_before)} output={output_path}"
    )


def main():
    input_dir, output_dir = script_arguments()
    for input_path in sorted(input_dir.glob("*.glb")):
        process_model(input_path, output_dir / input_path.name)


if __name__ == "__main__":
    main()
