import re

path = 'lib/pages/product_detail_page.dart'
with open(path, encoding='utf-8') as f:
    content = f.read()

# The dead code starts after the stub line and ends just before _infoChip
stub = "  Widget _buildBottomSheetContent(Map<String, dynamic> cartDetails) => const SizedBox.shrink();\n"
infochip_marker = "  Widget _infoChip(ColorScheme cs, String label, IconData icon, Color color) {"

stub_pos = content.find(stub)
infochip_pos = content.find(infochip_marker)

print(f"stub at char {stub_pos}, infochip at char {infochip_pos}")
print(f"Total chars: {len(content)}")

if stub_pos >= 0 and infochip_pos > stub_pos:
    stub_end = stub_pos + len(stub)
    dead = content[stub_end:infochip_pos]
    print(f"Dead code lines: {dead.count(chr(10))}")
    new_content = content[:stub_end] + "\n" + content[infochip_pos:]
    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Done - dead code removed!")
else:
    print("Markers not found, printing nearby content...")
    # Find the stub differently
    for marker in ["_buildBottomSheetContent", "_dummyHelper", "_infoChip"]:
        idx = content.find(marker)
        print(f"  '{marker}' at {idx}")

