import json
import sys
from pathlib import Path

import bpy


def script_arguments():
    separator = sys.argv.index("--") if "--" in sys.argv else len(sys.argv)
    arguments = sys.argv[separator + 1 :]
    if len(arguments) != 2:
        raise SystemExit("usage: blender --background --python blender_model_audit.py -- MODEL_DIR OUTPUT_JSON")
    return Path(arguments[0]).resolve(), Path(arguments[1]).resolve()


def image_metrics(image):
    width, height = image.size
    pixels = list(image.pixels)
    luminances = []
    saturated_dark = 0
    for index in range(0, len(pixels), 4):
        red, green, blue, alpha = pixels[index : index + 4]
        if alpha <= 0.01:
            continue
        luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        luminances.append(luminance)
        if luminance < 0.04:
            saturated_dark += 1
    luminances.sort()
    if not luminances:
        return {
            "width": width,
            "height": height,
            "mean_luminance": 0.0,
            "p05_luminance": 0.0,
            "p50_luminance": 0.0,
            "p95_luminance": 0.0,
            "dark_ratio_below_004": 0.0,
        }

    def percentile(fraction):
        return luminances[min(len(luminances) - 1, round((len(luminances) - 1) * fraction))]

    return {
        "width": width,
        "height": height,
        "mean_luminance": sum(luminances) / len(luminances),
        "p05_luminance": percentile(0.05),
        "p50_luminance": percentile(0.50),
        "p95_luminance": percentile(0.95),
        "dark_ratio_below_004": saturated_dark / len(luminances),
    }


def material_record(material):
    record = {
        "name": material.name,
        "use_nodes": material.use_nodes,
        "blend_method": getattr(material.surface_render_method, "name", str(material.surface_render_method)),
        "images": [],
    }
    if not material.use_nodes or material.node_tree is None:
        return record
    principled = next((node for node in material.node_tree.nodes if node.type == "BSDF_PRINCIPLED"), None)
    if principled is not None:
        record["base_color"] = list(principled.inputs["Base Color"].default_value)
        record["metallic"] = principled.inputs["Metallic"].default_value
        record["roughness"] = principled.inputs["Roughness"].default_value
    seen = set()
    for node in material.node_tree.nodes:
        if node.type != "TEX_IMAGE" or node.image is None or node.image.name in seen:
            continue
        seen.add(node.image.name)
        image = node.image
        image_record = {
            "name": image.name,
            "filepath": image.filepath,
            "colorspace": image.colorspace_settings.name,
            "packed": image.packed_file is not None,
        }
        image_record.update(image_metrics(image))
        record["images"].append(image_record)
    return record


def audit_model(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(path))
    mesh_objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    materials = []
    seen_materials = set()
    for obj in mesh_objects:
        for slot in obj.material_slots:
            if slot.material is None or slot.material.name in seen_materials:
                continue
            seen_materials.add(slot.material.name)
            materials.append(material_record(slot.material))
    return {
        "model": path.name,
        "mesh_count": len(mesh_objects),
        "vertex_count": sum(len(obj.data.vertices) for obj in mesh_objects),
        "triangle_count": sum(len(obj.data.loop_triangles) for obj in mesh_objects),
        "materials": materials,
    }


def main():
    model_dir, output_path = script_arguments()
    records = [audit_model(path) for path in sorted(model_dir.glob("*.glb"))]
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8")
    for record in records:
        image_summaries = []
        for material in record["materials"]:
            for image in material["images"]:
                image_summaries.append(
                    "%s mean=%.4f p50=%.4f dark=%.1f%%"
                    % (
                        image["name"],
                        image["mean_luminance"],
                        image["p50_luminance"],
                        image["dark_ratio_below_004"] * 100.0,
                    )
                )
        print(
            "AUDIT %s meshes=%d vertices=%d triangles=%d %s"
            % (
                record["model"],
                record["mesh_count"],
                record["vertex_count"],
                record["triangle_count"],
                "; ".join(image_summaries),
            )
        )


if __name__ == "__main__":
    main()
