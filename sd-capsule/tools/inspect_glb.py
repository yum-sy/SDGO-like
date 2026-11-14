"""Read acquired GLBs only; no network or modification of source assets."""
import hashlib
import json
import struct
from pathlib import Path
root = Path(__file__).resolve().parents[1]
report = {}
for name in ('rx78', 'zaku'):
    path = root / 'assets/models' / (name + '.glb')
    data = path.read_bytes()
    magic, version, length = struct.unpack_from('<III', data)
    assert magic == 0x46546C67 and version == 2 and length == len(data)
    size, chunk = struct.unpack_from('<II', data, 12)
    assert chunk == 0x4E4F534A
    gltf = json.loads(data[20:20+size])
    primitives = [p for m in gltf.get('meshes', []) for p in m['primitives']]
    report[name] = {
        'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(),
        **{k: len(gltf.get(k, [])) for k in ('nodes', 'meshes', 'skins', 'animations', 'materials', 'images')},
        'joint_attribute_primitives': sum('JOINTS_0' in p['attributes'] for p in primitives),
        'weight_attribute_primitives': sum('WEIGHTS_0' in p['attributes'] for p in primitives),
        'triangle_primitives': sum(p.get('mode', 4) == 4 for p in primitives),
        'line_primitives': sum(p.get('mode', 4) == 1 for p in primitives),
        'named_parts': [n['name'] for n in gltf['nodes'] if name == 'rx78' and 'name' in n and 'mesh' in n]
    }
(root / 'evidence/model-inspection.json').write_text(json.dumps(report, indent=2))
print(json.dumps(report, indent=2))
